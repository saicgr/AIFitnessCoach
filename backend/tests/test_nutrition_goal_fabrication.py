"""Regression gate: GET /nutrition/preferences never fabricates a "maintain"
goal for a user who has one on record elsewhere.

Row 45 (backend defaults triage): an account with 0 rows in
`nutrition_preferences` but `users.primary_goal = 'build_muscle'` got back
`nutrition_goal = "maintain"` from `NutritionPreferencesResponse`'s hardcoded
default (models.py) — a literal that doesn't exist anywhere in the DB for the
user and directly contradicts `users.primary_goal`. The client faithfully
rendered "Maintain Weight" next to a 5.9 kg weight-loss target.

Fixed in `api/v1/nutrition/preferences.py`: the 0-row branch now falls back
to the user's real `users.primary_goal`/`goals` (also decoding the legacy
JSON-encoded-string `users.goals` column) instead of a fabricated literal,
and only returns null when the account genuinely has no goal set anywhere.

Run: backend/.venv312/bin/python -m pytest tests/test_nutrition_goal_fabrication.py -v
"""
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from core.auth import get_current_user
from main import app

TEST_USER_ID = "11111111-2222-3333-4444-555555555555"

_NO_ROW = object()


class _Chain:
    """Chainable PostgREST stand-in. `_NO_ROW` reproduces `.maybe_single()`'s
    real behaviour of returning None (not a response with data=None) on 0 rows."""

    def __init__(self, table: str, canned: dict):
        self._table = table
        self._canned = canned

    def __getattr__(self, _name):
        return lambda *a, **k: self

    def execute(self):
        value = self._canned.get(self._table, [])
        if value is _NO_ROW:
            return None
        return SimpleNamespace(data=value)


def _fake_db(canned: dict):
    db = MagicMock()
    db.client.table.side_effect = lambda name: _Chain(name, canned)
    return db


@pytest.fixture(autouse=True)
def override_auth():
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "goal-test@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def client():
    return TestClient(app)


def _get_preferences(client, canned):
    db = _fake_db(canned)
    with patch("api.v1.nutrition.preferences.get_supabase_db", return_value=db):
        response = client.get(f"/api/v1/nutrition/preferences/{TEST_USER_ID}")
    return response


def test_no_prefs_row_reflects_real_users_primary_goal_not_maintain(client):
    """The exact repro from the triage row: 0 nutrition_preferences rows,
    users.primary_goal='build_muscle', users.goals is a JSON-ENCODED STRING
    (legacy VARCHAR column) — must decode it and never fall back to
    'maintain'."""
    response = _get_preferences(
        client,
        {
            "nutrition_preferences": _NO_ROW,
            "users": {
                "primary_goal": "build_muscle",
                "goals": '["build_muscle", "increase_strength"]',
                "target_weight_kg": 76.2036,
            },
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["nutrition_goal"] == "build_muscle"
    assert body["nutrition_goals"] == ["build_muscle", "increase_strength"]
    assert body["goal_weight_kg"] == 76.2036


def test_no_prefs_row_and_no_users_goal_returns_null_not_maintain(client):
    """An account with genuinely no goal anywhere must get null, not the old
    fabricated 'maintain' literal — the surface has to gate on this, never
    render an invented goal."""
    response = _get_preferences(
        client,
        {
            "nutrition_preferences": _NO_ROW,
            "users": {"primary_goal": None, "goals": None, "target_weight_kg": None},
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["nutrition_goal"] is None
    assert body["nutrition_goals"] == []


def test_existing_prefs_row_is_unaffected(client):
    """Sanity: the real-row path (untouched by this fix) still works."""
    response = _get_preferences(
        client,
        {
            "nutrition_preferences": {
                "id": "prefs-1",
                "user_id": TEST_USER_ID,
                "nutrition_goal": "lose_fat",
                "nutrition_goals": ["lose_fat"],
            },
            "users": {"target_weight_kg": 70.0},
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["nutrition_goal"] == "lose_fat"
