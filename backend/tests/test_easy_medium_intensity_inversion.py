"""Regression gate for UI_E2E 2026-08-05 row 32 (HIGH).

"Gentle Start" Wk1 Easy tier prescribes MORE reps than Medium for every
exercise on the same session — the intensity ladder is inverted. A
full-catalog scan of all 46 Zealova Library programs' Easy/Medium variant
pairs (program_variants.intensity_level, joined to program_variant_weeks by
variant_id) found this holds at EXACTLY 100% (every single exercise-reps
comparison, every week, every duration/frequency combo) for 15 programs —
the intensity_level LABEL was swapped onto the wrong row at generation time.
11 further programs show a PARTIAL inversion rate (49-96%) and are
deliberately NOT touched by this migration (a partial rate means a blind
label swap would not cleanly fix them).

This test applies migrations/2410_fix_easy_medium_intensity_label_swap.sql
inside an UNCOMMITTED transaction (always rolled back — never writes to the
live schema) and asserts the swap actually resolves the inversion to zero.
Requires a live-Postgres credential; skips cleanly without one.
"""
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlparse

import os
import pytest

psycopg2 = pytest.importorskip("psycopg2")

BACKEND = Path(__file__).resolve().parents[1]
MIGRATION_SQL = (BACKEND / "migrations" / "2410_fix_easy_medium_intensity_label_swap.sql").read_text()

# The 15 programs the migration fixes (exactly 100% inversion pre-fix).
FIXED_PROGRAM_NAMES = [
    "Gentle Start (Zealova Library)",
    "Kettlebell Hard (Zealova Library)",
    "Olympic Weightlifting — Snatch & Clean Build (Zealova Library)",
    "World Cup Ready — Soccer Athlete Prep (Zealova Library)",
    "Kettlebell Foundations (Zealova Library)",
    "Kettlebell Builder (Zealova Library)",
    "Pilates Foundations (Zealova Library)",
    "First Pull-Up (Zealova Library)",
    "Wave Progression (Zealova Library)",
    "Dumbbell Home Strength (Zealova Library)",
    "HIIT Shred (Zealova Library)",
    "Glutes Builder (Zealova Library)",
    "Menopause Strength (Zealova Library)",
    "Strength After 50 (Zealova Library)",
    "Rucking Ready (Zealova Library)",
]


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


def _sig(name: str) -> str | None:
    m = re.search(r"[-—]\s*([\dA-Za-z/x ]+?)/?(Easy|Medium|Hard)\s*$", name or "")
    return m.group(1).strip() if m else None


def _inversions_for_program(cur, program_name: str) -> tuple[int, int]:
    """Returns (total_reps_comparisons, inversions) for a program's Easy/Medium pairs."""
    cur.execute("SELECT id FROM branded_programs WHERE name = %s", (program_name,))
    row = cur.fetchone()
    assert row, f"program {program_name!r} must exist"
    base_id = row[0]

    cur.execute(
        "SELECT id, intensity_level, variant_name FROM program_variants WHERE base_program_id = %s",
        (base_id,),
    )
    groups: dict[str, dict[str, str]] = {}
    for vid, intensity, vname in cur.fetchall():
        s = _sig(vname)
        if s is None:
            continue
        groups.setdefault(s, {})[intensity] = vid
    pairs = [(t["Easy"], t["Medium"]) for t in groups.values() if "Easy" in t and "Medium" in t]
    assert pairs, f"{program_name} must have at least one Easy/Medium pair"

    total = 0
    inversions = 0
    for evid, mvid in pairs:
        cur.execute("SELECT week_number, workouts FROM program_variant_weeks WHERE variant_id = %s", (evid,))
        e_weeks = dict(cur.fetchall())
        cur.execute("SELECT week_number, workouts FROM program_variant_weeks WHERE variant_id = %s", (mvid,))
        m_weeks = dict(cur.fetchall())
        for wk, ed in e_weeks.items():
            md = m_weeks.get(wk)
            if md is None:
                continue
            if isinstance(ed, str):
                ed = json.loads(ed)
            if isinstance(md, str):
                md = json.loads(md)
            for eday, mday in zip(ed, md):
                for ee, me in zip(eday.get("exercises", []), mday.get("exercises", [])):
                    er, mr = ee.get("reps"), me.get("reps")
                    if isinstance(er, (int, float)) and isinstance(mr, (int, float)):
                        total += 1
                        if er > mr:
                            inversions += 1
    return total, inversions


@pytest.fixture
def conn():
    c = psycopg2.connect(**_DB_PARAMS)
    c.autocommit = False
    try:
        yield c
    finally:
        c.rollback()
        c.close()


def test_current_live_catalog_has_the_100pct_inversion(conn):
    """Pins the DEFECT (pre-fix state) for the reported program."""
    cur = conn.cursor()
    total, inversions = _inversions_for_program(cur, "Gentle Start (Zealova Library)")
    assert total > 0
    assert inversions == total, (
        f"expected the CURRENT (unfixed) catalog to show 100% Easy>Medium reps "
        f"inversion for Gentle Start, got {inversions}/{total} — if this fails, "
        f"migration 2410 was already applied and this pin is stale"
    )


@pytest.mark.parametrize("program_name", FIXED_PROGRAM_NAMES)
def test_migration_2410_resolves_inversion_to_zero(conn, program_name):
    cur = conn.cursor()
    cur.execute(MIGRATION_SQL)
    total, inversions = _inversions_for_program(cur, program_name)
    assert total > 0
    assert inversions == 0, f"{program_name}: {inversions}/{total} reps comparisons still inverted after the fix"


def test_migration_2410_does_not_create_duplicate_variant_keys(conn):
    """The unique(base_program_id, intensity_level, duration_weeks, sessions_per_week)
    constraint must hold after every row in the swap sequence — this is the
    defect a naive two-statement swap hits (UniqueViolation mid-transaction)."""
    cur = conn.cursor()
    cur.execute(MIGRATION_SQL)
    cur.execute("""
        SELECT base_program_id, intensity_level, duration_weeks, sessions_per_week, count(*)
        FROM program_variants GROUP BY 1,2,3,4 HAVING count(*) > 1
    """)
    dupes = cur.fetchall()
    assert dupes == [], dupes

    cur.execute("SELECT count(*) FROM program_variants WHERE sessions_per_week > 100")
    assert cur.fetchone()[0] == 0, "a row was left with the temporary +1000 sessions_per_week offset"
