"""
Tests for AI Consistency in Workout Generation.

This module tests that:
1. Readiness score affects workout intensity
2. Injuries are properly mapped to avoided muscles
3. Mood affects workout recommendations

These tests verify the AI consistency fixes implemented to ensure user data
(readiness, mood, injuries) is properly used in workout generation.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import json

# Import the functions we're testing
from api.v1.workouts.utils import (
    get_muscles_to_avoid_from_injuries,
    adjust_workout_params_for_readiness,
    INJURY_TO_AVOIDED_MUSCLES,
)


class TestInjuryToMuscleMapping:
    """Test injury-to-muscle mapping functionality."""

    def test_shoulder_injury_maps_to_correct_muscles(self):
        """Shoulder injury should avoid shoulders, chest, triceps, delts."""
        injuries = ["shoulder"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        # Should contain these muscles
        assert "shoulders" in avoided_muscles
        assert "chest" in avoided_muscles
        assert "triceps" in avoided_muscles

    def test_knee_injury_maps_to_leg_muscles(self):
        """Knee injury should avoid quads, hamstrings, calves, legs."""
        injuries = ["knee"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "quads" in avoided_muscles
        assert "hamstrings" in avoided_muscles
        assert "calves" in avoided_muscles
        assert "legs" in avoided_muscles

    def test_back_injury_maps_to_back_muscles(self):
        """Back injury should avoid back, lats, lower_back, traps."""
        injuries = ["back"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "back" in avoided_muscles
        assert "lats" in avoided_muscles
        assert "lower_back" in avoided_muscles
        assert "traps" in avoided_muscles

    def test_lower_back_injury_includes_posterior_chain(self):
        """Lower back injury should also avoid glutes and hamstrings."""
        injuries = ["lower_back"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "lower_back" in avoided_muscles
        assert "back" in avoided_muscles
        assert "glutes" in avoided_muscles
        assert "hamstrings" in avoided_muscles

    def test_wrist_injury_maps_to_arm_muscles(self):
        """Wrist injury should avoid forearms, biceps, triceps."""
        injuries = ["wrist"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "forearms" in avoided_muscles
        assert "biceps" in avoided_muscles
        assert "triceps" in avoided_muscles

    def test_multiple_injuries_combine_muscles(self):
        """Multiple injuries should combine all avoided muscles."""
        injuries = ["shoulder", "knee"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        # From shoulder
        assert "shoulders" in avoided_muscles
        assert "chest" in avoided_muscles

        # From knee
        assert "quads" in avoided_muscles
        assert "hamstrings" in avoided_muscles

    def test_empty_injuries_returns_empty_list(self):
        """Empty injury list should return empty avoided muscles."""
        injuries = []
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert avoided_muscles == []

    def test_none_injuries_returns_empty_list(self):
        """None injury list should return empty avoided muscles."""
        avoided_muscles = get_muscles_to_avoid_from_injuries(None)

        assert avoided_muscles == []

    def test_unknown_injury_returns_empty(self):
        """Unknown injury type should not crash, returns warning."""
        injuries = ["unknown_body_part"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        # Should not include any muscles for unknown injury
        # But should not crash either
        assert isinstance(avoided_muscles, list)

    def test_partial_match_injury(self):
        """Partial injury name match should work (e.g., 'shoulder pain')."""
        injuries = ["shoulder pain"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        # Should still match 'shoulder'
        assert "shoulders" in avoided_muscles
        assert "chest" in avoided_muscles

    def test_hip_injury_includes_lower_body(self):
        """Hip injury should avoid glutes, hip flexors, legs, quads, hamstrings."""
        injuries = ["hip"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "glutes" in avoided_muscles
        assert "hip_flexors" in avoided_muscles
        assert "legs" in avoided_muscles
        assert "quads" in avoided_muscles
        assert "hamstrings" in avoided_muscles

    def test_elbow_injury_includes_arm_muscles(self):
        """Elbow injury should avoid biceps, triceps, forearms."""
        injuries = ["elbow"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "biceps" in avoided_muscles
        assert "triceps" in avoided_muscles
        assert "forearms" in avoided_muscles

    def test_ankle_injury_includes_lower_leg(self):
        """Ankle injury should avoid calves and legs."""
        injuries = ["ankle"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "calves" in avoided_muscles
        assert "legs" in avoided_muscles

    def test_neck_injury_includes_upper_body(self):
        """Neck injury should avoid traps, shoulders, neck."""
        injuries = ["neck"]
        avoided_muscles = get_muscles_to_avoid_from_injuries(injuries)

        assert "traps" in avoided_muscles
        assert "shoulders" in avoided_muscles
        assert "neck" in avoided_muscles

    def test_all_injury_types_have_mappings(self):
        """All predefined injury types should have muscle mappings."""
        expected_injuries = [
            "shoulder", "back", "lower_back", "knee", "wrist",
            "ankle", "hip", "elbow", "neck", "chest", "groin",
            "hamstring", "quad", "calf", "rotator_cuff"
        ]

        for injury in expected_injuries:
            assert injury in INJURY_TO_AVOIDED_MUSCLES, f"Missing mapping for injury: {injury}"
            assert len(INJURY_TO_AVOIDED_MUSCLES[injury]) > 0, f"Empty mapping for injury: {injury}"


class TestReadinessAdjustment:
    """Test readiness-based workout parameter adjustments."""

    def test_low_readiness_reduces_intensity(self):
        """Low readiness (<50) should reduce sets/reps by 20%, increase rest by 30%."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=40)

        # 20% reduction in sets: 3 * 0.8 = 2.4 -> 2
        assert adjusted["sets"] == 2
        # 20% reduction in reps: 10 * 0.8 = 8
        assert adjusted["reps"] == 8
        # 30% increase in rest: 60 * 1.3 = 78
        assert adjusted["rest_seconds"] == 78
        assert adjusted.get("readiness_adjustment") == "low_readiness"

    def test_high_readiness_increases_intensity(self):
        """High readiness (>70) should increase sets/reps by 10%, reduce rest by 10%."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=85)

        # 10% increase in sets: 3 * 1.1 = 3.3 -> 3
        assert adjusted["sets"] == 3
        # 10% increase in reps: 10 * 1.1 = 11
        assert adjusted["reps"] == 11
        # 10% reduction in rest: 60 * 0.9 = 54
        assert adjusted["rest_seconds"] == 54
        assert adjusted.get("readiness_adjustment") == "high_readiness"

    def test_medium_readiness_normal_params(self):
        """Medium readiness (50-70) should use normal parameters."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=60)

        assert adjusted["sets"] == 3
        assert adjusted["reps"] == 10
        assert adjusted["rest_seconds"] == 60
        assert adjusted.get("readiness_adjustment") == "normal"

    def test_none_readiness_no_adjustment(self):
        """None readiness score should not adjust parameters."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=None)

        # Should return same values
        assert adjusted["sets"] == 3
        assert adjusted["reps"] == 10
        assert adjusted["rest_seconds"] == 60

    def test_empty_workout_params_uses_defaults(self):
        """Empty workout params should use default values."""
        adjusted = adjust_workout_params_for_readiness({}, readiness_score=40)

        # Should apply reduction to defaults (sets=3, reps=10, rest=60)
        assert adjusted["sets"] == 2  # 3 * 0.8
        assert adjusted["reps"] == 8  # 10 * 0.8
        assert adjusted["rest_seconds"] == 78  # 60 * 1.3

    def test_none_workout_params_uses_defaults(self):
        """None workout params should use default values."""
        adjusted = adjust_workout_params_for_readiness(None, readiness_score=40)

        assert adjusted["sets"] == 2
        assert adjusted["reps"] == 8
        assert adjusted["rest_seconds"] == 78


class TestMoodAdjustment:
    """Test mood-based workout parameter adjustments."""

    def test_tired_mood_reduces_intensity(self):
        """Tired mood should further reduce intensity."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=None, mood="tired")

        # 10% reduction: 3 * 0.9 = 2.7 -> 2
        assert adjusted["sets"] == 2
        # 10% reduction: 10 * 0.9 = 9
        assert adjusted["reps"] == 9
        # 20% more rest: 60 * 1.2 = 72
        assert adjusted["rest_seconds"] == 72
        assert adjusted.get("mood_adjustment") == "tired"
        assert adjusted.get("suggest_workout_type") == "recovery"

    def test_stressed_mood_reduces_intensity(self):
        """Stressed mood should reduce intensity and suggest recovery."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=None, mood="stressed")

        assert adjusted["sets"] == 2
        assert adjusted["reps"] == 9
        assert adjusted["rest_seconds"] == 72
        assert adjusted.get("mood_adjustment") == "stressed"
        assert adjusted.get("suggest_workout_type") == "recovery"

    def test_anxious_mood_reduces_intensity(self):
        """Anxious mood should reduce intensity like tired/stressed."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=None, mood="anxious")

        assert adjusted["sets"] == 2
        assert adjusted.get("mood_adjustment") == "anxious"
        assert adjusted.get("suggest_workout_type") == "recovery"

    def test_great_mood_no_reduction(self):
        """Great mood should not reduce intensity."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=None, mood="great")

        # Great mood should not reduce
        assert adjusted["sets"] == 3
        assert adjusted["reps"] == 10
        assert adjusted["rest_seconds"] == 60
        assert adjusted.get("mood_adjustment") == "great"
        assert adjusted.get("suggest_workout_type") is None

    def test_good_mood_no_adjustment(self):
        """Good mood should not adjust parameters."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=None, mood="good")

        # Good mood has no special handling, so no adjustment
        assert adjusted["sets"] == 3
        assert adjusted["reps"] == 10
        assert adjusted["rest_seconds"] == 60


