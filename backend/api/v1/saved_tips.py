"""
/api/v1/saved-tips — list / create / delete tips persisted from the
Imports feature's `tip_save` intent path.

The orchestrator (`/share/fetch-url`, `/share/import-text`,
`/share/import-audio`, `/share/import-pdf`) classifies certain payloads
as `tip_save` (motivational/educational paragraphs from Perplexity, X
threads, voice notes from a trainer, etc.). The orchestrator does NOT
write to `saved_tips` itself — that's the client's job once the user
confirms they want to save the summary. This module owns the
persistence + read API.
"""
from __future__ import annotations

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/saved-tips", tags=["Saved Tips"])


class SavedTipCreate(BaseModel):
    shared_item_id: Optional[str] = None
    source_url: Optional[str] = Field(default=None, max_length=2000)
    source_author: Optional[str] = Field(default=None, max_length=200)
    source_origin: Optional[str] = Field(default=None, max_length=40)
    summary: str = Field(..., min_length=1, max_length=1200)
    full_text: Optional[str] = Field(default=None, max_length=20000)


class SavedTipRow(BaseModel):
    id: str
    shared_item_id: Optional[str] = None
    source_url: Optional[str] = None
    source_author: Optional[str] = None
    source_origin: Optional[str] = None
    summary: str
    full_text: Optional[str] = None
    created_at: str


class SavedTipsListResponse(BaseModel):
    rows: list[SavedTipRow]
    next_cursor: Optional[str] = None


@router.post("", response_model=SavedTipRow)
async def create(
    request: SavedTipCreate,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    payload = {
        "user_id": user_id,
        "shared_item_id": request.shared_item_id,
        "source_url": request.source_url,
        "source_author": request.source_author,
        "source_origin": request.source_origin,
        "summary": request.summary.strip(),
        "full_text": (request.full_text or None),
    }
    try:
        res = db.client.table("saved_tips").insert(payload).execute()
    except Exception as exc:
        raise safe_internal_error(exc, "saved_tips_create")
    if not res.data:
        raise HTTPException(500, "Failed to create saved tip")
    r = res.data[0]
    return SavedTipRow(
        id=str(r["id"]),
        shared_item_id=r.get("shared_item_id"),
        source_url=r.get("source_url"),
        source_author=r.get("source_author"),
        source_origin=r.get("source_origin"),
        summary=r["summary"],
        full_text=r.get("full_text"),
        created_at=r["created_at"],
    )


@router.get("", response_model=SavedTipsListResponse)
async def list_tips(
    limit: int = Query(default=30, ge=1, le=100),
    cursor: Optional[str] = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    qb = (
        db.client.table("saved_tips")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(limit + 1)
    )
    if cursor:
        qb = qb.lt("created_at", cursor)
    res = qb.execute()
    rows = list(res.data or [])
    next_cursor = None
    if len(rows) > limit:
        next_cursor = rows[limit - 1]["created_at"]
        rows = rows[:limit]
    return SavedTipsListResponse(
        rows=[
            SavedTipRow(
                id=str(r["id"]),
                shared_item_id=r.get("shared_item_id"),
                source_url=r.get("source_url"),
                source_author=r.get("source_author"),
                source_origin=r.get("source_origin"),
                summary=r["summary"],
                full_text=r.get("full_text"),
                created_at=r["created_at"],
            )
            for r in rows
        ],
        next_cursor=next_cursor,
    )


@router.delete("/{tip_id}")
async def delete_tip(
    tip_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    db.client.table("saved_tips").delete().eq("id", tip_id).eq(
        "user_id", user_id
    ).execute()
    return {"id": tip_id, "deleted": True}
