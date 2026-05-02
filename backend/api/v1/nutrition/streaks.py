"""Nutrition streak tracking endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta, date as date_type
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from core.timezone_utils import resolve_timezone, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from api.v1.nutrition.models import NutritionStreakResponse

router = APIRouter()
logger = get_logger(__name__)

@router.get("/streak/{user_id}", response_model=NutritionStreakResponse)
async def get_nutrition_streak(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get nutrition streak for a user.
    """
    logger.info(f"Getting nutrition streak for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("nutrition_streaks")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not result or not result.data:
            # Create default streak (if table exists) or return defaults
            try:
                insert_result = db.client.table("nutrition_streaks")\
                    .insert({"user_id": user_id})\
                    .execute()
                data = insert_result.data[0] if insert_result and insert_result.data else {"user_id": user_id}
            except Exception:
                # Table might not exist yet - return defaults
                data = {"user_id": user_id}
        else:
            data = result.data

        # Self-heal: if last_logged_date is null but food_logs exist, backfill
        # streak from actual logs. Covers users who logged before streak-update
        # background task was wired into logging endpoints.
        if not data.get("last_logged_date"):
            try:
                import pytz
                user_tz_result = db.client.table("users") \
                    .select("timezone") \
                    .eq("id", user_id) \
                    .maybe_single() \
                    .execute()
                tz_str = (user_tz_result.data or {}).get("timezone") or "UTC"
                tz = pytz.timezone(tz_str)
                today_local: date_type = datetime.now(tz).date()
                cutoff_utc = (datetime.now(pytz.utc) - timedelta(days=90)).isoformat()
                logs_result = db.client.table("food_logs") \
                    .select("logged_at") \
                    .eq("user_id", user_id) \
                    .gte("logged_at", cutoff_utc) \
                    .order("logged_at", desc=True) \
                    .execute()
                if logs_result.data:
                    # Collect distinct local dates from food_logs
                    logged_dates = sorted(
                        {date_type.fromisoformat(
                            datetime.fromisoformat(
                                str(r["logged_at"]).replace("Z", "+00:00")
                            ).astimezone(tz).strftime("%Y-%m-%d")
                        ) for r in logs_result.data},
                        reverse=True,
                    )
                    # Compute consecutive streak ending at most-recent log
                    streak = 1
                    for i in range(1, len(logged_dates)):
                        if (logged_dates[i - 1] - logged_dates[i]).days == 1:
                            streak += 1
                        else:
                            break
                    most_recent = logged_dates[0]
                    # Streak is live only if logged today or yesterday
                    days_since = (today_local - most_recent).days
                    active_streak = streak if days_since <= 1 else 0
                    update = {
                        "current_streak_days": active_streak,
                        "total_days_logged": len(logged_dates),
                        "longest_streak_ever": max(data.get("longest_streak_ever", 0), streak),
                        "last_logged_date": most_recent.isoformat(),
                    }
                    if active_streak > 0:
                        update["streak_start_date"] = logged_dates[streak - 1].isoformat()
                    db.client.table("nutrition_streaks") \
                        .upsert({"user_id": user_id, **update}, on_conflict="user_id") \
                        .execute()
                    data.update(update)
            except Exception as heal_err:
                logger.warning(f"Streak self-heal failed for {user_id}: {heal_err}")

        return NutritionStreakResponse(
            id=data.get("id"),
            user_id=data.get("user_id", user_id),
            current_streak_days=data.get("current_streak_days", 0),
            streak_start_date=datetime.fromisoformat(str(data["streak_start_date"]).replace("Z", "+00:00")) if data.get("streak_start_date") else None,
            last_logged_date=datetime.fromisoformat(str(data["last_logged_date"]).replace("Z", "+00:00")) if data.get("last_logged_date") else None,
            freezes_available=data.get("freezes_available", 2),
            freezes_used_this_week=data.get("freezes_used_this_week", 0),
            week_start_date=datetime.fromisoformat(str(data["week_start_date"]).replace("Z", "+00:00")) if data.get("week_start_date") else None,
            longest_streak_ever=data.get("longest_streak_ever", 0),
            total_days_logged=data.get("total_days_logged", 0),
            weekly_goal_enabled=data.get("weekly_goal_enabled", False),
            weekly_goal_days=data.get("weekly_goal_days", 5),
            days_logged_this_week=data.get("days_logged_this_week", 0),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition streak: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/streak/{user_id}/freeze", response_model=NutritionStreakResponse)
async def use_streak_freeze(request: Request, user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Use a streak freeze to preserve current streak.
    """
    logger.info(f"Using streak freeze for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        # Get current streak
        result = db.client.table("nutrition_streaks")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Streak not found")

        data = result.data
        freezes_available = data.get("freezes_available", 0)

        if freezes_available <= 0:
            raise HTTPException(status_code=400, detail="No freezes available")

        # Use a freeze
        db.client.table("nutrition_streaks")\
            .update({
                "freezes_available": freezes_available - 1,
                "freezes_used_this_week": data.get("freezes_used_this_week", 0) + 1,
                "last_logged_date": get_user_today(user_tz),
            })\
            .eq("user_id", user_id)\
            .execute()

        return await get_nutrition_streak(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to use streak freeze: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


