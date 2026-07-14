"""
Tests for the Quick Start / Today's Workout API endpoints.

Tests the /api/v1/workouts/today endpoint that provides
the quick-start experience on the home screen.

Run with: pytest tests/test_quick_start.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import date, datetime, timedelta, timezone
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient

import api.v1.workouts.today as today_module
from api.v1.workouts.today import (
    _extract_primary_muscles,
    _row_to_summary,
    TodayWorkoutSummary,
    TodayWorkoutResponse,
)
from core.auth import get_current_user
from main import app

TEST_USER_ID = "test-user"


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def client():
    """TestClient with the auth dependency satisfied.

    `/workouts/today` and `/workouts/today/start` both `Depends(get_current_user)`.
    FastAPI resolves dependencies BEFORE query/body validation, so an
    unauthenticated call short-circuits with 401 and never reaches the code these
    tests are about. Overriding the dependency reproduces what a real signed-in
    caller produces (a user dict with an `id`). The auth gate itself is asserted
    separately in `test_unauthenticated_request_is_rejected`.

    This intentionally shadows the unauthenticated `client` fixture in conftest.
    """
    app.dependency_overrides[get_current_user] = lambda: {"id": TEST_USER_ID}
    # Pin the server's notion of "today" to UTC (what a real client does via the
    # X-User-Timezone header). Without it the server resolves UTC anyway while
    # the test machine computes dates in its local zone — so between 18:00 and
    # midnight CST the two disagree by a day and every is_today / days_until_next
    # assertion drifts.
    yield TestClient(app, headers={"X-User-Timezone": "UTC"})
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def anonymous_client():
    """TestClient with NO auth override — used to assert the 401 gate."""
    return TestClient(app)


@pytest.fixture(autouse=True)
def _isolate_today_state():
    """Clear the module's process-level caches between tests.

    /today memoizes its response, the user record and the gym profile in
    RedisCache instances that fall back to an in-process dict. Every test here
    uses the same user id, so without this an earlier test's cached response is
    served to a later one (cache HIT before any DB call), making results depend
    on test order.
    """
    caches = (
        today_module._today_workout_cache,
        today_module._user_record_cache,
        today_module._gym_profile_cache,
    )
    for cache in caches:
        cache._local.clear()
    today_module._last_bg_gen_schedule.clear()
    yield
    for cache in caches:
        cache._local.clear()
    today_module._last_bg_gen_schedule.clear()


@pytest.fixture(autouse=True)
def _no_real_background_generation():
    """Stop the endpoint's background auto-generation from calling Gemini.

    /today schedules `_sequential_generate_workouts` as a BackgroundTask when a
    scheduled day has no workout, and Starlette's TestClient RUNS background
    tasks after the response. Left unpatched, these tests would fire real
    workout generation. Patched here (not asserted on) so the endpoint's own
    logic is exercised while the fan-out is inert.
    """
    with patch.object(
        today_module, "_sequential_generate_workouts", new=AsyncMock()
    ) as m:
        yield m


def _utc_today() -> date:
    """The date the server will call "today" for these tests (tz header = UTC)."""
    return datetime.now(timezone.utc).date()


def _weekday_of(offset_days: int) -> int:
    """Mon=0..Sun=6 weekday of `utc_today + offset_days` (matches workout_days)."""
    return (_utc_today() + timedelta(days=offset_days)).weekday()


def _make_db_mock(
    *,
    today_rows=None,
    future_rows=None,
    completed_rows=None,
    workout_days=None,
    list_workouts_error: Exception = None,
):
    """Build a `get_supabase_db()` stand-in for the /today endpoint.

    `list_workouts` is dispatched on its kwargs instead of `side_effect=[...]`
    because /today issues its three reads CONCURRENTLY through a thread pool —
    a positional side_effect list would hand results to whichever query happened
    to run first, and a 4th call (the 14-day generation scan) would raise
    StopIteration.

    The supabase query-builder chain (`db.client.table(...)`) returns an empty
    result set, i.e. "no active gym profile, no generation placeholder".
    """
    db = MagicMock()

    chain = MagicMock()
    for method in (
        "select", "eq", "gte", "lte", "limit", "order", "single",
        "insert", "update", "delete", "or_", "is_",
    ):
        getattr(chain, method).return_value = chain
    chain.execute.return_value = MagicMock(data=[])
    db.client.table.return_value = chain

    db.get_user.return_value = {
        "id": TEST_USER_ID,
        "timezone": "UTC",
        "onboarding_completed": True,
        "preferences": {
            "workout_days": (
                workout_days if workout_days is not None else [_weekday_of(0)]
            )
        },
    }

    def _list_workouts(**kwargs):
        if list_workouts_error is not None:
            raise list_workouts_error
        if kwargs.get("allow_multiple_per_date"):
            return list(today_rows or [])
        if kwargs.get("order_asc"):
            return list(future_rows or [])
        if kwargs.get("is_completed") is True:
            return list(completed_rows or [])
        # 14-day scan for dates still needing generation.
        return []

    db.list_workouts.side_effect = _list_workouts
    return db


# ============================================================================
# Unit Tests for Helper Functions
# ============================================================================

class TestExtractPrimaryMuscles:
    """Tests for the _extract_primary_muscles helper function."""

    def test_extract_muscles_from_primary_muscle_field(self):
        """Should extract muscles from primary_muscle field."""
        exercises = [
            {"name": "Bench Press", "primary_muscle": "chest"},
            {"name": "Rows", "primary_muscle": "back"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Chest" in result
        assert "Back" in result

    def test_extract_muscles_from_primaryMuscle_field(self):
        """Should extract muscles from camelCase primaryMuscle field."""
        exercises = [
            {"name": "Squat", "primaryMuscle": "quadriceps"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Quadriceps" in result

    def test_extract_muscles_from_muscle_group_field(self):
        """Should extract muscles from muscle_group field."""
        exercises = [
            {"name": "Curl", "muscle_group": "biceps"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Biceps" in result

    def test_extract_muscles_from_target_muscle_field(self):
        """Should extract muscles from target_muscle field."""
        exercises = [
            {"name": "Tricep Extension", "target_muscle": "triceps"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Triceps" in result

    def test_extract_muscles_limits_to_four(self):
        """Should limit result to maximum 4 muscles."""
        exercises = [
            {"name": "Ex1", "primary_muscle": "chest"},
            {"name": "Ex2", "primary_muscle": "back"},
            {"name": "Ex3", "primary_muscle": "legs"},
            {"name": "Ex4", "primary_muscle": "shoulders"},
            {"name": "Ex5", "primary_muscle": "arms"},
            {"name": "Ex6", "primary_muscle": "core"},
        ]
        result = _extract_primary_muscles(exercises)
        assert len(result) <= 4

    def test_extract_muscles_removes_duplicates(self):
        """Should return unique muscles only."""
        exercises = [
            {"name": "Bench Press", "primary_muscle": "chest"},
            {"name": "Push Up", "primary_muscle": "chest"},
            {"name": "Incline Press", "primary_muscle": "chest"},
        ]
        result = _extract_primary_muscles(exercises)
        assert result == ["Chest"]

    def test_extract_muscles_empty_list(self):
        """Should handle empty exercise list."""
        result = _extract_primary_muscles([])
        assert result == []

    def test_extract_muscles_with_missing_muscle_info(self):
        """Should handle exercises without muscle info."""
        exercises = [
            {"name": "Unknown Exercise"},
            {"name": "Another Exercise", "sets": 3},
        ]
        result = _extract_primary_muscles(exercises)
        assert result == []

    def test_extract_muscles_non_dict_exercises(self):
        """Should handle non-dict items in exercise list."""
        exercises = ["invalid", None, {"primary_muscle": "chest"}]
        result = _extract_primary_muscles(exercises)
        assert "Chest" in result


class TestRowToSummary:
    """Tests for the _row_to_summary helper function.

    `_row_to_summary` now REQUIRES `user_today_str` (it raises ValueError
    otherwise) because falling back to `date.today()` returns the UTC date on a
    Render server, which mislabels a workout as "today" for anyone west of
    Greenwich. These tests therefore pass the caller's reference date explicitly,
    exactly like the endpoint does. The assertions (is_today, exercise parsing,
    defaults) are unchanged.
    """

    def test_row_to_summary_basic(self):
        """Should convert a basic row to TodayWorkoutSummary."""
        row = {
            "id": "workout-123",
            "name": "Upper Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "exercises": [
                {"name": "Push Up", "primary_muscle": "chest"},
                {"name": "Pull Up", "primary_muscle": "back"},
            ],
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.id == "workout-123"
        assert summary.name == "Upper Body"
        assert summary.type == "strength"
        assert summary.difficulty == "medium"
        assert summary.duration_minutes == 45
        assert summary.exercise_count == 2
        assert summary.is_today is True
        assert summary.is_completed is False

    def test_row_to_summary_with_json_string_exercises(self):
        """Should parse exercises from JSON string."""
        exercises = [{"name": "Squat", "primary_muscle": "legs"}]
        row = {
            "id": "workout-456",
            "name": "Leg Day",
            "type": "strength",
            "difficulty": "hard",
            "duration_minutes": 60,
            "exercises": json.dumps(exercises),
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.exercise_count == 1
        assert "Legs" in summary.primary_muscles

    def test_row_to_summary_with_exercises_json_field(self):
        """Should use exercises_json field if exercises is not present."""
        row = {
            "id": "workout-789",
            "name": "Full Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 50,
            "exercises_json": [{"name": "Deadlift", "primary_muscle": "back"}],
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.exercise_count == 1

    def test_row_to_summary_with_invalid_json_exercises(self):
        """Should handle invalid JSON in exercises field."""
        row = {
            "id": "workout-invalid",
            "name": "Test",
            "type": "strength",
            "difficulty": "easy",
            "duration_minutes": 30,
            "exercises": "invalid json {",
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.exercise_count == 0
        assert summary.primary_muscles == []

    def test_row_to_summary_future_date(self):
        """Should correctly identify future workout as not today."""
        tomorrow = (date.today() + timedelta(days=1)).isoformat()
        row = {
            "id": "workout-future",
            "name": "Future Workout",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "exercises": [],
            "scheduled_date": tomorrow,
            "is_completed": False,
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.is_today is False

    def test_row_to_summary_with_defaults(self):
        """Should use defaults for missing fields."""
        row = {
            "id": "workout-minimal",
            "scheduled_date": date.today().isoformat(),
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.name == "Workout"
        assert summary.type == "strength"
        assert summary.difficulty == "medium"
        assert summary.duration_minutes == 45
        assert summary.exercise_count == 0

    def test_row_to_summary_datetime_scheduled_date(self):
        """Should handle datetime string for scheduled_date."""
        row = {
            "id": "workout-dt",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 30,
            "exercises": [],
            "scheduled_date": f"{date.today().isoformat()}T10:00:00Z",
            "is_completed": False,
        }
        summary = _row_to_summary(row, user_today_str=date.today().isoformat())

        assert summary.scheduled_date == date.today().isoformat()


# ============================================================================
# API Endpoint Tests
# ============================================================================

class TestGetTodayWorkoutEndpoint:
    """Tests for the GET /workouts/today endpoint."""

    def test_endpoint_exists(self, client):
        """Test that the today endpoint exists."""
        response = client.get("/api/v1/workouts/today?user_id=test-user")
        # Should not be 404
        assert response.status_code != 404

    def test_unauthenticated_request_is_rejected(self, anonymous_client):
        """No bearer token => 401, before any user data is read."""
        response = anonymous_client.get("/api/v1/workouts/today?user_id=test-user")
        assert response.status_code == 401

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_omitted_user_id_resolves_to_authenticated_user(
        self, mock_context, mock_db, client
    ):
        """An omitted `user_id` query param resolves to the AUTHENTICATED user.

        USED TO ASSERT: 422 when `user_id` was missing.
        RETIRED BECAUSE: the coach's "View plan" deep link hits /workout/today
        with no query params, so `user_id` was made Optional and is now derived
        from the JWT (today.py: `user_id = current_user.get("id") ...`, else 401).
        GUARANTEE PROTECTED NOW: the response is still strictly user-scoped —
        an omitted user_id reads the CALLER's workouts, never a blank/global set.
        """
        mock_db.return_value = _make_db_mock()
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today")

        assert response.status_code == 200
        queried_user_ids = {
            call.kwargs.get("user_id")
            for call in mock_db.return_value.list_workouts.call_args_list
        }
        assert queried_user_ids == {TEST_USER_ID}

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_today_workout_when_exists(self, mock_context, mock_db, client):
        """Should return today's workout when one is scheduled."""
        today_str = _utc_today().isoformat()
        mock_workout = {
            "id": "workout-today-123",
            "name": "Morning Strength",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "exercises": json.dumps([{"name": "Squat", "primary_muscle": "legs"}]),
            "scheduled_date": today_str,
            "is_completed": False,
        }

        mock_db.return_value = _make_db_mock(
            today_rows=[mock_workout],
            workout_days=[_weekday_of(0)],
        )
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is True
        assert data["today_workout"]["id"] == "workout-today-123"
        assert data["today_workout"]["name"] == "Morning Strength"
        assert data["today_workout"]["is_today"] is True

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_rest_day_when_no_today_workout(self, mock_context, mock_db, client):
        """No workout today and none upcoming => rest-day response that asks for
        generation instead of dead-ending.

        USED TO ASSERT: `rest_day_message` contained "No upcoming workouts".
        RETIRED BECAUSE: the server-composed English `rest_day_message` was
        removed from TodayWorkoutResponse (commit 436ffed5) when the hero card
        moved to "never empty — auto-generate instead", and the copy moved
        client-side for i18n (AppLocalizations `quickStartCardTakeItEasyToday`).
        GUARANTEE PROTECTED NOW: the same user-visible outcome, expressed in the
        current contract — no today workout, no next workout, and the response
        TELLS the client a workout must be generated (and for which date), which
        is what stops the "No upcoming workouts" dead end.
        """
        mock_db.return_value = _make_db_mock(workout_days=[_weekday_of(0)])
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is False
        assert data["today_workout"] is None
        assert data["next_workout"] is None
        assert data["needs_generation"] is True
        assert data["next_workout_date"] == _utc_today().isoformat()

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_next_workout_on_rest_day(self, mock_context, mock_db, client):
        """Should return next workout info on rest day.

        The `"tomorrow" in rest_day_message` assertion is now expressed as
        `days_until_next == 1` — same guarantee (the client renders the wording).
        See test_returns_rest_day_when_no_today_workout for why the message field
        was retired.
        """
        tomorrow_str = (_utc_today() + timedelta(days=1)).isoformat()
        next_workout = {
            "id": "workout-tomorrow",
            "name": "Leg Day",
            "type": "strength",
            "difficulty": "hard",
            "duration_minutes": 60,
            "exercises": [],
            "scheduled_date": tomorrow_str,
            "is_completed": False,
        }

        # Today is a rest day: the user only trains on tomorrow's weekday.
        mock_db.return_value = _make_db_mock(
            future_rows=[next_workout],
            workout_days=[_weekday_of(1)],
        )
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is False
        assert data["next_workout"] is not None
        assert data["next_workout"]["id"] == "workout-tomorrow"
        assert data["next_workout"]["is_today"] is False
        assert data["days_until_next"] == 1

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_days_until_next_workout(self, mock_context, mock_db, client):
        """Should correctly calculate days until next workout.

        The `"3 days" in rest_day_message` assertion is now expressed as
        `days_until_next == 3` — same guarantee, current contract (see
        test_returns_rest_day_when_no_today_workout).
        """
        three_days_later = (_utc_today() + timedelta(days=3)).isoformat()
        next_workout = {
            "id": "workout-later",
            "name": "Full Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 50,
            "exercises": [],
            "scheduled_date": three_days_later,
            "is_completed": False,
        }

        mock_db.return_value = _make_db_mock(
            future_rows=[next_workout],
            workout_days=[_weekday_of(3)],
        )
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["next_workout"]["id"] == "workout-later"
        assert data["days_until_next"] == 3

    @patch('api.v1.workouts.today.get_supabase_db')
    def test_handles_database_error(self, mock_db, client):
        """Should return 500 when database error occurs."""
        mock_db.return_value = _make_db_mock(
            list_workouts_error=Exception("Database error")
        )

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 500


