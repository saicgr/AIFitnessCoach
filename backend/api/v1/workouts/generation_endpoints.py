"""Secondary endpoints for generation.  Sub-router included by main module.
Workout generation API endpoints (orchestrator).

This module combines all generation-related endpoints via sub-routers:
- Core generation: /generate, /generate-stream, /generate-onboarding
- Mood generation: /generate-from-mood-stream, /moods, mood history/analytics
- Workout operations: /swap, /swap-exercise, /add-exercise, /extend
- Comeback status: /comeback-status

Large endpoint groups are split into focused sub-modules:
- mood_generation.py: Mood-based workout generation
- workout_operations.py: Swap, add, extend operations
- generation_helpers.py: Shared helper functions (MET estimation, normalization)
"""
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
import asyncio
import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, get_user_today, target_date_to_utc_iso
from core.exceptions import safe_internal_error
from core.config import get_settings
from core.rate_limiter import user_limiter
from models.schemas import (
    Workout, GenerateWorkoutRequest, SwapWorkoutsRequest, SwapExerciseRequest,
    AddExerciseRequest, ExtendWorkoutRequest,
)
from services.gemini_service import GeminiService, validate_set_targets_strict
from services.exercise_library_service import get_exercise_library_service
from api.v1.workouts.utils import *  # Re-export hub for all workout sub-modules
from api.v1.workouts.generation_helpers import normalize_exercise_numeric_fields, _estimate_workout_met
from services.exercise_rag.service import get_exercise_rag_service
from services.adaptive_workout_service_helpers_part2 import get_user_set_type_preferences, build_set_type_context

logger = logging.getLogger(__name__)

