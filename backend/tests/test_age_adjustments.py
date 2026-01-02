"""
Tests for age-based workout intensity caps.

These tests verify that the age-based adjustment system correctly:
1. Identifies age brackets
2. Applies rep/set caps for different age groups
3. Adjusts rest times for older users
4. Reduces weight recommendations based on intensity ceiling
5. Works correctly with combined fitness level + age caps
"""
import pytest
from typing import Dict, List

# Import the functions we're testing
from services.adaptive_workout_service import (
    AGE_ADJUSTMENTS,
    get_age_bracket,
    get_age_adjustments,
    apply_age_caps,
    get_senior_workout_prompt_additions,
)
from api.v1.workouts.utils import (
    AGE_CAPS,
    get_age_bracket_from_age,
    validate_and_cap_exercise_parameters,
)


class TestAgeBracketDetection:
    """Test age bracket detection functions."""

    def test_young_adult_bracket(self):
        """Users under 30 should be 'young_adult'."""
        assert get_age_bracket(18) == "young_adult"
        assert get_age_bracket(25) == "young_adult"
        assert get_age_bracket(29) == "young_adult"
        # Also test utils version
        assert get_age_bracket_from_age(25) == "young_adult"

    def test_adult_bracket(self):
        """Users 30-44 should be 'adult'."""
        assert get_age_bracket(30) == "adult"
        assert get_age_bracket(35) == "adult"
        assert get_age_bracket(44) == "adult"
        assert get_age_bracket_from_age(40) == "adult"

    def test_middle_aged_bracket(self):
        """Users 45-59 should be 'middle_aged'."""
        assert get_age_bracket(45) == "middle_aged"
        assert get_age_bracket(50) == "middle_aged"
        assert get_age_bracket(59) == "middle_aged"
        assert get_age_bracket_from_age(55) == "middle_aged"

    def test_senior_bracket(self):
        """Users 60-74 should be 'senior'."""
        assert get_age_bracket(60) == "senior"
        assert get_age_bracket(65) == "senior"
        assert get_age_bracket(70) == "senior"
        assert get_age_bracket(74) == "senior"
        assert get_age_bracket_from_age(68) == "senior"

    def test_elderly_bracket(self):
        """Users 75+ should be 'elderly'."""
        assert get_age_bracket(75) == "elderly"
        assert get_age_bracket(80) == "elderly"
        assert get_age_bracket(90) == "elderly"
        assert get_age_bracket_from_age(85) == "elderly"


class TestAgeAdjustmentValues:
    """Test that age adjustments have correct values."""

    def test_young_adult_has_highest_limits(self):
        """Young adults should have the highest limits."""
        adjustments = get_age_adjustments(25)
        assert adjustments["max_reps_per_exercise"] == 25
        assert adjustments["max_sets_per_exercise"] == 6
        assert adjustments["rest_multiplier"] == 1.0
        assert adjustments["intensity_ceiling"] == 1.0

    def test_elderly_has_lowest_limits(self):
        """Elderly users should have the most conservative limits."""
        adjustments = get_age_adjustments(80)
        assert adjustments["max_reps_per_exercise"] == 10
        assert adjustments["max_sets_per_exercise"] == 3
        assert adjustments["rest_multiplier"] == 2.0
        assert adjustments["intensity_ceiling"] == 0.65

    def test_senior_limits(self):
        """Senior users (60-74) should have reduced limits."""
        adjustments = get_age_adjustments(70)
        assert adjustments["max_reps_per_exercise"] == 12
        assert adjustments["max_sets_per_exercise"] == 3
        assert adjustments["rest_multiplier"] == 1.5
        assert adjustments["intensity_ceiling"] == 0.75

    def test_middle_aged_limits(self):
        """Middle-aged users (45-59) should have moderately reduced limits."""
        adjustments = get_age_adjustments(50)
        assert adjustments["max_reps_per_exercise"] == 16
        assert adjustments["max_sets_per_exercise"] == 4
        assert adjustments["rest_multiplier"] == 1.25
        assert adjustments["intensity_ceiling"] == 0.85


