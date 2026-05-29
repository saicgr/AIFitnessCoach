"""Shared workout-building engine — single source of truth.

Turns a `WorkoutBuildParams` constraint set into a structured workout
(warm-up + main + cool-down). Used by:
  - the chat quick-workout / adapt tool
  - POST /workouts/customize          (live preview + persist)
  - POST /workouts/{id}/adapt         (fork or in-place)
  - presets, shuffle, trim/extend, equipment bulk swap, active-recovery

INSTANT by design: RAG vector select + deterministic adaptive params +
deterministic warm-up/cool-down scaling. NO LLM call inside this module
(the LLM only lives in the chat agent, to turn free text into these params).

SAFETY: pain/injury avoidance (transient sore_areas merged with profile
injuries) is a HARD constraint, never relaxed. The free-text parser maps words
to body parts deterministically — it never classifies exercise safety with an
LLM (see feedback_no_llm_for_safety_classification).

OVER-CONSTRAINED: if RAG returns nothing, we broaden in priority order
(variety -> equipment-pref -> impact -> focus), NEVER relaxing pain/injury, and
record what was relaxed in `relaxed_constraints`. If still empty we pivot to an
active-recovery/mobility session rather than erroring (no 422, no empty screen).
"""

import logging
from typing import Any, Dict, List, Optional, Tuple

from models.workout_studio import WorkoutBuildParams, BuiltWorkout

logger = logging.getLogger(__name__)

# ── Mapping tables (shared with the legacy quick-workout tool) ────────────────

FOCUS_AREA_MAP = {
    "full_body": "full_body", "upper": "chest", "lower": "legs",
    "push": "chest", "pull": "back",
    "cardio": "full_body_power", "core": "core",
    "boxing": "boxing", "hyrox": "hyrox", "crossfit": "crossfit",
    "martial_arts": "martial_arts", "hiit": "hiit",
    "strength": "strength", "endurance": "endurance",
    "flexibility": "flexibility", "mobility": "mobility",
    "chest": "chest", "back": "back", "shoulders": "shoulders",
    "arms": "arms", "legs": "legs", "glutes": "legs",
}

INTENSITY_TO_FITNESS = {"light": "beginner", "moderate": "intermediate", "intense": "advanced"}
FITNESS_LEVEL_ORDER = {"beginner": 1, "intermediate": 2, "advanced": 3}
STYLE_TO_FOCUS = {
    "strength": "strength", "hypertrophy": "hypertrophy",
    "endurance": "endurance", "circuit": "endurance",
}

TYPE_NAMES = {
    "full_body": "Full Body", "upper": "Upper Body", "lower": "Lower Body",
    "push": "Push", "pull": "Pull", "cardio": "Cardio", "core": "Core",
    "boxing": "Boxing", "hyrox": "HYROX", "crossfit": "CrossFit", "hiit": "HIIT",
    "chest": "Chest", "back": "Back", "shoulders": "Shoulders",
    "arms": "Arms", "legs": "Legs", "glutes": "Glutes", "mobility": "Mobility",
}
INTENSITY_NAMES = {"light": "Easy", "moderate": "Power", "intense": "Intense"}

# Body-part -> muscle groups to avoid (deterministic; cited general PT guidance).
SORE_TO_MUSCLES = {
    "back": ["back", "lower_back", "spine", "erectors"],
    "lower_back": ["lower_back", "back", "erectors"],
    "neck": ["neck", "traps"],
    "shoulder": ["shoulders", "delts"], "shoulders": ["shoulders", "delts"],
    "knee": ["quads", "hamstrings", "legs"], "knees": ["quads", "hamstrings", "legs"],
    "hip": ["glutes", "hip_flexors"], "hips": ["glutes", "hip_flexors"],
    "wrist": ["forearms", "wrist"], "wrists": ["forearms", "wrist"],
    "elbow": ["biceps", "triceps", "forearms"],
    "ankle": ["calves", "legs"], "ankles": ["calves", "legs"],
    "chest": ["chest", "pecs"], "core": ["core", "abs"], "abs": ["core", "abs"],
    "glute": ["glutes"], "glutes": ["glutes"],
    "hamstring": ["hamstrings"], "hamstrings": ["hamstrings"],
    "quad": ["quads"], "quads": ["quads"],
}

