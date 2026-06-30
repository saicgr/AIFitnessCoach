#!/usr/bin/env python3
"""
generate_curated_variants.py — Generate per-program variant libraries for
Zealova curated programs.

Each curated program gets its OWN dedicated branded_programs base (named
"<editorial_name> (Zealova Library)") so its variant library is fully isolated
from unrelated branded content.  After generation the script back-fills
programs.variant_base_id and programs.default_variant_id, then marks the
dedicated base is_active=false so it never surfaces in any branded-facing UI.

Model: gemini-3.1-flash-lite (override via GEMINI_MODEL env var per-run;
       the app-wide .env GEMINI_MODEL is NOT touched).

Reuses generate_programs.py functions directly: generate_variant,
get_or_create_branded_program, create_variant_record, ingest_week_to_supabase.

Usage:
    # Smoke test — single program, tiny matrix
    cd backend
    GEMINI_MODEL=gemini-3.1-flash-lite \\
        python3 scripts/generate_curated_variants.py \\
        --program-id 0f9d9142-be65-4d13-aafc-223c96867d5c \\
        --smoke-test

    # Single program, full matrix
    GEMINI_MODEL=gemini-3.1-flash-lite \\
        python3 scripts/generate_curated_variants.py \\
        --program-id 0f9d9142-be65-4d13-aafc-223c96867d5c

    # All 16 non-fixed programs (do NOT run without team-lead approval)
    GEMINI_MODEL=gemini-3.1-flash-lite \\
        python3 scripts/generate_curated_variants.py --all
"""

import os
import sys
import time
import json
import argparse
from pathlib import Path
from typing import Optional

# ── Bootstrap path so we can import generate_programs functions ───────────────
BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv
load_dotenv(BACKEND_DIR / ".env")

# GEMINI_MODEL read AFTER dotenv so an inline env-var override wins.
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
SUPABASE_URL   = os.getenv("SUPABASE_URL")
SUPABASE_KEY   = os.getenv("SUPABASE_KEY")
GEMINI_MODEL   = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite")

# Reuse the pipeline's rate-limiting constant.
REQUEST_DELAY = 60 / 15  # 15 req/min

# ── Fixed programs that stay genuinely fixed (never generate variants) ─────────
FIXED_PROGRAM_IDS = {
    "73d9ec23-5845-498f-8015-e961e141cec5",  # HYROX Full Simulation (1-session)
    "6e9539c2-feef-497d-9d0b-8c499838d2f8",  # 30-Day Plank Challenge
}

# ── The 16 non-fixed curated program IDs (all published, non-hyrox-sim/plank) ─
ALL_TARGET_IDS = [
    "28509af5-3ae9-4f3b-a4ad-bbf840798a64",  # HYROX Race Prep
    "6348ee98-26a1-4eda-9957-e058de835def",  # HYROX Pro — Elite Race Build
    "d98a7ddc-d55b-4b42-939f-e80f75d4e44e",  # Iron Surge
    "5886bf32-6ee9-4c17-aa5b-f733bfba3aca",  # Starting Strength Foundations
    "ed09f728-640c-4898-aaec-81643b1dd83b",  # Anabolic Foundations
    "8572438b-d394-4d01-bf4e-d9596e5cf7f4",  # Push/Pull/Legs Hypertrophy
    "b0d8bc88-b9be-4c3c-87e9-18100c9f9f87",  # Hypertrophy 4-Day Split
    "76ff820c-163c-44d5-9c9e-f84e7da311d4",  # Strong & Steady Women's
    "718331e4-0c06-4538-bded-63362031cdb9",  # Postpartum Rebuild
    "0f9d9142-be65-4d13-aafc-223c96867d5c",  # 7-Minute Upper Body
    "5988380c-defa-49a5-b0d8-83edc2f03d09",  # 7-Minute Lower Body
    "3132f0e1-c235-48da-ba78-52e4b9704442",  # Daily Flow — Yoga for Lifters
    "52e8f552-52f0-47bb-9e6c-d6f13a4977d9",  # Beach Body Ready
    "ce4e2196-f35d-440c-a425-880e675699bd",  # Lean Burn — Fat-Loss Circuit
    "cc56fab8-c9d4-42f0-936a-ea6975c9d064",  # Beginner Foundations
    "a616a82c-d9be-4b71-a7ef-7b291ec47107",  # No-Equipment Home Workout
]


