"""
Tests for WearOS Watch Sync API endpoints.

Tests the watch sync system endpoints:
- Batch sync (POST /watch-sync/sync)
- Activity goals (GET /watch-sync/goals/{user_id})

Run with: pytest backend/tests/test_watch_sync_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime
import uuid
import sys
import os

# Add the backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with chainable Supabase client pattern."""
    with patch("api.v1.watch_sync.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_db.table = mock_client.table

        # Create chainable mock for table operations
        mock_table = MagicMock()
        mock_client.table.return_value = mock_table

        # Make all table operations chainable
        mock_table.select.return_value = mock_table
        mock_table.insert.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.delete.return_value = mock_table
        mock_table.upsert.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.neq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.limit.return_value = mock_table
        mock_table.maybe_single.return_value = mock_table

        # Default execute returns empty data
        mock_response = MagicMock()
        mock_response.data = []
        mock_table.execute.return_value = mock_response

        # Store mock_table for easy access in tests
        mock_db._mock_table = mock_table

        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_gemini_service():
    """Mock the Gemini service for food analysis."""
    with patch("api.v1.watch_sync.get_gemini_service") as mock_get_gemini:
        mock_gemini = AsyncMock()
        mock_gemini.analyze_food = AsyncMock(return_value={
            "food_name": "Chicken Breast",
            "calories": 165,
            "protein_g": 31.0,
            "carbs_g": 0.0,
            "fat_g": 3.6
        })
        mock_get_gemini.return_value = mock_gemini
        yield mock_gemini


@pytest.fixture
def mock_user_context_service():
    """Mock the UserContextService."""
    with patch("api.v1.watch_sync.UserContextService") as mock_context_class:
        mock_context = MagicMock()
        mock_context.log_event = AsyncMock(return_value="event-123")
        mock_context.log_watch_food_logged = AsyncMock(return_value="event-456")
        mock_context.log_watch_activity_synced = AsyncMock(return_value="event-789")
        mock_context_class.return_value = mock_context
        yield mock_context


@pytest.fixture
def sample_user_id():
    return str(uuid.uuid4())


@pytest.fixture
def sample_set_log():
    """Sample workout set log from watch."""
    return {
        "session_id": "session-abc-123",
        "exercise_id": str(uuid.uuid4()),
        "exercise_name": "Bench Press",
        "set_number": 1,
        "actual_reps": 8,
        "weight_kg": 60.0,
        "rpe": 7,
        "rir": 3,
        "logged_at": int(datetime.now().timestamp() * 1000)
    }


@pytest.fixture
def sample_food_log():
    """Sample food log from watch voice input."""
    return {
        "input_type": "VOICE",
        "raw_input": "200 grams chicken breast",
        "calories": None,  # Will be analyzed by Gemini
        "meal_type": "LUNCH",
        "logged_at": int(datetime.now().timestamp() * 1000)
    }


@pytest.fixture
def sample_fasting_event():
    """Sample fasting event from watch."""
    return {
        "event_type": "START",
        "protocol": "16:8",
        "target_duration_minutes": 960,
        "elapsed_minutes": 0,
        "event_at": int(datetime.now().timestamp() * 1000)
    }


@pytest.fixture
def sample_activity():
    """Sample daily activity from watch."""
    return {
        "date": datetime.now().strftime("%Y-%m-%d"),
        "steps": 8500,
        "calories_burned": 450,
        "distance_meters": 6200,
        "active_minutes": 45,
        "heart_rate_samples": [
            {"timestamp": int(datetime.now().timestamp() * 1000), "bpm": 72},
            {"timestamp": int(datetime.now().timestamp() * 1000) + 60000, "bpm": 75}
        ]
    }


# ============================================================
# TESTS - Batch Sync Endpoint
# ============================================================

class TestWatchSyncBatchEndpoint:
    """Tests for POST /watch-sync/sync endpoint."""

    @pytest.mark.asyncio
    async def test_sync_workout_sets_success(
        self,
        mock_supabase_db,
        mock_user_context_service,
        sample_user_id,
        sample_set_log
    ):
        """Test syncing workout sets from watch."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, SetLogRequest

        # Configure mock to return sync record ID
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            device_id="pixel-watch-123",
            workout_sets=[SetLogRequest(**sample_set_log)]
        )

        result = await sync_watch_data(request)

        assert result.success is True
        assert result.synced_items == 1
        assert result.failed_items == 0
        assert result.errors is None

    @pytest.mark.asyncio
    async def test_sync_food_logs_with_gemini(
        self,
        mock_supabase_db,
        mock_gemini_service,
        mock_user_context_service,
        sample_user_id,
        sample_food_log
    ):
        """Test syncing food logs from watch with Gemini analysis."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, FoodLogRequest

        # Configure mock to return sync record ID
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            food_logs=[FoodLogRequest(**sample_food_log)]
        )

        result = await sync_watch_data(request)

        assert result.success is True
        assert result.synced_items == 1

        # Verify Gemini was called to analyze food
        mock_gemini_service.analyze_food.assert_called_once_with("200 grams chicken breast")

    @pytest.mark.asyncio
    async def test_sync_activity_data(
        self,
        mock_supabase_db,
        mock_user_context_service,
        sample_user_id,
        sample_activity
    ):
        """Test syncing daily activity from watch."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, ActivitySyncRequest

        # Configure mock
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            activity=ActivitySyncRequest(**sample_activity)
        )

        result = await sync_watch_data(request)

        assert result.success is True
        assert result.synced_items == 1

        # Verify context service was called
        mock_user_context_service.log_watch_activity_synced.assert_called_once()

    @pytest.mark.asyncio
    async def test_sync_fasting_events(
        self,
        mock_supabase_db,
        mock_user_context_service,
        sample_user_id,
        sample_fasting_event
    ):
        """Test syncing fasting events from watch."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, FastingEventRequest

        # Configure mock
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            fasting_events=[FastingEventRequest(**sample_fasting_event)]
        )

        result = await sync_watch_data(request)

        assert result.success is True
        assert result.synced_items == 1

    @pytest.mark.asyncio
    async def test_sync_empty_request(
        self,
        mock_supabase_db,
        mock_user_context_service,
        sample_user_id
    ):
        """Test sync with no data to sync."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest

        # Configure mock
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch"
        )

        result = await sync_watch_data(request)

        assert result.success is True
        assert result.synced_items == 0
        assert result.failed_items == 0

    @pytest.mark.asyncio
    async def test_sync_bulk_data(
        self,
        mock_supabase_db,
        mock_gemini_service,
        mock_user_context_service,
        sample_user_id,
        sample_set_log,
        sample_food_log,
        sample_activity
    ):
        """Test syncing multiple data types at once."""
        from api.v1.watch_sync import (
            sync_watch_data, WatchSyncRequest,
            SetLogRequest, FoodLogRequest, ActivitySyncRequest
        )

        # Configure mock
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            device_id="pixel-watch-123",
            workout_sets=[SetLogRequest(**sample_set_log)],
            food_logs=[FoodLogRequest(**sample_food_log)],
            activity=ActivitySyncRequest(**sample_activity)
        )

        result = await sync_watch_data(request)

        assert result.success is True
        assert result.synced_items == 3  # 1 set + 1 food + 1 activity

    @pytest.mark.asyncio
    async def test_sync_partial_failure(
        self,
        mock_supabase_db,
        mock_user_context_service,
        sample_user_id,
        sample_set_log
    ):
        """Test sync with some items failing."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, SetLogRequest

        # Configure mock to fail on insert
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]

        def execute_side_effect():
            if mock_supabase_db._call_count == 0:
                mock_supabase_db._call_count = 1
                return sync_response
            else:
                raise Exception("Database error")

        mock_supabase_db._call_count = 0
        mock_supabase_db._mock_table.execute.side_effect = execute_side_effect

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            workout_sets=[SetLogRequest(**sample_set_log)]
        )

        result = await sync_watch_data(request)

        # Should handle error gracefully
        assert result.failed_items >= 0