class TestLogQuickStartEndpoint:
    """Tests for the POST /workouts/today/start endpoint."""

    def test_endpoint_exists(self, client):
        """Test that the start endpoint exists."""
        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user&workout_id=workout-123"
        )
        # Should not be 404
        assert response.status_code != 404

    def test_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.post(
            "/api/v1/workouts/today/start?workout_id=workout-123"
        )
        assert response.status_code == 422

    def test_requires_workout_id(self, client):
        """Test that workout_id is required."""
        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user"
        )
        assert response.status_code == 422

    @patch('api.v1.workouts.today.user_context_service')
    def test_logs_quick_start_success(self, mock_context, client):
        """Should log quick start event successfully."""
        mock_context.log_event = AsyncMock()

        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user&workout_id=workout-123"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

        # Verify log_event was called
        mock_context.log_event.assert_called_once()
        call_args = mock_context.log_event.call_args
        assert call_args.kwargs["user_id"] == "test-user"
        assert call_args.kwargs["event_type"] == "quick_start_tapped"
        assert call_args.kwargs["event_data"]["workout_id"] == "workout-123"

    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_success_even_on_logging_failure(self, mock_context, client):
        """Should not fail request even if logging fails."""
        mock_context.log_event = AsyncMock(side_effect=Exception("Logging error"))

        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user&workout_id=workout-123"
        )

        # Should still return 200, just with success=False
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False