class TestCombinedReadinessMoodAdjustment:
    """Test combined readiness and mood adjustments."""

    def test_low_readiness_and_tired_mood_stacks(self):
        """Low readiness + tired mood should stack reductions."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=40, mood="tired")

        # First: low readiness (20% reduction)
        # sets: 3 * 0.8 = 2.4 -> 2
        # reps: 10 * 0.8 = 8
        # rest: 60 * 1.3 = 78

        # Then: tired mood (additional 10% reduction on current values)
        # sets: 2 * 0.9 = 1.8 -> 2 (capped at min 2)
        # reps: 8 * 0.9 = 7.2 -> 7
        # rest: 78 * 1.2 = 93.6 -> 93

        assert adjusted["sets"] == 2
        assert adjusted["reps"] == 7
        assert adjusted["rest_seconds"] == 93
        assert adjusted.get("readiness_adjustment") == "low_readiness"
        assert adjusted.get("mood_adjustment") == "tired"

    def test_high_readiness_and_great_mood_no_double_boost(self):
        """High readiness + great mood should not excessively boost."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=85, mood="great")

        # High readiness: 10% increase
        # sets: 3 * 1.1 = 3.3 -> 3
        # reps: 10 * 1.1 = 11
        # rest: 60 * 0.9 = 54

        # Great mood: no additional change

        assert adjusted["sets"] == 3
        assert adjusted["reps"] == 11
        assert adjusted["rest_seconds"] == 54
        assert adjusted.get("readiness_adjustment") == "high_readiness"
        assert adjusted.get("mood_adjustment") == "great"

    def test_high_readiness_with_tired_mood_balances(self):
        """High readiness with tired mood should partially cancel out."""
        base_params = {"sets": 3, "reps": 10, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=80, mood="tired")

        # High readiness first: 10% increase
        # sets: 3 * 1.1 = 3.3 -> 3
        # reps: 10 * 1.1 = 11
        # rest: 60 * 0.9 = 54

        # Then tired mood: 10% reduction on current
        # sets: 3 * 0.9 = 2.7 -> 2
        # reps: 11 * 0.9 = 9.9 -> 9
        # rest: 54 * 1.2 = 64.8 -> 64

        assert adjusted["sets"] == 2
        assert adjusted["reps"] == 9
        assert adjusted["rest_seconds"] == 64
        # Both adjustments should be tracked
        assert adjusted.get("readiness_adjustment") == "high_readiness"
        assert adjusted.get("mood_adjustment") == "tired"


