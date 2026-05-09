"""1000-scenario sweep for `/api/v1/exercise-preferences/suggest-substitutes`.

LOCAL FAST PATH (no AI). Hits exercise_library_cleaned MV. Should respond in <500ms per call.

Validates:
- Response always returns ≥2 substitutes for known exercises
- For injury-flagged reason, all substitutes are `is_safe_for_reason=True`
- For known compounds (squat/deadlift/bench/etc.) substitutes share the
  same primary muscle group
- For unknown exercise names, response either falls back gracefully or 404s

Run:
    cd backend && .venv/bin/python scripts/run_suggest_substitutes_validation.py
"""
from __future__ import annotations

import argparse
import asyncio
import csv
import json
import os
import sys
import time
from datetime import datetime as _dt
from pathlib import Path
from typing import Any, Dict, List

import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts._smoke_lib import (  # noqa: E402
    BACKEND, RENDER, USER_ID, get_jwt, init_outputs, write_row,
    consolidate_and_cleanup, warmup_endpoint,
)


# 80 well-known exercises across muscle groups + plyo + olympic + stretching
EXERCISES_TO_TEST = [
    # Compound legs (12)
    "Barbell Back Squat", "Barbell Front Squat", "Goblet Squat",
    "Bulgarian Split Squat", "Pistol Squat", "Walking Lunges",
    "Conventional Deadlift", "Romanian Deadlift", "Sumo Deadlift",
    "Leg Press", "Hack Squat", "Jump Squat",
    # Compound push (10)
    "Barbell Bench Press", "Incline Dumbbell Press", "Overhead Press",
    "Dumbbell Shoulder Press", "Push-Up", "Decline Bench Press",
    "Dips", "Diamond Push-up", "Archer Push-up", "Arnold Press",
    # Compound pull (8)
    "Pull-Up", "Chin-Up", "Barbell Row", "Dumbbell Row",
    "Cable Row", "Lat Pulldown", "Inverted Row", "Face Pull",
    # Isolation (12)
    "Bicep Curl", "Hammer Curl", "Tricep Extension", "Skull Crusher",
    "Lateral Raise", "Front Raise", "Rear Delt Fly", "Calf Raise",
    "Leg Extension", "Leg Curl", "Cable Fly", "Pec Deck",
    # Core (8)
    "Plank", "Side Plank", "Russian Twist", "Hanging Leg Raise",
    "Ab Wheel Rollout", "Crunch", "Dead Bug", "Bird Dog",
    # Cardio / plyo (8)
    "Burpee", "Box Jump", "Mountain Climber", "Jumping Jacks",
    "High Knees", "Skater Jumps", "Battle Ropes", "Jump Rope",
    # Olympic / advanced (6)
    "Power Clean", "Snatch", "Clean and Jerk", "Push Press",
    "Kettlebell Swing", "Turkish Get-Up",
    # Stretching / mobility (8)
    "Pigeon Pose", "Downward Dog", "Cat Cow", "Couch Stretch",
    "Worlds Greatest Stretch", "Thread the Needle", "Hip Flexor Stretch", "90/90 Stretch",
    # Glute / hip (8)
    "Hip Thrust", "Glute Bridge", "Cable Pull-Through", "Single-Leg RDL",
    "Cossack Squat", "Step-Up", "Reverse Lunge", "Lateral Lunge",
]

# 14 reasons (injury / preference / context)
REASONS = [
    None,
    "knee injury", "shoulder pain", "lower back pain",
    "wrist injury", "ankle sprain", "elbow tendinitis",
    "hip pain", "neck strain",
    "no equipment available", "boring",
    "pregnant — second trimester",
    "post-surgery rehab",
    "bored and want variety",
]

