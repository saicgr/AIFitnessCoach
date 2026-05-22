"""
Cycle-phase-aware nutrition adjustment (Phase H).

Deterministic, no-LLM helpers that layer a menstrual-cycle-phase adjustment
on top of the user's *base* nutrition targets:

  * a luteal-phase calorie bump (higher late-luteal hunger / a measurable
    rise in resting energy expenditure across the luteal phase),
  * a phase-shifted macro split (more complex carbs in the luteal phase,
    a touch more protein during menstruation),
  * a phase-aware re-ordering of which micronutrients are highlighted
    (iron + magnesium during menstruation, etc.).

Everything here is a NO-OP unless the user has explicitly enabled the
`hormonal_profiles.cycle_sync_nutrition` opt-in toggle AND has menstrual
tracking with a usable cycle prediction. The base targets are never
mutated destructively — callers get back a new value plus an
attribution string so the UI can label *why* a target moved.

Evidence base:
  * Resting energy expenditure is measurably higher in the luteal phase
    than the follicular phase, and self-reported energy intake / appetite
    rises in the late-luteal phase — hence a modest +calorie allowance
    (kept conservative, ~+200 kcal, configurable below).
  * Carbohydrate cravings cluster in the luteal phase; nudging the split
    toward complex carbs (and away from fat) matches that without raising
    total calories beyond the bump above.
  * Iron loss during menstruation and the role of magnesium / B6 in
    luteal-phase symptom relief drive the per-phase micronutrient
    emphasis (mirrors MacroFactor request 1.15).

The cycle phase itself comes from `services.cycle.cycle_predictor`
(`predict_for_user` -> `current_phase`), so there is a single prediction
path shared with workouts and the cycle screen.
"""
from __future__ import annotations

from typing import Dict, List, Optional, Tuple

# --- Tuning constants -------------------------------------------------------
# Luteal-phase calorie bump layered on the base daily target. Plan calls for
# ~+150-250 kcal; +200 sits in the middle. Single source of truth — change
# here only.
LUTEAL_CALORIE_BUMP = 200

# Macro-split deltas, in percentage points, applied to the diet-type base
# split (carb%, protein%, fat%) and then re-normalised to sum to 100.
# Positive = add that many points to the macro before normalisation.
#   * luteal   — shift toward complex carbs, trim fat (craving-aware).
#   * menstrual — small protein nudge (supports recovery / satiety during
#     the bleed); carbs eased back slightly.
# follicular & ovulation keep the base split (no delta).
_MACRO_PHASE_DELTAS: Dict[str, Tuple[int, int, int]] = {
    # phase:      (carb_delta, protein_delta, fat_delta)
    "luteal":     (+8, 0, -8),
    "menstrual":  (-4, +4, 0),
    "follicular": (0, 0, 0),
    "ovulation":  (0, 0, 0),
}

# Per-phase micronutrient emphasis. Keys are the *logical* nutrient roots
# used by the legacy pinned-nutrient list (the columns carry unit suffixes
# like `_mg` / `_ug` which the micronutrient endpoint strips before
# matching). Order = priority, highest first.
_MICRONUTRIENT_PHASE_EMPHASIS: Dict[str, List[str]] = {
    # Menstrual bleed: iron is lost with menstrual blood; magnesium and
    # vitamin C (aids non-heme iron absorption) support the bleed.
    "menstrual":  ["iron", "magnesium", "vitamin_c", "vitamin_b12"],
    # Follicular: rebuilding — B vitamins + zinc for the follicular ramp.
    "follicular": ["folate", "vitamin_b6", "zinc", "iron"],
    # Ovulation: antioxidants + zinc around the fertile window.
    "ovulation":  ["zinc", "vitamin_e", "folate", "vitamin_c"],
    # Luteal: magnesium, B6 and calcium are the best-evidenced for
    # luteal-phase symptom relief.
    "luteal":     ["magnesium", "vitamin_b6", "calcium", "vitamin_d"],
}

# Phases recognised by the predictor. Anything else => treat as no-op.
_VALID_PHASES = {"menstrual", "follicular", "ovulation", "luteal"}


