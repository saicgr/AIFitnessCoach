"""
Tests for focus area validation in workout generation.

These tests verify that the focus area validation system correctly identifies
exercises that don't match the declared workout focus (e.g., push-ups in a leg workout).

This catches AI hallucinations where exercise names don't match the workout type.

Run with: pytest tests/test_focus_area_validation.py -v
"""
import pytest
import asyncio
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.workouts.utils import (
    validate_exercise_matches_focus,
    validate_and_filter_focus_mismatches,
    FOCUS_AREA_MUSCLES,
    FOCUS_AREA_EXCLUDED_EXERCISES,
)


# ============ Test validate_exercise_matches_focus ============

class TestValidateExerciseMatchesFocus:
    """Tests for the single exercise validation function."""

    def test_leg_exercise_matches_leg_focus(self):
        """Leg exercises should match leg focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Barbell Squat",
            muscle_group="quadriceps",
            focus_area="legs"
        )
        assert result["matches"] is True
        assert result["confidence"] >= 0.8

    def test_leg_exercise_matches_lower_focus(self):
        """Leg exercises should match lower body focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Lunges",
            muscle_group="glutes",
            focus_area="lower"
        )
        assert result["matches"] is True

    def test_pushup_does_not_match_leg_focus(self):
        """Push-ups should NOT match leg focus (the bug we're fixing)."""
        result = validate_exercise_matches_focus(
            exercise_name="Push-ups",
            muscle_group="chest",
            focus_area="legs"
        )
        assert result["matches"] is False
        assert "push-up" in result["reason"].lower() or "chest" in result["reason"].lower()
        assert result["confidence"] >= 0.8

    def test_bench_press_does_not_match_leg_focus(self):
        """Bench press should NOT match leg focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Bench Press",
            muscle_group="chest",
            focus_area="legs"
        )
        assert result["matches"] is False

    def test_squat_does_not_match_push_focus(self):
        """Squats should NOT match push focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Barbell Squat",
            muscle_group="quadriceps",
            focus_area="push"
        )
        assert result["matches"] is False

    def test_chest_exercise_matches_push_focus(self):
        """Chest exercises should match push focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Incline Dumbbell Press",
            muscle_group="chest",
            focus_area="push"
        )
        assert result["matches"] is True

    def test_shoulder_exercise_matches_push_focus(self):
        """Shoulder exercises should match push focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Overhead Press",
            muscle_group="shoulders",
            focus_area="push"
        )
        assert result["matches"] is True

    def test_tricep_exercise_matches_push_focus(self):
        """Tricep exercises should match push focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Tricep Pushdown",
            muscle_group="triceps",
            focus_area="push"
        )
        assert result["matches"] is True

    def test_back_exercise_matches_pull_focus(self):
        """Back exercises should match pull focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Bent Over Row",
            muscle_group="back",
            focus_area="pull"
        )
        assert result["matches"] is True

    def test_bicep_exercise_matches_pull_focus(self):
        """Bicep exercises should match pull focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Barbell Curl",
            muscle_group="biceps",
            focus_area="pull"
        )
        assert result["matches"] is True

    def test_lat_pulldown_matches_pull_focus(self):
        """Lat pulldown should match pull focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Lat Pulldown",
            muscle_group="lats",
            focus_area="pull"
        )
        assert result["matches"] is True

    def test_pushup_does_not_match_pull_focus(self):
        """Push-ups should NOT match pull focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Push-ups",
            muscle_group="chest",
            focus_area="pull"
        )
        assert result["matches"] is False

    def test_any_exercise_matches_full_body_focus(self):
        """Any exercise should match full body focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Push-ups",
            muscle_group="chest",
            focus_area="full_body"
        )
        assert result["matches"] is True
        assert result["confidence"] == 1.0

    def test_any_exercise_matches_empty_focus(self):
        """Any exercise should match when no focus is specified."""
        result = validate_exercise_matches_focus(
            exercise_name="Random Exercise",
            muscle_group="random",
            focus_area=""
        )
        assert result["matches"] is True

    def test_any_exercise_matches_none_focus(self):
        """Any exercise should match when focus is None."""
        result = validate_exercise_matches_focus(
            exercise_name="Random Exercise",
            muscle_group="random",
            focus_area=None
        )
        assert result["matches"] is True

    def test_core_exercise_matches_core_focus(self):
        """Core exercises should match core focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Plank",
            muscle_group="abs",
            focus_area="core"
        )
        assert result["matches"] is True

    def test_oblique_exercise_matches_core_focus(self):
        """Oblique exercises should match core focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Russian Twist",
            muscle_group="obliques",
            focus_area="core"
        )
        assert result["matches"] is True

    def test_chest_exercise_matches_upper_focus(self):
        """Chest exercises should match upper body focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Bench Press",
            muscle_group="chest",
            focus_area="upper"
        )
        assert result["matches"] is True

    def test_back_exercise_matches_upper_focus(self):
        """Back exercises should match upper body focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Pull-ups",
            muscle_group="back",
            focus_area="upper"
        )
        assert result["matches"] is True

    def test_leg_exercise_does_not_match_upper_focus(self):
        """Leg exercises should NOT match upper body focus."""
        result = validate_exercise_matches_focus(
            exercise_name="Leg Press",
            muscle_group="quadriceps",
            focus_area="upper"
        )
        assert result["matches"] is False


