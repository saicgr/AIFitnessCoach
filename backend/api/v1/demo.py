"""
Demo and Trial API endpoints.

These endpoints allow users to preview the app before signing up,
and track their engagement to understand conversion patterns.

This addresses the common complaint:
"One of those apps where you answer a bunch of questions to get a 'tailored plan',
but then hit a paywall to even see how the app works, let alone what your plan
might look like."
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import uuid
import logging

from core.db import get_supabase_db
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
# FALLBACK EXERCISE DATA
# ============================================================================

FALLBACK_EXERCISES = {
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

WORKOUT_TEMPLATES = {
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
        if muscle_lower in FALLBACK_EXERCISES:
            for ex in FALLBACK_EXERCISES[muscle_lower]:
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
async def generate_preview_plan(request: PreviewPlanRequest):
    """
    Generate a preview workout plan based on quiz answers.

    This endpoint does NOT require authentication and returns a preview
    of what the user's personalized plan would look like.

    This directly addresses the complaint about not being able to see
    the tailored plan before hitting the paywall.
    """
    try:
        # Generate session_id if not provided
        session_id = request.session_id or str(uuid.uuid4())

        # Get workout template based on training split
        split = request.training_split or "push_pull_legs"
        templates = WORKOUT_TEMPLATES.get(split, WORKOUT_TEMPLATES["full_body"])

        # Generate workout days
        plan_days = []
        for i in range(request.days_per_week):
            template = templates[i % len(templates)]

            # Get exercises for this day
            exercises = _get_exercises_for_muscles(
                template["focus"],
                request.fitness_level,
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
                    "goals": request.goals,
                    "fitness_level": request.fitness_level,
                    "equipment_count": len(request.equipment),
                    "days_per_week": request.days_per_week,
                    "training_split": split,
                }
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to log demo interaction: {e}")

        return {
            "session_id": session_id,
            "plan": {
                "weeks": 4,
                "days_per_week": request.days_per_week,
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
                "fitness_level": request.fitness_level,
                "total_exercises": sum(len(d["exercises"]) for d in plan_days),
                "estimated_weekly_duration": sum(d["duration_minutes"] for d in plan_days),
            },
            "social_proof": {
                "similar_users": 10847,
                "avg_results_weeks": 4 if "lose_weight" in request.goals else 6,
                "success_rate": 87,
            }
        }

    except Exception as e:
        logger.error(f"Failed to generate preview plan: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/session/start")
async def start_demo_session(request: DemoSession):
    """Start or resume a demo session."""
    try:
        db = get_supabase_db()
        session_id = request.session_id or str(uuid.uuid4())

        # Check if session exists
        existing = db.client.table("demo_sessions").select("*").eq(
            "session_id", session_id
        ).execute()

        if existing.data:
            # Update existing session
            db.client.table("demo_sessions").update({
                "quiz_data": request.quiz_data or existing.data[0].get("quiz_data", {}),
                "device_info": request.device_info or existing.data[0].get("device_info", {}),
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
                "quiz_data": request.quiz_data or {},
                "device_info": request.device_info or {},
            }).execute()

            return {
                "session_id": session_id,
                "status": "active",
                "started_at": result.data[0]["started_at"] if result.data else datetime.utcnow().isoformat(),
            }

    except Exception as e:
        logger.error(f"Failed to start demo session: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/interaction")
async def log_demo_interaction(request: DemoInteraction):
    """Log a demo user interaction for analytics."""
    try:
        db = get_supabase_db()

        db.client.table("demo_interactions").insert({
            "session_id": request.session_id,
            "action_type": request.action_type,
            "screen": request.screen,
            "feature": request.feature,
            "duration_seconds": request.duration_seconds,
            "metadata": request.metadata or {},
        }).execute()

        return {"status": "logged"}

    except Exception as e:
        logger.error(f"Failed to log demo interaction: {e}")
        # Don't fail the request for logging failures
        return {"status": "error", "message": str(e)}


@router.post("/personalized-sample-workout")
async def generate_personalized_sample_workout(request: PersonalizedSampleWorkoutRequest):
    """
    Generate a personalized sample workout using REAL exercises from the database.

    This endpoint:
    1. Uses the user's quiz data (goals, equipment, fitness level) to select appropriate exercises
    2. Returns exercises WITH gif_url for video demonstrations
    3. Creates a truly personalized preview of what their workout plan would look like

    This addresses the complaint: "workouts look generic with no videos"
    """
    try:
        session_id = request.session_id or str(uuid.uuid4())

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

        primary_goal = request.goals[0] if request.goals else 'general_health'
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
        for eq in request.equipment:
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
            fitness_level=request.fitness_level
        )

        # If we didn't get enough exercises, try with just bodyweight
        if len(exercises) < 4:
            exercises = exercise_library.get_exercises_for_workout(
                focus_area=focus_area,
                equipment=['body weight'],
                count=6,
                fitness_level=request.fitness_level
            )

        # Calculate workout metadata
        duration_minutes = 30 + (len(exercises) * 5)
        estimated_calories = 150 + (len(exercises) * 30)

        # Determine workout name based on goals and fitness level
        workout_name = _get_personalized_workout_name(primary_goal, request.fitness_level)

        # Log the generation
        try:
            db = get_supabase_db()
            db.client.table("demo_interactions").insert({
                "session_id": session_id,
                "action_type": "personalized_sample_generated",
                "metadata": {
                    "goals": request.goals,
                    "fitness_level": request.fitness_level,
                    "equipment": request.equipment,
                    "exercise_count": len(exercises),
                    "has_gif_urls": sum(1 for ex in exercises if ex.get('gif_url')),
                }
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to log demo interaction: {e}")

        return {
            "session_id": session_id,
            "workout": {
                "id": f"personalized-sample-{session_id[:8]}",
                "name": workout_name,
                "description": f"A personalized workout designed for your {primary_goal.replace('_', ' ')} goals. "
                               f"This preview uses real exercises from our library of 1700+ exercises.",
                "duration_minutes": duration_minutes,
                "difficulty": request.fitness_level,
                "calories_estimate": estimated_calories,
                "type": request.workout_type_preference or "strength",
                "target_muscles": list(set(ex.get('body_part', '') for ex in exercises if ex.get('body_part'))),
                "equipment": list(set(ex.get('equipment', '') for ex in exercises if ex.get('equipment'))),
                "exercises": exercises,
            },
            "personalization": {
                "based_on_goals": request.goals,
                "fitness_level": request.fitness_level,
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
        logger.error(f"Failed to generate personalized sample workout: {e}")
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
        "total_available": 1722,  # Full library count
        "message": "Sign up to access 1,700+ personalized workout variations!"
    }


@router.post("/session/convert")
async def convert_demo_session(request: SessionConvertRequest):
    """
    Mark a demo session as converted to a real user.

    This is called when a demo user signs up.
    """
    try:
        db = get_supabase_db()

        # Update the session
        db.client.table("demo_sessions").update({
            "converted_to_user_id": request.user_id,
            "conversion_trigger": request.trigger,
            "ended_at": datetime.utcnow().isoformat(),
        }).eq("session_id", request.session_id).execute()

        # Get session to calculate duration
        session = db.client.table("demo_sessions").select("*").eq(
            "session_id", request.session_id
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
                    }).eq("session_id", request.session_id).execute()
                except Exception as e:
                    logger.warning(f"Failed to calculate duration: {e}")

        logger.info(f"Demo session {request.session_id} converted to user {request.user_id} via {request.trigger}")

        return {
            "status": "converted",
            "session_duration_seconds": duration_seconds,
        }

    except Exception as e:
        logger.error(f"Failed to convert demo session: {e}")
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
        logger.error(f"Failed to get demo session: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/analytics/conversion")
async def get_conversion_analytics(days: int = Query(30, ge=1, le=90)):
    """Get demo-to-signup conversion analytics."""
    try:
        db = get_supabase_db()

        # Get conversion funnel data
        result = db.client.from_("demo_conversion_funnel").select("*").execute()

        return {
            "period_days": days,
            "funnel_data": result.data or [],
        }

    except Exception as e:
        logger.error(f"Failed to get conversion analytics: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/analytics/features")
async def get_feature_analytics():
    """Get feature engagement analytics for demo users."""
    try:
        db = get_supabase_db()

        result = db.client.from_("demo_feature_engagement").select("*").execute()

        return {
            "features": result.data or [],
        }

    except Exception as e:
        logger.error(f"Failed to get feature analytics: {e}")
        raise safe_internal_error(e, "demo")


# ============================================================================
# APP TOUR ENDPOINTS
# ============================================================================


# Default tour configuration
DEFAULT_TOUR_CONFIG = {
    "steps": [
        {
            "id": "welcome",
            "title": "Welcome to Your FitWiz",
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


@router.post("/tour/start")
async def start_app_tour(request: TourStartRequest):
    """
    Start an app tour session.

    This endpoint creates a new tour session and returns tour configuration.
    For new users, it always shows the tour. For returning users from settings
    or deep links, it allows retaking the tour.
    """
    try:
        db = get_supabase_db()
        session_id = str(uuid.uuid4())

        should_show_tour = True

        # Check if user has already completed the tour (only for new_user source)
        if request.source == "new_user":
            if request.user_id:
                existing = db.client.table("app_tour_sessions").select(
                    "id, status"
                ).eq("user_id", request.user_id).eq("status", "completed").execute()

                if existing.data:
                    should_show_tour = False
            elif request.device_id:
                existing = db.client.table("app_tour_sessions").select(
                    "id, status"
                ).eq("device_id", request.device_id).eq("status", "completed").execute()

                if existing.data:
                    should_show_tour = False

        # Create tour session
        session_data = {
            "session_id": session_id,
            "user_id": request.user_id,
            "device_id": request.device_id,
            "source": request.source,
            "device_info": request.device_info or {},
            "app_version": request.app_version,
            "platform": request.platform,
            "status": "started",
            "steps_completed": [],
            "deep_links_clicked": [],
            "started_at": datetime.utcnow().isoformat(),
        }

        db.client.table("app_tour_sessions").insert(session_data).execute()

        # Log to user_context_logs if user_id provided
        if request.user_id:
            try:
                db.client.table("user_context_logs").insert({
                    "user_id": request.user_id,
                    "event_type": "app_tour_started",
                    "event_data": {
                        "session_id": session_id,
                        "source": request.source,
                        "platform": request.platform,
                    },
                }).execute()
            except Exception as e:
                logger.warning(f"Failed to log tour start to user_context_logs: {e}")

        return {
            "session_id": session_id,
            "should_show_tour": should_show_tour,
            "tour_config": DEFAULT_TOUR_CONFIG,
        }

    except Exception as e:
        logger.error(f"Failed to start app tour: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/tour/step-completed")
async def complete_tour_step(request: TourStepCompletedRequest):
    """
    Log tour step completion.

    Updates the session with completed step info and tracks
    any deep links that were clicked.
    """
    try:
        db = get_supabase_db()

        # Get current session
        result = db.client.table("app_tour_sessions").select("*").eq(
            "session_id", request.session_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Tour session not found")

        session = result.data[0]

        # Update steps_completed array
        steps_completed = session.get("steps_completed", []) or []
        step_data = {
            "step_id": request.step_id,
            "completed_at": datetime.utcnow().isoformat(),
            "duration_seconds": request.duration_seconds,
            "action_taken": request.action_taken,
        }
        steps_completed.append(step_data)

        # Track deep_links_clicked
        deep_links_clicked = session.get("deep_links_clicked", []) or []
        if request.deep_link_target:
            deep_links_clicked.append({
                "step_id": request.step_id,
                "target": request.deep_link_target,
                "clicked_at": datetime.utcnow().isoformat(),
            })

        # Update session
        db.client.table("app_tour_sessions").update({
            "steps_completed": steps_completed,
            "deep_links_clicked": deep_links_clicked,
            "last_activity_at": datetime.utcnow().isoformat(),
        }).eq("session_id", request.session_id).execute()

        return {
            "status": "logged",
            "step_id": request.step_id,
            "total_steps_completed": len(steps_completed),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log tour step completion: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/tour/completed")
async def complete_app_tour(request: TourCompletedRequest):
    """
    Mark tour as completed or skipped.

    Calculates duration, updates session status, and logs
    to user_context_logs for analytics.
    """
    try:
        db = get_supabase_db()

        # Get current session
        result = db.client.table("app_tour_sessions").select("*").eq(
            "session_id", request.session_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Tour session not found")

        session = result.data[0]

        # Calculate duration
        total_duration = request.total_duration_seconds
        if not total_duration and session.get("started_at"):
            try:
                started_at = datetime.fromisoformat(
                    session["started_at"].replace("Z", "+00:00")
                )
                total_duration = int(
                    (datetime.utcnow() - started_at.replace(tzinfo=None)).total_seconds()
                )
            except Exception as e:
                logger.warning(f"Failed to calculate tour duration: {e}")

        # Update session with completion data
        update_data = {
            "status": request.status,
            "completed_at": datetime.utcnow().isoformat(),
            "skip_step": request.skip_step,
            "demo_workout_started": request.demo_workout_started,
            "demo_workout_completed": request.demo_workout_completed,
            "plan_preview_viewed": request.plan_preview_viewed,
            "total_duration_seconds": total_duration,
        }

        # Merge deep_links_clicked with existing
        if request.deep_links_clicked:
            existing_links = session.get("deep_links_clicked", []) or []
            for link in request.deep_links_clicked:
                if link not in [dl.get("target") for dl in existing_links]:
                    existing_links.append({
                        "target": link,
                        "clicked_at": datetime.utcnow().isoformat(),
                    })
            update_data["deep_links_clicked"] = existing_links

        db.client.table("app_tour_sessions").update(update_data).eq(
            "session_id", request.session_id
        ).execute()

        # Log to user_context_logs
        user_id = session.get("user_id")
        if user_id:
            try:
                db.client.table("user_context_logs").insert({
                    "user_id": user_id,
                    "event_type": f"app_tour_{request.status}",
                    "event_data": {
                        "session_id": request.session_id,
                        "skip_step": request.skip_step,
                        "demo_workout_started": request.demo_workout_started,
                        "demo_workout_completed": request.demo_workout_completed,
                        "total_duration_seconds": total_duration,
                        "deep_links_clicked": request.deep_links_clicked,
                    },
                }).execute()
            except Exception as e:
                logger.warning(f"Failed to log tour completion to user_context_logs: {e}")

        # Update ui_onboarding_state JSONB if user_id exists
        if user_id:
            try:
                # Get current user data
                user_result = db.client.table("users").select(
                    "ui_onboarding_state"
                ).eq("id", user_id).execute()

                if user_result.data:
                    current_state = user_result.data[0].get("ui_onboarding_state", {}) or {}
                    current_state["app_tour_completed"] = request.status == "completed"
                    current_state["app_tour_skipped"] = request.status == "skipped"
                    current_state["app_tour_completed_at"] = datetime.utcnow().isoformat()

                    db.client.table("users").update({
                        "ui_onboarding_state": current_state,
                    }).eq("id", user_id).execute()
            except Exception as e:
                logger.warning(f"Failed to update ui_onboarding_state: {e}")

        return {
            "status": request.status,
            "total_duration_seconds": total_duration,
            "steps_completed": len(session.get("steps_completed", []) or []),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete app tour: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/tour/status/{identifier}")
async def get_tour_status(
    identifier: str,
    identifier_type: str = Query("user_id", description="Type of identifier: user_id or device_id"),
):
    """
    Get tour status for a user or device.

    Returns whether the user/device has completed the tour,
    total tour sessions, and latest session info.
    """
    try:
        db = get_supabase_db()

        # Validate identifier_type
        if identifier_type not in ["user_id", "device_id"]:
            raise HTTPException(
                status_code=400,
                detail="identifier_type must be 'user_id' or 'device_id'"
            )

        # Query sessions for this identifier
        result = db.client.table("app_tour_sessions").select("*").eq(
            identifier_type, identifier
        ).order("started_at", desc=True).execute()

        sessions = result.data or []

        has_completed_tour = any(
            s.get("status") == "completed" for s in sessions
        )

        latest_session = sessions[0] if sessions else None

        # Determine if we should show the tour
        should_show_tour = not has_completed_tour

        return {
            "identifier": identifier,
            "identifier_type": identifier_type,
            "has_completed_tour": has_completed_tour,
            "total_tour_sessions": len(sessions),
            "latest_session": {
                "session_id": latest_session.get("session_id"),
                "status": latest_session.get("status"),
                "source": latest_session.get("source"),
                "started_at": latest_session.get("started_at"),
                "completed_at": latest_session.get("completed_at"),
                "steps_completed": len(latest_session.get("steps_completed", []) or []),
            } if latest_session else None,
            "should_show_tour": should_show_tour,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get tour status: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/tour/analytics")
async def get_tour_analytics(
    days: int = Query(30, ge=1, le=90, description="Number of days to analyze"),
    source: Optional[str] = Query(None, description="Filter by source"),
    platform: Optional[str] = Query(None, description="Filter by platform"),
):
    """
    Get tour analytics (admin endpoint).

    Returns aggregated analytics about tour completion rates,
    step drop-off points, and engagement metrics.
    """
    try:
        db = get_supabase_db()

        # Try to get data from tour_analytics view first
        try:
            result = db.client.from_("tour_analytics").select("*").execute()
            if result.data:
                analytics = result.data[0] if result.data else {}
                return {
                    "period_days": days,
                    "source_filter": source,
                    "platform_filter": platform,
                    "analytics": analytics,
                }
        except Exception:
            # View doesn't exist, calculate manually
            pass

        # Calculate analytics from app_tour_sessions table
        cutoff_date = (datetime.utcnow() - timedelta(days=days)).isoformat()

        # Build query
        query = db.client.table("app_tour_sessions").select("*").gte(
            "started_at", cutoff_date
        )

        if source:
            query = query.eq("source", source)
        if platform:
            query = query.eq("platform", platform)

        result = query.execute()
        sessions = result.data or []

        # Calculate metrics
        total_sessions = len(sessions)
        completed_sessions = sum(1 for s in sessions if s.get("status") == "completed")
        skipped_sessions = sum(1 for s in sessions if s.get("status") == "skipped")

        # Calculate step completion rates
        step_completions = {}
        for session in sessions:
            for step in (session.get("steps_completed") or []):
                step_id = step.get("step_id", "unknown")
                step_completions[step_id] = step_completions.get(step_id, 0) + 1

        # Calculate average duration
        durations = [
            s.get("total_duration_seconds")
            for s in sessions
            if s.get("total_duration_seconds")
        ]
        avg_duration = sum(durations) / len(durations) if durations else 0

        # Demo workout engagement
        demo_started = sum(1 for s in sessions if s.get("demo_workout_started"))
        demo_completed = sum(1 for s in sessions if s.get("demo_workout_completed"))

        # Deep link engagement
        total_deep_links = sum(
            len(s.get("deep_links_clicked") or [])
            for s in sessions
        )

        # Source breakdown
        source_breakdown = {}
        for session in sessions:
            src = session.get("source", "unknown")
            source_breakdown[src] = source_breakdown.get(src, 0) + 1

        # Platform breakdown
        platform_breakdown = {}
        for session in sessions:
            plat = session.get("platform", "unknown")
            platform_breakdown[plat] = platform_breakdown.get(plat, 0) + 1

        return {
            "period_days": days,
            "source_filter": source,
            "platform_filter": platform,
            "analytics": {
                "total_sessions": total_sessions,
                "completed_sessions": completed_sessions,
                "skipped_sessions": skipped_sessions,
                "completion_rate": round(
                    completed_sessions / total_sessions * 100, 2
                ) if total_sessions > 0 else 0,
                "skip_rate": round(
                    skipped_sessions / total_sessions * 100, 2
                ) if total_sessions > 0 else 0,
                "average_duration_seconds": round(avg_duration, 1),
                "step_completion_rates": {
                    step_id: round(count / total_sessions * 100, 2)
                    for step_id, count in step_completions.items()
                } if total_sessions > 0 else {},
                "demo_workout_engagement": {
                    "started": demo_started,
                    "completed": demo_completed,
                    "start_rate": round(
                        demo_started / total_sessions * 100, 2
                    ) if total_sessions > 0 else 0,
                    "completion_rate": round(
                        demo_completed / demo_started * 100, 2
                    ) if demo_started > 0 else 0,
                },
                "deep_link_engagement": {
                    "total_clicks": total_deep_links,
                    "avg_per_session": round(
                        total_deep_links / total_sessions, 2
                    ) if total_sessions > 0 else 0,
                },
                "source_breakdown": source_breakdown,
                "platform_breakdown": platform_breakdown,
            },
        }

    except Exception as e:
        logger.error(f"Failed to get tour analytics: {e}")
        raise safe_internal_error(e, "demo")


# ============================================================================
# ENHANCED PREVIEW WORKOUT ENDPOINTS
# ============================================================================


class FullPreviewPlanRequest(BaseModel):
    """Request for generating a full 4-week preview plan with AI."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    days_per_week: int
    training_split: Optional[str] = "push_pull_legs"
    session_id: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None


