"""Race / dated-event goal API (Gap 11).

- POST /api/v1/race/goal   — set (or update) the user's race event + date
- GET  /api/v1/race/status — current periodization phase + today's auto-adjusted
                             recommendation (folds in recovery tier + load state)
- DELETE /api/v1/race/goal — clear the active race goal

Stores onto `custom_goals` (event_date/event_name, goal_type='endurance',
progression_strategy='periodized') so it composes with the existing goal +
keyword machinery. The periodization itself is deterministic
(`services/race_periodization.py`).
"""
import uuid
from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.timezone_utils import get_user_today, resolve_timezone
from services.race_periodization import compute_race_phase, format_race_context_for_ai

router = APIRouter()
logger = get_logger(__name__)


class RaceGoalCreate(BaseModel):
    event_name: str = Field(..., max_length=200)
    event_date: str = Field(..., max_length=10, description="YYYY-MM-DD")
    goal_text: Optional[str] = Field(default=None, max_length=500)


class RaceStatus(BaseModel):
    has_goal: bool
    event_name: Optional[str] = None
    event_date: Optional[str] = None
    phase: Optional[str] = None
    days_to_race: Optional[int] = None
    weeks_to_race: Optional[float] = None
    weekly_focus: Optional[str] = None
    today_recommendation: Optional[str] = None
    intensity_ceiling: Optional[str] = None
    adjusted_for: Optional[str] = None


def _active_race_goal(db, user_id: str) -> Optional[dict]:
    """The soonest upcoming dated goal (or most recent past, for post-race)."""
    try:
        res = db.client.table("custom_goals").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).not_.is_("event_date", "null").order(
            "event_date", desc=False
        ).execute()
        rows = res.data or []
        if not rows:
            return None
        # Prefer the next upcoming; if all are past, the latest past one.
        today = date.today()
        upcoming = [r for r in rows if _parse_date(r.get("event_date")) and _parse_date(r["event_date"]) >= today]
        if upcoming:
            return upcoming[0]
        return rows[-1]
    except Exception as e:
        logger.debug(f"[race] active goal lookup failed for {user_id}: {e}")
        return None


def _parse_date(s) -> Optional[date]:
    if not s:
        return None
    try:
        return date.fromisoformat(str(s)[:10])
    except Exception:
        return None


async def _recovery_and_load(user_id: str):
    """Best-effort (recovery_tier, load_state) for the daily auto-adjust."""
    recovery_tier = None
    load_state = None
    try:
        from services.user_context import user_context_service
        snap = await user_context_service.get_health_activity_snapshot(user_id, days=7)
        if snap and snap.get("has_data"):
            recovery_tier = (snap.get("recovery") or {}).get("tier")
    except Exception as e:
        logger.debug(f"[race] recovery lookup skipped: {e}")
    try:
        import asyncio
        from services.training_load_service import current_state
        st = await asyncio.to_thread(current_state, get_supabase_db(), user_id)
        if st and st.state and st.state != "calibration":
            load_state = st.state
    except Exception as e:
        logger.debug(f"[race] load lookup skipped: {e}")
    return recovery_tier, load_state


@router.post("/goal", response_model=RaceStatus)
async def set_race_goal(
    data: RaceGoalCreate,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Set or update the user's race/event goal."""
    user_id = str(current_user["id"])
    event_date = _parse_date(data.event_date)
    if event_date is None:
        raise HTTPException(status_code=422, detail="event_date must be YYYY-MM-DD")
    try:
        db = get_supabase_db()
        existing = _active_race_goal(db, user_id)
        row = {
            "event_name": data.event_name,
            "event_date": event_date.isoformat(),
            "goal_text": data.goal_text or f"Train for {data.event_name}",
            "goal_type": "endurance",
            "progression_strategy": "periodized",
            "is_active": True,
            "updated_at": datetime.utcnow().isoformat(),
        }
        if existing:
            db.client.table("custom_goals").update(row).eq("id", existing["id"]).execute()
        else:
            row["id"] = str(uuid.uuid4())
            row["user_id"] = user_id
            db.client.table("custom_goals").insert(row).execute()
        return await get_race_status(http_request, current_user)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[race] set goal failed: {e}", exc_info=True)
        raise safe_internal_error(e, "race")


@router.get("/status", response_model=RaceStatus)
async def get_race_status(
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Current periodization phase + today's auto-adjusted recommendation."""
    user_id = str(current_user["id"])
    try:
        db = get_supabase_db()
        goal = _active_race_goal(db, user_id)
        if not goal:
            return RaceStatus(has_goal=False)
        user_tz = resolve_timezone(http_request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        recovery_tier, load_state = await _recovery_and_load(user_id)
        rp = compute_race_phase(
            _parse_date(goal.get("event_date")),
            today,
            recovery_tier=recovery_tier,
            load_state=load_state,
        )
        return RaceStatus(
            has_goal=True,
            event_name=goal.get("event_name"),
            event_date=goal.get("event_date"),
            phase=rp.phase,
            days_to_race=rp.days_to_race,
            weeks_to_race=rp.weeks_to_race,
            weekly_focus=rp.weekly_focus,
            today_recommendation=rp.today_recommendation,
            intensity_ceiling=rp.intensity_ceiling,
            adjusted_for=rp.adjusted_for,
        )
    except Exception as e:
        logger.error(f"[race] status failed: {e}", exc_info=True)
        raise safe_internal_error(e, "race")


@router.delete("/goal")
async def clear_race_goal(
    current_user: dict = Depends(get_current_user),
):
    """Clear the active race goal (deactivates the dated custom_goal)."""
    user_id = str(current_user["id"])
    try:
        db = get_supabase_db()
        goal = _active_race_goal(db, user_id)
        if goal:
            db.client.table("custom_goals").update(
                {"is_active": False, "updated_at": datetime.utcnow().isoformat()}
            ).eq("id", goal["id"]).execute()
        return {"status": "cleared"}
    except Exception as e:
        logger.error(f"[race] clear goal failed: {e}", exc_info=True)
        raise safe_internal_error(e, "race")


# Shared helper for the coach context (Gap 11 + 17) — a compact race block.
async def race_context_for_coach(user_id: str, user_tz: str = "UTC") -> str:
    """Return the coach-prompt race block, or '' when the user has no event."""
    try:
        db = get_supabase_db()
        goal = _active_race_goal(db, user_id)
        if not goal:
            return ""
        today = date.fromisoformat(get_user_today(user_tz))
        recovery_tier, load_state = await _recovery_and_load(user_id)
        rp = compute_race_phase(
            _parse_date(goal.get("event_date")),
            today,
            recovery_tier=recovery_tier,
            load_state=load_state,
        )
        return format_race_context_for_ai(rp, goal.get("event_name"))
    except Exception as e:
        logger.debug(f"[race] coach context skipped for {user_id}: {e}")
        return ""
