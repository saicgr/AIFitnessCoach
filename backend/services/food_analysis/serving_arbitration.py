"""Barcode default-serving-size arbitration (Gap 2).

Open Food Facts frequently reports a product's serving size as a flat 100 g (a
DB default, not the label) — wrong for e.g. protein powder where a real serving
is ~1-2 scoops (~30-40 g). Logging that as 100 g silently triples the user's
calories and destroys trust ("accuracy = trust = retention", Amy's other lever).

This module resolves the most realistic default serving from multiple candidate
sources (OFF, USDA) plus the product name, deterministically when one source is
clearly usable, and via a single cheap structured Flash-Lite call only when every
candidate is missing or stuck at the suspicious ~100 g default. Because the
barcode result is cached for 30 days after resolution, the LLM call fires at most
once per product, not per scan.
"""
from typing import List, Optional

from google.genai import types
from pydantic import BaseModel, Field

from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry, settings
from services.gemini.utils import _sanitize_for_prompt

logger = get_logger(__name__)

# A serving within this tolerance of 100 g is treated as the OFF "default" — i.e.
# suspect, not a real label value — and triggers cross-source / LLM resolution.
_SUSPICIOUS_DEFAULT_G = 100.0
_SUSPICIOUS_TOLERANCE_G = 2.0
# Plausible real-world serving bounds (g/ml). Anything outside is rejected so a
# garbage candidate can't poison the result.
_MIN_SERVING_G = 5.0
_MAX_SERVING_G = 600.0


def _is_suspicious(serving_g: Optional[float]) -> bool:
    """True when a serving is missing or sitting on the OFF ~100g default."""
    if serving_g is None or serving_g <= 0:
        return True
    return abs(serving_g - _SUSPICIOUS_DEFAULT_G) <= _SUSPICIOUS_TOLERANCE_G


def _in_range(serving_g: Optional[float]) -> bool:
    return serving_g is not None and _MIN_SERVING_G <= serving_g <= _MAX_SERVING_G


class ServingResolution(BaseModel):
    """Structured output for the LLM serving-size arbiter."""

    serving_size_g: float = Field(
        description="Most realistic single-serving size in grams (or ml for liquids)."
    )
    serving_label: str = Field(
        default="",
        description="Short human label, e.g. '2 scoops (35 g)' or '1 cup (240 ml)'.",
    )
    confidence: str = Field(default="medium", description="low | medium | high")


def pick_deterministic_serving(candidates: List[dict]) -> Optional[dict]:
    """Pick a usable serving from candidates WITHOUT an LLM call.

    A candidate is ``{source, serving_size_g, serving_label}``. Returns the first
    candidate whose gram value is in a plausible range AND not the suspicious
    ~100 g default, else ``None`` (caller then falls back to the LLM arbiter).
    """
    for c in candidates:
        g = c.get("serving_size_g")
        if _in_range(g) and not _is_suspicious(g):
            return {
                "serving_size_g": float(g),
                "serving_label": c.get("serving_label") or "",
                "source": c.get("source") or "db",
            }
    return None


async def resolve_serving_with_llm(
    product_name: str,
    brand: Optional[str],
    candidates: List[dict],
    categories: Optional[str] = None,
    user_id: Optional[str] = None,
) -> Optional[dict]:
    """Single cheap Flash-Lite call to pick the most realistic default serving.

    Returns ``{serving_size_g, serving_label, source='llm'}`` or ``None`` on any
    failure (caller keeps the existing value). Never raises.
    """
    if not product_name:
        return None

    cand_lines = []
    for c in candidates:
        g = c.get("serving_size_g")
        label = c.get("serving_label") or ""
        cand_lines.append(
            f"- {c.get('source', 'db')}: "
            f"{'%.0f g' % g if g else 'unknown grams'}"
            f"{f'; label: {label}' if label else ''}"
        )
    candidates_block = "\n".join(cand_lines) if cand_lines else "- (none)"

    prompt = f"""Determine the most realistic DEFAULT SERVING SIZE for this packaged product.

Product: {_sanitize_for_prompt(product_name, max_len=200)}
Brand: {_sanitize_for_prompt(brand or 'unknown', max_len=120)}
Category: {_sanitize_for_prompt(categories or 'unknown', max_len=200)}

Candidate servings from food databases:
{candidates_block}

Rules:
- Open Food Facts often wrongly defaults serving size to exactly 100 g. Treat a
  100 g value as UNRELIABLE unless the product is genuinely served in ~100 g
  portions.
- Return the serving a person would actually log ONCE. Examples: whey protein
  powder = 1-2 scoops (~30-40 g); cereal ~40 g; chips ~28-30 g; soda can = 355 ml;
  yogurt cup ~150-170 g; energy bar = its bar weight.
- Prefer a candidate's real label serving when one looks correct; otherwise use
  product knowledge.
- serving_size_g must be a realistic single serving (typically 5-600 g/ml).
- serving_label: a short human phrase including the unit.
"""

    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=ServingResolution,
                max_output_tokens=300,
                temperature=0.1,
            ),
            user_id=user_id,
            method_name="resolve_serving_size",
            timeout=12,
        )
        data = response.parsed
        if not data:
            return None
        g = float(data.serving_size_g or 0)
        if not _in_range(g):
            logger.info(
                f"[ServingArbiter] LLM serving {g}g out of range for "
                f"'{product_name}' — keeping existing"
            )
            return None
        logger.info(
            f"[ServingArbiter] LLM resolved serving for '{product_name}': "
            f"{g}g ({data.serving_label})"
        )
        return {
            "serving_size_g": g,
            "serving_label": (data.serving_label or "").strip(),
            "source": "llm",
        }
    except Exception as e:
        logger.warning(f"[ServingArbiter] LLM serving resolution failed: {e}")
        return None