# ── Supabase client (shared singleton) ────────────────────────────────────────

_supabase = None

def get_supabase():
    global _supabase
    if _supabase is None:
        from supabase import create_client
        _supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _supabase


# ── Fetch a curated program row from programs table ───────────────────────────

def fetch_curated_program(program_id: str) -> Optional[dict]:
    sb = get_supabase()
    resp = sb.table("programs").select(
        "id, editorial_name, program_name, program_category, program_subcategory, "
        "description, tagline, goals, duration_weeks, sessions_per_week, is_published"
    ).eq("id", program_id).limit(1).execute()
    if not resp.data:
        return None
    return resp.data[0]


# ── Build the week/session matrix for a curated program ───────────────────────

def _weeks_for(program_row: dict) -> set:
    """Return the weeks set for a program's full generation matrix.

    Express programs (program_subcategory == 'Express', e.g. 7-Minute Upper/Lower
    Body) are capped at <= 4 weeks — long ladders (8w, 12w) make no sense for a
    quick-hit format and would generate junk content. All other programs get the
    standard ladder {1, 2, 4, 8, 12} merged with their intended duration.
    """
    intended = program_row.get("duration_weeks") or 8
    is_express = (program_row.get("program_subcategory") or "").strip().lower() == "express"

    if is_express:
        # Cap: keep only weeks <= 4, always include the intended duration if it
        # is also <= 4 (both 7-Minute programs have duration_weeks=2, so {1,2,4}).
        base = {1, 2, 4}
        if intended <= 4:
            base.add(intended)
        return base

    # Standard ladder for all other programs.
    return {1, 2, 4, 8, 12} | {intended}


def build_matrix(program_row: dict, smoke_test: bool = False):
    """Return sorted (weeks, sessions) tuples for generation.

    Full matrix:
      weeks    = _weeks_for(program_row)  — see helper for Express cap
      sessions = sorted( {3,4,5} | {program.sessions_per_week} ) clamped [2,6]

    Smoke-test matrix (tiny, fast):
      weeks = {1, 2}
      sessions = {3}
    """
    if smoke_test:
        weeks_set = {1, 2}
        sessions_set = {3}
    else:
        intended_sess = program_row.get("sessions_per_week") or 4
        weeks_set     = _weeks_for(program_row)
        sessions_set  = {3, 4, 5} | {intended_sess}
        sessions_set  = {s for s in sessions_set if 2 <= s <= 6}

    combos = [(w, s) for w in sorted(weeks_set) for s in sorted(sessions_set)]
    return combos


# ── Build the program dict that generate_variant expects ──────────────────────

def build_program_dict(program_row: dict) -> dict:
    """Construct the `program` dict that generate_variant / get_or_create_branded_program consume.

    The name gets a ' (Zealova Library)' suffix so get_or_create_branded_program's
    ilike('%name%') query finds no existing row and always creates a fresh dedicated base.
    """
    editorial = (program_row.get("editorial_name") or program_row.get("program_name") or "Unknown")
    goals = program_row.get("goals") or []
    description = program_row.get("description") or program_row.get("tagline") or ""

    return {
        "name": f"{editorial} (Zealova Library)",
        "category": program_row.get("program_category") or "General Fitness",
        "description": description,
        "has_supersets": False,
        "goals": goals,
        "priority": "High",
        # durations/sessions are placeholders here; generate_variant receives
        # the concrete (duration, sessions) values directly.
        "durations": [program_row.get("duration_weeks") or 8],
        "sessions": [program_row.get("sessions_per_week") or 4],
    }


# ── Pick the best default_variant_id for a base ──────────────────────────────

