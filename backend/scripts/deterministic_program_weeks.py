#!/usr/bin/env python3
"""
Deterministic weekly/daily generators for the 2026-07 catalog expansion
(generate_28_programs.py). These programs are fixed published protocols —
authoring them locally is cheaper AND more correct than LLM generation.

Every exercise name here was verified against resolve_exercise_demo_media
during pre-flight (2026-07-03). If you add a name, verify it first:
  SELECT count(*) FROM resolve_exercise_demo_media('<name>');

Registry:
  WEEKLY_BUILDERS[slug](week, total_weeks, spw) -> week dict
      {week, phase, focus, workouts: [session, ...]}   (len == spw)
  DAILY_BLOB_BUILDERS[slug]() -> programs.workouts blob (Plank precedent:
      flattened day-by-day, week_length != 7 so respects_training_days
      computes false on the base-blob preview path)
"""
from __future__ import annotations

import copy


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
def ex(name: str, sets: int, reps, rest: int, *, guide: str = "Bodyweight",
       equipment: str = "Bodyweight", body_part: str = "full body",
       muscle: str = "Full Body", difficulty: str = "beginner",
       cue: str = "", secs: int | None = None, notes: str | None = None) -> dict:
    """Standard exercise entry; pass secs for timed moves (adds timer fields)."""
    e = {
        "name": name,
        "exercise_name": name,
        "sets": sets,
        "reps": reps,
        "rest_seconds": rest,
        "weight_guidance": guide,
        "equipment": equipment,
        "body_part": body_part,
        "primary_muscle": muscle,
        "difficulty": difficulty,
        "form_cue": cue,
    }
    if secs is not None:
        e.update({"duration_seconds": secs, "tracking_type": "time",
                  "is_timed": True})
    if notes:
        e["notes"] = notes
    return e


def session(name: str, stype: str, minutes: int, exercises: list,
            notes: str | None = None) -> dict:
    s = {
        "workout_name": name,
        "name": name,
        "type": stype,
        "duration_minutes": minutes,
        "warmup": [],
        "cooldown": [],
        "exercises": exercises,
    }
    if notes:
        s["coach_notes"] = notes
    return s


def _clone_sessions(base: list, spw: int) -> list:
    """Tile a session list out to spw sessions (uniform weeks)."""
    out = []
    i = 0
    while len(out) < spw:
        s = copy.deepcopy(base[i % len(base)])
        if i >= len(base):
            s["workout_name"] = f"{s['workout_name']} ({i // len(base) + 1})"
            s["name"] = s["workout_name"]
        out.append(s)
        i += 1
    return out[:spw]


def _frac(week: int, total: int) -> float:
    return (week - 1) / max(total - 1, 1)


# ---------------------------------------------------------------------------
# 12-3-30 Treadmill — 4w × 5, timed. Ramp: W1 20min@8%, W2 25min@10%, W3+ full.
# ---------------------------------------------------------------------------
def w_12_3_30(week: int, total: int, spw: int) -> dict:
    ramp = min(_frac(week, max(total, 2)) * 1.5, 1.0)
    minutes = [20, 25, 30, 30][min(week - 1, 3)] if total <= 4 else int(20 + 10 * ramp)
    incline = [8, 10, 12, 12][min(week - 1, 3)] if total <= 4 else int(8 + 4 * ramp)
    phase = "Ramp-In" if minutes < 30 else "Full Protocol"
    base = session(
        f"12-3-30 Walk — {minutes} min",
        "Cardio", minutes + 8,
        [
            ex("Walking", 1, "5 minutes easy", 0, secs=300,
               guide="Flat, easy pace", cue="Loosen up before the hill"),
            ex("Incline treadmill walk", 1, f"{minutes} minutes", 0,
               secs=minutes * 60,
               guide=f"Incline {incline}%, speed 3.0 mph",
               body_part="lower legs", muscle="Glutes",
               cue="Stand tall, light grip on rails only if needed",
               notes="The 12-3-30: don't chase speed — the incline does the work."),
            ex("Walking", 1, "3 minutes easy", 0, secs=180,
               guide="Flat, cool down", cue="Let the heart rate drift down"),
        ],
        notes="Same workout every session — consistency is the program.",
    )
    return {"week": week, "phase": phase,
            "focus": f"Incline walking {minutes} min @ {incline}%",
            "workouts": _clone_sessions([base], spw)}


