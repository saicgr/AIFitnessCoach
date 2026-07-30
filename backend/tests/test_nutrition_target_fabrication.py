"""Regression gate: nutrition never fabricates a target the user didn't set.

The "2000-default trap": a user who has never configured nutrition targets has
NONE. Any code that substitutes 2000 kcal / 150 g protein / 200 g carbs / 65-67 g
fat publishes a plan that user never chose — and because
`NutritionPreferencesState.hasConfiguredTargets` (Flutter) is derived from
`target_calories != null`, ONE fabricated value defeats the gate on every
presenting surface at once: home coach card, nutrition rings, per-meal splits,
share cards.

`/nutrition/dynamic-targets` was fixed first (55057fd1) but the class stayed
open, most importantly on the WRITE side: `POST /nutrition/onboarding/skip`
INSERTed the fabricated plan into `nutrition_preferences`, after which the
read-side guard structurally could not tell it from a real plan.

Covered here:
  1. Skipping onboarding persists the skip and NOTHING else — no targets, no
     diet type, no meal pattern.
  2. `POST /nutrition/recommendations/{id}/generate` refuses (409) rather than
     inventing a 2000 kcal baseline when there is neither a configured target
     nor a usable adaptive TDEE, and reports `adjustment_amount = null` (not 0)
     when it recommends against no baseline.
  3. `POST /nutrition/reports/weekly` answers 200 with null targets and null
     "days hit goal" instead of grading the week against an invented plan.
     (It also used to 500 unconditionally — `get_weekly_nutrition_summary`
     returns a LIST, and the handler called `.get()` on it.)
  4. Static sweep: no fabricated-target default survives anywhere in the
     nutrition API surface owned by this module.

Run: backend/.venv312/bin/python -m pytest tests/test_nutrition_target_fabrication.py -v
"""
import re
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from core.auth import get_current_user
from main import app

TEST_USER_ID = "11111111-2222-3333-4444-555555555555"

BACKEND_ROOT = Path(__file__).resolve().parents[1]


# ── fixtures ────────────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def override_auth():
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "targets-test@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def client():
    return TestClient(app)


_NO_ROW = object()


class _Chain:
    """Chainable PostgREST stand-in that records what was written.

    `execute()` returns the canned value for the table. `_NO_ROW` reproduces
    `.maybe_single()`'s real behaviour of returning **None** on zero rows.
    """

    def __init__(self, table: str, canned: dict, writes: list):
        self._table = table
        self._canned = canned
        self._writes = writes

    def insert(self, payload, *a, **k):
        self._writes.append(("insert", self._table, payload))
        return self

    def update(self, payload, *a, **k):
        self._writes.append(("update", self._table, payload))
        return self

    def upsert(self, payload, *a, **k):
        self._writes.append(("upsert", self._table, payload))
        return self

    def __getattr__(self, _name):
        return lambda *a, **k: self

    def execute(self):
        value = self._canned.get(self._table, [])
        if value is _NO_ROW:
            return None
        return SimpleNamespace(data=value)


def _fake_db(canned: dict):
    writes: list = []
    db = MagicMock()
    db.client.table.side_effect = lambda name: _Chain(name, canned, writes)
    db.writes = writes
    return db


# ── 1. the write side: skipping persists no plan ────────────────────────────

TARGET_KEYS = {
    "target_calories",
    "target_protein_g",
    "target_carbs_g",
    "target_fat_g",
    "target_fiber_g",
}


def test_skip_onboarding_persists_no_targets_for_a_new_user(client):
    """A skip is "I did not choose a plan", so it must store no plan."""
    db = _fake_db({"nutrition_preferences": _NO_ROW})

    with patch("api.v1.nutrition.onboarding.get_supabase_db", return_value=db):
        response = client.post(
            "/api/v1/nutrition/onboarding/skip", json={"user_id": TEST_USER_ID}
        )

    assert response.status_code == 200, response.text
    inserts = [w for w in db.writes if w[0] == "insert" and w[1] == "nutrition_preferences"]
    assert len(inserts) == 1, db.writes
    payload = inserts[0][2]
    assert TARGET_KEYS.isdisjoint(payload), f"skip persisted targets: {payload}"
    # Nor a diet/meal-pattern choice the user never made.
    assert "diet_type" not in payload
    assert "meal_pattern" not in payload
    # It does record the fact of the skip.
    assert payload["nutrition_onboarding_completed"] is True
    assert payload["user_id"] == TEST_USER_ID