def pick_default_variant(base_id: str, target_weeks: int, target_sessions: int) -> Optional[str]:
    """Select the program_variants row closest to (target_weeks, target_sessions).

    Sort key: abs(weeks_diff), abs(sess_diff), intensity (prefer Medium).
    """
    sb = get_supabase()
    resp = sb.table("program_variants").select(
        "id, duration_weeks, sessions_per_week, intensity_level"
    ).eq("base_program_id", base_id).execute()
    rows = resp.data or []
    if not rows:
        return None

    intensity_rank = {"Easy": 0, "Medium": 1, "Hard": 2}

    def _key(r):
        dw  = r.get("duration_weeks") or 0
        spw = r.get("sessions_per_week") or 0
        ir  = intensity_rank.get(r.get("intensity_level") or "Medium", 1)
        return (abs(dw - target_weeks), abs(spw - target_sessions), abs(ir - 1))

    best = min(rows, key=_key)
    return best["id"]


# ── Post-generation: back-fill programs columns + hide base from branded UI ───

def backfill_programs_columns(program_id: str, base_id: str,
                               target_weeks: int, target_sessions: int) -> bool:
    """Set variant_base_id + default_variant_id on the curated programs row
    and mark the dedicated branded base is_active=false."""
    sb = get_supabase()

    default_vid = pick_default_variant(base_id, target_weeks, target_sessions)
    if not default_vid:
        print(f"   WARNING: no variants found under base {base_id} — skipping backfill")
        return False

    # Update the curated program row.
    sb.table("programs").update({
        "variant_base_id": base_id,
        "default_variant_id": default_vid,
    }).eq("id", program_id).execute()

    # Hide the dedicated branded base so it never appears in branded-facing UI.
    sb.table("branded_programs").update({
        "is_active": False,
    }).eq("id", base_id).execute()

    print(f"   Backfilled: variant_base_id={base_id}, default_variant_id={default_vid}")
    return True


# ── Lookup the dedicated branded base by exact suffixed name ──────────────────

def lookup_dedicated_base(suffixed_name: str) -> Optional[str]:
    sb = get_supabase()
    resp = sb.table("branded_programs").select("id").eq(
        "name", suffixed_name
    ).limit(1).execute()
    if resp.data:
        return resp.data[0]["id"]
    return None


# ── Main per-program generation logic ─────────────────────────────────────────

