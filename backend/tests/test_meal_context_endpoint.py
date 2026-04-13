"""
End-to-end HTTP test for GET /api/v1/chat/meal-context.

Uses httpx.AsyncClient + ASGITransport (matches conftest fixtures) with
the auth dependency overridden to a fake user. All 3 fetch helpers are
monkey-patched so the test runs offline.
"""
import os
import sys

import pytest
from httpx import ASGITransport, AsyncClient

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app  # noqa: E402
from core.auth import get_current_user  # noqa: E402
from api.v1 import chat_meal_context as mctx_mod  # noqa: E402


TEST_USER = {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "mctx@test.local",
    "auth_id": "00000000-0000-0000-0000-000000000000",
    "user_metadata": {},
}


@pytest.fixture(autouse=True)
def _override_auth():
    async def _fake():
        return TEST_USER
    app.dependency_overrides[get_current_user] = _fake
    # Clear cache between tests
    mctx_mod._CACHE.clear()
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def _patched_helpers(monkeypatch):
    """Controlled fixtures for the three helpers."""
    async def _daily(user_id, tz):
        return {
            "date": "2026-04-12",
            "timezone": tz,
            "total_calories": 1100,
            "total_protein_g": 75.0,
            "total_carbs_g": 120.0,
            "total_fat_g": 35.0,
            "total_fiber_g": 18.0,
            "target_calories": 2000,
            "target_protein_g": 150,
            "target_carbs_g": 200,
            "target_fat_g": 70,
            "calorie_remainder": 900,
            "macros_remaining": {
                "protein_g": 75.0, "carbs_g": 80.0, "fat_g": 35.0,
            },
            "meal_count": 2,
            "meal_types_logged": ["breakfast", "lunch"],
            "ultra_processed_count_today": 1,
            "over_budget": False,
        }

    async def _favs(user_id, limit=5, exclude_days=0):
        return [
            {
                "id": "f1", "name": "Paneer Masala Dosa",
                "total_calories": 480, "total_protein_g": 21,
                "total_carbs_g": 46, "total_fat_g": 25,
                "times_logged": 8, "last_logged_days_ago": 3,
            },
        ]

    async def _workout(user_id, tz):
        return {
            "id": "w1", "name": "Push Day", "type": "push",
            "is_completed": False, "duration_minutes": 45,
            "scheduled_date": "2026-04-12T18:00:00+00:00",
            "scheduled_time_local": "18:00",
            "primary_muscles": ["chest", "shoulders", "triceps"],
            "exercise_count": 3,
        }

    monkeypatch.setattr(mctx_mod, "fetch_daily_nutrition_context", _daily)
    monkeypatch.setattr(mctx_mod, "fetch_recent_favorites", _favs)
    monkeypatch.setattr(mctx_mod, "fetch_todays_workout", _workout)


@pytest.mark.asyncio
async def test_meal_context_happy_path(_patched_helpers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r = await c.get(
            "/api/v1/chat/meal-context",
            params={"meal_type": "lunch", "tz": "America/Chicago"},
            headers={"Authorization": "Bearer fake"},
        )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["calorie_remainder"] == 900
    assert body["macros_remaining"] == {"protein_g": 75.0, "carbs_g": 80.0, "fat_g": 35.0}
    assert body["meal_types_logged"] == ["breakfast", "lunch"]
    assert body["today_workout"]["name"] == "Push Day"
    assert body["today_workout"]["is_completed"] is False
    assert body["has_favorites"] is True
    assert body["favorites_preview"][0]["name"] == "Paneer Masala Dosa"
    assert body["over_budget"] is False
    assert body["context_partial"] is False
    assert body["meal_type"] == "lunch"
    assert body["timezone"] == "America/Chicago"


@pytest.mark.asyncio
async def test_meal_context_over_budget(_patched_helpers, monkeypatch):
    async def _over(user_id, tz):
        return {
            "total_calories": 2400, "target_calories": 2000,
            "total_protein_g": 0, "total_carbs_g": 0, "total_fat_g": 0, "total_fiber_g": 0,
            "macros_remaining": {"protein_g": None, "carbs_g": None, "fat_g": None},
            "calorie_remainder": -400, "over_budget": True,
            "meal_types_logged": ["breakfast", "lunch", "dinner"],
            "meal_count": 3, "ultra_processed_count_today": 0,
            "date": "2026-04-12", "timezone": tz,
        }
    monkeypatch.setattr(mctx_mod, "fetch_daily_nutrition_context", _over)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r = await c.get(
            "/api/v1/chat/meal-context",
            params={"meal_type": "snack", "tz": "UTC"},
            headers={"Authorization": "Bearer fake"},
        )
    body = r.json()
    assert r.status_code == 200
    assert body["over_budget"] is True
    assert body["calorie_remainder"] == -400


@pytest.mark.asyncio
async def test_meal_context_rest_day(_patched_helpers, monkeypatch):
    async def _no_workout(user_id, tz):
        return None
    monkeypatch.setattr(mctx_mod, "fetch_todays_workout", _no_workout)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r = await c.get(
            "/api/v1/chat/meal-context",
            params={"tz": "UTC"},
            headers={"Authorization": "Bearer fake"},
        )
    body = r.json()
    assert r.status_code == 200
    assert body["today_workout"] is None


@pytest.mark.asyncio
async def test_meal_context_partial_failure(monkeypatch):
    """One helper fails → context_partial=True, others still populate."""
    async def _daily_ok(user_id, tz):
        return {
            "total_calories": 500, "target_calories": 2000,
            "calorie_remainder": 1500, "over_budget": False,
            "macros_remaining": {"protein_g": None, "carbs_g": None, "fat_g": None},
            "meal_types_logged": [], "meal_count": 0,
            "ultra_processed_count_today": 0, "date": "2026-04-12", "timezone": tz,
        }
    async def _favs_boom(user_id, limit=5, exclude_days=0):
        raise RuntimeError("saved_foods down")
    async def _workout_ok(user_id, tz):
        return None
    monkeypatch.setattr(mctx_mod, "fetch_daily_nutrition_context", _daily_ok)
    monkeypatch.setattr(mctx_mod, "fetch_recent_favorites", _favs_boom)
    monkeypatch.setattr(mctx_mod, "fetch_todays_workout", _workout_ok)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r = await c.get(
            "/api/v1/chat/meal-context",
            params={"tz": "UTC"},
            headers={"Authorization": "Bearer fake"},
        )
    body = r.json()
    assert r.status_code == 200
    assert body["context_partial"] is True
    assert body["has_favorites"] is False
    assert body["calorie_remainder"] == 1500


@pytest.mark.asyncio
async def test_meal_context_cached(_patched_helpers):
    """Second call within 5 min should be served from cache (fast)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r1 = await c.get(
            "/api/v1/chat/meal-context",
            params={"tz": "UTC"},
            headers={"Authorization": "Bearer fake"},
        )
        r2 = await c.get(
            "/api/v1/chat/meal-context",
            params={"tz": "UTC"},
            headers={"Authorization": "Bearer fake"},
        )
    assert r1.json()["calorie_remainder"] == r2.json()["calorie_remainder"]
    # Cache hit should be dramatically faster
    assert r2.json()["computed_at_ms"] <= r1.json()["computed_at_ms"]
