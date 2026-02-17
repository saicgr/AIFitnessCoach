"""
Reactions API endpoints.

This module handles reaction operations:
- POST /reactions - Add a reaction to an activity
- DELETE /reactions/{activity_id} - Remove a reaction
- GET /reactions/{activity_id} - Get reactions for an activity
"""
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException

from models.social import (
    ActivityReaction, ActivityReactionCreate, ReactionsSummary, ReactionType,
)
from services.social_rag_service import get_social_rag_service
from .utils import get_supabase_client

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
            print(f"[Social] Reaction {reaction_id} indexed in ChromaDB")
    except Exception as e:
        print(f"[Social] Failed to index reaction in ChromaDB: {e}")


def _bg_remove_reaction(reaction_id: str):
    """Background task: remove reaction from ChromaDB."""
    try:
        social_rag = get_social_rag_service()
        social_rag.remove_reaction_from_rag(reaction_id)
    except Exception as e:
        print(f"[Social] Failed to remove reaction from ChromaDB: {e}")


@router.post("/reactions", response_model=ActivityReaction)
async def add_reaction(
    user_id: str,
    reaction: ActivityReactionCreate,
    background_tasks: BackgroundTasks,
):
    """
    Add a reaction to an activity.

    Args:
        user_id: User ID
        reaction: Reaction details

    Returns:
        Created reaction
    """
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
        raise HTTPException(status_code=500, detail="Failed to add reaction")

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

    return reaction_obj


@router.delete("/reactions/{activity_id}")
async def remove_reaction(
    user_id: str,
    activity_id: str,
    background_tasks: BackgroundTasks,
):
    """
    Remove user's reaction from an activity.

    Args:
        user_id: User ID
        activity_id: Activity ID

    Returns:
        Success message
    """
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
