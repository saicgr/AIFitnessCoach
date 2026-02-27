"""
Workout versioning API endpoints (SCD2).

This module handles workout version management:
- POST /regenerate - Regenerate a workout with new settings
- POST /regenerate-stream - Regenerate with streaming progress
- GET /{workout_id}/versions - Get version history
- POST /revert - Revert to a previous version
"""
import json
import time
from datetime import datetime
from typing import List, Optional, AsyncGenerator

from fastapi import APIRouter, Depends, HTTPException, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from core.rate_limiter import limiter

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    Workout, RegenerateWorkoutRequest, RevertWorkoutRequest, WorkoutVersionInfo,
)
from services.gemini_service import GeminiService
from services.exercise_rag_service import get_exercise_rag_service

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    normalize_goals_list,
    get_all_equipment,
)

router = APIRouter()
logger = get_logger(__name__)

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


@router.post("/regenerate", response_model=Workout)
async def regenerate_workout(request: RegenerateWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Regenerate a workout with new settings while preserving version history (SCD2).

    This endpoint:
    1. Gets the existing workout
    2. Generates a new workout using AI based on provided settings
    3. Creates a new version, marking the old one as superseded
    4. Returns the new version

    The old workout is NOT deleted - it's kept for history/revert.
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

        # Calculate target duration from min/max range or fallback
        if request.duration_minutes_min and request.duration_minutes_max:
            target_duration = (request.duration_minutes_min + request.duration_minutes_max) // 2
        elif request.duration_minutes_min:
            target_duration = request.duration_minutes_min
        elif request.duration_minutes_max:
            target_duration = request.duration_minutes_max
        else:
            target_duration = request.duration_minutes or 45

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
            logger.error(f"AI workout regeneration failed: {ai_error}")
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

        # Use SCD2 supersede to create new version
        new_workout = db.supersede_workout(request.workout_id, new_workout_data)
        logger.info(f"Workout regenerated: old_id={request.workout_id}, new_id={new_workout['id']}, version={new_workout.get('version_number')}")

        log_workout_change(
            workout_id=new_workout["id"],
            user_id=request.user_id,
            change_type="regenerated",
            change_source="regenerate_endpoint",
            new_value={
                "name": workout_name,
                "exercises_count": len(exercises),
                "previous_workout_id": request.workout_id
            }
        )

        regenerated = row_to_workout(new_workout)
        await index_workout_to_rag(regenerated)

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

            db.record_workout_regeneration(
                user_id=request.user_id,
                original_workout_id=request.workout_id,
                new_workout_id=new_workout["id"],
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
            logger.info(f"Recorded regeneration analytics for workout {new_workout['id']}")

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
                    logger.warning(f"Failed to index custom inputs to ChromaDB: {chroma_error}")
        except Exception as analytics_error:
            # Don't fail the regeneration if analytics recording fails
            logger.warning(f"Failed to record regeneration analytics: {analytics_error}")

        return regenerated

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to regenerate workout: {e}")
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

            # Calculate target duration from min/max range or fallback
            if body.duration_minutes_min and body.duration_minutes_max:
                target_duration = (body.duration_minutes_min + body.duration_minutes_max) // 2
            elif body.duration_minutes_min:
                target_duration = body.duration_minutes_min
            elif body.duration_minutes_max:
                target_duration = body.duration_minutes_max
            else:
                target_duration = body.duration_minutes or 45

            exercise_count = max(3, min(10, target_duration // 7))

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

            # Step 4: Save to database
            yield send_progress(4, 4, "Saving workout...", "Finalizing your new workout")

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

            new_workout = db.supersede_workout(body.workout_id, new_workout_data)
            logger.info(f"[STREAM] Workout regenerated: old_id={body.workout_id}, new_id={new_workout['id']}")

            log_workout_change(
                workout_id=new_workout["id"],
                user_id=body.user_id,
                change_type="regenerated",
                change_source="regenerate_stream_endpoint",
                new_value={
                    "name": workout_name,
                    "exercises_count": len(exercises),
                    "previous_workout_id": body.workout_id
                }
            )

            regenerated = row_to_workout(new_workout)
            await index_workout_to_rag(regenerated)

            # Record analytics (fire-and-forget)
            try:
                db.record_workout_regeneration(
                    user_id=body.user_id,
                    original_workout_id=body.workout_id,
                    new_workout_id=new_workout["id"],
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
                logger.warning(f"[STREAM] Failed to record analytics: {analytics_error}")

            # Send the completed workout
            workout_response = {
                "id": str(regenerated.id),
                "user_id": str(regenerated.user_id),
                "name": regenerated.name,
                "type": regenerated.type,
                "difficulty": regenerated.difficulty,
                "duration_minutes": regenerated.duration_minutes,
                "scheduled_date": str(regenerated.scheduled_date) if regenerated.scheduled_date else None,
                "exercises_json": json.loads(regenerated.exercises_json) if isinstance(regenerated.exercises_json, str) else regenerated.exercises_json,
                "is_completed": regenerated.is_completed,
                "generation_method": regenerated.generation_method,
                "version_number": regenerated.version_number,
                "total_time_ms": elapsed_ms(),
            }
            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Regeneration error: {e}")
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
        logger.error(f"Failed to get workout versions: {e}")
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
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to revert workout: {e}")
        raise safe_internal_error(e, "versioning")
