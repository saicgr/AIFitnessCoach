"""
Periodization endpoints (Phase 2.E + 2.H).

GET    /api/v1/periodization/state              — Current mesocycle state.
PUT    /api/v1/periodization/state              — Push mesocycle state from
                                                   the Flutter mesocycle_planner.dart
                                                   (was dead code; now wired).
POST   /api/v1/periodization/force-deload       — Force a deload week now (red-flag
                                                   autoregulation or user-triggered).
GET    /api/v1/periodization/bonus-workout      — Phase 2.H — opt-in extra
                                                   workout after the user
                                                   completes their planned week.
"""
from datetime import date, datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()


_VALID_SCHEMES = {"linear", "dup", "block", "conjugate"}


class MesocycleStateIn(BaseModel):
    cycle_start_date: Optional[date] = None
    weeks_per_cycle: int = Field(default=4, ge=3, le=8)
    current_week: int = Field(default=1, ge=1, le=8)
    scheme: str = Field(default="linear")
    is_deload_week: bool = False


@router.get("/periodization/state")
async def get_periodization_state(current_user: dict = Depends(get_current_user)):
    """Return current mesocycle state. 404 when the user hasn't been onboarded
    into a mesocycle yet (frontend should push state on first session via PUT)."""
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("mesocycle_state")
        .select("*")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not res.data:
        return {"state": None}
    return {"state": res.data[0]}


@router.put("/periodization/state")
async def upsert_periodization_state(
    payload: MesocycleStateIn,
    current_user: dict = Depends(get_current_user),
):
    """Upsert mesocycle state. Called from the Flutter mesocycle_planner on
    session start so the backend can pass deload_week into the generator."""
    if payload.scheme not in _VALID_SCHEMES:
        raise HTTPException(
            status_code=422,
            detail=f"scheme must be one of {sorted(_VALID_SCHEMES)}",
        )
    user_id = current_user["id"]
    db = get_supabase_db()
    row = payload.model_dump(exclude_none=True)
    row["user_id"] = user_id
    try:
        res = (
            db.client.table("mesocycle_state")
            .upsert(row, on_conflict="user_id")
            .execute()
        )
    except Exception as e:
        logger.error(f"❌ [periodization] upsert failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    return res.data[0] if res.data else row


@router.post("/periodization/force-deload")
async def force_deload(current_user: dict = Depends(get_current_user)):
    """Force the current week into deload mode. Triggered by:
      • Red-flag autoregulation (sleep<6h + HRV↓>10% + avg RPE>9 over 5 sessions)
      • User-driven from the coach chat
      • Plateau-break protocol when plateau_detector trips

    Sets is_deload_week=true; validator caps weekly volume at 60% MRV;
    generator passes deload=true into the prompt.
    """
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("mesocycle_state")
        .upsert(
            {
                "user_id": user_id,
                "is_deload_week": True,
                "last_forced_deload_at": datetime.now(timezone.utc).isoformat(),
                "last_trigger": {"trigger": "force_deload_endpoint"},
            },
            on_conflict="user_id",
        )
        .execute()
    )
    # Also bump the weekly_plans regen flag so /today re-generates with deload prompt.
    try:
        db.client.table("weekly_plans").update({
            "plan_locked": False,
            "regen_requested_at": datetime.now(timezone.utc).isoformat(),
        }).eq("user_id", user_id).gte(
            "week_start_date", (date.today() - timedelta(days=7)).isoformat()
        ).execute()
    except Exception as e:
        logger.warning(f"⚠️ [periodization] regen_requested_at bump failed: {e}")
    return {"forced_deload": True, "state": (res.data or [{}])[0]}


@router.get("/periodization/bonus-workout")
async def bonus_workout_eligibility(current_user: dict = Depends(get_current_user)):
    """Phase 2.H — when the user has completed every planned day this week,
    surface an opt-in extra workout. Returns:
      {"eligible": bool, "reason": str, "remaining_days_in_week": int,
       "suggested_archetype": str | None}

    Generation happens client-side via the existing workout-generate flow once
    the user opts in (no auto-creation — avoids forcing extra work onto a user
    who's already nailed the week).
    """
    user_id = current_user["id"]
    db = get_supabase_db()
    today = date.today()
    week_start = today - timedelta(days=today.weekday())  # Monday
    week_end = week_start + timedelta(days=6)

    # Fetch the current week's plan
    plan_res = (
        db.client.table("weekly_plans")
        .select("workout_days,week_start_date")
        .eq("user_id", user_id)
        .eq("week_start_date", week_start.isoformat())
        .limit(1)
        .execute()
    )
    if not plan_res.data:
        return {"eligible": False, "reason": "no_active_plan", "remaining_days_in_week": (week_end - today).days, "suggested_archetype": None}

    plan_row = plan_res.data[0]
    planned_days = plan_row.get("workout_days") or {}
    if not isinstance(planned_days, dict):
        return {"eligible": False, "reason": "plan_shape_unknown", "remaining_days_in_week": (week_end - today).days, "suggested_archetype": None}

    # Count planned workout days (skip rest days)
    planned_workouts = [d for d, info in planned_days.items() if info and not info.get("rest_day")]

    # Logs this week
    logs_res = (
        db.client.table("workout_logs")
        .select("completed_at")
        .eq("user_id", user_id)
        .gte("completed_at", week_start.isoformat())
        .lte("completed_at", (week_end + timedelta(days=1)).isoformat())
        .execute()
    )
    logged_count = len(logs_res.data or [])
    if logged_count < len(planned_workouts):
        return {
            "eligible": False,
            "reason": "planned_week_incomplete",
            "logged_workouts": logged_count,
            "planned_workouts": len(planned_workouts),
            "remaining_days_in_week": (week_end - today).days,
            "suggested_archetype": None,
        }

    # Eligible — suggest the least-trained muscle group as a focus.
    # (Reads 7-day sets-per-muscle aggregation; uses workout_validator landmarks
    # to pick the muscle furthest below MAV.)
    from services.workout_validator_phase2 import VOLUME_LANDMARKS
    from services.user_state_assembler import assemble_user_state

    state = assemble_user_state(user_id, db.client, force=True)
    deficit_per_muscle = []
    for muscle, landmarks in VOLUME_LANDMARKS.items():
        done = state.sets_per_muscle_7d.get(muscle, 0)
        deficit_per_muscle.append((muscle, landmarks["mav"] - done))
    deficit_per_muscle.sort(key=lambda x: x[1], reverse=True)
    best = deficit_per_muscle[0] if deficit_per_muscle else (None, 0)

    archetype_for_muscle = {
        "chest": "push", "shoulders": "push", "triceps": "push",
        "back": "pull", "biceps": "pull",
        "quads": "legs", "hamstrings": "legs", "glutes": "legs", "calves": "legs",
        "abs": "full_body",
    }
    suggested = archetype_for_muscle.get(best[0]) if best[0] else "full_body"

    return {
        "eligible": True,
        "reason": "completed_planned_week",
        "logged_workouts": logged_count,
        "planned_workouts": len(planned_workouts),
        "remaining_days_in_week": (week_end - today).days,
        "suggested_archetype": suggested,
        "suggested_focus_muscle": best[0],
        "set_deficit_vs_mav": int(best[1]) if best[0] else 0,
    }
