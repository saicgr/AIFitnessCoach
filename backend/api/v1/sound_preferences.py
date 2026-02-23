"""API endpoints for sound preferences management."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Literal
from core.auth import get_current_user
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.exceptions import safe_internal_error

logger = get_logger(__name__)
router = APIRouter(prefix="/sound-preferences", tags=["Sound Preferences"])


class SoundPreferences(BaseModel):
    """Sound preferences model."""
    countdown_sound_enabled: bool = True
    countdown_sound_type: Literal["beep", "chime", "voice", "tick", "none"] = "beep"
    completion_sound_enabled: bool = True
    completion_sound_type: Literal["chime", "bell", "success", "fanfare", "none"] = "chime"
    # NOTE: No "applause" option - user specifically hated it
    rest_timer_sound_enabled: bool = True
    rest_timer_sound_type: Literal["beep", "chime", "voice", "tick", "none"] = "beep"
    # Exercise completion sound - plays when all sets of an exercise are done
    exercise_completion_sound_enabled: bool = True
    exercise_completion_sound_type: Literal["chime", "bell", "ding", "pop", "whoosh", "none"] = "chime"
    sound_effects_volume: float = Field(default=0.8, ge=0.0, le=1.0)


class SoundPreferencesUpdate(BaseModel):
    """Update model for sound preferences."""
    countdown_sound_enabled: Optional[bool] = None
    countdown_sound_type: Optional[Literal["beep", "chime", "voice", "tick", "none"]] = None
    completion_sound_enabled: Optional[bool] = None
    completion_sound_type: Optional[Literal["chime", "bell", "success", "fanfare", "none"]] = None
    rest_timer_sound_enabled: Optional[bool] = None
    rest_timer_sound_type: Optional[Literal["beep", "chime", "voice", "tick", "none"]] = None
    exercise_completion_sound_enabled: Optional[bool] = None
    exercise_completion_sound_type: Optional[Literal["chime", "bell", "ding", "pop", "whoosh", "none"]] = None
    sound_effects_volume: Optional[float] = Field(default=None, ge=0.0, le=1.0)


@router.get("", response_model=SoundPreferences)
async def get_sound_preferences(user=Depends(get_current_user)):
    """Get user's sound preferences."""
    try:
        supabase = get_supabase().client
        result = supabase.table("sound_preferences").select("*").eq(
            "user_id", user["id"]
        ).execute()

        if result.data and len(result.data) > 0:
            prefs = result.data[0]
            return SoundPreferences(
                countdown_sound_enabled=prefs.get("countdown_sound_enabled", True),
                countdown_sound_type=prefs.get("countdown_sound_type", "beep"),
                completion_sound_enabled=prefs.get("completion_sound_enabled", True),
                completion_sound_type=prefs.get("completion_sound_type", "chime"),
                rest_timer_sound_enabled=prefs.get("rest_timer_sound_enabled", True),
                rest_timer_sound_type=prefs.get("rest_timer_sound_type", "beep"),
                exercise_completion_sound_enabled=prefs.get("exercise_completion_sound_enabled", True),
                exercise_completion_sound_type=prefs.get("exercise_completion_sound_type", "chime"),
                sound_effects_volume=prefs.get("sound_effects_volume", 0.8),
            )

        # Return defaults if no preferences exist
        return SoundPreferences()

    except Exception as e:
        logger.error(f"❌ Failed to get sound preferences: {e}")
        raise safe_internal_error(e, "sound_preferences")


@router.put("", response_model=SoundPreferences)
async def update_sound_preferences(
    update: SoundPreferencesUpdate,
    user=Depends(get_current_user)
):
    """Update user's sound preferences."""
    try:
        supabase = get_supabase().client
        user_id = user["id"]

        # Build update data (only include non-None values)
        update_data = {k: v for k, v in update.model_dump().items() if v is not None}

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        # Check if preferences exist
        existing = supabase.table("sound_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        if existing.data and len(existing.data) > 0:
            # Update existing
            result = supabase.table("sound_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            # Insert new
            update_data["user_id"] = user_id
            result = supabase.table("sound_preferences").insert(update_data).execute()

        # Log user activity for context tracking
        try:
            supabase.table("user_activity_log").insert({
                "user_id": user_id,
                "activity_type": "sound_preferences_updated",
                "metadata": update_data
            }).execute()
        except Exception:
            pass  # Don't fail if logging fails

        logger.info(f"✅ Updated sound preferences for user {user_id}: {update_data}")

        # Fetch and return updated preferences
        return await get_sound_preferences(user)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to update sound preferences: {e}")
        raise safe_internal_error(e, "sound_preferences")


@router.post("/reset")
async def reset_sound_preferences(user=Depends(get_current_user)):
    """Reset sound preferences to defaults."""
    try:
        supabase = get_supabase().client
        user_id = user["id"]

        # Delete existing preferences (will use defaults)
        supabase.table("sound_preferences").delete().eq("user_id", user_id).execute()

        logger.info(f"✅ Reset sound preferences to defaults for user {user_id}")

        return {"message": "Sound preferences reset to defaults"}

    except Exception as e:
        logger.error(f"❌ Failed to reset sound preferences: {e}")
        raise safe_internal_error(e, "sound_preferences")
