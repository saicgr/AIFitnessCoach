"""Full 100-scenario sweep for /api/v1/workouts/generate-stream.

Sequential, 5s pacing (well under the 15/min user limit) with auto-retry on
Vertex 429. Per-call CSV row + JSON dump; consolidates JSONs into the CSV
at the end and removes the json/ dir.

ETA: 100 × ~12s gen + 5s pacing ≈ 30 min (excluding any 429 retries).

Run:
    cd backend && .venv/bin/python scripts/run_generate_stream_full.py
"""
from __future__ import annotations

import argparse
import asyncio
import json
from typing import Any, Dict, List

import httpx

from datetime import datetime as _dt
from pathlib import Path as _P

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts._smoke_lib import (  # noqa: E402
    ACTIVE_PROFILE, BACKEND, RENDER, USER_ID,
    call_sse_with_retry, consolidate_and_cleanup,
    get_jwt, init_outputs, next_n_dates, resume_or_init_outputs,
    update_md_live_status, write_row, workout_summary,
)

_MD_PATH = _P("/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/scenarios/"
              "generate_stream_scenarios.md")

# --------------------------------------------------------------------------
# Equipment subsets (matches generate_stream_scenarios.md)
# --------------------------------------------------------------------------
E1_FULL = ["barbell", "dumbbells", "cable_machine", "squat_rack", "bench",
           "pull_up_bar", "kettlebell", "leg_press_machine", "lat_pulldown",
           "smith_machine", "treadmill", "rowing_machine", "stationary_bike",
           "elliptical", "resistance_bands"]
E2_BW: List[str] = []
E3_DB = ["dumbbells", "bench", "resistance_bands"]
E4_KB = ["kettlebell"]
E5_MACH = ["cable_machine", "leg_press_machine", "lat_pulldown", "smith_machine"]
E6_BANDS = ["resistance_bands"]
E7_NO_BB = ["dumbbells", "cable_machine", "bench", "pull_up_bar", "kettlebell",
            "lat_pulldown", "resistance_bands"]
E8_FW = ["barbell", "dumbbells", "kettlebell", "bench", "pull_up_bar"]
E9_DB1 = ["dumbbells"]
E10_HOME = ["dumbbells", "resistance_bands", "pull_up_bar"]
E11_CARDIO = ["treadmill", "rowing_machine", "stationary_bike", "elliptical"]
E12_BW_BANDS = ["resistance_bands"]


def _sc(idx: int, block: int, *, label: str, fitness_level: str, intensity: str,
        duration: int, goal: str, focus: str, equipment: List[str],
        date_str: str, injuries: List[str] = None,  # noqa: B006
        **extra: Any) -> Dict[str, Any]:
    """Build a scenario.

    NOTE: We OMIT `equipment` from the body when we want the server to use the
    user's gym profile (avoids the body-only fast-path bug when equipment+
    fitness_level+goals are all set). Default behavior here: SEND equipment so
    we have the AI scope to test variation. Bug only crashes when ALL THREE
    of {fitness_level, goals, equipment} are populated AND the if-branch fails
    on `training_split` etc. — fixed locally but Render may not have deployed.
    Mitigation: omit `goals` instead of equipment; the server falls back to user
    goals from DB.
    """
    body: Dict[str, Any] = {
        "user_id": USER_ID,
        "gym_profile_id": ACTIVE_PROFILE,
        "fitness_level": fitness_level,
        "duration_minutes": duration,
        "focus_areas": [focus],
        # `equipment` sent → server uses these. To dodge fast-path bug we
        # OMIT goals; server reads goals from user record.
        "equipment": equipment,
        "scheduled_date": date_str,
        "force_non_preferred_day": True,
        # `intensity` is NOT a request field; it's derived. We label scenarios
        # with intent only — the server picks intensity from fitness_level
        # unless the user has prefs set.
    }
    if injuries:
        body["injuries"] = injuries
    body.update(extra)
    return {"idx": idx, "block": block, "label": label, "body": body}


