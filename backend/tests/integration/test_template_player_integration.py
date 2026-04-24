"""
Deep-integration tests for the creator-program template player.

Patches the two inner helpers (_load_template_row + _fetch_user_current_1rms)
so we can exercise the real resolution logic without a live DB — hitting the
percent_tm math, Wendler training_max_factor, rounding to plate multiples, and
the None-when-no-active contract.
"""
from __future__ import annotations

from unittest.mock import patch
from uuid import uuid4

import pytest


def _wendler_template_row(user_id, squat_1rm_kg=140):
    """Minimal Wendler-style template row matching the schema written by
    services.workout_import.canonical.CanonicalProgramTemplate.to_supabase_row.
    """
    return {
        "id": str(uuid4()),
        "user_id": str(user_id),
        "source_app": "wendler_531",
        "program_name": "5/3/1 Boring But Big",
        "program_creator": "Jim Wendler",
        "total_weeks": 4,
        "days_per_week": 4,
        "unit_hint": "kg",
        # Snapshot keys match template_player._REF_TO_SNAPSHOT_KEY —
        # "back_squat" maps to "squat_kg" (not "back_squat_kg").
        "one_rm_inputs": {"squat_kg": squat_1rm_kg},
        "rounding_multiple_kg": 2.5,
        "training_max_factor": 0.9,
        "active": True,
        "current_week": 1,
        "current_day": 1,
        "raw_prescription": {
            "weeks": [
                {
                    "week_number": 1,
                    "days": [
                        {
                            "day_number": 1,
                            "day_label": "Squat Day",
                            "exercises": [
                                {
                                    "order": 1,
                                    "exercise_name_raw": "Back Squat",
                                    "exercise_name_canonical": "barbell_back_squat",
                                    "warmup_set_count": 0,
                                    "superset_id": None,
                                    "sets": [
                                        {
                                            "order": 1,
                                            "set_type": "working",
                                            "rep_target": {"min": 5, "max": 5, "amrap_last": False},
                                            "load_prescription": {
                                                "kind": "percent_tm",
                                                "value_min": 0.65,
                                                "value_max": 0.65,
                                                "reference_1rm_exercise": "back_squat",
                                            },
                                            "rpe_target": None,
                                            "rir_target": None,
                                        },
                                        {
                                            "order": 2,
                                            "set_type": "working",
                                            "rep_target": {"min": 5, "max": 5, "amrap_last": False},
                                            "load_prescription": {
                                                "kind": "percent_tm",
                                                "value_min": 0.75,
                                                "value_max": 0.75,
                                                "reference_1rm_exercise": "back_squat",
                                            },
                                            "rpe_target": None,
                                            "rir_target": None,
                                        },
                                        {
                                            "order": 3,
                                            "set_type": "amrap",
                                            "rep_target": {"min": 5, "max": 20, "amrap_last": True},
                                            "load_prescription": {
                                                "kind": "percent_tm",
                                                "value_min": 0.85,
                                                "value_max": 0.85,
                                                "reference_1rm_exercise": "back_squat",
                                            },
                                            "rpe_target": None,
                                            "rir_target": None,
                                        },
                                    ],
                                }
                            ],
                        }
                    ],
                }
            ]
        },
    }


def _nippard_template_row(user_id, bench_1rm_kg=100):
    """Non-Wendler template — training_max_factor=1.0, percent_1rm (not _tm)."""
    return {
        "id": str(uuid4()),
        "user_id": str(user_id),
        "source_app": "nippard_powerbuilding_v3",
        "program_name": "Nippard Powerbuilding v3",
        "program_creator": "Jeff Nippard",
        "total_weeks": 12,
        "days_per_week": 5,
        "unit_hint": "kg",
        "one_rm_inputs": {"bench_kg": bench_1rm_kg},
        "rounding_multiple_kg": 2.5,
        "training_max_factor": 1.0,
        "active": True,
        "current_week": 1,
        "current_day": 1,
        "raw_prescription": {
            "weeks": [{
                "week_number": 1,
                "days": [{
                    "day_number": 1,
                    "day_label": "Upper Push",
                    "exercises": [{
                        "order": 1,
                        "exercise_name_raw": "Bench Press",
                        "exercise_name_canonical": "barbell_bench_press",
                        "warmup_set_count": 0,
                        "superset_id": None,
                        "sets": [{
                            "order": 1,
                            "set_type": "working",
                            "rep_target": {"min": 5, "max": 5, "amrap_last": False},
                            "load_prescription": {
                                "kind": "percent_1rm",
                                "value_min": 0.80,
                                "value_max": 0.80,
                                "reference_1rm_exercise": "barbell_bench_press",
                            },
                            "rpe_target": None,
                            "rir_target": None,
                        }],
                    }],
                }],
            }]
        },
    }


def _get_set_weights(workout):
    """Extract the list of prescribed weights across every set in a
    GeneratedWorkoutResponse shape-agnostic."""
    weights: list[float] = []
    # Try the standard shape: workout.exercises[*].setTargets[*].targetWeightKg
    exercises = getattr(workout, "exercises", None)
    if exercises is None and isinstance(workout, dict):
        exercises = workout.get("exercises")
    for ex in exercises or []:
        targets = getattr(ex, "setTargets", None) or getattr(ex, "set_targets", None)
        if targets is None and isinstance(ex, dict):
            targets = ex.get("setTargets") or ex.get("set_targets") or ex.get("sets")
        for t in targets or []:
            w = (
                getattr(t, "targetWeightKg", None)
                or getattr(t, "target_weight_kg", None)
                or (isinstance(t, dict) and (t.get("targetWeightKg") or t.get("target_weight_kg") or t.get("weight_kg")))
            )
            if w is not None:
                weights.append(float(w))
    return weights


