"""Share template preferences endpoints.

GET  /api/v1/share-templates/preferences
PUT  /api/v1/share-templates/preferences

Stores per-user favorite templates and custom ordering. The client
keeps a SharedPreferences copy for instant UI; the backend exists for
cross-device sync.
"""
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class SharePreferencesBody(BaseModel):
    favorites: List[str] = Field(default_factory=list)
    template_order: List[str] = Field(default_factory=list)


@router.get("/share-templates/preferences")
async def get_preferences(current_user: dict = Depends(get_current_user)) -> dict:
    user_id = current_user["id"]
    db = get_supabase_db()
    try:
        resp = (
            db.client.table("users")
            .select("share_favorite_templates, share_template_order")
            .eq("id", user_id)
            .single()
            .execute()
        )
        row = resp.data or {}
        return {
            "favorites": row.get("share_favorite_templates") or [],
            "template_order": row.get("share_template_order") or [],
        }
    except Exception as e:
        logger.warning(f"[share-templates] get failed for {user_id}: {e}")
        # Degrade gracefully — client has local copy
        return {"favorites": [], "template_order": []}


@router.put("/share-templates/preferences")
async def put_preferences(
    body: SharePreferencesBody,
    current_user: dict = Depends(get_current_user),
) -> dict:
    user_id = current_user["id"]
    db = get_supabase_db()
    # Normalize — dedupe + drop empties
    favorites = [t for t in dict.fromkeys(body.favorites) if t]
    order = [t for t in dict.fromkeys(body.template_order) if t]
    try:
        db.client.table("users").update(
            {
                "share_favorite_templates": favorites,
                "share_template_order": order,
            }
        ).eq("id", user_id).execute()
    except Exception as e:
        logger.warning(f"[share-templates] put failed for {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to save preferences")
    return {"favorites": favorites, "template_order": order}