# ============ Test validate_and_filter_focus_mismatches ============

class TestValidateAndFilterFocusMismatches:
    """Tests for the batch validation function that filters mismatched exercises."""

    @pytest.mark.asyncio
    async def test_all_exercises_match_focus(self):
        """When all exercises match, no mismatches should be reported."""
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Leg Press", "muscle_group": "quads"},
            {"name": "Calf Raises", "muscle_group": "calves"},
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="legs",
            workout_name="Thunder Legs"
        )

        assert result["mismatch_count"] == 0
        assert len(result["valid_exercises"]) == 4
        assert len(result["mismatched_exercises"]) == 0
        assert len(result["warnings"]) == 0

    @pytest.mark.asyncio
    async def test_some_exercises_mismatch(self):
        """When some exercises don't match, they should be flagged."""
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch!
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch!
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="legs",
            workout_name="Thunder Legs"
        )

        assert result["mismatch_count"] == 2
        assert len(result["valid_exercises"]) == 2
        assert len(result["mismatched_exercises"]) == 2
        assert len(result["warnings"]) == 2

        # Check that the right exercises were flagged
        mismatched_names = [ex["name"] for ex in result["mismatched_exercises"]]
        assert "Push-ups" in mismatched_names
        assert "Bench Press" in mismatched_names

    @pytest.mark.asyncio
    async def test_majority_mismatch_detected(self):
        """When majority of exercises don't match, it should be flagged as critical."""
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},  # Match
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch
            {"name": "Shoulder Press", "muscle_group": "shoulders"},  # Mismatch
            {"name": "Tricep Dips", "muscle_group": "triceps"},  # Mismatch
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="legs",
            workout_name="Savage Wolf Legs"
        )

        # 4 out of 5 don't match (80%)
        assert result["mismatch_count"] == 4
        assert result["mismatch_count"] > len(exercises) / 2  # Majority mismatch

    @pytest.mark.asyncio
    async def test_full_body_focus_allows_all(self):
        """Full body focus should allow all exercises."""
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Push-ups", "muscle_group": "chest"},
            {"name": "Pull-ups", "muscle_group": "back"},
            {"name": "Plank", "muscle_group": "core"},
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="full_body",
            workout_name="Total Body Blast"
        )

        assert result["mismatch_count"] == 0
        assert len(result["valid_exercises"]) == 4

    @pytest.mark.asyncio
    async def test_empty_focus_allows_all(self):
        """Empty focus should allow all exercises."""
        exercises = [
            {"name": "Random Exercise 1", "muscle_group": "chest"},
            {"name": "Random Exercise 2", "muscle_group": "legs"},
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="",
            workout_name="Random Workout"
        )

        assert result["mismatch_count"] == 0
        assert len(result["valid_exercises"]) == 2

    @pytest.mark.asyncio
    async def test_push_focus_validation(self):
        """Push focus should allow chest, shoulders, triceps."""
        exercises = [
            {"name": "Bench Press", "muscle_group": "chest"},
            {"name": "Shoulder Press", "muscle_group": "shoulders"},
            {"name": "Tricep Pushdown", "muscle_group": "triceps"},
            {"name": "Barbell Row", "muscle_group": "back"},  # Mismatch
            {"name": "Squat", "muscle_group": "quadriceps"},  # Mismatch
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="push",
            workout_name="Phoenix Chest"
        )

        assert result["mismatch_count"] == 2
        assert len(result["valid_exercises"]) == 3

    @pytest.mark.asyncio
    async def test_pull_focus_validation(self):
        """Pull focus should allow back and biceps."""
        exercises = [
            {"name": "Barbell Row", "muscle_group": "back"},
            {"name": "Lat Pulldown", "muscle_group": "lats"},
            {"name": "Bicep Curl", "muscle_group": "biceps"},
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="pull",
            workout_name="Cobra Back"
        )

        assert result["mismatch_count"] == 2
        assert len(result["valid_exercises"]) == 3

    @pytest.mark.asyncio
    async def test_warnings_contain_exercise_names(self):
        """Warnings should contain the mismatched exercise names."""
        exercises = [
            {"name": "Squat", "muscle_group": "quadriceps"},
            {"name": "Diamond Push-ups", "muscle_group": "chest"},  # Mismatch
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="legs",
            workout_name="Iron Legs"
        )

        assert len(result["warnings"]) == 1
        assert "Diamond Push-ups" in result["warnings"][0]

    @pytest.mark.asyncio
    async def test_empty_exercises_list(self):
        """Empty exercises list should return empty results."""
        result = await validate_and_filter_focus_mismatches(
            exercises=[],
            focus_area="legs",
            workout_name="Empty Workout"
        )

        assert result["mismatch_count"] == 0
        assert len(result["valid_exercises"]) == 0
        assert len(result["mismatched_exercises"]) == 0


