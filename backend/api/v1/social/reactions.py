"""
Reactions API endpoints.

This module handles reaction operations:
- POST /reactions - Add a reaction to an activity
- DELETE /reactions/{activity_id} - Remove a reaction
- GET /reactions/{activity_id} - Get reactions for an activity
"""
import asyncio
from typing import Optional

from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException
from starlette.requests import Request
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter

from models.social import (
    ActivityReaction, ActivityReactionCreate, ReactionsSummary, ReactionType,
)
from services.social_rag_service import get_social_rag_service
from core.logger import get_logger
from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter()


def _bg_index_reaction(reaction_id: str, activity_id: str, user_id: str, reaction_type: str, created_at):
    """Background task: index reaction in ChromaDB for AI context."""
    try:
        supabase = get_supabase_client()
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        activity_result = supabase.table("activity_feed").select("user_id").eq("id", activity_id).execute()
        if activity_result.data:
            activity_owner_id = activity_result.data[0]["user_id"]
            owner_result = supabase.table("users").select("name").eq("id", activity_owner_id).execute()
            activity_owner = owner_result.data[0]["name"] if owner_result.data else "User"

            social_rag = get_social_rag_service()
            social_rag.add_reaction_to_rag(
                reaction_id=reaction_id,
                activity_id=activity_id,
                user_id=user_id,
                user_name=user_name,
                reaction_type=reaction_type,
                activity_owner=activity_owner,
                created_at=created_at,
            )
            logger.info(f"[Social] Reaction {reaction_id} indexed in ChromaDB")
    except Exception as e:
        logger.error(f"[Social] Failed to index reaction in ChromaDB: {e}", exc_info=True)


def _bg_remove_reaction(reaction_id: str):
    """Background task: remove reaction from ChromaDB."""
    try:
        social_rag = get_social_rag_service()
        social_rag.remove_reaction_from_rag(reaction_id)
    except Exception as e:
        logger.error(f"[Social] Failed to remove reaction from ChromaDB: {e}", exc_info=True)


def _bg_notify_reaction(activity_id: str, user_id: str, reaction_type: str):
    """Background task: send push notification for a new reaction."""
    try:
        supabase = get_supabase_client()

        # Get activity owner
        activity_result = supabase.table("activity_feed").select("user_id").eq("id", activity_id).execute()
        if not activity_result.data:
            return
        owner_id = activity_result.data[0]["user_id"]

        # Skip if reactor == owner
        if owner_id == user_id:
            return

        # Check privacy settings
        privacy_result = supabase.table("user_privacy_settings").select(
            "notify_reactions"
        ).eq("user_id", owner_id).execute()
        if privacy_result.data and not privacy_result.data[0].get("notify_reactions", True):
            return

        # Get reactor name
        reactor_result = supabase.table("users").select("name").eq("id", user_id).execute()
        reactor_name = reactor_result.data[0]["name"] if reactor_result.data else "Someone"

        # Create social_notifications row (upsert by from_user_id + reference_id + type for dedup)
        supabase.table("social_notifications").upsert({
            "user_id": owner_id,
            "from_user_id": user_id,
            "type": "reaction",
            "title": f"{reactor_name} reacted to your post",
            "body": f"{reactor_name} reacted with {reaction_type}",
            "reference_id": activity_id,
            "is_read": False,
        }, on_conflict="from_user_id,reference_id,type").execute()

        # Try to send push notification
        try:
            owner_result = supabase.table("users").select("fcm_token").eq("id", owner_id).execute()
            if owner_result.data and owner_result.data[0].get("fcm_token"):
                import asyncio
                from services.notification_service import NotificationService
                ns = NotificationService()
                asyncio.get_event_loop().run_until_complete(
                    ns.send_notification(
                        fcm_token=owner_result.data[0]["fcm_token"],
                        title=f"{reactor_name} reacted to your post",
                        body=f"Reacted with {reaction_type}",
                        data={"type": "reaction", "activity_id": activity_id},
                    )
                )
        except Exception:
            pass  # Push notification is best-effort

    except Exception as e:
        logger.error(f"[Social] Failed to notify reaction: {e}", exc_info=True)


