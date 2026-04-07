"""Secondary endpoints for xp.  Sub-router included by main module.
XP Events API - Daily Login, Streaks, Double XP Events
"""
from typing import Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, get_user_today
from core.exceptions import safe_internal_error

from .xp_models import (
    DailyLoginResponse,
    LoginStreakInfo,
    XPEvent,
    CreateEventRequest,
    BonusTemplate,
    AwardGoalXPRequest,
    AwardGoalXPResponse,
    DailyGoalsStatusResponse,
    FirstTimeBonusRequest,
    FirstTimeBonusResponse,
    FirstTimeBonusInfo,
    UseConsumableRequest,
    ConsumablesResponse,
    OpenCrateRequest,
    DailyCratesResponse,
    ClaimDailyCrateRequest,
    ClaimDailyCrateResponse,
    UnclaimedCrateItem,
    UnclaimedCratesResponse,
)

router = APIRouter()

@router.post("/use-consumable")
async def use_consumable(
    request: UseConsumableRequest,
    current_user=Depends(get_current_user)
):
    """
    Use a consumable item.

    For 'xp_token_2x': Activates 24-hour 2x XP boost.
    For 'streak_shield': Manual use (auto-use on missed login is separate).
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        item_type = request.item_type

        logger.info(f"[XP] Use consumable request: user_id={user_id}, item_type={item_type}")

        valid_types = ["streak_shield", "xp_token_2x", "fitness_crate", "premium_crate"]
        if item_type not in valid_types:
            raise HTTPException(status_code=400, detail=f"Invalid item type: {item_type}")

        if item_type == "xp_token_2x":
            # Activate 2x XP token
            result = db.client.rpc(
                "activate_2x_token",
                {"p_user_id": user_id}
            ).execute()

            if result.data:
                logger.info(f"[XP] 2x XP token activated for user {user_id}")
                return {
                    "success": True,
                    "item_type": item_type,
                    "message": "2x XP boost activated for 24 hours!",
                    "active_until": (datetime.utcnow() + timedelta(hours=24)).isoformat()
                }
            else:
                return {
                    "success": False,
                    "item_type": item_type,
                    "message": "No 2x XP tokens available"
                }

        else:
            # Generic consumable use
            result = db.client.rpc(
                "use_consumable",
                {"p_user_id": user_id, "p_item_type": item_type}
            ).execute()

            if result.data:
                return {
                    "success": True,
                    "item_type": item_type,
                    "message": f"{item_type.replace('_', ' ').title()} used!"
                }
            else:
                return {
                    "success": False,
                    "item_type": item_type,
                    "message": f"No {item_type.replace('_', ' ')}s available"
                }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error using consumable: {e}")
        raise safe_internal_error(e, "xp")


# Crate reward definitions
CRATE_REWARDS = {
    "fitness_crate": [
        {"type": "xp", "amount": 50, "weight": 40},
        {"type": "streak_shield", "amount": 1, "weight": 30},
        {"type": "xp_token_2x", "amount": 1, "weight": 20},
        {"type": "xp", "amount": 200, "weight": 10},
    ],
    "premium_crate": [
        {"type": "xp", "amount": 100, "weight": 30},
        {"type": "streak_shield", "amount": 2, "weight": 25},
        {"type": "xp_token_2x", "amount": 2, "weight": 25},
        {"type": "xp", "amount": 500, "weight": 15},
        {"type": "streak_shield", "amount": 3, "weight": 5},
    ],
}


class OpenCrateRequest(BaseModel):
    crate_type: str  # 'fitness_crate' or 'premium_crate'


@router.post("/open-crate")
async def open_crate(
    request: OpenCrateRequest,
    current_user=Depends(get_current_user)
):
    """
    Open a crate and receive a random reward.
    """
    import random

    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        crate_type = request.crate_type

        logger.info(f"[XP] Open crate request: user_id={user_id}, crate_type={crate_type}")

        if crate_type not in CRATE_REWARDS:
            raise HTTPException(status_code=400, detail=f"Invalid crate type: {crate_type}")

        # Check if user has the crate
        result = db.client.rpc(
            "use_consumable",
            {"p_user_id": user_id, "p_item_type": crate_type}
        ).execute()

        if not result.data:
            return {
                "success": False,
                "message": f"No {crate_type.replace('_', ' ')}s available"
            }

        # Roll for reward based on weights
        rewards = CRATE_REWARDS[crate_type]
        total_weight = sum(r["weight"] for r in rewards)
        roll = random.randint(1, total_weight)

        current_weight = 0
        selected_reward = rewards[0]
        for reward in rewards:
            current_weight += reward["weight"]
            if roll <= current_weight:
                selected_reward = reward
                break

        # Award the reward
        reward_type = selected_reward["type"]
        reward_amount = selected_reward["amount"]

        if reward_type == "xp":
            # Award XP
            db.client.rpc(
                "award_xp",
                {
                    "p_user_id": user_id,
                    "p_xp_amount": reward_amount,
                    "p_source": "crate_reward",
                    "p_source_id": crate_type,
                    "p_description": f"Reward from {crate_type.replace('_', ' ')}",
                    "p_is_verified": False
                }
            ).execute()
        else:
            # Award consumable
            db.client.rpc(
                "add_consumable",
                {"p_user_id": user_id, "p_item_type": reward_type, "p_quantity": reward_amount}
            ).execute()

        logger.info(f"[XP] Crate reward: {reward_amount} {reward_type}")

        return {
            "success": True,
            "crate_type": crate_type,
            "reward": {
                "type": reward_type,
                "amount": reward_amount,
                "display_name": f"{reward_amount} {reward_type.replace('_', ' ').title()}{'s' if reward_amount > 1 else ''}"
                    if reward_type != "xp" else f"+{reward_amount} XP"
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error opening crate: {e}")
        raise safe_internal_error(e, "xp")


# =============================================================================
# DAILY CRATE SYSTEM
# =============================================================================

class DailyCratesResponse(BaseModel):
    daily_crate_available: bool = True
    streak_crate_available: bool = False
    activity_crate_available: bool = False
    selected_crate: Optional[str] = None
    reward: Optional[dict] = None
    claimed: bool = False
    claimed_at: Optional[str] = None
    crate_date: str


class ClaimDailyCrateRequest(BaseModel):
    crate_type: str  # 'daily', 'streak', or 'activity'
    crate_date: Optional[str] = None  # ISO date e.g. '2026-04-05'; defaults to today


class ClaimDailyCrateResponse(BaseModel):
    success: bool
    crate_type: Optional[str] = None
    reward: Optional[dict] = None
    message: str


@router.get("/daily-crates", response_model=DailyCratesResponse)
async def get_daily_crates(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Get today's daily crate availability and status.

    Returns which crates are available:
    - daily: Always available
    - streak: Available if streak >= 7 days
    - activity: Available if all daily goals complete
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Resolve user timezone and pass their local date to RPC
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)

        result = db.client.rpc(
            "init_daily_crates",
            {"p_user_id": user_id, "p_user_date": today_str}
        ).execute()

        if result.data:
            data = result.data
            return DailyCratesResponse(
                daily_crate_available=data.get("daily_crate_available", True),
                streak_crate_available=data.get("streak_crate_available", False),
                activity_crate_available=data.get("activity_crate_available", False),
                selected_crate=data.get("selected_crate"),
                reward=data.get("reward"),
                claimed=data.get("claimed", False),
                claimed_at=data.get("claimed_at"),
                crate_date=str(data.get("crate_date", today_str))
            )

        return DailyCratesResponse(crate_date=today_str)

    except Exception as e:
        logger.error(f"[XP] Error getting daily crates: {e}")
        raise safe_internal_error(e, "xp")


@router.get("/unclaimed-crates", response_model=UnclaimedCratesResponse)
async def get_unclaimed_crates(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Get all unclaimed daily crates (up to 9 most recent).

    Returns accumulated unclaimed crate records so users can open
    multiple crates at once if they missed previous days.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Pass user's local date so unclaimed crates are filtered correctly
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)

        result = db.client.rpc(
            "get_unclaimed_crates",
            {"p_user_id": user_id, "p_user_date": today_str}
        ).execute()

        unclaimed_list = result.data or []
        items = [
            UnclaimedCrateItem(
                crate_date=str(item["crate_date"]),
                daily_crate_available=item.get("daily_crate_available", True),
                streak_crate_available=item.get("streak_crate_available", False),
                activity_crate_available=item.get("activity_crate_available", False),
            )
            for item in unclaimed_list
        ]

        return UnclaimedCratesResponse(
            unclaimed=items,
            count=len(items),
        )

    except Exception as e:
        logger.error(f"[XP] Error getting unclaimed crates: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/claim-daily-crate", response_model=ClaimDailyCrateResponse)
async def claim_daily_crate(
    request: ClaimDailyCrateRequest,
    http_request: Request,
    current_user=Depends(get_current_user)
):
    """
    Claim a daily crate (pick 1 of 3 available).

    User can only claim one crate per day.
    Higher tier crates have better rewards:
    - activity > streak > daily
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        crate_type = request.crate_type

        # Resolve user timezone for date validation and default
        user_tz = resolve_timezone(http_request, db, user_id)
        today_str = get_user_today(user_tz)

        crate_date = request.crate_date  # Optional ISO date string

        # Validate crate_date if provided
        if crate_date:
            from datetime import date as date_type
            try:
                crate_date_obj = date_type.fromisoformat(crate_date)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid date format. Use ISO format: YYYY-MM-DD")

            today_obj = date_type.fromisoformat(today_str)

            if crate_date_obj > today_obj:
                raise HTTPException(status_code=400, detail="Cannot claim crates from the future")
            if (today_obj - crate_date_obj).days > 9:
                raise HTTPException(status_code=400, detail="Crate too old to claim (max 9 days)")
        else:
            # Default to user's local today
            crate_date = today_str

        logger.info(f"[XP] Claim daily crate: user_id={user_id}, crate_type={crate_type}, crate_date={crate_date}")

        valid_types = ["daily", "streak", "activity"]
        if crate_type not in valid_types:
            raise HTTPException(status_code=400, detail=f"Invalid crate type: {crate_type}")

        rpc_params = {"p_user_id": user_id, "p_crate_type": crate_type, "p_crate_date": crate_date}

        result = db.client.rpc(
            "claim_daily_crate",
            rpc_params,
        ).execute()

        if result.data:
            data = result.data
            if data.get("success"):
                # RPC returns flat structure (migration 230): reward_type, reward_amount
                reward_type = data.get("reward_type", "xp")
                reward_amount = data.get("reward_amount", 0)

                logger.info(f"[XP] Daily crate reward: {reward_amount} {reward_type}")

                return {
                    "success": True,
                    "crate_type": data.get("crate_type", crate_type),
                    "reward": {
                        "type": reward_type,
                        "amount": reward_amount,
                        "display_name": f"{reward_amount} {reward_type.replace('_', ' ').title()}{'s' if reward_amount > 1 and reward_type != 'xp' else ''}"
                            if reward_type != "xp" else f"+{reward_amount} XP"
                    },
                    "message": data.get("message", "Crate opened!")
                }
            else:
                return {
                    "success": False,
                    "message": data.get("message", "Failed to claim crate")
                }

        return {"success": False, "message": "Failed to claim crate"}

    except HTTPException:
        raise
    except Exception as e:
        # Handle Supabase RPC JSON serialization quirk - data is in error message
        error_str = str(e)
        if "JSON could not be generated" in error_str and "details" in error_str:
            import ast
            import json
            try:
                error_dict = ast.literal_eval(error_str)
                details = error_dict.get('details', '')
                if details.startswith("b'") and details.endswith("'"):
                    json_str = details[2:-1]
                    data = json.loads(json_str)
                    logger.info(f"[XP] claim-daily-crate extracted data from RPC response")

                    # Respect the actual RPC result — don't hardcode success
                    if not data.get("success", False):
                        return ClaimDailyCrateResponse(
                            success=False,
                            message=data.get("message", "Failed to claim crate")
                        )

                    # RPC returns flat structure (migration 230): reward_type, reward_amount
                    reward_type = data.get("reward_type", "xp")
                    reward_amount = data.get("reward_amount", 0)
                    return ClaimDailyCrateResponse(
                        success=True,
                        crate_type=data.get("crate_type"),
                        reward={
                            "type": reward_type,
                            "amount": reward_amount,
                            "display_name": f"+{reward_amount} XP" if reward_type == "xp"
                                else f"{reward_amount} {reward_type.replace('_', ' ').title()}"
                        },
                        message=data.get("message", "Crate opened!")
                    )
            except Exception as parse_error:
                logger.error(f"[XP] Failed to parse RPC response: {parse_error}")

        logger.error(f"[XP] Error claiming daily crate: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/unlock-activity-crate")
