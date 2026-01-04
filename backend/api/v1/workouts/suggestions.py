"""
AI workout suggestions API endpoints.

This module handles AI-powered workout suggestions:
- POST /suggest - Get workout suggestions for regeneration
- GET /{workout_id}/summary - Get AI summary of a workout
- GET /{workout_id}/generation-params - Get AI reasoning for exercise selection
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


def _generate_fallback_summary(
    workout_name: str,
    exercises: list,
    duration_minutes: int,
    workout_type: str = None,
) -> str:
    """
    Generate a fallback summary when AI generation fails.
    Returns a valid JSON string that matches the expected format.
    """
    # Determine workout focus from exercises
    exercise_names = [ex.get("name", "") for ex in exercises[:3] if ex.get("name")]
    exercises_preview = ", ".join(exercise_names) if exercise_names else "various exercises"

    # Extract muscle groups
    muscles = set()
    for ex in exercises:
        muscle = ex.get("primary_muscle") or ex.get("muscle_group") or ex.get("target")
        if muscle:
            muscles.add(muscle.lower())

    muscle_focus = ", ".join(list(muscles)[:3]) if muscles else "full body"

    # Determine headline based on workout type
    type_headlines = {
        "strength": "Build Strength Today!",
        "hypertrophy": "Muscle Building Session!",
        "cardio": "Heart-Pumping Cardio!",
        "hiit": "High Intensity Burn!",
        "flexibility": "Stretch & Recover!",
        "endurance": "Endurance Challenge!",
    }
    headline = type_headlines.get(workout_type.lower() if workout_type else "", "Great Workout Ahead!")

    # Build sections
    sections = [
        {
            "icon": "🎯",
            "title": "Focus",
            "content": f"This workout targets {muscle_focus} with {len(exercises)} exercises",
            "color": "cyan"
        },
        {
            "icon": "💪",
            "title": "Key Moves",
            "content": f"Includes {exercises_preview} for comprehensive training",
            "color": "purple"
        },
        {
            "icon": "⏱️",
            "title": "Duration",
            "content": f"Complete in about {duration_minutes} minutes with proper rest periods",
            "color": "orange"
        }
    ]

    import json
    return json.dumps({"headline": headline, "sections": sections})


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

        try:
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

            # Validate that we got a non-empty summary
            if not summary or summary.strip() == "":
                logger.warning(f"AI returned empty summary for workout {workout_id}, generating fallback")
                summary = _generate_fallback_summary(
                    workout_name=workout_data.get("name", "Workout"),
                    exercises=exercises,
                    duration_minutes=workout_data.get("duration_minutes", 45),
                    workout_type=workout_data.get("type"),
                )
        except Exception as gen_error:
            logger.error(f"AI summary generation failed for workout {workout_id}: {gen_error}")
            # Generate a fallback summary instead of failing
            summary = _generate_fallback_summary(
                workout_name=workout_data.get("name", "Workout"),
                exercises=exercises,
                duration_minutes=workout_data.get("duration_minutes", 45),
                workout_type=workout_data.get("type"),
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


# ==================== WORKOUT GENERATION PARAMETERS ENDPOINT ====================

@router.get("/{workout_id}/generation-params")
async def get_workout_generation_params(workout_id: str):
    """
    Get the generation parameters and AI reasoning for a workout.

    This endpoint returns:
    - User profile parameters used to generate the workout
    - AI reasoning for exercise selection
    - Equipment, goals, and fitness level context
    """
    logger.info(f"Getting generation parameters for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        result = db.client.table("workouts").select("*").eq("id", workout_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = result.data[0]
        user_id = workout_data.get("user_id")

        # Get user profile for context
        user_result = db.client.table("users").select(
            "fitness_level, goals, equipment, injuries, age, weight_kg, height_cm, gender"
        ).eq("id", user_id).execute()

        user_profile = {}
        if user_result.data:
            user_data = user_result.data[0]
            user_profile = {
                "fitness_level": user_data.get("fitness_level", "intermediate"),
                "goals": parse_json_field(user_data.get("goals"), []),
                "equipment": parse_json_field(user_data.get("equipment"), []),
                "injuries": parse_json_field(user_data.get("injuries"), []),
                "age": user_data.get("age"),
                "weight_kg": user_data.get("weight_kg"),
                "height_cm": user_data.get("height_cm"),
                "gender": user_data.get("gender"),
            }

        # Get program preferences
        prefs_result = db.client.table("user_program_preferences").select("*").eq("user_id", user_id).execute()

        program_preferences = {}
        if prefs_result.data:
            prefs = prefs_result.data[0]
            program_preferences = {
                "difficulty": prefs.get("difficulty"),
                "duration_minutes": prefs.get("duration_minutes"),
                "workout_type": prefs.get("workout_type"),
                "training_split": prefs.get("training_split"),
                "workout_days": parse_json_field(prefs.get("workout_days"), []),
                "focus_areas": parse_json_field(prefs.get("focus_areas"), []),
                "custom_program_description": prefs.get("custom_program_description"),
            }

        # Parse workout exercises
        exercises = parse_json_field(workout_data.get("exercises_json"), [])

        # Build AI reasoning based on the workout parameters
        workout_type = workout_data.get("type", "strength")
        difficulty = workout_data.get("difficulty", "intermediate")
        target_muscles = parse_json_field(workout_data.get("target_muscles"), [])
        workout_name = workout_data.get("name", "Workout")

        # Try AI-powered reasoning first, fall back to static if it fails
        exercise_reasoning = []
        workout_reasoning = ""

        try:
            # Import and use the Gemini service for AI-powered reasoning
            from services.gemini_service import GeminiService
            gemini = GeminiService()

            ai_reasoning = await gemini.generate_exercise_reasoning(
                workout_name=workout_name,
                exercises=exercises,
                user_profile=user_profile,
                program_preferences=program_preferences,
                workout_type=workout_type,
                difficulty=difficulty,
            )

            # Check if AI returned valid reasoning
            if ai_reasoning.get("workout_reasoning") and ai_reasoning.get("exercise_reasoning"):
                workout_reasoning = ai_reasoning["workout_reasoning"]
                logger.info(f"✅ AI-generated workout reasoning for {workout_id}")

                # Map AI reasoning to exercises (match by name)
                ai_exercise_map = {
                    r.get("exercise_name", "").lower(): r.get("reasoning", "")
                    for r in ai_reasoning.get("exercise_reasoning", [])
                }

                for i, ex in enumerate(exercises):
                    ex_name = ex.get("name", f"Exercise {i+1}")
                    muscle_group = ex.get("muscle_group") or ex.get("primary_muscle") or ex.get("body_part", "general")
                    equipment = ex.get("equipment", "bodyweight")

                    # Use AI reasoning if available, otherwise fall back to static
                    ai_reason = ai_exercise_map.get(ex_name.lower(), "")
                    if ai_reason:
                        reasoning = ai_reason
                    else:
                        # Fall back to static reasoning for this exercise
                        reasoning = _build_exercise_reasoning(
                            exercise_name=ex_name,
                            muscle_group=muscle_group,
                            equipment=equipment,
                            sets=ex.get("sets", 3),
                            reps=ex.get("reps", "8-12"),
                            workout_type=workout_type,
                            difficulty=difficulty,
                            user_goals=user_profile.get("goals", []),
                            user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                            user_equipment=user_profile.get("equipment", []),
                        )

                    exercise_reasoning.append({
                        "exercise_name": ex_name,
                        "reasoning": reasoning,
                        "muscle_group": muscle_group,
                        "equipment": equipment,
                    })
            else:
                # AI returned empty - use static fallback
                raise ValueError("AI returned empty reasoning")

        except Exception as ai_error:
            logger.warning(f"⚠️ AI reasoning failed, using static fallback: {ai_error}")

            # Fall back to static reasoning generation
            for i, ex in enumerate(exercises):
                ex_name = ex.get("name", f"Exercise {i+1}")
                muscle_group = ex.get("muscle_group") or ex.get("primary_muscle") or ex.get("body_part", "general")
                equipment = ex.get("equipment", "bodyweight")
                sets = ex.get("sets", 3)
                reps = ex.get("reps", "8-12")

                reasoning = _build_exercise_reasoning(
                    exercise_name=ex_name,
                    muscle_group=muscle_group,
                    equipment=equipment,
                    sets=sets,
                    reps=reps,
                    workout_type=workout_type,
                    difficulty=difficulty,
                    user_goals=user_profile.get("goals", []),
                    user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                    user_equipment=user_profile.get("equipment", []),
                )
                exercise_reasoning.append({
                    "exercise_name": ex_name,
                    "reasoning": reasoning,
                    "muscle_group": muscle_group,
                    "equipment": equipment,
                })

            # Build static workout reasoning
            workout_reasoning = _build_workout_reasoning(
                workout_name=workout_name,
                workout_type=workout_type,
                difficulty=difficulty,
                target_muscles=target_muscles,
                exercise_count=len(exercises),
                duration_minutes=workout_data.get("duration_minutes", 45),
                user_goals=user_profile.get("goals", []),
                user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                training_split=program_preferences.get("training_split"),
            )

        return {
            "workout_id": workout_id,
            "workout_name": workout_data.get("name"),
            "workout_type": workout_type,
            "difficulty": difficulty,
            "duration_minutes": workout_data.get("duration_minutes"),
            "generation_method": workout_data.get("generation_method", "ai"),
            "user_profile": user_profile,
            "program_preferences": program_preferences,
            "workout_reasoning": workout_reasoning,
            "exercise_reasoning": exercise_reasoning,
            "target_muscles": target_muscles,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout generation params: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _build_exercise_reasoning(
    exercise_name: str,
    muscle_group: str,
    equipment: str,
    sets: int,
    reps: str,
    workout_type: str,
    difficulty: str,
    user_goals: list,
    user_fitness_level: str,
    user_equipment: list,
) -> str:
    """Build reasoning explanation for why an exercise was selected."""
    reasons = []

    # Muscle targeting
    if muscle_group:
        reasons.append(f"Targets {muscle_group} effectively")

    # Equipment match
    if equipment:
        equipment_lower = equipment.lower()
        if equipment_lower in ["bodyweight", "none", "body weight"]:
            reasons.append("Requires no equipment - great for home workouts")
        elif user_equipment and any(eq.lower() in equipment_lower for eq in user_equipment):
            reasons.append(f"Matches your available equipment ({equipment})")
        else:
            reasons.append(f"Uses {equipment}")

    # Goal alignment
    goal_map = {
        "muscle_gain": ["compound movement for muscle growth", "builds strength and size"],
        "weight_loss": ["burns calories efficiently", "elevates heart rate"],
        "strength": ["develops maximal strength", "progressive overload focused"],
        "endurance": ["builds muscular endurance", "higher rep scheme"],
        "flexibility": ["improves range of motion", "dynamic movement"],
        "general_fitness": ["well-rounded exercise", "functional movement pattern"],
    }
    for goal in user_goals:
        if goal.lower().replace(" ", "_") in goal_map:
            reasons.append(goal_map[goal.lower().replace(" ", "_")][0])
            break

    # Set/rep scheme reasoning
    if isinstance(reps, str) and "-" in reps:
        reasons.append(f"{sets} sets of {reps} reps for optimal stimulus")
    elif isinstance(reps, int) or (isinstance(reps, str) and reps.isdigit()):
        reps_int = int(reps) if isinstance(reps, str) else reps
        if reps_int <= 5:
            reasons.append(f"Low rep range ({sets}x{reps}) for strength focus")
        elif reps_int <= 12:
            reasons.append(f"{sets}x{reps} in hypertrophy range for muscle growth")
        else:
            reasons.append(f"Higher reps ({sets}x{reps}) for endurance and conditioning")

    # Difficulty appropriateness
    if difficulty:
        difficulty_lower = difficulty.lower()
        if difficulty_lower == "beginner":
            reasons.append("Beginner-friendly movement pattern")
        elif difficulty_lower == "advanced":
            reasons.append("Challenging variation for advanced trainees")

    return ". ".join(reasons) if reasons else "Selected to complement your workout program"


def _build_workout_reasoning(
    workout_name: str,
    workout_type: str,
    difficulty: str,
    target_muscles: list,
    exercise_count: int,
    duration_minutes: int,
    user_goals: list,
    user_fitness_level: str,
    training_split: str = None,
) -> str:
    """Build overall reasoning for the workout design."""
    parts = []

    # Workout type explanation
    type_explanations = {
        "strength": "This strength-focused workout emphasizes compound movements and progressive overload",
        "hypertrophy": "This hypertrophy workout is designed to maximize muscle growth through optimal volume",
        "cardio": "This cardio session elevates heart rate for cardiovascular health and calorie burn",
        "hiit": "This high-intensity interval training alternates intense bursts with recovery periods",
        "endurance": "This endurance workout builds stamina and muscular endurance",
        "flexibility": "This flexibility session improves mobility and range of motion",
        "full_body": "This full-body workout hits all major muscle groups in one session",
        "upper_body": "This upper body session targets chest, back, shoulders, and arms",
        "lower_body": "This lower body workout focuses on quads, hamstrings, glutes, and calves",
        "push": "This push workout targets chest, shoulders, and triceps",
        "pull": "This pull workout targets back, biceps, and rear delts",
        "legs": "This leg day focuses on quadriceps, hamstrings, glutes, and calves",
    }
    workout_type_lower = workout_type.lower().replace(" ", "_")
    if workout_type_lower in type_explanations:
        parts.append(type_explanations[workout_type_lower])
    else:
        parts.append(f"This {workout_type} workout is designed for balanced training")

    # Training split context
    if training_split:
        split_names = {
            "full_body": "full body split (training all muscles each session)",
            "upper_lower": "upper/lower split (alternating focus)",
            "push_pull_legs": "push/pull/legs split (organized by movement pattern)",
            "bro_split": "body part split (one muscle group per day)",
        }
        split_lower = training_split.lower().replace(" ", "_")
        if split_lower in split_names:
            parts.append(f"Following your {split_names[split_lower]}")

    # Target muscles
    if target_muscles:
        muscles_str = ", ".join(target_muscles[:3])
        if len(target_muscles) > 3:
            muscles_str += f" and {len(target_muscles) - 3} more"
        parts.append(f"Primary targets: {muscles_str}")

    # Goal alignment
    if user_goals:
        goals_str = ", ".join(user_goals[:2])
        parts.append(f"Aligned with your goals: {goals_str}")

    # Volume and duration
    parts.append(f"{exercise_count} exercises in approximately {duration_minutes} minutes")

    # Fitness level appropriateness
    if user_fitness_level:
        level_lower = user_fitness_level.lower()
        if level_lower == "beginner":
            parts.append("Designed for beginners with fundamental movements")
        elif level_lower == "intermediate":
            parts.append("Intermediate difficulty with progressive challenges")
        elif level_lower == "advanced":
            parts.append("Advanced training with complex movements and higher intensity")

    return ". ".join(parts) + "."
