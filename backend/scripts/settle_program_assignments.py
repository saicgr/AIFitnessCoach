#!/usr/bin/env python3
"""Program-assignment progress + lifecycle repair / gate (E2E register row 54).

Recomputes `user_program_assignments` progress from the assignment's `workouts`
rows and settles assignments whose scheduled window has fully elapsed, using the
same SQL chokepoints migration 2372 installed (so this script and the runtime
trigger can never disagree).

    # report only (exit 1 if any assignment is stale / unbounded)
    .venv/bin/python scripts/settle_program_assignments.py --check

    # repair
    .venv/bin/python scripts/settle_program_assignments.py --apply

Why a gate: an assignment that stays `is_active AND status='active'` after its
last scheduled workout has passed suppresses AI workout generation on its
weekdays FOREVER (api/v1/workouts/today.py `_assignment_covered_weekdays`).
"""
from __future__ import annotations

import argparse
import os
import sys

import psycopg2

STALE_SQL = """
SELECT a.id, a.user_id, a.custom_program_name, a.status, a.is_active,
       a.progress_percentage, a.workouts_completed, a.total_workouts,
       COUNT(w.id)                                   AS real_total,
       COUNT(w.id) FILTER (WHERE w.is_completed)     AS real_done,
       MAX(w.scheduled_date)::date                   AS last_scheduled,
       a.assigned_days
FROM user_program_assignments a
LEFT JOIN workouts w ON w.assignment_id = a.id
GROUP BY a.id
HAVING
    -- counters out of sync with the workouts they are derived from
    a.workouts_completed IS DISTINCT FROM COUNT(w.id) FILTER (WHERE w.is_completed)
 OR a.total_workouts     IS DISTINCT FROM COUNT(w.id)
    -- or an active assignment with no plan left on the calendar
 OR (a.status IN ('active','paused')
     AND ((COUNT(w.id) > 0 AND MAX(w.scheduled_date) < date_trunc('day', now()))
       OR (COUNT(w.id) = 0 AND a.started_at < date_trunc('day', now()))))
ORDER BY a.created_at DESC
"""


def _dsn() -> str:
    dsn = os.environ.get("DATABASE_URL", "")
    if not dsn:
        print("DATABASE_URL is not set", file=sys.stderr)
        sys.exit(2)
    dsn = dsn.replace("postgresql+asyncpg://", "postgresql://")
    if "sslmode" not in dsn:
        dsn += ("&" if "?" in dsn else "?") + "sslmode=require"
    return dsn


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="report stale assignments; exit 1 if any")
    ap.add_argument("--apply", action="store_true",
                    help="recompute progress + settle elapsed assignments")
    args = ap.parse_args()
    if not args.check and not args.apply:
        args.check = True

    conn = psycopg2.connect(_dsn())
    conn.autocommit = False
    try:
        with conn.cursor() as cur:
            cur.execute(STALE_SQL)
            stale = cur.fetchall()
            print(f"stale assignments: {len(stale)}")
            for r in stale:
                print(f"  {r[0]} '{r[2]}' status={r[3]} active={r[4]} "
                      f"progress={r[5]}% counted={r[6]}/{r[7]} "
                      f"actual={r[9]}/{r[8]} last={r[10]} days={r[11]}")

            if args.apply:
                cur.execute(
                    "SELECT public.program_assignment_progress_sync(NULL)"
                )
                synced = cur.fetchone()[0]
                cur.execute(
                    "SELECT public.program_assignment_settle_elapsed(NULL)"
                )
                settled = cur.fetchone()[0]
                conn.commit()
                print(f"progress rows updated: {synced}")
                print(f"elapsed assignments settled: {settled}")
                cur.execute(STALE_SQL)
                left = cur.fetchall()
                print(f"stale after repair: {len(left)}")
                return 1 if left else 0
        return 1 if stale else 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
