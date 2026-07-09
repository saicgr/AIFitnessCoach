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
import re
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
def _norm_name(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def assert_all_resolve(sb, primary_weeks: List[Dict[str, Any]]) -> None:
    names = sorted({(e.get("name") or "").strip()
                    for w in primary_weeks for s in w.get("workouts", [])
                    for e in s.get("exercises", []) if (e.get("name") or "").strip()})
    bad = []
    # Divergent-identity warnings (2026-07): the schedule shows an exercise's
    # authored `name`, but its exercise_id/media/detail-screen content is
    # whatever `resolve_exercise_demo_media` resolves that name to via the
    # exercise_aliases -> exercise_canonical canonical stack. When a name's
    # own canonical resolution is a SUBSTANTIALLY different exercise (not just
    # a media-matching synonym/plural — see the Ski Erg Easy / "Ski Ergometer
    # Cross Country Ski Basic Pull" incident), the schedule and detail screen
    # disagree. Not hard-failed: the resolver is a fuzzy media-matcher, so
    # trivial differences (e.g. "Burpee" vs "Burpees") are common and benign —
    # only printed for the reviewer/human to judge, same posture as
    # audit_program_exercise_name_consistency.py.
    divergent = []
    for n in names:
        r = sb.rpc("resolve_exercise_demo_media", {"p_name": n}).execute().data
        rows = r if isinstance(r, list) else ([r] if r else [])
        has_media = bool(rows) and any((row.get("image_s3_path") or row.get("video_s3_path")
                                        or row.get("image_url") or row.get("gif_url"))
                                       for row in rows)
        if not has_media:
            bad.append(n)
            continue
        canonical_name = rows[0].get("canonical_name")
        if canonical_name and _norm_name(canonical_name) != _norm_name(n):
            divergent.append((n, canonical_name))
    if bad:
        raise SystemExit(f"❌ {len(bad)} exercises do not resolve to media (reviewer "
                         f"should have fixed these): {bad[:15]}")
    print(f"✅ all {len(names)} distinct exercises resolve to library media")
    if divergent:
        print(f"⚠️  {len(divergent)} exercise name(s) resolve to a DIFFERENT canonical "
              f"exercise than their own text suggests — reviewer should confirm these "
              f"are the intended exercise, not a wrong-alias drift (Ski Erg Easy class):")
        for n, cn in divergent[:20]:
            print(f"   '{n}' → resolves to '{cn}'")


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


_MINUTES_TEXT_RE = re.compile(r"(\d+(?:\.\d+)?)(\s*(?:minutes?|min)\b)", re.IGNORECASE)
_SECONDS_TEXT_RE = re.compile(r"(\d+(?:\.\d+)?)(\s*(?:seconds?|secs?)\b)", re.IGNORECASE)
_SESSION_TITLE_MIN_RE = re.compile(r"(—\s*)(\d+(?:\.\d+)?)(\s*min\b)", re.IGNORECASE)


def _rewrite_minutes_text(text: Any, new_seconds: int) -> Any:
    """Best-effort: swap the leading '<N> minute(s)'/'<N> second(s)' in a
    human string (e.g. '30 minutes easy', '30 seconds') to match a newly-
    scaled duration, using whichever unit the original text used. Safe no-op
    if the text doesn't contain a recognizable minutes/seconds pattern."""
    if not isinstance(text, str) or not text:
        return text

    if _SECONDS_TEXT_RE.search(text):
        def _sub_secs(m: "re.Match") -> str:
            return f"{new_seconds}{m.group(2)}"
        new_text, n = _SECONDS_TEXT_RE.subn(_sub_secs, text, count=1)
        if n:
            return new_text

    new_minutes = round(new_seconds / 60, 1)
    new_minutes_str = str(int(new_minutes)) if new_minutes == int(new_minutes) else str(new_minutes)

    def _sub_min(m: "re.Match") -> str:
        return f"{new_minutes_str}{m.group(2)}"

    new_text, n = _MINUTES_TEXT_RE.subn(_sub_min, text, count=1)
    return new_text if n else text


def _resync_session_duration(w: Dict[str, Any]) -> None:
    """After scaling exercises' duration_seconds, recompute the session's
    duration_minutes from its parts and rewrite any '— N min' embedded in the
    workout_name/name so titles don't go stale against the new content."""
    exercises = w.get("exercises", [])
    total_seconds = 0
    has_any_secs = False
    for ex in exercises:
        secs = ex.get("duration_seconds")
        if secs:
            has_any_secs = True
            sets = ex.get("sets")
            try:
                sets_i = int(sets) if sets else 1
            except (TypeError, ValueError):
                sets_i = 1
            rest = ex.get("rest_seconds") or 0
            total_seconds += secs * max(sets_i, 1) + rest * max(sets_i - 1, 0)
    if not has_any_secs:
        return
    new_minutes = max(1, round(total_seconds / 60))
    w["duration_minutes"] = new_minutes
    for key in ("workout_name", "name"):
        val = w.get(key)
        if isinstance(val, str) and val:
            new_val, n = _SESSION_TITLE_MIN_RE.subn(
                lambda m: f"{m.group(1)}{new_minutes}{m.group(3)}", val, count=1
            )
            if n:
                w[key] = new_val


def scale_intensity(week: Dict[str, Any], level: str) -> Dict[str, Any]:
    """Easy: -1 set / +2 reps / +rest. Hard: +1 set / -2 reps / -rest — for
    rep-based exercises (unchanged behavior, exactly as before).

    For timed/distance exercises, this used to unconditionally skip scaling
    (a cardio program's Easy/Medium/Hard were byte-identical). Now: only
    exercises explicitly marked `intensity_scalable: true` at author time
    (the true "main effort" — never warmups/cooldowns/recovery days/fillers,
    which stay completely untouched, exactly like today) get scaled:
      - rounds-via-sets pattern (sets > 1, e.g. a 4x4 interval): vary ROUNDS
        and REST, never the named work-interval length (protocol identity —
        "4x4" stays 4-minute efforts — is preserved).
      - continuous/per-effort pattern (sets in (None, 1), e.g. a Zone-2 jog):
        vary DURATION (and rest, if present) directly.
    Any timed/distance exercise WITHOUT the flag is left exactly as before
    (unconditional skip) — zero behavior change for anything not explicitly
    opted in.
    """
    if level == "Medium":
        return week
    import copy
    wk = copy.deepcopy(week)
    for w in wk.get("workouts", []):
        touched = False
        for ex in w.get("exercises", []):
            tt = (ex.get("tracking_type") or "").lower()
            # duration_seconds presence is checked directly because
            # gemini-authored content doesn't reliably set tracking_type —
            # relying on that string alone silently misses timed exercises,
            # which then fall through to the rep-based path below and get
            # nonsensically "scaled" as if sets/reps (e.g. a continuous 25-min
            # walk turning into "2 sets of 3 reps").
            is_timed = (tt in ("time", "distance")
                       or "second" in str(ex.get("reps", "")).lower()
                       or bool(ex.get("duration_seconds")))
            if is_timed:
                if not ex.get("intensity_scalable"):
                    continue
                secs = ex.get("duration_seconds")
                rest = ex.get("rest_seconds")
                try:
                    sets_i = int(ex.get("sets")) if ex.get("sets") else None
                except (TypeError, ValueError):
                    sets_i = None
                if sets_i and sets_i > 1:
                    # rounds-via-sets pattern: vary rounds + rest, not work length
                    if level == "Hard":
                        ex["sets"] = sets_i + 1
                        if rest:
                            ex["rest_seconds"] = max(20, round(int(rest) * 0.8 / 5) * 5)
                    elif level == "Easy":
                        ex["sets"] = max(2, sets_i - 1)
                        if rest:
                            ex["rest_seconds"] = round(int(rest) * 1.25 / 5) * 5
                    touched = True
                elif secs:
                    # continuous/per-effort pattern: vary duration + rest directly.
                    # Floor is relative to the original duration (not a flat
                    # constant) so short bursts (e.g. a 30s jump-rope round)
                    # don't get clamped up to something longer than Hard.
                    factor = 1.15 if level == "Hard" else 0.85
                    new_secs = max(10, round(int(secs) * factor / 5) * 5)
                    ex["duration_seconds"] = new_secs
                    ex["reps"] = _rewrite_minutes_text(ex.get("reps"), new_secs)
                    if rest:
                        rfactor = 0.8 if level == "Hard" else 1.25
                        ex["rest_seconds"] = max(10, round(int(rest) * rfactor / 5) * 5)
                    touched = True
                continue
            # rep-based path — unchanged
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
        if touched:
            _resync_session_duration(w)
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
