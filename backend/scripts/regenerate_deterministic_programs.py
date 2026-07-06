#!/usr/bin/env python3
"""
regenerate_deterministic_programs.py — force-refresh already-shipped program
content in program_variant_weeks after the VO2max-protocol intensity-scaling
fix (real Easy/Medium/Hard for time-tracked cardio programs), without
re-spending any Gemini tokens.

Two modes:

  --slugs vo2max-protocol,zero-to-5k,...              (deterministic, free)
      Recomputes each program's PRIMARY (Medium) variant weeks straight from
      WEEKLY_BUILDERS[slug] (deterministic_program_weeks.py), re-ingests them
      (upsert), then force-derives the whole (weeks x sessions x intensity)
      matrix — every cell gets overwritten, not just incomplete ones (unlike
      generate_28_programs.py's derive_matrix, which is a resume-only
      skip-if-complete pass and would no-op on an already-shipped program).

  --gemini-fix --slugs feel-good-cardio,...            (gemini-authored, free)
      These programs' shipped content doesn't need rewriting — it just never
      got tagged with which exercises are the scalable "main effort". Reads
      each program's EXISTING primary-variant weeks, heuristically flags
      intensity_scalable on time/distance-tracked exercises that aren't a
      warmup/cooldown/recovery bookend, patches those weeks in place, then
      force-derives the matrix the same way. No Gemini calls are made.

--dry-run prints what would change without writing anything to Supabase.

Usage:
  python3 scripts/regenerate_deterministic_programs.py --slugs vo2max-protocol --dry-run
  python3 scripts/regenerate_deterministic_programs.py --slugs vo2max-protocol,treadmill-12-3-30,zero-to-5k,rucking-ready,jump-rope-10,shadow-boxing
  python3 scripts/regenerate_deterministic_programs.py --gemini-fix --slugs feel-good-cardio,endurance-base,hybrid-athlete,trail-ready,cricket-conditioning,pickleball-agility,three-two-eight --dry-run
  python3 scripts/regenerate_deterministic_programs.py --gemini-fix --slugs feel-good-cardio,endurance-base,hybrid-athlete,trail-ready,cricket-conditioning,pickleball-agility,three-two-eight
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))
sys.path.insert(0, str(Path(__file__).parent))
from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

import generate_programs as gp  # noqa: E402
import program_build as pb  # noqa: E402
import generate_28_programs as g28  # noqa: E402
from deterministic_program_weeks import WEEKLY_BUILDERS  # noqa: E402

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
MANIFEST_PATH = Path(__file__).parent / "specs" / "programs_28_manifest.json"


def _sb():
    from supabase import create_client
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def _load_manifest_by_slug() -> Dict[str, dict]:
    manifest = json.loads(MANIFEST_PATH.read_text())["programs"]
    return {m["slug"]: m for m in manifest}


def _get_program_and_primary(sb, m: dict) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """Look up the already-existing programs.id / branded base / primary
    (Medium) variant ids for an already-shipped program.
    Returns (programs_id, base_id, primary_vid) — any of which may be None
    if not found."""
    prow = (sb.table("programs").select("id, variant_base_id")
            .eq("program_name", m["program_name"]).limit(1).execute().data)
    if not prow:
        return None, None, None
    pid = prow[0]["id"]
    base_id = prow[0].get("variant_base_id")
    if not base_id:
        return pid, None, None
    vrow = (sb.table("program_variants").select("id")
            .eq("base_program_id", base_id)
            .eq("duration_weeks", m["duration_weeks"])
            .eq("sessions_per_week", m["sessions_per_week"])
            .eq("intensity_level", "Medium")
            .limit(1).execute().data)
    primary_vid = vrow[0]["id"] if vrow else None
    return pid, base_id, primary_vid


def _summarize_week(week: dict) -> str:
    parts = []
    for w in week.get("workouts", []):
        scal = [e for e in w.get("exercises", []) if e.get("intensity_scalable")]
        for e in scal[:1]:
            parts.append(f"{e.get('name')} sets={e.get('sets')} "
                         f"dur={e.get('duration_seconds')} rest={e.get('rest_seconds')}")
    return "; ".join(parts) or "(no scalable exercise found)"


def _force_derive_matrix(sb, m: dict, base_id: str, primary_vid: str,
                         dry_run: bool,
                         primary_override: Optional[List[dict]] = None) -> int:
    """Like generate_28_programs.derive_matrix, but OVERWRITES every cell
    unconditionally (no resume-skip) — every already-shipped derived variant
    gets recomputed from the (now-updated) primary weeks.

    In dry-run mode the primary variant is never actually written, so reading
    it back from the DB would show stale (pre-fix) content. Callers previewing
    a dry-run should pass the freshly-computed in-memory weeks as
    `primary_override` so the matrix preview reflects what WOULD be written.
    """
    dur, spw = m["duration_weeks"], m["sessions_per_week"]
    minutes = m["session_duration_minutes"]
    if primary_override is not None:
        primary = primary_override
    else:
        rows = (sb.table("program_variant_weeks")
                .select("week_number, phase, focus, workouts")
                .eq("variant_id", primary_vid).order("week_number").execute().data) or []
        primary = [{"week": r["week_number"], "phase": r.get("phase"),
                    "focus": r.get("focus"), "workouts": r.get("workouts", [])}
                   for r in rows]
    if len(primary) < dur:
        print(f"   ⚠️ primary incomplete ({len(primary)}/{dur}) — derive skipped")
        return 0

    weeks_axis, sessions_axis = pb.build_matrix(dur, spw, m["is_express"])
    n_done = 0
    for weeks in weeks_axis:
        wk_mapped = pb.map_weeks(primary, weeks)
        for sessions in sessions_axis:
            for intensity in pb.INTENSITIES:
                vname = f"{m['editorial_name']} — {weeks}w/{sessions}d/{intensity}"
                if dry_run:
                    sample = pb.map_sessions(
                        pb.scale_intensity(wk_mapped[0], intensity), sessions)
                    print(f"      [dry-run] {vname}: week1 sample -> "
                         f"{_summarize_week(sample)}")
                    n_done += 1
                    continue
                vid = g28.ensure_variant(sb, base_id, vname, weeks, sessions,
                                         intensity, minutes, m["program_category"])
                if not vid:
                    continue
                for w in wk_mapped:
                    cell_week = pb.map_sessions(
                        pb.scale_intensity(w, intensity), sessions)
                    workouts = g28.topup_week(cell_week["workouts"], minutes)
                    gp.ingest_week_to_supabase(
                        sb, vid, w["week"],
                        {"week": w["week"], "phase": w.get("phase"),
                         "focus": w.get("focus"), "workouts": workouts},
                        {"name": f"{m['editorial_name']} (Zealova Library)",
                         "variant_name": vname, "category": m["program_category"]})
                n_done += 1
    return n_done


def _refresh_programs_blob(sb, pid: str, primary_vid: str) -> None:
    week1 = gp.get_last_week_data(sb, primary_vid, 1)
    if week1:
        sb.table("programs").update({
            "workouts": {"workouts": week1.get("workouts", [])},
            "has_workouts": True,
        }).eq("id", pid).execute()


# ---------------------------------------------------------------------------
# Mode 1: deterministic (hand-authored) programs — recompute from the builder
# ---------------------------------------------------------------------------
def regenerate_deterministic(sb, m: dict, dry_run: bool) -> dict:
    slug = m["slug"]
    builder = WEEKLY_BUILDERS.get(slug)
    if not builder:
        return {"slug": slug, "error": "no deterministic builder registered for this slug"}
    pid, base_id, primary_vid = _get_program_and_primary(sb, m)
    if not base_id or not primary_vid:
        return {"slug": slug,
                "error": f"program not found or not fully shipped "
                        f"(programs.id={pid}, base={base_id}, primary={primary_vid})"}

    dur, spw, minutes = m["duration_weeks"], m["sessions_per_week"], m["session_duration_minutes"]
    print(f"-- {slug} -- base={base_id} primary={primary_vid}")
    fresh_primary: List[dict] = []
    for wk in range(1, dur + 1):
        week_data = builder(wk, dur, spw)
        workouts = g28.topup_week(week_data.get("workouts", []), minutes)
        print(f"   week {wk} (phase={week_data.get('phase')}): "
             f"{_summarize_week(week_data)}")
        fresh_primary.append({"week": wk, "phase": week_data.get("phase"),
                              "focus": week_data.get("focus"), "workouts": workouts})
        if dry_run:
            continue
        gp.ingest_week_to_supabase(
            sb, primary_vid, wk,
            {"week": wk, "phase": week_data.get("phase"),
             "focus": week_data.get("focus"), "workouts": workouts},
            {"name": f"{m['editorial_name']} (Zealova Library)",
             "variant_name": f"{m['editorial_name']} — {dur}w/{spw}d/Medium",
             "category": m["program_category"]})

    n = _force_derive_matrix(sb, m, base_id, primary_vid, dry_run,
                             primary_override=fresh_primary if dry_run else None)
    print(f"   derived matrix: {n} cells {'(dry-run)' if dry_run else 'refreshed'}")
    if not dry_run:
        _refresh_programs_blob(sb, pid, primary_vid)
    return {"slug": slug, "ok": True}


# ---------------------------------------------------------------------------
# Mode 2: gemini-authored programs — retroactively tag main effort, no rewrite
# ---------------------------------------------------------------------------
_BOOKEND_KEYWORDS = (
    "warm up", "warmup", "warm-up", "cool down", "cooldown", "cool-down",
    "recovery", "stretch", "mobility", "walk it off", "shakeout", "rest day",
)
_STALE_MENTION_RE = re.compile(r"\b\d+\s*(?:minutes?|min|rounds?)\b", re.IGNORECASE)


def _is_main_effort(ex: dict, idx: int, total: int) -> bool:
    tt = (ex.get("tracking_type") or "").lower()
    # duration_seconds is checked directly since gemini-authored content
    # doesn't reliably set tracking_type (see the matching note in
    # program_build.py::scale_intensity).
    is_timed = (tt in ("time", "distance")
               or "second" in str(ex.get("reps", "")).lower()
               or bool(ex.get("duration_seconds")))
    if not is_timed:
        return False
    name = (ex.get("name") or ex.get("exercise_name") or "").lower()
    guide = (ex.get("weight_guidance") or "").lower()
    haystack = f"{name} {guide}"
    if any(kw in haystack for kw in _BOOKEND_KEYWORDS):
        return False
    is_bookend_position = idx == 0 or idx == total - 1
    secs = ex.get("duration_seconds") or 0
    if is_bookend_position and secs and secs <= 360:
        return False
    return True


def regenerate_gemini_fix(sb, m: dict, dry_run: bool) -> dict:
    slug = m["slug"]
    pid, base_id, primary_vid = _get_program_and_primary(sb, m)
    if not base_id or not primary_vid:
        return {"slug": slug,
                "error": f"program not found or not fully shipped "
                        f"(programs.id={pid}, base={base_id}, primary={primary_vid})"}

    rows = (sb.table("program_variant_weeks")
            .select("id, week_number, phase, focus, workouts")
            .eq("variant_id", primary_vid).order("week_number").execute().data) or []
    print(f"-- {slug} (gemini-fix) -- base={base_id} primary={primary_vid} "
         f"weeks={len(rows)}")

    flagged_sample: List[str] = []
    excluded_sample: List[str] = []
    stale_hits: List[Tuple[str, str, str]] = []
    dirty_weeks: List[Tuple[int, dict]] = []

    for row in rows:
        workouts = row.get("workouts") or []
        week_changed = False
        for w in workouts:
            exercises = w.get("exercises") or []
            total = len(exercises)
            for idx, e in enumerate(exercises):
                if e.get("intensity_scalable"):
                    continue
                # _is_main_effort() itself gates on is_timed (broadened to
                # also catch duration_seconds-only exercises) and returns
                # False for anything not time/distance-tracked.
                if _is_main_effort(e, idx, total):
                    e["intensity_scalable"] = True
                    week_changed = True
                    if len(flagged_sample) < 8:
                        flagged_sample.append(f"week{row['week_number']}: {e.get('name')} "
                                              f"({e.get('reps')})")
                    for field in ("notes", "form_cue"):
                        text = e.get(field)
                        if text and _STALE_MENTION_RE.search(text):
                            stale_hits.append((e.get("name"), field, text))
                else:
                    if len(excluded_sample) < 8:
                        excluded_sample.append(f"week{row['week_number']}: {e.get('name')} "
                                               f"({e.get('reps')}) [pos {idx}/{total - 1}]")
        if week_changed:
            dirty_weeks.append((row["week_number"], {
                "phase": row.get("phase"), "focus": row.get("focus"), "workouts": workouts,
            }))

    print(f"   flagged sample ({len(flagged_sample)} shown): ")
    for s in flagged_sample:
        print(f"      + {s}")
    print(f"   excluded sample ({len(excluded_sample)} shown): ")
    for s in excluded_sample:
        print(f"      - {s}")
    if stale_hits:
        print(f"   ⚠️ {len(stale_hits)} flagged exercises have a notes/form_cue "
             "mention that may go stale once scaled — review manually:")
        for name, field, text in stale_hits[:10]:
            print(f"      {name}.{field}: {text!r}")

    if dry_run:
        print(f"   [dry-run] {len(dirty_weeks)}/{len(rows)} weeks would be patched")
        # rows' workouts were already mutated in place above (flags added),
        # so this reflects the post-patch state for an accurate matrix preview.
        full_primary = [{"week": r["week_number"], "phase": r.get("phase"),
                        "focus": r.get("focus"), "workouts": r.get("workouts", [])}
                       for r in sorted(rows, key=lambda r: r["week_number"])]
        n = _force_derive_matrix(sb, m, base_id, primary_vid, dry_run=True,
                                 primary_override=full_primary)
        print(f"   derived matrix: {n} cells (dry-run)")
        return {"slug": slug, "dry_run": True, "would_patch": len(dirty_weeks)}

    for week_num, week_data in dirty_weeks:
        gp.ingest_week_to_supabase(
            sb, primary_vid, week_num,
            {"week": week_num, "phase": week_data.get("phase"),
             "focus": week_data.get("focus"), "workouts": week_data.get("workouts", [])},
            {"name": f"{m['editorial_name']} (Zealova Library)",
             "variant_name": f"{m['editorial_name']} — {m['duration_weeks']}w/"
                             f"{m['sessions_per_week']}d/Medium",
             "category": m["program_category"]})
    print(f"   patched {len(dirty_weeks)}/{len(rows)} weeks with intensity_scalable flags")

    n = _force_derive_matrix(sb, m, base_id, primary_vid, dry_run=False)
    print(f"   derived matrix: {n} cells refreshed")
    _refresh_programs_blob(sb, pid, primary_vid)
    return {"slug": slug, "ok": True, "patched_weeks": len(dirty_weeks)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--slugs", required=True, help="comma-separated program slugs")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--gemini-fix", action="store_true",
                    help="use the retroactive-tagging path for gemini-authored programs")
    args = ap.parse_args()

    by_slug = _load_manifest_by_slug()
    slugs = [s.strip() for s in args.slugs.split(",") if s.strip()]
    unknown = [s for s in slugs if s not in by_slug]
    if unknown:
        sys.exit(f"unknown slug(s): {unknown}")

    sb = _sb()
    results = []
    for slug in slugs:
        m = by_slug[slug]
        try:
            if args.gemini_fix:
                results.append(regenerate_gemini_fix(sb, m, args.dry_run))
            else:
                results.append(regenerate_deterministic(sb, m, args.dry_run))
        except Exception as e:
            print(f"   ❌ {slug} crashed: {e}")
            results.append({"slug": slug, "error": str(e)})

    print(f"\n{'=' * 62}\nSUMMARY")
    for r in results:
        status = "ERROR: " + r["error"] if r.get("error") else \
                 ("dry-run" if r.get("dry_run") else "ok")
        print(f"   {r['slug']:24s} {status}")


if __name__ == "__main__":
    main()