async def unlock_activity_crate(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Unlock the activity crate when all daily goals are complete.
    Call this endpoint when the user completes their last daily goal.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Pass user's local date so activity crate unlocks for correct day
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)

        result = db.client.rpc(
            "update_activity_crate_availability",
            {"p_user_id": user_id, "p_user_date": today_str}
        ).execute()

        if result.data:
            logger.info(f"[XP] Activity crate unlocked for user {user_id}")
            return {"success": True, "message": "Activity crate unlocked!"}

        return {"success": False, "message": "Activity crate not available or already claimed"}

    except Exception as e:
        logger.error(f"[XP] Error unlocking activity crate: {e}")
        raise safe_internal_error(e, "xp")


# =============================================================================
# EXTENDED WEEKLY CHECKPOINTS (10 types)
# =============================================================================

@router.get("/weekly-checkpoints")
async def get_weekly_checkpoints(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Get all 10 weekly checkpoint progress items.

    Returns progress for:
    - Workouts (dynamic target based on user's days_per_week)
    - Perfect Week (all scheduled workouts completed)
    - Protein Goals (hit protein 5+ days)
    - Calorie Goals (hit calories 5+ days)
    - Hydration (hit water goal 5+ days)
    - Weight Logs (log weight 3+ times)
    - Habit Completion (80%+ habit completion)
    - Workout Streak (maintain 7+ day streak)
    - Social Engagement (engage with 5+ posts)
    - Body Measurements (log measurements 2+ times)

    Total possible XP: 1,575 per week
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "get_full_weekly_progress",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            return result.data

        # Fallback if RPC doesn't exist yet
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)
        return {
            "week_start": today_str,
            "total_xp_possible": 1575,
            "checkpoints": []
        }

    except Exception as e:
        logger.error(f"[XP] Error getting weekly checkpoints: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/increment-weekly-checkpoint")
async def increment_weekly_checkpoint(
    checkpoint_type: str = Query(..., description="Type: protein, calories, hydration, weight, habits, social, measurements"),
    current_user=Depends(get_current_user)
):
    """
    Increment a specific weekly checkpoint metric.

    Valid types:
    - protein: Hit daily protein goal
    - calories: Hit daily calorie goal
    - hydration: Hit daily water goal
    - weight: Log weight
    - habits: Update habit completion (pass completion_percent query param)
    - social: Engage with a post
    - measurements: Log body measurements
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Map checkpoint_type to RPC function name
        rpc_map = {
            "protein": "increment_weekly_protein",
            "calories": "increment_weekly_calories",
            "hydration": "increment_weekly_hydration",
            "weight": "increment_weekly_weight",
            "social": "increment_weekly_social",
            "measurements": "increment_weekly_measurements",
        }

        if checkpoint_type not in rpc_map:
            raise HTTPException(status_code=400, detail=f"Invalid checkpoint type: {checkpoint_type}")

        result = db.client.rpc(
            rpc_map[checkpoint_type],
            {"p_user_id": user_id}
        ).execute()

        return result.data if result.data else {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error incrementing weekly checkpoint: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/update-weekly-habits")
async def update_weekly_habits(
    completion_percent: float = Query(..., ge=0, le=100, description="Habit completion percentage (0-100)"),
    current_user=Depends(get_current_user)
):
    """
    Update weekly habit completion percentage.
    Awards XP if 80%+ is reached.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "update_weekly_habits",
            {"p_user_id": user_id, "p_completion_percent": completion_percent}
        ).execute()

        return result.data if result.data else {"success": True, "completion_percent": completion_percent}

    except Exception as e:
        logger.error(f"[XP] Error updating weekly habits: {e}")
        raise safe_internal_error(e, "xp")