class TryWorkoutRequest(BaseModel):
    """Request to try a demo workout."""
    session_id: str
    workout_id: str  # demo workout ID like "demo-beginner-full-body"
    started_at: Optional[str] = None


class TryWorkoutCompleteRequest(BaseModel):
    """Request when demo workout is completed."""
    session_id: str
    workout_id: str
    duration_seconds: int
    exercises_completed: int
    exercises_total: int
    feedback: Optional[str] = None  # too_easy, just_right, too_hard


@router.get("/preview-workout/{day}")
async def get_preview_workout(
    day: int,
    session_id: Optional[str] = Query(None, description="Demo session ID"),
    fitness_level: str = Query("intermediate", description="Fitness level"),
    training_split: str = Query("push_pull_legs", description="Training split"),
):
    """
    Get a specific day's workout from the preview plan.

    This endpoint does NOT require authentication and returns the full
    workout details for a specific day.

    Args:
        day: Day number (1-7)
        session_id: Optional session ID for tracking
        fitness_level: User's fitness level
        training_split: Training split type

    Returns:
        Full workout with exercises, sets, reps, and instructions
    """
    try:
        if day < 1 or day > 7:
            raise HTTPException(status_code=400, detail="Day must be between 1 and 7")

        # Get workout template based on training split
        templates = WORKOUT_TEMPLATES.get(training_split, WORKOUT_TEMPLATES["full_body"])
        template = templates[(day - 1) % len(templates)]

        # Get more detailed exercises for this day
        exercises = []
        for muscle in template["focus"]:
            muscle_lower = muscle.lower()
            if muscle_lower in FALLBACK_EXERCISES:
                for ex in FALLBACK_EXERCISES[muscle_lower]:
                    exercise = ex.copy()
                    # Add more detail for preview
                    exercise["id"] = f"preview-{muscle_lower}-{len(exercises)}"
                    exercise["instructions"] = _get_exercise_instructions(ex["name"])
                    exercise["rest_seconds"] = 60 if fitness_level == "beginner" else 45
                    exercise["tempo"] = "2-1-2" if fitness_level == "beginner" else "2-0-2"
                    exercises.append(exercise)

        workout = {
            "id": f"preview-day-{day}",
            "day": day,
            "name": template["name"],
            "focus_muscles": template["focus"],
            "workout_type": template["type"],
            "fitness_level": fitness_level,
            "exercises": exercises,
            "duration_minutes": 30 + (len(exercises) * 5),
            "estimated_calories": 150 + (len(exercises) * 30),
            "warmup": _get_preview_warmup(template["focus"]),
            "cooldown": _get_preview_cooldown(),
        }

        # Log the preview view
        if session_id:
            try:
                db = get_supabase_db()
                db.client.table("demo_interactions").insert({
                    "session_id": session_id,
                    "action_type": "preview_workout_viewed",
                    "screen": f"preview_day_{day}",
                    "metadata": {
                        "day": day,
                        "workout_name": template["name"],
                        "exercise_count": len(exercises),
                        "fitness_level": fitness_level,
                    }
                }).execute()
            except Exception as e:
                logger.warning(f"Failed to log preview workout view: {e}")

        return {
            "workout": workout,
            "preview_info": {
                "is_preview": True,
                "full_access_features": [
                    "AI-personalized exercise selection",
                    "Video demonstrations for each exercise",
                    "Real-time workout tracking",
                    "Progress analytics",
                    "Chat with AI coach",
                ],
                "cta": "Start your 7-day free trial to unlock all features!",
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get preview workout: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/try-workout")
async def start_try_workout(request: TryWorkoutRequest):
    """
    Let users try ONE workout before subscribing.

    This allows demo users to actually start a workout and experience
    the app's workout tracking features before committing.

    Returns:
        - The full workout to try
        - A token that expires in 1 hour
        - Instructions for completing the trial workout
    """
    try:
        db = get_supabase_db()

        # Check if this session has already tried a workout
        existing = db.client.table("demo_interactions").select("id").eq(
            "session_id", request.session_id
        ).eq(
            "action_type", "try_workout_started"
        ).execute()

        if existing.data and len(existing.data) >= 1:
            # Allow one retry, but no more
            if len(existing.data) >= 2:
                return {
                    "status": "limit_reached",
                    "message": "You've already tried a workout. Sign up for full access!",
                    "cta": {
                        "action": "start_trial",
                        "text": "Start 7-Day Free Trial",
                        "benefit": "Unlimited workouts + AI coaching",
                    }
                }

        # Get the sample workout
        sample_workouts = await get_sample_workouts()
        workout = None
        for w in sample_workouts["workouts"]:
            if w["id"] == request.workout_id:
                workout = w
                break

        if not workout:
            # If workout_id doesn't match, provide the first sample
            workout = sample_workouts["workouts"][0]

        # Generate a try-workout token (simple UUID, could be JWT in production)
        try_token = str(uuid.uuid4())

        # Log the try workout start
        db.client.table("demo_interactions").insert({
            "session_id": request.session_id,
            "action_type": "try_workout_started",
            "feature": "try_workout",
            "metadata": {
                "workout_id": workout["id"],
                "workout_name": workout["name"],
                "try_token": try_token,
                "started_at": request.started_at or datetime.utcnow().isoformat(),
            }
        }).execute()

        # Add tracking info to workout
        workout["try_token"] = try_token
        workout["try_expires_at"] = (datetime.utcnow().replace(microsecond=0) +
                                      timedelta(hours=1)).isoformat() + "Z"

        return {
            "status": "started",
            "workout": workout,
            "try_token": try_token,
            "expires_in_minutes": 60,
            "instructions": {
                "1": "Complete the workout at your own pace",
                "2": "Track your sets and reps as you go",
                "3": "Rate the workout when you finish",
            },
            "preview_limitations": [
                "No exercise swap (premium feature)",
                "No rest timer customization",
                "No workout history saved",
            ],
            "upgrade_cta": {
                "text": "Sign up to save this workout and unlock 1700+ exercises!",
                "trial_available": True,
            }
        }

    except Exception as e:
        logger.error(f"Failed to start try workout: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/try-workout/complete")
async def complete_try_workout(request: TryWorkoutCompleteRequest):
    """
    Complete a try workout and record the experience.

    This captures valuable data about the demo user's workout experience
    and provides a strong conversion opportunity.
    """
    try:
        db = get_supabase_db()

        # Log the completion
        db.client.table("demo_interactions").insert({
            "session_id": request.session_id,
            "action_type": "try_workout_completed",
            "feature": "try_workout",
            "duration_seconds": request.duration_seconds,
            "metadata": {
                "workout_id": request.workout_id,
                "exercises_completed": request.exercises_completed,
                "exercises_total": request.exercises_total,
                "completion_rate": round(request.exercises_completed / request.exercises_total * 100, 1) if request.exercises_total > 0 else 0,
                "feedback": request.feedback,
            }
        }).execute()

        # Calculate a mock "results" to show value
        completion_rate = (request.exercises_completed / request.exercises_total * 100) if request.exercises_total > 0 else 0

        return {
            "status": "completed",
            "summary": {
                "duration_minutes": round(request.duration_seconds / 60, 1),
                "exercises_completed": request.exercises_completed,
                "exercises_total": request.exercises_total,
                "completion_rate": round(completion_rate, 1),
                "estimated_calories": 50 + (request.exercises_completed * 25),
            },
            "motivation": _get_completion_motivation(completion_rate),
            "conversion_offer": {
                "headline": "You crushed it! Keep the momentum going.",
                "offer": "Start your 7-day FREE trial",
                "benefits": [
                    "Personalized AI-generated workout plans",
                    "Track progress and see real results",
                    "Access to 1700+ exercises with video guides",
                    "AI coach to answer your questions",
                ],
                "urgency": "Limited time: First week completely free!",
            },
            "next_steps": {
                "primary": {
                    "action": "start_trial",
                    "text": "Start Free Trial",
                },
                "secondary": {
                    "action": "view_plans",
                    "text": "See All Plans",
                },
            }
        }

    except Exception as e:
        logger.error(f"Failed to complete try workout: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/exercises-previewed/{session_id}")
async def get_previewed_exercises(session_id: str):
    """
    Get list of exercises/workouts that were previewed in a session.

    Useful for:
    - Showing users what they've explored
    - Personalized conversion messaging
    - Analytics on feature engagement
    """
    try:
        db = get_supabase_db()

        result = db.client.table("demo_interactions").select(
            "action_type, screen, feature, metadata, created_at"
        ).eq(
            "session_id", session_id
        ).in_(
            "action_type", ["preview_workout_viewed", "exercise_view", "workout_preview", "try_workout_started", "try_workout_completed"]
        ).order("created_at", desc=True).execute()

        interactions = result.data or []

        # Extract unique exercises and workouts viewed
        exercises_viewed = set()
        workouts_viewed = set()
        try_workout_data = None

        for interaction in interactions:
            metadata = interaction.get("metadata", {})

            if interaction["action_type"] == "exercise_view":
                exercises_viewed.add(metadata.get("exercise_name", "Unknown"))
            elif interaction["action_type"] in ["preview_workout_viewed", "workout_preview"]:
                workouts_viewed.add(metadata.get("workout_name", interaction.get("screen", "Unknown")))
            elif interaction["action_type"] == "try_workout_completed":
                try_workout_data = metadata

        return {
            "session_id": session_id,
            "exercises_viewed": list(exercises_viewed),
            "workouts_viewed": list(workouts_viewed),
            "total_interactions": len(interactions),
            "try_workout_completed": try_workout_data is not None,
            "try_workout_summary": try_workout_data,
        }

    except Exception as e:
        logger.error(f"Failed to get previewed exercises: {e}")
        raise safe_internal_error(e, "demo")


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def _get_exercise_instructions(exercise_name: str) -> List[str]:
    """Get basic instructions for an exercise."""
    # In production, this would come from the exercise database
    instructions_map = {
        "Push-ups": [
            "Start in a plank position with hands shoulder-width apart",
            "Lower your body until chest nearly touches the floor",
            "Push back up to starting position",
            "Keep core tight throughout the movement",
        ],
        "Dumbbell Bench Press": [
            "Lie on a flat bench holding dumbbells at chest level",
            "Press dumbbells up until arms are extended",
            "Lower back down with control",
            "Keep feet flat on the floor for stability",
        ],
        "Goblet Squats": [
            "Hold a dumbbell vertically at chest level",
            "Stand with feet shoulder-width apart",
            "Squat down keeping chest up and knees tracking over toes",
            "Push through heels to return to standing",
        ],
        "Lat Pulldowns": [
            "Sit at the lat pulldown machine with thighs secured",
            "Grip the bar wider than shoulder-width",
            "Pull the bar down to upper chest while squeezing shoulder blades",
            "Control the weight back up, stretching lats fully",
        ],
    }

    return instructions_map.get(exercise_name, [
        "Perform the exercise with controlled movement",
        "Focus on proper form over speed",
        "Breathe out during exertion, in during recovery",
        "Rest as needed between sets",
    ])


def _get_preview_warmup(focus_muscles: List[str]) -> Dict[str, Any]:
    """Get a preview warmup based on focus muscles."""
    warmup_exercises = [
        {"name": "Jumping Jacks", "duration_seconds": 60, "type": "cardio"},
        {"name": "Arm Circles", "duration_seconds": 30, "type": "dynamic"},
        {"name": "Leg Swings", "duration_seconds": 30, "type": "dynamic"},
        {"name": "Hip Circles", "duration_seconds": 30, "type": "dynamic"},
    ]

    # Add muscle-specific warmups
    if "chest" in focus_muscles or "shoulders" in focus_muscles:
        warmup_exercises.append(
            {"name": "Band Pull-Aparts", "duration_seconds": 30, "type": "activation"}
        )
    if "quadriceps" in focus_muscles or "hamstrings" in focus_muscles:
        warmup_exercises.append(
            {"name": "Bodyweight Squats", "reps": 10, "type": "activation"}
        )

    return {
        "duration_minutes": 5,
        "exercises": warmup_exercises,
    }


def _get_preview_cooldown() -> Dict[str, Any]:
    """Get a preview cooldown routine."""
    return {
        "duration_minutes": 5,
        "exercises": [
            {"name": "Static Chest Stretch", "duration_seconds": 30},
            {"name": "Shoulder Stretch", "duration_seconds": 30},
            {"name": "Quad Stretch", "duration_seconds": 30},
            {"name": "Hamstring Stretch", "duration_seconds": 30},
            {"name": "Deep Breathing", "duration_seconds": 60},
        ],
    }


def _get_completion_motivation(completion_rate: float) -> str:
    """Get a motivational message based on completion rate."""
    if completion_rate >= 100:
        return "Perfect workout! You completed every exercise. You're already on your way to reaching your goals!"
    elif completion_rate >= 80:
        return "Great job! You pushed through and completed most of the workout. Consistency like this builds real results!"
    elif completion_rate >= 50:
        return "Good effort! Every rep counts, and showing up is half the battle. Keep building that habit!"
    else:
        return "You showed up and that's what matters! Starting is the hardest part. Let's build from here!"
