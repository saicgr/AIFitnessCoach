"""
Injury management tools for LangGraph agents.

Contains tools for reporting, clearing, and tracking injuries.
"""

from typing import Dict, Any, Optional
from datetime import datetime, timedelta, timezone
import json

from langchain_core.tools import tool

from services.injury_service import get_injury_service, Injury
from services.coach.injury_directives import REINTRO_GRACE_DAYS
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import get_user_today

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
                    logger.warning(f"Failed to log workout change: {log_error}", exc_info=True)

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

                # DEDUP + REINJURY-ADAPTIVE (F2): a fresh report of the SAME body
                # part REPLACES the old entry — the new reported_at resets it to
                # acute (re-protected) and drops any reintroduction_until. If the
                # old entry was already RECOVERING/reintroducing, the recurrence
                # is escalated one severity level (it came back, take it more
                # seriously). Also fixes the prior no-dedup bug.
                _order = ["mild", "moderate", "severe"]
                _eff_severity = severity.lower()
                _old = next((i for i in current_injuries if isinstance(i, dict)
                             and (i.get("body_part") or "").lower() == body_part.lower()), None)
                if _old:
                    _was_recovering = bool(_old.get("reintroduction_until"))
                    _old_sev = (_old.get("severity") or "mild").lower()
                    _base = max(_order.index(_eff_severity) if _eff_severity in _order else 0,
                                _order.index(_old_sev) if _old_sev in _order else 0)
                    if _was_recovering:
                        _base = min(_base + 1, len(_order) - 1)
                    _eff_severity = _order[_base]
                current_injuries = [
                    i for i in current_injuries
                    if not (isinstance(i, dict)
                            and (i.get("body_part") or "").lower() == body_part.lower())
                ]
                current_injuries.append({
                    "id": injury_id,
                    "body_part": body_part.lower(),
                    "severity": _eff_severity,
                    "reported_at": reported_at.isoformat(),
                    "expected_recovery_date": expected_recovery_date.isoformat()
                })

                db.update_user(user_id, {"active_injuries": current_injuries})
                # Resolve any older still-active injury_history rows for this
                # body part so get_active_injuries doesn't return duplicates.
                try:
                    db.client.table("injury_history").update({"is_active": False}).eq(
                        "user_id", user_id
                    ).eq("body_part", body_part.lower()).eq("is_active", True).neq(
                        "id", injury_id
                    ).execute()
                except Exception:
                    pass
        except Exception as user_update_error:
            logger.warning(f"Failed to update user active injuries: {user_update_error}", exc_info=True)

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
        logger.error(f"Report injury failed: {e}", exc_info=True)
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

        # Calculate actual duration (normalize to tz-aware UTC — DB timestamps
        # are offset-aware, datetime.now() is naive; subtracting mixes raised).
        actual_recovery_date = datetime.now(timezone.utc)
        if isinstance(reported_at, str):
            reported_at = datetime.fromisoformat(reported_at.replace("Z", "+00:00"))
        if reported_at.tzinfo is None:
            reported_at = reported_at.replace(tzinfo=timezone.utc)
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

        # Enter REINTRODUCTION instead of hard-removing: keep the entry but stamp
        # `reintroduction_until` so the next workouts EASE the body part back in
        # (reduced load) for a grace window, then it auto-drops (resolver returns
        # it as expired). This is the user-requested "forget it but ease me back".
        reintro_until = (actual_recovery_date + timedelta(days=REINTRO_GRACE_DAYS)).isoformat()
        try:
            user = db.get_user(user_id)
            if user:
                current_injuries = user.get("active_injuries") or []
                if isinstance(current_injuries, str):
                    try:
                        current_injuries = json.loads(current_injuries)
                    except json.JSONDecodeError:
                        current_injuries = []

                updated_injuries = []
                for inj in current_injuries:
                    if not isinstance(inj, dict):
                        continue
                    same = inj.get("id") == injury_id or (
                        (inj.get("body_part") or "").lower() == (cleared_body_part or "").lower()
                    )
                    if same:
                        inj["reintroduction_until"] = reintro_until
                    updated_injuries.append(inj)
                db.update_user(user_id, {"active_injuries": updated_injuries})
        except Exception as user_update_error:
            logger.warning(f"Failed to update user active injuries: {user_update_error}", exc_info=True)

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
            "reintroduction_days": REINTRO_GRACE_DAYS,
            "message": f"Got it — I'll stop treating your {cleared_body_part} as injured. "
                       f"To be safe, your next workouts will EASE it back in with lighter, "
                       f"controlled movements over about {REINTRO_GRACE_DAYS} days before returning "
                       f"to full loading. (Injured {actual_days} days; planned {planned_weeks} weeks.)"
        }

    except Exception as e:
        logger.error(f"Clear injury failed: {e}", exc_info=True)
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
        logger.error(f"Get active injuries failed: {e}", exc_info=True)
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
    improvement_notes: str = None,
    timezone_str: str = "UTC"
) -> Dict[str, Any]:
    """
    Update the status of an active injury.

    Args:
        user_id: The user's ID (UUID string)
        injury_id: Specific injury UUID to update (use this OR body_part)
        body_part: Body part to update (use this OR injury_id)
        pain_level: New pain level (1-10)
        improvement_notes: Notes about improvement
        timezone_str: User's IANA timezone string (e.g. "America/New_York")

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
            new_notes = f"{old_notes or ''}\n[{get_user_today(timezone_str)}] {improvement_notes}".strip()
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
        logger.error(f"Update injury status failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "update_injury_status",
            "message": f"Failed to update injury: {str(e)}"
        }


# ── Durable auto-capture of pain from a workout request (D) ──────────────────
# An INJURY word ("hurt/pain/tweaked/strained...") persists; mere SORENESS
# ("sore/tight/stiff/DOMS") is transient and is left to the one-workout
# sore_areas path so a normal leg-day DOMS mention never nukes leg training.
_INJURY_WORDS = (
    "hurt", "hurts", "pain", "painful", "injured", "injury", "tweaked",
    "strained", "strain", "pulled", "sprained", "sprain", "sharp", "threw out",
    "throwing out", "thrown out", "popped", "jacked up", "messed up", "busted",
)
_SORENESS_ONLY_WORDS = ("sore", "soreness", "tight", "tightness", "stiff", "stiffness", "doms", "achy", "aching")
_SEVERE_WORDS = ("severe", "really bad", "agony", "excruciating", "can't move", "cant move", "can't bear", "cant bear", "can't walk", "cant walk")


def classify_pain_mention(text: str):
    """Deterministic: ('injury'|'soreness'|None, body_part|None, severity).
    No LLM (feedback_no_llm_for_safety_classification)."""
    if not text:
        return (None, None, "mild")
    from services.workout_builder import SORE_TO_MUSCLES
    t = text.lower()
    body_part = next((k for k in SORE_TO_MUSCLES if k in t), None)
    if not body_part:
        return (None, None, "mild")
    if any(w in t for w in _INJURY_WORDS):
        severity = "moderate" if any(w in t for w in _SEVERE_WORDS) else "mild"
        return ("injury", body_part, severity)
    if any(w in t for w in _SORENESS_ONLY_WORDS):
        return ("soreness", body_part, "mild")
    return (None, body_part, "mild")  # body part named as a focus, not pain


def capture_pain_from_text(user_id: str, text: str):
    """Durably persist a NEW injury mentioned inside a workout request (deduped,
    'mild' default). Returns the captured body_part or None. Best-effort; never
    raises and never blocks workout generation."""
    try:
        kind, body_part, severity = classify_pain_mention(text or "")
        if kind != "injury" or not body_part:
            return None  # soreness / no-pain → handled transiently, not persisted
        db = get_supabase_db()
        active = (db.get_user(user_id) or {}).get("active_injuries") or []
        if isinstance(active, list) and any(
            isinstance(i, dict) and (i.get("body_part") or "").lower() == body_part
            for i in active
        ):
            return None  # already tracked (report_injury also dedups)
        report_injury.invoke({
            "user_id": user_id,
            "body_part": body_part,
            "severity": severity,
            "notes": "auto-captured from a workout request",
        })
        logger.info(f"[InjuryCapture] auto-captured {severity} {body_part} from a workout request")
        return body_part
    except Exception as e:
        logger.warning(f"[InjuryCapture] capture failed (non-fatal): {e}")
        return None


# ── Red-flag safety escalation (F3) ──────────────────────────────────────────
# Symptoms that warrant a professional, not a "gentle workout". Deterministic
# keyword match (feedback_no_llm_for_safety_classification) — never an LLM call.
_RED_FLAG_PHRASES = (
    "numb", "numbness", "tingling", "tingl", "radiating", "shoots down",
    "shooting down", "shooting pain", "can't bear weight", "cant bear weight",
    "can't put weight", "cant put weight", "can't walk", "cant walk",
    "can't feel", "cant feel", "loss of feeling", "gave out", "gave way",
    "heard a pop", "popped", "locked up", "dislocat", "severe swelling",
    "can't move", "cant move", "shooting", "pins and needles",
)


def detect_red_flag(text: str):
    """Return (True, body_part|None) if the text contains a red-flag symptom
    that should pause workout generation and recommend a professional."""
    if not text:
        return (False, None)
    t = text.lower()
    if not any(p in t for p in _RED_FLAG_PHRASES):
        return (False, None)
    try:
        from services.workout_builder import SORE_TO_MUSCLES
        bp = next((k for k in SORE_TO_MUSCLES if k in t), None)
    except Exception:
        bp = None
    return (True, bp)


def red_flag_safety_response(body_part):
    """Standard safety message returned instead of auto-generating a workout."""
    area = f"your {body_part}" if body_part else "that area"
    return (
        f"Those symptoms around {area} (numbness, tingling, shooting/radiating "
        f"pain, or not being able to bear weight) are red flags I shouldn't "
        f"train through. Please get it checked by a doctor or physio before your "
        f"next session. I'll hold off on loading {area} until you're cleared. "
        f"This is general guidance, not medical advice."
    )
