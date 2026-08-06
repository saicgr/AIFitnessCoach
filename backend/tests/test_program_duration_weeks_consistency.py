"""Regression gate for UI_E2E 2026-08-05 row 30 (HIGH).

``programs.duration_weeks`` (rendered on the library card + the program
detail stat tile) must agree with the program's OWN embedded metadata: the
``workouts`` blob's ``duration`` string / day-count, and the ``phases``
array's max ``week_end``. "30-Day Plank Challenge"
(id=6e9539c2-feef-497d-9d0b-8c499838d2f8) had duration_weeks=1 while its own
blob said "5 weeks" (30 days at sessions_per_week=6) and its own phases
array's last entry ended at week 5 — three numbers on one row disagreeing
with each other.

This is a full-catalog CLASS gate (every published program's own
self-reported duration must be internally consistent), not just a pin on
the one reported program, per the "fix whole class + regression gate"
convention. Requires a live-Postgres credential; skips cleanly without one.
"""
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlparse

import os
import pytest

psycopg2 = pytest.importorskip("psycopg2")

BACKEND = Path(__file__).resolve().parents[1]
MIGRATION_SQL = (BACKEND / "migrations" / "2404_fix_plank_challenge_duration_weeks.sql").read_text()

_PLANK_PROGRAM_ID = "6e9539c2-feef-497d-9d0b-8c499838d2f8"


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


def _self_reported_weeks(program_row: dict) -> tuple[int | None, int | None]:
    """Return (weeks_from_blob_duration_string, weeks_from_phases_max_week_end)."""
    wk = program_row.get("workouts")
    if isinstance(wk, str):
        try:
            wk = json.loads(wk)
        except Exception:
            wk = None

    blob_weeks = None
    if isinstance(wk, dict):
        raw = wk.get("duration")
        s = str(raw) if raw is not None else ""
        m = re.search(r"(\d+)\s*week", s, re.I)
        if m:
            blob_weeks = int(m.group(1))
        else:
            m2 = re.search(r"(\d+)\s*day", s, re.I)
            if m2:
                blob_weeks = round(int(m2.group(1)) / 7) or 1

    phases = program_row.get("phases")
    if isinstance(phases, str):
        try:
            phases = json.loads(phases)
        except Exception:
            phases = None
    phase_weeks = None
    if isinstance(phases, list) and phases:
        ends = [p.get("week_end") for p in phases if isinstance(p, dict) and p.get("week_end") is not None]
        if ends:
            phase_weeks = max(ends)

    return blob_weeks, phase_weeks


@pytest.fixture
def conn():
    c = psycopg2.connect(**_DB_PARAMS)
    c.autocommit = False
    try:
        yield c
    finally:
        c.rollback()
        c.close()


def test_no_published_program_disagrees_with_its_own_embedded_duration(conn):
    """Whole-class gate: scans every program, not just the one reported.

    Applies migration 2404 first (uncommitted, rolled back at teardown) so
    this asserts the POST-FIX state of the catalog — the migration is the
    one known fix; this test's job is to confirm nothing ELSE in the
    297-program catalog shares the defect.
    """
    cur = conn.cursor()
    cur.execute(MIGRATION_SQL)
    cur.execute("SELECT id, program_name, duration_weeks, workouts, phases FROM programs")
    cols = ["id", "program_name", "duration_weeks", "workouts", "phases"]
    mismatches = []
    for row in cur.fetchall():
        r = dict(zip(cols, row))
        blob_weeks, phase_weeks = _self_reported_weeks(r)
        dw = r["duration_weeks"]
        reasons = []
        if blob_weeks is not None and dw != blob_weeks:
            reasons.append(f"blob says {blob_weeks}w, column says {dw}w")
        if phase_weeks is not None and dw != phase_weeks:
            reasons.append(f"phases end at week {phase_weeks}, column says {dw}w")
        if reasons:
            mismatches.append((r["id"], r["program_name"], reasons))

    assert mismatches == [], (
        f"{len(mismatches)} program(s) disagree with their own embedded "
        f"duration metadata: {mismatches}"
    )


def test_migration_2404_fixes_the_plank_challenge_row(conn):
    cur = conn.cursor()
    cur.execute(MIGRATION_SQL)
    cur.execute("SELECT duration_weeks FROM programs WHERE id = %s", (_PLANK_PROGRAM_ID,))
    row = cur.fetchone()
    assert row is not None, "30-Day Plank Challenge program row must exist"
    assert row[0] == 5, f"expected duration_weeks=5 after the fix, got {row[0]}"