# =============================================================================
# MONTHLY ACHIEVEMENTS (12 types)
# =============================================================================

@router.get("/monthly-achievements")
async def get_monthly_achievements(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Get all 12 monthly achievement progress items.

    Returns progress for:
    - Monthly Dedication (500 XP) - 20+ active days
    - Monthly Goal (1,000 XP) - Hit primary fitness goal
    - Monthly Nutrition (500 XP) - Hit macros 20+ days
    - Monthly Consistency (750 XP) - No missed scheduled workouts
    - Monthly Hydration (300 XP) - Hit water goal 25+ days
    - Monthly Weight (400 XP) - On track with weight goal
    - Monthly Habits (400 XP) - 80%+ habit completion
    - Monthly PRs (500 XP) - Set 3+ personal records
    - Monthly Social Star (300 XP) - Share 10+ posts
    - Monthly Supporter (200 XP) - React/comment on 50+ posts
    - Monthly Networker (250 XP) - Add 10+ friends
    - Monthly Measurements (150 XP) - Log measurements 8+ times

    Total possible XP: 5,250 per month
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "get_monthly_achievements_progress",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            return result.data

        # Fallback if RPC doesn't exist yet
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)
        return {
            "month": today_str[:7],  # "YYYY-MM"
            "total_xp_possible": 5250,
            "achievements": []
        }

    except Exception as e:
        logger.error(f"[XP] Error getting monthly achievements: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/increment-monthly-achievement")
