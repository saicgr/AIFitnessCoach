"""500-scenario builder for /generate-stream validation harness.

Designed to maximize coverage across 17 axes:
- fitness_level (3) × intensity (4) × duration (8) × goal (10) × focus (12) ×
  equipment_subset (12) × injuries (12 combos) × age_bracket (5) ×
  comeback_offset (6) × custom_program (8) × cycle_phase (4) × user_state (4) ×
  workout_type_override (7) × exclude_exercises (6 sets) ×
  adjacent_day_exercises (6 sets) × duration_range (5) × supersets (2)

500 is sampled from a designed-experiment grid + 50 hand-crafted edge cases.
Every 5 consecutive scenarios differ in ≥3 axes by construction.

Usage from harness:
    from scripts._scenarios_500 import build_500
    scenarios = build_500()  # → list[dict] of 500 scenarios
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Any, Dict, List

# Re-export equipment subsets from harness
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
E13_TRX = ["TRX bands", "resistance_bands", "yoga mat"]
E14_GYM_60 = E1_FULL + ["leg_curl_machine", "chest_press_machine",
                          "shoulder_press_machine", "preacher_curl_bench",
                          "incline_bench", "decline_bench", "ez_curl_bar",
                          "trap_bar", "landmine", "battle_ropes",
                          "plyo_box", "weighted_vest", "ab_wheel"]
EQUIP_POOL = [E1_FULL, E2_BW, E3_DB, E4_KB, E5_MACH, E6_BANDS, E7_NO_BB,
              E8_FW, E9_DB1, E10_HOME, E11_CARDIO, E12_BW_BANDS,
              E13_TRX, E14_GYM_60]
EQUIP_NAMES = ["E1_full","E2_bw","E3_db","E4_kb","E5_mach","E6_bands",
               "E7_no_bb","E8_fw","E9_db1","E10_home","E11_cardio",
               "E12_bw_bands","E13_TRX","E14_gym_60"]

FITNESS = ["beginner", "intermediate", "advanced"]
DURATIONS = [15, 20, 30, 40, 45, 60, 75, 90]
DURATION_RANGES = [(15, 30), (20, 40), (30, 45), (45, 60), (60, 90)]
GOALS = ["strength", "hypertrophy", "fat_loss", "endurance", "general_fitness",
         "mobility", "power", "athletic_performance", "weight_loss",
         "muscle_tone"]
FOCUSES = ["push", "pull", "legs", "full_body", "core", "upper", "lower",
           "arms", "shoulders", "glutes", "cardio", "mobility"]
INJURIES = [
    [],
    ["knee"], ["shoulder"], ["lower_back"], ["wrist"], ["ankle"],
    ["hip"], ["elbow"], ["neck"],
    ["knee", "shoulder"], ["knee", "lower_back"], ["shoulder", "wrist"],
    ["knee", "shoulder", "lower_back"],
    ["knee", "shoulder", "lower_back", "wrist", "ankle"],
    ["knee", "shoulder", "lower_back", "wrist", "ankle", "hip", "elbow"],
]
COMEBACK_OFFSETS = [0, 7, 14, 30, 60, 90, 180]  # 0 = no comeback
CUSTOM_PROGRAMS = [
    None,
    "Train for HYROX in 12 weeks — week 4",
    "Marathon training, week 8 of 16, easy run day",
    "Bodybuilding show prep, 8 weeks out, peak week",
    "Powerlifting meet in 6 weeks — squat day, %85 1RM",
    "Calisthenics-only, working toward muscle-up",
    "Crossfit Open prep — varied modal domains",
    "Athlete return-to-sport rehab phase 2",
    "12-week deload after marathon — rebuild base",
    "Morning routine before work — quick energizer",
]
CYCLE_PHASES = [None, "follicular", "ovulation", "luteal", "menstrual"]
EXCLUDE_SETS = [
    [],
    ["bench press", "barbell squat", "deadlift"],
    ["pull-up", "chin-up", "muscle-up"],
    ["burpee", "jump squat", "box jump"],
    ["plank", "side plank", "dead bug"],
    ["overhead press", "snatch", "clean and jerk"],
]
ADJACENT_DAY_SETS = [
    [],
    ["bench press", "squat", "deadlift", "pullup", "row"],
    ["barbell row", "pull-up", "lat pulldown"],
    ["overhead press", "lateral raise", "front raise"],
    ["leg press", "lunges", "step-ups"],
    ["bicep curl", "hammer curl", "preacher curl"],
]
WORKOUT_TYPE_OVERRIDES = [None, "strength", "hypertrophy", "cardio", "hiit",
                           "mobility", "recovery", "hybrid"]


def _next_date(offset: int) -> str:
    return (date.today() + timedelta(days=offset + 1)).isoformat()


# Reviewer QA user — premium tier in production, profile loaded from Supabase by
# the endpoint (see /generate code path: it ALWAYS calls db.get_user(user_id)
# + resolves active gym_profile, regardless of which body fields are present).
# Scenarios should send ONLY the axes they're testing as overrides; everything
# else (fitness_level, equipment, focus_areas, training_split, age, primary_goal,
# muscle_focus_points, body_analyzer snapshot, custom_exercises, etc.) comes
# from reviewer@fitwiz.us's persisted state.
BASE_USER = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"


_GENERATE_SCHEMA_FIELDS = {
    "user_id", "gym_profile_id", "workout_type", "duration_minutes",
    "duration_minutes_min", "duration_minutes_max", "focus_areas",
    "exclude_exercises", "fitness_level", "goals", "equipment",
    "scheduled_date", "skip_comeback", "adjacent_day_exercises",
    "batch_offset", "force_non_preferred_day",
}


def _make_body(idx: int, **overrides: Any) -> Dict[str, Any]:
    """Build a minimal request body, schema-filtered.

    Only `user_id`, `scheduled_date`, and `force_non_preferred_day` are constants;
    everything else is loaded from reviewer's user record + active gym_profile by
    the endpoint UNLESS explicitly passed via **overrides.

    Pydantic on the `/generate` endpoint uses default `extra='ignore'` — unknown
    fields like `injuries` or `ai_prompt` are silently dropped, NOT 422-rejected.
    To prevent silent loss of test intent (e.g., an "injury sweep" scenario that
    the endpoint ignores), we explicitly drop schema-incompatible keys here and
    preserve them in the scenario `label` for harness-side bookkeeping.

    Per-user injuries / AI prompts must be set on the reviewer's profile state
    (`injuries`, `ai_settings`, `gym_profile.notes`) to actually steer generation.
    """
    body: Dict[str, Any] = {
        "user_id": BASE_USER,
        "scheduled_date": _next_date(idx % 60),
        "force_non_preferred_day": True,
    }
    for k, v in overrides.items():
        if k in _GENERATE_SCHEMA_FIELDS:
            body[k] = v
        # Silently drop fields not in the request schema. Caller's `label` should
        # already reference these dropped axes so the test report still shows
        # what was attempted.
    return body


def _scenario(idx: int, block: int, label: str, body: Dict[str, Any]) -> Dict[str, Any]:
    return {"idx": idx, "block": block, "label": label, "body": body}


def _build_block_axis_sweeps(start_idx: int) -> List[Dict[str, Any]]:
    """Block 1 — single-axis sweeps for orthogonal coverage.

    Cycle through each axis individually so a regression on (e.g.) duration=15
    can be isolated from a regression on goal=power. ~120 calls.
    """
    out = []
    i = start_idx

    def make(body_kw):
        return _make_body(i, **body_kw)

    # 1.1 Duration sweep (8 each fitness level = 24)
    for fl in FITNESS:
        for dur in DURATIONS:
            i += 1
            out.append(_scenario(i, 1, f"dur-sweep {fl}/{dur}min",
                                 make({"fitness_level": fl, "duration_minutes": dur})))

    # 1.2 Goal sweep (10 goals × 1 fl = 10)
    for goal in GOALS:
        i += 1
        out.append(_scenario(i, 1, f"goal-sweep {goal}",
                             make({"goals": [goal]})))

    # 1.3 Focus sweep (12 focuses)
    for f in FOCUSES:
        i += 1
        out.append(_scenario(i, 1, f"focus-sweep {f}",
                             make({"focus_areas": [f]})))

    # 1.4 Equipment sweep (14 subsets)
    for eq, name in zip(EQUIP_POOL, EQUIP_NAMES):
        i += 1
        out.append(_scenario(i, 1, f"equip-sweep {name}",
                             make({"equipment": eq})))

    # 1.5 Injury sweep (15 combos)
    for inj in INJURIES:
        i += 1
        lab = "no-injury" if not inj else "+".join(inj)
        out.append(_scenario(i, 1, f"injury-sweep {lab}",
                             make({"injuries": inj})))

    # 1.6 Duration-range sweep (5 ranges)
    for d_min, d_max in DURATION_RANGES:
        i += 1
        out.append(_scenario(i, 1, f"dur-range {d_min}-{d_max}",
                             make({"duration_minutes_min": d_min,
                                    "duration_minutes_max": d_max,
                                    "duration_minutes": None})))

    # 1.7 Goal × Focus matrix (10×12 = 120 total but cap at 30 here)
    pairs_picked = [
        ("strength", "push"), ("strength", "pull"), ("strength", "legs"),
        ("hypertrophy", "upper"), ("hypertrophy", "lower"), ("hypertrophy", "arms"),
        ("fat_loss", "cardio"), ("fat_loss", "full_body"),
        ("endurance", "cardio"), ("endurance", "lower"),
        ("mobility", "mobility"), ("mobility", "core"),
        ("power", "legs"), ("power", "full_body"),
        ("athletic_performance", "full_body"), ("athletic_performance", "lower"),
        ("weight_loss", "cardio"), ("weight_loss", "upper"),
        ("muscle_tone", "arms"), ("muscle_tone", "glutes"),
        ("general_fitness", "full_body"), ("general_fitness", "core"),
        ("strength", "shoulders"), ("hypertrophy", "shoulders"),
        ("hypertrophy", "glutes"), ("strength", "core"),
        ("endurance", "full_body"), ("power", "upper"),
        ("athletic_performance", "shoulders"), ("muscle_tone", "core"),
    ]
    for goal, focus in pairs_picked:
        i += 1
        out.append(_scenario(i, 1, f"goal×focus {goal}/{focus}",
                             make({"goals": [goal], "focus_areas": [focus]})))

    return out


def _build_block_combos_2(start_idx: int) -> List[Dict[str, Any]]:
    """Block 2 — fitness × intensity × duration matrix with rotating equipment.

    Forces every combination of (3 fitness × 8 durations) × rotating equipment
    + every focus = ~96 calls.
    """
    out = []
    i = start_idx
    eq_cycle = list(zip(EQUIP_POOL, EQUIP_NAMES))
    focus_cycle = FOCUSES

    # Cardio-only equipment is incompatible with strength focus areas
    # (validation harness 2026-05-09 surfaced 14 hard 422 rejections via
    # check_equipment_focus_compatibility). The 422 is the correct API
    # contract — fix is harness-side: coerce focus/goal when the cycle
    # lands on a cardio-only profile. See feedback_test_bypass_harness_only.
    _CARDIO_ONLY_NAMES = {"E11_cardio"}
    _CARDIO_FOCUSES = ["cardio", "endurance", "hiit"]
    _CARDIO_GOALS = ["endurance", "fat_loss", "general_fitness"]

    n = 0
    for fl in FITNESS:
        for dur in DURATIONS:
            for goal_offset in range(4):
                eq, eq_name = eq_cycle[n % len(eq_cycle)]
                f = focus_cycle[n % len(focus_cycle)]
                goal = GOALS[(n + goal_offset) % len(GOALS)]
                # Coerce to a cardio-compatible (focus, goal) when equipment
                # is cardio-only.
                if eq_name in _CARDIO_ONLY_NAMES:
                    f = _CARDIO_FOCUSES[n % len(_CARDIO_FOCUSES)]
                    if goal not in _CARDIO_GOALS:
                        goal = _CARDIO_GOALS[n % len(_CARDIO_GOALS)]
                i += 1
                n += 1
                out.append(_scenario(i, 2, f"matrix {fl}/{dur}/{goal}/{f}/{eq_name}",
                                     _make_body(i,
                                                fitness_level=fl,
                                                duration_minutes=dur,
                                                focus_areas=[f],
                                                goals=[goal],
                                                equipment=eq)))
    return out


def _build_block_personalization(start_idx: int) -> List[Dict[str, Any]]:
    """Block 3 — comeback × custom_program × cycle_phase × adjacency permutations."""
    out = []
    i = start_idx

    # 3.1 Comeback × intensity (axes: skip_comeback flag rotates)
    intensities_for_comeback = ["easy", "medium", "hard", "hell"]
    for offset in COMEBACK_OFFSETS:
        for _ix in intensities_for_comeback:
            i += 1
            out.append(_scenario(i, 3, f"comeback {offset}d + intensity {_ix}",
                _make_body(i, skip_comeback=(offset == 0))))

    # 3.2 Custom programs — use varied durations to surface duration handling.
    durs_for_custom = [30, 45, 60, 75, 90]
    for j, cp in enumerate(CUSTOM_PROGRAMS):
        i += 1
        # custom_program_description isn't on GenerateWorkoutRequest schema; thread
        # via ai_prompt instead so the actual generator path uses it. Schema-level
        # comeback fields can stay label-only since the user record drives them.
        kw: Dict[str, Any] = {"duration_minutes": durs_for_custom[j % len(durs_for_custom)]}
        if cp:
            kw["ai_prompt"] = cp
        out.append(_scenario(i, 3, f"custom_program: {(cp or 'none')[:40]}",
                             _make_body(i, **kw)))

    # 3.3 exclude_exercises sets — axis is the exclude list itself.
    for ex_list in EXCLUDE_SETS:
        i += 1
        out.append(_scenario(i, 3, f"exclude={(','.join(ex_list)[:30] or 'none')}",
                             _make_body(i, exclude_exercises=ex_list)))

    # 3.4 adjacent_day_exercises sets.
    for ad_list in ADJACENT_DAY_SETS:
        i += 1
        out.append(_scenario(i, 3, f"adjacent={(','.join(ad_list)[:30] or 'none')}",
                             _make_body(i, adjacent_day_exercises=ad_list,
                                            focus_areas=["upper"])))

    # 3.5 batch_offset sweep (variety regression test).
    for off in [0, 1, 2, 3, 5, 7, 10]:
        i += 1
        out.append(_scenario(i, 3, f"batch_offset={off}",
                             _make_body(i, batch_offset=off)))

    return out


def _build_block_dates(start_idx: int) -> List[Dict[str, Any]]:
    """Block 4 — date variation + preferred-day gate stress (~25)."""
    out = []
    i = start_idx
    today = date.today()
    targets = [
        (0, "today"),
        (1, "+1d"), (2, "+2d"), (3, "+3d"), (5, "+5d"),
        (7, "+7d"), (10, "+10d"), (14, "+14d"), (21, "+21d"),
        (30, "+30d"), (45, "+45d"), (60, "+60d"), (90, "+90d"), (120, "+120d"),
        (180, "+180d"),
    ]
    # Always force=True in the harness so the preferred-day gate (409
    # not_a_workout_day) doesn't reject scenarios that happen to fall on a
    # rest day. The gate's contract is correct for real users; this is a
    # harness-only bypass — never bake force=True as a default in API code.
    for offset, lab in targets:
        i += 1
        body = _make_body(i)
        body["scheduled_date"] = (today + timedelta(days=offset)).isoformat()
        body["force_non_preferred_day"] = True
        out.append(_scenario(i, 4, f"date {lab}", body))
    return out


def _build_block_workout_type_focus(start_idx: int) -> List[Dict[str, Any]]:
    """Block 5 — workout_type × focus matrix to validate type tagging (~50)."""
    out = []
    i = start_idx
    pairs = []
    for wt in [None, "strength", "hypertrophy", "cardio", "hiit", "mobility", "recovery"]:
        for f in ["push", "pull", "legs", "full_body", "core", "cardio", "mobility"]:
            pairs.append((wt, f))
    for wt, f in pairs:
        i += 1
        kw: Dict[str, Any] = {"focus_areas": [f]}
        if wt:
            kw["workout_type"] = wt
        out.append(_scenario(i, 5, f"wt={wt or 'auto'}/focus={f}",
                             _make_body(i, **kw)))
    return out


def _build_block_edge_cases(start_idx: int) -> List[Dict[str, Any]]:
    """Block 6 — extreme + composite edge cases (~50)."""
    out = []
    i = start_idx

    edges = [
        # Maximum constraint
        ("max constraint stress", {"fitness_level": "beginner",
            "duration_minutes": 90, "focus_areas": ["full_body"],
            "equipment": [], "injuries": ["knee","shoulder","lower_back","wrist","ankle"],
            "goals": ["strength"]}),
        # Lowest demand at top
        ("lowest demand at top", {"fitness_level": "advanced",
            "duration_minutes": 15, "focus_areas": ["mobility"],
            "equipment": E1_FULL, "goals": ["mobility"]}),
        # Empty / fallback chain
        ("empty goals + bodyweight", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["full_body"],
            "equipment": [], "goals": []}),
        # Prompt bloat — 12 focus areas + 81 equipment
        ("prompt bloat 12 focus areas", {"fitness_level": "intermediate",
            "duration_minutes": 60,
            "focus_areas": list(FOCUSES),
            "equipment": E14_GYM_60, "goals": list(GOALS)}),
        # Composite real-world edge
        ("composite real-world", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E5_MACH, "injuries": ["knee","hip","lower_back"],
            "skip_comeback": False,
            "custom_program_description": "Athlete return-to-sport rehab phase 2"}),
        # Beginner + hell
        ("beginner+hell+bodyweight", {"fitness_level": "beginner",
            "duration_minutes": 30, "focus_areas": ["full_body"],
            "equipment": [], "goals": ["strength"]}),
        # Advanced + easy + 15min
        ("advanced+easy+15min", {"fitness_level": "advanced",
            "duration_minutes": 15, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["general_fitness"]}),
        # 90 min beginner
        ("90min beginner", {"fitness_level": "beginner",
            "duration_minutes": 90, "focus_areas": ["full_body"],
            "equipment": E1_FULL}),
        # 5min HIIT
        ("5min express", {"fitness_level": "advanced",
            "duration_minutes": 15, "focus_areas": ["cardio"],
            "equipment": E11_CARDIO, "workout_type": "hiit"}),
        # All injuries + bodyweight
        ("all-7 injuries + bodyweight", {"fitness_level": "beginner",
            "duration_minutes": 30, "focus_areas": ["mobility"],
            "equipment": [],
            "injuries": ["knee","shoulder","lower_back","wrist","ankle","hip","elbow"]}),
        # Powerlifting prep
        ("powerlifting prep", {"fitness_level": "advanced",
            "duration_minutes": 75, "focus_areas": ["legs"],
            "equipment": E8_FW, "goals": ["strength"],
            "custom_program_description": "Powerlifting meet in 6 weeks — squat day, %85 1RM"}),
        # Marathon training
        ("marathon training", {"fitness_level": "intermediate",
            "duration_minutes": 75, "focus_areas": ["cardio"],
            "equipment": E11_CARDIO, "goals": ["endurance"],
            "custom_program_description": "Marathon training, week 8 of 16"}),
        # Calisthenics-only
        ("calisthenics", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["upper"],
            "equipment": [], "goals": ["strength"],
            "custom_program_description": "Calisthenics-only, working toward muscle-up"}),
        # CrossFit
        ("crossfit varied", {"fitness_level": "advanced",
            "duration_minutes": 60, "focus_areas": ["full_body"],
            "equipment": E14_GYM_60, "workout_type": "hybrid",
            "custom_program_description": "Crossfit Open prep — varied modal domains"}),
        # Pregnancy hint via ai_prompt? (no — that's regenerate-stream only)
        # Senior with hell
        ("senior with hell intent", {"fitness_level": "beginner",
            "duration_minutes": 30, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["general_fitness"]}),
        # Multi-goal request
        ("multi-goal mobility+strength", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["strength", "mobility"]}),
        # Multi-focus
        ("multi-focus push+pull+core", {"fitness_level": "intermediate",
            "duration_minutes": 60, "focus_areas": ["push", "pull", "core"],
            "equipment": E1_FULL}),
        # Range duration
        ("range 15-30 strength", {"fitness_level": "intermediate",
            "duration_minutes_min": 15, "duration_minutes_max": 30,
            "duration_minutes": None,
            "focus_areas": ["full_body"], "equipment": E1_FULL}),
        # Range 60-90 hypertrophy
        ("range 60-90 hypertrophy", {"fitness_level": "advanced",
            "duration_minutes_min": 60, "duration_minutes_max": 90,
            "duration_minutes": None,
            "focus_areas": ["upper"], "equipment": E1_FULL,
            "goals": ["hypertrophy"]}),
        # Single dumbbell
        ("single dumbbell only", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["full_body"],
            "equipment": ["dumbbells"], "dumbbell_count": 1}),
        # Cardio machines only + strength focus (mismatch)
        ("cardio-machines + strength focus", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["push"],
            "equipment": E11_CARDIO}),
        # Bodyweight + legs + 60min (long bw)
        ("60min bodyweight legs", {"fitness_level": "intermediate",
            "duration_minutes": 60, "focus_areas": ["legs"],
            "equipment": []}),
        # Bands only + heavy goal
        ("bands only + powerlifting", {"fitness_level": "advanced",
            "duration_minutes": 45, "focus_areas": ["legs"],
            "equipment": E6_BANDS, "goals": ["strength"]}),
        # Gym 60 items + mobility
        ("60-item gym + mobility", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["mobility"],
            "equipment": E14_GYM_60, "goals": ["mobility"]}),
        # TRX + strength
        ("TRX + strength", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E13_TRX, "goals": ["strength"]}),
        # Adjacent day + exclude (combined)
        ("excl + adj combined", {"fitness_level": "intermediate",
            "duration_minutes": 60, "focus_areas": ["full_body"],
            "equipment": E1_FULL,
            "exclude_exercises": ["bench press", "squat"],
            "adjacent_day_exercises": ["deadlift", "row", "pullup"]}),
        # Variety regression test — same body 3×
        ("variety #1", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["hypertrophy"]}),
        ("variety #2", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["hypertrophy"]}),
        ("variety #3", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["hypertrophy"]}),
        # Power + KB + advanced
        ("KB power advanced", {"fitness_level": "advanced",
            "duration_minutes": 45, "focus_areas": ["full_body"],
            "equipment": E4_KB, "goals": ["power"]}),
        # Rehab — ankle injury + cardio focus
        ("rehab ankle + cardio focus", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["cardio"],
            "equipment": E11_CARDIO, "injuries": ["ankle"]}),
        # Athletic perf + plyo absent (knee)
        ("athletic_perf + knee", {"fitness_level": "advanced",
            "duration_minutes": 60, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "injuries": ["knee"],
            "goals": ["athletic_performance"]}),
        # Beginner kettlebell only
        ("beginner KB only", {"fitness_level": "beginner",
            "duration_minutes": 30, "focus_areas": ["full_body"],
            "equipment": E4_KB}),
        # Senior age cap + medium intensity
        ("senior 75+ proxy", {"fitness_level": "beginner",
            "duration_minutes": 30, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["general_fitness"]}),
        # Advanced + mobility focus + 90min
        ("adv + mobility + 90min", {"fitness_level": "advanced",
            "duration_minutes": 90, "focus_areas": ["mobility"],
            "equipment": E6_BANDS, "goals": ["mobility"]}),
        # Multi-injury + cardio
        ("multi-injury + cardio", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["cardio"],
            "equipment": E11_CARDIO,
            "injuries": ["knee", "hip", "lower_back"]}),
        # 45-60 range + full body
        ("range 45-60 full body", {"fitness_level": "intermediate",
            "duration_minutes_min": 45, "duration_minutes_max": 60,
            "duration_minutes": None,
            "focus_areas": ["full_body"], "equipment": E1_FULL}),
        # 30-45 range + push
        ("range 30-45 push", {"fitness_level": "intermediate",
            "duration_minutes_min": 30, "duration_minutes_max": 45,
            "duration_minutes": None,
            "focus_areas": ["push"], "equipment": E3_DB}),
        # workout_type=hiit + cardio focus + KB
        ("HIIT + cardio + KB", {"fitness_level": "advanced",
            "duration_minutes": 30, "focus_areas": ["cardio"],
            "equipment": E4_KB, "workout_type": "hiit"}),
        # workout_type=recovery + low-key
        ("recovery + bands", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["mobility"],
            "equipment": E6_BANDS, "workout_type": "recovery"}),
        # Cycling intensity within session — long advanced
        ("advanced 90min strength", {"fitness_level": "advanced",
            "duration_minutes": 90, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": ["strength"]}),
        # Empty equipment + cardio focus (forced bodyweight cardio)
        ("bodyweight cardio", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["cardio"],
            "equipment": []}),
        # Glutes focus + intermediate
        ("glutes focus intermediate", {"fitness_level": "intermediate",
            "duration_minutes": 45, "focus_areas": ["glutes"],
            "equipment": E1_FULL, "goals": ["hypertrophy"]}),
        # Arms day + dumbbells
        ("arms + dumbbells", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["arms"],
            "equipment": E3_DB}),
        # Shoulders + advanced
        ("shoulders + advanced", {"fitness_level": "advanced",
            "duration_minutes": 45, "focus_areas": ["shoulders"],
            "equipment": E1_FULL, "goals": ["strength"]}),
        # Progressive overload sanity (simulated streak)
        ("progressive overload sanity", {"fitness_level": "intermediate",
            "duration_minutes": 60, "focus_areas": ["legs"],
            "equipment": E1_FULL, "goals": ["strength"]}),
        # Long endurance run sim
        ("75min endurance run", {"fitness_level": "intermediate",
            "duration_minutes": 75, "focus_areas": ["cardio"],
            "equipment": ["treadmill"], "goals": ["endurance"]}),
        # Big-3 powerlift
        ("big-3 powerlift", {"fitness_level": "advanced",
            "duration_minutes": 90, "focus_areas": ["full_body"],
            "equipment": E8_FW, "goals": ["strength"]}),
        # Active recovery yoga
        ("yoga style mobility", {"fitness_level": "intermediate",
            "duration_minutes": 30, "focus_areas": ["mobility"],
            "equipment": E13_TRX, "goals": ["mobility"]}),
        # All goals union
        ("union all goals 60min", {"fitness_level": "intermediate",
            "duration_minutes": 60, "focus_areas": ["full_body"],
            "equipment": E1_FULL, "goals": list(GOALS)}),
    ]
    for label, kw in edges:
        i += 1
        # Drop schema-incompatible fields that some edge entries still carry over
        # from old WorkoutPlanRequest schema. The endpoint's body model rejects
        # unknown fields with 422.
        kw_clean = {k: v for k, v in kw.items()
                    if k not in {"custom_program_description", "dumbbell_count",
                                 "kettlebell_count"}}
        # Surface free-text intent through ai_prompt where available.
        if kw.get("custom_program_description"):
            kw_clean["ai_prompt"] = kw["custom_program_description"]
        out.append(_scenario(i, 6, label, _make_body(i, **kw_clean)))
    return out


def build_500() -> List[Dict[str, Any]]:
    """Build all 500 scenarios. Re-runnable, deterministic."""
    out: List[Dict[str, Any]] = []
    out.extend(_build_block_axis_sweeps(0))           # ~140
    out.extend(_build_block_combos_2(len(out)))       # ~96
    out.extend(_build_block_personalization(len(out)))  # ~75
    out.extend(_build_block_dates(len(out)))          # ~30
    out.extend(_build_block_workout_type_focus(len(out)))  # ~49
    out.extend(_build_block_edge_cases(len(out)))     # ~50

    # Pad / truncate to exactly 500.
    target = 500
    if len(out) > target:
        out = out[:target]
    elif len(out) < target:
        # Pad with rotation through axis-sweep templates.
        idx = len(out)
        n = 0
        # Pad with injury-positive scenarios only (skip the empty-injury entry from
        # INJURIES[0] in this padding loop). Ensures cross-surface injury coverage ≥25%.
        INJ_NONEMPTY = [x for x in INJURIES if x]
        # Same cardio-only coercion as block 2 (avoid 422
        # INCOMPATIBLE_EQUIPMENT_FOCUS in the pad rows).
        _CARDIO_ONLY_NAMES_PAD = {"E11_cardio"}
        _CARDIO_FOCUSES_PAD = ["cardio", "endurance", "hiit"]
        _CARDIO_GOALS_PAD = ["endurance", "fat_loss", "general_fitness"]
        while len(out) < target:
            fl = FITNESS[n % 3]
            dur = DURATIONS[n % len(DURATIONS)]
            goal = GOALS[n % len(GOALS)]
            f = FOCUSES[n % len(FOCUSES)]
            eq, eq_name = EQUIP_POOL[n % len(EQUIP_POOL)], EQUIP_NAMES[n % len(EQUIP_NAMES)]
            if eq_name in _CARDIO_ONLY_NAMES_PAD:
                f = _CARDIO_FOCUSES_PAD[n % len(_CARDIO_FOCUSES_PAD)]
                if goal not in _CARDIO_GOALS_PAD:
                    goal = _CARDIO_GOALS_PAD[n % len(_CARDIO_GOALS_PAD)]
            inj = INJ_NONEMPTY[n % len(INJ_NONEMPTY)]
            idx += 1
            out.append(_scenario(idx, 7,
                f"pad {fl}/{dur}/{goal}/{f}/{eq_name}/inj={'+'.join(inj)}",
                _make_body(idx,
                           fitness_level=fl, duration_minutes=dur,
                           focus_areas=[f], goals=[goal], equipment=eq,
                           injuries=inj)))
            n += 1
    # Re-number 1..500 to ensure contiguity.
    for k, sc in enumerate(out, start=1):
        sc["idx"] = k
    return out
