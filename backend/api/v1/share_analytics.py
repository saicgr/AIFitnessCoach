"""Share event analytics endpoint.

POST /api/v1/share-templates/events

Fire-and-forget log of share actions. Returns 202 (accepted) on
success. Client should NOT block the share UX on this response.
"""
from typing import Optional

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class ShareEventBody(BaseModel):
    template_id: str = Field(..., description="e.g. 'anatomy_hero', 'wrapped', 'trading_card'")
    destination: str = Field(..., description="'instagram_stories' | 'system_share' | 'save_only'")
    workout_log_id: Optional[str] = None


@router.post("/share-templates/events")
async def log_share_event(
    body: ShareEventBody,
    current_user: dict = Depends(get_current_user),
) -> JSONResponse:
    user_id = current_user["id"]
    db = get_supabase_db()
    try:
        db.client.table("share_events").insert(
            {
                "user_id": user_id,
                "template_id": body.template_id,
                "destination": body.destination,
                "workout_log_id": body.workout_log_id,
            }
        ).execute()
    except Exception as e:
        logger.warning(f"[share-events] insert failed for {user_id}: {e}")
        # Still 202 — analytics is best-effort
    return JSONResponse(
        status_code=202,
        content={"status": "accepted"},
    )
