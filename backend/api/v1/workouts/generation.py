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
import json
import asyncio
from datetime import datetime, timedelta
from typing import List, AsyncGenerator, Dict, Any, Optional

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from core.supabase_db import get_supabase_db
from core.logger import get_logger
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
from core.rate_limiter import limiter

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
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
)
from services.adaptive_workout_service import (
    apply_age_caps,
    get_senior_workout_prompt_additions,
    get_user_set_type_preferences,
    build_set_type_context,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post("/generate", response_model=Workout)
async def generate_workout(request: GenerateWorkoutRequest):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {request.user_id}")

    try:
        db = get_supabase_db()
        equipment_details = []  # Initialize to empty, may be populated from user data
        gym_profile_id = None  # Track which profile this workout is generated for

        # Initialize new training customization fields
        primary_goal = None
        muscle_focus_points = None
        training_split = None

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
                except Exception:
                    # No active profile found - will use user defaults
                    pass

            if gym_profile:
                # Load settings from gym profile
                gym_profile_id = gym_profile.get("id")
                equipment = request.equipment or gym_profile.get("equipment") or []
                equipment_details = gym_profile.get("equipment_details") or []
                workout_environment = gym_profile.get("workout_environment") or preferences.get("workout_environment")
                training_split = gym_profile.get("training_split")
                profile_goals = gym_profile.get("goals") or []
                goals = request.goals or profile_goals if profile_goals else user.get("goals", [])
                focus_areas = gym_profile.get("focus_areas") or []

                logger.info(f"🏋️ [GymProfile] Profile equipment: {len(equipment)} items")
                logger.info(f"📍 [GymProfile] Environment: {workout_environment}")
                if training_split:
                    logger.info(f"📅 [GymProfile] Training split: {training_split}")
            else:
                # Fall back to user settings
                goals = request.goals or user.get("goals", [])
                equipment = request.equipment or user.get("equipment", [])
                equipment_details = user.get("equipment_details", [])  # Detailed equipment with quantities/weights
                workout_environment = preferences.get("workout_environment")

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

        # Fetch user preferences (avoided exercises, avoided muscles, staple exercises)
        # This is CRITICAL for respecting user preferences in workout generation
        logger.info(f"🎯 [Workout Generation] Fetching user preferences for: {request.user_id}")
        avoided_exercises = await get_user_avoided_exercises(request.user_id)
        avoided_muscles = await get_user_avoided_muscles(request.user_id)
        staple_exercises = await get_user_staple_exercises(request.user_id)

        if avoided_exercises:
            logger.info(f"🚫 [Workout Generation] User has {len(avoided_exercises)} avoided exercises")
        if avoided_muscles.get("avoid") or avoided_muscles.get("reduce"):
            logger.info(f"🚫 [Workout Generation] User has avoided muscles: avoid={avoided_muscles.get('avoid')}, reduce={avoided_muscles.get('reduce')}")
        if staple_exercises:
            logger.info(f"⭐ [Workout Generation] User has {len(staple_exercises)} staple exercises")

        # Fetch progression context and rep preferences for leverage-based progressions
        logger.info(f"[Workout Generation] Fetching progression context for leverage-based progressions")
        rep_preferences = await get_user_rep_preferences(request.user_id)
        progression_context = await get_user_progression_context(request.user_id)

        # Build progression philosophy prompt
        progression_philosophy = build_progression_philosophy_prompt(
            rep_preferences=rep_preferences,
            progression_context=progression_context,
        )
        if rep_preferences.get("training_focus") != "balanced":
            logger.info(f"[Workout Generation] User training focus: {rep_preferences.get('training_focus')}")
        if progression_context.get("mastered_exercises"):
            logger.info(f"[Workout Generation] User has {len(progression_context['mastered_exercises'])} mastered exercises")

        # Fetch user's historical workout patterns and set/rep limits
        logger.info(f"[Workout Generation] Fetching workout patterns and set/rep limits for user: {request.user_id}")
        workout_patterns = await get_user_workout_patterns(request.user_id)
        workout_patterns_context = workout_patterns.get("historical_context", "")
        set_rep_limits = workout_patterns.get("set_rep_limits", {})
        exercise_patterns = workout_patterns.get("exercise_patterns", {})

        if set_rep_limits.get("max_sets_per_exercise", 5) < 5:
            logger.info(f"[Workout Generation] User has set max_sets_per_exercise: {set_rep_limits.get('max_sets_per_exercise')}")
        if set_rep_limits.get("max_reps_per_set", 15) < 15:
            logger.info(f"[Workout Generation] User has set max_reps_per_set: {set_rep_limits.get('max_reps_per_set')}")
        if exercise_patterns:
            logger.info(f"[Workout Generation] Found {len(exercise_patterns)} exercise patterns from history")

        # Fetch hormonal health context for gender-specific and cycle-aware workouts
        logger.info(f"[Workout Generation] Fetching hormonal health context for user: {request.user_id}")
        hormonal_context = await get_user_hormonal_context(request.user_id)
        hormonal_ai_context = hormonal_context.get("ai_context", "")
        if hormonal_context.get("cycle_phase"):
            logger.info(f"[Workout Generation] User is in {hormonal_context['cycle_phase']} phase (day {hormonal_context.get('cycle_day')})")
        if hormonal_context.get("kegels_enabled"):
            logger.info(f"[Workout Generation] User has kegels enabled - warmup: {hormonal_context.get('include_kegels_in_warmup')}, cooldown: {hormonal_context.get('include_kegels_in_cooldown')}")

        # Fetch set type preferences for personalized drop set / failure set recommendations
        logger.info(f"[Workout Generation] Fetching set type preferences for user: {request.user_id}")
        set_type_prefs = await get_user_set_type_preferences(request.user_id, supabase_client=db.client)
        set_type_context = build_set_type_context(set_type_prefs)
        if set_type_prefs:
            advanced_types = [k for k in set_type_prefs.keys() if k not in ["working", "warmup"]]
            if advanced_types:
                logger.info(f"[Workout Generation] User has history with set types: {advanced_types}")

        gemini_service = GeminiService()

        try:
            # Combine progression philosophy with hormonal context for AI
            combined_context = progression_philosophy or ""
            if hormonal_ai_context:
                combined_context = f"{combined_context}\n\nHORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}" if combined_context else f"HORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}"

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
                staple_exercises=staple_exercises if staple_exercises else None,
                progression_philosophy=combined_context if combined_context else None,
                workout_patterns_context=workout_patterns_context if workout_patterns_context else None,
                set_type_context=set_type_context if set_type_context else None,
                primary_goal=primary_goal,
                muscle_focus_points=muscle_focus_points,
            )

            exercises = workout_data.get("exercises", [])
            workout_name = workout_data.get("name", "Generated Workout")
            difficulty = workout_data.get("difficulty", intensity_preference)

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
            "scheduled_date": datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": request.duration_minutes or 45,
            "generation_method": "ai",
            "generation_source": "gemini_generation",
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Workout generated: id={created['id']}, gym_profile_id={gym_profile_id}")

        log_workout_change(
            workout_id=created['id'],
            user_id=request.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={"name": workout_name, "exercises_count": len(exercises)}
        )

        generated_workout = row_to_workout(created)
        await index_workout_to_rag(generated_workout)

        return generated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-stream")
