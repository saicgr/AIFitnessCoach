"""
Migration 2406 — plain-language day titles for "30-Day Plank Challenge".

Row 111 (2026-08 backend prompt sweep): Program detail -> SCHEDULE tab
session titles are cryptic numeric shorthand — "DAY 5 — 40S + SIDE",
"DAY 7 — 50S + TAPS", "DAY 26 — 150S + SIDE", "DAY 30 — FINAL 180S TEST".

Root cause: this program (id 6e9539c2-feef-497d-9d0b-8c499838d2f8) has
`programs.variant_base_id IS NULL` — it was never expanded into
`program_variants`/`program_variant_weeks`, so it schedules directly from
the `programs.workouts` BASE BLOB (CLAUDE.md: "curated program scheduling —
from program_variant_weeks NOT base blob" documents the general rule; this
program is the exception that proves it, and it's exactly why
`scripts/audit_program_copy_clarity.py` / `rewrite_program_copy_plain_language.py`
(which only scan `program_variant_weeks`) never saw these 30 titles at all.

Fix: deterministic (no LLM) rewrite of every `workout_name` in the 30-day
array — "Xs" -> "X-second hold", "+ Side"/"+ Taps" expanded to the actual
exercise added that day (side plank / shoulder taps, verified against each
day's `exercises` list), "Final Xs Test" -> "Final X-second hold test".
"Rest" days are untouched.

Run (dry run by default, prints before/after for every changed title):
    cd backend && .venv312/bin/python migrations/2409_plank_challenge_plain_titles.py
    cd backend && .venv312/bin/python migrations/2409_plank_challenge_plain_titles.py --apply

NOT applied by this sweep — per the task rule ("write a migration, say it
needs applying, do not apply it yourself"), this has only been run in
dry-run mode to verify the transform against the real live row.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

PROGRAM_ID = "6e9539c2-feef-497d-9d0b-8c499838d2f8"  # "30-Day Plank Challenge"

_REST_RE = re.compile(r"^Day (\d+) — Rest$")
_FINAL_RE = re.compile(r"^Day (\d+) — Final (\d+)s Test$")
_FOUNDATION_RE = re.compile(r"^Day (\d+) — Foundation (\d+)s$")
_PLUS_RE = re.compile(r"^Day (\d+) — (\d+)s \+ (Side|Taps)$")
_PLAIN_RE = re.compile(r"^Day (\d+) — (\d+)s$")

_PLUS_LABEL = {"Side": "side plank", "Taps": "shoulder taps"}


def rewrite_day_title(title: str) -> str:
    """Plain-language rewrite of one plank-challenge day title. Returns the
    input unchanged if it doesn't match a recognized shape (never guesses)."""
    if not isinstance(title, str):
        return title

    m = _REST_RE.match(title)
    if m:
        return title  # "Day N — Rest" is already plain.

    m = _FINAL_RE.match(title)
    if m:
        day, secs = m.groups()
        return f"Day {day} — Final {secs}-second hold test"

    m = _FOUNDATION_RE.match(title)
    if m:
        day, secs = m.groups()
        return f"Day {day} — {secs}-second hold (building the habit)"

    m = _PLUS_RE.match(title)
    if m:
        day, secs, extra = m.groups()
        return f"Day {day} — {secs}-second hold + {_PLUS_LABEL[extra]}"

    m = _PLAIN_RE.match(title)
    if m:
        day, secs = m.groups()
        return f"Day {day} — {secs}-second hold"

    return title


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from core.supabase_client import get_supabase  # noqa: E402

    db = get_supabase()
    row = db.client.table("programs").select("id, editorial_name, workouts").eq(
        "id", PROGRAM_ID
    ).execute().data
    if not row:
        print(f"Program {PROGRAM_ID} not found — nothing to do.")
        return 0
    row = row[0]
    blob = row.get("workouts") or {}
    sessions = (blob.get("workouts") or [])
    if not sessions:
        print("No workouts[] array in the base blob — nothing to do.")
        return 0

    changed = 0
    for sess in sessions:
        old = sess.get("workout_name")
        new = rewrite_day_title(old)
        if new != old:
            changed += 1
            print(f"  {old!r} -> {new!r}")
            sess["workout_name"] = new

    print(f"{changed} of {len(sessions)} titles would change.")
    if not args.apply:
        print("Dry run — pass --apply to write.")
        return 0

    db.client.table("programs").update({"workouts": blob}).eq("id", PROGRAM_ID).execute()
    print("Applied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
