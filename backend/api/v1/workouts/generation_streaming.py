"""
Streaming workout generation endpoint.

Extracted from generation.py to keep files under 1000 lines.
Provides:
- POST /generate-stream - SSE streaming workout generation
"""
from core.db import get_supabase_db
import json
import asyncio
from datetime import datetime
from typing import AsyncGenerator

from fastapi import APIRouter, Depends, Request
from core.auth import get_current_user
from fastapi.responses import StreamingResponse

from core.logger import get_logger
from core.config import get_settings
from models.schemas import GenerateWorkoutRequest
from ._gym_profile_helpers import get_active_gym_profile_id
from services.gemini_service import GeminiService, validate_set_targets_strict
from core.rate_limiter import user_limiter
from core.timezone_utils import resolve_timezone, get_user_today, target_date_to_utc_iso

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    normalize_goals_list,
    get_user_strength_history,
    get_user_favorite_exercises,
    get_user_exercise_queue,
    get_user_staple_exercises,
    get_staple_names,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    apply_1rm_weights_to_exercises,
    get_intensity_from_fitness_level,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    # Exercise parameter validation (safety net)
    validate_and_cap_exercise_parameters,
    get_user_comeback_status,
    # Progression philosophy helpers
    get_user_rep_preferences,
    get_user_progression_context,
    build_progression_philosophy_prompt,
    # Hormonal health context helpers
    get_user_hormonal_context,
    # Focus area validation
    validate_and_filter_focus_mismatches,
    # Duration resolver (request body → gym profile → user preferences → default)
    resolve_target_duration,
)

