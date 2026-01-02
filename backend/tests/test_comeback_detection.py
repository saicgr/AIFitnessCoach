"""
Tests for Break Detection and Comeback Workout System.

This module tests:
1. Break detection thresholds (short, medium, long, extended breaks)
2. Comeback adjustment calculations
3. Age + break combined adjustments (especially for seniors)
4. Comeback mode management (start, progress, end)
5. Integration with workout generation

Special focus on the 70-year-old returning after 5 weeks scenario.
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from typing import Optional

# Import the comeback service and types
from services.comeback_service import (
    ComebackService,
    BreakType,
    ComebackAdjustments,
    BreakStatus,
    get_comeback_service,
)


# =============================================================================
# Constants for Testing
# =============================================================================

MOCK_USER_ID = "test-user-comeback-123"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def comeback_service():
    """Create a fresh ComebackService instance for testing."""
    return ComebackService()


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase database client."""
    with patch("services.comeback_service.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


def create_mock_user(
    age: Optional[int] = 35,
    fitness_level: str = "intermediate",
    in_comeback_mode: bool = False,
    comeback_week: int = 0,
    comeback_started_at: Optional[str] = None,
    days_since_last_workout: int = 0,
):
    """Create a mock user object for testing."""
    return {
        "id": MOCK_USER_ID,
        "age": age,
        "fitness_level": fitness_level,
        "in_comeback_mode": in_comeback_mode,
        "comeback_week": comeback_week,
        "comeback_started_at": comeback_started_at,
        "days_since_last_workout": days_since_last_workout,
        "preferences": {},
    }


# =============================================================================
# Break Type Classification Tests
# =============================================================================

class TestBreakTypeClassification:
    """Tests for break type classification based on days off."""

    def test_active_status_under_7_days(self, comeback_service):
        """Users under 7 days off should be classified as active."""
        for days in [0, 1, 3, 5, 6]:
            break_type = comeback_service.classify_break_type(days)
            assert break_type == BreakType.ACTIVE, f"Expected ACTIVE for {days} days off"

    def test_short_break_7_to_13_days(self, comeback_service):
        """Users 7-13 days off should be classified as short break."""
        for days in [7, 8, 10, 13]:
            break_type = comeback_service.classify_break_type(days)
            assert break_type == BreakType.SHORT_BREAK, f"Expected SHORT_BREAK for {days} days off"

    def test_medium_break_14_to_27_days(self, comeback_service):
        """Users 14-27 days off should be classified as medium break."""
        for days in [14, 15, 20, 27]:
            break_type = comeback_service.classify_break_type(days)
            assert break_type == BreakType.MEDIUM_BREAK, f"Expected MEDIUM_BREAK for {days} days off"

    def test_long_break_28_to_41_days(self, comeback_service):
        """Users 28-41 days off should be classified as long break."""
        for days in [28, 30, 35, 41]:
            break_type = comeback_service.classify_break_type(days)
            assert break_type == BreakType.LONG_BREAK, f"Expected LONG_BREAK for {days} days off"

    def test_extended_break_42_plus_days(self, comeback_service):
        """Users 42+ days off should be classified as extended break."""
        for days in [42, 45, 60, 90, 180]:
            break_type = comeback_service.classify_break_type(days)
            assert break_type == BreakType.EXTENDED_BREAK, f"Expected EXTENDED_BREAK for {days} days off"


# =============================================================================
# Comeback Adjustment Calculation Tests
# =============================================================================

class TestComebackAdjustments:
    """Tests for comeback adjustment calculations."""

    def test_active_user_no_adjustments(self, comeback_service):
        """Active users should have no adjustments applied."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=3, age=35)

        assert adjustments.volume_multiplier == 1.0
        assert adjustments.intensity_multiplier == 1.0
        assert adjustments.extra_rest_seconds == 0
        assert adjustments.extra_warmup_minutes == 0

    def test_short_break_adjustments(self, comeback_service):
        """Short break should have 10% reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=7, age=35)

        # 10% volume reduction = 0.90 multiplier
        assert adjustments.volume_multiplier == 0.90
        # 10% intensity reduction = 0.90 multiplier
        assert adjustments.intensity_multiplier == 0.90
        # 15 seconds extra rest
        assert adjustments.extra_rest_seconds == 15
        # 2 minutes extra warmup
        assert adjustments.extra_warmup_minutes == 2

    def test_medium_break_adjustments(self, comeback_service):
        """Medium break (2 weeks) should have 25% volume reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=14, age=35)

        assert adjustments.volume_multiplier == 0.75
        assert adjustments.intensity_multiplier == 0.80
        assert adjustments.extra_rest_seconds == 30
        assert adjustments.extra_warmup_minutes == 3

    def test_long_break_adjustments(self, comeback_service):
        """Long break (4 weeks) should have 40% volume reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=28, age=35)

        assert adjustments.volume_multiplier == 0.60
        assert adjustments.intensity_multiplier == 0.70
        assert adjustments.extra_rest_seconds == 45
        assert adjustments.extra_warmup_minutes == 5

    def test_extended_break_adjustments(self, comeback_service):
        """Extended break (6+ weeks) should have 50% volume reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=42, age=35)

        assert adjustments.volume_multiplier == 0.50
        assert adjustments.intensity_multiplier == 0.60
        assert adjustments.extra_rest_seconds == 60
        assert adjustments.extra_warmup_minutes == 7


# =============================================================================
# Age-Based Adjustment Tests
# =============================================================================

class TestAgeBasedAdjustments:
    """Tests for age-based additional adjustments."""

    def test_young_adult_no_age_adjustment(self, comeback_service):
        """Young adults (under 30) should have no age-based adjustments."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=14, age=25)

        # Medium break + no age adjustment = 25% reduction
        assert adjustments.volume_multiplier == 0.75

    def test_middle_aged_additional_adjustment(self, comeback_service):
        """Middle-aged users (50-59) should have additional 10% reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=14, age=55)

        # Medium break (25%) + age adjustment (10%) = 35% total reduction
        # 1.0 - 0.35 = 0.65 multiplier
        assert adjustments.volume_multiplier == 0.65
        assert adjustments.extra_rest_seconds >= 30  # Medium break rest + age adjustment

    def test_senior_additional_adjustment(self, comeback_service):
        """Senior users (60-69) should have additional 15% reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=14, age=65)

        # Medium break (25%) + age adjustment (15%) = 40% total reduction
        # 1.0 - 0.40 = 0.60 multiplier
        assert adjustments.volume_multiplier == 0.60
        assert adjustments.extra_warmup_minutes >= 6  # Medium break + senior warmup

    def test_elderly_additional_adjustment(self, comeback_service):
        """Elderly users (70+) should have additional 20% reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=14, age=75)

        # Medium break (25%) + age adjustment (20%) = 45% total reduction
        # 1.0 - 0.45 = 0.55 multiplier
        assert adjustments.volume_multiplier == 0.55
        assert adjustments.extra_rest_seconds >= 45  # Significantly more rest


# =============================================================================
# Special Scenario: 70-Year-Old After 5 Weeks
# =============================================================================

class TestSeniorExtendedBreakScenario:
    """
    Special tests for the 70-year-old returning after 5 weeks scenario.

    This is a critical safety case - a senior returning from an extended break
    needs significantly reduced intensity to prevent injury.
    """

    def test_70_year_old_5_weeks_off_classification(self, comeback_service):
        """70-year-old after 35 days should be classified as long break."""
        break_type = comeback_service.classify_break_type(35)
        assert break_type == BreakType.LONG_BREAK

    def test_70_year_old_5_weeks_off_volume_reduction(self, comeback_service):
        """70-year-old after 35 days should have significant volume reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        # Long break (40%) + age 70 adjustment (20%) = 60% total reduction
        # But capped at 60% max reduction, so 0.40 multiplier
        assert adjustments.volume_multiplier <= 0.50
        assert adjustments.volume_multiplier >= 0.40

    def test_70_year_old_5_weeks_off_intensity_reduction(self, comeback_service):
        """70-year-old after 35 days should have significant intensity reduction."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        # Long break (30%) + age adjustment (20%) = 50% intensity reduction
        # 1.0 - 0.50 = 0.50 multiplier
        assert adjustments.intensity_multiplier <= 0.55
        assert adjustments.intensity_multiplier >= 0.45

    def test_70_year_old_5_weeks_off_extra_rest(self, comeback_service):
        """70-year-old after 35 days should have extended rest periods."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        # Should have significant extra rest (base + age adjustment)
        assert adjustments.extra_rest_seconds >= 60  # At least 60 seconds extra

    def test_70_year_old_5_weeks_off_max_exercises(self, comeback_service):
        """70-year-old after 35 days should have limited exercise count."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        # Should limit to 4 or fewer exercises per session
        assert adjustments.max_exercise_count <= 4

    def test_70_year_old_5_weeks_off_avoid_movements(self, comeback_service):
        """70-year-old after 35 days should avoid explosive movements."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        # Should avoid high-impact and explosive movements
        assert "explosive" in adjustments.avoid_movements or "high_impact" in adjustments.avoid_movements

    def test_70_year_old_5_weeks_off_focus_areas(self, comeback_service):
        """70-year-old after 35 days should focus on mobility and joint health."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        assert "mobility" in adjustments.focus_areas or "joint_health" in adjustments.focus_areas

    def test_70_year_old_5_weeks_off_warmup(self, comeback_service):
        """70-year-old after 35 days should have extended warmup."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)

        # Should have at least 8 minutes extra warmup (5 for long break + 3 for senior)
        assert adjustments.extra_warmup_minutes >= 8


