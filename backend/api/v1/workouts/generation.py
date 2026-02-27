"""
Workout generation API endpoints.

This module handles AI-powered workout generation:
- POST /generate - Generate a single workout
- POST /generate-stream - Generate a single workout with streaming
- POST /generate-from-mood-stream - Generate quick workout based on mood
- POST /swap - Swap workout date
- POST /swap-exercise - Swap an exercise within a workout
- POST /add-exercise - Add an exercise to a workout
- POST /extend - Extend a workout with more exercises
"""
import hashlib
import json
import asyncio
import threading
import uuid
from datetime import datetime, timedelta
from typing import List, AsyncGenerator, Dict, Any, Optional

from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from fastapi.responses import StreamingResponse

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.config import get_settings
from models.schemas import (
    Workout, GenerateWorkoutRequest, SwapWorkoutsRequest, SwapExerciseRequest,
    AddExerciseRequest, ExtendWorkoutRequest,
)
from services.gemini_service import GeminiService, validate_set_targets_strict
from services.exercise_library_service import get_exercise_library_service
from services.exercise_rag_service import get_exercise_rag_service
from services.mood_workout_service import mood_workout_service, MoodType
from services.user_context_service import user_context_service
from services.warmup_stretch_service import get_warmup_stretch_service
from services.feedback_analysis_service import get_user_difficulty_adjustment
from core.rate_limiter import limiter, user_limiter

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    normalize_goals_list,
    get_all_equipment,
    get_recently_used_exercises,
    get_user_strength_history,
    get_user_favorite_exercises,
    get_user_consistency_mode,
    get_user_exercise_queue,
    mark_queued_exercises_used,
    get_user_staple_exercises,
    get_staple_names,
    get_user_variation_percentage,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    apply_1rm_weights_to_exercises,
    get_intensity_from_fitness_level,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    get_user_progression_pace,
    get_user_workout_type_preference,
    auto_substitute_filtered_exercises,
    # AI Consistency helpers
    get_user_readiness_score,
    get_user_latest_mood,
    get_active_injuries_with_muscles,
    get_muscles_to_avoid_from_injuries,
    adjust_workout_params_for_readiness,
    INJURY_TO_AVOIDED_MUSCLES,
    # Exercise parameter validation (safety net)
    validate_and_cap_exercise_parameters,
    get_user_comeback_status,
    # Comeback/Break detection helpers
    get_comeback_context,
    apply_comeback_adjustments_to_exercises,
    start_comeback_mode_if_needed,
    get_comeback_prompt_context,
    # Progression philosophy helpers
    get_user_rep_preferences,
    get_user_progression_context,
    build_progression_philosophy_prompt,
    # Historical workout patterns and set/rep limits
    get_user_workout_patterns,
    enforce_set_rep_limits,
    # Exercise muscle mapping helpers
    get_all_muscles_for_exercise,
    compare_muscle_profiles,
    # Hormonal health context helpers
    get_user_hormonal_context,
    adjust_workout_for_cycle_phase,
    get_kegel_exercises_for_workout,
    # Focus area validation
    validate_and_filter_focus_mismatches,
    # Performance context for personalized notes
    get_user_personal_bests,
    format_performance_context,
    # Favorite workouts context
    get_user_favorite_workouts,
    build_favorite_workouts_context,
)
from services.adaptive_workout_service import (
    apply_age_caps,
    get_senior_workout_prompt_additions,
    get_user_set_type_preferences,
    build_set_type_context,
)

router = APIRouter()
logger = get_logger(__name__)

# Semaphore to limit concurrent background generations (prevent overloading Gemini)
_background_gen_semaphore = asyncio.Semaphore(10)


async def generate_next_day_background(user_id: str, target_date: str):
    """Background task: generate workout for next day after workout completion.

    Called when a user's today workout is marked as completed, to pre-cache
    tomorrow's workout so it's instantly available.

    Uses a semaphore to limit concurrent background generations and prevent
    overloading the Gemini API.
    """
    async with _background_gen_semaphore:
        logger.info(f"[NEXT-DAY] Starting next-day pre-cache for user={user_id}, date={target_date}")

        try:
            db = get_supabase_db()

            # Check if workout already exists for target date
            existing = db.list_workouts(
                user_id=user_id,
                from_date=target_date,
                to_date=target_date,
                limit=1,
            )
            if existing:
                logger.info(f"[NEXT-DAY] Workout already exists for {user_id} on {target_date}, skipping")
                return

            # Check for in-flight generation
            try:
                generating_check = db.client.table("workouts").select("id").eq(
                    "user_id", user_id
                ).eq(
                    "scheduled_date", target_date
                ).eq(
                    "status", "generating"
                ).execute()
                if generating_check.data:
                    logger.info(f"[NEXT-DAY] Workout already being generated for {user_id} on {target_date}, skipping")
                    return
            except Exception as e:
                logger.warning(f"Dedup check for pre-cache failed: {e}")

            # Use the existing generate_workout function
            from models.schemas import GenerateWorkoutRequest

            # Try to get user's active gym profile
            gym_profile_id = None
            try:
                active_result = db.client.table("gym_profiles").select("id").eq(
                    "user_id", user_id
                ).eq(
                    "is_active", True
                ).single().execute()
                if active_result.data:
                    gym_profile_id = active_result.data.get("id")
            except Exception as e:
                logger.warning(f"Failed to get active gym profile: {e}")

            request = GenerateWorkoutRequest(
                user_id=user_id,
                scheduled_date=target_date,
                gym_profile_id=gym_profile_id,
            )

            result = await generate_workout(request, background_tasks=BackgroundTasks())
            logger.info(f"[NEXT-DAY] Successfully pre-cached workout for {user_id} on {target_date}: "
                        f"{result.name if result else 'unknown'}")

        except Exception as e:
            logger.error(f"[NEXT-DAY] Failed to pre-cache workout for {user_id} on {target_date}: {e}")


# =============================================================================
# Comeback Status Check (lightweight pre-generation check)
# =============================================================================

