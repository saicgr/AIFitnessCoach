"""Parity test: Python `normalize_food_name()` MUST match SQL `normalize_food_name_sql()`.

Why this exists: the `*_normalized` columns on user_recipes / recipe_ingredients /
saved_foods / grocery_list_items are GENERATED STORED from the SQL function. The
Python normalizer is what callers use for the pre-insert dedupe SELECT. If the
two implementations ever drift, the SELECT misses an existing row and either:
  - silently inserts a duplicate (when the unique index allows it), or
  - throws an unique-violation 500 to the user (when it doesn't).

This test runs every fixture through both implementations and fails if any
single string produces different output. Add a new fixture row whenever you
add a new normalization rule.
"""
from __future__ import annotations

import os
import unittest

import psycopg2
from dotenv import load_dotenv

from core.food_naming import normalize_food_name  # noqa: E402  (run with PYTHONPATH=backend)


def _connect():
    """Open a Postgres connection using backend/.env DATABASE_URL.

    Mirrors the standing pattern from feedback_run_migrations_directly.md —
    backend/.venv + backend/.env is the canonical local-test setup. Falls
    back to the canonical repo .env when running from a worktree (which
    doesn't carry its own .env).
    """
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", ".env"),
        "/Users/saichetangrandhe/AIFitnessCoach/backend/.env",
    ]
    for path in candidates:
        if os.path.exists(path):
            load_dotenv(path)
            break
    dsn = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")
    return psycopg2.connect(dsn)


# Diverse fixture: Indian + western + branded + accented + empties + edge cases.
# Each row is `(input, expected_normalized)`. Same expected drives both sides.
FIXTURES: list[tuple[str | None, str]] = [
    # Empties / nones
    ("", ""),
    (None, ""),
    ("   ", ""),
    # Basic case + whitespace
    ("Idli", "idli"),
    ("IDLI", "idli"),
    ("idli", "idli"),
    ("  idli  ", "idli"),
    ("Masala Dosa", "masala dosa"),
    ("  Aloo  Paratha  ", "aloo paratha"),
    # Punctuation
    ("Dosa, Masala", "dosa masala"),
    ("Chicken Biryani (XL)", "chicken biryani xl"),
    ("McDonald's Burger", "mcdonald s burger"),
    ("Half-and-Half", "half and half"),
    # Plurals — irregular overrides
    ("Idlis", "idli"),
    ("IDLIS", "idli"),
    ("Samosas", "samosa"),
    ("Parathas", "paratha"),
    ("Chutneys", "chutney"),
    ("Rotis", "roti"),
    ("Curries", "curry"),
    ("Tomatoes", "tomato"),
    ("Potatoes", "potato"),
    ("Cookies", "cookie"),
    ("Brownies", "brownie"),
    ("Berries", "berry"),
    ("Cherries", "cherry"),
    # Plurals — generic suffix rules
    ("Boxes", "box"),
    ("Dishes", "dish"),
    ("Bananas", "banana"),
    ("Eggs", "egg"),
    ("Apples", "apple"),
    ("Puppies", "puppy"),
    # Plural rule exclusions (don't strip s from kiss/bus/basis)
    ("Kiss", "kiss"),
    ("Bus", "bus"),
    ("Basis", "basis"),
    # Diacritics
    ("Crème Brûlée", "creme brulee"),
    ("Café", "cafe"),
    ("Jalapeño", "jalapeno"),
    # Mixed real-world
    ("Chicken Curries", "chicken curry"),
    ("Tawa Fish Fry", "tawa fish fry"),
    ("Prawns Curry", "prawn curry"),
    ("Idli + Sambar + Coconut Chutney", "idli sambar coconut chutney"),
    # Numbers
    ("100% Whey", "100 whey"),
    ("Coca-Cola Zero", "coca cola zero"),
    ("Vitamin B12", "vitamin b12"),
]


class TestFoodNamingParity(unittest.TestCase):
    def test_python_matches_sql_for_every_fixture(self):
        conn = _connect()
        try:
            cur = conn.cursor()
            mismatches: list[str] = []
            for inp, expected in FIXTURES:
                py_out = normalize_food_name(inp)
                cur.execute("SELECT normalize_food_name_sql(%s)", (inp,))
                sql_out = cur.fetchone()[0] or ""
                if py_out != expected:
                    mismatches.append(
                        f"Python differs from expected: input={inp!r} "
                        f"expected={expected!r} got={py_out!r}"
                    )
                if sql_out != expected:
                    mismatches.append(
                        f"SQL differs from expected: input={inp!r} "
                        f"expected={expected!r} got={sql_out!r}"
                    )
                if py_out != sql_out:
                    mismatches.append(
                        f"Python ↔ SQL drift: input={inp!r} "
                        f"py={py_out!r} sql={sql_out!r}"
                    )
            self.assertEqual(
                mismatches, [],
                "Normalization parity failed:\n  " + "\n  ".join(mismatches),
            )
        finally:
            conn.close()


if __name__ == "__main__":
    unittest.main()
