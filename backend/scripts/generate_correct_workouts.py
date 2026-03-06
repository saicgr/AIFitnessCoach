#!/usr/bin/env python3
"""
Generate Correct Workout Data for All 574 Branded Programs
============================================================
This script generates UPDATE SQL to fix the program_variant_weeks table
which currently has templated/identical workout data across all programs.

Each program gets researched, program-specific workout content.

Usage:
    python3 generate_correct_workouts.py > ../migrations/1576_fix_all_workout_data.sql
"""

import json
import importlib
import importlib.util
import sys
from pathlib import Path

# Import shared exercise library
from exercise_lib import *

###############################################################################
# PROGRAM-SPECIFIC WORKOUT DEFINITIONS (core programs)
###############################################################################

def _phul_workouts():
    """PHUL: Power Hypertrophy Upper Lower - 4 days."""
    return [
        workout("Power Upper", "strength", 60, [
            BARBELL_BENCH(4, 5, 180, "Heavy, 85-90% 1RM"),
            BARBELL_ROW(4, 5, 180, "Match bench weight progression"),
            BARBELL_OHP(3, 6, 120, "Moderate-heavy"),
            BARBELL_CURL(3, 8, 60, "Moderate"),
            SKULL_CRUSHER(3, 8, 60, "EZ-bar"),
        ]),
        workout("Power Lower", "strength", 60, [
            BARBELL_SQUAT(4, 5, 180, "Heavy, 85-90% 1RM"),
            DEADLIFT(3, 5, 240, "Heavy, work up to top set"),
            LEG_PRESS(4, 5, 120, "Heavy"),
            LEG_CURL(3, 8, 60, "Moderate-heavy"),
            CALF_RAISE(4, 8, 45, "Heavy, 6-10 reps"),
        ]),
        workout("Hypertrophy Upper", "hypertrophy", 60, [
            DB_INCLINE_PRESS(3, 12, 60, "Moderate, feel the stretch"),
            CABLE_ROW(3, 12, 60, "Moderate, squeeze back"),
            DB_OHP(3, 12, 60, "Controlled tempo"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict form"),
            DB_CURL(3, 12, 45, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate, full extension"),
        ]),
        workout("Hypertrophy Lower", "hypertrophy", 60, [
            FRONT_SQUAT(3, 10, 90, "Moderate, upright torso"),
            RDL(3, 12, 90, "Moderate, slow eccentric"),
            LEG_EXT(3, 15, 45, "Moderate, squeeze at top"),
            LEG_CURL(3, 15, 45, "Moderate, full ROM"),
            HIP_THRUST(3, 12, 60, "Moderate-heavy"),
            CALF_RAISE(4, 15, 30, "Moderate, full stretch"),
        ]),
    ]

def _reddit_ppl_workouts():
    """Reddit PPL (Metallicadpa) - 6 days."""
    return [
        workout("Push A (Bench Focus)", "strength", 60, [
            BARBELL_BENCH(4, 5, 180, "Linear progression +2.5lb/session"),
            BARBELL_OHP(3, 10, 90, "Volume work"),
            DB_INCLINE_PRESS(3, 10, 60, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Superset with lateral raise"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            TRICEP_OVERHEAD(3, 12, 45, "Cable or dumbbell"),
        ]),
        workout("Pull A (Deadlift Focus)", "strength", 60, [
            DEADLIFT(1, 5, 300, "Linear progression +5lb/session"),
            BARBELL_ROW(3, 10, 90, "Moderate weight"),
            PULLUP(3, 10, 90, "Or lat pulldown"),
            FACE_PULL(5, 20, 30, "Light, high reps for shoulder health"),
            DB_CURL(4, 10, 45, "Moderate"),
            HAMMER_CURL(4, 10, 45, "Moderate"),
        ]),
        workout("Legs A (Squat Focus)", "strength", 60, [
            BARBELL_SQUAT(3, 5, 180, "Linear progression +2.5lb/session"),
            RDL(3, 10, 90, "Moderate, hamstring focus"),
            LEG_PRESS(3, 10, 90, "Heavy"),
            LEG_CURL(3, 10, 60, "Moderate"),
            CALF_RAISE(5, 12, 30, "Moderate, full ROM"),
        ]),
        workout("Push B (OHP Focus)", "strength", 60, [
            BARBELL_OHP(4, 5, 180, "Linear progression +2.5lb/session"),
            BARBELL_BENCH(3, 10, 90, "Volume work"),
            DB_INCLINE_PRESS(3, 10, 60, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Superset with lateral raise"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            TRICEP_OVERHEAD(3, 12, 45, "Cable or dumbbell"),
        ]),
        workout("Pull B (Row Focus)", "strength", 60, [
            BARBELL_ROW(4, 5, 180, "Heavy barbell rows"),
            LAT_PULLDOWN(3, 10, 60, "Wide grip"),
            CABLE_ROW(3, 10, 60, "Close grip, squeeze"),
            FACE_PULL(5, 20, 30, "Light, shoulder health"),
            BARBELL_CURL(4, 10, 45, "Moderate"),
            HAMMER_CURL(4, 10, 45, "Moderate"),
        ]),
        workout("Legs B (Volume)", "strength", 60, [
            BARBELL_SQUAT(3, 5, 180, "Same weight as Legs A"),
            SUMO_DEADLIFT(3, 10, 90, "Moderate, glute focus"),
            LEG_EXT(3, 10, 60, "Moderate, squeeze"),
            LEG_CURL(3, 10, 60, "Moderate"),
            CALF_RAISE(5, 12, 30, "Moderate, full ROM"),
        ]),
    ]

def _classic_5x5_workouts():
    """StrongLifts/Classic 5x5 - 3 days alternating A/B."""
    return [
        workout("Workout A", "strength", 45, [
            BARBELL_SQUAT(5, 5, 180, "Add 5lb every session"),
            BARBELL_BENCH(5, 5, 180, "Add 5lb every session"),
            BARBELL_ROW(5, 5, 180, "Add 5lb every session"),
        ]),
        workout("Workout B", "strength", 45, [
            BARBELL_SQUAT(5, 5, 180, "Add 5lb every session"),
            BARBELL_OHP(5, 5, 180, "Add 5lb every session"),
            DEADLIFT(1, 5, 300, "Add 10lb every session"),
        ]),
        workout("Workout A", "strength", 45, [
            BARBELL_SQUAT(5, 5, 180, "Add 5lb every session"),
            BARBELL_BENCH(5, 5, 180, "Add 5lb every session"),
            BARBELL_ROW(5, 5, 180, "Add 5lb every session"),
        ]),
    ]

def _gzclp_workouts():
    """GZCLP - 4 days with T1/T2/T3 tiers."""
    return [
        workout("Day 1: T1 Squat", "strength", 55, [
            BARBELL_SQUAT(5, 3, 180, "T1: 5x3, progress to 6x2 then 10x1"),
            BARBELL_BENCH(3, 10, 90, "T2: 3x10, progress to 3x8 then 3x6"),
            LAT_PULLDOWN(3, 15, 45, "T3: 3x15+, AMRAP last set"),
        ]),
        workout("Day 2: T1 OHP", "strength", 55, [
            BARBELL_OHP(5, 3, 180, "T1: 5x3"),
            DEADLIFT(3, 10, 120, "T2: 3x10"),
            DB_ROW(3, 15, 45, "T3: 3x15+, AMRAP last set"),
        ]),
        workout("Day 3: T1 Bench", "strength", 55, [
            BARBELL_BENCH(5, 3, 180, "T1: 5x3"),
            BARBELL_SQUAT(3, 10, 90, "T2: 3x10"),
            LAT_PULLDOWN(3, 15, 45, "T3: 3x15+, AMRAP last set"),
        ]),
        workout("Day 4: T1 Deadlift", "strength", 55, [
            DEADLIFT(5, 3, 240, "T1: 5x3"),
            BARBELL_OHP(3, 10, 90, "T2: 3x10"),
            DB_ROW(3, 15, 45, "T3: 3x15+, AMRAP last set"),
        ]),
    ]

def _nsuns_531_workouts():
    """nSuns 5/3/1 - 5 day LP variant."""
    return [
        workout("Day 1: Bench + OHP", "strength", 75, [
            BARBELL_BENCH(9, 5, 120, "5/3/1 progression: work up to AMRAP top set"),
            BARBELL_OHP(8, 5, 90, "T2: follow prescribed percentages"),
            DB_INCLINE_PRESS(3, 10, 60, "Accessory"),
            TRICEP_PUSHDOWN(3, 15, 45, "Accessory"),
            FACE_PULL(3, 20, 30, "Prehab"),
        ]),
        workout("Day 2: Squat + Sumo DL", "strength", 75, [
            BARBELL_SQUAT(9, 5, 120, "5/3/1 progression: AMRAP top set"),
            SUMO_DEADLIFT(8, 5, 90, "T2: back-off volume"),
            LEG_PRESS(3, 10, 90, "Accessory"),
            LEG_CURL(3, 12, 60, "Accessory"),
            HANGING_LEG_RAISE(3, 15, 45, "Core"),
        ]),
        workout("Day 3: OHP + Incline", "strength", 75, [
            BARBELL_OHP(9, 5, 120, "5/3/1 progression: AMRAP top set"),
            INCLINE_BENCH(8, 5, 90, "T2 close-grip or incline"),
            DB_LATERAL_RAISE(4, 15, 30, "Accessory"),
            PULLUP(3, 10, 60, "Accessory"),
            FACE_PULL(3, 20, 30, "Prehab"),
        ]),
        workout("Day 4: Deadlift + Front Squat", "strength", 75, [
            DEADLIFT(9, 5, 150, "5/3/1 progression: AMRAP top set"),
            FRONT_SQUAT(8, 5, 90, "T2 front squat volume"),
            BARBELL_ROW(3, 10, 60, "Accessory"),
            RDL(3, 10, 60, "Accessory"),
            HANGING_LEG_RAISE(3, 15, 45, "Core"),
        ]),
        workout("Day 5: Bench + CG Bench", "strength", 75, [
            BARBELL_BENCH(9, 5, 120, "5/3/1 progression: AMRAP top set"),
            CLOSE_GRIP_BENCH(8, 5, 90, "T2 tricep focus"),
            DB_BENCH(3, 12, 60, "Accessory"),
            DB_CURL(3, 12, 45, "Accessory"),
            FACE_PULL(3, 20, 30, "Prehab"),
        ]),
    ]

def _phat_workouts():
    """PHAT - 5 days: 2 power + 3 hypertrophy."""
    return [
        workout("Upper Power", "strength", 70, [
            BARBELL_ROW(3, 5, 180, "Heavy, power focus"),
            PULLUP(2, 8, 90, "Weighted if possible"),
            BARBELL_BENCH(3, 5, 180, "Heavy, power focus"),
            DIP(2, 8, 90, "Weighted if possible"),
            BARBELL_CURL(2, 8, 60, "Heavy"),
            SKULL_CRUSHER(2, 8, 60, "Heavy"),
        ]),
        workout("Lower Power", "strength", 70, [
            BARBELL_SQUAT(3, 5, 180, "Heavy, power focus"),
            HACK_SQUAT(2, 8, 120, "Heavy"),
            LEG_EXT(2, 8, 60, "Speed reps: explosive"),
            RDL(3, 8, 120, "Heavy"),
            LEG_CURL(2, 8, 60, "Speed reps"),
            CALF_RAISE(3, 8, 60, "Heavy"),
        ]),
        workout("Back & Shoulders Hypertrophy", "hypertrophy", 70, [
            BARBELL_ROW(6, 3, 60, "Speed sets: 65-70% of power day"),
            LAT_PULLDOWN(3, 12, 60, "Moderate, squeeze"),
            CABLE_ROW(3, 12, 60, "Close grip"),
            DB_OHP(3, 12, 60, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
        workout("Lower Hypertrophy", "hypertrophy", 70, [
            BARBELL_SQUAT(6, 3, 60, "Speed sets: 65-70% of power day"),
            LEG_PRESS(3, 15, 60, "Moderate, high reps"),
            LEG_EXT(3, 15, 45, "Moderate, squeeze"),
            RDL(3, 12, 60, "Moderate"),
            LEG_CURL(3, 15, 45, "Moderate"),
            CALF_RAISE(4, 12, 30, "Moderate, pause at top"),
        ]),
        workout("Chest & Arms Hypertrophy", "hypertrophy", 70, [
            BARBELL_BENCH(6, 3, 60, "Speed sets: 65-70% of power day"),
            DB_INCLINE_PRESS(3, 12, 60, "Moderate, stretch at bottom"),
            CABLE_FLY(3, 15, 45, "Light, max squeeze"),
            DB_CURL(3, 12, 45, "Moderate"),
            HAMMER_CURL(2, 15, 30, "Light"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
            TRICEP_OVERHEAD(2, 15, 30, "Light, full stretch"),
        ]),
    ]

def _531_workouts():
    """5/3/1 (Wendler) - 4 days with BBB assistance."""
    return [
        workout("Day 1: OHP + BBB Bench", "strength", 60, [
            BARBELL_OHP(3, 5, 180, "5/3/1: Week 1: 5x65%, 5x75%, 5+x85%"),
            BARBELL_BENCH(5, 10, 90, "BBB: 5x10 @ 50-60% of TM"),
            DB_LATERAL_RAISE(3, 15, 30, "Accessory"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
        workout("Day 2: Deadlift + BBB Squat", "strength", 60, [
            DEADLIFT(3, 5, 240, "5/3/1: Week 1: 5x65%, 5x75%, 5+x85%"),
            BARBELL_SQUAT(5, 10, 90, "BBB: 5x10 @ 50-60% of TM"),
            HANGING_LEG_RAISE(3, 15, 45, "Accessory"),
            RDL(3, 10, 60, "Light accessory"),
        ]),
        workout("Day 3: Bench + BBB OHP", "strength", 60, [
            BARBELL_BENCH(3, 5, 180, "5/3/1: Week 1: 5x65%, 5x75%, 5+x85%"),
            BARBELL_OHP(5, 10, 90, "BBB: 5x10 @ 50-60% of TM"),
            DB_ROW(3, 12, 60, "Accessory"),
            TRICEP_PUSHDOWN(3, 15, 45, "Accessory"),
        ]),
        workout("Day 4: Squat + BBB Deadlift", "strength", 60, [
            BARBELL_SQUAT(3, 5, 180, "5/3/1: Week 1: 5x65%, 5x75%, 5+x85%"),
            DEADLIFT(5, 10, 120, "BBB: 5x10 @ 50-60% of TM"),
            LEG_CURL(3, 12, 60, "Accessory"),
            CALF_RAISE(4, 15, 30, "Accessory"),
        ]),
    ]

def _upper_lower_4day():
    """Generic Upper/Lower 4-day split."""
    return [
        workout("Upper A (Strength)", "strength", 55, [
            BARBELL_BENCH(4, 6, 120, "Heavy compound"),
            BARBELL_ROW(4, 6, 120, "Match bench progression"),
            BARBELL_OHP(3, 8, 90, "Moderate-heavy"),
            PULLUP(3, 8, 90, "Or lat pulldown"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
        workout("Lower A (Strength)", "strength", 55, [
            BARBELL_SQUAT(4, 6, 180, "Heavy compound"),
            RDL(3, 8, 90, "Hamstring focus"),
            LEG_PRESS(3, 10, 90, "Volume"),
            CALF_RAISE(4, 12, 30, "Moderate"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
        workout("Upper B (Hypertrophy)", "hypertrophy", 55, [
            DB_INCLINE_PRESS(3, 12, 60, "Moderate"),
            CABLE_ROW(3, 12, 60, "Moderate"),
            DB_OHP(3, 12, 60, "Moderate"),
            DB_CURL(3, 12, 45, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
        ]),
        workout("Lower B (Hypertrophy)", "hypertrophy", 55, [
            FRONT_SQUAT(3, 10, 90, "Moderate"),
            DB_RDL(3, 12, 60, "Moderate"),
            LEG_EXT(3, 15, 45, "Moderate"),
            LEG_CURL(3, 15, 45, "Moderate"),
            CALF_RAISE(4, 15, 30, "Moderate"),
        ]),
    ]

def _ppl_6day():
    """Generic PPL 6-day split."""
    return [
        workout("Push Day", "strength", 55, [
            BARBELL_BENCH(4, 8, 120, "Progressive overload"),
            BARBELL_OHP(3, 10, 90, "Moderate"),
            DB_INCLINE_PRESS(3, 12, 60, "Moderate"),
            CABLE_FLY(3, 15, 45, "Light, squeeze"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
        ]),
        workout("Pull Day", "strength", 55, [
            DEADLIFT(3, 5, 180, "Heavy compound"),
            PULLUP(3, 8, 90, "Or lat pulldown"),
            CABLE_ROW(3, 12, 60, "Moderate"),
            FACE_PULL(3, 15, 30, "Prehab"),
            DB_CURL(3, 12, 45, "Moderate"),
            HAMMER_CURL(3, 12, 45, "Moderate"),
        ]),
        workout("Leg Day", "strength", 55, [
            BARBELL_SQUAT(4, 8, 180, "Progressive overload"),
            RDL(3, 10, 90, "Moderate"),
            LEG_PRESS(3, 12, 90, "Heavy"),
            LEG_CURL(3, 12, 60, "Moderate"),
            CALF_RAISE(4, 15, 30, "Moderate"),
            HANGING_LEG_RAISE(3, 12, 45, "Core"),
        ]),
        workout("Push Day B", "strength", 55, [
            BARBELL_OHP(4, 8, 120, "Progressive overload"),
            DB_BENCH(3, 10, 60, "Moderate"),
            DB_INCLINE_PRESS(3, 12, 60, "Moderate"),
            CABLE_FLY(3, 15, 45, "Light, squeeze"),
            TRICEP_OVERHEAD(3, 12, 45, "Moderate"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
        ]),
        workout("Pull Day B", "strength", 55, [
            BARBELL_ROW(4, 8, 120, "Heavy"),
            LAT_PULLDOWN(3, 10, 60, "Wide grip"),
            CABLE_ROW(3, 12, 60, "Close grip"),
            FACE_PULL(3, 15, 30, "Prehab"),
            BARBELL_CURL(3, 10, 45, "Moderate"),
            HAMMER_CURL(3, 12, 45, "Moderate"),
        ]),
        workout("Leg Day B", "strength", 55, [
            FRONT_SQUAT(4, 8, 120, "Moderate"),
            SUMO_DEADLIFT(3, 8, 120, "Moderate"),
            LEG_EXT(3, 12, 60, "Moderate"),
            LEG_CURL(3, 12, 60, "Moderate"),
            HIP_THRUST(3, 12, 60, "Moderate"),
            CALF_RAISE(4, 15, 30, "Moderate"),
        ]),
    ]


###############################################################################
# CORE PROGRAM MAPPING
###############################################################################

PROGRAM_WORKOUTS = {
    "PHUL": _phul_workouts,
    "Reddit PPL": _reddit_ppl_workouts,
    "Classic 5x5 Beginner": _classic_5x5_workouts,
    "GZCLP": _gzclp_workouts,
    "nSuns 5/3/1": _nsuns_531_workouts,
    "PHAT": _phat_workouts,
    "High Volume 5/3/1 Variant": _531_workouts,
    "6-Day PPL Split": _ppl_6day,
    "Upper Lower Linear": _upper_lower_4day,
}


###############################################################################
# COLLECT BATCH FILES
###############################################################################

def collect_all_workouts():
    """Import all batch_*.py files and merge their BATCH_WORKOUTS dicts."""
    all_workouts = dict(PROGRAM_WORKOUTS)
    scripts_dir = Path(__file__).parent
    for batch_file in sorted(scripts_dir.glob("batch_*.py")):
        module_name = batch_file.stem
        spec = importlib.util.spec_from_file_location(module_name, batch_file)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        if hasattr(mod, "BATCH_WORKOUTS"):
            all_workouts.update(mod.BATCH_WORKOUTS)
            print(f"-- Loaded {len(mod.BATCH_WORKOUTS)} programs from {batch_file.name}",
                  file=sys.stderr)
    return all_workouts


###############################################################################
# SQL GENERATION
###############################################################################

def escape_sql(s):
    return s.replace("'", "''")

def generate_update_sql(program_name, workouts_json_str):
    """Generate UPDATE SQL to fix workouts for all rows of a program."""
    escaped_json = escape_sql(workouts_json_str)
    return f"""UPDATE program_variant_weeks
SET workouts = '{escaped_json}'::jsonb
WHERE program_name = '{escape_sql(program_name)}';\n"""


def main():
    """Generate SQL for all programs that have defined workouts."""
    all_workouts = collect_all_workouts()

    print("-- ============================================================")
    print("-- Fix program_variant_weeks: Replace template workouts with")
    print("-- researched, program-specific workout content")
    print(f"-- Total programs: {len(all_workouts)}")
    print("-- Generated by generate_correct_workouts.py")
    print("-- ============================================================")
    print()
    print("BEGIN;")
    print()

    fixed = 0
    for program_name, workout_fn in sorted(all_workouts.items()):
        workouts = workout_fn() if callable(workout_fn) else workout_fn
        workouts_json = json.dumps(workouts, ensure_ascii=False)
        print(f"-- Program: {program_name}")
        print(generate_update_sql(program_name, workouts_json))
        fixed += 1

    print("COMMIT;")
    print()
    print(f"-- Fixed {fixed} programs")

if __name__ == "__main__":
    main()
