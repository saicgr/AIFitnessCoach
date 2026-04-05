"""
Mood-based workout generation and mood history/analytics endpoints.

Endpoints:
- POST /generate-from-mood-stream - Generate quick workout based on mood
- GET /moods - Get available mood options
- GET /{user_id}/mood-history - Get mood check-in history
- GET /{user_id}/mood-analytics - Get mood analytics and patterns
- PUT /{user_id}/mood-checkins/{checkin_id}/complete - Mark mood workout completed
- GET /{user_id}/mood-today - Get today's mood check-in
- GET /{user_id}/mood-weekly - Get weekly mood data
- GET /{user_id}/mood-calendar - Get monthly mood calendar
"""
from core.db import get_supabase_db
import json
import asyncio
from datetime import datetime, timedelta
from typing import List, AsyncGenerator, Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from fastapi.responses import StreamingResponse

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from core.timezone_utils import resolve_timezone, get_user_today, target_date_to_utc_iso
from services.gemini_service import GeminiService, validate_set_targets_strict
from services.mood_workout_service import mood_workout_service, MoodType
from services.user_context_service import user_context_service
from services.warmup_stretch_service import get_warmup_stretch_service

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    normalize_goals_list,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    get_user_staple_exercises,
    get_staple_names,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    apply_1rm_weights_to_exercises,
    get_intensity_from_fitness_level,
    get_user_rep_preferences,
    get_user_progression_context,
    get_user_hormonal_context,
    get_user_strength_history,
    get_user_favorite_exercises,
    get_user_exercise_queue,
    validate_and_cap_exercise_parameters,
    get_user_comeback_status,
    build_progression_philosophy_prompt,
)
from .generation_helpers import normalize_exercise_numeric_fields

router = APIRouter()
logger = get_logger(__name__)


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
    """Generate a quick workout based on user's current mood."""
    logger.info(f"🎯 Mood workout generation for user {body.user_id}, mood: {body.mood}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()
        mood_checkin_id = None

        try:
            try:
                mood = mood_workout_service.validate_mood(body.mood)
            except ValueError as e:
                yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"
                return

            db = get_supabase_db()

            user = db.get_user(body.user_id)
            if not user:
                yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                return

            fitness_level = user.get("fitness_level", "intermediate")
            goals = user.get("goals", [])
            equipment = user.get("equipment", [])

            params = mood_workout_service.get_workout_params(
                mood=mood,
                user_fitness_level=fitness_level,
                user_goals=goals,
                user_equipment=equipment,
                duration_override=body.duration_minutes,
            )

            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'mood': mood.value, 'mood_emoji': params['mood_emoji'], 'ttfb_ms': first_chunk_time})}\n\n"

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

            prompt = mood_workout_service.build_generation_prompt(
                mood=mood,
                user_fitness_level=fitness_level,
                user_goals=goals,
                user_equipment=equipment,
                duration_minutes=params["duration_minutes"],
            )

            yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'message': 'Creating your ' + mood.value + ' workout...'})}\n\n"

            from google.genai import types
            from core.config import get_settings
            from core.gemini_client import get_genai_client
            from models.gemini_schemas import GeneratedWorkoutResponse

            settings = get_settings()
            client = get_genai_client()

            try:
                gemini_start = datetime.now()
                response = await client.aio.models.generate_content(
                    model=settings.gemini_model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=GeneratedWorkoutResponse,
                        temperature=0.7,
                        max_output_tokens=4096,
                    ),
                )
                gemini_time_ms = (datetime.now() - gemini_start).total_seconds() * 1000
                logger.info(f"⚡ [Mood Workout] Gemini non-streaming completed in {gemini_time_ms:.0f}ms")

                content = response.text.strip() if response.text else ""
                if not content:
                    raise ValueError("Empty response from Gemini")

                workout_data = json.loads(content)

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

            try:
                exercises = workout_data.get("exercises", [])
                exercises = normalize_exercise_numeric_fields(exercises)

                warmup_stretch_svc = get_warmup_stretch_service()

                user_injuries = user.get("injuries", []) if user else []
                if isinstance(user_injuries, str):
                    user_injuries = [user_injuries] if user_injuries else []

                training_split = "full_body"
                if params.get("workout_type_preference") == "cardio":
                    training_split = "cardio"
                elif params.get("workout_type_preference") == "strength":
                    training_split = "full_body"

                warmup = await warmup_stretch_svc.generate_warmup(
                    exercises=exercises,
                    duration_minutes=params.get("warmup_duration", 3),
                    injuries=user_injuries if user_injuries else None,
                    user_id=body.user_id,
                    training_split=training_split,
                )
                logger.info(f"🔥 [Mood Workout] Generated {len(warmup)} warmup exercises using algorithm")

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

                one_rm_data = await get_user_1rm_data(body.user_id)
                training_intensity = await get_user_training_intensity(body.user_id)
                intensity_overrides = await get_user_intensity_overrides(body.user_id)

                if one_rm_data and exercises:
                    exercises = apply_1rm_weights_to_exercises(
                        exercises, one_rm_data, training_intensity, intensity_overrides
                    )
                    logger.info(f"💪 [Mood Workout] Applied 1RM-based weights to exercises")

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

            workout_db_data = {
                "user_id": body.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "description": workout_description,
                "scheduled_date": target_date_to_utc_iso(
                    params.get("scheduled_date") or get_user_today(resolve_timezone(request, db, body.user_id)),
                    resolve_timezone(request, db, body.user_id),
                ),
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

            if mood_checkin_id:
                try:
                    db.client.table("mood_checkins").update({
                        "workout_generated": True,
                        "workout_id": workout_id,
                    }).eq("id", mood_checkin_id).execute()
                except Exception as e:
                    logger.warning(f"⚠️ Failed to update mood check-in: {e}")

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
                "gemini_time_ms": gemini_time_ms,
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
    checkins: List[Dict[str, Any]]
    total_count: int
    has_more: bool


class MoodAnalyticsResponse(BaseModel):
    summary: Dict[str, Any]
    patterns: List[Dict[str, Any]]
    streaks: Dict[str, Any]
    recommendations: List[str]


class MoodDayEntry(BaseModel):
    mood: str
    emoji: str
    color: str
    time: str


class MoodDayData(BaseModel):
    date: str
    day_name: str
    moods: List[MoodDayEntry]
    primary_mood: Optional[str] = None
    checkin_count: int
    workout_completed: bool


class MoodWeeklySummary(BaseModel):
    total_checkins: int
    avg_mood_score: float
    trend: str


class MoodWeeklyResponse(BaseModel):
    days: List[MoodDayData]
    summary: MoodWeeklySummary


class MoodCalendarDay(BaseModel):
    moods: List[str]
    primary_mood: str
    color: str
    checkin_count: int


class MoodCalendarSummary(BaseModel):
    days_with_checkins: int
    total_checkins: int
    most_common_mood: Optional[str] = None


class MoodCalendarResponse(BaseModel):
    month: int
    year: int
    days: Dict[str, Optional[MoodCalendarDay]]
    summary: MoodCalendarSummary


# The remaining mood history/analytics/calendar endpoints are large but are
# pure read-only DB queries. They stay in generation.py as they are referenced
# from there via the router. They will be imported by generation.py.