# =============================================================================
# Comeback Week Progression Tests
# =============================================================================

class TestComebackWeekProgression:
    """Tests for gradual volume/intensity increase over comeback weeks."""

    def test_week_1_full_reduction(self, comeback_service):
        """Week 1 should have full comeback reduction."""
        adjustments = comeback_service.get_comeback_adjustments(
            days_off=28, age=35, comeback_week=1
        )

        # Full reduction in week 1
        assert adjustments.volume_multiplier == 0.60  # 40% reduction

    def test_week_2_reduced_reduction(self, comeback_service):
        """Week 2 should have reduced comeback reduction (progress)."""
        adjustments = comeback_service.get_comeback_adjustments(
            days_off=28, age=35, comeback_week=2
        )

        # Reduced reduction in week 2
        assert adjustments.volume_multiplier > 0.60
        assert adjustments.volume_multiplier < 1.0

    def test_week_3_further_reduced(self, comeback_service):
        """Week 3 should have further reduced comeback reduction."""
        adjustments = comeback_service.get_comeback_adjustments(
            days_off=28, age=35, comeback_week=3
        )

        # Further reduced in week 3
        assert adjustments.volume_multiplier >= 0.80

    def test_week_progression_increases_volume(self, comeback_service):
        """Each week should progressively increase volume multiplier."""
        week1 = comeback_service.get_comeback_adjustments(days_off=28, age=35, comeback_week=1)
        week2 = comeback_service.get_comeback_adjustments(days_off=28, age=35, comeback_week=2)
        week3 = comeback_service.get_comeback_adjustments(days_off=28, age=35, comeback_week=3)

        assert week2.volume_multiplier >= week1.volume_multiplier
        assert week3.volume_multiplier >= week2.volume_multiplier


