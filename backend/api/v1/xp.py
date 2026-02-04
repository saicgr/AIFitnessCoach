"""
XP Events API - Daily Login, Streaks, Double XP Events
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from datetime import date, datetime, timedelta
from typing import Optional, List
from core.supabase_db import get_supabase_db
from core.auth import get_current_user

router = APIRouter(prefix="/xp", tags=["XP & Progression"])


# =============================================================================
# MODELS
# =============================================================================

class DailyLoginResponse(BaseModel):
    is_first_login: bool
    streak_broken: bool
    current_streak: int
    longest_streak: int
    total_logins: int
    daily_xp: int
    first_login_xp: int
    streak_milestone_xp: int
    total_xp_awarded: int
    active_events: Optional[List[dict]] = None
    multiplier: float
    message: str
    already_claimed: bool = False


class LoginStreakInfo(BaseModel):
    current_streak: int
    longest_streak: int
    total_logins: int
    last_login_date: Optional[str] = None
    first_login_at: Optional[str] = None
    streak_start_date: Optional[str] = None
    has_logged_in_today: bool


class XPEvent(BaseModel):
    id: str
    event_name: str
    event_type: str
    description: Optional[str] = None
    xp_multiplier: float
    start_at: datetime
    end_at: datetime
    is_active: bool
    applies_to: List[str]
    icon_name: Optional[str] = None
    banner_color: Optional[str] = None


class CreateEventRequest(BaseModel):
    event_name: str = "Double XP Weekend"
    event_type: str = "weekend_bonus"
    multiplier: float = 2.0
    duration_hours: int = 48


class BonusTemplate(BaseModel):
    id: str
    bonus_type: str
    base_xp: int
    description: Optional[str] = None
    streak_multiplier: bool
    max_streak_multiplier: int
    is_active: bool


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/daily-login", response_model=DailyLoginResponse)
async def process_daily_login(
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
        print(f"🔍 [XP] daily-login called for user_id: {user_id}, auth_id: {current_user.get('auth_id')}")
        result = db.client.rpc(
            "process_daily_login",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            return DailyLoginResponse(**result.data)
        else:
            raise HTTPException(status_code=500, detail="Failed to process daily login")

    except HTTPException:
        raise
    except Exception as e:
        # Handle JSON parsing errors from Supabase client - extract data from error message
        error_str = str(e)
        if "JSON could not be generated" in error_str and "details" in error_str:
            import json
            import ast
            try:
                # Parse the error dict
                error_dict = ast.literal_eval(error_str)
                details = error_dict.get('details', '')
                # The details is a bytes string representation, extract it
                if details.startswith("b'") or details.startswith('b"'):
                    json_str = details[2:-1]  # Remove b' and trailing '
                    # Unescape the string
                    json_str = json_str.replace("\\'", "'").replace('\\"', '"')
                    data = json.loads(json_str)
                    return DailyLoginResponse(**data)
            except Exception as parse_error:
                print(f"Failed to parse RPC response: {parse_error}")
        raise HTTPException(status_code=500, detail=str(e))


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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/active-events", response_model=List[XPEvent])
async def get_active_events():
    """Get all currently active XP events (Double XP, etc.)."""
    try:
        db = get_supabase_db()
        result = db.client.rpc("get_active_xp_events").execute()
        return result.data or []

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/events", response_model=List[XPEvent])
async def get_all_events(
    include_inactive: bool = Query(False, description="Include past/inactive events"),
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
        raise HTTPException(status_code=500, detail=str(e))


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
        raise HTTPException(status_code=500, detail=str(e))


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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/bonus-templates", response_model=List[BonusTemplate])
async def get_bonus_templates():
    """Get all XP bonus templates (for reference/admin)."""
    try:
        db = get_supabase_db()
        result = db.client.table("xp_bonus_templates").select("*").order("bonus_type").execute()
        return result.data or []

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/checkpoint-progress")
async def get_checkpoint_progress(
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
        today = date.today()
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
        print(f"Error getting checkpoint progress: {e}")
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
        print(f"Error getting all checkpoint progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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

        print(f"🎯 [XP] Incrementing checkpoint workout for user {user_id}")

        result = db.client.rpc(
            "increment_checkpoint_workout",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            data = result.data
            total_xp = (data.get("weekly_xp_awarded", 0) or 0) + (data.get("monthly_xp_awarded", 0) or 0)

            if total_xp > 0:
                print(f"🎉 [XP] Checkpoint XP awarded: weekly={data.get('weekly_xp_awarded')}, monthly={data.get('monthly_xp_awarded')}")

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
        print(f"❌ [XP] Error incrementing checkpoint workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class AwardGoalXPRequest(BaseModel):
    goal_type: str  # 'weight_log', 'meal_log', 'workout_complete', 'protein_goal'
    source_id: Optional[str] = None  # Optional ID of the source (e.g., workout ID)


class AwardGoalXPResponse(BaseModel):
    success: bool
    xp_awarded: int
    message: str
    already_claimed: bool = False


@router.post("/award-goal-xp", response_model=AwardGoalXPResponse)
async def award_goal_xp(
    request: AwardGoalXPRequest,
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
        print(f"🎯 [XP] award-goal-xp called: user_id={user_id}, goal_type={request.goal_type}")

        # Use UTC timestamps with timezone for proper comparison with TIMESTAMPTZ
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)
        print(f"🔍 [XP] Checking existing claims from {today_start.isoformat()}Z to {today_end.isoformat()}Z")

        # Define XP amounts for each goal type
        goal_xp_amounts = {
            "weight_log": 15,
            "meal_log": 25,
            "workout_complete": 100,
            "protein_goal": 50,
            "body_measurements": 20,
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
            print(f"✅ [XP] Ensured user_xp record exists for user {user_id}")
        except Exception as init_err:
            print(f"⚠️ [XP] Could not ensure user_xp record: {init_err}")

        # Check if already awarded today (prevent double claiming)
        # Use ISO format with Z suffix for UTC timezone
        existing = db.client.table("xp_transactions").select("id").eq(
            "user_id", user_id
        ).eq(
            "source", source
        ).gte(
            "created_at", today_start.isoformat() + "Z"
        ).lt(
            "created_at", today_end.isoformat() + "Z"
        ).execute()
        print(f"🔍 [XP] Existing claims found: {len(existing.data) if existing.data else 0}")

        if existing.data and len(existing.data) > 0:
            print(f"⚠️ [XP] Already claimed {request.goal_type} today, returning 0 XP")
            return AwardGoalXPResponse(
                success=True,
                xp_awarded=0,
                message=f"Already claimed {request.goal_type} XP today",
                already_claimed=True
            )

        # Award XP using the award_xp function
        print(f"🎯 [XP] Calling award_xp RPC with amount={xp_amount}, source={source}")
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
        print(f"✅ [XP] award_xp RPC result: {result.data}")

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
                print(f"Warning: Could not fetch actual XP amount: {tx_err}")

        print(f"🎉 [XP] Successfully awarded {actual_xp_awarded} XP for {request.goal_type}")
        return AwardGoalXPResponse(
            success=True,
            xp_awarded=actual_xp_awarded,
            message=f"+{actual_xp_awarded} XP for {request.goal_type.replace('_', ' ')}!"
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ [XP] Error awarding goal XP: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class DailyGoalsStatusResponse(BaseModel):
    weight_log: bool = False
    meal_log: bool = False
    workout_complete: bool = False
    protein_goal: bool = False
    body_measurements: bool = False


@router.get("/daily-goals-status", response_model=DailyGoalsStatusResponse)
async def get_daily_goals_status(
    current_user=Depends(get_current_user)
):
    """
    Get today's goal completion status for UI sync.

    Returns which daily goals have been completed today (weight_log, meal_log, etc.)
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

        result = db.client.table("xp_transactions").select("source").eq(
            "user_id", user_id
        ).gte(
            "created_at", today_start.isoformat() + "Z"
        ).execute()

        sources = [r.get("source", "") for r in (result.data or [])]

        return DailyGoalsStatusResponse(
            weight_log="daily_goal_weight_log" in sources,
            meal_log="daily_goal_meal_log" in sources,
            workout_complete="daily_goal_workout_complete" in sources,
            protein_goal="daily_goal_protein_goal" in sources,
            body_measurements="daily_goal_body_measurements" in sources,
        )

    except Exception as e:
        print(f"Error getting daily goals status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# ONE-TIME BONUSES (First-Time Actions)
# =============================================================================

# First-time bonus types and their XP amounts (matches XP_SYSTEM_GUIDE.md)
FIRST_TIME_BONUSES = {
    # Account Milestones (Welcome Bonus is handled by daily login's first_login)
    "first_chat": 50,               # First Chat with AI Coach
    "first_complete_profile": 100,  # Complete Profile bonus
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


class FirstTimeBonusRequest(BaseModel):
    bonus_type: str


class FirstTimeBonusResponse(BaseModel):
    awarded: bool
    xp: int
    bonus_type: str
    message: str


class FirstTimeBonusInfo(BaseModel):
    bonus_type: str
    xp_awarded: int
    awarded_at: str


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

        print(f"🎁 [XP] First-time bonus request: user_id={user_id}, bonus_type={bonus_type}")

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
            print(f"⚠️ [XP] First-time bonus {bonus_type} already awarded to user {user_id}")
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
            print(f"⚠️ [XP] Could not ensure user_xp record: {init_err}")

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

        print(f"🎉 [XP] Awarded {xp_amount} XP for first-time bonus: {bonus_type}")
        return FirstTimeBonusResponse(
            awarded=True,
            xp=xp_amount,
            bonus_type=bonus_type,
            message=f"+{xp_amount} XP for {bonus_type.replace('_', ' ')}!"
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ [XP] Error awarding first-time bonus: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error getting first-time bonuses: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error getting available first-time bonuses: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# CONSUMABLES SYSTEM
# =============================================================================

class UseConsumableRequest(BaseModel):
    item_type: str  # 'streak_shield', 'xp_token_2x', 'fitness_crate', 'premium_crate'


class ConsumablesResponse(BaseModel):
    streak_shield: int = 0
    xp_token_2x: int = 0
    fitness_crate: int = 0
    premium_crate: int = 0
    active_2x_until: Optional[str] = None


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
                except:
                    pass

        return ConsumablesResponse(
            streak_shield=consumables.get("streak_shield", 0),
            xp_token_2x=consumables.get("xp_token_2x", 0),
            fitness_crate=consumables.get("fitness_crate", 0),
            premium_crate=consumables.get("premium_crate", 0),
            active_2x_until=active_until
        )

    except Exception as e:
        print(f"❌ [XP] Error getting consumables: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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

        print(f"🎁 [XP] Use consumable request: user_id={user_id}, item_type={item_type}")

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
                print(f"✅ [XP] 2x XP token activated for user {user_id}")
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
        print(f"❌ [XP] Error using consumable: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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

        print(f"🎁 [XP] Open crate request: user_id={user_id}, crate_type={crate_type}")

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

        print(f"🎉 [XP] Crate reward: {reward_amount} {reward_type}")

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
        print(f"❌ [XP] Error opening crate: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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


@router.get("/daily-crates", response_model=DailyCratesResponse)
async def get_daily_crates(
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

        result = db.client.rpc(
            "init_daily_crates",
            {"p_user_id": user_id}
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
                crate_date=str(data.get("crate_date", date.today().isoformat()))
            )

        return DailyCratesResponse(crate_date=date.today().isoformat())

    except Exception as e:
        print(f"❌ [XP] Error getting daily crates: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/claim-daily-crate")
async def claim_daily_crate(
    request: ClaimDailyCrateRequest,
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

        print(f"🎁 [XP] Claim daily crate: user_id={user_id}, crate_type={crate_type}")

        valid_types = ["daily", "streak", "activity"]
        if crate_type not in valid_types:
            raise HTTPException(status_code=400, detail=f"Invalid crate type: {crate_type}")

        result = db.client.rpc(
            "claim_daily_crate",
            {"p_user_id": user_id, "p_crate_type": crate_type}
        ).execute()

        if result.data:
            data = result.data
            if data.get("success"):
                reward = data.get("reward", {})
                reward_type = reward.get("type", "xp")
                reward_amount = reward.get("amount", 0)

                print(f"🎉 [XP] Daily crate reward: {reward_amount} {reward_type}")

                return {
                    "success": True,
                    "crate_type": crate_type,
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
        # Handle JSON parsing errors from Supabase client - extract data from error message
        error_str = str(e)
        print(f"🔍 [XP] Claim daily crate exception: {error_str}")
        if "JSON could not be generated" in error_str:
            import json
            import re
            try:
                # Extract the JSON from the bytes string in the details
                # Pattern matches: b'{"reward": ...}' with nested objects
                match = re.search(r"b'(\{[^}]*\"reward\"[^}]*\{[^}]*\}[^}]*\})'", error_str)
                if match:
                    json_str = match.group(1)
                    data = json.loads(json_str)
                    print(f"✅ [XP] Parsed RPC response from error: {data}")
                    if data.get("success"):
                        reward = data.get("reward", {})
                        reward_type = reward.get("type", "xp")
                        reward_amount = reward.get("amount", 0)
                        print(f"🎉 [XP] Daily crate reward (from error parse): {reward_amount} {reward_type}")
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
            except Exception as parse_error:
                print(f"❌ [XP] Failed to parse RPC response: {parse_error}")
        print(f"❌ [XP] Error claiming daily crate: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/unlock-activity-crate")
async def unlock_activity_crate(
    current_user=Depends(get_current_user)
):
    """
    Unlock the activity crate when all daily goals are complete.
    Call this endpoint when the user completes their last daily goal.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.rpc(
            "update_activity_crate_availability",
            {"p_user_id": user_id}
        ).execute()

        if result.data:
            print(f"✅ [XP] Activity crate unlocked for user {user_id}")
            return {"success": True, "message": "Activity crate unlocked!"}

        return {"success": False, "message": "Activity crate not available or already claimed"}

    except Exception as e:
        print(f"❌ [XP] Error unlocking activity crate: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# EXTENDED WEEKLY CHECKPOINTS (10 types)
# =============================================================================

@router.get("/weekly-checkpoints")
async def get_weekly_checkpoints(
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
        return {
            "week_start": date.today().isoformat(),
            "total_xp_possible": 1575,
            "checkpoints": []
        }

    except Exception as e:
        print(f"❌ [XP] Error getting weekly checkpoints: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error incrementing weekly checkpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error updating weekly habits: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# MONTHLY ACHIEVEMENTS (12 types)
# =============================================================================

@router.get("/monthly-achievements")
async def get_monthly_achievements(
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
        return {
            "month": date.today().strftime("%Y-%m"),
            "total_xp_possible": 5250,
            "achievements": []
        }

    except Exception as e:
        print(f"❌ [XP] Error getting monthly achievements: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error incrementing monthly achievement: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error updating monthly goal progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error updating monthly consistency: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error updating monthly weight status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error updating monthly habits: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error evaluating month-end: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# DAILY SOCIAL XP (4 actions, 270 XP cap)
# =============================================================================

@router.get("/daily-social-xp")
async def get_daily_social_xp(
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
        return {
            "date": date.today().isoformat(),
            "total_social_xp_today": 0,
            "daily_cap": 270,
            "remaining_cap": 270,
            "at_cap": False,
            "actions": []
        }

    except Exception as e:
        print(f"❌ [XP] Error getting daily social XP: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        print(f"❌ [XP] Error awarding social XP: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
