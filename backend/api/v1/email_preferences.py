"""
Email Preferences API endpoints.

Allows users to manage their email subscription preferences.
Addresses user review: "Had to give out email and can't find anywhere to unsubscribe."

ENDPOINTS:
- GET  /api/v1/email-preferences/{user_id} - Get current email preferences
- PUT  /api/v1/email-preferences/{user_id} - Update email preferences
- POST /api/v1/email-preferences/{user_id}/unsubscribe-marketing - Unsubscribe from all marketing emails
"""

from datetime import datetime
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter()
logger = get_logger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# REQUEST/RESPONSE MODELS
# ─────────────────────────────────────────────────────────────────────────────


class EmailPreferencesResponse(BaseModel):
    """Response model for email preferences."""
    id: str
    user_id: str
    workout_reminders: bool
    weekly_summary: bool
    coach_tips: bool
    product_updates: bool
    promotional: bool
    created_at: str
    updated_at: str


class EmailPreferencesUpdate(BaseModel):
    """Request model for updating email preferences."""
    workout_reminders: Optional[bool] = None
    weekly_summary: Optional[bool] = None
    coach_tips: Optional[bool] = None
    product_updates: Optional[bool] = None
    promotional: Optional[bool] = None


class UnsubscribeMarketingResponse(BaseModel):
    """Response after unsubscribing from all marketing emails."""
    success: bool
    message: str
    preferences: EmailPreferencesResponse


# ─────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────


def _preferences_to_response(data: dict) -> EmailPreferencesResponse:
    """Convert database row to response model."""
    return EmailPreferencesResponse(
        id=str(data["id"]),
        user_id=str(data["user_id"]),
        workout_reminders=data.get("workout_reminders", True),
        weekly_summary=data.get("weekly_summary", True),
        coach_tips=data.get("coach_tips", True),
        product_updates=data.get("product_updates", True),
        promotional=data.get("promotional", False),
        created_at=data.get("created_at", datetime.utcnow().isoformat()),
        updated_at=data.get("updated_at", datetime.utcnow().isoformat()),
    )


def _get_default_preferences(user_id: str) -> dict:
    """Get default email preferences for a new user."""
    return {
        "user_id": user_id,
        "workout_reminders": True,
        "weekly_summary": True,
        "coach_tips": True,
        "product_updates": True,
        "promotional": False,  # Marketing emails are opt-in
    }


