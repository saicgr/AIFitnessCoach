"""Canonical training-goal normalization for RIR/RPE prescription.

WHY THIS EXISTS (bug fix, 2026-07-14)
-------------------------------------
"Fix 7 / D2" introduced goal-aware RIR ramps in two places:

  * services/exercise_rag/formatting.py :: _build_set_targets
  * services/gemini/utils.py            :: apply_goal_aware_rir_override

Both keyed their ramp table on goal strings like ``hypertrophy``,
``muscle_gain``, ``fat_loss`` and ``endurance``. But the goal strings the
mobile app actually stores and sends are the ONBOARDING values —
``build_muscle``, ``lose_weight``, ``lose_fat``, ``increase_strength``,
``improve_endurance``, ``athletic_performance``. NONE of those matched a key.

Consequences in production (both generation paths):
  * exercise_rag fell through to the legacy ``[2, 1, 0, ...]`` ramp, so the
    3rd working set was RIR 0 -> ``set_type="failure"`` — for EVERY user,
    including beginners.
  * gemini's override returned the exercise list UNCHANGED (``ramp is None``),
    leaving Gemini's raw mechanical 2->1->0 to-failure ramp in place.

i.e. the entire "stop pushing every workout to failure" fix was dead code for
every real goal the product ships. This module is the single chokepoint that
maps any goal spelling onto a canonical goal so both call sites stay in sync.
"""
from typing import Dict, List, Optional

# Canonical goal -> working-set RIR ramp. Index = 0-based working-set ordinal.
# Values are "reps in reserve": lower = closer to failure. RIR 0 == failure.
RIR_RAMP_BY_CANONICAL_GOAL: Dict[str, List[int]] = {
    "strength":    [3, 2, 1, 1, 1],
    "power":       [3, 2, 1, 1, 1],
    "hypertrophy": [2, 1, 1, 1, 1],
    "endurance":   [3, 3, 2, 2, 2],
    "fat_loss":    [3, 2, 1, 1, 1],
    "general":     [3, 2, 2, 2, 2],
}

# Goals for which RIR/RPE is not a meaningful construct.
MOBILITY_GOALS = {"mobility", "recovery"}

# Every goal spelling the product has ever produced -> canonical goal.
# Onboarding values (mobile/flutter/lib/screens/onboarding) are the ones that
# actually reach the backend; the bare canonical names are kept so existing
# callers/tests that already pass e.g. "hypertrophy" keep working.
_GOAL_ALIASES: Dict[str, str] = {
    # --- muscle growth ---
    "build_muscle": "hypertrophy",
    "gain_muscle": "hypertrophy",
    "muscle_gain": "hypertrophy",
    "hypertrophy": "hypertrophy",
    "build_muscle_mass": "hypertrophy",
    "tone_up": "hypertrophy",
    # --- strength ---
    "increase_strength": "strength",
    "gain_strength": "strength",
    "get_stronger": "strength",
    "strength": "strength",
    # --- power / athletic ---
    "athletic_performance": "power",
    "sports_performance": "power",
    "power": "power",
    # --- fat loss ---
    "lose_weight": "fat_loss",
    "lose_fat": "fat_loss",
    "weight_loss": "fat_loss",
    "fat_loss": "fat_loss",
    # --- endurance ---
    "improve_endurance": "endurance",
    "endurance": "endurance",
    "cardio": "endurance",
    "improve_stamina": "endurance",
    # --- general ---
    "general_fitness": "general",
    "improve_health": "general",
    "stay_healthy": "general",
    "general": "general",
}


def canonicalize_goal(goal: Optional[str]) -> Optional[str]:
    """Map any goal spelling onto a canonical goal.

    Returns None when the goal is empty/unknown so callers can decide their
    own fallback. Mobility goals are returned as-is (they are handled by a
    separate no-RIR code path, not by a ramp).
    """
    if not goal:
        return None
    normalized = goal.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized in MOBILITY_GOALS:
        return normalized
    return _GOAL_ALIASES.get(normalized)


def get_rir_ramp(goals: Optional[List[str]]) -> Optional[List[int]]:
    """Resolve the working-set RIR ramp for a user's primary goal.

    Returns None for mobility/recovery goals (no RIR construct) so the caller
    can take its dedicated path. Unknown goals fall back to the conservative
    "general" ramp rather than the old to-failure default — an unrecognized
    goal must never be the reason a user gets trained to failure.
    """
    primary = goals[0] if goals else None
    canonical = canonicalize_goal(primary)
    if canonical is None:
        return RIR_RAMP_BY_CANONICAL_GOAL["general"]
    if canonical in MOBILITY_GOALS:
        return None
    return RIR_RAMP_BY_CANONICAL_GOAL[canonical]


def is_mobility_goal(goals: Optional[List[str]]) -> bool:
    """True when the primary goal is mobility/recovery (no RIR/RPE)."""
    primary = goals[0] if goals else None
    return canonicalize_goal(primary) in MOBILITY_GOALS


# --- Fitness-level intensity ceiling -----------------------------------------
#
# The product's own cached system prompt (services/gemini/cache_management.py,
# "## DIFFICULTY SCALING BY FITNESS LEVEL") specifies an RPE band per level:
#
#     Beginner      RPE 5-7    "Focus: Form and technique"
#     Intermediate  RPE 7-8    "Focus: Progressive overload"
#     Advanced      RPE 8-10   "Focus: Intensity techniques (drops, failure)"
#
# The goal-aware RIR ramps ignored fitness level entirely, so they overwrote the
# level-appropriate RPE the model had been instructed to produce — prescribing
# RPE 9 (and, before the goal-alias fix, RPE 10 / failure sets) to beginners.
# Since RPE = 10 - RIR, an RPE ceiling is a RIR *floor*. Advanced has no floor:
# failure work is explicitly sanctioned for them.
MIN_RIR_BY_FITNESS_LEVEL: Dict[str, int] = {
    "beginner": 3,      # RPE <= 7
    "intermediate": 2,  # RPE <= 8
    "advanced": 0,      # RPE <= 10 — failure sets permitted
}


def apply_fitness_level_rir_floor(target_rir: int, fitness_level: Optional[str]) -> int:
    """Raise `target_rir` to the minimum reps-in-reserve allowed for the level.

    Enforces the documented per-level RPE ceiling. Unknown/absent levels are
    treated as intermediate — the same default the rest of the generation
    pipeline uses — rather than left unclamped.
    """
    if fitness_level is None:
        return target_rir
    level = fitness_level.strip().lower()
    floor = MIN_RIR_BY_FITNESS_LEVEL.get(level, MIN_RIR_BY_FITNESS_LEVEL["intermediate"])
    return max(target_rir, floor)
