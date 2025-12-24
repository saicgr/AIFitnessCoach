"""
Reactions API endpoints.

This module handles reaction operations:
- POST /reactions - Add a reaction to an activity
- DELETE /reactions/{activity_id} - Remove a reaction
- GET /reactions/{activity_id} - Get reactions for an activity
"""
from typing import Optional

from fastapi import APIRouter, HTTPException

from models.social import (
    ActivityReaction, ActivityReactionCreate, ReactionsSummary, ReactionType,
)
from services.social_rag_service import get_social_rag_service
from .utils import get_supabase_client

router = APIRouter()


@router.post("/reactions", response_model=ActivityReaction)
async def add_reaction(
    user_id: str,
    reaction: ActivityReactionCreate,
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

    # Store in ChromaDB for AI social context
    try:
        # Get user name and activity owner
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        activity_result = supabase.table("activity_feed").select("user_id").eq("id", reaction.activity_id).execute()
        if activity_result.data:
            activity_owner_id = activity_result.data[0]["user_id"]
            owner_result = supabase.table("users").select("name").eq("id", activity_owner_id).execute()
            activity_owner = owner_result.data[0]["name"] if owner_result.data else "User"

            social_rag = get_social_rag_service()
            social_rag.add_reaction_to_rag(
                reaction_id=reaction_obj.id,
                activity_id=reaction.activity_id,
                user_id=user_id,
                user_name=user_name,
                reaction_type=reaction.reaction_type.value,
                activity_owner=activity_owner,
                created_at=reaction_obj.created_at,
            )
            print(f"[Social] Reaction {reaction_obj.id} saved to ChromaDB")
    except Exception as e:
        print(f"[Social] Failed to save reaction to ChromaDB: {e}")

    return reaction_obj


@router.delete("/reactions/{activity_id}")
async def remove_reaction(
    user_id: str,
    activity_id: str,
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

    # Remove from ChromaDB
    try:
        social_rag = get_social_rag_service()
        social_rag.remove_reaction_from_rag(reaction_id)
    except Exception as e:
        print(f"[Social] Failed to remove reaction from ChromaDB: {e}")

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

    result = supabase.table("activity_reactions").select("*").eq(
        "activity_id", activity_id
    ).execute()

    # Count by type
    reactions_by_type = {}
    user_reaction = None

    for row in result.data:
        reaction_type = row["reaction_type"]
        reactions_by_type[reaction_type] = reactions_by_type.get(reaction_type, 0) + 1

        if user_id and row["user_id"] == user_id:
            user_reaction = ReactionType(reaction_type)

    return ReactionsSummary(
        activity_id=activity_id,
        total_count=len(result.data),
        reactions_by_type=reactions_by_type,
        user_reaction=user_reaction,
    )
