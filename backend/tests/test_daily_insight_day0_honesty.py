"""
E2E register #80 / #132a / #132c — coach card correctness.

Runs against the actual Supabase database (same connection-resolution
pattern as tests/test_xp_database_integration.py). Creates throwaway `users`
/ `workouts` / `daily_activity` rows and drives the real
`_collect_snapshot` / `_pick_fallback_pillar` functions directly.

NOTE for local runs: this repo's checked-in `backend/.venv` is pinned to
Python 3.9 (see .python-version == 3.11 for the REAL runtime / Render). A
handful of unrelated files (e.g. api/v1/users/auth.py) use `dict | None`
PEP 604 union syntax, which 3.9 cannot parse. Importing anything under the
`api.v1` PACKAGE locally therefore raises TypeError at import time, via
api/v1/__init__.py eagerly importing every sibling submodule -- this is a
pre-existing, unrelated environment gap, not a defect in this test or the
code it tests. It does not affect CI/Render, which run 3.11. If you need to
verify locally without upgrading the venv, load the target file directly via
`importlib.util.spec_from_file_location` to sidestep the package `__init__`
chain (its own top-level imports are only `core.*` / `services.*`, which do
not hit the 3.9-incompatible syntax).

Run with: pytest tests/test_daily_insight_day0_honesty.py -v
"""

import os
import uuid
from datetime import datetime, timezone
from urllib.parse import unquote, urlparse

import pytest

psycopg2 = pytest.importorskip("psycopg2")


def _db_params() -> dict | None:
    """Same resolution order as test_xp_database_integration.py."""
    url = os.environ.get("DATABASE_URL_DIRECT") or os.environ.get("DATABASE_URL")
    p = urlparse(url) if url else None

    password = (
        os.environ.get("DATABASE_PASSWORD")
        or os.environ.get("SUPABASE_DB_PASSWORD")
        or (unquote(p.password) if p and p.password else None)
    )
    if not password:
        return None

    return {
        "host": os.environ.get("DATABASE_HOST")
                or (p.hostname if p else None)
                or "db.hpbzfahijszqmgsybuor.supabase.co",
        "port": int(os.environ.get("DATABASE_PORT") or (p.port if p and p.port else 5432)),
        "dbname": os.environ.get("DATABASE_NAME")
                  or ((p.path or "").lstrip("/") if p else "")
                  or "postgres",
        "user": os.environ.get("DATABASE_USER")
                or (unquote(p.username) if p and p.username else None)
                or "postgres",
        "password": password,
        "sslmode": "require",
    }


_DB_PARAMS = _db_params()

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        _DB_PARAMS is None,
        reason=(
            "No live-Postgres credential. Set DATABASE_PASSWORD / SUPABASE_DB_PASSWORD / "
            "DATABASE_URL_DIRECT, e.g. `cd backend && set -a && source ./.env && set +a`."
        ),
    ),
]


@pytest.fixture()
def pg(db_url=None):
    url = os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]
    url = url.replace("postgresql+asyncpg://", "postgresql://")
    conn = psycopg2.connect(url)
    conn.autocommit = True
    try:
        yield conn
    finally:
        conn.close()


@pytest.fixture()
def di():
    """The daily_insight module. Standard import -- works on the real
    Python 3.11 CI/Render runtime; see module docstring for the local py3.9
    .venv caveat."""
    from api.v1.coach import daily_insight
    return daily_insight


@pytest.fixture()
def sb():
    from core.db import get_supabase_db
    return get_supabase_db()


@pytest.fixture()
def test_user(pg):
    user_id = str(uuid.uuid4())
    tz = "America/Chicago"
    cur = pg.cursor()
    cur.execute(
        "INSERT INTO users (id, email, fitness_level, goals, equipment, "
        "onboarding_completed, timezone) VALUES (%s, %s, 'beginner', "
        "'general_fitness', 'none', false, %s)",
        (user_id, f"e2e-80-{user_id}@test.invalid", tz),
    )
    try:
        yield user_id, tz
    finally:
        for table in ("workouts", "daily_activity"):
            cur.execute(f"DELETE FROM {table} WHERE user_id = %s", (user_id,))
        cur.execute("DELETE FROM users WHERE id = %s", (user_id,))


class TestReachMetAndLifecycle:
    """E2E #80 — the coach card kept saying 'Generate today's workout or log
    a meal' right after a workout was completed."""

    def test_no_workout_train_not_applicable(self, di, sb, test_user):
        user_id, tz = test_user
        from core.timezone_utils import get_user_today
        local_date_iso = get_user_today(tz)
        snapshot, next_workout = di._collect_snapshot(sb, user_id, local_date_iso, tz)
        assert snapshot["train"]["applicable"] is False
        assert snapshot.get("lifecycle") == "new"

    def test_completed_workout_flips_reach_met_and_lifecycle(self, di, sb, test_user):
        """The core bug: scheduled_date is a noon-anchored timestamptz, and
        the OLD code compared it with a bare-date `.eq()`, which could never
        match -- reach_met stayed False forever and lifecycle stayed "new"."""
        user_id, tz = test_user
        from core.timezone_utils import get_user_today, target_date_to_utc_iso
        local_date_iso = get_user_today(tz)
        noon_iso = target_date_to_utc_iso(local_date_iso, tz)

        sb.client.table("workouts").insert({
            "user_id": user_id,
            "name": "Test Completed Workout",
            "type": "strength",
            "difficulty": "medium",
            "exercises_json": [],
            "scheduled_date": noon_iso,
            "completed_at": datetime.now(timezone.utc).isoformat(),
            "is_completed": True,
            "duration_minutes": 30,
        }).execute()

        snapshot, next_workout = di._collect_snapshot(sb, user_id, local_date_iso, tz)
        assert next_workout is not None
        assert snapshot["train"]["reach_met"] is True
        assert snapshot.get("lifecycle") == "active", (
            "a user who just completed a workout must not still read as "
            "lifecycle='new' regardless of the onboarding_completed flag"
        )


class TestMovePillarGatedOnHealthConnection:
    """E2E #132c — the coach invoked the "Move ring" for an account with no
    Health integration."""

    def test_never_synced_move_not_applicable(self, di, sb, test_user):
        user_id, tz = test_user
        from core.timezone_utils import get_user_today
        local_date_iso = get_user_today(tz)
        snapshot, _ = di._collect_snapshot(sb, user_id, local_date_iso, tz)
        assert snapshot["move"]["applicable"] is False
        assert "step_target" not in snapshot["move"]

    def test_connected_health_move_applicable(self, di, sb, test_user):
        user_id, tz = test_user
        from core.timezone_utils import get_user_today
        local_date_iso = get_user_today(tz)
        sb.client.table("daily_activity").insert({
            "user_id": user_id, "activity_date": local_date_iso, "steps": 500,
        }).execute()
        snapshot, _ = di._collect_snapshot(sb, user_id, local_date_iso, tz)
        assert snapshot["move"]["applicable"] is True
        assert snapshot["move"]["step_target"] == 10000

    def test_fallback_pillar_never_leads_with_move_when_disconnected(self, di):
        disconnected_snapshot = {
            "train": {"applicable": False, "reach_met": False},
            "nourish": {"calorie_target": 0, "calories_logged": 0},
            "move": {"applicable": False, "steps": 0},
            "sleep": {"target_hours": 0},
        }
        assert di._pick_fallback_pillar(disconnected_snapshot) != "move"
