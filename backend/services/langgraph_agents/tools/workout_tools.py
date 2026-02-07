"""
Workout modification tools for LangGraph agents.

Contains tools for adding, removing, replacing exercises,
modifying intensity, rescheduling, and generating quick workouts.
"""

from typing import List, Dict, Any
from datetime import datetime, timezone
import json
import re

from langchain_core.tools import tool

_UUID_PATTERN = re.compile(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    re.IGNORECASE
)


def _validate_workout_id(workout_id: str) -> bool:
    """Validate that workout_id is a valid UUID string."""
    return bool(_UUID_PATTERN.match(str(workout_id)))

from services.workout_modifier import WorkoutModifier
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from .base import run_async_in_sync

logger = get_logger(__name__)


def _get_user_equipment_info(user: Dict) -> tuple:
    """Extract equipment info from user profile."""
    user_equipment = user.get("equipment", []) if user else ["Bodyweight"]
    user_fitness_level = user.get("fitness_level", "intermediate") if user else "intermediate"
    user_prefs = user.get("preferences", {}) if user else {}

    if isinstance(user_prefs, str):
        try:
            user_prefs = json.loads(user_prefs) if user_prefs else {}
        except json.JSONDecodeError:
            user_prefs = {}

    dumbbell_count = user_prefs.get("dumbbell_count", 2)
    kettlebell_count = user_prefs.get("kettlebell_count", 1)

    return user_equipment, user_fitness_level, dumbbell_count, kettlebell_count


def _parse_injuries(user_injuries: Any) -> List[str]:
    """Parse user injuries from various formats."""
    if isinstance(user_injuries, str):
        try:
            user_injuries = json.loads(user_injuries)
        except json.JSONDecodeError:
            user_injuries = []

    injury_body_parts = []
    if user_injuries:
        for inj in user_injuries:
            if isinstance(inj, dict):
                injury_body_parts.append(inj.get("body_part", ""))
            elif isinstance(inj, str):
                injury_body_parts.append(inj)

    return injury_body_parts


@tool
def add_exercise_to_workout(
    workout_id: str,
    exercise_names: List[str],
    muscle_groups: List[str] = None
) -> Dict[str, Any]:
    """
    Add exercises to the user's current workout using the Exercise Library from ChromaDB.

    Args:
        workout_id: The UUID of the workout to modify
        exercise_names: List of exercise names to add (e.g., ["Push-ups", "Lunges"])
        muscle_groups: Optional list of target muscle groups

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "add_exercise",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Adding exercises {exercise_names} to workout {workout_id} using RAG")

    try:
        db = get_supabase_db()

        # Get current workout
        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "add_exercise",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        # Get current exercises
        exercises_data = workout.get("exercises")
        if isinstance(exercises_data, str):
            exercises = json.loads(exercises_data) if exercises_data else []
        else:
            exercises = exercises_data or []

        # Get user profile for personalized exercise selection
        user_id = workout.get("user_id")
        user = db.get_user(user_id) if user_id else None
        user_equipment, user_fitness_level, dumbbell_count, kettlebell_count = _get_user_equipment_info(user)

        # Use Exercise RAG to find exercises from the library
        from services.exercise_rag_service import get_exercise_rag_service
        exercise_rag = get_exercise_rag_service()

        added_exercises = []
        for exercise_name in exercise_names:
            # Check if exercise already exists in workout
            if any(ex.get("name", "").lower() == exercise_name.lower() for ex in exercises):
                logger.info(f"Exercise already exists: {exercise_name}")
                continue

            # Search for exercise in ChromaDB
            try:
                rag_results = run_async_in_sync(
                    exercise_rag.select_exercises_for_workout(
                        focus_area=exercise_name,
                        equipment=user_equipment if user_equipment else ["Bodyweight"],
                        fitness_level=user_fitness_level,
                        goals=["General Fitness"],
                        count=1,
                        avoid_exercises=[ex.get("name", "") for ex in exercises],
                        injuries=None,
                        dumbbell_count=dumbbell_count,
                        kettlebell_count=kettlebell_count,
                    ),
                    timeout=15
                )

                if rag_results:
                    ex = rag_results[0]
                    new_exercise = {
                        "name": ex.get("name", exercise_name),
                        "sets": ex.get("sets", 3),
                        "reps": ex.get("reps", 12),
                        "rest_seconds": ex.get("rest_seconds", 60),
                        "equipment": ex.get("equipment", "Bodyweight"),
                        "muscle_group": ex.get("muscle_group", ex.get("body_part", "")),
                        "notes": ex.get("notes", ""),
                        "gif_url": ex.get("gif_url", ""),
                        "video_url": ex.get("video_url", ""),
                        "image_url": ex.get("image_url", ""),
                        "library_id": ex.get("library_id", ""),
                    }
                    exercises.append(new_exercise)
                    added_exercises.append(new_exercise["name"])
                    logger.info(f"Added exercise from library: {new_exercise['name']}")
                else:
                    logger.warning(f"Exercise not found in library: {exercise_name}")

            except Exception as search_error:
                logger.warning(f"Failed to search for exercise {exercise_name}: {search_error}")

        if not added_exercises:
            return {
                "success": False,
                "action": "add_exercise",
                "workout_id": workout_id,
                "message": "Could not find exercises in the Exercise Library. Try different exercise names."
            }

        # Update workout in database
        update_data = {
            "exercises": exercises,
            "last_modified_method": "ai_coach",
        }
        db.update_workout(workout_id, update_data)

        logger.info(f"Successfully added {len(added_exercises)} exercises to workout {workout_id}")

        return {
            "success": True,
            "action": "add_exercise",
            "workout_id": workout_id,
            "exercises_added": added_exercises,
            "message": f"Added {len(added_exercises)} exercises: {', '.join(added_exercises)}"
        }

    except Exception as e:
        logger.error(f"Failed to add exercises: {e}")
        return {
            "success": False,
            "action": "add_exercise",
            "workout_id": workout_id,
            "message": f"Failed to add exercises: {str(e)}"
        }


@tool
def remove_exercise_from_workout(
    workout_id: str,
    exercise_names: List[str]
) -> Dict[str, Any]:
    """
    Remove exercises from the user's current workout.

    Args:
        workout_id: The UUID of the workout to modify
        exercise_names: List of exercise names to remove

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "remove_exercise",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Removing exercises {exercise_names} from workout {workout_id}")
    modifier = WorkoutModifier()
    success = modifier.remove_exercises_from_workout(
        workout_id=workout_id,
        exercise_names=exercise_names
    )
    return {
        "success": success,
        "action": "remove_exercise",
        "workout_id": workout_id,
        "exercises_removed": exercise_names,
        "message": f"Removed exercises: {', '.join(exercise_names)}" if success else "Failed to remove exercises"
    }


