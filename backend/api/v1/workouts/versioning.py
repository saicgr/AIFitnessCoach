"""
Workout versioning API endpoints (SCD2).

This module handles workout version management:
- POST /regenerate - Regenerate a workout with new settings
- POST /regenerate-stream - Regenerate with streaming progress
- GET /{workout_id}/versions - Get version history
- POST /revert - Revert to a previous version
"""
from core.db import get_supabase_db
import json
import time
import uuid
from datetime import datetime
from typing import List, Optional, AsyncGenerator

from fastapi import APIRouter, Depends, HTTPException, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from fastapi.responses import StreamingResponse, Response
from pydantic import BaseModel, Field

from core.rate_limiter import limiter

from core.logger import get_logger
from models.schemas import (
    Workout, RegenerateWorkoutRequest, RevertWorkoutRequest, WorkoutVersionInfo,
)
from services.gemini_service import GeminiService
from services.exercise_rag_service import get_exercise_rag_service
from services.regen_preview_cache import get_preview_cache
from services.workout_safety_validator import validate_and_repair, UserSafetyContext
from services.exercise_rag.safety_mode import build_plan as build_safety_mode_plan

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    normalize_goals_list,
    get_all_equipment,
    resolve_target_duration,
)

router = APIRouter()
logger = get_logger(__name__)

# ---------------------------------------------------------------------------
# Injury normalization helpers (reused from Phase 2I alias map)
# ---------------------------------------------------------------------------

# Maps user-facing injury labels to the canonical joint keys used by
# exercise_safety_index columns (e.g. shoulder_safe, lower_back_safe …).
# "back" is a common shorthand for "lower_back" — mapping it explicitly
# ensures UserSafetyContext.normalized_injuries() whitelists it correctly.
_INJURY_ALIAS: dict = {
    "back": "lower_back",
    "lower back": "lower_back",
    "low back": "lower_back",
}


def _normalize_injuries_for_safety(injuries: list) -> list:
    """
    Translate raw user-facing injury strings to canonical safety-index joint
    keys before passing them to UserSafetyContext.

    Applies the same alias map Phase 2I uses so both the Gemini prompt and the
    safety validator see the same normalized vocabulary. Unknown strings are
    passed through (UserSafetyContext.normalized_injuries() will whitelist-
    filter them against SUPPORTED_INJURY_JOINTS, dropping anything unrecognised).
    """
    import re as _re
    out = []
    for inj in (injuries or []):
        key = _re.sub(r"[\s\-]+", "_", (inj or "").strip().lower())
        canonical = _INJURY_ALIAS.get(key) or _INJURY_ALIAS.get(inj.strip().lower()) or key
        out.append(canonical)
    # Deduplicate while preserving order.
    seen: set = set()
    deduped = []
    for k in out:
        if k not in seen:
            seen.add(k)
            deduped.append(k)
    return deduped


# ---------------------------------------------------------------------------
# Difficulty scaling helpers
# ---------------------------------------------------------------------------

DIFFICULTY_PRESETS = {
    "easy":   {"sets": (2, 3), "reps": (12, 15), "rest": (90, 120), "rpe": (5, 6)},
    "hard":   {"sets": (3, 4), "reps": (6, 10),  "rest": (45, 75),  "rpe": (8, 9)},
    "hell":   {"sets": (4, 5), "reps": (6, 8),   "rest": (30, 45),  "rpe": (9, 10),
               "include_failure": True, "include_drop_sets": True},
}

_COMPOUND_GROUPS = {
    "chest", "back", "quadriceps", "quads", "glutes", "hamstrings",
    "shoulders", "full body", "full_body", "legs", "upper body", "lower body",
}


def _is_compound_exercise(exercise: dict) -> bool:
    """Return True if the exercise targets a multi-joint muscle group."""
    for field in ("body_part", "target_muscle", "muscle_group", "target_muscles"):
        value = exercise.get(field, "")
        if isinstance(value, list):
            for v in value:
                if str(v).lower().strip() in _COMPOUND_GROUPS:
                    return True
        elif isinstance(value, str) and value.lower().strip() in _COMPOUND_GROUPS:
            return True
    return False


def _rebuild_set_targets(
    num_sets: int,
    reps: int,
    weight_kg: float,
    rpe: int,
    is_hell: bool,
    is_compound: bool,
) -> list:
    """Build a per-set targets array with warmup, working, and optional failure/drop sets."""
    targets = []
    set_number = 1
    rir = max(0, 10 - rpe)

    # Warmup set
    targets.append({
        "set_number": set_number,
        "set_type": "warmup",
        "target_reps": reps + 4,
        "target_weight_kg": round(weight_kg * 0.5, 1) if weight_kg else None,
        "target_rpe": 5,
        "target_rir": 5,
    })
    set_number += 1

    # Working sets
    working_count = num_sets - 1  # subtract warmup
    if is_hell:
        working_count = max(1, working_count - (2 if not is_compound else 1))  # room for failure/drop

    for _ in range(working_count):
        targets.append({
            "set_number": set_number,
            "set_type": "working",
            "target_reps": reps,
            "target_weight_kg": round(weight_kg, 1) if weight_kg else None,
            "target_rpe": rpe,
            "target_rir": rir,
        })
        set_number += 1

    # Hell mode: failure set on last working set
    if is_hell:
        targets.append({
            "set_number": set_number,
            "set_type": "failure",
            "target_reps": reps,
            "target_weight_kg": round(weight_kg, 1) if weight_kg else None,
            "target_rpe": 10,
            "target_rir": 0,
            "is_failure_set": True,
        })
        set_number += 1

        # Hell mode isolation: drop set
        if not is_compound:
            targets.append({
                "set_number": set_number,
                "set_type": "drop",
                "target_reps": reps + 4,
                "target_weight_kg": round(weight_kg * 0.6, 1) if weight_kg else None,
                "target_rpe": 9,
                "target_rir": 1,
                "is_drop_set": True,
            })
            set_number += 1

    return targets