# ============ Test Focus Area Mappings ============

class TestFocusAreaMappings:
    """Tests for the focus area muscle and exercise mappings."""

    def test_all_common_focus_areas_have_mappings(self):
        """Common focus areas should have muscle mappings."""
        common_focus_areas = ['legs', 'push', 'pull', 'upper', 'lower', 'chest', 'back', 'shoulders', 'arms', 'core', 'glutes']

        for focus in common_focus_areas:
            assert focus in FOCUS_AREA_MUSCLES, f"Missing muscle mapping for '{focus}'"
            assert len(FOCUS_AREA_MUSCLES[focus]) > 0, f"Empty muscle mapping for '{focus}'"

    def test_legs_focus_has_all_leg_muscles(self):
        """Legs focus should include quads, hamstrings, glutes, calves."""
        leg_muscles = FOCUS_AREA_MUSCLES['legs']

        # Check that key leg muscles are covered
        assert any('quad' in m for m in leg_muscles)
        assert any('hamstring' in m for m in leg_muscles)
        assert any('glute' in m for m in leg_muscles)
        assert any('calf' in m or 'calves' in m for m in leg_muscles)

    def test_push_focus_has_push_muscles(self):
        """Push focus should include chest, shoulders, triceps."""
        push_muscles = FOCUS_AREA_MUSCLES['push']

        assert any('chest' in m or 'pec' in m for m in push_muscles)
        assert any('shoulder' in m or 'delt' in m for m in push_muscles)
        assert any('tricep' in m for m in push_muscles)

    def test_pull_focus_has_pull_muscles(self):
        """Pull focus should include back and biceps."""
        pull_muscles = FOCUS_AREA_MUSCLES['pull']

        assert any('back' in m or 'lat' in m for m in pull_muscles)
        assert any('bicep' in m for m in pull_muscles)

    def test_legs_excluded_exercises_include_pushups(self):
        """Legs focus should exclude push-ups."""
        excluded = FOCUS_AREA_EXCLUDED_EXERCISES.get('legs', [])

        assert any('push' in ex for ex in excluded)

    def test_push_excluded_exercises_include_squats(self):
        """Push focus should exclude squats."""
        excluded = FOCUS_AREA_EXCLUDED_EXERCISES.get('push', [])

        assert any('squat' in ex for ex in excluded)


# ============ Test Edge Cases ============

