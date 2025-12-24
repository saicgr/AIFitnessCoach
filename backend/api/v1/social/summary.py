"""
Social summary API endpoints.

This module handles social summary operations:
- GET /summary/{user_id} - Get comprehensive social summary (normal mode)
- GET /summary/senior/{user_id} - Get simplified summary (senior mode)
"""
from datetime import datetime, timezone

from fastapi import APIRouter

from models.social import (
    ActivityFeedItem, ActivityType,
    Challenge, SocialStats, SocialFeedSummary,
    SimplifiedActivityItem, SimplifiedChallenge, SeniorSocialSummary,
    UserProfile, ConnectionType,
)
from .utils import get_supabase_client
from .connections import get_followers, get_following, get_friends
from .feed import get_activity_feed

router = APIRouter()


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
