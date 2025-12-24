"""
Challenges API endpoints.

This module handles challenge operations:
- POST /challenges - Create a challenge
- GET /challenges - Get challenges
- POST /challenges/participate - Join a challenge
- PUT /challenges/participate/{challenge_id} - Update progress
- GET /challenges/{challenge_id}/leaderboard - Get challenge leaderboard
"""
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query

from models.social import (
    Challenge, ChallengeCreate, ChallengeParticipant,
    ChallengeParticipantCreate, ChallengeParticipantUpdate,
    ChallengeWithParticipation, ChallengeLeaderboard, ChallengeLeaderboardEntry,
    ChallengeType, ChallengeStatus,
)
from .utils import get_supabase_client

router = APIRouter()


@router.post("/challenges", response_model=Challenge)
async def create_challenge(
    user_id: str,
    challenge: ChallengeCreate,
):
    """
    Create a new challenge.

    Args:
        user_id: Creator's user ID
        challenge: Challenge details

    Returns:
        Created challenge
    """
    supabase = get_supabase_client()

    result = supabase.table("challenges").insert({
        "title": challenge.title,
        "description": challenge.description,
        "challenge_type": challenge.challenge_type.value,
        "goal_value": challenge.goal_value,
        "goal_unit": challenge.goal_unit,
        "start_date": challenge.start_date.isoformat(),
        "end_date": challenge.end_date.isoformat(),
        "created_by": user_id,
        "is_public": challenge.is_public,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create challenge")

    return Challenge(**result.data[0])


@router.get("/challenges", response_model=List[ChallengeWithParticipation])
async def get_challenges(
    user_id: Optional[str] = None,
    challenge_type: Optional[ChallengeType] = None,
    is_public: Optional[bool] = None,
    active_only: bool = True,
):
    """
    Get challenges (public or user's challenges).

    Args:
        user_id: Optional user ID to include participation data
        challenge_type: Optional filter by challenge type
        is_public: Optional filter by public/private
        active_only: Only show active challenges (default True)

    Returns:
        List of challenges with participation data
    """
    supabase = get_supabase_client()

    query = supabase.table("challenges").select("*, users(name, avatar_url)")

    if challenge_type:
        query = query.eq("challenge_type", challenge_type.value)
    if is_public is not None:
        query = query.eq("is_public", is_public)
    if active_only:
        query = query.gte("end_date", datetime.now(timezone.utc).isoformat())

    query = query.order("created_at", desc=True)

    result = query.execute()

    challenges = []
    for row in result.data:
        challenge = ChallengeWithParticipation(**row)

        if row.get("users"):
            challenge.creator_name = row["users"].get("name")
            challenge.creator_avatar = row["users"].get("avatar_url")

        # Get user's participation if user_id provided
        if user_id:
            part_result = supabase.table("challenge_participants").select("*").eq(
                "challenge_id", row["id"]
            ).eq("user_id", user_id).execute()

            if part_result.data:
                challenge.user_participation = ChallengeParticipant(**part_result.data[0])

        # Get top 3 participants
        top_result = supabase.table("challenge_participants").select(
            "*, users(name, avatar_url)"
        ).eq("challenge_id", row["id"]).order(
            "current_value", desc=True
        ).limit(3).execute()

        for part_row in top_result.data:
            participant = ChallengeParticipant(**part_row)
            if part_row.get("users"):
                participant.user_name = part_row["users"].get("name")
                participant.user_avatar = part_row["users"].get("avatar_url")
            challenge.top_participants.append(participant)

        challenges.append(challenge)

    return challenges


@router.post("/challenges/participate", response_model=ChallengeParticipant)
async def join_challenge(
    user_id: str,
    participation: ChallengeParticipantCreate,
):
    """
    Join a challenge.

    Args:
        user_id: User ID
        participation: Challenge to join

    Returns:
        Created participation
    """
    supabase = get_supabase_client()

    # Check if already participating
    existing = supabase.table("challenge_participants").select("*").eq(
        "challenge_id", participation.challenge_id
    ).eq("user_id", user_id).execute()

    if existing.data:
        raise HTTPException(status_code=400, detail="Already participating in this challenge")

    result = supabase.table("challenge_participants").insert({
        "challenge_id": participation.challenge_id,
        "user_id": user_id,
        "current_value": 0,
        "progress_percentage": 0,
        "status": "active",
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to join challenge")

    return ChallengeParticipant(**result.data[0])


@router.put("/challenges/participate/{challenge_id}", response_model=ChallengeParticipant)
async def update_challenge_progress(
    user_id: str,
    challenge_id: str,
    update: ChallengeParticipantUpdate,
):
    """
    Update user's progress in a challenge.

    Args:
        user_id: User ID
        challenge_id: Challenge ID
        update: Updated progress value

    Returns:
        Updated participation
    """
    supabase = get_supabase_client()

    # Get challenge goal
    challenge_result = supabase.table("challenges").select("goal_value").eq("id", challenge_id).execute()
    if not challenge_result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    goal_value = challenge_result.data[0]["goal_value"]
    progress_percentage = min((update.current_value / goal_value) * 100, 100)

    # Determine status
    status = "active"
    completed_at = None
    if progress_percentage >= 100:
        status = "completed"
        completed_at = datetime.now(timezone.utc).isoformat()

    result = supabase.table("challenge_participants").update({
        "current_value": update.current_value,
        "progress_percentage": progress_percentage,
        "status": status,
        "completed_at": completed_at,
    }).eq("challenge_id", challenge_id).eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Participation not found")

    return ChallengeParticipant(**result.data[0])


@router.get("/challenges/{challenge_id}/leaderboard", response_model=ChallengeLeaderboard)
async def get_challenge_leaderboard(
    challenge_id: str,
    user_id: Optional[str] = None,
    limit: int = Query(100, ge=1, le=500),
):
    """
    Get leaderboard for a challenge.

    Args:
        challenge_id: Challenge ID
        user_id: Optional user ID to include their rank
        limit: Max number of entries to return

    Returns:
        Challenge leaderboard
    """
    supabase = get_supabase_client()

    # Get challenge info
    challenge_result = supabase.table("challenges").select("title, goal_value, goal_unit").eq(
        "id", challenge_id
    ).execute()

    if not challenge_result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    challenge_data = challenge_result.data[0]

    # Get leaderboard from view
    leaderboard_result = supabase.rpc("get_challenge_leaderboard_data", {
        "p_challenge_id": challenge_id,
        "p_limit": limit,
    }).execute()

    entries = []
    user_rank = None

    for idx, row in enumerate(leaderboard_result.data, 1):
        entry = ChallengeLeaderboardEntry(
            rank=idx,
            user_id=row["user_id"],
            user_name=row.get("user_name"),
            user_avatar=row.get("user_avatar"),
            current_value=row["current_value"],
            progress_percentage=row["progress_percentage"],
            status=ChallengeStatus(row["status"]),
        )
        entries.append(entry)

        if user_id and row["user_id"] == user_id:
            user_rank = idx

    return ChallengeLeaderboard(
        challenge_id=challenge_id,
        challenge_title=challenge_data["title"],
        goal_value=challenge_data["goal_value"],
        goal_unit=challenge_data.get("goal_unit"),
        entries=entries,
        user_rank=user_rank,
    )