class TestApplyAgeCaps:
    """Test the apply_age_caps function."""

    def test_70_year_old_gets_capped_reps(self):
        """A 70-year-old user should have reps capped at 12."""
        exercises = [
            {"name": "Squat", "sets": 5, "reps": 20, "rest_seconds": 60},
            {"name": "Bench Press", "sets": 4, "reps": 15, "rest_seconds": 60},
        ]

        result = apply_age_caps(exercises, 70)

        # Reps should be capped at 12 for senior
        assert result[0]["reps"] == 12
        assert result[1]["reps"] == 12

        # Sets should be capped at 3 for senior
        assert result[0]["sets"] == 3
        assert result[1]["sets"] == 3

        # Rest should be multiplied by 1.5
        assert result[0]["rest_seconds"] == 90
        assert result[1]["rest_seconds"] == 90

    def test_25_year_old_no_caps_applied(self):
        """A 25-year-old should not have their workout capped down."""
        exercises = [
            {"name": "Squat", "sets": 5, "reps": 20, "rest_seconds": 60},
        ]

        result = apply_age_caps(exercises, 25)

        # Values should remain the same (within young adult limits)
        assert result[0]["reps"] == 20
        assert result[0]["sets"] == 5
        assert result[0]["rest_seconds"] == 60

    def test_age_caps_weight_reduction(self):
        """Weight should be reduced based on intensity ceiling for older users."""
        exercises = [
            {"name": "Squat", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_kg": 100},
        ]

        # 70-year-old (senior, intensity_ceiling=0.75)
        result = apply_age_caps(exercises, 70)
        assert result[0]["weight_kg"] == 75.0

        # Reset for elderly test
        exercises = [
            {"name": "Squat", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_kg": 100},
        ]

        # 80-year-old (elderly, intensity_ceiling=0.65)
        result = apply_age_caps(exercises, 80)
        assert result[0]["weight_kg"] == 65.0

    def test_no_caps_for_missing_age(self):
        """If age is None, no caps should be applied."""
        exercises = [
            {"name": "Squat", "sets": 5, "reps": 20, "rest_seconds": 60},
        ]

        result = apply_age_caps(exercises, None)
        assert result[0]["reps"] == 20
        assert result[0]["sets"] == 5

    def test_no_caps_for_minors(self):
        """If age < 18, no adult age caps should be applied."""
        exercises = [
            {"name": "Squat", "sets": 5, "reps": 20, "rest_seconds": 60},
        ]

        result = apply_age_caps(exercises, 16)
        assert result[0]["reps"] == 20
        assert result[0]["sets"] == 5


class TestSeniorWorkoutPromptAdditions:
    """Test the get_senior_workout_prompt_additions function."""

    def test_no_additions_for_young_users(self):
        """Users under 60 should not get senior prompt additions."""
        assert get_senior_workout_prompt_additions(25) is None
        assert get_senior_workout_prompt_additions(40) is None
        assert get_senior_workout_prompt_additions(59) is None

    def test_senior_user_gets_additions(self):
        """Users 60+ should get senior-specific prompt additions."""
        result = get_senior_workout_prompt_additions(65)

        assert result is not None
        assert "max_reps" in result
        assert "max_sets" in result
        assert "extra_rest_percent" in result
        assert "critical_instructions" in result
        assert "movement_priorities" in result
        assert "movements_to_avoid" in result

        # Check specific values for senior (60-74)
        assert result["max_reps"] == 12
        assert result["max_sets"] == 3
        assert result["extra_rest_percent"] == 50  # (1.5 - 1.0) * 100

    def test_elderly_user_gets_stricter_additions(self):
        """Users 75+ should get even stricter additions."""
        result = get_senior_workout_prompt_additions(80)

        assert result is not None
        assert result["age_bracket"] == "elderly"
        assert result["max_reps"] == 10
        assert result["extra_rest_percent"] == 100  # (2.0 - 1.0) * 100
        assert result["intensity_ceiling"] == 0.65

        # Elderly should have additional movements to avoid
        assert "barbell exercises" in result["movements_to_avoid"]

    def test_senior_prompt_contains_critical_instructions(self):
        """Senior prompt additions should contain critical workout limits."""
        result = get_senior_workout_prompt_additions(70)

        critical = result["critical_instructions"]
        assert "CRITICAL FOR SENIOR USER" in critical
        assert "Maximum 12 reps" in critical
        assert "Maximum 3 sets" in critical
        assert "50% longer rest" in critical
        assert "AVOID" in critical


class TestValidateAndCapExerciseParameters:
    """Test the validate_and_cap_exercise_parameters function from utils."""

    def test_fitness_level_and_age_combined(self):
        """Both fitness level and age caps should be applied."""
        exercises = [
            {"name": "Squat", "sets": 6, "reps": 30, "rest_seconds": 30},
        ]

        # Beginner + 70 years old = most conservative caps
        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=70,
            is_comeback=False
        )

        # Should be capped by both beginner limits AND senior limits
        # Beginner max_sets=3, max_reps=12 (already <= senior)
        # Senior max_sets=3, max_reps=12
        assert result[0]["sets"] == 3
        assert result[0]["reps"] == 12
        # Rest should be max(60 [beginner], 75 [senior]) = 75, then * 1.5 = 112
        assert result[0]["rest_seconds"] >= 90

    def test_comeback_mode_further_reduces(self):
        """Comeback mode should further reduce already age-capped exercises."""
        exercises = [
            {"name": "Squat", "sets": 4, "reps": 15, "rest_seconds": 60},
        ]

        # 70-year-old in comeback mode
        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=70,
            is_comeback=True
        )

        # First, age caps apply: reps=12, sets=3, rest=90
        # Then comeback: reps*0.7=8, sets-1=2, rest*1.2=108
        assert result[0]["reps"] <= 12 * 0.7 + 1  # Allow for rounding
        assert result[0]["sets"] == 2
        assert result[0]["rest_seconds"] >= 100

    def test_weight_reduction_for_seniors(self):
        """Weight should be reduced for senior users."""
        exercises = [
            {"name": "Squat", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_kg": 100},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=70,  # Senior: intensity_ceiling=0.75
            is_comeback=False
        )

        # Weight should be reduced by intensity ceiling
        assert result[0]["weight_kg"] == 75.0

    def test_elderly_gets_most_conservative(self):
        """Elderly users (75+) should get the most conservative caps."""
        exercises = [
            {"name": "Squat", "sets": 5, "reps": 20, "rest_seconds": 30, "weight_kg": 100},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="advanced",
            age=80,  # Elderly
            is_comeback=False
        )

        # Elderly caps: reps=10, sets=3, rest*2.0, intensity=0.65
        assert result[0]["reps"] == 10
        assert result[0]["sets"] == 3
        assert result[0]["rest_seconds"] >= 60  # min_rest*2
        assert result[0]["weight_kg"] == 65.0

    def test_string_reps_handled_correctly(self):
        """String reps like '8-12' should be parsed and capped."""
        exercises = [
            {"name": "Squat", "sets": 3, "reps": "15-20", "rest_seconds": 60},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=65,  # Senior
            is_comeback=False
        )

        # "15-20" -> takes 20, then caps to 12 for senior
        assert result[0]["reps"] == 12


class TestAgeAdjustmentConstants:
    """Test that the AGE_ADJUSTMENTS and AGE_CAPS constants are aligned."""

    def test_all_brackets_present_in_both(self):
        """All age brackets should be present in both constants."""
        expected_brackets = ["young_adult", "adult", "middle_aged", "senior", "elderly"]

        for bracket in expected_brackets:
            assert bracket in AGE_ADJUSTMENTS, f"Missing {bracket} in AGE_ADJUSTMENTS"
            assert bracket in AGE_CAPS, f"Missing {bracket} in AGE_CAPS"

    def test_values_aligned(self):
        """Max reps and sets should align between the two constants."""
        for bracket in ["young_adult", "adult", "middle_aged", "senior", "elderly"]:
            adj = AGE_ADJUSTMENTS[bracket]
            caps = AGE_CAPS[bracket]

            assert adj["max_reps_per_exercise"] == caps["max_reps"], \
                f"Misaligned max_reps for {bracket}"
            assert adj["max_sets_per_exercise"] == caps["max_sets"], \
                f"Misaligned max_sets for {bracket}"

    def test_intensity_ceilings_are_valid(self):
        """All intensity ceilings should be between 0 and 1."""
        for bracket, adj in AGE_ADJUSTMENTS.items():
            ceiling = adj["intensity_ceiling"]
            assert 0 < ceiling <= 1.0, f"Invalid intensity_ceiling for {bracket}: {ceiling}"

    def test_rest_multipliers_are_valid(self):
        """Rest multipliers should be >= 1.0 (never less rest)."""
        for bracket, adj in AGE_ADJUSTMENTS.items():
            mult = adj["rest_multiplier"]
            assert mult >= 1.0, f"Invalid rest_multiplier for {bracket}: {mult}"


class TestIntegrationScenarios:
    """Integration tests for realistic scenarios."""

    def test_70_year_old_beginner_comeback(self):
        """A 70-year-old beginner returning from break should get very conservative workout."""
        exercises = [
            {"name": "Bodyweight Squat", "sets": 4, "reps": 15, "rest_seconds": 45, "weight_kg": None},
            {"name": "Wall Push-ups", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_kg": None},
            {"name": "Chair Stand", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_kg": None},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=70,
            is_comeback=True
        )

        # All exercises should have very conservative parameters
        for ex in result:
            assert ex["sets"] <= 2, f"{ex['name']} has too many sets"
            # Beginner caps: 12 reps, senior caps: 12 reps, comeback: *0.7 = 8 (but min 3)
            assert ex["reps"] <= 12, f"{ex['name']} has too many reps"
            assert ex["rest_seconds"] >= 90, f"{ex['name']} has too little rest"

    def test_45_year_old_intermediate(self):
        """A 45-year-old intermediate user should get moderate caps."""
        exercises = [
            {"name": "Barbell Squat", "sets": 4, "reps": 12, "rest_seconds": 60, "weight_kg": 80},
            {"name": "Bench Press", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_kg": 60},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="intermediate",
            age=45,  # Middle-aged
            is_comeback=False
        )

        # Middle-aged caps: 16 reps, 4 sets, intensity_ceiling=0.85
        for ex in result:
            assert ex["sets"] <= 4
            assert ex["reps"] <= 16

        # Weight should be reduced by 15%
        assert result[0]["weight_kg"] == 68.0  # 80 * 0.85
        assert result[1]["weight_kg"] == 51.0  # 60 * 0.85

    def test_25_year_old_advanced_no_caps(self):
        """A 25-year-old advanced user should have minimal caps."""
        exercises = [
            {"name": "Squat", "sets": 5, "reps": 20, "rest_seconds": 45, "weight_kg": 100},
        ]

        result = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="advanced",
            age=25,
            is_comeback=False
        )

        # Advanced caps: 5 sets, 20 reps - should be unchanged
        assert result[0]["sets"] == 5
        assert result[0]["reps"] == 20
        assert result[0]["weight_kg"] == 100  # No intensity reduction


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
