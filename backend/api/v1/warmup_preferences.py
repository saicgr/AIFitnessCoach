"""
Warmup & Stretch Preferences API - Custom pre/post workout routines.

This module allows users to:
1. Set custom pre-workout routines (e.g., "10min inclined treadmill walk")
2. Set custom post-exercise routines (e.g., "5min cooldown walk")
3. Specify preferred warmups to always include
4. Specify avoided warmups to never include
5. Specify preferred stretches to always include
6. Specify avoided stretches to never include
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import logging

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/warmup-preferences", tags=["Warmup Preferences"])


# =============================================================================
# Request/Response Models
# =============================================================================

class ExerciseRoutineItem(BaseModel):
    """A single exercise in a custom routine."""
    name: str = Field(..., min_length=1, max_length=200)
    duration_minutes: Optional[int] = Field(default=5, ge=1, le=60)
    reps: Optional[int] = Field(default=None, ge=1, le=100)
    settings: Optional[Dict[str, Any]] = None  # e.g., {"incline": 3.0, "speed_mph": 3.0}
    equipment: Optional[str] = None
    notes: Optional[str] = Field(default=None, max_length=200)


class WarmupPreferencesUpdate(BaseModel):
    """Request to update warmup/stretch preferences."""
    pre_workout_routine: Optional[List[ExerciseRoutineItem]] = None
    post_exercise_routine: Optional[List[ExerciseRoutineItem]] = None
    preferred_warmups: Optional[List[str]] = None
    avoided_warmups: Optional[List[str]] = None
    preferred_stretches: Optional[List[str]] = None
    avoided_stretches: Optional[List[str]] = None


class WarmupPreferencesResponse(BaseModel):
    """Response with current warmup/stretch preferences."""
    id: Optional[str] = None
    user_id: str
    pre_workout_routine: List[Dict[str, Any]] = []
    post_exercise_routine: List[Dict[str, Any]] = []
    preferred_warmups: List[str] = []
    avoided_warmups: List[str] = []
    preferred_stretches: List[str] = []
    avoided_stretches: List[str] = []
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


# =============================================================================
# API Endpoints
# =============================================================================

@router.get("/{user_id}", response_model=WarmupPreferencesResponse)
async def get_warmup_preferences(user_id: str):
    """Get user's warmup/stretch preferences."""
    db = get_supabase_db()

    try:
        result = db.client.table("warmup_stretch_preferences").select("*").eq(
            "user_id", user_id
        ).limit(1).execute()

        if result.data:
            prefs = result.data[0]
            return WarmupPreferencesResponse(
                id=prefs.get("id"),
                user_id=user_id,
                pre_workout_routine=prefs.get("pre_workout_routine", []),
                post_exercise_routine=prefs.get("post_exercise_routine", []),
                preferred_warmups=prefs.get("preferred_warmups", []),
                avoided_warmups=prefs.get("avoided_warmups", []),
                preferred_stretches=prefs.get("preferred_stretches", []),
                avoided_stretches=prefs.get("avoided_stretches", []),
                created_at=prefs.get("created_at"),
                updated_at=prefs.get("updated_at"),
            )
        else:
            # Return empty preferences if none exist
            return WarmupPreferencesResponse(user_id=user_id)

    except Exception as e:
        logger.error(f"❌ Failed to get warmup preferences for {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}", response_model=WarmupPreferencesResponse)
