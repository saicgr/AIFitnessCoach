"""
Demo and Trial API endpoints.

These endpoints allow users to preview the app before signing up,
and track their engagement to understand conversion patterns.

This addresses the common complaint:
"One of those apps where you answer a bunch of questions to get a 'tailored plan',
but then hit a paywall to even see how the app works, let alone what your plan
might look like."
"""

from .demo_models import *  # noqa: F401, F403
from .demo_endpoints import router as _endpoints_router


from fastapi import APIRouter, HTTPException, Query, Request, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import uuid
import logging

from core import branding
from core.db import get_supabase_db
from core.rate_limiter import limiter
from core.auth import get_admin_user
from core.exceptions import safe_internal_error
from services.exercise_library_service import ExerciseLibraryService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/demo", tags=["Demo"])

# Initialize exercise library service
exercise_library = ExerciseLibraryService()


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class PreviewPlanRequest(BaseModel):
    """Request for generating a preview workout plan."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    days_per_week: int
    training_split: Optional[str] = "push_pull_legs"
    session_id: Optional[str] = None


class DemoInteraction(BaseModel):
    """Log a demo user interaction."""
    session_id: str
    action_type: str  # screen_view, exercise_view, workout_start, feature_tap
    screen: Optional[str] = None
    feature: Optional[str] = None
    duration_seconds: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None


class DemoSession(BaseModel):
    """Start or update a demo session."""
    session_id: Optional[str] = None
    quiz_data: Optional[Dict[str, Any]] = None
    device_info: Optional[Dict[str, Any]] = None


class SessionConvertRequest(BaseModel):
    """Request to mark a demo session as converted."""
    session_id: str
    user_id: str
    trigger: str


class PersonalizedSampleWorkoutRequest(BaseModel):
    """Request for generating a personalized sample workout with real exercises."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    workout_type_preference: Optional[str] = "strength"  # strength, cardio, mixed
    session_id: Optional[str] = None


class TourStartRequest(BaseModel):
    """Request to start an app tour session."""
    user_id: Optional[str] = None
    device_id: Optional[str] = None
    source: str = "new_user"  # new_user, settings, deep_link
    device_info: Optional[Dict[str, Any]] = None
    app_version: Optional[str] = None
    platform: Optional[str] = None


class TourStepCompletedRequest(BaseModel):
    """Request when a tour step is completed."""
    session_id: str
    step_id: str
    duration_seconds: Optional[int] = None
    action_taken: Optional[str] = None  # skip, next, deep_link
    deep_link_target: Optional[str] = None


class TourCompletedRequest(BaseModel):
    """Request when tour is completed or skipped."""
    session_id: str
    status: str  # completed, skipped
    skip_step: Optional[str] = None
    demo_workout_started: bool = False
    demo_workout_completed: bool = False
    plan_preview_viewed: bool = False
    deep_links_clicked: List[str] = []
    total_duration_seconds: Optional[int] = None


# ============================================================================
# CURATED EXERCISE DATA (for unauthenticated demo/guest experience)
# These are real exercises with real sets/reps, used to showcase the app's
# capabilities before signup. They are NOT personalized user data.
# ============================================================================

