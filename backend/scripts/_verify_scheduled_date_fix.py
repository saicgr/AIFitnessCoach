"""Verify the scheduled_date storage + /today safety net fix end-to-end
WITHOUT running the HTTP server. Checks four invariants:

1. target_date_to_utc_iso for CDT user → noon-local-converted-to-UTC
   (a date stored this way reads back as the SAME day in CDT)
2. A noon-UTC stored row does NOT match Wed's CDT [day_start, day_end]
   window when its date is Thursday (the original bug)
3. A bare-YYYY-MM-DD storage WOULD have polluted the Wed window
   (regression baseline — proves the fix matters)
4. live DB state for reviewer@zealova.com on 2026-05-20 returns
   today_rows=[] in CDT (post-migration assertion)
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # type: ignore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from datetime import datetime
from zoneinfo import ZoneInfo

import psycopg2  # type: ignore
from psycopg2.extras import RealDictCursor  # type: ignore

from core.timezone_utils import target_date_to_utc_iso, local_date_to_utc_range


CDT = "America/Chicago"


def assert_eq(label, got, want):
    ok = got == want
    print(f"  {'✅' if ok else '❌'} {label}: got={got!r} want={want!r}")
    if not ok:
        sys.exit(2)


def in_window(ts_iso: str, start_iso: str, end_iso: str) -> bool:
    ts = datetime.fromisoformat(ts_iso.replace("Z", "+00:00"))
    s = datetime.fromisoformat(start_iso.replace("Z", "+00:00"))
    e = datetime.fromisoformat(end_iso.replace("Z", "+00:00"))
    return s <= ts <= e


def main() -> None:
    print("\n[1] target_date_to_utc_iso for CDT user storing 'Thu 2026-05-21'")
    stored = target_date_to_utc_iso("2026-05-21", CDT)
    # noon CDT on May 21 = 17:00 UTC on May 21
    # noon CDT = 17:00 UTC; helper returns the UTC isoformat
    assert_eq("stored timestamp", stored, "2026-05-21T17:00:00+00:00")

    print("\n[2] CDT 'today=Wed May 20' window does NOT match the new Thu row")
    wed_start, wed_end = local_date_to_utc_range("2026-05-20", CDT)
    print(f"     wed window UTC = [{wed_start}, {wed_end}]")
    print(f"     thu row stored = {stored}")
    assert_eq("noon-CDT Thu row in Wed window", in_window(stored, wed_start, wed_end), False)

    print("\n[3] Regression baseline: bare YYYY-MM-DD = midnight UTC WOULD match Wed window")
    legacy = "2026-05-21T00:00:00+00:00"
    assert_eq("legacy midnight-UTC Thu row in Wed window", in_window(legacy, wed_start, wed_end), True)

    print("\n[4] CDT 'today=Thu May 21' window matches the new Thu row")
    thu_start, thu_end = local_date_to_utc_range("2026-05-21", CDT)
    print(f"     thu window UTC = [{thu_start}, {thu_end}]")
    assert_eq("noon-CDT Thu row in Thu window", in_window(stored, thu_start, thu_end), True)

    print("\n[5] Live DB: reviewer@zealova.com Wed 2026-05-20 (CDT) — today_rows must be empty")
    url = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://", 1)
    with psycopg2.connect(url, cursor_factory=RealDictCursor) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, name, scheduled_date
                FROM workouts
                WHERE user_id = %s
                  AND scheduled_date >= %s AND scheduled_date <= %s
                  AND is_completed = false
                """,
                ("d8f9677f-3cda-413b-8df7-0bb0035f69b1", wed_start, wed_end),
            )
            rows = cur.fetchall()
    assert_eq("today_rows count for zealova reviewer on Wed 2026-05-20 (CDT)", len(rows), 0)

    print("\n[6] Tomorrow's row should now be cleanly in Thu's window")
    with psycopg2.connect(url, cursor_factory=RealDictCursor) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, name, scheduled_date
                FROM workouts
                WHERE user_id = %s
                  AND scheduled_date >= %s AND scheduled_date <= %s
                  AND is_completed = false
                """,
                ("d8f9677f-3cda-413b-8df7-0bb0035f69b1", thu_start, thu_end),
            )
            rows = cur.fetchall()
            for r in rows:
                print(f"     thu_match: {dict(r)}")
    assert_eq("thu_rows includes the Birthday Blitz Lower", any("Birthday Blitz Lower" == r["name"] for r in rows), True)

    print("\nAll invariants hold. ✅")


if __name__ == "__main__":
    main()
