"""
API endpoints for workout challenges (friend-to-friend).

Endpoints:
- POST /send - Send challenge to specific friends
- GET /received - Get challenges received
- GET /sent - Get challenges sent
- POST /accept/{id} - Accept a challenge
- POST /decline/{id} - Decline a challenge
- POST /complete/{id} - Mark challenge as completed with results
- POST /abandon/{id} - Abandon a challenge midway
- GET /notifications - Get challenge notifications
- GET /stats/{user_id} - Get challenge statistics
- POST /accept-from-feed - Create + accept challenge from a feed post
- GET /{challenge_id} - Fetch a single challenge with user joins
- GET /activity/{activity_id}/leaderboard - Completed challenges leaderboard for a feed post
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from datetime import datetime, timezone

from models.workout_challenges import (
    SendChallengeRequest, SendChallengeResponse,
    AcceptChallengeRequest, DeclineChallengeRequest, CompleteChallengeRequest,
    AbandonChallengeRequest,
    WorkoutChallenge, ChallengesResponse,
    ChallengeNotification, NotificationsResponse,
    ChallengeStats, ChallengeStatus,
)
from core.auth import get_current_user
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from services.social_rag_service import get_social_rag_service

logger = get_logger(__name__)


def get_supabase_client():
    """Get Supabase client for database operations."""
    return get_supabase().client

router = APIRouter(prefix="/challenges")


# ============================================================
# SEND CHALLENGES
# ============================================================

@router.post("/send", response_model=SendChallengeResponse)
async def send_challenges(
    request: SendChallengeRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Send workout challenge to specific friends.

    After completing a workout, user can challenge friends to beat it.

    Args:
        user_id: User sending the challenge
        request: Challenge details (friends to challenge, workout data)

    Returns:
        Number of challenges sent and challenge IDs
    """
    supabase = get_supabase_client()

    # Validate that to_user_ids don't include sender
    if user_id in request.to_user_ids:
        raise HTTPException(status_code=400, detail="Cannot challenge yourself")

    # Get challenger's name for ChromaDB logging
    user_result = supabase.table("users").select("name").eq("id", user_id).execute()
    challenger_name = user_result.data[0]["name"] if user_result.data else "User"

    challenge_ids = []

    # Create a challenge for each friend
    for to_user_id in request.to_user_ids:
        challenge_data = {
            "from_user_id": user_id,
            "to_user_id": to_user_id,
            "workout_name": request.workout_name,
            "workout_data": request.workout_data,
            "challenge_message": request.challenge_message,
            "status": "pending",
            "is_retry": request.is_retry,
        }

        if request.workout_log_id:
            challenge_data["workout_log_id"] = request.workout_log_id
        if request.activity_id:
            challenge_data["activity_id"] = request.activity_id
        if request.retried_from_challenge_id:
            challenge_data["retried_from_challenge_id"] = request.retried_from_challenge_id

        # Insert challenge
        result = supabase.table("workout_challenges").insert(challenge_data).execute()

        if result.data:
            challenge_id = result.data[0]["id"]
            challenge_ids.append(challenge_id)

            # Log to ChromaDB
            try:
                social_rag = get_social_rag_service()
                to_user_result = supabase.table("users").select("name").eq("id", to_user_id).execute()
                to_user_name = to_user_result.data[0]["name"] if to_user_result.data else "User"

                collection = social_rag.get_social_collection()

                # Different logging for retries vs new challenges
                if request.is_retry:
                    # Retry: Show persistence and determination
                    collection.add(
                        documents=[f"{challenger_name} RETRIED challenge against {to_user_name} for '{request.workout_name}' (not giving up!)"],
                        metadatas=[{
                            "from_user_id": user_id,
                            "to_user_id": to_user_id,
                            "challenge_id": challenge_id,
                            "interaction_type": "challenge_retry",
                            "workout_name": request.workout_name,
                            "is_retry": True,
                            "retried_from_challenge_id": request.retried_from_challenge_id,
                            "created_at": datetime.now(timezone.utc).isoformat(),
                        }],
                        ids=[f"challenge_retry_{challenge_id}"],
                    )
                    logger.info(f"[Challenges] Retry logged: {challenger_name} -> {to_user_name} for {request.workout_name}")
                else:
                    # New challenge
                    collection.add(
                        documents=[f"{challenger_name} challenged {to_user_name} to beat {request.workout_name}"],
                        metadatas=[{
                            "from_user_id": user_id,
                            "to_user_id": to_user_id,
                            "challenge_id": challenge_id,
                            "interaction_type": "challenge_sent",
                            "workout_name": request.workout_name,
                            "created_at": datetime.now(timezone.utc).isoformat(),
                        }],
                        ids=[f"challenge_sent_{challenge_id}"],
                    )
            except Exception as e:
                logger.warning(f"[Challenges] Failed to log to ChromaDB: {e}")

    logger.info(f"✅ [Challenges] User {user_id} sent {len(challenge_ids)} challenges")

    # Log challenge sent activity
    await log_user_activity(
        user_id=user_id,
        action="challenge_sent",
        endpoint="/api/v1/challenges/send",
        message=f"Sent {len(challenge_ids)} challenge(s) for '{request.workout_name}'",
        metadata={
            "challenges_sent": len(challenge_ids),
            "workout_name": request.workout_name,
            "to_user_ids": request.to_user_ids,
            "is_retry": request.is_retry,
        },
        status_code=200
    )

    return SendChallengeResponse(
        message=f"Challenge sent to {len(challenge_ids)} friend(s)",
        challenges_sent=len(challenge_ids),
        challenge_ids=challenge_ids,
    )


