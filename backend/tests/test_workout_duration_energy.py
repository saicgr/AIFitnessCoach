"""
Regression tests for E2E register #146: the same workout reported
45 MIN / 226 CAL, then later 11 MIN / 55 CAL — four unreconciled
duration/energy models. See api/v1/workouts/workout_duration_energy.py for
the full class writeup.
"""
from unittest.mock import MagicMock

from api.v1.workouts.workout_duration_energy import (
    DEFAULT_WEIGHT_KG,
    derive_duration_and_calories,
    estimate_duration_minutes,
    estimate_workout_calories,
    resolve_user_weight_kg,
)


# ---------------------------------------------------------------------------
# estimate_duration_minutes — the canonical duration model
# ---------------------------------------------------------------------------
def test_duration_uses_sets_times_work_plus_rest():
    exercises = [{"sets": 3, "rest_seconds": 60}]
    # 3 * (40 + 60) / 60 = 5.0
    assert estimate_duration_minutes(exercises) == 5


def test_duration_defaults_missing_fields():
    assert estimate_duration_minutes([{}]) == round(3 * 100 / 60.0)


def test_duration_floors_at_one_minute():
    assert estimate_duration_minutes([]) == 1


def test_duration_ignores_non_dict_entries():
    exercises = [{"sets": 3, "rest_seconds": 60}, "garbage", None]
    assert estimate_duration_minutes(exercises) == 5


# ---------------------------------------------------------------------------
# estimate_workout_calories — the canonical energy model
# ---------------------------------------------------------------------------
def test_calories_scale_with_duration_only_when_composition_fixed():
    """Pins the exact bug shape: same exercises/weight, only duration
    changes -> calories change in lockstep (this IS correct behavior for
    the formula; the BUG was that duration changed without the energy
    figure being recomputed and persisted through the SAME formula)."""
    exercises = [{"name": "Back Squat", "sets": 4, "reps": 8, "muscle_group": "legs"}]
    cal_45 = estimate_workout_calories(exercises, "strength", "medium", 45, 80)
    cal_11 = estimate_workout_calories(exercises, "strength", "medium", 11, 80)
    assert cal_45 > cal_11
    # Same implied kcal/min (same MET, same weight) — proportional to
    # duration, modulo integer-rounding noise at small minute counts.
    assert abs(cal_45 / 45 - cal_11 / 11) < 0.15


def test_calories_never_raises_on_string_reps():
    """Program-expanded exercises can carry a range string like '8-12' —
    this used to raise inside `_estimate_workout_met`'s sets*reps*weight
    arithmetic, which the outer try/except would mask as a silent 0. Assert
    a MEANINGFUL (non-zero, sanitizer-derived) estimate, not just "didn't
    crash" — a bare "no exception" assertion wouldn't catch a sanitizer
    regression that silently degrades every result to the except-block 0."""
    exercises = [{"name": "Bench Press", "sets": 3, "reps": "8-12", "weight_kg": 60}]
    result = estimate_workout_calories(exercises, "strength", "medium", 30, 80)
    assert isinstance(result, int)
    assert result > 0, "expected a real sanitized estimate, not the fail-open 0"


def test_calories_never_raises_on_garbage_input():
    """No exercises still yields a baseline-MET estimate (never invents a
    zero, matches _estimate_workout_met's own no-exercise default) — the
    contract is "never raises", not "returns zero"."""
    assert estimate_workout_calories(None, "strength", "medium", 30, 80) >= 0
    assert estimate_workout_calories("not-a-list", "strength", "medium", 30, 80) >= 0
    assert estimate_workout_calories([{"sets": "bad", "reps": None}], None, None, 30, None) >= 0


def test_calories_uses_weight_kg_field_when_weight_missing():
    """`_estimate_workout_met` reads `weight`; program-expanded exercises
    carry `weight_kg` instead — the sanitizer must bridge that."""
    light = [{"name": "Row", "sets": 3, "reps": 10, "weight_kg": 10}]
    heavy = [{"name": "Row", "sets": 3, "reps": 10, "weight_kg": 100}]
    cal_light = estimate_workout_calories(light, "strength", "medium", 30, 80)
    cal_heavy = estimate_workout_calories(heavy, "strength", "medium", 30, 80)
    assert cal_heavy >= cal_light


# ---------------------------------------------------------------------------
# derive_duration_and_calories — the combined entry point
# ---------------------------------------------------------------------------
def test_derive_uses_authored_duration_when_given():
    exercises = [{"sets": 3, "rest_seconds": 60}]
    duration, calories = derive_duration_and_calories(
        exercises, "strength", "medium", 80, duration_minutes=45
    )
    assert duration == 45
    assert calories == estimate_workout_calories(exercises, "strength", "medium", 45, 80)


def test_derive_derives_duration_when_omitted():
    exercises = [{"sets": 3, "rest_seconds": 60}]
    duration, calories = derive_duration_and_calories(exercises, "strength", "medium", 80)
    assert duration == estimate_duration_minutes(exercises)
    assert calories > 0


def test_derive_never_returns_null_calories_for_a_nonempty_workout():
    """The core E2E #146 guarantee: a program-expanded session with real
    exercises must never end up with estimated_calories = None."""
    exercises = [
        {"name": "Squat", "sets": 4, "reps": 8, "muscle_group": "legs"},
        {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest"},
    ]
    duration, calories = derive_duration_and_calories(exercises, "strength", "medium", 75)
    assert duration is not None
    assert calories is not None
    assert calories > 0


# ---------------------------------------------------------------------------
# resolve_user_weight_kg
# ---------------------------------------------------------------------------
def test_resolve_user_weight_kg_reads_weight_kg_column():
    db = MagicMock()
    db.client.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value.data = [
        {"weight_kg": 82.5, "weight": None}
    ]
    assert resolve_user_weight_kg(db, "user-1") == 82.5


def test_resolve_user_weight_kg_falls_back_to_default_on_error():
    db = MagicMock()
    db.client.table.side_effect = Exception("db down")
    assert resolve_user_weight_kg(db, "user-1") == DEFAULT_WEIGHT_KG


def test_resolve_user_weight_kg_clamps_absurd_values():
    db = MagicMock()
    db.client.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value.data = [
        {"weight_kg": 9999, "weight": None}
    ]
    assert resolve_user_weight_kg(db, "user-1") == 250.0