def generate_for_program(program_id: str, smoke_test: bool = False) -> dict:
    """Run the full generation + backfill pipeline for one curated program."""
    if program_id in FIXED_PROGRAM_IDS:
        print(f"   SKIP: {program_id} is a fixed program (no variants)")
        return {"skipped": True}

    program_row = fetch_curated_program(program_id)
    if not program_row:
        print(f"   ERROR: program {program_id} not found in DB")
        return {"error": "not found"}

    editorial = program_row.get("editorial_name") or program_row.get("program_name")
    target_weeks    = program_row.get("duration_weeks") or 8
    target_sessions = program_row.get("sessions_per_week") or 4

    print(f"\n{'='*60}")
    print(f"Program: {editorial}")
    print(f"ID:      {program_id}")
    print(f"Target:  {target_weeks}w / {target_sessions} sess")
    print(f"Model:   {GEMINI_MODEL}")
    if smoke_test:
        print("Mode:    SMOKE TEST (weeks={1,2}, sessions={3})")
    print(f"{'='*60}")

    program_dict = build_program_dict(program_row)
    combos = build_matrix(program_row, smoke_test=smoke_test)

    print(f"Matrix: {len(combos)} combos: {combos}")

    # Initialize Gemini client with a hard per-call HTTP timeout so a wedged
    # socket can never hang the run forever (observed under high concurrency).
    # On timeout the genai call raises → the per-combo try/except marks that
    # combo failed and the loop continues; a resume re-run backfills the gap.
    from google import genai
    from google.genai import types as _genai_types
    client = genai.Client(
        api_key=GEMINI_API_KEY,
        http_options=_genai_types.HttpOptions(timeout=120_000),  # 120s, in ms
    )

    sb = get_supabase()

    # Import pipeline functions from generate_programs.py.
    import scripts.generate_programs as gp

    # Override the module-level GEMINI_MODEL so all calls inside the pipeline
    # use our chosen model (not whatever is in .env).
    gp.GEMINI_MODEL = GEMINI_MODEL

    # ── Volume-requirement prompt boost (monkeypatch, NOT editing the shared
    # generate_programs.py) ───────────────────────────────────────────────────
    # Gemini 3.1 Flash Lite tends to return weeks too THIN to pass the validator
    # (`generate_programs.validate_week` requires exercises_found >= sessions*3,
    # i.e. >=3 main exercises per workout). Flash-lite often returns ~2/workout
    # → "Low exercise count" → empty variants. We wrap the prompt builders to
    # append a forceful per-workout minimum with margin so flash-lite clears the
    # gate. Idempotent: only wraps once per process.
    def _volume_clause(sessions: int) -> str:
        sessions = sessions or 4
        return (
            "\n\n## NON-NEGOTIABLE VOLUME REQUIREMENT\n"
            f"Each of the {sessions} workouts MUST contain AT LEAST 5 main "
            "exercises in its \"exercises\" array (warmup/cooldown do NOT count "
            "toward this). Strength/hybrid workouts should have 5-7 main "
            f"exercises. The week MUST total AT LEAST {sessions * 5} main "
            "exercises across all its workouts. A workout with fewer than 4 main "
            "exercises, or a week below the minimum, is INVALID and will be "
            "REJECTED — always add appropriate accessory/secondary exercises "
            "(e.g. isolation work, core, carries) to meet the minimum. Never "
            "return a sparse week."
        )

    if not getattr(gp, "_volume_boost_applied", False):
        _orig_week_prompt = gp.get_week_prompt
        _orig_full_prompt = gp.get_full_program_prompt

        def _week_prompt_boosted(program, week_num, total_weeks, sessions, *a, **k):
            return _orig_week_prompt(
                program, week_num, total_weeks, sessions, *a, **k
            ) + _volume_clause(sessions)

        def _full_prompt_boosted(program, duration, sessions, *a, **k):
            return _orig_full_prompt(
                program, duration, sessions, *a, **k
            ) + _volume_clause(sessions)

        gp.get_week_prompt = _week_prompt_boosted
        gp.get_full_program_prompt = _full_prompt_boosted
        gp._volume_boost_applied = True

    # ── Deterministic top-up safety net (monkeypatch) ─────────────────────────
    # Even with the volume-clause prompt boost, Flash-Lite still occasionally
    # under-delivers a session. Rather than ship a thin week (the 2026-06 bug) or
    # just fail it, we top every thin/non-exempt session up to its duration floor
    # with library-resolved accessory exercises BEFORE ingest. Same engine the
    # backfill uses (services/program_session_filler.py) → equipment-gated (a
    # bodyweight program never gets gym gear), media auto-resolves, idempotent.
    # Equipment + difficulty are derived from the week itself so the patch is
    # program-independent and safe to apply once. See the plan file.
    if not getattr(gp, "_topup_applied", False):
        import asyncio as _asyncio
        import re as _re
        from collections import Counter as _Counter
        from services.program_session_filler import fill_thin_sessions as _fill

        def _week_equipment_union(workouts):
            eq = set()
            for w in workouts or []:
                for e in (w.get("exercises") or []):
                    val = (e.get("equipment") or "").strip().lower()
                    if val:
                        eq.update(p.strip() for p in _re.split(r"[/,]| or | and ", val))
            eq = {x for x in eq if x}
            eq.update({"bodyweight", "none"})  # bodyweight accessories always allowed
            return sorted(eq)

        def _week_difficulty(workouts):
            c = _Counter()
            for w in workouts or []:
                for e in (w.get("exercises") or []):
                    d = (e.get("difficulty") or "").strip().lower()
                    if d in ("beginner", "intermediate", "advanced", "elite"):
                        c[d] += 1
            return c.most_common(1)[0][0] if c else "intermediate"

        _orig_ingest = gp.ingest_week_to_supabase

        def _ingest_with_topup(supabase, variant_id, week_num, week_data,
                               program_metadata=None):
            try:
                workouts = week_data.get("workouts", [])
                res = _asyncio.run(_fill(
                    workouts,
                    equipment=_week_equipment_union(workouts),
                    difficulty_ceiling=_week_difficulty(workouts),
                    program_name=(program_metadata or {}).get("name"),
                ))
                week_data["workouts"] = res["workouts"]
                if res["added"]:
                    print(f"      🔧 top-up: +{len(res['added'])} accessory "
                          f"exercises (week {week_num})")
            except Exception as _e:  # never block ingest on the safety net
                print(f"      ⚠️ top-up skipped (week {week_num}): {_e}")
            return _orig_ingest(supabase, variant_id, week_num, week_data,
                                program_metadata)

        gp.ingest_week_to_supabase = _ingest_with_topup
        gp._topup_applied = True

    total_cost = 0.0
    variants_ok = 0
    variants_failed = 0
    dedicated_base_id: Optional[str] = None

    for (duration, sessions) in combos:
        label = f"{duration}w/{sessions}sess"
        print(f"\n   Combo {label}...")

        result = gp.generate_variant(
            program_dict, duration, sessions,
            sb, client,
            dry_run=False,
            resume=True,
        )

        cost = result.get("cost", 0.0)
        total_cost += cost

        if result.get("success"):
            variants_ok += 1
            print(f"   {label}: OK  cost=${cost:.4f}")
        else:
            variants_failed += 1
            print(f"   {label}: FAILED — {result.get('error', '?')}")

        # Discover the dedicated base after first successful variant.
        if dedicated_base_id is None:
            dedicated_base_id = lookup_dedicated_base(program_dict["name"])

        time.sleep(REQUEST_DELAY)

    print(f"\n   Total cost: ${total_cost:.4f}")
    print(f"   Variants: {variants_ok} OK / {variants_failed} failed")

    # Back-fill programs columns only when at least one variant was created.
    if dedicated_base_id and variants_ok > 0:
        backfill_programs_columns(program_id, dedicated_base_id, target_weeks, target_sessions)
    elif not dedicated_base_id:
        print("   WARNING: dedicated base not found — skipping backfill")

    return {
        "program_id": program_id,
        "editorial_name": editorial,
        "base_id": dedicated_base_id,
        "variants_ok": variants_ok,
        "variants_failed": variants_failed,
        "total_cost": total_cost,
    }