async def increment_monthly_achievement(
    achievement_type: str = Query(..., description="Type: active_day, nutrition, hydration, pr, posts_shared, social_interaction, friends, measurements"),
    interaction_type: str = Query("reaction", description="For social_interaction: 'reaction' or 'comment'"),
    current_user=Depends(get_current_user)
):
    """
    Increment a specific monthly achievement metric.

    Valid types:
    - active_day: Mark today as active
    - nutrition: Hit macros today
    - hydration: Hit water goal today
    - pr: Set a new personal record
    - posts_shared: Share a post
    - social_interaction: React/comment on a post (specify interaction_type)
    - friends: Add a friend
    - measurements: Log body measurements
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Map achievement_type to RPC function
        rpc_map = {
            "active_day": "increment_monthly_active_day",
            "nutrition": "increment_monthly_nutrition",
            "hydration": "increment_monthly_hydration",
            "pr": "increment_monthly_pr",
            "posts_shared": "increment_monthly_posts_shared",
            "friends": "increment_monthly_friends",
            "measurements": "increment_monthly_measurements",
        }

        if achievement_type == "social_interaction":
            result = db.client.rpc(
                "increment_monthly_social_interaction",
                {"p_user_id": user_id, "p_type": interaction_type}
            ).execute()
        elif achievement_type in rpc_map:
            result = db.client.rpc(
                rpc_map[achievement_type],
                {"p_user_id": user_id}
            ).execute()
        else:
            raise HTTPException(status_code=400, detail=f"Invalid achievement type: {achievement_type}")

        return result.data if result.data else {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error incrementing monthly achievement: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/update-monthly-goal-progress")
async def update_monthly_goal_progress(
    progress: float = Query(..., ge=0, le=100, description="Goal progress percentage (0-100)"),
    current_user=Depends(get_current_user)
):
    """
    Update monthly fitness goal progress.
    Awards 1,000 XP when 100% is reached.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "update_monthly_goal_progress",
            {"p_user_id": user_id, "p_progress": progress}
        ).execute()

        return result.data if result.data else {"success": True, "progress": progress}

    except Exception as e:
        logger.error(f"[XP] Error updating monthly goal progress: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/update-monthly-consistency")
