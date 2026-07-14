"""
Tests for Exercise History API endpoints.

Tests per-exercise workout history, progression charts,
personal records, and most performed exercises.

TWO STALE-CALL FIXES (the assertions themselves are unchanged):

1. AUTH. Every endpoint in this router now carries
   `current_user: dict = Depends(get_current_user)` plus an ownership guard
   (`current_user["id"] != user_id` -> 403). The tests sent no Authorization
   header, so every request died at the dependency with 401 before the endpoint
   ran. Fixed by overriding the dependency (`app.dependency_overrides`) with the
   request's own user, which is what an authenticated call looks like.

2. DB MOCKING. The tests hand-wired one exact builder chain
   (`from_.return_value.select.return_value.eq.return_value...`), which encodes a
   single call ORDER for a single table and silently returns a bare MagicMock the
   moment the endpoint adds a step. The endpoints have since grown per-gym scope
   resolution (`exercise_library_cleaned`, `gym_profiles`) and a gym_breakdown
   query, so those chains no longer matched. Replaced with `_Query` — a
   chainable builder stub dispatched PER TABLE — so a test states what each table
   returns rather than replaying a brittle call sequence.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from datetime import datetime, date, timedelta
import uuid

# Import app and router
from main import app
from core.auth import get_current_user
from api.v1.exercise_history import (
    router,
    TimeRange,
    ExerciseHistoryResponse,
    ExerciseChartDataResponse,
    ExercisePersonalRecordsResponse,
    MostPerformedExercisesResponse,
)

client = TestClient(app)

# Test data
TEST_USER_ID = str(uuid.uuid4())
TEST_EXERCISE_NAME = "bench press"


# ============================================
# Test doubles
# ============================================

@pytest.fixture(autouse=True)
def authenticated_user():
    """Authenticate every request as TEST_USER_ID (the owner of the data).

    The endpoints' ownership guard still runs — it compares this id against the
    `user_id` in the request, so the guard is exercised, not bypassed.
    """
    app.dependency_overrides[get_current_user] = lambda: {"id": TEST_USER_ID}
    yield
    app.dependency_overrides.pop(get_current_user, None)


def _result(data=None, count=None):
    """A supabase-py APIResponse stand-in (.data / .count)."""
    response = MagicMock()
    response.data = data
    response.count = count
    return response


class _Query:
    """Chainable stand-in for a supabase-py query builder.

    Every builder method (select / eq / ilike / gte / order / range / limit /
    in_ / single / maybe_single / insert / upsert / ...) returns self; execute()
    returns the configured result, or raises the configured error.
    """

    def __init__(self, result=None, error: Exception = None):
        self._result = result if result is not None else _result(data=[], count=0)
        self._error = error

    def execute(self):
        if self._error is not None:
            raise self._error
        return self._result

    def __getattr__(self, _name):
        return lambda *args, **kwargs: self


def _db(tables: dict = None, rpc: _Query = None):
    """A get_supabase_db() stand-in whose client dispatches per table name."""
    tables = tables or {}
    db = MagicMock()
    # Timezone resolution (user_today_date -> resolve_timezone) reads the user
    # row; an empty dict makes it deterministically fall back to UTC.
    db.get_user.return_value = {}
    fallback = _Query()
    db.client.from_.side_effect = lambda name, *a, **k: tables.get(name, fallback)
    db.client.table.side_effect = lambda name, *a, **k: tables.get(name, fallback)
    if rpc is not None:
        db.client.rpc.side_effect = lambda *a, **k: rpc
    return db


class TestExerciseHistoryEndpoint:
    """Tests for GET /exercise-history/{exercise_name}"""

    def test_get_exercise_history_success(self):
        """Test successful exercise history retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            history_rows = [
                {
                    "workout_log_id": str(uuid.uuid4()),
                    "exercise_name": "bench press",
                    "workout_date": "2024-01-15",
                    "workout_name": "Push Day",
                    "workout_type": "strength",
                    "sets_completed": 4,
                    "total_reps": 32,
                    "total_volume_kg": 2400.0,
                    "max_weight_kg": 80.0,
                    "estimated_1rm_kg": 96.0,
                    "avg_rpe": 7.5,
                },
                {
                    "workout_log_id": str(uuid.uuid4()),
                    "exercise_name": "bench press",
                    "workout_date": "2024-01-12",
                    "workout_name": "Upper Body",
                    "workout_type": "strength",
                    "sets_completed": 3,
                    "total_reps": 24,
                    "total_volume_kg": 1800.0,
                    "max_weight_kg": 75.0,
                    "estimated_1rm_kg": 90.0,
                    "avg_rpe": 7.0,
                },
            ]

            mock_db.return_value = _db({
                # count query + paginated query + summary query + gym breakdown
                "exercise_workout_history": _Query(_result(data=history_rows, count=5)),
                "exercise_personal_records": _Query(_result(data=[])),
                # no equipment row -> combined (cross-gym) scope, no gym filter
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}",
                params={"user_id": TEST_USER_ID, "time_range": "12_weeks"}
            )

            assert response.status_code == 200
            data = response.json()
            assert "records" in data
            assert "summary" in data
            assert data["exercise_name"] == TEST_EXERCISE_NAME

    def test_get_exercise_history_empty(self):
        """Test exercise history with no data."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "exercise_workout_history": _Query(_result(data=[], count=0)),
                "exercise_personal_records": _Query(_result(data=[])),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/unknown_exercise",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["total_records"] == 0
            assert data["records"] == []

    def test_get_exercise_history_missing_user_id(self):
        """Test exercise history without user_id parameter."""
        response = client.get(f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}")
        assert response.status_code == 422  # Validation error

    def test_get_exercise_history_pagination(self):
        """Test exercise history pagination."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            rows = [{"workout_log_id": str(uuid.uuid4())} for _ in range(20)]
            mock_db.return_value = _db({
                "exercise_workout_history": _Query(_result(data=rows, count=50)),
                "exercise_personal_records": _Query(_result(data=[])),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}",
                params={"user_id": TEST_USER_ID, "page": 1, "limit": 20}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["has_more"] == True
            assert data["total_pages"] == 3


class TestExerciseChartDataEndpoint:
    """Tests for GET /exercise-history/{exercise_name}/chart"""

    def test_get_chart_data_success(self):
        """Test successful chart data retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            points = [
                {
                    "workout_date": "2024-01-01",
                    "max_weight_kg": 70.0,
                    "avg_weight_kg": 65.0,
                    "total_volume_kg": 1400.0,
                    "total_reps": 30,
                    "estimated_1rm_kg": 84.0,
                },
                {
                    "workout_date": "2024-01-15",
                    "max_weight_kg": 75.0,
                    "avg_weight_kg": 70.0,
                    "total_volume_kg": 1600.0,
                    "total_reps": 32,
                    "estimated_1rm_kg": 90.0,
                },
                {
                    "workout_date": "2024-01-29",
                    "max_weight_kg": 80.0,
                    "avg_weight_kg": 75.0,
                    "total_volume_kg": 1800.0,
                    "total_reps": 35,
                    "estimated_1rm_kg": 96.0,
                },
            ]
            mock_db.return_value = _db({
                "exercise_workout_history": _Query(_result(data=points)),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}/chart",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert "data_points" in data
            assert "trend" in data
            assert len(data["data_points"]) == 3
            assert data["trend"]["direction"] == "improving"

    def test_get_chart_data_declining_trend(self):
        """Test chart data with declining trend."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "exercise_workout_history": _Query(_result(data=[
                    {"workout_date": "2024-01-01", "max_weight_kg": 80.0},
                    {"workout_date": "2024-01-15", "max_weight_kg": 70.0},
                ])),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}/chart",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["trend"]["direction"] == "declining"

    def test_get_chart_data_insufficient_data(self):
        """Test chart data with insufficient data points."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "exercise_workout_history": _Query(_result(
                    data=[{"workout_date": "2024-01-01", "max_weight_kg": 70.0}]
                )),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}/chart",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["trend"]["direction"] == "no_data"


class TestExercisePersonalRecordsEndpoint:
    """Tests for GET /exercise-history/{exercise_name}/prs"""

    def test_get_prs_success(self):
        """Test successful PR retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "exercise_personal_records": _Query(_result(data=[
                    {
                        "record_type": "max_weight",
                        "record_value": 100.0,
                        "record_unit": "kg",
                        "achieved_at": "2024-01-15T10:00:00",
                        "workout_name": "Push Day",
                        "reps_at_record": 5,
                        "weight_at_record_kg": 100.0,
                    },
                    {
                        "record_type": "best_1rm",
                        "record_value": 120.0,
                        "record_unit": "kg",
                        "achieved_at": "2024-01-15T10:00:00",
                        "workout_name": "Push Day",
                    },
                    {
                        "record_type": "max_volume",
                        "record_value": 3000.0,
                        "record_unit": "kg",
                        "achieved_at": "2024-01-10T09:00:00",
                        "workout_name": "Upper Body",
                    },
                ])),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/{TEST_EXERCISE_NAME}/prs",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["records"]) == 3
            assert data["max_weight"]["value"] == 100.0
            assert data["max_1rm"]["value"] == 120.0
            assert data["max_volume"]["value"] == 3000.0

    def test_get_prs_empty(self):
        """Test PR retrieval with no records."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "exercise_personal_records": _Query(_result(data=[])),
                "exercise_library_cleaned": _Query(_result(data=[])),
            })

            response = client.get(
                f"/api/v1/exercise-history/unknown_exercise/prs",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["records"] == []
            assert data["max_weight"] is None


class TestMostPerformedExercisesEndpoint:
    """Tests for GET /exercise-history/most-performed"""

    def test_get_most_performed_success(self):
        """Test successful most performed exercises retrieval.

        REGRESSION GATE: this endpoint's path is STATIC, but it used to be
        registered AFTER `GET /{exercise_name}`. Starlette matches in
        registration order, so `/exercise-history/most-performed` bound to the
        catch-all as exercise_name="most-performed" and this endpoint was
        unreachable — the app's "most performed" list silently rendered empty
        (the history payload has no `exercises` key). Asserting the response
        shape here fails if the route is ever shadowed again.
        """
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db(rpc=_Query(_result(data={
                "exercises": [
                    {
                        "exercise_name": "bench press",
                        "muscle_group": "chest",
                        "times_performed": 50,
                        "total_volume_kg": 50000.0,
                        "max_weight_kg": 100.0,
                        "last_performed_at": "2024-01-15",
                    },
                    {
                        "exercise_name": "squat",
                        "muscle_group": "quadriceps",
                        "times_performed": 45,
                        "total_volume_kg": 75000.0,
                        "max_weight_kg": 150.0,
                        "last_performed_at": "2024-01-14",
                    },
                ],
                "total_unique_exercises": 25,
            })))

            response = client.get(
                "/api/v1/exercise-history/most-performed",
                params={"user_id": TEST_USER_ID, "limit": 10}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["exercises"]) == 2
            assert data["exercises"][0]["exercise_name"] == "bench press"
            assert data["total_unique_exercises"] == 25


class TestLogViewEndpoint:
    """Tests for POST /exercise-history/log-view"""

    def test_log_view_success(self):
        """Test successful view logging."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "muscle_analytics_logs": _Query(_result(data=[{"id": str(uuid.uuid4())}])),
            })

            response = client.post(
                "/api/v1/exercise-history/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "exercise_name": TEST_EXERCISE_NAME,
                    "session_duration_seconds": 120,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "logged"

    def test_log_view_handles_error(self):
        """Test view logging handles database errors gracefully."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_db.return_value = _db({
                "muscle_analytics_logs": _Query(error=Exception("DB Error")),
            })

            response = client.post(
                "/api/v1/exercise-history/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "exercise_name": TEST_EXERCISE_NAME,
                }
            )

            # Should not fail, just return error status
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "error"


class TestTimeRangeConversion:
    """Tests for time range helper function."""

    def test_time_range_values(self):
        """Test all time range enum values convert correctly."""
        from api.v1.exercise_history import get_days_for_time_range

        assert get_days_for_time_range(TimeRange.FOUR_WEEKS) == 28
        assert get_days_for_time_range(TimeRange.EIGHT_WEEKS) == 56
        assert get_days_for_time_range(TimeRange.TWELVE_WEEKS) == 84
        assert get_days_for_time_range(TimeRange.SIX_MONTHS) == 180
        assert get_days_for_time_range(TimeRange.ONE_YEAR) == 365
        assert get_days_for_time_range(TimeRange.ALL_TIME) == 3650