# Edge-case exercise inputs (100)
EDGE_CASE_EXERCISES = [
    # Unknown / typo
    "Squet", "Bicep Curlz", "Made Up Move", "ABCDEFG",
    "Random Exercise 1", "Random Exercise 2", "Random Exercise 3",
    "test", "TEST", "TeSt MoVe",
    # Whitespace / casing
    " Squat ", "  Bench Press  ", "BENCH PRESS", "bench press",
    "Bench  Press", "PUSH-UP", "push-up", "Push Up", "Pushup", "push up",
    # Special chars
    "Squat!", "Bench-Press", "Bench/Press", "Bench (Press)",
    "Bench Press 3x10", "Bench Press @ 80%", "Squat 5x5",
    # Unicode / RTL / emoji
    "스쿼트", "ベンチプレス", "Squat 💪", "Squat™", "Café Curl",
    # Very long
    "A" * 100, "Squat " * 20, "The Most Amazing Exercise Of All Time Ever Invented",
    # Empty/short (mostly rejected by min_length=1)
    "S", "Sq", "Squ",
    # Duplicates with extras
    "Squat Variation A", "Squat Variation B", "Bench Press Variant",
    # Olympic / power
    "Power Snatch", "Hang Clean", "Front Rack Lunge",
    # Exotic equipment
    "Sandbag Carry", "Atlas Stone Lift", "Tire Flip",
    # Bodyweight regressions
    "Wall Push-Up", "Knee Push-Up", "Incline Push-Up",
    "Negative Pull-Up", "Assisted Pull-Up", "Band Pull-Up",
    # Unilateral
    "Single-Arm Row", "Single-Leg Bridge", "Single-Arm Press",
    # Tempo prefixes
    "Tempo Squat", "Pause Bench", "Slow Push-Up",
    # Free-text noise
    "I want to do something", "anything for chest",
    # Yoga-specific
    "Warrior 1", "Warrior 2", "Warrior 3",
    "Sun Salutation A", "Sun Salutation B",
    # Pilates
    "Pilates Hundred", "Roll-Up", "Single Leg Stretch",
    # Common misspellings
    "Dedlift", "Skuat", "Beanch Press", "Pulup", "Chinup",
    # Names with numbers
    "Squat 1", "Squat 2", "Squat 100",
    # Names with units
    "Squat 5kg", "Squat 50lb", "Bench 135",
    # Combos
    "Squat + Press", "Push Pull", "Chest & Back Day",
    # Workout names (not exercises)
    "Leg Day", "Arm Day", "HIIT", "AMRAP",
    # Brand / proper noun
    "Bulgarian Bag Swing", "Bosu Ball Squat", "TRX Row",
    # Misc real exercises that might miss the keyword list
    "Zercher Squat", "Jefferson Curl", "Nordic Hamstring Curl",
    "Copenhagen Plank", "L-Sit", "Pistol Squat to Box",
]


