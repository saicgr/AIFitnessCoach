"""
Injury management tools for LangGraph agents.

Contains tools for reporting, clearing, and tracking injuries.
"""

from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import json

from langchain_core.tools import tool

from services.injury_service import get_injury_service, Injury
from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


@tool
def report_injury(
    user_id: str,
    body_part: str,
    severity: str = "moderate",
    duration_weeks: int = None,
    pain_level: int = None,
    notes: str = None
) -> Dict[str, Any]:
    """
    Report a new injury for the user.

    This will:
    1. Record the injury in the database
    2. Modify upcoming workouts to remove exercises that affect the injured area
    3. Add appropriate rehab exercises based on recovery phase

    Args:
        user_id: The user's ID (UUID string)
        body_part: The injured body part (e.g., "back", "shoulder", "knee")
        severity: Injury severity - "mild" (2 weeks), "moderate" (3 weeks), or "severe" (5 weeks)
        duration_weeks: Optional custom recovery duration in weeks
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

        # Create injury record
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

        # Modify upcoming workouts
        workouts_modified = 0
        exercises_removed_total = []

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
                updated_exercises = injury_service.add_rehab_exercises_to_workout(safe_exercises, [injury])

                db.update_workout(workout_id, {
                    "exercises": updated_exercises,
                    "last_modified_method": "injury_modification"
                })

                workouts_modified += 1

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
            "exercises_to_avoid": contraindicated[:10],
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
    user_id: str,
    body_part: str = None,
    injury_id: str = None,
    user_feedback: str = None
) -> Dict[str, Any]:
    """
    Clear/resolve an injury for the user.

    Args:
        user_id: The user's ID (UUID string)
        body_part: The body part to clear (use this OR injury_id)
        injury_id: Specific injury UUID to clear (use this OR body_part)
        user_feedback: Optional feedback about the recovery

    Returns:
        Result dict with cleared injury details
    """
    logger.info(f"Tool: Clearing injury for user {user_id}")

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
            if actual_days < (planned_weeks * 7 * 0.7):
                recovery_status = "early"
            elif actual_days > (planned_weeks * 7 * 1.3):
                recovery_status = "late"

        # Update injury record as healed
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
def get_active_injuries(user_id: str) -> Dict[str, Any]:
    """
    Get all active injuries for a user with their current recovery status.

    Args:
        user_id: The user's ID (UUID string)

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

            # Create Injury object
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
                "rehab_exercises": [ex.get("name") for ex in rehab_exercises[:3]]
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
    user_id: str,
    injury_id: str = None,
    body_part: str = None,
    pain_level: int = None,
    improvement_notes: str = None
) -> Dict[str, Any]:
    """
    Update the status of an active injury.

    Args:
        user_id: The user's ID (UUID string)
        injury_id: Specific injury UUID to update (use this OR body_part)
        body_part: Body part to update (use this OR injury_id)
        pain_level: New pain level (1-10)
        improvement_notes: Notes about improvement

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
                "message": "No active injury found"
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
            new_notes = f"{old_notes or ''}\n[{datetime.now().strftime('%Y-%m-%d')}] {improvement_notes}".strip()
            update_data["improvement_notes"] = new_notes

        if not update_data:
            return {
                "success": False,
                "action": "update_injury_status",
                "message": "No updates provided. Specify pain_level or improvement_notes."
            }

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