# ---------------------------------------------------------------------------
# VO2max Protocol — 6w × 3: Norwegian 4×4 day + two Zone-2 days.
# ---------------------------------------------------------------------------
def w_vo2max(week: int, total: int, spw: int) -> dict:
    z2_a = min(30 + 3 * (week - 1), 50)      # jog/run zone-2 minutes
    z2_b = min(30 + 2 * (week - 1), 40)      # bike/row zone-2 minutes
    phase = "Base" if week <= 2 else ("Build" if week <= 4 else "Peak")
    s1 = session(
        "Norwegian 4×4 Intervals", "Cardio", 45,
        [
            ex("Jogging", 1, "10 minutes easy", 0, secs=600,
               guide="Zone 1-2 warmup", cue="Finish the warmup slightly sweaty"),
            ex("Running", 4, "4 minutes hard", 180, secs=240,
               guide="90-95% max heart rate",
               body_part="cardio", muscle="Full Body", difficulty="intermediate",
               cue="Hard but repeatable — the 4th interval should match the 1st",
               notes="3-minute ACTIVE recovery (slow walk/jog) between intervals."),
            ex("Walking", 1, "5 minutes easy", 0, secs=300,
               guide="Cool down", cue="Walk it off completely"),
        ],
        notes="The one hard day. Progress = same intervals at a faster pace.",
    )
    s2 = session(
        f"Zone 2 Run — {z2_a} min", "Cardio", z2_a + 5,
        [ex("Jogging", 1, f"{z2_a} minutes easy", 0, secs=z2_a * 60,
            guide="Zone 2 — conversational pace",
            cue="If you can't speak a sentence, slow down")],
        notes="Easy means easy. This session builds the base the 4×4 spends.",
    )
    s3 = session(
        f"Zone 2 Cross — {z2_b} min", "Cardio", z2_b + 5,
        [ex("Stationary bike", 1, f"{z2_b} minutes easy", 0, secs=z2_b * 60,
            guide="Zone 2 — conversational pace", equipment="Stationary bike",
            cue="Smooth cadence, nose-breathing pace",
            notes="Rowing or Elliptical are fine swaps — same duration, same easy effort.")],
    )
    return {"week": week, "phase": phase,
            "focus": "1 × 4×4 VO2max day + zone-2 volume",
            "workouts": _clone_sessions([s1, s2, s3], spw)}


# ---------------------------------------------------------------------------
# Zero to 5K — 9w × 3, canonical run/walk ladder.
# ---------------------------------------------------------------------------
_Z25K = {
    1: ("Run/Walk 1:1.5", [("Running", 8, 60, 90, "1 minute easy jog")],
        "8 rounds: jog 1 minute, brisk-walk 90 seconds between."),
    2: ("Run/Walk 1.5:2", [("Running", 6, 90, 120, "90 seconds easy jog")],
        "6 rounds: jog 90 seconds, walk 2 minutes between."),
    3: ("Run/Walk pyramids", [("Running", 2, 90, 90, "90 seconds easy jog"),
                              ("Running", 2, 180, 180, "3 minutes steady jog")],
        "Two pyramids: 90s jog / 90s walk, then 3min jog / 3min walk."),
    4: ("Longer runs arrive", [("Running", 2, 180, 90, "3 minutes steady"),
                               ("Running", 2, 300, 150, "5 minutes steady")],
        "3min run, 90s walk, 5min run, 2.5min walk — twice through."),
    5: ("5-minute blocks", [("Running", 3, 300, 180, "5 minutes steady")],
        "Three 5-minute runs with 3-minute walks. You're becoming a runner."),
    6: ("8-minute blocks", [("Running", 2, 480, 180, "8 minutes steady")],
        "Two 8-minute runs with a 3-minute walk between."),
    7: ("First continuous run", [("Running", 1, 1500, 0, "25 minutes continuous")],
        "No walk breaks — settle into the slowest pace that still feels like running."),
    8: ("Building the hold", [("Running", 1, 1680, 0, "28 minutes continuous")],
        "28 continuous minutes. Slow is fine; stopping is the only failure."),
    9: ("5K week", [("Running", 1, 1800, 0, "30 minutes continuous — your 5K")],
        "The goal run: 30 continuous minutes. That's Zero to 5K, done."),
}


