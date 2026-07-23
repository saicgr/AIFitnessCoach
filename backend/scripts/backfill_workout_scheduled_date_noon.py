"""Normalize legacy `workouts.scheduled_date` rows to the canonical NOON anchor.

Canonical convention (see CLAUDE.md "Local-day windows"): `workouts.scheduled_date`
is a timestamptz stored at NOON of the workout's day — noon-local via
`target_date_to_utc_iso(date, tz)`, or noon-UTC when a writer had no tz. Noon is
chosen because a noon anchor lands inside its own local-day midnight-to-midnight
window in EVERY realistic timezone, so day-window reads never mis-day a workout.

The bug this repairs: older writers (bare-date swap, AI-import) wrote
`f"{date}T00:00:00+00:00"` — MIDNIGHT UTC. A tz-aware day-window read
(`local_day_bounds`) for a user west of UTC starts at (e.g.) 05:00Z, so a
00:00Z row falls into the PREVIOUS local day's window and the workout vanishes
from "today". Shifting 00:00:00Z -> 12:00:00Z on the SAME UTC calendar date is a
zero-day-movement fix: it never changes which date the row represents (noon is
the same UTC date as midnight), and it makes the row robust to both UTC-day and
tz-aware readers.

Scope: ONLY rows at exactly 00:00:00 UTC. Rows already at noon-local/noon-UTC are
left untouched (they're canonical). Rows at arbitrary created-at times are legacy
`now()` stamps that already read correctly under the UTC-day-window readers and
are NOT moved (re-anchoring them could shift the apparent local day).

Usage:
    cd backend && set -a && source ./.env && set +a
    .venv/bin/python scripts/backfill_workout_scheduled_date_noon.py          # dry-run
    .venv/bin/python scripts/backfill_workout_scheduled_date_noon.py --apply  # write
"""
import argparse
import os
import sys

from supabase import create_client


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry-run)")
    args = ap.parse_args()

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_KEY")
    if not url or not key:
        print("❌ SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not in env", file=sys.stderr)
        return 2
    client = create_client(url, key)

    # Fetch candidate rows: scheduled_date at exactly midnight UTC. PostgREST
    # can't express "time-of-day == 00:00:00", so pull id+scheduled_date and
    # filter in Python. PostgREST caps a page at 1000, so paginate — there are
    # more than 1000 workouts and the midnight rows are scattered throughout.
    rows = []
    page = 0
    PAGE = 1000
    while True:
        batch = (
            client.table("workouts")
            .select("id, scheduled_date")
            .not_.is_("scheduled_date", "null")
            .order("id")
            .range(page * PAGE, page * PAGE + PAGE - 1)
            .execute()
            .data
            or []
        )
        rows.extend(batch)
        if len(batch) < PAGE:
            break
        page += 1

    targets = []
    for r in rows:
        sd = str(r.get("scheduled_date") or "")
        # Normalize the stored form to compare the UTC time-of-day. Rows are
        # stored as e.g. "2026-05-22T00:00:00+00:00" or "...Z".
        norm = sd.replace("Z", "+00:00")
        # Everything after the date is the time+offset; midnight-UTC rows carry
        # "T00:00:00+00:00" (or "T00:00:00.000000+00:00").
        if "T00:00:00" in norm and (norm.endswith("+00:00") or "+00:00" in norm):
            # Guard: only when the OFFSET is +00:00 AND the clock is 00:00:00.
            time_part = norm.split("T", 1)[1] if "T" in norm else ""
            if time_part.startswith("00:00:00") and "+00:00" in time_part:
                day = norm.split("T", 1)[0]  # 'YYYY-MM-DD'
                targets.append((r["id"], sd, f"{day}T12:00:00+00:00"))

    print(f"Found {len(targets)} midnight-UTC workout(s) to re-anchor to noon.")
    for wid, old, new in targets:
        print(f"  {wid}  {old}  ->  {new}")

    if not args.apply:
        print("\n(dry-run — pass --apply to write)")
        return 0

    for wid, _old, new in targets:
        client.table("workouts").update({"scheduled_date": new}).eq("id", wid).execute()
    print(f"\n✅ Re-anchored {len(targets)} row(s) to noon UTC.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