def build_100() -> List[Dict[str, Any]]:
    """100 scenarios across blocks. Equipment varied so no 5 consecutive match."""
    s: List[Dict[str, Any]] = []
    dates = next_n_dates(100, start_offset=1)
    i = 0

    # Block 1 — Fitness × Intensity × Duration × Equipment (1-25)
    plan_b1 = [
        ("beginner", 15, "general_fitness", "full_body", E2_BW, "easy bw 15"),
        ("beginner", 30, "mobility", "core", E12_BW_BANDS, "easy bw+bands 30"),
        ("beginner", 30, "strength", "full_body", E3_DB, "med db 30"),
        ("beginner", 45, "hypertrophy", "upper", E10_HOME, "med home 45"),
        ("beginner", 45, "fat_loss", "full_body", E1_FULL, "med full 45"),
        ("beginner", 30, "strength", "push", E8_FW, "hard fw 30 push"),
        ("beginner", 45, "hypertrophy", "legs", E5_MACH, "hard mach 45 legs"),
        ("beginner", 60, "endurance", "cardio", E11_CARDIO, "hard cardio 60"),
        ("beginner", 90, "general_fitness", "full_body", E1_FULL, "hard 90 edge"),
        ("beginner", 45, "strength", "push", E2_BW, "hell bw 45"),
        ("intermediate", 20, "mobility", "mobility", E6_BANDS, "easy bands 20"),
        ("intermediate", 30, "hypertrophy", "pull", E9_DB1, "med db1 30"),
        ("intermediate", 45, "strength", "legs", E1_FULL, "med full 45 legs"),
        ("intermediate", 60, "hypertrophy", "upper", E7_NO_BB, "med no_bb 60 upper"),
        ("intermediate", 75, "endurance", "full_body", E11_CARDIO, "med cardio 75"),
        ("intermediate", 30, "power", "legs", E4_KB, "hard kb 30 power"),
        ("intermediate", 45, "hypertrophy", "push", E1_FULL, "hard full 45 push"),
        ("intermediate", 60, "strength", "full_body", E8_FW, "hard fw 60 full"),
        ("intermediate", 90, "athletic_performance", "full_body", E1_FULL, "hard 90 athletic"),
        ("intermediate", 45, "fat_loss", "full_body", E2_BW, "hell bw 45 fatloss"),
        ("advanced", 30, "mobility", "mobility", E6_BANDS, "med bands 30 adv"),
        ("advanced", 45, "strength", "push", E1_FULL, "hard full 45 adv push"),
        ("advanced", 60, "hypertrophy", "legs", E5_MACH, "hard mach 60 adv legs"),
        ("advanced", 60, "strength", "full_body", E8_FW, "hell fw 60 adv"),
        ("advanced", 90, "athletic_performance", "full_body", E1_FULL, "hell 90 adv max"),
    ]
    for fl, dur, goal, focus, eq, lab in plan_b1:
        i += 1
        s.append(_sc(i, 1, label=f"{lab}", fitness_level=fl, intensity="auto",
                     duration=dur, goal=goal, focus=focus, equipment=eq,
                     date_str=dates[i - 1]))

    # Block 2 — Goal × Focus × Equipment rotation (26-50)
    plan_b2 = [
        ("beginner", "medium", 30, "strength", "push", E3_DB),
        ("intermediate", "hard", 45, "strength", "legs", E1_FULL),
        ("advanced", "medium", 60, "strength", "full_body", E8_FW),
        ("beginner", "medium", 45, "hypertrophy", "upper", E10_HOME),
        ("intermediate", "hard", 60, "hypertrophy", "full_body", E1_FULL),
        ("advanced", "hard", 75, "hypertrophy", "arms", E7_NO_BB),
        ("beginner", "medium", 30, "fat_loss", "cardio", E11_CARDIO),
        ("intermediate", "hard", 45, "fat_loss", "full_body", E4_KB),
        ("advanced", "hell", 30, "fat_loss", "core", E2_BW),
        ("beginner", "medium", 45, "endurance", "cardio", E11_CARDIO),
        ("intermediate", "hard", 60, "endurance", "lower", E1_FULL),
        ("advanced", "hard", 90, "endurance", "full_body", E11_CARDIO),
        ("beginner", "easy", 30, "general_fitness", "full_body", E1_FULL),
        ("intermediate", "medium", 45, "general_fitness", "core", E12_BW_BANDS),
        ("advanced", "medium", 60, "general_fitness", "full_body", E10_HOME),
        ("beginner", "easy", 30, "mobility", "mobility", E6_BANDS),
        ("intermediate", "easy", 45, "mobility", "core", E2_BW),
        ("advanced", "easy", 30, "mobility", "full_body", E12_BW_BANDS),
        ("intermediate", "hard", 30, "power", "legs", E4_KB),
        ("advanced", "hell", 45, "power", "full_body", E8_FW),
        ("intermediate", "hard", 45, "athletic_performance", "lower", E1_FULL),
        ("advanced", "hell", 60, "athletic_performance", "full_body", E8_FW),
        ("beginner", "medium", 45, "weight_loss", "cardio", E11_CARDIO),
        ("intermediate", "medium", 60, "weight_loss", "upper", E3_DB),
        ("beginner", "medium", 30, "muscle_tone", "arms", E9_DB1),
    ]
    for fl, intens, dur, goal, focus, eq in plan_b2:
        i += 1
        s.append(_sc(i, 2, label=f"{goal}/{focus}/{intens}/{fl}/{dur}",
                     fitness_level=fl, intensity=intens, duration=dur,
                     goal=goal, focus=focus, equipment=eq,
                     date_str=dates[i - 1]))

    # Block 3 — Date variation (subset, 15 calls 51-65)
    plan_b3 = [
        ("today", 0, "intermediate", "medium", 45, "strength", "full_body", E1_FULL),
        ("+1d", 1, "intermediate", "medium", 30, "mobility", "mobility", E6_BANDS),
        ("+3d", 3, "intermediate", "medium", 45, "strength", "push", E1_FULL),
        ("+7d", 7, "intermediate", "medium", 60, "hypertrophy", "legs", E1_FULL),
        ("+10d", 10, "intermediate", "medium", 30, "mobility", "core", E2_BW),
        ("+14d", 14, "intermediate", "medium", 45, "strength", "pull", E7_NO_BB),
        ("+21d", 21, "intermediate", "medium", 60, "hypertrophy", "upper", E1_FULL),
        ("+30d", 30, "intermediate", "medium", 75, "endurance", "full_body", E11_CARDIO),
        ("+45d", 45, "intermediate", "medium", 45, "mobility", "full_body", E10_HOME),
        ("+60d", 60, "intermediate", "medium", 60, "strength", "legs", E1_FULL),
        ("+1d clone", 1, "beginner", "easy", 30, "general_fitness", "full_body", E2_BW),
        ("+1d hard", 1, "advanced", "hard", 45, "strength", "push", E1_FULL),
        ("+5d", 5, "intermediate", "medium", 30, "fat_loss", "cardio", E11_CARDIO),
        ("+8d", 8, "intermediate", "medium", 45, "hypertrophy", "arms", E3_DB),
        ("+12d", 12, "intermediate", "medium", 60, "endurance", "full_body", E11_CARDIO),
    ]
    for lab, off, fl, intens, dur, goal, focus, eq in plan_b3:
        i += 1
        s.append(_sc(i, 3, label=f"{lab}: {goal}/{focus}",
                     fitness_level=fl, intensity=intens, duration=dur,
                     goal=goal, focus=focus, equipment=eq,
                     date_str=(dates[off] if off > 0 else dates[0])))

    # Block 4 — Injury combos (66-80)
    plan_b4 = [
        (["knee"], "intermediate", "hard", 45, "hypertrophy", "legs", E1_FULL),
        (["knee"], "beginner", "medium", 30, "strength", "legs", E5_MACH),
        (["shoulder"], "intermediate", "hard", 45, "hypertrophy", "push", E1_FULL),
        (["shoulder"], "advanced", "hard", 60, "strength", "upper", E8_FW),
        (["lower_back"], "intermediate", "medium", 45, "strength", "pull", E1_FULL),
        (["lower_back"], "beginner", "medium", 30, "hypertrophy", "full_body", E10_HOME),
        (["wrist"], "intermediate", "medium", 30, "hypertrophy", "push", E2_BW),
        (["ankle"], "intermediate", "hard", 30, "power", "legs", E4_KB),
        (["hip"], "beginner", "medium", 30, "strength", "legs", E5_MACH),
        (["elbow"], "advanced", "hard", 45, "hypertrophy", "arms", E1_FULL),
        (["neck"], "intermediate", "medium", 30, "hypertrophy", "shoulders", E3_DB),
        (["knee", "shoulder"], "intermediate", "medium", 45, "hypertrophy", "full_body", E1_FULL),
        (["knee", "lower_back"], "beginner", "medium", 30, "strength", "full_body", E5_MACH),
        (["knee", "shoulder", "lower_back"], "intermediate", "medium", 45,
         "general_fitness", "full_body", E5_MACH),
        (["knee", "shoulder", "lower_back", "wrist", "ankle", "hip", "elbow"],
         "beginner", "easy", 30, "mobility", "core", E12_BW_BANDS),
    ]
    for inj, fl, intens, dur, goal, focus, eq in plan_b4:
        i += 1
        s.append(_sc(i, 4, label=f"injuries={','.join(inj)}",
                     fitness_level=fl, intensity=intens, duration=dur,
                     goal=goal, focus=focus, equipment=eq,
                     date_str=dates[i - 1], injuries=inj))

    # Block 5 — Comeback / custom programs / batch_offset / exclude (81-95)
    plan_b5 = [
        ({"skip_comeback": False}, "intermediate", "medium", 30, "strength", "full_body", E3_DB,
         "skip_comeback=false (let user qualify)"),
        ({}, "intermediate", "medium", 45, "hypertrophy", "upper", E1_FULL, "vanilla"),
        ({}, "intermediate", "easy", 30, "mobility", "mobility", E6_BANDS, "vanilla easy"),
        ({}, "intermediate", "easy", 30, "general_fitness", "full_body", E10_HOME, "vanilla home"),
        ({}, "advanced", "hell", 60, "strength", "full_body", E1_FULL, "advanced hell"),
        ({"skip_comeback": True}, "intermediate", "hard", 60, "hypertrophy", "full_body", E1_FULL,
         "skip_comeback=true (force normal)"),
        ({}, "intermediate", "medium", 60, "athletic_performance", "full_body", E1_FULL,
         "athletic"),
        ({}, "intermediate", "medium", 75, "endurance", "cardio", E11_CARDIO, "endurance long"),
        ({}, "intermediate", "medium", 75, "hypertrophy", "upper", E1_FULL, "hyper long"),
        ({}, "intermediate", "medium", 90, "strength", "legs", E1_FULL, "strength long"),
        ({}, "intermediate", "medium", 45, "strength", "upper", E2_BW, "calisthenics-like"),
        ({}, "intermediate", "medium", 45, "athletic_performance", "full_body", E8_FW, "fw athletic"),
        ({"exclude_exercises": ["bench press", "barbell squat", "deadlift"]},
         "intermediate", "medium", 60, "strength", "full_body", E1_FULL, "exclude 3"),
        ({"adjacent_day_exercises": ["bench press", "squat", "deadlift", "pullup", "row"]},
         "intermediate", "medium", 45, "hypertrophy", "upper", E1_FULL, "adjacent avoid"),
        ({"batch_offset": 3},
         "intermediate", "medium", 45, "hypertrophy", "full_body", E1_FULL, "batch_offset=3"),
    ]
    for extras, fl, intens, dur, goal, focus, eq, lab in plan_b5:
        i += 1
        s.append(_sc(i, 5, label=lab, fitness_level=fl, intensity=intens, duration=dur,
                     goal=goal, focus=focus, equipment=eq, date_str=dates[i - 1],
                     **extras))

    # Block 6 — Edge composites (96-100)
    edge = [
        ({"injuries": ["knee", "shoulder", "lower_back", "wrist", "ankle"]},
         "beginner", "hell", 90, "strength", "full_body", E2_BW, "max constraint stress"),
        ({}, "advanced", "easy", 15, "mobility", "mobility", E1_FULL,
         "lowest demand at top fitness"),
        ({}, "intermediate", "medium", 45, "strength", "full_body", E5_MACH,
         "fallback chain stress"),
        ({"focus_areas": ["push", "pull", "legs", "full_body", "core", "upper",
                          "lower", "arms", "shoulders", "glutes", "cardio", "mobility"]},
         "intermediate", "medium", 60, "hypertrophy", "full_body", E1_FULL,
         "12 focus_areas + full eq prompt-bloat"),
        ({"injuries": ["knee", "hip", "lower_back"], "skip_comeback": False},
         "intermediate", "medium", 45, "general_fitness", "full_body", E5_MACH,
         "composite real-world edge"),
    ]
    for extras, fl, intens, dur, goal, focus, eq, lab in edge:
        i += 1
        body_extras = {k: v for k, v in extras.items() if k != "focus_areas"}
        if "focus_areas" in extras:
            # override focus_areas in body
            scen = _sc(i, 6, label=lab, fitness_level=fl, intensity=intens,
                       duration=dur, goal=goal, focus=focus, equipment=eq,
                       date_str=dates[i - 1], **body_extras)
            scen["body"]["focus_areas"] = extras["focus_areas"]
            s.append(scen)
        else:
            s.append(_sc(i, 6, label=lab, fitness_level=fl, intensity=intens,
                         duration=dur, goal=goal, focus=focus, equipment=eq,
                         date_str=dates[i - 1], **body_extras))
    return s[:100]


