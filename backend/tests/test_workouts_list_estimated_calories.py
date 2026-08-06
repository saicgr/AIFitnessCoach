"""
Regression test for docs/qa/UI_E2E_2026-08-05.md row 47.

GET /api/v1/workouts/ (the list endpoint the Home metrics carousel's KCAL
BURNED tile reads) silently stripped `estimated_calories` from every row:
the shared `Workout` response model never declared the field, so FastAPI's
response_model filtering dropped it even though `workouts.estimated_calories`
is a real, populated column. The client's own MET-based fallback only fired
because the field arrived null — so the tile showed a guess (125) instead of
the value the server actually computed and stored (147).
"""
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from core.auth import get_current_user
from main import app

TEST_USER_ID = "workouts-list-test-user"


@pytest.fixture
def client():
    app.dependency_overrides[get_current_user] = lambda: {"id": TEST_USER_ID}
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


def _workout_row(workout_id: str, estimated_calories):
    return {
        "id": workout_id,
        "user_id": TEST_USER_ID,
        "name": "Push Day",
        "type": "strength",
        "difficulty": "intermediate",
        "scheduled_date": "2026-08-05T12:00:00+00:00",
        "is_completed": True,
        "exercises_json": "[]",
        "duration_minutes": 45,
        "is_current": True,
        "version_number": 1,
        "is_favorite": False,
        # NOTE: no estimated_calories key here — matches the real
        # db.list_workouts SELECT, which never fetches it. The endpoint must
        # batch-fetch it separately.
    }


def test_list_workouts_returns_real_estimated_calories_not_null(client):
    row_a = _workout_row("workout-a", 147)
    row_b = _workout_row("workout-b", 283)

    mock_db = MagicMock()
    mock_db.list_workouts.return_value = [row_a, row_b]
    mock_db.client.table.return_value.select.return_value.in_.return_value.execute.return_value = (
        MagicMock(
            data=[
                {"id": "workout-a", "estimated_calories": 147},
                {"id": "workout-b", "estimated_calories": 283},
            ]
        )
    )

    with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db), \
         patch(
             "api.v1.workouts.crud.fetch_program_assignment_meta", return_value={}
         ):
        response = client.get(
            "/api/v1/workouts/", params={"user_id": TEST_USER_ID, "limit": 10}
        )

    assert response.status_code == 200, response.text
    body = response.json()
    by_id = {w["id"]: w for w in body}
    assert by_id["workout-a"]["estimated_calories"] == 147, (
        "estimated_calories must be the real server-computed value, not "
        "stripped to null (which drives the client's fabricated MET guess)"
    )
    assert by_id["workout-b"]["estimated_calories"] == 283


def test_list_workouts_missing_calories_column_is_none_not_zero(client):
    """A workout with no computed estimate yet must serialize as null, never
    a fabricated 0 (this repo's no-fabrication rule)."""
    row = _workout_row("workout-c", None)

    mock_db = MagicMock()
    mock_db.list_workouts.return_value = [row]
    mock_db.client.table.return_value.select.return_value.in_.return_value.execute.return_value = (
        MagicMock(data=[{"id": "workout-c", "estimated_calories": None}])
    )

    with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db), \
         patch(
             "api.v1.workouts.crud.fetch_program_assignment_meta", return_value={}
         ):
        response = client.get(
            "/api/v1/workouts/", params={"user_id": TEST_USER_ID, "limit": 10}
        )

    assert response.status_code == 200
    body = response.json()
    assert body[0]["estimated_calories"] is None
