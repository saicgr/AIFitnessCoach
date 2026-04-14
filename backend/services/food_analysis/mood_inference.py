"""Passive mood inference from nutritional signature (rules_v1).

Runs at food-log create time when the user skipped the post-meal check-in so
we have *some* signal for the Patterns tab / Gemini re-log warnings even if
the user never fills in mood_after themselves.

Confirmed user data always outranks inferred data in analytics — see
migration 1924 (get_food_patterns RPC applies a 0.5 weight to inferred rows).
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional, TypedDict

INFERENCE_SOURCE_V1 = "rules_v1"


class InferenceResult(TypedDict):
    mood: str
    energy: int
    confidence: float
    reason: str


# Minimum confidence before we persist an inference. Below this, we leave
# the inferred columns null so we don't pollute the dataset with noise.
MIN_CONFIDENCE_TO_PERSIST = 0.5


def _safe(num: Optional[float]) -> float:
    """Treat None/missing as 0 for numeric checks. Callers decide whether
    absence should short-circuit a rule (it usually should)."""
    return 0.0 if num is None else float(num)


def _has(num: Optional[float]) -> bool:
    return num is not None


def infer_mood_from_nutrition(
    nutrition: dict, logged_at: Optional[datetime] = None
) -> Optional[InferenceResult]:
    """Return {mood, energy, confidence, reason} or None if no rule matches.

    Expected `nutrition` keys (all optional, None-safe):
        total_calories, protein_g, carbs_g, fat_g, fiber_g, sugar_g,
        added_sugar_g, sodium_mg, alcohol_g, caffeine_mg, omega3_g,
        is_ultra_processed (bool)

    `logged_at` is used for the caffeine rule (only fires for pre-4pm meals).
    """

    if not nutrition:
        return None

    is_ultra = bool(nutrition.get("is_ultra_processed"))
    sodium = _safe(nutrition.get("sodium_mg"))
    added_sugar = _safe(nutrition.get("added_sugar_g"))
    sugar = _safe(nutrition.get("sugar_g"))
    protein = _safe(nutrition.get("protein_g"))
    fiber = _safe(nutrition.get("fiber_g"))
    carbs = _safe(nutrition.get("carbs_g"))
    alcohol = _safe(nutrition.get("alcohol_g"))
    caffeine = _safe(nutrition.get("caffeine_mg"))
    omega3 = _safe(nutrition.get("omega3_g"))

    # Rules are checked in priority order — the first match wins so that
    # strong negative signals (alcohol, ultra-processed+sodium) aren't
    # overridden by coincidental positive markers.

    # Strong negative: alcohol is the clearest tired/sluggish signal.
    if alcohol > 10:
        return {
            "mood": "tired",
            "energy": 2,
            "confidence": 0.70,
            "reason": f"Alcohol content ({alcohol:.0f}g) typically causes fatigue and disrupted energy.",
        }

    # Strong negative: ultra-processed + high sodium → bloated is a well-known pattern.
    if is_ultra and sodium > 1200:
        return {
            "mood": "bloated",
            "energy": 2,
            "confidence": 0.65,
            "reason": f"Ultra-processed meal with {sodium:.0f}mg sodium commonly causes water retention and bloating.",
        }

    # Negative: sugar crash pattern (high sugar + low protein).
    if added_sugar > 30 and protein < 10:
        return {
            "mood": "tired",
            "energy": 2,
            "confidence": 0.60,
            "reason": f"{added_sugar:.0f}g added sugar with only {protein:.0f}g protein tends to cause an energy crash.",
        }
    # Fallback when added_sugar isn't known but total sugar is very high.
    if not _has(nutrition.get("added_sugar_g")) and sugar > 45 and protein < 10:
        return {
            "mood": "tired",
            "energy": 2,
            "confidence": 0.55,
            "reason": f"{sugar:.0f}g sugar with low protein often leads to an energy dip.",
        }

    # Negative: high carbs + low fiber + low protein → sleepy after 1–2h.
    if fiber < 3 and carbs > 60 and protein < 15:
        return {
            "mood": "tired",
            "energy": 2,
            "confidence": 0.55,
            "reason": f"Low fiber ({fiber:.0f}g) with {carbs:.0f}g carbs and minimal protein commonly causes post-meal fatigue.",
        }

    # Strong positive: omega-3 rich + high fiber — classic energizing profile.
    if omega3 > 1 and fiber >= 5:
        return {
            "mood": "great",
            "energy": 4,
            "confidence": 0.55,
            "reason": f"Omega-3 rich meal ({omega3:.1f}g) with {fiber:.0f}g fiber is associated with sustained energy.",
        }

    # Positive: balanced high-protein + fiber + not ultra-processed → satisfied.
    if protein >= 25 and fiber >= 5 and not is_ultra:
        return {
            "mood": "satisfied",
            "energy": 4,
            "confidence": 0.65,
            "reason": f"Whole-food meal with {protein:.0f}g protein and {fiber:.0f}g fiber — typically satisfying and energy-stable.",
        }

    # Positive: caffeine before 4pm tends to read as a good-energy meal.
    hour = logged_at.hour if logged_at else 12
    if caffeine > 150 and hour < 16:
        return {
            "mood": "good",
            "energy": 4,
            "confidence": 0.50,
            "reason": f"Morning/afternoon caffeine boost ({caffeine:.0f}mg) commonly registers as higher energy.",
        }

    return None


def build_insert_patch(result: Optional[InferenceResult]) -> dict:
    """Convert an InferenceResult into the column patch we push onto the
    food_logs insert dict. Returns empty dict when result is None or below
    the persistence threshold."""
    if result is None:
        return {}
    if result["confidence"] < MIN_CONFIDENCE_TO_PERSIST:
        return {}
    return {
        "mood_after_inferred": result["mood"],
        "energy_level_inferred": result["energy"],
        "inference_confidence": round(result["confidence"], 2),
        "inference_source": INFERENCE_SOURCE_V1,
    }