class TestMinimumValueGuards:
    """Test that adjustments don't go below minimum safe values."""

    def test_sets_minimum_is_2(self):
        """Sets should never go below 2."""
        base_params = {"sets": 2, "reps": 10, "rest_seconds": 60}

        # Apply multiple reductions
        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=30, mood="tired")

        assert adjusted["sets"] >= 2

    def test_reps_minimum_is_5_with_mood(self):
        """Reps should never go below 5 when mood adjustment applied."""
        base_params = {"sets": 3, "reps": 6, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=30, mood="tired")

        assert adjusted["reps"] >= 5

    def test_reps_minimum_is_6_with_readiness(self):
        """Reps should never go below 6 when readiness adjustment applied."""
        base_params = {"sets": 3, "reps": 7, "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=30, mood=None)

        assert adjusted["reps"] >= 6


class TestRepsStringHandling:
    """Test handling of rep ranges as strings (e.g., '8-12')."""

    def test_rep_range_string_is_averaged(self):
        """Rep range string like '8-12' should use average."""
        base_params = {"sets": 3, "reps": "8-12", "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=40)

        # Average of 8-12 is 10, then 20% reduction = 8
        assert adjusted["reps"] == 8

    def test_single_rep_string_is_converted(self):
        """Single rep string like '10' should be converted to int."""
        base_params = {"sets": 3, "reps": "10", "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=40)

        # 10 with 20% reduction = 8
        assert adjusted["reps"] == 8

    def test_invalid_rep_string_uses_default(self):
        """Invalid rep string should use default of 10."""
        base_params = {"sets": 3, "reps": "invalid", "rest_seconds": 60}

        adjusted = adjust_workout_params_for_readiness(base_params, readiness_score=40)

        # Default 10 with 20% reduction = 8
        assert adjusted["reps"] == 8


# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