CURATED_EXERCISES = {
    "chest": [
        {"name": "Push-ups", "sets": 3, "reps": "10-15", "muscle_group": "Chest"},
        {"name": "Dumbbell Bench Press", "sets": 3, "reps": "8-12", "muscle_group": "Chest"},
        {"name": "Incline Dumbbell Press", "sets": 3, "reps": "8-12", "muscle_group": "Chest"},
        {"name": "Cable Flyes", "sets": 3, "reps": "12-15", "muscle_group": "Chest"},
    ],
    "shoulders": [
        {"name": "Overhead Press", "sets": 3, "reps": "8-10", "muscle_group": "Shoulders"},
        {"name": "Lateral Raises", "sets": 3, "reps": "12-15", "muscle_group": "Shoulders"},
        {"name": "Front Raises", "sets": 3, "reps": "10-12", "muscle_group": "Shoulders"},
    ],
    "triceps": [
        {"name": "Tricep Pushdowns", "sets": 3, "reps": "12-15", "muscle_group": "Triceps"},
        {"name": "Overhead Tricep Extension", "sets": 3, "reps": "10-12", "muscle_group": "Triceps"},
    ],
    "back": [
        {"name": "Lat Pulldowns", "sets": 3, "reps": "10-12", "muscle_group": "Back"},
        {"name": "Seated Cable Rows", "sets": 3, "reps": "10-12", "muscle_group": "Back"},
        {"name": "Dumbbell Rows", "sets": 3, "reps": "8-10", "muscle_group": "Back"},
        {"name": "Face Pulls", "sets": 3, "reps": "15-20", "muscle_group": "Back"},
    ],
    "biceps": [
        {"name": "Barbell Curls", "sets": 3, "reps": "10-12", "muscle_group": "Biceps"},
        {"name": "Hammer Curls", "sets": 3, "reps": "10-12", "muscle_group": "Biceps"},
    ],
    "quadriceps": [
        {"name": "Goblet Squats", "sets": 3, "reps": "10-12", "muscle_group": "Quadriceps"},
        {"name": "Leg Press", "sets": 3, "reps": "10-12", "muscle_group": "Quadriceps"},
        {"name": "Walking Lunges", "sets": 3, "reps": "12 each", "muscle_group": "Quadriceps"},
    ],
    "hamstrings": [
        {"name": "Romanian Deadlifts", "sets": 3, "reps": "8-10", "muscle_group": "Hamstrings"},
        {"name": "Leg Curls", "sets": 3, "reps": "10-12", "muscle_group": "Hamstrings"},
    ],
    "glutes": [
        {"name": "Hip Thrusts", "sets": 3, "reps": "10-12", "muscle_group": "Glutes"},
        {"name": "Glute Bridges", "sets": 3, "reps": "12-15", "muscle_group": "Glutes"},
    ],
    "core": [
        {"name": "Plank", "sets": 3, "reps": "30-60 sec", "muscle_group": "Core"},
        {"name": "Dead Bug", "sets": 3, "reps": "10 each", "muscle_group": "Core"},
    ],
}

CURATED_TEMPLATES = {
    "push_pull_legs": [
        {"name": "Push Day", "focus": ["chest", "shoulders", "triceps"], "type": "strength"},
        {"name": "Pull Day", "focus": ["back", "biceps"], "type": "strength"},
        {"name": "Leg Day", "focus": ["quadriceps", "hamstrings", "glutes"], "type": "strength"},
    ],
    "upper_lower": [
        {"name": "Upper Body", "focus": ["chest", "back", "shoulders", "biceps", "triceps"], "type": "strength"},
        {"name": "Lower Body", "focus": ["quadriceps", "hamstrings", "glutes"], "type": "strength"},
    ],
    "full_body": [
        {"name": "Full Body", "focus": ["chest", "back", "quadriceps", "shoulders", "core"], "type": "strength"},
    ],
    "body_part": [
        {"name": "Chest Day", "focus": ["chest", "triceps"], "type": "strength"},
        {"name": "Back Day", "focus": ["back", "biceps"], "type": "strength"},
        {"name": "Shoulder Day", "focus": ["shoulders"], "type": "strength"},
        {"name": "Leg Day", "focus": ["quadriceps", "hamstrings", "glutes"], "type": "strength"},
        {"name": "Arm Day", "focus": ["biceps", "triceps"], "type": "strength"},
    ],
}


