"""
Unit tests for services.exercise_tracking_metric.derive_tracking_metadata.

Pure-function tests — no DB, no HTTP. Covers the HYROX/functional stations the
distance + cardio tracker must classify correctly, plus the string parsers.

Run with: pytest backend/tests/test_exercise_tracking_metric.py -v
"""
import pytest

from services.exercise_tracking_metric import (
    derive_tracking_metadata,
    parse_distance_meters,
    parse_duration_seconds,
    attach_tracking_metadata,
    TRACK_WEIGHT,
    TRACK_BODYWEIGHT,
    TRACK_TIME,
    TRACK_DISTANCE,
)


# ---------------------------------------------------------------------------
# Distance string parser
# ---------------------------------------------------------------------------
@pytest.mark.parametrize("text,expected", [
    ("1000 m", 1000.0),
    ("1000m", 1000.0),
    ("200m", 200.0),
    ("50 m", 50.0),
    ("1 km", 1000.0),
    ("1.5 km", 1500.0),
    ("1km", 1000.0),
    ("400 yards", 365.76),
    ("1 mile", 1609.34),
    ("8 minutes", None),   # duration, not distance
    ("100 reps", None),
    ("12", None),          # bare number is ambiguous
    (12, None),
    (None, None),
])
def test_parse_distance_meters(text, expected):
    assert parse_distance_meters(text) == expected


# ---------------------------------------------------------------------------
# Duration string parser
# ---------------------------------------------------------------------------
@pytest.mark.parametrize("text,expected", [
    ("8 minutes", 480),
    ("8 min", 480),
    ("2 min", 120),
    ("30s", 30),
    ("45s hold", 45),
    ("30 sec", 30),
    ("90 seconds", 90),
    ("1 hour", 3600),
    ("1000 m", None),   # distance, not duration
    ("1000m", None),
    ("100 reps", None),
    (None, None),
])
def test_parse_duration_seconds(text, expected):
    assert parse_duration_seconds(text) == expected


# ---------------------------------------------------------------------------
# derive_tracking_metadata — the station matrix from the task contract
# ---------------------------------------------------------------------------
def test_skierg_distance_1000():
    meta = derive_tracking_metadata({"name": "SkiErg", "reps": "1000 m"})
    assert meta["tracking_type"] == TRACK_DISTANCE
    assert meta["distance_meters"] == 1000.0


def test_sled_push_distance_50():
    meta = derive_tracking_metadata({"name": "Sled Push", "reps": "50 m"})
    assert meta["tracking_type"] == TRACK_DISTANCE
    assert meta["distance_meters"] == 50.0


def test_farmers_carry_distance_by_name_no_target():
    # Name alone classifies as distance even when the unit was destroyed.
    meta = derive_tracking_metadata({"name": "Farmers Carry", "reps": "100"})
    assert meta["tracking_type"] == TRACK_DISTANCE
    assert meta["distance_meters"] is None


def test_rowerg_distance_with_duration_amrap():
    meta = derive_tracking_metadata({"name": "RowErg", "reps": "8 minutes"})
    # A timed row is still a distance station for the primary metric, but we
    # surface the duration too.
    assert meta["tracking_type"] == TRACK_DISTANCE
    assert meta["duration_seconds"] == 480


def test_plank_hold_time():
    meta = derive_tracking_metadata({"name": "Plank Hold", "reps": "45s hold"})
    assert meta["tracking_type"] == TRACK_TIME
    assert meta["duration_seconds"] == 45
    assert meta["hold_seconds"] == 45


def test_wall_sit_time_via_is_timed_flag():
    meta = derive_tracking_metadata(
        {"name": "Wall Sit", "is_timed": True, "hold_seconds": 60}
    )
    assert meta["tracking_type"] == TRACK_TIME
    assert meta["duration_seconds"] == 60
    assert meta["hold_seconds"] == 60


def test_burpees_bodyweight():
    meta = derive_tracking_metadata({"name": "Burpees", "reps": "15"})
    assert meta["tracking_type"] == TRACK_BODYWEIGHT


def test_wall_balls_bodyweight():
    meta = derive_tracking_metadata({"name": "Wall Balls", "reps": "20"})
    assert meta["tracking_type"] == TRACK_BODYWEIGHT


def test_burpee_broad_jump_is_distance():
    # "broad jump" wins -> distance (horizontal jump measured by distance).
    meta = derive_tracking_metadata({"name": "Burpee Broad Jumps", "reps": "10"})
    assert meta["tracking_type"] == TRACK_DISTANCE


def test_back_squat_weight():
    meta = derive_tracking_metadata({"name": "Back Squat", "reps": "5"})
    assert meta["tracking_type"] == TRACK_WEIGHT
    assert meta["distance_meters"] is None


def test_bodyweight_equipment_rep_based():
    meta = derive_tracking_metadata(
        {"name": "Some New Move", "equipment": "bodyweight", "reps": "12"}
    )
    assert meta["tracking_type"] == TRACK_BODYWEIGHT


def test_library_meta_takes_precedence_for_carry_pattern():
    # Canonical metadata (movement_pattern=carry) classifies as distance even
    # when the name is unfamiliar.
    meta = derive_tracking_metadata(
        {"name": "Heavy Object Walk", "reps": "40 m"},
        library_meta={"movement_pattern": "carry"},
    )
    assert meta["tracking_type"] == TRACK_DISTANCE
    assert meta["distance_meters"] == 40.0


def test_reps_spec_structured_dict_rendered():
    # A structured reps_spec dict (program path) is rendered to a raw string
    # and parsed for distance.
    meta = derive_tracking_metadata(
        {"name": "SkiErg", "reps_spec": {"kind": "freeform", "raw": "1000 m"}}
    )
    assert meta["tracking_type"] == TRACK_DISTANCE
    assert meta["distance_meters"] == 1000.0
    assert meta["reps_spec"] == "1000 m"


# ---------------------------------------------------------------------------
# attach_tracking_metadata — in-place applier used at serve-time
# ---------------------------------------------------------------------------
def test_attach_in_place_sets_fields():
    exercises = [
        {"name": "SkiErg", "reps": "1000 m"},
        {"name": "Back Squat", "reps": "5", "reps_spec": {"kind": "range", "min": 5, "max": 8}},
        "not-a-dict",
    ]
    attach_tracking_metadata(exercises)
    assert exercises[0]["tracking_type"] == TRACK_DISTANCE
    assert exercises[0]["distance_meters"] == 1000.0
    assert exercises[0]["reps_spec"] == "1000 m"
    assert exercises[1]["tracking_type"] == TRACK_WEIGHT
    # Structured reps_spec dict is stringified for the frontend at serve time.
    assert exercises[1]["reps_spec"] == "5-8"
    assert exercises[2] == "not-a-dict"  # untouched


def test_attach_does_not_clobber_existing_duration():
    ex = {"name": "Plank Hold", "reps": "45s", "duration_seconds": 99}
    attach_tracking_metadata([ex])
    assert ex["duration_seconds"] == 99  # real value preserved
