"""Regression gate: GET /timeline never disagrees with GET /hydration/goal on
the user's daily water goal.

Row 138 (backend defaults triage): the timeline aggregator hardcoded
`water_goal_ml: 2400` with a comment admitting it was a placeholder ("default
until per-user goal wiring lands"), while `api/v1/hydration.py`'s own default
is 2500 — two different fabricated numbers for the SAME unconfigured account,
shown on the same Home scroll (TIMELINE water tile vs TO DO TODAY chip).

Fixed in `api/v1/timeline.py`: the day-summary builder now calls
`api.v1.hydration.get_user_hydration_goal` (the single source of truth,
reading `user_settings.hydration_goal_ml`) instead of a literal, so both
surfaces always agree — whether the user has configured a goal or not.

Run: backend/.venv312/bin/python -m pytest tests/test_timeline_hydration_goal.py -v
"""
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from core.auth import get_current_user
from main import app

TEST_USER_ID = "22222222-3333-4444-5555-666666666666"

_NO_ROW = object()


class _Chain:
    """Chainable PostgREST stand-in.

    `.maybe_single()` mirrors the real "returns None on 0 rows" behaviour.
    `.single()` (used by get_user_hydration_goal) mirrors the real "raises on
    0/2+ rows" behaviour by raising when the canned value is `_NO_ROW`.
    """

    def __init__(self, table: str, canned: dict, used_single: bool = False):
        self._table = table
        self._canned = canned
        self._used_single = used_single

    def single(self, *a, **k):
        self._used_single = True
        return self

    def __getattr__(self, _name):
        return lambda *a, **k: self

    def execute(self):
        value = self._canned.get(self._table, [])
        if value is _NO_ROW:
            if self._used_single:
                raise Exception(f"no rows found for {self._table} (.single())")
            return None
        if isinstance(value, list):
            return SimpleNamespace(data=value)
        return SimpleNamespace(data=value)


def _fake_db(canned: dict):
    db = MagicMock()
    db.client.table.side_effect = lambda name: _Chain(name, canned)
    return db


@pytest.fixture(autouse=True)
def override_auth():
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "timeline-test@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def client():
    return TestClient(app)


_EMPTY_DOMAIN_TABLES = {
    "workouts": [],
    "food_logs": [],
    "hydration_logs": [],
    "body_measurements": [],
    "mood_log": [],
    "habit_logs": [],
    "user_streaks": [],
    "user_xp": [],
    "personal_records": [],
}


def _get_timeline(client, user_settings):
    canned = dict(_EMPTY_DOMAIN_TABLES)
    canned["user_settings"] = user_settings
    db = _fake_db(canned)

    with patch("api.v1.timeline.get_supabase_db", return_value=db), \
         patch("api.v1.hydration.get_supabase_db", return_value=db), \
         patch("api.v1.timeline.resolve_timezone", return_value="America/Chicago"), \
         patch("api.v1.timeline.get_timeline_cache", return_value=None), \
         patch("api.v1.timeline.set_timeline_cache", return_value=None):
        response = client.get(
            f"/api/v1/timeline?user_id={TEST_USER_ID}&date=2026-07-27&days=1"
        )
    return response


def test_timeline_water_goal_matches_hydration_default_when_unconfigured(client):
    """No user_settings row ⇒ get_user_hydration_goal's real DEFAULT_DAILY_GOAL_ML
    (2500), NEVER the old hardcoded-in-timeline 2400 literal."""
    from api.v1.hydration import DEFAULT_DAILY_GOAL_ML

    response = _get_timeline(client, user_settings=_NO_ROW)

    assert response.status_code == 200, response.text
    body = response.json()
    water_goal = body["days"][0]["summary"]["water_goal_ml"]
    assert water_goal == DEFAULT_DAILY_GOAL_ML
    assert water_goal != 2400, "timeline is still shipping its own stale literal"


def test_timeline_water_goal_reflects_configured_per_user_goal(client):
    """A user WITH a configured goal must see THAT number on the timeline, not
    either fabricated constant."""
    response = _get_timeline(
        client, user_settings={"hydration_goal_ml": 3200}
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["days"][0]["summary"]["water_goal_ml"] == 3200
