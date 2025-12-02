"""
LangChain tool definitions for workout modifications, injury management,
and food image analysis.

These tools are bound to the LLM and can be called automatically
based on user intent.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import json
import asyncio
from langchain_core.tools import tool
from services.workout_modifier import WorkoutModifier
from services.injury_service import get_injury_service, Injury
from services.vision_service import VisionService
from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Singleton vision service
_vision_service: Optional[VisionService] = None


def get_vision_service() -> VisionService:
    """Get or create the vision service singleton."""
    global _vision_service
    if _vision_service is None:
        _vision_service = VisionService()
    return _vision_service


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
        db = get_supabase_db()

        # Get the workout being moved
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
            # Swap dates
            logger.info(f"Swapping: workout {existing['id']} ({existing['name']}) will move to {old_date}")
            db.update_workout(existing['id'], {
                "scheduled_date": str(old_date),
                "last_modified_method": "ai_reschedule"
            })
            swapped_with = {"id": existing['id'], "name": existing['name']}

        # Update moved workout
        db.update_workout(workout_id, {
            "scheduled_date": new_date,
            "last_modified_method": "ai_reschedule"
        })

        # Log the change
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
def report_injury(
    user_id: int,
    body_part: str,
    severity: str = "moderate",
    duration_weeks: int = None,
    pain_level: int = None,
    notes: str = None
) -> Dict[str, Any]:
    """
    Report a new injury for the user. This will:
    1. Record the injury in the database
    2. Modify upcoming workouts to remove exercises that affect the injured area
    3. Add appropriate rehab exercises based on recovery phase

    Args:
        user_id: The user's ID
        body_part: The injured body part (e.g., "back", "shoulder", "knee", "hip", "ankle", "wrist", "elbow", "neck")
        severity: Injury severity - "mild" (2 weeks), "moderate" (3 weeks), or "severe" (5 weeks). Default is "moderate"
        duration_weeks: Optional custom recovery duration in weeks (overrides severity-based duration)
        pain_level: Optional pain level from 1-10
        notes: Optional notes about the injury

    Returns:
        Result dict with injury details, modified workouts, and rehab exercises
    """
    logger.info(f"Tool: Reporting injury for user {user_id}: {body_part} ({severity})")

    try:
        db = get_supabase_db()
        injury_service = get_injury_service()

        # Determine recovery duration
        if duration_weeks:
            recovery_weeks = duration_weeks
        else:
            recovery_weeks = injury_service.get_duration_for_severity(severity)

        # Calculate expected recovery date
        reported_at = datetime.now()
        expected_recovery_date = reported_at + timedelta(weeks=recovery_weeks)

        # Create injury record in injury_history table
        injury_data = {
            "user_id": user_id,
            "body_part": body_part.lower(),
            "severity": severity.lower(),
            "reported_at": reported_at.isoformat(),
            "expected_recovery_date": expected_recovery_date.isoformat(),
            "duration_planned_weeks": recovery_weeks,
            "pain_level_initial": pain_level,
            "pain_level_current": pain_level,
            "improvement_notes": notes,
            "is_active": True
        }

        created_injury = db.create_injury_history(injury_data)
        injury_id = created_injury.get("id")

        # Create Injury object for service operations
        injury = Injury(
            id=injury_id,
            user_id=user_id,
            body_part=body_part.lower(),
            severity=severity.lower(),
            reported_at=reported_at,
            expected_recovery_date=expected_recovery_date,
            pain_level=pain_level,
            notes=notes
        )

        # Get recovery info
        recovery_summary = injury_service.get_recovery_summary(injury)
        rehab_exercises = injury_service.get_rehab_exercises(injury)
        contraindicated = injury_service.get_contraindicated_exercises(body_part)

        # Modify upcoming workouts for this user
        workouts_modified = 0
        exercises_removed_total = []

        # Get upcoming workouts for the next recovery period
        upcoming_workouts = db.get_workouts_by_date_range(
            user_id,
            reported_at.strftime("%Y-%m-%d"),
            expected_recovery_date.strftime("%Y-%m-%d")
        )

        for workout in upcoming_workouts:
            if workout.get("is_completed"):
                continue

            workout_id = workout.get("id")
            exercises_data = workout.get("exercises")
            workout_name = workout.get("name")

            # Handle exercises (could be string or list)
            if isinstance(exercises_data, str):
                try:
                    exercises = json.loads(exercises_data) if exercises_data else []
                except json.JSONDecodeError:
                    exercises = []
            else:
                exercises = exercises_data or []

            # Filter exercises for this injury
            safe_exercises, removed = injury_service.filter_workout_for_injuries(exercises, [injury])

            if removed:
                exercises_removed_total.extend([ex.get("name", "Unknown") for ex in removed])

                # Add rehab exercises to the workout
                updated_exercises = injury_service.add_rehab_exercises_to_workout(safe_exercises, [injury])

                # Update workout in database
                db.update_workout(workout_id, {
                    "exercises": updated_exercises,
                    "last_modified_method": "injury_modification"
                })

                workouts_modified += 1

                # Log the modification
                try:
                    db.create_workout_change({
                        "workout_id": workout_id,
                        "user_id": user_id,
                        "change_type": "injury_modification",
                        "field_changed": "exercises",
                        "old_value": json.dumps(exercises) if isinstance(exercises, list) else exercises_data,
                        "new_value": json.dumps(updated_exercises),
                        "change_source": "injury_report",
                        "change_reason": f"{body_part} injury ({severity})"
                    })
                except Exception as log_error:
                    logger.warning(f"Failed to log workout change: {log_error}")

        # Update user's active injuries list
        try:
            user = db.get_user(user_id)
            if user:
                current_injuries = user.get("active_injuries") or []
                if isinstance(current_injuries, str):
                    try:
                        current_injuries = json.loads(current_injuries)
                    except json.JSONDecodeError:
                        current_injuries = []

                current_injuries.append({
                    "id": injury_id,
                    "body_part": body_part.lower(),
                    "severity": severity.lower(),
                    "reported_at": reported_at.isoformat(),
                    "expected_recovery_date": expected_recovery_date.isoformat()
                })

                db.update_user(user_id, {"active_injuries": current_injuries})
        except Exception as user_update_error:
            logger.warning(f"Failed to update user active injuries: {user_update_error}")

        return {
            "success": True,
            "action": "report_injury",
            "injury_id": injury_id,
            "user_id": user_id,
            "body_part": body_part,
            "severity": severity,
            "recovery_weeks": recovery_weeks,
            "expected_recovery_date": expected_recovery_date.strftime("%Y-%m-%d"),
            "current_phase": recovery_summary["current_phase"],
            "phase_description": recovery_summary["phase_description"],
            "workouts_modified": workouts_modified,
            "exercises_removed": list(set(exercises_removed_total)),
            "rehab_exercises": [ex.get("name") for ex in rehab_exercises],
            "exercises_to_avoid": contraindicated[:10],  # Top 10
            "message": f"Recorded {severity} {body_part} injury. Modified {workouts_modified} upcoming workouts. "
                       f"Recovery expected in {recovery_weeks} weeks ({expected_recovery_date.strftime('%B %d, %Y')}). "
                       f"Added {len(rehab_exercises)} rehab exercises."
        }

    except Exception as e:
        logger.error(f"Report injury failed: {e}")
        return {
            "success": False,
            "action": "report_injury",
            "user_id": user_id,
            "body_part": body_part,
            "message": f"Failed to report injury: {str(e)}"
        }


@tool
def clear_injury(
    user_id: int,
    body_part: str = None,
    injury_id: int = None,
    user_feedback: str = None
) -> Dict[str, Any]:
    """
    Clear/resolve an injury for the user. The user can do this when they feel recovered.
    This will restore full exercise capability for the affected body part.

    Args:
        user_id: The user's ID
        body_part: The body part to clear (e.g., "back", "shoulder"). Use this OR injury_id
        injury_id: Specific injury ID to clear. Use this OR body_part
        user_feedback: Optional feedback about the recovery (e.g., "feeling much better", "pain is gone")

    Returns:
        Result dict with cleared injury details
    """
    logger.info(f"Tool: Clearing injury for user {user_id}: body_part={body_part}, injury_id={injury_id}")

    try:
        db = get_supabase_db()

        # Find the injury to clear
        active_injuries = db.get_active_injuries(user_id)

        injury_record = None
        if injury_id:
            for inj in active_injuries:
                if inj.get("id") == injury_id:
                    injury_record = inj
                    break
        elif body_part:
            for inj in active_injuries:
                if inj.get("body_part") == body_part.lower():
                    injury_record = inj
                    break
        else:
            return {
                "success": False,
                "action": "clear_injury",
                "user_id": user_id,
                "message": "Please specify either body_part or injury_id to clear"
            }

        if not injury_record:
            return {
                "success": False,
                "action": "clear_injury",
                "user_id": user_id,
                "message": f"No active injury found for {'injury ID ' + str(injury_id) if injury_id else body_part}"
            }

        injury_id = injury_record.get("id")
        cleared_body_part = injury_record.get("body_part")
        severity = injury_record.get("severity")
        reported_at = injury_record.get("reported_at")
        planned_weeks = injury_record.get("duration_planned_weeks")

        # Calculate actual duration
        actual_recovery_date = datetime.now()
        if isinstance(reported_at, str):
            reported_at = datetime.fromisoformat(reported_at.replace("Z", "+00:00"))
        actual_days = (actual_recovery_date - reported_at).days

        # Determine if early or late recovery
        recovery_status = "on_time"
        if planned_weeks:
            if actual_days < (planned_weeks * 7 * 0.7):  # More than 30% early
                recovery_status = "early"
            elif actual_days > (planned_weeks * 7 * 1.3):  # More than 30% late
                recovery_status = "late"

        # Update injury record as healed
        # Note: We'll need to use raw client since we need specific fields
        db.client.table("injury_history").update({
            "is_active": False,
            "actual_recovery_date": actual_recovery_date.isoformat(),
            "duration_actual_days": actual_days,
            "recovery_phase": "healed",
            "user_feedback": user_feedback
        }).eq("id", injury_id).execute()

        # Remove from user's active injuries
        try:
            user = db.get_user(user_id)
            if user:
                current_injuries = user.get("active_injuries") or []
                if isinstance(current_injuries, str):
                    try:
                        current_injuries = json.loads(current_injuries)
                    except json.JSONDecodeError:
                        current_injuries = []

                # Remove the cleared injury
                updated_injuries = [
                    inj for inj in current_injuries
                    if inj.get("id") != injury_id and inj.get("body_part") != cleared_body_part
                ]
                db.update_user(user_id, {"active_injuries": updated_injuries})
        except Exception as user_update_error:
            logger.warning(f"Failed to update user active injuries: {user_update_error}")

        return {
            "success": True,
            "action": "clear_injury",
            "injury_id": injury_id,
            "user_id": user_id,
            "body_part": cleared_body_part,
            "severity": severity,
            "recovery_duration_days": actual_days,
            "planned_duration_weeks": planned_weeks,
            "recovery_status": recovery_status,
            "message": f"Cleared {cleared_body_part} injury. You were injured for {actual_days} days "
                       f"(planned: {planned_weeks} weeks). Recovery status: {recovery_status}. "
                       f"Full exercise capability restored for {cleared_body_part}!"
        }

    except Exception as e:
        logger.error(f"Clear injury failed: {e}")
        return {
            "success": False,
            "action": "clear_injury",
            "user_id": user_id,
            "message": f"Failed to clear injury: {str(e)}"
        }


@tool
def get_active_injuries(user_id: int) -> Dict[str, Any]:
    """
    Get all active injuries for a user with their current recovery status.

    Args:
        user_id: The user's ID

    Returns:
        Result dict with list of active injuries and their recovery progress
    """
    logger.info(f"Tool: Getting active injuries for user {user_id}")

    try:
        db = get_supabase_db()
        injury_service = get_injury_service()

        injuries = db.get_active_injuries(user_id)

        if not injuries:
            return {
                "success": True,
                "action": "get_active_injuries",
                "user_id": user_id,
                "injuries": [],
                "count": 0,
                "message": "No active injuries found. You're all clear!"
            }

        active_injuries = []
        for inj in injuries:
            injury_id = inj.get("id")
            body_part = inj.get("body_part")
            severity = inj.get("severity")
            reported_at = inj.get("reported_at")
            expected_recovery = inj.get("expected_recovery_date")
            planned_weeks = inj.get("duration_planned_weeks")
            pain_level = inj.get("pain_level_current")
            notes = inj.get("improvement_notes")

            # Parse dates
            if isinstance(reported_at, str):
                reported_at = datetime.fromisoformat(reported_at.replace("Z", "+00:00"))
            if isinstance(expected_recovery, str):
                expected_recovery = datetime.fromisoformat(expected_recovery.replace("Z", "+00:00"))

            # Create Injury object to get current phase
            injury = Injury(
                id=injury_id,
                user_id=user_id,
                body_part=body_part,
                severity=severity,
                reported_at=reported_at,
                expected_recovery_date=expected_recovery,
                pain_level=pain_level,
                notes=notes
            )

            recovery_summary = injury_service.get_recovery_summary(injury)
            rehab_exercises = injury_service.get_rehab_exercises(injury)

            active_injuries.append({
                "injury_id": injury_id,
                "body_part": body_part,
                "severity": severity,
                "days_since_injury": recovery_summary["days_since_injury"],
                "days_remaining": recovery_summary["days_remaining"],
                "current_phase": recovery_summary["current_phase"],
                "phase_description": recovery_summary["phase_description"],
                "allowed_intensity": recovery_summary["allowed_intensity"],
                "expected_recovery_date": recovery_summary["expected_recovery_date"],
                "progress_percent": recovery_summary["progress_percent"],
                "pain_level": pain_level,
                "rehab_exercises": [ex.get("name") for ex in rehab_exercises[:3]]  # Top 3
            })

        return {
            "success": True,
            "action": "get_active_injuries",
            "user_id": user_id,
            "injuries": active_injuries,
            "count": len(active_injuries),
            "message": f"Found {len(active_injuries)} active injury/injuries."
        }

    except Exception as e:
        logger.error(f"Get active injuries failed: {e}")
        return {
            "success": False,
            "action": "get_active_injuries",
            "user_id": user_id,
            "injuries": [],
            "message": f"Failed to get injuries: {str(e)}"
        }


@tool
def update_injury_status(
    user_id: int,
    injury_id: int = None,
    body_part: str = None,
    pain_level: int = None,
    improvement_notes: str = None
) -> Dict[str, Any]:
    """
    Update the status of an active injury (e.g., update pain level or add notes).
    Useful for tracking recovery progress.

    Args:
        user_id: The user's ID
        injury_id: Specific injury ID to update (use this OR body_part)
        body_part: Body part to update (use this OR injury_id)
        pain_level: New pain level (1-10)
        improvement_notes: Notes about improvement or current status

    Returns:
        Result dict with updated injury status
    """
    logger.info(f"Tool: Updating injury status for user {user_id}")

    try:
        db = get_supabase_db()

        # Find the injury
        active_injuries = db.get_active_injuries(user_id)

        injury_record = None
        if injury_id:
            for inj in active_injuries:
                if inj.get("id") == injury_id:
                    injury_record = inj
                    break
        elif body_part:
            for inj in active_injuries:
                if inj.get("body_part") == body_part.lower():
                    injury_record = inj
                    break
        else:
            return {
                "success": False,
                "action": "update_injury_status",
                "message": "Please specify either body_part or injury_id to update"
            }

        if not injury_record:
            return {
                "success": False,
                "action": "update_injury_status",
                "message": f"No active injury found"
            }

        injury_id = injury_record.get("id")
        current_body_part = injury_record.get("body_part")
        old_pain = injury_record.get("pain_level_current")
        old_notes = injury_record.get("improvement_notes")

        # Build update data
        update_data = {}

        if pain_level is not None:
            update_data["pain_level_current"] = pain_level

        if improvement_notes:
            # Append to existing notes
            new_notes = f"{old_notes or ''}\n[{datetime.now().strftime('%Y-%m-%d')}] {improvement_notes}".strip()
            update_data["improvement_notes"] = new_notes

        if not update_data:
            return {
                "success": False,
                "action": "update_injury_status",
                "message": "No updates provided. Specify pain_level or improvement_notes."
            }

        # Update using raw client
        db.client.table("injury_history").update(update_data).eq("id", injury_id).execute()

        pain_change = ""
        if pain_level is not None and old_pain is not None:
            if pain_level < old_pain:
                pain_change = f" Pain improved from {old_pain} to {pain_level}!"
            elif pain_level > old_pain:
                pain_change = f" Pain increased from {old_pain} to {pain_level}."

        return {
            "success": True,
            "action": "update_injury_status",
            "injury_id": injury_id,
            "body_part": current_body_part,
            "pain_level": pain_level,
            "notes_added": improvement_notes,
            "message": f"Updated {current_body_part} injury status.{pain_change}"
        }

    except Exception as e:
        logger.error(f"Update injury status failed: {e}")
        return {
            "success": False,
            "action": "update_injury_status",
            "message": f"Failed to update injury: {str(e)}"
        }


@tool
def delete_workout(
    workout_id: int,
    reason: str = None
) -> Dict[str, Any]:
    """
    Delete/cancel a workout from the user's schedule.
    This permanently removes the workout and all associated data.

    Args:
        workout_id: The ID of the workout to delete
        reason: Optional reason for deletion (e.g., "not feeling well", "rest day needed")

    Returns:
        Result dict with success status and workout details
    """
    logger.info(f"Tool: Deleting workout {workout_id}, reason: {reason}")

    try:
        db = get_supabase_db()

        # Get workout details before deletion
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

        # Delete related records first (cascade manually)
        # Delete performance logs for workout logs of this workout
        db.delete_performance_logs_by_workout_log(workout_id)

        # Delete workout logs
        db.delete_workout_logs_by_workout(workout_id)

        # Delete workout changes
        db.delete_workout_changes_by_workout(workout_id)

        # Delete the workout itself
        db.delete_workout(workout_id)

        # Log the deletion as a change
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
def analyze_food_image(
    user_id: str,
    image_base64: str,
    user_message: str = None
) -> Dict[str, Any]:
    """
    Analyze a food image to estimate calories, macros, and nutritional content.
    This tool uses GPT-4o-mini Vision to analyze the food in the image.

    IMPORTANT: Use this tool when the user sends an image of food they ate.
    The tool will:
    1. Analyze the image to identify food items
    2. Estimate calories and macros (protein, carbs, fat)
    3. Save the meal to the database
    4. Provide coaching feedback on the meal

    Args:
        user_id: The user's ID (UUID string)
        image_base64: Base64 encoded image data (without data:image prefix)
        user_message: Optional context from the user about the meal

    Returns:
        Result dict with nutrition analysis, saved food log, and coaching feedback
    """
    logger.info(f"Tool: Analyzing food image for user {user_id}")

    try:
        db = get_supabase_db()
        vision_service = get_vision_service()

        # Get user's nutrition targets for context
        user = db.get_user(user_id)
        user_context = None
        if user:
            targets = {
                "daily_calorie_target": user.get("daily_calorie_target"),
                "daily_protein_target_g": user.get("daily_protein_target_g"),
                "daily_carbs_target_g": user.get("daily_carbs_target_g"),
                "daily_fat_target_g": user.get("daily_fat_target_g"),
            }
            # Filter out None values
            targets = {k: v for k, v in targets.items() if v is not None}
            if targets:
                user_context = f"User's nutrition targets: {json.dumps(targets)}"
            if user_message:
                user_context = f"{user_context or ''}\nUser says: {user_message}"

        # Analyze the image using Vision service (async call)
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # We're in an async context, create a new task
            import concurrent.futures
            with concurrent.futures.ThreadPoolExecutor() as executor:
                future = executor.submit(
                    asyncio.run,
                    vision_service.analyze_food_image(image_base64, user_context)
                )
                analysis_result = future.result(timeout=60)
        else:
            analysis_result = asyncio.run(
                vision_service.analyze_food_image(image_base64, user_context)
            )

        if not analysis_result.get("success"):
            return {
                "success": False,
                "action": "analyze_food_image",
                "user_id": user_id,
                "message": analysis_result.get("error", "Failed to analyze food image")
            }

        # Extract nutrition data
        nutrition_data = analysis_result.get("data", {})
        meal_type = nutrition_data.get("meal_type", "snack")
        food_items = nutrition_data.get("food_items", [])
        total_calories = nutrition_data.get("total_calories", 0)
        protein_g = nutrition_data.get("protein_g", 0)
        carbs_g = nutrition_data.get("carbs_g", 0)
        fat_g = nutrition_data.get("fat_g", 0)
        fiber_g = nutrition_data.get("fiber_g", 0)
        health_score = nutrition_data.get("health_score", 5)
        ai_feedback = nutrition_data.get("feedback", "")

        # Save to database
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            health_score=health_score,
            ai_feedback=ai_feedback
        )

        food_log_id = food_log.get("id") if food_log else None

        # Get today's nutrition summary
        today = datetime.now().strftime("%Y-%m-%d")
        daily_summary = db.get_daily_nutrition_summary(user_id, today)

        # Format food items for response
        food_list = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('amount', '')})"
            for item in food_items
        ])

        # Build response message
        message = (
            f"🍽️ **{meal_type.title()} Logged!**\n\n"
            f"**Food Items:** {food_list}\n\n"
            f"**Nutrition:**\n"
            f"• Calories: {total_calories} kcal\n"
            f"• Protein: {protein_g}g\n"
            f"• Carbs: {carbs_g}g\n"
            f"• Fat: {fat_g}g\n"
            f"• Fiber: {fiber_g}g\n\n"
            f"**Health Score:** {health_score}/10\n\n"
            f"**Coach Feedback:** {ai_feedback}"
        )

        # Add daily progress if available
        if daily_summary and daily_summary.get("total_calories"):
            message += (
                f"\n\n**Today's Total:**\n"
                f"• Calories: {daily_summary.get('total_calories', 0)} kcal\n"
                f"• Protein: {daily_summary.get('total_protein_g', 0):.1f}g\n"
                f"• Carbs: {daily_summary.get('total_carbs_g', 0):.1f}g\n"
                f"• Fat: {daily_summary.get('total_fat_g', 0):.1f}g"
            )

        return {
            "success": True,
            "action": "analyze_food_image",
            "user_id": user_id,
            "food_log_id": food_log_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "health_score": health_score,
            "ai_feedback": ai_feedback,
            "daily_summary": daily_summary,
            "message": message
        }

    except Exception as e:
        logger.error(f"Analyze food image failed: {e}")
        return {
            "success": False,
            "action": "analyze_food_image",
            "user_id": user_id,
            "message": f"Failed to analyze food image: {str(e)}"
        }


@tool
def get_nutrition_summary(
    user_id: str,
    date: str = None,
    period: str = "day"
) -> Dict[str, Any]:
    """
    Get a nutrition summary for a user for a specific day or week.

    Args:
        user_id: The user's ID (UUID string)
        date: Date to get summary for (YYYY-MM-DD format). Defaults to today.
        period: "day" for daily summary, "week" for weekly summary

    Returns:
        Result dict with nutrition totals and meal breakdown
    """
    logger.info(f"Tool: Getting nutrition summary for user {user_id}, period: {period}")

    try:
        db = get_supabase_db()

        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")

        if period == "week":
            # Get weekly summary
            summary = db.get_weekly_nutrition_summary(user_id, date)

            if not summary:
                return {
                    "success": True,
                    "action": "get_nutrition_summary",
                    "user_id": user_id,
                    "period": "week",
                    "summary": [],
                    "message": "No meals logged this week yet."
                }

            total_calories = sum(day.get("total_calories", 0) or 0 for day in summary)
            avg_calories = total_calories / len(summary) if summary else 0

            message = (
                f"📊 **Weekly Nutrition Summary**\n"
                f"(Starting {date})\n\n"
                f"**Average Daily Intake:**\n"
                f"• Calories: {avg_calories:.0f} kcal\n"
                f"• Meals logged: {sum(day.get('meal_count', 0) for day in summary)} total\n"
            )

            return {
                "success": True,
                "action": "get_nutrition_summary",
                "user_id": user_id,
                "period": "week",
                "start_date": date,
                "daily_summaries": summary,
                "total_calories": total_calories,
                "average_daily_calories": avg_calories,
                "message": message
            }

        else:
            # Get daily summary
            summary = db.get_daily_nutrition_summary(user_id, date)

            if not summary or not summary.get("total_calories"):
                return {
                    "success": True,
                    "action": "get_nutrition_summary",
                    "user_id": user_id,
                    "period": "day",
                    "date": date,
                    "summary": None,
                    "message": f"No meals logged for {date} yet."
                }

            message = (
                f"📊 **Daily Nutrition Summary for {date}**\n\n"
                f"**Total Intake:**\n"
                f"• Calories: {summary.get('total_calories', 0)} kcal\n"
                f"• Protein: {summary.get('total_protein_g', 0):.1f}g\n"
                f"• Carbs: {summary.get('total_carbs_g', 0):.1f}g\n"
                f"• Fat: {summary.get('total_fat_g', 0):.1f}g\n"
                f"• Fiber: {summary.get('total_fiber_g', 0):.1f}g\n\n"
                f"**Meals Logged:** {summary.get('meal_count', 0)}\n"
                f"**Avg Health Score:** {summary.get('avg_health_score', 0):.1f}/10"
            )

            return {
                "success": True,
                "action": "get_nutrition_summary",
                "user_id": user_id,
                "period": "day",
                "date": date,
                "summary": summary,
                "message": message
            }

    except Exception as e:
        logger.error(f"Get nutrition summary failed: {e}")
        return {
            "success": False,
            "action": "get_nutrition_summary",
            "user_id": user_id,
            "message": f"Failed to get nutrition summary: {str(e)}"
        }


@tool
def get_recent_meals(
    user_id: str,
    limit: int = 5
) -> Dict[str, Any]:
    """
    Get the user's recent meal logs.

    Args:
        user_id: The user's ID (UUID string)
        limit: Maximum number of meals to return (default 5)

    Returns:
        Result dict with list of recent meals
    """
    logger.info(f"Tool: Getting recent meals for user {user_id}")

    try:
        db = get_supabase_db()

        meals = db.list_food_logs(user_id, limit=limit)

        if not meals:
            return {
                "success": True,
                "action": "get_recent_meals",
                "user_id": user_id,
                "meals": [],
                "message": "No meals logged yet. Send me a photo of your food to start tracking!"
            }

        meal_list = []
        for meal in meals:
            logged_at = meal.get("logged_at", "")
            if isinstance(logged_at, str) and "T" in logged_at:
                logged_at = logged_at.split("T")[0]

            food_items = meal.get("food_items", [])
            food_names = ", ".join([
                item.get("name", "Unknown") for item in food_items[:3]
            ])
            if len(food_items) > 3:
                food_names += f" +{len(food_items) - 3} more"

            meal_list.append({
                "id": meal.get("id"),
                "date": logged_at,
                "meal_type": meal.get("meal_type"),
                "food_items": food_names,
                "calories": meal.get("total_calories"),
                "health_score": meal.get("health_score")
            })

        message = f"🍽️ **Recent Meals ({len(meals)}):**\n\n"
        for m in meal_list:
            message += (
                f"• **{m['meal_type'].title()}** ({m['date']}): "
                f"{m['food_items']} - {m['calories']} kcal\n"
            )

        return {
            "success": True,
            "action": "get_recent_meals",
            "user_id": user_id,
            "meals": meal_list,
            "count": len(meal_list),
            "message": message
        }

    except Exception as e:
        logger.error(f"Get recent meals failed: {e}")
        return {
            "success": False,
            "action": "get_recent_meals",
            "user_id": user_id,
            "message": f"Failed to get recent meals: {str(e)}"
        }


# Registry of all available tools
ALL_TOOLS = [
    add_exercise_to_workout,
    remove_exercise_from_workout,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
    # Nutrition tools
    analyze_food_image,
    get_nutrition_summary,
    get_recent_meals,
]

# Tool name to function mapping
TOOLS_MAP = {tool.name: tool for tool in ALL_TOOLS}