@tool
def replace_all_exercises(
    workout_id: str,
    muscle_group: str,
    num_exercises: int = 5
) -> Dict[str, Any]:
    """
    Replace ALL exercises in a workout with new exercises targeting a specific muscle group.
    Uses the Exercise Library from ChromaDB for personalized exercise selection.

    Args:
        workout_id: The UUID of the workout to modify
        muscle_group: Target muscle group (e.g., "back", "chest", "legs")
        num_exercises: Number of new exercises to add (default 5)

    Returns:
        Result dict with success status, removed exercises, and new exercises
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Replacing all exercises in workout {workout_id} with {muscle_group} exercises")

    try:
        db = get_supabase_db()

        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        current_exercises = workout.get("exercises", [])
        old_exercise_names = [e.get("name", "Unknown") for e in current_exercises]

        # Get user profile
        user_id = workout.get("user_id")
        user = db.get_user(user_id) if user_id else None
        user_equipment, user_fitness_level, dumbbell_count, kettlebell_count = _get_user_equipment_info(user)
        user_goals = user.get("goals", []) if user else []
        user_injuries = user.get("active_injuries", []) if user else []
        injury_body_parts = _parse_injuries(user_injuries)

        # Map muscle group to focus area
        focus_area_map = {
            "back": "back", "chest": "chest", "legs": "legs",
            "shoulders": "shoulders", "arms": "arms", "core": "core",
            "glutes": "legs", "biceps": "arms", "triceps": "arms",
            "quads": "legs", "hamstrings": "legs", "calves": "legs", "abs": "core",
        }
        focus_area = focus_area_map.get(muscle_group.lower(), muscle_group.lower())

        # Use Exercise RAG
        from services.exercise_rag_service import get_exercise_rag_service
        exercise_rag = get_exercise_rag_service()

        rag_exercises = run_async_in_sync(
            exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=user_equipment if user_equipment else ["Bodyweight"],
                fitness_level=user_fitness_level,
                goals=user_goals if user_goals else ["General Fitness"],
                count=num_exercises,
                avoid_exercises=old_exercise_names,
                injuries=injury_body_parts if injury_body_parts else None,
                dumbbell_count=dumbbell_count,
                kettlebell_count=kettlebell_count,
            ),
            timeout=30
        )

        if not rag_exercises:
            return {
                "success": False,
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "message": f"Could not find exercises for {muscle_group}."
            }

        new_exercises = []
        for ex in rag_exercises:
            new_exercises.append({
                "name": ex.get("name", "Exercise"),
                "sets": ex.get("sets", 3),
                "reps": ex.get("reps", 12),
                "duration_seconds": ex.get("duration_seconds"),
                "muscle_group": muscle_group.lower(),
                "equipment": ex.get("equipment", "Bodyweight"),
                "notes": ex.get("notes", ""),
                "gif_url": ex.get("gif_url", ""),
                "video_url": ex.get("video_url", ""),
                "image_url": ex.get("image_url", ""),
                "library_id": ex.get("library_id", ""),
            })

        update_data = {
            "exercises": new_exercises,
            "name": f"{muscle_group.title()} Workout",
            "last_modified_method": "ai_replace_all"
        }
        db.update_workout(workout_id, update_data)

        new_exercise_names = [e["name"] for e in new_exercises]
        logger.info(f"Replaced {len(old_exercise_names)} exercises with {len(new_exercises)} {muscle_group} exercises")

        return {
            "success": True,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "exercises_removed": old_exercise_names,
            "exercises_added": new_exercise_names,
            "muscle_group": muscle_group,
            "message": f"Replaced all exercises with {len(new_exercises)} {muscle_group} exercises"
        }

    except Exception as e:
        logger.error(f"Error replacing exercises: {e}")
        return {
            "success": False,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "message": f"Failed to replace exercises: {str(e)}"
        }


@tool
def modify_workout_intensity(
    workout_id: str,
    modification: str
) -> Dict[str, Any]:
    """
    Modify the intensity of the user's workout.

    Args:
        workout_id: The UUID of the workout to modify
        modification: Type of modification - "easier", "harder", "shorter", "longer"

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "modify_intensity",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Modifying intensity for workout {workout_id}: {modification}")
    modifier = WorkoutModifier()
    success = modifier.modify_workout_intensity(
        workout_id=workout_id,
        modification=modification
    )
    return {
        "success": success,
        "action": "modify_intensity",
        "workout_id": workout_id,
        "modification": modification,
        "message": f"Workout intensity modified: {modification}" if success else "Failed to modify intensity"
    }