def w_zero_to_5k(week: int, total: int, spw: int) -> dict:
    focus, blocks, note = _Z25K[min(week, 9)]
    exercises = [ex("Brisk walking", 1, "5 minutes", 0, secs=300,
                    guide="Warmup walk", cue="Wake the legs up")]
    for name, sets, secs, rest, reps in blocks:
        exercises.append(ex(name, sets, reps, rest, secs=secs,
                            guide="Easy — you should be able to speak short sentences",
                            body_part="cardio", muscle="Full Body",
                            cue="Short strides, relaxed shoulders",
                            notes="Walk briskly (don't stand) during every rest." if rest else None))
    exercises.append(ex("Walking", 1, "5 minutes cool-down", 0, secs=300,
                        guide="Easy pace", cue="Shake it out"))
    minutes = round(sum(e.get("duration_seconds", 0) * e["sets"] +
                        e["rest_seconds"] * max(e["sets"] - 1, 0)
                        for e in exercises) / 60) + 2
    base = session(f"Zero to 5K — Week {week} Run", "Cardio", minutes, exercises,
                   notes=note + " Repeat any week that felt brutal — the plan doesn't mind.")
    phase = "Run/Walk" if week <= 4 else ("Run Blocks" if week <= 6 else "Continuous")
    return {"week": week, "phase": phase, "focus": focus,
            "workouts": _clone_sessions([base], spw)}


# ---------------------------------------------------------------------------
# Wave Progression — 12w × 4 barbell waves (8s / 5s / 3s / deload, ×3).
# ---------------------------------------------------------------------------
_WAVE = [  # (phase, sets, reps, pct, rpe)
    ("Volume 8s", 3, 8, 70, "RPE 7"),
    ("Strength 5s", 3, 5, 80, "RPE 8"),
    ("Intensity 3s", 3, 3, 87, "RPE 9"),
    ("Deload", 3, 5, 60, "RPE 5 — easy"),
]

_WAVE_DAYS = {
    "Squat Day": [
        ("Barbell Back Squat", True, "upper legs", "Quadriceps"),
        ("Forward Lunge", False, "upper legs", "Quadriceps"),
        ("Glute Bridge", False, "upper legs", "Glutes"),
        ("Standing Calf Raise", False, "lower legs", "Calves"),
        ("Wall Sit", False, "upper legs", "Quadriceps"),
        ("Plank", False, "waist", "Core"),
    ],
    "Bench Day": [
        ("Barbell Bench Press", True, "chest", "Chest"),
        ("Barbell Row", False, "back", "Lats"),
        ("Push-Up", False, "chest", "Chest"),
        ("Pike Push-Up", False, "shoulders", "Shoulders"),
        ("Dead Bug", False, "waist", "Core"),
        ("Suitcase Carry", False, "full body", "Core"),
    ],
    "Deadlift Day": [
        ("Barbell Deadlift", True, "back", "Lower Back"),
        ("Inverted Row", False, "back", "Lats"),
        ("Glute Bridge", False, "upper legs", "Glutes"),
        ("Farmers Carry", False, "full body", "Forearms"),
        ("Side Plank", False, "waist", "Core"),
        ("Superman", False, "back", "Lower Back"),
    ],
    "Press Day": [
        ("Barbell Overhead Press", True, "shoulders", "Shoulders"),
        ("Assisted Pull-Up", False, "back", "Lats"),
        ("Diamond Push-Up", False, "upper arms", "Triceps"),
        ("Barbell Row", False, "back", "Lats"),
        ("Dead Bug", False, "waist", "Core"),
        ("Farmers Carry", False, "full body", "Forearms"),
    ],
}