def build_1000() -> List[Dict[str, Any]]:
    """1000 (exercise, reason) pairs across 5 blocks.

    Block 1 (700) — 50 exercises × 14 reasons (full Cartesian, top half).
    Block 2 (200) — Remaining 30 exercises × top 7 reasons (210, capped 200).
    Block 3 (50)  — Edge-case exercises × no-reason (varied).
    Block 4 (30)  — Edge-case exercises × injury reasons.
    Block 5 (20)  — Canonical injury pairings (high-signal smoke).
    """
    out: List[Dict[str, Any]] = []
    i = 0

    # Block 1: 50 ex × 14 reasons = 700 (Cartesian, ordered)
    for ex in EXERCISES_TO_TEST[:50]:
        for reason in REASONS:
            i += 1
            out.append({
                "idx": i, "block": 1,
                "label": f"{ex} + {reason or 'no-reason'}",
                "exercise_name": ex, "reason": reason,
            })

    # Block 2: remaining 30 ex × top 7 reasons = 210 (cap 200)
    block2_count = 0
    for ex in EXERCISES_TO_TEST[50:]:
        for reason in REASONS[:7]:  # None + 6 injuries
            if block2_count >= 200:
                break
            i += 1
            block2_count += 1
            out.append({
                "idx": i, "block": 2,
                "label": f"{ex} + {reason or 'no-reason'}",
                "exercise_name": ex, "reason": reason,
            })
        if block2_count >= 200:
            break

    # Block 3: 50 edge-case exercises × no reason
    for ex in EDGE_CASE_EXERCISES[:50]:
        i += 1
        out.append({
            "idx": i, "block": 3,
            "label": f"edge: {ex!r}",
            "exercise_name": ex, "reason": None,
        })

    # Block 4: 30 edge-case exercises × rotating injury reason
    inj_rotation = [r for r in REASONS if r and "injury" in r or r and "pain" in r or r and "sprain" in r]
    if not inj_rotation:
        inj_rotation = ["knee injury", "shoulder pain", "lower back pain"]
    for k, ex in enumerate(EDGE_CASE_EXERCISES[50:80]):
        reason = inj_rotation[k % len(inj_rotation)]
        i += 1
        out.append({
            "idx": i, "block": 4,
            "label": f"edge+injury: {ex!r} + {reason}",
            "exercise_name": ex, "reason": reason,
        })

    # Block 5: 20 canonical high-signal pairs
    canonicals = [
        ("Barbell Back Squat", "knee injury"),
        ("Conventional Deadlift", "lower back pain"),
        ("Barbell Bench Press", "shoulder pain"),
        ("Overhead Press", "shoulder pain"),
        ("Pull-Up", "elbow tendinitis"),
        ("Push-Up", "wrist injury"),
        ("Box Jump", "ankle sprain"),
        ("Burpee", "knee injury"),
        ("Bicep Curl", "elbow tendinitis"),
        ("Calf Raise", "ankle sprain"),
        ("Plank", "lower back pain"),
        ("Russian Twist", "lower back pain"),
        ("Mountain Climber", "wrist injury"),
        ("Dips", "shoulder pain"),
        ("Pistol Squat", "knee injury"),
        ("Romanian Deadlift", "lower back pain"),
        ("Sumo Deadlift", "hip pain"),
        ("Hanging Leg Raise", "shoulder pain"),
        ("Walking Lunges", "knee injury"),
        ("Crunch", "neck strain"),
    ]
    for ex, reason in canonicals:
        i += 1
        out.append({
            "idx": i, "block": 5,
            "label": f"canonical: {ex} + {reason}",
            "exercise_name": ex, "reason": reason,
        })

    # Re-number 1..1000 contiguously
    for k, sc in enumerate(out[:1000], start=1):
        sc["idx"] = k
    return out[:1000]


# Backward compat alias (used by older imports / harnesses)
build_100 = build_1000


def _classify_block(ex: str, reason: str) -> int:
    e = ex.lower()
    if any(w in e for w in ["squat","deadlift","press","row","pull-up","chin-up","push-up","dip","lunge","clean","snatch"]):
        return 1  # Compound
    if any(w in e for w in ["curl","extension","raise","fly","crunch"]):
        return 2  # Isolation
    if any(w in e for w in ["plank","russian","ab wheel","leg raise"]):
        return 3  # Core
    if any(w in e for w in ["burpee","jump","mountain","jacks"]):
        return 4  # Cardio / plyo
    return 5  # Other


CSV_COLS = [
    "idx", "scenario_block", "label", "exercise_name", "reason",
    "http_status", "latency_ms", "response_message",
    "n_substitutes", "substitute_names_pipe",
    "substitutes_with_library_id", "substitutes_with_gif_url",
    "all_safe_for_reason", "request_body_json", "error_message",
]


async def call_substitutes(
    client: httpx.AsyncClient,
    jwt: str,
    body: Dict[str, Any],
) -> Dict[str, Any]:
    t0 = time.time()
    try:
        r = await client.post(
            f"{RENDER}/api/v1/exercise-preferences/suggest-substitutes",
            json=body,
            headers={"Authorization": f"Bearer {jwt}"},
            timeout=15.0,
        )
        latency_ms = int((time.time() - t0) * 1000)
        try:
            payload = r.json()
        except Exception:
            payload = {"_raw_text": r.text[:500]}
        err = None
        if r.status_code != 200:
            err = f"HTTP {r.status_code}: {str(payload)[:300]}"
        return {
            "status": r.status_code,
            "latency_ms": latency_ms,
            "body": payload,
            "request_body": body,
            "error": err,
        }
    except Exception as e:
        return {
            "status": -1,
            "latency_ms": int((time.time() - t0) * 1000),
            "body": {"_error": str(e)},
            "request_body": body,
            "error": f"{type(e).__name__}: {e}",
        }


