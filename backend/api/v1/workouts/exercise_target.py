"""Single source of truth for how many exercises a workout should contain.

Before this module the count logic was duplicated in three places that could
(and did) drift apart:
  * `generation_endpoints.py` — `base_exercise_count` + `EXERCISE_CAPS` (the
    per-level desired count) and `HARD_FAIL_FLOOR = 1` (the persisted floor),
  * `generation_streaming.py` — its own copy of the cap table,
  * `validation_utils.cap_exercise_count_by_density` — the density ceiling.

The drift let a 60-min beginner workout legitimately target 7 exercises, then a
downstream filter cascade collapse it to 1, then ship because the only floor was
"reject literally zero". This module centralises three concepts:

  * `density_max(duration, workout_type)` — the hard upper bound (≈1 ex/7 min
    strength, 1 ex/4 min circuit, with short-session §E brackets),
  * `target_exercise_count(...)` — the number we AIM for,
  * `min_exercise_floor(...)` — the number below which a workout is considered
    *thin* and must be backfilled or explicitly degraded.

All three are duration- AND workout-type-aware so a 15-min quick session or a
mobility/recovery day floors lower than a 60-min strength day.

This module is import-safe (no dependency on the generation or validation
modules) so both can depend on it.
"""

from __future__ import annotations

from typing import Optional

# Circuit-style types run higher exercise density (shorter work, more moves).
_CIRCUIT_TYPES = frozenset(
    {"cardio", "hiit", "circuit", "metcon", "endurance"}
)

# Mobility / recovery days are correctly LESS dense — never force strength
# density onto them.
_LOW_DENSITY_TYPES = frozenset(
    {"mobility", "recovery", "stretch", "stretching", "yoga", "cooldown", "warmup"}
)

# Per-fitness-level desired-count ceilings by duration bracket. Lifted verbatim
# from generation_endpoints.py (Fix 7 / D4) so behaviour is identical.
EXERCISE_CAPS = {
    "beginner": {30: 5, 45: 6, 60: 7, 75: 7, 90: 8},
    "intermediate": {30: 5, 45: 7, 60: 8, 75: 9, 90: 10},
    "advanced": {30: 6, 45: 8, 60: 9, 75: 10, 90: 11},
}

HELL_MODE_EXERCISE_CAPS = {
    "beginner": {30: 5, 45: 6, 60: 6, 75: 7, 90: 7},
    "intermediate": {30: 6, 45: 7, 60: 8, 75: 9, 90: 10},
    "advanced": {30: 6, 45: 8, 60: 10, 75: 11, 90: 12},
}


def _duration_bracket(effective_duration: int) -> int:
    """Map a duration in minutes to the nearest cap-table bracket (30..90)."""
    if effective_duration <= 35:
        return 30
    if effective_duration <= 50:
        return 45
    if effective_duration <= 65:
        return 60
    if effective_duration <= 80:
        return 75
    return 90


def density_max(duration_minutes: Optional[int], workout_type: str = "strength") -> int:
    """Hard upper bound on exercise count for a duration + type.

    This is the §E density ceiling (the last-line-of-defence cap), preserved
    bracket-for-bracket from the original `cap_exercise_count_by_density` so
    re-pointing that function here is behaviour-preserving.
    """
    if not duration_minutes or duration_minutes <= 0:
        # No duration signal → permissive (callers apply their own target).
        return 99

    wt = (workout_type or "").lower()
    is_circuit = wt in _CIRCUIT_TYPES

    if duration_minutes <= 5:
        return 2
    if duration_minutes <= 10:
        return 3
    if duration_minutes <= 15:
        return 4 if is_circuit else 3
    if duration_minutes <= 20:
        return 5 if is_circuit else 4
    if duration_minutes <= 30:
        return 7 if is_circuit else 5
    # Ratio fallback for longer sessions.
    min_per_ex = 4.0 if is_circuit else 7.0
    return max(3, int(duration_minutes / min_per_ex))


def _base_exercise_count(effective_duration: int) -> int:
    """≈1 exercise / 6 min, clamped — matches generation_endpoints.py:592."""
    return max(3, min(12, effective_duration // 6 + 1))


def target_exercise_count(
    duration_minutes: Optional[int],
    fitness_level: Optional[str],
    workout_type: str = "strength",
    is_hell_mode: bool = False,
) -> int:
    """The number of exercises generation should AIM for.

    target = min(base-by-duration, per-level cap, density ceiling), and never
    below the floor. Identical maths to the original generation_endpoints.py
    block (lines 588-650) plus the density clamp.
    """
    effective = duration_minutes or 45
    base = _base_exercise_count(effective)

    level = (fitness_level or "intermediate").lower()
    cap_table = HELL_MODE_EXERCISE_CAPS if is_hell_mode else EXERCISE_CAPS
    level_caps = cap_table.get(level, cap_table["intermediate"])
    level_cap = level_caps.get(_duration_bracket(effective), 8)

    dmax = density_max(effective, workout_type)
    target = min(base, level_cap, dmax)

    floor = min_exercise_floor(duration_minutes, fitness_level, workout_type)
    return max(target, floor)


def min_exercise_floor(
    duration_minutes: Optional[int],
    fitness_level: Optional[str] = None,
    workout_type: str = "strength",
) -> int:
    """The count below which a workout is *thin* and must be fixed/degraded.

    Derived from the same density brackets so target and floor never disagree.
    Scales down for short sessions and mobility/recovery types; a normal
    strength session of 30+ min floors at 5 (4 for the shortest qualifying
    bracket), which is the real fix for the "1 exercise 60-min" bug.
    """
    if not duration_minutes or duration_minutes <= 0:
        return 3

    wt = (workout_type or "").lower()

    # Mobility / recovery: low density is correct — a couple of moves is fine.
    if wt in _LOW_DENSITY_TYPES:
        if duration_minutes <= 15:
            return 2
        return 3

    dmax = density_max(duration_minutes, workout_type)

    # Short sessions: floor just under the ceiling (min 2).
    if duration_minutes <= 15:
        return max(2, dmax - 1)
    if duration_minutes <= 20:
        return max(3, dmax - 1)
    if duration_minutes <= 30:
        return max(4, dmax - 1)

    # 30+ min strength/hypertrophy/etc.: a real session. Floor at 5, but never
    # above the density ceiling (keeps it sane for unusual type/duration combos).
    return min(5, dmax)