def w_wave(week: int, total: int, spw: int) -> dict:
    wave_num = (week - 1) // 4 + 1          # 1..3
    phase, m_sets, m_reps, pct, rpe = _WAVE[(week - 1) % 4]
    bump = (wave_num - 1) * 2.5             # +2.5% per wave on top sets
    sessions = []
    for day_name, moves in _WAVE_DAYS.items():
        exercises = []
        for name, is_main, bp, muscle in moves:
            if is_main:
                exercises.append(ex(
                    name, m_sets, m_reps, 180,
                    guide=f"~{pct + bump:.1f}% 1RM ({rpe})",
                    equipment="Barbell", body_part=bp, muscle=muscle,
                    difficulty="intermediate",
                    cue="Same setup every rep — brace before you unrack",
                    notes=f"Wave {wave_num}: add ~2.5% over the same week last wave."))
            else:
                a_sets, a_reps = (2, 10) if phase == "Deload" else (3, 10)
                timed = name in ("Plank", "Side Plank", "Wall Sit",
                                 "Farmers Carry", "Suitcase Carry")
                exercises.append(ex(
                    name, a_sets, "30 seconds" if timed else a_reps, 90,
                    guide="RPE 7" if phase != "Deload" else "Easy",
                    equipment="Barbell" if name.startswith("Barbell") else "Bodyweight",
                    body_part=bp, muscle=muscle, difficulty="intermediate",
                    cue="Quality over load on accessories",
                    secs=30 if timed else None))
        sessions.append(session(f"{day_name} — {phase}", "Strength", 60, exercises))
    note = ("DELOAD week — half effort on purpose. The next wave starts heavier."
            if phase == "Deload" else
            f"Wave {wave_num} of 3, {phase}: top sets at ~{pct + bump:.1f}%.")
    for s in sessions:
        s["coach_notes"] = note
    return {"week": week, "phase": phase,
            "focus": f"Wave {wave_num} — {phase}",
            "workouts": _clone_sessions(sessions, spw)}


# ---------------------------------------------------------------------------
# Rucking Ready — 8w × 3: loaded ruck / leg strength / recovery walk.
# ---------------------------------------------------------------------------
def w_rucking(week: int, total: int, spw: int) -> dict:
    ruck_min = [20, 25, 30, 30, 35, 40, 40, 45][min(week - 1, 7)]
    load_pct = [5, 5, 8, 10, 10, 12, 15, 15][min(week - 1, 7)]
    phase = "Base" if week <= 3 else ("Build" if week <= 6 else "Peak")
    s1 = session(
        f"Loaded Ruck — {ruck_min} min", "Cardio", ruck_min + 5,
        [ex("Brisk walking", 1, f"{ruck_min} minutes loaded", 0, secs=ruck_min * 60,
            guide=f"Pack at ~{load_pct}% bodyweight", equipment="Backpack",
            cue="Tall posture, pack high and tight, roll through the whole foot",
            notes="One variable at a time: this week's duration and load are set — don't add both.")],
        notes="The ruck IS the workout. Walk with intent.",
    )
    s2 = session(
        "Ruck Legs", "Strength", 40,
        [
            ex("Step-Up", 3, 10, 60, guide="Bodyweight or light pack",
               body_part="upper legs", muscle="Quadriceps",
               cue="Drive through the top foot, no push-off from the floor leg"),
            ex("Forward Lunge", 3, 10, 60, body_part="upper legs",
               muscle="Quadriceps", cue="Long stride, knee tracks the toe"),
            ex("Bodyweight Squat", 3, 15, 45, body_part="upper legs",
               muscle="Quadriceps", cue="Sit back and down, chest proud"),
            ex("Standing Calf Raise", 3, 15, 45, body_part="lower legs",
               muscle="Calves", cue="Full range — rucks live on your calves"),
            ex("Glute Bridge", 3, 12, 45, body_part="upper legs",
               muscle="Glutes", cue="Squeeze at the top for a full second"),
            ex("Plank", 3, "40 seconds", 45, secs=40, body_part="waist",
               muscle="Core", cue="The pack needs a stiff trunk"),
        ],
    )
    s3 = session(
        "Recovery Walk", "Recovery", 30,
        [ex("Walking", 1, "30 minutes easy — NO pack", 0, secs=1800,
            guide="Unloaded, easy pace", cue="This one is for the joints")],
    )
    return {"week": week, "phase": phase,
            "focus": f"Ruck {ruck_min} min @ ~{load_pct}% BW",
            "workouts": _clone_sessions([s1, s2, s3], spw)}


# ---------------------------------------------------------------------------
# Jump Rope 10 — 4w × 5 × 10min express circuits (Skipping + low-impact actives).
# ---------------------------------------------------------------------------
_JR_FILLERS = [
    ("Standing Calf Raise", "lower legs", "Calves"),
    ("High Knees", "upper legs", "Hip Flexors"),
    ("Air Squat", "upper legs", "Quadriceps"),
    ("Mountain Climber", "waist", "Abdominals"),
    ("Jumping Jack", "full body", "Full Body"),
]


