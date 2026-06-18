"""
Friend Streak endpoints — Workstream F14.

1:1 shared streak (workout | food). No public feed. Invite via deep-link code;
streak increments once per shared local day when BOTH members logged.

  POST /friend-streak/invite              create an invite ({kind}) + deep link
  POST /friend-streak/accept              accept an invite ({invite_code})
  GET  /friend-streak/list                my active streaks
  POST /friend-streak/{id}/evaluate       re-evaluate one of my streaks now (idempotent)
  POST /friend-streak/cron/daily          cron-protected daily evaluator (X-Cron-Secret)

Logic lives in services.friend_streak_service (deterministic; no LLM).
"""
from __future__ import annotations

import hmac
from typing import Optional

from fastapi import APIRouter, Body, Depends, Header, HTTPException, Path, Request

from core.auth import get_current_user
from core.config import get_settings
from core.logger import get_logger
from services import friend_streak_service

logger = get_logger(__name__)
router = APIRouter()


@router.post("/friend-streak/invite")
async def create_invite(
    kind: str = Body("workout", embed=True),
    current_user: dict = Depends(get_current_user),
):
    """Create a pending friend-streak invite + a shareable deep link."""
    try:
        return friend_streak_service.create_invite(str(current_user["id"]), kind)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/friend-streak/accept")
async def accept_invite(
    invite_code: str = Body(..., embed=True),
    current_user: dict = Depends(get_current_user),
):
    try:
        return friend_streak_service.accept_invite(invite_code.strip(), str(current_user["id"]))
    except KeyError:
        raise HTTPException(status_code=404, detail="Unknown invite code")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/friend-streak/list")
async def list_streaks(current_user: dict = Depends(get_current_user)):
    return {"streaks": friend_streak_service.list_streaks(str(current_user["id"]))}


@router.post("/friend-streak/{streak_id}/evaluate")
async def evaluate_one(
    streak_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
):
    """Re-evaluate one of the caller's streaks now (e.g. just after logging).
    Idempotent — only increments once per shared day."""
    user_id = str(current_user["id"])
    from core.db.facade import get_supabase_db
    db = get_supabase_db()
    row = (
        db.client.table("friend_streaks").select("*").eq("id", streak_id).limit(1).execute()
    )
    if not row.data:
        raise HTTPException(status_code=404, detail="Streak not found")
    s = row.data[0]
    if user_id not in (s.get("user_a"), s.get("user_b")):
        raise HTTPException(status_code=403, detail="Access denied")
    return friend_streak_service.evaluate_streak(s)


@router.post("/friend-streak/cron/daily")
async def cron_daily(
    request: Request,
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """Daily evaluator (cron-protected): evaluate every active streak, increment
    where both logged, reset gaps."""
    settings = get_settings()
    secret = settings.cron_secret
    if not secret:
        raise HTTPException(status_code=503, detail="Cron not configured — set CRON_SECRET env var")
    if not x_cron_secret or not hmac.compare_digest(x_cron_secret, secret):
        raise HTTPException(status_code=401, detail="Invalid cron secret")
    return friend_streak_service.run_daily_evaluator()
