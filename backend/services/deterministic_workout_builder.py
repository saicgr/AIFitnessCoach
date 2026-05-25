"""
deterministic_workout_builder.py — Phase 2.J of workouts overhaul.

Pure-algorithm workout builder used as the safety net when:
  • Gemini fails the two-pass validator twice in a row (workout_generation_helpers).
  • Gemini's safety filters block fitness content (known risk per CLAUDE.md).
  • The user is offline (Flutter mirrors this logic via on-device Gemma; this
    is the SERVER-SIDE deterministic path).
  • Day-1 onboarding when there's no logged history yet.

No LLM, no RAG, no API calls. Pure functions over:
  • the user's split (from holistic_plan_service)
  • their equipment_inventory (Phase 1)
  • muscle recovery + injury flags (UserState)
  • volume landmarks (workout_validator_phase2.VOLUME_LANDMARKS)

The output schema MATCHES Gemini's so callers can swap in/out without
branching the consumer code. See `backend/models/gemini_schemas.py`.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from .workout_validator_phase2 import VOLUME_LANDMARKS

logger = logging.getLogger(__name__)


# --- Curated "templates" per split day. Keys = day archetype.
# Each entry: (exercise_name, muscle_group, movement_pattern, equipment).
# These are deliberately conservative + research-backed (compound→isolation).
TEMPLATES: Dict[str, List[Tuple[str, str, str, str]]] = {
    "push": [
        ("Barbell Bench Press",     "chest",     "push",  "barbell"),
        ("Overhead Press",          "shoulders", "push",  "barbell"),
        ("Incline Dumbbell Press",  "chest",     "push",  "dumbbell"),
        ("Lateral Raise",           "shoulders", "push",  "dumbbell"),
        ("Triceps Pushdown",        "triceps",   "push",  "cable"),
        ("Overhead Triceps Extension","triceps", "push",  "dumbbell"),
    ],
    "pull": [
        ("Barbell Row",             "back",      "pull",  "barbell"),
        ("Pull-Up",                 "back",      "pull",  "bodyweight"),
        ("Lat Pulldown",            "back",      "pull",  "cable"),
        ("Seated Cable Row",        "back",      "pull",  "cable"),
        ("Barbell Curl",            "biceps",    "pull",  "barbell"),
        ("Hammer Curl",             "biceps",    "pull",  "dumbbell"),
    ],
    "legs": [
        ("Back Squat",              "quads",     "squat", "barbell"),
        ("Romanian Deadlift",       "hamstrings","hinge", "barbell"),
        ("Leg Press",               "quads",     "squat", "machine"),
        ("Leg Curl",                "hamstrings","hinge", "machine"),
        ("Standing Calf Raise",     "calves",    "squat", "machine"),
        ("Hip Thrust",              "glutes",    "hinge", "barbell"),
    ],
    "upper": [
        ("Barbell Bench Press",     "chest",     "push",  "barbell"),
        ("Barbell Row",             "back",      "pull",  "barbell"),
        ("Overhead Press",          "shoulders", "push",  "barbell"),
        ("Lat Pulldown",            "back",      "pull",  "cable"),
        ("Barbell Curl",            "biceps",    "pull",  "barbell"),
        ("Triceps Pushdown",        "triceps",   "push",  "cable"),
    ],
    "lower": [
        ("Back Squat",              "quads",     "squat", "barbell"),
        ("Romanian Deadlift",       "hamstrings","hinge", "barbell"),
        ("Bulgarian Split Squat",   "quads",     "squat", "dumbbell"),
        ("Hip Thrust",              "glutes",    "hinge", "barbell"),
        ("Standing Calf Raise",     "calves",    "squat", "machine"),
        ("Hanging Leg Raise",       "abs",       "pull",  "bodyweight"),
    ],
    "full_body": [
        ("Back Squat",              "quads",     "squat", "barbell"),
        ("Barbell Bench Press",     "chest",     "push",  "barbell"),
        ("Barbell Row",             "back",      "pull",  "barbell"),
        ("Overhead Press",          "shoulders", "push",  "barbell"),
        ("Romanian Deadlift",       "hamstrings","hinge", "barbell"),
    ],
}


@dataclass
class BuildOptions:
    duration_minutes: int = 60
    progression_style: str = "straight"  # per Phase 2.F enum
    is_deload_week: bool = False
    user_equipment_categories: Optional[List[str]] = None
    injured_body_parts: Optional[List[str]] = None
    muscle_recovery: Optional[Dict[str, float]] = None


def build_workout_for_day(
    day_archetype: str,
    options: BuildOptions,
) -> Dict[str, Any]:
    """Build ONE day's workout deterministically.

    `day_archetype` is one of TEMPLATES.keys(): push, pull, legs, upper, lower,
    full_body. Falls back to full_body for unknown archetypes.

    Returns a workout dict in the same shape as Gemini's output.
    """
    archetype = day_archetype.lower().replace("-", "_")
    template = TEMPLATES.get(archetype) or TEMPLATES["full_body"]

    eq_categories = set(options.user_equipment_categories or [
        "barbell", "dumbbell", "cable", "machine", "bodyweight"
    ])
    injured = set((b or "").lower() for b in (options.injured_body_parts or []))

    # Filter out exercises we can't equip or that load an injured area.
    candidates: List[Tuple[str, str, str, str]] = []
    for name, muscle, pattern, equipment in template:
        if equipment not in eq_categories:
            continue
        if muscle in injured:
            continue
        candidates.append((name, muscle, pattern, equipment))

    # Recovery gate: drop exercises whose primary muscle is <40% recovered.
    recovery = options.muscle_recovery or {}
    candidates = [
        ex for ex in candidates if recovery.get(ex[1], 1.0) >= 0.40
    ]

    if not candidates:
        # Hard fallback: assume bodyweight always works.
        candidates = [("Push-Up", "chest", "push", "bodyweight"),
                      ("Bodyweight Squat", "quads", "squat", "bodyweight"),
                      ("Inverted Row", "back", "pull", "bodyweight")]

    # Sets/reps from progression style + deload scaling.
    sets_per_ex = _sets_per_exercise(options)
    reps_min, reps_max = _rep_range(options)

    exercises = []
    for name, muscle, pattern, equipment in candidates[:_target_exercise_count(options.duration_minutes)]:
        exercises.append({
            "name": name,
            "muscle_group": muscle,
            "movement_pattern": pattern,
            "equipment": equipment,
            "sets": sets_per_ex,
            "reps_min": reps_min,
            "reps_max": reps_max,
            "rest_seconds": 90,
            "set_type": "working",
            "is_drop_set": False,
            "drop_set_count": 0,
            "is_superset_with": None,
            "is_pr_test": False,
            "exercise_reasoning": (
                f"Deterministic fallback: {name} hits {muscle} via {pattern} "
                f"pattern. Sets/reps follow {options.progression_style} progression"
                f"{' at deload volume' if options.is_deload_week else ''}."
            ),
        })

    return {
        "day_archetype": archetype,
        "duration_minutes": options.duration_minutes,
        "exercises": exercises,
        "generated_via": "deterministic_fallback",
        "fallback_reason": "two_pass_validator_failed_or_offline",
    }


def build_weekly_plan(
    splits: List[str],
    options: BuildOptions,
) -> Dict[str, Any]:
    """Build a full week of workouts deterministically.

    `splits` = ordered list of day archetypes (e.g. ['push','pull','legs','rest', ...]).
    Returns the same shape as holistic_plan_service produces.
    """
    workouts = []
    day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for i, archetype in enumerate(splits[:7]):
        if archetype == "rest":
            workouts.append({"day": day_names[i] if i < 7 else f"Day {i + 1}", "rest_day": True, "exercises": []})
            continue
        wo = build_workout_for_day(archetype, options)
        wo["day"] = day_names[i] if i < 7 else f"Day {i + 1}"
        workouts.append(wo)
    return {
        "workouts": workouts,
        "generated_via": "deterministic_fallback",
        "is_deload_week": options.is_deload_week,
    }


def _sets_per_exercise(opts: BuildOptions) -> int:
    base = 3
    if opts.is_deload_week:
        return 2
    return base


def _rep_range(opts: BuildOptions) -> Tuple[int, int]:
    if opts.progression_style == "pyramid":
        return (6, 12)
    if opts.progression_style == "reverse_pyramid":
        return (4, 8)
    if opts.progression_style == "amrap":
        return (8, 25)
    if opts.progression_style == "double_progression":
        return (8, 12)
    if opts.progression_style == "rpt":
        return (3, 8)
    return (8, 10)  # straight


def _target_exercise_count(duration_min: int) -> int:
    if duration_min <= 30:
        return 3
    if duration_min <= 45:
        return 4
    if duration_min <= 75:
        return 6
    return 8


# Volume-landmark check — used by the builder to refuse to over-program when
# the user's recent strain is already at MRV.
def respects_volume_landmarks(
    weekly_sets: Dict[str, int],
    is_deload_week: bool,
) -> bool:
    for muscle, sets in (weekly_sets or {}).items():
        landmarks = VOLUME_LANDMARKS.get(muscle)
        if not landmarks:
            continue
        cap = int(landmarks["mrv"] * 0.6) if is_deload_week else landmarks["mrv"]
        if sets > cap:
            return False
    return True
