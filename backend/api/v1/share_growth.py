"""
Share growth endpoints — Workstream F growth loops (F5, F8, F16).

  F5  GET  /share/referral-link            issue/return the user's referral code + deferred deep link
      POST /share/referral/attribute       two-sided attribution on signup ({referral_code})
      GET  /s/{token}                       public deferred-deep-link resolver (web fallback / app payload)
  F8  GET  /share/workout-link/{workout_id} shareable deep link to a workout
      GET  /share/recipe-link/{recipe_id}   shareable deep link to a recipe/meal
      GET  /share/resolve-workout/{token}   workout scaled to the requesting user's level
  F16 GET  /share/on-this-day               past workouts + meals on this month/day in prior years

Self-hosted deferred deep links (no Branch/OneLink hard dependency; seam left in
referral_service._external_link_provider). The reward path reuses the existing
RevenueCat entitlement flow (services.referral_service.mark_referral_subscribed
is the documented hook for subscriptions/webhooks.py).

`/s/{token}` is intentionally UNAUTHENTICATED (a fresh installer has no token)
and uses a literal-first path that does not collide with the existing /share/*
Imports routes.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Path, Query

from core.auth import get_current_user
from core.logger import get_logger
from services import referral_service, share_data_service

logger = get_logger(__name__)
router = APIRouter()


# --------------------------------------------------------------------------- #
# F5 — referral code + deferred deep link.
# --------------------------------------------------------------------------- #
@router.get("/share/referral-link")
async def referral_link(current_user: dict = Depends(get_current_user)):
    """Return (creating if needed) the user's referral code + a shareable
    deferred-deep-link carrying it. Idempotent."""
    return referral_service.get_referral_link(str(current_user["id"]))


@router.post("/share/referral/attribute")
async def referral_attribute(
    referral_code: str = Body(..., embed=True),
    current_user: dict = Depends(get_current_user),
):
    """Two-sided attribution: the freshly-signed-up user reports the referral
    code they arrived with (resolved from a deferred deep link). Records a
    pending referral_tracking row. Idempotent on (referrer, referred)."""
    new_user_id = str(current_user["id"])
    try:
        return referral_service.record_referral_signup(
            referral_code=referral_code.strip().upper(), new_user_id=new_user_id,
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Unknown referral code")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# --------------------------------------------------------------------------- #
# F8 — do-my-workout / try-this-recipe links.
# --------------------------------------------------------------------------- #
@router.get("/share/workout-link/{workout_id}")
async def workout_link(
    workout_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
):
    """Shareable deep link to one of the user's workouts. Resolving it (by a
    different user) returns the workout scaled to their level."""
    user_id = str(current_user["id"])
    from core.db.facade import get_supabase_db
    db = get_supabase_db()
    owned = (
        db.client.table("workouts").select("id").eq("id", workout_id)
        .eq("user_id", user_id).limit(1).execute()
    )
    if not owned.data:
        raise HTTPException(status_code=404, detail="Workout not found")
    return referral_service.create_workout_link(user_id=user_id, workout_id=workout_id)


@router.get("/share/recipe-link/{recipe_id}")
async def recipe_link(
    recipe_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
):
    """Shareable deep link to a recipe/meal for a non-user to log post-install."""
    return referral_service.create_recipe_link(user_id=str(current_user["id"]), recipe_id=recipe_id)


@router.get("/share/resolve-workout/{token}")
async def resolve_workout(
    token: str = Path(...),
    current_user: dict = Depends(get_current_user),
):
    """Resolve a workout-link token and return the workout scaled to the
    requesting (installed) user's fitness level. Reuses the deterministic
    variant transform — no new generation, no LLM."""
    try:
        return referral_service.resolve_workout_for_user(
            token=token, requesting_user_id=str(current_user["id"]),
        )
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# --------------------------------------------------------------------------- #
# F5 — public deferred-deep-link resolver.
# --------------------------------------------------------------------------- #
@router.get("/s/{token}")
async def resolve_share_token(token: str = Path(...)):
    """Public (unauthenticated) resolver. A fresh installer hits this with no
    auth; we return the deep-link payload + web/store fallback so the app can
    pick it up post-install (deferred deep link). The marketing site's /s/ route
    can call this to 302 to the app or store."""
    try:
        return referral_service.resolve_link(token)
    except KeyError:
        raise HTTPException(status_code=404, detail="Unknown or expired link")


# --------------------------------------------------------------------------- #
# F16 — "A year ago today".
# --------------------------------------------------------------------------- #
@router.get("/share/on-this-day")
async def on_this_day(
    user_id: Optional[str] = Query(None),
    date: Optional[str] = Query(None, description="YYYY-MM-DD (defaults to today UTC)"),
    current_user: dict = Depends(get_current_user),
):
    """Past workouts + meals on this month/day in prior years (deterministic)."""
    uid = str(current_user["id"])
    if user_id and str(user_id) != uid:
        raise HTTPException(status_code=403, detail="Access denied")
    date_iso = date or datetime.now(timezone.utc).date().isoformat()
    try:
        return share_data_service.on_this_day(uid, date_iso)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date (use YYYY-MM-DD)")