@limiter.limit("5/minute")
async def generate_workout_streaming(request: Request, body: GenerateWorkoutRequest):
    """
    Generate a workout with streaming response for faster perceived performance.

    Returns Server-Sent Events (SSE) with:
    - event: chunk - Partial workout data as it's generated
    - event: done - Final complete workout data
    - event: error - Error message if generation fails

    Time to first content is typically <500ms vs 3-8s for full generation.
    """
    logger.info(f"🚀 Streaming workout generation for user {body.user_id}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()
        gym_profile_id = None  # Track which profile this workout is generated for

        try:
            db = get_supabase_db()

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
                    except Exception:
                        pass
                else:
                    # Try to get active profile
                    try:
                        active_result = db.client.table("gym_profiles").select("*").eq("user_id", body.user_id).eq("is_active", True).single().execute()
                        gym_profile = active_result.data if active_result.data else None
                        if gym_profile:
                            logger.info(f"🏋️ [GymProfile] Using active profile: {gym_profile.get('name')} ({gym_profile.get('id')})")
                    except Exception:
                        pass

                if gym_profile:
                    # Load settings from gym profile
                    gym_profile_id = gym_profile.get("id")
                    equipment = body.equipment or gym_profile.get("equipment") or []
                    profile_goals = gym_profile.get("goals") or []
                    goals = body.goals or profile_goals if profile_goals else user.get("goals", [])
                    logger.info(f"🏋️ [GymProfile] Profile equipment: {len(equipment)} items")
                else:
                    # Fall back to user settings
                    goals = body.goals or user.get("goals", [])
                    equipment = body.equipment or user.get("equipment", [])

                # Use explicit intensity_preference if set, otherwise derive from fitness level
                intensity_preference = preferences.get("intensity_preference") or get_intensity_from_fitness_level(fitness_level)

            # Fetch user preferences (avoided exercises, avoided muscles, staple exercises)
            # This is CRITICAL for respecting user preferences in workout generation
            avoided_exercises = await get_user_avoided_exercises(body.user_id)
            avoided_muscles = await get_user_avoided_muscles(body.user_id)
            staple_exercises = await get_user_staple_exercises(body.user_id)

            if avoided_exercises:
                logger.info(f"🚫 [Streaming] User has {len(avoided_exercises)} avoided exercises")
            if avoided_muscles.get("avoid") or avoided_muscles.get("reduce"):
                logger.info(f"🚫 [Streaming] User has avoided muscles")
            if staple_exercises:
                logger.info(f"⭐ [Streaming] User has {len(staple_exercises)} staple exercises")

            # Fetch progression context and rep preferences for leverage-based progressions
            rep_preferences = await get_user_rep_preferences(body.user_id)
            progression_context = await get_user_progression_context(body.user_id)
            progression_philosophy = build_progression_philosophy_prompt(
                rep_preferences=rep_preferences,
                progression_context=progression_context,
            )

            # Fetch hormonal health context for gender-specific and cycle-aware workouts
            hormonal_context = await get_user_hormonal_context(body.user_id)
            hormonal_ai_context = hormonal_context.get("ai_context", "")
            if hormonal_context.get("cycle_phase"):
                logger.info(f"[Streaming] User is in {hormonal_context['cycle_phase']} phase")

            # Combine progression philosophy with hormonal context
            combined_context = progression_philosophy or ""
            if hormonal_ai_context:
                combined_context = f"{combined_context}\n\nHORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}" if combined_context else f"HORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}"

            gemini_service = GeminiService()

            # Send initial acknowledgment (time to first byte)
            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'ttfb_ms': first_chunk_time})}\n\n"

            # Stream the workout generation
            accumulated_text = ""
            chunk_count = 0

            async for chunk in gemini_service.generate_workout_plan_streaming(
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=body.duration_minutes or 45,
                focus_areas=body.focus_areas,
                intensity_preference=intensity_preference,
                avoided_exercises=avoided_exercises if avoided_exercises else None,
                avoided_muscles=avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
                staple_exercises=staple_exercises if staple_exercises else None,
                progression_philosophy=combined_context if combined_context else None,
            ):
                accumulated_text += chunk
                chunk_count += 1

                # Send progress updates every few chunks
                if chunk_count % 3 == 0:
                    elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                    yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': len(accumulated_text), 'elapsed_ms': elapsed_ms})}\n\n"

            # Parse the complete response
            try:
                # Extract JSON from potential markdown code blocks
                content = accumulated_text.strip()
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                workout_data = json.loads(content)
                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", "Generated Workout")
                workout_type = workout_data.get("type", body.workout_type or "strength")
                difficulty = workout_data.get("difficulty", intensity_preference)

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
                logger.error(f"Failed to parse streaming response: {e}")
                yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data'})}\n\n"
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
                "scheduled_date": scheduled_date_str,
                "exercises_json": exercises,
                "duration_minutes": body.duration_minutes or 45,
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
                "scheduled_date": generated_workout.scheduled_date.isoformat() if generated_workout.scheduled_date else None,
                "exercises": exercises_list,
                "exercises_json": generated_workout.exercises_json,
                "duration_minutes": generated_workout.duration_minutes,
                "total_time_ms": total_time_ms,
                "chunk_count": chunk_count,
            }

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


