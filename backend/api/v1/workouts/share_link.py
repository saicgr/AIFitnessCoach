"""
Public shareable workout links.

POST /api/v1/workouts/{workout_id}/share-link
    Owner-only. Generates (or returns) the public share token + URL.

GET  /api/v1/workouts/public/{token}
    Anonymous. Reads the security-definer view `public_workouts_v` and
    returns workout data safe to render on zealova.com/w/[token].
"""
import os
import secrets
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, Path

from core import branding
from core.auth import get_current_user, verify_resource_ownership
from core.db import get_supabase_db
from core.logger import get_logger
from pydantic import BaseModel

router = APIRouter()
logger = get_logger(__name__)

PUBLIC_BASE_URL = os.environ.get(
    "PUBLIC_SHARE_BASE_URL", branding.WORKOUT_SHARE_BASE
)
TOKEN_LEN = 8
TOKEN_ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789"  # nanoid-friendly, no 0/O/1/l


class ShareLinkResponse(BaseModel):
    url: str
    token: str
    expires_at: Optional[str] = None


def _make_token() -> str:
    return "".join(secrets.choice(TOKEN_ALPHABET) for _ in range(TOKEN_LEN))


@router.post("/{workout_id}/share-link", response_model=ShareLinkResponse)
async def create_share_link(
    workout_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
) -> ShareLinkResponse:
    """Generate or return a public share token for the user's workout."""
    db = get_supabase_db()
    user_id = current_user["id"]

    row = (
        db.client.table("workouts")
        .select("id,user_id,share_token,is_completed")
        .eq("id", workout_id)
        .maybe_single()
        .execute()
    )
    workout = row.data if row else None
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    verify_resource_ownership(user_id, workout["user_id"], "workout")
    if not workout.get("is_completed"):
        raise HTTPException(
            status_code=400,
            detail="Only completed workouts can be shared",
        )

    token = workout.get("share_token")
    if not token:
        # Retry on the rare collision — 32^8 is ~10^12 so it's vanishingly
        # unlikely but cheap to handle correctly.
        for _ in range(3):
            candidate = _make_token()
            try:
                update = (
                    db.client.table("workouts")
                    .update({"share_token": candidate})
                    .eq("id", workout_id)
                    .execute()
                )
                if update.data:
                    token = candidate
                    break
            except Exception as exc:
                logger.warning("share token collision retry: %s", exc)
        if not token:
            raise HTTPException(
                status_code=500, detail="Could not generate share token"
            )

    return ShareLinkResponse(url=f"{PUBLIC_BASE_URL}/{token}", token=token)


@router.delete("/{workout_id}/share-link")
async def revoke_share_link(
    workout_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """Owner-only revocation — clears the share token, invalidates the URL."""
    db = get_supabase_db()
    user_id = current_user["id"]

    row = (
        db.client.table("workouts")
        .select("user_id,share_token")
        .eq("id", workout_id)
        .maybe_single()
        .execute()
    )
    if not row or not row.data:
        raise HTTPException(status_code=404, detail="Workout not found")
    verify_resource_ownership(user_id, row.data["user_id"], "workout")

    db.client.table("workouts").update({"share_token": None}).eq(
        "id", workout_id
    ).execute()
    return {"revoked": True}


@router.get("/public/{token}")
async def get_public_workout(token: str = Path(..., min_length=4, max_length=32)) -> Dict[str, Any]:
    """Anonymous read — looks up the public view by token."""
    db = get_supabase_db()
    try:
        row = (
            db.client.table("public_workouts_v")
            .select("*")
            .eq("share_token", token)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        logger.warning("public workout lookup failed: %s", exc)
        raise HTTPException(status_code=404, detail="Workout not found")

    data = row.data if row else None
    if not data:
        raise HTTPException(status_code=404, detail="Workout not found")
    return data
