"""
Unit tests for nutrition_context_helpers.

Mocks the Supabase DB facade so tests are deterministic and offline.
"""
import os
import sys
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.langgraph_agents.tools.nutrition_context_helpers import (  # noqa: E402
    fetch_daily_nutrition_context,
    fetch_recent_favorites,
    fetch_todays_workout,
)


# ── fetch_daily_nutrition_context ──────────────────────────────────────────

@pytest.mark.asyncio
async def test_daily_context_fresh_user(monkeypatch):
    """Fresh user: no logs, no targets → sensible null-heavy context."""
    db_mock = MagicMock()
    db_mock.get_daily_nutrition_summary.return_value = {
        "total_calories": 0,
        "total_protein_g": 0,
        "total_carbs_g": 0,
        "total_fat_g": 0,
        "total_fiber_g": 0,
        "meal_count": 0,
        "meals": [],
    }
    db_mock.get_user_nutrition_targets.return_value = {
        "daily_calorie_target": None,
        "daily_protein_target_g": None,
        "daily_carbs_target_g": None,
        "daily_fat_target_g": None,
    }
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )

    ctx = await fetch_daily_nutrition_context("u1", "America/Chicago")

    assert ctx["total_calories"] == 0
    assert ctx["calorie_remainder"] is None  # no target → None
    assert ctx["macros_remaining"]["protein_g"] is None
    assert ctx["over_budget"] is False
    assert ctx["meal_count"] == 0
    assert ctx["meal_types_logged"] == []
    assert ctx["ultra_processed_count_today"] == 0


@pytest.mark.asyncio
async def test_daily_context_typical_day(monkeypatch):
    """User with 2 logged meals, within budget."""
    db_mock = MagicMock()
    db_mock.get_daily_nutrition_summary.return_value = {
        "total_calories": 1100,
        "total_protein_g": 75,
        "total_carbs_g": 120,
        "total_fat_g": 35,
        "total_fiber_g": 18,
        "meal_count": 2,
        "meals": [
            {"meal_type": "breakfast", "is_ultra_processed": False},
            {"meal_type": "Lunch", "is_ultra_processed": True},
        ],
    }
    db_mock.get_user_nutrition_targets.return_value = {
        "daily_calorie_target": 2000,
        "daily_protein_target_g": 150,
        "daily_carbs_target_g": 200,
        "daily_fat_target_g": 70,
    }
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )

    ctx = await fetch_daily_nutrition_context("u1", "UTC")

    assert ctx["calorie_remainder"] == 900
    assert ctx["macros_remaining"] == {
        "protein_g": 75.0,
        "carbs_g": 80.0,
        "fat_g": 35.0,
    }
    assert ctx["over_budget"] is False
    assert ctx["meal_types_logged"] == ["breakfast", "lunch"]  # sorted, lowercased
    assert ctx["ultra_processed_count_today"] == 1


@pytest.mark.asyncio
async def test_daily_context_over_budget(monkeypatch):
    db_mock = MagicMock()
    db_mock.get_daily_nutrition_summary.return_value = {
        "total_calories": 2400,
        "total_protein_g": 0, "total_carbs_g": 0, "total_fat_g": 0,
        "total_fiber_g": 0, "meal_count": 3, "meals": [
            {"meal_type": "breakfast", "is_ultra_processed": False},
            {"meal_type": "lunch", "is_ultra_processed": False},
            {"meal_type": "dinner", "is_ultra_processed": False},
        ],
    }
    db_mock.get_user_nutrition_targets.return_value = {
        "daily_calorie_target": 2000,
        "daily_protein_target_g": None,
        "daily_carbs_target_g": None,
        "daily_fat_target_g": None,
    }
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )

    ctx = await fetch_daily_nutrition_context("u1", "UTC")

    assert ctx["calorie_remainder"] == -400
    assert ctx["over_budget"] is True


@pytest.mark.asyncio
async def test_daily_context_propagates_exception(monkeypatch):
    """Exception bubbles so _build_agent_state can set context_partial."""
    db_mock = MagicMock()
    db_mock.get_daily_nutrition_summary.side_effect = RuntimeError("DB down")
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )
    with pytest.raises(RuntimeError):
        await fetch_daily_nutrition_context("u1", "UTC")


# ── fetch_recent_favorites ─────────────────────────────────────────────────

def _mock_saved_foods_client(rows):
    """Build a supabase_client mock whose table().select()...execute() returns rows."""
    client = MagicMock()
    exec_mock = MagicMock()
    exec_mock.data = rows
    # Build the chain: table → select → eq → order → limit → execute
    table_mock = MagicMock()
    table_mock.select.return_value = table_mock
    table_mock.eq.return_value = table_mock
    table_mock.order.return_value = table_mock
    table_mock.limit.return_value = table_mock
    table_mock.execute.return_value = exec_mock
    client.table.return_value = table_mock
    return client