@router.post("/generate-from-mood-stream")
@limiter.limit("10/minute")
async def generate_mood_workout_streaming(request: Request, body: MoodWorkoutRequest):
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

            gemini_service = GeminiService()

            # Generate workout using streaming
            yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'message': 'Creating your {mood.value} workout...'})}\n\n"

            accumulated_text = ""
            chunk_count = 0

            async for chunk in gemini_service.generate_workout_plan_streaming(
                fitness_level=fitness_level,
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=params["duration_minutes"],
                focus_areas=None,
                intensity_preference=params["intensity_preference"],
                custom_prompt_override=prompt,
            ):
                accumulated_text += chunk
                chunk_count += 1

                if chunk_count % 5 == 0:
                    elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                    yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': len(accumulated_text), 'elapsed_ms': elapsed_ms})}\n\n"

            # Parse the response
            try:
                content = accumulated_text.strip()
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                workout_data = json.loads(content)
                exercises = workout_data.get("exercises", [])
                warmup = workout_data.get("warmup", [])
                cooldown = workout_data.get("cooldown", [])
                workout_name = workout_data.get("name", f"{mood.value.capitalize()} Quick Workout")
                workout_type = workout_data.get("type", params["workout_type_preference"])
                difficulty = workout_data.get("difficulty", params["intensity_preference"])
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
                "scheduled_date": datetime.now().isoformat(),
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
                "chunk_count": chunk_count,
                "mood": mood.value,
                "mood_emoji": params["mood_emoji"],
                "mood_color": params["mood_color"],
                "mood_checkin_id": mood_checkin_id,
                "motivational_message": motivational_message,
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
async def get_available_moods():
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


