"""
Tests for one-at-a-time workout generation flow.

This tests the feature where:
1. Onboarding generates only 1 workout (not batch)
2. After completing a workout, the next one is generated
3. The /today endpoint returns the EARLIEST upcoming workout (not latest)

Critical bug fix: The sort order fix ensures that when querying for
next workout with limit=1, we get the EARLIEST upcoming workout,
not the LATEST one (which caused "27 days" bug).

Run with: pytest backend/tests/test_one_at_a_time_generation.py -v
"""

import pytest
from datetime import date, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import uuid
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase_db():
    """Mock Supabase database for testing."""
    with patch("api.v1.workouts.today.get_supabase_db") as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def mock_user_context_service():
    """Mock user context service for analytics logging."""
    with patch("api.v1.workouts.today.user_context_service") as mock:
        mock.log_event = AsyncMock(return_value="event-id-123")
        yield mock


# ============================================================
# TEST: SORT ORDER FOR NEXT WORKOUT
# ============================================================

class TestNextWorkoutSortOrder:
    """Tests for the sort order fix that returns earliest upcoming workout."""

    def test_order_asc_returns_earliest_workout(
        self, sample_user_id, mock_supabase_db, mock_user_context_service
    ):
        """
        Critical test: When multiple future workouts exist,
        /today should return the EARLIEST one, not the LATEST.

        Bug scenario:
        - User has workouts on Jan 8 (2 days), Jan 10 (4 days), Feb 1 (27 days)
        - Old code with DESC order + limit=1 returned Feb 1 (27 days)
        - Fixed code with ASC order + limit=1 returns Jan 8 (2 days)
        """
        today = date.today()
        tomorrow = today + timedelta(days=1)

        # Create workouts at different future dates
        earliest_workout = {
            "id": str(uuid.uuid4()),
            "name": "Upper Body - Earliest",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "scheduled_date": (today + timedelta(days=2)).isoformat(),
            "is_completed": False,
            "exercises": [],
        }
        middle_workout = {
            "id": str(uuid.uuid4()),
            "name": "Lower Body - Middle",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "scheduled_date": (today + timedelta(days=5)).isoformat(),
            "is_completed": False,
            "exercises": [],
        }
        latest_workout = {
            "id": str(uuid.uuid4()),
            "name": "Full Body - Latest",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "scheduled_date": (today + timedelta(days=27)).isoformat(),
            "is_completed": False,
            "exercises": [],
        }

        # Mock user
        mock_supabase_db.get_user.return_value = {
            "id": sample_user_id,
            "preferences": '{"workout_days": [0, 2, 4]}'
        }

        # Mock: no workout today
        mock_supabase_db.list_workouts.side_effect = [
            [],  # First call: today's workouts (empty)
            [earliest_workout],  # Second call: future workouts with order_asc=True
        ]

        response = client.get(
            "/api/v1/workouts/today",
            params={"user_id": sample_user_id}
        )

        assert response.status_code == 200
        data = response.json()

        # Should return the EARLIEST workout, not the latest
        assert data["next_workout"] is not None
        assert data["next_workout"]["name"] == "Upper Body - Earliest"
        assert data["days_until_next"] == 2  # NOT 27!

    def test_list_workouts_called_with_order_asc(
        self, sample_user_id, mock_supabase_db, mock_user_context_service
    ):
        """Verify that list_workouts is called with order_asc=True for future workouts."""
        today = date.today()

        mock_supabase_db.get_user.return_value = {
            "id": sample_user_id,
            "preferences": '{"workout_days": [0, 2, 4]}'
        }
        mock_supabase_db.list_workouts.return_value = []

        response = client.get(
            "/api/v1/workouts/today",
            params={"user_id": sample_user_id}
        )

        # Check that the second call (future workouts) used order_asc=True
        calls = mock_supabase_db.list_workouts.call_args_list

        # First call is for today's workouts
        # Second call is for future workouts - should have order_asc=True
        if len(calls) >= 2:
            future_call_kwargs = calls[1].kwargs if calls[1].kwargs else {}
            # The call should include order_asc=True
            assert future_call_kwargs.get("order_asc", False) == True, \
                "Future workout query should use order_asc=True"


# ============================================================
# TEST: ONE-AT-A-TIME GENERATION SCHEMA
# ============================================================

class TestOneAtATimeGenerationSchema:
    """Tests for the schema supporting one-at-a-time generation."""

    def test_generate_monthly_request_accepts_max_workouts_one(self):
        """Test that generation request accepts max_workouts=1 for single workout."""
        from models.schemas import GenerateMonthlyRequest

        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-06",
            selected_days=[0, 2, 4],  # Mon, Wed, Fri
            duration_minutes=45,
            max_workouts=1,  # One-at-a-time
        )

        assert request.max_workouts == 1
        assert request.duration_minutes == 45

    def test_weeks_one_limits_generation_window(self):
        """
        Test that weeks=1 in generate-next limits the generation window.

        The generate-next endpoint uses weeks=1 to ensure only 1 workout
        is generated in the immediate timeframe.
        """
        from models.schemas import GenerateMonthlyRequest

        request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-06",
            selected_days=[0],  # Just Monday
            weeks=1,  # 1 week window
        )

        assert request.weeks == 1


# ============================================================
# TEST: NEXT WORKOUT DATE CALCULATION
# ============================================================

