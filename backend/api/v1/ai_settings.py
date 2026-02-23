"""
AI Settings API endpoints.

Handles CRUD operations for user AI coach personality preferences,
with full analytics tracking for every setting change.
"""
from typing import Optional, List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

logger = get_logger(__name__)
router = APIRouter(prefix="/ai-settings", tags=["AI Settings"])


# =====================================================
# Pydantic Models
# =====================================================

class AISettingsBase(BaseModel):
    """Base AI settings model."""
    # Coach Persona
    coach_persona_id: Optional[str] = Field(default=None, description="Selected coach persona ID (e.g., 'coach_mike', 'custom')")
    coach_name: Optional[str] = Field(default=None, description="Display name for the coach")
    is_custom_coach: Optional[bool] = Field(default=False, description="Whether using a custom coach configuration")

    # Personality & Tone
    coaching_style: Optional[str] = Field(default="motivational", description="Coaching personality style")
    communication_tone: Optional[str] = Field(default="encouraging", description="Communication tone")
    encouragement_level: Optional[float] = Field(default=0.7, ge=0.0, le=1.0, description="Encouragement level 0-1")
    response_length: Optional[str] = Field(default="balanced", description="Response verbosity")
    use_emojis: Optional[bool] = Field(default=True, description="Include emojis in responses")
    include_tips: Optional[bool] = Field(default=True, description="Include helpful tips")
    form_reminders: Optional[bool] = Field(default=True, description="Remind about exercise form")
    rest_day_suggestions: Optional[bool] = Field(default=True, description="Suggest rest days")
    nutrition_mentions: Optional[bool] = Field(default=True, description="Mention nutrition")
    injury_sensitivity: Optional[bool] = Field(default=True, description="Be mindful of injuries")
    save_chat_history: Optional[bool] = Field(default=True, description="Save chat history")
    use_rag: Optional[bool] = Field(default=True, description="Use RAG for context")
    default_agent: Optional[str] = Field(default="coach", description="Default agent type")
    enabled_agents: Optional[dict] = Field(
        default={"coach": True, "nutrition": True, "workout": True, "injury": True, "hydration": True},
        description="Which agents are enabled"
    )


class AISettingsUpdate(AISettingsBase):
    """Model for updating AI settings."""
    change_source: Optional[str] = Field(default="app", description="Source of change")
    device_platform: Optional[str] = Field(default=None, description="Device platform")
    app_version: Optional[str] = Field(default=None, description="App version")


class AISettingsResponse(AISettingsBase):
    """Response model for AI settings."""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime


class SettingChangeRecord(BaseModel):
    """Record of a single setting change."""
    id: str
    setting_name: str
    old_value: Optional[str]
    new_value: str
    change_source: Optional[str]
    changed_at: datetime
    device_platform: Optional[str]
    app_version: Optional[str]


class AISettingsHistoryResponse(BaseModel):
    """Response model for settings history."""
    changes: List[SettingChangeRecord]
    total_count: int


class PopularSettingsResponse(BaseModel):
    """Response model for popular settings analytics."""
    coaching_style: str
    communication_tone: str
    response_length: str
    user_count: int
    avg_encouragement: float
    emoji_users: int
    tips_users: int


# =====================================================
# API Endpoints
# =====================================================