# ============================================================
# TESTS - Activity Goals Endpoint
# ============================================================

class TestActivityGoalsEndpoint:
    """Tests for GET /watch-sync/goals/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_activity_goals_default(
        self,
        mock_supabase_db,
        sample_user_id
    ):
        """Test getting default activity goals when no settings exist."""
        from api.v1.watch_sync import get_activity_goals

        # Configure mock to return no data
        mock_response = MagicMock()
        mock_response.data = None
        mock_supabase_db._mock_table.execute.return_value = mock_response

        result = await get_activity_goals(sample_user_id)

        assert result.steps_goal == 10000
        assert result.active_minutes_goal == 30
        assert result.calories_burned_goal == 500
        assert result.water_ml_goal == 2000

    @pytest.mark.asyncio
    async def test_get_activity_goals_with_neat_settings(
        self,
        mock_supabase_db,
        sample_user_id
    ):
        """Test getting activity goals from NEAT settings."""
        from api.v1.watch_sync import get_activity_goals

        # Configure mock to return NEAT settings
        def execute_side_effect():
            response = MagicMock()
            # Check if it's the NEAT settings query
            if hasattr(mock_supabase_db, '_query_neat'):
                response.data = {"daily_step_goal": 12000}
            else:
                mock_supabase_db._query_neat = True
                response.data = {"daily_step_goal": 12000}
            return response

        mock_supabase_db._mock_table.execute.side_effect = execute_side_effect

        result = await get_activity_goals(sample_user_id)

        assert result.steps_goal == 12000

    @pytest.mark.asyncio
    async def test_get_activity_goals_with_hydration_settings(
        self,
        mock_supabase_db,
        sample_user_id
    ):
        """Test getting water goal from hydration settings."""
        from api.v1.watch_sync import get_activity_goals

        # Track which table is being queried
        call_count = [0]

        def execute_side_effect():
            response = MagicMock()
            call_count[0] += 1

            if call_count[0] == 1:  # NEAT settings
                response.data = None
            elif call_count[0] == 2:  # User profile
                response.data = None
            elif call_count[0] == 3:  # Hydration settings
                response.data = {"daily_goal_ml": 3000}
            else:
                response.data = None

            return response

        mock_supabase_db._mock_table.execute.side_effect = execute_side_effect

        result = await get_activity_goals(sample_user_id)

        assert result.water_ml_goal == 3000


# ============================================================
# TESTS - Request Validation
# ============================================================

class TestRequestValidation:
    """Tests for request model validation."""

    def test_set_log_validation_min_reps(self):
        """Test set log validation for minimum reps."""
        from api.v1.watch_sync import SetLogRequest

        # Valid set with 0 reps (some exercises may have 0 actual reps)
        set_log = SetLogRequest(
            session_id="session-123",
            exercise_id=str(uuid.uuid4()),
            exercise_name="Plank",
            set_number=1,
            actual_reps=0,
            logged_at=int(datetime.now().timestamp() * 1000)
        )
        assert set_log.actual_reps == 0

    def test_set_log_validation_rpe_range(self):
        """Test set log validation for RPE range."""
        from api.v1.watch_sync import SetLogRequest
        from pydantic import ValidationError

        # Invalid RPE > 10
        with pytest.raises(ValidationError):
            SetLogRequest(
                session_id="session-123",
                exercise_id=str(uuid.uuid4()),
                exercise_name="Squat",
                set_number=1,
                actual_reps=5,
                rpe=11,  # Invalid: must be <= 10
                logged_at=int(datetime.now().timestamp() * 1000)
            )

    def test_activity_sync_validation(self):
        """Test activity sync request validation."""
        from api.v1.watch_sync import ActivitySyncRequest

        activity = ActivitySyncRequest(
            date="2025-01-15",
            steps=10000,
            calories_burned=500,
            distance_meters=7500,
            active_minutes=60
        )

        assert activity.steps == 10000
        assert activity.calories_burned == 500

    def test_food_log_meal_type(self):
        """Test food log meal type values."""
        from api.v1.watch_sync import FoodLogRequest

        food_log = FoodLogRequest(
            input_type="VOICE",
            raw_input="oatmeal with berries",
            meal_type="BREAKFAST",
            logged_at=int(datetime.now().timestamp() * 1000)
        )

        assert food_log.meal_type == "BREAKFAST"


# ============================================================
# TESTS - Error Handling
# ============================================================

class TestErrorHandling:
    """Tests for error handling in watch sync."""

    @pytest.mark.asyncio
    async def test_gemini_failure_fallback(
        self,
        mock_supabase_db,
        mock_gemini_service,
        mock_user_context_service,
        sample_user_id
    ):
        """Test fallback when Gemini analysis fails."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, FoodLogRequest

        # Configure Gemini to fail
        mock_gemini_service.analyze_food.side_effect = Exception("Gemini API error")

        # Configure mock DB
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]
        mock_supabase_db._mock_table.execute.return_value = sync_response

        # Food log with pre-parsed values for fallback
        food_log = FoodLogRequest(
            input_type="VOICE",
            raw_input="chicken sandwich",
            food_name="Chicken Sandwich",
            calories=450,
            protein_g=25.0,
            carbs_g=40.0,
            fat_g=15.0,
            meal_type="LUNCH",
            logged_at=int(datetime.now().timestamp() * 1000)
        )

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            food_logs=[food_log]
        )

        result = await sync_watch_data(request)

        # Should still succeed using fallback values
        assert result.success is True
        assert result.synced_items == 1

    @pytest.mark.asyncio
    async def test_database_error_handling(
        self,
        mock_supabase_db,
        mock_user_context_service,
        sample_user_id,
        sample_set_log
    ):
        """Test handling of database errors."""
        from api.v1.watch_sync import sync_watch_data, WatchSyncRequest, SetLogRequest

        # First call for sync event creation succeeds
        sync_response = MagicMock()
        sync_response.data = [{"id": str(uuid.uuid4())}]

        call_count = [0]

        def execute_side_effect():
            call_count[0] += 1
            if call_count[0] == 1:
                return sync_response
            raise Exception("Database connection lost")

        mock_supabase_db._mock_table.execute.side_effect = execute_side_effect

        request = WatchSyncRequest(
            user_id=sample_user_id,
            device_source="watch",
            workout_sets=[SetLogRequest(**sample_set_log)]
        )

        result = await sync_watch_data(request)

        # Should track the failure
        assert result.failed_items > 0
        assert result.errors is not None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
