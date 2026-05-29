"""
Chat sessions API (migration 2218) — the Ask-Coach conversation list.

Routes (mounted under /coach):
  GET    /coach/sessions                list (q= search, include_archived, paging)
  POST   /coach/sessions                create an (empty) session
  GET    /coach/sessions/{id}           session metadata
  GET    /coach/sessions/{id}/messages  the session's chat turns (scoped history)
  PATCH  /coach/sessions/{id}           rename / archive
  DELETE /coach/sessions/{id}           delete (cascades its turns)
"""
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db

logger = logging.getLogger("coach_sessions_api")

router = APIRouter()


class SessionItem(BaseModel):
    id: str
    title: Optional[str] = None
    preview: Optional[str] = None
    is_archived: bool = False
    message_count: int = 0
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    last_message_at: Optional[str] = None


class SessionListResponse(BaseModel):
    total: int
    items: List[SessionItem]


class CreateSession(BaseModel):
    title: Optional[str] = None


class UpdateSession(BaseModel):
    title: Optional[str] = None
    is_archived: Optional[bool] = None


def _to_item(row: dict) -> SessionItem:
    return SessionItem(
        id=row.get("id"),
        title=row.get("title"),
        preview=row.get("preview"),
        is_archived=bool(row.get("is_archived")),
        message_count=int(row.get("message_count") or 0),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
        last_message_at=row.get("last_message_at"),
    )


@router.get("/sessions", response_model=SessionListResponse)
async def list_sessions(
    q: Optional[str] = Query(None, description="Search title + message content"),
    include_archived: bool = Query(False),
    limit: int = Query(100, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    uid = current_user["id"]
    if q and q.strip():
        rows = db.sessions.search_sessions(uid, q.strip(), limit=limit)
    else:
        rows = db.sessions.list_sessions(uid, include_archived=include_archived,
                                         limit=limit, offset=offset)
    items = [_to_item(r) for r in rows]
    return SessionListResponse(total=len(items), items=items)


@router.post("/sessions", response_model=SessionItem)
async def create_session(body: CreateSession, current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    row = db.sessions.create_session(current_user["id"], title=body.title)
    if not row:
        raise HTTPException(500, "Failed to create session")
    return _to_item(row)


@router.get("/sessions/{session_id}", response_model=SessionItem)
async def get_session(session_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    row = db.sessions.get_session(session_id, current_user["id"])
    if not row:
        raise HTTPException(404, "Session not found")
    return _to_item(row)


@router.get("/sessions/{session_id}/messages")
async def get_session_messages(
    session_id: str,
    limit: int = Query(200, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    """The session's chat turns, oldest first (same shape as /chat/history)."""
    db = get_supabase_db()
    uid = current_user["id"]
    if not db.sessions.get_session(session_id, uid):
        raise HTTPException(404, "Session not found")
    rows = (
        db.client.table("chat_history")
        .select(
            "id, user_id, user_message, ai_response, context_json, timestamp, "
            "is_pinned, audio_url, audio_duration_ms, media_url, media_type, "
            "source_surface, insight_id, session_id"
        )
        .eq("user_id", uid)
        .eq("session_id", session_id)
        .order("timestamp", desc=False)
        .range(offset, offset + limit - 1)
        .execute()
    ).data or []
    return {"session_id": session_id, "messages": rows}


@router.patch("/sessions/{session_id}", response_model=SessionItem)
async def update_session(
    session_id: str, body: UpdateSession, current_user: dict = Depends(get_current_user)
):
    db = get_supabase_db()
    uid = current_user["id"]
    existing = db.sessions.get_session(session_id, uid)
    if not existing:
        raise HTTPException(404, "Session not found")
    patch = {}
    if body.title is not None:
        patch["title"] = body.title.strip()[:120]
    if body.is_archived is not None:
        patch["is_archived"] = body.is_archived
    if not patch:
        return _to_item(existing)
    updated = db.sessions.update_session(session_id, uid, patch)
    return _to_item(updated or existing)


@router.delete("/sessions/{session_id}")
async def delete_session(session_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    uid = current_user["id"]
    if not db.sessions.get_session(session_id, uid):
        raise HTTPException(404, "Session not found")
    db.sessions.delete_session(session_id, uid)
    return {"ok": True}