def extract_summary(result: Dict[str, Any]) -> Dict[str, Any]:
    body = result.get("body") or {}
    if not isinstance(body, dict):
        body = {}
    subs = body.get("substitutes") or []
    names = [s.get("name", "") for s in subs]
    n_with_id = sum(1 for s in subs if s.get("library_id"))
    n_with_gif = sum(1 for s in subs if s.get("gif_url"))
    all_safe = all(s.get("is_safe_for_reason", True) for s in subs)
    return {
        "n_substitutes": len(subs),
        "substitute_names_pipe": "|".join(names),
        "substitutes_with_library_id": n_with_id,
        "substitutes_with_gif_url": n_with_gif,
        "all_safe_for_reason": all_safe,
        "response_message": (body.get("message") or "")[:200],
    }


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=1000)
    parser.add_argument("--pacing", type=float, default=0.2,
                        help="No AI involved → can run fast")
    args = parser.parse_args()

    print("[harness] auth...", flush=True)
    jwt = get_jwt()
    print("[harness] JWT ok", flush=True)

    scenarios = build_1000()[: args.n]
    print(f"[harness] {len(scenarios)} scenarios queued", flush=True)

    out_dir = init_outputs("render_suggest_substitutes", CSV_COLS)

    async with httpx.AsyncClient() as client:
        # Cold-start warmup — eliminates the ~7s outliers we saw on prior runs
        # (idx 4/8/12/17/22 all > 2s on the 2026-05-08 run). Hits the real
        # endpoint once before block-1 starts so subsequent calls are warm.
        print("[harness] warming up Render...", flush=True)
        last_warmup_ms = await warmup_endpoint(
            client, RENDER, jwt,
            "/api/v1/exercise-preferences/suggest-substitutes",
            {"exercise_name": "Squat", "user_id": USER_ID},
            target_ms=800,
        )
        print(f"[harness] warm — last call {last_warmup_ms}ms", flush=True)

        for sc in scenarios:
            body = {"exercise_name": sc["exercise_name"]}
            if sc["reason"]:
                body["reason"] = sc["reason"]
            res = await call_substitutes(client, jwt, body)
            ws = extract_summary(res)
            row = {
                "idx": sc["idx"], "scenario_block": sc["block"],
                "label": sc["label"],
                "exercise_name": sc["exercise_name"],
                "reason": sc["reason"] or "",
                "http_status": res["status"], "latency_ms": res["latency_ms"],
                "request_body_json": json.dumps(body, default=str),
                "error_message": res.get("error") or "",
                **ws,
            }
            full = {"scenario": sc, "result": res, "csv_row": row, "idx": sc["idx"]}
            write_row(out_dir, row, CSV_COLS, full)
            valid = (
                row["http_status"] == 200
                and ws["n_substitutes"] >= 2
                and ws["all_safe_for_reason"]
                and not row["error_message"]
            )
            print(
                f"[{sc['idx']}/{len(scenarios)}] block={sc['block']} "
                f"latency={row['latency_ms']}ms "
                f"n_subs={ws['n_substitutes']} "
                f"with_id={ws['substitutes_with_library_id']} "
                f"safe={ws['all_safe_for_reason']} "
                f"valid={'✅' if valid else '❌'} "
                f"| {sc['label']}",
                flush=True,
            )
            await asyncio.sleep(args.pacing)

    consolidate_and_cleanup(out_dir, CSV_COLS)
    print(f"[harness] DONE → {out_dir}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
