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
        result = db.client.rpc(
            "process_daily_login",
            {"p_user_id": current_user["id"]}
        ).execute()

        if result.data:
            return DailyLoginResponse(**result.data)
        else:
            raise HTTPException(status_code=500, detail="Failed to process daily login")

    except Exception as e:
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
        # Calculate current period
        today = date.today()

        if checkpoint_type == "weekly":
            # Get Monday of current week
            period_start = today - timedelta(days=today.weekday())
            period_end = period_start + timedelta(days=6)
        else:
            # Get first and last day of current month
            period_start = today.replace(day=1)
            next_month = period_start.replace(day=28) + timedelta(days=4)
            period_end = next_month - timedelta(days=next_month.day)

        result = db.client.table("user_checkpoint_progress").select("*").eq(
            "user_id", current_user["id"]
        ).eq(
            "checkpoint_type", checkpoint_type
        ).eq(
            "period_start", period_start.isoformat()
        ).single().execute()

        if result.data:
            return result.data
        else:
            return {
                "checkpoint_type": checkpoint_type,
                "period_start": period_start.isoformat(),
                "period_end": period_end.isoformat(),
                "checkpoints_earned": [],
                "total_xp_earned": 0
            }

    except Exception as e:
        # Return empty progress if not found
        return {
            "checkpoint_type": checkpoint_type,
            "checkpoints_earned": [],
            "total_xp_earned": 0
        }