@router.get("/comeback-status")
async def check_comeback_status(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Lightweight endpoint to check if a user is in comeback mode.

    Called before workout generation to determine if the user should be
    prompted with a comeback mode consent sheet.

    Returns:
        - in_comeback_mode: bool
        - days_since_last_workout: int or None
        - reason: str
    """
    status = await get_user_comeback_status(user_id)
    return status


# Shared generation cache (see core/generation_cache.py)
from core.generation_cache import generation_cache_key, get_cached_generation, set_cached_generation


def ensure_parsed_dict(value) -> Dict[str, Any]:
    """
    Ensure a value is a dict, parsing it from JSON string if needed.

    Gemini sometimes returns JSON strings instead of objects, or nested values
    may be stringified. This handles all those cases robustly.

    Args:
        value: A dict, JSON string, or other value

    Returns:
        A dict (or empty dict if parsing fails)
    """
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
            if isinstance(parsed, dict):
                return parsed
        except (json.JSONDecodeError, ValueError) as e:
            logger.debug(f"Failed to parse dict from string: {e}")
    return {}


def ensure_exercises_are_dicts(exercises) -> List[Dict[str, Any]]:
    """
    Ensure all exercises and their set_targets are proper dicts.

    Gemini responses can sometimes contain stringified JSON at various nesting
    levels. This function normalizes the entire exercises list so that every
    exercise and every set_target entry is a dict, not a string.

    Args:
        exercises: A list of exercise dicts (or strings that should be dicts)

    Returns:
        List of properly-typed exercise dicts with dict set_targets
    """
    if not exercises:
        return []

    # If exercises itself is a string, try to parse it
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, ValueError):
            logger.error(f"Failed to parse exercises string: {exercises[:200]}")
            return []

    if not isinstance(exercises, list):
        return []

    normalized = []
    for ex in exercises:
        # Ensure each exercise is a dict
        if isinstance(ex, str):
            try:
                ex = json.loads(ex)
            except (json.JSONDecodeError, ValueError):
                logger.warning(f"Skipping unparseable exercise string: {ex[:100]}")
                continue
        if not isinstance(ex, dict):
            continue

        # Ensure set_targets entries are dicts, not strings
        if 'set_targets' in ex and ex['set_targets']:
            if isinstance(ex['set_targets'], str):
                try:
                    ex['set_targets'] = json.loads(ex['set_targets'])
                except (json.JSONDecodeError, ValueError):
                    ex['set_targets'] = []

            if isinstance(ex['set_targets'], list):
                parsed_targets = []
                for st in ex['set_targets']:
                    if isinstance(st, str):
                        try:
                            st = json.loads(st)
                        except (json.JSONDecodeError, ValueError):
                            continue
                    if isinstance(st, dict):
                        parsed_targets.append(st)
                ex['set_targets'] = parsed_targets

        normalized.append(ex)

    return normalized


def normalize_exercise_numeric_fields(exercises: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Convert float values to integers for exercise fields.

    Gemini often returns floats like 3.0, 12.0 instead of 3, 12 which causes
    type cast errors in Flutter when parsing JSON.
    """
    # First ensure all exercises and set_targets are proper dicts
    exercises = ensure_exercises_are_dicts(exercises)

    for exercise in exercises:
        # Core numeric fields
        for field in ['sets', 'reps', 'rest_seconds', 'duration_seconds', 'hold_seconds',
                      'superset_group', 'superset_order', 'drop_set_count', 'drop_set_percentage',
                      'difficulty_num']:
            if field in exercise and exercise[field] is not None:
                try:
                    exercise[field] = int(exercise[field])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to convert {field} to int: {e}")

        # Convert set_targets if present
        if 'set_targets' in exercise and exercise['set_targets']:
            for target in exercise['set_targets']:
                if not isinstance(target, dict):
                    continue
                for field in ['set_number', 'target_reps', 'target_rpe', 'target_rir']:
                    if field in target and target[field] is not None:
                        try:
                            target[field] = int(target[field])
                        except (ValueError, TypeError) as e:
                            logger.debug(f"Failed to convert target {field} to int: {e}")

    return exercises


@router.post("/generate", response_model=Workout)
async def generate_workout(request: GenerateWorkoutRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Resolve gym_profile_id early for dedup checks
        dedup_gym_profile_id = request.gym_profile_id
        if not dedup_gym_profile_id:
            try:
                active_result = db.client.table("gym_profiles").select("id").eq(
                    "user_id", request.user_id
                ).eq("is_active", True).single().execute()
                if active_result.data:
                    dedup_gym_profile_id = active_result.data.get("id")
            except Exception as e:
                logger.warning(f"Failed to get active gym profile: {e}")

        # Duplicate check: return existing workout if one already exists for this date+profile
        placeholder_id = None
        if request.scheduled_date:
            try:
                sched = request.scheduled_date
                end_of_day = sched + "T23:59:59.999999+00:00" if len(sched) == 10 else sched
                query = db.client.table("workouts").select("*").eq(
                    "user_id", request.user_id
                ).gte(
                    "scheduled_date", sched
                ).lte(
                    "scheduled_date", end_of_day
                ).neq("status", "cancelled")
                if dedup_gym_profile_id:
                    query = query.eq("gym_profile_id", dedup_gym_profile_id)
                existing = query.limit(1).execute()
                if existing.data:
                    logger.info(f"✅ [Dedup] Workout already exists for {request.user_id} on {request.scheduled_date} (profile={dedup_gym_profile_id}), returning existing")
                    return row_to_workout(existing.data[0])
            except Exception as dedup_err:
                logger.warning(f"Dedup check failed, proceeding with generation: {dedup_err}")

            # Premium gate check: enforce free-tier workout generation limits
            from core.premium_gate import check_premium_gate
            await check_premium_gate(request.user_id, "ai_workout_generation")

            # Insert placeholder with status='generating' to prevent concurrent generation
            # This lets the streaming endpoint detect generation is already in progress
            try:
                import uuid
                placeholder_id = str(uuid.uuid4())
                placeholder_data = {
                    "id": placeholder_id,
                    "user_id": request.user_id,
                    "scheduled_date": request.scheduled_date,
                    "status": "generating",
                    "name": "Generating...",
                    "exercises_json": [],
                }
                if dedup_gym_profile_id:
                    placeholder_data["gym_profile_id"] = dedup_gym_profile_id
                db.client.table("workouts").insert(placeholder_data).execute()
                logger.info(f"🔒 [Dedup] Inserted placeholder {placeholder_id} for {request.user_id} on {request.scheduled_date} (profile={dedup_gym_profile_id})")
            except Exception as ph_err:
                logger.warning(f"Placeholder insert failed: {ph_err}")
                placeholder_id = None

        equipment_details = []  # Initialize to empty, may be populated from user data
        gym_profile_id = None  # Track which profile this workout is generated for

        # Initialize new training customization fields
        primary_goal = None
        muscle_focus_points = None
        training_split = None

        # Initialize fitness assessment fields
        pushup_capacity = None
        pullup_capacity = None
        plank_capacity = None
        squat_capacity = None
        cardio_capacity = None

        if request.fitness_level and request.goals and request.equipment:
            fitness_level = request.fitness_level
            goals = request.goals
            equipment = request.equipment
            # Derive intensity from fitness level - beginners get 'easy', not 'medium'
            intensity_preference = get_intensity_from_fitness_level(fitness_level)
            workout_environment = None
        else:
            user = db.get_user(request.user_id)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            fitness_level = request.fitness_level or user.get("fitness_level")
            preferences = parse_json_field(user.get("preferences"), {})

            # Check for gym profile - load equipment/environment from profile if available
            gym_profile = None
            if request.gym_profile_id:
                # Specific profile requested
                profile_result = db.client.table("gym_profiles").select("*").eq("id", request.gym_profile_id).single().execute()
                gym_profile = profile_result.data if profile_result.data else None
                logger.info(f"🏋️ [GymProfile] Using requested profile: {request.gym_profile_id}")
            else:
                # Try to get active profile
                try:
                    active_result = db.client.table("gym_profiles").select("*").eq("user_id", request.user_id).eq("is_active", True).single().execute()
                    gym_profile = active_result.data if active_result.data else None
                    if gym_profile:
                        logger.info(f"🏋️ [GymProfile] Using active profile: {gym_profile.get('name')} ({gym_profile.get('id')})")
                except Exception as e:
                    # No active profile found - will use user defaults
                    logger.debug(f"No active gym profile found: {e}")

            if gym_profile:
                # Load settings from gym profile
                gym_profile_id = gym_profile.get("id")
                equipment = request.equipment or gym_profile.get("equipment") or []
                equipment_details = gym_profile.get("equipment_details") or []
                workout_environment = gym_profile.get("workout_environment") or preferences.get("workout_environment")
                training_split = gym_profile.get("training_split")
                profile_goals = normalize_goals_list(gym_profile.get("goals"))
                # Parse user goals if it's a JSON string
                user_goals = normalize_goals_list(user.get("goals"))
                goals = normalize_goals_list(request.goals) if request.goals else (profile_goals if profile_goals else user_goals)
                focus_areas = gym_profile.get("focus_areas") or []

                logger.info(f"🏋️ [GymProfile] Profile equipment: {len(equipment)} items")
                logger.info(f"📍 [GymProfile] Environment: {workout_environment}")
                if training_split:
                    logger.info(f"📅 [GymProfile] Training split: {training_split}")
            else:
                # Fall back to user settings (parse JSON strings)
                goals = normalize_goals_list(request.goals) if request.goals else normalize_goals_list(user.get("goals"))
                equipment = request.equipment or parse_json_field(user.get("equipment"), [])
                equipment_details = parse_json_field(user.get("equipment_details"), [])
                workout_environment = preferences.get("workout_environment")
                focus_areas = []  # No focus areas when no gym profile

            # Use explicit intensity_preference if set, otherwise derive from fitness level
            # This ensures beginners get 'easy' difficulty, not 'medium'
            intensity_preference = preferences.get("intensity_preference") or get_intensity_from_fitness_level(fitness_level)

            # Get primary training goal and muscle focus points for workout customization
            primary_goal = user.get("primary_goal")
            muscle_focus_points = user.get("muscle_focus_points")
            if muscle_focus_points:
                logger.info(f"🏋️ [Workout Generation] User has muscle focus points: {muscle_focus_points}")
            if primary_goal:
                logger.info(f"🎯 [Workout Generation] User has primary goal: {primary_goal}")

            # Get fitness assessment data for smarter workout personalization
            pushup_capacity = user.get("pushup_capacity")
            pullup_capacity = user.get("pullup_capacity")
            plank_capacity = user.get("plank_capacity")
            squat_capacity = user.get("squat_capacity")
            cardio_capacity = user.get("cardio_capacity")
            has_assessment = any([pushup_capacity, pullup_capacity, plank_capacity, squat_capacity, cardio_capacity])
            if has_assessment:
                logger.info(f"💪 [Workout Generation] User has fitness assessment: pushups={pushup_capacity}, pullups={pullup_capacity}, plank={plank_capacity}, squats={squat_capacity}, cardio={cardio_capacity}")

        # Fetch user's custom exercises
        logger.info(f"🏋️ [Workout Generation] Fetching custom exercises for user: {request.user_id}")
        custom_exercises = []
        try:
            custom_result = db.client.table("exercises").select(
                "name", "primary_muscle", "equipment", "default_sets", "default_reps"
            ).eq("is_custom", True).eq("created_by_user_id", request.user_id).execute()
            if custom_result.data:
                custom_exercises = custom_result.data
                exercise_names = [ex.get("name") for ex in custom_exercises]
                logger.info(f"✅ [Workout Generation] Found {len(custom_exercises)} custom exercises: {exercise_names}")
            else:
                logger.info(f"🏋️ [Workout Generation] No custom exercises found for user {request.user_id}")
        except Exception as e:
            logger.warning(f"⚠️ [Workout Generation] Failed to fetch custom exercises: {e}")

        # Fetch ALL user preferences in PARALLEL for faster generation
        # This reduces ~900ms-1.8s of sequential DB calls to ~100-300ms
        logger.info(f"🚀 [Workout Generation] Fetching all user preferences in parallel for: {request.user_id}")
        (
            avoided_exercises,
            avoided_muscles,
            staple_exercises,
            rep_preferences,
            progression_context,
            workout_patterns,
            hormonal_context,
            set_type_prefs,
            injuries,
            consistency_mode,
            recently_used_exercises,
            variation_percentage,
            favorite_exercises,
            exercise_queue,
            favorite_workouts,
        ) = await asyncio.gather(
            get_user_avoided_exercises(request.user_id),
            get_user_avoided_muscles(request.user_id),
            get_user_staple_exercises(request.user_id, gym_profile_id=gym_profile_id),
            get_user_rep_preferences(request.user_id),
            get_user_progression_context(request.user_id),
            get_user_workout_patterns(request.user_id),
            get_user_hormonal_context(request.user_id),
            get_user_set_type_preferences(request.user_id, supabase_client=db.client),
            get_active_injuries_with_muscles(request.user_id),
            get_user_consistency_mode(request.user_id),
            get_recently_used_exercises(request.user_id),
            get_user_variation_percentage(request.user_id),
            get_user_favorite_exercises(request.user_id),
            get_user_exercise_queue(request.user_id),
            get_user_favorite_workouts(request.user_id),
        )
        logger.info(f"✅ [Workout Generation] All user preferences fetched in parallel")
        logger.info(f"🔄 [Consistency] Mode: {consistency_mode}, Recently used: {len(recently_used_exercises) if recently_used_exercises else 0}, Variation: {variation_percentage}%")

        # Log what we found
        if avoided_exercises:
            logger.info(f"🚫 [Workout Generation] User has {len(avoided_exercises)} avoided exercises")
        if avoided_muscles.get("avoid") or avoided_muscles.get("reduce"):
            logger.info(f"🚫 [Workout Generation] User has avoided muscles: avoid={avoided_muscles.get('avoid')}, reduce={avoided_muscles.get('reduce')}")
        if staple_exercises:
            logger.info(f"⭐ [Workout Generation] User has {len(staple_exercises)} staple exercises")
        if favorite_exercises:
            logger.info(f"❤️ [Workout Generation] User has {len(favorite_exercises)} favorite exercises: {favorite_exercises[:5]}")
        if exercise_queue:
            logger.info(f"📋 [Workout Generation] User has {len(exercise_queue)} queued exercises")

        # Build progression philosophy prompt
        progression_philosophy = build_progression_philosophy_prompt(
            rep_preferences=rep_preferences,
            progression_context=progression_context,
        )
        if rep_preferences.get("training_focus") != "balanced":
            logger.info(f"[Workout Generation] User training focus: {rep_preferences.get('training_focus')}")
        if progression_context.get("mastered_exercises"):
            logger.info(f"[Workout Generation] User has {len(progression_context['mastered_exercises'])} mastered exercises")

        # Extract workout patterns data
        workout_patterns_context = workout_patterns.get("historical_context", "")
        set_rep_limits = workout_patterns.get("set_rep_limits", {})
        exercise_patterns = workout_patterns.get("exercise_patterns", {})

        if set_rep_limits.get("max_sets_per_exercise", 5) < 5:
            logger.info(f"[Workout Generation] User has set max_sets_per_exercise: {set_rep_limits.get('max_sets_per_exercise')}")
        if set_rep_limits.get("max_reps_per_set", 15) < 15:
            logger.info(f"[Workout Generation] User has set max_reps_per_set: {set_rep_limits.get('max_reps_per_set')}")
        if exercise_patterns:
            logger.info(f"[Workout Generation] Found {len(exercise_patterns)} exercise patterns from history")

        # Build favorite workouts context for generation
        favorite_workouts_context = build_favorite_workouts_context(favorite_workouts) if favorite_workouts else ""
        if favorite_workouts:
            logger.info(f"❤️ [Workout Generation] User has {len(favorite_workouts)} favorite workout templates")

        # Extract hormonal context
        hormonal_ai_context = hormonal_context.get("ai_context", "")
        if hormonal_context.get("cycle_phase"):
            logger.info(f"[Workout Generation] User is in {hormonal_context['cycle_phase']} phase (day {hormonal_context.get('cycle_day')})")
        if hormonal_context.get("kegels_enabled"):
            logger.info(f"[Workout Generation] User has kegels enabled - warmup: {hormonal_context.get('include_kegels_in_warmup')}, cooldown: {hormonal_context.get('include_kegels_in_cooldown')}")

        # Build set type context
        set_type_context = build_set_type_context(set_type_prefs)
        if set_type_prefs:
            advanced_types = [k for k in set_type_prefs.keys() if k not in ["working", "warmup"]]
            if advanced_types:
                logger.info(f"[Workout Generation] User has history with set types: {advanced_types}")

        gemini_service = GeminiService()
        exercise_rag = get_exercise_rag_service()

        try:
            # Combine progression philosophy with hormonal context for AI
            combined_context = progression_philosophy or ""
            if hormonal_ai_context:
                combined_context = f"{combined_context}\n\nHORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}" if combined_context else f"HORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}"

            # Equipment guard: filter out "All Profiles" staples whose equipment isn't available
            if equipment and staple_exercises:
                filtered = []
                equipment_lower = [e.lower() for e in equipment]
                for s in staple_exercises:
                    if s.get("gym_profile_id") is not None:
                        filtered.append(s)  # Profile-specific: always include
                    elif not s.get("equipment") or s["equipment"].lower() in equipment_lower:
                        filtered.append(s)  # All-profiles: include if equipment matches or bodyweight
                    else:
                        logger.info(f"Skipping all-profiles staple '{s['name']}' - requires '{s.get('equipment')}' not in profile equipment")
                staple_exercises = filtered

            # Convert staple exercises from dicts to names
            staple_names = get_staple_names(staple_exercises) if staple_exercises else None

            # Determine focus area for RAG selection
            focus_area = request.focus_areas[0] if request.focus_areas else "full_body"

            # Calculate exercise count based on duration and fitness level
            target_duration = request.duration_minutes or 45

            # Handle duration ranges (e.g., user selected "45-60 min" during onboarding)
            # Use the MAX duration for exercise cap to give appropriate variety for longer sessions
            if request.duration_minutes_max:
                effective_duration = request.duration_minutes_max
            elif request.duration_minutes_min:
                effective_duration = request.duration_minutes_min
            else:
                effective_duration = target_duration

            # Calculate base exercise count from duration
            base_exercise_count = max(4, min(12, effective_duration // 6))

            # Define exercise caps by fitness level AND duration
            # Research: beginners benefit from 3-5 exercises, intermediate 5-7, advanced can handle more
            EXERCISE_CAPS = {
                "beginner": {
                    30: 4,   # Short session: focus on fundamentals
                    45: 5,   # Standard session: 5 exercises max
                    60: 5,   # Longer session: still 5 to master form
                    75: 6,   # Extended session: allow 1 more
                    90: 6,   # Marathon session: cap at 6 to prevent overwhelm
                },
                "intermediate": {
                    30: 5,
                    45: 6,
                    60: 7,
                    75: 8,
                    90: 9,
                },
                "advanced": {
                    30: 5,
                    45: 7,
                    60: 8,
                    75: 10,
                    90: 11,
                },
            }

            # Hell mode gets elevated caps (user accepted risk warning)
            HELL_MODE_EXERCISE_CAPS = {
                "beginner": {30: 5, 45: 6, 60: 6, 75: 7, 90: 7},
                "intermediate": {30: 6, 45: 7, 60: 8, 75: 9, 90: 10},
                "advanced": {30: 6, 45: 8, 60: 10, 75: 11, 90: 12},
            }

            # Determine which cap table to use
            is_hell_mode = intensity_preference and intensity_preference.lower() == "hell"
            cap_table = HELL_MODE_EXERCISE_CAPS if is_hell_mode else EXERCISE_CAPS

            # Get the appropriate cap for this fitness level and duration
            level = fitness_level or "intermediate"
            level_caps = cap_table.get(level, cap_table["intermediate"])

            # Find the closest duration bracket (using effective_duration for ranges)
            if effective_duration <= 35:
                duration_bracket = 30
            elif effective_duration <= 50:
                duration_bracket = 45
            elif effective_duration <= 65:
                duration_bracket = 60
            elif effective_duration <= 80:
                duration_bracket = 75
            else:
                duration_bracket = 90

            max_exercises = level_caps.get(duration_bracket, 8)
            exercise_count = min(base_exercise_count, max_exercises)

            logger.info(f"📊 [Exercise Count] Level: {level}, Duration: {effective_duration}min, Hell: {is_hell_mode}, Cap: {max_exercises}, Final: {exercise_count}")

            # Extract injury names (injuries already fetched in parallel above)
            # get_active_injuries_with_muscles returns {"injuries": [...], "avoided_muscles": [...]}
            injury_names = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)

            # Merge injury-based avoided muscles into the main avoided_muscles dict
            if isinstance(injuries, dict) and injuries.get("avoided_muscles"):
                injury_avoided = injuries["avoided_muscles"]
                existing_avoid = avoided_muscles.get("avoid", [])
                merged_avoid = list(set(existing_avoid + [m for m in injury_avoided if m not in existing_avoid]))
                avoided_muscles["avoid"] = merged_avoid
                if injury_avoided:
                    logger.info(f"🩹 [Injuries] Merged {len(injury_avoided)} injury-based avoided muscles: {injury_avoided}")

            # Use Exercise RAG to select exercises from the database
            # This ensures all exercise names match exercise_library_cleaned
            logger.info(f"🔍 [RAG] Selecting {exercise_count} exercises for {focus_area} workout")
            rag_exercises = await exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=equipment if isinstance(equipment, list) else [],
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                count=exercise_count,
                avoid_exercises=avoided_exercises if avoided_exercises else [],
                injuries=injury_names,
                staple_exercises=staple_exercises,
                avoided_muscles=avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
                workout_environment=workout_environment,
                # Exercise consistency preferences
                consistency_mode=consistency_mode,
                recently_used_exercises=recently_used_exercises,
                variation_percentage=variation_percentage,
                workout_type_preference=request.workout_type or "strength",
                favorite_exercises=favorite_exercises if favorite_exercises else None,
                queued_exercises=exercise_queue if exercise_queue else None,
            )

            if rag_exercises:
                # Use RAG-selected exercises - these have correct names from DB
                logger.info(f"✅ [RAG] Selected {len(rag_exercises)} exercises from library")
                workout_data = await gemini_service.generate_workout_from_library(
                    exercises=rag_exercises,
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=request.focus_areas if request.focus_areas else [focus_area],
                    intensity_preference=intensity_preference,
                    workout_type_preference=request.workout_type,
                    user_dob=user.get("date_of_birth") if user else None,
                )
            else:
                # Fallback to free-form generation if RAG returns no exercises
                logger.warning(f"⚠️ [RAG] No exercises found, falling back to free-form generation")
                workout_data = await gemini_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    equipment=equipment if isinstance(equipment, list) else [],
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=request.focus_areas,
                    intensity_preference=intensity_preference,
                    custom_exercises=custom_exercises if custom_exercises else None,
                    workout_environment=workout_environment,
                    equipment_details=equipment_details if equipment_details else None,
                    avoided_exercises=avoided_exercises if avoided_exercises else None,
                    avoided_muscles=avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
                    staple_exercises=staple_names,
                    progression_philosophy=combined_context if combined_context else None,
                    workout_patterns_context=workout_patterns_context if workout_patterns_context else None,
                    favorite_workouts_context=favorite_workouts_context if favorite_workouts_context else None,
                    set_type_context=set_type_context if set_type_context else None,
                    primary_goal=primary_goal,
                    muscle_focus_points=muscle_focus_points,
                    training_split=training_split,
                    # Fitness assessment for smarter workout personalization
                    pushup_capacity=pushup_capacity,
                    pullup_capacity=pullup_capacity,
                    plank_capacity=plank_capacity,
                    squat_capacity=squat_capacity,
                    cardio_capacity=cardio_capacity,
                    user_dob=user.get("date_of_birth") if user else None,
                )

            # Ensure workout_data is a dict (guard against Gemini returning a string)
            if isinstance(workout_data, str):
                try:
                    workout_data = json.loads(workout_data)
                except (json.JSONDecodeError, ValueError):
                    logger.error(f"workout_data is an unparseable string: {str(workout_data)[:200]}")
                    workout_data = {}
            if not isinstance(workout_data, dict):
                logger.error(f"workout_data is not a dict: type={type(workout_data).__name__}")
                workout_data = {}

            exercises = workout_data.get("exercises", [])
            exercises = normalize_exercise_numeric_fields(exercises)
            workout_name = workout_data.get("name", "Generated Workout")
            difficulty = workout_data.get("difficulty", intensity_preference)
            workout_description = workout_data.get("description")

            # Infer workout type from focus area for PPL tracking
            # This ensures workout_type is set correctly even when Gemini doesn't specify it
            from api.v1.workouts.utils import infer_workout_type_from_focus

            raw_type = workout_data.get("type", request.workout_type)
            if request.focus_areas and len(request.focus_areas) > 0:
                workout_type = infer_workout_type_from_focus(request.focus_areas[0])
                logger.info(f"🎯 [Type] Inferred workout type '{workout_type}' from focus '{request.focus_areas[0]}'")
            else:
                workout_type = raw_type or "strength"

            # POST-GENERATION VALIDATION: Filter out any exercises that violate user preferences
            # This is a safety net in case the AI still includes avoided exercises
            filtered_exercises = []  # Track filtered exercises for auto-substitution

            if avoided_exercises:
                original_count = len(exercises)
                avoided_lower = [ae.lower() for ae in avoided_exercises]
                filtered_exercises.extend([
                    ex for ex in exercises
                    if ex.get("name", "").lower() in avoided_lower
                ])
                exercises = [
                    ex for ex in exercises
                    if ex.get("name", "").lower() not in avoided_lower
                ]
                filtered_count = original_count - len(exercises)
                if filtered_count > 0:
                    logger.warning(f"⚠️ [Validation] Filtered out {filtered_count} avoided exercises from AI response")

            if avoided_muscles and avoided_muscles.get("avoid"):
                original_count = len(exercises)
                avoid_muscles_lower = [m.lower() for m in avoided_muscles["avoid"]]
                filtered_exercises.extend([
                    ex for ex in exercises
                    if ex.get("muscle_group", "").lower() in avoid_muscles_lower
                ])
                exercises = [
                    ex for ex in exercises
                    if ex.get("muscle_group", "").lower() not in avoid_muscles_lower
                ]
                filtered_count = original_count - len(exercises)
                if filtered_count > 0:
                    logger.warning(f"⚠️ [Validation] Filtered out {filtered_count} exercises targeting avoided muscles")

            # Handle "reduce" muscles - limit to max 1 exercise per reduced muscle
            if avoided_muscles and avoided_muscles.get("reduce"):
                reduce_muscles_lower = [m.lower() for m in avoided_muscles["reduce"]]
                muscle_counts = {}  # Track count of exercises per reduced muscle

                # Count exercises per reduced muscle
                for ex in exercises:
                    muscle = ex.get("muscle_group", "").lower()
                    if muscle in reduce_muscles_lower:
                        muscle_counts[muscle] = muscle_counts.get(muscle, 0) + 1

                # If any reduced muscle has more than 1 exercise, remove extras
                if any(count > 1 for count in muscle_counts.values()):
                    reduced_seen = set()
                    new_exercises = []
                    removed_count = 0

                    for ex in exercises:
                        muscle = ex.get("muscle_group", "").lower()
                        if muscle in reduce_muscles_lower:
                            if muscle not in reduced_seen:
                                reduced_seen.add(muscle)
                                new_exercises.append(ex)  # Keep first occurrence
                            else:
                                filtered_exercises.append(ex)  # Mark for substitution
                                removed_count += 1
                        else:
                            new_exercises.append(ex)

                    if removed_count > 0:
                        logger.info(f"🎯 [Validation] Limited {removed_count} exercises targeting reduced muscles (max 1 per muscle)")
                        exercises = new_exercises

            # Filter similar exercises to ensure movement pattern diversity
            # This prevents workouts like "6 push-up variations" by limiting MAX 2 per pattern
            from services.exercise_rag.filters import is_similar_exercise, get_movement_pattern

            # Phase 2: Deduplicate by movement pattern - MAX 2 exercises per pattern
            MAX_PER_PATTERN = 2
            pattern_counts = {}
            original_exercise_count = len(exercises)
            deduplicated_exercises = []
            seen_exercise_names = []

            for ex in exercises:
                ex_name = ex.get("name", "") or ex.get("exercise_name", "")
                pattern = get_movement_pattern(ex_name)

                # First check: Is this an exact duplicate of a seen exercise?
                is_duplicate = False
                for seen_name in seen_exercise_names:
                    if is_similar_exercise(ex_name, seen_name, check_movement_pattern=False):
                        is_duplicate = True
                        filtered_exercises.append(ex)  # Mark for auto-substitution
                        logger.debug(f"🔄 [Variety] Filtered duplicate: '{ex_name}' (same as '{seen_name}')")
                        break

                if is_duplicate:
                    continue

                # Second check: Movement pattern limit (MAX 2 per pattern)
                if pattern:
                    current_count = pattern_counts.get(pattern, 0)
                    if current_count >= MAX_PER_PATTERN:
                        filtered_exercises.append(ex)
                        logger.debug(f"🔄 [Variety] Filtered '{ex_name}' - pattern '{pattern}' has {current_count} exercises (max {MAX_PER_PATTERN})")
                        continue
                    pattern_counts[pattern] = current_count + 1

                seen_exercise_names.append(ex_name)
                deduplicated_exercises.append(ex)

            if len(deduplicated_exercises) < original_exercise_count:
                removed_count = original_exercise_count - len(deduplicated_exercises)
                logger.warning(f"⚠️ [Validation] Removed {removed_count} exercises due to pattern limits (MAX {MAX_PER_PATTERN} per pattern)")
                logger.info(f"📊 [Patterns] Final pattern distribution: {pattern_counts}")
                exercises = deduplicated_exercises

            # Phase 3: Validate equipment utilization - warn if workouts don't match user's equipment
            # This helps identify when Gemini is generating suboptimal equipment choices
            equipment_lower = [eq.lower() for eq in equipment] if equipment else []
            has_gym_equipment = any(eq in equipment_lower for eq in ["full_gym", "dumbbells", "barbell", "cable_machine", "machines"])

            if has_gym_equipment and exercises:
                bodyweight_count = sum(
                    1 for ex in exercises
                    if (ex.get("equipment", "") or "").lower() in ["bodyweight", "body weight", ""]
                )
                bodyweight_ratio = bodyweight_count / len(exercises)

                if bodyweight_ratio > 0.4:  # Lowered threshold from 0.5 to 0.4
                    logger.warning(
                        f"⚠️ [Equipment] High bodyweight ratio ({bodyweight_ratio:.0%}) "
                        f"despite gym equipment available: {equipment}"
                    )
                    # Log which equipment was available but not used
                    used_equipment = set(ex.get("equipment", "").lower() for ex in exercises)
                    unused_equipment = [eq for eq in equipment if eq.lower() not in used_equipment and eq != "bodyweight"]
                    if unused_equipment:
                        logger.info(f"📋 [Equipment] Unused equipment: {unused_equipment}")

                # Check kettlebell usage specifically
                if "kettlebell" in equipment_lower or "kettlebells" in equipment_lower:
                    kb_count = sum(
                        1 for ex in exercises
                        if "kettlebell" in (ex.get("equipment", "") or "").lower()
                        or "kb" in (ex.get("name", "") or "").lower()
                    )
                    if kb_count == 0:
                        logger.warning(f"⚠️ [Equipment] Kettlebell available but NOT used in any exercise!")

            # Auto-substitute filtered exercises with safe alternatives
            if filtered_exercises and exercises:
                exercises = await auto_substitute_filtered_exercises(
                    exercises=exercises,
                    filtered_exercises=filtered_exercises,
                    user_id=request.user_id,
                    avoided_exercises=avoided_exercises or [],
                    equipment=equipment if isinstance(equipment, list) else [],
                )

            # Log validation results
            if exercises:
                logger.info(f"✅ [Validation] Final workout has {len(exercises)} exercises after preference validation")
            else:
                logger.error(f"❌ [Validation] All exercises were filtered out! Regenerating without strict filtering...")
                # If all exercises were filtered, fall back to original (better than empty workout)
                exercises = workout_data.get("exercises", [])

            # Apply 1RM-based weights for personalized weight recommendations
            # This ensures weights are based on user's actual strength data
            one_rm_data = await get_user_1rm_data(request.user_id)
            training_intensity = await get_user_training_intensity(request.user_id)
            intensity_overrides = await get_user_intensity_overrides(request.user_id)

            if one_rm_data and exercises:
                exercises = apply_1rm_weights_to_exercises(
                    exercises, one_rm_data, training_intensity, intensity_overrides
                )
                logger.info(f"💪 [Weight Personalization] Applied 1RM-based weights to exercises")

            # Phase 7: Infer weights for exercises still missing weight_kg
            # This provides fallback weight recommendations based on exercise type and fitness level
            from core.weight_utils import get_starting_weight, detect_equipment_type

            weights_inferred = 0
            for ex in exercises:
                weight_kg = ex.get("weight_kg")
                # Check if weight is missing or invalid
                if weight_kg is None or weight_kg == 0 or str(weight_kg).lower() == "not set":
                    ex_equipment = (ex.get("equipment") or "").lower()
                    # Only infer for weighted exercises (not bodyweight)
                    if ex_equipment not in ["bodyweight", "body weight", ""]:
                        ex_name = ex.get("name", "") or ex.get("exercise_name", "")
                        detected_equipment = detect_equipment_type(ex_name, equipment)
                        inferred_weight = get_starting_weight(
                            exercise_name=ex_name,
                            equipment_type=detected_equipment,
                            fitness_level=fitness_level or "intermediate",
                        )
                        if inferred_weight and inferred_weight > 0:
                            ex["weight_kg"] = inferred_weight
                            weights_inferred += 1
                            logger.debug(f"💪 Inferred weight for {ex_name}: {inferred_weight}kg ({detected_equipment})")

            if weights_inferred > 0:
                logger.info(f"💪 [Weight Inference] Inferred weights for {weights_inferred} exercises missing weight_kg")

            # Phase 8: Enforce advanced techniques for intermediate/advanced users
            # This is a safety net in case Gemini doesn't set is_failure_set/is_drop_set
            if exercises and fitness_level and fitness_level.lower() in ["intermediate", "advanced"]:
                # Check if any exercises have advanced techniques
                has_failure_set = any(ex.get("is_failure_set") for ex in exercises)
                has_drop_set = any(ex.get("is_drop_set") for ex in exercises)

                # If no failure sets for intermediate/advanced, add to last isolation exercise
                if not has_failure_set:
                    # Find last isolation exercise (curls, extensions, raises, flyes)
                    isolation_keywords = ["curl", "extension", "raise", "fly", "flye", "kickback", "pulldown", "pushdown"]
                    for ex in reversed(exercises):
                        ex_name = (ex.get("name") or "").lower()
                        if any(kw in ex_name for kw in isolation_keywords):
                            ex["is_failure_set"] = True
                            ex["notes"] = (ex.get("notes") or "") + " Final set: AMRAP (to failure)"
                            logger.info(f"🔥 [Advanced Tech] Added failure set to '{ex.get('name')}'")
                            break
                    else:
                        # If no isolation found, add to last exercise
                        if exercises:
                            exercises[-1]["is_failure_set"] = True
                            exercises[-1]["notes"] = (exercises[-1].get("notes") or "") + " Final set: AMRAP"
                            logger.info(f"🔥 [Advanced Tech] Added failure set to last exercise '{exercises[-1].get('name')}'")

                # For advanced users, also add drop set if missing
                if fitness_level.lower() == "advanced" and not has_drop_set:
                    for ex in reversed(exercises):
                        ex_name = (ex.get("name") or "").lower()
                        if any(kw in ex_name for kw in isolation_keywords):
                            if not ex.get("is_failure_set"):  # Don't double-up on same exercise
                                ex["is_drop_set"] = True
                                ex["drop_set_count"] = 2
                                ex["drop_set_percentage"] = 20
                                ex["notes"] = (ex.get("notes") or "") + " Drop set: reduce weight 20% twice"
                                logger.info(f"🔥 [Advanced Tech] Added drop set to '{ex.get('name')}'")
                                break

            # CRITICAL SAFETY NET: Validate and cap exercise parameters
            # This prevents extreme workouts like 90 squats from reaching users
            # Fetch user age and comeback status for comprehensive validation
            user_age = None
            if not (request.fitness_level and request.goals and request.equipment):
                # We already fetched user above, get age from there
                user_age = user.get("age") if user else None

            comeback_status = await get_user_comeback_status(request.user_id)
            is_comeback = comeback_status.get("in_comeback_mode", False)
            if getattr(request, 'skip_comeback', None):
                is_comeback = False

            if exercises:
                exercises = validate_and_cap_exercise_parameters(
                    exercises=exercises,
                    fitness_level=fitness_level or "intermediate",
                    age=user_age,
                    is_comeback=is_comeback,
                    difficulty=intensity_preference
                )
                logger.info(f"🛡️ [Safety] Validated exercise parameters (fitness={fitness_level}, age={user_age}, comeback={is_comeback}, difficulty={intensity_preference})")

                # CRITICAL: Enforce user's set/rep limits as final validation
                # This ensures AI-generated workouts NEVER exceed user preferences
                if set_rep_limits:
                    exercises = enforce_set_rep_limits(
                        exercises=exercises,
                        set_rep_limits=set_rep_limits,
                        exercise_patterns=exercise_patterns,
                    )
                    logger.info(f"[Set/Rep Limits] Enforced user limits: max_sets={set_rep_limits.get('max_sets_per_exercise', 5)}, max_reps={set_rep_limits.get('max_reps_per_set', 15)}")

                # CYCLE PHASE ADJUSTMENTS: Reduce intensity during menstrual/luteal phases if symptoms
                if hormonal_context.get("cycle_phase"):
                    exercises = adjust_workout_for_cycle_phase(
                        exercises=exercises,
                        cycle_phase=hormonal_context["cycle_phase"],
                        symptom_severity=hormonal_context.get("symptom_severity"),
                    )
                    logger.info(f"[Hormonal Adjustments] Applied cycle phase adjustments for {hormonal_context['cycle_phase']} phase")

                # FOCUS AREA VALIDATION: Ensure exercises match the workout focus
                # This catches AI hallucinations where exercise names don't match the workout type
                MIN_EXERCISES_REQUIRED = 3  # Minimum exercises per workout

                if focus_areas and len(focus_areas) > 0 and exercises:
                    primary_focus = focus_areas[0]
                    focus_validation = await validate_and_filter_focus_mismatches(
                        exercises=exercises,
                        focus_area=primary_focus,
                        workout_name=workout_name,
                    )

                    if focus_validation["mismatch_count"] > 0:
                        logger.warning(
                            f"🚨 [Focus Validation] Found {focus_validation['mismatch_count']} mismatched exercises "
                            f"in '{workout_name}' for focus '{primary_focus}'. "
                            f"Mismatched: {[ex.get('name') for ex in focus_validation['mismatched_exercises']]}"
                        )

                        valid_exercises = focus_validation["valid_exercises"]

                        # If we have enough valid exercises, use only those
                        if len(valid_exercises) >= MIN_EXERCISES_REQUIRED:
                            logger.info(
                                f"✅ [Focus Validation] Filtering to {len(valid_exercises)} valid exercises "
                                f"(removed {focus_validation['mismatch_count']} mismatched)"
                            )
                            exercises = valid_exercises
                        else:
                            # Not enough valid exercises - this is a critical AI error
                            # Keep all exercises but log the issue prominently
                            logger.error(
                                f"❌ [Focus Validation] CRITICAL: Workout '{workout_name}' has only "
                                f"{len(valid_exercises)} valid exercises for '{primary_focus}' focus "
                                f"(minimum required: {MIN_EXERCISES_REQUIRED}). "
                                f"Keeping all {len(exercises)} exercises to meet minimum. "
                                f"User may see mismatched exercises (e.g., push-ups in leg workout)."
                            )

                # MINIMUM EXERCISE COUNT VALIDATION
                if len(exercises) < MIN_EXERCISES_REQUIRED:
                    logger.error(
                        f"❌ [Exercise Count] Workout '{workout_name}' has only {len(exercises)} exercises "
                        f"(minimum required: {MIN_EXERCISES_REQUIRED}). This is an AI generation error."
                    )

        except Exception as ai_error:
            logger.error(f"AI workout generation failed: {ai_error}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate workout: {str(ai_error)}"
            )

        workout_db_data = {
            "user_id": request.user_id,
            "gym_profile_id": gym_profile_id,  # Link workout to gym profile
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "description": workout_description,
            "scheduled_date": request.scheduled_date or datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": request.duration_minutes or 45,
            "generation_method": "ai",
            "generation_source": "gemini_generation",
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Workout generated: id={created['id']}, gym_profile_id={gym_profile_id}")

        # Delete placeholder now that real workout exists
        if placeholder_id:
            try:
                db.client.table("workouts").delete().eq("id", placeholder_id).execute()
                logger.info(f"🔓 [Dedup] Deleted placeholder {placeholder_id}")
            except Exception as e:
                logger.warning(f"Failed to delete placeholder: {e}")

        # Log workout change synchronously (quick, important for audit trail)
        log_workout_change(
            workout_id=created['id'],
            user_id=request.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={"name": workout_name, "exercises_count": len(exercises)}
        )

        generated_workout = row_to_workout(created)

        # Move RAG indexing to background (non-critical, don't block response)
        async def _bg_index_rag():
            try:
                await index_workout_to_rag(generated_workout)
            except Exception as e:
                logger.warning(f"Background: Failed to index workout to RAG: {e}")

        background_tasks.add_task(_bg_index_rag)

        # Track premium gate usage after successful generation
        from core.premium_gate import track_premium_usage
        background_tasks.add_task(track_premium_usage, request.user_id, "ai_workout_generation")

        return generated_workout

    except HTTPException:
        # Clean up placeholder on error
        if placeholder_id:
            try:
                db.client.table("workouts").delete().eq("id", placeholder_id).execute()
            except Exception as e:
                logger.warning(f"Placeholder cleanup failed: {e}")
        raise
    except Exception as e:
        # Clean up placeholder on error
        if placeholder_id:
            try:
                db.client.table("workouts").delete().eq("id", placeholder_id).execute()
            except Exception as cleanup_err:
                logger.warning(f"Placeholder cleanup failed: {cleanup_err}")
        logger.error(f"Failed to generate workout: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/generate-stream")
@user_limiter.limit("15/minute")  # User-based rate limit (more reliable than IP behind proxies)
async def generate_workout_streaming(request: Request, body: GenerateWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a workout with streaming response for faster perceived performance.

    Returns Server-Sent Events (SSE) with:
    - event: chunk - Partial workout data as it's generated
    - event: done - Final complete workout data
    - event: error - Error message if generation fails
    - event: already_generating - Workout generation already in progress

    Time to first content is typically <500ms vs 3-8s for full generation.
    """
    logger.info(f"🚀 Streaming workout generation for user {body.user_id}")

    # Idempotency check: If a workout is already being generated for this user/date, return early
    db = get_supabase_db()
    scheduled_date = body.scheduled_date or datetime.now().strftime("%Y-%m-%d")

    # Resolve gym_profile_id early for dedup checks
    stream_gym_profile_id = body.gym_profile_id or None
    if not stream_gym_profile_id:
        try:
            active_result = db.client.table("gym_profiles").select("id").eq(
                "user_id", body.user_id
            ).eq("is_active", True).single().execute()
            if active_result.data:
                stream_gym_profile_id = active_result.data.get("id")
        except Exception as e:
            logger.warning(f"Failed to get active gym profile: {e}")

    try:
        generating_query = db.client.table("workouts").select("id").eq(
            "user_id", body.user_id
        ).eq(
            "scheduled_date", scheduled_date
        ).eq(
            "status", "generating"
        )
        if stream_gym_profile_id:
            generating_query = generating_query.eq("gym_profile_id", stream_gym_profile_id)
        existing_generating = generating_query.execute()

        if existing_generating.data:
            workout_id = existing_generating.data[0]["id"]
            logger.info(f"⏳ [Idempotency] Workout already generating for {body.user_id} on {scheduled_date} (profile={stream_gym_profile_id}): {workout_id}")

            async def already_generating_sse():
                yield f"event: already_generating\ndata: {json.dumps({'status': 'already_generating', 'workout_id': workout_id, 'message': 'Workout generation already in progress'})}\n\n"

            return StreamingResponse(already_generating_sse(), media_type="text/event-stream")

        # Duplicate check: If a completed/active workout already exists for this user+date+profile, return it
        duplicate_query = db.client.table("workouts").select("id,name,status").eq(
            "user_id", body.user_id
        ).eq(
            "scheduled_date", scheduled_date
        ).neq(
            "status", "generating"
        )
        if stream_gym_profile_id:
            duplicate_query = duplicate_query.eq("gym_profile_id", stream_gym_profile_id)
        existing_workout = duplicate_query.limit(1).execute()

        if existing_workout.data:
            workout_id = existing_workout.data[0]["id"]
            logger.info(f"✅ [Duplicate] Workout already exists for {body.user_id} on {scheduled_date}: {workout_id}")
            full_workout = db.client.table("workouts").select("*").eq("id", workout_id).single().execute()

            async def existing_sse():
                yield f"event: done\ndata: {json.dumps(full_workout.data)}\n\n"

            return StreamingResponse(existing_sse(), media_type="text/event-stream")
    except Exception as e:
        # Log but don't fail - idempotency check is a nice-to-have
        logger.warning(f"⚠️ [Idempotency] Check failed: {e}")

    # Premium gate check: enforce free-tier workout generation limits
    from core.premium_gate import check_premium_gate
    await check_premium_gate(body.user_id, "ai_workout_generation")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()
        gym_profile_id = None  # Track which profile this workout is generated for

        try:

            # Get user data
            if body.fitness_level and body.goals and body.equipment:
                fitness_level = body.fitness_level
                goals = body.goals
                equipment = body.equipment
                # Derive intensity from fitness level - beginners get 'easy', not 'medium'
                intensity_preference = get_intensity_from_fitness_level(fitness_level)
            else:
                user = db.get_user(body.user_id)
                if not user:
                    yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                    return

                fitness_level = body.fitness_level or user.get("fitness_level")
                preferences = parse_json_field(user.get("preferences"), {})

                # Check for gym profile - load equipment/environment from profile if available
                gym_profile = None
                if hasattr(body, 'gym_profile_id') and body.gym_profile_id:
                    # Specific profile requested
                    try:
                        profile_result = db.client.table("gym_profiles").select("*").eq("id", body.gym_profile_id).single().execute()
                        gym_profile = profile_result.data if profile_result.data else None
                        logger.info(f"🏋️ [GymProfile] Using requested profile: {body.gym_profile_id}")
                    except Exception as e:
                        logger.warning(f"Failed to fetch gym profile: {e}")
                else:
                    # Try to get active profile
                    try:
                        active_result = db.client.table("gym_profiles").select("*").eq("user_id", body.user_id).eq("is_active", True).single().execute()
                        gym_profile = active_result.data if active_result.data else None
                        if gym_profile:
                            logger.info(f"🏋️ [GymProfile] Using active profile: {gym_profile.get('name')} ({gym_profile.get('id')})")
                    except Exception as e:
                        logger.debug(f"No active gym profile found: {e}")

                if gym_profile:
                    # Load settings from gym profile
                    gym_profile_id = gym_profile.get("id")
                    equipment = body.equipment or gym_profile.get("equipment") or []
                    profile_goals = normalize_goals_list(gym_profile.get("goals"))
                    # Parse user goals if it's a JSON string
                    user_goals = normalize_goals_list(user.get("goals"))
                    goals = normalize_goals_list(body.goals) if body.goals else (profile_goals if profile_goals else user_goals)
                    logger.info(f"🏋️ [GymProfile] Profile equipment: {len(equipment)} items")
                else:
                    # Fall back to user settings (parse JSON strings)
                    goals = normalize_goals_list(body.goals) if body.goals else normalize_goals_list(user.get("goals"))
                    equipment = body.equipment or parse_json_field(user.get("equipment"), [])

                # Use explicit intensity_preference if set, otherwise derive from fitness level
                intensity_preference = preferences.get("intensity_preference") or get_intensity_from_fitness_level(fitness_level)

            # Fetch user preferences in PARALLEL for faster response
            # This is CRITICAL for respecting user preferences in workout generation
            # Using asyncio.gather reduces ~3s of sequential fetches to ~500ms
            async def fetch_ai_coach_settings():
                """Helper to fetch AI coach settings with error handling."""
                try:
                    ai_result = db.client.table("user_ai_settings").select(
                        "coaching_style", "communication_tone", "coach_name", "coach_persona_id"
                    ).eq("user_id", body.user_id).single().execute()
                    return ai_result.data if ai_result.data else None
                except Exception as e:
                    logger.debug(f"[Streaming] No AI coach settings found, using defaults: {e}")
                    return None

            (
                avoided_exercises,
                avoided_muscles,
                staple_exercises,
                rep_preferences,
                progression_context,
                hormonal_context,
                ai_coach_settings,
                strength_history,
                favorite_exercises,
                exercise_queue,
            ) = await asyncio.gather(
                get_user_avoided_exercises(body.user_id),
                get_user_avoided_muscles(body.user_id),
                get_user_staple_exercises(body.user_id, gym_profile_id=gym_profile_id),
                get_user_rep_preferences(body.user_id),
                get_user_progression_context(body.user_id),
                get_user_hormonal_context(body.user_id),
                fetch_ai_coach_settings(),
                get_user_strength_history(body.user_id),
                get_user_favorite_exercises(body.user_id),
                get_user_exercise_queue(body.user_id),
            )

            # Log fetched preferences
            if avoided_exercises:
                logger.info(f"🚫 [Streaming] User has {len(avoided_exercises)} avoided exercises")
            if avoided_muscles.get("avoid") or avoided_muscles.get("reduce"):
                logger.info(f"🚫 [Streaming] User has avoided muscles")
            if staple_exercises:
                logger.info(f"⭐ [Streaming] User has {len(staple_exercises)} staple exercises")
            if favorite_exercises:
                logger.info(f"❤️ [Streaming] User has {len(favorite_exercises)} favorite exercises: {favorite_exercises[:5]}")
            if exercise_queue:
                logger.info(f"📋 [Streaming] User has {len(exercise_queue)} queued exercises")
            if ai_coach_settings:
                logger.info(f"🎨 [Streaming] Coach settings: style={ai_coach_settings.get('coaching_style')}, tone={ai_coach_settings.get('communication_tone')}")

            # Build progression philosophy from fetched data
            progression_philosophy = build_progression_philosophy_prompt(
                rep_preferences=rep_preferences,
                progression_context=progression_context,
            )

            # Process hormonal context
            hormonal_ai_context = hormonal_context.get("ai_context", "")
            if hormonal_context.get("cycle_phase"):
                logger.info(f"[Streaming] User is in {hormonal_context['cycle_phase']} phase")

            # Combine progression philosophy with hormonal context
            combined_context = progression_philosophy or ""
            if hormonal_ai_context:
                combined_context = f"{combined_context}\n\nHORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}" if combined_context else f"HORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}"

            gemini_service = GeminiService()

            # Calculate exercise count with fitness-level caps (same logic as /generate endpoint)
            effective_duration = body.duration_minutes_max or body.duration_minutes_min or (body.duration_minutes or 45)
            base_exercise_count = max(4, min(12, effective_duration // 6))

            # Define exercise caps by fitness level AND duration
            EXERCISE_CAPS = {
                "beginner": {30: 4, 45: 5, 60: 5, 75: 6, 90: 6},
                "intermediate": {30: 5, 45: 6, 60: 7, 75: 8, 90: 9},
                "advanced": {30: 5, 45: 7, 60: 8, 75: 10, 90: 11},
            }
            HELL_MODE_EXERCISE_CAPS = {
                "beginner": {30: 5, 45: 6, 60: 6, 75: 7, 90: 7},
                "intermediate": {30: 6, 45: 7, 60: 8, 75: 9, 90: 10},
                "advanced": {30: 6, 45: 8, 60: 10, 75: 11, 90: 12},
            }

            is_hell_mode = intensity_preference and intensity_preference.lower() == "hell"
            cap_table = HELL_MODE_EXERCISE_CAPS if is_hell_mode else EXERCISE_CAPS
            level = fitness_level or "intermediate"
            level_caps = cap_table.get(level, cap_table["intermediate"])

            # Find the closest duration bracket
            if effective_duration <= 35:
                duration_bracket = 30
            elif effective_duration <= 50:
                duration_bracket = 45
            elif effective_duration <= 65:
                duration_bracket = 60
            elif effective_duration <= 80:
                duration_bracket = 75
            else:
                duration_bracket = 90

            max_exercises = level_caps.get(duration_bracket, 8)
            exercise_count = min(base_exercise_count, max_exercises)

            logger.info(f"📊 [Streaming Exercise Count] Level: {level}, Duration: {effective_duration}min, Hell: {is_hell_mode}, Cap: {max_exercises}, Final: {exercise_count}")

            # Send initial acknowledgment (time to first byte)
            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'ttfb_ms': first_chunk_time})}\n\n"

            # Stream the workout generation
            accumulated_chunks = []
            total_chars = 0
            chunk_count = 0

            # Equipment guard: filter out "All Profiles" staples whose equipment isn't available
            if equipment and staple_exercises:
                filtered = []
                equipment_lower = [e.lower() for e in equipment]
                for s in staple_exercises:
                    if s.get("gym_profile_id") is not None:
                        filtered.append(s)  # Profile-specific: always include
                    elif not s.get("equipment") or s["equipment"].lower() in equipment_lower:
                        filtered.append(s)  # All-profiles: include if equipment matches or bodyweight
                    else:
                        logger.info(f"Skipping all-profiles staple '{s['name']}' - requires '{s.get('equipment')}' not in profile equipment")
                staple_exercises = filtered

            # Convert staple exercises from dicts to names
            staple_names = get_staple_names(staple_exercises) if staple_exercises else None

            # Check if context caching is enabled (faster generation)
            settings = get_settings()
            use_cached = settings.gemini_cache_enabled
            logger.info(f"[Streaming] Using {'CACHED' if use_cached else 'non-cached'} workout generation")

            try:
                # Use cached streaming if enabled (5-10x faster)
                generator_func = (
                    gemini_service.generate_workout_plan_streaming_cached
                    if use_cached
                    else gemini_service.generate_workout_plan_streaming
                )

                # Build kwargs - cached version takes strength_history
                generator_kwargs = {
                    "fitness_level": fitness_level or "intermediate",
                    "goals": goals if isinstance(goals, list) else [],
                    "equipment": equipment if isinstance(equipment, list) else [],
                    "duration_minutes": body.duration_minutes or 45,
                    "duration_minutes_min": body.duration_minutes_min,
                    "duration_minutes_max": body.duration_minutes_max,
                    "focus_areas": body.focus_areas,
                    "intensity_preference": intensity_preference,
                    "avoided_exercises": avoided_exercises if avoided_exercises else None,
                    "avoided_muscles": avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
                    "staple_exercises": staple_names,
                    "progression_philosophy": combined_context if combined_context else None,
                    "exercise_count": exercise_count,
                    "coach_style": ai_coach_settings.get("coaching_style") if ai_coach_settings else None,
                    "coach_tone": ai_coach_settings.get("communication_tone") if ai_coach_settings else None,
                    "scheduled_date": scheduled_date,
                    "user_dob": user.get("date_of_birth") if user else None,
                }

                # Add strength_history for cached version
                if use_cached:
                    generator_kwargs["strength_history"] = strength_history

                async for chunk in generator_func(**generator_kwargs):
                    accumulated_chunks.append(chunk)
                    total_chars += len(chunk)
                    chunk_count += 1

                    # Send progress updates every few chunks
                    if chunk_count % 3 == 0:
                        elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                        yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': total_chars, 'elapsed_ms': elapsed_ms})}\n\n"

                accumulated_text = "".join(accumulated_chunks)
                logger.info(f"✅ [Streaming] Stream completed: {chunk_count} chunks, {len(accumulated_text)} total chars")
            except Exception as stream_error:
                logger.error(f"❌ [Streaming] Stream error after {chunk_count} chunks, {total_chars} chars: {stream_error}")
                yield f"event: error\ndata: {json.dumps({'error': f'Streaming failed: {str(stream_error)}'})}\n\n"
                return

            # Parse the complete response
            try:
                # Extract JSON from potential markdown code blocks
                content = accumulated_text.strip()
                logger.info(f"🔍 [Streaming Parse] Raw response length: {len(accumulated_text)} chars")
                logger.debug(f"🔍 [Streaming Parse] Raw content: {accumulated_text[:500]}...")

                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                logger.info(f"🔍 [Streaming Parse] Cleaned content length: {len(content)} chars")
                if len(content) < 100:
                    logger.error(f"🚨 [Streaming Parse] Content too short, full content: {content}")

                workout_data = json.loads(content)

                # Ensure workout_data is a dict - Gemini may return a string
                if isinstance(workout_data, str):
                    try:
                        workout_data = json.loads(workout_data)
                    except (json.JSONDecodeError, ValueError):
                        logger.error(f"workout_data is a string that cannot be parsed: {workout_data[:200]}")
                        workout_data = {}

                if not isinstance(workout_data, dict):
                    logger.error(f"workout_data is not a dict: type={type(workout_data).__name__}")
                    workout_data = {}

                exercises = workout_data.get("exercises", [])
                exercises = normalize_exercise_numeric_fields(exercises)

                workout_name = workout_data.get("name", "Generated Workout")
                workout_type = workout_data.get("type", body.workout_type or "strength")
                difficulty = workout_data.get("difficulty", intensity_preference)
                workout_description = workout_data.get("description")
                estimated_duration = workout_data.get("estimated_duration_minutes")
                if estimated_duration is not None:
                    estimated_duration = int(estimated_duration)
                else:
                    # Calculate fallback duration from exercises if Gemini didn't provide one
                    # Formula: SUM(sets × (reps × 3s + rest_seconds)) / 60 + (exercises × 30s transitions) / 60
                    fallback_duration = 0
                    for ex in exercises:
                        sets = ex.get("sets", 3)
                        reps = ex.get("reps", 10)
                        rest = ex.get("rest_seconds", 60)
                        # Time per set: reps × 3s (avg rep time) + rest
                        time_per_set = (reps * 3) + rest
                        exercise_time = sets * time_per_set
                        fallback_duration += exercise_time
                    # Add 30s per exercise for transitions and convert to minutes
                    fallback_duration = (fallback_duration + len(exercises) * 30) / 60
                    estimated_duration = max(10, int(fallback_duration))  # Minimum 10 minutes
                    logger.debug(f"⏱️ [Streaming Duration] Calculated fallback duration: {estimated_duration} min (Gemini didn't provide one)")

                # DURATION VALIDATION: Check if estimated duration is within range
                # If exceeded, we could auto-truncate exercises to fit (future enhancement)
                if estimated_duration and body.duration_minutes_max:
                    if estimated_duration > body.duration_minutes_max:
                        logger.warning(f"⚠️ [Streaming Duration] Estimated duration {estimated_duration} min exceeds max {body.duration_minutes_max} min")
                        # OPTION 1 (Current): Log warning but allow it - Gemini should learn from this
                        # OPTION 2 (Future): Auto-truncate exercises to fit duration
                        # exercises = truncate_exercises_to_duration(exercises, body.duration_minutes_max)
                        # OPTION 3 (Future): Regenerate with stricter prompt (requires retry loop)
                    else:
                        logger.debug(f"✅ [Streaming Duration] Estimated {estimated_duration} min is within range {body.duration_minutes_min or 0}-{body.duration_minutes_max} min")
                elif estimated_duration:
                    logger.debug(f"⏱️ [Streaming Duration] Estimated duration: {estimated_duration} min")

                # POST-GENERATION VALIDATION: Filter out any exercises that violate user preferences
                if avoided_exercises:
                    original_count = len(exercises)
                    exercises = [
                        ex for ex in exercises
                        if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
                    ]
                    filtered_count = original_count - len(exercises)
                    if filtered_count > 0:
                        logger.warning(f"⚠️ [Streaming Validation] Filtered out {filtered_count} avoided exercises")

                if avoided_muscles and avoided_muscles.get("avoid"):
                    original_count = len(exercises)
                    avoid_muscles_lower = [m.lower() for m in avoided_muscles["avoid"]]
                    exercises = [
                        ex for ex in exercises
                        if ex.get("muscle_group", "").lower() not in avoid_muscles_lower
                    ]
                    filtered_count = original_count - len(exercises)
                    if filtered_count > 0:
                        logger.warning(f"⚠️ [Streaming Validation] Filtered out {filtered_count} exercises targeting avoided muscles")

                # Handle "reduce" muscles - limit to max 1 exercise per reduced muscle
                if avoided_muscles and avoided_muscles.get("reduce"):
                    reduce_muscles_lower = [m.lower() for m in avoided_muscles["reduce"]]
                    reduced_seen = set()
                    new_exercises = []
                    removed_count = 0

                    for ex in exercises:
                        muscle = ex.get("muscle_group", "").lower()
                        if muscle in reduce_muscles_lower:
                            if muscle not in reduced_seen:
                                reduced_seen.add(muscle)
                                new_exercises.append(ex)
                            else:
                                removed_count += 1
                        else:
                            new_exercises.append(ex)

                    if removed_count > 0:
                        logger.info(f"🎯 [Streaming Validation] Limited {removed_count} exercises targeting reduced muscles")
                        exercises = new_exercises

                # Update workout_data with filtered exercises
                workout_data["exercises"] = exercises

                # Apply 1RM-based weights for personalized weight recommendations
                # This ensures weights are based on user's actual strength data
                one_rm_data = await get_user_1rm_data(body.user_id)
                training_intensity = await get_user_training_intensity(body.user_id)
                intensity_overrides = await get_user_intensity_overrides(body.user_id)

                if one_rm_data and exercises:
                    exercises = apply_1rm_weights_to_exercises(
                        exercises, one_rm_data, training_intensity, intensity_overrides
                    )
                    logger.info(f"💪 [Streaming] Applied 1RM-based weights to exercises")

                # CRITICAL SAFETY NET: Validate and cap exercise parameters
                # This prevents extreme workouts like 90 squats from reaching users
                user_age = user.get("age") if user else None
                comeback_status = await get_user_comeback_status(body.user_id)
                is_comeback = comeback_status.get("in_comeback_mode", False)
                if getattr(body, 'skip_comeback', None):
                    is_comeback = False

                if exercises:
                    exercises = validate_and_cap_exercise_parameters(
                        exercises=exercises,
                        fitness_level=fitness_level or "intermediate",
                        age=user_age,
                        is_comeback=is_comeback,
                        difficulty=intensity_preference
                    )
                    logger.info(f"🛡️ [Streaming Safety] Validated exercise parameters (fitness={fitness_level}, age={user_age}, comeback={is_comeback}, difficulty={intensity_preference})")

                # FOCUS AREA VALIDATION: Ensure exercises match the workout focus
                # This catches AI hallucinations where exercise names don't match the workout type
                MIN_EXERCISES_REQUIRED = 3  # Minimum exercises per workout

                # Get focus areas from request body
                focus_areas = body.focus_areas if hasattr(body, 'focus_areas') and body.focus_areas else []

                if focus_areas and len(focus_areas) > 0 and exercises:
                    primary_focus = focus_areas[0]
                    focus_validation = await validate_and_filter_focus_mismatches(
                        exercises=exercises,
                        focus_area=primary_focus,
                        workout_name=workout_name,
                    )

                    if focus_validation["mismatch_count"] > 0:
                        logger.warning(
                            f"🚨 [Streaming Focus Validation] Found {focus_validation['mismatch_count']} mismatched exercises "
                            f"in '{workout_name}' for focus '{primary_focus}'. "
                            f"Mismatched: {[ex.get('name') for ex in focus_validation['mismatched_exercises']]}"
                        )

                        valid_exercises = focus_validation["valid_exercises"]

                        # If we have enough valid exercises, use only those
                        if len(valid_exercises) >= MIN_EXERCISES_REQUIRED:
                            logger.info(
                                f"✅ [Streaming Focus Validation] Filtering to {len(valid_exercises)} valid exercises "
                                f"(removed {focus_validation['mismatch_count']} mismatched)"
                            )
                            exercises = valid_exercises
                        else:
                            # Not enough valid exercises - keep all but log critical error
                            logger.error(
                                f"❌ [Streaming Focus Validation] CRITICAL: Workout '{workout_name}' has only "
                                f"{len(valid_exercises)} valid exercises for '{primary_focus}' focus "
                                f"(minimum required: {MIN_EXERCISES_REQUIRED}). "
                                f"Keeping all {len(exercises)} exercises to meet minimum."
                            )

                # MINIMUM EXERCISE COUNT VALIDATION
                if len(exercises) < MIN_EXERCISES_REQUIRED:
                    logger.error(
                        f"❌ [Streaming Exercise Count] Workout '{workout_name}' has only {len(exercises)} exercises "
                        f"(minimum required: {MIN_EXERCISES_REQUIRED}). This is an AI generation error."
                    )

                # CRITICAL: Validate set_targets - FAIL if missing (no fallback)
                user_context = {
                    "user_id": body.user_id,
                    "fitness_level": fitness_level,
                    "difficulty": difficulty,
                    "goals": goals if isinstance(goals, list) else [],
                    "equipment": equipment if isinstance(equipment, list) else [],
                }
                exercises = validate_set_targets_strict(exercises, user_context)

            except json.JSONDecodeError as e:
                logger.error(f"❌ Failed to parse streaming response: {e}")
                logger.error(f"❌ Raw accumulated text ({len(accumulated_text)} chars): {accumulated_text[:1000]}")
                logger.error(f"❌ Cleaned content for parsing ({len(content)} chars): {content[:1000]}")

                # Check if response was truncated (incomplete JSON)
                if content and (content.rstrip().endswith((',', '{', '[', ':')) or
                               not content.rstrip().endswith(('}', ']'))):
                    logger.error(f"❌ Detected truncated response - Gemini stream ended prematurely")
                    yield f"event: error\ndata: {json.dumps({'error': 'Workout generation was interrupted. Please try again.', 'raw_length': len(accumulated_text), 'truncated': True})}\n\n"
                else:
                    yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data', 'raw_length': len(accumulated_text)})}\n\n"
                return

            # Determine scheduled date - use provided date or default to today
            if body.scheduled_date:
                # Parse and validate the provided date
                try:
                    scheduled_dt = datetime.strptime(body.scheduled_date, "%Y-%m-%d")
                    scheduled_date_str = scheduled_dt.isoformat()
                    logger.info(f"📅 [Streaming] Using provided scheduled_date: {body.scheduled_date}")
                except ValueError:
                    logger.warning(f"⚠️ Invalid scheduled_date format: {body.scheduled_date}, using today")
                    scheduled_date_str = datetime.now().isoformat()
            else:
                scheduled_date_str = datetime.now().isoformat()

            # Save to database
            workout_db_data = {
                "user_id": body.user_id,
                "gym_profile_id": gym_profile_id,  # Link workout to gym profile
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "description": workout_description,
                "scheduled_date": scheduled_date_str,
                "exercises_json": exercises,
                "duration_minutes": body.duration_minutes or 45,
                "duration_minutes_min": body.duration_minutes_min,
                "duration_minutes_max": body.duration_minutes_max,
                "estimated_duration_minutes": estimated_duration,
                "generation_method": "ai",
                "generation_source": "streaming_generation",
            }

            created = db.create_workout(workout_db_data)
            total_time_ms = (datetime.now() - start_time).total_seconds() * 1000

            logger.info(f"✅ Streaming workout complete: {len(exercises)} exercises in {total_time_ms:.0f}ms, gym_profile_id={gym_profile_id}")

            # Log the change
            log_workout_change(
                workout_id=created['id'],
                user_id=body.user_id,
                change_type="generated",
                change_source="streaming_generation",
                new_value={"name": workout_name, "exercises_count": len(exercises)}
            )

            # Convert to Workout model
            generated_workout = row_to_workout(created)

            # Index to RAG asynchronously (don't wait)
            asyncio.create_task(index_workout_to_rag(generated_workout))

            # Send final complete response
            # Parse exercises from exercises_json (which is a string)
            exercises_list = json.loads(generated_workout.exercises_json) if generated_workout.exercises_json else []

            workout_response = {
                "id": generated_workout.id,
                "user_id": generated_workout.user_id,
                "name": generated_workout.name,
                "type": generated_workout.type,
                "difficulty": generated_workout.difficulty,
                "description": generated_workout.description,
                "scheduled_date": generated_workout.scheduled_date.isoformat() if generated_workout.scheduled_date else None,
                "exercises": exercises_list,
                "exercises_json": generated_workout.exercises_json,
                "duration_minutes": generated_workout.duration_minutes,
                "total_time_ms": total_time_ms,
                "chunk_count": chunk_count,
                "comeback_detected": comeback_status.get("in_comeback_mode", False),
                "days_since_last_workout": comeback_status.get("days_since_last_workout"),
            }

            # Track premium gate usage after successful streaming generation
            try:
                from core.premium_gate import track_premium_usage
                await track_premium_usage(body.user_id, "ai_workout_generation")
            except Exception as usage_err:
                logger.warning(f"Failed to track workout generation usage: {usage_err}")

            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"❌ Streaming workout generation failed: {e}")
            yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Disable nginx buffering
        }
    )


# =============================================================================
# MOOD-BASED QUICK WORKOUT GENERATION
# =============================================================================

from pydantic import BaseModel, Field
from typing import Optional


class MoodWorkoutRequest(BaseModel):
    """Request model for mood-based workout generation."""
    user_id: str
    mood: str = Field(..., description="User mood: great, good, tired, or stressed")
    duration_minutes: Optional[int] = Field(default=None, ge=10, le=45)
    device: Optional[str] = None
    app_version: Optional[str] = None
    skip_comeback: Optional[bool] = Field(default=None, description="If True, skip comeback mode adjustments")


@router.post("/generate-from-mood-stream")
@limiter.limit("10/minute")
async def generate_mood_workout_streaming(request: Request, body: MoodWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a quick workout based on user's current mood.

    This endpoint provides fast workout generation tailored to how the user feels:
    - great: High intensity strength/HIIT (25-30 min)
    - good: Balanced mixed workout (20-25 min)
    - tired: Gentle recovery/mobility (15-20 min)
    - stressed: Stress-relief cardio/flow (20-25 min)

    Returns Server-Sent Events (SSE) with:
    - event: chunk - Progress updates during generation
    - event: done - Complete workout with mood check-in ID
    - event: error - Error message if generation fails
    """
    logger.info(f"🎯 Mood workout generation for user {body.user_id}, mood: {body.mood}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()
        mood_checkin_id = None

        try:
            # Validate mood
            try:
                mood = mood_workout_service.validate_mood(body.mood)
            except ValueError as e:
                yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"
                return

            db = get_supabase_db()

            # Get user data
            user = db.get_user(body.user_id)
            if not user:
                yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                return

            fitness_level = user.get("fitness_level", "intermediate")
            goals = user.get("goals", [])
            equipment = user.get("equipment", [])

            # Get mood workout parameters
            params = mood_workout_service.get_workout_params(
                mood=mood,
                user_fitness_level=fitness_level,
                user_goals=goals,
                user_equipment=equipment,
                duration_override=body.duration_minutes,
            )

            # Send initial acknowledgment
            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'mood': mood.value, 'mood_emoji': params['mood_emoji'], 'ttfb_ms': first_chunk_time})}\n\n"

            # Log mood check-in to database
            try:
                context = mood_workout_service.get_context_data(
                    device=body.device,
                    app_version=body.app_version,
                )
                checkin_result = db.client.table("mood_checkins").insert({
                    "user_id": body.user_id,
                    "mood": mood.value,
                    "workout_generated": False,
                    "context": context,
                }).execute()

                if checkin_result.data:
                    mood_checkin_id = checkin_result.data[0]["id"]
                    logger.info(f"✅ Mood check-in created: {mood_checkin_id}")

            except Exception as e:
                logger.warning(f"⚠️ Failed to log mood check-in: {e}")

            # Build the prompt
            prompt = mood_workout_service.build_generation_prompt(
                mood=mood,
                user_fitness_level=fitness_level,
                user_goals=goals,
                user_equipment=equipment,
                duration_minutes=params["duration_minutes"],
            )

            # Generate workout using NON-STREAMING for faster response
            # Mood workouts are small (~500 token prompt, ~6KB response)
            # Non-streaming is 3-5x faster than streaming for small responses
            yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'message': 'Creating your ' + mood.value + ' workout...'})}\n\n"

            from google.genai import types
            from core.config import get_settings
            from core.gemini_client import get_genai_client
            from models.gemini_schemas import GeneratedWorkoutResponse

            settings = get_settings()
            client = get_genai_client()

            try:
                # Use non-streaming for faster response (3-5s vs 19s with streaming)
                gemini_start = datetime.now()
                response = await client.aio.models.generate_content(
                    model=settings.gemini_model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=GeneratedWorkoutResponse,
                        temperature=0.7,
                        max_output_tokens=4096,  # Mood workouts are smaller
                    ),
                )
                gemini_time_ms = (datetime.now() - gemini_start).total_seconds() * 1000
                logger.info(f"⚡ [Mood Workout] Gemini non-streaming completed in {gemini_time_ms:.0f}ms")

                content = response.text.strip() if response.text else ""
                if not content:
                    raise ValueError("Empty response from Gemini")

                workout_data = json.loads(content)

                # Ensure workout_data is a dict (guard against Gemini returning a string)
                if isinstance(workout_data, str):
                    try:
                        workout_data = json.loads(workout_data)
                    except (json.JSONDecodeError, ValueError):
                        workout_data = {}
                if not isinstance(workout_data, dict):
                    workout_data = {}
            except Exception as gemini_error:
                logger.error(f"❌ [Mood Workout] Gemini error: {gemini_error}")
                yield f"event: error\ndata: {json.dumps({'error': f'Failed to generate workout: {str(gemini_error)}'})}\n\n"
                return

            # Parse the response
            try:
                exercises = workout_data.get("exercises", [])
                exercises = normalize_exercise_numeric_fields(exercises)

                # Generate warmup and cooldown using dictionary-based algorithm (not Gemini)
                # This provides consistent exercise names that match our database
                warmup_stretch_svc = get_warmup_stretch_service()

                # Get user injuries for injury-aware warmup/cooldown selection
                user_injuries = user.get("injuries", []) if user else []
                if isinstance(user_injuries, str):
                    user_injuries = [user_injuries] if user_injuries else []

                # Determine training split from mood/workout type
                training_split = "full_body"  # Default for mood workouts
                if params.get("workout_type_preference") == "cardio":
                    training_split = "cardio"
                elif params.get("workout_type_preference") == "strength":
                    training_split = "full_body"

                # Generate warmup using algorithm (instant, with video URLs)
                warmup = await warmup_stretch_svc.generate_warmup(
                    exercises=exercises,
                    duration_minutes=params.get("warmup_duration", 3),
                    injuries=user_injuries if user_injuries else None,
                    user_id=body.user_id,
                    training_split=training_split,
                )
                logger.info(f"🔥 [Mood Workout] Generated {len(warmup)} warmup exercises using algorithm")

                # Generate cooldown/stretches using algorithm (instant, with video URLs)
                cooldown = await warmup_stretch_svc.generate_stretches(
                    exercises=exercises,
                    duration_minutes=params.get("cooldown_duration", 2),
                    injuries=user_injuries if user_injuries else None,
                    user_id=body.user_id,
                    training_split=training_split,
                )
                logger.info(f"❄️ [Mood Workout] Generated {len(cooldown)} cooldown/stretch exercises using algorithm")

                workout_name = workout_data.get("name", f"{mood.value.capitalize()} Quick Workout")
                workout_type = workout_data.get("type", params["workout_type_preference"])
                difficulty = workout_data.get("difficulty", params["intensity_preference"])
                workout_description = workout_data.get("description")
                motivational_message = workout_data.get("motivational_message", "")

                # Apply 1RM-based weights for personalized weight recommendations
                # This ensures weights are based on user's actual strength data
                one_rm_data = await get_user_1rm_data(body.user_id)
                training_intensity = await get_user_training_intensity(body.user_id)
                intensity_overrides = await get_user_intensity_overrides(body.user_id)

                if one_rm_data and exercises:
                    exercises = apply_1rm_weights_to_exercises(
                        exercises, one_rm_data, training_intensity, intensity_overrides
                    )
                    logger.info(f"💪 [Mood Workout] Applied 1RM-based weights to exercises")

                # CRITICAL SAFETY NET: Validate and cap exercise parameters
                # This prevents extreme workouts like 90 squats from reaching users
                user_age = user.get("age") if user else None
                comeback_status = await get_user_comeback_status(body.user_id)
                is_comeback = comeback_status.get("in_comeback_mode", False)
                if getattr(body, 'skip_comeback', None):
                    is_comeback = False

                if exercises:
                    exercises = validate_and_cap_exercise_parameters(
                        exercises=exercises,
                        fitness_level=fitness_level or "intermediate",
                        age=user_age,
                        is_comeback=is_comeback,
                        difficulty=params["intensity_preference"]
                    )
                    logger.info(f"🛡️ [Mood Safety] Validated exercise parameters (fitness={fitness_level}, age={user_age}, comeback={is_comeback}, difficulty={params['intensity_preference']})")

                    # CRITICAL: Validate set_targets - FAIL if missing (no fallback)
                    user_context = {
                        "user_id": body.user_id,
                        "fitness_level": fitness_level,
                        "difficulty": difficulty,
                        "goals": goals if isinstance(goals, list) else [],
                        "equipment": equipment if isinstance(equipment, list) else [],
                        "mood": mood.value if mood else None,
                    }
                    exercises = validate_set_targets_strict(exercises, user_context)

            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse mood workout response: {e}")
                yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data'})}\n\n"
                return

            # Save workout to database
            workout_db_data = {
                "user_id": body.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "description": workout_description,
                "scheduled_date": params.get("scheduled_date") or datetime.now().isoformat(),
                "exercises_json": exercises,
                "duration_minutes": params["duration_minutes"],
                "generation_method": "ai",
                "generation_source": "mood_generation",
                "generation_metadata": {
                    "mood": mood.value,
                    "mood_checkin_id": mood_checkin_id,
                    "warmup": warmup,
                    "cooldown": cooldown,
                    "motivational_message": motivational_message,
                },
            }

            created = db.create_workout(workout_db_data)
            workout_id = created["id"]
            total_time_ms = (datetime.now() - start_time).total_seconds() * 1000

            logger.info(f"✅ Mood workout complete: {len(exercises)} exercises in {total_time_ms:.0f}ms")

            # Update mood check-in with workout reference
            if mood_checkin_id:
                try:
                    db.client.table("mood_checkins").update({
                        "workout_generated": True,
                        "workout_id": workout_id,
                    }).eq("id", mood_checkin_id).execute()
                except Exception as e:
                    logger.warning(f"⚠️ Failed to update mood check-in: {e}")

            # Log the change
            log_workout_change(
                workout_id=workout_id,
                user_id=body.user_id,
                change_type="generated",
                change_source="mood_generation",
                new_value={
                    "name": workout_name,
                    "exercises_count": len(exercises),
                    "mood": mood.value,
                }
            )

            # Log to user context
            try:
                await user_context_service.log_mood_checkin(
                    user_id=body.user_id,
                    mood=mood.value,
                    workout_generated=True,
                    workout_id=workout_id,
                    device=body.device,
                    app_version=body.app_version,
                )
            except Exception as e:
                logger.warning(f"⚠️ Failed to log context: {e}")

            # Build final response
            generated_workout = row_to_workout(created)

            workout_response = {
                "id": generated_workout.id,
                "user_id": generated_workout.user_id,
                "name": generated_workout.name,
                "type": generated_workout.type,
                "difficulty": generated_workout.difficulty,
                "scheduled_date": generated_workout.scheduled_date.isoformat() if generated_workout.scheduled_date else None,
                "exercises": exercises,
                "warmup": warmup,
                "cooldown": cooldown,
                "duration_minutes": params["duration_minutes"],
                "total_time_ms": total_time_ms,
                "gemini_time_ms": gemini_time_ms,  # Track Gemini API time
                "mood": mood.value,
                "mood_emoji": params["mood_emoji"],
                "mood_color": params["mood_color"],
                "mood_checkin_id": mood_checkin_id,
                "motivational_message": motivational_message,
                "comeback_detected": comeback_status.get("in_comeback_mode", False),
                "days_since_last_workout": comeback_status.get("days_since_last_workout"),
            }

            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"❌ Mood workout generation failed: {e}")
            yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


