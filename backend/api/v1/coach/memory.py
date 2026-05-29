"""
Coach memory API (migration 2217).

User-facing CRUD for the "What Coach remembers" screen + the nightly
consolidation cron. Memories are user-scoped via get_current_user; the cron
endpoint is protected by the shared X-Cron-Secret header.

Routes (mounted under /coach):
  GET    /coach/memory                 list the user's memories (grouped)
  PATCH  /coach/memory/{id}            edit/correct a memory's content
  POST   /coach/memory/{id}/resolve    close an open loop (also used by chips)
  DELETE /coach/memory/{id}            forget one (tombstone; ?hard=true purges)
  GET    /coach/memory/settings        { enabled }
  PUT    /coach/memory/settings        set master memory toggle
  DELETE /coach/memory                 forget everything (hard purge)
  POST   /coach/memory/consolidate     nightly reflection (cron-only)
"""
import hmac
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request
from pydantic import BaseModel

from core.auth import get_current_user
from core.config import get_settings
from core.db import get_supabase_db

logger = logging.getLogger("coach_memory_api")

router = APIRouter()


# --------------------------------------------------------------------------- models
class MemoryItem(BaseModel):
    id: str
    memory_type: str
    category: str
    content: str
    status: str
    salience: float
    sensitive: bool
    source_quote: Optional[str] = None
    resolution_prompt: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class MemoryListResponse(BaseModel):
    enabled: bool
    total: int
    items: List[MemoryItem]


class MemoryEdit(BaseModel):
    content: Optional[str] = None
    salience: Optional[float] = None


class MemorySettings(BaseModel):
    enabled: bool


def _to_item(row: dict) -> MemoryItem:
    return MemoryItem(
        id=row.get("id"),
        memory_type=row.get("memory_type") or "semantic",
        category=row.get("category") or "other",
        content=row.get("content") or "",
        status=row.get("status") or "active",
        salience=float(row.get("salience") or 0.5),
        sensitive=bool(row.get("sensitive")),
        source_quote=row.get("source_quote"),
        resolution_prompt=row.get("resolution_prompt"),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


# --------------------------------------------------------------------------- list
@router.get("/memory", response_model=MemoryListResponse)
async def list_memory(
    include_resolved: bool = Query(False, description="Include resolved/superseded history"),
    q: Optional[str] = Query(None, description="Search within memory content"),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    user_id = current_user["id"]
    enabled = db.memory.get_memory_enabled(user_id)
    if q:
        rows = db.memory.search_memories(user_id, q, limit=100)
    elif include_resolved:
        rows = db.memory.list_memories(
            user_id,
            statuses=["active", "open", "provisional", "resolved", "superseded"],
            limit=300,
        )
    else:
        rows = db.memory.list_memories(
            user_id, statuses=["active", "open", "provisional"], limit=200
        )
    items = [_to_item(r) for r in rows]
    return MemoryListResponse(enabled=enabled, total=len(items), items=items)


# --------------------------------------------------------------------------- edit
@router.patch("/memory/{memory_id}", response_model=MemoryItem)
async def edit_memory(
    memory_id: str,
    body: MemoryEdit,
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    user_id = current_user["id"]
    existing = db.memory.get_memory(memory_id, user_id)
    if not existing:
        raise HTTPException(404, "Memory not found")
    patch = {}
    if body.content is not None:
        patch["content"] = body.content.strip()[:600]
    if body.salience is not None:
        patch["salience"] = max(0.0, min(1.0, body.salience))
    if not patch:
        return _to_item(existing)
    updated = db.memory.update_memory(memory_id, user_id, patch)
    # Re-index the corrected content so relevance retrieval stays accurate.
    if updated and body.content is not None:
        try:
            from services.coach.memory import embeddings
            embeddings.index_memory(updated)
        except Exception:
            pass
    return _to_item(updated or existing)


# --------------------------------------------------------------------------- resolve
@router.post("/memory/{memory_id}/resolve", response_model=MemoryItem)
async def resolve_memory(memory_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    user_id = current_user["id"]
    existing = db.memory.get_memory(memory_id, user_id)
    if not existing:
        raise HTTPException(404, "Memory not found")
    resolved = db.memory.resolve_memory(memory_id, user_id)
    # Cascade to a linked injury_history row if present.
    if existing.get("linked_table") == "injury_history" and existing.get("linked_id"):
        try:
            db.client.table("injury_history").update(
                {"is_active": False}
            ).eq("id", existing["linked_id"]).execute()
        except Exception:
            pass
    return _to_item(resolved or existing)


# --------------------------------------------------------------------------- delete one
@router.delete("/memory/{memory_id}")
async def delete_memory(
    memory_id: str,
    hard: bool = Query(False, description="Hard delete instead of tombstone"),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    user_id = current_user["id"]
    existing = db.memory.get_memory(memory_id, user_id)
    if not existing:
        raise HTTPException(404, "Memory not found")
    if hard:
        db.memory.hard_delete_memory(memory_id, user_id)
        try:
            from services.coach.memory import embeddings
            embeddings.delete_memory(user_id, memory_id)
        except Exception:
            pass
    else:
        # Tombstone (status=dismissed) so the extractor won't re-add it.
        db.memory.dismiss_memory(memory_id, user_id)
        try:
            from services.coach.memory import embeddings
            embeddings.delete_memory(user_id, memory_id)
        except Exception:
            pass
    return {"ok": True, "hard": hard}


# --------------------------------------------------------------------------- settings
@router.get("/memory/settings", response_model=MemorySettings)
async def get_memory_settings(current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    return MemorySettings(enabled=db.memory.get_memory_enabled(current_user["id"]))


@router.put("/memory/settings", response_model=MemorySettings)
async def set_memory_settings(
    body: MemorySettings, current_user: dict = Depends(get_current_user)
):
    db = get_supabase_db()
    db.memory.set_memory_enabled(current_user["id"], body.enabled)
    return MemorySettings(enabled=body.enabled)


# --------------------------------------------------------------------------- purge
@router.delete("/memory")
async def forget_everything(current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    db.memory.delete_all_for_user(current_user["id"])
    return {"ok": True}


# --------------------------------------------------------------------------- cron
def _verify_cron_secret(x_cron_secret: Optional[str]):
    cron_secret = get_settings().cron_secret
    if not cron_secret or len(cron_secret) < 32:
        raise HTTPException(503, "Cron secret not configured")
    if not x_cron_secret or not hmac.compare_digest(x_cron_secret, cron_secret):
        raise HTTPException(401, "Invalid cron secret")


@router.post("/memory/consolidate")
async def consolidate(
    request: Request,
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """Nightly reflection over every user with active memory: dedupe, decay,
    open-loop expiry, episodic->semantic promotion, derived insights."""
    _verify_cron_secret(x_cron_secret)
    from services.coach.memory.pipeline import consolidate_all_active
    totals = consolidate_all_active()
    return {"ok": True, **totals}
