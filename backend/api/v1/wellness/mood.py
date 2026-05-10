"""Mood logging endpoints (POST /wellness/mood/log, GET /wellness/mood/today).

Backed by the `mood_log` table created in migration
`create_mood_log_and_supporting_indexes` (2026-05-10). Used by:
- Direct frontend mood picker
- LangGraph wellness agent's `log_event(domain='mood', ...)` flow
- Timeline aggregator (reads /wellness/mood/today via service helper)
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import get_user_today, local_date_to_utc_range, resolve_timezone

logger = get_logger(__name__)
router = APIRouter()


# --- Allowed values --------------------------------------------------------

ALLOWED_MOODS = {
    "great", "good", "ok", "low", "bad",
    "anxious", "stressed", "tired", "energized", "focused", "happy", "sad",
}

ALLOWED_SOURCES = {
    "chat", "manual", "voice", "auto_inference", "wearable_sync",
}


# --- Request/response models ----------------------------------------------

class MoodLogRequest(BaseModel):
    user_id: str = Field(..., max_length=64)
    mood: str = Field(..., max_length=32, description="One of ALLOWED_MOODS")
    energy_level: Optional[int] = Field(None, ge=1, le=5)
    notes: Optional[str] = Field(None, max_length=500)
    source: str = Field("manual", max_length=32)
    occurred_at: Optional[str] = Field(None, description="ISO8601, defaults to now in user TZ")


class MoodEntry(BaseModel):
    id: str
    mood: str
    energy_level: Optional[int]
    notes: Optional[str]
    source: str
    occurred_at: str


# --- Endpoints -------------------------------------------------------------

@router.post("/log", response_model=MoodEntry)
async def log_mood(
    request: Request,
    body: MoodLogRequest,
    current_user: dict = Depends(get_current_user),
):
    """Log a mood entry. Idempotency for chat-originated calls is handled at
    the /events/log facade — direct callers should de-dup on the client."""
    if body.mood.lower().strip() not in ALLOWED_MOODS:
        raise HTTPException(
            status_code=400,
            detail=f"mood must be one of {sorted(ALLOWED_MOODS)}",
        )
    source = body.source.lower().strip()
    if source not in ALLOWED_SOURCES:
        raise HTTPException(
            status_code=400,
            detail=f"source must be one of {sorted(ALLOWED_SOURCES)}",
        )

    db = get_supabase_db()
    occurred_at = body.occurred_at or datetime.now(timezone.utc).isoformat()

    row = {
        "user_id": body.user_id,
        "mood": body.mood.lower().strip(),
        "energy_level": body.energy_level,
        "notes": body.notes,
        "source": source,
        "occurred_at": occurred_at,
    }
    try:
        result = db.client.table("mood_log").insert(row).execute()
    except Exception as e:
        logger.error(f"[Mood] insert failed for {body.user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to log mood")

    if not result.data:
        raise HTTPException(status_code=500, detail="Mood insert returned empty")
    inserted = result.data[0]

    # Invalidate timeline cache so the new mood lands in /timeline immediately.
    try:
        from api.v1.timeline_cache import invalidate_timeline_cache
        user_tz = resolve_timezone(request, db, body.user_id)
        local_date = get_user_today(user_tz)  # mood almost always today
        await invalidate_timeline_cache(body.user_id, local_date)
    except Exception:
        pass

    return MoodEntry(
        id=inserted["id"],
        mood=inserted["mood"],
        energy_level=inserted.get("energy_level"),
        notes=inserted.get("notes"),
        source=inserted["source"],
        occurred_at=inserted["occurred_at"],
    )


@router.get("/today")
async def get_today_mood(
    request: Request,
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Return today's mood entries in the user's local timezone."""
    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    today_str = get_user_today(user_tz)
    range_start, range_end = local_date_to_utc_range(today_str, user_tz)

    result = db.client.table("mood_log").select("*").eq(
        "user_id", user_id,
    ).gte(
        "occurred_at", range_start,
    ).lte(
        "occurred_at", range_end,
    ).is_(
        "deleted_at", "null",
    ).order("occurred_at", desc=True).execute()

    return {"entries": result.data or [], "date": today_str, "user_tz": user_tz}