@router.get("/moods")
async def get_available_moods(
    current_user: dict = Depends(get_current_user),
):
    """Get all available mood options with display info."""
    return {
        "moods": mood_workout_service.get_all_moods(),
    }


# ============================================================================
# MOOD HISTORY & ANALYTICS ENDPOINTS
# ============================================================================


class MoodHistoryResponse(BaseModel):
    """Response model for mood history."""
    checkins: List[Dict[str, Any]]
    total_count: int
    has_more: bool


class MoodAnalyticsResponse(BaseModel):
    """Response model for mood analytics."""
    summary: Dict[str, Any]
    patterns: List[Dict[str, Any]]
    streaks: Dict[str, Any]
    recommendations: List[str]


class MoodDayEntry(BaseModel):
    """Single mood entry within a day."""
    mood: str
    emoji: str
    color: str
    time: str


class MoodDayData(BaseModel):
    """Mood data for a single day."""
    date: str
    day_name: str
    moods: List[MoodDayEntry]
    primary_mood: Optional[str] = None
    checkin_count: int
    workout_completed: bool


class MoodWeeklySummary(BaseModel):
    """Summary stats for weekly mood data."""
    total_checkins: int
    avg_mood_score: float
    trend: str  # "improving", "declining", "stable"


class MoodWeeklyResponse(BaseModel):
    """Response model for weekly mood data."""
    days: List[MoodDayData]
    summary: MoodWeeklySummary


