"""
Tests for Today's Workout API endpoints.

Tests the GET /api/v1/workouts/today and POST /api/v1/workouts/today/start endpoints
which provide the quick-start experience for users.

Test cases:
- User has workout scheduled for today -> returns workout summary
- Today is rest day -> returns rest_day status with next workout info
- Today is workout day but no workout generated -> appropriate response
- No upcoming workouts scheduled -> appropriate response
- User context logging is triggered

Run with: pytest backend/tests/test_today_workout.py -v
"""

import pytest
from datetime import datetime, date, timedelta, timezone
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import uuid
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from core.auth import get_current_user


client = TestClient(app)


def _utc_today() -> date:
    """'Today' as the endpoint will actually resolve it.

    None of these requests send an X-User-Timezone header and the mocked
    user has no `timezone` field, so `resolve_timezone` always falls back to
    UTC. Building fixture dates from the local system clock (`date.today()`)
    instead of UTC made every same-day/next-day assertion flaky whenever the
    suite runs in the local-evening/UTC-past-midnight window (any US timezone
    after ~7pm local). Anchor here so fixture dates always agree with what
    the endpoint computes.
    """
    return datetime.now(timezone.utc).date()


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture(autouse=True)
def auth_as_sample_user(sample_user_id):
    """Authenticate every request in this module as `sample_user_id`.

    `GET /workouts/today` and `POST /workouts/today/start` are behind
    `Depends(get_current_user)` (Supabase JWT). These tests cover today-workout
    BUSINESS LOGIC, not authentication — auth is covered by the auth tests — so
    the dependency is stubbed; without it every request 401s before the handler
    runs. The override is torn down after each test so the shared `main.app`
    object is not left mutated for other test modules.
    """
    async def _current_user():
        return {"id": sample_user_id, "email": "test@example.com"}

    app.dependency_overrides[get_current_user] = _current_user
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def sample_workout_id():
    """Sample workout ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase_db():
    """Mock Supabase database for testing."""
    with patch("api.v1.workouts.today.get_supabase_db") as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        # `db.client.table(...)` chained-query calls (e.g. the completed_today_rows
        # completed_at fallback, active-assignment lookup) must resolve to no
        # data rather than leaking a truthy MagicMock through every
        # `.select()/.eq()/.gte()/.lt()/.order()/.limit()` link. Self-referential
        # so any chain shape/length still bottoms out at an empty `.execute()`.
        query_chain = MagicMock()
        for method in (
            "select", "eq", "neq", "gte", "lte", "gt", "lt",
            "order", "limit", "single", "maybe_single",
        ):
            getattr(query_chain, method).return_value = query_chain
        query_chain.execute.return_value = MagicMock(data=None)
        db_mock.client.table.return_value = query_chain
        yield db_mock


@pytest.fixture
def mock_user_context_service():
    """Mock user context service for analytics logging."""
    with patch("api.v1.workouts.today.user_context_service") as mock:
        mock.log_event = AsyncMock(return_value="event-id-123")
        yield mock


@pytest.fixture
def today_workout_row(sample_workout_id):
    """Sample workout row for today."""
    today_str = _utc_today().isoformat()
    return {
        "id": sample_workout_id,
        "name": "Upper Body Strength",
        "type": "strength",
        "difficulty": "medium",
        "duration_minutes": 45,
        "scheduled_date": today_str,
        "is_completed": False,
        "exercises": [
            {
                "name": "Bench Press",
                "sets": 4,
                "reps": 10,
                "primary_muscle": "Chest",
                "equipment": "barbell",
            },
            {
                "name": "Pull Up",
                "sets": 3,
                "reps": 8,
                "primaryMuscle": "Back",
                "equipment": "pull-up bar",
            },
            {
                "name": "Overhead Press",
                "sets": 3,
                "reps": 10,
                "muscle_group": "Shoulders",
                "equipment": "dumbbells",
            },
        ],
    }


@pytest.fixture
def future_workout_row():
    """Sample workout row for future date."""
    future_date = (_utc_today() + timedelta(days=2)).isoformat()
    return {
        "id": str(uuid.uuid4()),
        "name": "Lower Body Power",
        "type": "strength",
        "difficulty": "hard",
        "duration_minutes": 50,
        "scheduled_date": future_date,
        "is_completed": False,
        "exercises": [
            {
                "name": "Squat",
                "sets": 5,
                "reps": 5,
                "target_muscle": "Quadriceps",
                "equipment": "barbell",
            },
            {
                "name": "Deadlift",
                "sets": 4,
                "reps": 6,
                "primaryMuscle": "Hamstrings",
                "equipment": "barbell",
            },
        ],
    }


# ============================================================
# GET /api/v1/workouts/today TESTS
# ============================================================

class TestGetTodayWorkout:
    """Tests for the GET /api/v1/workouts/today endpoint."""

    def test_get_today_workout_success(
        self, mock_supabase_db, mock_user_context_service, sample_user_id, today_workout_row
    ):
        """Test getting today's workout when one is scheduled."""
        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [today_workout_row],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        assert data["has_workout_today"] is True
        assert data["today_workout"] is not None
        assert data["today_workout"]["name"] == "Upper Body Strength"
        assert data["today_workout"]["type"] == "strength"
        assert data["today_workout"]["difficulty"] == "medium"
        assert data["today_workout"]["duration_minutes"] == 45
        assert data["today_workout"]["exercise_count"] == 3
        assert data["today_workout"]["is_today"] is True
        assert data["today_workout"]["is_completed"] is False
        assert len(data["today_workout"]["primary_muscles"]) > 0
        # `rest_day_message` was retired from TodayWorkoutResponse in 436ffed5
        # (Jan 2026) — the Flutter client now composes its own rest-day copy.
        assert data["next_workout"] is None

    def test_get_today_workout_rest_day_with_upcoming(
        self, mock_supabase_db, mock_user_context_service, sample_user_id, future_workout_row
    ):
        """Test getting today's workout when today is a rest day but future workouts exist."""
        mock_supabase_db.list_workouts.side_effect = [
            [],
            [future_workout_row],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        assert data["has_workout_today"] is False
        assert data["today_workout"] is None
        assert data["next_workout"] is not None
        assert data["next_workout"]["name"] == "Lower Body Power"
        assert data["days_until_next"] == 2
        # `rest_day_message` was retired from TodayWorkoutResponse in 436ffed5
        # (Jan 2026) — the Flutter client now composes its own rest-day copy.

    def test_get_today_workout_rest_day_tomorrow_workout(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test rest day message when next workout is tomorrow."""
        tomorrow = (_utc_today() + timedelta(days=1)).isoformat()
        tomorrow_workout = {
            "id": str(uuid.uuid4()),
            "name": "Full Body Circuit",
            "type": "hiit",
            "difficulty": "medium",
            "duration_minutes": 30,
            "scheduled_date": tomorrow,
            "is_completed": False,
            "exercises": [{"name": "Burpee", "sets": 3, "reps": 10}],
        }

        mock_supabase_db.list_workouts.side_effect = [
            [],
            [tomorrow_workout],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        assert data["has_workout_today"] is False
        assert data["days_until_next"] == 1
        # `rest_day_message` was retired from TodayWorkoutResponse in 436ffed5
        # (Jan 2026) — the Flutter client now composes its own rest-day copy.

    def test_get_today_workout_no_upcoming_workouts(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test when no workouts are scheduled at all."""
        mock_supabase_db.list_workouts.side_effect = [
            [],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        assert data["has_workout_today"] is False
        assert data["today_workout"] is None
        assert data["next_workout"] is None
        assert data["days_until_next"] is None
        # `rest_day_message` was retired from TodayWorkoutResponse in 436ffed5
        # (Jan 2026) — the Flutter client now composes its own rest-day copy.

    def test_get_today_workout_completed_workout_not_returned(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test that completed workouts are not returned as today's workout."""
        mock_supabase_db.list_workouts.side_effect = [
            [],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is False

    def test_get_today_workout_missing_user_id(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test that an omitted user_id derives the user from the JWT instead
        of 422ing — the /workout/today deep-link (coach "View plan" CTA) hits
        this endpoint without a user_id query param (see today.py's handling
        of `current_user` when `user_id` is falsy)."""
        mock_supabase_db.list_workouts.side_effect = [[], [], []]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get("/api/v1/workouts/today")

        assert response.status_code == 200
        mock_user_context_service.log_event.assert_called_once()
        call_args = mock_user_context_service.log_event.call_args
        assert call_args.kwargs["user_id"] == sample_user_id

    def test_get_today_workout_exercises_as_json_string(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test parsing exercises when stored as JSON string."""
        today_str = _utc_today().isoformat()
        workout_with_json_exercises = {
            "id": str(uuid.uuid4()),
            "name": "Workout with JSON exercises",
            "type": "strength",
            "difficulty": "easy",
            "duration_minutes": 30,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises": json.dumps([
                {"name": "Push Up", "sets": 3, "reps": 15, "primary_muscle": "Chest"},
            ]),
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_with_json_exercises],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["exercise_count"] == 1

    def test_get_today_workout_exercises_json_field(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test parsing exercises from exercises_json field."""
        today_str = _utc_today().isoformat()
        workout_with_exercises_json = {
            "id": str(uuid.uuid4()),
            "name": "Workout with exercises_json",
            "type": "cardio",
            "difficulty": "medium",
            "duration_minutes": 25,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises_json": [
                {"name": "Jump Rope", "sets": 1, "reps": 100, "muscleGroup": "Cardio"},
            ],
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_with_exercises_json],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["exercise_count"] == 1

    def test_get_today_workout_database_error(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test handling of database errors."""
        mock_supabase_db.list_workouts.side_effect = Exception("Database connection failed")

        response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 500

    def test_get_today_workout_logs_analytics_event(
        self, mock_supabase_db, mock_user_context_service, sample_user_id, today_workout_row
    ):
        """Test that analytics event is logged for quick start view."""
        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [today_workout_row],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200

        mock_user_context_service.log_event.assert_called_once()
        call_args = mock_user_context_service.log_event.call_args
        assert call_args.kwargs["user_id"] == sample_user_id
        assert call_args.kwargs["event_type"] == "quick_start_viewed"
        assert "has_workout_today" in call_args.kwargs["event_data"]

    def test_get_today_workout_logging_failure_does_not_fail_request(
        self, mock_supabase_db, mock_user_context_service, sample_user_id, today_workout_row
    ):
        """Test that logging failure doesn't fail the main request.

        The real `log_event` already swallows every exception internally
        (services/user_context/service.py) — every /today-style endpoint
        schedules it via `background_tasks.add_task` unwrapped, relying on
        that contract rather than a try/except per call site. A background
        task only runs AFTER the response has already been sent to the
        client, so even if it raises, the client-observed behavior is still
        a clean 200 — only the server-side logs would show the error.
        Starlette's TestClient defaults to `raise_server_exceptions=True`
        specifically so tests notice bugs there; asserting the actual
        client-observed contract means opting out of that for this request.
        """
        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [today_workout_row],
            [],
            [],
        ]
        mock_user_context_service.log_event.side_effect = Exception("Logging failed")

        lenient_client = TestClient(app, raise_server_exceptions=False)

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = lenient_client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200

    def test_get_today_workout_extracts_primary_muscles(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test that primary muscles are correctly extracted from exercises."""
        today_str = _utc_today().isoformat()
        workout_with_varied_muscles = {
            "id": str(uuid.uuid4()),
            "name": "Full Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 60,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises": [
                {"name": "Bench Press", "primary_muscle": "chest"},
                {"name": "Pull Up", "primaryMuscle": "back"},
                {"name": "Squat", "muscle_group": "legs"},
                {"name": "Plank", "target_muscle": "core"},
                {"name": "Curl", "primary_muscle": "arms"},
                {"name": "Press", "primary_muscle": "shoulders"},
            ],
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_with_varied_muscles],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert len(data["today_workout"]["primary_muscles"]) <= 4

    def test_get_today_workout_handles_empty_exercises(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test handling workout with no exercises."""
        today_str = _utc_today().isoformat()
        workout_no_exercises = {
            "id": str(uuid.uuid4()),
            "name": "Empty Workout",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 30,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises": [],
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_no_exercises],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["exercise_count"] == 0
        assert data["today_workout"]["primary_muscles"] == []


class TestNextWorkoutsList:
    """E2E register #65: `/today` must not collapse every upcoming scheduled
    workout down to a single `next_workout`. A user with a schedule gap
    (e.g. Wed missing, Fri already generated, Sun already generated) needs
    the FULL near-term picture, not just the earliest existing row.

    These patch `_get_active_gym_profile_id` directly to None — the shared
    `mock_supabase_db` MagicMock leaks a MagicMock through the gym-profile
    lookup and fails `TodayWorkoutResponse.gym_profile_id` validation
    (pre-existing harness issue affecting the whole `TestGetTodayWorkout`
    class, unrelated to this fix — see the E2E backend report).
    """

    def test_multiple_future_workouts_all_surfaced(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        friday = (_utc_today() + timedelta(days=2)).isoformat()
        sunday = (_utc_today() + timedelta(days=4)).isoformat()

        def _row(name, scheduled_date):
            return {
                "id": str(uuid.uuid4()),
                "name": name,
                "type": "strength",
                "difficulty": "medium",
                "duration_minutes": 40,
                "scheduled_date": scheduled_date,
                "is_completed": False,
                "exercises": [{"name": "Squat", "sets": 3, "reps": 10}],
            }

        friday_row = _row("Friday Session", friday)
        sunday_row = _row("Sunday Session", sunday)

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [],
            [friday_row, sunday_row],  # DB returns ascending by scheduled_date
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        # Old-client compatibility: next_workout is still the earliest.
        assert data["next_workout"] is not None
        assert data["next_workout"]["name"] == "Friday Session"

        # New: BOTH upcoming workouts are surfaced, not just the first.
        assert "next_workouts" in data
        assert [w["name"] for w in data["next_workouts"]] == [
            "Friday Session",
            "Sunday Session",
        ]
        assert data["next_workouts"][0] == data["next_workout"]

    def test_single_future_workout_still_populates_the_list(
        self, mock_supabase_db, mock_user_context_service, sample_user_id, future_workout_row
    ):
        mock_supabase_db.list_workouts.side_effect = [
            [],
            [future_workout_row],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert len(data["next_workouts"]) == 1
        assert data["next_workouts"][0]["name"] == "Lower Body Power"

    def test_no_upcoming_workouts_yields_empty_list(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        mock_supabase_db.list_workouts.side_effect = [[], [], []]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["next_workouts"] == []
        assert data["next_workout"] is None


# ============================================================
# POST /api/v1/workouts/today/start TESTS
# ============================================================

class TestLogQuickStart:
    """Tests for the POST /api/v1/workouts/today/start endpoint."""

    def test_log_quick_start_success(
        self, mock_user_context_service, sample_user_id, sample_workout_id
    ):
        """Test successfully logging quick start."""
        response = client.post(
            f"/api/v1/workouts/today/start?user_id={sample_user_id}&workout_id={sample_workout_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "logged" in data["message"].lower()

        mock_user_context_service.log_event.assert_called_once()
        call_args = mock_user_context_service.log_event.call_args
        assert call_args.kwargs["user_id"] == sample_user_id
        assert call_args.kwargs["event_type"] == "quick_start_tapped"
        assert call_args.kwargs["event_data"]["workout_id"] == sample_workout_id
        assert call_args.kwargs["event_data"]["source"] == "quick_start_widget"

    def test_log_quick_start_logging_failure(
        self, mock_user_context_service, sample_user_id, sample_workout_id
    ):
        """Test that logging failure returns graceful response."""
        mock_user_context_service.log_event.side_effect = Exception("Logging service unavailable")

        response = client.post(
            f"/api/v1/workouts/today/start?user_id={sample_user_id}&workout_id={sample_workout_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False
        assert "failed" in data["message"].lower() or "continues" in data["message"].lower()

    def test_log_quick_start_missing_user_id(self, sample_workout_id):
        """Test that missing user_id returns validation error."""
        response = client.post(
            f"/api/v1/workouts/today/start?workout_id={sample_workout_id}"
        )

        assert response.status_code == 422

    def test_log_quick_start_missing_workout_id(self, sample_user_id):
        """Test that missing workout_id returns validation error."""
        response = client.post(
            f"/api/v1/workouts/today/start?user_id={sample_user_id}"
        )

        assert response.status_code == 422

    def test_log_quick_start_tracks_timestamp(
        self, mock_user_context_service, sample_user_id, sample_workout_id
    ):
        """Test that quick start logging includes timestamp."""
        response = client.post(
            f"/api/v1/workouts/today/start?user_id={sample_user_id}&workout_id={sample_workout_id}"
        )

        assert response.status_code == 200

        call_args = mock_user_context_service.log_event.call_args
        event_data = call_args.kwargs["event_data"]
        assert "timestamp" in event_data


# ============================================================
# EDGE CASES AND INTEGRATION TESTS
# ============================================================

class TestTodayWorkoutEdgeCases:
    """Edge case tests for Today's Workout endpoints."""

    def test_today_workout_with_malformed_exercises_json(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test handling of malformed exercises JSON."""
        today_str = _utc_today().isoformat()
        workout_bad_json = {
            "id": str(uuid.uuid4()),
            "name": "Workout with bad JSON",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 30,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises": "{invalid json}",
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_bad_json],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["exercise_count"] == 0

    def test_today_workout_default_values(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test that missing fields use appropriate defaults."""
        today_str = _utc_today().isoformat()
        minimal_workout = {
            "id": str(uuid.uuid4()),
            "scheduled_date": today_str,
            "is_completed": False,
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [minimal_workout],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["name"] == "Workout"
        assert data["today_workout"]["type"] == "strength"
        assert data["today_workout"]["difficulty"] == "medium"
        assert data["today_workout"]["duration_minutes"] == 45
        assert data["today_workout"]["exercise_count"] == 0

    def test_today_workout_scheduled_date_formats(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test handling of different scheduled_date formats."""
        today_str = _utc_today().isoformat()
        workout_with_datetime = {
            "id": str(uuid.uuid4()),
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "easy",
            "duration_minutes": 30,
            "scheduled_date": f"{today_str}T10:00:00Z",
            "is_completed": False,
            "exercises": [],
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_with_datetime],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["is_today"] is True

    def test_today_workout_none_exercises_field(
        self, mock_supabase_db, mock_user_context_service, sample_user_id
    ):
        """Test handling of None exercises field."""
        today_str = _utc_today().isoformat()
        workout_none_exercises = {
            "id": str(uuid.uuid4()),
            "name": "No Exercises",
            "type": "rest",
            "difficulty": "easy",
            "duration_minutes": 0,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises": None,
        }

        # gather() order: today_rows, future_rows, completed_today_rows.
        mock_supabase_db.list_workouts.side_effect = [
            [workout_none_exercises],
            [],
            [],
        ]

        with patch("api.v1.workouts.today._get_active_gym_profile_id", return_value=None), \
             patch("api.v1.workouts.today._is_today_a_workout_day", return_value=True):
            response = client.get(f"/api/v1/workouts/today?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["today_workout"]["exercise_count"] == 0
        assert data["today_workout"]["primary_muscles"] == []


# ============================================================
# UNIT TESTS FOR HELPER FUNCTIONS
# ============================================================

class TestHelperFunctions:
    """Unit tests for helper functions in today.py."""

    def test_extract_primary_muscles_various_field_names(self):
        """Test that primary muscles are extracted from various field names."""
        from api.v1.workouts.today import _extract_primary_muscles

        exercises = [
            {"name": "Ex1", "primary_muscle": "chest"},
            {"name": "Ex2", "primaryMuscle": "back"},
            {"name": "Ex3", "muscle_group": "legs"},
            {"name": "Ex4", "muscleGroup": "arms"},
            {"name": "Ex5", "target_muscle": "core"},
        ]

        muscles = _extract_primary_muscles(exercises)

        assert "Chest" in muscles
        assert "Back" in muscles
        assert "Legs" in muscles
        assert "Arms" in muscles

    def test_extract_primary_muscles_empty_list(self):
        """Test extracting muscles from empty exercise list."""
        from api.v1.workouts.today import _extract_primary_muscles

        muscles = _extract_primary_muscles([])
        assert muscles == []

    def test_extract_primary_muscles_no_muscle_info(self):
        """Test extracting muscles when exercises have no muscle info."""
        from api.v1.workouts.today import _extract_primary_muscles

        exercises = [
            {"name": "Ex1", "sets": 3, "reps": 10},
            {"name": "Ex2", "sets": 3, "reps": 10},
        ]

        muscles = _extract_primary_muscles(exercises)
        assert muscles == []

    def test_extract_primary_muscles_limits_to_four(self):
        """Test that extracted muscles are limited to 4."""
        from api.v1.workouts.today import _extract_primary_muscles

        exercises = [
            {"name": "Ex1", "primary_muscle": "chest"},
            {"name": "Ex2", "primary_muscle": "back"},
            {"name": "Ex3", "primary_muscle": "legs"},
            {"name": "Ex4", "primary_muscle": "arms"},
            {"name": "Ex5", "primary_muscle": "core"},
            {"name": "Ex6", "primary_muscle": "shoulders"},
        ]

        muscles = _extract_primary_muscles(exercises)
        assert len(muscles) <= 4

    def test_row_to_summary_basic(self):
        """Test converting a row to TodayWorkoutSummary.

        `_row_to_summary` now takes the caller's resolved `user_today_str` and
        raises if it is missing — it must never fall back to the UTC server's
        `date.today()` when deciding `is_today`, or users west of UTC see the
        wrong day flagged. Passing it is the current calling convention; the
        assertions below are unchanged.
        """
        from api.v1.workouts.today import _row_to_summary

        today_str = date.today().isoformat()
        row = {
            "id": "workout-123",
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "hard",
            "duration_minutes": 60,
            "scheduled_date": today_str,
            "is_completed": False,
            "exercises": [
                {"name": "Squat", "primary_muscle": "legs"},
            ],
        }

        summary = _row_to_summary(row, today_str)

        assert summary.id == "workout-123"
        assert summary.name == "Test Workout"
        assert summary.type == "strength"
        assert summary.difficulty == "hard"
        assert summary.duration_minutes == 60
        assert summary.exercise_count == 1
        assert summary.is_today is True
        assert summary.is_completed is False


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