# Exercises to drop when impact_level == "low" (joint-sparing).
HIGH_IMPACT_KEYWORDS = (
    "jump", "jumping", "hop", "plyo", "plyometric", "box jump", "burpee",
    "skater", "bound", "tuck", "broad jump", "high knee", "mountain climber",
    "jump rope", "jump squat", "jumping jack", "star jump", "depth jump",
)

# Deterministic warm-up / cool-down pools (no LLM, instant). name + seconds.
WARMUP_POOL = [
    ("Arm Circles", 40), ("Leg Swings", 40), ("Bodyweight Squats", 45),
    ("Hip Circles", 40), ("Cat-Cow", 45), ("Torso Twists", 40),
    ("Shoulder Rolls", 30), ("Marching in Place", 60), ("Inchworm Walkout", 45),
    ("World's Greatest Stretch", 60),
]
WARMUP_POOL_LOWER = [
    ("Leg Swings", 40), ("Bodyweight Squats", 45), ("Hip Circles", 40),
    ("Glute Bridges", 45), ("Walking Lunges", 60), ("Ankle Circles", 30),
]
WARMUP_POOL_UPPER = [
    ("Arm Circles", 40), ("Shoulder Rolls", 30), ("Band Pull-Aparts", 45),
    ("Scapular Push-Ups", 45), ("Wall Slides", 45), ("Cat-Cow", 45),
]
COOLDOWN_POOL = [
    ("Child's Pose", 45), ("Standing Hamstring Stretch", 40), ("Chest Stretch", 40),
    ("Quad Stretch", 40), ("Cat-Cow", 45), ("Seated Forward Fold", 45),
    ("Figure-Four Stretch", 40), ("Shoulder Stretch", 40), ("Deep Breathing", 60),
]


# ── User context ──────────────────────────────────────────────────────────────

def _resolve_user_context(user: Optional[dict]) -> Dict[str, Any]:
    """Equipment / fitness / goals / injuries / db counts from a user row.
    Mirrors workout_tools._get_user_equipment_info semantics."""
    if not user:
        return {
            "equipment": ["Bodyweight"], "fitness_level": "intermediate",
            "goals": ["General Fitness"], "injuries": [],
            "dumbbell_count": 2, "kettlebell_count": 1, "staples": [],
        }
    equipment = user.get("equipment") or []
    if isinstance(equipment, str):
        equipment = [equipment]
    fitness_level = (user.get("fitness_level") or "intermediate").lower()
    goals = user.get("goals") or ["General Fitness"]
    injuries_raw = user.get("active_injuries") or []
    injuries: List[str] = []
    if isinstance(injuries_raw, list):
        for inj in injuries_raw:
            if isinstance(inj, dict):
                bp = inj.get("body_part")
                if bp:
                    injuries.append(str(bp))
            elif inj:
                injuries.append(str(inj))
    return {
        "equipment": equipment or ["Bodyweight"],
        "fitness_level": fitness_level,
        "goals": goals,
        "injuries": injuries,
        "dumbbell_count": int(user.get("dumbbell_count") or 2),
        "kettlebell_count": int(user.get("kettlebell_count") or 1),
        "staples": user.get("staple_exercises") or [],
    }


def _sore_to_avoided(sore_areas: List[str], profile_injuries: List[str]) -> Tuple[Dict[str, List[str]], List[str]]:
    """Merge transient sore areas with persistent profile injuries (both avoided).
    Returns ({'avoid': [...], 'reduce': []}, injuries_body_parts)."""
    avoid_muscles: List[str] = []
    injuries: List[str] = list(profile_injuries)
    for raw in list(sore_areas) + list(profile_injuries):
        key = str(raw).strip().lower()
        if key in SORE_TO_MUSCLES:
            avoid_muscles.extend(SORE_TO_MUSCLES[key])
        elif key:
            avoid_muscles.append(key)
        if key and key not in [i.lower() for i in injuries]:
            injuries.append(raw)
    # dedup preserving order
    seen = set()
    avoid_unique = [m for m in avoid_muscles if not (m in seen or seen.add(m))]
    return ({"avoid": avoid_unique, "reduce": []}, injuries)


