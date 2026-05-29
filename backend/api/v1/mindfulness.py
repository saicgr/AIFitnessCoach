"""Mindfulness / meditation session logging + daily aggregation.

Backs the "Mindfulness minutes" key metric (Google Health parity). A completed
in-app meditation or breathwork session POSTs here; the home mindful-minutes
ring and the metrics dashboard card read today's aggregate back.

Daily aggregation is by `local_date` — the user's timezone calendar day frozen
at write time (see migrations/2214_mindfulness_sessions.sql) — so a session
logged near local midnight stays on the right day and changing timezones never
reshuffles history. Same pattern as nutrition summaries / hydration.
"""
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field

from core.db import get_supabase_db
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today, _is_valid_tz

router = APIRouter()
logger = get_logger(__name__)

# Default soft daily target (minutes) when the user has no custom goal.
DEFAULT_TARGET_MINUTES = 10
# Hard ceiling mirrors the DB CHECK (4h) — defends against a stuck timer.
MAX_DURATION_SECONDS = 14400
ALLOWED_SOURCES = {"meditation", "breathwork", "sleep_story"}


class LogMindfulnessRequest(BaseModel):
    source: str = Field(default="meditation")
    meditation_slug: Optional[str] = None
    duration_seconds: int = Field(..., gt=0)


class MindfulnessSession(BaseModel):
    id: str
    source: str
    meditation_slug: Optional[str] = None
    duration_seconds: int
    completed_at: str


class MindfulnessTodayResponse(BaseModel):
    minutes: int
    target_minutes: int
    session_count: int
    sessions: List[MindfulnessSession]


class MindfulnessDayPoint(BaseModel):
    date: str          # YYYY-MM-DD (user-local)
    minutes: int


class MindfulnessHistoryResponse(BaseModel):
    days: List[MindfulnessDayPoint]


def _resolve_tz(request: Request, db, user_id: str, tz_param: Optional[str]) -> str:
    """Header-first tz resolution with an explicit `tz` query fallback.

    Mirrors nutrition/summaries: the X-User-Timezone header wins; the `tz`
    query param is only consulted when resolution would otherwise fall back to
    UTC (cold start before prefs load). Never silently UTC for a non-UTC user
    near midnight — that would misfile the day.
    """
    user_tz = resolve_timezone(request, db, user_id)
    if user_tz == "UTC" and tz_param and _is_valid_tz(tz_param):
        user_tz = tz_param
    return user_tz


@router.post("/mindfulness/log", response_model=MindfulnessTodayResponse)
async def log_mindfulness_session(
    body: LogMindfulnessRequest,
    request: Request,
    tz: Optional[str] = Query(default=None, description="IANA timezone fallback"),
    current_user: dict = Depends(get_current_user),
):
    """Record a completed meditation/breathwork session for the caller.

    Returns today's running total so the client can reconcile the ring without
    a second round-trip.
    """
    try:
        db = get_supabase_db()
        user_id = str(current_user["id"])

        source = body.source if body.source in ALLOWED_SOURCES else "meditation"
        # Defensive clamp on top of the DB CHECK — a wedged timer or bad client
        # value must not poison the daily aggregate.
        duration = max(1, min(int(body.duration_seconds), MAX_DURATION_SECONDS))

        user_tz = _resolve_tz(request, db, user_id, tz)
        local_date = get_user_today(user_tz)

        row = {
            "user_id": user_id,
            "source": source,
            "meditation_slug": body.meditation_slug,
            "duration_seconds": duration,
            "local_date": local_date,
        }
        result = db.client.table("mindfulness_sessions").insert(row).execute()
        if not result.data or not result.data[0].get("id"):
            # No silent success — surface the failed insert so the client error
            # path fires rather than the ring silently staying at 0.
            raise safe_internal_error(
                ValueError("mindfulness_sessions insert returned empty data"), "mindfulness"
            )

        return await _today_payload(db, user_id, user_tz)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"mindfulness/log failed: {e}", exc_info=True)
        raise safe_internal_error(e, "mindfulness")


@router.get("/mindfulness/today/{user_id}", response_model=MindfulnessTodayResponse)
async def get_mindfulness_today(
    user_id: str,
    request: Request,
    tz: Optional[str] = Query(default=None, description="IANA timezone fallback"),
    current_user: dict = Depends(get_current_user),
):
    """Today's total mindful minutes + the sessions behind it."""
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = _resolve_tz(request, db, user_id, tz)
        return await _today_payload(db, user_id, user_tz)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"mindfulness/today failed: {e}", exc_info=True)
        raise safe_internal_error(e, "mindfulness")


@router.get("/mindfulness/history/{user_id}", response_model=MindfulnessHistoryResponse)
async def get_mindfulness_history(
    user_id: str,
    request: Request,
    days: int = Query(default=7, ge=1, le=90),
    tz: Optional[str] = Query(default=None, description="IANA timezone fallback"),
    current_user: dict = Depends(get_current_user),
):
    """Per-day mindful minutes for the sparkline.

    Always returns exactly `days` points ending today (zero-filled), so the
    chart x-axis is date-true and gaps render as gaps, not collapsed points.
    """
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = _resolve_tz(request, db, user_id, tz)

        today_str = get_user_today(user_tz)
        today = datetime.strptime(today_str, "%Y-%m-%d").date()
        start = today - timedelta(days=days - 1)

        rows = (
            db.client.table("mindfulness_sessions")
            .select("duration_seconds, local_date")
            .eq("user_id", user_id)
            .gte("local_date", start.isoformat())
            .lte("local_date", today.isoformat())
            .execute()
        ).data or []

        # Sum seconds per local_date, then minute-round once at the end.
        secs_by_date: dict = {}
        for r in rows:
            d = r.get("local_date")
            if not d:
                continue
            secs_by_date[d] = secs_by_date.get(d, 0) + int(r.get("duration_seconds") or 0)

        points: List[MindfulnessDayPoint] = []
        for i in range(days):
            d = (start + timedelta(days=i)).isoformat()
            points.append(MindfulnessDayPoint(date=d, minutes=secs_by_date.get(d, 0) // 60))

        return MindfulnessHistoryResponse(days=points)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"mindfulness/history failed: {e}", exc_info=True)
        raise safe_internal_error(e, "mindfulness")


async def _today_payload(db, user_id: str, user_tz: str) -> MindfulnessTodayResponse:
    """Build today's aggregate payload (shared by /log and /today)."""
    local_date = get_user_today(user_tz)
    rows = (
        db.client.table("mindfulness_sessions")
        .select("id, source, meditation_slug, duration_seconds, completed_at")
        .eq("user_id", user_id)
        .eq("local_date", local_date)
        .order("completed_at", desc=True)
        .execute()
    ).data or []

    total_seconds = sum(int(r.get("duration_seconds") or 0) for r in rows)
    sessions = [
        MindfulnessSession(
            id=str(r["id"]),
            source=r.get("source") or "meditation",
            meditation_slug=r.get("meditation_slug"),
            duration_seconds=int(r.get("duration_seconds") or 0),
            completed_at=str(r.get("completed_at") or ""),
        )
        for r in rows
    ]

    # Soft daily target. A per-user mindfulness goal column is not shipped yet
    # (see plan); when it is, read it from health_goals here. Until then use the
    # default rather than a guaranteed-failing phantom-column query on every
    # request (project_supabase_schema_drift).
    target = DEFAULT_TARGET_MINUTES

    return MindfulnessTodayResponse(
        minutes=total_seconds // 60,
        target_minutes=target,
        session_count=len(sessions),
        sessions=sessions,
    )
