"""
Quick Workout API endpoint.

This module provides endpoints for quick, time-constrained workouts
for busy users who want 5-15 minute workouts.

- POST /quick - Generate a quick workout tailored to duration and focus
"""
import json
from datetime import datetime
from typing import Optional, List, Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import Workout
from services.gemini_service import GeminiService
from services.user_context_service import user_context_service

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    validate_and_cap_exercise_parameters,
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Type Definitions
# ============================================

QuickWorkoutSource = Literal["button", "chat"]


# ============================================
# Request/Response Models
# ============================================

class QuickWorkoutRequest(BaseModel):
    """Request to generate a quick workout."""
    user_id: str = Field(..., max_length=100)
    duration: int = Field(
        default=10,
        ge=5,
        le=15,
        description="Workout duration in minutes (5, 10, or 15)"
    )
    focus: Optional[str] = Field(
        default=None,
        max_length=50,
        description="Optional focus: cardio, strength, stretch, or full_body"
    )
    source: QuickWorkoutSource = Field(
        default="button",
        description="Source of request: 'button' (UI) or 'chat' (AI coach conversation)"
    )


class QuickWorkoutResponse(BaseModel):
    """Response containing the generated quick workout."""
    workout: Workout
    message: str = Field(..., max_length=500)
    duration_minutes: int
    focus: Optional[str] = None
    exercises_count: int
    source: QuickWorkoutSource = "button"


# ============================================
# Quick Workout Generation
# ============================================

async def generate_quick_workout_prompt(
    duration: int,
    focus: Optional[str],
    fitness_level: str,
    equipment: List[str],
    avoided_exercises: Optional[List[str]] = None,
    avoided_muscles: Optional[dict] = None,
) -> str:
    """Build a prompt specifically for quick workouts."""

    focus_instruction = ""
    if focus == "cardio":
        focus_instruction = """
FOCUS: CARDIO
- High heart rate, minimal rest
- Exercises like: jumping jacks, burpees, high knees, mountain climbers
- Use duration_seconds for time-based movements
- Short rest periods (10-15 seconds)
"""
    elif focus == "strength":
        focus_instruction = """
FOCUS: STRENGTH
- Compound movements for efficiency
- Exercises like: squats, push-ups, lunges, rows
- Higher intensity, moderate rest (30 seconds)
- 2-3 sets per exercise to save time
"""
    elif focus == "stretch":
        focus_instruction = """
FOCUS: STRETCH/MOBILITY
- Dynamic stretches and holds
- Exercises like: hip flexor stretch, cat-cow, world's greatest stretch
- Use hold_seconds for static stretches (20-30 seconds)
- Minimal rest, flow between movements
"""
    elif focus == "full_body":
        focus_instruction = """
FOCUS: FULL BODY
- Hit all major muscle groups efficiently
- Compound movements that work multiple muscles
- Upper + lower + core in one session
- Circuit-style for time efficiency
"""
    else:
        focus_instruction = """
FOCUS: BALANCED QUICK WORKOUT
- Mix of strength and cardio
- Full body engagement
- Efficient compound movements
"""

    avoided_instruction = ""
    if avoided_exercises:
        avoided_instruction = f"\n\nDO NOT include these exercises (user preference): {', '.join(avoided_exercises)}"

    if avoided_muscles:
        if avoided_muscles.get("avoid"):
            avoided_instruction += f"\nAVOID targeting these muscles: {', '.join(avoided_muscles['avoid'])}"
        if avoided_muscles.get("reduce"):
            avoided_instruction += f"\nMINIMIZE targeting these muscles: {', '.join(avoided_muscles['reduce'])}"

    equipment_str = ", ".join(equipment) if equipment else "bodyweight only"

    prompt = f"""Generate a {duration}-minute quick workout for a {fitness_level} user.

{focus_instruction}

EQUIPMENT AVAILABLE: {equipment_str}

CRITICAL REQUIREMENTS for {duration}-minute workout:
1. Total workout time MUST fit within {duration} minutes including rest
2. For 5 min: 3-4 exercises, minimal rest
3. For 10 min: 4-6 exercises, short rest
4. For 15 min: 5-8 exercises, moderate rest
5. Include only exercises that can be done quickly
6. Prioritize efficiency - compound movements over isolation
7. Clear, actionable exercise names
{avoided_instruction}

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{{
  "name": "Quick [Focus] Blast" or similar energetic name,
  "type": "{focus or 'quick'}",
  "difficulty": "{fitness_level}",
  "exercises": [
    {{
      "name": "Exercise Name",
      "sets": 2,
      "reps": 10,
      "rest_seconds": 15,
      "duration_seconds": null,
      "hold_seconds": null,
      "notes": "Brief form cue",
      "muscle_group": "primary muscle"
    }}
  ]
}}

IMPORTANT:
- Use "duration_seconds" for time-based cardio exercises (e.g., 30 seconds of jumping jacks)
- Use "hold_seconds" for stretches (e.g., hold hamstring stretch 20 seconds)
- Use "reps" for count-based exercises
- Keep rest_seconds SHORT (10-30 seconds) to fit time constraint
- Calculate: total_time = sum of (sets * (reps * 3 + rest_seconds)) for all exercises"""

    return prompt


