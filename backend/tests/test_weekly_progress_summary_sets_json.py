"""Regression gate for UI_E2E 2026-08-05 row 46 (HIGH) / row 70 (MED, same class).

``weekly_progress_summary`` (096_progress_analytics.sql, last rewritten by
migration 2043) reads ``workout_logs.exercises_performance`` — a column that
is NULL on every current workout_logs row, because migration 2238 already
established ``sets_json`` as the sole write target for logged sets (and
re-pointed the SIBLING views ``exercise_workout_history`` /
``muscle_group_weekly_volume`` / ``muscle_group_weekly_volume_by_gym`` at it)
without including ``weekly_progress_summary`` in that migration.

Verified live: SUM(total_volume_kg)/SUM(total_sets)/SUM(total_reps) across
EVERY row of the CURRENT (unfixed) view is exactly 0 — for the entire user
base, not just one account — while 113 completed workout_logs rows across 6
users carry real sets_json data in the same window.

This test applies migrations/2403_repoint_weekly_progress_summary_at_sets_json.sql
inside an UNCOMMITTED transaction (always rolled back in the fixture
teardown — this test NEVER writes to the live schema) and asserts the view
now derives real, non-zero numbers from that data. Requires a live-Postgres
credential (DATABASE_URL / DATABASE_PASSWORD / SUPABASE_DB_PASSWORD); skips
cleanly without one, matching the established pattern in
test_xp_database_integration.py.
"""
import json
import os
from pathlib import Path
from urllib.parse import unquote, urlparse

import pytest

psycopg2 = pytest.importorskip("psycopg2")

BACKEND = Path(__file__).resolve().parents[1]
MIGRATION_SQL = (BACKEND / "migrations" / "2403_repoint_weekly_progress_summary_at_sets_json.sql").read_text()

# QA account with known, verified-live completed workout_logs carrying real
# sets_json (9 reps @ 25kg quadriceps set in the 2026-07-27 week).
_QA_USER_ID = "1aa02a24-0224-4a5a-b1e5-3f24dcd60bdc"


def _db_params() -> dict | None:
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
        "host": os.environ.get("DATABASE_HOST") or (p.hostname if p else None),
        "port": int(os.environ.get("DATABASE_PORT") or (p.port if p and p.port else 5432)),
        "dbname": os.environ.get("DATABASE_NAME") or ((p.path or "").lstrip("/") if p else "") or "postgres",
        "user": os.environ.get("DATABASE_USER") or (unquote(p.username) if p and p.username else None) or "postgres",
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


@pytest.fixture
def uncommitted_conn():
    """A live connection whose transaction is ALWAYS rolled back — this test
    never persists a schema change, regardless of pass/fail."""
    conn = psycopg2.connect(**_DB_PARAMS)
    conn.autocommit = False
    try:
        yield conn
    finally:
        conn.rollback()
        conn.close()


def test_current_live_view_sums_to_zero_across_every_user(uncommitted_conn):
    """Pins the FIX on the live catalog.

    Originally pinned the pre-fix defect (every weekly_progress_summary row
    summing to zero, reading the dead exercises_performance column).
    Migration 2403 has since been applied to the live database directly
    (see git log on that migration file), so the untouched `uncommitted_conn`
    here already reflects the fixed state — this now pins that the fix has
    landed and holds, instead of re-pinning a defect that no longer exists
    live.
    """
    cur = uncommitted_conn.cursor()
    cur.execute(
        "SELECT COALESCE(SUM(total_volume_kg), -1), COALESCE(SUM(total_sets), -1), "
        "COALESCE(SUM(total_reps), -1) FROM weekly_progress_summary"
    )
    volume, sets, reps = cur.fetchone()
    assert volume > 0 and sets > 0 and reps > 0, (
        f"expected the CURRENT (already-fixed) live weekly_progress_summary to "
        f"report real non-zero totals, got volume={volume} sets={sets} reps={reps} "
        f"— the fix may have regressed"
    )


def test_migration_2403_repoints_view_at_real_sets_json_data(uncommitted_conn):
    """Seeds a SYNTHETIC workout_logs row for the QA account, in an isolated
    week (2020-01-06, nowhere near any real logged data), rather than
    asserting on a specific historical live row. The original version of
    this test hardcoded "the 2026-07-27 week has a 9 reps @ 25kg quadriceps
    set" from a live verification snapshot — but that QA account is in
    ongoing use and its workout_logs content has since changed (the
    2026-07-27 week's completed set is now a 0kg assisted chin-up, not a
    25kg quadriceps set), so pinning to it rotted exactly like a live
    snapshot test would. Seeding our own row inside this same
    always-rolled-back transaction keeps the test deterministic without
    ever touching the live schema.
    """
    cur = uncommitted_conn.cursor()

    cur.execute("SELECT id FROM workouts WHERE user_id = %s LIMIT 1", (_QA_USER_ID,))
    workout_row = cur.fetchone()
    assert workout_row, "QA account must have at least one workouts row to attach a log to"
    workout_id = workout_row[0]

    synthetic_week_start = "2020-01-06"  # a Monday; isolated from any real data
    sets_json = json.dumps([{
        "reps": 9,
        "weight_kg": 25,
        "is_completed": True,
        "set_number": 1,
        "exercise_name": "Leg Press",
    }])
    cur.execute(
        """
        INSERT INTO workout_logs
            (workout_id, user_id, sets_json, total_time_seconds, completed_at, duration_minutes, status)
        VALUES (%s, %s, %s::jsonb, 2700, %s, 45, 'completed')
        """,
        (workout_id, _QA_USER_ID, sets_json, f"{synthetic_week_start}T12:00:00+00:00"),
    )

    cur.execute(MIGRATION_SQL)

    cur.execute(
        "SELECT week_start, total_volume_kg, total_sets, total_reps, workouts_completed "
        "FROM weekly_progress_summary WHERE user_id = %s AND week_start = %s",
        (_QA_USER_ID, synthetic_week_start),
    )
    row = cur.fetchone()
    assert row, "synthetic week must produce a weekly_progress_summary row"

    # 9 reps @ 25kg -> 225.0 kg total volume, exactly like
    # muscle_group_weekly_volume (already fixed by migration 2238) reports
    # for the identical underlying sets_json shape.
    _, total_volume_kg, total_sets, total_reps, workouts_completed = row
    assert total_volume_kg == 225, row
    assert total_sets == 1, row
    assert total_reps == 9, row
    assert workouts_completed == 1, row

    # Whole-catalog sanity: fixing the view must not silently zero out other
    # users' data, and must recover real (non-fabricated) aggregate volume.
    cur.execute(
        "SELECT SUM(total_volume_kg), SUM(total_sets), SUM(total_reps) FROM weekly_progress_summary"
    )
    total_volume, total_sets_all, total_reps_all = cur.fetchone()
    assert total_volume and total_volume > 0
    assert total_sets_all and total_sets_all > 0
    assert total_reps_all and total_reps_all > 0
