"""Real-database companion to test_food_macro_integrity_e2e.py.

WHY THIS EXISTS
---------------
``test_food_macro_integrity_e2e.py`` drives ``/log-image-stream`` with a
``_FakeDB`` and a hardcoded analysis dict. That is a good, fast unit test of
the macro-integrity GATE, but its assertions are about a payload captured in
memory — it cannot prove the thing its own test names claim
("...persists_null_not_zero"), because nothing is ever persisted.

The original incident was precisely a persistence-shaped bug: a dish the
analyzer could only price in calories was written with 0/0/0 macros instead of
NULL, so "no data" became "measured zero" and every downstream average was
silently wrong. Distinguishing those two states is a property of the COLUMNS,
not of the request handler, so it needs a real database to verify.

SAFETY
------
Every test here runs inside an explicit transaction that is ALWAYS rolled back,
so nothing is persisted even on failure. No cleanup step can be skipped or
forgotten, and a crashed test cannot leave residue. Reads are done inside the
same transaction, which is exactly what makes the round trip meaningful.

Skips cleanly when DATABASE_URL_DIRECT is not configured, so it never breaks a
contributor without DB access.
"""
from __future__ import annotations

import os
import re
import uuid
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parent.parent


def _direct_dsn() -> str | None:
    """Session-mode Postgres DSN, or None when unavailable.

    Deliberately the DIRECT endpoint, not the pooler: this test opens an
    explicit transaction, and a transaction-mode pooler is the wrong tool for
    holding one open across several statements.
    """
    env_path = BACKEND / ".env"
    if not env_path.exists():
        return None
    env = dict(
        re.findall(r"^(\w+)=(.*)$", env_path.read_text(encoding="utf-8"), re.M)
    )
    dsn = env.get("DATABASE_URL_DIRECT") or os.environ.get("DATABASE_URL_DIRECT")
    if not dsn:
        return None
    return dsn.replace("postgresql+asyncpg://", "postgresql://").strip()


psycopg2 = pytest.importorskip("psycopg2", reason="psycopg2 not installed")

_DSN = _direct_dsn()
pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(_DSN is None, reason="DATABASE_URL_DIRECT not configured"),
]


@pytest.fixture
def rolled_back_cursor():
    """A cursor whose transaction is always rolled back."""
    conn = psycopg2.connect(_DSN)
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            yield cur
    finally:
        conn.rollback()   # never commit — this fixture must not persist anything
        conn.close()


@pytest.fixture
def a_real_user_id(rolled_back_cursor):
    rolled_back_cursor.execute("SELECT id FROM users LIMIT 1;")
    row = rolled_back_cursor.fetchone()
    if not row:
        pytest.skip("no users row to attach a food_log to")
    return row[0]


def _insert(cur, user_id, name, calories, protein, carbs, fat):
    cur.execute(
        """
        INSERT INTO food_logs
            (id, user_id, food_name, total_calories, protein_g, carbs_g, fat_g,
             logged_at, input_type)
        VALUES (%s, %s, %s, %s, %s, %s, %s, now(), 'camera')
        RETURNING protein_g, carbs_g, fat_g, total_calories;
        """,
        (str(uuid.uuid4()), user_id, name, calories, protein, carbs, fat),
    )
    return cur.fetchone()


def test_calories_only_dish_persists_null_macros_not_zero(
    rolled_back_cursor, a_real_user_id
):
    """THE incident: unknown macros must come back NULL, never 0."""
    protein, carbs, fat, calories = _insert(
        rolled_back_cursor, a_real_user_id,
        "__test__ chocolate layer cake with strawberry coulis",
        520, None, None, None,
    )

    assert calories == 520, "calories should round-trip unchanged"
    assert protein is None and carbs is None and fat is None, (
        "Unknown macros round-tripped as something other than NULL "
        f"(got protein={protein!r} carbs={carbs!r} fat={fat!r}). "
        "'Not measured' must stay distinguishable from 'measured zero' — "
        "collapsing them silently corrupts every downstream average."
    )


def test_spirit_persists_real_zero_macros_not_null(
    rolled_back_cursor, a_real_user_id
):
    """The mirror case: a genuine 0 must NOT be corrupted into NULL."""
    protein, carbs, fat, calories = _insert(
        rolled_back_cursor, a_real_user_id,
        "__test__ Vodka (80 Proof), 1.5 oz",
        97, 0, 0, 0,
    )

    assert calories == 97
    assert (protein, carbs, fat) == (0, 0, 0), (
        f"A real zero was not preserved (got {protein!r}, {carbs!r}, {fat!r}). "
        "The NULL-vs-zero guard must not overcorrect in the other direction."
    )


def test_macro_columns_are_nullable():
    """The distinction above is only possible if the columns allow NULL.

    A future NOT NULL DEFAULT 0 migration would silently reinstate the original
    bug for every write path at once, so pin it here.
    """
    conn = psycopg2.connect(_DSN)
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT column_name, is_nullable
                FROM information_schema.columns
                WHERE table_name = 'food_logs'
                  AND column_name IN ('protein_g', 'carbs_g', 'fat_g');
                """
            )
            nullability = dict(cur.fetchall())
    finally:
        conn.rollback()
        conn.close()

    assert nullability, "food_logs macro columns not found"
    not_nullable = [c for c, n in nullability.items() if n != "YES"]
    assert not not_nullable, (
        f"food_logs macro column(s) {not_nullable} are NOT NULL. That makes "
        "'unknown' impossible to express, so unknown macros will be stored as "
        "0 and read back as a measurement."
    )


def test_nothing_from_this_module_was_persisted():
    """Belt-and-braces: prove the rollbacks actually held."""
    conn = psycopg2.connect(_DSN)
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM food_logs WHERE food_name LIKE '\\_\\_test\\_\\_%';"
            )
            leaked = cur.fetchone()[0]
    finally:
        conn.rollback()
        conn.close()

    assert leaked == 0, (
        f"{leaked} row(s) from this module survived — a transaction was "
        "committed that should have been rolled back."
    )