class MoodCalendarDay(BaseModel):
    """Mood data for a single calendar day."""
    moods: List[str]
    primary_mood: str
    color: str
    checkin_count: int


class MoodCalendarSummary(BaseModel):
    """Summary stats for calendar mood data."""
    days_with_checkins: int
    total_checkins: int
    most_common_mood: Optional[str] = None


class MoodCalendarResponse(BaseModel):
    """Response model for monthly mood calendar data."""
    month: int
    year: int
    days: Dict[str, Optional[MoodCalendarDay]]
    summary: MoodCalendarSummary


@router.get("/{user_id}/mood-history", response_model=MoodHistoryResponse)
async def get_mood_history(
    user_id: str,
    limit: int = 30,
    offset: int = 0,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's mood check-in history.

    Returns a list of mood check-ins with workout information.
    Supports pagination and date filtering.
    """
    logger.info(f"Fetching mood history for user {user_id}")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("mood_checkins") \
            .select("*, workouts(id, name, type, difficulty, completed)") \
            .eq("user_id", user_id) \
            .order("check_in_time", desc=True)

        # Apply date filters if provided
        if start_date:
            query = query.gte("check_in_time", start_date)
        if end_date:
            query = query.lte("check_in_time", end_date)

        # Get total count first
        count_result = db.client.table("mood_checkins") \
            .select("*", count="exact") \
            .eq("user_id", user_id)

        if start_date:
            count_result = count_result.gte("check_in_time", start_date)
        if end_date:
            count_result = count_result.lte("check_in_time", end_date)

        count_response = count_result.execute()
        total_count = count_response.count if count_response.count else 0

        # Apply pagination
        query = query.range(offset, offset + limit - 1)

        result = query.execute()

        checkins = []
        for row in result.data or []:
            # Get mood config for display info
            mood_type = row.get("mood", "good")
            config = mood_workout_service.get_mood_config(
                mood_workout_service.validate_mood(mood_type)
            )

            workout_data = row.get("workouts")

            checkins.append({
                "id": row.get("id"),
                "mood": mood_type,
                "mood_emoji": config.emoji,
                "mood_color": config.color_hex,
                "check_in_time": row.get("check_in_time"),
                "workout_generated": row.get("workout_generated", False),
                "workout_completed": row.get("workout_completed", False),
                "workout": {
                    "id": workout_data.get("id"),
                    "name": workout_data.get("name"),
                    "type": workout_data.get("type"),
                    "difficulty": workout_data.get("difficulty"),
                    "completed": workout_data.get("completed"),
                } if workout_data else None,
                "context": row.get("context", {}),
            })

        return MoodHistoryResponse(
            checkins=checkins,
            total_count=total_count,
            has_more=(offset + limit) < total_count,
        )

    except Exception as e:
        logger.error(f"Failed to get mood history: {e}")
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-analytics", response_model=MoodAnalyticsResponse)
async def get_mood_analytics(
    user_id: str,
    days: int = 30,
    current_user: dict = Depends(get_current_user),
):
    """
    Get mood analytics and patterns for a user.

    Returns:
    - Summary: Total check-ins, most frequent mood, completion rate
    - Patterns: Mood distribution by time of day, day of week
    - Streaks: Current streak, longest streak
    - Recommendations: AI-generated suggestions based on patterns
    """
    logger.info(f"Fetching mood analytics for user {user_id}, last {days} days")

    try:
        db = get_supabase_db()

        # Calculate date range
        from datetime import timedelta
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # Fetch all check-ins in date range
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("check_in_time", start_date.isoformat()) \
            .lte("check_in_time", end_date.isoformat()) \
            .order("check_in_time", desc=True) \
            .execute()

        checkins = result.data or []
        total_count = len(checkins)

        if total_count == 0:
            return MoodAnalyticsResponse(
                summary={
                    "total_checkins": 0,
                    "workouts_generated": 0,
                    "workouts_completed": 0,
                    "completion_rate": 0,
                    "most_frequent_mood": None,
                    "days_tracked": days,
                },
                patterns=[],
                streaks={
                    "current_streak": 0,
                    "longest_streak": 0,
                    "last_checkin": None,
                },
                recommendations=[
                    "Start tracking your mood to get personalized insights!",
                    "Check in daily to see how your mood affects your workouts.",
                ],
            )

        # Calculate mood distribution
        mood_counts = {"great": 0, "good": 0, "tired": 0, "stressed": 0}
        workouts_generated = 0
        workouts_completed = 0
        time_of_day_moods = {"morning": {}, "afternoon": {}, "evening": {}, "night": {}}
        day_of_week_moods = {
            "monday": {}, "tuesday": {}, "wednesday": {},
            "thursday": {}, "friday": {}, "saturday": {}, "sunday": {}
        }

        for checkin in checkins:
            mood = checkin.get("mood", "good")
            mood_counts[mood] = mood_counts.get(mood, 0) + 1

            if checkin.get("workout_generated"):
                workouts_generated += 1
            if checkin.get("workout_completed"):
                workouts_completed += 1

            # Parse context for patterns
            context = checkin.get("context", {})
            time_of_day = context.get("time_of_day", "afternoon")
            day_of_week = context.get("day_of_week", "monday")

            if time_of_day in time_of_day_moods:
                time_of_day_moods[time_of_day][mood] = time_of_day_moods[time_of_day].get(mood, 0) + 1

            if day_of_week in day_of_week_moods:
                day_of_week_moods[day_of_week][mood] = day_of_week_moods[day_of_week].get(mood, 0) + 1

        # Find most frequent mood
        most_frequent_mood = max(mood_counts, key=mood_counts.get)
        most_frequent_config = mood_workout_service.get_mood_config(
            mood_workout_service.validate_mood(most_frequent_mood)
        )

        # Calculate streaks
        from datetime import date as date_type
        checkin_dates = set()
        for checkin in checkins:
            check_in_time = checkin.get("check_in_time", "")
            if check_in_time:
                try:
                    dt = datetime.fromisoformat(check_in_time.replace("Z", "+00:00"))
                    checkin_dates.add(dt.date())
                except (ValueError, AttributeError) as e:
                    logger.debug(f"Failed to parse check-in date: {e}")

        sorted_dates = sorted(checkin_dates, reverse=True)

        current_streak = 0
        longest_streak = 0
        temp_streak = 0
        today = date_type.today()

        if sorted_dates:
            # Calculate current streak
            expected_date = today
            for d in sorted_dates:
                if d == expected_date or d == expected_date - timedelta(days=1):
                    current_streak += 1
                    expected_date = d - timedelta(days=1)
                else:
                    break

            # Calculate longest streak
            prev_date = None
            for d in sorted(checkin_dates):
                if prev_date is None or (d - prev_date).days == 1:
                    temp_streak += 1
                else:
                    longest_streak = max(longest_streak, temp_streak)
                    temp_streak = 1
                prev_date = d
            longest_streak = max(longest_streak, temp_streak)

        # Build patterns list
        patterns = []

        # Mood distribution pattern
        patterns.append({
            "type": "mood_distribution",
            "title": "Your Mood Distribution",
            "data": [
                {
                    "mood": mood,
                    "count": count,
                    "percentage": round((count / total_count) * 100, 1) if total_count > 0 else 0,
                    "emoji": mood_workout_service.get_mood_config(
                        mood_workout_service.validate_mood(mood)
                    ).emoji,
                }
                for mood, count in mood_counts.items()
            ],
        })

        # Time of day pattern
        patterns.append({
            "type": "time_of_day",
            "title": "Mood by Time of Day",
            "data": [
                {
                    "time_of_day": tod,
                    "moods": moods,
                    "dominant_mood": max(moods, key=moods.get) if moods else None,
                }
                for tod, moods in time_of_day_moods.items()
            ],
        })

        # Day of week pattern
        patterns.append({
            "type": "day_of_week",
            "title": "Mood by Day of Week",
            "data": [
                {
                    "day": dow,
                    "moods": moods,
                    "dominant_mood": max(moods, key=moods.get) if moods else None,
                }
                for dow, moods in day_of_week_moods.items()
            ],
        })

        # Generate recommendations
        recommendations = []

        completion_rate = (workouts_completed / workouts_generated * 100) if workouts_generated > 0 else 0

        if completion_rate < 50 and workouts_generated > 3:
            recommendations.append(
                "Try shorter workouts when you're feeling tired or stressed - you're more likely to complete them!"
            )

        if mood_counts.get("tired", 0) > total_count * 0.4:
            recommendations.append(
                "You've been feeling tired frequently. Consider adjusting your sleep schedule or trying recovery workouts."
            )

        if mood_counts.get("stressed", 0) > total_count * 0.3:
            recommendations.append(
                "Stress has been high lately. Our stress-relief workouts include breathing exercises and flow movements."
            )

        if mood_counts.get("great", 0) > total_count * 0.5:
            recommendations.append(
                "You're often feeling great! Consider trying more challenging workouts to push your limits."
            )

        if current_streak >= 7:
            recommendations.append(
                f"Amazing! You're on a {current_streak}-day streak. Keep it up!"
            )
        elif current_streak == 0:
            recommendations.append(
                "Check in with your mood today and get a personalized workout suggestion!"
            )

        return MoodAnalyticsResponse(
            summary={
                "total_checkins": total_count,
                "workouts_generated": workouts_generated,
                "workouts_completed": workouts_completed,
                "completion_rate": round(completion_rate, 1),
                "most_frequent_mood": {
                    "mood": most_frequent_mood,
                    "emoji": most_frequent_config.emoji,
                    "color": most_frequent_config.color_hex,
                    "count": mood_counts[most_frequent_mood],
                },
                "days_tracked": days,
            },
            patterns=patterns,
            streaks={
                "current_streak": current_streak,
                "longest_streak": longest_streak,
                "last_checkin": checkins[0].get("check_in_time") if checkins else None,
            },
            recommendations=recommendations,
        )

    except Exception as e:
        logger.error(f"Failed to get mood analytics: {e}")
        raise safe_internal_error(e, "generation")


@router.put("/{user_id}/mood-checkins/{checkin_id}/complete")
async def mark_mood_workout_completed(user_id: str, checkin_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Mark a mood check-in's workout as completed."""
    logger.info(f"Marking mood workout completed: user={user_id}, checkin={checkin_id}")

    try:
        db = get_supabase_db()

        # Verify check-in belongs to user
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("id", checkin_id) \
            .eq("user_id", user_id) \
            .single() \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Mood check-in not found")

        # Update completion status
        db.client.table("mood_checkins") \
            .update({"workout_completed": True}) \
            .eq("id", checkin_id) \
            .execute()

        return {"success": True, "message": "Workout marked as completed"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to mark mood workout completed: {e}")
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-today")
async def get_today_mood(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get user's mood check-in for today (if any)."""
    logger.info(f"Fetching today's mood for user {user_id}")

    try:
        db = get_supabase_db()

        # Query today's check-in using the view
        result = db.client.table("today_mood_checkin") \
            .select("*") \
            .eq("user_id", user_id) \
            .execute()

        if result.data and len(result.data) > 0:
            checkin = result.data[0]
            mood_type = checkin.get("mood", "good")
            config = mood_workout_service.get_mood_config(
                mood_workout_service.validate_mood(mood_type)
            )

            return {
                "has_checkin": True,
                "checkin": {
                    "id": checkin.get("id"),
                    "mood": mood_type,
                    "mood_emoji": config.emoji,
                    "mood_color": config.color_hex,
                    "check_in_time": checkin.get("check_in_time"),
                    "workout_generated": checkin.get("workout_generated", False),
                    "workout_completed": checkin.get("workout_completed", False),
                    "workout_id": checkin.get("workout_id"),
                },
            }

        return {
            "has_checkin": False,
            "checkin": None,
        }

    except Exception as e:
        logger.error(f"Failed to get today's mood: {e}")
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-weekly", response_model=MoodWeeklyResponse)
async def get_mood_weekly(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's mood data for the last 7 days.

    Returns daily mood check-ins with trend analysis for weekly chart visualization.
    """
    logger.info(f"Fetching weekly mood data for user {user_id}")

    try:
        db = get_supabase_db()

        # Calculate date range (last 7 days)
        today = datetime.now().date()
        week_ago = today - timedelta(days=6)  # Include today, so 7 days total

        # Fetch check-ins for the week
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("check_in_time", week_ago.isoformat()) \
            .lte("check_in_time", (today + timedelta(days=1)).isoformat()) \
            .order("check_in_time", desc=False) \
            .execute()

        checkins = result.data or []

        # Mood score mapping for trend calculation
        mood_scores = {"great": 4, "good": 3, "tired": 2, "stressed": 1}

        # Group check-ins by date
        days_data = {}
        for i in range(7):
            day = week_ago + timedelta(days=i)
            day_str = day.isoformat()
            days_data[day_str] = {
                "date": day_str,
                "day_name": day.strftime("%A"),
                "moods": [],
                "primary_mood": None,
                "checkin_count": 0,
                "workout_completed": False,
            }

        # Process check-ins
        total_score = 0
        total_checkins = 0
        first_half_scores = []
        second_half_scores = []

        for checkin in checkins:
            check_time = checkin.get("check_in_time", "")
            if not check_time:
                continue

            # Parse date
            if "T" in check_time:
                day_str = check_time.split("T")[0]
            else:
                day_str = check_time[:10]

            if day_str not in days_data:
                continue

            mood = checkin.get("mood", "good")
            config = mood_workout_service.get_mood_config(
                mood_workout_service.validate_mood(mood)
            )

            # Parse time for display
            try:
                time_part = check_time.split("T")[1][:5] if "T" in check_time else "00:00"
            except (IndexError, AttributeError):
                time_part = "00:00"

            days_data[day_str]["moods"].append({
                "mood": mood,
                "emoji": config.emoji,
                "color": config.color_hex,
                "time": time_part,
            })
            days_data[day_str]["checkin_count"] += 1

            if checkin.get("workout_completed"):
                days_data[day_str]["workout_completed"] = True

            # Track scores for trend
            score = mood_scores.get(mood, 2)
            total_score += score
            total_checkins += 1

            # Determine if first or second half of week
            day_index = (datetime.fromisoformat(day_str).date() - week_ago).days
            if day_index < 4:
                first_half_scores.append(score)
            else:
                second_half_scores.append(score)

        # Calculate primary mood for each day (most frequent)
        for day_str, day_data in days_data.items():
            if day_data["moods"]:
                mood_counts = {}
                for m in day_data["moods"]:
                    mood_counts[m["mood"]] = mood_counts.get(m["mood"], 0) + 1
                day_data["primary_mood"] = max(mood_counts, key=mood_counts.get)

        # Calculate trend
        avg_score = total_score / total_checkins if total_checkins > 0 else 0
        first_half_avg = sum(first_half_scores) / len(first_half_scores) if first_half_scores else 0
        second_half_avg = sum(second_half_scores) / len(second_half_scores) if second_half_scores else 0

        if second_half_avg > first_half_avg + 0.3:
            trend = "improving"
        elif second_half_avg < first_half_avg - 0.3:
            trend = "declining"
        else:
            trend = "stable"

        # Convert to list sorted by date
        days_list = [
            MoodDayData(
                date=d["date"],
                day_name=d["day_name"],
                moods=[MoodDayEntry(**m) for m in d["moods"]],
                primary_mood=d["primary_mood"],
                checkin_count=d["checkin_count"],
                workout_completed=d["workout_completed"],
            )
            for d in sorted(days_data.values(), key=lambda x: x["date"])
        ]

        return MoodWeeklyResponse(
            days=days_list,
            summary=MoodWeeklySummary(
                total_checkins=total_checkins,
                avg_mood_score=round(avg_score, 2),
                trend=trend,
            ),
        )

    except Exception as e:
        logger.error(f"Failed to get weekly mood data: {e}")
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-calendar", response_model=MoodCalendarResponse)
async def get_mood_calendar(user_id: str, month: int, year: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's mood data for a specific month.

    Returns mood check-ins organized by day for calendar heatmap visualization.
    """
    logger.info(f"Fetching mood calendar for user {user_id}, {year}-{month:02d}")

    try:
        db = get_supabase_db()

        # Validate month and year
        if month < 1 or month > 12:
            raise HTTPException(status_code=400, detail="Month must be between 1 and 12")
        if year < 2020 or year > 2100:
            raise HTTPException(status_code=400, detail="Invalid year")

        # Calculate date range for the month
        import calendar
        _, last_day = calendar.monthrange(year, month)
        start_date = f"{year}-{month:02d}-01"
        end_date = f"{year}-{month:02d}-{last_day}"

        # Fetch check-ins for the month
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("check_in_time", start_date) \
            .lte("check_in_time", f"{end_date}T23:59:59") \
            .order("check_in_time", desc=False) \
            .execute()

        checkins = result.data or []

        # Initialize days dict with all days of the month
        days_data: Dict[str, Optional[Dict]] = {}
        for day in range(1, last_day + 1):
            day_str = f"{year}-{month:02d}-{day:02d}"
            days_data[day_str] = None

        # Process check-ins
        day_checkins: Dict[str, List[str]] = {}  # date -> list of moods

        for checkin in checkins:
            check_time = checkin.get("check_in_time", "")
            if not check_time:
                continue

            # Parse date
            if "T" in check_time:
                day_str = check_time.split("T")[0]
            else:
                day_str = check_time[:10]

            if day_str not in days_data:
                continue

            mood = checkin.get("mood", "good")

            if day_str not in day_checkins:
                day_checkins[day_str] = []
            day_checkins[day_str].append(mood)

        # Calculate stats for each day with check-ins
        mood_counts_total: Dict[str, int] = {}
        days_with_checkins = 0
        total_checkins = 0

        for day_str, moods in day_checkins.items():
            if moods:
                days_with_checkins += 1
                total_checkins += len(moods)

                # Count moods for this day
                mood_counts = {}
                for m in moods:
                    mood_counts[m] = mood_counts.get(m, 0) + 1
                    mood_counts_total[m] = mood_counts_total.get(m, 0) + 1

                # Get primary mood (most frequent)
                primary_mood = max(mood_counts, key=mood_counts.get)
                config = mood_workout_service.get_mood_config(
                    mood_workout_service.validate_mood(primary_mood)
                )

                days_data[day_str] = {
                    "moods": moods,
                    "primary_mood": primary_mood,
                    "color": config.color_hex,
                    "checkin_count": len(moods),
                }

        # Convert to response format
        days_response: Dict[str, Optional[MoodCalendarDay]] = {}
        for day_str, data in days_data.items():
            if data:
                days_response[day_str] = MoodCalendarDay(**data)
            else:
                days_response[day_str] = None

        # Get most common mood
        most_common_mood = max(mood_counts_total, key=mood_counts_total.get) if mood_counts_total else None

        return MoodCalendarResponse(
            month=month,
            year=year,
            days=days_response,
            summary=MoodCalendarSummary(
                days_with_checkins=days_with_checkins,
                total_checkins=total_checkins,
                most_common_mood=most_common_mood,
            ),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get mood calendar data: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/swap")
async def swap_workout_date(request: SwapWorkoutsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Move a workout to a new date, swapping if another workout exists there."""
    logger.info(f"Swapping workout {request.workout_id} to {request.new_date}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        old_date = workout.get("scheduled_date")
        user_id = workout.get("user_id")

        # Check for existing workout on new date
        existing_workouts = db.get_workouts_by_date_range(user_id, request.new_date, request.new_date)

        if existing_workouts:
            existing = existing_workouts[0]
            db.update_workout(existing["id"], {"scheduled_date": old_date, "last_modified_method": "date_swap"})
            log_workout_change(existing["id"], user_id, "date_swap", "scheduled_date", request.new_date, old_date)

        db.update_workout(request.workout_id, {"scheduled_date": request.new_date, "last_modified_method": "date_swap"})
        log_workout_change(request.workout_id, user_id, "date_swap", "scheduled_date", old_date, request.new_date)

        return {"success": True, "old_date": old_date, "new_date": request.new_date}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap workout: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/swap-exercise", response_model=Workout)
async def swap_exercise_in_workout(request: SwapExerciseRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Swap an exercise within a workout with a new exercise from the library.

    This endpoint now considers secondary muscles when finding replacements
    and will warn if the swap significantly changes the muscle profile.
    """
    logger.info(f"Swapping exercise '{request.old_exercise_name}' with '{request.new_exercise_name}' in workout {request.workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Parse exercises
        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        # Get muscle profiles for both exercises to compare
        old_muscles = await get_all_muscles_for_exercise(request.old_exercise_name)
        new_muscles = await get_all_muscles_for_exercise(request.new_exercise_name)

        muscle_comparison = None
        muscle_profile_warning = None

        if old_muscles and new_muscles:
            muscle_comparison = compare_muscle_profiles(old_muscles, new_muscles)
            if muscle_comparison.get("warning"):
                muscle_profile_warning = muscle_comparison["warning"]
                logger.warning(
                    f"Exercise swap muscle profile warning: {muscle_profile_warning} "
                    f"(similarity: {muscle_comparison.get('similarity_score', 0):.0%})"
                )

        # Find and replace the exercise
        exercise_found = False
        for i, exercise in enumerate(exercises):
            if exercise.get("name", "").lower() == request.old_exercise_name.lower():
                exercise_found = True

                # Get new exercise details from library
                exercise_lib = get_exercise_library_service()
                new_exercise_data = exercise_lib.search_exercises(request.new_exercise_name, limit=1)

                if new_exercise_data:
                    new_ex = new_exercise_data[0]
                    # Preserve sets/reps from old exercise, update other fields
                    exercises[i] = {
                        **exercise,  # Keep original sets, reps, rest_seconds
                        "name": new_ex.get("name", request.new_exercise_name),
                        "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part") or exercise.get("muscle_group"),
                        "equipment": new_ex.get("equipment") or exercise.get("equipment"),
                        "notes": new_ex.get("instructions") or exercise.get("notes", ""),
                        "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                        "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                        "library_id": new_ex.get("id"),
                        # Add secondary muscles info for future reference
                        "secondary_muscles": new_ex.get("secondary_muscles", []),
                    }

                    # Add muscle profile warning if significant change detected
                    if muscle_profile_warning:
                        exercises[i]["muscle_profile_warning"] = muscle_profile_warning
                        exercises[i]["muscle_similarity_score"] = muscle_comparison.get("similarity_score", 1.0)
                else:
                    # Just update the name if exercise not found in library
                    exercises[i]["name"] = request.new_exercise_name
                break

        if not exercise_found:
            raise HTTPException(status_code=404, detail=f"Exercise '{request.old_exercise_name}' not found in workout")

        # Update the workout
        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_swap"
        }

        updated = db.update_workout(request.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        # Log the change with muscle profile info
        change_metadata = {
            "old_exercise": request.old_exercise_name,
            "new_exercise": request.new_exercise_name,
        }
        if muscle_comparison:
            change_metadata["muscle_profile"] = {
                "is_similar": muscle_comparison.get("is_similar", True),
                "similarity_score": muscle_comparison.get("similarity_score", 1.0),
                "warning": muscle_profile_warning,
            }

        log_workout_change(
            request.workout_id,
            workout.get("user_id"),
            "exercise_swap",
            "exercises_json",
            request.old_exercise_name,
            request.new_exercise_name
        )

        # Log the swap to exercise_swaps table for analytics & AI learning
        try:
            db.client.table("exercise_swaps").insert({
                "user_id": workout.get("user_id"),
                "workout_id": request.workout_id,
                "original_exercise": request.old_exercise_name,
                "new_exercise": request.new_exercise_name,
                "swap_reason": request.reason,
                "swap_source": request.swap_source or "ai_suggestion",
                "exercise_index": i,
                "workout_phase": "main",
            }).execute()
            logger.info(f"Logged swap to exercise_swaps: {request.old_exercise_name} -> {request.new_exercise_name}")
        except Exception as e:
            logger.warning(f"Failed to log swap to exercise_swaps: {e}")
            # Don't fail the swap if logging fails

        updated_workout = row_to_workout(updated)

        # Log detailed swap info
        if muscle_profile_warning:
            logger.info(
                f"Exercise swapped in workout {request.workout_id} with warning: {muscle_profile_warning}"
            )
        else:
            logger.info(f"Exercise swapped successfully in workout {request.workout_id}")

        # Re-index to RAG in background (non-critical, don't block response)
        async def _bg_index():
            try:
                await index_workout_to_rag(updated_workout)
            except Exception as e:
                logger.warning(f"Background: Failed to index swapped workout to RAG: {e}")

        background_tasks.add_task(_bg_index)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap exercise: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/add-exercise", response_model=Workout)
async def add_exercise_to_workout(request: AddExerciseRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Add a new exercise to an existing workout."""
    section = request.section or "main"
    logger.info(f"Adding exercise '{request.exercise_name}' to workout {request.workout_id} (section: {section})")
    try:
        db = get_supabase_db()

        # Get the workout (always needed for response)
        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get exercise details from library (shared for all sections)
        exercise_lib = get_exercise_library_service()
        exercise_data = exercise_lib.search_exercises(request.exercise_name, limit=1)

        exercise_name = request.exercise_name
        muscle_group = None
        if exercise_data:
            ex_info = exercise_data[0]
            exercise_name = ex_info.get("name", request.exercise_name)
            muscle_group = ex_info.get("target_muscle") or ex_info.get("body_part")

        if section == "main":
            # Existing behavior: add to main workout exercises
            exercises_json = workout.get("exercises_json", "[]")
            if isinstance(exercises_json, str):
                exercises = json.loads(exercises_json)
            else:
                exercises = exercises_json

            if exercise_data:
                new_ex = exercise_data[0]
                new_exercise = {
                    "name": new_ex.get("name", request.exercise_name),
                    "sets": request.sets,
                    "reps": request.reps,
                    "rest_seconds": request.rest_seconds,
                    "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part"),
                    "equipment": new_ex.get("equipment"),
                    "notes": new_ex.get("instructions", ""),
                    "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                    "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                    "library_id": new_ex.get("id"),
                }
            else:
                new_exercise = {
                    "name": request.exercise_name,
                    "sets": request.sets,
                    "reps": request.reps,
                    "rest_seconds": request.rest_seconds,
                }

            exercises.append(new_exercise)

            update_data = {
                "exercises_json": json.dumps(exercises),
                "last_modified_at": datetime.now().isoformat(),
                "last_modified_method": "exercise_add"
            }

            updated = db.update_workout(request.workout_id, update_data)
            if not updated:
                raise HTTPException(status_code=500, detail="Failed to update workout")

            log_workout_change(
                request.workout_id,
                workout.get("user_id"),
                "exercise_add",
                "exercises_json",
                None,
                request.exercise_name
            )

            updated_workout = row_to_workout(updated)
            logger.info(f"Exercise '{request.exercise_name}' added successfully to workout {request.workout_id} (main)")

            async def _bg_index():
                try:
                    await index_workout_to_rag(updated_workout)
                except Exception as e:
                    logger.warning(f"Background: Failed to index workout to RAG after exercise add: {e}")

            background_tasks.add_task(_bg_index)

            return updated_workout

        elif section == "warmup":
            new_warmup_exercise = {
                "name": exercise_name,
                "sets": 1,
                "reps": None,
                "duration_seconds": 30,
                "rest_seconds": 10,
                "equipment": "none",
                "muscle_group": muscle_group or "general",
                "notes": None
            }

            # Query existing warmup for this workout
            warmup_result = db.client.table("warmups").select("*").eq(
                "workout_id", request.workout_id
            ).eq("is_current", True).execute()

            if warmup_result.data:
                warmup_row = warmup_result.data[0]
                existing_exercises = warmup_row.get("exercises_json", "[]")
                if isinstance(existing_exercises, str):
                    warmup_exercises = json.loads(existing_exercises)
                else:
                    warmup_exercises = existing_exercises or []

                warmup_exercises.append(new_warmup_exercise)

                db.client.table("warmups").update({
                    "exercises_json": json.dumps(warmup_exercises),
                    "updated_at": datetime.now().isoformat(),
                }).eq("id", warmup_row["id"]).execute()

                logger.info(f"Exercise '{exercise_name}' added to existing warmup for workout {request.workout_id}")
            else:
                # Insert a new warmup row
                new_warmup_id = str(uuid.uuid4())
                db.client.table("warmups").insert({
                    "id": new_warmup_id,
                    "workout_id": request.workout_id,
                    "exercises_json": json.dumps([new_warmup_exercise]),
                    "duration_minutes": 5,
                    "is_current": True,
                    "version_number": 1,
                    "created_at": datetime.now().isoformat(),
                    "updated_at": datetime.now().isoformat(),
                }).execute()

                logger.info(f"Exercise '{exercise_name}' added with new warmup for workout {request.workout_id}")

            # Return the main workout (unchanged) as expected by response_model
            return row_to_workout(workout)

        elif section == "stretches":
            new_stretch_exercise = {
                "name": exercise_name,
                "sets": 1,
                "reps": 1,
                "duration_seconds": 30,
                "rest_seconds": 0,
                "equipment": "none",
                "muscle_group": muscle_group or "general",
                "notes": None
            }

            # Query existing stretch for this workout
            stretch_result = db.client.table("stretches").select("*").eq(
                "workout_id", request.workout_id
            ).eq("is_current", True).execute()

            if stretch_result.data:
                stretch_row = stretch_result.data[0]
                existing_exercises = stretch_row.get("exercises_json", "[]")
                if isinstance(existing_exercises, str):
                    stretch_exercises = json.loads(existing_exercises)
                else:
                    stretch_exercises = existing_exercises or []

                stretch_exercises.append(new_stretch_exercise)

                db.client.table("stretches").update({
                    "exercises_json": json.dumps(stretch_exercises),
                    "updated_at": datetime.now().isoformat(),
                }).eq("id", stretch_row["id"]).execute()

                logger.info(f"Exercise '{exercise_name}' added to existing stretches for workout {request.workout_id}")
            else:
                # Insert a new stretch row
                new_stretch_id = str(uuid.uuid4())
                db.client.table("stretches").insert({
                    "id": new_stretch_id,
                    "workout_id": request.workout_id,
                    "exercises_json": json.dumps([new_stretch_exercise]),
                    "duration_minutes": 5,
                    "is_current": True,
                    "version_number": 1,
                    "created_at": datetime.now().isoformat(),
                    "updated_at": datetime.now().isoformat(),
                }).execute()

                logger.info(f"Exercise '{exercise_name}' added with new stretches for workout {request.workout_id}")

            # Return the main workout (unchanged) as expected by response_model
            return row_to_workout(workout)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add exercise: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/extend", response_model=Workout)
async def extend_workout(request: ExtendWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Extend an existing workout with additional AI-generated exercises.

    This endpoint addresses the complaint: "Those few little baby exercises weren't enough
    and there's no way to do more under the same plan."

    Users can request additional exercises that complement their existing workout,
    targeting either the same muscle groups (for more volume) or complementary
    muscle groups (for a more complete workout).
    """
    logger.info(f"🔥 Extending workout {request.workout_id} for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Get the existing workout
        workout_result = db.client.table("workouts").select("*").eq(
            "id", request.workout_id
        ).eq("user_id", request.user_id).execute()

        if not workout_result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        existing_workout = workout_result.data[0]
        existing_exercises_json = existing_workout.get("exercises_json")

        # Parse existing exercises
        if isinstance(existing_exercises_json, str):
            existing_exercises = json.loads(existing_exercises_json)
        else:
            existing_exercises = existing_exercises_json or []

        if not existing_exercises:
            raise HTTPException(status_code=400, detail="Workout has no exercises to extend")

        # Extract muscle groups from existing workout
        existing_muscle_groups = list(set(
            ex.get("muscle_group", "").lower() for ex in existing_exercises
            if ex.get("muscle_group")
        ))
        existing_exercise_names = [ex.get("name", "").lower() for ex in existing_exercises]

        logger.info(f"📋 Existing workout has {len(existing_exercises)} exercises targeting: {existing_muscle_groups}")

        # Get user data
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level", "intermediate")
        equipment = user.get("equipment", [])
        goals = user.get("goals", [])

        # Get user preferences in PARALLEL for faster response
        avoided_exercises, avoided_muscles, staple_exercises = await asyncio.gather(
            get_user_avoided_exercises(request.user_id),
            get_user_avoided_muscles(request.user_id),
            get_user_staple_exercises(request.user_id),
        )
        staple_names = get_staple_names(staple_exercises) if staple_exercises else []

        # Determine intensity for new exercises
        workout_difficulty = existing_workout.get("difficulty", "medium")
        if request.intensity == "lighter":
            target_intensity = "easy" if workout_difficulty == "medium" else "medium"
        elif request.intensity == "harder":
            target_intensity = "hard" if workout_difficulty == "medium" else "hard"
        else:
            target_intensity = workout_difficulty

        # Build the extension prompt
        gemini_service = GeminiService()

        focus_instruction = ""
        if request.focus_same_muscles:
            focus_instruction = f"""
🎯 FOCUS: Generate exercises for the SAME muscle groups as the original workout.
Target muscles: {', '.join(existing_muscle_groups)}
This user wants MORE VOLUME for these muscles."""
        else:
            focus_instruction = f"""
🎯 FOCUS: Generate exercises for COMPLEMENTARY muscle groups.
Already worked: {', '.join(existing_muscle_groups)}
Select exercises for OTHER muscle groups to create a more balanced workout."""

        extension_prompt = f"""Generate {request.additional_exercises} additional exercises to EXTEND an existing workout.

ORIGINAL WORKOUT CONTEXT:
- Existing exercises: {', '.join(existing_exercise_names)}
- Muscle groups worked: {', '.join(existing_muscle_groups)}
- User fitness level: {fitness_level}
- Available equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Target intensity: {target_intensity}

{focus_instruction}

⚠️ CRITICAL CONSTRAINTS:
- Do NOT repeat any exercises already in the workout: {', '.join(existing_exercise_names)}
- Do NOT include these avoided exercises: {', '.join(avoided_exercises) if avoided_exercises else 'None'}
- Staple exercises to consider including: {', '.join(staple_names) if staple_names else 'None'}

Return ONLY a JSON array of exercises (no wrapper object):
[
  {{
    "name": "Exercise name",
    "sets": 3,
    "reps": 12,
    "weight_kg": 10,
    "rest_seconds": 60,
    "equipment": "equipment used",
    "muscle_group": "primary muscle",
    "notes": "Form tips"
  }}
]

Generate exactly {request.additional_exercises} exercises that complement the existing workout."""

        try:
            # Use the chat method to generate JSON response
            raw_response = await gemini_service.chat(
                user_message=extension_prompt,
                system_prompt="You are a fitness expert. Return ONLY valid JSON arrays/objects with no additional text or markdown formatting."
            )

            # Parse the JSON response using robust extraction
            parsed_response = gemini_service._extract_json_robust(raw_response)

            # Handle the response
            if parsed_response is None:
                # Try to parse the raw response directly
                try:
                    parsed_response = json.loads(raw_response.strip())
                except json.JSONDecodeError:
                    logger.error(f"Failed to parse extension response: {raw_response[:500]}")
                    raise ValueError("Failed to parse AI response as JSON")

            # Parse the response - could be list or dict
            if isinstance(parsed_response, list):
                new_exercises = parsed_response
            else:
                new_exercises = parsed_response.get("exercises", []) if isinstance(parsed_response, dict) else []

            # Normalize numeric fields (Gemini returns floats like 3.0 instead of 3)
            new_exercises = normalize_exercise_numeric_fields(new_exercises)

            # Validate and filter new exercises
            if avoided_exercises:
                new_exercises = [
                    ex for ex in new_exercises
                    if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
                ]

            # Filter out duplicates
            new_exercises = [
                ex for ex in new_exercises
                if ex.get("name", "").lower() not in existing_exercise_names
            ]

            if not new_exercises:
                raise HTTPException(status_code=500, detail="Failed to generate valid extension exercises")

            logger.info(f"✅ Generated {len(new_exercises)} extension exercises")

        except Exception as ai_error:
            logger.error(f"AI extension generation failed: {ai_error}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate extension exercises: {str(ai_error)}"
            )

        # Combine existing and new exercises
        combined_exercises = existing_exercises + new_exercises
        new_duration = (existing_workout.get("duration_minutes") or 45) + request.additional_duration_minutes

        # Update the workout with extended exercises
        update_data = {
            "exercises_json": json.dumps(combined_exercises),
            "duration_minutes": new_duration,
        }

        updated_result = db.client.table("workouts").update(
            update_data
        ).eq("id", request.workout_id).execute()

        if not updated_result.data:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        # Log the change
        log_workout_change(
            workout_id=request.workout_id,
            user_id=request.user_id,
            change_type="extended",
            change_source="user_request",
            new_value={
                "added_exercises": len(new_exercises),
                "new_total_exercises": len(combined_exercises),
                "new_duration": new_duration
            }
        )

        logger.info(f"🎉 Workout extended: {len(existing_exercises)} → {len(combined_exercises)} exercises, {new_duration} minutes")

        return row_to_workout(updated_result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to extend workout: {e}")
        raise safe_internal_error(e, "generation")


# =============================================================================
# ONBOARDING WORKOUT GENERATION (Minimal Profile, No DB User Required)
# =============================================================================


class OnboardingGenerateRequest(BaseModel):
    """Request model for generating a workout during onboarding with inline profile data."""
    user_id: str
    goals: List[str]
    fitness_level: str
    equipment: List[str]
    limitations: List[str] = []
    days_per_week: int = Field(default=3, ge=1, le=7)
    workout_duration_min: Optional[int] = Field(default=None, ge=10, le=120)
    workout_duration_max: Optional[int] = Field(default=None, ge=10, le=120)
    primary_goal: Optional[str] = None
    scheduled_date: Optional[str] = None  # YYYY-MM-DD


@router.post("/generate-onboarding")
@limiter.limit("10/minute")
async def generate_onboarding_workout_streaming(request: Request, body: OnboardingGenerateRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a workout during onboarding using inline profile data.

    This is a simplified streaming endpoint for use during onboarding when the
    full user profile may not yet exist in the database. It accepts all
    necessary profile information directly in the request body.

    Returns Server-Sent Events (SSE) with:
    - event: chunk - Progress updates during generation
    - event: done - Complete workout data
    - event: error - Error message if generation fails
    - event: already_generating - Workout generation already in progress
    """
    logger.info(f"🚀 Onboarding workout generation for user {body.user_id}, "
                f"level={body.fitness_level}, goals={body.goals}, equipment={len(body.equipment)} items")

    db = get_supabase_db()
    scheduled_date = body.scheduled_date or datetime.now().strftime("%Y-%m-%d")

    # Idempotency: check for existing generating or completed workout
    try:
        existing_generating = db.client.table("workouts").select("id").eq(
            "user_id", body.user_id
        ).eq(
            "scheduled_date", scheduled_date
        ).eq(
            "status", "generating"
        ).execute()

        if existing_generating.data:
            workout_id = existing_generating.data[0]["id"]
            logger.info(f"⏳ [Onboarding Idempotency] Already generating for {body.user_id} on {scheduled_date}: {workout_id}")

            async def already_generating_sse():
                yield f"event: already_generating\ndata: {json.dumps({'status': 'already_generating', 'workout_id': workout_id, 'message': 'Workout generation already in progress'})}\n\n"

            return StreamingResponse(already_generating_sse(), media_type="text/event-stream")

        existing_workout = db.client.table("workouts").select("id,name,status").eq(
            "user_id", body.user_id
        ).eq(
            "scheduled_date", scheduled_date
        ).neq(
            "status", "generating"
        ).limit(1).execute()

        if existing_workout.data:
            workout_id = existing_workout.data[0]["id"]
            logger.info(f"✅ [Onboarding Duplicate] Workout exists for {body.user_id} on {scheduled_date}: {workout_id}")
            full_workout = db.client.table("workouts").select("*").eq("id", workout_id).single().execute()

            async def existing_sse():
                yield f"event: done\ndata: {json.dumps(full_workout.data)}\n\n"

            return StreamingResponse(existing_sse(), media_type="text/event-stream")
    except Exception as e:
        logger.warning(f"⚠️ [Onboarding Idempotency] Check failed: {e}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()

        try:
            fitness_level = body.fitness_level or "intermediate"
            goals = body.goals if isinstance(body.goals, list) else []
            equipment = body.equipment if isinstance(body.equipment, list) else []
            intensity_preference = get_intensity_from_fitness_level(fitness_level)

            # Duration from request or sensible defaults
            duration_min = body.workout_duration_min
            duration_max = body.workout_duration_max
            effective_duration = duration_max or duration_min or 45

            # Calculate exercise count with fitness-level caps
            base_exercise_count = max(4, min(12, effective_duration // 6))

            EXERCISE_CAPS = {
                "beginner": {30: 4, 45: 5, 60: 5, 75: 6, 90: 6},
                "intermediate": {30: 5, 45: 6, 60: 7, 75: 8, 90: 9},
                "advanced": {30: 5, 45: 7, 60: 8, 75: 10, 90: 11},
            }

            level_caps = EXERCISE_CAPS.get(fitness_level, EXERCISE_CAPS["intermediate"])

            if effective_duration <= 35:
                duration_bracket = 30
            elif effective_duration <= 50:
                duration_bracket = 45
            elif effective_duration <= 65:
                duration_bracket = 60
            elif effective_duration <= 80:
                duration_bracket = 75
            else:
                duration_bracket = 90

            max_exercises = level_caps.get(duration_bracket, 8)
            exercise_count = min(base_exercise_count, max_exercises)

            logger.info(f"📊 [Onboarding Exercise Count] Level: {fitness_level}, Duration: {effective_duration}min, "
                        f"Cap: {max_exercises}, Final: {exercise_count}")

            # Send initial acknowledgment
            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'ttfb_ms': first_chunk_time})}\n\n"

            # Stream the workout generation (no user preferences - this is onboarding)
            gemini_service = GeminiService()
            accumulated_chunks = []
            total_chars = 0
            chunk_count = 0

            settings = get_settings()
            use_cached = settings.gemini_cache_enabled
            logger.info(f"[Onboarding] Using {'CACHED' if use_cached else 'non-cached'} workout generation")

            try:
                generator_func = (
                    gemini_service.generate_workout_plan_streaming_cached
                    if use_cached
                    else gemini_service.generate_workout_plan_streaming
                )

                # Try to get user DOB for birthday theming
                onboarding_user = db.get_user(body.user_id)
                onboarding_dob = onboarding_user.get("date_of_birth") if onboarding_user else None

                generator_kwargs = {
                    "fitness_level": fitness_level,
                    "goals": goals,
                    "equipment": equipment,
                    "duration_minutes": effective_duration,
                    "duration_minutes_min": duration_min,
                    "duration_minutes_max": duration_max,
                    "focus_areas": None,
                    "intensity_preference": intensity_preference,
                    "avoided_exercises": None,
                    "avoided_muscles": None,
                    "staple_exercises": None,
                    "progression_philosophy": None,
                    "exercise_count": exercise_count,
                    "coach_style": None,
                    "coach_tone": None,
                    "scheduled_date": scheduled_date,
                    "user_dob": onboarding_dob,
                }

                if use_cached:
                    generator_kwargs["strength_history"] = None

                async for chunk in generator_func(**generator_kwargs):
                    accumulated_chunks.append(chunk)
                    total_chars += len(chunk)
                    chunk_count += 1

                    if chunk_count % 3 == 0:
                        elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                        yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': total_chars, 'elapsed_ms': elapsed_ms})}\n\n"

                accumulated_text = "".join(accumulated_chunks)
                logger.info(f"✅ [Onboarding] Stream completed: {chunk_count} chunks, {len(accumulated_text)} total chars")
            except Exception as stream_error:
                logger.error(f"❌ [Onboarding] Stream error after {chunk_count} chunks: {stream_error}")
                yield f"event: error\ndata: {json.dumps({'error': f'Streaming failed: {str(stream_error)}'})}\n\n"
                return

            # Parse the complete response
            try:
                content = accumulated_text.strip()
                logger.info(f"🔍 [Onboarding Parse] Raw response length: {len(accumulated_text)} chars")

                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                workout_data = json.loads(content)

                if isinstance(workout_data, str):
                    try:
                        workout_data = json.loads(workout_data)
                    except (json.JSONDecodeError, ValueError):
                        workout_data = {}

                if not isinstance(workout_data, dict):
                    workout_data = {}

                exercises = workout_data.get("exercises", [])
                exercises = normalize_exercise_numeric_fields(exercises)

                workout_name = workout_data.get("name", "Your First Workout")
                workout_type = workout_data.get("type", "strength")
                difficulty = workout_data.get("difficulty", intensity_preference)
                workout_description = workout_data.get("description")
                estimated_duration = workout_data.get("estimated_duration_minutes")
                if estimated_duration is not None:
                    estimated_duration = int(estimated_duration)
                else:
                    fallback_duration = 0
                    for ex in exercises:
                        sets = ex.get("sets", 3)
                        reps = ex.get("reps", 10)
                        rest = ex.get("rest_seconds", 60)
                        time_per_set = (reps * 3) + rest
                        exercise_time = sets * time_per_set
                        fallback_duration += exercise_time
                    fallback_duration = (fallback_duration + len(exercises) * 30) / 60
                    estimated_duration = max(10, int(fallback_duration))

                # Validate and cap exercise parameters for onboarding users
                if exercises:
                    exercises = validate_and_cap_exercise_parameters(
                        exercises=exercises,
                        fitness_level=fitness_level,
                        age=None,
                        is_comeback=False,
                        difficulty=intensity_preference,
                    )
                    logger.info(f"🛡️ [Onboarding Safety] Validated exercise parameters (fitness={fitness_level})")

                # Validate set_targets
                user_context = {
                    "user_id": body.user_id,
                    "fitness_level": fitness_level,
                    "difficulty": difficulty,
                    "goals": goals,
                    "equipment": equipment,
                }
                exercises = validate_set_targets_strict(exercises, user_context)

            except json.JSONDecodeError as e:
                logger.error(f"❌ [Onboarding] Failed to parse response: {e}")
                if content and (content.rstrip().endswith((',', '{', '[', ':')) or
                               not content.rstrip().endswith(('}', ']'))):
                    yield f"event: error\ndata: {json.dumps({'error': 'Workout generation was interrupted. Please try again.', 'truncated': True})}\n\n"
                else:
                    yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data'})}\n\n"
                return

            # Determine scheduled date
            if body.scheduled_date:
                try:
                    scheduled_dt = datetime.strptime(body.scheduled_date, "%Y-%m-%d")
                    scheduled_date_str = scheduled_dt.isoformat()
                except ValueError:
                    scheduled_date_str = datetime.now().isoformat()
            else:
                scheduled_date_str = datetime.now().isoformat()

            # Save to database
            workout_db_data = {
                "user_id": body.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "description": workout_description,
                "scheduled_date": scheduled_date_str,
                "exercises_json": exercises,
                "duration_minutes": effective_duration,
                "duration_minutes_min": duration_min,
                "duration_minutes_max": duration_max,
                "estimated_duration_minutes": estimated_duration,
                "generation_method": "ai",
                "generation_source": "onboarding_generation",
            }

            created = db.create_workout(workout_db_data)
            total_time_ms = (datetime.now() - start_time).total_seconds() * 1000

            logger.info(f"✅ [Onboarding] Workout complete: {len(exercises)} exercises in {total_time_ms:.0f}ms")

            # Log the change
            log_workout_change(
                workout_id=created['id'],
                user_id=body.user_id,
                change_type="generated",
                change_source="onboarding_generation",
                new_value={"name": workout_name, "exercises_count": len(exercises)},
            )

            # Convert to Workout model
            generated_workout = row_to_workout(created)

            # Index to RAG asynchronously
            asyncio.create_task(index_workout_to_rag(generated_workout))

            # Send final complete response
            exercises_list = json.loads(generated_workout.exercises_json) if generated_workout.exercises_json else []

            workout_response = {
                "id": generated_workout.id,
                "user_id": generated_workout.user_id,
                "name": generated_workout.name,
                "type": generated_workout.type,
                "difficulty": generated_workout.difficulty,
                "description": generated_workout.description,
                "scheduled_date": generated_workout.scheduled_date.isoformat() if generated_workout.scheduled_date else None,
                "exercises": exercises_list,
                "exercises_json": generated_workout.exercises_json,
                "duration_minutes": generated_workout.duration_minutes,
                "total_time_ms": total_time_ms,
                "chunk_count": chunk_count,
                "source": "onboarding",
            }

            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"❌ [Onboarding] Generation failed: {e}")
            yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