@router.post("/reactions", response_model=ActivityReaction)
@limiter.limit("30/minute")
async def add_reaction(
    request: Request,
    user_id: str,
    reaction: ActivityReactionCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Add a reaction to an activity.

    Args:
        user_id: User ID
        reaction: Reaction details

    Returns:
        Created reaction
    """
    verify_user_ownership(current_user, user_id)
    supabase = get_supabase_client()

    # Check if already reacted (upsert behavior)
    existing = supabase.table("activity_reactions").select("*").eq(
        "activity_id", reaction.activity_id
    ).eq("user_id", user_id).execute()

    if existing.data:
        # Update existing reaction
        result = supabase.table("activity_reactions").update({
            "reaction_type": reaction.reaction_type.value,
        }).eq("id", existing.data[0]["id"]).execute()
    else:
        # Create new reaction
        result = supabase.table("activity_reactions").insert({
            "activity_id": reaction.activity_id,
            "user_id": user_id,
            "reaction_type": reaction.reaction_type.value,
        }).execute()

    if not result.data:
        raise safe_internal_error(ValueError("Failed to add reaction"), "social")

    reaction_obj = ActivityReaction(**result.data[0])

    # Index in ChromaDB in background - non-blocking
    background_tasks.add_task(
        _bg_index_reaction,
        reaction_id=reaction_obj.id,
        activity_id=reaction.activity_id,
        user_id=user_id,
        reaction_type=reaction.reaction_type.value,
        created_at=reaction_obj.created_at,
    )

    # Send push notification for reaction (F5)
    background_tasks.add_task(
        _bg_notify_reaction,
        activity_id=reaction.activity_id,
        user_id=user_id,
        reaction_type=reaction.reaction_type.value,
    )

    return reaction_obj


@router.delete("/reactions/{activity_id}")
@limiter.limit("30/minute")
async def remove_reaction(
    request: Request,
    user_id: str,
    activity_id: str,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Remove user's reaction from an activity.

    Args:
        user_id: User ID
        activity_id: Activity ID

    Returns:
        Success message
    """
    verify_user_ownership(current_user, user_id)
    supabase = get_supabase_client()

    # Get reaction ID before deleting
    reaction_result = supabase.table("activity_reactions").select("id").eq(
        "activity_id", activity_id
    ).eq("user_id", user_id).execute()

    if not reaction_result.data:
        raise HTTPException(status_code=404, detail="Reaction not found")

    reaction_id = reaction_result.data[0]["id"]

    result = supabase.table("activity_reactions").delete().eq(
        "activity_id", activity_id
    ).eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Reaction not found")

    # Remove from ChromaDB in background - non-blocking
    background_tasks.add_task(_bg_remove_reaction, reaction_id)

    return {"message": "Reaction removed successfully"}


@router.get("/reactions/{activity_id}", response_model=ReactionsSummary)
async def get_reactions(
    activity_id: str,
    user_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all reactions for an activity.

    Args:
        activity_id: Activity ID
        user_id: Optional user ID to include their reaction

    Returns:
        Reactions summary
    """
    supabase = get_supabase_client()

    # Single query: fetch all reactions for this activity (reaction_type + user_id)
    all_reactions = supabase.table("activity_reactions").select(
        "reaction_type, user_id"
    ).eq("activity_id", activity_id).execute()

    # Group by type in Python
    reactions_by_type = {}
    user_reaction = None
    for r in (all_reactions.data or []):
        rt = r["reaction_type"]
        reactions_by_type[rt] = reactions_by_type.get(rt, 0) + 1
        if user_id and r["user_id"] == user_id:
            user_reaction = ReactionType(rt)

    total_count = sum(reactions_by_type.values())

    return ReactionsSummary(
        activity_id=activity_id,
        total_count=total_count,
        reactions_by_type=reactions_by_type,
        user_reaction=user_reaction,
    )
