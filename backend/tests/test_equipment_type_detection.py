"""Tests for `core.weight_utils.detect_equipment_type` after the bodyweight
default fix (Fix 3 in plan peppy-conjuring-valley).

Prior bug: any exercise without a recognized equipment keyword fell through to
`return "dumbbell"`, resulting in 93% of bodyweight exercises being tagged as
dumbbell-equipped (wrong starting-weight calc, wrong increment unit, wrong UI).
"""
from core.weight_utils import detect_equipment_type


def test_bodyweight_movements_detected():
    """Calisthenics names with no implement keyword resolve to bodyweight."""
    assert detect_equipment_type("Burpee", []) == "bodyweight"
    assert detect_equipment_type("Frog Jump", []) == "bodyweight"
    assert detect_equipment_type("Star Jump", []) == "bodyweight"
    assert detect_equipment_type("Walkout", []) == "bodyweight"
    assert detect_equipment_type("Bear Crawl", []) == "bodyweight"
    assert detect_equipment_type("Mountain Climber", []) == "bodyweight"
    assert detect_equipment_type("Wall Sit", []) == "bodyweight"
    assert detect_equipment_type("Plank", []) == "bodyweight"
    assert detect_equipment_type("Air Squat", []) == "bodyweight"
    assert detect_equipment_type("Bodyweight Squat", []) == "bodyweight"


def test_bodyweight_overrides_user_equipment_list():
    """A 'Burpee' on a barbell-equipped user is still bodyweight — the
    movement determines the implement, not the user's owned gear."""
    assert detect_equipment_type("Burpee", ["barbell"]) == "bodyweight"
    assert detect_equipment_type("Mountain Climber",
                                  ["barbell", "dumbbells"]) == "bodyweight"


def test_implement_keywords_still_win():
    """Regression: real implement keywords are still detected correctly."""
    assert detect_equipment_type("Cable Row", ["cable_machine"]) == "cable"
    assert detect_equipment_type("Dumbbell One Arm Snatch", []) == "dumbbell"
    assert detect_equipment_type("Barbell Back Squat", []) == "barbell"
    assert detect_equipment_type("Kettlebell Swing", []) == "kettlebell"
    # NOTE: "Smith Machine Squat" currently returns "machine" not "smith_machine"
    # because the keyword loop has "machine" listed before "smith" in
    # weight_utils.py:200-201. Pre-existing bug, out of scope for Fix 3.
    assert detect_equipment_type("Smith Machine Squat", []) == "machine"


def test_unknown_movement_defaults_to_bodyweight():
    """The conservative default for unknown movements is bodyweight, not
    dumbbell — bodyweight has no weight-calc consequences, so it's the
    safer fallback when the detector has no signal."""
    assert detect_equipment_type("Random Made Up Movement", []) == "bodyweight"
    assert detect_equipment_type("", []) == "bodyweight"


def test_user_equipment_list_bodyweight_token():
    """If user's equipment_list contains 'bodyweight' / 'none', that's
    enough to resolve to bodyweight even when the name has no signal."""
    assert detect_equipment_type("Random Movement", ["bodyweight"]) == "bodyweight"
    assert detect_equipment_type("Random Movement", ["none"]) == "bodyweight"
    assert detect_equipment_type("Random Movement", ["body_weight"]) == "bodyweight"


def test_user_equipment_list_fallback_to_dumbbell_only_when_no_bw():
    """When equipment_list has dumbbells (and no bodyweight token) and the
    movement is genuinely ambiguous, falling back to dumbbell is OK."""
    # 'foo bar' has no keyword and no bodyweight token in user list.
    # User has dumbbells → infer dumbbell.
    assert detect_equipment_type("foo bar", ["dumbbells"]) == "dumbbell"
