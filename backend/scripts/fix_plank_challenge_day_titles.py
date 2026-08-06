#!/usr/bin/env python3
"""Rewrite the 30-Day Plank Challenge's cryptic day titles into plain
language (row 111, 2026-08 backend prompt sweep).

"Day 5 — 40s + Side", "Day 7 — 50s + Taps", "Day 30 — Final 180s Test" are
`workout_name` shorthand a normal user has to decode ("s" = seconds, "Side" =
side plank, "Taps" = shoulder taps). This program is base-blob-only
(`programs.variant_base_id IS NULL`, served from `programs.workouts`), which
is why `audit_program_copy_clarity.py` never caught it before this sweep
extended that gate to scan base-blob programs too.

Hand-mapped rather than a generic regex — there are only 22 non-Rest day
titles and the "+ Side" / "+ Taps" suffixes need real English, not a
mechanical substitution ("Side" isn't a jargon WORD to translate, it's an
abbreviation of "side plank" that only makes sense in this one program's
titles). Rest-day titles ("Day 4 — Rest") are untouched — already plain.

    .venv/bin/python scripts/fix_plank_challenge_day_titles.py            # dry run
    .venv/bin/python scripts/fix_plank_challenge_day_titles.py --apply
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase  # noqa: E402

PROGRAM_ID = "6e9539c2-feef-497d-9d0b-8c499838d2f8"  # 30-Day Plank Challenge

TITLE_MAP = {
    "Day 1 — Foundation 20s": "Day 1 — Foundation: 20-second hold",
    "Day 2 — Foundation 20s": "Day 2 — Foundation: 20-second hold",
    "Day 3 — 30s": "Day 3 — 30-second hold",
    "Day 5 — 40s + Side": "Day 5 — 40-second hold + side plank",
    "Day 6 — 45s": "Day 6 — 45-second hold",
    "Day 7 — 50s + Taps": "Day 7 — 50-second hold + shoulder taps",
    "Day 9 — 60s": "Day 9 — 60-second hold",
    "Day 10 — 60s + Side": "Day 10 — 60-second hold + side plank",
    "Day 11 — 70s": "Day 11 — 70-second hold",
    "Day 13 — 80s + Taps": "Day 13 — 80-second hold + shoulder taps",
    "Day 14 — 90s": "Day 14 — 90-second hold",
    "Day 15 — 90s + Side": "Day 15 — 90-second hold + side plank",
    "Day 17 — 100s": "Day 17 — 100-second hold",
    "Day 18 — 100s + Taps": "Day 18 — 100-second hold + shoulder taps",
    "Day 19 — 110s": "Day 19 — 110-second hold",
    "Day 21 — 120s + Side": "Day 21 — 120-second hold + side plank",
    "Day 22 — 130s": "Day 22 — 130-second hold",
    "Day 23 — 140s": "Day 23 — 140-second hold",
    "Day 25 — 150s": "Day 25 — 150-second hold",
    "Day 26 — 150s + Side": "Day 26 — 150-second hold + side plank",
    "Day 27 — 160s": "Day 27 — 160-second hold",
    "Day 29 — 170s": "Day 29 — 170-second hold",
    "Day 30 — Final 180s Test": "Day 30 — Final 3-minute hold",
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    db = get_supabase()
    row = (
        db.client.table("programs")
        .select("id, workouts")
        .eq("id", PROGRAM_ID)
        .limit(1)
        .execute()
        .data
    )
    if not row:
        print("Plank Challenge program not found in this environment", file=sys.stderr)
        return 1
    blob = row[0]["workouts"]
    sessions = blob.get("workouts") if isinstance(blob, dict) else blob
    if not isinstance(sessions, list):
        print("unexpected workouts shape", file=sys.stderr)
        return 1

    changed = 0
    for s in sessions:
        old = s.get("workout_name")
        new = TITLE_MAP.get(old)
        if new and new != old:
            print(f"  {old!r} -> {new!r}")
            s["workout_name"] = new
            changed += 1

    print(f"{changed} day titles to rewrite")
    if not args.apply:
        print("dry run — pass --apply to write")
        return 0
    if changed == 0:
        print("nothing to write")
        return 0

    if isinstance(blob, dict):
        blob["workouts"] = sessions
        new_blob = blob
    else:
        new_blob = sessions
    db.client.table("programs").update({"workouts": new_blob}).eq("id", PROGRAM_ID).execute()
    print(f"wrote {changed} title changes to programs.id={PROGRAM_ID}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
