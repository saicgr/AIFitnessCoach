"""
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
from core.db import get_supabase_db
from .generation_endpoints import router as _endpoints_router, generate_workout

import hashlib
import json
import asyncio
import re
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
from core.timezone_utils import resolve_timezone, get_user_today, target_date_to_utc_iso

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
    get_recent_workout_name_words,
)
from services.adaptive_workout_service import (
    apply_age_caps,
    get_senior_workout_prompt_additions,
    get_user_set_type_preferences,
    build_set_type_context,
)

from .generation_helpers import (
    _estimate_workout_met,
    ensure_parsed_dict,
    ensure_exercises_are_dicts,
    normalize_exercise_numeric_fields,
)
from .mood_generation import router as mood_router, MoodWorkoutRequest
from .workout_operations import router as operations_router
from .mood_analytics import router as mood_analytics_router
from .generation_streaming import router as streaming_router

router = APIRouter()
logger = get_logger(__name__)

# Include sub-routers for mood, operations, streaming, and analytics endpoints
router.include_router(mood_router)
router.include_router(operations_router)
router.include_router(mood_analytics_router)
router.include_router(streaming_router)


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
                logger.warning(f"Dedup check for pre-cache failed: {e}", exc_info=True)

            # Use the existing generate_workout function
            from models.schemas import GenerateWorkoutRequest
            from starlette.requests import Request as StarletteRequest
            from starlette.datastructures import Headers

            # Try to get user's active gym profile
            gym_profile_id = None
            try:
                active_result = db.client.table("gym_profiles").select("id").eq(
                    "user_id", user_id
                ).eq(
                    "is_active", True
                ).maybe_single().execute()
                if active_result.data:
                    gym_profile_id = active_result.data.get("id")
            except Exception as e:
                logger.warning(f"Failed to get active gym profile: {e}", exc_info=True)

            gen_body = GenerateWorkoutRequest(
                user_id=user_id,
                scheduled_date=target_date,
                gym_profile_id=gym_profile_id,
            )

            # Build a minimal Starlette Request for the endpoint
            dummy_scope = {"type": "http", "method": "POST", "path": "/api/v1/workouts/generate", "headers": []}
            dummy_request = StarletteRequest(scope=dummy_scope)
            # Attach state for rate limiter / timezone resolution
            dummy_request.state.user_id = user_id

            result = await generate_workout(
                dummy_request,
                body=gen_body,
                background_tasks=BackgroundTasks(),
                current_user={"id": user_id},
            )
            logger.info(f"[NEXT-DAY] Successfully pre-cached workout for {user_id} on {target_date}: "
                        f"{result.name if result else 'unknown'}")

        except Exception as e:
            logger.error(f"[NEXT-DAY] Failed to pre-cache workout for {user_id} on {target_date}: {e}", exc_info=True)


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



# Include secondary endpoints
router.include_router(_endpoints_router)