@router.get("/{user_id}", response_model=AISettingsResponse)
async def get_ai_settings(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get AI settings for a user.
    Creates default settings if none exist.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        supabase = get_supabase().client

        # Try to get existing settings
        result = supabase.table("user_ai_settings").select("*").eq("user_id", user_id).execute()

        if result.data and len(result.data) > 0:
            return AISettingsResponse(**result.data[0])

        # Create default settings if none exist
        default_settings = {
            "user_id": user_id,
            "coaching_style": "motivational",
            "communication_tone": "encouraging",
            "encouragement_level": 0.7,
            "response_length": "balanced",
            "use_emojis": True,
            "include_tips": True,
            "form_reminders": True,
            "rest_day_suggestions": True,
            "nutrition_mentions": True,
            "injury_sensitivity": True,
            "save_chat_history": True,
            "use_rag": True,
            "default_agent": "coach",
            "enabled_agents": {"coach": True, "nutrition": True, "workout": True, "injury": True, "hydration": True},
        }

        insert_result = supabase.table("user_ai_settings").insert(default_settings).execute()

        if insert_result.data:
            logger.info(f"Created default AI settings for user {user_id}")
            return AISettingsResponse(**insert_result.data[0])

        raise HTTPException(status_code=500, detail="Failed to create default settings")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting AI settings for user {user_id}: {e}")
        raise safe_internal_error(e, "get_ai_settings")


@router.put("/{user_id}", response_model=AISettingsResponse)
async def update_ai_settings(user_id: str, settings: AISettingsUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update AI settings for a user.
    Tracks all changes in history for analytics.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        supabase = get_supabase().client

        # Get current settings for comparison
        current = supabase.table("user_ai_settings").select("*").eq("user_id", user_id).execute()

        # Build update data (only non-None fields)
        update_data = {}
        settings_dict = settings.model_dump(exclude_none=True, exclude={"change_source", "device_platform", "app_version"})

        for key, value in settings_dict.items():
            update_data[key] = value

        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Track changes in history
        if current.data and len(current.data) > 0:
            old_settings = current.data[0]

            for key, new_value in settings_dict.items():
                old_value = old_settings.get(key)

                # Convert for comparison (handle bools and floats)
                if isinstance(new_value, bool):
                    old_str = str(old_value).lower() if old_value is not None else None
                    new_str = str(new_value).lower()
                elif isinstance(new_value, float):
                    old_str = str(old_value) if old_value is not None else None
                    new_str = str(new_value)
                elif isinstance(new_value, dict):
                    # Skip dict comparison for now (enabled_agents)
                    continue
                else:
                    old_str = str(old_value) if old_value is not None else None
                    new_str = str(new_value)

                if old_str != new_str:
                    # Record the change
                    history_record = {
                        "user_id": user_id,
                        "setting_name": key,
                        "old_value": old_str,
                        "new_value": new_str,
                        "change_source": settings.change_source or "app",
                        "device_platform": settings.device_platform,
                        "app_version": settings.app_version,
                    }
                    supabase.table("ai_settings_history").insert(history_record).execute()
                    logger.info(f"Recorded AI settings change for user {user_id}: {key} = {new_str}")

            # Update existing settings
            result = supabase.table("user_ai_settings").update(update_data).eq("user_id", user_id).execute()
        else:
            # Create new settings record
            update_data["user_id"] = user_id
            result = supabase.table("user_ai_settings").insert(update_data).execute()

            # Record initial setup in history
            for key, value in settings_dict.items():
                if not isinstance(value, dict):
                    history_record = {
                        "user_id": user_id,
                        "setting_name": key,
                        "old_value": None,
                        "new_value": str(value),
                        "change_source": settings.change_source or "app",
                        "device_platform": settings.device_platform,
                        "app_version": settings.app_version,
                    }
                    supabase.table("ai_settings_history").insert(history_record).execute()

        if result.data:
            # Log AI settings update
            await log_user_activity(
                user_id=user_id,
                action="ai_settings_updated",
                endpoint=f"/api/v1/ai-settings/{user_id}",
                message=f"Updated AI coach settings",
                metadata={"changed_fields": list(settings_dict.keys())},
                status_code=200
            )
            return AISettingsResponse(**result.data[0])

        raise HTTPException(status_code=500, detail="Failed to update settings")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating AI settings for user {user_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="ai_settings_update",
            error=e,
            endpoint=f"/api/v1/ai-settings/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "update_ai_settings")


@router.get("/{user_id}/history", response_model=AISettingsHistoryResponse)
async def get_ai_settings_history(
    user_id: str,
    setting_name: Optional[str] = Query(None, description="Filter by setting name"),
    limit: int = Query(50, ge=1, le=500, description="Number of records to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI settings change history for a user.
    Useful for analyzing user behavior and preferences over time.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        supabase = get_supabase().client

        query = supabase.table("ai_settings_history").select("*", count="exact").eq("user_id", user_id)

        if setting_name:
            query = query.eq("setting_name", setting_name)

        result = query.order("changed_at", desc=True).range(offset, offset + limit - 1).execute()

        changes = [SettingChangeRecord(**record) for record in result.data] if result.data else []

        return AISettingsHistoryResponse(
            changes=changes,
            total_count=result.count or 0
        )

    except Exception as e:
        logger.error(f"Error getting AI settings history for user {user_id}: {e}")
        raise safe_internal_error(e, "get_ai_settings_history")


@router.delete("/{user_id}")
async def reset_ai_settings(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Reset AI settings to defaults for a user.
    Records the reset in history.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        supabase = get_supabase().client

        # Get current settings before reset
        current = supabase.table("user_ai_settings").select("*").eq("user_id", user_id).execute()

        # Delete current settings
        supabase.table("user_ai_settings").delete().eq("user_id", user_id).execute()

        # Record reset in history
        if current.data and len(current.data) > 0:
            history_record = {
                "user_id": user_id,
                "setting_name": "all_settings",
                "old_value": "custom",
                "new_value": "reset_to_defaults",
                "change_source": "app",
            }
            supabase.table("ai_settings_history").insert(history_record).execute()

        logger.info(f"Reset AI settings to defaults for user {user_id}")

        # Log AI settings reset
        await log_user_activity(
            user_id=user_id,
            action="ai_settings_reset",
            endpoint=f"/api/v1/ai-settings/{user_id}",
            message="Reset AI coach settings to defaults",
            status_code=200
        )

        return {"success": True, "message": "AI settings reset to defaults"}

    except Exception as e:
        logger.error(f"Error resetting AI settings for user {user_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="ai_settings_reset",
            error=e,
            endpoint=f"/api/v1/ai-settings/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "reset_ai_settings")


# =====================================================
# Analytics Endpoints
# =====================================================

@router.get("/analytics/popular")
async def get_popular_settings():
    """
    Get popular AI settings combinations across all users.
    For admin/analytics dashboard.
    """
    try:
        supabase = get_supabase().client

        # Use the view we created
        result = supabase.table("ai_settings_popularity").select("*").execute()

        return {"popularity": result.data if result.data else []}

    except Exception as e:
        logger.error(f"Error getting popular settings analytics: {e}")
        raise safe_internal_error(e, "ai_settings_analytics")


@router.get("/analytics/trends")
async def get_settings_trends(days: int = Query(30, ge=1, le=365, description="Number of days to analyze")):
    """
    Get AI settings change trends over time.
    For admin/analytics dashboard.
    """
    try:
        supabase = get_supabase().client

        # Query the trends view
        result = supabase.table("ai_settings_change_trends").select("*").execute()

        return {"trends": result.data if result.data else []}

    except Exception as e:
        logger.error(f"Error getting settings trends: {e}")
        raise safe_internal_error(e, "ai_settings_analytics")


@router.get("/analytics/engagement")
async def get_engagement_by_style():
    """
    Get user engagement metrics grouped by AI personality style.
    For admin/analytics dashboard.
    """
    try:
        supabase = get_supabase().client

        result = supabase.table("user_engagement_by_ai_style").select("*").execute()

        return {"engagement": result.data if result.data else []}

    except Exception as e:
        logger.error(f"Error getting engagement analytics: {e}")
        raise safe_internal_error(e, "ai_settings_analytics")
