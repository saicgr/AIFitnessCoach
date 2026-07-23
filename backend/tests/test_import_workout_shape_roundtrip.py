"""Regression: the share-funnel workout importer wrote the raw Flutter exercise
shape (reps as a range STRING like "8-12", equipment as a LIST) straight into
saved_workouts.exercises JSONB. That JSONB is read back as List[ExerciseTemplate]
(SavedWorkout(**row)), where reps is Optional[int] and equipment is Optional[str]
— so read-back raised ValidationError -> 500 for every imported workout.

These tests lock the fix at the ExerciseTemplate boundary (the single read-back
type) and through the shared _workout_ex_to_template mapper the importer now uses,
so what gets written always deserializes back with no error and the rep range is
preserved losslessly in reps_display.
"""

from datetime import datetime, timezone

import pytest

from models.saved_workouts import ExerciseTemplate, SavedWorkout
from api.v1.saved_workouts import _workout_ex_to_template


# A realistic reviewed-import payload as Flutter sends it: a rep range string,
# equipment as a list, and a timed hold whose reps are null.
FLUTTER_IMPORT_EXERCISES = [
    {
        "name": "Barbell Back Squat",
        "sets": 4,
        "reps": "8-12",                 # range STRING, not an int
        "equipment": ["barbell", "squat rack"],  # LIST, not a str
        "muscle_group": "legs",
    },
    {
        "name": "Plank",
        "sets": 3,
        "reps": None,                   # timed hold: no reps
        "hold_seconds": 45,
        "is_timed": True,
        "equipment": [],
    },
    {
        "name": "Dumbbell Lunge",
        "sets": 3,
        "reps": "12 each side",         # per-side cue the int can't hold
        "equipment": "dumbbell",        # already a str
    },
]


def test_exercise_template_accepts_range_string_and_equipment_list():
    """The exact shapes that used to 500 now construct, losslessly."""
    ex = ExerciseTemplate(**FLUTTER_IMPORT_EXERCISES[0])
    # reps coerced to the TOP of the range (progression targets the harder end)
    assert ex.reps == 12
    # the original range is preserved so it still renders as "8-12"
    assert ex.reps_display == "8-12"
    # equipment list joined into the canonical string, nothing dropped
    assert ex.equipment == "barbell, squat rack"


def test_exercise_template_timed_hold_reps_null():
    ex = ExerciseTemplate(**FLUTTER_IMPORT_EXERCISES[1])
    assert ex.reps is None
    assert ex.reps_display is None      # nothing to gloss
    assert ex.hold_seconds == 45
    assert ex.equipment is None         # empty list -> None, not ""


def test_exercise_template_per_side_reps_string():
    ex = ExerciseTemplate(**FLUTTER_IMPORT_EXERCISES[2])
    assert ex.reps == 12                # leading number extracted
    assert ex.reps_display == "12 each side"   # per-side cue preserved
    assert ex.equipment == "dumbbell"   # plain str untouched


def test_single_number_string_needs_no_display():
    ex = ExerciseTemplate(name="Curl", reps="8")
    assert ex.reps == 8
    assert ex.reps_display is None      # int fully captures "8"


def test_non_numeric_reps_is_unknown_but_preserved():
    ex = ExerciseTemplate(name="Burpees", reps="AMRAP")
    assert ex.reps is None              # honestly "unknown" as an int
    assert ex.reps_display == "AMRAP"   # original still shown


def test_mapper_produces_revalidatable_dict():
    """_workout_ex_to_template must return a dict that re-validates without error
    (it is what gets written to JSONB)."""
    for raw in FLUTTER_IMPORT_EXERCISES:
        d = _workout_ex_to_template(raw)
        # round-trips through the model with no ValidationError
        ex = ExerciseTemplate.model_validate(d)
        assert ex.name == raw["name"]


def test_full_saved_workout_roundtrip_no_500():
    """Simulate the whole write->read path: normalize the import (as the endpoint
    now does), store as JSONB, then read the row back as SavedWorkout — which
    coerces each dict into ExerciseTemplate. This is the exact step that 500'd."""
    normalized = [
        _workout_ex_to_template(ex)
        for ex in FLUTTER_IMPORT_EXERCISES
        if ex.get("name")
    ]

    # This dict mirrors a saved_workouts row as read back from Postgres.
    row = {
        "id": "00000000-0000-0000-0000-000000000001",
        "user_id": "11111111-1111-1111-1111-111111111111",
        "workout_name": "Imported Leg Day",
        "workout_description": "Imported from a shared link",
        "exercises": normalized,        # JSONB list of dicts
        "total_exercises": len(normalized),
        "folder": "Imported",
        "tags": ["imported", "share_funnel"],
        "times_completed": 0,
        "saved_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }

    saved = SavedWorkout(**row)          # <- used to raise ValidationError (500)

    assert len(saved.exercises) == 3
    assert all(isinstance(e, ExerciseTemplate) for e in saved.exercises)
    # range preserved end to end
    squat = saved.exercises[0]
    assert squat.reps == 12
    assert squat.reps_display == "8-12"
    assert squat.equipment == "barbell, squat rack"
    # timed hold survived
    assert saved.exercises[1].reps is None
    assert saved.exercises[1].hold_seconds == 45


def test_reps_display_not_clobbered_when_producer_sets_it():
    ex = ExerciseTemplate(name="Squat", reps="8-12", reps_display="8 to 12 reps")
    assert ex.reps == 12
    assert ex.reps_display == "8 to 12 reps"
