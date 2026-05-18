"""Public page-comments API for the marketing site.

Powers the comment section on zealova.com long-form pages — the /vs/*
comparison pages and the /best-*-2026 roundup pages.

Email-keyed, frictionless, publishes immediately — the same model as the
public /roadmap board (api/v1/public_roadmap.py). The marketing site has no
logged-in users, so a plain required email is the identity key.

Comments are FLAT (no threading) — marketing-page comments are not a forum.

Page CONTENT is prerendered static; these endpoints only serve the dynamic
comments, keyed by the stable `page_slug` string (e.g. 'vs/bevel').

Tables: migration 2082 (page_comments).
All writes use the service-role Supabase client and are rate-limited per IP.

ENDPOINTS (mounted at /api/v1/page-comments):
- GET  /comments/{page_slug} - flat comment list, oldest-first
- POST /comment              - add a comment (email REQUIRED)

RATE LIMIT: /comment 10/hour per IP.
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, EmailStr, Field

from core.logger import get_logger
from core.rate_limiter import limiter
from core.supabase_client import get_supabase

logger = get_logger(__name__)
router = APIRouter()


class PageCommentRequest(BaseModel):
    page_slug: str = Field(min_length=1, max_length=160)
    author_name: str = Field(min_length=1, max_length=80)
    body: str = Field(min_length=1, max_length=1000)
    email: EmailStr  # REQUIRED — visitors must supply an email to comment
    # Honeypot — bots fill every field. Legit submissions leave this blank.
    website: Optional[str] = Field(default=None, max_length=200)


@router.get("/comments/{page_slug:path}")
async def list_comments(page_slug: str):
    """All visible comments for a page, oldest-first.

    `:path` converter so slugs containing a slash (e.g. 'vs/bevel') work.
    """
    db = get_supabase()
    try:
        rows = (
            db.client.table("page_comments")
            .select("id, author_name, body, created_at")
            .eq("page_slug", page_slug.strip())
            .eq("is_hidden", False)
            .order("created_at", desc=False)
            .execute()
        )
    except Exception as e:
        logger.error(f"[page-comments] fetch failed slug={page_slug}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not load comments.")
    return {"comments": rows.data or []}


@router.post("/comment")
@limiter.limit("10/hour")
async def add_comment(request: Request, payload: PageCommentRequest):
    """Post a flat comment on a marketing page. Publishes immediately."""
    if payload.website:  # honeypot tripped — bot. Fake success, drop.
        logger.info("[page-comments] honeypot triggered")
        return {"success": True, "comment": None}

    slug = payload.page_slug.strip()
    author = payload.author_name.strip()
    body = payload.body.strip()
    db = get_supabase()

    try:
        ins = db.client.table("page_comments").insert({
            "page_slug": slug,
            "author_name": author,
            "body": body,
            "email": str(payload.email).strip().lower(),
        }).execute()
    except Exception as e:
        logger.error(f"[page-comments] insert failed slug={slug}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not post comment. Please try again.")

    row = (ins.data or [{}])[0]
    logger.info(f"[page-comments] comment slug={slug} by={author}")
    return {
        "success": True,
        "comment": {
            "id": row.get("id"),
            "author_name": author,
            "body": body,
            "created_at": row.get("created_at"),
        },
    }
