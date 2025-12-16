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
    Add exercises to the user's current workout using the Exercise Library from ChromaDB.

    Args:
        workout_id: The ID of the workout to modify
        exercise_names: List of exercise names to add (e.g., ["Push-ups", "Lunges"])
        muscle_groups: Optional list of target muscle groups

    Returns:
        Result dict with success status and message
    """
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
        user_equipment = user.get("equipment", []) if user else ["Bodyweight"]
        user_fitness_level = user.get("fitness_level", "intermediate") if user else "intermediate"

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
                # Run async search in sync context
                loop = asyncio.get_event_loop()
                if loop.is_running():
                    import concurrent.futures
                    with concurrent.futures.ThreadPoolExecutor() as executor:
                        future = executor.submit(
                            asyncio.run,
                            exercise_rag.select_exercises_for_workout(
                                focus_area=exercise_name,  # Use exercise name as search query
                                equipment=user_equipment if user_equipment else ["Bodyweight"],
                                fitness_level=user_fitness_level,
                                goals=["General Fitness"],
                                count=1,
                                avoid_exercises=[ex.get("name", "") for ex in exercises],
                                injuries=None,
                            )
                        )
                        rag_results = future.result(timeout=15)
                else:
                    rag_results = asyncio.run(
                        exercise_rag.select_exercises_for_workout(
                            focus_area=exercise_name,
                            equipment=user_equipment if user_equipment else ["Bodyweight"],
                            fitness_level=user_fitness_level,
                            goals=["General Fitness"],
                            count=1,
                            avoid_exercises=[ex.get("name", "") for ex in exercises],
                            injuries=None,
                        )
                    )

                if rag_results:
                    # Use the exercise from the library
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
                    }
                    exercises.append(new_exercise)
                    added_exercises.append(new_exercise["name"])
                    logger.info(f"✅ Added exercise from library: {new_exercise['name']}")
                else:
                    # Exercise not found in library - return error
                    logger.warning(f"Exercise not found in library: {exercise_name}")

            except Exception as search_error:
                logger.warning(f"Failed to search for exercise {exercise_name}: {search_error}")

        if not added_exercises:
            return {
                "success": False,
                "action": "add_exercise",
                "workout_id": workout_id,
                "message": f"Could not find exercises in the Exercise Library. Try different exercise names."
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
def replace_all_exercises(
    workout_id: int,
    muscle_group: str,
    num_exercises: int = 5
) -> Dict[str, Any]:
    """
    Replace ALL exercises in a workout with new exercises targeting a specific muscle group.
    Uses the Exercise Library from ChromaDB for personalized exercise selection.
    Use this when the user wants to completely change their workout to focus on a different muscle group.

    Args:
        workout_id: The ID of the workout to modify
        muscle_group: Target muscle group for new exercises (e.g., "back", "chest", "legs", "shoulders", "arms", "core")
        num_exercises: Number of new exercises to add (default 5)

    Returns:
        Result dict with success status, removed exercises, and new exercises
    """
    logger.info(f"Tool: Replacing all exercises in workout {workout_id} with {muscle_group} exercises using RAG")

    try:
        db = get_supabase_db()

        # Get current workout
        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        # Get current exercises
        current_exercises = workout.get("exercises", [])
        old_exercise_names = [e.get("name", "Unknown") for e in current_exercises]

        # Get user profile for personalized exercise selection
        user_id = workout.get("user_id")
        user = db.get_user(user_id) if user_id else None
        user_equipment = user.get("equipment", []) if user else ["Bodyweight"]
        user_fitness_level = user.get("fitness_level", "intermediate") if user else "intermediate"
        user_goals = user.get("goals", []) if user else []
        user_injuries = user.get("active_injuries", []) if user else []

        # Parse injuries if stored as JSON string
        if isinstance(user_injuries, str):
            try:
                user_injuries = json.loads(user_injuries)
            except json.JSONDecodeError:
                user_injuries = []

        # Extract injury body parts for filtering
        injury_body_parts = []
        if user_injuries:
            for inj in user_injuries:
                if isinstance(inj, dict):
                    injury_body_parts.append(inj.get("body_part", ""))
                elif isinstance(inj, str):
                    injury_body_parts.append(inj)

        # Map muscle group to focus area for RAG search
        focus_area_map = {
            "back": "back",
            "chest": "chest",
            "legs": "legs",
            "shoulders": "shoulders",
            "arms": "arms",
            "core": "core",
            "glutes": "legs",
            "biceps": "arms",
            "triceps": "arms",
            "quads": "legs",
            "hamstrings": "legs",
            "calves": "legs",
            "abs": "core",
        }
        focus_area = focus_area_map.get(muscle_group.lower(), muscle_group.lower())

        # Use Exercise RAG to select personalized exercises
        new_exercises = []
        from services.exercise_rag_service import get_exercise_rag_service
        exercise_rag = get_exercise_rag_service()

        # Run async function in sync context
        loop = asyncio.get_event_loop()
        if loop.is_running():
            import concurrent.futures
            with concurrent.futures.ThreadPoolExecutor() as executor:
                future = executor.submit(
                    asyncio.run,
                    exercise_rag.select_exercises_for_workout(
                        focus_area=focus_area,
                        equipment=user_equipment if user_equipment else ["Bodyweight"],
                        fitness_level=user_fitness_level,
                        goals=user_goals if user_goals else ["General Fitness"],
                        count=num_exercises,
                        avoid_exercises=old_exercise_names,
                        injuries=injury_body_parts if injury_body_parts else None,
                    )
                )
                rag_exercises = future.result(timeout=30)
        else:
            rag_exercises = asyncio.run(
                exercise_rag.select_exercises_for_workout(
                    focus_area=focus_area,
                    equipment=user_equipment if user_equipment else ["Bodyweight"],
                    fitness_level=user_fitness_level,
                    goals=user_goals if user_goals else ["General Fitness"],
                    count=num_exercises,
                    avoid_exercises=old_exercise_names,
                    injuries=injury_body_parts if injury_body_parts else None,
                )
            )

        if rag_exercises:
            logger.info(f"✅ RAG selected {len(rag_exercises)} {muscle_group} exercises from ChromaDB")
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
                })

        if not new_exercises:
            return {
                "success": False,
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "message": f"Could not find exercises for {muscle_group}. Please try a different muscle group."
            }

        # Update workout with new exercises
        update_data = {
            "exercises": new_exercises,
            "name": f"{muscle_group.title()} Workout",
            "last_modified_method": "ai_replace_all"
        }

        db.update_workout(workout_id, update_data)

        new_exercise_names = [e["name"] for e in new_exercises]

        logger.info(f"Replaced {len(old_exercise_names)} exercises with {len(new_exercises)} {muscle_group} exercises from Exercise Library")

        return {
            "success": True,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "exercises_removed": old_exercise_names,
            "exercises_added": new_exercise_names,
            "muscle_group": muscle_group,
            "message": f"Replaced all exercises with {len(new_exercises)} {muscle_group} exercises: {', '.join(new_exercise_names)}"
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
def generate_quick_workout(
    user_id: str,
    workout_id: str = None,
    duration_minutes: int = 15,
    workout_type: str = "full_body",
    intensity: str = "moderate"
) -> Dict[str, Any]:
    """
    Generate a quick workout for the user using the Exercise Library from ChromaDB.
    If workout_id is provided, replaces that workout. Otherwise, creates a new workout for today.
    Use this when the user asks for a "quick workout", "short workout", "something fast",
    or wants a new workout.

    Args:
        user_id: The user's ID (required)
        workout_id: Optional ID of workout to replace. If not provided, creates a new workout for today.
        duration_minutes: Target duration in minutes (default 15, max 30 for quick workouts)
        workout_type: Type of workout. Standard types: "full_body", "upper", "lower", "cardio", "core".
                     Sport-specific types: "boxing", "hyrox", "crossfit", "martial_arts", "hiit", "strength", "endurance", "flexibility", "mobility"
        intensity: Workout intensity - "light", "moderate", "intense" (default moderate)

    Returns:
        Result dict with the new quick workout details
    """
    logger.info(f"Tool: Generating quick {duration_minutes}min {workout_type} workout for user {user_id}")

    try:
        db = get_supabase_db()

        old_exercise_names = []
        workout = None
        is_new_workout = False

        # Try to get existing workout if workout_id provided
        if workout_id:
            workout = db.get_workout(workout_id)
            if workout:
                old_exercises = workout.get("exercises", [])
                old_exercise_names = [e.get("name", "Unknown") for e in old_exercises]

        # If no workout found, we'll create a new one
        if not workout:
            is_new_workout = True
            logger.info(f"No existing workout found, will create new workout for user {user_id}")

        # Get user profile for personalized exercise selection
        user = db.get_user(user_id) if user_id else None
        user_equipment = user.get("equipment", []) if user else ["Bodyweight"]
        user_fitness_level = user.get("fitness_level", "intermediate") if user else "intermediate"
        user_goals = user.get("goals", []) if user else []
        user_injuries = user.get("active_injuries", []) if user else []

        # Parse injuries if stored as JSON string
        if isinstance(user_injuries, str):
            try:
                user_injuries = json.loads(user_injuries)
            except json.JSONDecodeError:
                user_injuries = []

        # Extract injury body parts for filtering
        injury_body_parts = []
        if user_injuries:
            for inj in user_injuries:
                if isinstance(inj, dict):
                    injury_body_parts.append(inj.get("body_part", ""))
                elif isinstance(inj, str):
                    injury_body_parts.append(inj)

        # Map workout type to focus area for RAG search
        # Standard workout types
        focus_area_map = {
            "full_body": "full_body",
            "upper": "chest",  # Will also get shoulders, back, arms
            "lower": "legs",
            "cardio": "full_body_power",  # Explosive movements
            "core": "core",
            # Sport-specific workout types
            "boxing": "boxing",  # Boxing-specific exercises (punches, footwork, conditioning)
            "hyrox": "hyrox",  # HYROX competition training (functional fitness, rowing, running)
            "crossfit": "crossfit",  # CrossFit-style WODs
            "martial_arts": "martial_arts",  # General martial arts conditioning
            "hiit": "hiit",  # High-intensity interval training
            "strength": "strength",  # Pure strength training
            "endurance": "endurance",  # Endurance/stamina focused
            "flexibility": "flexibility",  # Stretching and flexibility
            "mobility": "mobility",  # Joint mobility work
            # Body part aliases
            "chest": "chest",
            "back": "back",
            "shoulders": "shoulders",
            "arms": "arms",
            "legs": "legs",
            "glutes": "legs",
        }

        workout_type_key = workout_type.lower().replace(" ", "_").replace("-", "_")

        # Check for sport-specific keywords in workout_type
        sport_keywords = {
            "box": "boxing",
            "punch": "boxing",
            "fighter": "boxing",
            "mma": "martial_arts",
            "hyrox": "hyrox",
            "crossfit": "crossfit",
            "wod": "crossfit",
            "hiit": "hiit",
            "interval": "hiit",
            "tabata": "hiit",
            "stretch": "flexibility",
            "yoga": "flexibility",
            "mobil": "mobility",
        }

        for keyword, sport_type in sport_keywords.items():
            if keyword in workout_type_key:
                workout_type_key = sport_type
                break

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

        # Map intensity to fitness level for RAG
        intensity_to_fitness = {
            "light": "beginner",
            "moderate": "intermediate",
            "intense": "advanced",
        }
        rag_fitness_level = intensity_to_fitness.get(intensity_key, user_fitness_level)

        # Use Exercise RAG to select personalized exercises
        new_exercises = []
        try:
            from services.exercise_rag_service import get_exercise_rag_service
            exercise_rag = get_exercise_rag_service()

            # Run async function in sync context
            loop = asyncio.get_event_loop()
            if loop.is_running():
                import concurrent.futures
                with concurrent.futures.ThreadPoolExecutor() as executor:
                    future = executor.submit(
                        asyncio.run,
                        exercise_rag.select_exercises_for_workout(
                            focus_area=focus_area,
                            equipment=user_equipment if user_equipment else ["Bodyweight"],
                            fitness_level=rag_fitness_level,
                            goals=user_goals if user_goals else ["General Fitness"],
                            count=exercise_count,
                            avoid_exercises=old_exercise_names,  # Avoid exercises from current workout
                            injuries=injury_body_parts if injury_body_parts else None,
                        )
                    )
                    rag_exercises = future.result(timeout=30)
            else:
                rag_exercises = asyncio.run(
                    exercise_rag.select_exercises_for_workout(
                        focus_area=focus_area,
                        equipment=user_equipment if user_equipment else ["Bodyweight"],
                        fitness_level=rag_fitness_level,
                        goals=user_goals if user_goals else ["General Fitness"],
                        count=exercise_count,
                        avoid_exercises=old_exercise_names,
                        injuries=injury_body_parts if injury_body_parts else None,
                    )
                )

            if rag_exercises:
                logger.info(f"✅ RAG selected {len(rag_exercises)} exercises from ChromaDB")

                # Adjust sets/reps based on intensity
                sets_reps_config = {
                    "light": {"sets": 2, "reps": 10},
                    "moderate": {"sets": 3, "reps": 12},
                    "intense": {"sets": 4, "reps": 12},
                }
                config = sets_reps_config.get(intensity_key, {"sets": 3, "reps": 12})

                for ex in rag_exercises:
                    new_exercises.append({
                        "name": ex.get("name", "Exercise"),
                        "sets": config["sets"],
                        "reps": ex.get("reps", config["reps"]),
                        "duration_seconds": ex.get("duration_seconds"),
                        "muscle_group": ex.get("muscle_group", ex.get("body_part", workout_type_key)),
                        "equipment": ex.get("equipment", "Bodyweight"),
                        "notes": ex.get("notes", ""),
                        "gif_url": ex.get("gif_url", ""),
                    })

        except Exception as rag_error:
            logger.error(f"Exercise RAG failed: {rag_error}")
            return {
                "success": False,
                "action": "generate_quick_workout",
                "workout_id": workout_id,
                "message": f"Could not generate workout from Exercise Library: {str(rag_error)}"
            }

        if not new_exercises:
            return {
                "success": False,
                "action": "generate_quick_workout",
                "workout_id": workout_id,
                "message": f"Could not find exercises for {workout_type} workout. Please try a different workout type."
            }

        # Generate workout name
        intensity_names = {"light": "Easy", "moderate": "Power", "intense": "Intense"}
        type_names = {
            # Standard types
            "full_body": "Full Body",
            "upper": "Upper Body",
            "lower": "Lower Body",
            "cardio": "Cardio",
            "core": "Core",
            # Sport-specific types
            "boxing": "Boxing",
            "hyrox": "HYROX",
            "crossfit": "CrossFit",
            "martial_arts": "Martial Arts",
            "hiit": "HIIT",
            "strength": "Strength",
            "endurance": "Endurance",
            "flexibility": "Flexibility",
            "mobility": "Mobility",
            # Body parts
            "chest": "Chest",
            "back": "Back",
            "shoulders": "Shoulders",
            "arms": "Arms",
            "legs": "Legs",
            "glutes": "Glutes",
        }
        workout_name = f"Quick {intensity_names.get(intensity_key, 'Power')} {type_names.get(workout_type_key, workout_type_key.replace('_', ' ').title())}"

        new_exercise_names = [e["name"] for e in new_exercises]
        final_workout_id = workout_id

        if is_new_workout:
            # Create a new workout for today
            from datetime import date
            today = date.today().isoformat()

            new_workout_data = {
                "user_id": user_id,
                "name": workout_name,
                "type": workout_type_key.replace("_", " "),
                "difficulty": intensity_key,
                "scheduled_date": today,
                "exercises_json": new_exercises,
                "duration_minutes": min(duration_minutes, 30),
                "is_completed": False,
                "generation_method": "ai_quick_workout",
                "generation_source": "chat",
            }

            created_workout = db.create_workout(new_workout_data)
            if created_workout:
                final_workout_id = created_workout.get("id")
                logger.info(f"Created new quick workout {final_workout_id}: {workout_name}")
            else:
                return {
                    "success": False,
                    "action": "generate_quick_workout",
                    "message": "Failed to create new workout in database"
                }
        else:
            # Update existing workout
            update_data = {
                "exercises": new_exercises,
                "name": workout_name,
                "duration_minutes": min(duration_minutes, 30),  # Cap at 30 for quick workouts
                "difficulty": intensity_key,
                "type": workout_type_key.replace("_", " "),
                "last_modified_method": "ai_quick_workout"
            }
            db.update_workout(workout_id, update_data)
            logger.info(f"Updated workout {workout_id}: {workout_name}")

        logger.info(f"Generated quick workout: {workout_name} with {len(new_exercises)} exercises from Exercise Library")

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
            "message": f"{'Created' if is_new_workout else 'Updated'} '{workout_name}' - {len(new_exercises)} exercises, ~{min(duration_minutes, 30)} minutes"
        }

    except Exception as e:
        logger.error(f"Generate quick workout failed: {e}")
        return {
            "success": False,
            "action": "generate_quick_workout",
            "workout_id": workout_id,
            "message": f"Failed to generate quick workout: {str(e)}"
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
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
    generate_quick_workout,  # New quick workout generator
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
