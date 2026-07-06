"""Public roadmap API for the marketing site.

Powers the public /roadmap kanban board on zealova.com: anonymous,
email-keyed feature voting + flat comments + visitor feature suggestions.

Deliberately separate from the auth-keyed in-app feature board
(api/v1/features.py + migration 046) — the marketing site has no logged-in
users. Board CONTENT lives in a TS data file (frontend/src/data/roadmap.ts);
these endpoints only serve the dynamic votes / comments / suggestions, keyed
by the stable `feature_slug` string.

Tables: migration 2078 (roadmap_votes, roadmap_comments, roadmap_suggestions).
All writes use the service-role Supabase client and are rate-limited per IP.

ENDPOINTS (mounted at /api/v1/roadmap):
- GET  /state                   - vote + comment counts per slug (board hydration)
- POST /vote                    - email-keyed vote (idempotent on re-vote)
- GET  /comments/{feature_slug} - flat comment list
- POST /comment                 - add a flat comment
- POST /suggest                 - submit a feature suggestion (admin-moderated)

RATE LIMITS: /vote 20/hr, /comment 10/hr, /suggest 5/hr (per IP).
"""
import asyncio
from collections import Counter
from typing import Optional

from cachetools import TTLCache
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, EmailStr, Field

from core.logger import get_logger
from core.rate_limiter import limiter
from core.supabase_client import get_supabase

logger = get_logger(__name__)
router = APIRouter()

# The board is public and re-fetched on every page view, but vote/comment
# counts don't need to be real-time — voting/commenting updates the caller's
# own view optimistically client-side (see Roadmap.tsx handleVoted/
# handleCommentAdded), so a short-lived cache is invisible to the voter and
# saves two Supabase round-trips for every other visitor in the window.
_STATE_CACHE: "TTLCache[str, dict]" = TTLCache(maxsize=1, ttl=20)


# ===================================
# Request models
# ===================================

class VoteRequest(BaseModel):
    feature_slug: str = Field(min_length=1, max_length=120)
    email: EmailStr
    notify_on_ship: bool = True
    # Honeypot — bots fill every field. Legit submissions leave this blank.
    website: Optional[str] = Field(default=None, max_length=200)


class CommentRequest(BaseModel):
    feature_slug: str = Field(min_length=1, max_length=120)
    author_name: str = Field(min_length=1, max_length=80)
    body: str = Field(min_length=1, max_length=1000)
    email: Optional[EmailStr] = None
    parent_id: Optional[str] = Field(default=None, max_length=64)  # reply target
    website: Optional[str] = Field(default=None, max_length=200)  # honeypot


# Threaded comments are capped at 10 levels: depth 0 (top-level) .. depth 9.
MAX_COMMENT_DEPTH = 9


class SuggestRequest(BaseModel):
    email: EmailStr
    title: str = Field(min_length=3, max_length=140)
    body: str = Field(min_length=10, max_length=1000)
    website: Optional[str] = Field(default=None, max_length=200)  # honeypot


def _is_unique_violation(err: Exception) -> bool:
    """Postgres unique-constraint violation, surfaced via the supabase client."""
    msg = str(err).lower()
    return "duplicate" in msg or "23505" in msg or "unique" in msg


# ===================================
# Endpoints
# ===================================

@router.get("/state")
async def get_roadmap_state():
    """Vote + comment counts keyed by feature_slug.

    One call drives the whole board's client-side hydration. The board's
    static content is prerendered; only these numbers are dynamic.
    """
    cached = _STATE_CACHE.get("state")
    if cached is not None:
        return cached

    db = get_supabase()

    def _fetch_votes():
        return db.client.table("roadmap_votes").select("feature_slug").execute()

    def _fetch_comments():
        return (
            db.client.table("roadmap_comments")
            .select("feature_slug")
            .eq("is_hidden", False)
            .execute()
        )

    try:
        # Two independent Supabase REST calls — run them concurrently instead
        # of back-to-back (was ~1s serial, now bounded by the slower of the two).
        votes, comments = await asyncio.gather(
            asyncio.to_thread(_fetch_votes),
            asyncio.to_thread(_fetch_comments),
        )
    except Exception as e:
        logger.error(f"[roadmap] state fetch failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not load roadmap state.")

    vote_counts = Counter(r["feature_slug"] for r in (votes.data or []))
    comment_counts = Counter(r["feature_slug"] for r in (comments.data or []))

    result = {
        slug: {
            "vote_count": vote_counts.get(slug, 0),
            "comment_count": comment_counts.get(slug, 0),
        }
        for slug in (set(vote_counts) | set(comment_counts))
    }
    _STATE_CACHE["state"] = result
    return result


