"""
Audio Preferences API endpoints.

Manages user audio preferences for workout sessions including:
- Background music compatibility
- TTS (text-to-speech) volume
- Audio ducking behavior
- Video mute preferences

ENDPOINTS:
- GET  /api/v1/audio-preferences/{user_id} - Get user's audio preferences
- PUT  /api/v1/audio-preferences/{user_id} - Update user's audio preferences
- POST /api/v1/audio-preferences/{user_id} - Create default preferences if none exist
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Pydantic Models
# ============================================

class AudioPreferences(BaseModel):
    """User audio preferences model."""
    allow_background_music: bool = Field(
        default=True,
        description="Whether to allow background music during workouts"
    )
    tts_volume: float = Field(
        default=0.8,
        ge=0.0,
        le=1.0,
        description="Text-to-speech volume level (0-1)"
    )
    audio_ducking: bool = Field(
        default=True,
        description="Whether to duck (lower) background audio during TTS announcements"
    )
    duck_volume_level: float = Field(
        default=0.3,
        ge=0.0,
        le=1.0,
        description="Volume level for ducked audio (0-1)"
    )
    mute_during_video: bool = Field(
        default=False,
        description="Whether to mute TTS during exercise video playback"
    )


class AudioPreferencesResponse(BaseModel):
    """Response model for audio preferences."""
    user_id: str
    allow_background_music: bool
    tts_volume: float
    audio_ducking: bool
    duck_volume_level: float
    mute_during_video: bool
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class AudioPreferencesUpdate(BaseModel):
    """Request model for updating audio preferences."""
    allow_background_music: Optional[bool] = None
    tts_volume: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    audio_ducking: Optional[bool] = None
    duck_volume_level: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    mute_during_video: Optional[bool] = None


# ============================================
# Helper Functions
# ============================================

def get_default_preferences() -> dict:
    """Get default audio preferences."""
    return {
        "allow_background_music": True,
        "tts_volume": 0.8,
        "audio_ducking": True,
        "duck_volume_level": 0.3,
        "mute_during_video": False,
    }


# ============================================
# API Endpoints
# ============================================

@router.get("/{user_id}", response_model=AudioPreferencesResponse)
async def get_audio_preferences(user_id: str):
    """
    Get user's audio preferences.

    Returns the user's audio preferences if they exist,
    otherwise returns default preferences.
    """
    logger.info(f"Getting audio preferences for user {user_id}")

    try:
        supabase = get_supabase()

        # Query audio preferences for user
        result = supabase.client.table("audio_preferences").select(
            "user_id, allow_background_music, tts_volume, audio_ducking, "
            "duck_volume_level, mute_during_video, created_at, updated_at"
        ).eq("user_id", user_id).execute()

        if result.data and len(result.data) > 0:
            prefs = result.data[0]
            logger.info(f"Found audio preferences for user {user_id}")
            return AudioPreferencesResponse(
                user_id=prefs["user_id"],
                allow_background_music=prefs.get("allow_background_music", True),
                tts_volume=prefs.get("tts_volume", 0.8),
                audio_ducking=prefs.get("audio_ducking", True),
                duck_volume_level=prefs.get("duck_volume_level", 0.3),
                mute_during_video=prefs.get("mute_during_video", False),
                created_at=prefs.get("created_at"),
                updated_at=prefs.get("updated_at"),
            )
        else:
            # Return default preferences (not stored yet)
            logger.info(f"No audio preferences found for user {user_id}, returning defaults")
            defaults = get_default_preferences()
            return AudioPreferencesResponse(
                user_id=user_id,
                **defaults
            )

    except Exception as e:
        logger.error(f"Failed to get audio preferences for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}", response_model=AudioPreferencesResponse)
async def update_audio_preferences(user_id: str, update: AudioPreferencesUpdate):
    """
    Update user's audio preferences.

    Only updates the fields that are provided.
    Creates preferences if they don't exist.
    """
    logger.info(f"Updating audio preferences for user {user_id}")

    try:
        supabase = get_supabase()
        now = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing_result = supabase.client.table("audio_preferences").select(
            "user_id, allow_background_music"
        ).eq("user_id", user_id).execute()

        # Get current background music setting for logging
        old_background_music = None
        if existing_result.data and len(existing_result.data) > 0:
            old_background_music = existing_result.data[0].get("allow_background_music", True)

        # Build update data (only non-None fields)
        update_data = {}
        if update.allow_background_music is not None:
            update_data["allow_background_music"] = update.allow_background_music
        if update.tts_volume is not None:
            update_data["tts_volume"] = update.tts_volume
        if update.audio_ducking is not None:
            update_data["audio_ducking"] = update.audio_ducking
        if update.duck_volume_level is not None:
            update_data["duck_volume_level"] = update.duck_volume_level
        if update.mute_during_video is not None:
            update_data["mute_during_video"] = update.mute_during_video

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        update_data["updated_at"] = now

        if existing_result.data and len(existing_result.data) > 0:
            # Update existing preferences
            result = supabase.client.table("audio_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            # Insert new preferences with defaults for non-provided fields
            defaults = get_default_preferences()
            insert_data = {
                **defaults,
                **update_data,
                "user_id": user_id,
                "created_at": now,
            }
            result = supabase.client.table("audio_preferences").insert(
                insert_data
            ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update audio preferences")

        prefs = result.data[0]
        logger.info(f"Updated audio preferences for user {user_id}")

        # Log user context for background music preference changes
        if update.allow_background_music is not None and old_background_music != update.allow_background_music:
            if update.allow_background_music:
                message = "Enabled background music support"
            else:
                message = "Disabled background music support"

            await log_user_activity(
                user_id=user_id,
                action="audio_preferences_updated",
                endpoint=f"/api/v1/audio-preferences/{user_id}",
                message=message,
                metadata={
                    "allow_background_music": update.allow_background_music,
                    "previous_value": old_background_music,
                    "tts_volume": prefs.get("tts_volume"),
                    "audio_ducking": prefs.get("audio_ducking"),
                },
                status_code=200
            )
            logger.info(f"Logged audio preference change: {message} for user {user_id}")

        return AudioPreferencesResponse(
            user_id=prefs["user_id"],
            allow_background_music=prefs.get("allow_background_music", True),
            tts_volume=prefs.get("tts_volume", 0.8),
            audio_ducking=prefs.get("audio_ducking", True),
            duck_volume_level=prefs.get("duck_volume_level", 0.3),
            mute_during_video=prefs.get("mute_during_video", False),
            created_at=prefs.get("created_at"),
            updated_at=prefs.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update audio preferences for user {user_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="audio_preferences_updated",
            error=e,
            endpoint=f"/api/v1/audio-preferences/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}", response_model=AudioPreferencesResponse)
async def create_audio_preferences(user_id: str, preferences: Optional[AudioPreferences] = None):
    """
    Create default audio preferences for a user.

    If preferences already exist, returns the existing ones.
    If custom preferences are provided, uses those instead of defaults.
    """
    logger.info(f"Creating audio preferences for user {user_id}")

    try:
        supabase = get_supabase()
        now = datetime.utcnow().isoformat()

        # Check if preferences already exist
        existing_result = supabase.client.table("audio_preferences").select(
            "user_id, allow_background_music, tts_volume, audio_ducking, "
            "duck_volume_level, mute_during_video, created_at, updated_at"
        ).eq("user_id", user_id).execute()

        if existing_result.data and len(existing_result.data) > 0:
            # Return existing preferences
            prefs = existing_result.data[0]
            logger.info(f"Audio preferences already exist for user {user_id}")
            return AudioPreferencesResponse(
                user_id=prefs["user_id"],
                allow_background_music=prefs.get("allow_background_music", True),
                tts_volume=prefs.get("tts_volume", 0.8),
                audio_ducking=prefs.get("audio_ducking", True),
                duck_volume_level=prefs.get("duck_volume_level", 0.3),
                mute_during_video=prefs.get("mute_during_video", False),
                created_at=prefs.get("created_at"),
                updated_at=prefs.get("updated_at"),
            )

        # Use provided preferences or defaults
        if preferences:
            insert_data = {
                "user_id": user_id,
                "allow_background_music": preferences.allow_background_music,
                "tts_volume": preferences.tts_volume,
                "audio_ducking": preferences.audio_ducking,
                "duck_volume_level": preferences.duck_volume_level,
                "mute_during_video": preferences.mute_during_video,
                "created_at": now,
                "updated_at": now,
            }
        else:
            insert_data = {
                "user_id": user_id,
                **get_default_preferences(),
                "created_at": now,
                "updated_at": now,
            }

        result = supabase.client.table("audio_preferences").insert(
            insert_data
        ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create audio preferences")

        prefs = result.data[0]
        logger.info(f"Created audio preferences for user {user_id}")

        # Log the creation
        await log_user_activity(
            user_id=user_id,
            action="audio_preferences_created",
            endpoint=f"/api/v1/audio-preferences/{user_id}",
            message="Created audio preferences",
            metadata={
                "allow_background_music": prefs.get("allow_background_music"),
                "tts_volume": prefs.get("tts_volume"),
                "audio_ducking": prefs.get("audio_ducking"),
                "duck_volume_level": prefs.get("duck_volume_level"),
                "mute_during_video": prefs.get("mute_during_video"),
            },
            status_code=201
        )

        return AudioPreferencesResponse(
            user_id=prefs["user_id"],
            allow_background_music=prefs.get("allow_background_music", True),
            tts_volume=prefs.get("tts_volume", 0.8),
            audio_ducking=prefs.get("audio_ducking", True),
            duck_volume_level=prefs.get("duck_volume_level", 0.3),
            mute_during_video=prefs.get("mute_during_video", False),
            created_at=prefs.get("created_at"),
            updated_at=prefs.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create audio preferences for user {user_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="audio_preferences_created",
            error=e,
            endpoint=f"/api/v1/audio-preferences/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))
