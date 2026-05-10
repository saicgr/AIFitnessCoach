"""Full 100-scenario sweep for /api/v1/workouts/regenerate-stream.

Pre-step: lists user's existing workouts; if < 20, falls back to whatever
exists (cycling through them). Each scenario regenerates one workout with
varied overrides. **Never** calls /regenerate-commit — preview rows accumulate.

Pacing 13s (under 5/min IP limit) + 429 retry. ETA: 100 × ~25s ≈ 42 min.

Run:
    cd backend && .venv/bin/python scripts/run_regenerate_stream_full.py
"""
from __future__ import annotations

import argparse
import asyncio
import json
from datetime import date
from typing import Any, Dict, List

import httpx

from datetime import datetime as _dt
from pathlib import Path as _P

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts._smoke_lib import (  # noqa: E402
    BACKEND, RENDER, USER_ID,
    call_sse_with_retry, consolidate_and_cleanup,
    get_jwt, init_outputs, sb, resume_or_init_outputs,
    update_md_live_status, write_row, workout_summary,
)

_MD_PATH = _P("/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/scenarios/"
              "regenerate_stream_scenarios.md")


def list_user_workouts(min_count: int = 20) -> List[Dict[str, Any]]:
    today_str = date.today().isoformat()
    fut = sb.table("workouts").select(
        "id, name, type, scheduled_date, difficulty, duration_minutes"
    ).eq("user_id", USER_ID).gte("scheduled_date", today_str).order(
        "scheduled_date"
    ).limit(50).execute()
    workouts = list(fut.data or [])
    if len(workouts) < min_count:
        past = sb.table("workouts").select(
            "id, name, type, scheduled_date, difficulty, duration_minutes"
        ).eq("user_id", USER_ID).lt("scheduled_date", today_str).order(
            "scheduled_date", desc=True
        ).limit(min_count - len(workouts)).execute()
        workouts.extend(past.data or [])
    return workouts


# RegenerateWorkoutRequest schema fields. Anything else is silently dropped
# at the boundary so test scenarios don't leak schema-extra fields into the
# request body (Pydantic uses extra='ignore' by default — drops without 422,
# making test intent invisible).
_REGEN_SCHEMA_FIELDS = {
    "workout_id", "user_id", "duration_minutes", "duration_minutes_min",
    "duration_minutes_max", "fitness_level", "difficulty", "equipment",
    "focus_areas", "injuries", "workout_type", "workout_name", "ai_prompt",
    "dumbbell_count", "kettlebell_count", "new_scheduled_date",
    "force_non_preferred_day",
}


def _filter_schema(body: Dict[str, Any]) -> Dict[str, Any]:
    """Drop any keys not on RegenerateWorkoutRequest. The endpoint loads
    fitness_level / equipment / focus_areas / etc. from reviewer@fitwiz.us's
    user record + active gym_profile when not provided in the body, so noise
    defaults can simply be removed (rely on user state)."""
    return {k: v for k, v in body.items() if k in _REGEN_SCHEMA_FIELDS}