async def update_monthly_consistency(
    scheduled: int = Query(None, ge=0, description="Total scheduled workouts this month"),
    completed: int = Query(None, ge=0, description="Completed workouts this month"),
    missed: int = Query(None, ge=0, description="Missed workouts this month"),
    current_user=Depends(get_current_user)
):
    """
    Update monthly workout consistency tracking.
    Awards 750 XP at month end if no missed workouts.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "update_monthly_consistency",
            {
                "p_user_id": user_id,
                "p_scheduled": scheduled,
                "p_completed": completed,
                "p_missed": missed
            }
        ).execute()

        return result.data if result.data else {"success": True}

    except Exception as e:
        logger.error(f"[XP] Error updating monthly consistency: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/update-monthly-weight-status")
async def update_monthly_weight_status(
    on_track: bool = Query(..., description="Whether user is on track with weight goal"),
    current_user=Depends(get_current_user)
):
    """
    Update monthly weight goal status.
    Awards 400 XP at month end if on track.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "update_monthly_weight_status",
            {"p_user_id": user_id, "p_on_track": on_track}
        ).execute()

        return result.data if result.data else {"success": True, "on_track": on_track}

    except Exception as e:
        logger.error(f"[XP] Error updating monthly weight status: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/update-monthly-habits")
async def update_monthly_habits_endpoint(
    completion_percent: float = Query(..., ge=0, le=100, description="Habit completion percentage (0-100)"),
    current_user=Depends(get_current_user)
):
    """
    Update monthly habit completion percentage.
    Awards 400 XP at month end if 80%+ completion.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "update_monthly_habits",
            {"p_user_id": user_id, "p_completion_percent": completion_percent}
        ).execute()

        return result.data if result.data else {"success": True, "completion_percent": completion_percent}

    except Exception as e:
        logger.error(f"[XP] Error updating monthly habits: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/evaluate-month-end")
async def evaluate_month_end(
    current_user=Depends(get_current_user)
):
    """
    Evaluate and award month-end achievements.
    Call this at the end of the month or when checking final status.

    Awards pending XP for:
    - Monthly Consistency (750 XP) - if no missed workouts
    - Monthly Weight (400 XP) - if on track
    - Monthly Habits (400 XP) - if 80%+ completion
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "evaluate_monthly_achievements",
            {"p_user_id": user_id}
        ).execute()

        return result.data if result.data else {"success": True, "total_xp_awarded": 0}

    except Exception as e:
        logger.error(f"[XP] Error evaluating month-end: {e}")
        raise safe_internal_error(e, "xp")


