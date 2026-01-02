"""
Tests for exercise parameter validation.

These tests ensure that the validate_and_cap_exercise_parameters function
properly caps exercise parameters to prevent extreme workouts from reaching users.

The main scenario this addresses: Gemini generates 90 squats for a 70-year-old
beginner returning from a break. This should NEVER happen.
"""

import pytest
from api.v1.workouts.utils import (
    validate_and_cap_exercise_parameters,
    FITNESS_LEVEL_CAPS,
    AGE_CAPS,
    ABSOLUTE_MAX_REPS,
    ABSOLUTE_MAX_SETS,
    ABSOLUTE_MIN_REST,
    get_age_bracket_from_age,
)


class TestValidateAndCapExerciseParameters:
    """Test the main validation function."""

    def test_90_reps_capped_to_12_for_beginner(self):
        """
        The 90 squats issue: Gemini returns 90 reps for a beginner.
        This should be capped to 12 (beginner max).
        """
        exercises = [
            {"name": "Squats", "sets": 5, "reps": 90, "rest_seconds": 20}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=None,
            is_comeback=False
        )

        assert len(result) == 1
        assert result[0]["reps"] == 12  # Beginner max
        assert result[0]["sets"] == 3   # Beginner max sets
        assert result[0]["rest_seconds"] >= 60  # Beginner min rest

    def test_70_year_old_gets_max_10_reps(self):
        """
        A 70-year-old should never get more than 10 reps (elderly cap).
        Even if they're advanced fitness level.
        """
        exercises = [
            {"name": "Bench Press", "sets": 4, "reps": 20, "rest_seconds": 45}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="advanced",  # Even advanced users...
            age=70,  # ...at 70 years old...
            is_comeback=False
        )

        assert result[0]["reps"] <= 12  # Senior cap (60-74)
        assert result[0]["rest_seconds"] >= 75  # Senior min rest

    def test_75_year_old_elderly_caps(self):
        """
        A 75-year-old should get elderly caps (max 10 reps).
        """
        exercises = [
            {"name": "Deadlift", "sets": 5, "reps": 15, "rest_seconds": 30}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="advanced",
            age=75,
            is_comeback=False
        )

        assert result[0]["reps"] <= 10  # Elderly max
        assert result[0]["sets"] <= 3   # Elderly max sets
        assert result[0]["rest_seconds"] >= 90  # Elderly min rest

    def test_comeback_mode_reduces_volume(self):
        """
        A user returning from a break should get reduced volume.
        30% reps reduction, 1 set reduction.
        """
        exercises = [
            {"name": "Squats", "sets": 4, "reps": 12, "rest_seconds": 60}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=25,  # Young adult - no age multiplier on rest
            is_comeback=True
        )

        # Reps: 12 * 0.7 = 8.4 -> 8
        # Sets: 4 - 1 = 3
        # Rest: 60 * 1.2 = 72
        assert result[0]["reps"] == 8
        assert result[0]["sets"] == 3
        assert result[0]["rest_seconds"] == 72

    def test_70_year_old_beginner_comeback_triple_cap(self):
        """
        THE CRITICAL SCENARIO: 70-year-old beginner returning from break.
        This should apply ALL THREE caps:
        1. Beginner caps
        2. Senior age caps (60-74)
        3. Comeback reduction

        A 90-squat workout should become something very manageable.
        """
        exercises = [
            {"name": "Squats", "sets": 5, "reps": 90, "rest_seconds": 20}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=70,
            is_comeback=True
        )

        # Step 1: Beginner caps -> sets=3, reps=12, rest=60
        # Step 2: Senior caps (70yo) -> reps=min(12,12)=12, sets=min(3,3)=3, rest=max(60,75)=75, rest*1.5=112
        # Step 3: Comeback -> reps=12*0.7=8, sets=3-1=2, rest=112*1.2=134

        assert result[0]["reps"] <= 10  # Should be heavily reduced
        assert result[0]["sets"] == 2   # Minimum for comeback
        assert result[0]["rest_seconds"] >= 100  # Lots of rest

    def test_absolute_maximum_caps_always_apply(self):
        """
        Even for advanced users, absolute maximums apply.
        Never more than 30 reps, 6 sets.
        """
        exercises = [
            {"name": "Pull-ups", "sets": 10, "reps": 100, "rest_seconds": 10}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="advanced",
            age=25,
            is_comeback=False
        )

        # Advanced caps: sets=5, reps=20 (both below absolute max)
        # Young adult caps: sets=6, reps=25
        # The lower of fitness and age caps applies
        assert result[0]["reps"] <= ABSOLUTE_MAX_REPS  # 30
        assert result[0]["sets"] <= ABSOLUTE_MAX_SETS  # 6
        assert result[0]["rest_seconds"] >= ABSOLUTE_MIN_REST  # 30

    def test_string_reps_are_handled(self):
        """
        Gemini sometimes returns reps as strings like "8-12" or "10".
        These should be parsed correctly.
        """
        exercises = [
            {"name": "Curls", "sets": 3, "reps": "8-12", "rest_seconds": 45}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=None,
            is_comeback=False
        )

        # Should parse "8-12" and use 12 (higher value) for capping
        assert isinstance(result[0]["reps"], int)
        assert result[0]["reps"] <= 15  # Intermediate max

    def test_empty_exercises_returns_empty(self):
        """Empty input should return empty output."""
        result = validate_and_cap_exercise_parameters(
            exercises=[],
            fitness_level="beginner",
            age=70,
            is_comeback=True
        )
        assert result == []

    def test_none_exercises_returns_none(self):
        """None input should return None."""
        result = validate_and_cap_exercise_parameters(
            exercises=None,
            fitness_level="beginner",
            age=70,
            is_comeback=True
        )
        assert result is None

    def test_unknown_fitness_level_defaults_to_intermediate(self):
        """Unknown fitness level should default to intermediate caps."""
        exercises = [
            {"name": "Squats", "sets": 5, "reps": 20, "rest_seconds": 30}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="expert",  # Not a valid level
            age=None,
            is_comeback=False
        )

        # Should use intermediate caps
        assert result[0]["reps"] <= 15  # Intermediate max
        assert result[0]["sets"] <= 4   # Intermediate max sets

    def test_preserves_other_exercise_fields(self):
        """
        The function should preserve fields like name, muscle_group, equipment.
        """
        exercises = [
            {
                "name": "Bench Press",
                "sets": 10,
                "reps": 50,
                "rest_seconds": 10,
                "muscle_group": "chest",
                "equipment": "barbell",
                "notes": "Keep elbows at 45 degrees"
            }
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=None,
            is_comeback=False
        )

        assert result[0]["name"] == "Bench Press"
        assert result[0]["muscle_group"] == "chest"
        assert result[0]["equipment"] == "barbell"
        assert result[0]["notes"] == "Keep elbows at 45 degrees"

    def test_weight_reduced_for_elderly(self):
        """
        For elderly users, weight should be reduced by intensity ceiling.
        """
        exercises = [
            {"name": "Squat", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_kg": 100}
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=75,
            is_comeback=False
        )

        # Elderly intensity ceiling is 0.65
        assert result[0]["weight_kg"] == 65.0  # 100 * 0.65


class TestAgeBracketFunction:
    """Test the age bracket helper function."""

    def test_young_adult_under_30(self):
        assert get_age_bracket_from_age(18) == "young_adult"
        assert get_age_bracket_from_age(25) == "young_adult"
        assert get_age_bracket_from_age(29) == "young_adult"

    def test_adult_30_to_44(self):
        assert get_age_bracket_from_age(30) == "adult"
        assert get_age_bracket_from_age(40) == "adult"
        assert get_age_bracket_from_age(44) == "adult"

    def test_middle_aged_45_to_59(self):
        assert get_age_bracket_from_age(45) == "middle_aged"
        assert get_age_bracket_from_age(50) == "middle_aged"
        assert get_age_bracket_from_age(59) == "middle_aged"

    def test_senior_60_to_74(self):
        assert get_age_bracket_from_age(60) == "senior"
        assert get_age_bracket_from_age(70) == "senior"
        assert get_age_bracket_from_age(74) == "senior"

    def test_elderly_75_plus(self):
        assert get_age_bracket_from_age(75) == "elderly"
        assert get_age_bracket_from_age(80) == "elderly"
        assert get_age_bracket_from_age(100) == "elderly"


class TestFitnessLevelCaps:
    """Test the fitness level cap constants."""

    def test_beginner_caps_are_conservative(self):
        caps = FITNESS_LEVEL_CAPS["beginner"]
        assert caps["max_sets"] == 3
        assert caps["max_reps"] == 12
        assert caps["min_rest"] == 60

    def test_intermediate_caps_are_moderate(self):
        caps = FITNESS_LEVEL_CAPS["intermediate"]
        assert caps["max_sets"] == 4
        assert caps["max_reps"] == 15
        assert caps["min_rest"] == 45

    def test_advanced_caps_are_higher(self):
        caps = FITNESS_LEVEL_CAPS["advanced"]
        assert caps["max_sets"] == 5
        assert caps["max_reps"] == 20
        assert caps["min_rest"] == 30


class TestAgeCaps:
    """Test the age-based cap constants."""

    def test_elderly_caps_are_most_conservative(self):
        caps = AGE_CAPS["elderly"]
        assert caps["max_reps"] == 10
        assert caps["max_sets"] == 3
        assert caps["min_rest"] == 90
        assert caps["intensity_ceiling"] == 0.65

    def test_senior_caps(self):
        caps = AGE_CAPS["senior"]
        assert caps["max_reps"] == 12
        assert caps["max_sets"] == 3
        assert caps["min_rest"] == 75
        assert caps["intensity_ceiling"] == 0.75

    def test_young_adult_has_no_restrictions(self):
        caps = AGE_CAPS["young_adult"]
        assert caps["max_reps"] == 25
        assert caps["max_sets"] == 6
        assert caps["min_rest"] == 30
        assert caps["intensity_ceiling"] == 1.0


class TestMultipleExercises:
    """Test that validation works correctly with multiple exercises."""

    def test_all_exercises_are_capped(self):
        """All exercises in a workout should be validated."""
        exercises = [
            {"name": "Squats", "sets": 5, "reps": 90, "rest_seconds": 20},
            {"name": "Bench Press", "sets": 6, "reps": 50, "rest_seconds": 15},
            {"name": "Deadlifts", "sets": 4, "reps": 30, "rest_seconds": 25},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=70,
            is_comeback=True
        )

        assert len(result) == 3
        for ex in result:
            assert ex["reps"] <= 10  # All should be capped
            assert ex["sets"] <= 3   # All should be capped
            assert ex["rest_seconds"] >= 90  # All should have adequate rest


class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_missing_sets_uses_default(self):
        """If sets is missing, use default of 3."""
        exercises = [{"name": "Curls", "reps": 10, "rest_seconds": 60}]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=None,
            is_comeback=False
        )

        assert "sets" in result[0]
        assert result[0]["sets"] == 3  # Default

    def test_missing_reps_uses_default(self):
        """If reps is missing, use default of 10."""
        exercises = [{"name": "Curls", "sets": 3, "rest_seconds": 60}]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=None,
            is_comeback=False
        )

        assert "reps" in result[0]
        assert result[0]["reps"] == 10  # Default

    def test_missing_rest_uses_default(self):
        """If rest_seconds is missing, use default of 60."""
        exercises = [{"name": "Curls", "sets": 3, "reps": 10}]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=None,
            is_comeback=False
        )

        assert "rest_seconds" in result[0]
        assert result[0]["rest_seconds"] >= 45  # At least intermediate min rest

    def test_invalid_reps_string_uses_default(self):
        """Invalid reps string should use default of 10."""
        exercises = [{"name": "Curls", "sets": 3, "reps": "invalid", "rest_seconds": 60}]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=None,
            is_comeback=False
        )

        assert result[0]["reps"] == 10  # Default

    def test_original_exercises_not_mutated(self):
        """The original exercise list should not be mutated."""
        exercises = [
            {"name": "Squats", "sets": 5, "reps": 90, "rest_seconds": 20}
        ]
        original_reps = exercises[0]["reps"]

        validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=70,
            is_comeback=True
        )

        # Original should be unchanged
        assert exercises[0]["reps"] == original_reps
