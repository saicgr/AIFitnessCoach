"""Tests for `services.exercise_rag.utils.canonicalize_exercise_name`.

Style guide: peppy-conjuring-valley.md Fix 12.
"""
from services.exercise_rag.utils import canonicalize_exercise_name


def test_idempotent_on_canonical_names():
    """Already-canonical names pass through unchanged."""
    for n in [
        "Barbell Back Squat",
        "Single-Arm Dumbbell Row",
        "Romanian Deadlift",
        "Bench Press",
        "Pull-Up",
        "Burpee",
    ]:
        assert canonicalize_exercise_name(n) == n


def test_hyphenation_compounds():
    assert canonicalize_exercise_name("pull up") == "Pull-Up"
    assert canonicalize_exercise_name("Push Up") == "Push-Up"
    assert canonicalize_exercise_name("chin up") == "Chin-Up"
    assert canonicalize_exercise_name("Sit Up") == "Sit-Up"
    assert canonicalize_exercise_name("Step Up") == "Step-Up"
    assert canonicalize_exercise_name("Single Arm Dumbbell Row") == "Single-Arm Dumbbell Row"
    assert canonicalize_exercise_name("One Arm Snatch") == "Single-Arm Snatch"
    assert canonicalize_exercise_name("Bent Over Barbell Row") == "Bent-Over Barbell Row"


def test_explicit_rename_map():
    assert canonicalize_exercise_name("Wall Sit Bodyweight") == "Wall Sit"
    assert canonicalize_exercise_name("Frog Jumps") == "Frog Jump"
    assert canonicalize_exercise_name("Mountain Climbers") == "Mountain Climber"
    assert canonicalize_exercise_name("Mountain Climber Jumps") == "Mountain Climber Jump"
    assert canonicalize_exercise_name("Half Burpees") == "Half Burpee"
    assert canonicalize_exercise_name("Bodyweight Squat") == "Air Squat"
    assert canonicalize_exercise_name("Climber A Padded Stool Supported") == \
        "Stool-Supported Mountain Climber"


def test_blocklist_returns_empty():
    """Anatomy posters return empty so caller can drop them."""
    assert canonicalize_exercise_name("Major Groups Muscle Body") == ""


def test_strips_filename_artifacts():
    assert canonicalize_exercise_name("Burpee  ") == "Burpee"  # trailing ws
    assert canonicalize_exercise_name("Burpee_Female") == "Burpee"
    assert canonicalize_exercise_name("Push-Up_male") == "Push-Up"
    assert canonicalize_exercise_name("Squat (VERSION 2)") == "Squat"
    assert canonicalize_exercise_name("Deadlift (front POV)") == "Deadlift"


def test_small_connectors_lowercased_mid_name():
    """`with`, `to`, `and` etc. stay lowercase mid-name (Title Case style)."""
    assert canonicalize_exercise_name("Kettlebell Sumo Deadlift With High Pull") == \
        "Kettlebell Sumo Deadlift High Pull"  # via rename map
    assert canonicalize_exercise_name("Deadlift And Press") == "Deadlift and Press"
    assert canonicalize_exercise_name("Lunge To Press") == "Lunge to Press"


def test_empty_input_safe():
    assert canonicalize_exercise_name("") == ""
    assert canonicalize_exercise_name(None) == ""  # type: ignore[arg-type]


def test_idempotency_under_repeat():
    """Applying twice yields the same result as applying once."""
    samples = [
        "pull up",
        "Mountain Climbers",
        "Single Arm Dumbbell Row",
        "Burpee_Female",
        "Major Groups Muscle Body",
    ]
    for s in samples:
        once = canonicalize_exercise_name(s)
        twice = canonicalize_exercise_name(once or "")
        assert once == twice, f"non-idempotent: {s!r} → {once!r} → {twice!r}"
