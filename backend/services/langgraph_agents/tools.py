"""
LangChain tool definitions for workout modifications and injury management.

These tools are bound to the LLM and can be called automatically
based on user intent.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import json
from langchain_core.tools import tool
from services.workout_modifier import WorkoutModifier
from services.injury_service import get_injury_service, Injury
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
        db = get_db()
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
        result = db.conn.execute("SELECT COALESCE(MAX(id), 0) + 1 FROM injury_history").fetchone()
        injury_id = result[0]

        db.conn.execute("""
            INSERT INTO injury_history
            (id, user_id, body_part, severity, reported_at, expected_recovery_date,
             duration_planned_weeks, pain_level_initial, pain_level_current, improvement_notes, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            injury_id,
            user_id,
            body_part.lower(),
            severity.lower(),
            reported_at,
            expected_recovery_date,
            recovery_weeks,
            pain_level,
            pain_level,
            notes,
            True
        ])

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
        upcoming_workouts = db.conn.execute("""
            SELECT id, exercises_json, name FROM workouts
            WHERE user_id = ? AND scheduled_date >= ? AND scheduled_date <= ? AND is_completed = FALSE
            ORDER BY scheduled_date
        """, [user_id, reported_at.strftime("%Y-%m-%d"), expected_recovery_date.strftime("%Y-%m-%d")]).fetchall()

        for workout in upcoming_workouts:
            workout_id = workout[0]
            exercises_json = workout[1]
            workout_name = workout[2]

            try:
                exercises = json.loads(exercises_json) if exercises_json else []
            except json.JSONDecodeError:
                exercises = []

            # Filter exercises for this injury
            safe_exercises, removed = injury_service.filter_workout_for_injuries(exercises, [injury])

            if removed:
                exercises_removed_total.extend([ex.get("name", "Unknown") for ex in removed])

                # Add rehab exercises to the workout
                updated_exercises = injury_service.add_rehab_exercises_to_workout(safe_exercises, [injury])

                # Update workout in database
                db.conn.execute("""
                    UPDATE workouts
                    SET exercises_json = ?, last_modified_method = 'injury_modification', last_modified_at = ?
                    WHERE id = ?
                """, [json.dumps(updated_exercises), datetime.now(), workout_id])

                workouts_modified += 1

                # Log the modification
                try:
                    change_result = db.conn.execute("SELECT COALESCE(MAX(id), 0) + 1 FROM workout_changes").fetchone()
                    change_id = change_result[0]
                    db.conn.execute("""
                        INSERT INTO workout_changes
                        (id, workout_id, user_id, change_type, field_changed, old_value, new_value, change_source, change_reason)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, [
                        change_id,
                        workout_id,
                        user_id,
                        "injury_modification",
                        "exercises_json",
                        exercises_json,
                        json.dumps(updated_exercises),
                        "injury_report",
                        f"{body_part} injury ({severity})"
                    ])
                except Exception as log_error:
                    logger.warning(f"Failed to log workout change: {log_error}")

        # Update injury record with modification counts
        db.conn.execute("""
            UPDATE injury_history
            SET workouts_modified_count = ?,
                exercises_removed = ?,
                rehab_exercises_added = ?
            WHERE id = ?
        """, [
            workouts_modified,
            json.dumps(list(set(exercises_removed_total))),
            json.dumps([ex.get("name") for ex in rehab_exercises]),
            injury_id
        ])

        # Update user's active injuries list
        try:
            user_injuries = db.conn.execute(
                "SELECT active_injuries FROM users WHERE id = ?", [user_id]
            ).fetchone()

            current_injuries = []
            if user_injuries and user_injuries[0]:
                try:
                    current_injuries = json.loads(user_injuries[0])
                except json.JSONDecodeError:
                    current_injuries = []

            current_injuries.append({
                "id": injury_id,
                "body_part": body_part.lower(),
                "severity": severity.lower(),
                "reported_at": reported_at.isoformat(),
                "expected_recovery_date": expected_recovery_date.isoformat()
            })

            db.conn.execute(
                "UPDATE users SET active_injuries = ? WHERE id = ?",
                [json.dumps(current_injuries), user_id]
            )
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
        db = get_db()

        # Find the injury to clear
        if injury_id:
            injury_record = db.conn.execute("""
                SELECT id, body_part, severity, reported_at, expected_recovery_date, duration_planned_weeks
                FROM injury_history
                WHERE id = ? AND user_id = ? AND is_active = TRUE
            """, [injury_id, user_id]).fetchone()
        elif body_part:
            injury_record = db.conn.execute("""
                SELECT id, body_part, severity, reported_at, expected_recovery_date, duration_planned_weeks
                FROM injury_history
                WHERE user_id = ? AND body_part = ? AND is_active = TRUE
                ORDER BY reported_at DESC
                LIMIT 1
            """, [user_id, body_part.lower()]).fetchone()
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

        injury_id = injury_record[0]
        cleared_body_part = injury_record[1]
        severity = injury_record[2]
        reported_at = injury_record[3]
        expected_recovery = injury_record[4]
        planned_weeks = injury_record[5]

        # Calculate actual duration
        actual_recovery_date = datetime.now()
        if isinstance(reported_at, str):
            reported_at = datetime.fromisoformat(reported_at)
        actual_days = (actual_recovery_date - reported_at).days

        # Determine if early or late recovery
        recovery_status = "on_time"
        if actual_days < (planned_weeks * 7 * 0.7):  # More than 30% early
            recovery_status = "early"
        elif actual_days > (planned_weeks * 7 * 1.3):  # More than 30% late
            recovery_status = "late"

        # Update injury record as healed
        db.conn.execute("""
            UPDATE injury_history
            SET is_active = FALSE,
                actual_recovery_date = ?,
                duration_actual_days = ?,
                recovery_phase = 'healed',
                user_feedback = ?
            WHERE id = ?
        """, [actual_recovery_date, actual_days, user_feedback, injury_id])

        # Remove from user's active injuries
        try:
            user_injuries = db.conn.execute(
                "SELECT active_injuries FROM users WHERE id = ?", [user_id]
            ).fetchone()

            if user_injuries and user_injuries[0]:
                try:
                    current_injuries = json.loads(user_injuries[0])
                    # Remove the cleared injury
                    updated_injuries = [
                        inj for inj in current_injuries
                        if inj.get("id") != injury_id and inj.get("body_part") != cleared_body_part
                    ]
                    db.conn.execute(
                        "UPDATE users SET active_injuries = ? WHERE id = ?",
                        [json.dumps(updated_injuries), user_id]
                    )
                except json.JSONDecodeError:
                    pass
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
        db = get_db()
        injury_service = get_injury_service()

        injuries = db.conn.execute("""
            SELECT id, body_part, severity, reported_at, expected_recovery_date,
                   duration_planned_weeks, pain_level_current, improvement_notes, recovery_phase
            FROM injury_history
            WHERE user_id = ? AND is_active = TRUE
            ORDER BY reported_at DESC
        """, [user_id]).fetchall()

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
            injury_id = inj[0]
            body_part = inj[1]
            severity = inj[2]
            reported_at = inj[3]
            expected_recovery = inj[4]
            planned_weeks = inj[5]
            pain_level = inj[6]
            notes = inj[7]
            stored_phase = inj[8]

            # Parse dates
            if isinstance(reported_at, str):
                reported_at = datetime.fromisoformat(reported_at)
            if isinstance(expected_recovery, str):
                expected_recovery = datetime.fromisoformat(expected_recovery)

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
        db = get_db()

        # Find the injury
        if injury_id:
            injury_record = db.conn.execute("""
                SELECT id, body_part, pain_level_current, improvement_notes
                FROM injury_history
                WHERE id = ? AND user_id = ? AND is_active = TRUE
            """, [injury_id, user_id]).fetchone()
        elif body_part:
            injury_record = db.conn.execute("""
                SELECT id, body_part, pain_level_current, improvement_notes
                FROM injury_history
                WHERE user_id = ? AND body_part = ? AND is_active = TRUE
                ORDER BY reported_at DESC
                LIMIT 1
            """, [user_id, body_part.lower()]).fetchone()
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

        injury_id = injury_record[0]
        current_body_part = injury_record[1]
        old_pain = injury_record[2]
        old_notes = injury_record[3]

        # Build update query
        updates = []
        params = []

        if pain_level is not None:
            updates.append("pain_level_current = ?")
            params.append(pain_level)

        if improvement_notes:
            # Append to existing notes
            new_notes = f"{old_notes or ''}\n[{datetime.now().strftime('%Y-%m-%d')}] {improvement_notes}".strip()
            updates.append("improvement_notes = ?")
            params.append(new_notes)

        if not updates:
            return {
                "success": False,
                "action": "update_injury_status",
                "message": "No updates provided. Specify pain_level or improvement_notes."
            }

        params.append(injury_id)
        db.conn.execute(f"""
            UPDATE injury_history
            SET {', '.join(updates)}
            WHERE id = ?
        """, params)

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
        db = get_db()

        # Get workout details before deletion
        workout = db.conn.execute(
            "SELECT id, user_id, name, scheduled_date, type FROM workouts WHERE id = ?",
            [workout_id]
        ).fetchone()

        if not workout:
            return {
                "success": False,
                "action": "delete_workout",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        workout_name = workout[2]
        scheduled_date = workout[3]
        workout_type = workout[4]
        user_id = workout[1]

        # Delete related records first (cascade manually)
        # Delete performance logs for workout logs of this workout
        db.conn.execute("""
            DELETE FROM performance_logs
            WHERE workout_log_id IN (SELECT id FROM workout_logs WHERE workout_id = ?)
        """, [workout_id])

        # Delete workout logs
        db.conn.execute("DELETE FROM workout_logs WHERE workout_id = ?", [workout_id])

        # Delete workout changes
        db.conn.execute("DELETE FROM workout_changes WHERE workout_id = ?", [workout_id])

        # Delete the workout itself
        db.conn.execute("DELETE FROM workouts WHERE id = ?", [workout_id])

        # Log the deletion as a change (in a general log if needed)
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
                "deleted",
                "workout",
                workout_name,
                None,
                "ai_coach",
                reason or "Deleted via AI coach"
            ])
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
]

# Tool name to function mapping
TOOLS_MAP = {tool.name: tool for tool in ALL_TOOLS}