def _primary_focus_area(focus_areas: List[str], active_recovery: bool) -> str:
    if active_recovery:
        return "mobility"
    if not focus_areas:
        return "full_body"
    distinct = {f.lower() for f in focus_areas}
    if len(distinct) == 1:
        f = next(iter(distinct))
        return FOCUS_AREA_MAP.get(f, "full_body")
    return "full_body"


def _exercise_count(params: WorkoutBuildParams) -> int:
    if params.exercise_count:
        return max(1, min(params.exercise_count, 12))
    # main time = total - warmup - cooldown, ~ one exercise per 4 min of main work
    main_min = max(5, params.duration_minutes - params.warmup_minutes - params.cooldown_minutes)
    if main_min <= 8:
        return 3
    if main_min <= 14:
        return 4
    if main_min <= 20:
        return 5
    if main_min <= 30:
        return 6
    return 7


def _is_high_impact(name: str) -> bool:
    n = (name or "").lower()
    return any(k in n for k in HIGH_IMPACT_KEYWORDS)


def _scale_block(pool: List[Tuple[str, int]], minutes: int) -> List[Dict[str, Any]]:
    """Deterministically pick warm-up/cool-down moves to roughly fill `minutes`."""
    if minutes <= 0:
        return []
    target_seconds = minutes * 60
    out: List[Dict[str, Any]] = []
    acc = 0
    for name, secs in pool:
        if acc >= target_seconds and len(out) >= 2:
            break
        out.append({
            "name": name,
            "sets": 1,
            "reps": None,
            "duration_seconds": secs,
            "hold_seconds": secs,
            "is_timed": True,
            "rest_seconds": 0,
            "equipment": "Bodyweight",
        })
        acc += secs
    return out


def _build_warmup(focus_area: str, minutes: int) -> List[Dict[str, Any]]:
    if focus_area in ("legs", "lower"):
        pool = WARMUP_POOL_LOWER
    elif focus_area in ("chest", "back", "shoulders", "arms", "upper", "push", "pull"):
        pool = WARMUP_POOL_UPPER
    else:
        pool = WARMUP_POOL
    return _scale_block(pool, minutes)


def _build_cooldown(minutes: int) -> List[Dict[str, Any]]:
    return _scale_block(COOLDOWN_POOL, minutes)


# ── Free-text constraint parser (deterministic, NO LLM) ───────────────────────