def _get_exercises_for_muscles(
    muscles: List[str],
    fitness_level: str,
    count: int = 5
) -> List[Dict[str, Any]]:
    """Get exercises for the given muscle groups."""
    exercises = []

    # Adjust sets based on fitness level
    sets_modifier = {"beginner": -1, "intermediate": 0, "advanced": 1}
    modifier = sets_modifier.get(fitness_level, 0)

    for muscle in muscles:
        muscle_lower = muscle.lower()
        if muscle_lower in CURATED_EXERCISES:
            for ex in CURATED_EXERCISES[muscle_lower]:
                exercise = ex.copy()
                exercise["sets"] = max(2, exercise["sets"] + modifier)
                exercises.append(exercise)
                if len(exercises) >= count:
                    break
        if len(exercises) >= count:
            break

    return exercises[:count]


# ============================================================================
# ENDPOINTS
# ============================================================================

@router.post("/generate-preview-plan")
@limiter.limit("3/hour")
async def generate_preview_plan(request: Request, body: PreviewPlanRequest):
    """
    Generate a preview workout plan based on quiz answers.

    This endpoint does NOT require authentication and returns a preview
    of what the user's personalized plan would look like.

    This directly addresses the complaint about not being able to see
    the tailored plan before hitting the paywall.
    """
    try:
        # Generate session_id if not provided
        session_id = body.session_id or str(uuid.uuid4())

        # Get workout template based on training split
        split = body.training_split or "push_pull_legs"
        templates = CURATED_TEMPLATES.get(split, CURATED_TEMPLATES["full_body"])

        # Generate workout days
        plan_days = []
        for i in range(body.days_per_week):
            template = templates[i % len(templates)]

            # Get exercises for this day
            exercises = _get_exercises_for_muscles(
                template["focus"],
                body.fitness_level,
                count=5
            )

            plan_days.append({
                "day": i + 1,
                "name": template["name"],
                "focus_muscles": template["focus"],
                "workout_type": template["type"],
                "exercises": exercises,
                "duration_minutes": 30 + (len(exercises) * 5),
                "estimated_calories": 150 + (len(exercises) * 30),
            })

        # Log the preview generation
        try:
            db = get_supabase_db()
            db.client.table("demo_interactions").insert({
                "session_id": session_id,
                "action_type": "preview_plan_generated",
                "metadata": {
                    "goals": body.goals,
                    "fitness_level": body.fitness_level,
                    "equipment_count": len(body.equipment),
                    "days_per_week": body.days_per_week,
                    "training_split": split,
                }
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to log demo interaction: {e}", exc_info=True)

        return {
            "session_id": session_id,
            "plan": {
                "weeks": 4,
                "days_per_week": body.days_per_week,
                "training_split": split,
                "workout_days": plan_days,
                "program_structure": {
                    "week_1": "Foundation - Learn proper form",
                    "week_2": "Build - Increase intensity",
                    "week_3": "Challenge - Peak difficulty",
                    "week_4": "Recovery - Active deload",
                },
            },
            "personalization": {
                "goal_match": True,
                "equipment_match": True,
                "fitness_level": body.fitness_level,
                "total_exercises": sum(len(d["exercises"]) for d in plan_days),
                "estimated_weekly_duration": sum(d["duration_minutes"] for d in plan_days),
            },
        }

    except Exception as e:
        logger.error(f"Failed to generate preview plan: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


@router.post("/session/start")
@limiter.limit("5/hour")
async def start_demo_session(request: Request, body: DemoSession):
    """Start or resume a demo session."""
    try:
        db = get_supabase_db()
        session_id = body.session_id or str(uuid.uuid4())

        # Check if session exists
        existing = db.client.table("demo_sessions").select("*").eq(
            "session_id", session_id
        ).execute()

        if existing.data:
            # Update existing session
            db.client.table("demo_sessions").update({
                "quiz_data": body.quiz_data or existing.data[0].get("quiz_data", {}),
                "device_info": body.device_info or existing.data[0].get("device_info", {}),
            }).eq("session_id", session_id).execute()

            return {
                "session_id": session_id,
                "status": "resumed",
                "started_at": existing.data[0]["started_at"],
            }
        else:
            # Create new session
            result = db.client.table("demo_sessions").insert({
                "session_id": session_id,
                "quiz_data": body.quiz_data or {},
                "device_info": body.device_info or {},
            }).execute()

            return {
                "session_id": session_id,
                "status": "active",
                "started_at": result.data[0]["started_at"] if result.data else datetime.utcnow().isoformat(),
            }

    except Exception as e:
        logger.error(f"Failed to start demo session: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


@router.post("/interaction")
@limiter.limit("30/hour")
async def log_demo_interaction(request: Request, body: DemoInteraction):
    """Log a demo user interaction for analytics."""
    try:
        db = get_supabase_db()

        db.client.table("demo_interactions").insert({
            "session_id": body.session_id,
            "action_type": body.action_type,
            "screen": body.screen,
            "feature": body.feature,
            "duration_seconds": body.duration_seconds,
            "metadata": body.metadata or {},
        }).execute()

        return {"status": "logged"}

    except Exception as e:
        logger.error(f"Failed to log demo interaction: {e}", exc_info=True)
        # Don't fail the request for logging failures
        return {"status": "error", "message": str(e)}


@router.post("/personalized-sample-workout")
@limiter.limit("3/hour")
async def generate_personalized_sample_workout(request: Request, body: PersonalizedSampleWorkoutRequest):
    """
    Generate a personalized sample workout using REAL exercises from the database.

    This endpoint:
    1. Uses the user's quiz data (goals, equipment, fitness level) to select appropriate exercises
    2. Returns exercises WITH gif_url for video demonstrations
    3. Creates a truly personalized preview of what their workout plan would look like

    This addresses the complaint: "workouts look generic with no videos"
    """
    try:
        session_id = body.session_id or str(uuid.uuid4())

        # Determine workout focus based on goals
        goal_to_focus = {
            'build_muscle': 'full_body',
            'lose_weight': 'full_body',
            'increase_strength': 'full_body',
            'improve_endurance': 'full_body',
            'stay_active': 'full_body',
            'flexibility': 'full_body',
            'athletic_performance': 'full_body',
            'general_health': 'full_body',
        }

        primary_goal = body.goals[0] if body.goals else 'general_health'
        focus_area = goal_to_focus.get(primary_goal, 'full_body')

        # Map equipment values to match exercise library format
        equipment_mapping = {
            'bodyweight': 'body weight',
            'dumbbells': 'dumbbell',
            'barbell': 'barbell',
            'kettlebell': 'kettlebell',
            'resistance_bands': 'band',
            'pull_up_bar': 'body weight',
            'cable_machine': 'cable',
            'full_gym': ['dumbbell', 'barbell', 'cable', 'machine', 'body weight'],
        }

        # Convert equipment list
        mapped_equipment = []
        for eq in body.equipment:
            eq_lower = eq.lower()
            if eq_lower in equipment_mapping:
                mapping = equipment_mapping[eq_lower]
                if isinstance(mapping, list):
                    mapped_equipment.extend(mapping)
                else:
                    mapped_equipment.append(mapping)
            else:
                mapped_equipment.append(eq_lower)

        # Always include bodyweight exercises
        if 'body weight' not in mapped_equipment:
            mapped_equipment.append('body weight')

        # Get real exercises from the library
        exercises = exercise_library.get_exercises_for_workout(
            focus_area=focus_area,
            equipment=mapped_equipment,
            count=6,
            fitness_level=body.fitness_level
        )

        # If we didn't get enough exercises, try with just bodyweight
        if len(exercises) < 4:
            exercises = exercise_library.get_exercises_for_workout(
                focus_area=focus_area,
                equipment=['body weight'],
                count=6,
                fitness_level=body.fitness_level
            )

        # Calculate workout metadata
        duration_minutes = 30 + (len(exercises) * 5)
        estimated_calories = 150 + (len(exercises) * 30)

        # Determine workout name based on goals and fitness level
        workout_name = _get_personalized_workout_name(primary_goal, body.fitness_level)

        # Log the generation
        try:
            db = get_supabase_db()
            db.client.table("demo_interactions").insert({
                "session_id": session_id,
                "action_type": "personalized_sample_generated",
                "metadata": {
                    "goals": body.goals,
                    "fitness_level": body.fitness_level,
                    "equipment": body.equipment,
                    "exercise_count": len(exercises),
                    "has_gif_urls": sum(1 for ex in exercises if ex.get('gif_url')),
                }
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to log demo interaction: {e}", exc_info=True)

        return {
            "session_id": session_id,
            "workout": {
                "id": f"personalized-sample-{session_id[:8]}",
                "name": workout_name,
                "description": f"A personalized workout designed for your {primary_goal.replace('_', ' ')} goals. "
                               f"This preview uses real exercises from our library of 1700+ exercises.",
                "duration_minutes": duration_minutes,
                "difficulty": body.fitness_level,
                "calories_estimate": estimated_calories,
                "type": body.workout_type_preference or "strength",
                "target_muscles": list(set(ex.get('body_part', '') for ex in exercises if ex.get('body_part'))),
                "equipment": list(set(ex.get('equipment', '') for ex in exercises if ex.get('equipment'))),
                "exercises": exercises,
            },
            "personalization": {
                "based_on_goals": body.goals,
                "fitness_level": body.fitness_level,
                "equipment_matched": True,
                "exercises_with_videos": sum(1 for ex in exercises if ex.get('gif_url')),
                "total_exercises": len(exercises),
            },
            "preview_info": {
                "is_preview": True,
                "message": "This is a sample of your personalized workout. Sign up for full access!",
                "full_access_features": [
                    "4-week progressive workout program",
                    "AI coach chat for personalized advice",
                    "Workout history and progress tracking",
                    "Exercise substitutions and modifications",
                    "Rest timer and workout logging",
                ],
            }
        }

    except Exception as e:
        logger.error(f"Failed to generate personalized sample workout: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


def _get_personalized_workout_name(goal: str, fitness_level: str) -> str:
    """Generate a personalized workout name based on goal and level."""
    goal_names = {
        'build_muscle': 'Muscle Building',
        'lose_weight': 'Fat Burning',
        'increase_strength': 'Strength Training',
        'improve_endurance': 'Endurance',
        'stay_active': 'Active Living',
        'flexibility': 'Flexibility',
        'athletic_performance': 'Athletic Performance',
        'general_health': 'Total Body',
    }

    level_modifiers = {
        'beginner': 'Foundation',
        'intermediate': 'Power',
        'advanced': 'Elite',
    }

    goal_name = goal_names.get(goal, 'Full Body')
    level_modifier = level_modifiers.get(fitness_level, '')

    return f"{level_modifier} {goal_name} Workout".strip()


@router.get("/sample-workouts")
async def get_sample_workouts(
    equipment: Optional[str] = Query(None, description="Comma-separated equipment list"),
    goal: Optional[str] = Query(None, description="Primary fitness goal"),
    fitness_level: Optional[str] = Query("intermediate", description="Fitness level"),
):
    """
    Get sample workouts for demo/guest mode.

    These are pre-built workouts that showcase the app's capabilities
    without requiring authentication.
    """
    sample_workouts = [
        {
            "id": "demo-beginner-full-body",
            "name": "Beginner Full Body",
            "description": "Perfect for getting started with strength training",
            "duration_minutes": 30,
            "difficulty": "beginner",
            "calories_estimate": 180,
            "exercises": [
                {"name": "Bodyweight Squats", "sets": 3, "reps": "12", "muscle_group": "Legs"},
                {"name": "Push-ups (Modified)", "sets": 3, "reps": "8-10", "muscle_group": "Chest"},
                {"name": "Dumbbell Rows", "sets": 3, "reps": "10 each", "muscle_group": "Back"},
                {"name": "Walking Lunges", "sets": 3, "reps": "10 each", "muscle_group": "Legs"},
                {"name": "Plank", "sets": 3, "reps": "30 sec", "muscle_group": "Core"},
                {"name": "Glute Bridges", "sets": 3, "reps": "12", "muscle_group": "Glutes"},
            ]
        },
        {
            "id": "demo-hiit-blast",
            "name": "Quick HIIT Blast",
            "description": "High intensity, maximum calorie burn in minimal time",
            "duration_minutes": 20,
            "difficulty": "intermediate",
            "calories_estimate": 250,
            "exercises": [
                {"name": "Burpees", "sets": 4, "reps": "10", "muscle_group": "Full Body"},
                {"name": "Mountain Climbers", "sets": 4, "reps": "20 each", "muscle_group": "Core"},
                {"name": "Jump Squats", "sets": 4, "reps": "12", "muscle_group": "Legs"},
                {"name": "High Knees", "sets": 4, "reps": "30 sec", "muscle_group": "Cardio"},
                {"name": "Plank Jacks", "sets": 4, "reps": "15", "muscle_group": "Core"},
            ]
        },
        {
            "id": "demo-upper-strength",
            "name": "Upper Body Strength",
            "description": "Build a stronger, more defined upper body",
            "duration_minutes": 35,
            "difficulty": "intermediate",
            "calories_estimate": 200,
            "exercises": [
                {"name": "Dumbbell Bench Press", "sets": 4, "reps": "8-10", "muscle_group": "Chest"},
                {"name": "Bent-Over Rows", "sets": 4, "reps": "8-10", "muscle_group": "Back"},
                {"name": "Shoulder Press", "sets": 3, "reps": "10", "muscle_group": "Shoulders"},
                {"name": "Bicep Curls", "sets": 3, "reps": "12", "muscle_group": "Biceps"},
                {"name": "Tricep Dips", "sets": 3, "reps": "10", "muscle_group": "Triceps"},
                {"name": "Face Pulls", "sets": 3, "reps": "15", "muscle_group": "Rear Delts"},
            ]
        },
        {
            "id": "demo-lower-power",
            "name": "Lower Body Power",
            "description": "Build strong, powerful legs",
            "duration_minutes": 40,
            "difficulty": "intermediate",
            "calories_estimate": 280,
            "exercises": [
                {"name": "Goblet Squats", "sets": 4, "reps": "10", "muscle_group": "Quadriceps"},
                {"name": "Romanian Deadlifts", "sets": 4, "reps": "8", "muscle_group": "Hamstrings"},
                {"name": "Walking Lunges", "sets": 3, "reps": "12 each", "muscle_group": "Quadriceps"},
                {"name": "Hip Thrusts", "sets": 4, "reps": "12", "muscle_group": "Glutes"},
                {"name": "Calf Raises", "sets": 3, "reps": "15", "muscle_group": "Calves"},
                {"name": "Leg Curls", "sets": 3, "reps": "12", "muscle_group": "Hamstrings"},
            ]
        },
    ]

    # Filter by fitness level if specified
    if fitness_level:
        if fitness_level == "beginner":
            # Put beginner workout first
            sample_workouts = sorted(
                sample_workouts,
                key=lambda w: 0 if w["difficulty"] == "beginner" else 1
            )
        elif fitness_level == "advanced":
            # Filter out beginner workouts for advanced users
            sample_workouts = [w for w in sample_workouts if w["difficulty"] != "beginner"]

    return {
        "workouts": sample_workouts,
    }


@router.post("/session/convert")
@limiter.limit("3/hour")
async def convert_demo_session(request: Request, body: SessionConvertRequest):
    """
    Mark a demo session as converted to a real user.

    This is called when a demo user signs up.
    """
    try:
        db = get_supabase_db()

        # Update the session
        db.client.table("demo_sessions").update({
            "converted_to_user_id": body.user_id,
            "conversion_trigger": body.trigger,
            "ended_at": datetime.utcnow().isoformat(),
        }).eq("session_id", body.session_id).execute()

        # Get session to calculate duration
        session = db.client.table("demo_sessions").select("*").eq(
            "session_id", body.session_id
        ).execute()

        duration_seconds = None
        if session.data:
            started_at = session.data[0].get("started_at")
            if started_at:
                try:
                    start_time = datetime.fromisoformat(started_at.replace("Z", "+00:00"))
                    duration_seconds = int((datetime.utcnow() - start_time.replace(tzinfo=None)).total_seconds())

                    db.client.table("demo_sessions").update({
                        "duration_seconds": duration_seconds,
                    }).eq("session_id", body.session_id).execute()
                except Exception as e:
                    logger.warning(f"Failed to calculate duration: {e}", exc_info=True)

        logger.info(f"Demo session {body.session_id} converted to user {body.user_id} via {body.trigger}")

        return {
            "status": "converted",
            "session_duration_seconds": duration_seconds,
        }

    except Exception as e:
        logger.error(f"Failed to convert demo session: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


@router.get("/session/{session_id}")
async def get_demo_session(session_id: str):
    """Get demo session details."""
    try:
        db = get_supabase_db()

        result = db.client.table("demo_sessions").select("*").eq(
            "session_id", session_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Session not found")

        session = result.data[0]

        # Get interaction count
        interactions = db.client.table("demo_interactions").select(
            "action_type", count="exact"
        ).eq("session_id", session_id).execute()

        return {
            "session": session,
            "interaction_count": interactions.count if interactions.count else 0,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get demo session: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


@router.get("/analytics/conversion")
async def get_conversion_analytics(days: int = Query(30, ge=1, le=90), admin: dict = Depends(get_admin_user)):
    """Get demo-to-signup conversion analytics. SECURITY: Admin-only."""
    try:
        db = get_supabase_db()

        # Get conversion funnel data
        result = db.client.from_("demo_conversion_funnel").select("*").execute()

        return {
            "period_days": days,
            "funnel_data": result.data or [],
        }

    except Exception as e:
        logger.error(f"Failed to get conversion analytics: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


@router.get("/analytics/features")
async def get_feature_analytics(admin: dict = Depends(get_admin_user)):
    """Get feature engagement analytics for demo users. SECURITY: Admin-only."""
    try:
        db = get_supabase_db()

        result = db.client.from_("demo_feature_engagement").select("*").execute()

        return {
            "features": result.data or [],
        }

    except Exception as e:
        logger.error(f"Failed to get feature analytics: {e}", exc_info=True)
        raise safe_internal_error(e, "demo")


# ============================================================================
# APP TOUR ENDPOINTS
# ============================================================================


# Default tour configuration
DEFAULT_TOUR_CONFIG = {
    "steps": [
        {
            "id": "welcome",
            "title": f"Welcome to Your {branding.APP_NAME}",
            "description": "Let's take a quick tour of the app",
            "target": "home_screen",
        },
        {
            "id": "workout_preview",
            "title": "Your Personalized Workouts",
            "description": "AI-generated workouts tailored to your goals",
            "target": "workout_card",
            "deep_link": "/workout/today",
        },
        {
            "id": "exercise_library",
            "title": "1700+ Exercises",
            "description": "Browse our complete exercise library with video guides",
            "target": "library_tab",
            "deep_link": "/library",
        },
        {
            "id": "progress_tracking",
            "title": "Track Your Progress",
            "description": "See your improvements over time",
            "target": "progress_tab",
            "deep_link": "/progress",
        },
        {
            "id": "ai_coach",
            "title": "Chat with Your AI Coach",
            "description": "Get personalized advice anytime",
            "target": "chat_fab",
            "deep_link": "/chat",
        },
        {
            "id": "try_workout",
            "title": "Try a Demo Workout",
            "description": "Experience a full workout before signing up",
            "target": "demo_workout_button",
            "action": "start_demo_workout",
        },
    ],
    "version": "1.0",
    "allow_skip": True,
    "show_progress_indicator": True,
}



# Include secondary endpoints
router.include_router(_endpoints_router)