@pytest.mark.asyncio
async def test_no_active_template_returns_none():
    """Absence of a template is not an error — None signals 'fall through'."""
    from services.workout_generation import template_player

    with patch.object(template_player, "_load_template_row", return_value=None):
        result = await template_player.plan_workout_from_template(user_id=uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_wendler_percent_tm_with_rounding():
    """TM = 140 × 0.9 = 126 kg. 65% × 126 = 81.9 → round(2.5) = 82.5.
    75% × 126 = 94.5 (already on the step). 85% × 126 = 107.1 → 107.5.
    """
    from services.workout_generation import template_player

    user_id = uuid4()
    tpl = _wendler_template_row(user_id, squat_1rm_kg=140)

    with patch.object(template_player, "_load_template_row", return_value=tpl), \
         patch.object(template_player, "_fetch_user_current_1rms",
                      return_value={"back_squat": 140.0}):
        workout = await template_player.plan_workout_from_template(user_id=user_id)

    assert workout is not None, "Wendler template should materialize a workout"
    weights = _get_set_weights(workout)
    assert len(weights) == 3, f"expected 3 working sets, got {weights}"
    # Allow 0.1 kg tolerance for floating-point; check the 2.5-kg grid.
    assert abs(weights[0] - 82.5) < 0.1, weights
    assert abs(weights[1] - 94.5) < 0.1 or abs(weights[1] - 95.0) < 0.1, weights
    assert abs(weights[2] - 107.5) < 0.1, weights


@pytest.mark.asyncio
async def test_nippard_percent_1rm_no_tm_factor():
    """Non-Wendler: 80% × 100 kg = 80 kg (no 0.9 factor). Rounds to 80.0."""
    from services.workout_generation import template_player

    user_id = uuid4()
    tpl = _nippard_template_row(user_id, bench_1rm_kg=100)

    with patch.object(template_player, "_load_template_row", return_value=tpl), \
         patch.object(template_player, "_fetch_user_current_1rms",
                      return_value={"barbell_bench_press": 100.0}):
        workout = await template_player.plan_workout_from_template(user_id=user_id)

    assert workout is not None
    weights = _get_set_weights(workout)
    assert len(weights) == 1
    # 100 × 1.0 × 0.80 = 80.0, snapped to 2.5 grid = 80.0.
    assert abs(weights[0] - 80.0) < 0.1, weights


@pytest.mark.asyncio
async def test_live_1rm_overrides_snapshot():
    """When strength_records has a live 1RM, it takes priority over the
    snapshot baked into the template at import time (#59 stale TM/1RM guard).
    """
    from services.workout_generation import template_player

    user_id = uuid4()
    # Snapshot says 140 kg, but the user has since hit a new PR of 160.
    tpl = _wendler_template_row(user_id, squat_1rm_kg=140)

    with patch.object(template_player, "_load_template_row", return_value=tpl), \
         patch.object(template_player, "_fetch_user_current_1rms",
                      return_value={"back_squat": 160.0}):
        workout = await template_player.plan_workout_from_template(user_id=user_id)

    assert workout is not None
    weights = _get_set_weights(workout)
    # TM = 160 × 0.9 = 144 kg. 65% × 144 = 93.6 → round to 92.5 or 95.0.
    # 85% × 144 = 122.4 → 122.5.
    assert weights[0] > 90.0, f"expected ~92.5kg with live 160kg 1RM, got {weights[0]}"
    assert abs(weights[-1] - 122.5) < 0.1, \
        f"expected 122.5kg for 85% of 144kg TM, got {weights[-1]}"


@pytest.mark.asyncio
async def test_snapshot_fallback_when_strength_records_empty():
    """User imported the template but hasn't logged any lifts in-app yet —
    fall back to the one_rm_inputs snapshot so day-1 still works."""
    from services.workout_generation import template_player

    user_id = uuid4()
    tpl = _wendler_template_row(user_id, squat_1rm_kg=140)

    with patch.object(template_player, "_load_template_row", return_value=tpl), \
         patch.object(template_player, "_fetch_user_current_1rms",
                      return_value={}):  # empty — no live history yet
        workout = await template_player.plan_workout_from_template(user_id=user_id)

    assert workout is not None, "snapshot fallback should kick in"
    weights = _get_set_weights(workout)
    # Same math as test_wendler_percent_tm_with_rounding — snapshot=140.
    assert abs(weights[0] - 82.5) < 0.1


@pytest.mark.asyncio
async def test_week_day_overrides():
    """Explicit week/day args override the template's current_week/current_day
    pointers, letting the workout generator serve up any specific session."""
    from services.workout_generation import template_player

    user_id = uuid4()
    tpl = _wendler_template_row(user_id)

    with patch.object(template_player, "_load_template_row", return_value=tpl), \
         patch.object(template_player, "_fetch_user_current_1rms",
                      return_value={"back_squat": 140.0}):
        # Only week 1 day 1 exists in our fixture. Out-of-range day wraps to
        # day 1 of the requested week per the player's fallback logic.
        workout = await template_player.plan_workout_from_template(
            user_id=user_id, week=1, day=99
        )

    assert workout is not None, "out-of-range day should wrap to day 1"
    weights = _get_set_weights(workout)
    assert len(weights) == 3


@pytest.mark.asyncio
async def test_malformed_prescription_returns_none():
    """Empty weeks array is not an error — return None and let AI take over."""
    from services.workout_generation import template_player

    user_id = uuid4()
    tpl = _wendler_template_row(user_id)
    tpl["raw_prescription"] = {"weeks": []}

    with patch.object(template_player, "_load_template_row", return_value=tpl):
        result = await template_player.plan_workout_from_template(user_id=user_id)

    assert result is None