@tool
def reschedule_workout(
    workout_id: str,
    new_date: str,
    reason: str = None
) -> Dict[str, Any]:
    """
    Move a workout to a different date. If another workout exists on the target date, they will be swapped.

    Args:
        workout_id: The UUID of the workout to move
        new_date: New date in YYYY-MM-DD format
        reason: Reason for rescheduling

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "reschedule",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Rescheduling workout {workout_id} to {new_date}")

    try:
        db = get_supabase_db()

        moved_workout = db.get_workout(workout_id)
        if not moved_workout:
            return {
                "success": False,
                "action": "reschedule",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        old_date = moved_workout.get("scheduled_date")
        user_id = moved_workout.get("user_id")
        workout_name = moved_workout.get("name")

        # Check for existing workout on new date
        workouts_on_date = db.get_workouts_by_date_range(user_id, new_date, new_date)

        swapped_with = None
        if workouts_on_date:
            existing = workouts_on_date[0]
            logger.info(f"Swapping: workout {existing['id']} will move to {old_date}")
            db.update_workout(existing['id'], {
                "scheduled_date": str(old_date),
                "last_modified_method": "ai_reschedule"
            })
            swapped_with = {"id": existing['id'], "name": existing['name']}

        db.update_workout(workout_id, {
            "scheduled_date": new_date,
            "last_modified_method": "ai_reschedule"
        })

        try:
            db.create_workout_change({
                "workout_id": workout_id,
                "user_id": user_id,
                "change_type": "rescheduled",
                "field_changed": "scheduled_date",
                "old_value": str(old_date),
                "new_value": new_date,
                "change_source": "ai_coach",
                "change_reason": reason or "Rescheduled via AI coach"
            })
        except Exception as log_error:
            logger.warning(f"Failed to log workout change: {log_error}")

        if swapped_with:
            message = f"Moved '{workout_name}' to {new_date} and swapped with '{swapped_with['name']}'"
        else:
            message = f"Moved '{workout_name}' from {old_date} to {new_date}"

        return {
            "success": True,
            "action": "reschedule",
            "workout_id": workout_id,
            "workout_name": workout_name,
            "old_date": str(old_date),
            "new_date": new_date,
            "swapped_with": swapped_with,
            "message": message
        }

    except Exception as e:
        logger.error(f"Reschedule failed: {e}")
        return {
            "success": False,
            "action": "reschedule",
            "workout_id": workout_id,
            "message": f"Failed to reschedule: {str(e)}"
        }


@tool
def delete_workout(
    workout_id: str,
    reason: str = None
) -> Dict[str, Any]:
    """
    Delete/cancel a workout from the user's schedule.

    Args:
        workout_id: The UUID of the workout to delete
        reason: Optional reason for deletion

    Returns:
        Result dict with success status and workout details
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "delete_workout",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Deleting workout {workout_id}")

    try:
        db = get_supabase_db()

        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "delete_workout",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        workout_name = workout.get("name")
        scheduled_date = workout.get("scheduled_date")
        workout_type = workout.get("type")
        user_id = workout.get("user_id")

        # Delete related records
        db.delete_performance_logs_by_workout_log(workout_id)
        db.delete_workout_logs_by_workout(workout_id)
        db.delete_workout_changes_by_workout(workout_id)
        db.delete_workout(workout_id)

        try:
            db.create_workout_change({
                "workout_id": workout_id,
                "user_id": user_id,
                "change_type": "deleted",
                "field_changed": "workout",
                "old_value": workout_name,
                "new_value": None,
                "change_source": "ai_coach",
                "change_reason": reason or "Deleted via AI coach"
            })
        except Exception as log_error:
            logger.warning(f"Failed to log workout deletion: {log_error}")

        return {
            "success": True,
            "action": "delete_workout",
            "workout_id": workout_id,
            "workout_name": workout_name,
            "scheduled_date": str(scheduled_date),
            "workout_type": workout_type,
            "reason": reason,
            "message": f"Successfully deleted '{workout_name}' scheduled for {scheduled_date}"
        }

    except Exception as e:
        logger.error(f"Delete workout failed: {e}")
        return {
            "success": False,
            "action": "delete_workout",
            "workout_id": workout_id,
            "message": f"Failed to delete workout: {str(e)}"
        }