def parse_constraints_text(text: str, base: Optional[WorkoutBuildParams] = None) -> WorkoutBuildParams:
    """Turn 'I have back pain, keep it short and low impact' into params.
    Keyword-based and deterministic. Body-part words become sore_areas (HARD
    avoidance). Used by the REST /adapt endpoint; the chat agent has its own
    LLM extraction that produces the same param shape."""
    p = (base.model_copy(deep=True) if base else WorkoutBuildParams())
    t = (text or "").lower()

    # body parts -> sore_areas (hard avoidance)
    for key in SORE_TO_MUSCLES:
        if key in t and key not in p.sore_areas:
            p.sore_areas.append(key)

    # intensity
    if any(w in t for w in ("easier", "lighter", "light", "gentle", "go easy", "less intense")):
        p.intensity = "light"
    if any(w in t for w in ("harder", "tougher", "more intense", "intense", "beast")):
        p.intensity = "intense"

    # duration
    import re
    m = re.search(r"(\d+)\s*(?:min|minute)", t)
    if m:
        p.duration_minutes = max(5, min(120, int(m.group(1))))
    elif any(w in t for w in ("shorter", "quick", "less time", "short on time", "keep it short", "short")):
        p.duration_minutes = max(5, p.duration_minutes - 10)
    elif any(w in t for w in ("longer", "more time", "extend")):
        p.duration_minutes = min(120, p.duration_minutes + 10)

    # equipment
    if any(w in t for w in ("no equipment", "bodyweight", "no gear", "nothing", "at home", "no weights")):
        p.equipment = ["Bodyweight"]
    if "no dumbbell" in t or "no dumbbells" in t:
        p.equipment = [e for e in (p.equipment or []) if "dumbbell" not in e.lower()] or ["Bodyweight"]
    if "no barbell" in t:
        p.equipment = [e for e in (p.equipment or []) if "barbell" not in e.lower()] or ["Bodyweight"]

    # impact / joints
    if any(w in t for w in ("low impact", "low-impact", "joint", "joints", "no jumping", "easy on")):
        p.impact_level = "low"

    # recovery
    if any(w in t for w in ("recovery", "active recovery", "mobility", "stretch", "rest day")):
        p.active_recovery = True
        p.intensity = "light"

    # focus — but never treat a body part the user said HURTS as the focus.
    # ("I have back pain" sets sore_areas=['back']; it must NOT become focus.)
    sore_now = {s.lower() for s in p.sore_areas}
    for fa in ("upper", "lower", "core", "legs", "chest", "back", "shoulders", "arms", "glutes", "push", "pull", "cardio"):
        if fa in t and fa not in sore_now:
            if "full_body" in p.focus_areas:
                p.focus_areas = [fa]
            elif fa not in p.focus_areas:
                p.focus_areas.append(fa)

    return p


# ── The engine ────────────────────────────────────────────────────────────────

