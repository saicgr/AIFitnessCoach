"""Menu Analyses: persisted menu/buffet scans the user can reopen later.

Also hosts the two auxiliary endpoints the Menu Analysis sheet uses during
recommendation pre-fetch:

- `GET /nutrition/food-log-history/frequency` — normalized dish-name
  frequency map over the user's last N days of food_logs.
- `GET /nutrition/menu-items/similar` — ChromaDB lookup for semantically
  similar menu items the user has liked before (liked=true, matched by
  cosine in the `menu_items` collection).

Kept in one file because they share helpers (normalization, auth,
error wrappers). The CRUD endpoints + `similar` endpoint all live
under the `/nutrition` prefix mounted by `api/v1/nutrition/__init__.py`.
"""
from __future__ import annotations

import re
import uuid
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


# ───────────────────────────────────────────────────────────────
# Pydantic schemas
# ───────────────────────────────────────────────────────────────


class MenuAnalysisCreate(BaseModel):
    """Request body for saving a menu analysis as a reusable artifact."""
    title: Optional[str] = None
    restaurant_name: Optional[str] = None
    analysis_type: str = Field(..., pattern=r"^(plate|menu|buffet)$")
    sections: List[Dict[str, Any]] = Field(default_factory=list)
    food_items: List[Dict[str, Any]] = Field(default_factory=list)
    menu_photo_urls: List[str] = Field(default_factory=list)
    elapsed_seconds: Optional[float] = None


class MenuAnalysisUpdate(BaseModel):
    title: Optional[str] = None
    restaurant_name: Optional[str] = None
    is_pinned: Optional[bool] = None


class MenuAnalysisOut(BaseModel):
    id: str
    title: Optional[str]
    restaurant_name: Optional[str]
    analysis_type: str
    sections: List[Dict[str, Any]]
    food_items: List[Dict[str, Any]]
    menu_photo_urls: List[str]
    elapsed_seconds: Optional[float]
    is_pinned: bool
    times_opened: int
    last_opened_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime


# ───────────────────────────────────────────────────────────────
# Helpers
# ───────────────────────────────────────────────────────────────


_STOPWORDS = {
    "the", "a", "an", "of", "with", "and", "&", "w/", "w", "in",
    "on", "at", "for", "to", "from", "by", "fresh", "house", "side",
    "signature", "classic", "traditional", "special",
}


def _normalize_dish_name(raw: str) -> str:
    """Lowercase, strip accents/punctuation, drop stopwords, collapse
    whitespace. Used for both history frequency buckets and similarity
    short-circuit checks."""
    if not raw:
        return ""
    lowered = raw.lower().strip()
    # Replace punctuation with spaces
    cleaned = re.sub(r"[^\w\s]", " ", lowered)
    tokens = [t for t in cleaned.split() if t and t not in _STOPWORDS]
    return " ".join(tokens)


