"""
Tests for the Habits Tracking API endpoints.

Tests the /api/v1/habits/* endpoints for habit CRUD, logging,
streaks, summaries, templates, and AI suggestions.

Run with: pytest tests/test_habits_api.py -v

NOTE ON THE 2026-07 REWRITE
---------------------------
Every test in this file used to call an API that does not exist: paths like
``POST /api/v1/habits/`` with ``user_id`` in the body, ``PUT /habits/{habit_id}``,
``POST /habits/logs/batch``, ``GET /habits/summary``; and a habit schema of
``target_value`` / ``target_unit`` / ``specific_days`` / log ``status``.

The real contract (``api/v1/habits.py`` + ``api/v1/habits_endpoints.py``,
``models/habits.py``) is user-scoped in the PATH and uses
``target_count`` / ``unit`` / ``target_days`` and boolean ``completed`` /
``skipped`` on logs. Every endpoint is also behind ``Depends(get_current_user)``
plus ``verify_user_ownership``, which nothing here overrode — hence the
``assert 401 == 200`` avalanche.

So: the tests were calling the code wrong, not asserting retired behavior. Each
one below keeps its original INTENT (and, where the old assertion was only
``status_code in [200, 201]``, asserts more than it used to) but calls the real
routes with the real payloads. Where a field simply has a different name in the
product (``target_value`` → ``target_count``), the assertion was carried over to
the real field. Where a field never existed in the product at all
(``habits.template_id``), the docstring explains what guarantee replaced it.
"""

import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from collections import defaultdict
from datetime import datetime, date, timedelta, timezone
from uuid import uuid4
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from core.auth import get_current_user
from core.timezone_utils import get_user_today


# ============================================================================
# Helpers
# ============================================================================

def api_today() -> date:
    """Today as the *endpoints* compute it.

    The habit endpoints resolve the user's timezone and then call
    ``get_user_today(tz)``. Our mock DB reports the user's timezone as UTC, so
    server-local ``date.today()`` can be a day off (e.g. 23:00 CDT = tomorrow in
    UTC), which would flip the "no future dates" check. Compute the same value
    the endpoint does.
    """
    return date.fromisoformat(get_user_today("UTC"))


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _make_table_mock() -> MagicMock:
    """A chainable stand-in for supabase-py's query builder."""
    table = MagicMock()
    for method in (
        "select", "insert", "update", "delete", "upsert", "eq", "neq", "gte",
        "lte", "lt", "gt", "order", "limit", "is_", "in_", "single",
        "maybe_single", "ilike", "like", "range", "not_",
    ):
        getattr(table, method).return_value = table
    table.execute.return_value = MagicMock(data=[])
    return table


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def test_user_id():
    """Sample user ID for testing."""
    return str(uuid4())


@pytest.fixture
def other_user_id():
    """Another user ID for authorization tests."""
    return str(uuid4())


@pytest.fixture
def client(test_user_id):
    """Test client authenticated as ``test_user_id``.

    Every habits route depends on ``get_current_user`` and then calls
    ``verify_user_ownership(current_user, user_id)``. Overriding the dependency
    is what makes the endpoints reachable; ownership is still enforced against
    the ``user_id`` in the path (see test_habit_unauthorized_access).
    """
    app.dependency_overrides[get_current_user] = lambda: {"id": test_user_id}
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with a chainable, per-table Supabase client.

    ``db.client.table(name)`` returns a distinct mock per table name, so a test
    can stage rows per table (``mock_db.tables["habit_logs"]``) instead of
    relying on brittle call-ordering with ``side_effect`` lists.

    Activity logging is stubbed too: ``log_user_activity`` / ``log_user_error``
    write to Supabase for real and are pure telemetry — they are not the thing
    under test here.
    """
    tables = defaultdict(_make_table_mock)

    mock_db = MagicMock()
    mock_db.client.table.side_effect = lambda name: tables[name]
    # resolve_timezone() reads this; pin it so `today` is deterministic.
    mock_db.get_user.return_value = {"timezone": "UTC"}
    mock_db.tables = tables

    def set_data(table_name, data):
        tables[table_name].execute.return_value = MagicMock(data=data)

    mock_db.set_data = set_data

    with patch("api.v1.habits.get_supabase_db", return_value=mock_db), \
         patch("api.v1.habits_endpoints.get_supabase_db", return_value=mock_db), \
         patch("api.v1.habits.log_user_activity", new=AsyncMock()), \
         patch("api.v1.habits.log_user_error", new=AsyncMock()), \
         patch("api.v1.habits_endpoints.log_user_error", new=AsyncMock()):
        yield mock_db


@pytest.fixture
def sample_habit(test_user_id):
    """Sample habit row, shaped like the real `habits` table / `Habit` model."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "name": "Drink Water",
        "description": "Drink 8 glasses of water daily",
        "category": "health",
        "habit_type": "positive",
        "frequency": "daily",
        "target_days": None,
        "target_count": 8,
        "unit": "glasses",
        "icon": "water_drop",
        "color": "#2196F3",
        "reminder_time": "09:00:00",
        "reminder_enabled": True,
        "is_active": True,
        "is_suggested": False,
        "created_at": _now_iso(),
        "updated_at": _now_iso(),
    }


@pytest.fixture
def sample_negative_habit(test_user_id):
    """Sample negative habit (avoid something)."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "name": "No Social Media Before Noon",
        "description": "Avoid social media until after 12pm",
        "category": "lifestyle",
        "habit_type": "negative",
        "frequency": "daily",
        "target_days": None,
        "target_count": 1,
        "unit": None,
        "icon": "phone_disabled",
        "color": "#F44336",
        "reminder_time": None,
        "reminder_enabled": False,
        "is_active": True,
        "is_suggested": False,
        "created_at": _now_iso(),
        "updated_at": _now_iso(),
    }


@pytest.fixture
def sample_specific_days_habit(test_user_id):
    """Sample habit with specific_days frequency (target_days: 0=Sun … 6=Sat)."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "name": "Gym Session",
        "description": "Complete a gym workout",
        "category": "activity",
        "habit_type": "positive",
        "frequency": "specific_days",
        "target_days": [1, 3, 5],  # Monday, Wednesday, Friday
        "target_count": 1,
        "unit": "sessions",
        "icon": "fitness_center",
        "color": "#4CAF50",
        "reminder_time": None,
        "reminder_enabled": False,
        "is_active": True,
        "is_suggested": False,
        "created_at": _now_iso(),
        "updated_at": _now_iso(),
    }