async def build_adapted_workout(params: WorkoutBuildParams, user: Optional[dict], *, fast: bool = True) -> BuiltWorkout:
    """Build a structured workout from params. Async (RAG + adaptive are async).
    Never raises on over-constraint — broadens and records relaxations.

    fast=True (default) uses the no-LLM deterministic RAG selection so live
    preview / adaptation is instant (<1s). The user's requirement is that
    customization is RAG-instant, not slow LLM generation.
    """
    from services.exercise_rag_service import get_exercise_rag_service
    from services.adaptive_workout_service import get_adaptive_workout_service

    ctx = _resolve_user_context(user)
    relaxed: List[str] = []

    if params.active_recovery:
        params.intensity = "light"
        if not params.focus_areas or params.focus_areas == ["full_body"]:
            params.focus_areas = ["mobility"]

    focus_area = _primary_focus_area(params.focus_areas, params.active_recovery)
    avoided_muscles, injuries = _sore_to_avoided(params.sore_areas, ctx["injuries"])
    equipment = params.equipment if params.equipment else ctx["equipment"]
    count = _exercise_count(params)

    # intensity -> fitness ceiling (never above the user's real level)
    suggested = INTENSITY_TO_FITNESS.get(params.intensity, "intermediate")
    user_rank = FITNESS_LEVEL_ORDER.get(ctx["fitness_level"], 2)
    sugg_rank = FITNESS_LEVEL_ORDER.get(suggested, 2)
    rag_fitness = ctx["fitness_level"] if sugg_rank > user_rank else suggested

    workout_focus = STYLE_TO_FOCUS.get(params.training_style, "hypertrophy")
    staple_exercises = ctx["staples"] if params.prioritize_staples else None

    rag = get_exercise_rag_service()
    avoid_list = list(params.avoid_exercises) + list(params.exclude_current)

    async def _select(over_fetch: int, use_equipment, use_impact_focus):
        return await rag.select_exercises_for_workout(
            focus_area=focus_area if use_impact_focus else "full_body",
            equipment=use_equipment if use_equipment else ["Bodyweight"],
            fitness_level=rag_fitness,
            goals=ctx["goals"],
            count=count + over_fetch,
            avoid_exercises=avoid_list,
            injuries=injuries if injuries else None,
            dumbbell_count=ctx["dumbbell_count"],
            kettlebell_count=ctx["kettlebell_count"],
            staple_exercises=staple_exercises,
            avoided_muscles=avoided_muscles if avoided_muscles["avoid"] else None,
            consistency_mode="vary",
            workout_type_preference=workout_focus,
            fast=fast,
        )

    # Over-fetch a buffer so impact filtering can backfill.
    buffer = 4 if params.impact_level == "low" else 0
    rag_exercises: List[Dict[str, Any]] = []
    try:
        rag_exercises = await _select(buffer, equipment, True) or []
    except Exception as e:
        logger.error(f"[workout_builder] RAG select failed: {e}", exc_info=True)
        rag_exercises = []

    # Broaden ladder (NEVER relax injuries/pain): equipment-pref -> focus.
    if len(rag_exercises) < max(1, count // 2):
        relaxed.append("Broadened equipment to find enough exercises.")
        try:
            rag_exercises = await _select(buffer, ["Bodyweight"], True) or rag_exercises
        except Exception:
            pass
    if not rag_exercises:
        relaxed.append("Broadened focus to full body to find safe exercises.")
        try:
            rag_exercises = await _select(buffer, ["Bodyweight"], False) or []
        except Exception:
            pass

    # Final safety net: active-recovery mobility session rather than empty/error.
    if not rag_exercises:
        relaxed.append("Couldn't match your constraints, so this is a gentle mobility session.")
        cooldown = _build_cooldown(max(params.cooldown_minutes, 6))
        return BuiltWorkout(
            name="Active Recovery & Mobility",
            type="mobility", difficulty="light",
            duration_minutes=params.duration_minutes,
            target_muscles=["full body"],
            warmup=_build_warmup("full_body", max(params.warmup_minutes, 3)),
            exercises=_build_warmup("mobility", max(8, params.duration_minutes - 4)),
            cooldown=cooldown, relaxed_constraints=relaxed,
            notes="A restorative session to keep you moving safely.",
        )

    # Impact filter (low => drop high-impact). Applied AFTER the broaden ladder
    # so broadening can't re-introduce jumping/plyo moves. Soft vs pain: if it
    # would leave too few, keep some and note it (pain/injury is never relaxed).
    if params.impact_level == "low":
        filtered = [e for e in rag_exercises if not _is_high_impact(e.get("name", ""))]
        if len(filtered) < max(1, count // 2) and len(filtered) < len(rag_exercises):
            relaxed.append("Kept a couple of dynamic moves; not enough strictly low-impact options matched.")
        else:
            rag_exercises = filtered

    # Dedup by name (RAG backfill can repeat in thin candidate pools).
    _seen = set()
    deduped = []
    for e in rag_exercises:
        k = (e.get("name", "") or "").strip().lower()
        if k and k not in _seen:
            _seen.add(k)
            deduped.append(e)
    rag_exercises = deduped[:count]

    # adaptive params
    adaptive = get_adaptive_workout_service(supabase_client=None)
    try:
        adaptive_params = await adaptive.get_adaptive_parameters(
            user_id=(user or {}).get("id", ""),
            workout_type=workout_focus,
            user_goals=ctx["goals"],
        )
    except Exception:
        adaptive_params = {"sets": 3, "reps": 12, "rest_seconds": 60}

    main_exercises: List[Dict[str, Any]] = []
    target_muscles: List[str] = []
    for ex in rag_exercises:
        name = ex.get("name", "Exercise")
        ex_type = "compound" if any(
            c in name.lower() for c in ("squat", "deadlift", "bench", "press", "row", "pull-up", "push-up")
        ) else "isolation"
        rest = adaptive.get_varied_rest_time(ex_type, workout_focus)
        mg = ex.get("muscle_group") or ex.get("body_part") or focus_area
        if mg and mg not in target_muscles:
            target_muscles.append(mg)
        main_exercises.append({
            "name": name,
            "sets": ex.get("sets", adaptive_params.get("sets", 3)),
            "reps": ex.get("reps", adaptive_params.get("reps", 12)),
            "rest_seconds": rest,
            "duration_seconds": ex.get("duration_seconds"),
            "hold_seconds": ex.get("hold_seconds"),
            "is_timed": ex.get("is_timed", False),
            "is_unilateral": ex.get("is_unilateral", False),
            "muscle_group": mg,
            "equipment": ex.get("equipment", "Bodyweight"),
            "notes": ex.get("notes", "") or ex.get("instructions", ""),
            "gif_url": ex.get("gif_url", ""),
            "video_url": ex.get("video_url", ""),
            "image_url": ex.get("image_url", ""),
            "library_id": ex.get("library_id", "") or ex.get("id", ""),
            "set_targets": ex.get("set_targets"),
        })

    # supersets (honor explicit flag, else auto)
    use_supersets = params.supersets
    if use_supersets is None:
        use_supersets = adaptive.should_use_supersets(workout_focus, params.duration_minutes, len(main_exercises))
    if use_supersets:
        main_exercises = adaptive.create_superset_pairs(main_exercises)

    # AMRAP finisher (honor explicit flag, else auto)
    use_amrap = params.amrap
    if use_amrap is None:
        use_amrap = adaptive.should_include_amrap(workout_focus, rag_fitness)
    if use_amrap and not params.active_recovery:
        main_exercises.append(adaptive.create_amrap_finisher(main_exercises, workout_focus))

    # name
    primary_focus_key = (params.focus_areas[0].lower() if params.focus_areas else "full_body")
    type_name = TYPE_NAMES.get(primary_focus_key, primary_focus_key.replace("_", " ").title())
    if params.active_recovery:
        workout_name = "Active Recovery & Mobility"
    else:
        workout_name = f"{INTENSITY_NAMES.get(params.intensity, 'Power')} {type_name}"

    return BuiltWorkout(
        name=workout_name,
        type=primary_focus_key.replace("_", " "),
        difficulty=params.intensity,
        duration_minutes=params.duration_minutes,
        target_muscles=target_muscles,
        warmup=_build_warmup(focus_area, params.warmup_minutes),
        exercises=main_exercises,
        cooldown=_build_cooldown(params.cooldown_minutes),
        relaxed_constraints=relaxed,
        notes=None,
    )


# ── Persistence helper (shared by endpoints + chat tool) ─────────────────────

def persist_built_workout(
    db,
    user_id: str,
    built: BuiltWorkout,
    params: WorkoutBuildParams,
    existing_workout_id: Optional[str] = None,
    generation_source: str = "studio",
) -> Optional[str]:
    """Persist a BuiltWorkout to the `workouts` table.

    exercises_json carries the MAIN exercises only (so the existing detail
    screen renders unchanged). Warm-up / cool-down / studio params /
    relaxations live in generation_metadata for the new sectioned UI to read.
    """
    from datetime import datetime, timezone

    metadata = {
        "warmup": built.warmup,
        "cooldown": built.cooldown,
        "studio_params": params.model_dump(),
        "relaxed_constraints": built.relaxed_constraints,
    }
    if existing_workout_id:
        update = {
            "exercises_json": built.exercises,
            "name": built.name,
            "type": built.type,
            "difficulty": built.difficulty,
            "duration_minutes": min(built.duration_minutes, 120),
            "generation_method": "studio",
            "generation_metadata": metadata,
        }
        db.update_workout(existing_workout_id, update)
        return existing_workout_id

    today_utc = datetime.now(timezone.utc).date().isoformat()
    row = {
        "user_id": user_id,
        "name": built.name,
        "type": built.type,
        "difficulty": built.difficulty,
        "scheduled_date": today_utc,
        "exercises_json": built.exercises,
        "duration_minutes": min(built.duration_minutes, 120),
        "is_completed": False,
        "generation_method": "studio",
        "generation_source": generation_source,
        "generation_metadata": metadata,
    }
    created = db.create_workout(row)
    return created.get("id") if created else None
