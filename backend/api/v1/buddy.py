"""
Buddy workouts — Phase 6 #15 of workouts overhaul.

Two friends pair up + execute the same workout at the same time. Set
completions broadcast via Supabase Realtime (the `buddy_set_events` table
is in the supabase_realtime publication — Flutter subscribes to row inserts
where session_id = current_session.id).

Endpoints
---------
- POST   /api/v1/buddy/start             Create a pending session inviting a
                                         friend (or accept-anyone if no
                                         partner_user_id given).
- POST   /api/v1/buddy/{id}/accept       Partner accepts; status → active.
- POST   /api/v1/buddy/{id}/set-complete Log a completed set; row also lands
                                         on the Realtime channel.
- POST   /api/v1/buddy/{id}/end          Mark session completed/cancelled.
- GET    /api/v1/buddy/active            Return the user's active session
                                         (if any) for the in-app Resume banner.
- GET    /api/v1/buddy/{id}/events       Replay set events (used on screen
                                         attach before the realtime sub catches up).
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()


class StartBuddyIn(BaseModel):
    partner_user_id: Optional[str] = None  # null = open invite to any friend
    workout_id: Optional[str] = None
    exercises_snapshot: Optional[list] = None


class SetCompleteIn(BaseModel):
    exercise_id: str
    exercise_name: Optional[str] = None
    set_number: int = Field(ge=1)
    weight_kg: Optional[float] = None
    reps: Optional[int] = None
    rpe: Optional[float] = None


@router.post("/buddy/start")
async def start_buddy(
    payload: StartBuddyIn,
    current_user: dict = Depends(get_current_user),
):
    """Host creates a pending buddy session. Status flips to 'active' when the
    partner accepts via POST /buddy/{id}/accept."""
    db = get_supabase_db()
    user_id = current_user["id"]
    row = {
        "host_user_id": user_id,
        "partner_user_id": payload.partner_user_id,
        "workout_id": payload.workout_id,
        "status": "pending",
        "exercises_snapshot": payload.exercises_snapshot,
    }
    res = db.client.table("buddy_workout_sessions").insert(row).execute()
    if not res.data:
        raise HTTPException(status_code=500, detail="buddy_session_insert_failed")
    logger.info(
        f"🏋️ [buddy] user={user_id} created session={res.data[0]['id']} "
        f"partner={payload.partner_user_id or '<open>'}"
    )
    return res.data[0]


@router.post("/buddy/{session_id}/accept")
async def accept_buddy(
    session_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Partner accepts a pending session. If the session is open-invite (no
    partner_user_id), the first accepter wins the slot."""
    db = get_supabase_db()
    user_id = current_user["id"]
    row_res = (
        db.client.table("buddy_workout_sessions")
        .select("*").eq("id", session_id).limit(1).execute()
    )
    if not row_res.data:
        raise HTTPException(status_code=404, detail="session_not_found")
    sess = row_res.data[0]
    if sess["status"] != "pending":
        raise HTTPException(status_code=409, detail={"error": "session_not_pending", "status": sess["status"]})
    if sess["host_user_id"] == user_id:
        raise HTTPException(status_code=400, detail="cannot_accept_own_session")
    if sess.get("partner_user_id") and sess["partner_user_id"] != user_id:
        raise HTTPException(status_code=403, detail="not_invited")

    update = {
        "partner_user_id": user_id,
        "status": "active",
        "started_at": datetime.now(timezone.utc).isoformat(),
    }
    upd = (
        db.client.table("buddy_workout_sessions")
        .update(update).eq("id", session_id).execute()
    )
    return upd.data[0] if upd.data else {**sess, **update}


@router.post("/buddy/{session_id}/set-complete")
async def buddy_set_complete(
    session_id: str,
    payload: SetCompleteIn,
    current_user: dict = Depends(get_current_user),
):
    """Append a completed set event. Broadcasts to the partner via Realtime
    (the table is in supabase_realtime publication)."""
    db = get_supabase_db()
    user_id = current_user["id"]
    event = {
        "session_id": session_id,
        "user_id": user_id,
        "exercise_id": payload.exercise_id,
        "exercise_name": payload.exercise_name,
        "set_number": payload.set_number,
        "weight_kg": payload.weight_kg,
        "reps": payload.reps,
        "rpe": payload.rpe,
    }
    try:
        res = db.client.table("buddy_set_events").insert(event).execute()
    except Exception as e:
        logger.error(f"❌ [buddy] set_complete insert failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"insert_failed: {e}")
    return res.data[0] if res.data else event


@router.post("/buddy/{session_id}/end")
async def end_buddy(
    session_id: str,
    cancelled: bool = False,
    current_user: dict = Depends(get_current_user),
):
    """End a session (completed by default; cancelled=true marks it dropped)."""
    db = get_supabase_db()
    new_status = "cancelled" if cancelled else "completed"
    res = (
        db.client.table("buddy_workout_sessions")
        .update({
            "status": new_status,
            "ended_at": datetime.now(timezone.utc).isoformat(),
        })
        .eq("id", session_id)
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="session_not_found")
    return res.data[0]


@router.get("/buddy/active")
async def active_buddy(current_user: dict = Depends(get_current_user)):
    """Return the user's currently-active session (if any). Powers the
    "Resume buddy workout" home banner."""
    db = get_supabase_db()
    user_id = current_user["id"]
    res = (
        db.client.table("buddy_workout_sessions")
        .select("*")
        .eq("status", "active")
        .or_(f"host_user_id.eq.{user_id},partner_user_id.eq.{user_id}")
        .limit(1)
        .execute()
    )
    return {"session": (res.data or [None])[0]}


@router.get("/buddy/{session_id}/events")
async def buddy_events_replay(
    session_id: str,
    limit: int = 200,
    current_user: dict = Depends(get_current_user),
):
    """Replay event history when the client attaches mid-session. Realtime
    subscription only delivers events AFTER subscribe; this fills the gap."""
    db = get_supabase_db()
    res = (
        db.client.table("buddy_set_events")
        .select("*")
        .eq("session_id", session_id)
        .order("completed_at", desc=False)
        .limit(limit)
        .execute()
    )
    return {"events": res.data or [], "count": len(res.data or [])}
