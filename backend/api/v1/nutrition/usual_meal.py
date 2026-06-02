"""Proactive "your usual?" meal endpoint (Gap 16).

Surfaces the user's most-frequently-logged meal for a given slot so the home
contextual-nudge can proactively offer a one-tap re-log ("Log your usual
oatmeal?"). Reuses the existing `_resolve_usual` resolver — pull-only until now.
"""
import asyncio
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class UsualMealResponse(BaseModel):
    found: bool
    meal_type: Optional[str] = None
    label: Optional[str] = Field(default=None, description="e.g. 'Your usual (5x in last 30 days)'")
    summary: Optional[str] = Field(default=None, description="Comma-joined item names")
    total_calories: int = 0
    protein_g: float = 0.0
    item_names: List[str] = Field(default_factory=list)


@router.get("/usual-meal", response_model=UsualMealResponse)
async def get_usual_meal(
    request: Request,
    meal_type: str = Query(..., max_length=20, description="breakfast|lunch|dinner|snack"),
    tz: str = Query(default="UTC", max_length=64),
    current_user: dict = Depends(get_current_user),
):
    """Return the user's habitual meal for `meal_type`, if one exists."""
    user_id = str(current_user["id"])
    try:
        from services.contextual_meal_service import (
            ContextualRef,
            ReferenceType,
            _resolve_usual,
        )

        ref = ContextualRef()
        ref.ref_type = ReferenceType.USUAL
        ref.meal_type = (meal_type or "").lower().strip() or None

        db = get_supabase_db()
        loop = asyncio.get_event_loop()
        resolved = await _resolve_usual(ref, user_id, db, loop, tz)

        if not resolved.found:
            return UsualMealResponse(found=False, meal_type=ref.meal_type)

        names = [str(i.get("name")) for i in (resolved.items or []) if i.get("name")]
        return UsualMealResponse(
            found=True,
            meal_type=ref.meal_type,
            label=resolved.source_label,
            summary=", ".join(names) if names else None,
            total_calories=int(resolved.total_calories or 0),
            protein_g=round(float(resolved.protein_g or 0), 1),
            item_names=names,
        )
    except Exception as e:
        logger.error(f"[usual_meal] failed for {user_id[:8]}: {e}", exc_info=True)
        raise safe_internal_error(e, "usual_meal")
