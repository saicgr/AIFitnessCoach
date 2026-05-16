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
from collections import Counter
from typing import Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, EmailStr, Field

from core.logger import get_logger
from core.rate_limiter import limiter
from core.supabase_client import get_supabase

logger = get_logger(__name__)
router = APIRouter()


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
    website: Optional[str] = Field(default=None, max_length=200)  # honeypot


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
    db = get_supabase()
    try:
        votes = db.client.table("roadmap_votes").select("feature_slug").execute()
        comments = (
            db.client.table("roadmap_comments")
            .select("feature_slug")
            .eq("is_hidden", False)
            .execute()
        )
    except Exception as e:
        logger.error(f"[roadmap] state fetch failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not load roadmap state.")

    vote_counts = Counter(r["feature_slug"] for r in (votes.data or []))
    comment_counts = Counter(r["feature_slug"] for r in (comments.data or []))

    return {
        slug: {
            "vote_count": vote_counts.get(slug, 0),
            "comment_count": comment_counts.get(slug, 0),
        }
        for slug in (set(vote_counts) | set(comment_counts))
    }


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
    """Flat comment list for a feature, oldest-first. No threading, no sort."""
    db = get_supabase()
    try:
        rows = (
            db.client.table("roadmap_comments")
            .select("id, author_name, body, created_at")
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
    try:
        ins = db.client.table("roadmap_comments").insert({
            "feature_slug": slug,
            "author_name": author,
            "body": body,
            "email": (str(payload.email).strip().lower() if payload.email else None),
        }).execute()
    except Exception as e:
        logger.error(f"[roadmap] comment insert failed slug={slug}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not post comment. Please try again.")

    row = (ins.data or [{}])[0]
    logger.info(f"[roadmap] comment slug={slug} by={author}")
    return {
        "success": True,
        "comment": {
            "id": row.get("id"),
            "author_name": author,
            "body": body,
            "created_at": row.get("created_at"),
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
