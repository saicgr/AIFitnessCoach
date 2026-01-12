"""
Tests for exercise difficulty filtering and ranking.

The system uses a RATIO-BASED approach where:
- All exercises are available to all users
- Difficulty is used for RANKING, not hard filtering
- Exception: Elite (10) exercises are filtered for beginners to prevent injury
"""

import pytest
from services.exercise_rag.service import (
    get_difficulty_numeric,
    is_exercise_too_difficult,
    is_exercise_too_difficult_strict,
    get_difficulty_score,
    get_exercise_difficulty_category,
    DIFFICULTY_CEILING,
    DIFFICULTY_STRING_TO_NUM,
    DIFFICULTY_RATIOS,
)


class TestDifficultyNumericConversion:
    """Test conversion of difficulty values to numeric scale."""

    def test_string_beginner_returns_2(self):
        assert get_difficulty_numeric("beginner") == 2

    def test_string_intermediate_returns_5(self):
        assert get_difficulty_numeric("intermediate") == 5

    def test_string_advanced_returns_8(self):
        assert get_difficulty_numeric("advanced") == 8

    def test_string_elite_returns_10(self):
        assert get_difficulty_numeric("elite") == 10

    def test_numeric_int_returns_same(self):
        assert get_difficulty_numeric(7) == 7

    def test_numeric_float_returns_int(self):
        assert get_difficulty_numeric(6.5) == 6

    def test_none_returns_default_2(self):
        """None defaults to beginner (2) so all users can access."""
        assert get_difficulty_numeric(None) == 2

    def test_empty_string_returns_default_2(self):
        """Empty string defaults to beginner (2)."""
        assert get_difficulty_numeric("") == 2

    def test_unknown_string_returns_default_2(self):
        """Unknown string defaults to beginner (2)."""
        assert get_difficulty_numeric("super_hard") == 2

    def test_case_insensitive(self):
        assert get_difficulty_numeric("BEGINNER") == 2
        assert get_difficulty_numeric("Intermediate") == 5


class TestIsExerciseTooDifficult:
    """Test the exercise difficulty filtering logic (ratio-based system).

    The new system only hard-filters Elite (10) exercises for beginners.
    All other exercises are ranked, not filtered.
    """

    def test_beginner_can_access_all_non_elite_exercises(self):
        """Beginners can access beginner, intermediate, and advanced exercises."""
        assert is_exercise_too_difficult("beginner", "beginner") is False
        assert is_exercise_too_difficult("intermediate", "beginner") is False
        assert is_exercise_too_difficult("advanced", "beginner") is False
        assert is_exercise_too_difficult(1, "beginner") is False
        assert is_exercise_too_difficult(5, "beginner") is False
        assert is_exercise_too_difficult(8, "beginner") is False
        assert is_exercise_too_difficult(9, "beginner") is False

    def test_beginner_cannot_access_elite_exercises(self):
        """Elite (10) exercises are filtered for beginners - safety measure."""
        assert is_exercise_too_difficult("elite", "beginner") is True
        assert is_exercise_too_difficult(10, "beginner") is True

    def test_intermediate_can_access_all_exercises(self):
        """Intermediate users can access all exercises including elite."""
        assert is_exercise_too_difficult("beginner", "intermediate") is False
        assert is_exercise_too_difficult("intermediate", "intermediate") is False
        assert is_exercise_too_difficult("advanced", "intermediate") is False
        assert is_exercise_too_difficult("elite", "intermediate") is False
        assert is_exercise_too_difficult(10, "intermediate") is False

    def test_advanced_can_access_all_exercises(self):
        """Advanced users have no restrictions."""
        assert is_exercise_too_difficult("beginner", "advanced") is False
        assert is_exercise_too_difficult("intermediate", "advanced") is False
        assert is_exercise_too_difficult("advanced", "advanced") is False
        assert is_exercise_too_difficult("elite", "advanced") is False
        assert is_exercise_too_difficult(10, "advanced") is False

    def test_case_insensitive_fitness_level(self):
        assert is_exercise_too_difficult(10, "BEGINNER") is True
        assert is_exercise_too_difficult(10, "Beginner") is True


class TestIsExerciseTooDifficultStrict:
    """Test the STRICT difficulty filtering (original hard-filter logic)."""

    def test_beginner_cannot_do_advanced_exercises_strict(self):
        """Advanced exercises are filtered for beginners in strict mode."""
        assert is_exercise_too_difficult_strict("advanced", "beginner") is True
        assert is_exercise_too_difficult_strict(8, "beginner") is True

    def test_beginner_can_do_beginner_exercises_strict(self):
        """Beginner exercises pass in strict mode."""
        assert is_exercise_too_difficult_strict("beginner", "beginner") is False
        assert is_exercise_too_difficult_strict(3, "beginner") is False

    def test_beginner_cannot_do_intermediate_exercises_strict(self):
        """Intermediate exercises are filtered for beginners in strict mode."""
        assert is_exercise_too_difficult_strict("intermediate", "beginner") is True
        assert is_exercise_too_difficult_strict(5, "beginner") is True


