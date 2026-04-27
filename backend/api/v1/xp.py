"""
XP Events API - Daily Login, Streaks, Double XP Events
"""
from core import branding
from core.db import get_supabase_db

from .xp_models import *  # noqa: F401, F403
from .xp_endpoints import router as _endpoints_router

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel
from datetime import date, datetime, timedelta
from typing import Optional, List
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, get_user_today, local_date_to_utc_range
from core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/xp", tags=["XP & Progression"])


# Models live in xp_models.py; star-imported above. Do NOT re-declare them
# here — a local redefinition silently diverges from xp_endpoints' copy and
# breaks field validators (see process_daily_login 500, Apr 2026).


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/daily-login", response_model=DailyLoginResponse)
async def process_daily_login(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Process daily login and award XP bonuses.

    Awards:
    - First login bonus (500 XP) for new users
    - Daily check-in bonus (25 × streak day, max 175 XP)
    - Streak milestone bonuses (7, 30, 100, 365 days)
    - Double XP multiplier if event is active
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        logger.info(f"[XP] daily-login called for user_id: {user_id}, auth_id: {current_user.get('auth_id')}")

        # Resolve user timezone and pass their local date to RPC
        user_tz = resolve_timezone(request, db, user_id)
        user_today = get_user_today(user_tz)

        result = db.client.rpc(
            "process_daily_login",
            {"p_user_id": user_id, "p_user_date": user_today}
        ).execute()

        if result.data:
            data = result.data
            # Normalize field names: SQL migration 1884 uses different names than Pydantic model
            if "daily_bonus" in data and "daily_xp" not in data:
                data["daily_xp"] = data.pop("daily_bonus")
            if "streak_bonus" in data and "streak_milestone_xp" not in data:
                data["streak_milestone_xp"] = data.pop("streak_bonus")
            if "max_streak" in data and "longest_streak" not in data:
                data["longest_streak"] = data.pop("max_streak")
            if "multiplier" not in data:
                data["multiplier"] = 1.0
            return DailyLoginResponse(**data)
        else:
            raise safe_internal_error(ValueError("Failed to process daily login"), "xp")

    except HTTPException:
        raise
    except Exception as e:
        # Handle Supabase RPC JSON serialization quirk - data is in error message
        # The Supabase Python client sometimes returns valid data wrapped in an error
        error_str = str(e)
        if "JSON could not be generated" in error_str and "details" in error_str:
            import ast
            import json
            try:
                # Parse the error string as a Python dict
                error_dict = ast.literal_eval(error_str)
                details = error_dict.get('details', '')

                # The details is a string like "b'{json}'"
                if details.startswith("b'") and details.endswith("'"):
                    json_str = details[2:-1]  # Remove b' and trailing '
                    data = json.loads(json_str)
                    # Normalize field names here too
                    if "daily_bonus" in data and "daily_xp" not in data:
                        data["daily_xp"] = data.pop("daily_bonus")
                    if "streak_bonus" in data and "streak_milestone_xp" not in data:
                        data["streak_milestone_xp"] = data.pop("streak_bonus")
                    if "max_streak" in data and "longest_streak" not in data:
                        data["longest_streak"] = data.pop("max_streak")
                    if "multiplier" not in data:
                        data["multiplier"] = 1.0
                    # Ensure already_claimed responses have 0 XP to prevent phantom rewards
                    if data.get("already_claimed"):
                        data.setdefault("total_xp_awarded", 0)
                        data.setdefault("daily_xp", 0)
                        data.setdefault("first_login_xp", 0)
                        data.setdefault("streak_milestone_xp", 0)
                    logger.info(f"[XP] daily-login extracted data from RPC response (already_claimed={data.get('already_claimed', False)})")
                    return DailyLoginResponse(**data)
            except Exception as parse_error:
                logger.error(f"[XP] Failed to parse RPC response: {parse_error}", exc_info=True)

        logger.error(f"[XP] daily-login error: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


@router.get("/login-streak", response_model=LoginStreakInfo)
async def get_login_streak(
    current_user=Depends(get_current_user)
):
    """Get user's login streak information."""
    try:
        db = get_supabase_db()
        result = db.client.rpc(
            "get_login_streak",
            {"p_user_id": current_user["id"]}
        ).execute()

        if result.data:
            return LoginStreakInfo(**result.data)
        else:
            return LoginStreakInfo(
                current_streak=0,
                longest_streak=0,
                total_logins=0,
                has_logged_in_today=False
            )

    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.get("/active-events", response_model=List[XPEvent])
async def get_active_events(
    current_user: dict = Depends(get_current_user),
):
    """Get all currently active XP events (Double XP, etc.)."""
    try:
        db = get_supabase_db()
        result = db.client.rpc("get_active_xp_events").execute()
        return result.data or []

    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.get("/events", response_model=List[XPEvent])
async def get_all_events(
    include_inactive: bool = Query(False, description="Include past/inactive events"),
    current_user: dict = Depends(get_current_user),
):
    """Get all XP events (admin view)."""
    try:
        db = get_supabase_db()
        query = db.client.table("xp_events").select("*").order("start_at", desc=True)

        if not include_inactive:
            query = query.eq("is_active", True)

        result = query.execute()
        return result.data or []

    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.post("/events/enable-double-xp")
async def enable_double_xp_event(
    request: CreateEventRequest,
    current_user=Depends(get_current_user)
):
    """
    Enable a Double XP event (admin only).

    Creates a new XP event with the specified multiplier and duration.
    """
    try:
        db = get_supabase_db()
        result = db.client.rpc(
            "enable_double_xp_event",
            {
                "p_event_name": request.event_name,
                "p_event_type": request.event_type,
                "p_multiplier": request.multiplier,
                "p_duration_hours": request.duration_hours,
                "p_admin_id": current_user["id"]
            }
        ).execute()

        return {
            "event_id": result.data,
            "message": f"{request.event_name} enabled for {request.duration_hours} hours",
            "multiplier": request.multiplier
        }

    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.delete("/events/{event_id}")
async def disable_event(
    event_id: str,
    current_user=Depends(get_current_user)
):
    """Disable/end an XP event early (admin only)."""
    try:
        db = get_supabase_db()
        result = db.client.table("xp_events").update({
            "is_active": False,
            "end_at": datetime.utcnow().isoformat()
        }).eq("id", event_id).execute()

        return {"message": "Event disabled", "event_id": event_id}

    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.get("/bonus-templates", response_model=List[BonusTemplate])
async def get_bonus_templates(
    current_user: dict = Depends(get_current_user),
):
    """Get all XP bonus templates (for reference/admin)."""
    try:
        db = get_supabase_db()
        result = db.client.table("xp_bonus_templates").select("*").order("bonus_type").execute()
        return result.data or []

    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.put("/bonus-templates/{bonus_type}")
async def update_bonus_template(
    bonus_type: str,
    base_xp: int = Query(..., gt=0, description="New base XP amount"),
    is_active: bool = Query(True, description="Whether the bonus is active"),
    current_user=Depends(get_current_user)
):
    """Update an XP bonus template (admin only)."""
    try:
        db = get_supabase_db()
        result = db.client.table("xp_bonus_templates").update({
            "base_xp": base_xp,
            "is_active": is_active
        }).eq("bonus_type", bonus_type).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Bonus template not found")

        return {"message": "Bonus template updated", "bonus_type": bonus_type, "base_xp": base_xp}

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "xp")


@router.get("/checkpoint-progress")
async def get_checkpoint_progress(
    request: Request,
    checkpoint_type: str = Query("weekly", description="'weekly' or 'monthly'"),
    current_user=Depends(get_current_user)
):
    """Get user's weekly or monthly checkpoint progress."""
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Initialize checkpoint progress if needed and get current status
        result = db.client.rpc(
            "init_user_checkpoint_progress",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            data = result.data
            if checkpoint_type in data:
                checkpoint_data = data[checkpoint_type]
                return {
                    "checkpoint_type": checkpoint_type,
                    "period_start": checkpoint_data.get("period_start"),
                    "period_end": checkpoint_data.get("period_end"),
                    "workouts_target": checkpoint_data.get("workouts_target"),
                    "workouts_completed": checkpoint_data.get("workouts_completed", 0),
                    "xp_awarded": checkpoint_data.get("xp_awarded", False),
                    "progress_percent": checkpoint_data.get("progress_percent", 0),
                    "xp_reward": 200 if checkpoint_type == "weekly" else 1000,
                    "days_per_week": checkpoint_data.get("days_per_week")
                }

        # Fallback if RPC doesn't return expected data (uses default 5 days/week)
        user_tz = resolve_timezone(request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        default_days_per_week = 5
        if checkpoint_type == "weekly":
            period_start = today - timedelta(days=today.weekday())
            period_end = period_start + timedelta(days=6)
            target = default_days_per_week  # Dynamic: equals days_per_week
            reward = 200
        else:
            period_start = today.replace(day=1)
            next_month = period_start.replace(day=28) + timedelta(days=4)
            period_end = next_month - timedelta(days=next_month.day)
            target = int(default_days_per_week * 4.3 + 0.99)  # Dynamic: ceil(days_per_week * 4.3)
            reward = 1000

        return {
            "checkpoint_type": checkpoint_type,
            "period_start": period_start.isoformat(),
            "period_end": period_end.isoformat(),
            "workouts_target": target,
            "workouts_completed": 0,
            "xp_awarded": False,
            "progress_percent": 0,
            "xp_reward": reward,
            "days_per_week": default_days_per_week
        }

    except Exception as e:
        logger.error(f"Error getting checkpoint progress: {e}", exc_info=True)
        # Return empty progress on error with default 5 days/week targets
        default_days_per_week = 5
        return {
            "checkpoint_type": checkpoint_type,
            "workouts_target": default_days_per_week if checkpoint_type == "weekly" else int(default_days_per_week * 4.3 + 0.99),
            "workouts_completed": 0,
            "xp_awarded": False,
            "progress_percent": 0,
            "xp_reward": 200 if checkpoint_type == "weekly" else 1000,
            "days_per_week": default_days_per_week
        }


@router.get("/all-checkpoint-progress")
async def get_all_checkpoint_progress(
    current_user=Depends(get_current_user)
):
    """Get both weekly and monthly checkpoint progress."""
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "init_user_checkpoint_progress",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            return result.data

        return {"weekly": None, "monthly": None}

    except Exception as e:
        logger.error(f"Error getting all checkpoint progress: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


@router.post("/increment-checkpoint-workout")
async def increment_checkpoint_workout(
    current_user=Depends(get_current_user)
):
    """
    Increment workout count for weekly/monthly checkpoints.
    Call this when a workout is completed.
    Returns any XP awarded for reaching checkpoints.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        logger.info(f"[XP] Incrementing checkpoint workout for user {user_id}")

        result = db.client.rpc(
            "increment_checkpoint_workout",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            data = result.data
            total_xp = (data.get("weekly_xp_awarded", 0) or 0) + (data.get("monthly_xp_awarded", 0) or 0)

            if total_xp > 0:
                logger.info(f"[XP] Checkpoint XP awarded: weekly={data.get('weekly_xp_awarded')}, monthly={data.get('monthly_xp_awarded')}")

            return {
                "success": True,
                "weekly_xp_awarded": data.get("weekly_xp_awarded", 0),
                "monthly_xp_awarded": data.get("monthly_xp_awarded", 0),
                "weekly_workouts": data.get("weekly_workouts", 0),
                "monthly_workouts": data.get("monthly_workouts", 0),
                "weekly_complete": data.get("weekly_complete", False),
                "monthly_complete": data.get("monthly_complete", False),
                "total_xp_awarded": total_xp
            }

        return {"success": True, "weekly_xp_awarded": 0, "monthly_xp_awarded": 0, "total_xp_awarded": 0}

    except Exception as e:
        logger.error(f"[XP] Error incrementing checkpoint workout: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


@router.post("/award-goal-xp", response_model=AwardGoalXPResponse)
async def award_goal_xp(
    request: AwardGoalXPRequest,
    http_request: Request,
    current_user=Depends(get_current_user)
):
    """
    Award XP for completing daily goals.

    Goal types and XP amounts:
    - weight_log: 15 XP (once per day)
    - meal_log: 25 XP (once per day)
    - workout_complete: 100 XP (once per day)
    - protein_goal: 50 XP (once per day)
    - body_measurements: 20 XP (once per day)
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        logger.info(f"[XP] award-goal-xp called: user_id={user_id}, goal_type={request.goal_type}")

        # Resolve user timezone and get today's UTC range
        user_tz = resolve_timezone(http_request, db, user_id)
        today_str = get_user_today(user_tz)
        today_start_iso, today_end_iso = local_date_to_utc_range(today_str, user_tz)
        logger.info(f"[XP] Checking existing claims from {today_start_iso} to {today_end_iso}")

        # Define XP amounts for each goal type
        goal_xp_amounts = {
            "weight_log": 15,
            "meal_log": 25,
            "workout_complete": 100,
            "protein_goal": 50,
            "body_measurements": 20,
            "steps_goal": 100,
            "hydration_goal": 40,
            "calorie_goal": 60,
        }

        if request.goal_type not in goal_xp_amounts:
            raise HTTPException(status_code=400, detail=f"Invalid goal_type: {request.goal_type}")

        xp_amount = goal_xp_amounts[request.goal_type]
        source = f"daily_goal_{request.goal_type}"

        # Ensure user has a user_xp record (critical for award_xp function to work)
        try:
            db.client.table("user_xp").upsert({
                "user_id": user_id,
                "total_xp": 0,
                "current_level": 1,
                "title": "Novice",
                "trust_level": 1
            }, on_conflict="user_id", ignore_duplicates=True).execute()
            logger.info(f"[XP] Ensured user_xp record exists for user {user_id}")
        except Exception as init_err:
            logger.warning(f"[XP] Could not ensure user_xp record: {init_err}", exc_info=True)

        # Check if already awarded today (prevent double claiming)
        existing = db.client.table("xp_transactions").select("id").eq(
            "user_id", user_id
        ).eq(
            "source", source
        ).gte(
            "created_at", today_start_iso
        ).lt(
            "created_at", today_end_iso
        ).execute()
        logger.info(f"[XP] Existing claims found: {len(existing.data) if existing.data else 0}")

        if existing.data and len(existing.data) > 0:
            logger.warning(f"[XP] Already claimed {request.goal_type} today, returning 0 XP")
            return AwardGoalXPResponse(
                success=True,
                xp_awarded=0,
                message=f"Already claimed {request.goal_type} XP today",
                already_claimed=True
            )

        # Award XP using the award_xp function
        logger.info(f"[XP] Calling award_xp RPC with amount={xp_amount}, source={source}")
        result = db.client.rpc(
            "award_xp",
            {
                "p_user_id": user_id,
                "p_xp_amount": xp_amount,
                "p_source": source,
                "p_source_id": request.source_id,
                "p_description": f"Daily goal: {request.goal_type.replace('_', ' ')}",
                "p_is_verified": False
            }
        ).execute()
        logger.info(f"[XP] award_xp RPC result: {result.data}")

        # Get actual XP awarded from the result (accounts for trust_level multiplier)
        actual_xp_awarded = xp_amount
        if result.data:
            # The award_xp function returns the updated user_xp record
            # We need to check xp_transactions for the actual amount
            try:
                recent_tx = db.client.table("xp_transactions").select("xp_amount").eq(
                    "user_id", user_id
                ).eq(
                    "source", source
                ).order("created_at", desc=True).limit(1).execute()
                if recent_tx.data and len(recent_tx.data) > 0:
                    actual_xp_awarded = recent_tx.data[0].get("xp_amount", xp_amount)
            except Exception as tx_err:
                logger.warning(f"Could not fetch actual XP amount: {tx_err}", exc_info=True)

        logger.info(f"[XP] Successfully awarded {actual_xp_awarded} XP for {request.goal_type}")
        return AwardGoalXPResponse(
            success=True,
            xp_awarded=actual_xp_awarded,
            message=f"+{actual_xp_awarded} XP for {request.goal_type.replace('_', ' ')}!"
        )

    except HTTPException:
        raise
    except Exception as e:
        # Handle race condition: unique index violation means another concurrent
        # request already awarded XP for this goal today
        error_str = str(e).lower()
        if "unique" in error_str or "duplicate" in error_str or "idx_xp_transactions_daily_goal_dedup" in error_str:
            logger.warning(f"[XP] Race condition caught: {request.goal_type} already awarded (concurrent request)", exc_info=True)
            return AwardGoalXPResponse(
                success=True,
                xp_awarded=0,
                message=f"Already claimed {request.goal_type} XP today",
                already_claimed=True
            )
        logger.error(f"[XP] Error awarding goal XP: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


@router.get("/daily-goals-status", response_model=DailyGoalsStatusResponse)
async def get_daily_goals_status(
    request: Request,
    current_user=Depends(get_current_user)
):
    """
    Get today's goal completion status for UI sync.

    Returns which daily goals have been completed today (weight_log, meal_log, etc.)
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)
        today_start_iso, today_end_iso = local_date_to_utc_range(today_str, user_tz)

        result = db.client.table("xp_transactions").select("source").eq(
            "user_id", user_id
        ).gte(
            "created_at", today_start_iso
        ).lt(
            "created_at", today_end_iso
        ).execute()

        sources = [r.get("source", "") for r in (result.data or [])]

        return DailyGoalsStatusResponse(
            weight_log="daily_goal_weight_log" in sources,
            meal_log="daily_goal_meal_log" in sources,
            workout_complete="daily_goal_workout_complete" in sources,
            protein_goal="daily_goal_protein_goal" in sources,
            body_measurements="daily_goal_body_measurements" in sources,
            steps_goal="daily_goal_steps_goal" in sources,
            hydration_goal="daily_goal_hydration_goal" in sources,
            calorie_goal="daily_goal_calorie_goal" in sources,
        )

    except Exception as e:
        logger.error(f"Error getting daily goals status: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


# =============================================================================
# ONE-TIME BONUSES (First-Time Actions)
# =============================================================================

# First-time bonus types and their XP amounts (matches XP_SYSTEM_GUIDE.md)
FIRST_TIME_BONUSES = {
    # Account Milestones (Welcome Bonus is handled by daily login's first_login)
    "first_chat": 15,               # First Chat with AI Coach (reduced to prevent level inflation)
    "first_complete_profile": 0,    # Complete Profile (no XP - happens during onboarding)
    # First Meal Logs
    "first_breakfast": 50,
    "first_lunch": 50,
    "first_dinner": 50,
    "first_snack": 25,
    # First Goal Achievements
    "first_workout": 150,
    "first_protein_goal": 100,
    "first_calorie_goal": 100,
    "first_weight_log": 50,
    "first_fasting": 75,
    # First Feature Usage
    "first_recipe": 50,
    "first_template": 25,           # First Meal Template Saved
    "first_progress_photo": 75,
    "first_habit": 25,
    "first_pr": 100,
    "first_body_measurements": 50,
    # First Social Actions
    "first_friend": 50,
    "first_post": 75,               # First Social Post
    "first_reaction": 10,
    "first_comment": 15,
    "first_share": 25,              # First Post Shared
}


@router.post("/award-first-time-bonus", response_model=FirstTimeBonusResponse)
async def award_first_time_bonus(
    request: FirstTimeBonusRequest,
    current_user=Depends(get_current_user)
):
    """
    Award XP for completing a first-time action.

    Each bonus type can only be awarded once per user.
    Returns the XP awarded (0 if already claimed).
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        bonus_type = request.bonus_type

        logger.info(f"[XP] First-time bonus request: user_id={user_id}, bonus_type={bonus_type}")

        if bonus_type not in FIRST_TIME_BONUSES:
            raise HTTPException(status_code=400, detail=f"Invalid bonus type: {bonus_type}")

        xp_amount = FIRST_TIME_BONUSES[bonus_type]

        # Check if already awarded
        existing = db.client.table("user_first_time_bonuses").select("id").eq(
            "user_id", user_id
        ).eq(
            "bonus_type", bonus_type
        ).execute()

        if existing.data and len(existing.data) > 0:
            logger.warning(f"[XP] First-time bonus {bonus_type} already awarded to user {user_id}")
            return FirstTimeBonusResponse(
                awarded=False,
                xp=0,
                bonus_type=bonus_type,
                message=f"Already received {bonus_type} bonus"
            )

        # Ensure user has a user_xp record
        try:
            db.client.table("user_xp").upsert({
                "user_id": user_id,
                "total_xp": 0,
                "current_level": 1,
                "title": "Novice",
                "trust_level": 1
            }, on_conflict="user_id", ignore_duplicates=True).execute()
        except Exception as init_err:
            logger.warning(f"[XP] Could not ensure user_xp record: {init_err}", exc_info=True)

        # Record the bonus
        db.client.table("user_first_time_bonuses").insert({
            "user_id": user_id,
            "bonus_type": bonus_type,
            "xp_awarded": xp_amount
        }).execute()

        # Award XP using the award_xp function
        db.client.rpc(
            "award_xp",
            {
                "p_user_id": user_id,
                "p_xp_amount": xp_amount,
                "p_source": "first_time_bonus",
                "p_source_id": bonus_type,
                "p_description": f"First-time bonus: {bonus_type.replace('_', ' ')}",
                "p_is_verified": False
            }
        ).execute()

        logger.info(f"[XP] Awarded {xp_amount} XP for first-time bonus: {bonus_type}")
        return FirstTimeBonusResponse(
            awarded=True,
            xp=xp_amount,
            bonus_type=bonus_type,
            message=f"+{xp_amount} XP for {bonus_type.replace('_', ' ')}!"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error awarding first-time bonus: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


@router.get("/first-time-bonuses", response_model=List[FirstTimeBonusInfo])
async def get_first_time_bonuses(
    current_user=Depends(get_current_user)
):
    """
    Get all first-time bonuses that have been awarded to the user.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.table("user_first_time_bonuses").select(
            "bonus_type", "xp_awarded", "awarded_at"
        ).eq(
            "user_id", user_id
        ).order("awarded_at", desc=True).execute()

        return [
            FirstTimeBonusInfo(
                bonus_type=r["bonus_type"],
                xp_awarded=r["xp_awarded"],
                awarded_at=r["awarded_at"]
            )
            for r in (result.data or [])
        ]

    except Exception as e:
        logger.error(f"[XP] Error getting first-time bonuses: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


@router.get("/available-first-time-bonuses")
async def get_available_first_time_bonuses(
    current_user=Depends(get_current_user)
):
    """
    Get list of first-time bonuses that haven't been claimed yet.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Get already awarded bonuses
        result = db.client.table("user_first_time_bonuses").select(
            "bonus_type"
        ).eq(
            "user_id", user_id
        ).execute()

        awarded = {r["bonus_type"] for r in (result.data or [])}

        # Return all bonuses with their status
        bonuses = []
        for bonus_type, xp_amount in FIRST_TIME_BONUSES.items():
            bonuses.append({
                "bonus_type": bonus_type,
                "xp_amount": xp_amount,
                "awarded": bonus_type in awarded
            })

        return {"bonuses": bonuses}

    except Exception as e:
        logger.error(f"[XP] Error getting available first-time bonuses: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


# =============================================================================
# CONSUMABLES SYSTEM
# =============================================================================

@router.get("/consumables", response_model=ConsumablesResponse)
async def get_consumables(
    current_user=Depends(get_current_user)
):
    """
    Get user's current consumable inventory.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Get consumables via RPC (initializes if needed)
        result = db.client.rpc(
            "get_user_consumables",
            {"p_user_id": user_id}
        ).execute()

        consumables = result.data or {}

        # Check if 2x XP is active
        xp_result = db.client.table("user_xp").select(
            "active_2x_token_until"
        ).eq("user_id", user_id).single().execute()

        active_until = None
        if xp_result.data and xp_result.data.get("active_2x_token_until"):
            active_until_dt = xp_result.data["active_2x_token_until"]
            if isinstance(active_until_dt, str):
                from datetime import datetime as dt
                try:
                    parsed = dt.fromisoformat(active_until_dt.replace('Z', '+00:00'))
                    if parsed > datetime.utcnow().replace(tzinfo=parsed.tzinfo):
                        active_until = active_until_dt
                except Exception as e:
                    logger.debug(f"Failed to parse 2x token date: {e}")

        return ConsumablesResponse(
            streak_shield=consumables.get("streak_shield", 0),
            xp_token_2x=consumables.get("xp_token_2x", 0),
            fitness_crate=consumables.get("fitness_crate", 0),
            premium_crate=consumables.get("premium_crate", 0),
            active_2x_until=active_until
        )

    except Exception as e:
        logger.error(f"[XP] Error getting consumables: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")



# =============================================================================
# WEEKLY SUMMARY — hero metric for the XP card (Phase 2b)
# =============================================================================


@router.get("/weekly-summary", response_model=WeeklySummaryResponse)
async def get_weekly_xp_summary(
    user_id: Optional[str] = Query(default=None),
    current_user=Depends(get_current_user),
):
    """Aggregate XP earned this week, last week, and per-day for 7 days.

    Implementation note: runs a single ranged query on `xp_transactions`
    over the last 14 days and buckets rows locally. A server-side aggregate
    RPC would be marginally faster but forking RPCs for every dashboard
    card is worse debt than a 14-day row scan — the table is indexed on
    user_id + created_at.
    """
    try:
        db = get_supabase_db()
        target_user_id = user_id or current_user["id"]

        # Only allow the caller to read their own summary. Matches the RLS
        # policy on `xp_transactions` so a malformed service-role query
        # still returns the right slice.
        if target_user_id != current_user["id"]:
            raise HTTPException(status_code=403, detail="Cannot read another user's XP summary")

        # Compute UTC windows — the UI reframes in local tz via the date
        # column when needed. Sparkline is 7 days inclusive of today.
        now = datetime.utcnow()
        start_14d = (now - timedelta(days=14)).isoformat()

        result = db.client.table("xp_transactions").select(
            "xp_amount, created_at"
        ).eq("user_id", target_user_id).gte("created_at", start_14d).execute()

        rows = result.data or []

        # Bucket into per-day totals (UTC day-boundaries). Good-enough for
        # a weekly-XP card; the absolute timestamps still respect the tz.
        today = now.date()
        by_day: dict[date, int] = {}
        for row in rows:
            ts = row.get("created_at")
            amt = int(row.get("xp_amount") or 0)
            if not ts or amt == 0:
                continue
            try:
                d = datetime.fromisoformat(ts.replace("Z", "+00:00")).date()
            except Exception:
                continue
            by_day[d] = by_day.get(d, 0) + amt

        # Sparkline: oldest-first so the UI can map index → day ago.
        sparkline = [by_day.get(today - timedelta(days=i), 0) for i in range(6, -1, -1)]

        this_week_xp = sum(
            amt for d, amt in by_day.items() if d > today - timedelta(days=7)
        )
        last_week_xp = sum(
            amt for d, amt in by_day.items()
            if today - timedelta(days=14) < d <= today - timedelta(days=7)
        )

        # Nudge selection — prioritise the fastest XP-earning action the
        # user hasn't completed today. Kept as a small deterministic switch
        # (not LLM) so the label is predictable and testable.
        # `log_breakfast` is the default because it's universally available
        # and cheap. Phase 2b UI can expand this pool.
        nudge = ""
        try:
            # Check if user has any food log today
            start_today = datetime.combine(today, datetime.min.time()).isoformat()
            food_res = db.client.table("food_logs").select(
                "id", count="exact"
            ).eq("user_id", target_user_id).gte("logged_at", start_today).limit(1).execute()
            logged_food_today = (food_res.count or 0) > 0
            if not logged_food_today:
                nudge = "log_breakfast"
            else:
                # Fall through: check if they logged a workout today
                wk_res = db.client.table("workout_logs").select(
                    "id", count="exact"
                ).eq("user_id", target_user_id).gte("completed_at", start_today).limit(1).execute()
                if (wk_res.count or 0) == 0:
                    nudge = "log_workout"
        except Exception as e:
            # Nudge is best-effort — never block the summary on it.
            logger.debug(f"[XP] weekly-summary nudge probe failed: {e}")

        return WeeklySummaryResponse(
            this_week_xp=this_week_xp,
            last_week_xp=last_week_xp,
            sparkline_7day=sparkline,
            next_nudge=nudge,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[XP] Error computing weekly summary: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


# =============================================================================
# NEXT LEVEL PREVIEW — what's on the other side of the progress bar
# =============================================================================


# Config-driven reward catalogue. Keyed by the *next* level (i.e. what the
# user is currently progressing toward). Intermediate levels fall back to
# the generic cosmetic tier so the preview row is never empty.
#
# Source-of-truth rule: any change here must land with the same copy in the
# Flutter-side catalogue (`data/models/level_reward.dart` or the level-up
# celebration sheet) so the preview and the actual ceremony stay in sync.
_LEVEL_REWARDS: dict[int, dict] = {
    2:  {"kind": "cosmetic",   "label": "New avatar frame",              "icon": "shield_rounded",           "tier": "silver"},
    3:  {"kind": "cosmetic",   "label": "Bronze progress badge",         "icon": "workspace_premium",        "tier": "silver"},
    4:  {"kind": "cosmetic",   "label": "Profile accent palette",        "icon": "palette_outlined",         "tier": "silver"},
    5:  {"kind": "functional", "label": "Second coach persona",          "icon": "switch_account_outlined",  "tier": "gold"},
    6:  {"kind": "cosmetic",   "label": "Silver progress badge",         "icon": "workspace_premium",        "tier": "silver"},
    7:  {"kind": "cosmetic",   "label": "Themed app icon",               "icon": "apps_outlined",            "tier": "silver"},
    8:  {"kind": "cosmetic",   "label": "Custom streak flame color",     "icon": "local_fire_department",    "tier": "silver"},
    9:  {"kind": "cosmetic",   "label": "Gold progress badge",           "icon": "workspace_premium",        "tier": "gold"},
    10: {"kind": "functional", "label": "Muscle-volume heatmap",         "icon": "insights_rounded",         "tier": "gold"},
    15: {"kind": "functional", "label": "Auto rest-day rescheduling",    "icon": "event_repeat_rounded",     "tier": "gold"},
    20: {"kind": "merch",      "label": "Physical sticker pack",         "icon": "local_shipping_outlined",  "tier": "platinum"},
    25: {"kind": "pricing",    "label": "Retention pricing unlock",      "icon": "sell_outlined",            "tier": "platinum"},
    50: {"kind": "merch",      "label": f"{branding.MERCH_PRODUCT_PREFIX} t-shirt", "icon": "checkroom_outlined", "tier": "platinum"},
    100:{"kind": "merch",      "label": f"{branding.MERCH_PRODUCT_PREFIX} hoodie",  "icon": "checkroom_outlined", "tier": "platinum"},
}

_FALLBACK_REWARD = {
    "kind": "cosmetic",
    "label": "New cosmetic unlock",
    "icon": "auto_awesome_outlined",
    "tier": "silver",
}


def _reward_for_next_level(next_level: int) -> NextLevelRewardBlock:
    """Pick the reward for the *next* level.

    Exact match → use the configured reward.
    No match → walk down to the most recent milestone ≤ next_level; if the
    last milestone's tier implies ongoing unlocks (merch / pricing keep
    their appeal between drops), we re-use its label. Otherwise fall back
    to the generic cosmetic entry so the card never reads blank.
    """
    if next_level in _LEVEL_REWARDS:
        return NextLevelRewardBlock(**_LEVEL_REWARDS[next_level])
    # For "in-between" levels, keep the reward preview motivating by using
    # the generic cosmetic tier rather than repeating the last milestone —
    # users would otherwise see "Physical sticker pack" for Lv 21–24 which
    # is misleading.
    return NextLevelRewardBlock(**_FALLBACK_REWARD)


@router.get("/next-level-preview", response_model=NextLevelPreviewResponse)
async def get_next_level_preview(
    user_id: Optional[str] = Query(default=None),
    current_user=Depends(get_current_user),
):
    """Return current level, progress, and the reward for the next level.

    Single source of truth for the XP-card "next-level unlock" chip. The UI
    renders whichever tier/kind the server picks — it never hardcodes.
    """
    try:
        db = get_supabase_db()
        target_user_id = user_id or current_user["id"]

        if target_user_id != current_user["id"]:
            raise HTTPException(status_code=403, detail="Cannot read another user's XP")

        result = db.client.table("user_xp").select(
            "current_level, xp_in_current_level, xp_to_next_level"
        ).eq("user_id", target_user_id).single().execute()

        row = result.data or {}
        level = int(row.get("current_level") or 1)
        xp_in = int(row.get("xp_in_current_level") or 0)
        xp_to_next = int(row.get("xp_to_next_level") or 150)

        return NextLevelPreviewResponse(
            level=level,
            xp_in_level=xp_in,
            xp_to_next=xp_to_next,
            reward=_reward_for_next_level(level + 1),
        )

    except HTTPException:
        raise
    except Exception as e:
        # If the user has no `user_xp` row yet (fresh signup before the
        # first XP-earning action), return the L1→L2 preview with zeroes
        # instead of a 500. The preview card is a motivational affordance,
        # not a hard requirement.
        msg = str(e).lower()
        if "no rows" in msg or "not found" in msg:
            return NextLevelPreviewResponse(
                level=1,
                xp_in_level=0,
                xp_to_next=150,
                reward=_reward_for_next_level(2),
            )
        logger.error(f"[XP] Error computing next-level preview: {e}", exc_info=True)
        raise safe_internal_error(e, "xp")


# Include secondary endpoints
router.include_router(_endpoints_router)