# ─────────────────────────────────────────────────────────────────────────────
# API ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/{user_id}", response_model=EmailPreferencesResponse)
async def get_email_preferences(user_id: str):
    """
    Get current email preferences for a user.

    If no preferences exist, creates default preferences with:
    - workout_reminders: true (essential)
    - weekly_summary: true
    - coach_tips: true
    - product_updates: true
    - promotional: false (opt-in)

    Returns:
        EmailPreferencesResponse: Current email preference settings
    """
    logger.info(f"Getting email preferences for user {user_id}")

    try:
        supabase = get_supabase()

        # First, verify the user exists
        user_result = supabase.client.table("users").select("id").eq(
            "id", user_id
        ).single().execute()

        if not user_result.data:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Try to get existing preferences
        prefs_result = supabase.client.table("email_preferences").select(
            "*"
        ).eq("user_id", user_id).single().execute()

        if prefs_result.data:
            logger.info(f"Found existing email preferences for user {user_id}")
            return _preferences_to_response(prefs_result.data)

        # No preferences exist - create defaults
        logger.info(f"Creating default email preferences for user {user_id}")
        default_prefs = _get_default_preferences(user_id)

        insert_result = supabase.client.table("email_preferences").insert(
            default_prefs
        ).execute()

        if not insert_result.data:
            raise HTTPException(
                status_code=500,
                detail="Failed to create default email preferences"
            )

        await log_user_activity(
            user_id=user_id,
            action="email_preferences_created",
            endpoint=f"/api/v1/email-preferences/{user_id}",
            message="Default email preferences created",
            status_code=200
        )

        return _preferences_to_response(insert_result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting email preferences: {e}")
        await log_user_error(
            user_id=user_id,
            action="get_email_preferences",
            error=e,
            endpoint=f"/api/v1/email-preferences/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}", response_model=EmailPreferencesResponse)
async def update_email_preferences(user_id: str, preferences: EmailPreferencesUpdate):
    """
    Update email preferences for a user.

    Only the fields provided in the request body will be updated.
    Other fields will retain their current values.

    Args:
        user_id: The user's ID
        preferences: The preference fields to update

    Returns:
        EmailPreferencesResponse: Updated email preference settings
    """
    logger.info(f"Updating email preferences for user {user_id}")
    logger.debug(f"Update payload: {preferences.model_dump(exclude_none=True)}")

    try:
        supabase = get_supabase()

        # Verify user exists
        user_result = supabase.client.table("users").select("id").eq(
            "id", user_id
        ).single().execute()

        if not user_result.data:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Build update payload (only non-None fields)
        update_data = preferences.model_dump(exclude_none=True)

        if not update_data:
            # No fields to update - just return current preferences
            return await get_email_preferences(user_id)

        # Add updated_at timestamp
        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = supabase.client.table("email_preferences").select(
            "id"
        ).eq("user_id", user_id).single().execute()

        if existing.data:
            # Update existing preferences
            result = supabase.client.table("email_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            # Create new preferences with defaults + updates
            new_prefs = _get_default_preferences(user_id)
            new_prefs.update(update_data)
            result = supabase.client.table("email_preferences").insert(
                new_prefs
            ).execute()

        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Failed to update email preferences"
            )

        # Log the preference change for analytics
        changed_fields = list(preferences.model_dump(exclude_none=True).keys())
        await log_user_activity(
            user_id=user_id,
            action="email_preferences_updated",
            endpoint=f"/api/v1/email-preferences/{user_id}",
            message=f"Email preferences updated: {', '.join(changed_fields)}",
            metadata={
                "changed_fields": changed_fields,
                "new_values": preferences.model_dump(exclude_none=True)
            },
            status_code=200
        )

        logger.info(f"Email preferences updated for user {user_id}: {changed_fields}")
        return _preferences_to_response(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating email preferences: {e}")
        await log_user_error(
            user_id=user_id,
            action="update_email_preferences",
            error=e,
            endpoint=f"/api/v1/email-preferences/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/unsubscribe-marketing", response_model=UnsubscribeMarketingResponse)
async def unsubscribe_from_marketing(user_id: str):
    """
    Quick action to unsubscribe from all marketing/non-essential emails.

    This sets:
    - weekly_summary: false
    - coach_tips: false
    - product_updates: false
    - promotional: false

    workout_reminders is kept true as it's considered essential for the service.

    Returns:
        UnsubscribeMarketingResponse: Confirmation and updated preferences
    """
    logger.info(f"Unsubscribing user {user_id} from all marketing emails")

    try:
        supabase = get_supabase()

        # Verify user exists
        user_result = supabase.client.table("users").select("id, email").eq(
            "id", user_id
        ).single().execute()

        if not user_result.data:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Update preferences to unsubscribe from all marketing
        update_data = {
            "weekly_summary": False,
            "coach_tips": False,
            "product_updates": False,
            "promotional": False,
            "updated_at": datetime.utcnow().isoformat()
        }

        # Check if preferences exist
        existing = supabase.client.table("email_preferences").select(
            "id"
        ).eq("user_id", user_id).single().execute()

        if existing.data:
            result = supabase.client.table("email_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            # Create new preferences with marketing disabled
            new_prefs = {
                "user_id": user_id,
                "workout_reminders": True,  # Keep essential reminders
                **update_data
            }
            result = supabase.client.table("email_preferences").insert(
                new_prefs
            ).execute()

        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Failed to unsubscribe from marketing emails"
            )

        # Log this important preference change
        await log_user_activity(
            user_id=user_id,
            action="unsubscribed_from_marketing",
            endpoint=f"/api/v1/email-preferences/{user_id}/unsubscribe-marketing",
            message="User unsubscribed from all marketing emails",
            metadata={
                "disabled": ["weekly_summary", "coach_tips", "product_updates", "promotional"],
                "kept_enabled": ["workout_reminders"]
            },
            status_code=200
        )

        logger.info(f"User {user_id} successfully unsubscribed from marketing emails")

        return UnsubscribeMarketingResponse(
            success=True,
            message="Successfully unsubscribed from all marketing emails. You will still receive essential workout reminders.",
            preferences=_preferences_to_response(result.data[0])
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error unsubscribing from marketing: {e}")
        await log_user_error(
            user_id=user_id,
            action="unsubscribe_from_marketing",
            error=e,
            endpoint=f"/api/v1/email-preferences/{user_id}/unsubscribe-marketing",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/subscribe-all")
async def subscribe_to_all(user_id: str):
    """
    Quick action to subscribe to all email types (opt back in).

    Returns:
        EmailPreferencesResponse: Updated preferences with all enabled
    """
    logger.info(f"Subscribing user {user_id} to all email types")

    try:
        supabase = get_supabase()

        # Verify user exists
        user_result = supabase.client.table("users").select("id").eq(
            "id", user_id
        ).single().execute()

        if not user_result.data:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Update all preferences to true
        update_data = {
            "workout_reminders": True,
            "weekly_summary": True,
            "coach_tips": True,
            "product_updates": True,
            "promotional": True,
            "updated_at": datetime.utcnow().isoformat()
        }

        # Check if preferences exist
        existing = supabase.client.table("email_preferences").select(
            "id"
        ).eq("user_id", user_id).single().execute()

        if existing.data:
            result = supabase.client.table("email_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            update_data["user_id"] = user_id
            result = supabase.client.table("email_preferences").insert(
                update_data
            ).execute()

        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Failed to subscribe to all emails"
            )

        await log_user_activity(
            user_id=user_id,
            action="subscribed_to_all_emails",
            endpoint=f"/api/v1/email-preferences/{user_id}/subscribe-all",
            message="User subscribed to all email types",
            status_code=200
        )

        logger.info(f"User {user_id} subscribed to all email types")
        return _preferences_to_response(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error subscribing to all: {e}")
        await log_user_error(
            user_id=user_id,
            action="subscribe_to_all",
            error=e,
            endpoint=f"/api/v1/email-preferences/{user_id}/subscribe-all",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))
