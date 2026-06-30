#!/usr/bin/env python3
"""
Build a brand-new curated program from SONNET-AUTHORED content (NO Gemini).

This is the ingest + derive + publish harness behind the `program-builder` agent.
A Sonnet author swarm produces ONE expert PRIMARY variant (intended weeks ×
sessions, all weeks, library-only exercise names). This harness then:
  1. validates every exercise resolves to a real library row (delegate to the
     reviewer for judgment; here we hard-fail on unresolved as a backstop),
  2. creates the dedicated branded base + the PRIMARY variant and ingests its
     weeks (reusing generate_programs.ingest helpers — the volume-floor top-up +
     validate_week fire automatically),
  3. DERIVES the rest of the (weeks × sessions × intensity) matrix deterministically
     ("author one, derive the rest") and ingests every derived week,
  4. backfills programs.variant_base_id / default_variant_id,
  5. creates + publishes the `programs` row with a NON-EMPTY workouts blob
     (the primary's representative week) so has_workouts computes true.

Input spec JSON (authored by the swarm + orchestrator):
{
  "program": {
     "slug","program_name","editorial_name","tagline","description",
     "who_for","who_not_for","equipment_summary","progression_note","goals":[...],
     "program_category","program_subcategory","difficulty_level",
     "duration_weeks","sessions_per_week","session_duration_minutes",
     "is_circuit": false
  },
  "primary_weeks": [ {week, phase, focus, workouts:[{workout_name,type,duration_minutes,
                      exercises:[{name,exercise_id,sets,reps,rest_seconds,duration_seconds,
                      tracking_type,equipment,body_part,primary_muscle,difficulty,
                      superset_group}]}]} , ... ]
}

Usage: python3 scripts/program_build.py spec.json [--dry-run] [--no-publish]
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))
from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

import generate_programs as gp  # noqa: E402  (reuse model-agnostic ingest helpers)
from services.program_session_filler import fill_thin_sessions  # noqa: E402

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# The matrix we ship for new programs (smaller than the old Gemini 18-cell, still
# gives week/session/intensity selection). Express programs cap weeks at <=4.
INTENSITIES = ["Easy", "Medium", "Hard"]


def _sb():
    from supabase import create_client
    return create_client(SUPABASE_URL, SUPABASE_KEY)


# ---------------------------------------------------------------------------
# Exercise resolution backstop (the reviewer is the real gate; this catches leaks)
# ---------------------------------------------------------------------------
def assert_all_resolve(sb, primary_weeks: List[Dict[str, Any]]) -> None:
    names = sorted({(e.get("name") or "").strip()
                    for w in primary_weeks for s in w.get("workouts", [])
                    for e in s.get("exercises", []) if (e.get("name") or "").strip()})
    bad = []
    for n in names:
        r = sb.rpc("resolve_exercise_demo_media", {"p_name": n}).execute().data
        has_media = bool(r) and any((row.get("image_s3_path") or row.get("video_s3_path")
                                     or row.get("image_url") or row.get("gif_url"))
                                    for row in (r if isinstance(r, list) else [r]))
        if not has_media:
            bad.append(n)
    if bad:
        raise SystemExit(f"❌ {len(bad)} exercises do not resolve to media (reviewer "
                         f"should have fixed these): {bad[:15]}")
    print(f"✅ all {len(names)} distinct exercises resolve to library media")


# ---------------------------------------------------------------------------
# The deterministic variant deriver — "author one, derive the rest"
# ---------------------------------------------------------------------------
def _bump_reps(reps: Any, delta: int) -> Any:
    """Nudge a numeric rep target; leave time/distance strings untouched."""
    if isinstance(reps, int):
        return max(1, reps + delta)
    s = str(reps or "")
    if s.isdigit():
        return str(max(1, int(s) + delta))
    return reps  # "30 seconds", "8-12", "AMRAP" -> unchanged


def scale_intensity(week: Dict[str, Any], level: str) -> Dict[str, Any]:
    """Easy: -1 set / +2 reps / +rest. Hard: +1 set / -2 reps / -rest. Rep-based
    only — NEVER scale a timed/distance conditioning move."""
    if level == "Medium":
        return week
    import copy
    wk = copy.deepcopy(week)
    for w in wk.get("workouts", []):
        for ex in w.get("exercises", []):
            tt = (ex.get("tracking_type") or "").lower()
            if tt in ("time", "distance") or "second" in str(ex.get("reps", "")).lower():
                continue
            try:
                sets = int(ex.get("sets") or 3)
            except (TypeError, ValueError):
                continue
            if level == "Easy":
                ex["sets"] = max(2, sets - 1)
                ex["reps"] = _bump_reps(ex.get("reps"), +2)
                ex["rest_seconds"] = int(ex.get("rest_seconds") or 60) + 15
            elif level == "Hard":
                ex["sets"] = sets + 1
                ex["reps"] = _bump_reps(ex.get("reps"), -2)
                ex["rest_seconds"] = max(45, int(ex.get("rest_seconds") or 60) - 15)
    return wk


def map_weeks(primary: List[Dict[str, Any]], target_weeks: int) -> List[Dict[str, Any]]:
    """Phase-aware truncate/extend. Keeps week 1 (intro), the final (peak) week,
    proportionally-spaced middle weeks, and any deload week when room allows."""
    import copy
    N = len(primary)
    if target_weeks == N:
        out = copy.deepcopy(primary)
    elif target_weeks < N:
        keep_idx = {0, N - 1}
        # retain a deload if present and we have >=4 weeks of room
        if target_weeks >= 4:
            for i, wk in enumerate(primary):
                if "deload" in (str(wk.get("phase", "")) + str(wk.get("focus", ""))).lower():
                    keep_idx.add(i)
        # fill the rest with proportionally-spaced middle weeks
        i = 0
        while len(keep_idx) < target_weeks and i < N:
            keep_idx.add(round(i * (N - 1) / max(1, target_weeks - 1)))
            i += 1
        out = [copy.deepcopy(primary[i]) for i in sorted(keep_idx)][:target_weeks]
    else:  # extend: tile the accumulation block (skip intro/peak), re-insert deloads
        mid = primary[1:-1] or primary
        out = [copy.deepcopy(primary[0])]
        k = 0
        while len(out) < target_weeks - 1:
            out.append(copy.deepcopy(mid[k % len(mid)]))
            k += 1
        out.append(copy.deepcopy(primary[-1]))
    for i, wk in enumerate(out):
        wk["week"] = i + 1
    return out


def map_sessions(week: Dict[str, Any], target_sessions: int) -> Dict[str, Any]:
    """Drop lowest-priority sessions or clone-and-append. Thin synthesized days are
    backfilled to the volume floor by the ingest wrapper (fill_thin_sessions)."""
    import copy
    wk = copy.deepcopy(week)
    workouts = wk.get("workouts", [])
    S = len(workouts)
    if target_sessions == S or S == 0:
        return wk
    if target_sessions < S:
        wk["workouts"] = workouts[:target_sessions]  # keep first (primary) days
    else:
        for i in range(target_sessions - S):
            clone = copy.deepcopy(workouts[i % S])
            clone["workout_name"] = f"{clone.get('workout_name','Day')} (Volume {i+1})"
            wk["workouts"].append(clone)
    return wk


def _topup_week(workouts: List[Dict[str, Any]], session_minutes: int) -> List[Dict[str, Any]]:
    """Top thin/non-exempt sessions up to the duration floor with library-resolved,
    equipment-gated accessories (reuses the shared filler). Equipment = union of the
    week's existing exercise equipment (+ bodyweight), so a bodyweight program never
    gets gym gear. Best-effort + sync wrapper around the async filler."""
    import asyncio
    import re
    eq = set()
    for s in workouts or []:
        for e in (s.get("exercises") or []):
            val = (e.get("equipment") or "").strip().lower()
            if val:
                eq.update(p.strip() for p in re.split(r"[/,]| or | and ", val))
    eq = sorted({x for x in eq if x} | {"bodyweight", "none"})
    try:
        res = asyncio.run(fill_thin_sessions(workouts, equipment=eq,
                                             difficulty_ceiling="intermediate"))
        return res["workouts"]
    except Exception:
        return workouts


def build_matrix(duration_weeks: int, sessions_per_week: int, is_express: bool):
    weeks = sorted({1, 2, 4, duration_weeks} if is_express
                   else {1, 2, 4, 8, 12, duration_weeks})
    weeks = [w for w in weeks if (w <= 4 if is_express else w <= 12) and w >= 1]
    sessions = sorted({s for s in {3, 4, 5, sessions_per_week} if 2 <= s <= 6})
    return weeks, sessions


def derive_and_ingest(sb, base_id: str, prog_dict: Dict[str, Any],
                      primary: List[Dict[str, Any]],
                      duration_weeks: int, sessions_per_week: int,
                      session_minutes: int, is_express: bool) -> int:
    weeks_axis, sessions_axis = build_matrix(duration_weeks, sessions_per_week, is_express)
    n_cells = 0
    for weeks in weeks_axis:
        wk_mapped = map_weeks(primary, weeks)
        for sessions in sessions_axis:
            for intensity in INTENSITIES:
                cell = [map_sessions(scale_intensity(w, intensity), sessions)
                        for w in wk_mapped]
                vname = f"{prog_dict['name']} — {weeks}w/{sessions}d/{intensity}"
                vid = gp.create_variant_record(
                    sb, base_id, {**prog_dict, "name": vname}, weeks, sessions)
                if not vid:
                    continue
                # stamp the real session duration + intensity on the variant row
                sb.table("program_variants").update({
                    "session_duration_minutes": session_minutes,
                    "intensity_level": intensity,
                }).eq("id", vid).execute()
                for w in cell:
                    # Guarantee the per-session volume floor (raw gp.ingest does
                    # NOT run the top-up the Gemini wrapper does). Equipment derived
                    # from the week so a bodyweight program stays bodyweight.
                    workouts = _topup_week(w["workouts"], session_minutes)
                    gp.ingest_week_to_supabase(
                        sb, vid, w["week"],
                        {"week": w["week"], "phase": w.get("phase"),
                         "focus": w.get("focus"), "workouts": workouts},
                        {"name": prog_dict["name"]})
                n_cells += 1
    return n_cells


# ---------------------------------------------------------------------------
# Publish the programs row (NON-EMPTY workouts blob -> has_workouts true)
# ---------------------------------------------------------------------------
def publish_program(sb, spec_prog: Dict[str, Any], base_id: str,
                    primary: List[Dict[str, Any]], publish: bool) -> str:
    rep_week = primary[0]
    blob = {"workouts": rep_week["workouts"]}
    row = {
        "program_name": spec_prog["program_name"],
        "editorial_name": spec_prog.get("editorial_name"),
        "tagline": spec_prog.get("tagline"),
        "description": spec_prog.get("description"),
        "who_for": spec_prog.get("who_for"),
        "who_not_for": spec_prog.get("who_not_for"),
        "equipment_summary": spec_prog.get("equipment_summary"),
        "progression_note": spec_prog.get("progression_note"),
        "goals": spec_prog.get("goals") or [],
        "program_category": spec_prog["program_category"],
        "program_subcategory": spec_prog.get("program_subcategory"),
        "difficulty_level": spec_prog.get("difficulty_level"),
        "duration_weeks": spec_prog["duration_weeks"],
        "sessions_per_week": spec_prog["sessions_per_week"],
        "session_duration_minutes": spec_prog["session_duration_minutes"],
        "workouts": blob,
        "has_workouts": True,
        "is_published": bool(publish),
    }
    existing = (sb.table("programs").select("id")
                .eq("program_name", spec_prog["program_name"]).execute().data)
    if existing:
        pid = existing[0]["id"]
        sb.table("programs").update(row).eq("id", pid).execute()
    else:
        pid = sb.table("programs").insert(row).execute().data[0]["id"]
    # link variant base + default (intended cell)
    from generate_curated_variants import backfill_programs_columns
    backfill_programs_columns(pid, base_id, spec_prog["duration_weeks"],
                              spec_prog["sessions_per_week"])
    return pid


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec", help="path to the program spec JSON")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-publish", action="store_true")
    args = ap.parse_args()

    spec = json.loads(Path(args.spec).read_text())
    prog = spec["program"]
    primary = spec["primary_weeks"]
    is_express = bool(prog.get("session_duration_minutes", 60) <= 15)

    sb = _sb()
    print(f"▶ Building '{prog['program_name']}' ({prog['program_category']}, "
          f"{prog['duration_weeks']}w/{prog['sessions_per_week']}d/"
          f"{prog['session_duration_minutes']}min, {len(primary)} authored weeks)")
    assert_all_resolve(sb, primary)
    if args.dry_run:
        weeks_axis, sessions_axis = build_matrix(
            prog["duration_weeks"], prog["sessions_per_week"], is_express)
        print(f"   would derive {len(weeks_axis)*len(sessions_axis)*3} variant cells "
              f"(weeks={weeks_axis} × sessions={sessions_axis} × {INTENSITIES})")
        return

    prog_dict = {"name": f"{prog['editorial_name']} (Zealova Library)",
                 "category": prog["program_category"],
                 "description": prog.get("description") or prog.get("tagline"),
                 "goals": prog.get("goals") or [], "has_supersets": False}
    base_id = gp.get_or_create_branded_program(sb, prog_dict)
    print(f"   branded base: {base_id}")
    n = derive_and_ingest(sb, base_id, prog_dict, primary,
                          prog["duration_weeks"], prog["sessions_per_week"],
                          prog["session_duration_minutes"], is_express)
    print(f"   ingested {n} variant cells (incl. primary)")
    pid = publish_program(sb, prog, base_id, primary, publish=not args.no_publish)
    print(f"   ✅ program {pid} {'PUBLISHED' if not args.no_publish else 'built (unpublished)'}")


if __name__ == "__main__":
    main()