def _row_to_out(row: Dict[str, Any]) -> MenuAnalysisOut:
    return MenuAnalysisOut(
        id=row["id"],
        title=row.get("title"),
        restaurant_name=row.get("restaurant_name"),
        analysis_type=row["analysis_type"],
        sections=row.get("sections") or [],
        food_items=row.get("food_items") or [],
        menu_photo_urls=row.get("menu_photo_urls") or [],
        elapsed_seconds=row.get("elapsed_seconds"),
        is_pinned=bool(row.get("is_pinned", False)),
        times_opened=int(row.get("times_opened") or 0),
        last_opened_at=row.get("last_opened_at"),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


async def _index_menu_items_in_chroma(
    *,
    menu_analysis_id: str,
    user_id: str,
    restaurant_name: Optional[str],
    food_items: List[Dict[str, Any]],
) -> None:
    """BackgroundTask helper — upsert every parsed dish into the
    `menu_items` ChromaDB collection so cross-menu similarity recall
    works during future recommendation pre-fetch. Best-effort; failures
    are logged but don't break the save."""
    try:
        from services.menu_items_rag_service import get_menu_items_rag

        rag = get_menu_items_rag()
        await rag.upsert_dishes(
            menu_analysis_id=menu_analysis_id,
            user_id=user_id,
            restaurant_name=restaurant_name,
            food_items=food_items,
        )
    except Exception as exc:
        logger.warning(
            f"[Chroma] menu_items upsert failed for {menu_analysis_id}: {exc}",
            exc_info=True,
        )


# ───────────────────────────────────────────────────────────────
# CRUD — menu analyses
# ───────────────────────────────────────────────────────────────


@router.get("/menu-analyses", response_model=List[MenuAnalysisOut])
async def list_menu_analyses(
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=200),
):
    """List the current user's saved menu analyses, pinned first."""
    user_id = current_user["id"]
    db = get_supabase_db()
    resp = (
        db.client.table("menu_analyses")
        .select("*")
        .eq("user_id", user_id)
        .is_("deleted_at", "null")
        .order("is_pinned", desc=True)
        .order("last_opened_at", desc=True, nullsfirst=False)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    return [_row_to_out(r) for r in (resp.data or [])]


@router.get("/menu-analyses/{menu_id}", response_model=MenuAnalysisOut)
async def get_menu_analysis(
    menu_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    resp = (
        db.client.table("menu_analyses")
        .select("*")
        .eq("id", menu_id)
        .eq("user_id", user_id)
        .is_("deleted_at", "null")
        .limit(1)
        .execute()
    )
    rows = resp.data or []
    if not rows:
        raise HTTPException(status_code=404, detail="Menu analysis not found")

    # Increment times_opened + last_opened_at (fire-and-forget pattern)
    db.client.table("menu_analyses").update({
        "times_opened": (rows[0].get("times_opened") or 0) + 1,
        "last_opened_at": datetime.now(tz=timezone.utc).isoformat(),
    }).eq("id", menu_id).eq("user_id", user_id).execute()

    return _row_to_out(rows[0])


@router.post("/menu-analyses", response_model=MenuAnalysisOut)
async def create_menu_analysis(
    payload: MenuAnalysisCreate,
    background: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Persist a menu analysis. Called after a successful scan either
    explicitly (bookmark button) or automatically at the end of the
    SSE pipeline. Idempotent-ish — callers may submit the same menu
    twice; we store duplicates and let the user dedupe via the
    history UI."""
    user_id = current_user["id"]
    db = get_supabase_db()

    row = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "title": payload.title,
        "restaurant_name": payload.restaurant_name,
        "analysis_type": payload.analysis_type,
        "sections": payload.sections,
        "food_items": payload.food_items,
        "menu_photo_urls": payload.menu_photo_urls,
        "elapsed_seconds": payload.elapsed_seconds,
    }
    resp = db.client.table("menu_analyses").insert(row).execute()
    rows = resp.data or []
    if not rows:
        raise HTTPException(status_code=500, detail="Failed to save menu analysis")

    # Index dishes into ChromaDB in the background so the Recommended
    # section of a FUTURE menu scan can pull "similar to what you liked".
    background.add_task(
        _index_menu_items_in_chroma,
        menu_analysis_id=rows[0]["id"],
        user_id=user_id,
        restaurant_name=payload.restaurant_name,
        food_items=payload.food_items,
    )

    return _row_to_out(rows[0])


@router.patch("/menu-analyses/{menu_id}", response_model=MenuAnalysisOut)
async def update_menu_analysis(
    menu_id: str,
    payload: MenuAnalysisUpdate,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()

    updates: Dict[str, Any] = {}
    if payload.title is not None:
        updates["title"] = payload.title
    if payload.restaurant_name is not None:
        updates["restaurant_name"] = payload.restaurant_name
    if payload.is_pinned is not None:
        updates["is_pinned"] = payload.is_pinned

    if not updates:
        # No-op update — just return the current row
        return await get_menu_analysis(menu_id, current_user)

    resp = (
        db.client.table("menu_analyses")
        .update(updates)
        .eq("id", menu_id)
        .eq("user_id", user_id)
        .execute()
    )
    rows = resp.data or []
    if not rows:
        raise HTTPException(status_code=404, detail="Menu analysis not found")
    return _row_to_out(rows[0])


@router.delete("/menu-analyses/{menu_id}")
async def delete_menu_analysis(
    menu_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    # Soft delete
    db.client.table("menu_analyses").update({
        "deleted_at": datetime.now(tz=timezone.utc).isoformat(),
    }).eq("id", menu_id).eq("user_id", user_id).execute()
    return {"success": True}


# ───────────────────────────────────────────────────────────────
# History frequency map — used by recommendation pre-fetch
# ───────────────────────────────────────────────────────────────


class HistoryFrequencyResponse(BaseModel):
    frequency: Dict[str, int]  # normalized_dish_name -> count
    total_logs: int
    days: int


@router.get("/food-log-history/frequency", response_model=HistoryFrequencyResponse)
async def food_log_history_frequency(
    current_user: dict = Depends(get_current_user),
    days: int = Query(default=60, ge=1, le=365),
    limit: int = Query(default=500, ge=1, le=2000),
):
    """Return a {normalized_dish_name: count} frequency map over the
    user's recent food logs. Menu-Analysis recommendation scoring uses
    this to compute `historyAffinity` — how much a candidate dish
    resembles what the user habitually logs."""
    user_id = current_user["id"]
    db = get_supabase_db()

    since = (datetime.now(tz=timezone.utc) - timedelta(days=days)).isoformat()
    resp = (
        db.client.table("food_logs")
        .select("food_name, logged_at")
        .eq("user_id", user_id)
        .gte("logged_at", since)
        .is_("deleted_at", "null")
        .order("logged_at", desc=True)
        .limit(limit)
        .execute()
    )
    rows = resp.data or []

    counter: Counter[str] = Counter()
    for row in rows:
        normalized = _normalize_dish_name(row.get("food_name") or "")
        if normalized:
            counter[normalized] += 1

    return HistoryFrequencyResponse(
        frequency=dict(counter),
        total_logs=len(rows),
        days=days,
    )


# ───────────────────────────────────────────────────────────────
# menu_items similarity — cross-menu semantic recall
# ───────────────────────────────────────────────────────────────


class SimilarMenuItem(BaseModel):
    dish_name: str
    restaurant_name: Optional[str]
    cosine: float
    liked: bool
    menu_analysis_id: Optional[str]
    calories: Optional[float]
    protein_g: Optional[float]


class SimilarMenuItemsResponse(BaseModel):
    query: str
    results: List[SimilarMenuItem]


@router.get("/menu-items/similar", response_model=SimilarMenuItemsResponse)
async def similar_menu_items(
    query: str = Query(..., min_length=1, description="Dish name or phrase to find semantic neighbors for"),
    current_user: dict = Depends(get_current_user),
    k: int = Query(default=10, ge=1, le=50),
    liked_only: bool = Query(default=True, description="Restrict to dishes the user has historically logged/liked"),
):
    """Query the `menu_items` ChromaDB collection for semantically similar
    dishes the user has previously seen on a menu (and optionally liked).
    Used by the recommendation pipeline to seed `favoriteMatch` and
    `historyAffinity` with TRUE semantic similarity rather than
    keyword-only fallback."""
    user_id = current_user["id"]

    try:
        from services.menu_items_rag_service import get_menu_items_rag

        rag = get_menu_items_rag()
        hits = await rag.query_similar(
            query=query,
            user_id=user_id,
            k=k,
            liked_only=liked_only,
        )
    except Exception as exc:
        # Graceful degradation — if ChromaDB is down or collection
        # is empty, return no results rather than 500. Recommendation
        # pipeline treats empty results as a neutral signal.
        logger.warning(
            f"[Chroma] menu_items query failed user={user_id} query={query!r}: {exc}",
            exc_info=True,
        )
        return SimilarMenuItemsResponse(query=query, results=[])

    return SimilarMenuItemsResponse(
        query=query,
        results=[SimilarMenuItem(**h) for h in hits],
    )
