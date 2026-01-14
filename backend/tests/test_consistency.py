"""
Tests for the Consistency Insights API endpoints.

Tests the /api/v1/consistency/* endpoints that provide
workout consistency insights, streaks, and patterns.

Run with: pytest tests/test_consistency.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, date, timedelta

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.consistency import (
    get_day_name,
    get_time_of_day_name,
    get_time_of_day_display,
    calculate_weekly_trend,
    get_recovery_message,
    get_motivation_quote,
)
from models.consistency import (
    DayOfWeek,
    TimeOfDay,
    RecoveryType,
    StreakEndReason,
    ConsistencyInsights,
    ConsistencyPatterns,
    DayPattern,
    TimeOfDayPattern,
    WeeklyConsistencyMetric,
    StreakHistoryRecord,
    StreakRecoveryRequest,
    StreakRecoveryResponse,
    CalendarHeatmapData,
    CalendarHeatmapResponse,
)


# ============================================================================
# Unit Tests for Helper Functions
# ============================================================================

class TestGetDayName:
    """Tests for the get_day_name helper function."""

    def test_sunday(self):
        """Should return 'Sunday' for day 0."""
        assert get_day_name(0) == "Sunday"

    def test_monday(self):
        """Should return 'Monday' for day 1."""
        assert get_day_name(1) == "Monday"

    def test_saturday(self):
        """Should return 'Saturday' for day 6."""
        assert get_day_name(6) == "Saturday"

    def test_invalid_day(self):
        """Should return 'Unknown' for invalid day."""
        assert get_day_name(7) == "Unknown"
        assert get_day_name(-1) == "Unknown"


class TestGetTimeOfDayName:
    """Tests for the get_time_of_day_name helper function."""

    def test_early_morning(self):
        """Should return 'early_morning' for 5-7 AM."""
        assert get_time_of_day_name(5) == "early_morning"
        assert get_time_of_day_name(7) == "early_morning"

    def test_morning(self):
        """Should return 'morning' for 8-10 AM."""
        assert get_time_of_day_name(8) == "morning"
        assert get_time_of_day_name(10) == "morning"

    def test_midday(self):
        """Should return 'midday' for 11-13."""
        assert get_time_of_day_name(11) == "midday"
        assert get_time_of_day_name(13) == "midday"

    def test_afternoon(self):
        """Should return 'afternoon' for 14-16."""
        assert get_time_of_day_name(14) == "afternoon"
        assert get_time_of_day_name(16) == "afternoon"

    def test_evening(self):
        """Should return 'evening' for 17-19."""
        assert get_time_of_day_name(17) == "evening"
        assert get_time_of_day_name(19) == "evening"

    def test_night(self):
        """Should return 'night' for other hours."""
        assert get_time_of_day_name(20) == "night"
        assert get_time_of_day_name(22) == "night"
        assert get_time_of_day_name(4) == "night"


class TestGetTimeOfDayDisplay:
    """Tests for the get_time_of_day_display helper function."""

    def test_all_display_names(self):
        """Should return display names for all time categories."""
        assert "5-8 AM" in get_time_of_day_display("early_morning")
        assert "8-11 AM" in get_time_of_day_display("morning")
        assert "11 AM" in get_time_of_day_display("midday")
        assert "2-5 PM" in get_time_of_day_display("afternoon")
        assert "5-8 PM" in get_time_of_day_display("evening")
        assert "8-11 PM" in get_time_of_day_display("night")

    def test_unknown_key(self):
        """Should return the key for unknown time."""
        assert get_time_of_day_display("unknown") == "unknown"


class TestCalculateWeeklyTrend:
    """Tests for the calculate_weekly_trend helper function."""

    def test_improving_trend(self):
        """Should return 'improving' when last week is significantly higher."""
        rates = [60.0, 65.0, 70.0, 85.0]  # Last week jumped >10%
        assert calculate_weekly_trend(rates) == "improving"

    def test_declining_trend(self):
        """Should return 'declining' when last week is significantly lower."""
        rates = [80.0, 75.0, 70.0, 55.0]  # Last week dropped >10%
        assert calculate_weekly_trend(rates) == "declining"

    def test_stable_trend(self):
        """Should return 'stable' when change is within 10%."""
        rates = [70.0, 72.0, 68.0, 71.0]
        assert calculate_weekly_trend(rates) == "stable"

    def test_insufficient_data(self):
        """Should return 'stable' with less than 2 data points."""
        assert calculate_weekly_trend([70.0]) == "stable"
        assert calculate_weekly_trend([]) == "stable"


class TestGetRecoveryMessage:
    """Tests for the get_recovery_message helper function."""

    def test_one_day_missed_with_streak(self):
        """Should return encouraging message for one missed day with streak."""
        message = get_recovery_message(1, 10)
        assert "10-day" in message
        assert "streak" in message.lower()

    def test_one_day_missed_without_streak(self):
        """Should return generic message for one missed day."""
        message = get_recovery_message(1, 0)
        assert len(message) > 0

    def test_few_days_missed(self):
        """Should return recovery-focused message for 2-3 days."""
        message = get_recovery_message(2, 5)
        assert len(message) > 0

    def test_week_missed(self):
        """Should return supportive message for about a week."""
        message = get_recovery_message(5, 0)
        assert len(message) > 0

    def test_long_break(self):
        """Should return welcome back message for long breaks."""
        message = get_recovery_message(14, 0)
        assert "welcome back" in message.lower() or "journey" in message.lower()


class TestGetMotivationQuote:
    """Tests for the get_motivation_quote helper function."""

    def test_returns_string(self):
        """Should return a non-empty string."""
        quote = get_motivation_quote()
        assert isinstance(quote, str)
        assert len(quote) > 0

    def test_returns_different_quotes(self):
        """Should be capable of returning different quotes (randomness)."""
        quotes = set()
        for _ in range(50):  # Run multiple times to test randomness
            quotes.add(get_motivation_quote())
        # Should have at least 2 different quotes after 50 tries
        assert len(quotes) >= 2


# ============================================================================
# Enum Tests
# ============================================================================

class TestDayOfWeekEnum:
    """Tests for the DayOfWeek enum."""

    def test_all_days_defined(self):
        """Should have all days of the week."""
        assert DayOfWeek.SUNDAY.value == 0
        assert DayOfWeek.MONDAY.value == 1
        assert DayOfWeek.TUESDAY.value == 2
        assert DayOfWeek.WEDNESDAY.value == 3
        assert DayOfWeek.THURSDAY.value == 4
        assert DayOfWeek.FRIDAY.value == 5
        assert DayOfWeek.SATURDAY.value == 6

    def test_display_name(self):
        """Should have display_name property."""
        assert DayOfWeek.MONDAY.display_name == "Monday"
        assert DayOfWeek.FRIDAY.display_name == "Friday"

    def test_short_name(self):
        """Should have short_name property."""
        assert DayOfWeek.MONDAY.short_name == "Mon"
        assert DayOfWeek.FRIDAY.short_name == "Fri"


class TestTimeOfDayEnum:
    """Tests for the TimeOfDay enum."""

    def test_all_periods_defined(self):
        """Should have all time periods."""
        assert TimeOfDay.EARLY_MORNING.value == "early_morning"
        assert TimeOfDay.MORNING.value == "morning"
        assert TimeOfDay.MIDDAY.value == "midday"
        assert TimeOfDay.AFTERNOON.value == "afternoon"
        assert TimeOfDay.EVENING.value == "evening"
        assert TimeOfDay.NIGHT.value == "night"

    def test_from_hour(self):
        """Should convert hour to TimeOfDay."""
        assert TimeOfDay.from_hour(6) == TimeOfDay.EARLY_MORNING
        assert TimeOfDay.from_hour(9) == TimeOfDay.MORNING
        assert TimeOfDay.from_hour(12) == TimeOfDay.MIDDAY
        assert TimeOfDay.from_hour(15) == TimeOfDay.AFTERNOON
        assert TimeOfDay.from_hour(18) == TimeOfDay.EVENING
        assert TimeOfDay.from_hour(21) == TimeOfDay.NIGHT


class TestRecoveryTypeEnum:
    """Tests for the RecoveryType enum."""

    def test_all_types_defined(self):
        """Should have all recovery types."""
        assert RecoveryType.STANDARD.value == "standard"
        assert RecoveryType.QUICK_RECOVERY.value == "quick_recovery"
        assert RecoveryType.CUSTOM.value == "custom"


class TestStreakEndReasonEnum:
    """Tests for the StreakEndReason enum."""

    def test_all_reasons_defined(self):
        """Should have all streak end reasons."""
        assert StreakEndReason.MISSED_WORKOUT.value == "missed_workout"
        assert StreakEndReason.MANUAL_RESET.value == "manual_reset"
        assert StreakEndReason.PROGRAM_CHANGE.value == "program_change"


# ============================================================================
# Pydantic Model Tests
# ============================================================================

class TestDayPatternModel:
    """Tests for the DayPattern model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        pattern = DayPattern(
            day_of_week=1,
            day_name="Monday",
            total_completions=10,
            total_skips=2,
            completion_rate=83.3,
            is_best_day=True,
            is_worst_day=False,
        )
        assert pattern.day_of_week == 1
        assert pattern.completion_rate == 83.3


