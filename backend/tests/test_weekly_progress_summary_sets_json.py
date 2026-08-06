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
    """Pins the DEFECT as it exists today, before the migration is applied."""
    cur = uncommitted_conn.cursor()
    cur.execute(
        "SELECT COALESCE(SUM(total_volume_kg), -1), COALESCE(SUM(total_sets), -1), "
        "COALESCE(SUM(total_reps), -1) FROM weekly_progress_summary"
    )
    volume, sets, reps = cur.fetchone()
    assert (volume, sets, reps) == (0, 0, 0), (
        "expected the CURRENT (unfixed) weekly_progress_summary to sum to zero "
        "everywhere (reading the dead exercises_performance column) — if this "
        "fails, migration 2403 was already applied and this pin is stale"
    )


def test_migration_2403_repoints_view_at_real_sets_json_data(uncommitted_conn):
    cur = uncommitted_conn.cursor()
    cur.execute(MIGRATION_SQL)

    cur.execute(
        "SELECT week_start, total_volume_kg, total_sets, total_reps, workouts_completed "
        "FROM weekly_progress_summary WHERE user_id = %s ORDER BY week_start",
        (_QA_USER_ID,),
    )
    rows = cur.fetchall()
    assert rows, "QA account must have at least one weekly_progress_summary row"

    # 2026-07-27 week: verified live 9 reps @ 25kg quadriceps set exists in
    # workout_logs.sets_json for this account -> 225.0 kg total volume, same
    # number muscle_group_weekly_volume (already fixed by migration 2238)
    # independently reports for the identical underlying rows.
    week = next(r for r in rows if str(r[0]) == "2026-07-27")
    _, total_volume_kg, total_sets, total_reps, workouts_completed = week
    assert total_volume_kg == 225, week
    assert total_sets >= 1, week
    assert total_reps >= 9, week
    assert workouts_completed >= 1, week

    # Whole-catalog sanity: fixing the view must not silently zero out other
    # users' data, and must recover real (non-fabricated) aggregate volume.
    cur.execute(
        "SELECT SUM(total_volume_kg), SUM(total_sets), SUM(total_reps) FROM weekly_progress_summary"
    )
    total_volume, total_sets_all, total_reps_all = cur.fetchone()
    assert total_volume and total_volume > 0
    assert total_sets_all and total_sets_all > 0
    assert total_reps_all and total_reps_all > 0
