"""
Tests for exercise difficulty filtering.

Ensures beginners don't get advanced exercises like Muscle-Ups.
"""

import pytest
from services.exercise_rag.service import (
    get_difficulty_numeric,
    is_exercise_too_difficult,
    DIFFICULTY_CEILING,
    DIFFICULTY_STRING_TO_NUM,
)


class TestDifficultyNumericConversion:
    """Test conversion of difficulty values to numeric scale."""

    def test_string_beginner_returns_2(self):
        assert get_difficulty_numeric("beginner") == 2

    def test_string_intermediate_returns_5(self):
        assert get_difficulty_numeric("intermediate") == 5

    def test_string_advanced_returns_8(self):
        assert get_difficulty_numeric("advanced") == 8

    def test_numeric_int_returns_same(self):
        assert get_difficulty_numeric(7) == 7

    def test_numeric_float_returns_int(self):
        assert get_difficulty_numeric(6.5) == 6

    def test_none_returns_default_5(self):
        assert get_difficulty_numeric(None) == 5

    def test_empty_string_returns_default_5(self):
        assert get_difficulty_numeric("") == 5

    def test_unknown_string_returns_default_5(self):
        assert get_difficulty_numeric("super_hard") == 5

    def test_case_insensitive(self):
        assert get_difficulty_numeric("BEGINNER") == 2
        assert get_difficulty_numeric("Intermediate") == 5


class TestIsExerciseTooDifficult:
    """Test the exercise difficulty filtering logic."""

    def test_beginner_cannot_do_advanced_exercises(self):
        # Advanced exercise (difficulty 8) should be filtered for beginners
        assert is_exercise_too_difficult("advanced", "beginner") is True
        assert is_exercise_too_difficult(8, "beginner") is True
        assert is_exercise_too_difficult(9, "beginner") is True
        assert is_exercise_too_difficult(10, "beginner") is True

    def test_beginner_can_do_beginner_exercises(self):
        # Beginner exercises should be allowed for beginners
        assert is_exercise_too_difficult("beginner", "beginner") is False
        assert is_exercise_too_difficult(1, "beginner") is False
        assert is_exercise_too_difficult(2, "beginner") is False
        assert is_exercise_too_difficult(3, "beginner") is False

    def test_beginner_cannot_do_intermediate_exercises(self):
        # Intermediate exercises (difficulty 5) exceed beginner ceiling (3)
        assert is_exercise_too_difficult("intermediate", "beginner") is True
        assert is_exercise_too_difficult(5, "beginner") is True

    def test_intermediate_can_do_intermediate_exercises(self):
        # Intermediate users can do intermediate exercises
        assert is_exercise_too_difficult("intermediate", "intermediate") is False
        assert is_exercise_too_difficult(5, "intermediate") is False
        assert is_exercise_too_difficult(6, "intermediate") is False

    def test_intermediate_cannot_do_advanced_exercises(self):
        # Advanced exercises exceed intermediate ceiling
        assert is_exercise_too_difficult("advanced", "intermediate") is True
        assert is_exercise_too_difficult(8, "intermediate") is True

    def test_advanced_can_do_any_exercise(self):
        # Advanced users have no restrictions
        assert is_exercise_too_difficult("beginner", "advanced") is False
        assert is_exercise_too_difficult("intermediate", "advanced") is False
        assert is_exercise_too_difficult("advanced", "advanced") is False
        assert is_exercise_too_difficult(10, "advanced") is False

    def test_case_insensitive_fitness_level(self):
        assert is_exercise_too_difficult(8, "BEGINNER") is True
        assert is_exercise_too_difficult(8, "Beginner") is True


class TestDifficultyCeilings:
    """Test the difficulty ceiling constants are correct."""

    def test_beginner_ceiling_is_3(self):
        assert DIFFICULTY_CEILING["beginner"] == 3

    def test_intermediate_ceiling_is_6(self):
        assert DIFFICULTY_CEILING["intermediate"] == 6

    def test_advanced_ceiling_is_10(self):
        assert DIFFICULTY_CEILING["advanced"] == 10


class TestAdvancedExerciseExamples:
    """
    Test specific exercise examples that beginners should NOT get.
    These are exercises that require significant skill/strength.
    """

    # These should have difficulty > 3 in the database
    ADVANCED_EXERCISE_DIFFICULTIES = {
        "muscle_up": 9,
        "pull_up": 7,
        "pistol_squat": 8,
        "handstand_pushup": 9,
        "one_arm_pushup": 8,
        "planche": 10,
        "front_lever": 9,
    }

    def test_muscle_up_filtered_for_beginner(self):
        """Muscle-ups should never be given to beginners."""
        assert is_exercise_too_difficult(9, "beginner") is True

    def test_pull_up_filtered_for_beginner(self):
        """Regular pull-ups should be filtered for beginners."""
        assert is_exercise_too_difficult(7, "beginner") is True

    def test_pistol_squat_filtered_for_beginner(self):
        """Pistol squats require balance and strength, not for beginners."""
        assert is_exercise_too_difficult(8, "beginner") is True


class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_boundary_difficulty_3_for_beginner(self):
        """Difficulty 3 is exactly at beginner ceiling - should be allowed."""
        assert is_exercise_too_difficult(3, "beginner") is False

    def test_boundary_difficulty_4_for_beginner(self):
        """Difficulty 4 exceeds beginner ceiling - should be filtered."""
        assert is_exercise_too_difficult(4, "beginner") is True

    def test_boundary_difficulty_6_for_intermediate(self):
        """Difficulty 6 is exactly at intermediate ceiling - should be allowed."""
        assert is_exercise_too_difficult(6, "intermediate") is False

    def test_boundary_difficulty_7_for_intermediate(self):
        """Difficulty 7 exceeds intermediate ceiling - should be filtered."""
        assert is_exercise_too_difficult(7, "intermediate") is True

    def test_unknown_fitness_level_defaults_to_intermediate(self):
        """Unknown fitness level should use intermediate ceiling (6)."""
        # Difficulty 6 should be allowed
        assert is_exercise_too_difficult(6, "unknown_level") is False
        # Difficulty 7 should be filtered
        assert is_exercise_too_difficult(7, "unknown_level") is True