def test_skip_onboarding_does_not_touch_targets_of_an_existing_row(client):
    db = _fake_db({"nutrition_preferences": [{"id": "prefs-1"}]})

    with patch("api.v1.nutrition.onboarding.get_supabase_db", return_value=db):
        response = client.post(
            "/api/v1/nutrition/onboarding/skip", json={"user_id": TEST_USER_ID}
        )

    assert response.status_code == 200, response.text
    updates = [w for w in db.writes if w[0] == "update" and w[1] == "nutrition_preferences"]
    assert len(updates) == 1, db.writes
    assert TARGET_KEYS.isdisjoint(updates[0][2])


def test_skip_onboarding_rejects_another_users_id(client):
    """The handler had no ownership check at all."""
    db = _fake_db({"nutrition_preferences": _NO_ROW})
    with patch("api.v1.nutrition.onboarding.get_supabase_db", return_value=db):
        response = client.post(
            "/api/v1/nutrition/onboarding/skip", json={"user_id": "some-other-user"}
        )
    assert response.status_code == 403
    assert db.writes == []


# ── 2. weekly recommendation ────────────────────────────────────────────────


def _generate(client, canned):
    db = _fake_db(canned)
    with patch(
        "api.v1.nutrition.weekly_recommendations.get_supabase_db", return_value=db
    ), patch(
        "api.v1.nutrition.weekly_recommendations.resolve_timezone",
        return_value="America/Chicago",
    ):
        response = client.post(
            f"/api/v1/nutrition/recommendations/{TEST_USER_ID}/generate"
        )
    return response, db


def test_generate_refuses_instead_of_inventing_a_baseline(client):
    """No configured target + no adaptive TDEE ⇒ 409, and nothing persisted.

    The old code read `prefs.get("target_calories", 2000)` and wrote a
    "recommendation" built on that invented number; accepting it then copied
    the invention into nutrition_preferences as a real plan.
    """
    response, db = _generate(
        client,
        {
            "adaptive_nutrition_calculations": _NO_ROW,
            "nutrition_preferences": {"nutrition_goal": "maintain", "target_calories": None},
        },
    )

    assert response.status_code == 409, response.text
    assert "target" in response.json()["detail"].lower()
    assert [w for w in db.writes if w[1] == "weekly_nutrition_recommendations"] == []


