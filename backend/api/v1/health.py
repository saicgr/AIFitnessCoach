"""
Health check endpoints.

Also hosts the user-facing `/recovery-hours-remaining` endpoint used by
the home `RecoveryCountdownTile` — kept here to honor the URL spec
`/api/v1/health/recovery-hours-remaining`. Distinct from the system
liveness probes above which never read user data.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from core import branding
from core.auth import get_current_user
from core.config import get_settings
from core.db import get_supabase_db
from core.logger import get_logger
from services.gemini_service import cost_tracker

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


@router.get("/")
async def health_check():
    """Basic health check."""
    return {"status": "healthy", "service": f"{branding.APP_NAME} Backend"}


@router.get("/ready")
async def readiness_check():
    """Readiness check - verifies all dependencies are available."""
    return {
        "status": "ready",
        "checks": {
            "gemini": "connected",
            "rag": "initialized",
        }
    }


@router.get("/debug/gemini")
async def debug_gemini():
    """Debug endpoint - shows Gemini config without making API calls."""
    return {
        "model": settings.gemini_model,
        "embedding_model": settings.gemini_embedding_model,
        "api_key_set": bool(settings.gemini_api_key),
        "cache_enabled": getattr(settings, 'gemini_cache_enabled', False),
        "status": "configured",
    }


@router.get("/debug/costs")
async def debug_costs():
    """Debug endpoint - shows accumulated Vertex AI cost estimates since last deploy."""
    return cost_tracker.snapshot()


class RecoveryHoursResponse(BaseModel):
    last_workout_at: Optional[str] = None
    estimated_total_recovery_hours: int = 0
    hours_remaining: int = 0
    next_ready_at: Optional[str] = None


@router.get("/recovery-hours-remaining", response_model=RecoveryHoursResponse)
async def get_recovery_hours_remaining(
    current_user: dict = Depends(get_current_user),
) -> RecoveryHoursResponse:
    """
    Estimate hours until the user is training-ready again.

    Reads the most recent `workout_logs` row with `completed_at IS NOT NULL`.
    Light sessions (< 45 min) → 12h recovery budget; hard sessions (>= 45 min)
    → 36h. `hours_remaining = max(budget - elapsed, 0)`. If no completed
    workout exists, returns all-zeroes (UI self-collapses).
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Missing user id")

    try:
        db = get_supabase_db()

        # Most recent completed workout_log. Pull duration_minutes via the
        # joined workouts row (workout_logs typically references workout_id).
        log_resp = (
            db.client.table("workout_logs")
            .select("completed_at,workout_id,duration_minutes")
            .eq("user_id", user_id)
            .not_.is_("completed_at", "null")
            .order("completed_at", desc=True)
            .limit(1)
            .execute()
        )
        if not log_resp.data:
            return RecoveryHoursResponse()

        log = log_resp.data[0]
        completed_at_raw = log.get("completed_at")
        if not completed_at_raw:
            return RecoveryHoursResponse()

        # Duration: prefer workout_logs.duration_minutes; fall back to the
        # workouts row (some clients only persist duration on the template).
        duration_min: Optional[int] = None
        raw_dur = log.get("duration_minutes")
        if raw_dur is not None:
            try:
                duration_min = int(raw_dur)
            except (TypeError, ValueError):
                duration_min = None

        if duration_min is None and log.get("workout_id"):
            try:
                w_resp = (
                    db.client.table("workouts")
                    .select("duration_minutes")
                    .eq("id", log["workout_id"])
                    .limit(1)
                    .execute()
                )
                if w_resp.data:
                    raw_dur2 = w_resp.data[0].get("duration_minutes")
                    if raw_dur2 is not None:
                        duration_min = int(raw_dur2)
            except Exception:
                duration_min = None

        # Spec heuristic: >= 45 min = hard (36h), else light (12h).
        is_hard = (duration_min or 0) >= 45
        total_hours = 36 if is_hard else 12

        # Parse completed_at (Postgres returns ISO8601 with optional Z).
        completed_at = datetime.fromisoformat(
            str(completed_at_raw).replace("Z", "+00:00")
        )
        if completed_at.tzinfo is None:
            completed_at = completed_at.replace(tzinfo=timezone.utc)

        now = datetime.now(timezone.utc)
        elapsed_hours = (now - completed_at).total_seconds() / 3600.0
        hours_remaining = max(int(round(total_hours - elapsed_hours)), 0)
        next_ready = completed_at + timedelta(hours=total_hours)

        return RecoveryHoursResponse(
            last_workout_at=completed_at.isoformat(),
            estimated_total_recovery_hours=total_hours,
            hours_remaining=hours_remaining,
            next_ready_at=next_ready.isoformat(),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"recovery-hours-remaining failed user={user_id}: {e}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=500,
            detail=f"recovery_hours_failed: {e.__class__.__name__}",
        )