# =============================================================================
# DAILY SOCIAL XP (4 actions, 270 XP cap)
# =============================================================================

@router.get("/daily-social-xp")
async def get_daily_social_xp(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Get today's social XP status and available actions.

    Returns:
    - Share Post: 15 XP (max 3/day = 45 XP)
    - React to Post: 5 XP (max 10/day = 50 XP)
    - Comment: 10 XP (max 5/day = 50 XP)
    - Add Friend: 25 XP (max 5/day = 125 XP)

    Daily cap: 270 XP total from social actions
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "get_daily_social_xp_status",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            return result.data

        # Fallback if RPC doesn't exist
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)
        return {
            "date": today_str,
            "total_social_xp_today": 0,
            "daily_cap": 270,
            "remaining_cap": 270,
            "at_cap": False,
            "actions": []
        }

    except Exception as e:
        logger.error(f"[XP] Error getting daily social XP: {e}")
        raise safe_internal_error(e, "xp")


@router.post("/award-social-xp")
async def award_social_xp(
    action_type: str = Query(..., description="Type: share, react, comment, friend"),
    current_user=Depends(get_current_user)
):
    """
    Award XP for a social action.

    Action types and XP:
    - share: 15 XP (max 3/day = 45 XP)
    - react: 5 XP (max 10/day = 50 XP)
    - comment: 10 XP (max 5/day = 50 XP)
    - friend: 25 XP (max 5/day = 125 XP)

    Daily cap: 270 XP total
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Map action_type to RPC function
        rpc_map = {
            "share": "award_social_share_xp",
            "react": "award_social_react_xp",
            "comment": "award_social_comment_xp",
            "friend": "award_social_friend_xp",
        }

        if action_type not in rpc_map:
            raise HTTPException(status_code=400, detail=f"Invalid action type: {action_type}")

        result = db.client.rpc(
            rpc_map[action_type],
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            return result.data

        return {"success": True, "xp_awarded": 0}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error awarding social XP: {e}")
        raise safe_internal_error(e, "xp")


# =============================================================================
# LEVEL PROGRESSION (Unified 250-Level System - Migration 227)
# =============================================================================

# XP required for each level (1-175), levels 176-250 are flat 100,000 XP
_XP_TABLE = [
    # Levels 1-10 (Beginner): Quick early wins
    25, 30, 40, 50, 65, 80, 100, 120, 150, 180,
    # Levels 11-25 (Novice)
    200, 220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 420, 440, 460, 500,
    # Levels 26-50 (Apprentice)
    550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1800,
    # Levels 51-75 (Athlete)
    1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4500,
    # Levels 76-100 (Elite)
    4800, 5000, 5200, 5400, 5600, 5800, 6000, 6200, 6400, 6600, 6800, 7000, 7200, 7400, 7600, 7800, 8000, 8200, 8400, 8600, 8800, 9000, 9200, 9400, 10000,
    # Levels 101-125 (Master)
    10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 15500, 16000, 16500, 17000, 17500, 18000, 18500, 19000, 19500, 20000, 20500, 21000, 21500, 22000, 23000,
    # Levels 126-150 (Champion)
    24000, 25000, 26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 41000, 42000, 43000, 44000, 45000, 46000, 47000, 50000,
    # Levels 151-175 (Legend)
    52000, 54000, 56000, 58000, 60000, 62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000
]


def _get_xp_for_level(level: int) -> int:
    """Get XP required to complete the given level (level up to next)."""
    if level >= 250:
        return 0  # Max level
    elif level <= 175:
        return _XP_TABLE[level - 1]
    else:
        # Levels 176-250 are flat 100,000 XP each (prestige tier)
        return 100000


def _get_xp_title(level: int) -> str:
    """Get XP title based on level (11 tiers)."""
    if level <= 10:
        return "Beginner"
    elif level <= 25:
        return "Novice"
    elif level <= 50:
        return "Apprentice"
    elif level <= 75:
        return "Athlete"
    elif level <= 100:
        return "Elite"
    elif level <= 125:
        return "Master"
    elif level <= 150:
        return "Champion"
    elif level <= 175:
        return "Legend"
    elif level <= 200:
        return "Mythic"
    elif level <= 225:
        return "Immortal"
    else:
        return "Transcendent"


@router.get("/level-info")
async def get_level_info(
    level: int = Query(..., ge=1, le=250, description="Level number (1-250)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get XP requirements and rewards for a specific level.

    Unified 250-level progressive system (migration 227):
    - Levels 1-10 (Beginner): 25-180 XP each
    - Levels 11-25 (Novice): 200-500 XP each
    - Levels 26-50 (Apprentice): 550-1,800 XP each
    - Levels 51-75 (Athlete): 1,900-4,500 XP each
    - Levels 76-100 (Elite): 4,800-10,000 XP each
    - Levels 101-125 (Master): 10,500-23,000 XP each
    - Levels 126-150 (Champion): 24,000-50,000 XP each
    - Levels 151-175 (Legend): 52,000-100,000 XP each
    - Levels 176-200 (Mythic): 100,000 XP each
    - Levels 201-225 (Immortal): 100,000 XP each
    - Levels 226-250 (Transcendent): 100,000 XP each
    """
    # Get XP requirement and title using unified formula
    xp_needed = _get_xp_for_level(level)
    title = _get_xp_title(level)

    # Calculate total XP to reach this level
    total_xp = 0
    for l in range(1, level):
        total_xp += _get_xp_for_level(l)

    # Level milestone rewards (updated for new tier system)
    milestone_rewards = {
        5: "Streak Shield x1",
        10: "2x XP Token",
        15: "Fitness Crate x2",
        20: "Streak Shield x2",
        25: "2x XP Token x2",
        30: "Premium Crate",
        40: "Streak Shield x3",
        50: "2x XP Token x3 + Premium Crate",
        60: "Fitness Crate x5",
        75: "Premium Crate x2",
        100: "Elite Badge + Premium Crate x3",
        125: "Master Badge + Master Crate",
        150: "Champion Badge + Champion Crate x2",
        175: "Legend Badge + Legend Crate x3",
        200: "Mythic Badge + Mythic Crate x5",
        225: "Immortal Badge + Immortal Crate x7",
        250: "Transcendent Badge + Legendary Crate x10",
    }

    return {
        "level": level,
        "title": title,
        "xp_to_next_level": xp_needed,
        "total_xp_to_reach": total_xp,
        "milestone_reward": milestone_rewards.get(level)
    }
