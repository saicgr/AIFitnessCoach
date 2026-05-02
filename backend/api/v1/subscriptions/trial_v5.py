"""
Onboarding v5 trial endpoints — supplements existing trials.py with
mechanics introduced in the redesigned onboarding flow:

- GET  /trial-summary  — Day 7 personalized trial summary (workouts done,
                         meals logged, progress toward goal, coach interactions)
- GET  /trial-status-v5 — Day X / 7 + goal date + commitment-pact state
                         (lighter-weight than full /trial-status; used by
                         home-screen trial-progress widget on every cold start)

Both endpoints expect an authenticated user. Win-back email scheduling lives
in services/win_back_service.py and is triggered by the RevenueCat
CANCELLATION webhook handler, not via these endpoints.
"""
from datetime import date, datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from core.supabase_client import get_supabase
from core.auth import get_current_user
from core.logger import get_logger
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


class TrialStatusV5Response(BaseModel):
    """Lightweight trial status for home screen widget rendering."""
    is_in_trial: bool
    day_of_trial: Optional[int] = None  # 1..7
    days_remaining: Optional[int] = None
    trial_start_date: Optional[str] = None
    trial_end_date: Optional[str] = None
    goal_target_date: Optional[str] = None
    commitment_pact_accepted: bool = False
    is_paused: bool = False
    paused_until: Optional[str] = None


@router.get("/trial-status-v5", response_model=TrialStatusV5Response)
async def trial_status_v5(current_user: dict = Depends(get_current_user)):
    """
    Lightweight trial status for the home-screen trial-progress widget.
    Returns Day X/7 + goal date + commitment pact state.
    """
    user_id = current_user["id"]
    try:
        supabase = get_supabase()
        result = supabase.client.table("users")\
            .select("trial_start_date, goal_target_date, commitment_pact_accepted, paused_at, pause_duration_days")\
            .eq("id", user_id)\
            .maybe_single()\
            .execute()

        if not result.data:
            return TrialStatusV5Response(is_in_trial=False)

        row = result.data
        start_str = row.get("trial_start_date")
        if not start_str:
            return TrialStatusV5Response(
                is_in_trial=False,
                goal_target_date=row.get("goal_target_date"),
                commitment_pact_accepted=bool(row.get("commitment_pact_accepted")),
            )

        start = date.fromisoformat(start_str)
        today = date.today()
        day_of_trial = max(1, (today - start).days + 1)
        end_date = start + timedelta(days=7)
        days_remaining = max(0, (end_date - today).days)
        is_in_trial = day_of_trial <= 7

        # Pause state
        paused_at_str = row.get("paused_at")
        is_paused = paused_at_str is not None
        paused_until = None
        if is_paused and row.get("pause_duration_days"):
            paused_at_dt = datetime.fromisoformat(paused_at_str.replace("Z", "+00:00"))
            paused_until = (paused_at_dt + timedelta(days=row["pause_duration_days"])).date().isoformat()

        return TrialStatusV5Response(
            is_in_trial=is_in_trial,
            day_of_trial=day_of_trial if is_in_trial else None,
            days_remaining=days_remaining if is_in_trial else None,
            trial_start_date=start_str,
            trial_end_date=end_date.isoformat(),
            goal_target_date=row.get("goal_target_date"),
            commitment_pact_accepted=bool(row.get("commitment_pact_accepted")),
            is_paused=is_paused,
            paused_until=paused_until,
        )
    except Exception as e:
        logger.error(f"trial-status-v5 failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "trial-status-v5")


class TrialSummaryResponse(BaseModel):
    """Day 7 personalized trial summary — what user accomplished during trial."""
    workouts_completed: int
    total_volume_kg: float
    sets_logged: int
    reps_logged: int
    meals_logged: int
    coach_interactions: int
    goal_target_date: Optional[str] = None
    current_weight_kg: Optional[float] = None
    weight_delta_kg: Optional[float] = None  # Change since trial start
    streak_days: int = 0


@router.get("/trial-summary", response_model=TrialSummaryResponse)
async def trial_summary(current_user: dict = Depends(get_current_user)):
    """
    Day 7 personalized trial summary endpoint.
    Used by:
      1. Day 7 in-app trial-end summary screen
      2. Day 7 personalized email
      3. Win-back emails (post-cancel) — references this same data
    """
    user_id = current_user["id"]
    try:
        supabase = get_supabase()

        # Get trial_start_date
        user_result = supabase.client.table("users")\
            .select("trial_start_date, goal_target_date, weight_kg")\
            .eq("id", user_id)\
            .maybe_single()\
            .execute()

        user_row = user_result.data or {}
        trial_start_str = user_row.get("trial_start_date")
        if not trial_start_str:
            # No trial recorded — return zero summary rather than error
            return TrialSummaryResponse(
                workouts_completed=0,
                total_volume_kg=0.0,
                sets_logged=0,
                reps_logged=0,
                meals_logged=0,
                coach_interactions=0,
            )

        trial_start = trial_start_str  # ISO date string for filtering

        # Workouts completed during trial
        workouts_result = supabase.client.table("completed_workouts")\
            .select("id, total_volume_kg, total_sets, total_reps")\
            .eq("user_id", user_id)\
            .gte("completed_at", trial_start)\
            .execute()
        workouts = workouts_result.data or []
        workouts_completed = len(workouts)
        total_volume = sum(w.get("total_volume_kg", 0) or 0 for w in workouts)
        sets_logged = sum(w.get("total_sets", 0) or 0 for w in workouts)
        reps_logged = sum(w.get("total_reps", 0) or 0 for w in workouts)

        # Meals logged during trial
        try:
            meals_result = supabase.client.table("food_log")\
                .select("id", count="exact")\
                .eq("user_id", user_id)\
                .gte("logged_at", trial_start)\
                .execute()
            meals_logged = meals_result.count or 0
        except Exception:
            meals_logged = 0

        # Coach interactions during trial
        try:
            chat_result = supabase.client.table("chat_messages")\
                .select("id", count="exact")\
                .eq("user_id", user_id)\
                .eq("role", "user")\
                .gte("created_at", trial_start)\
                .execute()
            coach_interactions = chat_result.count or 0
        except Exception:
            coach_interactions = 0

        # Current weight + delta
        try:
            weight_result = supabase.client.table("weight_logs")\
                .select("weight_kg, logged_at")\
                .eq("user_id", user_id)\
                .order("logged_at", desc=True)\
                .limit(1)\
                .execute()
            current_weight = weight_result.data[0]["weight_kg"] if weight_result.data else user_row.get("weight_kg")
        except Exception:
            current_weight = user_row.get("weight_kg")

        weight_delta = None
        if current_weight and user_row.get("weight_kg"):
            weight_delta = round(current_weight - user_row["weight_kg"], 2)

        # Streak (best-effort — falls back to workout count if streak service is unavailable)
        try:
            streak_result = supabase.client.table("user_streaks")\
                .select("current_streak")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()
            streak_days = streak_result.data.get("current_streak", 0) if streak_result.data else 0
        except Exception:
            streak_days = workouts_completed

        return TrialSummaryResponse(
            workouts_completed=workouts_completed,
            total_volume_kg=round(total_volume, 1),
            sets_logged=sets_logged,
            reps_logged=reps_logged,
            meals_logged=meals_logged,
            coach_interactions=coach_interactions,
            goal_target_date=user_row.get("goal_target_date"),
            current_weight_kg=current_weight,
            weight_delta_kg=weight_delta,
            streak_days=streak_days,
        )
    except Exception as e:
        logger.error(f"trial-summary failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "trial-summary")