@router.post("/vote")
@limiter.limit("20/hour")
async def vote(request: Request, payload: VoteRequest):
    """Record an email-keyed vote for a feature.

    Frictionless — no email confirmation. Re-voting with the same email is
    idempotent (the unique index absorbs it) and returns already_voted=true.
    """
    if payload.website:  # honeypot tripped — bot. Fake success, drop.
        logger.info("[roadmap] vote honeypot triggered")
        return {"success": True, "already_voted": False, "vote_count": 0}

    slug = payload.feature_slug.strip()
    email_lower = str(payload.email).strip().lower()
    db = get_supabase()

    already_voted = False
    try:
        db.client.table("roadmap_votes").insert({
            "feature_slug": slug,
            "email": email_lower,
            "notify_on_ship": payload.notify_on_ship,
        }).execute()
    except Exception as e:
        if _is_unique_violation(e):
            already_voted = True
        else:
            logger.error(f"[roadmap] vote insert failed slug={slug}: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Could not record vote. Please try again.")

    try:
        rows = (
            db.client.table("roadmap_votes")
            .select("id", count="exact")
            .eq("feature_slug", slug)
            .execute()
        )
        vote_count = rows.count or 0
    except Exception:
        vote_count = 0

    logger.info(f"[roadmap] vote slug={slug} already={already_voted} count={vote_count}")
    return {"success": True, "already_voted": already_voted, "vote_count": vote_count}


@router.get("/comments/{feature_slug}")
async def list_comments(feature_slug: str):
    """All comments for a feature, oldest-first. Threaded — each row carries
    parent_id + depth; the client assembles the tree."""
    db = get_supabase()
    try:
        rows = (
            db.client.table("roadmap_comments")
            .select("id, author_name, body, created_at, parent_id, depth")
            .eq("feature_slug", feature_slug.strip())
            .eq("is_hidden", False)
            .order("created_at", desc=False)
            .execute()
        )
    except Exception as e:
        logger.error(f"[roadmap] comments fetch failed slug={feature_slug}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not load comments.")
    return {"comments": rows.data or []}


@router.post("/comment")
@limiter.limit("10/hour")
async def add_comment(request: Request, payload: CommentRequest):
    """Post a flat comment on a feature."""
    if payload.website:  # honeypot tripped — bot. Fake success, drop.
        logger.info("[roadmap] comment honeypot triggered")
        return {"success": True, "comment": None}

    slug = payload.feature_slug.strip()
    author = payload.author_name.strip()
    body = payload.body.strip()
    db = get_supabase()

    # Resolve the reply target (if any) and compute thread depth.
    parent_id = (payload.parent_id or "").strip() or None
    depth = 0
    if parent_id:
        try:
            parent = (
                db.client.table("roadmap_comments")
                .select("feature_slug, depth")
                .eq("id", parent_id)
                .single()
                .execute()
            )
            prow = parent.data
        except Exception:
            prow = None
        if not prow or prow.get("feature_slug") != slug:
            raise HTTPException(status_code=400, detail="Reply target not found.")
        depth = (prow.get("depth") or 0) + 1
        if depth > MAX_COMMENT_DEPTH:
            raise HTTPException(status_code=400, detail="Maximum reply depth reached.")

    try:
        ins = db.client.table("roadmap_comments").insert({
            "feature_slug": slug,
            "author_name": author,
            "body": body,
            "email": (str(payload.email).strip().lower() if payload.email else None),
            "parent_id": parent_id,
            "depth": depth,
        }).execute()
    except Exception as e:
        logger.error(f"[roadmap] comment insert failed slug={slug}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not post comment. Please try again.")

    row = (ins.data or [{}])[0]
    logger.info(f"[roadmap] comment slug={slug} by={author} depth={depth}")
    return {
        "success": True,
        "comment": {
            "id": row.get("id"),
            "author_name": author,
            "body": body,
            "created_at": row.get("created_at"),
            "parent_id": parent_id,
            "depth": depth,
        },
    }


@router.post("/suggest")
@limiter.limit("5/hour")
async def suggest_feature(request: Request, payload: SuggestRequest):
    """Submit a feature suggestion. Stored as 'pending' for admin moderation."""
    if payload.website:  # honeypot tripped — bot. Fake success, drop.
        logger.info("[roadmap] suggestion honeypot triggered")
        return {"success": True, "message": "Thanks for the idea."}

    db = get_supabase()
    try:
        db.client.table("roadmap_suggestions").insert({
            "email": str(payload.email).strip().lower(),
            "title": payload.title.strip(),
            "body": payload.body.strip(),
        }).execute()
    except Exception as e:
        logger.error(f"[roadmap] suggestion insert failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not submit suggestion. Please try again.")

    logger.info(f"[roadmap] suggestion received: {payload.title.strip()[:60]!r}")
    return {"success": True, "message": "Thanks — we read every suggestion."}
