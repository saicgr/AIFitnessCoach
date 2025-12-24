"""
Tests for Daily Activity API endpoints.

Tests:
- Activity syncing
- Today's activity retrieval
- Activity by date
- Activity history
- Activity summary
- Activity deletion
- Batch syncing

Run with: pytest backend/tests/test_activity_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import date, datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for activity operations."""
    with patch("api.v1.activity.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_activity_data():
    return {
        "id": "activity-1",
        "user_id": "user-123-abc",
        "activity_date": "2025-01-10",
        "steps": 10000,
        "calories_burned": 2500.0,
        "active_calories": 500.0,
        "distance_meters": 8000.0,
        "resting_heart_rate": 65,
        "avg_heart_rate": 75,
        "max_heart_rate": 150,
        "sleep_minutes": 480,
        "source": "health_connect",
        "synced_at": "2025-01-10T23:00:00",
    }


@pytest.fixture
def sample_activity_input():
    return {
        "user_id": "user-123-abc",
        "activity_date": date(2025, 1, 10),
        "steps": 10000,
        "calories_burned": 2500.0,
        "active_calories": 500.0,
        "distance_meters": 8000.0,
        "resting_heart_rate": 65,
        "avg_heart_rate": 75,
        "max_heart_rate": 150,
        "sleep_minutes": 480,
        "source": "health_connect",
    }


# ============================================================
# SYNC ACTIVITY TESTS
# ============================================================

class TestSyncActivity:
    """Test activity syncing endpoint."""

    def test_sync_activity_success(self, mock_supabase_db, sample_activity_data, sample_activity_input):
        """Test successful activity sync."""
        from api.v1.activity import sync_daily_activity, DailyActivityInput
        import asyncio

        mock_supabase_db.upsert_daily_activity.return_value = sample_activity_data

        input_data = DailyActivityInput(**sample_activity_input)

        result = asyncio.get_event_loop().run_until_complete(
            sync_daily_activity(input_data)
        )

        assert result.steps == 10000
        assert result.distance_km == 8.0

    def test_sync_activity_update_existing(self, mock_supabase_db, sample_activity_data, sample_activity_input):
        """Test updating existing activity via sync."""
        from api.v1.activity import sync_daily_activity, DailyActivityInput
        import asyncio

        updated_data = {**sample_activity_data, "steps": 12000}
        mock_supabase_db.upsert_daily_activity.return_value = updated_data

        input_data = DailyActivityInput(**{**sample_activity_input, "steps": 12000})

        result = asyncio.get_event_loop().run_until_complete(
            sync_daily_activity(input_data)
        )

        assert result.steps == 12000

    def test_sync_activity_failure(self, mock_supabase_db, sample_activity_input):
        """Test sync failure handling."""
        from api.v1.activity import sync_daily_activity, DailyActivityInput
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.upsert_daily_activity.return_value = None

        input_data = DailyActivityInput(**sample_activity_input)

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                sync_daily_activity(input_data)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# GET TODAY'S ACTIVITY TESTS
# ============================================================

class TestGetTodayActivity:
    """Test get today's activity endpoint."""

    def test_get_today_activity_exists(self, mock_supabase_db, sample_user_id, sample_activity_data):
        """Test getting today's activity when it exists."""
        from api.v1.activity import get_today_activity
        import asyncio

        mock_supabase_db.get_daily_activity.return_value = sample_activity_data

        result = asyncio.get_event_loop().run_until_complete(
            get_today_activity(sample_user_id)
        )

        assert result is not None
        assert result.steps == 10000
        assert result.sleep_hours == 8.0

    def test_get_today_activity_not_exists(self, mock_supabase_db, sample_user_id):
        """Test getting today's activity when none exists."""
        from api.v1.activity import get_today_activity
        import asyncio

        mock_supabase_db.get_daily_activity.return_value = None

        result = asyncio.get_event_loop().run_until_complete(
            get_today_activity(sample_user_id)
        )

        assert result is None


# ============================================================
# GET ACTIVITY BY DATE TESTS
# ============================================================

class TestGetActivityByDate:
    """Test get activity by date endpoint."""

    def test_get_activity_by_date_exists(self, mock_supabase_db, sample_user_id, sample_activity_data):
        """Test getting activity for a specific date."""
        from api.v1.activity import get_activity_by_date
        import asyncio

        mock_supabase_db.get_daily_activity.return_value = sample_activity_data

        result = asyncio.get_event_loop().run_until_complete(
            get_activity_by_date(sample_user_id, date(2025, 1, 10))
        )

        assert result is not None
        assert result.activity_date == "2025-01-10"

    def test_get_activity_by_date_not_exists(self, mock_supabase_db, sample_user_id):
        """Test getting activity for a date with no data."""
        from api.v1.activity import get_activity_by_date
        import asyncio

        mock_supabase_db.get_daily_activity.return_value = None

        result = asyncio.get_event_loop().run_until_complete(
            get_activity_by_date(sample_user_id, date(2025, 1, 1))
        )

        assert result is None


# ============================================================
# GET ACTIVITY HISTORY TESTS
# ============================================================

class TestGetActivityHistory:
    """Test activity history endpoint."""

    def test_get_activity_history_success(self, mock_supabase_db, sample_user_id, sample_activity_data):
        """Test getting activity history."""
        from api.v1.activity import get_activity_history
        import asyncio

        mock_supabase_db.list_daily_activity.return_value = [
            sample_activity_data,
            {**sample_activity_data, "id": "activity-2", "activity_date": "2025-01-09", "steps": 8000},
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_activity_history(sample_user_id)
        )

        assert len(result) == 2
        assert result[0].steps == 10000
        assert result[1].steps == 8000

    def test_get_activity_history_empty(self, mock_supabase_db, sample_user_id):
        """Test getting empty activity history."""
        from api.v1.activity import get_activity_history
        import asyncio

        mock_supabase_db.list_daily_activity.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            get_activity_history(sample_user_id)
        )

        assert len(result) == 0

    def test_get_activity_history_with_date_range(self, mock_supabase_db, sample_user_id, sample_activity_data):
        """Test getting activity history with date range."""
        from api.v1.activity import get_activity_history
        import asyncio

        mock_supabase_db.list_daily_activity.return_value = [sample_activity_data]

        asyncio.get_event_loop().run_until_complete(
            get_activity_history(
                sample_user_id,
                from_date=date(2025, 1, 1),
                to_date=date(2025, 1, 31)
            )
        )

        mock_supabase_db.list_daily_activity.assert_called_with(
            user_id=sample_user_id,
            from_date="2025-01-01",
            to_date="2025-01-31",
            limit=30
        )