@pytest.mark.asyncio
async def test_favorites_empty(monkeypatch):
    client = _mock_saved_foods_client([])
    sb_mock = MagicMock()
    sb_mock.client = client
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase",
        lambda: sb_mock,
    )

    favs = await fetch_recent_favorites("u1", limit=5)
    assert favs == []


@pytest.mark.asyncio
async def test_favorites_basic(monkeypatch):
    now = datetime.utcnow()
    rows = [
        {
            "id": "f1", "name": "Paneer Masala Dosa",
            "total_calories": 480, "total_protein_g": 21,
            "total_carbs_g": 46, "total_fat_g": 25,
            "times_logged": 8,
            "last_logged_at": (now - timedelta(days=3)).isoformat() + "+00:00",
        },
        {
            "id": "f2", "name": "Greek Yogurt Bowl",
            "total_calories": 250, "total_protein_g": 18,
            "total_carbs_g": 28, "total_fat_g": 8,
            "times_logged": 5, "last_logged_at": None,
        },
    ]
    client = _mock_saved_foods_client(rows)
    sb_mock = MagicMock()
    sb_mock.client = client
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase",
        lambda: sb_mock,
    )

    favs = await fetch_recent_favorites("u1", limit=5)
    assert len(favs) == 2
    assert favs[0]["name"] == "Paneer Masala Dosa"
    assert favs[0]["last_logged_days_ago"] == 3
    assert favs[1]["last_logged_days_ago"] is None


@pytest.mark.asyncio
async def test_favorites_exclude_within_days(monkeypatch):
    """exclude_days=7 drops favorites logged in last 7 days."""
    now = datetime.utcnow()
    rows = [
        {
            "id": "recent", "name": "Recent Meal",
            "total_calories": 400, "total_protein_g": 20,
            "total_carbs_g": 30, "total_fat_g": 15, "times_logged": 10,
            "last_logged_at": (now - timedelta(days=2)).isoformat() + "+00:00",
        },
        {
            "id": "old", "name": "Old Favorite",
            "total_calories": 300, "total_protein_g": 15,
            "total_carbs_g": 25, "total_fat_g": 10, "times_logged": 5,
            "last_logged_at": (now - timedelta(days=14)).isoformat() + "+00:00",
        },
    ]
    client = _mock_saved_foods_client(rows)
    sb_mock = MagicMock()
    sb_mock.client = client
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase",
        lambda: sb_mock,
    )

    favs = await fetch_recent_favorites("u1", limit=5, exclude_days=7)
    names = [f["name"] for f in favs]
    assert "Old Favorite" in names
    assert "Recent Meal" not in names


# ── fetch_todays_workout ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_todays_workout_rest_day(monkeypatch):
    db_mock = MagicMock()
    db_mock.list_workouts.return_value = []
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )
    w = await fetch_todays_workout("u1", "America/Chicago")
    assert w is None


@pytest.mark.asyncio
async def test_todays_workout_scheduled(monkeypatch):
    db_mock = MagicMock()
    db_mock.list_workouts.return_value = [{
        "id": "w1", "name": "Push Day", "type": "push",
        "is_completed": False, "duration_minutes": 45,
        "scheduled_date": "2026-04-12T18:00:00+00:00",
        "exercises_json": [
            {"name": "Bench Press", "primary_muscle": "chest"},
            {"name": "Shoulder Press", "primary_muscle": "shoulders"},
            {"name": "Tricep Pushdown", "primary_muscle": "triceps"},
        ],
    }]
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )
    w = await fetch_todays_workout("u1", "UTC")
    assert w is not None
    assert w["name"] == "Push Day"
    assert w["type"] == "push"
    assert w["is_completed"] is False
    assert w["scheduled_time_local"] == "18:00"
    assert "chest" in w["primary_muscles"]
    assert w["exercise_count"] == 3


@pytest.mark.asyncio
async def test_todays_workout_completed(monkeypatch):
    db_mock = MagicMock()
    db_mock.list_workouts.return_value = [{
        "id": "w1", "name": "Pull Day", "type": "pull",
        "is_completed": True, "duration_minutes": 50,
        "scheduled_date": "2026-04-12T08:00:00+00:00",
        "exercises_json": [],
    }]
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )
    w = await fetch_todays_workout("u1", "UTC")
    assert w["is_completed"] is True


@pytest.mark.asyncio
async def test_todays_workout_propagates_exception(monkeypatch):
    db_mock = MagicMock()
    db_mock.list_workouts.side_effect = RuntimeError("DB error")
    monkeypatch.setattr(
        "services.langgraph_agents.tools.nutrition_context_helpers.get_supabase_db",
        lambda: db_mock,
    )
    with pytest.raises(RuntimeError):
        await fetch_todays_workout("u1", "UTC")