def test_generate_with_no_baseline_reports_null_adjustment_not_zero(client):
    """A recommendation can stand on a real TDEE with no prior target — but the
    delta against a target that doesn't exist is null, never 0 (0 reads as
    "you're already on plan")."""
    persisted = {
        "id": "rec-1",
        "user_id": TEST_USER_ID,
        "week_start": "2026-07-27",
        "current_goal": "maintain",
        "target_rate_per_week": 0.0,
        "calculated_tdee": 2400,
        "recommended_calories": 2400,
        "recommended_protein_g": 180,
        "recommended_carbs_g": 240,
        "recommended_fat_g": 80,
        "adjustment_reason": "Based on your actual TDEE of 2400 cal.",
        "adjustment_amount": None,
        "user_accepted": False,
        "user_modified": False,
        "modified_calories": None,
    }
    response, db = _generate(
        client,
        {
            "adaptive_nutrition_calculations": {
                "calculated_tdee": 2400,
                "data_quality_score": 0.9,
            },
            "nutrition_preferences": {"nutrition_goal": "maintain"},
            "weekly_nutrition_recommendations": [persisted],
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["adjustment_amount"] is None
    assert body["recommended_calories"] == 2400
    # week_start crosses the wire as a plain date string; it used to be handed
    # to pydantic as a datetime, which is a hard ValidationError → 500.
    assert body["week_start"] == "2026-07-27"

    written = [w for w in db.writes if w[1] == "weekly_nutrition_recommendations"]
    assert written and written[0][2]["adjustment_amount"] is None
    assert written[0][2]["recommended_calories"] == 2400


# ── 3. weekly report ────────────────────────────────────────────────────────


def _weekly_report(client, *, targets: dict):
    day = {
        "total_calories": 1800,
        "total_protein_g": 120.0,
        "total_carbs_g": 180.0,
        "total_fat_g": 60.0,
        "total_fiber_g": 20.0,
        "meal_count": 3,
        "top_foods": [{"name": "Oats", "calories": 300, "protein_g": 10}],
    }
    db = _fake_db({"food_logs": [], "users": {"name": "Riley"}})
    db.get_weekly_nutrition_summary.return_value = [dict(day) for _ in range(7)]
    db.get_user_nutrition_targets.return_value = targets

    with patch(
        "api.v1.nutrition.reports.get_supabase_db", return_value=db
    ), patch(
        "api.v1.nutrition.reports.resolve_timezone", return_value="America/Chicago"
    ), patch(
        "api.v1.nutrition.reports.GeminiService", side_effect=RuntimeError("offline")
    ):
        return client.post("/api/v1/nutrition/reports/weekly?week_start=2026-07-20")


def test_weekly_report_returns_null_targets_when_none_configured(client):
    response = _weekly_report(
        client,
        targets={"daily_calorie_target": None, "daily_protein_target_g": None},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["calorie_target"] is None
    assert body["protein_target_g"] is None
    # Not 0/7 against an invented goal — the metric simply does not exist.
    assert body["days_hit_calorie_goal"] is None
    assert body["days_hit_protein_goal"] is None
    assert body["daily_calories"] == [1800] * 7
    assert "2000" not in body["ai_narrative"]


def test_weekly_report_grades_against_real_targets_when_they_exist(client):
    response = _weekly_report(
        client,
        targets={"daily_calorie_target": 1800, "daily_protein_target_g": 120},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["calorie_target"] == 1800
    assert body["days_hit_calorie_goal"] == 7
    assert body["days_hit_protein_goal"] == 7


# ── 4. static sweep over this module's surface ──────────────────────────────

_TARGET_FIELDS = "|".join([
    "target_calories", "target_protein_g", "target_carbs_g", "target_fat_g",
    "target_fiber_g", "daily_calorie_target", "daily_protein_target_g",
    "daily_carbs_target_g", "daily_fat_target_g", "calorie_target",
    "protein_target_g",
])

_FABRICATION_PATTERNS = [
    # summary.get("calorie_target", 2000)
    re.compile(rf"""\.get\(\s*["'](?:{_TARGET_FIELDS})["']\s*,\s*(\d+)"""),
    # weekly.get("calorie_target") or 2000   /   prefs["target_calories"] or 150
    re.compile(rf"""(?:{_TARGET_FIELDS})["']?\s*\)?\]?\s*or\s+(\d+)"""),
    # "target_calories": 2000   /   calorie_target: int = 2000
    re.compile(rf"""["']?(?:{_TARGET_FIELDS})["']?\s*(?::\s*(?:int|float)?\s*=|=|:)\s*(\d+)\b"""),
]

# Every file this module owns. Siblings that still fabricate targets live in
# other domains (scores_endpoints.py, users/onboarding.py,
# nutrition_calculator_service.py, holistic_plan_service.py,
# langgraph_agents/plan_agent/nodes.py, recipe_suggestion_service.py) and are
# tracked separately — widening this list is how this gate grows.
_OWNED_PATHS = [
    "api/v1/nutrition",
    "api/v1/nutrition_preferences_endpoints.py",
    "services/dish_image_service.py",
]


def _owned_python_files():
    for rel in _OWNED_PATHS:
        path = BACKEND_ROOT / rel
        if path.is_dir():
            yield from sorted(p for p in path.rglob("*.py") if "__pycache__" not in str(p))
        else:
            yield path


def test_no_fabricated_target_defaults_in_the_nutrition_api_surface():
    offenders = []
    for path in _owned_python_files():
        for lineno, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            for pattern in _FABRICATION_PATTERNS:
                match = pattern.search(line)
                # < 30 is never a calorie/macro target — it's a percentage
                # split, an index, or a version number.
                if match and int(match.group(1)) >= 30:
                    offenders.append(
                        f"{path.relative_to(BACKEND_ROOT)}:{lineno}: {stripped[:120]}"
                    )
                    break

    assert not offenders, (
        "fabricated nutrition-target default(s) reintroduced:\n  "
        + "\n  ".join(offenders)
    )
