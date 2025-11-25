"""
LangChain tool definitions for workout modifications.

These tools are bound to the LLM and can be called automatically
based on user intent.
"""
from typing import List, Dict, Any
from datetime import datetime
from langchain_core.tools import tool
from services.workout_modifier import WorkoutModifier
from core.duckdb_database import get_db
from core.logger import get_logger

logger = get_logger(__name__)


@tool
def add_exercise_to_workout(
    workout_id: int,
    exercise_names: List[str],
    muscle_groups: List[str] = None
) -> Dict[str, Any]:
    """
    Add exercises to the user's current workout.

    Args:
        workout_id: The ID of the workout to modify
        exercise_names: List of exercise names to add (e.g., ["Push-ups", "Lunges"])
        muscle_groups: Optional list of target muscle groups

    Returns:
        Result dict with success status and message
    """
    logger.info(f"Tool: Adding exercises {exercise_names} to workout {workout_id}")
    modifier = WorkoutModifier()
    success = modifier.add_exercises_to_workout(
        workout_id=workout_id,
        exercise_names=exercise_names,
        muscle_groups=muscle_groups or []
    )
    return {
        "success": success,
        "action": "add_exercise",
        "workout_id": workout_id,
        "exercises_added": exercise_names,
        "message": f"Added {len(exercise_names)} exercises: {', '.join(exercise_names)}" if success else "Failed to add exercises"
    }


@tool
def remove_exercise_from_workout(
    workout_id: int,
    exercise_names: List[str]
) -> Dict[str, Any]:
    """
    Remove exercises from the user's current workout.

    Args:
        workout_id: The ID of the workout to modify
        exercise_names: List of exercise names to remove

    Returns:
        Result dict with success status and message
    """
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
def modify_workout_intensity(
    workout_id: int,
    modification: str
) -> Dict[str, Any]:
    """
    Modify the intensity of the user's workout.

    Args:
        workout_id: The ID of the workout to modify
        modification: Type of modification - "easier", "harder", "shorter", "longer"

    Returns:
        Result dict with success status and message
    """
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
    workout_id: int,
    new_date: str,
    reason: str = None
) -> Dict[str, Any]:
    """
    Move a workout to a different date. If another workout exists on the target date, they will be swapped.

    Args:
        workout_id: The ID of the workout to move
        new_date: New date in YYYY-MM-DD format (e.g., "2024-11-27")
        reason: Reason for rescheduling the workout

    Returns:
        Result dict with success status and message
    """
    logger.info(f"Tool: Rescheduling workout {workout_id} to {new_date}, reason: {reason}")

    try:
        db = get_db()

        # Get the workout being moved
        moved_workout = db.conn.execute(
            "SELECT id, user_id, name, scheduled_date FROM workouts WHERE id = ?",
            [workout_id]
        ).fetchone()

        if not moved_workout:
            return {
                "success": False,
                "action": "reschedule",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        old_date = moved_workout[3]
        user_id = moved_workout[1]
        workout_name = moved_workout[2]

        # Check for existing workout on new date
        existing = db.conn.execute(
            "SELECT id, name FROM workouts WHERE user_id = ? AND scheduled_date >= ? AND scheduled_date < ?",
            [user_id, new_date, new_date + " 23:59:59"]
        ).fetchone()

        swapped_with = None
        if existing:
            # Swap dates
            logger.info(f"Swapping: workout {existing[0]} ({existing[1]}) will move to {old_date}")
            db.conn.execute(
                "UPDATE workouts SET scheduled_date = ?, last_modified_at = ?, last_modified_method = 'ai_reschedule' WHERE id = ?",
                [old_date, datetime.now(), existing[0]]
            )
            swapped_with = {"id": existing[0], "name": existing[1]}

        # Update moved workout
        db.conn.execute(
            "UPDATE workouts SET scheduled_date = ?, last_modified_at = ?, last_modified_method = 'ai_reschedule' WHERE id = ?",
            [new_date, datetime.now(), workout_id]
        )

        # Log the change
        try:
            result = db.conn.execute("SELECT COALESCE(MAX(id), 0) + 1 FROM workout_changes").fetchone()
            change_id = result[0]
            db.conn.execute("""
                INSERT INTO workout_changes
                (id, workout_id, user_id, change_type, field_changed, old_value, new_value, change_source, change_reason)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                change_id,
                workout_id,
                user_id,
                "rescheduled",
                "scheduled_date",
                str(old_date),
                new_date,
                "ai_coach",
                reason or "Rescheduled via AI coach"
            ])
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


# Registry of all available tools
ALL_TOOLS = [
    add_exercise_to_workout,
    remove_exercise_from_workout,
    modify_workout_intensity,
    reschedule_workout,
]

# Tool name to function mapping
TOOLS_MAP = {tool.name: tool for tool in ALL_TOOLS}
