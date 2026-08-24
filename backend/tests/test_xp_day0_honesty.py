"""
E2E register #66 — day-0 XP honesty.

Runs against the actual Supabase database (mirrors
tests/test_xp_database_integration.py's connection resolution). Creates a
throwaway `users` row (no FK to auth.users on `id`, so a bare UUID is safe)
and drives the real RPCs directly, exactly as api/v1/xp.py and
api/v1/xp_endpoints.py do, so a regression in migration 2400's SQL is caught
here rather than in production.

Run with: pytest tests/test_xp_day0_honesty.py -v
"""

import os
import uuid
from datetime import date, timedelta
from urllib.parse import unquote, urlparse

import pytest

psycopg2 = pytest.importorskip("psycopg2")


def _db_params() -> dict | None:
    """Same resolution order as test_xp_database_integration.py — see that
    file's docstring for why this must never raise at import time."""
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
def db():
    conn = psycopg2.connect(**_DB_PARAMS)
    conn.autocommit = True
    try:
        yield conn
    finally:
        conn.close()


@pytest.fixture()
def test_user(db):
    """A throwaway `users` row. `created_at` defaults to NOW() (a brand-new
    account), which is what the crate 24h-age gate needs to test against."""
    user_id = str(uuid.uuid4())
    cur = db.cursor()
    cur.execute(
        """
        INSERT INTO users (id, email, fitness_level, goals, equipment)
        VALUES (%s, %s, 'beginner', '["general_fitness"]', 'none')
        """,
        (user_id, f"e2e-66-{user_id}@test.invalid"),
    )
    try:
        yield user_id
    finally:
        # Cascade cleanup — best-effort, order matters for FKs that exist.
        for table in (
            "xp_transactions", "user_login_streaks", "user_daily_crates",
            "user_first_time_bonuses", "user_xp", "xp_streak_freeze_ledger",
        ):
            try:
                cur.execute(f"DELETE FROM {table} WHERE user_id = %s", (user_id,))
            except Exception:
                db.rollback() if not db.autocommit else None
        cur.execute("DELETE FROM users WHERE id = %s", (user_id,))


def _process_daily_login(db, user_id: str, on_date: date) -> dict:
    cur = db.cursor()
    cur.execute(
        "SELECT process_daily_login(%s, %s)", (user_id, on_date.isoformat())
    )
    return cur.fetchone()[0]


class TestFirstLoginNoLongerDoubleAwards:
    """Fix #1: the FIRST-EVER process_daily_login call must not ALSO pay the
    daily-login bonus for the same event that earned the welcome bonus."""

    def test_day0_daily_bonus_is_zero(self, db, test_user):
        result = _process_daily_login(db, test_user, date.today())
        assert result["is_first_login"] is True
        assert result["daily_xp"] == 0, (
            "day-0 daily_login bonus should be suppressed — it double-counts "
            "the same login event as the welcome (first_login) bonus"
        )
        # The welcome bonus itself must still fire — this is a suppression of
        # ONE lever, not a wholesale removal of day-0 XP.
        assert result["first_login_xp"] > 0
        assert result["total_xp_awarded"] == result["first_login_xp"]

    def test_day2_daily_bonus_resumes(self, db, test_user):
        """The SECOND consecutive day must earn the normal daily_login bonus
        — proves the fix is day-0-specific, not a blanket disablement."""
        _process_daily_login(db, test_user, date.today())
        result = _process_daily_login(db, test_user, date.today() + timedelta(days=1))
        assert result["is_first_login"] is False
        assert result["daily_xp"] > 0, (
            "the daily-login streak mechanic must resume on the user's "
            "genuine second day"
        )


class TestDailyCrateRequiresAccountAge:
    """Fix #2/#3: a brand-new account must not have a random-reward crate to
    open before it has done anything."""

    def test_fresh_account_daily_crate_unavailable(self, db, test_user):
        cur = db.cursor()
        cur.execute(
            "SELECT init_daily_crates(%s, %s)", (test_user, date.today().isoformat())
        )
        status = cur.fetchone()[0]
        assert status["daily_crate_available"] is False, (
            "init_daily_crates must withhold the crate on signup day"
        )

    def test_fresh_account_claim_daily_crate_refused(self, db, test_user):
        """Exercises claim_daily_crate's OWN fallback row-creation branch
        directly (no prior init_daily_crates call) — this is the branch that
        actually calls award_xp(), so it is the one that must be honest even
        if the status-read path were somehow bypassed."""
        cur = db.cursor()
        cur.execute(
            "SELECT claim_daily_crate(%s, %s, %s)",
            (test_user, "daily", date.today().isoformat()),
        )
        result = cur.fetchone()[0]
        assert result["success"] is False
        assert "not available" in result["message"].lower()

    def test_day_old_account_daily_crate_available(self, db, test_user):
        """A genuinely >=24h-old account must still get its daily crate —
        this is a gate on account age, not a removal of the mechanic."""
        cur = db.cursor()
        cur.execute(
            "UPDATE users SET created_at = NOW() - INTERVAL '25 hours' WHERE id = %s",
            (test_user,),
        )
        cur.execute(
            "SELECT init_daily_crates(%s, %s)", (test_user, date.today().isoformat())
        )
        status = cur.fetchone()[0]
        assert status["daily_crate_available"] is True


class TestFirstGoalSetNoLongerAwardsXP:
    """Fix #4: first_goal_set fired on a MANDATORY onboarding field, not a
    discrete accomplishment — zeroed to match the first_complete_profile
    precedent. Pure unit check on the source-of-truth dict (no DB needed)."""

    def test_first_goal_set_is_zero(self):
        from api.v1.xp import FIRST_TIME_BONUSES

        assert FIRST_TIME_BONUSES["first_goal_set"] == 0