# ============================================================
# GET ACTIVITY SUMMARY TESTS
# ============================================================

class TestGetActivitySummary:
    """Test activity summary endpoint."""

    def test_get_activity_summary_success(self, mock_supabase_db, sample_user_id):
        """Test getting activity summary."""
        from api.v1.activity import get_activity_summary
        import asyncio

        mock_supabase_db.get_activity_summary.return_value = {
            "total_steps": 70000,
            "avg_steps": 10000.0,
            "total_calories": 17500.0,
            "avg_calories": 2500.0,
            "total_distance_km": 56.0,
            "avg_distance_km": 8.0,
            "avg_heart_rate": 72.5,
            "days_tracked": 7,
        }

        result = asyncio.get_event_loop().run_until_complete(
            get_activity_summary(sample_user_id, days=7)
        )

        assert result.total_steps == 70000
        assert result.avg_steps == 10000.0
        assert result.days_tracked == 7

    def test_get_activity_summary_empty(self, mock_supabase_db, sample_user_id):
        """Test getting summary with no data."""
        from api.v1.activity import get_activity_summary
        import asyncio

        mock_supabase_db.get_activity_summary.return_value = {
            "total_steps": None,
            "avg_steps": None,
            "total_calories": None,
            "avg_calories": None,
            "total_distance_km": None,
            "avg_distance_km": None,
            "avg_heart_rate": None,
            "days_tracked": None,
        }

        result = asyncio.get_event_loop().run_until_complete(
            get_activity_summary(sample_user_id)
        )

        assert result.total_steps == 0
        assert result.days_tracked == 0


# ============================================================
# DELETE ACTIVITY TESTS
# ============================================================

class TestDeleteActivity:
    """Test activity deletion endpoint."""

    def test_delete_activity_success(self, mock_supabase_db, sample_user_id):
        """Test successful activity deletion."""
        from api.v1.activity import delete_activity
        import asyncio

        mock_supabase_db.delete_daily_activity.return_value = True

        result = asyncio.get_event_loop().run_until_complete(
            delete_activity(sample_user_id, date(2025, 1, 10))
        )

        assert result["message"] == "Activity deleted successfully"

    def test_delete_activity_not_found(self, mock_supabase_db, sample_user_id):
        """Test deleting non-existent activity."""
        from api.v1.activity import delete_activity
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.delete_daily_activity.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                delete_activity(sample_user_id, date(2025, 1, 1))
            )

        assert exc_info.value.status_code == 404


# ============================================================
# BATCH SYNC TESTS
# ============================================================

