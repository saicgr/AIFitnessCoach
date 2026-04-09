"""
Dashboard API Endpoints
========================
Provides aggregated weekly dashboard data for the home screen.

Endpoints:
- GET /dashboard/weekly/{user_id} - Get this week's dashboard summary
"""

from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
import asyncio
import logging

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================================
# Pydantic Models
# ============================================================================

class MeasurementDelta(BaseModel):
    """Delta between two measurement entries."""
    field: str
    previous: Optional[float] = None
    current: Optional[float] = None
    delta: Optional[float] = None


class WeeklyDashboardResponse(BaseModel):
    """Response model for weekly dashboard summary."""
    week_start: date
    week_end: date
    workout_compliance: Dict[str, Any]
    nutrition_adherence_pct: Optional[float] = None
    readiness_scores: List[Dict[str, Any]]
    measurement_highlights: List[MeasurementDelta]
    upcoming_goals: List[Dict[str, Any]]
    mood_today: Optional[str] = None


# ============================================================================
# Endpoints
# ============================================================================

@router.get("/weekly/{user_id}", response_model=WeeklyDashboardResponse)
async def get_weekly_dashboard(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get this week's dashboard data at a glance."""
    verify_user_ownership(current_user, user_id)
    db = get_supabase_db()

    # Calculate week boundaries (Monday to Sunday)
    today = datetime.utcnow().date()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)

    week_start_str = week_start.isoformat()
    week_end_str = week_end.isoformat()

    try:
        # Run all queries in parallel
        (
            workouts_resp,
            user_resp,
            food_logs_resp,
            readiness_resp,
            measurements_resp,
            goals_resp,
        ) = await asyncio.gather(
            _query_async(
                db, "workouts", "id, completed, workout_date",
                user_id, week_start_str, week_end_str,
            ),
            _query_user(db, user_id),
            _query_async(
                db, "food_logs", "id, logged_at",
                user_id, week_start_str, week_end_str,
                date_column="logged_at",
            ),
            _query_async(
                db, "readiness_scores", "*",
                user_id, week_start_str, week_end_str,
                date_column="score_date",
            ),
            _query_measurements(db, user_id),
            _query_goals(db, user_id),
        )

        # --- Workout compliance ---
        workouts = workouts_resp or []
        completed_count = sum(1 for w in workouts if w.get("completed"))
        total_scheduled = len(workouts)

        # Get user's target workouts per week from preferences
        user_data = user_resp
        target_per_week = 3  # default
        if user_data:
            target_per_week = (
                user_data.get("workout_days_per_week")
                or user_data.get("preferences", {}).get("workout_days_per_week")
                or 3
            )

        workout_compliance = {
            "completed": completed_count,
            "scheduled": total_scheduled,
            "target": target_per_week,
            "pct": round((completed_count / target_per_week) * 100, 1) if target_per_week > 0 else 0,
        }

        # --- Nutrition adherence ---
        food_logs = food_logs_resp or []
        days_with_logs = len(set(
            (fl.get("logged_at") or "")[:10] for fl in food_logs if fl.get("logged_at")
        ))
        days_elapsed = (today - week_start).days + 1
        nutrition_adherence_pct = round((days_with_logs / days_elapsed) * 100, 1) if days_elapsed > 0 else None

        # --- Readiness scores ---
        readiness_scores = readiness_resp or []

        # --- Measurement highlights ---
        measurements = measurements_resp or []
        measurement_highlights = _compute_measurement_deltas(measurements)

        # --- Upcoming goals ---
        upcoming_goals = goals_resp or []

        # --- Mood today ---
        mood_today = None
        if readiness_scores:
            today_scores = [r for r in readiness_scores if r.get("score_date") == today.isoformat()]
            if today_scores:
                mood_today = today_scores[-1].get("mood_emoji")

        return WeeklyDashboardResponse(
            week_start=week_start,
            week_end=week_end,
            workout_compliance=workout_compliance,
            nutrition_adherence_pct=nutrition_adherence_pct,
            readiness_scores=readiness_scores,
            measurement_highlights=measurement_highlights,
            upcoming_goals=upcoming_goals,
            mood_today=mood_today,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to fetch weekly dashboard for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error()


# ============================================================================
# Helper Functions
# ============================================================================

async def _query_async(
    db, table: str, select: str, user_id: str,
    start: str, end: str, date_column: str = "workout_date",
):
    """Query a table for records within a date range."""
    try:
        response = db.client.table(table).select(select).eq(
            "user_id", user_id
        ).gte(date_column, start).lte(date_column, end).execute()
        return response.data or []
    except Exception as e:
        logger.warning(f"Dashboard query failed for {table}: {e}", exc_info=True)
        return []


async def _query_user(db, user_id: str):
    """Get user profile data."""
    try:
        response = db.client.table("users").select(
            "workout_days_per_week, preferences"
        ).eq("id", user_id).limit(1).execute()
        return response.data[0] if response.data else {}
    except Exception as e:
        logger.warning(f"Dashboard user query failed: {e}", exc_info=True)
        return {}


async def _query_measurements(db, user_id: str):
    """Get the latest 2 body measurement entries for delta calculation."""
    try:
        response = db.client.table("body_measurements").select("*").eq(
            "user_id", user_id
        ).order("measured_at", desc=True).limit(2).execute()
        return response.data or []
    except Exception as e:
        logger.warning(f"Dashboard measurements query failed: {e}", exc_info=True)
        return []


async def _query_goals(db, user_id: str):
    """Get active personal goals."""
    try:
        response = db.client.table("personal_goals").select(
            "id, title, target_value, current_value, unit, status, deadline"
        ).eq("user_id", user_id).eq("status", "active").execute()
        return response.data or []
    except Exception as e:
        logger.warning(f"Dashboard goals query failed: {e}", exc_info=True)
        return []


_MEASUREMENT_FIELDS = ["weight_kg", "body_fat_pct", "waist_cm", "chest_cm", "arm_cm", "thigh_cm"]


def _compute_measurement_deltas(measurements: list) -> List[MeasurementDelta]:
    """Compute deltas between the two most recent measurement entries."""
    if len(measurements) < 2:
        return []

    current = measurements[0]
    previous = measurements[1]
    deltas = []

    for field in _MEASUREMENT_FIELDS:
        cur_val = current.get(field)
        prev_val = previous.get(field)
        if cur_val is not None and prev_val is not None:
            deltas.append(MeasurementDelta(
                field=field,
                previous=prev_val,
                current=cur_val,
                delta=round(cur_val - prev_val, 2),
            ))

    return deltas