@router.get("/{user_id}/mood-history", response_model=MoodHistoryResponse)
async def get_mood_history(
    user_id: str,
    limit: int = 30,
    offset: int = 0,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/mood-analytics", response_model=MoodAnalyticsResponse)
async def get_mood_analytics(
    user_id: str,
    days: int = 30,
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
                except (ValueError, AttributeError):
                    pass

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
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}/mood-checkins/{checkin_id}/complete")
async def mark_mood_workout_completed(user_id: str, checkin_id: str):
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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/mood-today")
async def get_today_mood(user_id: str):
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
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/swap")
async def swap_workout_date(request: SwapWorkoutsRequest):
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
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/swap-exercise", response_model=Workout)
async def swap_exercise_in_workout(request: SwapExerciseRequest):
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

        # Re-index to RAG
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/add-exercise", response_model=Workout)
async def add_exercise_to_workout(request: AddExerciseRequest):
    """Add a new exercise to an existing workout."""
    logger.info(f"Adding exercise '{request.exercise_name}' to workout {request.workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Parse existing exercises
        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        # Get exercise details from library
        exercise_lib = get_exercise_library_service()
        exercise_data = exercise_lib.search_exercises(request.exercise_name, limit=1)

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
            # Create basic exercise entry if not found in library
            new_exercise = {
                "name": request.exercise_name,
                "sets": request.sets,
                "reps": request.reps,
                "rest_seconds": request.rest_seconds,
            }

        # Append the new exercise
        exercises.append(new_exercise)

        # Update the workout
        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_add"
        }

        updated = db.update_workout(request.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        # Log the change
        log_workout_change(
            request.workout_id,
            workout.get("user_id"),
            "exercise_add",
            "exercises_json",
            None,
            request.exercise_name
        )

        updated_workout = row_to_workout(updated)
        logger.info(f"Exercise '{request.exercise_name}' added successfully to workout {request.workout_id}")

        # Re-index to RAG
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/extend", response_model=Workout)
async def extend_workout(request: ExtendWorkoutRequest):
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

        # Get user preferences
        avoided_exercises = await get_user_avoided_exercises(request.user_id)
        avoided_muscles = await get_user_avoided_muscles(request.user_id)
        staple_exercises = await get_user_staple_exercises(request.user_id)

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
- Staple exercises to consider including: {', '.join(staple_exercises) if staple_exercises else 'None'}

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
        raise HTTPException(status_code=500, detail=str(e))