def _apply_difficulty_scaling(exercises: list, difficulty: str) -> list:
    """Scale exercise parameters (sets, reps, rest, RPE) based on difficulty preset."""
    preset_key = difficulty.lower().strip()
    if preset_key not in DIFFICULTY_PRESETS:
        return exercises

    config = DIFFICULTY_PRESETS[preset_key]
    sets_range = config["sets"]
    reps_range = config["reps"]
    rest_range = config["rest"]
    rpe_range = config["rpe"]
    is_hell = config.get("include_failure", False)

    scaled = []
    for ex in exercises:
        ex = dict(ex)  # shallow copy
        compound = _is_compound_exercise(ex)

        # Compounds: max sets, lower reps, higher rest
        # Isolation: min sets, higher reps, lower rest
        num_sets = sets_range[1] if compound else sets_range[0]
        reps = reps_range[0] if compound else reps_range[1]
        rest = rest_range[1] if compound else rest_range[0]
        rpe = rpe_range[1] if compound else rpe_range[0]

        ex["sets"] = num_sets
        ex["reps"] = reps
        ex["rest_seconds"] = rest
        ex["rpe"] = rpe

        # Get baseline weight for set_targets
        weight_kg = 0
        if ex.get("weight_kg"):
            weight_kg = float(ex["weight_kg"])
        elif ex.get("set_targets") and isinstance(ex["set_targets"], list):
            for st in ex["set_targets"]:
                if isinstance(st, dict) and st.get("target_weight_kg"):
                    weight_kg = float(st["target_weight_kg"])
                    break

        ex["set_targets"] = _rebuild_set_targets(
            num_sets=num_sets,
            reps=reps,
            weight_kg=weight_kg,
            rpe=rpe,
            is_hell=is_hell,
            is_compound=compound,
        )

        scaled.append(ex)

    logger.info(f"🔥 Applied {preset_key} difficulty scaling to {len(scaled)} exercises")
    return scaled


def _serialize_preview_workout(payload: dict) -> dict:
    """Shape a preview payload for client consumption.

    Strips internal-only keys (``_commit_data``) and coerces ``exercises_json``
    to a decoded list so the client doesn't have to double-parse it. Mirrors
    the fields a committed Workout row would expose.
    """
    exercises = payload.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (ValueError, json.JSONDecodeError):
            exercises = []

    equipment = payload.get("equipment")
    if isinstance(equipment, str):
        try:
            equipment = json.loads(equipment)
        except (ValueError, json.JSONDecodeError):
            equipment = []

    generation_metadata = payload.get("generation_metadata")
    if isinstance(generation_metadata, str):
        try:
            generation_metadata = json.loads(generation_metadata)
        except (ValueError, json.JSONDecodeError):
            generation_metadata = None

    return {
        "id": payload.get("id"),
        "preview_id": payload.get("preview_id"),
        "user_id": payload.get("user_id"),
        "name": payload.get("name"),
        "type": payload.get("type"),
        "difficulty": payload.get("difficulty"),
        "scheduled_date": payload.get("scheduled_date"),
        "exercises_json": exercises,
        "duration_minutes": payload.get("duration_minutes"),
        "equipment": equipment,
        "is_completed": payload.get("is_completed", False),
        "generation_method": payload.get("generation_method"),
        "generation_source": payload.get("generation_source"),
        "generation_metadata": generation_metadata,
        # Explicitly flag preview-ness so the client can decorate the review
        # sheet and never accidentally persist the id as a real workout id.
        "is_preview": True,
        # Safety fields — Phase 3L. Propagated so the disclaimer banner widget
        # (Phase 1E) can render unconditionally whenever safety_mode=True.
        "safety_mode": payload.get("safety_mode", False),
        "safety_audit": payload.get("safety_audit", []),
    }