router = APIRouter()
@router.post("/generate", response_model=Workout)
@user_limiter.limit("15/minute")
async def generate_workout(request: Request, *, body: GenerateWorkoutRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {body.user_id}")

    try:
        db = get_supabase_db()

        # Resolve gym_profile_id early for dedup checks
        dedup_gym_profile_id = body.gym_profile_id
        if not dedup_gym_profile_id:
            try:
                active_result = db.client.table("gym_profiles").select("id").eq(
                    "user_id", body.user_id
                ).eq("is_active", True).maybe_single().execute()
                if active_result and active_result.data:
                    dedup_gym_profile_id = active_result.data.get("id")
            except Exception as e:
                logger.warning(f"Failed to get active gym profile: {e}", exc_info=True)

        # Resolve timezone for premium gate checks
        _gen_tz = resolve_timezone(request, db, body.user_id)

        # Preferred-day gate: reject when scheduled_date falls outside the user's
        # preferred workout days unless force_non_preferred_day was set (mirrors
        # the same gate on /generate-stream). Keeps accidental / stale-client
        # calls from planting rest-day workouts that the home carousel would
        # then surface as TODAY.
        if body.scheduled_date and not body.force_non_preferred_day:
            from .today import _get_user_workout_days, _calculate_next_workout_date
            _gate_user = db.get_user(body.user_id)
            if _gate_user:
                _selected_days = _get_user_workout_days(_gate_user)
                if _selected_days:
                    try:
                        _weekday = datetime.strptime(body.scheduled_date, "%Y-%m-%d").weekday()
                    except ValueError:
                        _weekday = None
                    if _weekday is not None and _weekday not in _selected_days:
                        _today_str = get_user_today(_gen_tz)
                        _suggested = _calculate_next_workout_date(_selected_days, user_today_str=_today_str)
                        logger.info(
                            f"[PreferredDayGate] Rejecting /generate for user={body.user_id} "
                            f"scheduled_date={body.scheduled_date} (weekday={_weekday}, preferred={_selected_days}); "
                            f"suggested_date={_suggested}"
                        )
                        raise HTTPException(
                            status_code=409,
                            detail={
                                "error": "not_a_workout_day",
                                "scheduled_date": body.scheduled_date,
                                "suggested_date": _suggested,
                                "selected_days": _selected_days,
                            },
                        )

        # Duplicate check: return existing workout if one already exists for this date+profile
        placeholder_id = None
        if body.scheduled_date:
            try:
                sched = body.scheduled_date
                end_of_day = sched + "T23:59:59.999999+00:00" if len(sched) == 10 else sched
                query = db.client.table("workouts").select("*").eq(
                    "user_id", body.user_id
                ).gte(
                    "scheduled_date", sched
                ).lte(
                    "scheduled_date", end_of_day
                ).neq("status", "cancelled")
                if dedup_gym_profile_id:
                    query = query.eq("gym_profile_id", dedup_gym_profile_id)
                existing = query.limit(1).execute()
                if existing.data:
                    logger.info(f"✅ [Dedup] Workout already exists for {body.user_id} on {body.scheduled_date} (profile={dedup_gym_profile_id}), returning existing")
                    return row_to_workout(existing.data[0])
            except Exception as dedup_err:
                logger.warning(f"Dedup check failed, proceeding with generation: {dedup_err}", exc_info=True)

            # Premium gate check: enforce free-tier workout generation limits
            from core.premium_gate import check_premium_gate
            await check_premium_gate(body.user_id, "ai_workout_generation", _gen_tz)

            # Insert placeholder with status='generating' to prevent concurrent generation
            # This lets the streaming endpoint detect generation is already in progress
            try:
                import uuid
                placeholder_id = str(uuid.uuid4())
                placeholder_data = {
                    "id": placeholder_id,
                    "user_id": body.user_id,
                    "scheduled_date": body.scheduled_date,
                    "status": "generating",
                    "name": "Generating...",
                    "type": body.workout_type or "strength",
                    "difficulty": "medium",
                    "exercises_json": [],
                }
                if dedup_gym_profile_id:
                    placeholder_data["gym_profile_id"] = dedup_gym_profile_id
                db.client.table("workouts").insert(placeholder_data).execute()
                logger.info(f"🔒 [Dedup] Inserted placeholder {placeholder_id} for {body.user_id} on {body.scheduled_date} (profile={dedup_gym_profile_id})")
            except Exception as ph_err:
                logger.warning(f"Placeholder insert failed: {ph_err}", exc_info=True)
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
        training_experience = None

        if body.fitness_level and body.goals and body.equipment:
            fitness_level = body.fitness_level
            goals = body.goals
            equipment = body.equipment
            # Derive intensity from fitness level - beginners get 'easy', not 'medium'
            intensity_preference = get_intensity_from_fitness_level(fitness_level)
            workout_environment = None
        else:
            user = db.get_user(body.user_id)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            fitness_level = body.fitness_level or user.get("fitness_level")
            preferences = parse_json_field(user.get("preferences"), {})

            # Check for gym profile - load equipment/environment from profile if available
            gym_profile = None
            if body.gym_profile_id:
                # Specific profile requested — .single() raises PGRST116 on 0 rows
                # (e.g. id doesn't exist or was deleted), so guard with try/except.
                try:
                    profile_result = db.client.table("gym_profiles").select("*").eq("id", body.gym_profile_id).single().execute()
                    gym_profile = profile_result.data if profile_result and profile_result.data else None
                except Exception as e:
                    logger.warning(f"🏋️ [GymProfile] Requested profile {body.gym_profile_id} not found: {e}")
                    gym_profile = None
                if gym_profile:
                    logger.info(f"🏋️ [GymProfile] Using requested profile: {body.gym_profile_id}")
            else:
                # Try to get active profile
                try:
                    active_result = db.client.table("gym_profiles").select("*").eq("user_id", body.user_id).eq("is_active", True).single().execute()
                    gym_profile = active_result.data if active_result.data else None
                    if gym_profile:
                        logger.info(f"🏋️ [GymProfile] Using active profile: {gym_profile.get('name')} ({gym_profile.get('id')})")
                except Exception as e:
                    # No active profile found - will use user defaults
                    logger.debug(f"No active gym profile found: {e}")

            if gym_profile:
                # Load settings from gym profile
                gym_profile_id = gym_profile.get("id")
                equipment = body.equipment or gym_profile.get("equipment") or []
                equipment_details = gym_profile.get("equipment_details") or []
                workout_environment = gym_profile.get("workout_environment") or preferences.get("workout_environment")
                training_split = gym_profile.get("training_split")
                workout_days = gym_profile.get("workout_days") or []
                profile_goals = normalize_goals_list(gym_profile.get("goals"))
                # Parse user goals if it's a JSON string
                user_goals = normalize_goals_list(user.get("goals"))
                goals = normalize_goals_list(body.goals) if body.goals else (profile_goals if profile_goals else user_goals)
                focus_areas = gym_profile.get("focus_areas") or []

                logger.info(f"🏋️ [GymProfile] Profile equipment: {len(equipment)} items")
                logger.info(f"📍 [GymProfile] Environment: {workout_environment}")
                if training_split:
                    logger.info(f"📅 [GymProfile] Training split: {training_split}")
            else:
                # Fall back to user settings (parse JSON strings)
                goals = normalize_goals_list(body.goals) if body.goals else normalize_goals_list(user.get("goals"))
                equipment = body.equipment or parse_json_field(user.get("equipment"), [])
                equipment_details = parse_json_field(user.get("equipment_details"), [])
                workout_environment = preferences.get("workout_environment")
                focus_areas = []  # No focus areas when no gym profile
                training_split = user.get("training_split")  # Fallback to user record
                workout_days = parse_json_field(user.get("workout_days"), [])

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

            # Body Analyzer context — pulls the latest snapshot (composition +
            # posture findings) and renders a compact prompt block so the
            # generator can tune rep ranges / accessory work to the user's
            # current physique. Failure is non-blocking.
            body_analyzer_context = None
            try:
                ba_row = db.client.table("body_analyzer_snapshots").select(
                    "overall_rating, body_type, body_fat_percent, muscle_mass_percent, "
                    "symmetry_score, posture_findings, improvement_tips, created_at"
                ).eq("user_id", body.user_id).order(
                    "created_at", desc=True
                ).limit(1).execute()
                if ba_row and ba_row.data:
                    s = ba_row.data[0]
                    posture_findings = s.get("posture_findings") or []
                    posture_lines = "\n".join(
                        f"  - {p.get('issue')}: severity {p.get('severity')}, corrective {p.get('corrective_exercise_tag')}"
                        for p in posture_findings
                    )
                    body_analyzer_context = (
                        "## USER BODY ANALYZER SNAPSHOT\n"
                        f"- Overall rating: {s.get('overall_rating')}/100\n"
                        f"- Body type: {s.get('body_type') or user.get('body_type')}\n"
                        f"- Body fat: {s.get('body_fat_percent')}%\n"
                        f"- Muscle mass: {s.get('muscle_mass_percent')}%\n"
                        f"- Symmetry: {s.get('symmetry_score')}/100\n"
                        + (f"- Posture findings:\n{posture_lines}\n" if posture_lines else "")
                        + "Use this to bias accessory selection (e.g. unilateral work for low symmetry,"
                        " corrective exercises matching the posture tags, rep ranges tuned to body-type response)."
                    )
                    logger.info("💪 [Workout Generation] Body Analyzer context attached")
            except Exception as ba_err:
                logger.debug(f"[Workout Generation] Body Analyzer context unavailable: {ba_err}")

            # Get fitness assessment data for smarter workout personalization
            pushup_capacity = user.get("pushup_capacity")
            pullup_capacity = user.get("pullup_capacity")
            plank_capacity = user.get("plank_capacity")
            squat_capacity = user.get("squat_capacity")
            cardio_capacity = user.get("cardio_capacity")
            training_experience = user.get("training_experience")
            has_assessment = any([pushup_capacity, pullup_capacity, plank_capacity, squat_capacity, cardio_capacity, training_experience])
            if has_assessment:
                logger.info(f"💪 [Workout Generation] User has fitness assessment: pushups={pushup_capacity}, pullups={pullup_capacity}, plank={plank_capacity}, squats={squat_capacity}, cardio={cardio_capacity}, experience={training_experience}")

        # Fetch user's custom exercises
        logger.info(f"🏋️ [Workout Generation] Fetching custom exercises for user: {body.user_id}")
        custom_exercises = []
        try:
            custom_result = db.client.table("exercises").select(
                "name", "primary_muscle", "equipment", "default_sets", "default_reps"
            ).eq("is_custom", True).eq("created_by_user_id", body.user_id).execute()
            if custom_result.data:
                custom_exercises = custom_result.data
                exercise_names = [ex.get("name") for ex in custom_exercises]
                logger.info(f"✅ [Workout Generation] Found {len(custom_exercises)} custom exercises: {exercise_names}")
            else:
                logger.info(f"🏋️ [Workout Generation] No custom exercises found for user {body.user_id}")
        except Exception as e:
            logger.warning(f"⚠️ [Workout Generation] Failed to fetch custom exercises: {e}", exc_info=True)

        # Fetch ALL user preferences in PARALLEL for faster generation
        # This reduces ~900ms-1.8s of sequential DB calls to ~100-300ms
        logger.info(f"🚀 [Workout Generation] Fetching all user preferences in parallel for: {body.user_id}")
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
            get_user_avoided_exercises(body.user_id),
            get_user_avoided_muscles(body.user_id),
            get_user_staple_exercises(body.user_id, gym_profile_id=gym_profile_id, scheduled_date=body.scheduled_date),
            get_user_rep_preferences(body.user_id),
            get_user_progression_context(body.user_id),
            get_user_workout_patterns(body.user_id),
            get_user_hormonal_context(body.user_id, timezone_str=resolve_timezone(request, db, body.user_id)),
            get_user_set_type_preferences(body.user_id, supabase_client=db.client),
            get_active_injuries_with_muscles(body.user_id),
            get_user_consistency_mode(body.user_id),
            get_recently_used_exercises(body.user_id),  # lookback scaled below
            get_user_variation_percentage(body.user_id),
            get_user_favorite_exercises(body.user_id),
            get_user_exercise_queue(body.user_id),
            get_user_favorite_workouts(body.user_id),
        )
        logger.info(f"✅ [Workout Generation] All user preferences fetched in parallel")
        # Scale lookback: higher variation → longer lookback to catch more recently used exercises
        lookback_days = 7 + max(0, (variation_percentage - 10)) // 5
        if lookback_days > 7:
            recently_used_exercises = await get_recently_used_exercises(body.user_id, days=lookback_days)
            logger.info(f"🔄 [Variety] Extended lookback to {lookback_days} days (variation={variation_percentage}%)")

        # Fetch exercises for hard-exclusion (scaled by variation_percentage)
        # 30% → 7 days, 50% → 11 days, 80% → 17 days, 100% → 21 days
        hard_exclude_days = max(7, 7 + max(0, (variation_percentage - 10)) // 5)
        very_recently_used_exercises = await get_recently_used_exercises(body.user_id, days=hard_exclude_days)
        logger.info(f"🔄 [Variety] Hard-exclude window: {hard_exclude_days} days, found {len(very_recently_used_exercises)} exercises")

        # Fetch recent workout name words to avoid repetitive names
        avoid_name_words = await get_recent_workout_name_words(body.user_id, days=lookback_days if lookback_days > 7 else 14)
        logger.info(f"🔄 [Consistency] Mode: {consistency_mode}, Recently used: {len(recently_used_exercises) if recently_used_exercises else 0}, Variation: {variation_percentage}%")

        # Merge adjacent-day exercises into the avoid list for variety
        if body.adjacent_day_exercises:
            existing_lower = {e.lower() for e in (avoided_exercises or [])}
            new_avoids = [e for e in body.adjacent_day_exercises if e.lower() not in existing_lower]
            if new_avoids:
                avoided_exercises = list(avoided_exercises or []) + new_avoids
                logger.info(f"🔄 [Variety] Added {len(new_avoids)} adjacent-day exercises to avoid list")

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
            focus_area = body.focus_areas[0] if body.focus_areas else "full_body"

            # Calculate exercise count based on duration and fitness level.
            # Resolve target from request body → gym profile → user preferences
            # so the user's saved workout_duration is honored when the client
            # doesn't forward it.
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

            # Handle duration ranges (e.g., user selected "45-60 min" during onboarding)
            # Use the MAX duration for exercise cap to give appropriate variety for longer sessions
            if target_duration_max:
                effective_duration = target_duration_max
            elif target_duration_min:
                effective_duration = target_duration_min
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
                workout_type_preference=body.workout_type or "strength",
                favorite_exercises=favorite_exercises if favorite_exercises else None,
                queued_exercises=exercise_queue if exercise_queue else None,
                batch_offset=body.batch_offset,
                very_recently_used_exercises=very_recently_used_exercises,
            )

            if rag_exercises:
                # Use RAG-selected exercises - these have correct names from DB
                logger.info(f"✅ [RAG] Selected {len(rag_exercises)} exercises from library")
                workout_data = await gemini_service.generate_workout_from_library(
                    exercises=rag_exercises,
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    duration_minutes=target_duration,
                    focus_areas=body.focus_areas if body.focus_areas else [focus_area],
                    intensity_preference=intensity_preference,
                    workout_type_preference=body.workout_type,
                    avoid_name_words=avoid_name_words,
                    user_dob=user.get("date_of_birth") if user else None,
                    injuries=injury_names if injury_names else None,
                )
            else:
                # Fallback to free-form generation if RAG returns no exercises
                logger.warning(f"⚠️ [RAG] No exercises found, falling back to free-form generation")
                workout_data = await gemini_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    equipment=equipment if isinstance(equipment, list) else [],
                    duration_minutes=target_duration,
                    focus_areas=body.focus_areas,
                    avoid_name_words=avoid_name_words,
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
                    body_analyzer_context=body_analyzer_context,
                    training_split=training_split,
                    workout_days=workout_days if workout_days else None,
                    # Fitness assessment for smarter workout personalization
                    pushup_capacity=pushup_capacity,
                    pullup_capacity=pullup_capacity,
                    plank_capacity=plank_capacity,
                    squat_capacity=squat_capacity,
                    cardio_capacity=cardio_capacity,
                    training_experience=training_experience,
                    user_dob=user.get("date_of_birth") if user else None,
                    user_id=body.user_id,
                    workout_weight_unit=user.get("workout_weight_unit") or user.get("weight_unit") or "lbs",
                )

            # Ensure workout_data is a dict (guard against Gemini returning a string)
            if isinstance(workout_data, str):
                try:
                    workout_data = json.loads(workout_data)
                except (json.JSONDecodeError, ValueError):
                    logger.error(f"workout_data is an unparseable string: {str(workout_data)[:200]}", exc_info=True)
                    workout_data = {}
            if not isinstance(workout_data, dict):
                logger.error(f"workout_data is not a dict: type={type(workout_data).__name__}")
                workout_data = {}

            exercises = workout_data.get("exercises", [])
            exercises = normalize_exercise_numeric_fields(exercises)

            # Normalize equipment values — Gemini may echo snake_case from user profile
            from services.exercise_rag.utils import normalize_equipment_value
            for ex in exercises:
                raw_eq = ex.get("equipment", "")
                if raw_eq and "_" in raw_eq:
                    ex["equipment"] = normalize_equipment_value(raw_eq, ex.get("name", ""))

            workout_name = workout_data.get("name", "Generated Workout")
            difficulty = workout_data.get("difficulty", intensity_preference)
            workout_description = workout_data.get("description")

            # Infer workout type from focus area for PPL tracking
            # This ensures workout_type is set correctly even when Gemini doesn't specify it
            from api.v1.workouts.utils import infer_workout_type_from_focus

            raw_type = workout_data.get("type", body.workout_type)
            if body.focus_areas and len(body.focus_areas) > 0:
                workout_type = infer_workout_type_from_focus(body.focus_areas[0])
                logger.info(f"🎯 [Type] Inferred workout type '{workout_type}' from focus '{body.focus_areas[0]}'")
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
            from services.exercise_rag.filters import is_similar_exercise, get_movement_pattern, filter_by_equipment
            from services.exercise_rag.utils import infer_equipment_from_name, strip_dedup_suffix

            # Pre-pass: strip "(N)" import-duplicate suffixes so base names match
            # in the similarity check below (e.g. Burpee(1) → Burpee).
            for _ex in exercises:
                _raw = _ex.get("name") or _ex.get("exercise_name") or ""
                _clean = strip_dedup_suffix(_raw)
                if _clean and _clean != _raw:
                    _ex["name"] = _clean

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

            # Phase 3.5: Hard equipment filter - reject exercises requiring unavailable equipment
            if equipment and exercises:
                equipment_compatible = []
                for ex in exercises:
                    ex_equip = (ex.get("equipment") or "").strip()
                    ex_name = ex.get("name", "") or ex.get("exercise_name", "")
                    if not ex_equip or ex_equip.lower() in ("bodyweight", "body weight", "none", ""):
                        ex_equip = infer_equipment_from_name(ex_name)
                    if filter_by_equipment(ex_equip, equipment, ex_name):
                        equipment_compatible.append(ex)
                    else:
                        filtered_exercises.append(ex)
                        logger.warning(
                            f"[Equipment Filter] Removed '{ex_name}' - "
                            f"requires '{ex_equip}', user has: {equipment}"
                        )
                if len(equipment_compatible) < len(exercises):
                    removed_count = len(exercises) - len(equipment_compatible)
                    logger.info(
                        f"[Equipment Filter] Removed {removed_count} exercises "
                        f"with incompatible equipment"
                    )
                    exercises = equipment_compatible

            # Phase 3: Validate equipment utilization - warn if workouts don't match user's equipment
            # This helps identify when Gemini is generating suboptimal equipment choices
            equipment_lower = [eq.lower() for eq in equipment] if equipment else []
            _bw_aliases = {"bodyweight", "none", "no_equipment", ""}
            has_gym_equipment = any(eq not in _bw_aliases for eq in equipment_lower)

            if has_gym_equipment and exercises:
                bw_keywords = {"bodyweight", "body weight", ""}
                bw_exercises = [ex for ex in exercises if (ex.get("equipment", "") or "").lower() in bw_keywords]
                equip_exercises = [ex for ex in exercises if (ex.get("equipment", "") or "").lower() not in bw_keywords]
                bodyweight_count = len(bw_exercises)
                bodyweight_ratio = bodyweight_count / len(exercises) if exercises else 0

                if bodyweight_ratio > 0.3 and bodyweight_count > 1:
                    # Trim excess bodyweight exercises — keep at most 1
                    exercises = equip_exercises + bw_exercises[:1]
                    removed_count = bodyweight_count - 1
                    logger.info(
                        f"🔧 [Equipment] Trimmed to {len(exercises)} exercises "
                        f"(removed {removed_count} excess bodyweight, ratio was {bodyweight_ratio:.0%})"
                    )
                elif bodyweight_ratio > 0.4:
                    logger.warning(
                        f"⚠️ [Equipment] High bodyweight ratio ({bodyweight_ratio:.0%}) "
                        f"despite gym equipment available: {equipment}"
                    )

                # Log unused equipment for monitoring
                if exercises:
                    used_equipment = set(ex.get("equipment", "").lower() for ex in exercises)
                    unused_equipment = [eq for eq in equipment if eq.lower() not in used_equipment and eq != "bodyweight"]
                    if unused_equipment:
                        logger.info(f"📋 [Equipment] Unused equipment: {unused_equipment}")

                # Check each non-bodyweight equipment type is used
                _equip_name_hints = {
                    "kettlebell": ["kettlebell", "kb "],
                    "kettlebells": ["kettlebell", "kb "],
                    "resistance_bands": ["band", "resistance"],
                    "pull_up_bar": ["pull-up", "pull up", "chin-up", "chin up", "hanging"],
                    "trx": ["trx", "suspension"],
                    "medicine_ball": ["medicine ball", "med ball"],
                }
                for eq_key, hints in _equip_name_hints.items():
                    if eq_key in equipment_lower:
                        used = sum(
                            1 for ex in exercises
                            if any(h in (ex.get("equipment", "") or "").lower() or h in (ex.get("name", "") or "").lower() for h in hints)
                        )
                        if used == 0:
                            logger.debug(f"[Equipment] {eq_key} available but not used in this workout")

            # Auto-substitute filtered exercises with safe alternatives
            if filtered_exercises and exercises:
                exercises = await auto_substitute_filtered_exercises(
                    exercises=exercises,
                    filtered_exercises=filtered_exercises,
                    user_id=body.user_id,
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
            one_rm_data = await get_user_1rm_data(body.user_id)
            training_intensity = await get_user_training_intensity(body.user_id)
            intensity_overrides = await get_user_intensity_overrides(body.user_id)

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
            if not (body.fitness_level and body.goals and body.equipment):
                # We already fetched user above, get age from there
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

                    # Full-body muscle group coverage check
                    missing_groups = focus_validation.get("missing_muscle_groups", [])
                    if missing_groups:
                        friendly = {"legs": "Legs/Glutes", "back": "Back/Pull", "chest_push": "Chest/Shoulders/Push"}
                        missing_names = [friendly.get(g, g) for g in missing_groups]
                        logger.error(
                            f"❌ [Full Body Validation] Workout '{workout_name}' labeled full_body but MISSING: "
                            f"{', '.join(missing_names)}. Exercises: {[ex.get('name') for ex in exercises]}. "
                            f"This is an AI generation error — workout should cover all major muscle groups."
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
                # Count distinct exercises, not set entries. Advanced
                # techniques like "Added failure set to X" can duplicate
                # the same exercise as multiple list entries; we only
                # want to reject workouts that are truly 1-2 exercises.
                distinct_exercise_names = {
                    (ex.get("name") or "").strip().lower()
                    for ex in exercises
                    if (ex.get("name") or "").strip()
                }
                if len(distinct_exercise_names) < MIN_EXERCISES_REQUIRED:
                    _eq_for_log = equipment if isinstance(equipment, list) else []
                    logger.error(
                        f"❌ [Exercise Count] Workout '{workout_name}' has only "
                        f"{len(distinct_exercise_names)} distinct exercises "
                        f"(minimum required: {MIN_EXERCISES_REQUIRED}). "
                        f"Equipment={_eq_for_log}, focus={focus_areas}. "
                        f"Likely candidate pool too small — aborting insert."
                    )
                    # Return a structured 422 so the Flutter client can surface
                    # a "your gym profile needs more equipment for this focus"
                    # message instead of silently showing a 2-exercise workout.
                    raise HTTPException(
                        status_code=422,
                        detail={
                            "code": "EXERCISE_POOL_TOO_SMALL",
                            "message": (
                                f"Only {len(distinct_exercise_names)} exercises could be selected "
                                f"for this focus/equipment combination (minimum {MIN_EXERCISES_REQUIRED}). "
                                f"Add more equipment to your gym profile or pick a different focus."
                            ),
                            "distinct_exercise_count": len(distinct_exercise_names),
                            "minimum_required": MIN_EXERCISES_REQUIRED,
                            "focus_areas": focus_areas,
                            "equipment_count": len(_eq_for_log),
                        },
                    )

        except Exception as ai_error:
            logger.error(f"AI workout generation failed: {ai_error}", exc_info=True)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate workout: {str(ai_error)}"
            )

        # Compute estimated calories using MET-based formula
        _user_weight_kg = float(user.get("weight_kg") or user.get("weight") or 70) if user else 70.0
        _user_weight_kg = max(30.0, min(_user_weight_kg, 250.0))
        _effective_duration = workout_data.get("estimated_duration_minutes") or target_duration
        _met = _estimate_workout_met(exercises, workout_type, difficulty)
        _estimated_calories = round(_met * _user_weight_kg * (_effective_duration / 60.0))
        logger.info(f"[Calories] MET={_met:.1f}, weight={_user_weight_kg}kg, duration={_effective_duration}min -> {_estimated_calories} cal")

        workout_db_data = {
            "user_id": body.user_id,
            "gym_profile_id": gym_profile_id,  # Link workout to gym profile
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "description": workout_description,
            "scheduled_date": target_date_to_utc_iso(
                body.scheduled_date or get_user_today(resolve_timezone(request, db, body.user_id)),
                resolve_timezone(request, db, body.user_id),
            ),
            "exercises_json": exercises,
            "duration_minutes": target_duration,
            "duration_minutes_min": target_duration_min,
            "duration_minutes_max": target_duration_max,
            "estimated_calories": _estimated_calories,
            "generation_method": "ai",
            "generation_source": "gemini_generation",
        }

        try:
            created = db.create_workout(workout_db_data)
        except Exception as insert_err:
            # Retry without estimated_calories if column doesn't exist yet
            if 'PGRST204' in str(insert_err) and 'estimated_calories' in str(insert_err):
                logger.warning("[Calories] estimated_calories column not in schema cache, retrying without it", exc_info=True)
                workout_db_data.pop('estimated_calories', None)
                created = db.create_workout(workout_db_data)
            else:
                raise
        logger.info(f"Workout generated: id={created['id']}, gym_profile_id={gym_profile_id}")

        # Delete placeholder now that real workout exists
        if placeholder_id:
            try:
                db.client.table("workouts").delete().eq("id", placeholder_id).execute()
                logger.info(f"🔓 [Dedup] Deleted placeholder {placeholder_id}")
            except Exception as e:
                logger.warning(f"Failed to delete placeholder: {e}", exc_info=True)

        # Log workout change synchronously (quick, important for audit trail)
        log_workout_change(
            workout_id=created['id'],
            user_id=body.user_id,
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
                logger.warning(f"Background: Failed to index workout to RAG: {e}", exc_info=True)

        background_tasks.add_task(_bg_index_rag)

        # Track premium gate usage after successful generation
        from core.premium_gate import track_premium_usage
        background_tasks.add_task(track_premium_usage, body.user_id, "ai_workout_generation", _gen_tz)

        return generated_workout

    except HTTPException:
        # Clean up placeholder on error
        if placeholder_id:
            try:
                db.client.table("workouts").delete().eq("id", placeholder_id).execute()
            except Exception as e:
                logger.warning(f"Placeholder cleanup failed: {e}", exc_info=True)
        raise
    except Exception as e:
        # Clean up placeholder on error
        if placeholder_id:
            try:
                db.client.table("workouts").delete().eq("id", placeholder_id).execute()
            except Exception as cleanup_err:
                logger.warning(f"Placeholder cleanup failed: {cleanup_err}", exc_info=True)
        logger.error(f"Failed to generate workout: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")


# Streaming generation endpoint is in generation_streaming.py sub-router.
# Mood history/analytics endpoints are in mood_analytics.py sub-router.
# Swap, add-exercise, extend, and onboarding endpoints are in sub-modules:
# - workout_operations.py (swap, swap-exercise, add-exercise, extend)
# - Onboarding generation is included via the generation router in __init__.py
# These are included via router.include_router() at the top of this file.
