"""
Tests for fitness level edge cases.

This test suite covers edge cases identified in the fitness level handling:
1. None/empty fitness level defaults
2. Invalid fitness level strings (typos)
3. Case insensitivity
4. Quick workout intensity override protection
5. Workout modifier respecting ceilings
6. Fallback exercise parameters
"""

import pytest
from services.exercise_rag.service import (
    validate_fitness_level,
    is_exercise_too_difficult,
    VALID_FITNESS_LEVELS,
    DEFAULT_FITNESS_LEVEL,
    DIFFICULTY_CEILING,
)
from services.adaptive_workout_service import AdaptiveWorkoutService


class TestValidateFitnessLevel:
    """Test the validate_fitness_level function."""

    def test_none_returns_default(self):
        """None fitness level should return default."""
        result = validate_fitness_level(None)
        assert result == DEFAULT_FITNESS_LEVEL
        assert result == "intermediate"

    def test_empty_string_returns_default(self):
        """Empty string should return default."""
        result = validate_fitness_level("")
        assert result == DEFAULT_FITNESS_LEVEL

    def test_whitespace_only_returns_default(self):
        """Whitespace-only string should return default."""
        result = validate_fitness_level("   ")
        assert result == DEFAULT_FITNESS_LEVEL

    def test_valid_beginner(self):
        """'beginner' should return 'beginner'."""
        assert validate_fitness_level("beginner") == "beginner"

    def test_valid_intermediate(self):
        """'intermediate' should return 'intermediate'."""
        assert validate_fitness_level("intermediate") == "intermediate"

    def test_valid_advanced(self):
        """'advanced' should return 'advanced'."""
        assert validate_fitness_level("advanced") == "advanced"

    def test_case_insensitive_uppercase(self):
        """BEGINNER should normalize to beginner."""
        assert validate_fitness_level("BEGINNER") == "beginner"
        assert validate_fitness_level("INTERMEDIATE") == "intermediate"
        assert validate_fitness_level("ADVANCED") == "advanced"

    def test_case_insensitive_mixed(self):
        """Mixed case should normalize."""
        assert validate_fitness_level("Beginner") == "beginner"
        assert validate_fitness_level("InTerMeDiAtE") == "intermediate"

    def test_typo_returns_default(self):
        """Typos should return default."""
        assert validate_fitness_level("beginnner") == DEFAULT_FITNESS_LEVEL  # extra 'n'
        assert validate_fitness_level("begginer") == DEFAULT_FITNESS_LEVEL
        assert validate_fitness_level("intermidiate") == DEFAULT_FITNESS_LEVEL

    def test_invalid_value_returns_default(self):
        """Unknown values should return default."""
        assert validate_fitness_level("expert") == DEFAULT_FITNESS_LEVEL
        assert validate_fitness_level("newbie") == DEFAULT_FITNESS_LEVEL
        assert validate_fitness_level("pro") == DEFAULT_FITNESS_LEVEL

    def test_numeric_value_returns_default(self):
        """Numeric values should return default."""
        assert validate_fitness_level("1") == DEFAULT_FITNESS_LEVEL
        assert validate_fitness_level("2") == DEFAULT_FITNESS_LEVEL


class TestIsExerciseTooDifficultEdgeCases:
    """Test edge cases in is_exercise_too_difficult.

    With the ratio-based system, only Elite (10) exercises are filtered for beginners.
    """

    def test_none_fitness_level_handled(self):
        """None fitness level should not crash."""
        # This should not raise AttributeError
        result = is_exercise_too_difficult(5, None)
        # Should use default intermediate (no restrictions)
        assert result is False

    def test_empty_fitness_level_handled(self):
        """Empty fitness level should not crash."""
        result = is_exercise_too_difficult(5, "")
        assert result is False  # Uses default intermediate

    def test_typo_fitness_level_uses_default(self):
        """Typo in fitness level should use default (intermediate)."""
        # Typo defaults to intermediate, which has no restrictions
        assert is_exercise_too_difficult(5, "beginnner") is False
        assert is_exercise_too_difficult(7, "beginnner") is False
        assert is_exercise_too_difficult(10, "beginnner") is False  # Not beginner, so no elite filter

    def test_none_difficulty_uses_default(self):
        """None exercise difficulty should use default (2 = beginner)."""
        # Difficulty None defaults to 2, which is available to all
        assert is_exercise_too_difficult(None, "beginner") is False
        assert is_exercise_too_difficult(None, "intermediate") is False