def w_jump_rope(week: int, total: int, spw: int) -> dict:
    work = [30, 40, 50, 60][min(week - 1, 3)]
    rest = [20, 20, 15, 15][min(week - 1, 3)]
    rounds = 4
    phase = ["Foundation", "Build", "Build", "Peak"][min(week - 1, 3)]
    sessions = []
    for i in range(spw):
        filler_name, bp, muscle = _JR_FILLERS[i % len(_JR_FILLERS)]
        exercises = []
        for _ in range(rounds):
            exercises.append(ex("Skipping", 1, f"{work} seconds", rest, secs=work,
                                guide="Smooth, low bounce", equipment="Jump rope",
                                body_part="full body", muscle="Calves",
                                cue="Wrists spin the rope, not the arms",
                                notes="Trip? Restart the interval — it still counts."))
            exercises.append(ex(filler_name, 1, "30 seconds", rest, secs=30,
                                body_part=bp, muscle=muscle,
                                cue="Active recovery pace — keep breathing"))
        sessions.append(session(
            f"Jump Rope 10 — Circuit {chr(65 + i % 5)}", "HIIT", 10, exercises,
            notes=f"{rounds} rounds of {work}s rope / 30s active. Ten minutes, done."))
    return {"week": week, "phase": phase,
            "focus": f"{work}s rope intervals", "workouts": sessions}


# ---------------------------------------------------------------------------
# Shadow Boxing Conditioning — 4w × 5 × 20min round-based sessions.
# ---------------------------------------------------------------------------
_SB_ACTIVES = [
    [("Air Squat", "upper legs", "Quadriceps"), ("Dead Bug", "waist", "Core")],
    [("Mountain Climber", "waist", "Abdominals"), ("Push-Up", "chest", "Chest")],
    [("High Knees", "upper legs", "Hip Flexors"), ("Plank", "waist", "Core")],
    [("Forward Lunge", "upper legs", "Quadriceps"), ("Side Plank", "waist", "Core")],
    [("Jumping Jack", "full body", "Full Body"), ("Superman", "back", "Lower Back")],
]


def w_shadow_boxing(week: int, total: int, spw: int) -> dict:
    rounds = [4, 5, 5, 6][min(week - 1, 3)]
    phase = ["Foundation", "Build", "Build", "Peak"][min(week - 1, 3)]
    sessions = []
    for i in range(spw):
        actives = _SB_ACTIVES[i % len(_SB_ACTIVES)]
        exercises = []
        for r in range(rounds):
            exercises.append(ex(
                "Shadow boxing", 1, "3 minutes", 60, secs=180,
                guide="Jab-cross-hook combos, constant footwork",
                body_part="full body", muscle="Full Body",
                cue="Stay light on your feet; exhale on every punch",
                notes=f"Round {r + 1} of {rounds}. Work at a talk-in-short-sentences pace."))
            a_name, bp, muscle = actives[r % len(actives)]
            timed = a_name in ("Plank", "Side Plank")
            exercises.append(ex(a_name, 1, "30 seconds", 30, secs=30 if timed else 30,
                                body_part=bp, muscle=muscle,
                                cue="Active break — keep moving"))
        sessions.append(session(
            f"Shadow Boxing — Session {chr(65 + i % 5)}", "HIIT", 20, exercises,
            notes=f"{rounds} × 3-minute rounds with actives between."))
    return {"week": week, "phase": phase,
            "focus": f"{rounds} rounds on the clock", "workouts": sessions}


# ---------------------------------------------------------------------------
# Daily blobs (Plank Challenge precedent: flattened 30-day base blob, no matrix)
# ---------------------------------------------------------------------------
def blob_daily_walk() -> dict:
    days = []
    for d in range(1, 31):
        week = (d - 1) // 7
        if d % 7 == 0:
            days.append({
                "day": d, "type": "Recovery",
                "workout_name": f"Day {d} — Recovery Stroll",
                "exercises": [ex("Walking", 1, "15 minutes, genuinely easy", 0,
                                 secs=900, guide="Stroll pace",
                                 cue="This one protects the streak, not the lungs")],
            })
            continue
        minutes = min(15 + week * 5 + (d % 7 - 1), 40)
        if d == 30:
            minutes = 40
        days.append({
            "day": d, "type": "Cardio",
            "workout_name": f"Day {d} — {minutes}-Minute Brisk Walk",
            "exercises": [ex("Brisk walking", 1, f"{minutes} minutes", 0,
                             secs=minutes * 60,
                             guide="Brisk — breathing harder, still able to talk",
                             cue="Head up, arms swinging, own the pace",
                             notes="Outside if you can. Missed yesterday? Repeat it — nothing resets.")],
        })
    return {
        "program": "Daily Walk Challenge",
        "category": "Getting Started",
        "duration": "5 weeks",
        "difficulty": "Beginner",
        "description": ("A 30-day walking streak from 15 easy minutes to a 40-minute "
                        "victory lap, with a recovery stroll every 7th day. Repeat a "
                        "missed day rather than restarting."),
        "session_duration": 25,
        "sessions_per_week": 6,
        "goals": ["Habit-Building", "Cardio Health", "Fat Loss"],
        "workouts": days,
    }