async def update_warmup_preferences(user_id: str, request: WarmupPreferencesUpdate):
    """Update user's warmup/stretch preferences (upsert)."""
    db = get_supabase_db()

    try:
        # Build update data (only include non-None values)
        update_data = {"user_id": user_id}

        if request.pre_workout_routine is not None:
            update_data["pre_workout_routine"] = [item.model_dump() for item in request.pre_workout_routine]

        if request.post_exercise_routine is not None:
            update_data["post_exercise_routine"] = [item.model_dump() for item in request.post_exercise_routine]

        if request.preferred_warmups is not None:
            update_data["preferred_warmups"] = request.preferred_warmups

        if request.avoided_warmups is not None:
            update_data["avoided_warmups"] = request.avoided_warmups

        if request.preferred_stretches is not None:
            update_data["preferred_stretches"] = request.preferred_stretches

        if request.avoided_stretches is not None:
            update_data["avoided_stretches"] = request.avoided_stretches

        # Upsert (insert or update)
        result = db.client.table("warmup_stretch_preferences").upsert(
            update_data,
            on_conflict="user_id"
        ).execute()

        if result.data:
            prefs = result.data[0]
            logger.info(f"✅ Updated warmup preferences for user {user_id}")
            return WarmupPreferencesResponse(
                id=prefs.get("id"),
                user_id=user_id,
                pre_workout_routine=prefs.get("pre_workout_routine", []),
                post_exercise_routine=prefs.get("post_exercise_routine", []),
                preferred_warmups=prefs.get("preferred_warmups", []),
                avoided_warmups=prefs.get("avoided_warmups", []),
                preferred_stretches=prefs.get("preferred_stretches", []),
                avoided_stretches=prefs.get("avoided_stretches", []),
                created_at=prefs.get("created_at"),
                updated_at=prefs.get("updated_at"),
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to save preferences")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to update warmup preferences for {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/pre-workout", response_model=WarmupPreferencesResponse)
async def add_pre_workout_exercise(user_id: str, exercise: ExerciseRoutineItem):
    """Add an exercise to the pre-workout routine."""
    db = get_supabase_db()

    try:
        # Get current preferences
        result = db.client.table("warmup_stretch_preferences").select("*").eq(
            "user_id", user_id
        ).limit(1).execute()

        current_routine = []
        if result.data:
            current_routine = result.data[0].get("pre_workout_routine", [])

        # Add new exercise
        current_routine.append(exercise.model_dump())

        # Upsert
        result = db.client.table("warmup_stretch_preferences").upsert({
            "user_id": user_id,
            "pre_workout_routine": current_routine
        }, on_conflict="user_id").execute()

        if result.data:
            prefs = result.data[0]
            logger.info(f"✅ Added pre-workout exercise for user {user_id}: {exercise.name}")
            return WarmupPreferencesResponse(
                id=prefs.get("id"),
                user_id=user_id,
                pre_workout_routine=prefs.get("pre_workout_routine", []),
                post_exercise_routine=prefs.get("post_exercise_routine", []),
                preferred_warmups=prefs.get("preferred_warmups", []),
                avoided_warmups=prefs.get("avoided_warmups", []),
                preferred_stretches=prefs.get("preferred_stretches", []),
                avoided_stretches=prefs.get("avoided_stretches", []),
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to add exercise")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to add pre-workout exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/post-exercise", response_model=WarmupPreferencesResponse)
async def add_post_exercise(user_id: str, exercise: ExerciseRoutineItem):
    """Add an exercise to the post-exercise (cooldown) routine."""
    db = get_supabase_db()

    try:
        # Get current preferences
        result = db.client.table("warmup_stretch_preferences").select("*").eq(
            "user_id", user_id
        ).limit(1).execute()

        current_routine = []
        if result.data:
            current_routine = result.data[0].get("post_exercise_routine", [])

        # Add new exercise
        current_routine.append(exercise.model_dump())

        # Upsert
        result = db.client.table("warmup_stretch_preferences").upsert({
            "user_id": user_id,
            "post_exercise_routine": current_routine
        }, on_conflict="user_id").execute()

        if result.data:
            prefs = result.data[0]
            logger.info(f"✅ Added post-exercise for user {user_id}: {exercise.name}")
            return WarmupPreferencesResponse(
                id=prefs.get("id"),
                user_id=user_id,
                pre_workout_routine=prefs.get("pre_workout_routine", []),
                post_exercise_routine=prefs.get("post_exercise_routine", []),
                preferred_warmups=prefs.get("preferred_warmups", []),
                avoided_warmups=prefs.get("avoided_warmups", []),
                preferred_stretches=prefs.get("preferred_stretches", []),
                avoided_stretches=prefs.get("avoided_stretches", []),
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to add exercise")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to add post-exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/pre-workout/{index}")
async def remove_pre_workout_exercise(user_id: str, index: int):
    """Remove an exercise from the pre-workout routine by index."""
    db = get_supabase_db()

    try:
        # Get current preferences
        result = db.client.table("warmup_stretch_preferences").select("*").eq(
            "user_id", user_id
        ).limit(1).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No preferences found")

        current_routine = result.data[0].get("pre_workout_routine", [])

        if index < 0 or index >= len(current_routine):
            raise HTTPException(status_code=400, detail="Invalid index")

        # Remove exercise
        removed = current_routine.pop(index)

        # Update
        db.client.table("warmup_stretch_preferences").update({
            "pre_workout_routine": current_routine
        }).eq("user_id", user_id).execute()

        logger.info(f"✅ Removed pre-workout exercise at index {index} for user {user_id}")
        return {"message": f"Removed exercise: {removed.get('name', 'Unknown')}"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to remove pre-workout exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/post-exercise/{index}")
async def remove_post_exercise(user_id: str, index: int):
    """Remove an exercise from the post-exercise routine by index."""
    db = get_supabase_db()

    try:
        # Get current preferences
        result = db.client.table("warmup_stretch_preferences").select("*").eq(
            "user_id", user_id
        ).limit(1).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No preferences found")

        current_routine = result.data[0].get("post_exercise_routine", [])

        if index < 0 or index >= len(current_routine):
            raise HTTPException(status_code=400, detail="Invalid index")

        # Remove exercise
        removed = current_routine.pop(index)

        # Update
        db.client.table("warmup_stretch_preferences").update({
            "post_exercise_routine": current_routine
        }).eq("user_id", user_id).execute()

        logger.info(f"✅ Removed post-exercise at index {index} for user {user_id}")
        return {"message": f"Removed exercise: {removed.get('name', 'Unknown')}"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to remove post-exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}")
async def clear_warmup_preferences(user_id: str):
    """Clear all warmup/stretch preferences for a user."""
    db = get_supabase_db()

    try:
        db.client.table("warmup_stretch_preferences").delete().eq(
            "user_id", user_id
        ).execute()

        logger.info(f"✅ Cleared warmup preferences for user {user_id}")
        return {"message": "Preferences cleared"}

    except Exception as e:
        logger.error(f"❌ Failed to clear warmup preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))
