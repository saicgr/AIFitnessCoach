"""Backfill: rewrite workouts.scheduled_date rows stored at midnight UTC to
noon UTC.

The old `/workouts/generate` rag_first path wrote `scheduled_date` as a bare
'YYYY-MM-DD', which Postgres TIMESTAMPTZ stores as midnight UTC. For any user
west of UTC (CDT, PDT, EDT, …) that timestamp falls into the *previous* local
day's tz-aware [day_start, day_end] window, so the /today endpoint serves
tomorrow's workout as TODAY.

Strategy: move the time component to 12:00 UTC. The date portion is preserved
verbatim. This is safe even for users east of UTC (noon UTC stays inside the
local day for any zone within ±11h of UTC, which covers all inhabited zones).

DRY-RUN by default. Pass --apply to actually write.

Usage:
    backend/.venv/bin/python backend/scripts/fix_midnight_utc_scheduled_dates.py
    backend/.venv/bin/python backend/scripts/fix_midnight_utc_scheduled_dates.py --apply
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # type: ignore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

import psycopg2  # type: ignore
from psycopg2.extras import RealDictCursor  # type: ignore


COUNT_SQL = """
SELECT count(*) AS n
FROM workouts
WHERE EXTRACT(hour FROM scheduled_date AT TIME ZONE 'UTC') = 0
  AND EXTRACT(minute FROM scheduled_date AT TIME ZONE 'UTC') = 0
"""

UPDATE_SQL = """
UPDATE workouts
SET scheduled_date = (scheduled_date::date + interval '12 hours')
WHERE EXTRACT(hour FROM scheduled_date AT TIME ZONE 'UTC') = 0
  AND EXTRACT(minute FROM scheduled_date AT TIME ZONE 'UTC') = 0
"""

SAMPLE_SQL = """
SELECT id, user_id, name, scheduled_date::text AS sd
FROM workouts
WHERE EXTRACT(hour FROM scheduled_date AT TIME ZONE 'UTC') = 0
  AND EXTRACT(minute FROM scheduled_date AT TIME ZONE 'UTC') = 0
ORDER BY scheduled_date DESC
LIMIT 10
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="actually write")
    args = parser.parse_args()

    url = os.environ["DATABASE_URL"].replace(
        "postgresql+asyncpg://", "postgresql://", 1
    )
    with psycopg2.connect(url, cursor_factory=RealDictCursor) as conn:
        with conn.cursor() as cur:
            cur.execute(COUNT_SQL)
            n = cur.fetchone()["n"]
            print(f"rows with scheduled_date at midnight UTC: {n}")

            cur.execute(SAMPLE_SQL)
            print("sample:")
            for r in cur.fetchall():
                print(" ", dict(r))

            if not args.apply:
                print("\n[dry-run] re-run with --apply to write the UPDATE.")
                return

            cur.execute(UPDATE_SQL)
            updated = cur.rowcount
            conn.commit()
            print(f"updated rows: {updated}")


if __name__ == "__main__":
    main()