from .generation_helpers import (
    _estimate_workout_met,
    normalize_exercise_numeric_fields,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post("/generate-stream")
@user_limiter.limit("15/minute")
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
    logger.info(f"Streaming workout generation for user {body.user_id}")

    # Idempotency check: If a workout is already being generated for this user/date, return early
    db = get_supabase_db()
    _user_tz = resolve_timezone(request, db, body.user_id)
    scheduled_date = body.scheduled_date or get_user_today(_user_tz)

    # Resolve gym_profile_id early for dedup checks. None is a valid outcome:
    # legacy users or users mid-onboarding may not have an active profile yet,
    # and the generator handles profile_id=None downstream.
    stream_gym_profile_id = body.gym_profile_id or get_active_gym_profile_id(db, body.user_id)

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
            logger.info(f"[Idempotency] Workout already generating for {body.user_id} on {scheduled_date} (profile={stream_gym_profile_id}): {workout_id}")

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
            logger.info(f"[Duplicate] Workout already exists for {body.user_id} on {scheduled_date}: {workout_id}")
            try:
                full_workout = db.client.table("workouts").select("*").eq("id", workout_id).single().execute()
            except Exception as e:
                # Row was deleted between the duplicate-check and the refetch, or RLS
                # blocked the read. Skip the shortcut and fall through to regenerate.
                logger.warning(f"[Duplicate] Failed to refetch workout {workout_id}: {e}")
                full_workout = None

            if full_workout and full_workout.data:
                async def existing_sse():
                    yield f"event: done\ndata: {json.dumps(full_workout.data)}\n\n"

                return StreamingResponse(existing_sse(), media_type="text/event-stream")
    except Exception as e:
        # Log but don't fail - idempotency check is a nice-to-have
        logger.warning(f"[Idempotency] Check failed: {e}", exc_info=True)

    # Premium gate check: enforce free-tier workout generation limits
    from core.premium_gate import check_premium_gate
    await check_premium_gate(body.user_id, "ai_workout_generation", _user_tz)

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()
        gym_profile_id = None  # Track which profile this workout is generated for
        # Track user + gym_profile across both branches below so the duration
        # resolver can consult them (short-circuit path leaves both as None).
        user = None
        gym_profile = None

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
                    try:
                        profile_result = db.client.table("gym_profiles").select("*").eq("id", body.gym_profile_id).single().execute()
                        gym_profile = profile_result.data if profile_result.data else None
                        logger.info(f"[GymProfile] Using requested profile: {body.gym_profile_id}")
                    except Exception as e:
                        logger.warning(f"Failed to fetch gym profile: {e}", exc_info=True)
                else:
                    try:
                        active_result = db.client.table("gym_profiles").select("*").eq("user_id", body.user_id).eq("is_active", True).single().execute()
                        gym_profile = active_result.data if active_result.data else None
                        if gym_profile:
                            logger.info(f"[GymProfile] Using active profile: {gym_profile.get('name')} ({gym_profile.get('id')})")
                    except Exception as e:
                        logger.debug(f"No active gym profile found: {e}")

                if gym_profile:
                    gym_profile_id = gym_profile.get("id")
                    equipment = body.equipment or gym_profile.get("equipment") or []
                    training_split = gym_profile.get("training_split")
                    workout_days = gym_profile.get("workout_days") or []
                    profile_goals = normalize_goals_list(gym_profile.get("goals"))
                    user_goals = normalize_goals_list(user.get("goals"))
                    goals = normalize_goals_list(body.goals) if body.goals else (profile_goals if profile_goals else user_goals)
                    logger.info(f"[GymProfile] Profile equipment: {len(equipment)} items")
                    if training_split:
                        logger.info(f"[GymProfile-Stream] Training split: {training_split}")
                else:
                    goals = normalize_goals_list(body.goals) if body.goals else normalize_goals_list(user.get("goals"))
                    equipment = body.equipment or parse_json_field(user.get("equipment"), [])
                    training_split = user.get("training_split")
                    workout_days = parse_json_field(user.get("workout_days"), [])

                intensity_preference = preferences.get("intensity_preference") or get_intensity_from_fitness_level(fitness_level)

            # Fetch user preferences in PARALLEL for faster response
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
                get_user_staple_exercises(body.user_id, gym_profile_id=gym_profile_id, scheduled_date=getattr(body, 'scheduled_date', None)),
                get_user_rep_preferences(body.user_id),
                get_user_progression_context(body.user_id),
                get_user_hormonal_context(body.user_id, timezone_str=resolve_timezone(request, db, body.user_id)),
                fetch_ai_coach_settings(),
                get_user_strength_history(body.user_id),
                get_user_favorite_exercises(body.user_id),
                get_user_exercise_queue(body.user_id),
            )

            # Log fetched preferences
            if avoided_exercises:
                logger.info(f"[Streaming] User has {len(avoided_exercises)} avoided exercises")
            if avoided_muscles.get("avoid") or avoided_muscles.get("reduce"):
                logger.info(f"[Streaming] User has avoided muscles")
            if staple_exercises:
                logger.info(f"[Streaming] User has {len(staple_exercises)} staple exercises")
            if favorite_exercises:
                logger.info(f"[Streaming] User has {len(favorite_exercises)} favorite exercises: {favorite_exercises[:5]}")
            if exercise_queue:
                logger.info(f"[Streaming] User has {len(exercise_queue)} queued exercises")
            if ai_coach_settings:
                logger.info(f"[Streaming] Coach settings: style={ai_coach_settings.get('coaching_style')}, tone={ai_coach_settings.get('communication_tone')}")

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

            # Resolve target duration from request body → gym profile → user preferences.
            # Without this, body.duration_minutes defaults to None and the effective
            # value silently falls to 45 min even when the user set a different preference.
            resolved_duration = resolve_target_duration(
                body_duration=body.duration_minutes,
                body_duration_min=body.duration_minutes_min,
                body_duration_max=body.duration_minutes_max,
                gym_profile=gym_profile,
                user=user,
            )
            target_duration = resolved_duration["target"]
            target_duration_min = resolved_duration["min"]
            target_duration_max = resolved_duration["max"]
            logger.info(
                f"[Streaming Duration] Resolved target={target_duration}, "
                f"min={target_duration_min}, max={target_duration_max} "
                f"(body={body.duration_minutes}, gym.duration_minutes={gym_profile.get('duration_minutes') if gym_profile else None})"
            )

            # Calculate exercise count with fitness-level caps
            effective_duration = target_duration_max or target_duration_min or target_duration
            base_exercise_count = max(4, min(12, effective_duration // 6))

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

            logger.info(f"[Streaming Exercise Count] Level: {level}, Duration: {effective_duration}min, Hell: {is_hell_mode}, Cap: {max_exercises}, Final: {exercise_count}")

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
                        filtered.append(s)
                    elif not s.get("equipment") or s["equipment"].lower() in equipment_lower:
                        filtered.append(s)
                    else:
                        logger.info(f"Skipping all-profiles staple '{s['name']}' - requires '{s.get('equipment')}' not in profile equipment")
                staple_exercises = filtered

            staple_names = get_staple_names(staple_exercises) if staple_exercises else None

            # Check if context caching is enabled (faster generation)
            settings = get_settings()
            use_cached = settings.gemini_cache_enabled
            logger.info(f"[Streaming] Using {'CACHED' if use_cached else 'non-cached'} workout generation")

            try:
                generator_func = (
                    gemini_service.generate_workout_plan_streaming_cached
                    if use_cached
                    else gemini_service.generate_workout_plan_streaming
                )

                generator_kwargs = {
                    "fitness_level": fitness_level or "intermediate",
                    "goals": goals if isinstance(goals, list) else [],
                    "equipment": equipment if isinstance(equipment, list) else [],
                    "duration_minutes": target_duration,
                    "duration_minutes_min": target_duration_min,
                    "duration_minutes_max": target_duration_max,
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
                    "user_id": body.user_id,
                    "training_split": training_split,
                    "workout_days": workout_days if workout_days else None,
                }

                generator_kwargs["strength_history"] = strength_history
                generator_kwargs["workout_weight_unit"] = user.get("workout_weight_unit") or user.get("weight_unit") or "lbs" if user else "lbs"

                async for chunk in generator_func(**generator_kwargs):
                    accumulated_chunks.append(chunk)
                    total_chars += len(chunk)
                    chunk_count += 1

                    if chunk_count % 3 == 0:
                        elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                        yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': total_chars, 'elapsed_ms': elapsed_ms})}\n\n"

                accumulated_text = "".join(accumulated_chunks)
                logger.info(f"[Streaming] Stream completed: {chunk_count} chunks, {len(accumulated_text)} total chars")
            except Exception as stream_error:
                logger.error(f"[Streaming] Stream error after {chunk_count} chunks, {total_chars} chars: {stream_error}", exc_info=True)
                yield f"event: error\ndata: {json.dumps({'error': f'Streaming failed: {str(stream_error)}'})}\n\n"
                return

            # Parse the complete response
            try:
                content = accumulated_text.strip()
                logger.info(f"[Streaming Parse] Raw response length: {len(accumulated_text)} chars")
                logger.debug(f"[Streaming Parse] Raw content: {accumulated_text[:500]}...")

                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                logger.info(f"[Streaming Parse] Cleaned content length: {len(content)} chars")
                if len(content) < 100:
                    logger.error(f"[Streaming Parse] Content too short, full content: {content}")

                workout_data = json.loads(content)

                if isinstance(workout_data, str):
                    try:
                        workout_data = json.loads(workout_data)
                    except (json.JSONDecodeError, ValueError):
                        logger.error(f"workout_data is a string that cannot be parsed: {workout_data[:200]}", exc_info=True)
                        workout_data = {}

                if not isinstance(workout_data, dict):
                    logger.error(f"workout_data is not a dict: type={type(workout_data).__name__}")
                    workout_data = {}

                exercises = workout_data.get("exercises", [])
                exercises = normalize_exercise_numeric_fields(exercises)

                # Normalize equipment values — Gemini echoes snake_case from user profile
                from services.exercise_rag.utils import normalize_equipment_value
                for ex in exercises:
                    raw_eq = ex.get("equipment", "")
                    if raw_eq and "_" in raw_eq:
                        ex["equipment"] = normalize_equipment_value(raw_eq, ex.get("name", ""))

                workout_name = workout_data.get("name", "Generated Workout")
                workout_type = workout_data.get("type", body.workout_type or "strength")
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
                    logger.debug(f"[Streaming Duration] Calculated fallback duration: {estimated_duration} min")

                # DURATION VALIDATION (against resolved target, not raw body value)
                if estimated_duration and target_duration_max:
                    if estimated_duration > target_duration_max:
                        logger.warning(f"[Streaming Duration] Estimated duration {estimated_duration} min exceeds max {target_duration_max} min")
                    else:
                        logger.debug(f"[Streaming Duration] Estimated {estimated_duration} min is within range")
                elif estimated_duration:
                    logger.debug(f"[Streaming Duration] Estimated duration: {estimated_duration} min")

                # POST-GENERATION VALIDATION: Filter out exercises that violate user preferences
                if avoided_exercises:
                    original_count = len(exercises)
                    exercises = [
                        ex for ex in exercises
                        if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
                    ]
                    filtered_count = original_count - len(exercises)
                    if filtered_count > 0:
                        logger.warning(f"[Streaming Validation] Filtered out {filtered_count} avoided exercises")

                if avoided_muscles and avoided_muscles.get("avoid"):
                    original_count = len(exercises)
                    avoid_muscles_lower = [m.lower() for m in avoided_muscles["avoid"]]
                    exercises = [
                        ex for ex in exercises
                        if ex.get("muscle_group", "").lower() not in avoid_muscles_lower
                    ]
                    filtered_count = original_count - len(exercises)
                    if filtered_count > 0:
                        logger.warning(f"[Streaming Validation] Filtered out {filtered_count} exercises targeting avoided muscles")

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
                        logger.info(f"[Streaming Validation] Limited {removed_count} exercises targeting reduced muscles")
                        exercises = new_exercises

                # Phase 3.5 (streaming): reject exercises requiring equipment the
                # user does not have. Mirrors generation_endpoints.py:691. Also
                # uses name-inference to catch mis-tagged library rows
                # (e.g. "Hanging Toes-to-Bar" stored as bodyweight but needing a bar).
                if equipment and exercises:
                    from services.exercise_rag.filters import filter_by_equipment
                    from services.exercise_rag.utils import infer_equipment_from_name
                    equipment_compatible = []
                    equipment_rejected_names: List[str] = []
                    for ex in exercises:
                        ex_equip = (ex.get("equipment") or "").strip()
                        ex_name = ex.get("name", "") or ex.get("exercise_name", "")
                        # Override bodyweight/empty tags via name inference so
                        # mis-labeled rows don't sneak through.
                        if not ex_equip or ex_equip.lower() in ("bodyweight", "body weight", "none", ""):
                            ex_equip = infer_equipment_from_name(ex_name)
                        if filter_by_equipment(ex_equip, equipment, ex_name):
                            equipment_compatible.append(ex)
                        else:
                            equipment_rejected_names.append(ex_name)
                            logger.warning(
                                f"[Streaming Equipment Filter] Removed '{ex_name}' — "
                                f"requires '{ex_equip}', user has: {equipment}"
                            )
                    if equipment_rejected_names:
                        logger.info(
                            f"[Streaming Equipment Filter] Removed {len(equipment_rejected_names)} "
                            f"exercises with incompatible equipment: {equipment_rejected_names}"
                        )
                        exercises = equipment_compatible

                # Defensive dedup: strip "(N)" suffixes that come from duplicate
                # library imports (e.g. Burpee vs Burpee(1)), then collapse
                # remaining duplicates by case-insensitive base name.
                if exercises:
                    from services.exercise_rag.utils import dedup_key, strip_dedup_suffix
                    _seen_keys: set = set()
                    _deduped: List[dict] = []
                    _collapsed = 0
                    for ex in exercises:
                        raw_name = ex.get("name", "") or ex.get("exercise_name", "")
                        key = dedup_key(raw_name)
                        if not key or key in _seen_keys:
                            _collapsed += 1
                            continue
                        _seen_keys.add(key)
                        # Normalize the stored name too so the client never sees "(N)".
                        cleaned = strip_dedup_suffix(raw_name)
                        if cleaned != raw_name:
                            ex["name"] = cleaned
                        _deduped.append(ex)
                    if _collapsed:
                        logger.info(f"[Streaming Dedup] Collapsed {_collapsed} duplicate exercises by normalized name")
                    exercises = _deduped

                workout_data["exercises"] = exercises

                # Apply 1RM-based weights
                one_rm_data = await get_user_1rm_data(body.user_id)
                training_intensity = await get_user_training_intensity(body.user_id)
                intensity_overrides = await get_user_intensity_overrides(body.user_id)

                if one_rm_data and exercises:
                    exercises = apply_1rm_weights_to_exercises(
                        exercises, one_rm_data, training_intensity, intensity_overrides
                    )
                    logger.info(f"[Streaming] Applied 1RM-based weights to exercises")

                # CRITICAL SAFETY NET: Validate and cap exercise parameters
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
                    logger.info(f"[Streaming Safety] Validated exercise parameters (fitness={fitness_level}, age={user_age}, comeback={is_comeback}, difficulty={intensity_preference})")

                # FOCUS AREA VALIDATION
                MIN_EXERCISES_REQUIRED = 3

                focus_areas = body.focus_areas if hasattr(body, 'focus_areas') and body.focus_areas else []

                if focus_areas and len(focus_areas) > 0 and exercises:
                    primary_focus = focus_areas[0]
                    focus_validation = await validate_and_filter_focus_mismatches(
                        exercises=exercises,
                        focus_area=primary_focus,
                        workout_name=workout_name,
                    )

                    missing_groups = focus_validation.get("missing_muscle_groups", [])
                    if missing_groups:
                        friendly = {"legs": "Legs/Glutes", "back": "Back/Pull", "chest_push": "Chest/Shoulders/Push"}
                        missing_names = [friendly.get(g, g) for g in missing_groups]
                        logger.error(
                            f"[Streaming Full Body Validation] Workout '{workout_name}' labeled full_body but MISSING: "
                            f"{', '.join(missing_names)}. Exercises: {[ex.get('name') for ex in exercises]}."
                        )

                    if focus_validation["mismatch_count"] > 0:
                        logger.warning(
                            f"[Streaming Focus Validation] Found {focus_validation['mismatch_count']} mismatched exercises "
                            f"in '{workout_name}' for focus '{primary_focus}'."
                        )

                        valid_exercises = focus_validation["valid_exercises"]

                        if len(valid_exercises) >= MIN_EXERCISES_REQUIRED:
                            logger.info(
                                f"[Streaming Focus Validation] Filtering to {len(valid_exercises)} valid exercises "
                                f"(removed {focus_validation['mismatch_count']} mismatched)"
                            )
                            exercises = valid_exercises
                        else:
                            logger.error(
                                f"[Streaming Focus Validation] CRITICAL: Workout '{workout_name}' has only "
                                f"{len(valid_exercises)} valid exercises for '{primary_focus}' focus "
                                f"(minimum required: {MIN_EXERCISES_REQUIRED}). "
                                f"Keeping all {len(exercises)} exercises to meet minimum."
                            )

                if len(exercises) < MIN_EXERCISES_REQUIRED:
                    logger.error(
                        f"[Streaming Exercise Count] Workout '{workout_name}' has only {len(exercises)} exercises "
                        f"(minimum required: {MIN_EXERCISES_REQUIRED})."
                    )

                # CRITICAL: Validate set_targets
                user_context = {
                    "user_id": body.user_id,
                    "fitness_level": fitness_level,
                    "difficulty": difficulty,
                    "goals": goals if isinstance(goals, list) else [],
                    "equipment": equipment if isinstance(equipment, list) else [],
                }
                exercises = validate_set_targets_strict(exercises, user_context)

            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse streaming response: {e}", exc_info=True)
                logger.error(f"Raw accumulated text ({len(accumulated_text)} chars): {accumulated_text[:1000]}", exc_info=True)
                logger.error(f"Cleaned content for parsing ({len(content)} chars): {content[:1000]}", exc_info=True)

                if content and (content.rstrip().endswith((',', '{', '[', ':')) or
                               not content.rstrip().endswith(('}', ']'))):
                    logger.error(f"Detected truncated response - Gemini stream ended prematurely", exc_info=True)
                    yield f"event: error\ndata: {json.dumps({'error': 'Workout generation was interrupted. Please try again.', 'raw_length': len(accumulated_text), 'truncated': True})}\n\n"
                else:
                    yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data', 'raw_length': len(accumulated_text)})}\n\n"
                return

            # Determine scheduled date
            _stream_tz = resolve_timezone(request, db, body.user_id)
            if body.scheduled_date:
                try:
                    datetime.strptime(body.scheduled_date, "%Y-%m-%d")
                    scheduled_date_str = target_date_to_utc_iso(body.scheduled_date, _stream_tz)
                    logger.info(f"[Streaming] Using provided scheduled_date: {body.scheduled_date} (tz={_stream_tz})")
                except ValueError:
                    logger.warning(f"Invalid scheduled_date format: {body.scheduled_date}, using today", exc_info=True)
                    scheduled_date_str = target_date_to_utc_iso(get_user_today(_stream_tz), _stream_tz)
            else:
                scheduled_date_str = target_date_to_utc_iso(get_user_today(_stream_tz), _stream_tz)

            # Compute estimated calories using MET-based formula
            _user_weight_kg = float(user.get("weight_kg") or user.get("weight") or 70) if user else 70.0
            _user_weight_kg = max(30.0, min(_user_weight_kg, 250.0))
            _effective_duration = estimated_duration or target_duration
            _met = _estimate_workout_met(exercises, workout_type, difficulty)
            _estimated_calories = round(_met * _user_weight_kg * (_effective_duration / 60.0))

            # Save to database
            workout_db_data = {
                "user_id": body.user_id,
                "gym_profile_id": gym_profile_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "description": workout_description,
                "scheduled_date": scheduled_date_str,
                "exercises_json": exercises,
                "duration_minutes": target_duration,
                "duration_minutes_min": target_duration_min,
                "duration_minutes_max": target_duration_max,
                "estimated_duration_minutes": estimated_duration,
                "estimated_calories": _estimated_calories,
                "generation_method": "ai",
                "generation_source": "streaming_generation",
            }

            try:
                created = db.create_workout(workout_db_data)
            except Exception as insert_err:
                if 'PGRST204' in str(insert_err) and 'estimated_calories' in str(insert_err):
                    logger.warning("[Streaming] estimated_calories column not in schema cache, retrying without it", exc_info=True)
                    workout_db_data.pop('estimated_calories', None)
                    created = db.create_workout(workout_db_data)
                else:
                    raise
            total_time_ms = (datetime.now() - start_time).total_seconds() * 1000

            logger.info(f"Streaming workout complete: {len(exercises)} exercises in {total_time_ms:.0f}ms, gym_profile_id={gym_profile_id}")

            log_workout_change(
                workout_id=created['id'],
                user_id=body.user_id,
                change_type="generated",
                change_source="streaming_generation",
                new_value={"name": workout_name, "exercises_count": len(exercises)}
            )

            generated_workout = row_to_workout(created)

            # Index to RAG asynchronously (don't wait)
            asyncio.create_task(index_workout_to_rag(generated_workout))

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
                await track_premium_usage(body.user_id, "ai_workout_generation", _user_tz)
            except Exception as usage_err:
                logger.warning(f"Failed to track workout generation usage: {usage_err}", exc_info=True)

            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"Streaming workout generation failed: {e}", exc_info=True)
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