class TestEdgeCases:
    """Tests for edge cases and unusual inputs."""

    def test_case_insensitive_focus(self):
        """Focus area matching should be case insensitive."""
        result = validate_exercise_matches_focus(
            exercise_name="Squat",
            muscle_group="quadriceps",
            focus_area="LEGS"
        )
        assert result["matches"] is True

    def test_case_insensitive_muscle_group(self):
        """Muscle group matching should be case insensitive."""
        result = validate_exercise_matches_focus(
            exercise_name="Squat",
            muscle_group="QUADRICEPS",
            focus_area="legs"
        )
        assert result["matches"] is True

    def test_whitespace_handling(self):
        """Whitespace in inputs should be handled."""
        result = validate_exercise_matches_focus(
            exercise_name="  Squat  ",
            muscle_group="  quadriceps  ",
            focus_area="  legs  "
        )
        assert result["matches"] is True

    def test_empty_muscle_group(self):
        """Empty muscle group should be handled gracefully."""
        result = validate_exercise_matches_focus(
            exercise_name="Unknown Exercise",
            muscle_group="",
            focus_area="legs"
        )
        # Should not crash, might match or not based on exercise name
        assert "matches" in result
        assert "confidence" in result

    def test_none_muscle_group(self):
        """None muscle group should be handled gracefully."""
        result = validate_exercise_matches_focus(
            exercise_name="Unknown Exercise",
            muscle_group=None,
            focus_area="legs"
        )
        # Should not crash
        assert "matches" in result

    def test_unknown_focus_area(self):
        """Unknown focus area should be handled gracefully."""
        result = validate_exercise_matches_focus(
            exercise_name="Random Exercise",
            muscle_group="random",
            focus_area="unknown_focus_xyz"
        )
        # Should allow by default with low confidence
        assert result["matches"] is True
        assert result["confidence"] < 1.0

    @pytest.mark.asyncio
    async def test_exercises_with_missing_fields(self):
        """Exercises with missing name or muscle_group should be handled."""
        exercises = [
            {"name": "Squat"},  # Missing muscle_group
            {"muscle_group": "chest"},  # Missing name
            {},  # Missing both
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="legs",
            workout_name="Test Workout"
        )

        # Should not crash
        assert "mismatch_count" in result
        assert "valid_exercises" in result


# ============ Real-World Bug Scenario Tests ============

class TestRealWorldBugScenarios:
    """Tests that reproduce real-world bugs like the one reported by digithat123@gmail.com."""

    @pytest.mark.asyncio
    async def test_leg_workout_with_only_pushups_detected(self):
        """
        Reproduce the bug: Workout named 'Leg Workout' but only contains push-ups.
        This should be detected as a critical mismatch.
        """
        # This is what the AI sometimes generates incorrectly
        exercises = [
            {"name": "Push-ups", "muscle_group": "chest"},
            {"name": "Wide Push-ups", "muscle_group": "chest"},
            {"name": "Diamond Push-ups", "muscle_group": "chest"},
            {"name": "Pike Push-ups", "muscle_group": "shoulders"},
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="legs",
            workout_name="Thunder Legs"
        )

        # All 4 exercises should be mismatched
        assert result["mismatch_count"] == 4
        assert len(result["valid_exercises"]) == 0
        # This is a critical mismatch (100% of exercises don't match)
        assert result["mismatch_count"] > len(exercises) / 2

    @pytest.mark.asyncio
    async def test_push_workout_with_squats_detected(self):
        """Push workout containing leg exercises should be detected."""
        exercises = [
            {"name": "Bench Press", "muscle_group": "chest"},
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},  # Mismatch
            {"name": "Shoulder Press", "muscle_group": "shoulders"},
            {"name": "Lunges", "muscle_group": "glutes"},  # Mismatch
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="push",
            workout_name="Iron Phoenix Chest"
        )

        assert result["mismatch_count"] == 2
        mismatched_names = [ex["name"] for ex in result["mismatched_exercises"]]
        assert "Barbell Squat" in mismatched_names
        assert "Lunges" in mismatched_names

    @pytest.mark.asyncio
    async def test_back_workout_with_chest_exercises_detected(self):
        """Back workout containing chest exercises should be detected."""
        exercises = [
            {"name": "Barbell Row", "muscle_group": "back"},
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch
            {"name": "Lat Pulldown", "muscle_group": "lats"},
            {"name": "Chest Fly", "muscle_group": "chest"},  # Mismatch
        ]

        result = await validate_and_filter_focus_mismatches(
            exercises=exercises,
            focus_area="back",
            workout_name="Cobra Back"
        )

        assert result["mismatch_count"] == 2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