def build_100(sources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """500 scenarios. Cycles `sources` if fewer exist."""
    s: List[Dict[str, Any]] = []
    src = lambda k: sources[k % len(sources)]  # noqa: E731
    i = 0

    # Block 1 — Difficulty intent (1-20). Use diff=easy/medium/hard/hell.
    diffs = ["easy", "medium", "hard", "hell"]
    for k, d in enumerate(diffs * 5):  # 20
        i += 1
        s.append({
            "idx": i, "block": 1,
            "label": f"diff={d}",
            "body": {
                "workout_id": src(k)["id"],
                "user_id": USER_ID,
                "duration_minutes": 30 if d == "easy" else 45 if d == "medium" else 60,
                "difficulty": d,
                "fitness_level": "intermediate",
            },
        })

    # Block 2 — Duration adjustment (21-35). 15 calls.
    durations_b2 = [15, 20, 25, 30, 45, 60, 75, 90, 75, 90, 15, 90, 30, 60, 45]
    for k, dur in enumerate(durations_b2):
        i += 1
        s.append({
            "idx": i, "block": 2,
            "label": f"duration={dur}",
            "body": {
                "workout_id": src(k + 20)["id"],
                "user_id": USER_ID,
                "duration_minutes": dur,
                "difficulty": "medium",
            },
        })

    # Block 3 — Equipment swap (36-50). 15 calls.
    eq_b3 = [
        [], [], ["dumbbells", "bench"], ["dumbbells"],
        ["kettlebell"], ["kettlebell"], ["cable_machine", "leg_press_machine"],
        ["resistance_bands"], ["treadmill"], ["dumbbells", "pull_up_bar"],
        ["barbell", "dumbbells"], ["resistance_bands"],
        ["barbell", "squat_rack", "bench"], [], ["dumbbells", "kettlebell"],
    ]
    for k, eq in enumerate(eq_b3):
        i += 1
        s.append({
            "idx": i, "block": 3,
            "label": f"equip={'+'.join(eq) if eq else 'bodyweight'}",
            "body": {
                "workout_id": src(k + 35)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "equipment": eq,
                "difficulty": "medium",
            },
        })

    # Block 4 — Focus pivot (51-65). 15 calls.
    focuses = ["pull", "upper", "cardio", "mobility", "HIIT", "push", "legs",
               "core", "arms", "shoulders", "cardio", "core", "glutes",
               "upper", "full_body"]
    for k, f in enumerate(focuses):
        i += 1
        s.append({
            "idx": i, "block": 4,
            "label": f"focus={f}",
            "body": {
                "workout_id": src(k + 50)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "focus_areas": [f],
                "difficulty": "medium",
            },
        })

    # Block 5 — AI prompt overrides (66-80). 15 calls.
    prompts = [
        "make it more compound-focused, fewer isolation exercises",
        "no jumping or impact today, my knees hurt",
        "more cardio please, I want to sweat",
        "shorter rest periods between sets, like 30s",
        "longer rest, 2-3 min, I'm trying to lift heavier",
        "include 5 minutes of warmup specific to shoulders",
        "no barbell exercises today",
        "make it a pyramid set structure (10-8-6-4)",
        "I want supersets and giant sets, push intensity",
        "easy day, foam rolling and stretching only",
        "I'm pregnant, second trimester — adjust accordingly",
        "post-injury return-to-running phase 2",
        "12 weeks out from a powerlifting meet — accumulation block",
        "menstrual cycle day 2, please de-escalate intensity",
        "fasted training, low energy, keep it under 30 min",
    ]
    for k, p in enumerate(prompts):
        i += 1
        s.append({
            "idx": i, "block": 5,
            "label": f"ai_prompt='{p[:40]}...'",
            "body": {
                "workout_id": src(k + 65)["id"],
                "user_id": USER_ID,
                "duration_minutes": 30 if "30 min" in p else 45,
                "ai_prompt": p,
            },
        })

    # Block 6 — Reschedule (81-90). 10 calls.
    reschedules = [
        (date.today().isoformat(), True, "today + force"),
        ((date.today()).isoformat(), True, "today force #2"),
        ((date.today()).isoformat(), True, "today force #3"),
        ("+7d", True, "+7d force"),
        ("+14d", True, "+14d force"),
        ("+1d", True, "+1d force"),
        ("+3d", True, "+3d force"),
        ("+5d", True, "+5d force"),
        ("+30d", True, "+30d force"),
        ("+60d", True, "+60d force"),
    ]
    from datetime import timedelta as _td
    for k, (d_spec, force, lab) in enumerate(reschedules):
        i += 1
        if d_spec.startswith("+"):
            offset = int(d_spec[1:].rstrip("d"))
            new_date = (date.today() + _td(days=offset)).isoformat()
        else:
            new_date = d_spec
        s.append({
            "idx": i, "block": 6,
            "label": lab,
            "body": {
                "workout_id": src(k + 80)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "new_scheduled_date": new_date,
                "force_non_preferred_day": force,
            },
        })

    # Block 7 — Injury injection during regen (91-95).
    inj_specs = [
        (["knee"], "legs"),
        (["shoulder"], "push"),
        (["lower_back"], "pull"),
        (["knee", "shoulder", "wrist"], "full_body"),
        (["knee", "shoulder", "lower_back", "wrist", "ankle", "hip", "elbow"], "core"),
    ]
    for k, (inj, focus) in enumerate(inj_specs):
        i += 1
        s.append({
            "idx": i, "block": 7,
            "label": f"injuries={','.join(inj)}/focus={focus}",
            "body": {
                "workout_id": src(k + 90)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "injuries": inj,
                "focus_areas": [focus],
                "difficulty": "easy" if len(inj) >= 5 else "medium",
            },
        })

    # Block 8 — Composite + extreme (96-100).
    same_id = sources[5 % len(sources)]["id"]  # for variety check
    composite = [
        ("same source variety #1", {
            "workout_id": same_id, "user_id": USER_ID,
            "duration_minutes": 45, "difficulty": "medium",
            "focus_areas": ["full_body"],
        }),
        ("same source variety #2", {
            "workout_id": same_id, "user_id": USER_ID,
            "duration_minutes": 45, "difficulty": "medium",
            "focus_areas": ["full_body"],
        }),
        ("same source variety #3", {
            "workout_id": same_id, "user_id": USER_ID,
            "duration_minutes": 45, "difficulty": "medium",
            "focus_areas": ["full_body"],
        }),
        ("max payload", {
            "workout_id": src(95)["id"], "user_id": USER_ID,
            "duration_minutes": 60,
            "difficulty": "hell",
            "fitness_level": "advanced",
            "equipment": ["barbell", "dumbbells", "cable_machine", "squat_rack",
                          "bench", "pull_up_bar", "kettlebell"],
            "focus_areas": ["push", "pull", "legs", "full_body", "core", "upper"],
            "injuries": ["knee", "shoulder", "lower_back"],
            "ai_prompt": "Maximum challenge while respecting all constraints. " * 5,
            "workout_name": "Phoenix Inferno",
            "dumbbell_count": 2,
            "kettlebell_count": 2,
        }),
        ("minimal payload", {
            "workout_id": src(96)["id"], "user_id": USER_ID,
        }),
    ]
    for lab, body in composite:
        i += 1
        s.append({"idx": i, "block": 8, "label": lab, "body": body})

    # =====================================================================
    # Block 9 — Goal × Difficulty grid (101-150). 50 calls.
    # Tests goal-driven prescription (rep ranges, rest, sets) per progressive_overload.
    # =====================================================================
    goals = ["strength", "hypertrophy", "endurance", "power", "fat_loss"]
    diffs9 = ["easy", "medium", "hard", "hell"]
    fls = ["beginner", "intermediate", "advanced"]
    for k in range(50):
        i += 1
        g = goals[k % len(goals)]
        d = diffs9[k % len(diffs9)]
        fl = fls[k % len(fls)]
        s.append({
            "idx": i, "block": 9,
            "label": f"goal={g}/diff={d}/fl={fl}",
            "body": {
                "workout_id": src(k + 100)["id"],
                "user_id": USER_ID,
                "duration_minutes": [30, 45, 60][k % 3],
                "goals": [g],
                "difficulty": d,
                "fitness_level": fl,
            },
        })

    # =====================================================================
    # Block 10 — Equipment-restriction edges (151-200). 50 calls.
    # Single dumbbell, single kettlebell, machine-only, bands-only, hotel-room, etc.
    # =====================================================================
    eq_specs_b10 = [
        # Single-side gear
        ([], "bodyweight only"),
        (["dumbbells"], "1 dumbbell only", {"dumbbell_count": 1}),
        (["dumbbells"], "1 dumbbell pair", {"dumbbell_count": 2}),
        (["kettlebell"], "1 kettlebell", {"kettlebell_count": 1}),
        (["kettlebell"], "2 kettlebells", {"kettlebell_count": 2}),
        # Machine-only
        (["leg_press_machine", "lat_pulldown", "cable_machine"], "machine-only"),
        (["smith_machine"], "smith machine only"),
        (["chest_press_machine", "leg_press_machine"], "2 machines"),
        # Bands / minimal
        (["resistance_bands"], "bands only"),
        (["resistance_bands", "pull_up_bar"], "bands + pullup"),
        (["jump_rope"], "jump rope only"),
        (["yoga_mat"], "yoga mat only"),
        # Cardio
        (["treadmill"], "treadmill only"),
        (["rower"], "rower only"),
        (["assault_bike"], "assault bike only"),
        (["elliptical"], "elliptical only"),
        # Outdoor / hotel
        (["pull_up_bar"], "park / pullup bar"),
        (["sandbag"], "sandbag only"),
        (["medicine_ball"], "medicine ball only"),
        (["sliders"], "sliders only"),
        # Exotic
        (["trx_straps"], "TRX only"),
        (["bulgarian_bag"], "bulgarian bag"),
        (["mace"], "mace only"),
        # Mixed home gym
        (["dumbbells", "bench", "pull_up_bar"], "home gym minimal"),
        (["dumbbells", "kettlebell", "resistance_bands", "pull_up_bar"], "home gym mid"),
        (["barbell", "squat_rack", "bench", "dumbbells"], "garage gym"),
        # Commercial gym full
        (["barbell", "dumbbells", "cable_machine", "leg_press_machine",
          "lat_pulldown", "smith_machine", "squat_rack", "bench",
          "pull_up_bar", "kettlebell", "resistance_bands", "treadmill",
          "rower", "assault_bike"], "full commercial gym"),
    ]
    eq_specs_b10 = (eq_specs_b10 * 2)[:50]
    for k, spec in enumerate(eq_specs_b10):
        eq, lab = spec[0], spec[1]
        extras = spec[2] if len(spec) > 2 else {}
        i += 1
        body = {
            "workout_id": src(k + 150)["id"],
            "user_id": USER_ID,
            "duration_minutes": 45,
            "equipment": eq,
            "difficulty": "medium",
        }
        body.update(extras)
        s.append({"idx": i, "block": 10, "label": f"equip: {lab}", "body": body})

    # =====================================================================
    # Block 11 — Injury × Equipment combos (201-250). 50 calls.
    # Joint-by-joint injury matrix × varied equipment access.
    # =====================================================================
    injuries11 = ["knee", "shoulder", "lower_back", "elbow", "wrist", "hip", "ankle", "neck"]
    eq_b11 = [[], ["dumbbells"], ["barbell", "bench"], ["kettlebell"],
              ["resistance_bands"], ["cable_machine", "leg_press_machine"]]
    multi = [["knee", "shoulder"], ["lower_back", "knee"],
             ["wrist", "elbow", "shoulder"], ["hip", "knee", "ankle"]]
    combos = [(inj, eq) for inj in injuries11 for eq in eq_b11[:2]]  # 16
    combos += [([inj], eq) for inj in injuries11 for eq in eq_b11[2:5]]  # 24
    combos += [(m, eq_b11[k % len(eq_b11)]) for k, m in enumerate(multi * 3)]  # 12
    combos = combos[:50]
    for k, (inj, eq) in enumerate(combos):
        if isinstance(inj, list) and inj and isinstance(inj[0], str):
            inj_list = inj
        else:
            inj_list = [inj] if isinstance(inj, str) else list(inj)
        i += 1
        s.append({
            "idx": i, "block": 11,
            "label": f"inj={'+'.join(inj_list)} eq={'+'.join(eq) or 'BW'}",
            "body": {
                "workout_id": src(k + 200)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "injuries": inj_list,
                "equipment": eq,
                "difficulty": "easy" if len(inj_list) >= 3 else "medium",
            },
        })

    # =====================================================================
    # Block 12 — AI prompt edge cases (251-300). 50 calls.
    # Long prompts, multilingual, contradictions, dietary, recovery state, etc.
    # =====================================================================
    prompts12 = [
        # Long
        "I want a workout that focuses on hypertrophy of the upper body, "
        "specifically chest and shoulders, with a secondary focus on triceps. "
        "Keep rest periods around 60-90 seconds and aim for 8-12 reps per set. "
        "Include both compound and isolation movements, with emphasis on time "
        "under tension. " * 3,
        # Multilingual
        "Hazlo más difícil, por favor",
        "もっとハードにしてください",
        "更加挑战性的训练",
        "Сделайте тренировку сложнее",
        "एक चुनौतीपूर्ण कसरत बनाएं",
        # Contradictions
        "make it harder but easier on my joints",
        "more cardio but no impact",
        "pure strength but high reps",
        "shorter workout but more exercises",
        # Dietary / fasting
        "I'm fasted, last meal 18 hours ago",
        "post-workout, I have a heavy meal in 30 min",
        "keto for 6 months, glycogen low",
        # Recovery state
        "DOMS in legs, day 2 after heavy squats",
        "slept 4 hours last night",
        "feeling great, want to push it",
        "minor cold, congestion, low energy",
        "back from 2-week vacation, deconditioned",
        # Schedule pressure
        "only have 15 minutes before a meeting",
        "have 90 minutes — go full intensity",
        "double session, this is workout 2 of 2 today",
        # Special populations
        "I'm 65 years old, joint-friendly please",
        "I'm 14, just started lifting, learn-the-movements focus",
        "I'm 6 months post-partum, gentle progression",
        "I'm pregnant first trimester, no supine work",
        # Goals (specific PRs)
        "training for a 5K in 8 weeks",
        "training for a powerlifting meet in 12 weeks",
        "training for an obstacle course race",
        "training for a marathon — long run is tomorrow",
        # Mood
        "feeling stressed, want to release tension",
        "anxious, give me something rhythmic",
        "happy and energetic, let's go big",
        # Style preferences
        "I love supersets, give me 5+",
        "I hate cardio — minimum required only",
        "I prefer machines over free weights",
        "I prefer free weights only",
        # Time of day
        "early morning, low CNS state",
        "late evening, don't make me too wired",
        "lunchtime quickie",
        # Body part bias
        "skip arms today",
        "no legs today, played soccer this morning",
        "abs/core focus — I'm doing a photo shoot tomorrow",
        # Format
        "I want every exercise to be unilateral",
        "I want supersets only — no straight sets",
        "I want a circuit — 4 rounds, no breaks within rounds",
        "I want EMOM-style — 30 minutes total",
        "I want AMRAP-style — 20 minutes",
        # Empty / weird
        "",
        " ",
        "?????",
        "🔥💪🏋️",
    ]
    # Phase E: explicitly send `injuries: []` so block 12 actually exercises
    # the LLM path. Without this, the test user d54e6652's profile injuries
    # (5–7 joints) leak in, the safety-mode override fires, and every
    # prompt — Spanish, Japanese, English alike — collapses to the same
    # "Gentle Mobility Session" output. Also send a representative
    # focus_areas so the cascade has a sensible starting point.
    for k, p in enumerate(prompts12[:30]):
        i += 1
        s.append({
            "idx": i, "block": 12,
            "label": f"ai={p[:40]!r}",
            "body": {
                "workout_id": src(k + 250)["id"],
                "user_id": USER_ID,
                "duration_minutes": 15 if "15 minutes" in p else 90 if "90 minutes" in p else 45,
                "ai_prompt": p,
                "injuries": [],          # NEW (Phase E) — clear profile injuries
                "focus_areas": ["full_body"],  # NEW (Phase E) — explicit anchor
            },
        })

    # =====================================================================
    # Block 13 — Special populations (301-350). 50 calls.
    # Senior, teen, pregnant, post-partum, disability, returning athlete.
    # =====================================================================
    populations = [
        # Senior progression
        ("senior beginner", {"fitness_level": "beginner", "ai_prompt": "I'm 70, brand new to lifting"}),
        ("senior intermediate", {"fitness_level": "intermediate", "ai_prompt": "I'm 68, lifted for 5 years"}),
        ("senior advanced", {"fitness_level": "advanced", "ai_prompt": "I'm 65, masters powerlifter"}),
        ("senior frail", {"fitness_level": "beginner", "ai_prompt": "I'm 80, frail, balance issues"}),
        # Teen progression
        ("teen 14", {"fitness_level": "beginner", "ai_prompt": "I'm 14, just starting"}),
        ("teen 16", {"fitness_level": "intermediate", "ai_prompt": "I'm 16, varsity athlete"}),
        ("teen 17", {"fitness_level": "advanced", "ai_prompt": "I'm 17, college recruit"}),
        # Pregnancy
        ("pregnant T1", {"ai_prompt": "first trimester, energy dip"}),
        ("pregnant T2", {"ai_prompt": "second trimester, no supine"}),
        ("pregnant T3", {"ai_prompt": "third trimester, week 36, modify everything"}),
        # Post-partum
        ("postpartum 6w", {"ai_prompt": "6 weeks post-partum, just cleared by OB"}),
        ("postpartum 12w", {"ai_prompt": "12 weeks post-partum, returning to lifting"}),
        ("postpartum 6mo", {"ai_prompt": "6 months post-partum, full clearance"}),
        # Disability / chronic
        ("seated wheelchair", {"ai_prompt": "wheelchair user, upper body focus"}),
        ("amputee BK", {"ai_prompt": "below-knee amputee, prosthetic user"}),
        ("MS mild", {"ai_prompt": "MS, mild fatigue, balance work"}),
        ("Parkinson's mild", {"ai_prompt": "early-stage Parkinson's, tremor minor"}),
        ("Diabetes T2", {"ai_prompt": "T2 diabetes, post-meal training"}),
        ("hypertension", {"ai_prompt": "BP 145/95, doctor said avoid Valsalva"}),
        # Returning
        ("RTS week 1", {"ai_prompt": "return to sport week 1 after ACL"}),
        ("RTS week 6", {"ai_prompt": "return to sport week 6 after rotator cuff"}),
        ("post-COVID", {"ai_prompt": "post-COVID 3 months, easing back"}),
        # Menstrual
        ("luteal phase", {"ai_prompt": "luteal phase day 22, fatigue high"}),
        ("ovulation peak", {"ai_prompt": "day 14, peak strength window, push it"}),
        ("menstrual day 1", {"ai_prompt": "cycle day 1, cramps, mobility focus"}),
        # Body comp / weight
        ("bariatric postop", {"ai_prompt": "6 months post bariatric surgery"}),
        ("competitive cut", {"ai_prompt": "10 days from photo shoot, depleted"}),
        ("offseason bulk", {"ai_prompt": "offseason +10lb above setpoint"}),
        # Injury rehab phases
        ("phase 1 PT", {"injuries": ["knee"], "ai_prompt": "phase 1 PT post-op"}),
        ("phase 2 PT", {"injuries": ["knee"], "ai_prompt": "phase 2 PT cleared squats"}),
        ("phase 3 PT", {"injuries": ["knee"], "ai_prompt": "phase 3 PT plyo cleared"}),
        # Time-zone / shift
        ("night shift worker", {"ai_prompt": "night shift, training at 3am"}),
        ("jet-lagged", {"ai_prompt": "just landed, 8h time diff"}),
        # Veteran lifters
        ("masters 50+", {"fitness_level": "advanced", "ai_prompt": "50yo, 30 years lifting, recovery slower"}),
        ("masters 60+", {"fitness_level": "advanced", "ai_prompt": "62yo, masters competitor"}),
        # Adaptive
        ("blind", {"ai_prompt": "I'm blind, machine-based safer"}),
        ("hearing impaired", {"ai_prompt": "hearing impaired, verbal cues differ"}),
        # Chronic pain
        ("fibromyalgia", {"ai_prompt": "fibromyalgia flare-up day"}),
        ("chronic LBP", {"ai_prompt": "chronic LBP 5+ years, mostly desk work"}),
        ("RA mild", {"ai_prompt": "mild rheumatoid arthritis"}),
        # Cardiac
        ("post-MI 6mo", {"ai_prompt": "6 months post-MI, cardiac rehab phase 3"}),
        ("AFib controlled", {"ai_prompt": "AFib, on beta-blockers"}),
        # Mental health
        ("depression", {"ai_prompt": "depressive episode, low motivation"}),
        ("anxiety", {"ai_prompt": "anxiety, prefer rhythmic + grounding"}),
        # Eating disorder recovery
        ("ED recovery", {"ai_prompt": "ED recovery, no calorie talk"}),
        # Pediatric
        ("kid 8", {"ai_prompt": "I'm 8, with my parent"}),
        ("kid 11", {"ai_prompt": "I'm 11, soccer team prep"}),
        # Neurological
        ("stroke recovery", {"ai_prompt": "1 year post-stroke, left-side weakness"}),
        # Pre-surgery
        ("prehab knee", {"ai_prompt": "knee replacement in 6 weeks, prehab"}),
        ("prehab back", {"ai_prompt": "spine fusion in 8 weeks, build"}),
        # Misc
        ("first ever workout", {"fitness_level": "beginner", "ai_prompt": "first workout ever in my life"}),
    ]
    for k, (lab, extras) in enumerate(populations[:50]):
        i += 1
        body = {
            "workout_id": src(k + 300)["id"],
            "user_id": USER_ID,
            "duration_minutes": 30 if "frail" in lab or "kid" in lab else 45,
            "difficulty": "easy" if any(t in lab for t in ["frail", "T3", "phase 1", "kid", "stroke"]) else "medium",
        }
        body.update(extras)
        s.append({"idx": i, "block": 13, "label": f"pop: {lab}", "body": body})

    # =====================================================================
    # Block 14 — Reschedule × force × difficulty matrix (351-370). 20 calls.
    # (Trimmed from 50 → 20 to free slots for the dedicated injury sweep in Block 17;
    # reschedule basics are already covered by Block 6.)
    # =====================================================================
    from datetime import timedelta as _td2
    offsets14 = [-1, 0, 1, 2, 3, 5, 7, 10, 14, 21, 30, 45, 60, 90, 120]
    diffs14 = ["easy", "medium", "hard", "hell"]
    forces = [True, False]
    for k in range(20):
        off = offsets14[k % len(offsets14)]
        d = diffs14[k % len(diffs14)]
        f = forces[k % len(forces)]
        new_date = (date.today() + _td2(days=off)).isoformat()
        i += 1
        s.append({
            "idx": i, "block": 14,
            "label": f"resched={off:+d}d force={f} diff={d}",
            "body": {
                "workout_id": src(k + 350)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "new_scheduled_date": new_date,
                "force_non_preferred_day": f,
                "difficulty": d,
            },
        })

    # =====================================================================
    # Block 15 — Workout name + preserve_history + fitness_level (401-450). 50 calls.
    # Tests `workout_name` override + `preserve_history` flag interactions.
    # =====================================================================
    custom_names = [
        "Phoenix Rising", "Iron Forge", "Steel Resolve", "Apex Hunt",
        "Quantum Lift", "Solar Flare", "Tidal Force", "Granite Will",
        "Velvet Hammer", "Crimson Dawn", "Eclipse Protocol", "Zenith Push",
        "Inferno Block", "Avalanche Set", "Tempest Surge", "Nebula Climb",
        "Vortex Crush", "Lightning Round", "Glacier Mass", "Ember Burn",
        # edge cases
        "", " ", "x" * 200,  # boundary
        "Workout 🔥", "Léger", "ベンチデー",  # unicode
        "VERY LONG NAME WITH MANY MANY WORDS THAT KEEPS GOING AND GOING",
        "name w/ sp3c!al ch@rs",
        "tabs\there",
    ]
    for k in range(50):
        nm = custom_names[k % len(custom_names)]
        ph = (k % 3 == 0)
        fl = ["beginner", "intermediate", "advanced"][k % 3]
        i += 1
        s.append({
            "idx": i, "block": 15,
            "label": f"name={nm[:20]!r} preserve={ph} fl={fl}",
            "body": {
                "workout_id": src(k + 400)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "workout_name": nm,
                "preserve_history": ph,
                "fitness_level": fl,
                "difficulty": "medium",
            },
        })

    # =====================================================================
    # Block 16 — Variety regression (371-390). 20 calls on same source workout.
    # Probes: do regenerations of identical body produce distinct workouts?
    # (Trimmed to 20 — variety regression is also probed by Block 8 composite.)
    # =====================================================================
    var_id = sources[0]["id"]
    for k in range(20):
        i += 1
        s.append({
            "idx": i, "block": 16,
            "label": f"variety #{k+1}/20 same source same body",
            "body": {
                "workout_id": var_id,
                "user_id": USER_ID,
                "duration_minutes": 45,
                "difficulty": "medium",
                "fitness_level": "intermediate",
                "focus_areas": ["full_body"],
            },
        })

    # =====================================================================
    # Block 17 — Dedicated injury sweep (391-500). 110 calls.
    # Bumps cross-surface injury coverage to ≥25%. Each scenario sets
    # `injuries[]` AND varies focus/equipment/fitness/severity context.
    # =====================================================================
    single_injuries = ["knee", "shoulder", "lower_back", "elbow", "wrist", "hip", "ankle", "neck"]
    multi_injuries = [
        ["knee", "shoulder"],
        ["knee", "lower_back"],
        ["shoulder", "wrist"],
        ["shoulder", "elbow"],
        ["lower_back", "hip"],
        ["knee", "ankle"],
        ["wrist", "elbow", "shoulder"],
        ["knee", "hip", "ankle"],
        ["knee", "shoulder", "lower_back"],
        ["knee", "shoulder", "lower_back", "wrist"],
        ["knee", "shoulder", "lower_back", "wrist", "ankle"],
        ["knee", "shoulder", "lower_back", "wrist", "ankle", "hip", "elbow"],
    ]
    inj_focuses = ["full_body", "upper", "lower", "core", "cardio", "mobility"]
    inj_equips = [[], ["dumbbells"], ["resistance_bands"], ["cable_machine"],
                  ["barbell", "dumbbells", "bench"], ["kettlebell"]]
    inj_diffs = ["easy", "medium", "hard"]
    inj_fls = ["beginner", "intermediate", "advanced"]
    inj_prompts = [
        None,
        "post-PT phase 2, cleared for compound lifts at 70%",
        "acute flare-up, painful day — keep gentle",
        "12 weeks post-op ACL, return-to-sport phase",
        "rotator cuff impingement, no overhead work",
        "L4-L5 disc bulge, MRI confirmed, no loaded flexion",
        "tennis elbow medial side, week 6 of rehab",
        "carpal tunnel mild, prefer neutral grip",
        "hip labral tear, surgery declined, avoid deep flexion",
        "Achilles tendinopathy, week 4 of eccentric protocol",
        "whiplash 3 weeks ago, gentle ROM only",
    ]

    inj_scenarios = []
    # 8 singles × 6 focuses = 48
    seq = 0
    for inj in single_injuries:
        for foc in inj_focuses:
            inj_scenarios.append({
                "injuries": [inj], "focus": foc,
                "equip": inj_equips[seq % len(inj_equips)],
                "diff": inj_diffs[seq % len(inj_diffs)],
                "fl": inj_fls[seq % len(inj_fls)],
                "prompt": inj_prompts[seq % len(inj_prompts)],
            })
            seq += 1
    # 12 multi-injury combos × 4 focuses each = 48
    for inj in multi_injuries:
        for foc_idx in range(4):
            inj_scenarios.append({
                "injuries": inj,
                "focus": inj_focuses[(seq + foc_idx) % len(inj_focuses)],
                "equip": inj_equips[seq % len(inj_equips)],
                "diff": "easy" if len(inj) >= 4 else inj_diffs[seq % len(inj_diffs)],
                "fl": inj_fls[seq % len(inj_fls)],
                "prompt": inj_prompts[seq % len(inj_prompts)],
            })
            seq += 1
    # +24 single-injury × duration sweep (15/30/60) for the 8 joints
    for inj in single_injuries:
        for dur_label in ["short15", "long60", "max90"]:
            inj_scenarios.append({
                "injuries": [inj], "focus": "full_body",
                "equip": inj_equips[seq % len(inj_equips)],
                "diff": "medium",
                "fl": inj_fls[seq % len(inj_fls)],
                "prompt": inj_prompts[seq % len(inj_prompts)],
                "_dur_override": {"short15": 15, "long60": 60, "max90": 90}[dur_label],
            })
            seq += 1

    inj_scenarios = inj_scenarios[:120]
    for k, spec in enumerate(inj_scenarios):
        i += 1
        dur = spec.get("_dur_override")
        if dur is None:
            dur = 30 if spec["diff"] == "easy" else 45
        body = {
            "workout_id": src(k + 390)["id"],
            "user_id": USER_ID,
            "duration_minutes": dur,
            "injuries": spec["injuries"],
            "focus_areas": [spec["focus"]],
            "equipment": spec["equip"],
            "difficulty": spec["diff"],
            "fitness_level": spec["fl"],
        }
        if spec["prompt"]:
            body["ai_prompt"] = spec["prompt"]
        s.append({
            "idx": i, "block": 17,
            "label": f"inj={'+'.join(spec['injuries'])} foc={spec['focus']} diff={spec['diff']} dur={dur}",
            "body": body,
        })

    # Filter every body to schema-only keys. Noise defaults (hardcoded
    # fitness_level=intermediate, etc.) stay through but unknown keys (goals,
    # preserve_history, dumbbell_count when out of range, etc.) are dropped here
    # rather than being silently ignored by the endpoint.
    for sc in s:
        sc["body"] = _filter_schema(sc["body"])
    return s[:500]


# Back-compat alias
build_500 = build_100


CSV_COLS = [
    "idx", "scenario_block", "label", "source_workout_id",
    "http_status", "latency_ms", "request_body_json", "sse_event_count",
    "preview_id",
    "workout_id", "workout_name", "workout_type", "workout_difficulty",
    "workout_notes", "n_exercises", "exercise_names_pipe",
    "per_exercise_sets", "per_exercise_reps", "per_exercise_weight_kg",
    "per_exercise_rest_seconds", "per_exercise_muscle_group",
    "duration_minutes", "total_volume_kg", "error_message",
]


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=500)
    parser.add_argument("--pacing", type=float, default=13.0)
    parser.add_argument(
        "--resume", default=None,
        help="Path to existing run dir to resume, OR 'auto' for latest matching dir.",
    )
    args = parser.parse_args()

    print("[harness] auth...", flush=True)
    jwt = get_jwt()
    import time as _t
    jwt_holder = {"jwt": jwt, "minted_at": _t.time()}
    print("[harness] JWT ok", flush=True)

    print("[harness] listing source workouts...", flush=True)
    sources = list_user_workouts(min_count=20)
    if not sources:
        print("[harness] ERROR: user has 0 workouts to regenerate.", flush=True)
        return
    print(f"[harness] {len(sources)} sources found", flush=True)

    scenarios = build_100(sources)[: args.n]
    print(f"[harness] {len(scenarios)} scenarios queued", flush=True)

    out_dir, completed_idx, md_entries = resume_or_init_outputs(
        "render_regenerate_stream_full", CSV_COLS, args.resume,
    )
    url = f"{RENDER}/api/v1/workouts/regenerate-stream"
    started = _dt.now().isoformat(timespec="seconds")

    async with httpx.AsyncClient() as client:
        for sc in scenarios:
            if sc["idx"] in completed_idx:
                print(f"[{sc['idx']}/{len(scenarios)}] SKIP (already done in resume dir)",
                      flush=True)
                continue
            res = await call_sse_with_retry(client, jwt_holder["jwt"], url, sc["body"], jwt_holder=jwt_holder)
            jwt = jwt_holder["jwt"]  # carry refreshed token forward
            ws = workout_summary(res)
            row = {
                "idx": sc["idx"], "scenario_block": sc["block"], "label": sc["label"],
                "source_workout_id": sc["body"].get("workout_id", ""),
                "http_status": res["status"], "latency_ms": res["latency_ms"],
                "request_body_json": json.dumps(sc["body"], default=str),
                "sse_event_count": len(res.get("events") or []),
                "preview_id": res.get("preview_id") or "",
                "error_message": res.get("error") or "",
                **ws,
            }
            full = {"scenario": sc, "result": res, "csv_row": row, "idx": sc["idx"]}
            write_row(out_dir, row, CSV_COLS, full)

            valid = (
                row["http_status"] == 200
                and bool(row["preview_id"])
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
                f"preview={row['preview_id'][:8] if row['preview_id'] else '-'} "
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