class TestBatchSync:
    """Test batch activity syncing endpoint."""

    def test_sync_batch_success(self, mock_supabase_db, sample_activity_data, sample_activity_input):
        """Test successful batch sync."""
        from api.v1.activity import sync_batch_activity, DailyActivityInput
        import asyncio

        mock_supabase_db.upsert_daily_activity.return_value = sample_activity_data

        activities = [
            DailyActivityInput(**sample_activity_input),
            DailyActivityInput(**{**sample_activity_input, "activity_date": date(2025, 1, 9)}),
        ]

        result = asyncio.get_event_loop().run_until_complete(
            sync_batch_activity(activities)
        )

        assert result["synced"] == 2
        assert result["total"] == 2

    def test_sync_batch_empty(self, mock_supabase_db):
        """Test batch sync with empty list."""
        from api.v1.activity import sync_batch_activity
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            sync_batch_activity([])
        )

        assert result["synced"] == 0
        assert result["results"] == []

    def test_sync_batch_partial_failure(self, mock_supabase_db, sample_activity_data, sample_activity_input):
        """Test batch sync with some failures."""
        from api.v1.activity import sync_batch_activity, DailyActivityInput
        import asyncio

        # First succeeds, second fails
        mock_supabase_db.upsert_daily_activity.side_effect = [sample_activity_data, None]

        activities = [
            DailyActivityInput(**sample_activity_input),
            DailyActivityInput(**{**sample_activity_input, "activity_date": date(2025, 1, 9)}),
        ]

        result = asyncio.get_event_loop().run_until_complete(
            sync_batch_activity(activities)
        )

        assert result["synced"] == 1
        assert result["total"] == 2

    def test_sync_batch_exception(self, mock_supabase_db, sample_activity_data, sample_activity_input):
        """Test batch sync handling exceptions."""
        from api.v1.activity import sync_batch_activity, DailyActivityInput
        import asyncio

        # First succeeds, second raises exception
        mock_supabase_db.upsert_daily_activity.side_effect = [
            sample_activity_data,
            Exception("Database error")
        ]

        activities = [
            DailyActivityInput(**sample_activity_input),
            DailyActivityInput(**{**sample_activity_input, "activity_date": date(2025, 1, 9)}),
        ]

        result = asyncio.get_event_loop().run_until_complete(
            sync_batch_activity(activities)
        )

        assert result["synced"] == 1
        assert any(r["status"] == "error" for r in result["results"])


# ============================================================
# HELPER FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions."""

    def test_row_to_activity_response(self, sample_activity_data):
        """Test conversion of database row to response model."""
        from api.v1.activity import row_to_activity_response

        result = row_to_activity_response(sample_activity_data)

        assert result.steps == 10000
        assert result.distance_km == 8.0
        assert result.sleep_hours == 8.0

    def test_row_to_activity_response_null_values(self):
        """Test handling null values in conversion."""
        from api.v1.activity import row_to_activity_response

        row = {
            "id": "activity-1",
            "user_id": "user-123",
            "activity_date": "2025-01-10",
            "steps": None,
            "calories_burned": None,
            "active_calories": None,
            "distance_meters": None,
            "resting_heart_rate": None,
            "avg_heart_rate": None,
            "max_heart_rate": None,
            "sleep_minutes": None,
            "source": None,
            "synced_at": "2025-01-10T23:00:00",
        }

        result = row_to_activity_response(row)

        assert result.steps == 0
        assert result.distance_km == 0.0
        assert result.sleep_hours is None


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestActivityModels:
    """Test Pydantic model validation."""

    def test_daily_activity_input_valid(self):
        """Test valid DailyActivityInput."""
        from api.v1.activity import DailyActivityInput

        input_data = DailyActivityInput(
            user_id="user-123",
            activity_date=date(2025, 1, 10),
            steps=10000,
            calories_burned=2500.0,
            active_calories=500.0,
            distance_meters=8000.0,
        )

        assert input_data.steps == 10000
        assert input_data.source == "health_connect"  # Default

    def test_daily_activity_input_defaults(self):
        """Test DailyActivityInput default values."""
        from api.v1.activity import DailyActivityInput

        input_data = DailyActivityInput(
            user_id="user-123",
            activity_date=date(2025, 1, 10),
        )

        assert input_data.steps == 0
        assert input_data.calories_burned == 0
        assert input_data.source == "health_connect"

    def test_daily_activity_input_invalid_steps(self):
        """Test DailyActivityInput with invalid steps."""
        from api.v1.activity import DailyActivityInput
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            DailyActivityInput(
                user_id="user-123",
                activity_date=date(2025, 1, 10),
                steps=-100,  # Invalid: must be >= 0
            )

    def test_daily_activity_input_invalid_heart_rate(self):
        """Test DailyActivityInput with invalid heart rate."""
        from api.v1.activity import DailyActivityInput
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            DailyActivityInput(
                user_id="user-123",
                activity_date=date(2025, 1, 10),
                resting_heart_rate=20,  # Invalid: must be >= 30
            )

    def test_activity_summary_response(self):
        """Test ActivitySummaryResponse model."""
        from api.v1.activity import ActivitySummaryResponse

        summary = ActivitySummaryResponse(
            total_steps=70000,
            avg_steps=10000.0,
            total_calories=17500.0,
            avg_calories=2500.0,
            total_distance_km=56.0,
            avg_distance_km=8.0,
            avg_heart_rate=72.5,
            days_tracked=7,
        )

        assert summary.total_steps == 70000
        assert summary.avg_heart_rate == 72.5


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