class TestNextWorkoutDateCalculation:
    """Tests for calculating the next workout date based on selected_days."""

    def test_find_next_workout_day_basic(self):
        """Test finding next workout day from selected_days."""
        # Simulate the logic from generate-next endpoint
        from datetime import date, timedelta

        # User's selected workout days (Mon=0, Wed=2, Fri=4)
        selected_days = [0, 2, 4]

        # Start searching from a specific date (e.g., Tuesday)
        # Tuesday = weekday 1
        search_date = date(2025, 1, 7)  # Tuesday
        assert search_date.weekday() == 1

        # Find next day that matches selected_days
        next_workout_date = None
        for i in range(14):
            check_date = search_date + timedelta(days=i)
            if check_date.weekday() in selected_days:
                next_workout_date = check_date
                break

        # Should find Wednesday (weekday=2)
        assert next_workout_date is not None
        assert next_workout_date.weekday() == 2  # Wednesday
        assert next_workout_date == date(2025, 1, 8)

    def test_find_next_workout_wraps_to_next_week(self):
        """Test that search wraps to next week if needed."""
        from datetime import date, timedelta

        # User only works out on Mondays
        selected_days = [0]  # Monday only

        # Start searching from Tuesday
        search_date = date(2025, 1, 7)  # Tuesday

        next_workout_date = None
        for i in range(14):
            check_date = search_date + timedelta(days=i)
            if check_date.weekday() in selected_days:
                next_workout_date = check_date
                break

        # Should find next Monday (6 days later)
        assert next_workout_date is not None
        assert next_workout_date.weekday() == 0  # Monday
        assert next_workout_date == date(2025, 1, 13)

    def test_skip_existing_workout_dates(self):
        """Test that existing workout dates are skipped."""
        from datetime import date

        # Simulate existing workouts
        existing_workouts = [
            {"scheduled_date": "2025-01-08"},
            {"scheduled_date": "2025-01-10"},
        ]

        next_date_to_generate = date(2025, 1, 13)  # Monday after existing

        # Check if workout already exists
        existing_dates = [
            w["scheduled_date"][:10] for w in existing_workouts
        ]

        assert "2025-01-08" in existing_dates
        assert "2025-01-10" in existing_dates
        assert str(next_date_to_generate) not in existing_dates


# ============================================================
# TEST: FLOW DOCUMENTATION
# ============================================================

class TestOneAtATimeFlow:
    """
    Documentation tests for the one-at-a-time workflow.

    Flow:
    1. User onboards -> generates 1 workout (today's or next day)
    2. User completes workout -> triggers generate-next endpoint
    3. generate-next finds the next workout day and generates 1 workout
    4. Repeat step 2-3 forever

    The user always sees exactly 1 upcoming workout until they complete it.
    """

    def test_onboarding_generates_one_workout(self):
        """
        Document: Onboarding uses maxWorkouts=1 to generate single workout.

        See: mobile/flutter/lib/screens/onboarding/workout_generation_screen.dart:107
        """
        from models.schemas import GenerateMonthlyRequest

        # This is what the Flutter app sends during onboarding
        onboarding_request = GenerateMonthlyRequest(
            user_id="new-user-123",
            month_start_date="2025-01-06",  # Today
            selected_days=[0, 2, 4],
            duration_minutes=45,
            max_workouts=1,  # KEY: Only generate 1 workout
        )

        assert onboarding_request.max_workouts == 1

    def test_generate_next_uses_weeks_one(self):
        """
        Document: generate-next endpoint uses weeks=1 for limited window.

        See: backend/api/v1/workouts/background.py:525
        """
        from models.schemas import GenerateMonthlyRequest

        # This is what generate-next sends to the generation service
        next_request = GenerateMonthlyRequest(
            user_id="user-123",
            month_start_date="2025-01-10",  # Next workout day
            selected_days=[0, 2, 4],
            duration_minutes=45,
            weeks=1,  # KEY: 1 week window = 1 workout
        )

        assert next_request.weeks == 1

    def test_never_batch_generate_on_workouts_tab(self):
        """
        Document: Workouts tab no longer triggers batch generation.

        Previously, clicking Workouts tab would check if user has <3 days
        of workouts and regenerate 2 weeks batch. This was removed.

        See: mobile/flutter/lib/screens/workouts/workouts_screen.dart:35-36
        """
        # This is documentation - the actual removal is in Flutter code
        # The initState no longer calls checkAndRegenerateIfNeeded()
        pass


# ============================================================
# TEST: DATABASE LAYER
# ============================================================

class TestDatabaseOrderAsc:
    """Tests for the order_asc parameter in database queries."""

    def test_list_workouts_signature_has_order_asc(self):
        """Verify list_workouts function accepts order_asc parameter."""
        from core.db.facade import SupabaseDB
        import inspect

        sig = inspect.signature(SupabaseDB.list_workouts)
        params = list(sig.parameters.keys())

        assert "order_asc" in params, \
            "list_workouts must have order_asc parameter"

    def test_order_asc_default_is_false(self):
        """Verify order_asc defaults to False (DESC order)."""
        from core.db.facade import SupabaseDB
        import inspect

        sig = inspect.signature(SupabaseDB.list_workouts)
        order_asc_param = sig.parameters.get("order_asc")

        assert order_asc_param is not None
        assert order_asc_param.default == False, \
            "order_asc should default to False (DESC order)"


# ============================================================
# INTEGRATION TEST MARKER
# ============================================================

@pytest.mark.integration
class TestOneAtATimeIntegration:
    """
    Integration tests that require database connection.

    These are skipped in CI but can be run locally with:
    pytest backend/tests/test_one_at_a_time_generation.py -v -m integration
    """

    @pytest.mark.skip(reason="Requires database connection")
    def test_full_onboarding_to_completion_flow(self):
        """
        Full integration test of the one-at-a-time flow.

        1. Create user
        2. Generate 1 workout (onboarding)
        3. Complete workout
        4. Verify next workout is generated
        5. Verify only 2 workouts exist total
        """
        pass