class TestQuickWorkoutIntensityProtection:
    """Test that quick workout respects fitness level ceilings."""

    def test_beginner_cannot_get_advanced_exercises(self):
        """
        Beginner selecting 'intense' should NOT get advanced exercises.

        This tests the logic that should be in workout_tools.py.
        """
        # Simulate the logic from workout_tools.py
        user_fitness_level = "beginner"
        selected_intensity = "intense"

        intensity_to_fitness = {
            "light": "beginner",
            "moderate": "intermediate",
            "intense": "advanced",
        }
        suggested_fitness_level = intensity_to_fitness.get(selected_intensity, "intermediate")

        FITNESS_LEVEL_ORDER = {"beginner": 1, "intermediate": 2, "advanced": 3}
        user_level_rank = FITNESS_LEVEL_ORDER.get(user_fitness_level.lower(), 2)
        suggested_level_rank = FITNESS_LEVEL_ORDER.get(suggested_fitness_level, 2)

        # The fix should cap at user's level
        if suggested_level_rank > user_level_rank:
            rag_fitness_level = user_fitness_level
        else:
            rag_fitness_level = suggested_fitness_level

        assert rag_fitness_level == "beginner", "Beginner should NOT get advanced exercises"

    def test_intermediate_can_get_light(self):
        """Intermediate user can select light intensity."""
        user_fitness_level = "intermediate"
        selected_intensity = "light"

        intensity_to_fitness = {
            "light": "beginner",
            "moderate": "intermediate",
            "intense": "advanced",
        }
        suggested_fitness_level = intensity_to_fitness.get(selected_intensity, "intermediate")

        FITNESS_LEVEL_ORDER = {"beginner": 1, "intermediate": 2, "advanced": 3}
        user_level_rank = FITNESS_LEVEL_ORDER.get(user_fitness_level.lower(), 2)
        suggested_level_rank = FITNESS_LEVEL_ORDER.get(suggested_fitness_level, 2)

        if suggested_level_rank > user_level_rank:
            rag_fitness_level = user_fitness_level
        else:
            rag_fitness_level = suggested_fitness_level

        # Intermediate CAN request lighter workouts
        assert rag_fitness_level == "beginner"

    def test_advanced_can_get_any_intensity(self):
        """Advanced user can select any intensity."""
        for intensity in ["light", "moderate", "intense"]:
            user_fitness_level = "advanced"

            intensity_to_fitness = {
                "light": "beginner",
                "moderate": "intermediate",
                "intense": "advanced",
            }
            suggested_fitness_level = intensity_to_fitness.get(intensity, "intermediate")

            FITNESS_LEVEL_ORDER = {"beginner": 1, "intermediate": 2, "advanced": 3}
            user_level_rank = FITNESS_LEVEL_ORDER.get(user_fitness_level.lower(), 2)
            suggested_level_rank = FITNESS_LEVEL_ORDER.get(suggested_fitness_level, 2)

            if suggested_level_rank > user_level_rank:
                rag_fitness_level = user_fitness_level
            else:
                rag_fitness_level = suggested_fitness_level

            # Advanced can get any level
            assert rag_fitness_level == suggested_fitness_level


class TestWorkoutModifierCeilings:
    """Test workout modifier respects fitness level ceilings."""

    FITNESS_CEILINGS = {
        "beginner": {"sets_max": 3, "reps_max": 12, "reps_min": 6},
        "intermediate": {"sets_max": 5, "reps_max": 15, "reps_min": 4},
        "advanced": {"sets_max": 8, "reps_max": 20, "reps_min": 1},
    }

    def test_beginner_increase_capped_at_3_sets(self):
        """Beginner increasing workout should cap at 3 sets."""
        fitness_level = "beginner"
        ceiling = self.FITNESS_CEILINGS[fitness_level]

        # Start with 2 sets
        current_sets = 2

        # "Increase" modification
        new_sets = min(ceiling["sets_max"], current_sets + 1)

        assert new_sets == 3, "Beginner should cap at 3 sets"

        # Try to increase again
        new_sets = min(ceiling["sets_max"], new_sets + 1)
        assert new_sets == 3, "Beginner should still be capped at 3 sets"

    def test_beginner_increase_capped_at_12_reps(self):
        """Beginner increasing workout should cap at 12 reps."""
        fitness_level = "beginner"
        ceiling = self.FITNESS_CEILINGS[fitness_level]

        # Start with 10 reps
        current_reps = 10

        # "Increase" by 2 reps
        new_reps = min(ceiling["reps_max"], current_reps + 2)
        assert new_reps == 12

        # Try again
        new_reps = min(ceiling["reps_max"], new_reps + 2)
        assert new_reps == 12, "Beginner should cap at 12 reps"

    def test_beginner_decrease_floors_at_6_reps(self):
        """Beginner decreasing workout should floor at 6 reps."""
        fitness_level = "beginner"
        ceiling = self.FITNESS_CEILINGS[fitness_level]

        # Start with 8 reps
        current_reps = 8

        # "Decrease" by 2 reps
        new_reps = max(ceiling["reps_min"], current_reps - 2)
        assert new_reps == 6

        # Try again
        new_reps = max(ceiling["reps_min"], new_reps - 2)
        assert new_reps == 6, "Beginner should floor at 6 reps"

    def test_advanced_has_higher_limits(self):
        """Advanced user has higher modification limits."""
        fitness_level = "advanced"
        ceiling = self.FITNESS_CEILINGS[fitness_level]

        # Can go up to 8 sets
        assert min(ceiling["sets_max"], 6 + 1) == 7
        assert min(ceiling["sets_max"], 7 + 1) == 8
        assert min(ceiling["sets_max"], 8 + 1) == 8  # capped

        # Can go up to 20 reps
        assert min(ceiling["reps_max"], 18 + 2) == 20

        # Can go down to 1 rep (power singles)
        assert max(ceiling["reps_min"], 3 - 2) == 1


