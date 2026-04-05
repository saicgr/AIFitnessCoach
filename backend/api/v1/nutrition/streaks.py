"""Nutrition streak tracking endpoints."""
from core.db import get_supabase_db
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from core.timezone_utils import resolve_timezone
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
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
        logger.error(f"Failed to get nutrition streak: {e}")
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
        logger.error(f"Failed to use streak freeze: {e}")
        raise safe_internal_error(e, "nutrition")