@tool
def generate_quick_workout(
    user_id: str,
    workout_id: str = None,
    duration_minutes: int = 15,
    workout_type: str = "full_body",
    intensity: str = "moderate"
) -> Dict[str, Any]:
    """
    Generate a quick workout for the user using the Exercise Library.

    Args:
        user_id: The user's ID (required)
        workout_id: Optional ID of workout to replace
        duration_minutes: Target duration in minutes (default 15, max 30)
        workout_type: Type of workout (full_body, upper, lower, cardio, core, boxing, etc.)
        intensity: Workout intensity - "light", "moderate", "intense"

    Returns:
        Result dict with the new quick workout details
    """
    logger.info(f"Tool: Generating quick {duration_minutes}min {workout_type} workout for user {user_id}")

    try:
        db = get_supabase_db()

        old_exercise_names = []
        workout = None
        is_new_workout = False

        # Try to get existing workout
        if workout_id:
            workout = db.get_workout(workout_id)
            if workout:
                old_exercises = workout.get("exercises", [])
                old_exercise_names = [e.get("name", "Unknown") for e in old_exercises]

        # If no workout found, check for existing incomplete workout for today
        if not workout:
            today_utc = datetime.now(timezone.utc).date().isoformat()
            existing_today = db.client.table("workouts").select("*").eq(
                "user_id", user_id
            ).eq("is_completed", False).eq("is_current", True).gte(
                "scheduled_date", today_utc
            ).lte("scheduled_date", today_utc + "T23:59:59Z").order(
                "created_at", desc=True
            ).limit(1).execute()

            if existing_today.data:
                workout = existing_today.data[0]
                workout_id = workout.get("id")
                old_exercises = workout.get("exercises_json", []) or workout.get("exercises", [])
                old_exercise_names = [e.get("name", "Unknown") for e in old_exercises] if old_exercises else []
            else:
                is_new_workout = True

        # Get user profile
        user = db.get_user(user_id) if user_id else None
        user_equipment, user_fitness_level, dumbbell_count, kettlebell_count = _get_user_equipment_info(user)
        user_goals = user.get("goals", []) if user else []
        user_injuries = user.get("active_injuries", []) if user else []
        injury_body_parts = _parse_injuries(user_injuries)

        # Map workout type to focus area
        focus_area_map = {
            "full_body": "full_body", "upper": "chest", "lower": "legs",
            "cardio": "full_body_power", "core": "core",
            "boxing": "boxing", "hyrox": "hyrox", "crossfit": "crossfit",
            "martial_arts": "martial_arts", "hiit": "hiit",
            "strength": "strength", "endurance": "endurance",
            "flexibility": "flexibility", "mobility": "mobility",
            "cricket": "cricket", "football": "football",
            "basketball": "basketball", "tennis": "tennis",
            "chest": "chest", "back": "back", "shoulders": "shoulders",
            "arms": "arms", "legs": "legs", "glutes": "legs",
        }

        workout_type_key = workout_type.lower().replace(" ", "_").replace("-", "_")
        if workout_type_key not in focus_area_map:
            workout_type_key = "full_body"
        focus_area = focus_area_map[workout_type_key]

        # Determine exercise count based on duration
        if duration_minutes <= 10:
            exercise_count = 3
        elif duration_minutes <= 15:
            exercise_count = 4
        elif duration_minutes <= 20:
            exercise_count = 5
        else:
            exercise_count = 6

        intensity_key = intensity.lower()
        if intensity_key not in ["light", "moderate", "intense"]:
            intensity_key = "moderate"

        # Map intensity to suggested fitness level
        intensity_to_fitness = {
            "light": "beginner",
            "moderate": "intermediate",
            "intense": "advanced",
        }
        suggested_fitness_level = intensity_to_fitness.get(intensity_key, "intermediate")

        # CRITICAL: Enforce fitness level ceiling - user cannot request exercises
        # above their actual fitness level. This prevents beginners from getting
        # advanced exercises just because they selected "intense" workout.
        FITNESS_LEVEL_ORDER = {"beginner": 1, "intermediate": 2, "advanced": 3}
        user_level_rank = FITNESS_LEVEL_ORDER.get(user_fitness_level.lower(), 2)
        suggested_level_rank = FITNESS_LEVEL_ORDER.get(suggested_fitness_level, 2)

        if suggested_level_rank > user_level_rank:
            logger.warning(
                f"[Quick Workout] User {user_fitness_level} requested {intensity_key} intensity. "
                f"Capping exercise selection at user's level to prevent inappropriate exercises."
            )
            rag_fitness_level = user_fitness_level
        else:
            rag_fitness_level = suggested_fitness_level

        logger.info(f"[Quick Workout] Intensity={intensity_key}, user_level={user_fitness_level}, rag_level={rag_fitness_level}")

        # Use Exercise RAG
        from services.exercise_rag_service import get_exercise_rag_service
        exercise_rag = get_exercise_rag_service()

        try:
            rag_exercises = run_async_in_sync(
                exercise_rag.select_exercises_for_workout(
                    focus_area=focus_area,
                    equipment=user_equipment if user_equipment else ["Bodyweight"],
                    fitness_level=rag_fitness_level,
                    goals=user_goals if user_goals else ["General Fitness"],
                    count=exercise_count,
                    avoid_exercises=old_exercise_names,
                    injuries=injury_body_parts if injury_body_parts else None,
                    dumbbell_count=dumbbell_count,
                    kettlebell_count=kettlebell_count,
                ),
                timeout=30
            )
        except Exception as rag_error:
            logger.error(f"Exercise RAG failed: {rag_error}")
            return {
                "success": False,
                "action": "generate_quick_workout",
                "workout_id": workout_id,
                "message": f"Could not generate workout: {str(rag_error)}"
            }

        if not rag_exercises:
            return {
                "success": False,
                "action": "generate_quick_workout",
                "workout_id": workout_id,
                "message": f"Could not find exercises for {workout_type} workout."
            }

        # Get adaptive parameters
        from services.adaptive_workout_service import get_adaptive_workout_service
        adaptive_service = get_adaptive_workout_service(db.client)

        intensity_to_focus = {
            "light": "endurance",
            "moderate": "hypertrophy",
            "intense": "strength",
        }
        workout_focus = intensity_to_focus.get(intensity_key, "hypertrophy")

        try:
            adaptive_params = run_async_in_sync(
                adaptive_service.get_adaptive_parameters(
                    user_id=user_id,
                    workout_type=workout_focus,
                    user_goals=user_goals,
                ),
                timeout=5
            )
        except Exception:
            adaptive_params = {"sets": 3, "reps": 12, "rest_seconds": 60}

        new_exercises = []
        for ex in rag_exercises:
            exercise_type = "compound" if any(
                compound in ex.get("name", "").lower()
                for compound in ["squat", "deadlift", "bench", "press", "row", "pull-up", "push-up"]
            ) else "isolation"
            rest_time = adaptive_service.get_varied_rest_time(exercise_type, workout_focus)

            new_exercises.append({
                "name": ex.get("name", "Exercise"),
                "sets": adaptive_params["sets"],
                "reps": ex.get("reps", adaptive_params["reps"]),
                "rest_seconds": rest_time,
                "duration_seconds": ex.get("duration_seconds"),
                "muscle_group": ex.get("muscle_group", ex.get("body_part", workout_type_key)),
                "equipment": ex.get("equipment", "Bodyweight"),
                "notes": ex.get("notes", ""),
                "gif_url": ex.get("gif_url", ""),
                "video_url": ex.get("video_url", ""),
                "image_url": ex.get("image_url", ""),
                "library_id": ex.get("library_id", ""),
            })

        # Apply supersets if appropriate
        if adaptive_service.should_use_supersets(workout_focus, duration_minutes, len(new_exercises)):
            new_exercises = adaptive_service.create_superset_pairs(new_exercises)

        # Add AMRAP finisher if appropriate
        if adaptive_service.should_include_amrap(workout_focus, rag_fitness_level):
            amrap_exercise = adaptive_service.create_amrap_finisher(new_exercises, workout_focus)
            new_exercises.append(amrap_exercise)

        # Generate workout name
        intensity_names = {"light": "Easy", "moderate": "Power", "intense": "Intense"}
        type_names = {
            "full_body": "Full Body", "upper": "Upper Body", "lower": "Lower Body",
            "cardio": "Cardio", "core": "Core", "boxing": "Boxing",
            "hyrox": "HYROX", "crossfit": "CrossFit", "hiit": "HIIT",
            "chest": "Chest", "back": "Back", "shoulders": "Shoulders",
            "arms": "Arms", "legs": "Legs",
        }
        workout_name = f"Quick {intensity_names.get(intensity_key, 'Power')} {type_names.get(workout_type_key, workout_type_key.replace('_', ' ').title())}"

        new_exercise_names = [e["name"] for e in new_exercises]
        final_workout_id = workout_id

        if is_new_workout:
            today_utc = datetime.now(timezone.utc).date().isoformat()
            new_workout_data = {
                "user_id": user_id,
                "name": workout_name,
                "type": workout_type_key.replace("_", " "),
                "difficulty": intensity_key,
                "scheduled_date": today_utc,
                "exercises_json": new_exercises,
                "duration_minutes": min(duration_minutes, 30),
                "is_completed": False,
                "generation_method": "ai_quick_workout",
                "generation_source": "chat",
            }
            created_workout = db.create_workout(new_workout_data)
            if created_workout:
                final_workout_id = created_workout.get("id")
            else:
                return {
                    "success": False,
                    "action": "generate_quick_workout",
                    "message": "Failed to create new workout"
                }
        else:
            update_data = {
                "exercises_json": new_exercises,
                "name": workout_name,
                "duration_minutes": min(duration_minutes, 30),
                "difficulty": intensity_key,
                "type": workout_type_key.replace("_", " "),
                "generation_method": "ai_quick_workout"
            }
            db.update_workout(workout_id, update_data)
            final_workout_id = workout_id

        return {
            "success": True,
            "action": "generate_quick_workout",
            "workout_id": final_workout_id,
            "workout_name": workout_name,
            "duration_minutes": min(duration_minutes, 30),
            "workout_type": workout_type_key,
            "intensity": intensity_key,
            "exercises_removed": old_exercise_names,
            "exercises_added": new_exercise_names,
            "exercise_count": len(new_exercises),
            "is_new_workout": is_new_workout,
            "message": f"{'Created' if is_new_workout else 'Updated'} '{workout_name}' - {len(new_exercises)} exercises"
        }

    except Exception as e:
        logger.error(f"Generate quick workout failed: {e}")
        return {
            "success": False,
            "action": "generate_quick_workout",
            "workout_id": workout_id,
            "message": f"Failed to generate quick workout: {str(e)}"
        }