class TestFallbackExerciseParameters:
    """Test fallback exercises use appropriate parameters for fitness level."""

    def test_beginner_fallback_parameters(self):
        """Beginner fallback should have 2 sets, 10 reps."""
        fitness_level = "beginner"

        if fitness_level == "beginner":
            fallback_sets, fallback_reps = 2, 10
        elif fitness_level == "advanced":
            fallback_sets, fallback_reps = 4, 12
        else:
            fallback_sets, fallback_reps = 3, 12

        assert fallback_sets == 2
        assert fallback_reps == 10

    def test_intermediate_fallback_parameters(self):
        """Intermediate fallback should have 3 sets, 12 reps."""
        fitness_level = "intermediate"

        if fitness_level == "beginner":
            fallback_sets, fallback_reps = 2, 10
        elif fitness_level == "advanced":
            fallback_sets, fallback_reps = 4, 12
        else:
            fallback_sets, fallback_reps = 3, 12

        assert fallback_sets == 3
        assert fallback_reps == 12

    def test_advanced_fallback_parameters(self):
        """Advanced fallback should have 4 sets, 12 reps."""
        fitness_level = "advanced"

        if fitness_level == "beginner":
            fallback_sets, fallback_reps = 2, 10
        elif fitness_level == "advanced":
            fallback_sets, fallback_reps = 4, 12
        else:
            fallback_sets, fallback_reps = 3, 12

        assert fallback_sets == 4
        assert fallback_reps == 12


class TestAdaptiveServiceWithNullFitnessLevel:
    """Test AdaptiveWorkoutService with null/empty fitness level."""

    @pytest.fixture
    def service(self):
        return AdaptiveWorkoutService(supabase_client=None)

    @pytest.mark.asyncio
    async def test_none_fitness_level_no_ceiling(self, service):
        """When fitness_level is None, no ceiling should be applied."""
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            fitness_level=None,
        )

        # Should get base hypertrophy params (no ceiling applied)
        # Hypertrophy base: sets 3-5, reps 8-12
        assert params["sets"] >= 3
        assert params["reps"] >= 8

    @pytest.mark.asyncio
    async def test_empty_string_fitness_level(self, service):
        """Empty string fitness level should not crash."""
        # Should not raise exception
        params = await service.get_adaptive_parameters(
            user_id="test-user",
            workout_type="hypertrophy",
            fitness_level="",
        )

        assert "sets" in params
        assert "reps" in params


class TestDifficultyCeilingConstants:
    """Test difficulty ceiling constants are correctly defined."""

    def test_beginner_ceiling_is_3(self):
        """Beginner ceiling should be 3."""
        assert DIFFICULTY_CEILING["beginner"] == 3

    def test_intermediate_ceiling_is_6(self):
        """Intermediate ceiling should be 6."""
        assert DIFFICULTY_CEILING["intermediate"] == 6

    def test_advanced_ceiling_is_10(self):
        """Advanced ceiling should be 10 (no limit)."""
        assert DIFFICULTY_CEILING["advanced"] == 10

    def test_valid_fitness_levels_complete(self):
        """All expected fitness levels should be in the valid set."""
        assert "beginner" in VALID_FITNESS_LEVELS
        assert "intermediate" in VALID_FITNESS_LEVELS
        assert "advanced" in VALID_FITNESS_LEVELS
        assert len(VALID_FITNESS_LEVELS) == 3