@router.post("/quick", response_model=QuickWorkoutResponse)
async def generate_quick_workout(request: QuickWorkoutRequest):
    """
    Generate a quick workout for busy users.

    Parameters:
    - duration: 5, 10, or 15 minutes
    - focus: optional - cardio, strength, stretch, or full_body
    - source: 'button' (UI button) or 'chat' (AI coach conversation)

    Returns a complete workout that can be started immediately.
    """
    logger.info(f"Generating quick workout for user {request.user_id}: {request.duration}min, focus={request.focus}, source={request.source}")

    try:
        db = get_supabase_db()

        # Get user data
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level", "intermediate")
        equipment = user.get("equipment", [])

        # Get user preferences
        avoided_exercises = await get_user_avoided_exercises(request.user_id)
        avoided_muscles = await get_user_avoided_muscles(request.user_id)

        if avoided_exercises:
            logger.info(f"[Quick Workout] Filtering {len(avoided_exercises)} avoided exercises")

        # Build the prompt
        prompt = await generate_quick_workout_prompt(
            duration=request.duration,
            focus=request.focus,
            fitness_level=fitness_level,
            equipment=equipment if isinstance(equipment, list) else [],
            avoided_exercises=avoided_exercises,
            avoided_muscles=avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
        )

        # Generate with Gemini
        gemini_service = GeminiService()

        try:
            from google.genai import types
            from google import genai
            from core.config import get_settings

            settings = get_settings()
            client = genai.Client(api_key=settings.gemini_api_key)

            response = await client.aio.models.generate_content(
                model=settings.gemini_model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=4096,
                    temperature=0.7,
                ),
            )

            content = response.text.strip() if response.text else ""

            if not content:
                raise HTTPException(status_code=500, detail="Empty response from AI")

            # Parse the response
            # Clean markdown if present
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            workout_data = json.loads(content.strip())

            exercises = workout_data.get("exercises", [])
            workout_name = workout_data.get("name", f"Quick {request.duration}min Workout")
            workout_type = workout_data.get("type", request.focus or "quick")
            difficulty = workout_data.get("difficulty", fitness_level)

            # Validate exercises
            if avoided_exercises:
                avoided_lower = [ae.lower() for ae in avoided_exercises]
                exercises = [
                    ex for ex in exercises
                    if ex.get("name", "").lower() not in avoided_lower
                ]

            # Safety validation
            exercises = validate_and_cap_exercise_parameters(
                exercises=exercises,
                fitness_level=fitness_level,
            )

            if not exercises:
                raise HTTPException(status_code=500, detail="No valid exercises generated")

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI response: {e}")
            raise HTTPException(status_code=500, detail="Failed to parse workout data")
        except Exception as ai_error:
            logger.error(f"AI generation failed: {ai_error}")
            raise HTTPException(status_code=500, detail=f"Failed to generate workout: {str(ai_error)}")

        # Save the workout
        workout_db_data = {
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": request.duration,
            "generation_method": "ai",
            "generation_source": "quick_workout",
            "generation_metadata": json.dumps({
                "focus": request.focus,
                "duration": request.duration,
                "quick_workout": True,
                "source": request.source,
            }),
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Quick workout generated: id={created['id']}, exercises={len(exercises)}, source={request.source}")

        # Log the change
        log_workout_change(
            workout_id=created['id'],
            user_id=request.user_id,
            change_type="generated",
            change_source="quick_workout",
            new_value={
                "name": workout_name,
                "exercises_count": len(exercises),
                "duration": request.duration,
                "focus": request.focus,
                "source": request.source,
            }
        )

        # Track quick workout usage for personalization
        try:
            await track_quick_workout_usage(
                user_id=request.user_id,
                duration=request.duration,
                focus=request.focus,
                source=request.source,
            )
        except Exception as e:
            logger.warning(f"Failed to track quick workout usage: {e}")

        # Log to user context
        try:
            await user_context_service.log_action(
                user_id=request.user_id,
                action="quick_workout_generated",
                details={
                    "workout_id": created['id'],
                    "duration": request.duration,
                    "focus": request.focus,
                    "exercises_count": len(exercises),
                    "source": request.source,
                }
            )
        except Exception as e:
            logger.warning(f"Failed to log user context: {e}")

        generated_workout = row_to_workout(created)
        await index_workout_to_rag(generated_workout)

        return QuickWorkoutResponse(
            workout=generated_workout,
            message=f"Quick {request.duration}-minute workout ready!",
            duration_minutes=request.duration,
            focus=request.focus,
            exercises_count=len(exercises),
            source=request.source,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate quick workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def track_quick_workout_usage(
    user_id: str,
    duration: int,
    focus: Optional[str],
    source: QuickWorkoutSource = "button",
) -> None:
    """Track quick workout usage for personalization."""
    db = get_supabase_db()

    try:
        # Use the RPC function to increment count and track source
        result = db.client.rpc(
            "increment_quick_workout_count",
            {"uid": user_id, "workout_source": source}
        ).execute()

        # Also update preferred duration and focus
        db.client.table("quick_workout_preferences").upsert({
            "user_id": user_id,
            "preferred_duration": duration,
            "preferred_focus": focus,
            "source": source,
        }, on_conflict="user_id").execute()

        logger.debug(f"Tracked quick workout usage: user={user_id}, source={source}")

    except Exception as e:
        # Table might not exist yet, that's ok - fall back to simple upsert
        logger.debug(f"Could not track quick workout preference via RPC: {e}")
        try:
            db.client.table("quick_workout_preferences").upsert({
                "user_id": user_id,
                "preferred_duration": duration,
                "preferred_focus": focus,
                "last_quick_workout_at": datetime.now().isoformat(),
                "source": source,
                "quick_workout_count": 1,
            }, on_conflict="user_id").execute()
        except Exception as fallback_error:
            logger.debug(f"Fallback upsert also failed: {fallback_error}")


@router.get("/quick/preferences/{user_id}")
async def get_quick_workout_preferences(user_id: str):
    """Get user's quick workout preferences."""
    db = get_supabase_db()

    try:
        result = db.client.table("quick_workout_preferences").select("*").eq("user_id", user_id).single().execute()

        if result.data:
            return {
                "preferred_duration": result.data.get("preferred_duration", 10),
                "preferred_focus": result.data.get("preferred_focus"),
                "quick_workout_count": result.data.get("quick_workout_count", 0),
                "last_quick_workout_at": result.data.get("last_quick_workout_at"),
                "source": result.data.get("source", "button"),
            }
        else:
            return {
                "preferred_duration": 10,
                "preferred_focus": None,
                "quick_workout_count": 0,
                "last_quick_workout_at": None,
                "source": "button",
            }
    except Exception as e:
        logger.debug(f"Could not fetch quick workout preferences: {e}")
        return {
            "preferred_duration": 10,
            "preferred_focus": None,
            "quick_workout_count": 0,
            "last_quick_workout_at": None,
            "source": "button",
        }


@router.get("/quick/analytics/source")
async def get_quick_workout_source_analytics():
    """
    Get analytics on quick workout source usage (button vs chat).

    This endpoint is useful for understanding user behavior patterns
    and optimizing the quick workout experience.
    """
    db = get_supabase_db()

    try:
        result = db.client.from_("quick_workout_source_analytics").select("*").execute()

        if result.data:
            return {
                "analytics": result.data,
                "summary": {
                    "button_users": sum(r["total_users"] for r in result.data if r["source"] == "button"),
                    "chat_users": sum(r["total_users"] for r in result.data if r["source"] == "chat"),
                    "button_workouts": sum(r["total_workouts"] for r in result.data if r["source"] == "button"),
                    "chat_workouts": sum(r["total_workouts"] for r in result.data if r["source"] == "chat"),
                }
            }
        else:
            return {
                "analytics": [],
                "summary": {
                    "button_users": 0,
                    "chat_users": 0,
                    "button_workouts": 0,
                    "chat_workouts": 0,
                }
            }
    except Exception as e:
        logger.debug(f"Could not fetch quick workout source analytics: {e}")
        return {
            "analytics": [],
            "summary": {
                "button_users": 0,
                "chat_users": 0,
                "button_workouts": 0,
                "chat_workouts": 0,
            },
            "error": str(e),
        }