@pytest.fixture
def sample_habit_log(test_user_id, sample_habit):
    """Sample habit log row, shaped like the real `habit_logs` table."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "habit_id": sample_habit["id"],
        "log_date": api_today().isoformat(),
        "completed": True,
        "value": 8,
        "notes": "Hit my water goal!",
        "skipped": False,
        "skip_reason": None,
        "completed_at": _now_iso(),
        "created_at": _now_iso(),
    }


@pytest.fixture
def sample_habit_template():
    """Sample habit template row, shaped like the real `habit_templates` table."""
    return {
        "id": str(uuid4()),
        "name": "Stay Hydrated",
        "description": "Track daily water intake",
        "category": "health",
        "habit_type": "positive",
        "suggested_target": 8,
        "unit": "glasses",
        "icon": "water_drop",
        "color": "#2196F3",
        "is_active": True,
        "sort_order": 1,
    }


@pytest.fixture
def sample_streak(test_user_id, sample_habit):
    """Sample `habit_streaks` row (streaks live in their own table, maintained
    by the DB trigger in migration 128 — not on the habit row)."""
    return {
        "id": str(uuid4()),
        "habit_id": sample_habit["id"],
        "user_id": test_user_id,
        "current_streak": 5,
        "longest_streak": 10,
        "last_completed_date": api_today().isoformat(),
        "streak_start_date": (api_today() - timedelta(days=4)).isoformat(),
        "updated_at": _now_iso(),
    }


def today_view_row(habit: dict, completed: bool = False, value=None,
                   current_streak: int = 0, longest_streak: int = 0) -> dict:
    """Build a `today_habits_view` row from a habit row (the view renames
    id → habit_id and created_at → habit_created_at)."""
    row = {k: v for k, v in habit.items() if k not in ("id", "created_at", "updated_at")}
    row["habit_id"] = habit["id"]
    row["habit_created_at"] = habit["created_at"]
    row["completed"] = completed
    row["value"] = value
    row["current_streak"] = current_streak
    row["longest_streak"] = longest_streak
    return row


# ============================================================================
# Habit CRUD Tests
# ============================================================================

class TestHabitsAPI:
    """Tests for the Habits API endpoints."""

    # ============ HABIT CRUD ============

    def test_create_habit_success(self, client, mock_supabase_db, test_user_id):
        """Test creating a new habit."""
        habit_id = str(uuid4())
        created_habit = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "Morning Meditation",
            "description": "Meditate for 10 minutes every morning",
            "category": "lifestyle",
            "habit_type": "positive",
            "frequency": "daily",
            "target_days": None,
            "target_count": 10,
            "unit": "minutes",
            "icon": "self_improvement",
            "color": "#9C27B0",
            "reminder_time": None,
            "reminder_enabled": False,
            "is_active": True,
            "is_suggested": False,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
        }
        mock_supabase_db.set_data("habits", [created_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "name": "Morning Meditation",
                "description": "Meditate for 10 minutes every morning",
                "category": "lifestyle",
                "habit_type": "positive",
                "frequency": "daily",
                "target_count": 10,
                "unit": "minutes",
                "icon": "self_improvement",
                "color": "#9C27B0",
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["name"] == "Morning Meditation"
        assert data["habit_type"] == "positive"
        # `target_value` in the old test; the product field is `target_count`.
        assert data["target_count"] == 10

        # The row actually written carries the caller's values.
        insert_payload = mock_supabase_db.tables["habits"].insert.call_args[0][0]
        assert insert_payload["user_id"] == test_user_id
        assert insert_payload["name"] == "Morning Meditation"
        assert insert_payload["target_count"] == 10
        assert insert_payload["is_active"] is True

    def test_create_habit_with_all_fields(self, client, mock_supabase_db, test_user_id):
        """Test creating habit with all optional fields."""
        created_habit = {
            "id": str(uuid4()),
            "user_id": test_user_id,
            "name": "Evening Reading",
            "description": "Read for 30 minutes before bed",
            "category": "lifestyle",
            "habit_type": "positive",
            "frequency": "daily",
            "target_days": None,
            "target_count": 30,
            "unit": "minutes",
            "icon": "menu_book",
            "color": "#FF9800",
            "reminder_time": "21:00:00",
            "reminder_enabled": True,
            "is_active": True,
            "is_suggested": False,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
        }
        mock_supabase_db.set_data("habits", [created_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "name": "Evening Reading",
                "description": "Read for 30 minutes before bed",
                "category": "lifestyle",
                "habit_type": "positive",
                "frequency": "daily",
                "target_count": 30,
                "unit": "minutes",
                "icon": "menu_book",
                "color": "#FF9800",
                "reminder_time": "21:00",
                "reminder_enabled": True,
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["reminder_enabled"] is True
        assert data["reminder_time"] == "21:00:00"
        # Old test asserted `category == "personal_growth"`; `category` is a
        # closed enum (HabitCategory) in the product — "lifestyle" is its slot
        # for personal-growth habits. Intent (category round-trips) preserved.
        assert data["category"] == "lifestyle"

        insert_payload = mock_supabase_db.tables["habits"].insert.call_args[0][0]
        assert insert_payload["reminder_time"] == "21:00:00"
        assert insert_payload["reminder_enabled"] is True

    def test_create_negative_habit(self, client, mock_supabase_db, test_user_id):
        """Test creating a 'negative' habit (avoid something)."""
        created_habit = {
            "id": str(uuid4()),
            "user_id": test_user_id,
            "name": "No Late Night Snacking",
            "description": "Avoid eating after 8pm",
            "category": "nutrition",
            "habit_type": "negative",
            "frequency": "daily",
            "target_days": None,
            "target_count": 1,
            "unit": None,
            "icon": "no_food",
            "color": "#F44336",
            "reminder_time": None,
            "reminder_enabled": False,
            "is_active": True,
            "is_suggested": False,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
        }
        mock_supabase_db.set_data("habits", [created_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "name": "No Late Night Snacking",
                "description": "Avoid eating after 8pm",
                "category": "nutrition",
                "habit_type": "negative",
                "frequency": "daily",
                "icon": "no_food",
                "color": "#F44336",
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["habit_type"] == "negative"
        # An avoid-this habit has no quantity: no unit, and the default
        # target_count of 1 ("did it / didn't"). Old test asserted the
        # equivalent on the never-shipped `target_value` field.
        assert data["unit"] is None
        assert data["target_count"] == 1

    def test_create_habit_specific_days(self, client, mock_supabase_db, test_user_id):
        """Test creating habit with specific days frequency."""
        created_habit = {
            "id": str(uuid4()),
            "user_id": test_user_id,
            "name": "Gym Workout",
            "description": "Complete a gym session",
            "category": "activity",
            "habit_type": "positive",
            "frequency": "specific_days",
            "target_days": [1, 3, 5],  # Mon, Wed, Fri
            "target_count": 1,
            "unit": "sessions",
            "icon": "fitness_center",
            "color": "#4CAF50",
            "reminder_time": None,
            "reminder_enabled": False,
            "is_active": True,
            "is_suggested": False,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
        }
        mock_supabase_db.set_data("habits", [created_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "name": "Gym Workout",
                "description": "Complete a gym session",
                "category": "activity",
                "habit_type": "positive",
                "frequency": "specific_days",
                "target_days": [1, 3, 5],
                "target_count": 1,
                "unit": "sessions",
                "icon": "fitness_center",
                "color": "#4CAF50",
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["frequency"] == "specific_days"
        # `specific_days` in the old test; the product field is `target_days`.
        assert data["target_days"] == [1, 3, 5]

    def test_get_habits_empty(self, client, mock_supabase_db, test_user_id):
        """Test getting habits when none exist."""
        mock_supabase_db.set_data("habits", [])

        response = client.get(f"/api/v1/habits/{test_user_id}")

        assert response.status_code == 200
        assert response.json() == []

    def test_get_habits_filters_inactive(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that inactive habits are filtered by default."""
        mock_supabase_db.set_data("habits", [sample_habit])

        response = client.get(f"/api/v1/habits/{test_user_id}")

        assert response.status_code == 200
        habits = response.json()
        assert all(h["is_active"] for h in habits)
        # The filter is applied server-side, not just trusted from the fixture.
        eq_calls = mock_supabase_db.tables["habits"].eq.call_args_list
        assert ("is_active", True) in [c.args for c in eq_calls]

    def test_get_today_habits_with_status(self, client, mock_supabase_db, test_user_id,
                                          sample_habit, sample_habit_log):
        """Test getting today's habits with completion status."""
        mock_supabase_db.set_data(
            "today_habits_view",
            [today_view_row(sample_habit, completed=True, value=8,
                            current_streak=5, longest_streak=10)],
        )
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        response = client.get(f"/api/v1/habits/{test_user_id}/today")

        assert response.status_code == 200
        data = response.json()
        habits = data["habits"]
        assert len(habits) == 1
        # Old test asserted a `today_status` string; the product exposes the
        # boolean `today_completed` (+ today_value) on HabitWithStatus.
        assert habits[0]["today_completed"] is True
        assert habits[0]["today_value"] == 8
        assert data["total_habits"] == 1
        assert data["completed_today"] == 1
        assert data["completion_percentage"] == 100.0

    def test_update_habit(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test updating an existing habit."""
        updated_habit = {**sample_habit, "name": "Drink More Water", "target_count": 10}
        mock_supabase_db.set_data("habits", [updated_habit])

        response = client.put(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}",
            json={"name": "Drink More Water", "target_count": 10},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Drink More Water"
        assert data["target_count"] == 10

        update_payload = mock_supabase_db.tables["habits"].update.call_args[0][0]
        assert update_payload == {"name": "Drink More Water", "target_count": 10}

    def test_delete_habit_soft_delete(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that delete is a soft delete (sets is_active=False)."""
        mock_supabase_db.set_data("habits", [sample_habit])

        response = client.delete(f"/api/v1/habits/{test_user_id}/{sample_habit['id']}")

        assert response.status_code == 200
        # Verify update was called, not delete
        mock_supabase_db.tables["habits"].update.assert_called_once_with({"is_active": False})
        mock_supabase_db.tables["habits"].delete.assert_not_called()

    def test_archive_habit(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test archiving a habit.

        The old test asserted an `is_archived` flag / `success: true` body.
        Archiving is a soft delete in the product (there is no `is_archived`
        column — migration 128 archives by clearing `is_active`), and the
        endpoint reports it in its message. Same guarantee: POST .../archive
        deactivates the habit and confirms it.
        """
        mock_supabase_db.set_data("habits", [sample_habit])

        response = client.post(f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/archive")

        assert response.status_code == 200
        assert "archived" in response.json()["message"]
        mock_supabase_db.tables["habits"].update.assert_called_once_with({"is_active": False})
        mock_supabase_db.tables["habits"].delete.assert_not_called()

    # ============ HABIT LOGS ============

    def test_log_habit_completion(self, client, mock_supabase_db, test_user_id,
                                  sample_habit, sample_habit_log):
        """Test logging a habit as completed."""
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": True,
                "value": 8,
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        # Logs carry booleans (`completed` / `skipped`), not a `status` string.
        assert data["completed"] is True
        assert data["value"] == 8

    def test_log_habit_with_value(self, client, mock_supabase_db, test_user_id, sample_habit,
                                  sample_habit_log):
        """Test logging a quantitative habit with value."""
        log_row = {**sample_habit_log, "value": 6, "notes": "Managed 6 glasses today"}
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [log_row])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": True,
                "value": 6,
                "notes": "Managed 6 glasses today",
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["value"] == 6
        assert data["notes"] == "Managed 6 glasses today"

    def test_log_habit_skip(self, client, mock_supabase_db, test_user_id, sample_habit,
                            sample_habit_log):
        """Test skipping a habit with reason."""
        log_row = {
            **sample_habit_log,
            "completed": False,
            "completed_at": None,
            "value": None,
            "notes": None,
            "skipped": True,
            "skip_reason": "Feeling unwell",
        }
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [log_row])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": False,
                "skipped": True,
                "skip_reason": "Feeling unwell",
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["skipped"] is True
        assert data["completed"] is False
        assert data["skip_reason"] == "Feeling unwell"

        # A skip must not be written as a completion (that would fake a streak).
        upsert_payload = mock_supabase_db.tables["habit_logs"].upsert.call_args[0][0]
        assert upsert_payload["skipped"] is True
        assert upsert_payload["completed"] is False
        assert upsert_payload["completed_at"] is None

    def test_update_habit_log(self, client, mock_supabase_db, test_user_id, sample_habit_log):
        """Test updating an existing habit log."""
        updated_log = {**sample_habit_log, "value": 10, "notes": "Actually drank 10 glasses!"}
        mock_supabase_db.set_data("habit_logs", [updated_log])

        response = client.put(
            f"/api/v1/habits/{test_user_id}/log/{sample_habit_log['id']}",
            json={"value": 10, "notes": "Actually drank 10 glasses!"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["value"] == 10
        assert data["notes"] == "Actually drank 10 glasses!"

    def test_get_habit_logs_date_range(self, client, mock_supabase_db, test_user_id,
                                       sample_habit, sample_habit_log):
        """Test getting habit logs for a date range."""
        today = api_today()
        logs = [
            {
                **sample_habit_log,
                "id": str(uuid4()),
                "log_date": (today - timedelta(days=i)).isoformat(),
            }
            for i in range(7)
        ]
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", logs)

        start_date = (today - timedelta(days=6)).isoformat()
        end_date = today.isoformat()

        response = client.get(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/logs"
            f"?start_date={start_date}&end_date={end_date}"
        )

        assert response.status_code == 200
        assert len(response.json()) == 7
        # The requested window is what's queried.
        log_table = mock_supabase_db.tables["habit_logs"]
        log_table.gte.assert_called_once_with("log_date", start_date)
        log_table.lte.assert_called_once_with("log_date", end_date)

    def test_batch_log_habits(self, client, mock_supabase_db, test_user_id,
                              sample_habit, sample_negative_habit, sample_habit_log):
        """Test logging multiple habits at once.

        REGRESSION GUARD (real bug, fixed 2026-07): batch-log called the
        `log_habit` route handler directly, so `current_user` stayed an
        unresolved `Depends` marker and every single log failed with
        "'Depends' object is not subscriptable" — while the endpoint still
        answered 200 with created_count=0. Silent data loss. Hence the
        assertion on created_count/failed_count, not just the status code.
        """
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/batch-log",
            json={
                "logs": [
                    {
                        "habit_id": sample_habit["id"],
                        "log_date": api_today().isoformat(),
                        "completed": True,
                        "value": 8,
                    },
                    {
                        "habit_id": sample_negative_habit["id"],
                        "log_date": api_today().isoformat(),
                        "completed": True,
                    },
                ]
            },
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["created_count"] == 2
        assert data["failed_count"] == 0
        assert len(data["results"]) == 2
        assert all(r["status"] == "success" for r in data["results"])

    def test_log_habit_updates_streak(self, client, mock_supabase_db, test_user_id,
                                      sample_habit, sample_habit_log, sample_streak):
        """Test that logging updates the streak correctly.

        Streaks are maintained by the `update_habit_streak` DB trigger on
        `habit_logs` (migration 128), so what the API must guarantee is: a
        completed log is written as completed, and the streak endpoint then
        serves the incremented streak. Both halves are asserted here (the old
        test only asserted the POST's status code).
        """
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": True,
            },
        )
        assert response.status_code in [200, 201]

        upsert_payload = mock_supabase_db.tables["habit_logs"].upsert.call_args[0][0]
        assert upsert_payload["completed"] is True
        assert upsert_payload["completed_at"] is not None

        # Streak (post-trigger) is served from habit_streaks: 5 → 6.
        mock_supabase_db.set_data("habit_streaks", [{**sample_streak, "current_streak": 6}])
        streak_response = client.get(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/streak"
        )
        assert streak_response.status_code == 200
        assert streak_response.json()["current_streak"] == 6

    # ============ STREAKS ============

    def test_streak_increments_on_consecutive_days(self, client, mock_supabase_db, test_user_id,
                                                   sample_habit, sample_habit_log, sample_streak):
        """Test streak increases with consecutive completions."""
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": True,
            },
        )
        assert response.status_code in [200, 201]

        # Yesterday was completed too → trigger advances the streak 5 → 6 and
        # the streak endpoint must surface that, with the start date unchanged.
        mock_supabase_db.set_data("habit_streaks", [{
            **sample_streak,
            "current_streak": 6,
            "last_completed_date": api_today().isoformat(),
        }])

        streak = client.get(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/streak"
        ).json()
        assert streak["current_streak"] == 6
        assert streak["last_completed_date"] == api_today().isoformat()

    def test_streak_resets_on_missed_day(self, client, mock_supabase_db, test_user_id,
                                         sample_habit, sample_habit_log, sample_streak):
        """Test streak resets when a day is missed."""
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": True,
            },
        )
        assert response.status_code in [200, 201]

        # A gap yesterday → the trigger restarts the streak at 1 today, but the
        # all-time longest is untouched.
        mock_supabase_db.set_data("habit_streaks", [{
            **sample_streak,
            "current_streak": 1,
            "streak_start_date": api_today().isoformat(),
        }])

        streak = client.get(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/streak"
        ).json()
        assert streak["current_streak"] == 1
        assert streak["longest_streak"] == 10
        assert streak["streak_start_date"] == api_today().isoformat()

    def test_longest_streak_preserved(self, client, mock_supabase_db, test_user_id,
                                      sample_habit, sample_streak):
        """Test that longest streak is never decreased."""
        mock_supabase_db.set_data("habit_streaks", [{
            **sample_streak, "current_streak": 6, "longest_streak": 10,
        }])

        response = client.get(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/streak"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["longest_streak"] == 10
        assert data["longest_streak"] >= data["current_streak"]

    def test_get_all_streaks(self, client, mock_supabase_db, test_user_id,
                             sample_habit, sample_negative_habit, sample_streak):
        """Test getting streaks for all habits."""
        streaks = [
            {**sample_streak, "current_streak": 5, "longest_streak": 10},
            {
                **sample_streak,
                "id": str(uuid4()),
                "habit_id": sample_negative_habit["id"],
                "current_streak": 3,
                "longest_streak": 7,
            },
        ]
        mock_supabase_db.set_data("habit_streaks", streaks)

        response = client.get(f"/api/v1/habits/{test_user_id}/streaks")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert all("current_streak" in s for s in data)
        assert [s["current_streak"] for s in data] == [5, 3]

    def test_get_habit_streak(self, client, mock_supabase_db, test_user_id,
                              sample_habit, sample_streak):
        """Test getting streak for a specific habit."""
        mock_supabase_db.set_data("habit_streaks", [sample_streak])

        response = client.get(
            f"/api/v1/habits/{test_user_id}/{sample_habit['id']}/streak"
        )

        assert response.status_code == 200
        data = response.json()
        assert "current_streak" in data
        assert data["current_streak"] == 5
        assert data["longest_streak"] == 10

    # ============ SUMMARIES ============

    def test_get_habits_summary(self, client, mock_supabase_db, test_user_id,
                                sample_habit, sample_habit_log, sample_streak):
        """Test getting overall habits summary.

        REGRESSION GUARD (real bug, fixed 2026-07): the summary endpoint read
        `habit.get("completion_rate_7d")` off `TodayHabitsResponse.habits`,
        which Pydantic had already coerced into `HabitWithStatus` models — so it
        raised AttributeError and 500'd for every user with at least one habit.

        Field names: the old test asserted `total_habits` /
        `completion_rate_this_week`; HabitsSummary exposes `total_active_habits`
        / `completion_rate_today` (+ streak stats). Same intent — the dashboard
        summary reports how many habits exist, how many are done, and the rate.
        """
        mock_supabase_db.set_data(
            "today_habits_view",
            [today_view_row(sample_habit, completed=True, value=8,
                            current_streak=5, longest_streak=10)],
        )
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])
        mock_supabase_db.set_data("habit_streaks", [sample_streak])

        response = client.get(f"/api/v1/habits/{test_user_id}/summary")

        assert response.status_code == 200
        data = response.json()
        assert data["total_active_habits"] == 1
        assert data["completed_today"] == 1
        assert data["completion_rate_today"] == 100.0
        assert data["longest_current_streak"] == 5
        assert data["best_habit_name"] == sample_habit["name"]

    def test_get_weekly_summary(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test getting weekly summary."""
        mock_supabase_db.set_data("habit_weekly_summary_view", [{
            "habit_id": sample_habit["id"],
            "user_id": test_user_id,
            "name": sample_habit["name"],
            "days_completed": 4,
            "completion_rate": 80.0,
            "current_streak": 5,
        }])

        response = client.get(f"/api/v1/habits/{test_user_id}/weekly-summary")

        assert response.status_code == 200
        data = response.json()
        # Per-habit weekly rows (the old test expected one aggregate object).
        assert len(data) == 1
        assert data[0]["completion_rate"] == 80.0
        assert data[0]["days_completed"] == 4
        assert data[0]["habit_name"] == sample_habit["name"]
        assert data[0]["week_start"] == (api_today() - timedelta(days=6)).isoformat()

    def test_get_habits_calendar(self, client, mock_supabase_db, test_user_id,
                                 sample_habit, sample_streak):
        """Test getting calendar view data."""
        today = api_today()
        start_date = today - timedelta(days=29)
        logs = [
            {
                "id": str(uuid4()),
                "habit_id": sample_habit["id"],
                "user_id": test_user_id,
                "log_date": (today - timedelta(days=i)).isoformat(),
                "completed": i % 2 == 0,
                "skipped": False,
                "value": 8 if i % 2 == 0 else None,
            }
            for i in range(30)
        ]
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", logs)
        mock_supabase_db.set_data("habit_streaks", [sample_streak])

        response = client.get(
            f"/api/v1/habits/{test_user_id}/calendar"
            f"?habit_id={sample_habit['id']}"
            f"&start_date={start_date.isoformat()}&end_date={today.isoformat()}"
        )

        assert response.status_code == 200
        data = response.json()
        # 30 inclusive days, one cell each.
        assert len(data["data"]) == 30
        assert data["habit_name"] == sample_habit["name"]
        by_date = {c["date"]: c["status"] for c in data["data"]}
        assert by_date[today.isoformat()] == "completed"
        assert by_date[(today - timedelta(days=1)).isoformat()] == "missed"
        assert data["streak_info"]["current_streak"] == 5

    # ============ TEMPLATES ============

    def test_get_habit_templates(self, client, mock_supabase_db, sample_habit_template):
        """Test getting all habit templates."""
        templates = [
            sample_habit_template,
            {
                "id": str(uuid4()),
                "name": "Daily Exercise",
                "description": "Exercise for 30 minutes",
                "category": "activity",
                "habit_type": "positive",
                "suggested_target": 30,
                "unit": "minutes",
                "icon": "fitness_center",
                "color": "#4CAF50",
                "is_active": True,
                "sort_order": 2,
            },
        ]
        mock_supabase_db.set_data("habit_templates", templates)

        response = client.get("/api/v1/habits/templates/all")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert {t["name"] for t in data} == {"Stay Hydrated", "Daily Exercise"}

    def test_get_templates_by_category(self, client, mock_supabase_db, sample_habit_template):
        """Test filtering templates by category."""
        mock_supabase_db.set_data("habit_templates", [sample_habit_template])

        response = client.get("/api/v1/habits/templates/all?category=health")

        assert response.status_code == 200
        data = response.json()
        assert data
        assert all(t["category"] == "health" for t in data)
        # Filtering happens in the query, not in the fixture.
        eq_calls = [c.args for c in mock_supabase_db.tables["habit_templates"].eq.call_args_list]
        assert ("category", "health") in eq_calls

    def test_create_habit_from_template(self, client, mock_supabase_db, test_user_id,
                                        sample_habit_template):
        """Test creating a habit from a template.

        REGRESSION GUARD (real bug, fixed 2026-07): this endpoint called the
        `create_habit` route handler directly and left `current_user` as an
        unresolved `Depends` marker, so it 500'd on every call.

        The old test also asserted `habit["template_id"] == template.id`; habits
        have no `template_id` column (migration 128) — a template is a stencil,
        not a foreign key. The provenance guarantee is asserted instead on the
        row actually inserted: name/category/target/unit come from the template.
        """
        created_habit = {
            "id": str(uuid4()),
            "user_id": test_user_id,
            "name": sample_habit_template["name"],
            "description": sample_habit_template["description"],
            "category": sample_habit_template["category"],
            "habit_type": sample_habit_template["habit_type"],
            "frequency": "daily",
            "target_days": None,
            "target_count": sample_habit_template["suggested_target"],
            "unit": sample_habit_template["unit"],
            "icon": sample_habit_template["icon"],
            "color": sample_habit_template["color"],
            "reminder_time": None,
            "reminder_enabled": False,
            "is_active": True,
            "is_suggested": False,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
        }
        mock_supabase_db.set_data("habit_templates", [sample_habit_template])
        mock_supabase_db.set_data("habits", [created_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/from-template"
            f"?template_id={sample_habit_template['id']}"
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["name"] == sample_habit_template["name"]

        insert_payload = mock_supabase_db.tables["habits"].insert.call_args[0][0]
        assert insert_payload["user_id"] == test_user_id
        assert insert_payload["name"] == sample_habit_template["name"]
        assert insert_payload["category"] == sample_habit_template["category"]
        assert insert_payload["target_count"] == sample_habit_template["suggested_target"]
        assert insert_payload["unit"] == sample_habit_template["unit"]

    # ============ AI SUGGESTIONS ============

    def test_get_ai_suggestions(self, client, mock_supabase_db, test_user_id,
                                sample_habit_template):
        """Test getting AI-powered habit suggestions.

        Suggestions are a POST (the request carries the user's goals) and return
        `HabitSuggestionResponse{suggested_habits, reasoning}`. The old test
        expected a per-item `reason` key; the product explains the whole set once
        in `reasoning`, so that is what's asserted.
        """
        suggested = [
            {
                **sample_habit_template,
                "id": str(uuid4()),
                "name": "Morning Stretch",
                "description": "Start your day with 5 minutes of stretching",
                "category": "activity",
            },
            {
                **sample_habit_template,
                "id": str(uuid4()),
                "name": "Protein Intake",
                "description": "Track daily protein consumption",
                "category": "nutrition",
            },
        ]
        mock_supabase_db.set_data("users", [{
            "fitness_level": "intermediate",
            "goals": ["build muscle"],
            "preferences": {"workout_days_per_week": 4},
        }])
        mock_supabase_db.set_data("habits", [])

        with patch(
            "services.habit_suggestion_service.HabitSuggestionService."
            "get_personalized_suggestions",
            new=AsyncMock(return_value=suggested),
        ):
            response = client.post(
                f"/api/v1/habits/{test_user_id}/suggestions",
                json={"goals": ["build muscle", "improve mobility"]},
            )

        assert response.status_code == 200
        data = response.json()
        assert len(data["suggested_habits"]) == 2
        assert [h["name"] for h in data["suggested_habits"]] == [
            "Morning Stretch", "Protein Intake",
        ]
        assert data["reasoning"]

    def test_get_habit_insights(self, client, mock_supabase_db, test_user_id,
                                sample_habit, sample_habit_log, sample_streak):
        """Test getting AI-generated habit insights.

        REGRESSION GUARD (real bug, fixed 2026-07): insights called
        `get_habits_summary(user_id)` / `get_weekly_summary(user_id)` — both
        route handlers that require `request` — so it raised TypeError and 500'd
        on every single call.

        Field names: the product returns HabitInsights{summary,
        best_performing_habits, needs_improvement, suggestions, streak_analysis}
        rather than the old test's `analysis` / `improvement_tips`. Same intent:
        a human-readable read on performance plus actionable tips.
        """
        mock_supabase_db.set_data(
            "today_habits_view",
            [today_view_row(sample_habit, completed=True, value=8,
                            current_streak=5, longest_streak=10)],
        )
        mock_supabase_db.set_data("habit_logs", [sample_habit_log])
        mock_supabase_db.set_data("habit_streaks", [sample_streak])
        mock_supabase_db.set_data("habit_weekly_summary_view", [{
            "habit_id": sample_habit["id"],
            "user_id": test_user_id,
            "name": sample_habit["name"],
            "days_completed": 6,
            "completion_rate": 85.0,
            "current_streak": 5,
        }])

        response = client.get(f"/api/v1/habits/{test_user_id}/insights")

        assert response.status_code == 200
        data = response.json()
        assert data["summary"]
        assert data["streak_analysis"]
        assert isinstance(data["suggestions"], list)
        # 85% completion ⇒ this habit is called out as best-performing.
        assert data["best_performing_habits"] == [sample_habit["name"]]
        assert data["needs_improvement"] == []

    # ============ EDGE CASES ============

    def test_habit_unauthorized_access(self, client, mock_supabase_db, test_user_id,
                                       other_user_id, sample_habit):
        """Test that users can't access other users' habits.

        The old test allowed 200-with-empty-body. The product is stricter than
        that: every route runs `verify_user_ownership(current_user, user_id)`
        and hard-403s an IDOR attempt before any query runs. Asserting the 403
        (and that nothing was read from `habits`) is the guarantee worth having.
        """
        mock_supabase_db.set_data("habits", [sample_habit])

        response = client.get(f"/api/v1/habits/{other_user_id}")

        assert response.status_code == 403
        mock_supabase_db.tables["habits"].execute.assert_not_called()

    def test_log_future_date_rejected(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that logging for future dates is rejected."""
        future_date = (api_today() + timedelta(days=5)).isoformat()
        mock_supabase_db.set_data("habits", [sample_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": future_date,
                "completed": True,
            },
        )

        assert response.status_code in [400, 422]
        # And nothing was written.
        mock_supabase_db.tables["habit_logs"].upsert.assert_not_called()

    def test_duplicate_log_same_date_upsert(self, client, mock_supabase_db, test_user_id,
                                            sample_habit, sample_habit_log):
        """Test that logging same habit same date updates existing."""
        mock_supabase_db.set_data("habits", [sample_habit])
        mock_supabase_db.set_data("habit_logs", [{**sample_habit_log, "value": 8}])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": sample_habit["id"],
                "log_date": api_today().isoformat(),
                "completed": True,
                "value": 8,
            },
        )

        assert response.status_code in [200, 201]
        assert response.json()["value"] == 8
        # De-dupe is delegated to the (habit_id, log_date) unique index — the
        # second log of the day must UPSERT on that conflict, never plain insert.
        log_table = mock_supabase_db.tables["habit_logs"]
        log_table.insert.assert_not_called()
        assert log_table.upsert.call_args.kwargs["on_conflict"] == "habit_id,log_date"

    def test_specific_days_habit_only_tracked_on_those_days(self, client, mock_supabase_db,
                                                            test_user_id,
                                                            sample_specific_days_habit,
                                                            sample_habit_log):
        """Test habits with specific_days frequency.

        The old test computed an `is_tracking_day` flag, stuffed the answer into
        the mock, and then asserted only `status_code == 200` — it could not
        fail. Here the day filter in `get_today_habits` is exercised for real:
        the same habit is included when today IS one of its target_days and
        excluded when it is not.
        """
        # today_habits_view rows carry the habit's target_days; the endpoint maps
        # python weekday (Mon=0) → the table's Sun=0 convention.
        today_dow = (api_today().weekday() + 1) % 7
        other_dow = (today_dow + 1) % 7

        mock_supabase_db.set_data("habit_logs", [sample_habit_log])

        # Case 1: today is a scheduled day → habit is tracked.
        scheduled = {**sample_specific_days_habit, "target_days": [today_dow]}
        mock_supabase_db.set_data("today_habits_view", [today_view_row(scheduled)])

        response = client.get(f"/api/v1/habits/{test_user_id}/today")
        assert response.status_code == 200
        data = response.json()
        assert data["total_habits"] == 1
        assert data["habits"][0]["name"] == "Gym Session"

        # Case 2: today is NOT a scheduled day → habit is filtered out.
        unscheduled = {**sample_specific_days_habit, "target_days": [other_dow]}
        mock_supabase_db.set_data("today_habits_view", [today_view_row(unscheduled)])

        response = client.get(f"/api/v1/habits/{test_user_id}/today")
        assert response.status_code == 200
        data = response.json()
        assert data["habits"] == []
        assert data["total_habits"] == 0


# ============================================================================
# Validation Tests
# ============================================================================

class TestHabitValidation:
    """Tests for request validation in habit endpoints."""

    def test_create_habit_requires_name(self, client, mock_supabase_db, test_user_id):
        """Test that name is required for habit creation."""
        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "habit_type": "positive",
                "frequency": "daily",
            },
        )

        assert response.status_code == 422
        mock_supabase_db.tables["habits"].insert.assert_not_called()

    def test_create_habit_validates_frequency(self, client, mock_supabase_db, test_user_id):
        """Test that frequency must be valid."""
        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "name": "Test Habit",
                "habit_type": "positive",
                "frequency": "invalid_frequency",
            },
        )

        assert response.status_code == 422
        mock_supabase_db.tables["habits"].insert.assert_not_called()

    def test_log_habit_requires_status(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that a log request missing its required fields is rejected.

        Named for a `status` field that the product never had: a log's state is
        the booleans `completed` / `skipped`, which default to False. The
        required fields on HabitLogCreate are `habit_id` and `log_date` — a body
        with neither must 422 rather than silently log something.
        """
        mock_supabase_db.set_data("habits", [sample_habit])

        response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={},  # no habit_id, no log_date
        )

        assert response.status_code == 422
        mock_supabase_db.tables["habit_logs"].upsert.assert_not_called()

    def test_specific_days_requires_days_array(self, client, mock_supabase_db, test_user_id):
        """Test that specific_days frequency requires days array.

        `HabitCreate.target_days` has always been documented "Required for
        SPECIFIC_DAYS frequency", but nothing enforced it: the habit was created
        with target_days=NULL and then silently behaved as a DAILY habit
        (`get_today_habits` only applies the day filter `if target_days`), while
        the calendar marked every unlogged day "missed" instead of
        "not_scheduled". Validator added to models/habits.py (create only).
        """
        response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={
                "name": "Test Habit",
                "habit_type": "positive",
                "frequency": "specific_days",
                # Missing target_days
            },
        )

        assert response.status_code == 422
        mock_supabase_db.tables["habits"].insert.assert_not_called()


# ============================================================================
# Error Handling Tests
# ============================================================================

class TestHabitErrorHandling:
    """Tests for error handling in habit endpoints."""

    def test_handles_database_error(self, client, mock_supabase_db, test_user_id):
        """Test handling of database errors."""
        mock_supabase_db.tables["habits"].execute.side_effect = Exception(
            "Database connection failed"
        )

        response = client.get(f"/api/v1/habits/{test_user_id}")

        assert response.status_code == 500
        # The DB error is not leaked to the client.
        assert "Database connection failed" not in response.text

    def test_handles_habit_not_found(self, client, mock_supabase_db, test_user_id):
        """Test handling of habit not found.

        There is no single-habit GET in the product (the list endpoint is
        `GET /habits/{user_id}`), so "unknown habit id" is exercised on a
        habit-scoped route: updating a habit that isn't yours/doesn't exist must
        404 — and must not fall through to an UPDATE.
        """
        mock_supabase_db.set_data("habits", [])  # ownership lookup finds nothing

        response = client.put(
            f"/api/v1/habits/{test_user_id}/{str(uuid4())}",
            json={"name": "Renamed"},
        )

        assert response.status_code == 404
        mock_supabase_db.tables["habits"].update.assert_not_called()

    def test_handles_log_not_found(self, client, mock_supabase_db, test_user_id):
        """Test handling of log not found for update."""
        mock_supabase_db.set_data("habit_logs", [])

        response = client.put(
            f"/api/v1/habits/{test_user_id}/log/{str(uuid4())}",
            json={"value": 10},
        )

        assert response.status_code in [404, 400]
        mock_supabase_db.tables["habit_logs"].update.assert_not_called()


# ============================================================================
# Integration-Style Tests
# ============================================================================

class TestHabitIntegration:
    """Integration-style tests for habit workflows."""

    def test_complete_habit_lifecycle(self, client, mock_supabase_db, test_user_id,
                                      sample_habit_log):
        """Test the complete lifecycle: create -> log -> update -> delete."""
        habit_id = str(uuid4())
        habit_row = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "Test Habit",
            "description": None,
            "category": "general",
            "habit_type": "positive",
            "frequency": "daily",
            "target_days": None,
            "target_count": 1,
            "unit": None,
            "icon": "check_circle",
            "color": "#4CAF50",
            "reminder_time": None,
            "reminder_enabled": False,
            "is_active": True,
            "is_suggested": False,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
        }

        # Step 1: Create habit
        mock_supabase_db.set_data("habits", [habit_row])
        create_response = client.post(
            f"/api/v1/habits/{test_user_id}",
            json={"name": "Test Habit", "habit_type": "positive", "frequency": "daily"},
        )
        assert create_response.status_code in [200, 201]
        assert create_response.json()["id"] == habit_id

        # Step 2: Log completion
        mock_supabase_db.set_data("habit_logs", [{**sample_habit_log, "habit_id": habit_id}])
        log_response = client.post(
            f"/api/v1/habits/{test_user_id}/log",
            json={
                "habit_id": habit_id,
                "log_date": api_today().isoformat(),
                "completed": True,
            },
        )
        assert log_response.status_code in [200, 201]
        assert log_response.json()["completed"] is True

        # Step 3: Update habit
        mock_supabase_db.set_data("habits", [{**habit_row, "name": "Updated Habit Name"}])
        update_response = client.put(
            f"/api/v1/habits/{test_user_id}/{habit_id}",
            json={"name": "Updated Habit Name"},
        )
        assert update_response.status_code == 200
        assert update_response.json()["name"] == "Updated Habit Name"

        # Step 4: Delete (soft delete)
        delete_response = client.delete(f"/api/v1/habits/{test_user_id}/{habit_id}")
        assert delete_response.status_code == 200
        assert mock_supabase_db.tables["habits"].update.call_args[0][0] == {"is_active": False}

    def test_streak_calculation_workflow(self, client, mock_supabase_db, test_user_id,
                                         sample_habit, sample_habit_log, sample_streak):
        """Test streak calculation over multiple days."""
        today = api_today()
        habit_id = sample_habit["id"]
        mock_supabase_db.set_data("habits", [sample_habit])

        # Log 5 consecutive days.
        for i in range(5, 0, -1):
            log_date = today - timedelta(days=i)
            mock_supabase_db.set_data("habit_logs", [{
                **sample_habit_log,
                "id": str(uuid4()),
                "habit_id": habit_id,
                "log_date": log_date.isoformat(),
            }])

            response = client.post(
                f"/api/v1/habits/{test_user_id}/log",
                json={
                    "habit_id": habit_id,
                    "log_date": log_date.isoformat(),
                    "completed": True,
                },
            )
            assert response.status_code in [200, 201]
            assert response.json()["log_date"] == log_date.isoformat()

        # Final streak check (habit_streaks is maintained by the DB trigger).
        mock_supabase_db.set_data("habit_streaks", [{
            **sample_streak,
            "habit_id": habit_id,
            "current_streak": 5,
            "longest_streak": 5,
        }])

        response = client.get(f"/api/v1/habits/{test_user_id}/{habit_id}/streak")

        assert response.status_code == 200
        data = response.json()
        assert data["current_streak"] == 5


# ============================================================================
# Model Validation Tests
# ============================================================================

class TestHabitModels:
    """Tests for the habit Pydantic models.

    These three used to assert a literal list against a copy of itself
    (`for f in ["daily", ...]: assert f in ["daily", ...]`) — tautologies that
    could never fail and never touched the product. They now pin the real enums
    in models/habits.py, which is what the original names promised. The old
    lists also contained values the product never had ("monthly" frequency;
    "partial"/"missed" log statuses) — a log's state is two booleans, not a
    status enum.
    """

    def test_habit_frequency_values(self):
        """Test valid habit frequency values."""
        from models.habits import HabitFrequency

        assert {f.value for f in HabitFrequency} == {"daily", "weekly", "specific_days"}

    def test_habit_type_values(self):
        """Test valid habit type values."""
        from models.habits import HabitType

        assert {t.value for t in HabitType} == {"positive", "negative"}

    def test_log_status_values(self):
        """Test the valid states of a habit log."""
        from models.habits import HabitLogCreate

        log = HabitLogCreate(habit_id=uuid4(), log_date=api_today())
        # Neither done nor skipped until something says so.
        assert log.completed is False
        assert log.skipped is False

        completed = HabitLogCreate(habit_id=uuid4(), log_date=api_today(), completed=True)
        assert completed.completed is True

        skipped = HabitLogCreate(
            habit_id=uuid4(), log_date=api_today(), skipped=True, skip_reason="Sick"
        )
        assert skipped.skipped is True
        assert skipped.completed is False
        assert skipped.skip_reason == "Sick"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
