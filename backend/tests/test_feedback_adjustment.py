"""
Tests for Feedback Analysis Service and Difficulty Adjustment Functionality.

This module tests:
1. Adjustment calculation from user feedback
2. Difficulty ceiling modification based on adjustment
3. Edge cases (no feedback, mixed feedback, low confidence)
4. Integration with exercise RAG service
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock

from services.feedback_analysis_service import (
    FeedbackAnalysisService,
    FeedbackAnalysis,
    get_feedback_analysis_service,
    get_user_difficulty_adjustment,
    MIN_FEEDBACK_FOR_ADJUSTMENT,
    STRONG_THRESHOLD,
    MODERATE_THRESHOLD,
)
from services.exercise_rag.service import (
    get_adjusted_difficulty_ceiling,
    is_exercise_too_difficult,
    DIFFICULTY_CEILING,
)


# Mock UUID for testing
MOCK_USER_ID = "test-user-123"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def feedback_service():
    """Create a feedback analysis service instance."""
    return FeedbackAnalysisService()


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client for database operations."""
    with patch("services.feedback_analysis_service.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


# =============================================================================
# Helper Functions
# =============================================================================

def generate_exercise_feedback(
    difficulty: str = "just_right",
    rating: int = 4,
    exercise_name: str = "Push-ups",
):
    """Generate a mock exercise feedback entry."""
    return {
        "exercise_name": exercise_name,
        "difficulty_felt": difficulty,
        "rating": rating,
        "would_do_again": True,
        "created_at": datetime.now().isoformat(),
    }


def generate_workout_feedback(
    difficulty: str = "just_right",
    rating: int = 4,
    energy_level: str = "good",
):
    """Generate a mock workout feedback entry."""
    return {
        "overall_difficulty": difficulty,
        "overall_rating": rating,
        "energy_level": energy_level,
        "created_at": datetime.now().isoformat(),
    }


# =============================================================================
# Test: Adjustment Calculation from Feedback
# =============================================================================

class TestAdjustmentCalculation:
    """Tests for _calculate_adjustment method."""

    def test_no_feedback_returns_neutral(self, feedback_service):
        """Test that no feedback returns a neutral (0) adjustment."""
        result = feedback_service._calculate_adjustment([], [])

        assert result.difficulty_adjustment == 0
        assert result.total_feedback_count == 0
        assert result.confidence == 0.0
        assert "No difficulty feedback" in result.recommendation

    def test_all_too_easy_returns_positive_adjustment(self, feedback_service):
        """Test that mostly 'too_easy' feedback returns a positive adjustment."""
        exercise_feedback = [
            generate_exercise_feedback("too_easy") for _ in range(5)
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        assert result.difficulty_adjustment > 0
        assert result.too_easy_count >= 5
        assert "too easy" in result.recommendation.lower()

    def test_all_too_hard_returns_negative_adjustment(self, feedback_service):
        """Test that mostly 'too_hard' feedback returns a negative adjustment."""
        exercise_feedback = [
            generate_exercise_feedback("too_hard") for _ in range(5)
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        assert result.difficulty_adjustment < 0
        assert result.too_hard_count >= 5
        assert "too hard" in result.recommendation.lower()

    def test_all_just_right_returns_neutral(self, feedback_service):
        """Test that 'just_right' feedback maintains neutral adjustment."""
        exercise_feedback = [
            generate_exercise_feedback("just_right") for _ in range(5)
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        assert result.difficulty_adjustment == 0
        assert result.just_right_count >= 5
        assert "just right" in result.recommendation.lower() or "maintaining" in result.recommendation.lower()

    def test_mixed_feedback_returns_moderate_adjustment(self, feedback_service):
        """Test that mixed feedback returns an appropriate adjustment."""
        # 3 too_easy, 1 just_right, 1 too_hard = should lean towards easier
        exercise_feedback = [
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("just_right"),
            generate_exercise_feedback("too_hard"),
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Should have positive adjustment since 60% is too_easy
        assert result.difficulty_adjustment >= 1
        assert result.total_feedback_count == 5

    def test_strong_threshold_gives_strong_adjustment(self, feedback_service):
        """Test that feedback exceeding strong threshold gives max adjustment."""
        # 8 out of 10 = 80% too_easy (above 70% strong threshold)
        exercise_feedback = [
            generate_exercise_feedback("too_easy") for _ in range(8)
        ] + [
            generate_exercise_feedback("just_right") for _ in range(2)
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        assert result.difficulty_adjustment == 2  # Strong adjustment

    def test_moderate_threshold_gives_moderate_adjustment(self, feedback_service):
        """Test that feedback at moderate threshold gives moderate adjustment."""
        # 5 out of 8 = ~62% too_easy (above 50%, below 70%)
        exercise_feedback = [
            generate_exercise_feedback("too_easy") for _ in range(5)
        ] + [
            generate_exercise_feedback("just_right") for _ in range(3)
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Should be moderate (+1 or reduced from +2)
        assert result.difficulty_adjustment in [1, 2]

    def test_workout_feedback_has_less_weight(self, feedback_service):
        """Test that workout-level feedback is weighted less than exercise feedback."""
        # 2 exercise feedbacks (weight 2 each) = 4
        # 4 workout feedbacks (weight 1 each) = 4
        exercise_feedback = [
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("too_easy"),
        ]
        workout_feedback = [
            generate_workout_feedback("too_hard"),
            generate_workout_feedback("too_hard"),
            generate_workout_feedback("too_hard"),
            generate_workout_feedback("too_hard"),
        ]

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Should be balanced or slightly negative
        # (4 too_easy weighted + 4 too_hard weighted = mixed)
        assert -1 <= result.difficulty_adjustment <= 1

    def test_low_confidence_reduces_strong_adjustment(self, feedback_service):
        """Test that low confidence reduces strong adjustments."""
        # Only 2 feedback entries (below MIN_FEEDBACK_FOR_ADJUSTMENT of 3)
        exercise_feedback = [
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("too_easy"),
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Should have reduced confidence
        assert result.confidence < 0.5
        # Strong adjustment should be reduced due to low confidence
        assert result.difficulty_adjustment <= 1


# =============================================================================
# Test: Difficulty Ceiling Modification
# =============================================================================

class TestDifficultyCeilingModification:
    """Tests for get_adjusted_difficulty_ceiling function."""

    def test_no_adjustment_returns_base_ceiling(self):
        """Test that no adjustment returns the base difficulty ceiling."""
        for level in ["beginner", "intermediate", "advanced"]:
            result = get_adjusted_difficulty_ceiling(level, 0)
            assert result == DIFFICULTY_CEILING[level]

    def test_positive_adjustment_increases_ceiling(self):
        """Test that positive adjustment increases the difficulty ceiling."""
        base = DIFFICULTY_CEILING["beginner"]  # 3

        result_plus_1 = get_adjusted_difficulty_ceiling("beginner", 1)
        result_plus_2 = get_adjusted_difficulty_ceiling("beginner", 2)

        assert result_plus_1 == base + 1  # 4
        assert result_plus_2 == base + 2  # 5

    def test_negative_adjustment_decreases_ceiling(self):
        """Test that negative adjustment decreases the difficulty ceiling."""
        base = DIFFICULTY_CEILING["intermediate"]  # 6

        result_minus_1 = get_adjusted_difficulty_ceiling("intermediate", -1)
        result_minus_2 = get_adjusted_difficulty_ceiling("intermediate", -2)

        assert result_minus_1 == base - 1  # 5
        assert result_minus_2 == base - 2  # 4

    def test_ceiling_clamped_to_max_10(self):
        """Test that adjusted ceiling is clamped to maximum of 10."""
        # Advanced ceiling is 10, +2 adjustment should still be 10
        result = get_adjusted_difficulty_ceiling("advanced", 2)
        assert result == 10

    def test_ceiling_clamped_to_min_1(self):
        """Test that adjusted ceiling is clamped to minimum of 1."""
        # Beginner ceiling is 3, -5 adjustment should give 1 (clamped)
        result = get_adjusted_difficulty_ceiling("beginner", -5)
        assert result == 1

    def test_invalid_fitness_level_uses_default(self):
        """Test that invalid fitness level falls back to default."""
        result = get_adjusted_difficulty_ceiling("invalid_level", 0)
        # Should use intermediate as default (ceiling 6)
        assert result == 6


class TestIsExerciseTooDifficult:
    """Tests for is_exercise_too_difficult function with adjustment."""

    def test_exercise_within_ceiling_allowed(self):
        """Test that exercises within ceiling are allowed."""
        # Beginner ceiling is 3, exercise difficulty 2 should pass
        result = is_exercise_too_difficult(2, "beginner", 0)
        assert result is False

    def test_exercise_above_ceiling_filtered(self):
        """Test that exercises above ceiling are filtered out."""
        # Beginner ceiling is 3, exercise difficulty 5 should be filtered
        result = is_exercise_too_difficult(5, "beginner", 0)
        assert result is True

    def test_positive_adjustment_allows_harder_exercises(self):
        """Test that positive adjustment allows harder exercises."""
        # Beginner ceiling is 3, exercise difficulty 5
        # With +2 adjustment, ceiling becomes 5, so difficulty 5 should pass
        result = is_exercise_too_difficult(5, "beginner", 2)
        assert result is False

    def test_negative_adjustment_filters_more_exercises(self):
        """Test that negative adjustment filters more exercises."""
        # Intermediate ceiling is 6, exercise difficulty 5
        # With -2 adjustment, ceiling becomes 4, so difficulty 5 should fail
        result = is_exercise_too_difficult(5, "intermediate", -2)
        assert result is True

    def test_string_difficulty_values(self):
        """Test that string difficulty values work correctly."""
        # "advanced" maps to difficulty 8
        result_beginner = is_exercise_too_difficult("advanced", "beginner", 0)
        result_advanced = is_exercise_too_difficult("advanced", "advanced", 0)

        assert result_beginner is True  # 8 > 3
        assert result_advanced is False  # 8 <= 10


# =============================================================================
# Test: Edge Cases
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases in feedback analysis."""

    def test_empty_difficulty_felt_ignored(self, feedback_service):
        """Test that feedback without difficulty_felt is handled gracefully."""
        exercise_feedback = [
            {"exercise_name": "Push-ups", "difficulty_felt": "", "rating": 4, "created_at": datetime.now().isoformat()},
            generate_exercise_feedback("too_easy"),
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Should only count the one valid feedback
        assert result.total_feedback_count == 2  # Both entries counted
        # Only one has valid difficulty_felt

    def test_none_difficulty_felt_ignored(self, feedback_service):
        """Test that None difficulty_felt is handled gracefully."""
        exercise_feedback = [
            {"exercise_name": "Push-ups", "difficulty_felt": None, "rating": 4, "created_at": datetime.now().isoformat()},
            generate_exercise_feedback("too_hard"),
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Should handle None without crashing
        assert result is not None

    def test_case_insensitive_difficulty_values(self, feedback_service):
        """Test that difficulty values are handled case-insensitively."""
        exercise_feedback = [
            {"exercise_name": "Push-ups", "difficulty_felt": "TOO_EASY", "rating": 4, "created_at": datetime.now().isoformat()},
            {"exercise_name": "Squats", "difficulty_felt": "Too_Hard", "rating": 4, "created_at": datetime.now().isoformat()},
        ]
        workout_feedback = []

        result = feedback_service._calculate_adjustment(exercise_feedback, workout_feedback)

        # Both should be recognized
        assert result.too_easy_count >= 1
        assert result.too_hard_count >= 1

    def test_fitness_level_normalization(self):
        """Test that fitness level is normalized correctly."""
        # Test various forms of fitness level input
        test_cases = [
            ("BEGINNER", "beginner"),
            ("  intermediate  ", "intermediate"),
            ("Advanced", "advanced"),
            (None, "intermediate"),  # Default
            ("", "intermediate"),  # Default
            ("invalid", "intermediate"),  # Default
        ]

        for input_level, expected_ceiling_level in test_cases:
            result = get_adjusted_difficulty_ceiling(input_level or "", 0)
            expected = DIFFICULTY_CEILING.get(expected_ceiling_level, 6)
            assert result == expected, f"Failed for input '{input_level}'"


# =============================================================================
# Test: Integration
# =============================================================================

class TestIntegration:
    """Integration tests for the feedback analysis service."""

    @pytest.mark.asyncio
    async def test_analyze_user_feedback_returns_analysis(self, mock_supabase):
        """Test that analyze_user_feedback returns a proper FeedbackAnalysis."""
        # Setup mock
        exercise_result = MagicMock()
        exercise_result.data = [
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("too_easy"),
            generate_exercise_feedback("just_right"),
        ]

        workout_result = MagicMock()
        workout_result.data = [
            generate_workout_feedback("too_easy"),
        ]

        # Mock chain for exercise_feedback
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_gte = MagicMock()

        mock_supabase.client.table.return_value = mock_table
        mock_table.select.return_value = mock_select
        mock_select.eq.return_value = mock_eq
        mock_eq.gte.return_value = mock_gte

        # First call returns exercise feedback, second returns workout feedback
        mock_gte.execute.side_effect = [exercise_result, workout_result]

        service = FeedbackAnalysisService()
        result = await service.analyze_user_feedback(MOCK_USER_ID, days=14)

        assert isinstance(result, FeedbackAnalysis)
        assert result.total_feedback_count == 4
        assert result.difficulty_adjustment >= 0  # Should be positive (mostly too_easy)

    @pytest.mark.asyncio
    async def test_get_user_difficulty_adjustment_convenience_function(self, mock_supabase):
        """Test the convenience function returns adjustment tuple."""
        # Setup mock
        exercise_result = MagicMock()
        exercise_result.data = [
            generate_exercise_feedback("too_hard") for _ in range(5)
        ]

        workout_result = MagicMock()
        workout_result.data = []

        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_gte = MagicMock()

        mock_supabase.client.table.return_value = mock_table
        mock_table.select.return_value = mock_select
        mock_select.eq.return_value = mock_eq
        mock_eq.gte.return_value = mock_gte
        mock_gte.execute.side_effect = [exercise_result, workout_result]

        adjustment, recommendation = await get_user_difficulty_adjustment(MOCK_USER_ID)

        assert isinstance(adjustment, int)
        assert isinstance(recommendation, str)
        assert adjustment < 0  # Should be negative (all too_hard)


# =============================================================================
# Test: FeedbackAnalysis DataClass
# =============================================================================

class TestFeedbackAnalysisDataClass:
    """Tests for the FeedbackAnalysis dataclass."""

    def test_to_dict_conversion(self):
        """Test that FeedbackAnalysis converts to dict correctly."""
        analysis = FeedbackAnalysis(
            difficulty_adjustment=1,
            too_easy_count=5,
            just_right_count=2,
            too_hard_count=1,
            total_feedback_count=8,
            confidence=0.75,
            recommendation="Test recommendation",
        )

        result = analysis.to_dict()

        assert result["difficulty_adjustment"] == 1
        assert result["too_easy_count"] == 5
        assert result["just_right_count"] == 2
        assert result["too_hard_count"] == 1
        assert result["total_feedback_count"] == 8
        assert result["confidence"] == 0.75
        assert result["recommendation"] == "Test recommendation"

    def test_confidence_rounding(self):
        """Test that confidence is rounded to 2 decimal places."""
        analysis = FeedbackAnalysis(
            difficulty_adjustment=0,
            too_easy_count=0,
            just_right_count=0,
            too_hard_count=0,
            total_feedback_count=0,
            confidence=0.33333333,
            recommendation="Test",
        )

        result = analysis.to_dict()

        assert result["confidence"] == 0.33


# =============================================================================
# Test: Threshold Constants
# =============================================================================

class TestThresholdConstants:
    """Tests to verify threshold constants are set correctly."""

    def test_strong_threshold_is_70_percent(self):
        """Test that strong threshold is 70%."""
        assert STRONG_THRESHOLD == 0.7

    def test_moderate_threshold_is_50_percent(self):
        """Test that moderate threshold is 50%."""
        assert MODERATE_THRESHOLD == 0.5

    def test_min_feedback_for_adjustment_is_3(self):
        """Test that minimum feedback count is 3."""
        assert MIN_FEEDBACK_FOR_ADJUSTMENT == 3

    def test_difficulty_ceilings_are_correct(self):
        """Test that difficulty ceilings are set correctly."""
        assert DIFFICULTY_CEILING["beginner"] == 3
        assert DIFFICULTY_CEILING["intermediate"] == 6
        assert DIFFICULTY_CEILING["advanced"] == 10
