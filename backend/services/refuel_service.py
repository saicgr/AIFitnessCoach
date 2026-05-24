"""
Post-cardio refuel prescriber — water + carbs + protein guidance after a
cardio session, derived from ACSM / NATA position stands.

References (these are the canonical sources our defaults map onto):
  - ACSM Position Stand: Exercise and Fluid Replacement (2007) — fluid loss
    estimate of ~0.012-0.020 L/kg/min and replacement at 100-150% of loss.
  - ISSN Position Stand: Nutrient Timing (2017) — 1.0-1.2 g/kg/h carbs in
    the 30-60 min post-exercise window and 0.25-0.30 g/kg protein.
  - NATA Position Statement: Fluid Replacement (2017) — bounds + warm-up
    rules; we floor the prescription at 250 ml.

Design notes:
  - Skip (return None) on low-intensity sessions (<200 kcal) — refuel
    coaching adds noise for a 15-min walk.
  - Skip if user already met both carb AND protein targets today — we
    don't want to over-feed someone hitting their numbers.
  - The rationale string draws from a variant pool so the card doesn't
    read like a robotic template across days (feedback_dynamic_copy).
"""
from __future__ import annotations

import random
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field

from core.logger import get_logger

logger = get_logger(__name__)


# ACSM-style coefficients (per-kg per-minute fluid loss).
_FLUID_LOSS_L_PER_KG_PER_MIN_LIGHT = 0.012
_FLUID_LOSS_L_PER_KG_PER_MIN_INTENSE = 0.020
# Replacement rate — ACSM recommends 100-150% of loss; use 150%.
_FLUID_REPLACEMENT_FACTOR = 1.5

# ISSN nutrient-timing carb defaults (g/kg/h).
_CARBS_G_PER_KG_PER_HOUR_LOW = 1.0
_CARBS_G_PER_KG_PER_HOUR_HIGH = 1.2

# ISSN protein default (g/kg, single dose).
_PROTEIN_G_PER_KG_LOW = 0.25
_PROTEIN_G_PER_KG_HIGH = 0.30

# Bounds.
_WATER_MIN_ML = 250
_WATER_MAX_ML = 1500
_CARBS_MIN_G = 15
_CARBS_MAX_G = 80
_PROTEIN_MIN_G = 10
_PROTEIN_MAX_G = 40

# Intensity skip threshold (kcal).
_MIN_CALORIES_FOR_REFUEL = 200

# Post-exercise refuel window (minutes).
_DEFAULT_REFUEL_WINDOW_MIN = 30


class RefuelPrescription(BaseModel):
    """Post-cardio recovery target — shown to user as a card after a session."""

    water_ml: int = Field(..., ge=0)
    carbs_g: int = Field(..., ge=0)
    protein_g: int = Field(..., ge=0)
    window_minutes: int = _DEFAULT_REFUEL_WINDOW_MIN
    rationale: str


def _intensity_factor(calories: float, duration_min: float) -> float:
    """Return 0.0 (light) .. 1.0 (intense) based on kcal/min."""
    if duration_min <= 0:
        return 0.0
    kcal_per_min = calories / duration_min
    # ~5 kcal/min = walk; ~15 kcal/min = hard run. Map to [0, 1].
    if kcal_per_min <= 5:
        return 0.0
    if kcal_per_min >= 15:
        return 1.0
    return (kcal_per_min - 5) / 10.0


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * max(0.0, min(1.0, t))


def _bound(v: float, lo: int, hi: int) -> int:
    return int(max(lo, min(hi, round(v))))


# Rationale variant pool — see feedback_dynamic_copy_not_robotic.md.
# We slot in {activity} and {duration_min}. The pool needs ≥4 variants per
# pattern so 100 invocations yield broad coverage.
_RATIONALE_VARIANTS: List[str] = [
    "After that {duration_min}-min {activity}, your tank is low — top off fluids and refeed within {window} min.",
    "{duration_min} minutes of {activity} burns through glycogen — hit these in the next half hour.",
    "Nice {activity}. Your muscles are primed to absorb carbs and protein right now.",
    "Recovery starts now. Replace what that {duration_min}-min {activity} cost you.",
    "Window's open: post-{activity} refuel works best in the next {window} minutes.",
    "Your body just spent — this is the fastest path back to baseline after a {duration_min}-min {activity}.",
    "Don't waste the absorption window — refuel after that {activity} before it closes.",
    "{activity} done. Restock fluids, carbs, and a hit of protein to rebuild.",
]


