"""Read-only diagnostic for the Wed20/Thu21 workout schedule mismatch.

Runs queries A–E from the plan against the live DB using DATABASE_URL from
backend/.env. Prints results to stdout. Does NOT mutate anything.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Load backend/.env so DATABASE_URL is available
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # type: ignore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

import psycopg2  # type: ignore
from psycopg2.extras import RealDictCursor  # type: ignore

EMAILS = ("reviewer@zealova.com", "reviewer@fitwiz.us")


def run(cur, label: str, sql: str, params=(), keys: tuple | None = None) -> None:
    print(f"\n=== {label} ===")
    cur.execute(sql, params)
    rows = cur.fetchall()
    if not rows:
        print("(no rows)")
        return
    for r in rows:
        d = dict(r)
        if keys is not None:
            d = {k: d.get(k) for k in keys}
        print(d)


def main() -> None:
    url = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://", 1)
    with psycopg2.connect(url, cursor_factory=RealDictCursor) as conn:
        with conn.cursor() as cur:
            run(
                cur,
                "A. Users (prefs / DOB / tz / tier)",
                """
                SELECT id, email, preferences->'workout_days' AS workout_days,
                       date_of_birth, timezone
                FROM users WHERE email = ANY(%s)
                """,
                (list(EMAILS),),
            )
            run(
                cur,
                "B. Gym profiles",
                """
                SELECT id, name, workout_days, is_active, created_at, user_id
                FROM gym_profiles
                WHERE user_id IN (
                    SELECT id FROM users WHERE email = ANY(%s)
                )
                ORDER BY user_id, created_at
                """,
                (list(EMAILS),),
            )
            run(
                cur,
                "C. Workouts 2026-05-17..2026-05-25 (compact)",
                """
                SELECT id, user_id, name, scheduled_date::date AS d,
                       is_completed, gym_profile_id, status,
                       generation_method, generation_source,
                       original_scheduled_date::date AS orig_d,
                       reschedule_count, rescheduled_from_workout_id,
                       is_current, version_number, parent_workout_id,
                       created_at
                FROM workouts
                WHERE user_id IN (
                    SELECT id FROM users WHERE email = ANY(%s)
                )
                  AND scheduled_date::date >= '2026-05-17'
                  AND scheduled_date::date <= '2026-05-25'
                ORDER BY user_id, scheduled_date, created_at
                """,
                (list(EMAILS),),
            )
            run(
                cur,
                "D0. daily_plan_entries columns",
                """
                SELECT column_name FROM information_schema.columns
                WHERE table_name='daily_plan_entries' AND table_schema='public'
                ORDER BY ordinal_position
                """,
            )
            run(
                cur,
                "D. daily_plan_entries 2026-05-17..2026-05-25",
                """
                SELECT * FROM daily_plan_entries
                WHERE user_id IN (
                    SELECT id FROM users WHERE email = ANY(%s)
                )
                  AND plan_date BETWEEN '2026-05-17' AND '2026-05-25'
                ORDER BY user_id, plan_date
                """,
                (list(EMAILS),),
            )
            run(
                cur,
                "E. Past-date orphans (is_completed=false, scheduled_date<today)",
                """
                SELECT scheduled_date::date AS d, count(*) AS n
                FROM workouts
                WHERE user_id IN (
                    SELECT id FROM users WHERE email = ANY(%s)
                )
                  AND is_completed = false
                  AND scheduled_date < now()::date
                GROUP BY 1 ORDER BY 1 DESC LIMIT 30
                """,
                (list(EMAILS),),
            )


if __name__ == "__main__":
    main()
