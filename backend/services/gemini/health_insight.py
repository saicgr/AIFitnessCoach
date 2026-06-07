"""
Grounded health-metric narration (Gemini).

A single reusable helper that turns ALREADY-COMPUTED ground-truth facts into a
short, plain-language coach read for the new health surfaces — Vitals, Heart
Health Score, Fitness Index. Mirrors the guardrails of
api/v1/coach/daily_insight.py:

  - Per-user-per-day cost cap (shared 0.02 USD ceiling, read off cost_tracker).
  - Number guardrail: every number the model prints must be one of the values
    we passed in. A single ungrounded number => reject + deterministic fallback.
  - Deterministic, flagged fallback on cap / Gemini failure / mismatch. Never a
    silent fallback to invented copy (CLAUDE.md).

The caller computes the metric deterministically and passes the headline-worthy
facts; Gemini only phrases them. No numbers originate in the model.
"""
from __future__ import annotations

import logging
import re
from typing import Any, Dict, List, Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import cost_tracker, gemini_generate_with_retry

logger = logging.getLogger("health_insight")

# Shared with the daily-insight surface: ~25 short calls/day at p99.
MAX_INSIGHT_USD_PER_USER_PER_DAY = 0.02

_NUMBER_RE = re.compile(r"\b(\d{1,5}(?:,\d{3})*)(?:\.\d+)?\b")


def _user_cost_today_usd(user_id: str) -> float:
    try:
        snap = cost_tracker.snapshot()
        return float((snap.get("by_user", {}).get(user_id) or {}).get("cost_usd", 0.0))
    except Exception:
        return 0.0


def _grounded_number_set(facts: Dict[str, Any]) -> set:
    """Every numeric value in `facts` as a string set. Trivial ints 0-3 always
    allowed (sentence counters / 'one or two')."""
    out: set = {"0", "1", "2", "3"}

    def _walk(v: Any) -> None:
        if isinstance(v, dict):
            for vv in v.values():
                _walk(vv)
        elif isinstance(v, (list, tuple)):
            for vv in v:
                _walk(vv)
        elif isinstance(v, bool):
            return
        elif isinstance(v, (int, float)):
            out.add(str(int(v)))
            if isinstance(v, float) and not v.is_integer():
                out.add(f"{v:.1f}")
        elif isinstance(v, str):
            # Pull any numbers embedded in a pre-formatted fact string
            # (e.g. "6h 41m", "85 bpm") so they count as grounded.
            for m in _NUMBER_RE.finditer(v):
                out.add(m.group(1).replace(",", ""))

    _walk(facts)
    return out


def _numbers_grounded(text: str, facts: Dict[str, Any]) -> bool:
    if not text:
        return True
    grounded = _grounded_number_set(facts)
    for m in _NUMBER_RE.finditer(text):
        token = m.group(1).replace(",", "")
        if token not in grounded:
            logger.warning(
                "[health_insight] number guardrail rejected '%s' (kind facts=%s)",
                token, sorted(grounded)[:12],
            )
            return False
    return True


def _facts_block(facts: Dict[str, Any]) -> str:
    lines: List[str] = []
    for k, v in facts.items():
        if v is None:
            continue
        lines.append(f"- {k}: {v}")
    return "\n".join(lines)


async def generate_grounded_insight(
    *,
    user_id: str,
    kind: str,
    first_name: Optional[str],
    facts: Dict[str, Any],
    fallback_headline: str,
    fallback_body: str,
    guidance: str = "",
) -> Dict[str, str]:
    """Return {headline, body, delivery}.

    `kind` is a short label used in the prompt + logs ("vitals",
    "heart_health", "fitness_index"). `facts` is the ground-truth dict the
    model may reference. `guidance` is one optional sentence steering the angle
    (e.g. "Lead with the weakest component."). On any failure the caller's
    deterministic fallback copy is returned, flagged delivery=
    "deterministic_fallback".
    """
    fallback = {
        "headline": fallback_headline,
        "body": fallback_body,
        "delivery": "deterministic_fallback",
    }

    if _user_cost_today_usd(user_id) >= MAX_INSIGHT_USD_PER_USER_PER_DAY:
        logger.info("[health_insight] %s cost cap hit for %s — fallback", kind, user_id)
        return fallback

    name = (first_name or "").strip() or None
    vocative = f" Address them as {name}." if name else ""
    system_instruction = (
        "You are a concise, encouraging fitness and health coach. You are given "
        "ground-truth facts about one user's health metric. Write a short read of "
        "it in AT MOST 2 sentences (max ~45 words).\n"
        "HARD RULES:\n"
        "- Only reference the numbers in the facts. Never invent or estimate a "
        "number that is not listed.\n"
        "- No em dashes or en dashes. Use plain commas/periods.\n"
        "- Plain, human, specific. No hashtags, no emoji, no markdown.\n"
        f"- Be actionable when the facts suggest a clear next step.{vocative}\n"
        "Return ONLY a compact JSON object: "
        '{"headline": "<=6 words", "body": "1-2 sentences"}'
    )
    user_message = (
        f"Metric: {kind}\n"
        f"Facts:\n{_facts_block(facts)}\n"
        + (f"\nGuidance: {guidance}\n" if guidance else "")
    )

    settings = get_settings()
    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                max_output_tokens=200,
                temperature=0.5,
            ),
            user_id=user_id,
            timeout=18.0,
            max_retries=3,
            method_name=f"health_insight_{kind}",
        )
        text = getattr(response, "text", None)
        if not text:
            return fallback
        import json
        parsed = json.loads(text)
        headline = (parsed.get("headline") or "").strip()
        body = (parsed.get("body") or "").strip()
        if not headline or not body:
            return fallback
        # Guardrails: numbers grounded + no dashes slipped through.
        if not _numbers_grounded(headline + " " + body, facts):
            return fallback
        if "—" in body or "–" in body or "—" in headline or "–" in headline:
            body = body.replace("—", ", ").replace("–", ", ")
            headline = headline.replace("—", " ").replace("–", " ")
        return {"headline": headline[:60], "body": body[:240], "delivery": "gemini"}
    except Exception as e:
        logger.warning("[health_insight] %s gemini failed: %s", kind, e)
        return fallback