# =============================================================================
# Prompt Context Generation Tests
# =============================================================================

class TestPromptContextGeneration:
    """Tests for Gemini prompt context generation."""

    def test_prompt_context_includes_days_off(self, comeback_service):
        """Prompt context should include days off information."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)
        context = comeback_service._generate_prompt_context(
            days_off=35,
            break_type=BreakType.LONG_BREAK,
            age=70,
            comeback_week=1,
            adjustments=adjustments
        )

        assert "35 days off" in context

    def test_prompt_context_includes_senior_warning(self, comeback_service):
        """Prompt context for seniors should include special warnings."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=70)
        context = comeback_service._generate_prompt_context(
            days_off=35,
            break_type=BreakType.LONG_BREAK,
            age=70,
            comeback_week=1,
            adjustments=adjustments
        )

        assert "70" in context
        # Should mention senior or age considerations
        assert "SENIOR" in context or "Age" in context

    def test_prompt_context_includes_volume_reduction(self, comeback_service):
        """Prompt context should mention volume reduction percentage."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=35, age=35)
        context = comeback_service._generate_prompt_context(
            days_off=35,
            break_type=BreakType.LONG_BREAK,
            age=35,
            comeback_week=1,
            adjustments=adjustments
        )

        # Should mention reduction percentage
        assert "reduction" in context.lower() or "%" in context


# =============================================================================
# Integration Tests (with mocked database)
# =============================================================================

class TestComebackServiceIntegration:
    """Integration tests with mocked database calls."""

    @pytest.mark.asyncio
    async def test_get_days_since_last_workout_no_workouts(self, comeback_service, mock_supabase):
        """Test days calculation when user has no completed workouts."""
        # Setup mock - no completed workouts
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        days = await comeback_service.get_days_since_last_workout(MOCK_USER_ID)

        # Should return a large number (999) for users with no workout history
        assert days == 999

    @pytest.mark.asyncio
    async def test_get_days_since_last_workout_recent_workout(self, comeback_service, mock_supabase):
        """Test days calculation when user has a recent workout."""
        # Setup mock - workout from 5 days ago
        five_days_ago = (datetime.now() - timedelta(days=5)).isoformat()
        mock_result = MagicMock()
        mock_result.data = [{"scheduled_date": five_days_ago}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        days = await comeback_service.get_days_since_last_workout(MOCK_USER_ID)

        # Should return approximately 5 days (allow for timezone differences)
        assert 4 <= days <= 6

    @pytest.mark.asyncio
    async def test_detect_break_status_active_user(self, comeback_service, mock_supabase):
        """Test break status detection for an active user."""
        # Setup mocks
        mock_supabase.get_user.return_value = create_mock_user(age=35)

        two_days_ago = (datetime.now() - timedelta(days=2)).isoformat()
        mock_result = MagicMock()
        mock_result.data = [{"scheduled_date": two_days_ago}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        status = await comeback_service.detect_break_status(MOCK_USER_ID)

        assert status.break_type == BreakType.ACTIVE
        assert not status.in_comeback_mode

    @pytest.mark.asyncio
    async def test_detect_break_status_senior_long_break(self, comeback_service, mock_supabase):
        """Test break status detection for a senior after long break."""
        # Setup mocks - 70-year-old, 35 days since last workout
        mock_supabase.get_user.return_value = create_mock_user(age=70)

        thirty_five_days_ago = (datetime.now() - timedelta(days=35)).isoformat()
        mock_result = MagicMock()
        mock_result.data = [{"scheduled_date": thirty_five_days_ago}]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        status = await comeback_service.detect_break_status(MOCK_USER_ID)

        assert status.break_type == BreakType.LONG_BREAK
        assert status.in_comeback_mode
        assert status.user_age == 70
        assert status.age_adjustment_applied > 0
        assert status.adjustments.volume_multiplier < 0.5


# =============================================================================
# Edge Cases
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and boundary conditions."""

    def test_very_old_user_extreme_adjustment(self, comeback_service):
        """Test adjustments for very old users (80+)."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=42, age=85)

        # Should have maximum adjustments
        assert adjustments.volume_multiplier <= 0.45
        assert adjustments.extra_rest_seconds >= 60
        assert "high_impact" in adjustments.avoid_movements

    def test_no_age_provided(self, comeback_service):
        """Test adjustments when age is not provided."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=28, age=None)

        # Should still calculate base adjustments
        assert adjustments.volume_multiplier == 0.60
        assert adjustments.intensity_multiplier == 0.70

    def test_very_long_break_cap(self, comeback_service):
        """Test that very long breaks are handled properly."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=365, age=35)

        # Should be classified as extended break
        assert adjustments.volume_multiplier == 0.50
        assert adjustments.extra_warmup_minutes >= 7

    def test_zero_days_off(self, comeback_service):
        """Test zero days off returns no adjustments."""
        adjustments = comeback_service.get_comeback_adjustments(days_off=0, age=35)

        assert adjustments.volume_multiplier == 1.0
        assert adjustments.intensity_multiplier == 1.0

    def test_negative_days_handled(self, comeback_service):
        """Test negative days are handled gracefully."""
        # This shouldn't happen, but we should handle it
        break_type = comeback_service.classify_break_type(-1)
        assert break_type == BreakType.ACTIVE


# =============================================================================
# Comeback Duration Tests
# =============================================================================

class TestComebackDuration:
    """Tests for recommended comeback duration."""

    def test_short_break_1_week_comeback(self, comeback_service):
        """Short break should recommend 1 week comeback."""
        duration = comeback_service.COMEBACK_DURATION_WEEKS[BreakType.SHORT_BREAK]
        assert duration == 1

    def test_medium_break_2_week_comeback(self, comeback_service):
        """Medium break should recommend 2 week comeback."""
        duration = comeback_service.COMEBACK_DURATION_WEEKS[BreakType.MEDIUM_BREAK]
        assert duration == 2

    def test_long_break_3_week_comeback(self, comeback_service):
        """Long break should recommend 3 week comeback."""
        duration = comeback_service.COMEBACK_DURATION_WEEKS[BreakType.LONG_BREAK]
        assert duration == 3

    def test_extended_break_4_week_comeback(self, comeback_service):
        """Extended break should recommend 4 week comeback."""
        duration = comeback_service.COMEBACK_DURATION_WEEKS[BreakType.EXTENDED_BREAK]
        assert duration == 4


# =============================================================================
# Run Tests
# =============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
