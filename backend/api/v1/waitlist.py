"""Public waitlist endpoint for the marketing site.

Anonymous users POST { email, source, platform_interest } → row in
public.waitlist + transactional confirmation email via Resend.

Rate-limited at the network edge by FastAPI's `slowapi` integration. The
unique-email constraint at the DB layer prevents duplicate inserts; we
treat duplicates as success so the user doesn't feel rejected for a
double-tap.
"""
from __future__ import annotations

import re
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException, Request
from pydantic import BaseModel, EmailStr, Field

from core.logger import get_logger
from core.rate_limiter import limiter
from core.supabase_client import get_supabase
from services.email_waitlist import WaitlistEmailService

logger = get_logger(__name__)
router = APIRouter()

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
ALLOWED_SOURCES = {
    "marketing_landing",
    "waitlist_page",
    "twitter",
    "linkedin",
    "tiktok",
    "instagram",
    "reddit",
    "other",
}
ALLOWED_PLATFORM_INTEREST = {"ios", "android", "both"}


class WaitlistJoinRequest(BaseModel):
    email: EmailStr
    source: str = Field(default="marketing_landing", max_length=64)
    platform_interest: str = Field(default="both", max_length=16)
    first_name: Optional[str] = Field(default=None, max_length=80)
    referrer: Optional[str] = Field(default=None, max_length=500)
    user_agent: Optional[str] = Field(default=None, max_length=500)
    # Honeypot — bots fill every input. Legit submissions leave this blank.
    website: Optional[str] = Field(default=None, max_length=200)


class WaitlistJoinResponse(BaseModel):
    success: bool
    message: str


@router.post("/", response_model=WaitlistJoinResponse)
@limiter.limit("5/minute")
async def join_waitlist(
    request: Request,
    payload: WaitlistJoinRequest,
    background_tasks: BackgroundTasks,
):
    """Anonymous waitlist signup.

    - Validates email shape (Pydantic EmailStr + regex belt-and-braces).
    - Honeypot check — bots filling the hidden `website` field get a fake
      success and are silently dropped.
    - Inserts via service-role Supabase client (bypasses anon RLS gate so
      we can also rate-limit + dedupe in this endpoint).
    - Sends Resend confirmation email in a background task so the response
      stays fast even when Resend is slow.
    """
    if payload.website:
        # Honeypot tripped — bot. Pretend it worked, log, drop.
        logger.info(f"[waitlist] honeypot triggered, ip={request.client.host if request.client else 'unknown'}")
        return WaitlistJoinResponse(
            success=True,
            message="You're on the list.",
        )

    email_lower = str(payload.email).strip().lower()
    if not EMAIL_RE.match(email_lower):
        raise HTTPException(status_code=400, detail="Invalid email format")

    source = payload.source if payload.source in ALLOWED_SOURCES else "other"
    platform_interest = (
        payload.platform_interest
        if payload.platform_interest in ALLOWED_PLATFORM_INTEREST
        else "both"
    )

    db = get_supabase()
    try:
        db.client.table("waitlist").insert({
            "email": email_lower,
            "source": source,
            "platform_interest": platform_interest,
            "referrer": payload.referrer,
            "user_agent": payload.user_agent or request.headers.get("user-agent"),
        }).execute()
        logger.info(f"[waitlist] joined: {email_lower} via {source}")
    except Exception as e:
        # Treat unique-violation as success — duplicate signup shouldn't feel
        # like an error to the user. PostgREST returns 23505 in `code` for
        # unique violations and the supabase client surfaces it via the
        # exception's args / repr.
        msg = str(e).lower()
        if "duplicate" in msg or "23505" in msg or "unique constraint" in msg:
            logger.info(f"[waitlist] duplicate (already on list): {email_lower}")
            return WaitlistJoinResponse(
                success=True,
                message="You're already on the list. We've got you.",
            )
        logger.error(f"[waitlist] insert failed for {email_lower}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not join waitlist. Please try again.")

    # Fire-and-forget confirmation email. Failures here don't block signup.
    email_service = WaitlistEmailService()
    if email_service.is_configured():
        background_tasks.add_task(
            _send_confirmation_safely,
            email_service,
            email_lower,
            payload.first_name,
        )

    return WaitlistJoinResponse(
        success=True,
        message="You're in. Check your inbox for what's next.",
    )


async def _send_confirmation_safely(
    service: WaitlistEmailService,
    email: str,
    first_name: Optional[str],
):
    """Background-task wrapper that swallows Resend failures so they don't
    crash the worker. The endpoint already returned 200 — the user has no
    way to retry from the UI even if the email failed."""
    try:
        await service.send_waitlist_confirmation(email, first_name=first_name)
    except Exception as e:
        logger.error(f"[waitlist] confirmation email failed for {email}: {e}", exc_info=True)