def blob_squat_30() -> dict:
    days = []
    reps_ladder = [10, 12, 14, 0, 15, 16, 18, 0, 20, 22, 24, 0, 25, 26, 28, 0,
                   30, 32, 34, 0, 35, 36, 38, 0, 40, 42, 44, 0, 46, 50]
    for d in range(1, 31):
        target = reps_ladder[d - 1]
        if target == 0:  # every 4th day: recovery
            days.append({
                "day": d, "type": "Rest",
                "workout_name": f"Day {d} — Recovery",
                "exercises": [
                    ex("Child Pose", 1, "60 seconds", 0, secs=60,
                       guide="Breathe and decompress",
                       body_part="back", muscle="Lower Back",
                       cue="Sink the hips back, long exhales"),
                    ex("Standing Calf Raise", 2, 12, 30,
                       body_part="lower legs", muscle="Calves",
                       cue="Easy pumps to flush the legs"),
                ],
            })
            continue
        variation_day = d % 3 == 2
        exercises = []
        if d == 30:
            exercises.append(ex("Bodyweight Squat", 1, 50, 0,
                                body_part="upper legs", muscle="Quadriceps",
                                cue="Break it into mini-sets if needed — 50 total is the win",
                                notes="THE TEST: 50 reps. Rest-pause allowed. Celebrate after."))
        else:
            sets = 3 if d <= 16 else 2
            exercises.append(ex("Bodyweight Squat", sets, target // (1 if sets == 1 else 2) + 2, 45,
                                body_part="upper legs", muscle="Quadriceps",
                                cue="Sit back and down, knees track the toes",
                                notes=f"Day {d} target: ~{target} quality reps total."))
            if variation_day:
                exercises.append(ex("Sumo Squat", 2, 10, 45,
                                    body_part="upper legs", muscle="Adductors",
                                    cue="Wide stance, toes out, knees pushed out"))
                exercises.append(ex("Wall Sit", 2, "30 seconds", 30, secs=30,
                                    body_part="upper legs", muscle="Quadriceps",
                                    cue="Thighs parallel, back flat on the wall"))
            else:
                exercises.append(ex("Glute Bridge", 2, 12, 30,
                                    body_part="upper legs", muscle="Glutes",
                                    cue="Drive through heels, squeeze at the top"))
                exercises.append(ex("Chair Squat", 2, 8, 30,
                                    body_part="upper legs", muscle="Quadriceps",
                                    cue="Tap the chair, don't sit — control the descent"))
        days.append({
            "day": d, "type": "Strength",
            "workout_name": f"Day {d} — Squat Ladder" if not variation_day
                            else f"Day {d} — Squat Variations",
            "exercises": exercises,
        })
    return {
        "program": "30-Day Squat Challenge",
        "category": "Quick Hits",
        "duration": "5 weeks",
        "difficulty": "Beginner",
        "description": ("A daily squat progression from 3×10 to a 50-rep test, with "
                        "variation days and a recovery day every 4th day. Repeat a "
                        "missed day rather than restarting."),
        "session_duration": 12,
        "sessions_per_week": 6,
        "goals": ["Leg Strength", "Habit-Building", "Endurance"],
        "workouts": days,
    }


WEEKLY_BUILDERS = {
    "treadmill-12-3-30": w_12_3_30,
    "vo2max-protocol": w_vo2max,
    "zero-to-5k": w_zero_to_5k,
    "wave-progression": w_wave,
    "rucking-ready": w_rucking,
    "jump-rope-10": w_jump_rope,
    "shadow-boxing": w_shadow_boxing,
}

DAILY_BLOB_BUILDERS = {
    "daily-walk-challenge": blob_daily_walk,
    "squat-challenge-30": blob_squat_30,
}
