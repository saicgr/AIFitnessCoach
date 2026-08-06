"""
Regression guard for GET /api/v1/scores/readiness/history.

REGRESSION GUARD (real bug, fixed 2026-07-28, commits b271a901 / 13a0be3a /
8448b7d0): `readiness_scores` columns are ALL nullable (the mid-workout
check-in writes only the sliders it collected, with no computed score yet),
but the response models originally declared them required. A single partial
row 500'd the whole endpoint with Pydantic ValidationErrors three layers deep:

  1. ReadinessResponse required sleep_quality/fatigue_level/stress_level/
     muscle_soreness/hooper_index/readiness_score/readiness_level — a NULL row
     failed with "7 validation errors for ReadinessResponse" (Sentry
     PYTHON-FASTAPI-6Y).
  2. Fixing (1) let a None readiness_score reach
     `calculate_readiness_trend`, which did `current_score > 60` — TypeError.
  3. Fixing (2) still left `ReadinessHistoryResponse.average_score: float`
     required, so a history with zero SCORED rows (average=None) failed with
     "1 validation error for ReadinessHistoryResponse" (Sentry
     PYTHON-FASTAPI-73).

This test pins the end state: a mix of fully-populated and all-null rows
must build a 200 response whose average_score is a plain float (scoreless
rows excluded from the average, not coerced to 0) — no ValidationError.
"""
from collections import defaultdict
from datetime import date, timedelta
from unittest.mock import MagicMock, AsyncMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from core.auth import get_current_user


def _make_table_mock() -> MagicMock:
    table = MagicMock()
    for method in (
        "select", "insert", "update", "delete", "upsert", "eq", "neq", "gte",
        "lte", "lt", "gt", "order", "limit", "is_", "in_", "single",
        "maybe_single", "ilike", "like", "range", "not_",
    ):
        getattr(table, method).return_value = table
    table.execute.return_value = MagicMock(data=[])
    return table


@pytest.fixture
def test_user_id():
    return str(uuid4())


@pytest.fixture
def client(test_user_id):
    app.dependency_overrides[get_current_user] = lambda: {"id": test_user_id}
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def mock_supabase_db():
    tables = defaultdict(_make_table_mock)
    mock_db = MagicMock()
    mock_db.client.table.side_effect = lambda name: tables[name]
    mock_db.get_user.return_value = {"timezone": "UTC"}
    mock_db.tables = tables

    def set_data(table_name, data):
        tables[table_name].execute.return_value = MagicMock(data=data)

    mock_db.set_data = set_data

    with patch("api.v1.scores.get_supabase_db", return_value=mock_db):
        yield mock_db


def _row(user_id: str, days_ago: int, *, scored: bool) -> dict:
    """A `readiness_scores` row shaped like the real table.

    scored=False mirrors a mid-workout check-in that wrote the sliders it
    collected without a computed score — every derived column is NULL,
    exactly the shape that used to 500 this endpoint.
    """
    d = (date.today() - timedelta(days=days_ago)).isoformat()
    base = {
        "id": str(uuid4()),
        "user_id": user_id,
        "score_date": d,
        "sleep_quality": 3 if scored else None,
        "fatigue_level": 2 if scored else None,
        "stress_level": 2 if scored else None,
        "muscle_soreness": 3 if scored else None,
        "mood": None,
        "energy_level": None,
        "hooper_index": 10 if scored else None,
        "readiness_score": 78 if scored else None,
        "readiness_level": "good" if scored else None,
        "ai_workout_recommendation": None,
        "recommended_intensity": None,
        "ai_insight": None,
        "mood_emoji": None,
        "notes": None,
        "submitted_at": None,
        "created_at": None,
    }
    return base


class TestReadinessHistoryNullableRows:
    def test_mixed_null_and_scored_rows_return_200(self, client, mock_supabase_db, test_user_id):
        rows = [
            _row(test_user_id, days_ago=0, scored=True),
            _row(test_user_id, days_ago=1, scored=False),  # partial check-in — no score yet
            _row(test_user_id, days_ago=2, scored=True),
        ]
        mock_supabase_db.set_data("readiness_scores", rows)

        response = client.get(
            f"/api/v1/scores/readiness/history?user_id={test_user_id}&days=30"
        )

        assert response.status_code == 200, response.text
        data = response.json()
        assert len(data["readiness_scores"]) == 3
        # The scoreless row must round-trip with nulls, not be dropped or coerced.
        null_row = next(r for r in data["readiness_scores"] if r["readiness_score"] is None)
        assert null_row["hooper_index"] is None
        assert null_row["readiness_level"] is None
        # average_score excludes the null row rather than coercing it to 0
        # (which would drag the average down and fabricate a decline).
        assert data["average_score"] == 78.0

    def test_all_rows_scoreless_returns_null_average_not_500(self, client, mock_supabase_db, test_user_id):
        """Zero SCORED rows (average=None) must not violate
        ReadinessHistoryResponse.average_score — this is the exact shape
        that produced PYTHON-FASTAPI-73."""
        rows = [_row(test_user_id, days_ago=0, scored=False)]
        mock_supabase_db.set_data("readiness_scores", rows)

        response = client.get(
            f"/api/v1/scores/readiness/history?user_id={test_user_id}&days=30"
        )

        assert response.status_code == 200, response.text
        data = response.json()
        assert data["average_score"] is None
        assert data["total_days"] == 1

    def test_empty_history_returns_200(self, client, mock_supabase_db, test_user_id):
        mock_supabase_db.set_data("readiness_scores", [])

        response = client.get(
            f"/api/v1/scores/readiness/history?user_id={test_user_id}&days=30"
        )

        assert response.status_code == 200, response.text
        data = response.json()
        assert data["readiness_scores"] == []
        assert data["average_score"] is None
        assert data["total_days"] == 0
