"""Language-agnostic hydration split for the food text/voice logger.

Amy-style "type your food, calories appear" loggers ignore beverages. Gap 1
makes a single typed/dictated entry like "2 eggs and a glass of water" log the
eggs as food AND the water as hydration, in ANY language — keyword matching
("water", "oz") breaks for non-English input, so we use a tiny structured LLM
call on the cheap default model (``gemini-3.1-flash-lite``).

The detector is deliberately conservative: it only counts *drinkable* fluids
that contribute to hydration (water, coffee/tea, sports drinks, protein shakes),
never the water content of solid foods, and returns ``None`` on any failure so a
hydration miss never blocks a food log. Gating it on the user's
``hydration_tracking_enabled`` preference (Gap 6) keeps cost at zero when the
feature is off — exactly the trade Amy made.
"""
from typing import Optional

from google.genai import types
from pydantic import BaseModel, Field

from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry, settings
from services.gemini.utils import _sanitize_for_prompt

logger = get_logger(__name__)

# drink_type values accepted by hydration_logs (mirrors HydrationLogCreate).
_ALLOWED_DRINK_TYPES = {"water", "protein_shake", "sports_drink", "coffee", "other"}


class HydrationSplitResponse(BaseModel):
    """Structured output for the hydration detection pre-pass."""

    has_hydration: bool = Field(
        description="True only if the text mentions a drinkable beverage that hydrates."
    )
    amount_ml: int = Field(
        default=0,
        description="Total fluid volume in milliliters. 0 when has_hydration is false.",
    )
    drink_type: str = Field(
        default="water",
        description="One of: water, protein_shake, sports_drink, coffee, other.",
    )


_PROMPT_TEMPLATE = """You parse a single food/drink log entry written in ANY language.

Decide whether it contains a DRINKABLE beverage that contributes to hydration
(plain water, coffee, tea, sports drinks, protein shakes, juice, milk, soda).

Rules:
- Count ONLY beverages the person drank. NEVER count the water content of solid
  foods (soup, watermelon, yogurt are food, not a logged beverage).
- Sum the total fluid volume across all beverages and return it in milliliters.
- Reasonable real-world volumes when the user is vague (these are guidelines, not
  rigid): a glass of water ≈ 250 ml, a cup ≈ 240 ml, a mug of coffee ≈ 240 ml,
  a bottle ≈ 500 ml, a large bottle ≈ 750 ml, a can ≈ 355 ml, "a sip" ≈ 50 ml.
- Honor explicit amounts the user gives (e.g. "500 ml", "16 oz" = 473 ml,
  "2 glasses" = 500 ml, "1 L" = 1000 ml).
- drink_type: "water" for plain water; "coffee" for coffee/tea; "sports_drink"
  for electrolyte/sports drinks; "protein_shake" for protein/meal shakes;
  "other" for juice/milk/soda/anything else. If multiple, pick the largest by volume.
- If there is NO logged beverage at all, return has_hydration=false, amount_ml=0.

Entry: "{entry}"
"""


async def detect_hydration_in_text(
    description: str, user_id: Optional[str] = None
) -> Optional[dict]:
    """Detect a hydration component in a free-text food entry.

    Returns ``{"amount_ml": int, "drink_type": str}`` when a beverage is found,
    else ``None``. Never raises — any failure yields ``None`` so the food-log
    path is unaffected.
    """
    if not description or not description.strip():
        return None

    prompt = _PROMPT_TEMPLATE.format(entry=_sanitize_for_prompt(description, max_len=2000))

    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=HydrationSplitResponse,
                max_output_tokens=400,
                temperature=0.0,
            ),
            user_id=user_id,
            method_name="detect_hydration_in_text",
            timeout=12,
        )
        data = response.parsed
        if not data or not data.has_hydration:
            return None

        amount_ml = int(data.amount_ml or 0)
        if amount_ml <= 0:
            return None
        # Clamp to the same sane bounds the hydration endpoint enforces (1-10000).
        amount_ml = max(1, min(amount_ml, 10000))

        drink_type = (data.drink_type or "water").strip().lower()
        if drink_type not in _ALLOWED_DRINK_TYPES:
            drink_type = "water"

        logger.info(
            f"[HydrationSplit] Detected {amount_ml}ml {drink_type} in text log "
            f"for user {user_id}"
        )
        return {"amount_ml": amount_ml, "drink_type": drink_type}

    except Exception as e:
        logger.warning(f"[HydrationSplit] detection skipped: {e}")
        return None
