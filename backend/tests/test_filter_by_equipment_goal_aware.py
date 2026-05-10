"""Tests for goal-aware bodyweight gating in `filter_by_equipment` (Fix 2).

Pre-fix behavior: any bodyweight-tagged exercise was eligible for every
user. Audit found 70% of returned exercises in weighted-equipment scenarios
were bodyweight (Burpee / Frog Jump / Mountain Climber Jump) — see
peppy-conjuring-valley.md Fix 2 / B1.
"""
from services.exercise_rag.filters import (
    filter_by_equipment,
    is_strength_appropriate_bodyweight,
    is_plyometric,
)


def test_bodyweight_only_user_unaffected():
    """A bw-only user still gets every bw-tagged exercise. Behavior preserved."""
    assert filter_by_equipment(
        "Bodyweight", ["bodyweight"], "Burpee", goals=["strength"]
    ) is True
    assert filter_by_equipment(
        "Bodyweight", [], "Push-Up", goals=["strength"]
    ) is True


def test_equipped_strength_user_blocks_generic_bodyweight():
    """A user with weighted equipment and a strength goal should NOT receive
    generic bodyweight exercises like Burpee."""
    assert filter_by_equipment(
        "Bodyweight",
        ["barbell", "dumbbells", "bench"],
        "Burpee",
        goals=["strength"],
    ) is False
    assert filter_by_equipment(
        "Bodyweight",
        ["barbell"],
        "Frog Jump",
        goals=["hypertrophy"],
    ) is False


def test_equipped_strength_user_keeps_allow_listed_bodyweight():
    """Strength-bias bodyweight movements pass even on equipped users."""
    assert filter_by_equipment(
        "Bodyweight",
        ["barbell", "dumbbells"],
        "Pistol Squat",
        goals=["strength"],
    ) is True
    assert filter_by_equipment(
        "Bodyweight",
        ["barbell"],
        "Single-Leg Romanian Deadlift",
        goals=["strength"],
    ) is True
    assert filter_by_equipment(
        "Bodyweight",
        ["dumbbells"],
        "Archer Push-Up",
        goals=["hypertrophy"],
    ) is True


def test_mobility_blocks_plyometrics():
    """Mobility / recovery goals should never include burpees / jump squats."""
    assert filter_by_equipment(
        "Bodyweight", ["bodyweight"], "Burpee",
        goals=["mobility"],
    ) is False
    assert filter_by_equipment(
        "Bodyweight", ["bodyweight"], "Jump Squat",
        goals=["recovery"],
    ) is False
    assert filter_by_equipment(
        "Bodyweight", ["bodyweight"], "Box Jump",
        goals=["injury_recovery"],
    ) is False


def test_mobility_keeps_static_holds():
    assert filter_by_equipment(
        "Bodyweight", ["bodyweight"], "Plank",
        goals=["mobility"],
    ) is True


def test_no_goals_argument_preserves_old_behavior():
    """When goals=None or [], all bw exercises pass — no regression for
    callers that haven't been updated yet."""
    assert filter_by_equipment(
        "Bodyweight", ["barbell"], "Burpee"
    ) is True
    assert filter_by_equipment(
        "Bodyweight", ["barbell"], "Burpee", goals=[]
    ) is True


def test_endurance_goal_unaffected():
    """Endurance goal isn't in STRENGTH_GOALS, so bw exercises still pass."""
    assert filter_by_equipment(
        "Bodyweight", ["barbell"], "Burpee", goals=["endurance"]
    ) is True


def test_helpers_classify_correctly():
    assert is_strength_appropriate_bodyweight("Pistol Squat") is True
    assert is_strength_appropriate_bodyweight("Single-Arm Archer Push-Up") is True
    assert is_strength_appropriate_bodyweight("Burpee") is False
    assert is_plyometric("Mountain Climber Jump") is True
    assert is_plyometric("Box Jump") is True
    assert is_plyometric("Push-Up") is False
