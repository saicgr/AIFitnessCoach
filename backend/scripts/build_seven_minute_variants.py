#!/usr/bin/env python3
"""
Give the 7-Minute Upper/Lower programs REAL variation — a proper variant matrix
(week-count × frequency) with distinct daily circuits and week-over-week
progression, while KEEPING the fixed ACSM bodyweight timer-circuit format.

WHY (2026-06-30): after `fix_seven_minute_circuits.py` these two programs became
fixed base-blob circuits with NO variant library — so the app showed no
week-count / times-per-week picker, only 2 near-identical circuits (A/B) that
repeated verbatim across the week, and a "2 WK · 5×/WK" card that overstated the
(non-varying) content. The user asked for real variation like the other curated
programs.

WHAT this builds (deterministic — NO LLM):
  • 5 DISTINCT circuits per focus (A–E) so every weekly session differs.
  • A variant matrix: duration_weeks ∈ {1,2,4} × sessions_per_week ∈ {3,4,5}
    (intensity "Medium") = 9 variants per program → the app renders a real
    weeks + times/week picker (via _variant_options, filtered to non-empty).
  • Week-over-week progression: phase-labelled weeks (Foundation → Build →
    Peak), escalating rounds guidance, circuit-order rotation per week, and a
    harder-variant swap in the Peak phase (Push-Up→Diamond, Air Squat→Jump
    Squat, Jumping Jack→Burpee).
  • Every move carries reps="30 seconds"/duration_seconds/tracking_type:"time"/
    rest_seconds:10 so the active-workout timer renders (same as the base blob).
  • Media auto-maps: `program_exercises_with_media` is a VIEW keyed positionally
    on the exercises array; every palette move has a verified exercise_id + media,
    so no MV refresh is needed.

Idempotent: deletes any prior program_variants + program_variant_weeks whose
base_program_id == the program id, then rebuilds. Sets programs.variant_base_id =
program id, default_variant_id = the 2wk×5x variant (keeps the current card),
duration_weeks=2, sessions_per_week=5, session_duration_minutes=7.

Run:  python3 scripts/build_seven_minute_variants.py [--dry-run]
Verify after with the SQL printed at the end (or the plan file).
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))
from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

UPPER_ID = "0f9d9142-be65-4d13-aafc-223c96867d5c"
LOWER_ID = "5988380c-defa-49a5-b0d8-83edc2f03d09"

# name -> (exercise_id, body_part, primary_muscle) — every row verified tagged +
# media (same verified palette as fix_seven_minute_circuits.py).
PALETTE = {
    "Jumping Jack": ("fa1778bc-774d-4a50-b770-d77d03acbd4c", "full body", "Full Body"),
    "Push-Up": ("445e49e3-777b-4754-ab34-5b37a0a5b3f4", "chest", "Chest"),
    "Decline Push-Up": ("51dd998d-01b7-4322-a774-cf48ac115833", "chest", "Chest"),
    "Diamond Push-Up": ("be255cf5-d456-4e3b-9901-0a411079d3c1", "upper arms", "Triceps"),
    "Pike Push-Up": ("b5c8751d-2489-4571-a58e-537afee542fb", "shoulders", "Shoulders"),
    "Floor Tricep Dip": ("6d2ec965-0bfc-4793-9d18-6d87f20e0171", "upper arms", "Triceps"),
    "Bench Dip On Floor": ("884e6e2b-ef7a-489d-b8f4-63b8477a1138", "upper arms", "Triceps"),
    "Mountain Climber": ("3284b7dd-367d-471e-a1ff-ec34fcb633f9", "waist", "Abdominals"),
    "Superman": ("d67db642-0d4e-4b61-9a66-5210b14cb9f9", "back", "Lower Back"),
    "Bird Dog": ("21b355f3-8f63-49ed-8b0c-9c4efd19af0c", "full body", "Core"),
    "Bicycles": ("79b29d6f-98e3-4851-aade-b96e7fea6a58", "waist", "Abdominals"),
    "Side Plank": ("224d012e-6c66-4b03-876c-8ab461fce31b", "waist", "Core"),
    "High Knees": ("d9e75684-4be9-4071-9f40-3eec7c9fa7f4", "upper legs", "Hip Flexors"),
    "Air Squat": ("0498fe89-cf6f-4325-80e0-e510827dc870", "upper legs", "Quadriceps"),
    "Forward Lunge": ("87928423-9489-4783-a9bc-40e8edb53d60", "upper legs", "Quadriceps"),
    "Glute Bridge With Abduction Bodyweight": ("233924e9-0cf8-443c-9027-3d915e8eadad", "upper legs", "Glutes"),
    "Wall Sit": ("bb43b32a-c008-4c88-bd2f-e28d274238ed", "upper legs", "Quadriceps"),
    "Jump Squat": ("8a83a48a-e927-4104-8a78-f8ae6961887a", "upper legs", "Quadriceps"),
    "Standing Calf Raise": ("f9486c0c-c34f-4f84-a933-9e9ba5007a02", "lower legs", "Calves"),
    "Burpee": ("c4d421fe-3e28-471b-8a95-293f0733d161", "full body", "Full Body"),
}

# Moves worked one side at a time → half the interval per side.
PER_SIDE = {"Forward Lunge", "Side Plank", "Bird Dog"}

# Peak-phase intensifier: base move → harder variant (both in PALETTE + media).
HARDER = {
    "Push-Up": "Diamond Push-Up",
    "Decline Push-Up": "Diamond Push-Up",
    "Air Squat": "Jump Squat",
    "Jumping Jack": "Burpee",
}

# 5 DISTINCT circuits per focus (~10 timed bodyweight moves each, alternating
# muscle groups, ~7 minutes at 30s work / 10s rest). All names are in PALETTE.
LOWER_CIRCUITS = [
    # A
    ["Jumping Jack", "Air Squat", "Forward Lunge", "Glute Bridge With Abduction Bodyweight",
     "Wall Sit", "High Knees", "Jump Squat", "Standing Calf Raise", "Mountain Climber", "Side Plank"],
    # B
    ["Jumping Jack", "Air Squat", "Forward Lunge", "Glute Bridge With Abduction Bodyweight",
     "Wall Sit", "Burpee", "Jump Squat", "Standing Calf Raise", "Bicycles", "Side Plank"],
    # C
    ["High Knees", "Jump Squat", "Glute Bridge With Abduction Bodyweight", "Forward Lunge",
     "Wall Sit", "Mountain Climber", "Air Squat", "Standing Calf Raise", "Superman", "Side Plank"],
    # D
    ["Jumping Jack", "Forward Lunge", "Jump Squat", "Glute Bridge With Abduction Bodyweight",
     "Wall Sit", "High Knees", "Air Squat", "Standing Calf Raise", "Bird Dog", "Bicycles"],
    # E
    ["Burpee", "Air Squat", "Forward Lunge", "Glute Bridge With Abduction Bodyweight",
     "Wall Sit", "Jump Squat", "High Knees", "Standing Calf Raise", "Mountain Climber", "Superman"],
]
UPPER_CIRCUITS = [
    # A
    ["Jumping Jack", "Push-Up", "Floor Tricep Dip", "Mountain Climber", "Pike Push-Up",
     "Superman", "Bicycles", "Diamond Push-Up", "Side Plank", "High Knees"],
    # B
    ["Jumping Jack", "Decline Push-Up", "Bench Dip On Floor", "Mountain Climber", "Pike Push-Up",
     "Bird Dog", "Bicycles", "Push-Up", "Side Plank", "High Knees"],
    # C
    ["High Knees", "Push-Up", "Pike Push-Up", "Floor Tricep Dip", "Mountain Climber",
     "Superman", "Diamond Push-Up", "Bicycles", "Bench Dip On Floor", "Side Plank"],
    # D
    ["Jumping Jack", "Diamond Push-Up", "Bench Dip On Floor", "Mountain Climber", "Decline Push-Up",
     "Superman", "Pike Push-Up", "Bicycles", "Push-Up", "High Knees"],
    # E
    ["Burpee", "Push-Up", "Floor Tricep Dip", "Pike Push-Up", "Mountain Climber",
     "Diamond Push-Up", "Bird Dog", "Side Plank", "Decline Push-Up", "High Knees"],
]
CIRCUIT_TAGS = ["A", "B", "C", "D", "E"]

WEEKS_OPTIONS = [1, 2, 4]
FREQ_OPTIONS = [3, 4, 5]
DEFAULT_WEEKS = 2
DEFAULT_FREQ = 5


def _phase(week: int, total: int) -> tuple[str, str, int]:
    """(phase, rounds_note, is_peak) for week `week` of `total`."""
    frac = (week - 1) / max(total - 1, 1)
    if frac < 0.4:
        return ("Foundation", "Beginner pace — 2 rounds of the circuit, "
                "30s work / 10s rest between moves.", 0)
    if frac < 0.75:
        return ("Build", "3 rounds of the circuit — push the pace, keep the "
                "10s rest tight.", 0)
    return ("Peak", "3–4 rounds, minimal rest between moves. Max effort every "
            "interval.", 1)


def _exercise(name: str, peak: bool) -> dict:
    if peak and name in HARDER:
        name = HARDER[name]
    eid, bp, pm = PALETTE[name]
    per_side = name in PER_SIDE
    secs = 20 if per_side else 30
    reps = f"{secs} seconds per side" if per_side else f"{secs} seconds"
    return {
        "name": name,
        "exercise_name": name,
        "exercise_id": eid,
        "sets": 1,
        "reps": reps,
        "duration_seconds": secs,
        "tracking_type": "time",
        "is_timed": True,
        "rest_seconds": 10,
        "equipment": "Bodyweight",
        "body_part": bp,
        "primary_muscle": pm,
        "per_side": per_side,
        "notes": "Max effort for the full interval, then 10s rest.",
    }


def _session(label: str, circuit: list, peak: bool, rounds_note: str) -> dict:
    return {
        "name": label,
        "workout_name": label,
        "type": "HIIT",
        "duration_minutes": 7,
        "rounds_note": rounds_note,
        "warmup": [],
        "cooldown": [],
        "exercises": [_exercise(n, peak) for n in circuit],
    }


def build_week(focus_word: str, circuits: list, week: int, total: int,
               freq: int) -> tuple[dict, list]:
    """Return (variant_week_row_fields, workouts[]) for one week."""
    phase, rounds_note, peak = _phase(week, total)
    # Rotate the starting circuit per week so consecutive weeks feel fresh.
    n = len(circuits)
    workouts = []
    for i in range(freq):
        idx = (week - 1 + i) % n
        tag = CIRCUIT_TAGS[idx]
        label = f"7-Minute {focus_word} Circuit {tag}"
        workouts.append(_session(label, circuits[idx], bool(peak), rounds_note))
    return ({"phase": phase, "focus": f"{focus_word} body HIIT"}, workouts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    from supabase import create_client
    sb = create_client(SUPABASE_URL, SUPABASE_KEY)

    for pid, focus, word, circuits in (
        (UPPER_ID, "upper", "Upper", UPPER_CIRCUITS),
        (LOWER_ID, "lower", "Lower", LOWER_CIRCUITS),
    ):
        row = sb.table("programs").select(
            "id, program_name, program_category, editorial_name"
        ).eq("id", pid).single().execute().data
        category = row.get("program_category")
        editorial = row.get("editorial_name") or row.get("program_name")
        print(f"\n▶ {row['program_name']} ({category}) — building variant matrix")

        # program_variants.base_program_id + programs.variant_base_id both FK to
        # branded_programs.id. Each curated program gets its OWN dedicated,
        # HIDDEN (is_active=False) branded base named "<editorial> (Zealova
        # Library)" — same convention as generate_curated_variants.py — so its
        # variant library is isolated and it never surfaces in branded UI or the
        # library category counts. Idempotent: reuse the base if it already
        # exists.
        base_name = f"{editorial} (Zealova Library)"
        base = sb.table("branded_programs").select("id").eq(
            "name", base_name).limit(1).execute().data
        if base:
            base_id = base[0]["id"]
        elif args.dry_run:
            base_id = "<new-branded-base>"
        else:
            base_id = sb.table("branded_programs").insert({
                "name": base_name,
                "tagline": "Zealova library base — 7-minute bodyweight circuits.",
                "category": "bodyweight",
                "difficulty_level": "beginner",
                "duration_weeks": max(WEEKS_OPTIONS),
                "sessions_per_week": max(FREQ_OPTIONS),
                "split_type": "full_body",
                "goals": [],
                "requires_gym": False,
                "minimum_equipment": [],
                "is_active": False,   # never surface in branded-facing UI
                "is_featured": False,
                "is_premium": False,
            }).execute().data[0]["id"]
            print(f"   ✨ branded base {base_id}")

        # Idempotency: wipe any prior variants (+ their weeks) under this base.
        old = sb.table("program_variants").select("id").eq(
            "base_program_id", base_id).execute().data or [] if base else []
        if old and not args.dry_run:
            for v in old:
                sb.table("program_variant_weeks").delete().eq(
                    "variant_id", v["id"]).execute()
            sb.table("program_variants").delete().eq(
                "base_program_id", base_id).execute()
        if old:
            print(f"   cleared {len(old)} prior variants")

        default_variant_id = None
        n_variants = 0
        n_weeks_total = 0
        for weeks in WEEKS_OPTIONS:
            for freq in FREQ_OPTIONS:
                variant_name = f"7-Minute {word} Body — {weeks}wk × {freq}/wk"
                # First week's blob doubles as the variant.workouts summary.
                _, first_workouts = build_week(word, circuits, 1, weeks, freq)
                vrow_fields = {
                    "base_program_id": base_id,
                    "variant_name": variant_name,
                    "intensity_level": "Medium",
                    "duration_weeks": weeks,
                    "sessions_per_week": freq,
                    "session_duration_minutes": 7,
                    "program_category": category,
                    "workouts": {"workouts": first_workouts},
                }
                if args.dry_run:
                    n_variants += 1
                    n_weeks_total += weeks
                    continue
                vid = sb.table("program_variants").insert(
                    vrow_fields).execute().data[0]["id"]
                n_variants += 1
                week_rows = []
                for w in range(1, weeks + 1):
                    meta, workouts = build_week(word, circuits, w, weeks, freq)
                    week_rows.append({
                        "variant_id": vid,
                        "week_number": w,
                        "phase": meta["phase"],
                        "focus": meta["focus"],
                        "program_name": row["program_name"],
                        "variant_name": variant_name,
                        "category": category,
                        "workouts": workouts,
                    })
                    n_weeks_total += 1
                sb.table("program_variant_weeks").insert(week_rows).execute()
                if weeks == DEFAULT_WEEKS and freq == DEFAULT_FREQ:
                    default_variant_id = vid

        print(f"   built {n_variants} variants, {n_weeks_total} week rows")

        if args.dry_run:
            print("   (dry-run — no writes)")
            continue

        sb.table("programs").update({
            "variant_base_id": base_id,
            "default_variant_id": default_variant_id,
            "duration_weeks": DEFAULT_WEEKS,
            "sessions_per_week": DEFAULT_FREQ,
            "session_duration_minutes": 7,
            "has_workouts": True,
        }).eq("id", pid).execute()
        print(f"   ✅ default_variant_id={default_variant_id} "
              f"({DEFAULT_WEEKS}wk × {DEFAULT_FREQ}/wk)")

    print("\nVerify:\n"
          "  SELECT p.program_name, p.default_variant_id,\n"
          "         count(distinct v.id) n_variants, count(w.id) n_weeks\n"
          "  FROM programs p\n"
          "  JOIN program_variants v ON v.base_program_id = p.variant_base_id\n"
          "  LEFT JOIN program_variant_weeks w ON w.variant_id = v.id\n"
          f"  WHERE p.id IN ('{UPPER_ID}','{LOWER_ID}')\n"
          "  GROUP BY 1,2;")


if __name__ == "__main__":
    main()
