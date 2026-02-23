"""
Program customization API endpoints.

This module handles workout program customization:
- POST /update-program - Update program preferences and delete future workouts
- POST /quick-regenerate - Regenerate workouts with current settings (no wizard)
"""
import json
from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import UpdateProgramRequest, UpdateProgramResponse

from .utils import get_workout_rag_service

router = APIRouter()
logger = get_logger(__name__)


class QuickRegenerateRequest(BaseModel):
    """Request model for quick workout regeneration."""
    user_id: str
    reason: Optional[str] = None  # Optional reason for analytics


class QuickRegenerateResponse(BaseModel):
    """Response model for quick regeneration."""
    success: bool
    message: str
    workouts_deleted: int
    workouts_generated: int


@router.post("/update-program", response_model=UpdateProgramResponse)
async def update_program(request: UpdateProgramRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update user's program preferences and delete future incomplete workouts.

    This endpoint:
    1. Updates the user's preferences in the database
    2. Deletes only future incomplete workouts (is_completed=false AND scheduled_date >= today)
    3. Records the changes for analytics
    4. Returns count of deleted workouts for regeneration

    SAFETY: Never deletes completed workouts or past workouts.
    The frontend should trigger workout regeneration after this succeeds.
    """
    logger.info(f"Updating program for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get current preferences
        current_prefs = user.get("preferences", {})
        if isinstance(current_prefs, str):
            try:
                current_prefs = json.loads(current_prefs)
            except json.JSONDecodeError:
                current_prefs = {}

        # Build updated preferences
        updated_prefs = dict(current_prefs)

        if request.difficulty is not None:
            updated_prefs["intensity_preference"] = request.difficulty
        if request.duration_minutes is not None:
            updated_prefs["workout_duration"] = request.duration_minutes
        if request.workout_type is not None:
            updated_prefs["training_split"] = request.workout_type
        if request.workout_days is not None:
            # Store both days_per_week and workout_days
            updated_prefs["days_per_week"] = len(request.workout_days)
            # Convert day names to indices (Mon=0, Tue=1, etc.)
            day_map = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}
            selected_indices = [day_map.get(d, 0) for d in request.workout_days]
            # Store as workout_days for consistency across backend and Flutter
            updated_prefs["workout_days"] = sorted(selected_indices)
            logger.info(f"Storing workout_days: {sorted(selected_indices)} (0=Mon, 6=Sun)")
        if request.dumbbell_count is not None:
            updated_prefs["dumbbell_count"] = request.dumbbell_count
        if request.kettlebell_count is not None:
            updated_prefs["kettlebell_count"] = request.kettlebell_count
        if request.custom_program_description is not None:
            updated_prefs["custom_program_description"] = request.custom_program_description

        # Update user preferences and equipment/injuries
        update_data = {"preferences": updated_prefs}

        if request.equipment is not None:
            update_data["equipment"] = request.equipment
        if request.injuries is not None:
            update_data["active_injuries"] = request.injuries

        db.update_user(request.user_id, update_data)
        logger.info(f"Updated preferences for user {request.user_id}")

        # Delete only future incomplete workouts
        # CRITICAL: Never delete completed workouts or past workouts
        today = date.today().isoformat()

        # Get all workouts for user
        all_workouts = db.list_workouts(request.user_id, limit=1000)

        # Filter to only future incomplete workouts
        workouts_to_delete = []
        for w in all_workouts:
            scheduled_date = w.get("scheduled_date")
            is_completed = w.get("is_completed", False)

            # Convert scheduled_date to string for comparison
            if hasattr(scheduled_date, 'isoformat'):
                scheduled_date = scheduled_date.isoformat()
            elif hasattr(scheduled_date, 'strftime'):
                scheduled_date = scheduled_date.strftime('%Y-%m-%d')

            # Only delete if: not completed AND scheduled for today or future
            if not is_completed and scheduled_date and scheduled_date >= today:
                workouts_to_delete.append(w)

        logger.info(f"Found {len(workouts_to_delete)} future incomplete workouts to delete")

        # Delete workout changes first (FK constraint)
        for w in workouts_to_delete:
            try:
                db.delete_workout_changes_by_workout(w["id"])
            except Exception as e:
                logger.warning(f"Could not delete workout changes for {w['id']}: {e}")

        # Delete the workouts
        deleted_count = 0
        for w in workouts_to_delete:
            try:
                db.delete_workout(w["id"])
                deleted_count += 1
            except Exception as e:
                logger.error(f"Failed to delete workout {w['id']}: {e}")

        logger.info(f"Deleted {deleted_count} future incomplete workouts for user {request.user_id}")

        # Index preference changes to RAG for AI context
        try:
            rag_service = get_workout_rag_service()
            await rag_service.index_program_preferences(
                user_id=request.user_id,
                difficulty=request.difficulty,
                duration_minutes=request.duration_minutes,
                workout_type=request.workout_type,
                workout_days=request.workout_days,
                equipment=request.equipment,
                focus_areas=request.focus_areas,
                injuries=request.injuries,
                workout_environment=request.workout_environment,
                change_reason="program_customization",
            )
            logger.info(f"Indexed program preferences to RAG for user {request.user_id}")
        except Exception as e:
            logger.warning(f"Could not index preferences to RAG: {e}")

        # Save program snapshot to history
        try:
            snapshot_data = {
                "user_id": request.user_id,
                "preferences": updated_prefs,
                "equipment": request.equipment or [],
                "injuries": request.injuries or [],
                "focus_areas": request.focus_areas or [],
                "program_name": None,  # Auto-generated name could be added
                "description": f"Updated via Customize Program on {date.today().isoformat()}",
                "is_current": True,
                "applied_at": datetime.now().isoformat(),
            }

            # Mark all other programs as not current first
            db.client.table("program_history").update({
                "is_current": False
            }).eq("user_id", request.user_id).eq("is_current", True).execute()

            # Save new snapshot
            db.client.table("program_history").insert(snapshot_data).execute()
            logger.info(f"Saved program snapshot to history for user {request.user_id}")
        except Exception as e:
            logger.warning(f"Could not save program snapshot: {e}")

        return UpdateProgramResponse(
            success=True,
            message=f"Program updated. {deleted_count} future workouts deleted for regeneration.",
            workouts_deleted=deleted_count,
            preferences_updated=True
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update program: {e}")
        raise safe_internal_error(e, "program")


@router.post("/quick-regenerate", response_model=QuickRegenerateResponse)
async def quick_regenerate_workouts(request: QuickRegenerateRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Quick regenerate workouts using current program settings.

    This endpoint:
    1. Deletes future incomplete workouts (same as update-program)
    2. Triggers streaming workout generation with existing preferences
    3. Logs the action for analytics

    Use this when users want fresh workouts without changing their settings.
    """
    logger.info(f"Quick regenerating workouts for user {request.user_id}")
    if request.reason:
        logger.info(f"  Reason: {request.reason}")

    # Log for analytics: User reset program mid-week
    logger.info(f"ANALYTICS: User {request.user_id} reset program mid-week via quick regenerate")

    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Delete only future incomplete workouts (same logic as update-program)
        today = date.today().isoformat()
        all_workouts = db.list_workouts(request.user_id, limit=1000)

        workouts_to_delete = []
        for w in all_workouts:
            scheduled_date = w.get("scheduled_date")
            is_completed = w.get("is_completed", False)

            if hasattr(scheduled_date, 'isoformat'):
                scheduled_date = scheduled_date.isoformat()
            elif hasattr(scheduled_date, 'strftime'):
                scheduled_date = scheduled_date.strftime('%Y-%m-%d')

            if not is_completed and scheduled_date and scheduled_date >= today:
                workouts_to_delete.append(w)

        logger.info(f"Found {len(workouts_to_delete)} future incomplete workouts to delete")

        # Delete workout changes first (FK constraint)
        for w in workouts_to_delete:
            try:
                db.delete_workout_changes_by_workout(w["id"])
            except Exception as e:
                logger.warning(f"Could not delete workout changes for {w['id']}: {e}")

        # Delete the workouts
        deleted_count = 0
        for w in workouts_to_delete:
            try:
                db.delete_workout(w["id"])
                deleted_count += 1
            except Exception as e:
                logger.error(f"Failed to delete workout {w['id']}: {e}")

        logger.info(f"Deleted {deleted_count} future incomplete workouts for user {request.user_id}")

        # Log to user_activity for analytics if the table exists
        try:
            activity_data = {
                "user_id": request.user_id,
                "activity_type": "program_quick_reset",
                "activity_data": {
                    "workouts_deleted": deleted_count,
                    "reason": request.reason or "quick_reset_button",
                    "timestamp": datetime.now().isoformat(),
                },
            }
            db.client.table("user_activity").insert(activity_data).execute()
            logger.info(f"Logged quick reset activity for user {request.user_id}")
        except Exception as e:
            # Table might not exist or other error - don't fail the operation
            logger.warning(f"Could not log activity: {e}")

        # Note: Actual workout generation is done by the frontend using streaming endpoint
        # This endpoint just clears the old workouts and returns success

        return QuickRegenerateResponse(
            success=True,
            message=f"Cleared {deleted_count} workouts. Ready for regeneration.",
            workouts_deleted=deleted_count,
            workouts_generated=0  # Frontend will generate via streaming
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to quick regenerate: {e}")
        raise safe_internal_error(e, "program")