# ============================================================================
# Response Model Tests
# ============================================================================

class TestTodayWorkoutSummaryModel:
    """Tests for the TodayWorkoutSummary model."""

    def test_model_instantiation(self):
        """Should create model with required fields."""
        summary = TodayWorkoutSummary(
            id="workout-123",
            name="Test Workout",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            exercise_count=5,
            primary_muscles=["Chest", "Back"],
            scheduled_date="2024-01-15",
            is_today=True,
            is_completed=False,
        )

        assert summary.id == "workout-123"
        assert summary.exercise_count == 5
        assert len(summary.primary_muscles) == 2


class TestTodayWorkoutResponseModel:
    """Tests for the TodayWorkoutResponse model."""

    def test_response_with_today_workout(self):
        """Should create response with today's workout."""
        today_workout = TodayWorkoutSummary(
            id="workout-123",
            name="Test Workout",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            exercise_count=5,
            primary_muscles=["Chest"],
            scheduled_date="2024-01-15",
            is_today=True,
            is_completed=False,
        )

        response = TodayWorkoutResponse(
            has_workout_today=True,
            today_workout=today_workout,
        )

        assert response.has_workout_today is True
        assert response.today_workout is not None
        assert response.next_workout is None

    def test_response_with_next_workout(self):
        """Should create response with next workout on rest day."""
        next_workout = TodayWorkoutSummary(
            id="workout-456",
            name="Tomorrow's Workout",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            exercise_count=4,
            primary_muscles=["Legs"],
            scheduled_date="2024-01-16",
            is_today=False,
            is_completed=False,
        )

        response = TodayWorkoutResponse(
            has_workout_today=False,
            next_workout=next_workout,
            rest_day_message="Rest day! Next workout tomorrow.",
            days_until_next=1,
        )

        assert response.has_workout_today is False
        assert response.today_workout is None
        assert response.next_workout is not None
        assert response.days_until_next == 1

    def test_response_with_no_workouts(self):
        """Should create response with no workouts scheduled."""
        response = TodayWorkoutResponse(
            has_workout_today=False,
            rest_day_message="No upcoming workouts scheduled.",
        )

        assert response.has_workout_today is False
        assert response.today_workout is None
        assert response.next_workout is None
        assert response.days_until_next is None
