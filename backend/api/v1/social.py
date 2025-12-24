"""Social features API endpoints."""

from fastapi import APIRouter, HTTPException, Query, Depends
from typing import List, Optional
from datetime import datetime, timedelta, timezone
import os

from models.social import (
    # User Connections
    UserConnection, UserConnectionCreate, UserConnectionWithProfile, UserProfile,
    ConnectionType, ConnectionStatus,
    # Activity Feed
    ActivityFeedItem, ActivityFeedItemCreate, ActivityFeedResponse,
    ActivityType, Visibility,
    # Reactions
    ActivityReaction, ActivityReactionCreate, ReactionsSummary, ReactionType,
    # Comments
    ActivityComment, ActivityCommentCreate, ActivityCommentUpdate, CommentsResponse,
    # Challenges
    Challenge, ChallengeCreate, ChallengeParticipant,
    ChallengeParticipantCreate, ChallengeParticipantUpdate,
    ChallengeWithParticipation, ChallengeLeaderboard, ChallengeLeaderboardEntry,
    ChallengeType, ChallengeStatus,
    # Privacy
    UserPrivacySettings, UserPrivacySettingsUpdate,
    # Summary
    SocialStats, SocialFeedSummary,
    # Senior Mode
    SimplifiedActivityItem, SimplifiedChallenge, SeniorSocialSummary,
)
from utils.supabase_client import get_supabase_client
from services.social_rag_service import get_social_rag_service

router = APIRouter(prefix="/social")


# ============================================================
# USER CONNECTIONS
# ============================================================