# ── Smoke-test verification queries ──────────────────────────────────────────

def run_smoke_verification(program_id: str):
    """Print the same SELECTs that the backend /library/{id} and /library/{id}/schedule use."""
    sb = get_supabase()

    # 1. Fetch updated programs row.
    prog_resp = sb.table("programs").select(
        "id, editorial_name, variant_base_id, default_variant_id"
    ).eq("id", program_id).limit(1).execute()
    prog = prog_resp.data[0] if prog_resp.data else {}

    base_id    = prog.get("variant_base_id")
    default_id = prog.get("default_variant_id")

    print(f"\n{'='*60}")
    print("SMOKE VERIFICATION")
    print(f"{'='*60}")
    print(f"programs row: variant_base_id={base_id}  default_variant_id={default_id}")

    if not base_id:
        print("ERROR: variant_base_id is NULL — backfill did not run")
        return

    # 2. variant_options (mirrors _fetch_variant_options in program_templates.py).
    vresp = sb.table("program_variants").select(
        "id, duration_weeks, sessions_per_week, intensity_level, generation_model"
    ).eq("base_program_id", base_id).order("duration_weeks", desc=False).execute()
    variants = vresp.data or []

    print(f"\nvariant_options ({len(variants)} rows):")
    for v in variants:
        is_def = v["id"] == default_id
        print(f"  {v['duration_weeks']}w/{v['sessions_per_week']}sess  "
              f"intensity={v['intensity_level']}  "
              f"model={v.get('generation_model', '?')}  "
              f"{'[DEFAULT]' if is_def else ''}")

    # 3. Schedule query for default variant (week 1).
    if default_id:
        wresp = sb.table("program_variant_weeks").select(
            "week_number, phase, focus, workouts"
        ).eq("variant_id", default_id).order("week_number", desc=False).execute()
        weeks = wresp.data or []

        print(f"\nprogram_variant_weeks for default variant ({len(weeks)} weeks):")
        for w in weeks:
            wkts = w.get("workouts") or []
            total_ex = sum(len(wkt.get("exercises", [])) for wkt in wkts if isinstance(wkt, dict))
            print(f"  Week {w['week_number']}: {len(wkts)} days, {total_ex} exercises total — phase={w.get('phase')}")

        # Print a sample exercise from week 1 day 1.
        if weeks:
            w1 = weeks[0]
            wkts1 = w1.get("workouts") or []
            if wkts1:
                day1 = wkts1[0] if isinstance(wkts1[0], dict) else {}
                exes = day1.get("exercises") or []
                if exes:
                    sample = exes[0]
                    print(f"\nSample exercise (week 1 day 1 ex 1):")
                    print(json.dumps(sample, indent=2)[:800])

    # 4. Media coverage via program_exercises_with_media for the default variant.
    if default_id:
        try:
            mresp = sb.table("program_exercises_with_media").select(
                "exercise_name_normalized, canonical_name, image_s3_path, video_s3_path"
            ).eq("variant_id", default_id).execute()
            mrows = mresp.data or []
            total_ex_rows = len(mrows)
            with_image = sum(1 for r in mrows if r.get("image_s3_path"))
            with_video  = sum(1 for r in mrows if r.get("video_s3_path"))
            pct = (with_image / total_ex_rows * 100) if total_ex_rows else 0
            print(f"\nMedia coverage (program_exercises_with_media, week 1):")
            print(f"  Total exercise rows : {total_ex_rows}")
            print(f"  With image_s3_path  : {with_image}  ({pct:.0f}%)")
            print(f"  With video_s3_path  : {with_video}")

            # Show first 3 media rows.
            if mrows:
                print("  Sample rows:")
                for r in mrows[:3]:
                    print(f"    {r.get('exercise_name_normalized')} → "
                          f"canonical={r.get('canonical_name')}  "
                          f"img={'Y' if r.get('image_s3_path') else 'N'}  "
                          f"vid={'Y' if r.get('video_s3_path') else 'N'}")
        except Exception as e:
            print(f"\nMedia coverage query failed (view may not index new rows yet): {e}")

    # 5. exercise_id resolution: canonical_name → exercise_library_cleaned.
    if default_id:
        try:
            mresp2 = sb.table("program_exercises_with_media").select(
                "canonical_name"
            ).eq("variant_id", default_id).execute()
            canon_names = list({
                r["canonical_name"] for r in (mresp2.data or []) if r.get("canonical_name")
            })
            if canon_names:
                lib_resp = sb.table("exercise_library_cleaned").select(
                    "id, name"
                ).in_("name", canon_names[:20]).execute()
                resolved = len(lib_resp.data or [])
                print(f"\nexercise_id resolution: {resolved}/{len(canon_names)} canonical names "
                      f"resolved in exercise_library_cleaned")
        except Exception as e:
            print(f"\nexercise_id resolution query failed: {e}")

    print(f"\n{'='*60}")
    print("VERIFICATION COMPLETE")
    print(f"{'='*60}")