class TestTimeOfDayPatternModel:
    """Tests for the TimeOfDayPattern model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        pattern = TimeOfDayPattern(
            time_of_day="morning",
            display_name="Morning (8-11 AM)",
            total_completions=15,
            total_skips=3,
            completion_rate=83.3,
            is_preferred=True,
        )
        assert pattern.time_of_day == "morning"
        assert pattern.is_preferred is True


class TestWeeklyConsistencyMetricModel:
    """Tests for the WeeklyConsistencyMetric model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        metric = WeeklyConsistencyMetric(
            week_start=date(2024, 1, 1),
            week_end=date(2024, 1, 7),
            workouts_scheduled=4,
            workouts_completed=3,
            workouts_skipped=1,
            completion_rate=75.0,
            total_workout_minutes=180,
            average_session_minutes=60.0,
        )
        assert metric.workouts_completed == 3
        assert metric.completion_rate == 75.0


class TestStreakRecoveryRequestModel:
    """Tests for the StreakRecoveryRequest model."""

    def test_required_fields(self):
        """Should require user_id."""
        request = StreakRecoveryRequest(user_id="test-user")
        assert request.user_id == "test-user"
        assert request.recovery_type == RecoveryType.STANDARD.value

    def test_custom_recovery_type(self):
        """Should accept custom recovery type."""
        request = StreakRecoveryRequest(
            user_id="test-user",
            recovery_type=RecoveryType.QUICK_RECOVERY.value,
        )
        assert request.recovery_type == RecoveryType.QUICK_RECOVERY.value