@router.post("/connections", response_model=UserConnection)
async def create_connection(
    user_id: str,
    connection: UserConnectionCreate,
):
    """
    Create a new user connection (follow someone).

    Args:
        user_id: ID of the user creating the connection (follower)
        connection: Connection details (who to follow)

    Returns:
        Created connection

    Raises:
        400: If trying to follow self or already following
        404: If target user not found
    """
    supabase = get_supabase_client()

    # Prevent self-following
    if user_id == connection.following_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")

    # Check if connection already exists
    existing = supabase.table("user_connections").select("*").eq(
        "follower_id", user_id
    ).eq("following_id", connection.following_id).execute()

    if existing.data:
        raise HTTPException(status_code=400, detail="Already following this user")

    # Create connection
    result = supabase.table("user_connections").insert({
        "follower_id": user_id,
        "following_id": connection.following_id,
        "connection_type": connection.connection_type.value,
        "status": "active",
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create connection")

    return UserConnection(**result.data[0])


@router.delete("/connections/{following_id}")
async def delete_connection(
    user_id: str,
    following_id: str,
):
    """
    Delete a connection (unfollow someone).

    Args:
        user_id: ID of the user (follower)
        following_id: ID of the user to unfollow

    Returns:
        Success message
    """
    supabase = get_supabase_client()

    result = supabase.table("user_connections").delete().eq(
        "follower_id", user_id
    ).eq("following_id", following_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Connection not found")

    return {"message": "Connection deleted successfully"}


@router.get("/connections/followers/{user_id}", response_model=List[UserConnectionWithProfile])
async def get_followers(
    user_id: str,
    connection_type: Optional[ConnectionType] = None,
):
    """
    Get all followers for a user.

    Args:
        user_id: User ID
        connection_type: Optional filter by connection type

    Returns:
        List of followers with profile data
    """
    supabase = get_supabase_client()

    query = supabase.table("user_connections").select(
        "*, users!user_connections_follower_id_fkey(id, name, avatar_url)"
    ).eq("following_id", user_id).eq("status", "active")

    if connection_type:
        query = query.eq("connection_type", connection_type.value)

    result = query.execute()

    connections = []
    for row in result.data:
        conn = UserConnectionWithProfile(**row)
        if row.get("users"):
            conn.user_profile = UserProfile(
                id=row["users"]["id"],
                name=row["users"].get("name", "Unknown"),
                avatar_url=row["users"].get("avatar_url"),
            )
        connections.append(conn)

    return connections


@router.get("/connections/following/{user_id}", response_model=List[UserConnectionWithProfile])
async def get_following(
    user_id: str,
    connection_type: Optional[ConnectionType] = None,
):
    """
    Get all users that a user is following.

    Args:
        user_id: User ID
        connection_type: Optional filter by connection type

    Returns:
        List of following connections with profile data
    """
    supabase = get_supabase_client()

    query = supabase.table("user_connections").select(
        "*, users!user_connections_following_id_fkey(id, name, avatar_url)"
    ).eq("follower_id", user_id).eq("status", "active")

    if connection_type:
        query = query.eq("connection_type", connection_type.value)

    result = query.execute()

    connections = []
    for row in result.data:
        conn = UserConnectionWithProfile(**row)
        if row.get("users"):
            conn.user_profile = UserProfile(
                id=row["users"]["id"],
                name=row["users"].get("name", "Unknown"),
                avatar_url=row["users"].get("avatar_url"),
            )
        connections.append(conn)

    return connections


@router.get("/connections/friends/{user_id}", response_model=List[UserProfile])
async def get_friends(user_id: str):
    """
    Get mutual friends (users who follow each other).

    Args:
        user_id: User ID

    Returns:
        List of friend profiles
    """
    supabase = get_supabase_client()

    # Use the user_friends view created in migration
    result = supabase.table("user_friends").select(
        "friend_id, users!user_friends_friend_id_fkey(id, name, avatar_url)"
    ).eq("user_id", user_id).execute()

    friends = []
    for row in result.data:
        if row.get("users"):
            friends.append(UserProfile(
                id=row["users"]["id"],
                name=row["users"].get("name", "Unknown"),
                avatar_url=row["users"].get("avatar_url"),
            ))

    return friends


# ============================================================
# ACTIVITY FEED
# ============================================================

@router.get("/feed/{user_id}", response_model=ActivityFeedResponse)
async def get_activity_feed(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    activity_type: Optional[ActivityType] = None,
):
    """
    Get activity feed for a user (their activities + friends' activities).

    Args:
        user_id: User ID
        page: Page number (1-indexed)
        page_size: Items per page
        activity_type: Optional filter by activity type

    Returns:
        Paginated activity feed
    """
    supabase = get_supabase_client()

    # Get user's following list
    following_result = supabase.table("user_connections").select("following_id").eq(
        "follower_id", user_id
    ).eq("status", "active").execute()

    following_ids = [row["following_id"] for row in following_result.data]
    following_ids.append(user_id)  # Include user's own activities

    # Build query
    query = supabase.table("activity_feed").select(
        "*, users(name, avatar_url)",
        count="exact"
    ).in_("user_id", following_ids).order("created_at", desc=True)

    if activity_type:
        query = query.eq("activity_type", activity_type.value)

    # Apply pagination
    offset = (page - 1) * page_size
    query = query.range(offset, offset + page_size - 1)

    result = query.execute()

    # Parse activities
    activities = []
    for row in result.data:
        activity = ActivityFeedItem(**row)
        if row.get("users"):
            activity.user_name = row["users"].get("name")
            activity.user_avatar = row["users"].get("avatar_url")
        activities.append(activity)

    total_count = result.count or 0

    return ActivityFeedResponse(
        items=activities,
        total_count=total_count,
        page=page,
        page_size=page_size,
        has_more=offset + page_size < total_count,
    )


@router.post("/feed", response_model=ActivityFeedItem)
async def create_activity(
    user_id: str,
    activity: ActivityFeedItemCreate,
):
    """
    Create a new activity feed item.

    Args:
        user_id: User ID
        activity: Activity details

    Returns:
        Created activity
    """
    supabase = get_supabase_client()

    result = supabase.table("activity_feed").insert({
        "user_id": user_id,
        "activity_type": activity.activity_type.value,
        "activity_data": activity.activity_data,
        "visibility": activity.visibility.value,
        "workout_log_id": activity.workout_log_id,
        "achievement_id": activity.achievement_id,
        "pr_id": activity.pr_id,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create activity")

    activity_item = ActivityFeedItem(**result.data[0])

    # Store in ChromaDB for AI context
    try:
        # Get user name
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        social_rag = get_social_rag_service()
        social_rag.add_activity_to_rag(
            activity_id=activity_item.id,
            user_id=user_id,
            user_name=user_name,
            activity_type=activity.activity_type.value,
            activity_data=activity.activity_data,
            visibility=activity.visibility.value,
            created_at=activity_item.created_at,
        )
        print(f"✅ [Social] Activity {activity_item.id} saved to ChromaDB")
    except Exception as e:
        # Non-critical - don't fail the request if ChromaDB fails
        print(f"⚠️ [Social] Failed to save activity to ChromaDB: {e}")

    return activity_item


@router.delete("/feed/{activity_id}")
async def delete_activity(
    user_id: str,
    activity_id: str,
):
    """
    Delete an activity (user can only delete their own).

    Args:
        user_id: User ID
        activity_id: Activity ID

    Returns:
        Success message
    """
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("activity_feed").select("user_id").eq("id", activity_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Activity not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this activity")

    result = supabase.table("activity_feed").delete().eq("id", activity_id).execute()

    # Remove from ChromaDB
    try:
        social_rag = get_social_rag_service()
        social_rag.delete_activity_from_rag(activity_id)
    except Exception as e:
        print(f"⚠️ [Social] Failed to remove activity from ChromaDB: {e}")

    return {"message": "Activity deleted successfully"}


# ============================================================
# REACTIONS
# ============================================================

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
            print(f"✅ [Social] Reaction {reaction_obj.id} saved to ChromaDB")
    except Exception as e:
        print(f"⚠️ [Social] Failed to save reaction to ChromaDB: {e}")

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
        print(f"⚠️ [Social] Failed to remove reaction from ChromaDB: {e}")

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


# ============================================================
# COMMENTS
# ============================================================

@router.post("/comments", response_model=ActivityComment)
async def add_comment(
    user_id: str,
    comment: ActivityCommentCreate,
):
    """
    Add a comment to an activity.

    Args:
        user_id: User ID
        comment: Comment details

    Returns:
        Created comment
    """
    supabase = get_supabase_client()

    result = supabase.table("activity_comments").insert({
        "activity_id": comment.activity_id,
        "user_id": user_id,
        "comment_text": comment.comment_text,
        "parent_comment_id": comment.parent_comment_id,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to add comment")

    return ActivityComment(**result.data[0])


@router.put("/comments/{comment_id}", response_model=ActivityComment)
async def update_comment(
    user_id: str,
    comment_id: str,
    update: ActivityCommentUpdate,
):
    """
    Update a comment (user can only update their own).

    Args:
        user_id: User ID
        comment_id: Comment ID
        update: Updated comment text

    Returns:
        Updated comment
    """
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("activity_comments").select("user_id").eq("id", comment_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Comment not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this comment")

    result = supabase.table("activity_comments").update({
        "comment_text": update.comment_text,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", comment_id).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to update comment")

    return ActivityComment(**result.data[0])


@router.delete("/comments/{comment_id}")
async def delete_comment(
    user_id: str,
    comment_id: str,
):
    """
    Delete a comment (user can only delete their own).

    Args:
        user_id: User ID
        comment_id: Comment ID

    Returns:
        Success message
    """
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("activity_comments").select("user_id").eq("id", comment_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Comment not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")

    result = supabase.table("activity_comments").delete().eq("id", comment_id).execute()

    return {"message": "Comment deleted successfully"}


@router.get("/comments/{activity_id}", response_model=CommentsResponse)
async def get_comments(
    activity_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
):
    """
    Get comments for an activity.

    Args:
        activity_id: Activity ID
        page: Page number
        page_size: Items per page

    Returns:
        Paginated comments
    """
    supabase = get_supabase_client()

    offset = (page - 1) * page_size

    result = supabase.table("activity_comments").select(
        "*, users(name, avatar_url)",
        count="exact"
    ).eq("activity_id", activity_id).is_("parent_comment_id", "null").order(
        "created_at", desc=True
    ).range(offset, offset + page_size - 1).execute()

    comments = []
    for row in result.data:
        comment = ActivityComment(**row)
        if row.get("users"):
            comment.user_name = row["users"].get("name")
            comment.user_avatar = row["users"].get("avatar_url")
        comments.append(comment)

    total_count = result.count or 0

    return CommentsResponse(
        comments=comments,
        total_count=total_count,
        page=page,
        page_size=page_size,
    )


# ============================================================
# CHALLENGES
# ============================================================

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


# ============================================================
# PRIVACY SETTINGS
# ============================================================

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


# ============================================================
# SOCIAL SUMMARY
# ============================================================

@router.get("/summary/{user_id}", response_model=SocialFeedSummary)
async def get_social_summary(user_id: str):
    """
    Get comprehensive social summary for user (for normal mode).

    Args:
        user_id: User ID

    Returns:
        Social feed summary with activity feed, challenges, suggestions
    """
    supabase = get_supabase_client()

    # Get activity feed (first 10 items)
    feed_response = await get_activity_feed(user_id, page=1, page_size=10)

    # Get suggested challenges (public, active, not yet joined)
    challenges_result = supabase.table("challenges").select("*").eq(
        "is_public", True
    ).gte("end_date", datetime.now(timezone.utc).isoformat()).limit(5).execute()

    suggested_challenges = [Challenge(**row) for row in challenges_result.data]

    # Get social stats
    followers = await get_followers(user_id)
    following = await get_following(user_id)
    friends = await get_friends(user_id)

    active_challenges_result = supabase.table("challenge_participants").select("*", count="exact").eq(
        "user_id", user_id
    ).eq("status", "active").execute()

    completed_challenges_result = supabase.table("challenge_participants").select("*", count="exact").eq(
        "user_id", user_id
    ).eq("status", "completed").execute()

    social_stats = SocialStats(
        followers_count=len(followers),
        following_count=len(following),
        friends_count=len(friends),
        active_challenges=active_challenges_result.count or 0,
        completed_challenges=completed_challenges_result.count or 0,
    )

    return SocialFeedSummary(
        activity_feed=feed_response.items,
        suggested_challenges=suggested_challenges,
        friend_suggestions=[],  # TODO: Implement friend suggestions algorithm
        social_stats=social_stats,
    )


@router.get("/summary/senior/{user_id}", response_model=SeniorSocialSummary)
async def get_senior_social_summary(user_id: str):
    """
    Get simplified social summary for senior mode.

    Args:
        user_id: User ID

    Returns:
        Simplified social summary with easy-to-understand content
    """
    supabase = get_supabase_client()

    # Get recent activities (simplified)
    feed_response = await get_activity_feed(user_id, page=1, page_size=5)

    simplified_activities = []
    for item in feed_response.items:
        summary_text = _generate_simple_summary(item)
        simplified_activities.append(SimplifiedActivityItem(
            id=item.id,
            user_name=item.user_name or "Someone",
            user_avatar=item.user_avatar,
            activity_type=item.activity_type,
            summary_text=summary_text,
            created_at=item.created_at,
            can_cheer=True,
            has_cheered=False,  # TODO: Check if user has reacted
        ))

    # Get user's challenges (simplified)
    challenges_result = supabase.table("challenge_participants").select(
        "*, challenges(title, goal_value, goal_unit, end_date)"
    ).eq("user_id", user_id).eq("status", "active").execute()

    simplified_challenges = []
    for row in challenges_result.data:
        if row.get("challenges"):
            challenge_data = row["challenges"]
            end_date = datetime.fromisoformat(challenge_data["end_date"].replace("Z", "+00:00"))
            days_remaining = max(0, (end_date - datetime.now(timezone.utc)).days)

            simplified_challenges.append(SimplifiedChallenge(
                id=row["id"],
                title=challenge_data["title"],
                simple_description=f"Reach {challenge_data['goal_value']} {challenge_data.get('goal_unit', '')}",
                your_progress=f"{row['current_value']} out of {challenge_data['goal_value']} {challenge_data.get('goal_unit', '')}",
                progress_percentage=row["progress_percentage"],
                days_remaining=days_remaining,
            ))

    # Get family connections
    family_connections = await get_following(user_id, connection_type=ConnectionType.FAMILY)
    family_members = [conn.user_profile for conn in family_connections if conn.user_profile]

    # Count encouragements received (reactions to user's activities)
    user_activities = supabase.table("activity_feed").select("id").eq("user_id", user_id).execute()
    activity_ids = [row["id"] for row in user_activities.data]

    encouragement_count = 0
    if activity_ids:
        reactions_result = supabase.table("activity_reactions").select("*", count="exact").in_(
            "activity_id", activity_ids
        ).execute()
        encouragement_count = reactions_result.count or 0

    return SeniorSocialSummary(
        recent_activities=simplified_activities,
        your_challenges=simplified_challenges,
        family_members=family_members,
        encouragement_count=encouragement_count,
    )


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _generate_simple_summary(activity: ActivityFeedItem) -> str:
    """Generate simple summary text for senior mode."""
    user_name = activity.user_name or "Someone"

    if activity.activity_type == ActivityType.WORKOUT_COMPLETED:
        workout_name = activity.activity_data.get("workout_name", "a workout")
        return f"{user_name} completed {workout_name}"

    elif activity.activity_type == ActivityType.ACHIEVEMENT_EARNED:
        achievement = activity.activity_data.get("achievement_name", "an achievement")
        return f"{user_name} earned {achievement}!"

    elif activity.activity_type == ActivityType.PERSONAL_RECORD:
        exercise = activity.activity_data.get("exercise_name", "an exercise")
        return f"{user_name} set a new personal record in {exercise}!"

    elif activity.activity_type == ActivityType.WEIGHT_MILESTONE:
        change = activity.activity_data.get("weight_change", 0)
        direction = "lost" if change < 0 else "gained"
        return f"{user_name} {direction} {abs(change)} lbs"

    elif activity.activity_type == ActivityType.STREAK_MILESTONE:
        days = activity.activity_data.get("streak_days", 0)
        return f"{user_name} has a {days}-day workout streak!"

    return f"{user_name} was active"