# ── CLI ────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate variant libraries for Zealova curated programs."
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--program-id", metavar="UUID",
        help="Generate variants for a single curated program by id",
    )
    group.add_argument(
        "--all", action="store_true",
        help="Generate variants for all 16 non-fixed curated programs. "
             "DO NOT run without team-lead approval — expensive.",
    )
    parser.add_argument(
        "--smoke-test", action="store_true",
        help="Restrict matrix to weeks={1,2}, sessions={3} for a fast/cheap test run",
    )
    args = parser.parse_args()

    print(f"generate_curated_variants.py")
    print(f"Model: {GEMINI_MODEL}")
    if args.smoke_test:
        print("Mode:  SMOKE TEST (weeks={{1,2}}, sessions={{3}})")

    if args.program_id:
        if args.program_id in FIXED_PROGRAM_IDS:
            print(f"ERROR: {args.program_id} is a fixed program — no variants generated")
            sys.exit(1)
        result = generate_for_program(args.program_id, smoke_test=args.smoke_test)
        if args.smoke_test and not result.get("error") and not result.get("skipped"):
            run_smoke_verification(args.program_id)
        print(f"\nResult: {json.dumps(result, indent=2)}")
    else:
        # --all: loop all 16 non-fixed programs in order
        grand_total = 0.0
        for pid in ALL_TARGET_IDS:
            r = generate_for_program(pid, smoke_test=args.smoke_test)
            grand_total += r.get("total_cost", 0.0)
        print(f"\nGrand total cost: ${grand_total:.4f}")


if __name__ == "__main__":
    main()