class TestConsistencyInsightsModel:
    """Tests for the ConsistencyInsights model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        insights = ConsistencyInsights(
            user_id="test-user",
            current_streak=7,
            longest_streak=14,
            is_streak_active=True,
            best_day=DayPattern(
                day_of_week=1,
                day_name="Monday",
                completion_rate=90.0,
                is_best_day=True,
            ),
            worst_day=DayPattern(
                day_of_week=5,
                day_name="Friday",
                completion_rate=50.0,
                is_worst_day=True,
            ),
            day_patterns=[],
            preferred_time="morning",
            time_patterns=[],
            month_workouts_completed=12,
            month_workouts_scheduled=16,
            month_completion_rate=75.0,
            month_display="12 of 16 workouts",
            weekly_completion_rates=[],
            average_weekly_rate=75.0,
            weekly_trend="improving",
            needs_recovery=False,
            days_since_last_workout=0,
        )
        assert insights.current_streak == 7
        assert insights.weekly_trend == "improving"


# ============================================================================
# API Endpoint Tests - Consistency Insights
# ============================================================================

class TestConsistencyInsightsEndpoint:
    """Tests for GET /consistency/insights endpoint."""

    def test_endpoint_exists(self, client):
        """Test that insights endpoint exists."""
        response = client.get(
            "/api/v1/consistency/insights?user_id=test-user"
        )
        assert response.status_code != 404

    def test_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.get("/api/v1/consistency/insights")
        assert response.status_code == 422

    @patch('api.v1.consistency.get_supabase_db')
    def test_returns_insights_for_user(self, mock_db, client):
        """Should return consistency insights."""
        # Mock user data
        mock_user_result = MagicMock()
        mock_user_result.data = {
            "current_streak": 5,
            "last_workout_date": date.today().isoformat(),
        }

        # Mock patterns data
        mock_patterns_result = MagicMock()
        mock_patterns_result.data = [
            {"day_of_week": 1, "hour_of_day": 9, "completion_count": 10, "skip_count": 2},
        ]

        # Mock workouts count
        mock_count_result = MagicMock()
        mock_count_result.count = 4

        mock_db_instance = MagicMock()

        # User table query
        mock_user_query = MagicMock()
        mock_user_query.select.return_value = mock_user_query
        mock_user_query.eq.return_value = mock_user_query
        mock_user_query.maybe_single.return_value = mock_user_query
        mock_user_query.execute.return_value = mock_user_result

        # Patterns table query
        mock_patterns_query = MagicMock()
        mock_patterns_query.select.return_value = mock_patterns_query
        mock_patterns_query.eq.return_value = mock_patterns_query
        mock_patterns_query.execute.return_value = mock_patterns_result

        # Workouts count query
        mock_workouts_query = MagicMock()
        mock_workouts_query.select.return_value = mock_workouts_query
        mock_workouts_query.eq.return_value = mock_workouts_query
        mock_workouts_query.gte.return_value = mock_workouts_query
        mock_workouts_query.lte.return_value = mock_workouts_query
        mock_workouts_query.execute.return_value = mock_count_result

        def table_side_effect(table_name):
            if table_name == "users":
                return mock_user_query
            elif table_name == "workout_time_patterns":
                return mock_patterns_query
            elif table_name == "workouts":
                return mock_workouts_query
            return MagicMock()

        mock_db_instance.client.table = MagicMock(side_effect=table_side_effect)
        mock_db_instance.client.rpc.return_value.execute.return_value = MagicMock(data=5)
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/consistency/insights?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "current_streak" in data
        assert "day_patterns" in data
        assert "time_patterns" in data

    @patch('api.v1.consistency.get_supabase_db')
    def test_handles_new_user(self, mock_db, client):
        """Should handle user with no data."""
        mock_user_result = MagicMock()
        mock_user_result.data = None

        mock_patterns_result = MagicMock()
        mock_patterns_result.data = []

        mock_count_result = MagicMock()
        mock_count_result.count = 0

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.lte.return_value = mock_query
        mock_query.maybe_single.return_value = mock_query
        mock_query.execute.return_value = mock_count_result

        mock_db_instance.client.table.return_value = mock_query
        mock_db_instance.client.rpc.return_value.execute.return_value = MagicMock(data=0)
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/consistency/insights?user_id=new-user"
        )

        # Should not error, return defaults
        assert response.status_code == 200


# ============================================================================
# API Endpoint Tests - Consistency Patterns
# ============================================================================

class TestConsistencyPatternsEndpoint:
    """Tests for GET /consistency/patterns endpoint."""

    def test_endpoint_exists(self, client):
        """Test that patterns endpoint exists."""
        response = client.get(
            "/api/v1/consistency/patterns?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.consistency.get_supabase_db')
    def test_returns_patterns(self, mock_db, client):
        """Should return consistency patterns."""
        mock_patterns_result = MagicMock()
        mock_patterns_result.data = [
            {"day_of_week": 1, "hour_of_day": 9, "completion_count": 10, "skip_count": 2, "updated_at": datetime.now().isoformat()},
            {"day_of_week": 3, "hour_of_day": 17, "completion_count": 8, "skip_count": 4, "updated_at": datetime.now().isoformat()},
        ]

        mock_history_result = MagicMock()
        mock_history_result.data = [
            {"id": "streak-1", "user_id": "test-user", "streak_length": 7, "started_at": "2024-01-01T00:00:00Z", "ended_at": "2024-01-07T00:00:00Z", "end_reason": "missed_workout", "created_at": "2024-01-01T00:00:00Z"},
        ]

        mock_db_instance = MagicMock()

        def table_side_effect(table_name):
            query = MagicMock()
            query.select.return_value = query
            query.eq.return_value = query
            query.order.return_value = query
            query.limit.return_value = query

            if table_name == "workout_time_patterns":
                query.execute.return_value = mock_patterns_result
            elif table_name == "streak_history":
                query.execute.return_value = mock_history_result
            return query

        mock_db_instance.client.table = MagicMock(side_effect=table_side_effect)
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/consistency/patterns?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "time_patterns" in data
        assert "day_patterns" in data
        assert "streak_history" in data


# ============================================================================
# API Endpoint Tests - Calendar Heatmap
# ============================================================================

class TestCalendarHeatmapEndpoint:
    """Tests for GET /consistency/calendar endpoint."""

    def test_endpoint_exists(self, client):
        """Test that calendar endpoint exists."""
        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.consistency.get_supabase_db')
    def test_returns_calendar_data(self, mock_db, client):
        """Should return calendar heatmap data."""
        today = date.today()
        mock_result = MagicMock()
        mock_result.data = [
            {"id": "w1", "name": "Upper Body", "scheduled_date": today.isoformat(), "completed": True},
            {"id": "w2", "name": "Lower Body", "scheduled_date": (today - timedelta(days=1)).isoformat(), "completed": False},
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.lte.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&weeks=4"
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "total_completed" in data
        assert "total_missed" in data
        assert "total_rest_days" in data

    @patch('api.v1.consistency.get_supabase_db')
    def test_accepts_weeks_parameter(self, mock_db, client):
        """Should accept weeks parameter."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.lte.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&weeks=8"
        )

        assert response.status_code == 200

    @patch('api.v1.consistency.get_supabase_db')
    def test_accepts_date_range_parameters(self, mock_db, client):
        """Should accept start_date and end_date parameters for custom date range."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.lte.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&start_date=2025-01-01&end_date=2025-01-31"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["start_date"] == "2025-01-01"
        assert data["end_date"] == "2025-01-31"

    @patch('api.v1.consistency.get_supabase_db')
    def test_date_range_returns_correct_days(self, mock_db, client):
        """Should return correct number of days for date range."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.lte.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        # Request 7 days
        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&start_date=2025-01-01&end_date=2025-01-07"
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 7

    def test_invalid_date_format_returns_400(self, client):
        """Should return 400 for invalid date format."""
        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&start_date=invalid&end_date=2025-01-31"
        )
        assert response.status_code == 400
        assert "Invalid date format" in response.json()["detail"]

    def test_end_date_before_start_date_returns_400(self, client):
        """Should return 400 when end_date is before start_date."""
        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&start_date=2025-01-31&end_date=2025-01-01"
        )
        assert response.status_code == 400
        assert "end_date must be greater than or equal to start_date" in response.json()["detail"]

    @patch('api.v1.consistency.get_supabase_db')
    def test_backward_compatibility_with_weeks(self, mock_db, client):
        """Should still work with weeks parameter for backward compatibility."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.lte.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        # Test without any date params (should default to 4 weeks)
        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user"
        )
        assert response.status_code == 200

        # Test with weeks param
        response = client.get(
            "/api/v1/consistency/calendar?user_id=test-user&weeks=2"
        )
        assert response.status_code == 200


# ============================================================================
# API Endpoint Tests - Streak Recovery
# ============================================================================

class TestStreakRecoveryEndpoint:
    """Tests for POST /consistency/streak-recovery endpoint."""

    def test_endpoint_exists(self, client):
        """Test that streak-recovery endpoint exists."""
        response = client.post(
            "/api/v1/consistency/streak-recovery",
            json={"user_id": "test-user"}
        )
        assert response.status_code != 404

    @patch('api.v1.consistency.get_supabase_db')
    def test_initiates_recovery(self, mock_db, client):
        """Should initiate streak recovery."""
        mock_user_result = MagicMock()
        mock_user_result.data = {
            "current_streak": 0,
            "last_workout_date": (date.today() - timedelta(days=3)).isoformat(),
        }

        mock_history_result = MagicMock()
        mock_history_result.data = [{"streak_length": 7}]

        mock_insert_result = MagicMock()
        mock_insert_result.data = [{"id": "recovery-123"}]

        mock_db_instance = MagicMock()

        def table_side_effect(table_name):
            query = MagicMock()
            query.select.return_value = query
            query.eq.return_value = query
            query.maybe_single.return_value = query
            query.order.return_value = query
            query.limit.return_value = query
            query.insert.return_value = query

            if table_name == "users":
                query.execute.return_value = mock_user_result
            elif table_name == "streak_history":
                query.execute.return_value = mock_history_result
            elif table_name == "streak_recovery_attempts":
                query.execute.return_value = mock_insert_result
            return query

        mock_db_instance.client.table = MagicMock(side_effect=table_side_effect)
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/consistency/streak-recovery",
            json={"user_id": "test-user", "recovery_type": "standard"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "attempt_id" in data
        assert "message" in data
        assert "motivation_quote" in data


class TestCompleteStreakRecoveryEndpoint:
    """Tests for POST /consistency/streak-recovery/{attempt_id}/complete endpoint."""

    def test_endpoint_exists(self, client):
        """Test that complete endpoint exists."""
        response = client.post(
            "/api/v1/consistency/streak-recovery/attempt-123/complete?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.consistency.get_supabase_db')
    def test_completes_recovery_successfully(self, mock_db, client):
        """Should complete recovery attempt."""
        mock_result = MagicMock()
        mock_result.data = [{"id": "attempt-123"}]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.update.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/consistency/streak-recovery/attempt-123/complete?user_id=test-user&was_successful=true"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    @patch('api.v1.consistency.get_supabase_db')
    def test_returns_404_for_missing_attempt(self, mock_db, client):
        """Should return 404 for missing attempt."""
        mock_result = MagicMock()
        mock_result.data = []  # Not found

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.update.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/consistency/streak-recovery/missing-attempt/complete?user_id=test-user"
        )

        assert response.status_code == 404


# ============================================================================
# Response Model Tests
# ============================================================================

class TestCalendarHeatmapDataModel:
    """Tests for the CalendarHeatmapData model."""

    def test_completed_status(self):
        """Should create model with completed status."""
        data = CalendarHeatmapData(
            date=date(2024, 1, 15),
            day_of_week=1,
            status="completed",
            workout_name="Upper Body",
        )
        assert data.status == "completed"
        assert data.workout_name == "Upper Body"

    def test_missed_status(self):
        """Should create model with missed status."""
        data = CalendarHeatmapData(
            date=date(2024, 1, 15),
            day_of_week=1,
            status="missed",
            workout_name="Lower Body",
        )
        assert data.status == "missed"

    def test_rest_status(self):
        """Should create model with rest status."""
        data = CalendarHeatmapData(
            date=date(2024, 1, 15),
            day_of_week=1,
            status="rest",
            workout_name=None,
        )
        assert data.status == "rest"
        assert data.workout_name is None


class TestCalendarHeatmapResponseModel:
    """Tests for the CalendarHeatmapResponse model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        response = CalendarHeatmapResponse(
            user_id="test-user",
            start_date=date(2024, 1, 1),
            end_date=date(2024, 1, 28),
            data=[
                CalendarHeatmapData(
                    date=date(2024, 1, 15),
                    day_of_week=1,
                    status="completed",
                ),
            ],
            total_completed=10,
            total_missed=2,
            total_rest_days=16,
        )
        assert response.total_completed == 10
        assert len(response.data) == 1


class TestStreakRecoveryResponseModel:
    """Tests for the StreakRecoveryResponse model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        response = StreakRecoveryResponse(
            success=True,
            attempt_id="recovery-123",
            message="Welcome back! Let's get you moving again.",
            motivation_quote="The best time to start was yesterday. The next best time is now.",
            suggested_workout_type="quick_recovery",
            suggested_duration_minutes=20,
        )
        assert response.success is True
        assert response.suggested_duration_minutes == 20
