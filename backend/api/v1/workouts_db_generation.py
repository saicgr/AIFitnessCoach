"""
Workout generation, streaming, and suggestion endpoints.

Sub-router included by workouts_db.py main router.
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
from fastapi.responses import StreamingResponse
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional, AsyncGenerator
from datetime import datetime
import json
import asyncio

from core.supabase_db import get_supabase_db
from core.logger import get_logger, set_log_context
from core.rate_limiter import limiter
from core.timezone_utils import resolve_timezone, get_user_today, target_date_to_utc_iso
from core.generation_cache import generation_cache_key, get_cached_generation, set_cached_generation
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import Workout, GenerateWorkoutRequest
from services.gemini_service import GeminiService

from .workouts_db_helpers import (
    ensure_workout_data_dict,
    normalize_goals_list,
    parse_json_field,
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    WorkoutSuggestionRequest,
    WorkoutSuggestion,
    WorkoutSuggestionsResponse,
)

router = APIRouter()
logger = get_logger(__name__)


async def _background_log_generation(user_id: str, workout_id: str, workout_name: str, workout_type: str, exercises_count: int, duration_minutes: int):
    """Background task: Log workout generation analytics (non-critical)."""
    set_log_context(user_id=f"...{user_id[-4:]}" if len(user_id) > 4 else user_id)
    try:
        await log_user_activity(
            user_id=user_id,
            action="workout_generation",
            endpoint="/api/v1/workouts-db/generate",
            message=f"Generated workout: {workout_name}",
            metadata={
                "workout_id": workout_id,
                "workout_type": workout_type,
                "exercises_count": exercises_count,
                "duration_minutes": duration_minutes,
            },
            status_code=200
        )
    except Exception as e:
        logger.warning(f"Background: Failed to log generation activity: {e}", exc_info=True)


async def _background_index_rag(workout: Workout):
    """Background task: Index workout to RAG (non-critical)."""
    try:
        await index_workout_to_rag(workout)
    except Exception as e:
        logger.warning(f"Background: Failed to index workout to RAG: {e}", exc_info=True)


@router.post("/generate", response_model=Workout)
@limiter.limit("5/minute")
async def generate_workout(request: Request, body: GenerateWorkoutRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {body.user_id}")

    try:
        db = get_supabase_db()

        primary_goal = None
        muscle_focus_points = None
        user_dob = None

        if body.fitness_level and body.goals and body.equipment:
            fitness_level = body.fitness_level
            goals = body.goals
            equipment = body.equipment
            user = db.get_user(body.user_id)
            if user:
                user_dob = user.get("date_of_birth")
        else:
            user = db.get_user(body.user_id)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            fitness_level = body.fitness_level or user.get("fitness_level")
            goals = body.goals or user.get("goals", [])
            equipment = body.equipment or user.get("equipment", [])
            primary_goal = user.get("primary_goal")
            muscle_focus_points = user.get("muscle_focus_points")
            user_dob = user.get("date_of_birth")

        cache_params = {
            "fitness_level": fitness_level,
            "goals": goals if isinstance(goals, list) else [],
            "equipment": equipment if isinstance(equipment, list) else [],
            "duration_minutes": body.duration_minutes or 45,
            "focus_areas": body.focus_areas,
            "workout_type": body.workout_type,
            "primary_goal": primary_goal,
            "muscle_focus_points": muscle_focus_points,
        }
        cache_key = generation_cache_key(body.user_id, cache_params)
        cached_workout_data = await get_cached_generation(cache_key)

        if cached_workout_data:
            exercises = cached_workout_data.get("exercises", [])
            workout_name = cached_workout_data.get("name", "Generated Workout")
            workout_type = cached_workout_data.get("type", body.workout_type or "strength")
            difficulty = cached_workout_data.get("difficulty", "medium")
            logger.info(f"Using cached workout generation for user {body.user_id}")
        else:
            gemini_service = GeminiService()

            try:
                workout_data = await gemini_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    equipment=equipment if isinstance(equipment, list) else [],
                    duration_minutes=body.duration_minutes or 45,
                    focus_areas=body.focus_areas,
                    primary_goal=primary_goal,
                    muscle_focus_points=muscle_focus_points,
                    user_dob=user_dob,
                )

                workout_data = ensure_workout_data_dict(workout_data, context="generate")

                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", "Generated Workout")
                workout_type = workout_data.get("type", body.workout_type or "strength")
                difficulty = workout_data.get("difficulty", "medium")

                await set_cached_generation(cache_key, workout_data)

            except Exception as ai_error:
                logger.error(f"AI workout generation failed: {ai_error}", exc_info=True)
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to generate workout: {str(ai_error)}"
                )

        workout_db_data = {
            "user_id": body.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": target_date_to_utc_iso(
                body.scheduled_date or get_user_today(resolve_timezone(request, db, body.user_id)),
                resolve_timezone(request, db, body.user_id),
            ),
            "exercises_json": exercises,
            "duration_minutes": body.duration_minutes or 45,
            "generation_method": "ai",
            "generation_source": "gemini_generation",
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Workout generated: id={created['id']}")

        log_workout_change(
            workout_id=created['id'],
            user_id=body.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={"name": workout_name, "exercises_count": len(exercises)}
        )

        generated_workout = row_to_workout(created)

        background_tasks.add_task(_background_index_rag, generated_workout)
        background_tasks.add_task(
            _background_log_generation,
            user_id=body.user_id,
            workout_id=created['id'],
            workout_name=workout_name,
            workout_type=workout_type,
            exercises_count=len(exercises),
            duration_minutes=body.duration_minutes or 45,
        )

        return generated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout: {e}", exc_info=True)
        await log_user_error(
            user_id=body.user_id,
            action="workout_generation",
            error=e,
            endpoint="/api/v1/workouts-db/generate",
            metadata={"workout_type": body.workout_type},
            status_code=500
        )
        raise safe_internal_error(e, "workouts_db")


@router.post("/generate-stream")
@limiter.limit("5/minute")
async def generate_workout_streaming(request: Request, body: GenerateWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a workout with streaming response for faster perceived performance.

    Returns Server-Sent Events (SSE) stream:
    - 'chunk' events with partial JSON as it generates
    - 'done' event with the complete workout object when finished
    - 'error' event if something fails
    """
    logger.info(f"[Streaming] Generating workout for user {body.user_id}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        try:
            db = get_supabase_db()

            user_dob = None
            if body.fitness_level and body.goals and body.equipment:
                fitness_level = body.fitness_level
                goals = body.goals
                equipment = body.equipment
                user = db.get_user(body.user_id)
                if user:
                    user_dob = user.get("date_of_birth")
            else:
                user = db.get_user(body.user_id)
                if not user:
                    yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                    return

                fitness_level = body.fitness_level or user.get("fitness_level")
                goals = body.goals or user.get("goals", [])
                equipment = body.equipment or user.get("equipment", [])
                user_dob = user.get("date_of_birth")

            gemini_service = GeminiService()
            content_chunks = []

            async for chunk in gemini_service.generate_workout_plan_streaming(
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=body.duration_minutes or 45,
                focus_areas=body.focus_areas,
                user_dob=user_dob,
            ):
                content_chunks.append(chunk)
                yield f"event: chunk\ndata: {json.dumps({'chunk': chunk})}\n\n"

            full_content = "".join(content_chunks)
            content = full_content.strip()
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            workout_data = json.loads(content.strip())

            workout_data = ensure_workout_data_dict(workout_data, context="streaming")
            if not workout_data:
                yield f"event: error\ndata: {json.dumps({'error': 'AI response was not valid JSON'})}\n\n"
                return

            if "exercises" not in workout_data or not workout_data["exercises"]:
                yield f"event: error\ndata: {json.dumps({'error': 'AI response missing exercises'})}\n\n"
                return

            user_tz = resolve_timezone(request, db, body.user_id)
            workout_db_data = {
                "user_id": body.user_id,
                "name": workout_data.get("name", "Generated Workout"),
                "type": workout_data.get("type", body.workout_type or "strength"),
                "difficulty": workout_data.get("difficulty", "medium"),
                "scheduled_date": target_date_to_utc_iso(
                    body.scheduled_date or get_user_today(user_tz), user_tz,
                ),
                "exercises_json": workout_data.get("exercises", []),
                "duration_minutes": body.duration_minutes or 45,
                "generation_method": "ai",
                "generation_source": "gemini_streaming",
            }

            created = db.create_workout(workout_db_data)
            logger.info(f"[Streaming] Workout generated: id={created['id']}")

            log_workout_change(
                workout_id=created['id'],
                user_id=body.user_id,
                change_type="generated",
                change_source="ai_streaming",
                new_value={"name": workout_data.get("name"), "exercises_count": len(workout_data.get("exercises", []))}
            )

            generated_workout = row_to_workout(created)
            asyncio.create_task(index_workout_to_rag(generated_workout))

            workout_response = {
                "id": created["id"],
                "user_id": created["user_id"],
                "name": created["name"],
                "type": created["type"],
                "difficulty": created["difficulty"],
                "scheduled_date": created["scheduled_date"],
                "exercises_json": created.get("exercises_json"),
                "duration_minutes": created.get("duration_minutes"),
                "is_completed": created.get("is_completed", False),
            }
            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except json.JSONDecodeError as e:
            logger.error(f"[Streaming] JSON parse error: {e}", exc_info=True)
            yield f"event: error\ndata: {json.dumps({'error': f'Failed to parse AI response: {str(e)}'})}\n\n"
        except Exception as e:
            logger.error(f"[Streaming] Error: {e}", exc_info=True)
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


@router.post("/suggest", response_model=WorkoutSuggestionsResponse)
@limiter.limit("5/minute")
async def get_workout_suggestions(request: Request, body: WorkoutSuggestionRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-powered workout suggestions for regeneration.

    Returns 3-5 workout suggestions based on current workout context,
    user's fitness profile, and optional natural language prompt.
    """
    logger.info(f"Getting workout suggestions for workout {body.workout_id}")

    try:
        db = get_supabase_db()

        existing = db.get_workout(body.workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        user = db.get_user(body.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = normalize_goals_list(user.get("goals"))
        equipment = parse_json_field(user.get("equipment"), [])
        injuries = parse_json_field(user.get("active_injuries"), [])

        current_type = body.current_workout_type or existing.get("type") or "Strength"
        current_duration = existing.get("duration_minutes") or 45

        system_prompt = f"""You are a fitness expert helping a user find alternative workout ideas.

USER PROFILE (for context only):
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Default Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Injuries/Limitations: {', '.join(injuries) if injuries else 'None'}

CURRENT WORKOUT:
- Type: {current_type}
- Duration: {current_duration} minutes

IMPORTANT RULES:
1. If the user mentions specific equipment in their request (e.g., "dumbbells", "barbell", "kettlebell"), use ONLY that equipment - ignore the default equipment from their profile
2. If the user mentions a duration (e.g., "30 minutes", "1 hour"), use that duration
3. If the user mentions a sport or activity (e.g., "boxing", "cricket", "swimming"), create workouts that train for that sport
4. Always respect injuries/limitations
5. Match the user's fitness level

Generate 4 different workout suggestions that:
1. Vary in workout type (e.g., Strength, HIIT, Cardio, Flexibility)
2. Follow the user's specific requests if any
3. Consider injuries and fitness level

Return a JSON object with a "suggestions" array containing exactly 4 suggestions, each containing:
- name: Creative workout name that reflects the equipment/sport if specified
- type: One of [Strength, HIIT, Cardio, Flexibility, Full Body, Upper Body, Lower Body, Core]
- difficulty: One of [easy, medium, hard]
- duration_minutes: Integer between 15-90 (use user's requested duration if specified)
- description: 1-2 sentence description mentioning the specific equipment/focus
- focus_areas: Array of 1-3 body areas targeted
- sample_exercises: Array of 4-5 exercise names that would be included

Example format: {{"suggestions": [...]}}"""

        user_prompt = body.prompt if body.prompt else "Give me some workout alternatives"

        from google.genai import types
        from core.config import get_settings
        from services.gemini.constants import gemini_generate_with_retry
        settings = get_settings()

        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=f"{system_prompt}\n\nUser request: {user_prompt}",
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=WorkoutSuggestionsResponse,
                temperature=0.7,
                max_output_tokens=4000,
            ),
            user_id=body.user_id,
            method_name="suggest_workout_db",
        )

        content = response.text.strip()
        data = json.loads(content)
        suggestions_data = data.get("suggestions", [])

        suggestions = []
        for s in suggestions_data[:5]:
            suggestions.append(WorkoutSuggestion(
                name=s.get("name", "Custom Workout"),
                type=s.get("type", "Strength"),
                difficulty=s.get("difficulty", "medium").lower(),
                duration_minutes=min(max(int(s.get("duration_minutes", 45)), 15), 90),
                description=s.get("description", ""),
                focus_areas=s.get("focus_areas", [])[:3],
                sample_exercises=s.get("sample_exercises", [])[:5],
            ))

        logger.info(f"Generated {len(suggestions)} workout suggestions")
        return WorkoutSuggestionsResponse(suggestions=suggestions)

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse AI response: {e}", exc_info=True)
        return WorkoutSuggestionsResponse(suggestions=[
            WorkoutSuggestion(
                name="Power Strength", type="Strength", difficulty="medium",
                duration_minutes=45, description="A balanced strength workout targeting major muscle groups.",
                focus_areas=["Full Body"],
                sample_exercises=["Squats", "Bench Press", "Rows", "Shoulder Press", "Lunges"]
            ),
            WorkoutSuggestion(
                name="Quick HIIT Blast", type="HIIT", difficulty="hard",
                duration_minutes=30, description="High-intensity interval training for maximum calorie burn.",
                focus_areas=["Full Body", "Cardio"],
                sample_exercises=["Burpees", "Mountain Climbers", "Jump Squats", "High Knees"]
            ),
            WorkoutSuggestion(
                name="Mobility Flow", type="Flexibility", difficulty="easy",
                duration_minutes=30, description="Gentle stretching and mobility work for recovery.",
                focus_areas=["Full Body"],
                sample_exercises=["Cat-Cow", "Hip Flexor Stretch", "Thread the Needle", "Pigeon Pose"]
            ),
        ])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout suggestions: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")