def adjust_calories_for_phase(
    base_calories: int,
    phase: Optional[str],
) -> Tuple[int, int, Optional[str]]:
    """Layer the luteal-phase calorie bump on a base daily calorie target.

    Returns ``(adjusted_calories, cycle_calorie_delta, reason)``.

    Pure / deterministic. ``phase`` of None or any non-luteal phase yields
    a zero delta and the base value unchanged — the caller is responsible
    for only passing a real phase when ``cycle_sync_nutrition`` is on.
    """
    if phase == "luteal":
        return (
            base_calories + LUTEAL_CALORIE_BUMP,
            LUTEAL_CALORIE_BUMP,
            f"Luteal phase — +{LUTEAL_CALORIE_BUMP} kcal for higher "
            "pre-period hunger and energy expenditure",
        )
    return base_calories, 0, None


def adjust_macro_split_for_phase(
    carb_pct: int,
    protein_pct: int,
    fat_pct: int,
    phase: Optional[str],
) -> Tuple[Tuple[int, int, int], Optional[str]]:
    """Layer a phase-shifted macro split over the diet-type base split.

    ``carb_pct/protein_pct/fat_pct`` is the base split (should sum to ~100).
    Returns ``((carb%, protein%, fat%), reason)`` with the adjusted split
    re-normalised to sum to exactly 100. A None / unchanged phase returns
    the base split untouched and ``reason=None``.
    """
    if phase not in _MACRO_PHASE_DELTAS:
        return (carb_pct, protein_pct, fat_pct), None

    d_carb, d_protein, d_fat = _MACRO_PHASE_DELTAS[phase]
    if (d_carb, d_protein, d_fat) == (0, 0, 0):
        return (carb_pct, protein_pct, fat_pct), None

    # Apply deltas, floor each macro so we never drive one negative.
    raw_carb = max(5, carb_pct + d_carb)
    raw_protein = max(5, protein_pct + d_protein)
    raw_fat = max(5, fat_pct + d_fat)
    total = raw_carb + raw_protein + raw_fat

    # Re-normalise to 100; assign the rounding remainder to carbs so the
    # three integers always sum to exactly 100.
    norm_protein = round(raw_protein * 100 / total)
    norm_fat = round(raw_fat * 100 / total)
    norm_carb = 100 - norm_protein - norm_fat

    if phase == "luteal":
        reason = "Luteal phase — more complex carbs to match cravings"
    elif phase == "menstrual":
        reason = "Menstrual phase — a touch more protein during your period"
    else:
        reason = None

    return (norm_carb, norm_protein, norm_fat), reason


def emphasised_nutrients_for_phase(phase: Optional[str]) -> List[str]:
    """Return the ordered list of micronutrient roots to emphasise for a
    given cycle phase. Empty list for None / unknown phase (no-op).

    The returned roots are matched against the micronutrient endpoint's
    nutrient keys after unit-suffix stripping (``iron`` matches ``iron_mg``).
    """
    if phase not in _VALID_PHASES:
        return []
    return list(_MICRONUTRIENT_PHASE_EMPHASIS.get(phase, []))


def get_cycle_phase_if_synced(
    client,
    user_id: str,
    today,
) -> Optional[str]:
    """Resolve the user's *current cycle phase* — but only if cycle-sync
    nutrition is opted in and a real prediction is available.

    Returns the phase string (``menstrual`` / ``follicular`` / ``ovulation``
    / ``luteal``) or ``None``. ``None`` means "do not apply any cycle-aware
    adjustment" — for an un-opted-in user, a user with no menstrual
    tracking, pregnancy mode, or zero period history.

    This is the single gate every cycle-aware nutrition path calls so the
    behaviour is consistent: the gate is the ``hormonal_profiles``
    ``cycle_sync_nutrition`` boolean, NOT the user's gender.

    Defensive by design: any error (missing table, malformed row, predictor
    failure) returns ``None`` so a cycle-tracking fault can never break the
    nutrition endpoints — it just degrades to the plain base targets.
    """
    try:
        profile_res = (
            client.table("hormonal_profiles")
            .select("cycle_sync_nutrition")
            .eq("user_id", str(user_id))
            .limit(1)
            .execute()
        )
        rows = profile_res.data or []
        if not rows:
            return None
        if not rows[0].get("cycle_sync_nutrition"):
            # The opt-in toggle is off (or NULL) — no cycle adjustment.
            return None

        # Lazy import keeps cycle_predictor out of the import graph for the
        # (overwhelmingly common) un-synced path.
        from services.cycle.cycle_predictor import predict_for_user

        prediction = predict_for_user(client, str(user_id), today)
        if not prediction.get("predictions_available"):
            # Symptom-only profile, pregnancy mode, or no period history.
            return None
        phase = prediction.get("current_phase")
        return phase if phase in _VALID_PHASES else None
    except Exception:
        # Never let a cycle fault break nutrition — degrade to base targets.
        return None
