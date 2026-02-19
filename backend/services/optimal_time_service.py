"""Service for calculating optimal notification send times per user."""

from datetime import datetime, timezone, timedelta
from typing import Tuple

from core.supabase_client import get_supabase
from core.logger import get_logger

logger = get_logger(__name__)


async def calculate_optimal_hour(
    user_id: str,
    notification_type: str = "general",
    days: int = 14,
) -> Tuple[int, float]:
    """
    Calculate the optimal hour to send notifications to a user.
    Returns (optimal_hour, confidence_score).
    Uses last N days of notification opens + app sessions.
    """
    supabase = get_supabase()
    now = datetime.now(timezone.utc)
    cutoff = (now - timedelta(days=days)).isoformat()

    # 1. Get notification open events
    events_resp = supabase.client.table("notification_events").select(
        "local_hour_opened, opened_at"
    ).eq("user_id", user_id).not_.is_(
        "opened_at", "null"
    ).gte("sent_at", cutoff).execute()

    events = events_resp.data or []

    # 2. Get app open times from activity logs as supplementary signal
    app_opens_resp = supabase.client.table("user_activity_log").select(
        "created_at"
    ).eq("user_id", user_id).eq(
        "action", "app_opened"
    ).gte("created_at", cutoff).limit(100).execute()

    app_opens = app_opens_resp.data or []

    # 3. Weighted scoring
    hour_scores = [0.0] * 24

    for event in events:
        hour = event.get("local_hour_opened")
        if hour is None:
            continue
        opened_at = datetime.fromisoformat(event["opened_at"].replace("Z", "+00:00"))
        days_ago = (now - opened_at).days
        weight = max(0.3, 1.0 - (days_ago / days))
        hour_scores[hour] += weight * 2.0  # 2x weight for notification engagement

    for app_open in app_opens:
        try:
            open_time = datetime.fromisoformat(app_open["created_at"].replace("Z", "+00:00"))
            hour = open_time.hour
            days_ago = (now - open_time).days
            weight = max(0.3, 1.0 - (days_ago / days))
            hour_scores[hour] += weight * 1.0
        except (ValueError, KeyError):
            continue

    # 4. Find peak hour
    if max(hour_scores) == 0:
        return (9, 0.0)  # Default 9 AM, zero confidence

    optimal_hour = hour_scores.index(max(hour_scores))
    total_events = len(events) + len(app_opens)
    confidence = min(1.0, total_events / 20)  # Full confidence at 20+ data points

    return (optimal_hour, confidence)


async def recalculate_all_optimal_times():
    """Recalculate optimal send times for all active users. Called daily."""
    supabase = get_supabase()
    now = datetime.now(timezone.utc)

    # Get all active users with FCM tokens
    users_resp = supabase.client.table("users").select("id").not_.is_("fcm_token", "null").execute()
    users = users_resp.data or []

    results = {"total": len(users), "updated": 0, "errors": 0}

    for user in users:
        user_id = user["id"]
        try:
            workout_hour, workout_conf = await calculate_optimal_hour(user_id, "workout_reminder")
            nutrition_hour, nutrition_conf = await calculate_optimal_hour(user_id, "nutrition_reminder")
            general_hour, general_conf = await calculate_optimal_hour(user_id, "general")

            best_conf = max(workout_conf, nutrition_conf, general_conf)
            total_points = int(best_conf * 20)

            # Upsert optimal times
            supabase.client.table("user_optimal_send_times").upsert({
                "user_id": user_id,
                "workout_reminder_hour": workout_hour,
                "nutrition_reminder_hour": nutrition_hour,
                "general_optimal_hour": general_hour,
                "confidence_score": best_conf,
                "data_points": total_points,
                "calculation_method": "weighted_moving_average",
                "calculated_at": now.isoformat(),
                "expires_at": (now + timedelta(days=1)).isoformat(),
            }).execute()

            results["updated"] += 1
        except Exception as e:
            logger.error(f"Error calculating optimal time for user {user_id}: {e}")
            results["errors"] += 1

    logger.info(f"Optimal times recalculated: {results}")
    return results