class TestDifficultyCategories:
    """Test exercise difficulty categorization."""

    def test_beginner_category(self):
        assert get_exercise_difficulty_category("beginner") == "beginner"
        assert get_exercise_difficulty_category(1) == "beginner"
        assert get_exercise_difficulty_category(2) == "beginner"
        assert get_exercise_difficulty_category(3) == "beginner"

    def test_intermediate_category(self):
        assert get_exercise_difficulty_category("intermediate") == "intermediate"
        assert get_exercise_difficulty_category(4) == "intermediate"
        assert get_exercise_difficulty_category(5) == "intermediate"
        assert get_exercise_difficulty_category(6) == "intermediate"

    def test_advanced_category(self):
        assert get_exercise_difficulty_category("advanced") == "advanced"
        assert get_exercise_difficulty_category(7) == "advanced"
        assert get_exercise_difficulty_category(8) == "advanced"
        assert get_exercise_difficulty_category(9) == "advanced"
        assert get_exercise_difficulty_category(10) == "advanced"


class TestDifficultyScoring:
    """Test difficulty score calculation for ranking."""

    def test_beginner_user_prefers_beginner_exercises(self):
        """Beginner users get higher scores for beginner exercises."""
        beginner_score = get_difficulty_score("beginner", "beginner")
        intermediate_score = get_difficulty_score("intermediate", "beginner")
        advanced_score = get_difficulty_score("advanced", "beginner")

        assert beginner_score > intermediate_score
        assert intermediate_score > advanced_score

    def test_advanced_user_prefers_advanced_exercises(self):
        """Advanced users get higher scores for advanced exercises."""
        beginner_score = get_difficulty_score("beginner", "advanced")
        intermediate_score = get_difficulty_score("intermediate", "advanced")
        advanced_score = get_difficulty_score("advanced", "advanced")

        assert advanced_score > intermediate_score
        assert advanced_score > beginner_score

    def test_intermediate_user_balanced_preference(self):
        """Intermediate users prefer intermediate exercises."""
        beginner_score = get_difficulty_score("beginner", "intermediate")
        intermediate_score = get_difficulty_score("intermediate", "intermediate")
        advanced_score = get_difficulty_score("advanced", "intermediate")

        assert intermediate_score >= beginner_score
        assert intermediate_score >= advanced_score

    def test_scores_are_in_valid_range(self):
        """All scores should be between 0 and 1."""
        for user_level in ["beginner", "intermediate", "advanced"]:
            for exercise_level in ["beginner", "intermediate", "advanced"]:
                score = get_difficulty_score(exercise_level, user_level)
                assert 0 <= score <= 1, f"Score {score} out of range for {exercise_level}/{user_level}"


class TestDifficultyRatios:
    """Test the difficulty ratio configuration."""

    def test_all_fitness_levels_have_ratios(self):
        """All fitness levels should have ratio configurations."""
        assert "beginner" in DIFFICULTY_RATIOS
        assert "intermediate" in DIFFICULTY_RATIOS
        assert "advanced" in DIFFICULTY_RATIOS

    def test_ratios_sum_to_one(self):
        """Each fitness level's ratios should sum to 1.0."""
        for level, ratios in DIFFICULTY_RATIOS.items():
            total = sum(ratios.values())
            assert abs(total - 1.0) < 0.01, f"{level} ratios sum to {total}, not 1.0"

    def test_beginner_prefers_beginner(self):
        """Beginner ratio config should prefer beginner exercises."""
        ratios = DIFFICULTY_RATIOS["beginner"]
        assert ratios["beginner"] > ratios["advanced"]

    def test_advanced_prefers_advanced(self):
        """Advanced ratio config should prefer advanced exercises."""
        ratios = DIFFICULTY_RATIOS["advanced"]
        assert ratios["advanced"] > ratios["beginner"]


class TestDifficultyCeilings:
    """Test the difficulty ceiling constants (used for ranking preferences)."""

    def test_beginner_ceiling_is_6(self):
        assert DIFFICULTY_CEILING["beginner"] == 6

    def test_intermediate_ceiling_is_8(self):
        assert DIFFICULTY_CEILING["intermediate"] == 8

    def test_advanced_ceiling_is_10(self):
        assert DIFFICULTY_CEILING["advanced"] == 10


class TestEliteExerciseSafety:
    """
    Test that Elite exercises are filtered for beginners.
    This is a safety measure to prevent injury from extremely advanced movements.
    """

    def test_elite_filtered_for_beginner(self):
        """Elite exercises should never be given to beginners."""
        assert is_exercise_too_difficult("elite", "beginner") is True
        assert is_exercise_too_difficult(10, "beginner") is True

    def test_elite_allowed_for_intermediate(self):
        """Elite exercises are allowed for intermediate users."""
        assert is_exercise_too_difficult("elite", "intermediate") is False
        assert is_exercise_too_difficult(10, "intermediate") is False

    def test_elite_allowed_for_advanced(self):
        """Elite exercises are allowed for advanced users."""
        assert is_exercise_too_difficult("elite", "advanced") is False
        assert is_exercise_too_difficult(10, "advanced") is False

    def test_beginner_with_positive_adjustment_can_access_elite(self):
        """Beginners with positive difficulty adjustment can access elite."""
        assert is_exercise_too_difficult("elite", "beginner", difficulty_adjustment=1) is False
        assert is_exercise_too_difficult(10, "beginner", difficulty_adjustment=2) is False


class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_none_fitness_level_defaults_to_intermediate(self):
        """None fitness level should default to intermediate (no elite restriction)."""
        # Intermediate users can access elite exercises
        assert is_exercise_too_difficult(10, None) is False

    def test_unknown_fitness_level_defaults_to_intermediate(self):
        """Unknown fitness level should default to intermediate."""
        assert is_exercise_too_difficult(10, "unknown_level") is False
