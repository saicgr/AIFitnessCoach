#!/usr/bin/env python3
"""Regression gate for #53 — editing an ACTIVE program must be a targeted
re-dating, never a destructive rewrite.

The bug: PATCH /program-templates/assignments/{id} with new `assigned_days`
used to DELETE every future incomplete workout of the assignment and re-expand
from the flat sample-week `user_program_templates.days` starting TODAY. For a
curated (variant-scheduled) program that:
  - discarded weeks 2..N of authored content (every week became week 1's),
  - restarted the program at week 1 from today,
  - stacked sessions when fewer weekdays were assigned than sessions/week,
  - and, because the re-expand ran inside a bare try/except AFTER the delete,
    left the user with NOTHING at all when it raised.

The fix (services/program_template_expander.reschedule_assignment_days) moves
the surviving rows: same content, same week number, same session ordinal, only
the calendar date changes — and never into the past.

Run:  .venv/bin/python scripts/verify_program_reschedule.py --check
Exit 0 = all assertions hold.
"""
from __future__ import annotations

import argparse
import os
import sys
from datetime import date, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.program_template_expander import (  # noqa: E402
    plan_assignment_reschedule,
    plan_variant_schedule,
)

FAILURES: list = []


def check(label: str, ok: bool, detail: str = "") -> None:
    if ok:
        print(f"  PASS  {label}")
    else:
        print(f"  FAIL  {label} :: {detail}")
        FAILURES.append(label)


def _build_rows(anchor: date, weeks: int, sessions: int, days: list) -> list:
    """Materialize what expand_variant_weeks would have written."""
    weeks_rows = [
        {
            "week_number": w,
            "workouts": [
                {"workout_name": f"W{w}S{s}", "exercises": []}
                for s in range(sessions)
            ],
        }
        for w in range(1, weeks + 1)
    ]
    plan = plan_variant_schedule(
        weeks_rows, assigned_days=days, start_date=anchor
    )
    return [
        {
            "id": f"w{p['week_number']}-s{p['session_idx']}",
            "template_week": p["week_number"],
            "template_day_index": p["session_idx"],
            "scheduled_date": p["scheduled"],
            "content": p["session"]["workout_name"],
        }
        for p in plan["planned"]
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.parse_args()

    # Mirrors the live HYROX Race Prep assignment: 8 weeks x 4 sessions,
    # anchored 2026-07-03, originally on Tue/Wed/Fri/Sat ([1,2,4,5]).
    anchor = date(2026, 7, 3)
    rows = _build_rows(anchor, weeks=8, sessions=4, days=[1, 2, 4, 5])
    print(f"baseline: {len(rows)} rows, weeks "
          f"{sorted({r['template_week'] for r in rows})}")

    # --- 1. Mid-program weekday change (today = start of week 5) -----------
    today = date(2026, 7, 31)
    future = [r for r in rows if r["scheduled_date"][:10] >= today.isoformat()]
    plan = plan_assignment_reschedule(
        future, assigned_days=[0, 3], anchor_date=anchor, today=today
    )

    check("every future row is planned (none dropped)",
          len(plan) == len(future), f"{len(plan)} vs {len(future)}")
    check("no row is deleted — the planner only emits date moves",
          all("new_scheduled" in p for p in plan))
    weeks_after = sorted({p["week"] for p in plan})
    check("weeks 5..8 survive the edit",
          weeks_after == [5, 6, 7, 8], str(weeks_after))
    per_week = {}
    for p in plan:
        per_week[p["week"]] = per_week.get(p["week"], 0) + 1
    check("each surviving week keeps all 4 sessions "
          "(no collapse to a single workout)",
          set(per_week.values()) == {4}, str(per_week))
    check("no row is moved into the past",
          all(p["new_scheduled"][:10] >= today.isoformat() for p in plan),
          str([p["new_scheduled"] for p in plan][:4]))
    # Week alignment preserved: week w still sits in its own calendar week.
    bad = [
        p for p in plan
        if not (anchor + timedelta(days=(p["week"] - 1) * 7)
                <= date.fromisoformat(p["new_scheduled"][:10])
                <= anchor + timedelta(days=(p["week"] - 1) * 7 + 6))
    ]
    check("week numbering stays aligned to the original anchor "
          "(program does not restart at week 1)", not bad,
          str([(p["week"], p["new_scheduled"][:10]) for p in bad[:4]]))
    moved_weekdays = {
        date.fromisoformat(p["new_scheduled"][:10]).weekday()
        for p in plan if p["moved"]
    }
    check("moved rows land only on the newly assigned weekdays",
          moved_weekdays <= {0, 3}, str(moved_weekdays))
    check("time of day is preserved",
          all(p["new_scheduled"][11:16] == p["old_scheduled"][11:16]
              for p in plan))

    # --- 2. Fewer weekdays than sessions/week: sessions cycle, none lost ---
    plan1 = plan_assignment_reschedule(
        future, assigned_days=[2], anchor_date=anchor, today=today
    )
    check("1 assigned day, 4 sessions/week → all 4 sessions still scheduled",
          len(plan1) == len(future), f"{len(plan1)} vs {len(future)}")

    # --- 3. Idempotency: re-applying the same days is a no-op --------------
    applied = [
        {
            "id": p["id"],
            "template_week": p["week"],
            "template_day_index": int(p["id"].split("-s")[1]),
            "scheduled_date": p["new_scheduled"],
        }
        for p in plan
    ]
    again = plan_assignment_reschedule(
        applied, assigned_days=[0, 3], anchor_date=anchor, today=today
    )
    check("re-applying the same weekdays moves nothing",
          not any(p["moved"] for p in again),
          str([p["new_scheduled"] for p in again if p["moved"]][:4]))

    # --- 4. Past + completed rows are outside the candidate set ------------
    past = [r for r in rows if r["scheduled_date"][:10] < today.isoformat()]
    check("weeks 1..4 (already elapsed) are never candidates",
          sorted({r["template_week"] for r in past}) == [1, 2, 3, 4])

    print()
    if FAILURES:
        print(f"FAILED: {len(FAILURES)} assertion(s): {FAILURES}")
        return 1
    print("OK — reschedule is targeted, non-destructive and week-aligned.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
