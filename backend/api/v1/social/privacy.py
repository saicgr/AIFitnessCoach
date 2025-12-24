"""
Privacy settings API endpoints.

This module handles privacy settings:
- GET /privacy/{user_id} - Get privacy settings
- PUT /privacy/{user_id} - Update privacy settings
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException

from models.social import (
    UserPrivacySettings, UserPrivacySettingsUpdate, Visibility,
)
from .utils import get_supabase_client

router = APIRouter()


@router.get("/privacy/{user_id}", response_model=UserPrivacySettings)
async def get_privacy_settings(user_id: str):
    """
    Get user's privacy settings.

    Args:
        user_id: User ID

    Returns:
        Privacy settings
    """
    supabase = get_supabase_client()

    result = supabase.table("user_privacy_settings").select("*").eq("user_id", user_id).execute()

    if not result.data:
        # Return default settings
        return UserPrivacySettings(
            user_id=user_id,
            updated_at=datetime.now(timezone.utc),
        )

    return UserPrivacySettings(**result.data[0])


@router.put("/privacy/{user_id}", response_model=UserPrivacySettings)
async def update_privacy_settings(
    user_id: str,
    update: UserPrivacySettingsUpdate,
):
    """
    Update user's privacy settings.

    Args:
        user_id: User ID
        update: Updated settings

    Returns:
        Updated privacy settings
    """
    supabase = get_supabase_client()

    # Build update dict (only include non-None values)
    update_data = {
        k: v.value if isinstance(v, Visibility) else v
        for k, v in update.dict(exclude_unset=True).items()
        if v is not None
    }
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    # Upsert (update if exists, insert if not)
    result = supabase.table("user_privacy_settings").upsert({
        "user_id": user_id,
        **update_data,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to update privacy settings")

    return UserPrivacySettings(**result.data[0])
