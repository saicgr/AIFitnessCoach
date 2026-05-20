"""Run the /today endpoint's core query path against the live DB to see what
it returns for reviewer@zealova.com on 2026-05-20 — without HTTP/auth.

Replicates today.py's today_rows + future_rows queries.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # type: ignore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import psycopg2  # type: ignore
from psycopg2.extras import RealDictCursor  # type: ignore


USER_ID = "d8f9677f-3cda-413b-8df7-0bb0035f69b1"  # reviewer@zealova.com
USER_TZ_VARIANTS = ["America/Chicago", "UTC"]  # try both


def local_date_to_utc_range(date_str: str, tz_str: str) -> tuple[str, str]:
    tz = ZoneInfo(tz_str)
    y, m, d = int(date_str[:4]), int(date_str[5:7]), int(date_str[8:10])
    start = datetime(y, m, d, 0, 0, 0, tzinfo=tz).astimezone(ZoneInfo("UTC"))
    end = datetime(y, m, d, 23, 59, 59, tzinfo=tz).astimezone(ZoneInfo("UTC"))
    return start.isoformat(), end.isoformat()


def main() -> None:
    url = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://", 1)
    with psycopg2.connect(url, cursor_factory=RealDictCursor) as conn:
        with conn.cursor() as cur:
            for tz_str in USER_TZ_VARIANTS:
                for today_str in ["2026-05-20"]:
                    start, end = local_date_to_utc_range(today_str, tz_str)
                    print(f"\n=== tz={tz_str} today_str={today_str} ===")
                    print(f"window = [{start}, {end}]")

                    cur.execute(
                        """
                        SELECT id, name, scheduled_date, is_completed,
                               gym_profile_id, is_current
                        FROM workouts
                        WHERE user_id = %s
                          AND scheduled_date >= %s
                          AND scheduled_date <= %s
                          AND is_completed = false
                        ORDER BY scheduled_date
                        """,
                        (USER_ID, start, end),
                    )
                    rows = cur.fetchall()
                    print("today_rows (is_completed=false in window):")
                    for r in rows:
                        print(" ", dict(r))

                    # future_rows: tomorrow..30d
                    tomorrow_str = (datetime.strptime(today_str, "%Y-%m-%d").date() + timedelta(days=1)).isoformat()
                    end_str = (datetime.strptime(today_str, "%Y-%m-%d").date() + timedelta(days=30)).isoformat()
                    f_start, _ = local_date_to_utc_range(tomorrow_str, tz_str)
                    _, f_end = local_date_to_utc_range(end_str, tz_str)
                    cur.execute(
                        """
                        SELECT id, name, scheduled_date, is_completed,
                               gym_profile_id, is_current
                        FROM workouts
                        WHERE user_id = %s
                          AND scheduled_date >= %s
                          AND scheduled_date <= %s
                          AND is_completed = false
                        ORDER BY scheduled_date
                        LIMIT 1
                        """,
                        (USER_ID, f_start, f_end),
                    )
                    fut = cur.fetchall()
                    print("future_rows (first, is_completed=false):")
                    for r in fut:
                        print(" ", dict(r))


if __name__ == "__main__":
    main()