def _make_rationale(activity_type: str, duration_min: int, window_min: int) -> str:
    template = random.choice(_RATIONALE_VARIANTS)
    return template.format(
        activity=activity_type.replace("_", " "),
        duration_min=duration_min,
        window=window_min,
    )


def _remaining(targets: Dict[str, Any], key_target: str, key_consumed: str) -> Optional[float]:
    """Pull `target - consumed` from a nutrition summary-like dict.

    Returns None if the target is unknown — the prescriber will treat
    that as "no ceiling" rather than zeroing the prescription out."""
    target = targets.get(key_target)
    consumed = targets.get(key_consumed)
    if target is None:
        return None
    try:
        return float(target) - float(consumed or 0)
    except (ValueError, TypeError):
        return None


def compute_refuel(
    cardio_log_dict: Dict[str, Any],
    user_weight_kg: Optional[float],
    user_remaining_macros_today: Dict[str, Any],
) -> Optional[RefuelPrescription]:
    """Build a refuel prescription for a single cardio session.

    Args:
        cardio_log_dict: row from `cardio_logs` (must have `duration_seconds`,
            `calories`, `activity_type`).
        user_weight_kg: bodyweight in kg. If None, defaults to 70 kg.
        user_remaining_macros_today: dict with keys like
            `daily_carbs_target_g`, `total_carbs_g`,
            `daily_protein_target_g`, `total_protein_g`.

    Returns:
        RefuelPrescription, or None if the session is too light or the
        user has already met both carb + protein targets today.
    """
    duration_seconds = cardio_log_dict.get("duration_seconds") or 0
    calories = cardio_log_dict.get("calories") or 0
    activity_type = cardio_log_dict.get("activity_type") or "session"

    # Skip 1: low-intensity sessions.
    if calories < _MIN_CALORIES_FOR_REFUEL:
        return None

    duration_min = max(1, int(round(duration_seconds / 60.0)))
    duration_hours = duration_min / 60.0

    # Skip 2: already met both targets today. (We allow refuel if either
    # macro still has headroom — recovery matters even if calories met.)
    carbs_remaining = _remaining(
        user_remaining_macros_today, "daily_carbs_target_g", "total_carbs_g"
    )
    protein_remaining = _remaining(
        user_remaining_macros_today, "daily_protein_target_g", "total_protein_g"
    )
    if (
        carbs_remaining is not None
        and protein_remaining is not None
        and carbs_remaining <= 0
        and protein_remaining <= 0
    ):
        return None

    weight = float(user_weight_kg) if user_weight_kg else 70.0
    intensity = _intensity_factor(float(calories), float(duration_min))

    # Water — fluid loss L/kg/min × duration × replacement factor → ml.
    loss_per_min = _lerp(
        _FLUID_LOSS_L_PER_KG_PER_MIN_LIGHT,
        _FLUID_LOSS_L_PER_KG_PER_MIN_INTENSE,
        intensity,
    )
    water_ml_raw = weight * loss_per_min * duration_min * _FLUID_REPLACEMENT_FACTOR * 1000.0
    water_ml = _bound(water_ml_raw, _WATER_MIN_ML, _WATER_MAX_ML)

    # Carbs — g/kg/h × duration_hours × bodyweight, capped to remaining intake.
    carbs_per_kg_per_h = _lerp(
        _CARBS_G_PER_KG_PER_HOUR_LOW, _CARBS_G_PER_KG_PER_HOUR_HIGH, intensity
    )
    carbs_g_raw = carbs_per_kg_per_h * duration_hours * weight
    if carbs_remaining is not None and carbs_remaining > 0:
        carbs_g_raw = min(carbs_g_raw, carbs_remaining)
    carbs_g = _bound(carbs_g_raw, _CARBS_MIN_G, _CARBS_MAX_G)

    # Protein — g/kg single dose, capped to remaining intake.
    protein_per_kg = _lerp(
        _PROTEIN_G_PER_KG_LOW, _PROTEIN_G_PER_KG_HIGH, intensity
    )
    protein_g_raw = protein_per_kg * weight
    if protein_remaining is not None and protein_remaining > 0:
        protein_g_raw = min(protein_g_raw, protein_remaining)
    protein_g = _bound(protein_g_raw, _PROTEIN_MIN_G, _PROTEIN_MAX_G)

    rationale = _make_rationale(activity_type, duration_min, _DEFAULT_REFUEL_WINDOW_MIN)

    return RefuelPrescription(
        water_ml=water_ml,
        carbs_g=carbs_g,
        protein_g=protein_g,
        window_minutes=_DEFAULT_REFUEL_WINDOW_MIN,
        rationale=rationale,
    )
