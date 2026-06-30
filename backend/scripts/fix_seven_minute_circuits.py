#!/usr/bin/env python3
"""
Rebuild the 7-Minute Upper/Lower programs as FIXED bodyweight TIMER circuits.

WHY (2026-06-30): the 7-minute programs were wrong — their default variant was a
60-min sets×reps plan with dumbbells/pull-ups, and the base blob had the right
"Circuit" structure but empty exercise names. They should be the classic ACSM
"Scientific 7-Minute Workout": bodyweight moves, 30s work / 10s rest between
exercises, ordered to alternate muscle groups, repeat 2-3 rounds as you progress.

This script (idempotent):
  • rewrites programs.workouts as a FIXED program = 5 circuit sessions (rotating
    A/B) of ~10 bodyweight moves each, every move reps="30 seconds" + explicit
    duration_seconds:30 + tracking_type:"time", rest_seconds:10. (5 sessions ×
    duration_weeks=2 = 10 scheduled workouts.)
  • sets default_variant_id=NULL, variant_base_id=NULL, has_workouts=true,
    progression_note (makes it schedule from the base blob like 30-Day Plank).
  • DELETES the mangled program_variants + program_variant_weeks for the old
    variant_base_id so the picker never offers a wrong variant.

Run: python3 scripts/fix_seven_minute_circuits.py [--dry-run]
Verify after with the SQL in the plan file.
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

# name -> (exercise_id, body_part, primary_muscle) — every row verified tagged + media.
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
    "Abdominal Crunches": ("5454b22a-d25e-4b7a-924b-b3da28422470", "waist", "Abdominals"),
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

# Each circuit: list of (exercise name, reps display). "30 seconds" => timed move.
# NOTE: avoid "Abdominal Crunches"/"Crunch Floor" — the tracking-metric name lexicon
# misclassifies them as `distance` (would show a meters input instead of a timer).
# "Bicycles" / "Bird Dog" / "Side Plank" / "Mountain Climber" all derive to `time`.
UPPER_A = [
    ("Jumping Jack", "30 seconds"), ("Push-Up", "30 seconds"),
    ("Floor Tricep Dip", "30 seconds"), ("Mountain Climber", "30 seconds"),
    ("Pike Push-Up", "30 seconds"), ("Superman", "30 seconds"),
    ("Bicycles", "30 seconds"), ("Diamond Push-Up", "30 seconds"),
    ("Side Plank", "20 seconds per side"), ("High Knees", "30 seconds"),
]
UPPER_B = [
    ("Jumping Jack", "30 seconds"), ("Decline Push-Up", "30 seconds"),
    ("Bench Dip On Floor", "30 seconds"), ("Mountain Climber", "30 seconds"),
    ("Pike Push-Up", "30 seconds"), ("Bird Dog", "20 seconds per side"),
    ("Bicycles", "30 seconds"), ("Push-Up", "30 seconds"),
    ("Side Plank", "20 seconds per side"), ("High Knees", "30 seconds"),
]
LOWER_A = [
    ("Jumping Jack", "30 seconds"), ("Air Squat", "30 seconds"),
    ("Forward Lunge", "20 seconds per side"),
    ("Glute Bridge With Abduction Bodyweight", "30 seconds"),
    ("Wall Sit", "30 seconds"), ("High Knees", "30 seconds"),
    ("Jump Squat", "30 seconds"), ("Standing Calf Raise", "30 seconds"),
    ("Mountain Climber", "30 seconds"), ("Side Plank", "20 seconds per side"),
]
LOWER_B = [
    ("Jumping Jack", "30 seconds"), ("Air Squat", "30 seconds"),
    ("Forward Lunge", "20 seconds per side"),
    ("Glute Bridge With Abduction Bodyweight", "30 seconds"),
    ("Wall Sit", "30 seconds"), ("Burpee", "30 seconds"),
    ("Jump Squat", "30 seconds"), ("Standing Calf Raise", "30 seconds"),
    ("Bicycles", "30 seconds"), ("Side Plank", "20 seconds per side"),
]


def _exercise(name: str, reps: str) -> dict:
    eid, bp, pm = PALETTE[name]
    per_side = "per side" in reps
    return {
        "name": name,
        "exercise_name": name,           # both keys (importer reads either)
        "exercise_id": eid,
        "sets": 1,
        "reps": reps,                    # "30 seconds" -> reps_spec -> timer at serve time
        "duration_seconds": 30,          # explicit belt-and-suspenders
        "tracking_type": "time",
        "is_timed": True,
        "rest_seconds": 10,              # inter-exercise rest (ACSM protocol)
        "equipment": "Bodyweight",
        "body_part": bp,
        "primary_muscle": pm,
        "per_side": per_side,
        "notes": "Max effort for the full interval, then 10s rest.",
    }


def _session(label: str, circuit: list) -> dict:
    return {
        "workout_name": label,
        "name": label,
        "type": "HIIT",                  # bodyweight timed circuit
        "duration_minutes": 7,
        "rounds_note": "Repeat the circuit 2-3 rounds as you get fitter.",
        "exercises": [_exercise(n, r) for n, r in circuit],
    }


def build_blob(focus: str) -> dict:
    """5 sessions (A,B,A,B,A) -> with duration_weeks=2 = 10 scheduled workouts."""
    a, b = (UPPER_A, UPPER_B) if focus == "upper" else (LOWER_A, LOWER_B)
    word = "Upper" if focus == "upper" else "Lower"
    seq = [a, b, a, b, a]
    workouts = []
    for i, circ in enumerate(seq):
        tag = "A" if circ is a else "B"
        workouts.append(_session(f"7-Minute {word} Circuit {tag}", circ))
        workouts[-1]["day"] = i + 1
    return {"workouts": workouts}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    from supabase import create_client
    sb = create_client(SUPABASE_URL, SUPABASE_KEY)

    for pid, focus, word in ((UPPER_ID, "upper", "Upper"), (LOWER_ID, "lower", "Lower")):
        row = sb.table("programs").select(
            "id, program_name, variant_base_id, default_variant_id"
        ).eq("id", pid).single().execute().data
        old_base = row.get("variant_base_id")
        blob = build_blob(focus)
        n_ex = sum(len(s["exercises"]) for s in blob["workouts"])
        print(f"\n▶ {row['program_name']}: {len(blob['workouts'])} circuit sessions, "
              f"{n_ex} timed moves; old variant_base={old_base}")
        if args.dry_run:
            print("   (dry-run — no writes)")
            continue

        # 1) delete mangled variants + their weeks for this program's family
        if old_base:
            vids = [v["id"] for v in (sb.table("program_variants").select("id")
                    .eq("base_program_id", old_base).execute().data or [])]
            for vid in vids:
                sb.table("program_variant_weeks").delete().eq("variant_id", vid).execute()
            if vids:
                sb.table("program_variants").delete().eq("base_program_id", old_base).execute()
            print(f"   deleted {len(vids)} variants + their weeks")

        # 2) rewrite the program: fixed timer circuit, schedule from base blob
        sb.table("programs").update({
            "workouts": blob,
            "default_variant_id": None,
            "variant_base_id": None,
            "has_workouts": True,
            "session_duration_minutes": 7,
            "duration_weeks": 2,
            "sessions_per_week": 5,
            "progression_note": "Each move is 30 seconds of max effort with 10 "
                                "seconds rest, in an order that alternates muscle "
                                "groups. Repeat the circuit 2-3 rounds as you get "
                                "fitter.",
        }).eq("id", pid).execute()
        print("   ✅ rewritten as fixed 7-minute timer circuit")


if __name__ == "__main__":
    main()