@router.post("/regenerate")
async def regenerate_workout(request: RegenerateWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Regenerate a workout and return a PREVIEW payload (no DB mutation).

    Behaviour (Phase 1C — preview/commit refactor):
      1. Gets the existing workout + user profile.
      2. Generates a new workout via RAG + Gemini.
      3. Stores the payload in the in-process preview cache under a fresh
         ``preview_id`` (UUID). The original workout remains ``is_current=True``.
      4. Returns ``{preview_id, workout}`` — the caller must hit
         ``/regenerate-commit`` with that ``preview_id`` to actually supersede.

    This endpoint never writes to ``workouts`` — prior versions called
    ``db.supersede_workout`` which destroyed the user's scheduled workout at
    generate-time even if they never tapped Approve. The commit endpoint is
    now responsible for the write.
    """
    logger.info(f"Regenerating workout {request.workout_id} for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Get existing workout
        existing = db.get_workout(request.workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get user data for generation
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Determine generation parameters
        # Use user-selected settings if provided, otherwise fall back to user profile
        fitness_level = request.fitness_level or user.get("fitness_level") or "intermediate"
        # IMPORTANT: Use explicit None check so empty list [] is respected
        equipment = request.equipment if request.equipment is not None else parse_json_field(user.get("equipment"), [])
        # Merge custom equipment from user profile (e.g., "TRX Bands", "Yoga Wheel")
        if user and isinstance(equipment, list):
            for item in get_all_equipment(user):
                if item and item not in equipment:
                    equipment.append(item)
        goals = normalize_goals_list(user.get("goals"))
        preferences = parse_json_field(user.get("preferences"), {})
        # Get equipment counts - use request if provided, otherwise fall back to user preferences
        dumbbell_count = request.dumbbell_count if request.dumbbell_count is not None else preferences.get("dumbbell_count", 2)
        kettlebell_count = request.kettlebell_count if request.kettlebell_count is not None else preferences.get("kettlebell_count", 1)

        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        # Get user-selected difficulty (easy/medium/hard) - will override AI-generated difficulty
        user_difficulty = request.difficulty

        # Get injuries from request (user-selected) or fall back to user profile
        injuries = request.injuries or []
        if not injuries:
            # Check user's active injuries from profile
            user_injuries = parse_json_field(user.get("active_injuries"), [])
            if user_injuries:
                injuries = user_injuries

        if injuries:
            logger.info(f"Regenerating workout avoiding exercises for injuries: {injuries}")

        # Get workout type from request
        workout_type_override = request.workout_type
        if workout_type_override:
            logger.info(f"Regenerating with workout type override: {workout_type_override}")

        # Determine focus area from existing workout or request
        focus_areas = request.focus_areas or []

        logger.info(f"Regenerating workout with: fitness_level={fitness_level}")
        logger.info(f"  - equipment={equipment} (from request: {request.equipment})")
        logger.info(f"  - dumbbell_count={dumbbell_count} (from request: {request.dumbbell_count})")
        logger.info(f"  - kettlebell_count={kettlebell_count} (from request: {request.kettlebell_count})")
        logger.info(f"  - difficulty={user_difficulty}")
        logger.info(f"  - workout_type={workout_type_override}")
        logger.info(f"  - duration_minutes={request.duration_minutes} (min={request.duration_minutes_min}, max={request.duration_minutes_max})")
        logger.info(f"  - ai_prompt={request.ai_prompt}")
        logger.info(f"  - injuries={injuries}")
        logger.info(f"  - focus_areas={focus_areas}")

        gemini_service = GeminiService()
        exercise_rag = get_exercise_rag_service()
        if not focus_areas:
            # Try to determine focus from existing workout's target muscles
            existing_exercises = parse_json_field(existing.get("exercises_json") or existing.get("exercises"), [])
            if existing_exercises:
                target_muscles = set()
                for ex in existing_exercises:
                    if isinstance(ex, dict) and ex.get("target_muscles"):
                        muscles = ex.get("target_muscles")
                        if isinstance(muscles, list):
                            target_muscles.update(muscles)
                        elif isinstance(muscles, str):
                            target_muscles.add(muscles)
                if target_muscles:
                    focus_areas = list(target_muscles)[:2]  # Use up to 2 main muscles

        focus_area = focus_areas[0] if focus_areas else "full_body"

        # Calculate target duration from min/max range or fallback. When the
        # request body has nothing, fall back to gym profile / user prefs via
        # resolve_target_duration so user's saved workout_duration is honored.
        if request.duration_minutes_min and request.duration_minutes_max:
            target_duration = (request.duration_minutes_min + request.duration_minutes_max) // 2
        elif request.duration_minutes_min:
            target_duration = request.duration_minutes_min
        elif request.duration_minutes_max:
            target_duration = request.duration_minutes_max
        elif request.duration_minutes:
            target_duration = request.duration_minutes
        else:
            _resolved = resolve_target_duration(
                body_duration=None, body_duration_min=None, body_duration_max=None,
                gym_profile=None, user=user,
            )
            target_duration = _resolved["target"]

        # Rule: ~7 minutes per exercise (including rest) for a balanced workout
        exercise_count = max(3, min(10, target_duration // 7))  # 3-10 exercises
        logger.info(f"Target duration: {target_duration} mins -> {exercise_count} exercises")

        try:
            # Use RAG to intelligently select exercises from ChromaDB/Supabase
            rag_exercises = await exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=equipment if isinstance(equipment, list) else [],
                fitness_level=fitness_level,
                goals=goals if isinstance(goals, list) else [],
                count=exercise_count,  # Dynamic count based on duration
                avoid_exercises=[],  # Don't avoid any since we're regenerating
                injuries=injuries if injuries else None,
                dumbbell_count=dumbbell_count,
                kettlebell_count=kettlebell_count,
            )

            if rag_exercises:
                # Use RAG-selected exercises with real videos
                logger.info(f"RAG selected {len(rag_exercises)} exercises for regeneration")
                workout_data = await gemini_service.generate_workout_from_library(
                    exercises=rag_exercises,
                    fitness_level=fitness_level,
                    goals=goals if isinstance(goals, list) else [],
                    duration_minutes=target_duration,
                    focus_areas=focus_areas if focus_areas else [focus_area],
                    age=user_age,
                    activity_level=user_activity_level,
                    intensity_preference=user_difficulty,
                    workout_type_preference=workout_type_override,
                    custom_program_description=request.ai_prompt if request.ai_prompt else None,
                    user_dob=user.get("date_of_birth") if user else None,
                    injuries=injuries if injuries else None,
                )
            else:
                # No fallback - RAG must return exercises
                logger.error("RAG returned no exercises for regeneration")
                raise ValueError(f"RAG returned no exercises for focus_area={focus_area}")

            # Ensure workout_data is a dict (guard against Gemini returning a string)
            if isinstance(workout_data, str):
                import json as _json
                try:
                    workout_data = _json.loads(workout_data)
                except (ValueError, _json.JSONDecodeError):
                    workout_data = {}
            if not isinstance(workout_data, dict):
                workout_data = {}

            exercises = workout_data.get("exercises", [])
            # Use provided workout_name if specified, otherwise use AI-generated name
            workout_name = request.workout_name or workout_data.get("name", "Regenerated Workout")
            # Use user-selected workout type if provided, otherwise use AI-generated or existing
            workout_type = workout_type_override or workout_data.get("type", existing.get("type", "strength"))
            # Use user-selected difficulty if provided, otherwise use AI-generated or default
            difficulty = user_difficulty or workout_data.get("difficulty", "medium")

            # Apply difficulty scaling to exercises (non-medium only)
            if user_difficulty and user_difficulty.lower() != "medium":
                exercises = _apply_difficulty_scaling(exercises, user_difficulty)

        except Exception as ai_error:
            logger.error(f"AI workout regeneration failed: {ai_error}", exc_info=True)
            raise safe_internal_error(ai_error, "versioning_ai_generation")

        # Track if RAG was used for metadata
        used_rag = rag_exercises is not None and len(rag_exercises) > 0

        # Prepare new workout data for the SCD2 supersede operation
        new_workout_data = {
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": existing.get("scheduled_date"),  # Keep same date
            "exercises_json": exercises,
            "duration_minutes": target_duration,
            "equipment": json.dumps(equipment) if equipment else "[]",  # Store user-selected equipment
            "is_completed": False,  # Reset completion on regenerate
            "generation_method": "rag_regenerate" if used_rag else "ai_regenerate",
            "generation_source": "regenerate_endpoint",
            "generation_metadata": json.dumps({
                "regenerated_from": request.workout_id,
                "previous_version": existing.get("version_number", 1),
                "fitness_level": fitness_level,
                "equipment": equipment,
                "difficulty": difficulty,
                "workout_type": workout_type,
                "workout_type_override": workout_type_override,
                "used_rag": used_rag,
                "focus_area": focus_area,
                "injuries_considered": injuries if injuries else [],
            }),
        }

        # ---------------------------------------------------------------
        # Phase 3L — Safety validation + repair (BEFORE preview cache).
        # Never return unvalidated exercises to the user.
        # ---------------------------------------------------------------
        normalized_injuries = _normalize_injuries_for_safety(injuries)
        safety_ctx = UserSafetyContext(
            injuries=normalized_injuries,
            difficulty=(user_difficulty or "intermediate").lower().strip(),
            equipment=equipment if isinstance(equipment, list) else [],
            user_id=str(request.user_id),
        )
        safety_mode_active = False
        safety_audit: list = []
        try:
            val_result = await validate_and_repair(exercises, safety_ctx)
            if val_result.safety_mode_triggered:
                logger.info(
                    "🛡️  [Regen] safety_mode triggered user=%s violations=%d — "
                    "replacing with PT-friendly plan",
                    request.user_id,
                    len(val_result.violations),
                )
                sm_plan = await build_safety_mode_plan(
                    safety_ctx,
                    duration_minutes=target_duration,
                    focus_areas=focus_areas if focus_areas else None,
                )
                # Replace generated content with the safety-mode plan.
                exercises = sm_plan.get("exercises", [])
                workout_name = sm_plan.get("name", workout_name)
                difficulty = sm_plan.get("difficulty", "beginner")
                safety_mode_active = True
                safety_audit = [
                    {"safety_mode": True, "notice": sm_plan.get("notice"),
                     "violations": len(val_result.violations)}
                ]
                # Sync new_workout_data with the safe plan.
                new_workout_data["exercises_json"] = exercises
                new_workout_data["name"] = workout_name
                new_workout_data["difficulty"] = difficulty
            else:
                exercises = val_result.final_exercises
                safety_audit = val_result.audit
                new_workout_data["exercises_json"] = exercises
                logger.info(
                    "✅ [Regen] safety validation passed user=%s swaps=%d latency=%.1fms",
                    request.user_id,
                    sum(1 for s in val_result.swaps if s.reason == "swapped"),
                    val_result.swap_latency_ms,
                )
        except Exception as safety_err:
            # Hard fallback: any unexpected validator error forces safety-mode.
            # We never return unvalidated exercises — better a gentle session
            # than a potentially dangerous one.
            logger.error(
                "❌ [Regen] validate_and_repair raised unexpectedly: %s — "
                "forcing safety-mode fallback",
                safety_err,
                exc_info=True,
            )
            try:
                sm_plan = await build_safety_mode_plan(
                    safety_ctx,
                    duration_minutes=target_duration,
                    focus_areas=focus_areas if focus_areas else None,
                )
                exercises = sm_plan.get("exercises", [])
                workout_name = sm_plan.get("name", workout_name)
                difficulty = sm_plan.get("difficulty", "beginner")
                safety_mode_active = True
                safety_audit = [{"safety_mode": True, "error_fallback": True}]
                new_workout_data["exercises_json"] = exercises
                new_workout_data["name"] = workout_name
                new_workout_data["difficulty"] = difficulty
            except Exception as sm_err:
                logger.error(
                    "❌ [Regen] safety-mode fallback also failed: %s", sm_err, exc_info=True
                )
                raise safe_internal_error(sm_err, "versioning_safety_mode")

        # PREVIEW MODE: Do NOT call db.supersede_workout here. The original
        # workout must remain is_current=True until the user approves via
        # /regenerate-commit. We stash the generated payload in an in-process
        # TTL cache and return a preview_id for the client to commit later.
        preview_cache = get_preview_cache()
        preview_id = str(uuid.uuid4())

        # Build a dict that mirrors the committed row shape so the client can
        # render the review sheet identically whether looking at a preview or
        # a real workout. This mirror must be kept in sync with
        # utils.row_to_workout expectations.
        preview_payload = {
            "id": preview_id,  # tentative id — replaced by real UUID on commit
            "preview_id": preview_id,
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": existing.get("scheduled_date"),
            "exercises_json": exercises,
            "duration_minutes": target_duration,
            "equipment": new_workout_data["equipment"],
            "is_completed": False,
            "generation_method": new_workout_data["generation_method"],
            "generation_source": new_workout_data["generation_source"],
            "generation_metadata": new_workout_data["generation_metadata"],
            # Safety audit field: safe for JSON serialisation.
            "safety_audit": safety_audit,
            # Propagated to the client so the disclaimer banner can render
            # whenever safety_mode is True (Phase 1E widget).
            "safety_mode": safety_mode_active,
            # The data the commit endpoint will hand to db.supersede_workout.
            # Kept separately so any subsequent preview-swap/add mutations can
            # keep this payload in lockstep with exercises_json.
            "_commit_data": new_workout_data,
        }

        await preview_cache.store(
            preview_id=preview_id,
            payload=preview_payload,
            user_id=request.user_id,
            original_workout_id=request.workout_id,
            metadata={
                "focus_area": focus_area,
                "injuries": injuries,
                "used_rag": used_rag,
            },
        )

        logger.info(
            f"🧪 Preview generated: preview_id={preview_id} original={request.workout_id} "
            f"exercises={len(exercises)}"
        )

        # Record regeneration analytics for tracking user customization patterns
        try:
            # Extract custom inputs (focus area/injury typed in "Other" field)
            custom_focus_area = None
            custom_injury = None

            # Check if focus_areas contains a custom entry (not from predefined list)
            predefined_focus_areas = [
                "full_body", "upper_body", "lower_body", "core", "back", "chest",
                "shoulders", "arms", "legs", "glutes", "cardio", "flexibility"
            ]
            if focus_areas:
                for fa in focus_areas:
                    if fa and fa.lower() not in [p.lower() for p in predefined_focus_areas]:
                        custom_focus_area = fa
                        break

            # Check if injuries contains a custom entry
            predefined_injuries = [
                "shoulder", "knee", "back", "wrist", "ankle", "hip", "neck", "elbow"
            ]
            if injuries:
                for inj in injuries:
                    if inj and inj.lower() not in [p.lower() for p in predefined_injuries]:
                        custom_injury = inj
                        break

            generation_end_time = time.time()
            generation_time_ms = None

            # In preview mode there is no committed new_workout yet; attribute
            # analytics to the preview_id. On commit we can optionally emit a
            # second record keyed by the real workout id. Current analytics
            # consumer treats new_workout_id as a correlation key, not an FK.
            db.record_workout_regeneration(
                user_id=request.user_id,
                original_workout_id=request.workout_id,
                new_workout_id=preview_id,
                difficulty=user_difficulty,
                duration_minutes=request.duration_minutes,
                workout_type=workout_type_override,
                equipment=equipment if isinstance(equipment, list) else [],
                focus_areas=focus_areas if focus_areas else [],
                injuries=injuries if injuries else [],
                custom_focus_area=custom_focus_area,
                custom_injury=custom_injury,
                generation_method="rag_regenerate" if used_rag else "ai_regenerate",
                used_rag=used_rag,
                generation_time_ms=generation_time_ms,
            )
            logger.info(f"Recorded regeneration analytics for preview {preview_id}")

            # Index custom inputs to ChromaDB for AI retrieval (fire-and-forget)
            if custom_focus_area or custom_injury:
                try:
                    from services.custom_inputs_rag_service import get_custom_inputs_rag_service
                    custom_rag = get_custom_inputs_rag_service()

                    if custom_focus_area:
                        await custom_rag.index_custom_input(
                            input_type="focus_area",
                            input_value=custom_focus_area,
                            user_id=request.user_id,
                        )
                        logger.info(f"Indexed custom focus area to ChromaDB: {custom_focus_area}")

                    if custom_injury:
                        await custom_rag.index_custom_input(
                            input_type="injury",
                            input_value=custom_injury,
                            user_id=request.user_id,
                        )
                        logger.info(f"Indexed custom injury to ChromaDB: {custom_injury}")
                except Exception as chroma_error:
                    logger.warning(f"Failed to index custom inputs to ChromaDB: {chroma_error}", exc_info=True)
        except Exception as analytics_error:
            # Don't fail the regeneration if analytics recording fails
            logger.warning(f"Failed to record regeneration analytics: {analytics_error}", exc_info=True)

        # Return a preview response. Frontend consumes preview_id + workout.
        # The workout dict mirrors the shape of a committed Workout row, with
        # the preview_id stapled in so the review sheet can pass it to
        # /regenerate-commit, /regenerate-discard, and the preview-aware
        # swap/add endpoints.
        return {"preview_id": preview_id, "workout": _serialize_preview_workout(preview_payload)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to regenerate workout: {e}", exc_info=True)
        raise safe_internal_error(e, "versioning")


@router.post("/regenerate-stream")
@limiter.limit("5/minute")
async def regenerate_workout_streaming(request: Request, body: RegenerateWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Regenerate a workout with streaming progress updates via SSE.

    This provides real-time feedback during workout regeneration:
    - Step 1: Loading user data
    - Step 2: Selecting exercises via RAG
    - Step 3: Generating workout with AI
    - Step 4: Saving to database

    Returns SSE events with progress updates and final workout.
    """
    logger.info(f"[STREAM] Regenerating workout {body.workout_id} for user {body.user_id}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(step: int, total: int, message: str, detail: str = None):
            data = {
                "type": "progress",
                "step": step,
                "total_steps": total,
                "message": message,
                "detail": detail,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            data = {"type": "error", "error": error, "elapsed_ms": elapsed_ms()}
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Load user and workout data
            yield send_progress(1, 4, "Loading your profile...", "Fetching workout settings")

            db = get_supabase_db()

            existing = db.get_workout(body.workout_id)
            if not existing:
                yield send_error("Workout not found")
                return

            user = db.get_user(body.user_id)
            if not user:
                yield send_error("User not found")
                return

            # Parse user data
            fitness_level = body.fitness_level or user.get("fitness_level") or "intermediate"
            equipment = body.equipment if body.equipment is not None else parse_json_field(user.get("equipment"), [])
            # Merge custom equipment from user profile (e.g., "TRX Bands", "Yoga Wheel")
            if user and isinstance(equipment, list):
                for item in get_all_equipment(user):
                    if item and item not in equipment:
                        equipment.append(item)
            goals = normalize_goals_list(user.get("goals"))
            preferences = parse_json_field(user.get("preferences"), {})
            dumbbell_count = body.dumbbell_count if body.dumbbell_count is not None else preferences.get("dumbbell_count", 2)
            kettlebell_count = body.kettlebell_count if body.kettlebell_count is not None else preferences.get("kettlebell_count", 1)
            user_age = user.get("age")
            user_activity_level = user.get("activity_level")
            user_difficulty = body.difficulty

            # Get injuries
            injuries = body.injuries or []
            if not injuries:
                user_injuries = parse_json_field(user.get("active_injuries"), [])
                if user_injuries:
                    injuries = user_injuries

            workout_type_override = body.workout_type
            focus_areas = body.focus_areas or []

            # Step 2: Select exercises using RAG
            yield send_progress(2, 4, "Selecting exercises...", "Finding the best exercises for you")

            gemini_service = GeminiService()
            exercise_rag = get_exercise_rag_service()

            if not focus_areas:
                existing_exercises = parse_json_field(existing.get("exercises_json") or existing.get("exercises"), [])
                if existing_exercises:
                    target_muscles = set()
                    for ex in existing_exercises:
                        if isinstance(ex, dict) and ex.get("target_muscles"):
                            muscles = ex.get("target_muscles")
                            if isinstance(muscles, list):
                                target_muscles.update(muscles)
                            elif isinstance(muscles, str):
                                target_muscles.add(muscles)
                    if target_muscles:
                        focus_areas = list(target_muscles)[:2]

            focus_area = focus_areas[0] if focus_areas else "full_body"

            # Calculate target duration from min/max range or fallback. Fall
            # back to user preferences (via resolve_target_duration) so saved
            # workout_duration is honored when the body omits it.
            if body.duration_minutes_min and body.duration_minutes_max:
                target_duration = (body.duration_minutes_min + body.duration_minutes_max) // 2
            elif body.duration_minutes_min:
                target_duration = body.duration_minutes_min
            elif body.duration_minutes_max:
                target_duration = body.duration_minutes_max
            elif body.duration_minutes:
                target_duration = body.duration_minutes
            else:
                _resolved = resolve_target_duration(
                    body_duration=None, body_duration_min=None, body_duration_max=None,
                    gym_profile=None, user=user,
                )
                target_duration = _resolved["target"]

            # Difficulty-aware exercise count: easy = fewer exercises with more rest,
            # hard/hell = more exercises packed tighter.
            diff_lower = (user_difficulty or "medium").lower()
            if diff_lower == "easy":
                exercise_count = max(3, min(5, target_duration // 10))
                target_duration = min(target_duration, 40)  # cap easy at 40 min
            elif diff_lower in ("hard", "hell"):
                exercise_count = max(4, min(10, target_duration // 6))
            else:
                exercise_count = max(3, min(8, target_duration // 7))

            # Further reduce if many injuries — fewer safe exercises available
            if injuries and len(injuries) >= 4:
                exercise_count = max(3, exercise_count - len(injuries) // 3)

            rag_exercises = await exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=equipment if isinstance(equipment, list) else [],
                fitness_level=fitness_level,
                goals=goals if isinstance(goals, list) else [],
                count=exercise_count,
                avoid_exercises=[],
                injuries=injuries if injuries else None,
                dumbbell_count=dumbbell_count,
                kettlebell_count=kettlebell_count,
            )

            if not rag_exercises:
                yield send_error(f"No exercises found for focus area: {focus_area}")
                return

            # Step 3: Generate workout with AI
            yield send_progress(3, 4, "Creating your workout...", f"Selected {len(rag_exercises)} exercises")

            workout_data = await gemini_service.generate_workout_from_library(
                exercises=rag_exercises,
                fitness_level=fitness_level,
                goals=goals if isinstance(goals, list) else [],
                duration_minutes=target_duration,
                focus_areas=focus_areas if focus_areas else [focus_area],
                age=user_age,
                activity_level=user_activity_level,
                intensity_preference=user_difficulty,
                workout_type_preference=workout_type_override,
                custom_program_description=body.ai_prompt if body.ai_prompt else None,
                user_dob=user.get("date_of_birth") if user else None,
                injuries=injuries if injuries else None,
            )

            # Ensure workout_data is a dict (guard against Gemini returning a string)
            if isinstance(workout_data, str):
                import json as _json
                try:
                    workout_data = _json.loads(workout_data)
                except (ValueError, _json.JSONDecodeError):
                    workout_data = {}
            if not isinstance(workout_data, dict):
                workout_data = {}

            exercises = workout_data.get("exercises", [])

            # Filter similar exercises to ensure movement pattern diversity
            # This prevents workouts like "6 push-up variations"
            from services.exercise_rag.filters import is_similar_exercise

            original_count = len(exercises)
            deduplicated = []
            seen_names = []

            for ex in exercises:
                ex_name = ex.get("name", "") or ex.get("exercise_name", "")
                is_dup = any(is_similar_exercise(ex_name, seen) for seen in seen_names)
                if not is_dup:
                    seen_names.append(ex_name)
                    deduplicated.append(ex)
                else:
                    logger.info(f"🔄 [Variety] Filtered similar exercise: {ex_name}")

            if len(deduplicated) < original_count:
                logger.warning(f"⚠️ [Validation] Removed {original_count - len(deduplicated)} similar exercises to ensure variety")
                exercises = deduplicated

            workout_name = body.workout_name or workout_data.get("name", "Regenerated Workout")
            workout_type = workout_type_override or workout_data.get("type", existing.get("type", "strength"))
            difficulty = user_difficulty or workout_data.get("difficulty", "medium")

            # Apply difficulty scaling to exercises (non-medium only)
            if user_difficulty and user_difficulty.lower() != "medium":
                exercises = _apply_difficulty_scaling(exercises, user_difficulty)

            # Step 4: Safety-validate and cache preview (NO DB write). The
            # user must explicitly approve via /regenerate-commit for the
            # original workout to be superseded.
            yield send_progress(4, 4, "Preparing preview...", "Finalizing your new workout")

            # ---------------------------------------------------------------
            # Phase 3L — Safety validation + repair (streaming path).
            # Emit safety_check before, safety_done after so the client can
            # show a brief "Checking safety…" indicator.
            # ---------------------------------------------------------------
            stream_normalized_injuries = _normalize_injuries_for_safety(injuries)
            stream_safety_ctx = UserSafetyContext(
                injuries=stream_normalized_injuries,
                difficulty=(user_difficulty or "intermediate").lower().strip(),
                equipment=equipment if isinstance(equipment, list) else [],
                user_id=str(body.user_id),
            )
            _sc_event = json.dumps({
                "type": "safety_check",
                "exercise_count": len(exercises),
                "elapsed_ms": elapsed_ms(),
            })
            yield f"event: safety_check\ndata: {_sc_event}\n\n"

            stream_safety_mode_active = False
            stream_safety_audit: list = []
            try:
                stream_val = await validate_and_repair(exercises, stream_safety_ctx)
                if stream_val.safety_mode_triggered:
                    logger.info(
                        "🛡️  [RegenStream] safety_mode triggered user=%s violations=%d",
                        body.user_id,
                        len(stream_val.violations),
                    )
                    sm_plan = await build_safety_mode_plan(
                        stream_safety_ctx,
                        duration_minutes=target_duration,
                        focus_areas=focus_areas if focus_areas else None,
                    )
                    exercises = sm_plan.get("exercises", [])
                    workout_name = sm_plan.get("name", workout_name)
                    difficulty = sm_plan.get("difficulty", "beginner")
                    stream_safety_mode_active = True
                    stream_safety_audit = [
                        {
                            "safety_mode": True,
                            "notice": sm_plan.get("notice"),
                            "violations": len(stream_val.violations),
                        }
                    ]
                else:
                    exercises = stream_val.final_exercises
                    stream_safety_audit = stream_val.audit
                    logger.info(
                        "✅ [RegenStream] safety validation passed user=%s swaps=%d latency=%.1fms",
                        body.user_id,
                        sum(1 for s in stream_val.swaps if s.reason == "swapped"),
                        stream_val.swap_latency_ms,
                    )
                _violations_count = (
                    stream_safety_audit[0].get("violations", 0)
                    if stream_safety_mode_active
                    else len(stream_val.violations)
                )
                _swaps_count = (
                    0
                    if stream_safety_mode_active
                    else sum(1 for s in stream_val.swaps if s.reason == "swapped")
                )
                _sd_event = json.dumps({
                    "type": "safety_done",
                    "violations": _violations_count,
                    "swaps": _swaps_count,
                    "safety_mode": stream_safety_mode_active,
                    "elapsed_ms": elapsed_ms(),
                })
                yield f"event: safety_done\ndata: {_sd_event}\n\n"
            except Exception as stream_safety_err:
                # Hard fallback — never return unvalidated exercises.
                logger.error(
                    "❌ [RegenStream] validate_and_repair raised unexpectedly: %s — "
                    "forcing safety-mode fallback",
                    stream_safety_err,
                    exc_info=True,
                )
                try:
                    sm_plan = await build_safety_mode_plan(
                        stream_safety_ctx,
                        duration_minutes=target_duration,
                        focus_areas=focus_areas if focus_areas else None,
                    )
                    exercises = sm_plan.get("exercises", [])
                    workout_name = sm_plan.get("name", workout_name)
                    difficulty = sm_plan.get("difficulty", "beginner")
                    stream_safety_mode_active = True
                    stream_safety_audit = [{"safety_mode": True, "error_fallback": True}]
                    _sd_err_event = json.dumps({
                        "type": "safety_done",
                        "violations": 0,
                        "swaps": 0,
                        "safety_mode": True,
                        "error_fallback": True,
                        "elapsed_ms": elapsed_ms(),
                    })
                    yield f"event: safety_done\ndata: {_sd_err_event}\n\n"
                except Exception as sm_err:
                    logger.error(
                        "❌ [RegenStream] safety-mode fallback also failed: %s", sm_err, exc_info=True
                    )
                    yield send_error("Safety validation failed. Please try again.")
                    return

            used_rag = rag_exercises is not None and len(rag_exercises) > 0

            new_workout_data = {
                "user_id": body.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "scheduled_date": existing.get("scheduled_date"),
                "exercises_json": exercises,
                "duration_minutes": target_duration,
                "equipment": json.dumps(equipment) if equipment else "[]",
                "is_completed": False,
                "generation_method": "rag_regenerate_stream" if used_rag else "ai_regenerate_stream",
                "generation_source": "regenerate_stream_endpoint",
                "generation_metadata": json.dumps({
                    "regenerated_from": body.workout_id,
                    "previous_version": existing.get("version_number", 1),
                    "fitness_level": fitness_level,
                    "equipment": equipment,
                    "difficulty": difficulty,
                    "workout_type": workout_type,
                    "workout_type_override": workout_type_override,
                    "used_rag": used_rag,
                    "focus_area": focus_area,
                    "injuries_considered": injuries if injuries else [],
                    "streaming": True,
                }),
            }

            preview_cache = get_preview_cache()
            preview_id = str(uuid.uuid4())

            # Keep new_workout_data.exercises_json in sync with validated exercises.
            new_workout_data["exercises_json"] = exercises
            new_workout_data["name"] = workout_name
            new_workout_data["difficulty"] = difficulty

            preview_payload = {
                "id": preview_id,
                "preview_id": preview_id,
                "user_id": body.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "scheduled_date": existing.get("scheduled_date"),
                "exercises_json": exercises,
                "duration_minutes": target_duration,
                "equipment": new_workout_data["equipment"],
                "is_completed": False,
                "generation_method": new_workout_data["generation_method"],
                "generation_source": new_workout_data["generation_source"],
                "generation_metadata": new_workout_data["generation_metadata"],
                # Safety fields — Phase 3L.
                "safety_audit": stream_safety_audit,
                "safety_mode": stream_safety_mode_active,
                "_commit_data": new_workout_data,
            }

            await preview_cache.store(
                preview_id=preview_id,
                payload=preview_payload,
                user_id=body.user_id,
                original_workout_id=body.workout_id,
                metadata={
                    "focus_area": focus_area,
                    "injuries": injuries,
                    "used_rag": used_rag,
                    "streaming": True,
                },
            )

            logger.info(
                f"[STREAM] 🧪 Preview generated: preview_id={preview_id} "
                f"original={body.workout_id} exercises={len(exercises)}"
            )

            # Record analytics (fire-and-forget). Attributed to preview_id —
            # the real workout id doesn't exist until /regenerate-commit.
            try:
                db.record_workout_regeneration(
                    user_id=body.user_id,
                    original_workout_id=body.workout_id,
                    new_workout_id=preview_id,
                    difficulty=user_difficulty,
                    duration_minutes=body.duration_minutes,
                    workout_type=workout_type_override,
                    equipment=equipment if isinstance(equipment, list) else [],
                    focus_areas=focus_areas if focus_areas else [],
                    injuries=injuries if injuries else [],
                    custom_focus_area=None,
                    custom_injury=None,
                    generation_method="rag_regenerate_stream" if used_rag else "ai_regenerate_stream",
                    used_rag=used_rag,
                    generation_time_ms=elapsed_ms(),
                )
            except Exception as analytics_error:
                logger.warning(f"[STREAM] Failed to record analytics: {analytics_error}", exc_info=True)

            # Emit the final `done` event with preview payload. The client
            # reads `preview_id` from here and passes it to commit/discard/
            # preview-swap endpoints.
            workout_response = {
                "preview_id": preview_id,
                "workout": _serialize_preview_workout(preview_payload),
                "total_time_ms": elapsed_ms(),
            }
            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Regeneration error: {e}", exc_info=True)
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


# ---------------------------------------------------------------------------
# Preview commit / discard
# ---------------------------------------------------------------------------
#
# These endpoints are the missing half of the preview-based regeneration flow.
# /regenerate and /regenerate-stream hand back a preview_id; the client calls
# /regenerate-commit on Approve (writes to DB) or /regenerate-discard on Back
# (drops the cached preview). Until one of the two is called, the original
# workout remains untouched.
# ---------------------------------------------------------------------------


class RegenerateCommitRequest(BaseModel):
    """Commit a cached preview as the new current version of a workout."""

    preview_id: str = Field(..., min_length=1, max_length=200)
    original_workout_id: str = Field(..., min_length=1, max_length=100)


class RegenerateDiscardRequest(BaseModel):
    """Discard a cached preview. Used when the user taps Back on the review
    sheet — tells the server to drop the preview now instead of waiting for
    TTL expiry. Pure client convenience; TTL alone is sufficient for safety.
    """

    preview_id: str = Field(..., min_length=1, max_length=200)


def _preview_error(code: str, status_code: int, message: str) -> HTTPException:
    """Build an HTTPException with a structured error body the client can
    pattern-match against (``error`` code + human ``message``)."""
    return HTTPException(
        status_code=status_code,
        detail={"error": code, "message": message},
    )


@router.post("/regenerate-commit")
@limiter.limit("10/minute")
async def regenerate_commit(
    request: Request,
    body: RegenerateCommitRequest,
    current_user: dict = Depends(get_current_user),
):
    """Commit a cached preview: supersede the original workout with the
    preview payload, delete the preview, and return the freshly-committed
    workout.

    Idempotency
    -----------
    If this endpoint is called twice for the same ``preview_id`` (e.g. the
    user double-taps Approve, or a flaky network retries the request), the
    second call must not double-supersede.  We implement idempotency in two
    layers:

      1. After a successful commit we delete the preview. A second request
         therefore sees ``PREVIEW_EXPIRED``. In that case we fall through to
         step 2 rather than erroring.
      2. We look up the ``original_workout_id`` — if it is no longer the
         current version AND its ``superseded_by`` points at a workout that
         already exists, we return that workout. The second call becomes a
         no-op that returns the same data the first call returned.

    Safety
    ------
    Before we supersede, we verify the original workout is still
    ``is_current=True``. If another device already superseded it (two regens
    racing), we surface ``ORIGINAL_ALREADY_SUPERSEDED`` (409).
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    preview_cache = get_preview_cache()
    entry, err = await preview_cache.get_owned(body.preview_id, user_id)

    db = get_supabase_db()

    # --- Layer 1: preview missing -> maybe idempotent replay ---------------
    if entry is None:
        if err == "PREVIEW_NOT_OWNED":
            raise _preview_error(
                "PREVIEW_NOT_OWNED",
                403,
                "This preview belongs to another user.",
            )

        # err == "PREVIEW_EXPIRED": check whether we already superseded.
        original = db.get_workout(body.original_workout_id)
        if not original:
            raise _preview_error(
                "PREVIEW_EXPIRED",
                404,
                "The preview has expired. Please regenerate and try again.",
            )

        superseded_by = original.get("superseded_by")
        # If the original is not current and points to a successor, treat this
        # as an idempotent replay and return the successor.
        if not original.get("is_current") and superseded_by:
            successor = db.get_workout(superseded_by)
            if successor:
                logger.info(
                    f"↩️ Commit replay detected: preview={body.preview_id} "
                    f"original={body.original_workout_id} -> existing successor={successor['id']}"
                )
                committed = row_to_workout(successor)
                return {
                    "workout": committed.model_dump(mode="json"),
                    "original_workout_id": body.original_workout_id,
                    "supersede_at": successor.get("valid_from"),
                    "idempotent_replay": True,
                }

        raise _preview_error(
            "PREVIEW_EXPIRED",
            404,
            "The preview has expired. Please regenerate and try again.",
        )

    # --- Layer 2: sanity-check the preview matches the request -------------
    if entry.original_workout_id != body.original_workout_id:
        # Body's original_workout_id must match what the preview was generated
        # against — prevents a client bug where a stale preview_id commits
        # against a different workout.
        raise _preview_error(
            "PREVIEW_MISMATCH",
            400,
            "Preview does not correspond to the supplied original_workout_id.",
        )

    # --- Layer 3: verify the original is still current --------------------
    original = db.get_workout(body.original_workout_id)
    if not original:
        raise _preview_error(
            "ORIGINAL_NOT_FOUND",
            404,
            "The original workout no longer exists.",
        )
    if not original.get("is_current"):
        logger.warning(
            f"⚠️ Commit blocked: original {body.original_workout_id} is already "
            f"superseded (superseded_by={original.get('superseded_by')})"
        )
        raise _preview_error(
            "ORIGINAL_ALREADY_SUPERSEDED",
            409,
            "This workout was already replaced on another device. Please refresh and try again.",
        )

    # --- Commit path -------------------------------------------------------
    commit_data = entry.payload.get("_commit_data") or {}
    if not commit_data:
        # Should never happen — the store path always writes _commit_data.
        logger.error(
            f"Preview {body.preview_id} has no _commit_data; cannot commit."
        )
        raise _preview_error(
            "PREVIEW_CORRUPT",
            500,
            "The cached preview is missing commit metadata. Please regenerate.",
        )

    try:
        # Sync exercises/name/type/difficulty from the (possibly-mutated)
        # preview payload back into commit_data — preview swap/add may have
        # mutated exercises_json after initial store.
        commit_data["exercises_json"] = entry.payload.get(
            "exercises_json", commit_data.get("exercises_json", [])
        )
        commit_data["name"] = entry.payload.get("name", commit_data.get("name"))
        commit_data["type"] = entry.payload.get("type", commit_data.get("type"))
        commit_data["difficulty"] = entry.payload.get(
            "difficulty", commit_data.get("difficulty")
        )
        commit_data["duration_minutes"] = entry.payload.get(
            "duration_minutes", commit_data.get("duration_minutes")
        )

        new_workout = db.supersede_workout(body.original_workout_id, commit_data)
    except ValueError as ve:
        # supersede_workout raises ValueError if old workout vanished mid-flight.
        logger.warning(f"Commit supersede ValueError: {ve}")
        raise _preview_error(
            "ORIGINAL_NOT_FOUND",
            404,
            "The original workout was removed. Please refresh.",
        )
    except Exception as e:
        logger.error(f"Commit supersede failed: {e}", exc_info=True)
        raise safe_internal_error(e, "versioning_commit")

    logger.info(
        f"✅ Commit: preview={body.preview_id} original={body.original_workout_id} "
        f"new_id={new_workout['id']} version={new_workout.get('version_number')}"
    )

    # Evict preview from cache — successive commits with same preview_id will
    # now hit the idempotent-replay branch above.
    await preview_cache.delete(body.preview_id)

    log_workout_change(
        workout_id=new_workout["id"],
        user_id=user_id,
        change_type="regenerated",
        change_source="regenerate_commit_endpoint",
        new_value={
            "preview_id": body.preview_id,
            "previous_workout_id": body.original_workout_id,
            "exercises_count": len(commit_data.get("exercises_json") or []),
        },
    )

    committed = row_to_workout(new_workout)
    try:
        await index_workout_to_rag(committed)
    except Exception as e:
        logger.warning(f"RAG re-index after commit failed (non-fatal): {e}", exc_info=True)

    return {
        "workout": committed.model_dump(mode="json"),
        "original_workout_id": body.original_workout_id,
        "supersede_at": new_workout.get("valid_from"),
        "idempotent_replay": False,
    }


@router.post("/regenerate-discard", status_code=204)
@limiter.limit("30/minute")
async def regenerate_discard(
    request: Request,
    body: RegenerateDiscardRequest,
    current_user: dict = Depends(get_current_user),
):
    """Discard a cached preview. Returns 204 on success.

    If the preview doesn't exist (already expired or already discarded) we
    still return 204 — discard is idempotent.

    If the preview exists but belongs to another user we return 403 without
    revealing the preview's owner.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    preview_cache = get_preview_cache()
    entry, err = await preview_cache.get_owned(body.preview_id, user_id)

    if entry is None and err == "PREVIEW_NOT_OWNED":
        raise _preview_error(
            "PREVIEW_NOT_OWNED",
            403,
            "This preview belongs to another user.",
        )

    # Whether it was expired, missing, or present-and-owned, delete is a
    # no-op-safe call.
    if entry is not None:
        await preview_cache.delete(body.preview_id)
        logger.info(f"🗑️ Discarded preview {body.preview_id} for user={user_id}")
    else:
        logger.info(
            f"🗑️ Discard no-op for preview {body.preview_id} (not present)"
        )

    return Response(status_code=204)


@router.get("/{workout_id}/versions", response_model=List[WorkoutVersionInfo])
async def get_workout_versions(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all versions of a workout (version history).

    Returns a list of version info objects ordered by version number (newest first).
    """
    logger.info(f"Getting versions for workout {workout_id}")

    try:
        db = get_supabase_db()
        versions = db.get_workout_versions(workout_id)

        if not versions:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Convert to version info objects
        version_infos = []
        for v in versions:
            exercises = v.get("exercises_json", [])
            if isinstance(exercises, str):
                try:
                    exercises = json.loads(exercises)
                except Exception as e:
                    logger.debug(f"Failed to parse exercises_json for workout version: {e}")
                    exercises = []

            version_infos.append(WorkoutVersionInfo(
                id=str(v.get("id")),
                version_number=v.get("version_number", 1),
                name=v.get("name", ""),
                is_current=v.get("is_current", False),
                valid_from=v.get("valid_from"),
                valid_to=v.get("valid_to"),
                generation_method=v.get("generation_method"),
                exercises_count=len(exercises) if isinstance(exercises, list) else 0
            ))

        return version_infos

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout versions: {e}", exc_info=True)
        raise safe_internal_error(e, "versioning")


@router.post("/revert", response_model=Workout)
async def revert_workout(request: RevertWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Revert a workout to a previous version.

    This creates a NEW version with the content of the target version,
    preserving the full history (SCD2 style).
    """
    logger.info(f"Reverting workout {request.workout_id} to version {request.target_version}")

    try:
        db = get_supabase_db()

        # Use the SCD2 revert method
        reverted = db.revert_workout(request.workout_id, request.target_version)

        logger.info(f"Workout reverted: workout_id={request.workout_id}, target_version={request.target_version}, new_id={reverted['id']}")

        log_workout_change(
            workout_id=reverted["id"],
            user_id=reverted.get("user_id"),
            change_type="reverted",
            change_source="revert_endpoint",
            new_value={
                "reverted_to_version": request.target_version,
                "original_workout_id": request.workout_id
            }
        )

        reverted_workout = row_to_workout(reverted)
        await index_workout_to_rag(reverted_workout)

        return reverted_workout

    except ValueError as e:
        raise HTTPException(status_code=404, detail="Version not found")
    except Exception as e:
        logger.error(f"Failed to revert workout: {e}", exc_info=True)
        raise safe_internal_error(e, "versioning")


class UnsupersedeRequest(BaseModel):
    workout_id: str


@router.post("/unsupersede")
async def unsupersede_workout(
    request: UnsupersedeRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Restore a superseded workout so it becomes current again.

    Used when user regenerates a workout but chooses "Add Workout" instead of
    "Replace" — both the old and new workout should appear for the same date.
    """
    logger.info(f"Un-superseding workout {request.workout_id}")

    try:
        db = get_supabase_db()

        db.client.table("workouts").update({
            "is_current": True,
            "valid_to": None,
            "superseded_by": None,
        }).eq("id", request.workout_id).execute()

        logger.info(f"Workout {request.workout_id} un-superseded successfully")
        return {"status": "ok", "workout_id": request.workout_id}

    except Exception as e:
        logger.error(f"Failed to un-supersede workout: {e}", exc_info=True)
        raise safe_internal_error(e, "versioning")