# ============================================================
# GET CHALLENGES
# ============================================================

@router.get("/received", response_model=ChallengesResponse)
async def get_received_challenges(
    status: Optional[ChallengeStatus] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Get challenges received by user.

    Args:
        user_id: User ID
        status: Filter by status (pending, accepted, etc.)
        page: Page number
        page_size: Items per page

    Returns:
        List of challenges
    """
    supabase = get_supabase_client()

    # Build query
    query = supabase.table("workout_challenges").select(
        "*, from_user:users!from_user_id(name, avatar_url)",
        count="exact"
    ).eq("to_user_id", user_id).order("created_at", desc=True)

    if status:
        query = query.eq("status", status.value)

    # Pagination
    start = (page - 1) * page_size
    end = start + page_size - 1
    result = query.range(start, end).execute()

    # Format response
    challenges = []
    for row in result.data:
        challenge = WorkoutChallenge(**row)
        if row.get("from_user"):
            challenge.from_user_name = row["from_user"].get("name")
            challenge.from_user_avatar = row["from_user"].get("avatar_url")
        challenges.append(challenge)

    return ChallengesResponse(
        challenges=challenges,
        total=result.count or 0,
        page=page,
        page_size=page_size,
    )


@router.get("/sent", response_model=ChallengesResponse)
async def get_sent_challenges(
    status: Optional[ChallengeStatus] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Get challenges sent by user.

    Args:
        user_id: User ID
        status: Filter by status
        page: Page number
        page_size: Items per page

    Returns:
        List of challenges
    """
    supabase = get_supabase_client()

    # Build query
    query = supabase.table("workout_challenges").select(
        "*, to_user:users!to_user_id(name, avatar_url)",
        count="exact"
    ).eq("from_user_id", user_id).order("created_at", desc=True)

    if status:
        query = query.eq("status", status.value)

    # Pagination
    start = (page - 1) * page_size
    end = start + page_size - 1
    result = query.range(start, end).execute()

    # Format response
    challenges = []
    for row in result.data:
        challenge = WorkoutChallenge(**row)
        if row.get("to_user"):
            challenge.to_user_name = row["to_user"].get("name")
            challenge.to_user_avatar = row["to_user"].get("avatar_url")
        challenges.append(challenge)

    return ChallengesResponse(
        challenges=challenges,
        total=result.count or 0,
        page=page,
        page_size=page_size,
    )


# ============================================================
# ACCEPT / DECLINE CHALLENGES
# ============================================================

@router.post("/accept/{challenge_id}", response_model=WorkoutChallenge)
async def accept_challenge(
    challenge_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Accept a challenge.

    Args:
        user_id: User accepting the challenge
        challenge_id: Challenge ID

    Returns:
        Updated challenge
    """
    supabase = get_supabase_client()

    # Verify challenge belongs to user
    challenge_result = supabase.table("workout_challenges").select("*").eq(
        "id", challenge_id
    ).eq("to_user_id", user_id).execute()

    if not challenge_result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    challenge = challenge_result.data[0]

    if challenge["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"Challenge is already {challenge['status']}")

    # Update status
    update_result = supabase.table("workout_challenges").update({
        "status": "accepted",
        "accepted_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", challenge_id).execute()

    # Log to ChromaDB
    try:
        social_rag = get_social_rag_service()
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        collection = social_rag.get_social_collection()
        collection.add(
            documents=[f"{user_name} accepted challenge for {challenge['workout_name']}"],
            metadatas=[{
                "user_id": user_id,
                "challenge_id": challenge_id,
                "interaction_type": "challenge_accepted",
                "created_at": datetime.now(timezone.utc).isoformat(),
            }],
            ids=[f"challenge_accepted_{challenge_id}_{datetime.now().timestamp()}"],
        )
    except Exception as e:
        logger.warning(f"[Challenges] Failed to log to ChromaDB: {e}")

    logger.info(f"[Challenges] User {user_id} accepted challenge {challenge_id}")

    return WorkoutChallenge(**update_result.data[0])


@router.post("/decline/{challenge_id}")
async def decline_challenge(
    challenge_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Decline a challenge.

    Args:
        user_id: User declining
        challenge_id: Challenge ID

    Returns:
        Success message
    """
    supabase = get_supabase_client()

    # Verify challenge belongs to user
    challenge_result = supabase.table("workout_challenges").select("*").eq(
        "id", challenge_id
    ).eq("to_user_id", user_id).execute()

    if not challenge_result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    challenge = challenge_result.data[0]

    if challenge["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"Challenge is already {challenge['status']}")

    # Update status
    supabase.table("workout_challenges").update({
        "status": "declined",
        "declined_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", challenge_id).execute()

    logger.info(f"[Challenges] User {user_id} declined challenge {challenge_id}")

    return {"message": "Challenge declined"}


@router.post("/complete/{challenge_id}", response_model=WorkoutChallenge)
async def complete_challenge(
    challenge_id: str,
    request: CompleteChallengeRequest,
    auto_post_to_feed: bool = True,  # NEW: Auto-post to activity feed
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Mark challenge as completed with results.

    Compares user's performance to the original challenge stats.
    Optionally posts result to activity feed (default: true).

    Args:
        user_id: User completing the challenge
        challenge_id: Challenge ID
        request: Completion data (workout_log_id, stats)
        auto_post_to_feed: Whether to post result to activity feed

    Returns:
        Updated challenge with comparison results
    """
    supabase = get_supabase_client()

    # Get challenge with challenger info
    challenge_result = supabase.table("workout_challenges").select(
        "*, from_user:users!from_user_id(name, avatar_url)"
    ).eq("id", challenge_id).eq("to_user_id", user_id).execute()

    if not challenge_result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    challenge = challenge_result.data[0]

    if challenge["status"] != "accepted":
        raise HTTPException(status_code=400, detail="Challenge must be accepted first")

    # Compare stats to determine if they beat the challenge
    original_stats = challenge["workout_data"]
    challenged_stats = request.challenged_stats

    # Simple comparison: Did they beat the duration AND volume?
    did_beat = False
    if "duration_minutes" in original_stats and "duration_minutes" in challenged_stats:
        if "total_volume" in original_stats and "total_volume" in challenged_stats:
            # Beat if: (faster time OR equal time) AND (higher/equal volume)
            did_beat = (
                challenged_stats["duration_minutes"] <= original_stats["duration_minutes"]
                and challenged_stats["total_volume"] >= original_stats["total_volume"]
            )

    # Update challenge
    update_result = supabase.table("workout_challenges").update({
        "status": "completed",
        "completed_at": datetime.now(timezone.utc).isoformat(),
        "challenger_stats": original_stats,
        "challenged_stats": challenged_stats,
        "did_beat": did_beat,
    }).eq("id", challenge_id).execute()

    # Auto-post to activity feed if enabled
    if auto_post_to_feed:
        try:
            challenger_name = challenge.get("from_user", {}).get("name", "someone")

            # Create activity post
            activity_type = "challenge_victory" if did_beat else "challenge_completed"

            activity_data = {
                "workout_name": challenge["workout_name"],
                "challenger_name": challenger_name,
                "challenger_id": challenge["from_user_id"],
                "challenge_id": challenge_id,
                "did_beat": did_beat,
                # Your stats
                "your_duration": challenged_stats.get("duration_minutes"),
                "your_volume": challenged_stats.get("total_volume"),
                # Their stats to beat
                "their_duration": original_stats.get("duration_minutes"),
                "their_volume": original_stats.get("total_volume"),
                # Comparison
                "time_difference": (
                    original_stats.get("duration_minutes", 0) - challenged_stats.get("duration_minutes", 0)
                ) if did_beat else None,
                "volume_difference": (
                    challenged_stats.get("total_volume", 0) - original_stats.get("total_volume", 0)
                ) if did_beat else None,
            }

            supabase.table("activity_feed").insert({
                "user_id": user_id,
                "activity_type": activity_type,
                "activity_data": activity_data,
                "visibility": "friends",  # Default to friends
            }).execute()

            logger.info(f"[Challenges] Posted challenge result to activity feed (beat: {did_beat})")
        except Exception as e:
            logger.warning(f"[Challenges] Failed to post to activity feed: {e}")
            # Don't fail the challenge completion if posting fails

    # Log to ChromaDB
    try:
        social_rag = get_social_rag_service()
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        outcome = "beat" if did_beat else "attempted"
        collection = social_rag.get_social_collection()
        collection.add(
            documents=[f"{user_name} {outcome} the challenge for {challenge['workout_name']}"],
            metadatas=[{
                "user_id": user_id,
                "challenge_id": challenge_id,
                "interaction_type": "challenge_completed",
                "did_beat": did_beat,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }],
            ids=[f"challenge_completed_{challenge_id}"],
        )
    except Exception as e:
        logger.warning(f"[Challenges] Failed to log to ChromaDB: {e}")

    logger.info(f"[Challenges] User {user_id} completed challenge {challenge_id} (beat: {did_beat})")

    return WorkoutChallenge(**update_result.data[0])


@router.post("/abandon/{challenge_id}", response_model=WorkoutChallenge)
async def abandon_challenge(
    challenge_id: str,
    request: AbandonChallengeRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Abandon/quit a challenge midway through workout.

    This is used when a user gives up during the challenge workout.
    The quit reason will be shown to the challenger (making it embarrassing!).

    Args:
        user_id: User abandoning the challenge
        challenge_id: Challenge ID
        request: Quit reason and partial stats

    Returns:
        Updated challenge with abandonment data
    """
    supabase = get_supabase_client()

    # Get challenge with challenger info
    challenge_result = supabase.table("workout_challenges").select(
        "*, from_user:users!from_user_id(name, avatar_url)"
    ).eq("id", challenge_id).eq("to_user_id", user_id).execute()

    if not challenge_result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    challenge = challenge_result.data[0]

    if challenge["status"] != "accepted":
        raise HTTPException(status_code=400, detail="Can only abandon accepted challenges")

    # Update challenge to abandoned status
    update_result = supabase.table("workout_challenges").update({
        "status": "abandoned",
        "abandoned_at": datetime.now(timezone.utc).isoformat(),
        "quit_reason": request.quit_reason,
        "partial_stats": request.partial_stats,
    }).eq("id", challenge_id).execute()

    # Post to activity feed (optional - for public shame!)
    try:
        challenger_name = challenge.get("from_user", {}).get("name", "someone")

        activity_data = {
            "workout_name": challenge["workout_name"],
            "challenger_name": challenger_name,
            "challenger_id": challenge["from_user_id"],
            "challenge_id": challenge_id,
            "quit_reason": request.quit_reason,
            "partial_stats": request.partial_stats,
            "target_stats": challenge["workout_data"],
        }

        # Only post if user wants public accountability (could be a setting)
        # For now, we DON'T auto-post abandonments to feed (too harsh)
        # But we DO notify the challenger via challenge_notifications (trigger handles this)

        logger.info(f"[Challenges] User {user_id} abandoned challenge {challenge_id}: {request.quit_reason}")
    except Exception as e:
        logger.warning(f"[Challenges] Error processing abandonment: {e}")

    # Log to ChromaDB for AI insights
    try:
        social_rag = get_social_rag_service()
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"
        challenger_name = challenge.get("from_user", {}).get("name", "someone")

        collection = social_rag.get_social_collection()
        collection.add(
            documents=[
                f"{user_name} abandoned the workout challenge from {challenger_name} "
                f"for '{challenge['workout_name']}' with reason: {request.quit_reason}"
            ],
            metadatas=[{
                "type": "challenge_abandoned",
                "user_id": user_id,
                "challenge_id": challenge_id,
                "workout_name": challenge["workout_name"],
                "quit_reason": request.quit_reason,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }],
            ids=[f"challenge_abandoned_{challenge_id}"],
        )
    except Exception as e:
        logger.warning(f"[Challenges] Failed to log to ChromaDB: {e}")

    return WorkoutChallenge(**update_result.data[0])


# ============================================================
# NOTIFICATIONS
# ============================================================

@router.get("/notifications", response_model=NotificationsResponse)
async def get_notifications(
    unread_only: bool = False,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Get challenge notifications for user.

    Args:
        user_id: User ID
        unread_only: Only return unread notifications

    Returns:
        List of notifications
    """
    supabase = get_supabase_client()

    query = supabase.table("challenge_notifications").select(
        "*, challenge:workout_challenges(*)",
        count="exact"
    ).eq("user_id", user_id).order("created_at", desc=True)

    if unread_only:
        query = query.eq("is_read", False)

    result = query.execute()

    # Count unread
    unread_result = supabase.table("challenge_notifications").select(
        "id", count="exact"
    ).eq("user_id", user_id).eq("is_read", False).execute()

    notifications = [ChallengeNotification(**row) for row in result.data]

    return NotificationsResponse(
        notifications=notifications,
        total=result.count or 0,
        unread_count=unread_result.count or 0,
    )


@router.put("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """Mark notification as read."""
    supabase = get_supabase_client()

    supabase.table("challenge_notifications").update({
        "is_read": True,
        "read_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", notification_id).eq("user_id", user_id).execute()

    return {"message": "Notification marked as read"}


# ============================================================
# STATISTICS
# ============================================================

@router.get("/stats/{user_id}", response_model=ChallengeStats)
async def get_challenge_stats(user_id: str, current_user: dict = Depends(get_current_user)):
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    """
    Get challenge statistics for user.

    Args:
        user_id: User ID

    Returns:
        Challenge stats (sent, received, won, lost, win rate)
    """
    supabase = get_supabase_client()

    # Count sent challenges
    sent_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("from_user_id", user_id).execute()
    challenges_sent = sent_result.count or 0

    # Count received challenges
    received_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).execute()
    challenges_received = received_result.count or 0

    # Count accepted
    accepted_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).in_("status", ["accepted", "completed"]).execute()
    challenges_accepted = accepted_result.count or 0

    # Count declined
    declined_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).eq("status", "declined").execute()
    challenges_declined = declined_result.count or 0

    # Count won (completed and beat)
    won_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).eq("status", "completed").eq("did_beat", True).execute()
    challenges_won = won_result.count or 0

    # Count lost (completed but didn't beat)
    lost_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).eq("status", "completed").eq("did_beat", False).execute()
    challenges_lost = lost_result.count or 0

    # Count abandoned
    abandoned_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).eq("status", "abandoned").execute()
    challenges_abandoned = abandoned_result.count or 0

    # Calculate win rate
    total_completed = challenges_won + challenges_lost
    win_rate = (challenges_won / total_completed * 100) if total_completed > 0 else 0.0

    # Get retry statistics using database function
    retry_stats_result = supabase.rpc("get_user_retry_stats", {"p_user_id": user_id}).execute()
    retry_stats = retry_stats_result.data[0] if retry_stats_result.data else {}

    total_retries = retry_stats.get("total_retries", 0) or 0
    retries_won = retry_stats.get("retries_won", 0) or 0
    retry_win_rate = retry_stats.get("retry_win_rate", 0.0) or 0.0
    most_retried_workout = retry_stats.get("most_retried_workout")

    return ChallengeStats(
        user_id=user_id,
        challenges_sent=challenges_sent,
        challenges_received=challenges_received,
        challenges_accepted=challenges_accepted,
        challenges_declined=challenges_declined,
        challenges_won=challenges_won,
        challenges_lost=challenges_lost,
        challenges_abandoned=challenges_abandoned,
        win_rate=round(win_rate, 2),
        total_retries=total_retries,
        retries_won=retries_won,
        retry_win_rate=round(retry_win_rate, 2),
        most_retried_workout=most_retried_workout,
    )


# ============================================================
# ACCEPT FROM FEED (one-tap challenge from activity feed)
# ============================================================

@router.post("/accept-from-feed", response_model=WorkoutChallenge)
async def accept_challenge_from_feed(
    activity_id: str = Query(..., description="Activity feed post ID"),
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Atomically create + accept a challenge from a feed post.

    When a user sees a friend's workout in the feed and taps "Challenge",
    this creates the challenge already in accepted state so they can
    immediately start the workout.

    Args:
        activity_id: The activity_feed row ID
        current_user: Authenticated user

    Returns:
        The new challenge row (already accepted)
    """
    supabase = get_supabase_client()

    # Fetch the activity feed post
    activity_result = supabase.table("activity_feed").select(
        "id, user_id, activity_type, activity_data"
    ).eq("id", activity_id).execute()

    if not activity_result.data:
        raise HTTPException(status_code=404, detail="Activity post not found")

    activity = activity_result.data[0]
    poster_id = activity["user_id"]
    activity_type = activity["activity_type"]
    activity_data = activity.get("activity_data") or {}

    # Only allow challenges from workout posts
    if activity_type not in ("workout_completed", "workout_shared"):
        raise HTTPException(
            status_code=400,
            detail="Can only challenge from workout posts",
        )

    # Prevent self-challenge
    if poster_id == user_id:
        raise HTTPException(status_code=400, detail="Cannot challenge yourself")

    # Check for duplicate active challenge (same activity + same user)
    dup_result = supabase.table("workout_challenges").select(
        "id", count="exact"
    ).eq("activity_id", activity_id).eq(
        "to_user_id", user_id
    ).in_("status", ["pending", "accepted"]).execute()

    if (dup_result.count or 0) > 0:
        raise HTTPException(
            status_code=409,
            detail="You already have an active challenge for this workout",
        )

    # Build challenge row
    now_iso = datetime.now(timezone.utc).isoformat()
    challenge_data = {
        "from_user_id": poster_id,
        "to_user_id": user_id,
        "activity_id": activity_id,
        "workout_name": activity_data.get("workout_name", "Workout"),
        "workout_data": activity_data.get("workout_data", activity_data),
        "status": "accepted",
        "accepted_at": now_iso,
    }

    result = supabase.table("workout_challenges").insert(challenge_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create challenge")

    challenge_row = result.data[0]

    # Log to ChromaDB
    try:
        social_rag = get_social_rag_service()
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"
        poster_result = supabase.table("users").select("name").eq("id", poster_id).execute()
        poster_name = poster_result.data[0]["name"] if poster_result.data else "User"

        collection = social_rag.get_social_collection()
        collection.add(
            documents=[f"{user_name} accepted a feed challenge from {poster_name} for '{challenge_row['workout_name']}'"],
            metadatas=[{
                "user_id": user_id,
                "from_user_id": poster_id,
                "challenge_id": challenge_row["id"],
                "activity_id": activity_id,
                "interaction_type": "challenge_accepted_from_feed",
                "created_at": now_iso,
            }],
            ids=[f"challenge_feed_{challenge_row['id']}"],
        )
    except Exception as e:
        logger.warning(f"[Challenges] Failed to log feed-accept to ChromaDB: {e}")

    logger.info(f"✅ [Challenges] User {user_id} accepted feed challenge {challenge_row['id']} from activity {activity_id}")

    return WorkoutChallenge(**challenge_row)


# ============================================================
# ACTIVITY LEADERBOARD (all completed challenges for a feed post)
# NOTE: Must be registered BEFORE /{challenge_id} wildcard route
# ============================================================

@router.get("/activity/{activity_id}/leaderboard")
async def get_activity_leaderboard(
    activity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get leaderboard of all completed challenges for a specific activity post.

    Returns users who completed the challenge ordered by whether they beat
    the original poster's stats.

    Args:
        activity_id: The activity_feed post ID
        current_user: Authenticated user

    Returns:
        List of leaderboard entries with position, user info, stats, did_beat
    """
    supabase = get_supabase_client()

    result = supabase.table("workout_challenges").select(
        "id, to_user_id, challenged_stats, did_beat, completed_at, "
        "to_user:users!to_user_id(name, avatar_url)"
    ).eq("activity_id", activity_id).eq(
        "status", "completed"
    ).order("did_beat", desc=True).order("completed_at").execute()

    leaderboard = []
    for idx, row in enumerate(result.data):
        to_user = row.get("to_user") or {}
        leaderboard.append({
            "position": idx + 1,
            "challenge_id": row["id"],
            "user_id": row["to_user_id"],
            "user_name": to_user.get("name"),
            "user_avatar": to_user.get("avatar_url"),
            "stats": row.get("challenged_stats"),
            "did_beat": row.get("did_beat", False),
            "completed_at": row.get("completed_at"),
        })

    return {"activity_id": activity_id, "leaderboard": leaderboard, "total": len(leaderboard)}


# ============================================================
# GET SINGLE CHALLENGE (with user joins)
# NOTE: Wildcard route - must be LAST among GET routes
# ============================================================

@router.get("/{challenge_id}", response_model=WorkoutChallenge)
async def get_challenge(
    challenge_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["id"])
    """
    Fetch a single challenge with from_user and to_user joins.

    Only participants (challenger or challenged) may view.

    Args:
        challenge_id: Challenge ID
        current_user: Authenticated user

    Returns:
        Challenge data with user info
    """
    supabase = get_supabase_client()

    result = supabase.table("workout_challenges").select(
        "*, from_user:users!from_user_id(name, avatar_url), to_user:users!to_user_id(name, avatar_url)"
    ).eq("id", challenge_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Challenge not found")

    row = result.data[0]

    # Only participants may view
    if row["from_user_id"] != user_id and row["to_user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Access denied")

    challenge = WorkoutChallenge(**row)
    if row.get("from_user"):
        challenge.from_user_name = row["from_user"].get("name")
        challenge.from_user_avatar = row["from_user"].get("avatar_url")
    if row.get("to_user"):
        challenge.to_user_name = row["to_user"].get("name")
        challenge.to_user_avatar = row["to_user"].get("avatar_url")

    return challenge
