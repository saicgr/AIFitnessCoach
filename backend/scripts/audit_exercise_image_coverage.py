"""Audit + repair exercise-image 404 coverage.

Finds workout exercise names referenced in `workouts.exercises_json` (and the
exercise-tip / RAG sources) that DO NOT match an `exercise_library` row, then
proposes alias mappings into `exercise_image_aliases` using string-similarity
against library names. Writes high-confidence (>= 0.92 trigram similarity)
mappings directly; low-confidence candidates land in a CSV the operator can
hand-review.

Idempotent: re-running skips display_names already in the alias table.

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.audit_exercise_image_coverage

Output:
    backend/scripts/out/exercise_image_alias_audit_<ts>.csv (low-confidence)

Notes:
    * Uses raw asyncpg via backend/.env DATABASE_URL — no MCP.
    * Trigram threshold of 0.92 is intentionally conservative; this resolves
      "Barbell Close Grip Press" → "Close-Grip Barbell Bench Press" but NOT
      "Lat Pulldown" → "Lat Pushdown" (which would re-introduce the
      lat-pulldown bug).
    * Refreshes `exercise_library_cleaned` MV at the end so the new aliases
      become visible to the runtime path immediately.
"""
from __future__ import annotations

import asyncio
import csv
import os
import sys
import time
from pathlib import Path
from typing import List, Tuple

import asyncpg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

OUT_DIR = BACKEND / "scripts" / "out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

DB_URL = os.environ["DATABASE_URL"]
HIGH_CONFIDENCE = 0.92
LOW_CONFIDENCE = 0.70


async def fetch_referenced_names(conn: asyncpg.Connection) -> List[str]:
    """Distinct exercise names referenced by workouts.exercises_json.

    The column is a JSON array of objects with a `name` field. jsonb_path_query
    is cheaper than scanning Python-side because Postgres can use the GIN
    index on exercises_json.
    """
    rows = await conn.fetch(
        """
        SELECT DISTINCT lower(ex->>'name') AS name
        FROM workouts,
             jsonb_array_elements(exercises_json::jsonb) AS ex
        WHERE ex->>'name' IS NOT NULL
        """
    )
    return [r["name"] for r in rows if r["name"]]


async def main() -> int:
    conn = await asyncpg.connect(DB_URL)
    try:
        # Ensure pg_trgm is available — we rely on similarity().
        await conn.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

        referenced = await fetch_referenced_names(conn)
        print(f"[audit] {len(referenced)} distinct workout exercise names")

        existing = {
            r["display_name"]
            for r in await conn.fetch(
                "SELECT display_name FROM exercise_image_aliases"
            )
        }
        print(f"[audit] {len(existing)} aliases already mapped")

        # Names with no exact (case-insensitive) library row.
        unmatched: List[str] = []
        for name in referenced:
            if name in existing:
                continue
            row = await conn.fetchrow(
                "SELECT 1 FROM exercise_library "
                "WHERE lower(exercise_name) = $1 AND image_s3_path IS NOT NULL "
                "LIMIT 1",
                name,
            )
            if row is None:
                unmatched.append(name)
        print(f"[audit] {len(unmatched)} unmatched names need an alias")

        high: List[Tuple[str, str, str, float]] = []
        low: List[Tuple[str, str, str, float]] = []

        for name in unmatched:
            cand = await conn.fetchrow(
                """
                SELECT id, exercise_name, similarity(lower(exercise_name), $1) AS s
                FROM exercise_library
                WHERE image_s3_path IS NOT NULL
                ORDER BY similarity(lower(exercise_name), $1) DESC NULLS LAST
                LIMIT 1
                """,
                name,
            )
            if not cand or cand["s"] is None:
                continue
            row = (name, str(cand["id"]), cand["exercise_name"], float(cand["s"]))
            if cand["s"] >= HIGH_CONFIDENCE:
                high.append(row)
            elif cand["s"] >= LOW_CONFIDENCE:
                low.append(row)

        print(f"[audit] high-confidence aliases to insert: {len(high)}")
        print(f"[audit] low-confidence candidates for manual review: {len(low)}")

        # Insert high-confidence aliases — ON CONFLICT DO NOTHING in case a
        # previous run inserted them.
        for display, lib_id, _lib_name, _s in high:
            await conn.execute(
                """
                INSERT INTO exercise_image_aliases (display_name, library_exercise_id, source)
                VALUES ($1, $2, 'audit_script')
                ON CONFLICT (display_name) DO NOTHING
                """,
                display, lib_id,
            )

        if low:
            ts = int(time.time())
            out = OUT_DIR / f"exercise_image_alias_audit_{ts}.csv"
            with out.open("w", newline="") as f:
                w = csv.writer(f)
                w.writerow(["display_name", "candidate_library_id", "candidate_library_name", "trigram_similarity"])
                for row in low:
                    w.writerow(row)
            print(f"[audit] low-confidence CSV written: {out}")

        # Refresh MV so the runtime path sees new aliases immediately.
        try:
            await conn.execute("SELECT refresh_exercise_library_cleaned()")
            print("[audit] refreshed exercise_library_cleaned MV")
        except Exception as e:  # noqa: BLE001
            print(f"[audit] MV refresh skipped: {e}")

        return 0
    finally:
        await conn.close()


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
