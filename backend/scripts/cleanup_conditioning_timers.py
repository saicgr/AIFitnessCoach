#!/usr/bin/env python3
"""
Normalize CONTINUOUS-CARDIO / conditioning moves in curated programs to timers.

WHY (2026-06-30): some curated programs author conditioning moves (Mountain
Climber, Jumping Jacks, Plank Jacks, Flutter Kicks…) with a bare REP number
(e.g. "Mountain Climber x 120"), which renders as a rep counter instead of a
timer. These are continuous-effort moves — a timer is the correct metric. This
rewrites ONLY a tight whitelist of continuous-cardio moves that carry a bare rep
count into a clean timed form (reps "Ns" + duration_seconds + tracking_type:time
+ is_timed), so the active-workout screen shows a countdown.

DELIBERATELY EXCLUDED (these stay reps): strength/plyo moves that are legitimately
counted — box/squat/broad jumps, skater SQUATS/lunges, Pilates "The Hundred",
burpees (often counted), and anything already authored as "X seconds".

Scope: published curated programs — both the programs.workouts base blob (fixed
programs) and every program_variant_weeks.workouts row of their variants.

Run: python3 scripts/cleanup_conditioning_timers.py [--apply]   (dry-run default)
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))
from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Tight whitelist: CONTINUOUS-cardio / conditioning moves only. A timer is the
# right metric for these. NOTE the negative guards — "skater squat", "squat jump",
# "box jump", "broad jump" are rep-based and must NOT match.
_COND_RE = re.compile(
    r"(mountain climber|high knee|butt kick|fast feet|jumping jack|jump rope|"
    r"jumping rope|skipping rope|plank jack|seal jack|cross jack|star jump|"
    r"running in place|sprint in place|jog in place|flutter kick|scissor kick|"
    r"bear crawl|shadow box|in and out|in-and-out)", re.I)
_EXCLUDE_RE = re.compile(
    r"(skater squat|skater lunge|squat jump|box jump|broad jump|burpee|"
    r"the hundred|pilates)", re.I)

DEFAULT_SECONDS = 40   # standard conditioning interval when none is authored


def _is_bare_reps(reps) -> bool:
    """True when reps is a plain rep COUNT >=2 (not already 'X seconds')."""
    if reps is None:
        return False
    s = str(reps).strip().lower()
    if "second" in s or "sec" in s or "min" in s:
        return False
    return bool(re.fullmatch(r"\d+", s)) and int(s) >= 2


def _retime(ex: dict) -> bool:
    """Mutate one exercise into a clean timed form. Returns True if it changed."""
    name = ex.get("name") or ex.get("exercise_name") or ""
    if not _COND_RE.search(name) or _EXCLUDE_RE.search(name):
        return False
    if not _is_bare_reps(ex.get("reps")):
        return False  # already timed / not a bare count -> idempotent no-op
    try:
        dur = int(ex.get("duration_seconds") or 0)
    except (TypeError, ValueError):
        dur = 0
    if dur <= 0:
        dur = DEFAULT_SECONDS
    ex["reps"] = f"{dur} seconds"
    ex["duration_seconds"] = dur
    ex["tracking_type"] = "time"
    ex["is_timed"] = True
    return True


def _walk_sessions(workouts) -> int:
    """workouts = list of session dicts; retime in place. Returns #changed."""
    changed = 0
    for s in (workouts or []):
        for e in (s.get("exercises") or []):
            if _retime(e):
                changed += 1
    return changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="persist (default dry-run)")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()
    from supabase import create_client
    sb = create_client(SUPABASE_URL, SUPABASE_KEY)

    progs = (sb.table("programs")
             .select("id, program_name, workouts, variant_base_id")
             .eq("is_published", True).execute().data or [])
    total_changed = 0
    rows_touched = 0
    per_prog = {}

    for p in progs:
        pname = p["program_name"]
        pc = 0
        # 1) base blob (fixed programs)
        blob = p.get("workouts") or {}
        sessions = blob.get("workouts") if isinstance(blob, dict) else blob
        if sessions:
            c = _walk_sessions(sessions)
            if c:
                pc += c
                rows_touched += 1
                if args.apply:
                    sb.table("programs").update({"workouts": blob}).eq("id", p["id"]).execute()
        # 2) variant weeks
        if p.get("variant_base_id"):
            vids = [v["id"] for v in (sb.table("program_variants").select("id")
                    .eq("base_program_id", p["variant_base_id"]).execute().data or [])]
            for i in range(0, len(vids), 50):
                chunk = vids[i:i + 50]
                start = 0
                while True:
                    r = (sb.table("program_variant_weeks").select("id, workouts")
                         .in_("variant_id", chunk).range(start, start + 499).execute())
                    batch = r.data or []
                    for wr in batch:
                        c = _walk_sessions(wr.get("workouts") or [])
                        if c:
                            pc += c
                            rows_touched += 1
                            if args.apply:
                                (sb.table("program_variant_weeks")
                                 .update({"workouts": wr["workouts"]})
                                 .eq("id", wr["id"]).execute())
                    if len(batch) < 500:
                        break
                    start += 500
        if pc:
            per_prog[pname] = pc
            total_changed += pc

    print(f"\n{'APPLIED' if args.apply else 'DRY-RUN'} — conditioning moves retimed")
    for nm, c in sorted(per_prog.items(), key=lambda x: -x[1]):
        print(f"  {c:6}  {nm}")
    print(f"  ------\n  {total_changed} exercise instances across {rows_touched} rows")
    if not args.apply:
        print("\n  (dry-run — nothing written. Re-run with --apply.)")


if __name__ == "__main__":
    main()
