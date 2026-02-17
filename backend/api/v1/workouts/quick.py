"""
Quick Workout API endpoint.

This module provides endpoints for quick, time-constrained workouts
for busy users who want 5-30 minute workouts.

- POST /quick - Generate a quick workout tailored to duration and focus
"""
import asyncio
import json
from datetime import datetime
from typing import Optional, List, Literal

from fastapi import APIRouter, HTTPException, Request, BackgroundTasks
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from models.schemas import Workout
from models.gemini_schemas import GeneratedWorkoutResponse
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

# Concurrency semaphore to cap concurrent Gemini calls
_gemini_semaphore = asyncio.Semaphore(10)


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
        le=30,
        description="Workout duration in minutes (5-30)"
    )
    focus: Optional[str] = Field(
        default=None,
        max_length=50,
        description="Optional focus: cardio, strength, stretch, or full_body"
    )
    difficulty: Optional[str] = Field(
        default=None,
        max_length=20,
        description="Optional difficulty: easy, medium, hard, or hell"
    )
    equipment: Optional[List[str]] = Field(
        default=None,
        description="Optional equipment list (overrides user profile)"
    )
    injuries: Optional[List[str]] = Field(
        default=None,
        description="Optional injuries to work around"
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
    injuries: Optional[List[str]] = None,
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

    injuries_instruction = ""
    if injuries:
        injuries_instruction = f"\n\nINJURIES TO WORK AROUND: {', '.join(injuries)}\n- Avoid exercises that stress these areas\n- Suggest safe alternatives that don't aggravate these injuries"

    equipment_str = ", ".join(equipment) if equipment else "bodyweight only"

    prompt = f"""Generate a {duration}-minute quick workout for a {fitness_level} user.

{focus_instruction}

EQUIPMENT AVAILABLE: {equipment_str}

CRITICAL REQUIREMENTS for {duration}-minute workout:
1. Total workout time MUST fit within {duration} minutes including rest
2. For 5 min: 3-4 exercises, minimal rest
3. For 10 min: 4-6 exercises, short rest
4. For 15 min: 5-8 exercises, moderate rest
5. For 20 min: 6-10 exercises, moderate rest
6. For 25 min: 8-12 exercises, moderate rest
7. For 30 min: 10-14 exercises, standard rest
8. Include only exercises that can be done quickly
9. Prioritize efficiency - compound movements over isolation
10. Clear, actionable exercise names
{avoided_instruction}{injuries_instruction}

FIELD GUIDELINES:
- "name": A creative, energetic workout name (e.g. "Quick Cardio Blast")
- "type": "{focus or 'quick'}"
- "difficulty": "{fitness_level}"
- "duration_minutes": {duration}
- "target_muscles": list of primary muscles targeted
- "notes": optional overall workout tip
- Each exercise needs "set_targets" matching the "sets" count, each with set_number (1-indexed), set_type ("working"), and target_reps
- Use "duration_seconds" for time-based cardio (e.g. 30s jumping jacks)
- Use "hold_seconds" for stretches (e.g. 20s hamstring stretch)
- Use "reps" for count-based exercises
- Keep rest_seconds SHORT (10-30 seconds) to fit {duration}-minute time constraint
- Keep sets to 2-3 per exercise to save time"""

    return prompt


@router.post("/quick", response_model=QuickWorkoutResponse)
@limiter.limit("5/minute")
async def generate_quick_workout(request: Request, body: QuickWorkoutRequest, background_tasks: BackgroundTasks):
    """
    Generate a quick workout for busy users.

    Parameters:
    - duration: 5-30 minutes
    - focus: optional - cardio, strength, stretch, or full_body
    - difficulty: optional - easy, medium, hard, or hell
    - equipment: optional - list of equipment (overrides profile)
    - injuries: optional - list of injuries to work around
    - source: 'button' (UI button) or 'chat' (AI coach conversation)

    Returns a complete workout that can be started immediately.
    """
    logger.info(f"Generating quick workout for user {body.user_id}: {body.duration}min, focus={body.focus}, difficulty={body.difficulty}, source={body.source}")

    try:
        db = get_supabase_db()

        # Get user data
        user = db.get_user(body.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Use request overrides or fall back to user profile
        fitness_level = body.difficulty or user.get("fitness_level", "intermediate")
        equipment = body.equipment if body.equipment is not None else user.get("equipment", [])

        # Get user preferences
        avoided_exercises = await get_user_avoided_exercises(body.user_id)
        avoided_muscles = await get_user_avoided_muscles(body.user_id)

        if avoided_exercises:
            logger.info(f"[Quick Workout] Filtering {len(avoided_exercises)} avoided exercises")

        # Build the prompt
        prompt = await generate_quick_workout_prompt(
            duration=body.duration,
            focus=body.focus,
            fitness_level=fitness_level,
            equipment=equipment if isinstance(equipment, list) else [],
            avoided_exercises=avoided_exercises,
            avoided_muscles=avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
            injuries=body.injuries,
        )

        # Generate with Gemini (with semaphore + retry)
        try:
            from google.genai import types
            from core.config import get_settings
            from core.gemini_client import get_genai_client

            settings = get_settings()
            client = get_genai_client()

            content = ""
            last_error = None
            for attempt in range(2):  # 1 initial + 1 retry
                try:
                    async with _gemini_semaphore:
                        response = await client.aio.models.generate_content(
                            model=settings.gemini_model,
                            contents=prompt,
                            config=types.GenerateContentConfig(
                                response_mime_type="application/json",
                                response_schema=GeneratedWorkoutResponse,
                                max_output_tokens=8192,
                                temperature=0.7,
                            ),
                        )

                    content = response.text.strip() if response.text else ""
                    if content:
                        break
                except Exception as e:
                    last_error = e
                    error_str = str(e).lower()
                    if "resourceexhausted" in error_str or "429" in error_str or "quota" in error_str:
                        if attempt == 0:
                            logger.warning(f"[Quick Workout] Gemini quota hit, retrying in 2s...")
                            await asyncio.sleep(2)
                            continue
                    raise

            if not content:
                if last_error:
                    raise last_error
                raise HTTPException(status_code=500, detail="Empty response from AI")

            # Parse the response - try direct parse first, then extract JSON
            workout_data = None
            try:
                workout_data = json.loads(content)
            except json.JSONDecodeError:
                # Try extracting JSON from markdown code blocks
                import re
                json_match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', content, re.DOTALL)
                if json_match:
                    workout_data = json.loads(json_match.group(1))
                else:
                    # Try finding the first { to last }
                    start = content.find('{')
                    end = content.rfind('}')
                    if start != -1 and end != -1 and end > start:
                        workout_data = json.loads(content[start:end + 1])

            if workout_data is None:
                raise json.JSONDecodeError("Could not extract valid JSON", content, 0)

            # Ensure workout_data is a dict (guard against Gemini returning a string)
            if isinstance(workout_data, str):
                try:
                    workout_data = json.loads(workout_data)
                except (json.JSONDecodeError, ValueError):
                    workout_data = {}
            if not isinstance(workout_data, dict):
                workout_data = {}

            exercises = workout_data.get("exercises", [])
            # Normalize exercises to ensure all items and set_targets are dicts
            from api.v1.workouts.generation import ensure_exercises_are_dicts, normalize_exercise_numeric_fields
            exercises = ensure_exercises_are_dicts(exercises)
            exercises = normalize_exercise_numeric_fields(exercises)

            workout_name = workout_data.get("name", f"Quick {body.duration}min Workout")
            workout_type = workout_data.get("type", body.focus or "quick")
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
                difficulty=difficulty,
            )

            if not exercises:
                raise HTTPException(status_code=500, detail="No valid exercises generated")

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI response: {e}")
            raise HTTPException(status_code=500, detail="Failed to parse workout data")
        except HTTPException:
            raise
        except Exception as ai_error:
            logger.error(f"AI generation failed: {ai_error}")
            raise HTTPException(status_code=500, detail=f"Failed to generate workout: {str(ai_error)}")

        # Save the workout
        workout_db_data = {
            "user_id": body.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": body.duration,
            "generation_method": "ai",
            "generation_source": "quick_workout",
            "generation_metadata": json.dumps({
                "focus": body.focus,
                "difficulty": body.difficulty,
                "equipment": body.equipment,
                "injuries": body.injuries,
                "duration": body.duration,
                "quick_workout": True,
                "source": body.source,
            }),
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Quick workout generated: id={created['id']}, exercises={len(exercises)}, source={body.source}")

        # Log the change
        log_workout_change(
            workout_id=created['id'],
            user_id=body.user_id,
            change_type="generated",
            change_source="quick_workout",
            new_value={
                "name": workout_name,
                "exercises_count": len(exercises),
                "duration": body.duration,
                "focus": body.focus,
                "source": body.source,
            }
        )

        # Track quick workout usage for personalization
        try:
            await track_quick_workout_usage(
                user_id=body.user_id,
                duration=body.duration,
                focus=body.focus,
                source=body.source,
            )
        except Exception as e:
            logger.warning(f"Failed to track quick workout usage: {e}")

        # Log to user context
        try:
            await user_context_service.log_action(
                user_id=body.user_id,
                action="quick_workout_generated",
                details={
                    "workout_id": created['id'],
                    "duration": body.duration,
                    "focus": body.focus,
                    "exercises_count": len(exercises),
                    "source": body.source,
                }
            )
        except Exception as e:
            logger.warning(f"Failed to log user context: {e}")

        generated_workout = row_to_workout(created)

        # Index to RAG in background (non-blocking)
        background_tasks.add_task(index_workout_to_rag, generated_workout)

        return QuickWorkoutResponse(
            workout=generated_workout,
            message=f"Quick {body.duration}-minute workout ready!",
            duration_minutes=body.duration,
            focus=body.focus,
            exercises_count=len(exercises),
            source=body.source,
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
