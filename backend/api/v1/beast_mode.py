"""
Beast Mode configuration API endpoints.

Handles CRUD operations for user beast mode preferences
(custom sets, reps, rest, intensity, preferred/avoided exercises).
"""
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter

logger = get_logger(__name__)
router = APIRouter()


# =====================================================
# Pydantic Models
# =====================================================

class BeastModeConfig(BaseModel):
    """Beast mode configuration schema."""
    enabled: bool = Field(default=False, description="Whether beast mode is active")
    target_sets: Optional[int] = Field(default=None, ge=1, le=20, description="Target sets per exercise")
    target_reps: Optional[str] = Field(default=None, max_length=50, description="Target reps per set (e.g., '8-12', '5')")
    rest_seconds: Optional[int] = Field(default=None, ge=10, le=600, description="Rest between sets in seconds")
    intensity_level: Optional[str] = Field(default=None, max_length=50, description="Intensity level (e.g., 'moderate', 'high', 'max')")
    preferred_exercises: Optional[list] = Field(default=None, max_length=50, description="Preferred exercises list")
    avoided_exercises: Optional[list] = Field(default=None, max_length=50, description="Exercises to avoid")
    notes: Optional[str] = Field(default=None, max_length=500, description="Additional notes for the AI coach")


class BeastModeResponse(BaseModel):
    """Response model for beast mode config."""
    config: Optional[Dict[str, Any]] = None
    message: str


# =====================================================
# API Endpoints
# =====================================================

@router.get("/config")
@limiter.limit("30/minute")
async def get_beast_mode_config(
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Get beast mode configuration for the current user.
    Returns null config if not set.
    """
    user_id = str(current_user["id"])
    try:
        supabase = get_supabase().client

        result = supabase.table("user_settings").select(
            "beast_mode_config"
        ).eq("user_id", user_id).maybe_single().execute()

        config = None
        if result and result.data:
            config = result.data.get("beast_mode_config")

        return BeastModeResponse(
            config=config,
            message="Beast mode config retrieved" if config else "No beast mode config set",
        )

    except Exception as e:
        logger.error(f"Error getting beast mode config for user {user_id}: {e}")
        raise safe_internal_error(e, "get_beast_mode_config")


@router.put("/config")
@limiter.limit("20/minute")
async def update_beast_mode_config(
    request: Request,
    config: BeastModeConfig,
    current_user: dict = Depends(get_current_user),
):
    """
    Save or update beast mode configuration for the current user.
    """
    user_id = str(current_user["id"])
    try:
        supabase = get_supabase().client
        config_dict = config.model_dump(exclude_none=True)

        # Check if user_settings row exists
        existing = supabase.table("user_settings").select(
            "user_id"
        ).eq("user_id", user_id).maybe_single().execute()

        if existing and existing.data:
            # Update existing row
            supabase.table("user_settings").update(
                {"beast_mode_config": config_dict}
            ).eq("user_id", user_id).execute()
        else:
            # Insert new row
            supabase.table("user_settings").insert(
                {"user_id": user_id, "beast_mode_config": config_dict}
            ).execute()

        logger.info(f"Updated beast mode config for user {user_id}: enabled={config.enabled}")

        return BeastModeResponse(
            config=config_dict,
            message="Beast mode config updated",
        )

    except Exception as e:
        logger.error(f"Error updating beast mode config for user {user_id}: {e}")
        raise safe_internal_error(e, "update_beast_mode_config")


@router.delete("/config")
@limiter.limit("10/minute")
async def reset_beast_mode_config(
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Reset beast mode configuration to defaults (null).
    """
    user_id = str(current_user["id"])
    try:
        supabase = get_supabase().client

        # Set beast_mode_config to null
        supabase.table("user_settings").update(
            {"beast_mode_config": None}
        ).eq("user_id", user_id).execute()

        logger.info(f"Reset beast mode config for user {user_id}")

        return BeastModeResponse(
            config=None,
            message="Beast mode config reset to defaults",
        )

    except Exception as e:
        logger.error(f"Error resetting beast mode config for user {user_id}: {e}")
        raise safe_internal_error(e, "reset_beast_mode_config")
