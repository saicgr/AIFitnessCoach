"""
Tests for POST /exercise-history/batch — per-set history for the Pre-Set
Insight banner.
"""

import uuid
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)
TEST_USER_ID = str(uuid.uuid4())


def _mock_user_dep(user_id=TEST_USER_ID):
    """Bypass the auth dependency for these tests."""
    from core.auth import get_current_user

    async def _override():
        return {"id": user_id, "email": "t@example.com"}

    app.dependency_overrides[get_current_user] = _override


def _clear_overrides():
    app.dependency_overrides.clear()


class TestBatchExerciseHistory:
    def test_returns_per_set_sessions_grouped_by_exercise(self):
        _mock_user_dep()
        try:
            with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
                mock_client = MagicMock()
                mock_db.return_value.client = mock_client

                session_a = str(uuid.uuid4())
                session_b = str(uuid.uuid4())

                # Two sessions of Bench Press and one session of Squat.
                mock_client.from_.return_value.select.return_value \
                    .eq.return_value.in_.return_value.gte.return_value \
                    .order.return_value.limit.return_value.execute.return_value = MagicMock(
                        data=[
                            {"exercise_name": "bench press", "set_number": 1,
                             "reps_completed": 10, "weight_kg": 80.0, "rpe": 8,
                             "rir": 2, "set_type": "working",
                             "recorded_at": "2026-04-19T10:00:00Z",
                             "workout_log_id": session_a},
                            {"exercise_name": "bench press", "set_number": 2,
                             "reps_completed": 9, "weight_kg": 80.0, "rpe": 9,
                             "rir": 1, "set_type": "working",
                             "recorded_at": "2026-04-19T10:05:00Z",
                             "workout_log_id": session_a},
                            {"exercise_name": "bench press", "set_number": 1,
                             "reps_completed": 11, "weight_kg": 77.5, "rpe": 7,
                             "rir": 3, "set_type": "working",
                             "recorded_at": "2026-04-12T10:00:00Z",
                             "workout_log_id": session_b},
                            # Warmup gets filtered
                            {"exercise_name": "bench press", "set_number": 0,
                             "reps_completed": 10, "weight_kg": 40.0, "rpe": 4,
                             "rir": 5, "set_type": "warmup",
                             "recorded_at": "2026-04-19T09:55:00Z",
                             "workout_log_id": session_a},
                            {"exercise_name": "squat", "set_number": 1,
                             "reps_completed": 8, "weight_kg": 100.0, "rpe": 8,
                             "rir": 2, "set_type": "working",
                             "recorded_at": "2026-04-18T10:00:00Z",
                             "workout_log_id": str(uuid.uuid4())},
                        ]
                    )

                response = client.post("/api/v1/exercise-history/batch", json={
                    "user_id": TEST_USER_ID,
                    "exercise_names": ["Bench Press", "Squat"],
                    "limit_per_exercise": 6,
                    "days_back": 84,
                })

                assert response.status_code == 200, response.text
                data = response.json()
                histories = data["histories"]

                assert "Bench Press" in histories
                assert "Squat" in histories

                bench = histories["Bench Press"]
                assert len(bench) == 2  # two sessions
                # Newest first
                assert bench[0]["date"] == "2026-04-19"
                assert len(bench[0]["working_sets"]) == 2  # warmup filtered
                assert bench[0]["working_sets"][0]["reps"] == 10
                assert bench[0]["working_sets"][0]["weight_kg"] == 80.0
                assert bench[0]["working_sets"][0]["rir"] == 2

                squat = histories["Squat"]
                assert len(squat) == 1
                assert squat[0]["working_sets"][0]["reps"] == 8
        finally:
            _clear_overrides()

    def test_returns_empty_histories_when_no_rows(self):
        _mock_user_dep()
        try:
            with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
                mock_client = MagicMock()
                mock_db.return_value.client = mock_client
                mock_client.from_.return_value.select.return_value \
                    .eq.return_value.in_.return_value.gte.return_value \
                    .order.return_value.limit.return_value.execute.return_value = MagicMock(data=[])

                response = client.post("/api/v1/exercise-history/batch", json={
                    "user_id": TEST_USER_ID,
                    "exercise_names": ["Unknown Exercise"],
                })

                assert response.status_code == 200
                assert response.json() == {"histories": {"Unknown Exercise": []}}
        finally:
            _clear_overrides()

    def test_rejects_cross_user_access(self):
        # Authenticated as one user, requesting another user's history.
        _mock_user_dep(user_id=str(uuid.uuid4()))
        try:
            response = client.post("/api/v1/exercise-history/batch", json={
                "user_id": TEST_USER_ID,
                "exercise_names": ["Bench Press"],
            })
            assert response.status_code == 403
        finally:
            _clear_overrides()

    def test_rejects_empty_exercise_list(self):
        _mock_user_dep()
        try:
            response = client.post("/api/v1/exercise-history/batch", json={
                "user_id": TEST_USER_ID,
                "exercise_names": [],
            })
            assert response.status_code == 422
        finally:
            _clear_overrides()

    def test_filters_zero_rep_sets(self):
        _mock_user_dep()
        try:
            with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
                mock_client = MagicMock()
                mock_db.return_value.client = mock_client
                mock_client.from_.return_value.select.return_value \
                    .eq.return_value.in_.return_value.gte.return_value \
                    .order.return_value.limit.return_value.execute.return_value = MagicMock(
                        data=[
                            {"exercise_name": "bench press", "set_number": 1,
                             "reps_completed": 0, "weight_kg": 80.0, "rpe": None,
                             "rir": None, "set_type": "working",
                             "recorded_at": "2026-04-19T10:00:00Z",
                             "workout_log_id": "abc"},
                        ]
                    )

                response = client.post("/api/v1/exercise-history/batch", json={
                    "user_id": TEST_USER_ID,
                    "exercise_names": ["Bench Press"],
                })

                assert response.status_code == 200
                # Session dropped because all its sets were zero-rep.
                assert response.json()["histories"]["Bench Press"] == []
        finally:
            _clear_overrides()
