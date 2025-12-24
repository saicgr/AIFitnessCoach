"""
AI workout suggestions API endpoints.

This module handles AI-powered workout suggestions:
- POST /suggest - Get workout suggestions for regeneration
- GET /{workout_id}/summary - Get AI summary of a workout
"""
import json
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.langgraph_agents.workout_insights.graph import generate_workout_insights

from .utils import parse_json_field

router = APIRouter()
logger = get_logger(__name__)


class WorkoutSuggestionRequest(BaseModel):
    """Request for AI workout suggestions."""
    workout_id: str
    user_id: str
    current_workout_type: Optional[str] = None
    prompt: Optional[str] = None


class WorkoutSuggestion(BaseModel):
    """A single workout suggestion."""
    name: str
    type: str
    difficulty: str
    duration_minutes: int
    description: str
    focus_areas: List[str]
    sample_exercises: List[str] = []  # Preview of exercises included


class WorkoutSuggestionsResponse(BaseModel):
    """Response with workout suggestions."""
    suggestions: List[WorkoutSuggestion]


@router.post("/suggest", response_model=WorkoutSuggestionsResponse)
async def get_workout_suggestions(request: WorkoutSuggestionRequest):
    """
    Get AI-powered workout suggestions for regeneration.

    Returns 3-5 workout suggestions based on:
    - Current workout context
    - User's fitness profile
    - Optional natural language prompt from user
    """
    logger.info(f"Getting workout suggestions for workout {request.workout_id}")

    try:
        db = get_supabase_db()

        # Get existing workout
        existing = db.get_workout(request.workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get user data
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user context
        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        equipment = parse_json_field(user.get("equipment"), [])
        injuries = parse_json_field(user.get("active_injuries"), [])

        # Get current workout info
        current_type = request.current_workout_type or existing.get("type") or "Strength"
        current_duration = existing.get("duration_minutes") or 45

        # Build prompt for AI
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

Return a JSON array with exactly 4 suggestions, each containing:
- name: Creative workout name that reflects the equipment/sport if specified (e.g., "Dumbbell Power Circuit", "Cricket Athlete Conditioning")
- type: One of [Strength, HIIT, Cardio, Flexibility, Full Body, Upper Body, Lower Body, Core]
- difficulty: One of [easy, medium, hard]
- duration_minutes: Integer between 15-90 (use user's requested duration if specified)
- description: 1-2 sentence description mentioning the specific equipment/focus
- focus_areas: Array of 1-3 body areas targeted
- sample_exercises: Array of 4-5 exercise names that would be included (e.g., ["Bench Press", "Rows", "Squats"])

IMPORTANT: Return ONLY the JSON array, no markdown or explanations."""

        user_prompt = request.prompt if request.prompt else "Give me some workout alternatives"

        from google import genai
        from google.genai import types
        from core.config import get_settings
        settings = get_settings()

        client = genai.Client(api_key=settings.gemini_api_key)
        response = await client.aio.models.generate_content(
            model=settings.gemini_model,
            contents=f"{system_prompt}\n\nUser request: {user_prompt}",
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.7,
                max_output_tokens=4000,
            ),
        )

        content = response.text.strip()

        # Parse JSON response
        if "```" in content:
            # Extract from code block
            parts = content.split("```")
            for part in parts:
                part = part.strip()
                if part.startswith("json"):
                    part = part[4:].strip()
                if part.startswith("["):
                    content = part
                    break

        # Find JSON array
        start_idx = content.find("[")
        end_idx = content.rfind("]") + 1
        if start_idx != -1 and end_idx > start_idx:
            content = content[start_idx:end_idx]

        suggestions_data = json.loads(content)

        # Validate and convert to response format
        suggestions = []
        for s in suggestions_data[:5]:  # Limit to 5
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
        logger.error(f"Failed to parse AI response: {e}")
        # Return default suggestions on parse error
        return WorkoutSuggestionsResponse(suggestions=[
            WorkoutSuggestion(
                name="Power Strength",
                type="Strength",
                difficulty="medium",
                duration_minutes=45,
                description="A balanced strength workout targeting major muscle groups.",
                focus_areas=["Full Body"],
                sample_exercises=["Squats", "Bench Press", "Rows", "Shoulder Press", "Lunges"]
            ),
            WorkoutSuggestion(
                name="Quick HIIT Blast",
                type="HIIT",
                difficulty="hard",
                duration_minutes=30,
                description="High-intensity interval training for maximum calorie burn.",
                focus_areas=["Full Body", "Cardio"],
                sample_exercises=["Burpees", "Mountain Climbers", "Jump Squats", "High Knees"]
            ),
            WorkoutSuggestion(
                name="Mobility Flow",
                type="Flexibility",
                difficulty="easy",
                duration_minutes=30,
                description="Gentle stretching and mobility work for recovery.",
                focus_areas=["Full Body"],
                sample_exercises=["Cat-Cow", "Hip Flexor Stretch", "Thread the Needle", "Pigeon Pose"]
            ),
        ])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}/summary")
async def get_workout_ai_summary(workout_id: str, force_regenerate: bool = False):
    """
    Generate an AI summary/description of a workout explaining the intention and benefits.

    Summaries are cached in Supabase per workout per user. Use force_regenerate=true to
    bypass the cache and generate a fresh summary.
    """
    logger.info(f"Getting AI summary for workout {workout_id} (force_regenerate={force_regenerate})")
    try:
        db = get_supabase_db()

        # Get the workout
        result = db.client.table("workouts").select("*").eq("id", workout_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = result.data[0]
        user_id = workout_data.get("user_id")

        # Check for cached summary first (unless force_regenerate)
        if not force_regenerate:
            cached = db.client.table("workout_summaries").select("summary").eq(
                "workout_id", workout_id
            ).eq("user_id", user_id).execute()

            if cached.data:
                logger.info(f"Returning cached summary for workout {workout_id}")
                return {"summary": cached.data[0]["summary"], "cached": True}

        # Parse exercises
        exercises = parse_json_field(workout_data.get("exercises_json"), [])
        target_muscles = parse_json_field(workout_data.get("target_muscles"), [])

        # Get user info for goals and fitness level
        user_result = db.client.table("users").select("goals, fitness_level").eq("id", user_id).execute()

        user_goals = []
        fitness_level = "intermediate"
        if user_result.data:
            user_goals = parse_json_field(user_result.data[0].get("goals"), [])
            fitness_level = user_result.data[0].get("fitness_level", "intermediate")

        # Generate the AI summary using LangGraph agent
        import time
        start_time = time.time()

        summary = await generate_workout_insights(
            workout_id=workout_id,
            workout_name=workout_data.get("name", "Workout"),
            exercises=exercises,
            duration_minutes=workout_data.get("duration_minutes", 45),
            workout_type=workout_data.get("type"),
            difficulty=workout_data.get("difficulty"),
            user_goals=user_goals,
            fitness_level=fitness_level,
        )

        generation_time_ms = int((time.time() - start_time) * 1000)

        # Calculate workout metadata for storage
        duration_minutes = workout_data.get("duration_minutes", 0)
        calories_estimate = duration_minutes * 6 if duration_minutes else len(exercises) * 5

        # Store the summary in Supabase (upsert)
        summary_record = {
            "workout_id": workout_id,
            "user_id": user_id,
            "summary": summary,
            "workout_name": workout_data.get("name"),
            "workout_type": workout_data.get("type"),
            "exercise_count": len(exercises),
            "duration_minutes": duration_minutes,
            "calories_estimate": calories_estimate,
            "model_used": "gpt-4o-mini",
            "generation_time_ms": generation_time_ms,
            "generated_at": datetime.utcnow().isoformat()
        }

        try:
            # Try to upsert (insert or update on conflict)
            existing = db.client.table("workout_summaries").select("id").eq(
                "workout_id", workout_id
            ).eq("user_id", user_id).execute()

            if existing.data:
                db.client.table("workout_summaries").update(summary_record).eq(
                    "id", existing.data[0]["id"]
                ).execute()
                logger.info(f"Updated cached summary for workout {workout_id}")
            else:
                db.client.table("workout_summaries").insert(summary_record).execute()
                logger.info(f"Stored new summary for workout {workout_id}")
        except Exception as store_error:
            # Don't fail the request if storage fails, just log it
            logger.warning(f"Failed to store workout summary: {store_error}")

        return {"summary": summary, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))
