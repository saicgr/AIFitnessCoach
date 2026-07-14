"""
Tests for Muscle Analytics API endpoints.

Tests muscle heatmap, training frequency, balance analysis,
and per-muscle exercise data.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from datetime import datetime, date, timedelta, timezone
import uuid

# Import app and router
from main import app
from core.auth import get_current_user
from api.v1.muscle_analytics import (
    router,
    TimeRange,
    ViewType,
    MuscleHeatmapResponse,
    MuscleFrequencyResponse,
    MuscleBalanceResponse,
    MuscleExercisesResponse,
    MuscleHistoryResponse,
)

client = TestClient(app)

# Test data
TEST_USER_ID = str(uuid.uuid4())


@pytest.fixture(autouse=True)
def _authenticated_user():
    """Satisfy the auth dependency for every muscle-analytics request.

    Every endpoint in this router depends on `get_current_user` and then calls
    `verify_user_ownership(current_user, user_id)`. Without an override the
    requests 401 before the handler runs, so the authenticated identity must be
    the same user the tests query for (TEST_USER_ID).
    """
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "muscle-test@example.com",
    }
    try:
        yield
    finally:
        app.dependency_overrides.pop(get_current_user, None)


class QueryChain:
    """Minimal stand-in for a PostgREST query builder.

    Every builder method (`select`, `eq`, `gte`, `ilike`, `order`, `is_`, ...)
    returns the chain itself and `execute()` yields the configured rows, so a
    test doesn't have to mirror the exact call sequence of the endpoint under
    test. `not_` is exposed as an attribute (not a call) to match
    `query.not_.is_(...)`.
    """

    def __init__(self, data):
        self._data = data

    @property
    def not_(self):
        return self

    def __getattr__(self, _name):
        return lambda *args, **kwargs: self

    def execute(self):
        return MagicMock(data=self._data)


class TestMuscleHeatmapEndpoint:
    """Tests for GET /muscle-analytics/heatmap"""

    def test_get_heatmap_success(self):
        """Test successful heatmap data retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # Mock RPC call
            mock_result = MagicMock()
            mock_result.data = {
                "user_id": TEST_USER_ID,
                "period_days": 28,
                "max_volume_kg": 5000.0,
                "muscles": [
                    {
                        "muscle_group": "chest",
                        "total_volume_kg": 5000.0,
                        "intensity_score": 100,
                        "workout_count": 8,
                        "color": "high",
                        "hex_color": "#FF4444",
                    },
                    {
                        "muscle_group": "back",
                        "total_volume_kg": 4000.0,
                        "intensity_score": 80,
                        "workout_count": 6,
                        "color": "high",
                        "hex_color": "#FF4444",
                    },
                    {
                        "muscle_group": "legs",
                        "total_volume_kg": 2000.0,
                        "intensity_score": 40,
                        "workout_count": 4,
                        "color": "medium",
                        "hex_color": "#FF8844",
                    },
                ],
            }
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/heatmap",
                params={"user_id": TEST_USER_ID, "time_range": "4_weeks"}
            )

            assert response.status_code == 200
            data = response.json()
            assert "muscles" in data
            assert len(data["muscles"]) == 3
            assert data["most_trained"] == "chest"
            assert data["least_trained"] == "legs"

    def test_get_heatmap_fallback(self):
        """Test heatmap with fallback query when RPC fails.

        The fallback source changed: it used to read the `muscle_training_frequency`
        view, but that view depends on `workout_sets`, which is empty in prod, so
        the endpoint now aggregates `workout_logs.sets_json` directly (see the
        comment at muscle_analytics.py "Fallback: aggregate from
        workout_logs.sets_json"). The mock therefore feeds workout_logs rows.
        The guarantee under test is unchanged: when the RPC blows up, the
        endpoint still returns muscle data instead of erroring.
        """
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # Make RPC fail
            mock_client.rpc.return_value.execute.side_effect = Exception("RPC failed")

            # Fallback now aggregates completed workout_logs by primary muscle.
            mock_client.table.return_value = QueryChain([
                {
                    "id": "log-1",
                    "completed_at": datetime.now().astimezone().isoformat(),
                    "sets_json": [
                        {
                            "name": "Bench Press",
                            "sets": [
                                {"reps": 10, "weight_kg": 60},
                                {"reps": 10, "weight_kg": 60},
                            ],
                        },
                    ],
                },
            ])

            response = client.get(
                "/api/v1/muscle-analytics/heatmap",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["muscles"]) == 1
            assert data["muscles"][0]["volume_kg"] == 1200.0
            assert data["muscles"][0]["workout_count"] == 1

    def test_get_heatmap_empty(self):
        """Test heatmap with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {"muscles": []}
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/heatmap",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["muscles"] == []


class TestMuscleFrequencyEndpoint:
    """Tests for GET /muscle-analytics/frequency"""

    def test_get_frequency_success(self):
        """Test successful frequency data retrieval.

        Source changed: frequency is now aggregated per row from
        `exercise_workout_history` (one row = one session for that muscle) rather
        than read pre-aggregated from a `muscle_training_frequency` view, so the
        fixture supplies session rows. Intent is unchanged: 8 chest sessions in
        30 days (2.0/wk) is optimal, 2 calf sessions (0.5/wk) is undertrained.
        """
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # The endpoint measures "days since" against datetime.now(UTC), so
            # anchor the fixture dates to the UTC day (not the local one) to keep
            # the expected values stable in any timezone.
            today = datetime.now(timezone.utc).date()
            rows = []
            # Chest: 8 sessions in the last 30 days -> 2.0/week -> optimal
            for i in range(8):
                rows.append({
                    "muscle_group": "chest",
                    "workout_date": (today - timedelta(days=i * 3)).isoformat(),
                    "total_volume_kg": 12500.0,
                })
            # Calves: 2 sessions in the last 30 days -> 0.5/week -> undertrained
            for i in range(2):
                rows.append({
                    "muscle_group": "calves",
                    "workout_date": (today - timedelta(days=16 + i * 7)).isoformat(),
                    "total_volume_kg": 5000.0,
                })
            mock_client.from_.return_value = QueryChain(rows)

            response = client.get(
                "/api/v1/muscle-analytics/frequency",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["frequencies"]) == 2
            # Chest should be optimal, calves should be undertrained
            assert data["undertrained_count"] == 1
            assert data["overtrained_count"] == 0

            by_muscle = {f["muscle_group"]: f for f in data["frequencies"]}
            assert by_muscle["chest"]["recommendation"] == "optimal"
            assert by_muscle["calves"]["recommendation"] == "undertrained"
            # Regression guard: days_since_last_training used to be silently None
            # for every muscle — `workout_date` is a DATE, so parsing it yields a
            # naive datetime and subtracting it from an aware `now` raised a
            # TypeError that was swallowed by a bare `except: pass`.
            assert by_muscle["chest"]["days_since_last_training"] == 0
            assert by_muscle["calves"]["days_since_last_training"] == 16

    def test_get_frequency_empty(self):
        """Test frequency with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_client.from_.return_value = QueryChain([])

            response = client.get(
                "/api/v1/muscle-analytics/frequency",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["frequencies"] == []
            assert data["avg_weekly_workouts"] == 0


class TestMuscleBalanceEndpoint:
    """Tests for GET /muscle-analytics/balance"""

    def test_get_balance_balanced(self):
        """Test balance analysis with balanced training.

        Source changed: the endpoint no longer reads a pre-computed
        `muscle_balance` view row (push_volume_kg / push_pull_ratio / ...); it
        sums per-muscle volume from `exercise_workout_history` and derives the
        four ratios itself. The fixture now supplies per-muscle volumes that add
        up to the same balanced picture the old fixture described
        (push 5000 / pull 5000, upper 10000 / lower 8000, chest 3000 / back 3500,
        quads 4000 / hamstrings 2000). Assertions are unchanged.
        """
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_client.from_.return_value = QueryChain([
                {"muscle_group": "chest", "total_volume_kg": 3000.0},
                {"muscle_group": "shoulders", "total_volume_kg": 1000.0},
                {"muscle_group": "triceps", "total_volume_kg": 1000.0},
                {"muscle_group": "back", "total_volume_kg": 3500.0},
                {"muscle_group": "biceps", "total_volume_kg": 1500.0},
                {"muscle_group": "quads", "total_volume_kg": 4000.0},
                {"muscle_group": "hamstrings", "total_volume_kg": 2000.0},
                {"muscle_group": "glutes", "total_volume_kg": 1500.0},
                {"muscle_group": "calves", "total_volume_kg": 500.0},
            ])

            response = client.get(
                "/api/v1/muscle-analytics/balance",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["ratios"]) == 4
            assert data["overall_status"] == "balanced"
            assert data["imbalance_count"] == 0

            push_pull = next(r for r in data["ratios"] if r["category"] == "push_pull")
            assert push_pull["side1_volume_kg"] == 5000.0
            assert push_pull["side2_volume_kg"] == 5000.0
            assert push_pull["ratio"] == 1.0

    def test_get_balance_imbalanced(self):
        """Test balance analysis with imbalanced training.

        Same source change as test_get_balance_balanced: per-muscle volumes are
        supplied and the endpoint derives the ratios. Volumes reproduce the old
        fixture's imbalanced picture (push 8000 / pull 4000 = 2.0,
        upper 12000 / lower 5000, chest 5000 / back 2000, quads 4000 /
        hamstrings 1000 = 4.0). Assertions are unchanged.
        """
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_client.from_.return_value = QueryChain([
                {"muscle_group": "chest", "total_volume_kg": 5000.0},
                {"muscle_group": "shoulders", "total_volume_kg": 2000.0},
                {"muscle_group": "triceps", "total_volume_kg": 1000.0},
                {"muscle_group": "back", "total_volume_kg": 2000.0},
                {"muscle_group": "biceps", "total_volume_kg": 2000.0},
                {"muscle_group": "quads", "total_volume_kg": 4000.0},
                {"muscle_group": "hamstrings", "total_volume_kg": 1000.0},
            ])

            response = client.get(
                "/api/v1/muscle-analytics/balance",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["imbalance_count"] >= 2
            assert data["overall_status"] == "significant_imbalances"
            assert len(data["recommendations"]) > 0

            push_pull = next(r for r in data["ratios"] if r["category"] == "push_pull")
            assert push_pull["ratio"] == 2.0
            assert push_pull["status"] == "severe_imbalance"

    def test_get_balance_empty(self):
        """Test balance with no data.

        Empty-state contract changed: the endpoint used to return whatever the
        `muscle_balance` view held (nothing -> `ratios == []`). It now always
        emits the same four ratio slots — that is what `get_balance_status`'s
        dedicated "insufficient_data" status is for (see test_balance_status),
        and what the Flutter balance chart renders. So "no data" is now expressed
        as four zero-volume ratios flagged insufficient_data, not an empty list.
        The guarantee under test is unchanged: no data must not be reported as an
        imbalance.
        """
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_client.from_.return_value = QueryChain([])

            response = client.get(
                "/api/v1/muscle-analytics/balance",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["ratios"]) == 4
            assert all(r["status"] == "insufficient_data" for r in data["ratios"])
            assert all(
                r["side1_volume_kg"] == 0 and r["side2_volume_kg"] == 0
                for r in data["ratios"]
            )
            assert data["imbalance_count"] == 0
            assert data["recommendations"] == []


class TestMuscleExercisesEndpoint:
    """Tests for GET /muscle-analytics/muscle/{muscle_group}/exercises"""

    def test_get_exercises_success(self):
        """Test successful muscle exercises retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {
                "exercises": [
                    {
                        "exercise_name": "bench press",
                        "times_performed": 50,
                        "total_volume_kg": 50000.0,
                        "max_weight_kg": 100.0,
                        "last_performed": "2024-01-15",
                    },
                    {
                        "exercise_name": "incline press",
                        "times_performed": 30,
                        "total_volume_kg": 25000.0,
                        "max_weight_kg": 80.0,
                        "last_performed": "2024-01-14",
                    },
                ],
            }
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/exercises",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["exercises"]) == 2
            assert data["muscle_group"] == "chest"
            # First exercise should have higher contribution
            assert data["exercises"][0]["contribution"] > data["exercises"][1]["contribution"]

    def test_get_exercises_empty(self):
        """Test muscle exercises with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {"exercises": []}
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/forearms/exercises",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["exercises"] == []
            assert data["total_exercises"] == 0


class TestMuscleHistoryEndpoint:
    """Tests for GET /muscle-analytics/muscle/{muscle_group}/history"""

    def test_get_history_success(self):
        """Test successful muscle history retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "week_start": "2024-01-01",
                    "week_number": 1,
                    "year": 2024,
                    "total_sets": 15,
                    "total_volume_kg": 5000.0,
                    "exercise_count": 3,
                    "max_weight_kg": 100.0,
                },
                {
                    "week_start": "2024-01-08",
                    "week_number": 2,
                    "year": 2024,
                    "total_sets": 18,
                    "total_volume_kg": 6000.0,
                    "exercise_count": 4,
                    "max_weight_kg": 105.0,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/history",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["data_points"]) == 2
            assert data["volume_trend"] == "improving"
            assert data["volume_change"] > 0

    def test_get_history_declining(self):
        """Test muscle history with declining trend."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "week_start": "2024-01-01",
                    "week_number": 1,
                    "year": 2024,
                    "total_sets": 20,
                    "total_volume_kg": 8000.0,
                },
                {
                    "week_start": "2024-01-08",
                    "week_number": 2,
                    "year": 2024,
                    "total_sets": 12,
                    "total_volume_kg": 5000.0,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/history",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["volume_trend"] == "declining"

    def test_get_history_insufficient_data(self):
        """Test muscle history with insufficient data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {"week_start": "2024-01-01", "week_number": 1, "year": 2024, "total_sets": 15, "total_volume_kg": 5000.0},
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/history",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["volume_trend"] == "insufficient_data"


class TestLogViewEndpoint:
    """Tests for POST /muscle-analytics/log-view"""

    def test_log_view_heatmap(self):
        """Test logging heatmap view."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [{"id": str(uuid.uuid4())}]
            mock_client.from_.return_value.insert.return_value.execute.return_value = mock_result

            response = client.post(
                "/api/v1/muscle-analytics/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "view_type": "heatmap",
                    "session_duration_seconds": 30,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "logged"

    def test_log_view_muscle_detail(self):
        """Test logging muscle detail view."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [{"id": str(uuid.uuid4())}]
            mock_client.from_.return_value.insert.return_value.execute.return_value = mock_result

            response = client.post(
                "/api/v1/muscle-analytics/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "view_type": "muscle_detail",
                    "muscle_group": "chest",
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "logged"

    def test_log_view_handles_error(self):
        """Test view logging handles database errors gracefully."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client
            mock_client.from_.return_value.insert.return_value.execute.side_effect = Exception("DB Error")

            response = client.post(
                "/api/v1/muscle-analytics/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "view_type": "heatmap",
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "error"


class TestHelperFunctions:
    """Tests for helper functions."""

    def test_time_range_conversion(self):
        """Test time range to days conversion."""
        from api.v1.muscle_analytics import get_days_for_time_range

        assert get_days_for_time_range(TimeRange.ONE_WEEK) == 7
        assert get_days_for_time_range(TimeRange.TWO_WEEKS) == 14
        assert get_days_for_time_range(TimeRange.FOUR_WEEKS) == 28
        assert get_days_for_time_range(TimeRange.EIGHT_WEEKS) == 56
        assert get_days_for_time_range(TimeRange.TWELVE_WEEKS) == 84

    def test_intensity_color(self):
        """Test intensity to color conversion."""
        from api.v1.muscle_analytics import get_intensity_color

        color, hex_color = get_intensity_color(0.9)
        assert color == "high"
        assert hex_color == "#FF4444"

        color, hex_color = get_intensity_color(0.6)
        assert color == "medium"

        color, hex_color = get_intensity_color(0.3)
        assert color == "low"

        color, hex_color = get_intensity_color(0.1)
        assert color == "none"

    def test_frequency_recommendation(self):
        """Test frequency recommendation logic."""
        from api.v1.muscle_analytics import get_frequency_recommendation

        assert get_frequency_recommendation(0.5) == "undertrained"
        assert get_frequency_recommendation(2.0) == "optimal"
        assert get_frequency_recommendation(5.0) == "overtrained"

    def test_balance_status(self):
        """Test balance status determination."""
        from api.v1.muscle_analytics import get_balance_status

        status, rec = get_balance_status(1.0, 0.8, 1.2)
        assert status == "balanced"

        status, rec = get_balance_status(1.4, 0.8, 1.2)
        assert status == "imbalanced"

        status, rec = get_balance_status(2.0, 0.8, 1.2)
        assert status == "severe_imbalance"

        status, rec = get_balance_status(0, 0.8, 1.2)
        assert status == "insufficient_data"