CSV_COLS = [
    "idx", "scenario_block", "label", "http_status", "latency_ms",
    "request_body_json", "sse_event_count",
    "workout_id", "workout_name", "workout_type", "workout_difficulty",
    "workout_notes", "n_exercises", "exercise_names_pipe",
    "per_exercise_sets", "per_exercise_reps", "per_exercise_weight_kg",
    "per_exercise_rest_seconds", "per_exercise_muscle_group",
    "duration_minutes", "total_volume_kg", "error_message",
]


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=500)
    parser.add_argument("--pacing", type=float, default=5.0)
    parser.add_argument(
        "--resume", default=None,
        help="Path to existing run dir to resume, OR 'auto' for latest matching dir.",
    )
    parser.add_argument(
        "--scenario-set", choices=["100", "500"], default="500",
        help="100 = legacy build_100() in this file; 500 = scripts/_scenarios_500.py",
    )
    args = parser.parse_args()

    print("[harness] auth...", flush=True)
    jwt = get_jwt()
    print("[harness] JWT ok", flush=True)

    if args.scenario_set == "500":
        from scripts._scenarios_500 import build_500
        scenarios = build_500()[: args.n]
    else:
        scenarios = build_100()[: args.n]
    print(f"[harness] {len(scenarios)} scenarios queued", flush=True)

    out_dir, completed_idx, md_entries = resume_or_init_outputs(
        "render_generate_stream_full", CSV_COLS, args.resume,
    )
    url = f"{RENDER}/api/v1/workouts/generate-stream"
    started = _dt.now().isoformat(timespec="seconds")

    async with httpx.AsyncClient() as client:
        for sc in scenarios:
            if sc["idx"] in completed_idx:
                print(f"[{sc['idx']}/{len(scenarios)}] SKIP (already done in resume dir)",
                      flush=True)
                continue
            res = await call_sse_with_retry(client, jwt, url, sc["body"])
            ws = workout_summary(res)
            row = {
                "idx": sc["idx"], "scenario_block": sc["block"], "label": sc["label"],
                "http_status": res["status"], "latency_ms": res["latency_ms"],
                "request_body_json": json.dumps(sc["body"], default=str),
                "sse_event_count": len(res.get("events") or []),
                "error_message": res.get("error") or "",
                **ws,
            }
            full = {"scenario": sc, "result": res, "csv_row": row, "idx": sc["idx"]}
            write_row(out_dir, row, CSV_COLS, full)

            # Update scenarios MD with this scenario's status (real-time).
            valid = (
                row["http_status"] == 200
                and ws["n_exercises"] > 0
                and not row["error_message"]
            )
            md_entries.append({
                "idx": sc["idx"], "label": sc["label"],
                "name": ws["workout_name"], "n_exercises": ws["n_exercises"],
                "latency_ms": row["latency_ms"],
                "error": row["error_message"], "valid": valid,
            })
            update_md_live_status(_MD_PATH, md_entries, started)

            print(
                f"[{sc['idx']}/{len(scenarios)}] block={sc['block']} "
                f"status={row['http_status']} "
                f"latency={row['latency_ms']}ms "
                f"name=\"{ws['workout_name']}\" "
                f"n_ex={ws['n_exercises']} "
                f"valid={'✅' if valid else '❌'} "
                f"err={row['error_message'] or 'OK'} | {sc['label']}",
                flush=True,
            )
            await asyncio.sleep(args.pacing)

    print("[harness] consolidating jsons → csv...", flush=True)
    consolidate_and_cleanup(out_dir, CSV_COLS)
    print(f"[harness] DONE → {out_dir}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
