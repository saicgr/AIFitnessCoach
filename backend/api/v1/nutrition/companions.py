"""Companion suggestions endpoint — feeds the CompanionPickerSheet.

POST /api/v1/nutrition/companions
    Returns the ranked list of typical add-on foods (sides, condiments,
    beverages) for a given primary food, merging the user's own co-occurrence
    history with a cached Gemini-sourced "typically paired with" list.

POST /api/v1/nutrition/companions/reject
    Records a user-taught negative (`primary_name` + `companion_name`) so we
    suppress that pair on subsequent /companions calls. Idempotent upsert.

See services/companion_resolver.py for the merge / cache logic and
migrations/1919_food_companion_cache.sql for the two persistence tables.
"""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field, validator

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.rate_limiter import limiter
from services.companion_resolver import (
    record_rejected_pair,
    resolve_companions,
)

router = APIRouter()
logger = get_logger(__name__)


# ─── Request / response models ─────────────────────────────────────────────


class CompanionsRequest(BaseModel):
    user_id: str = Field(..., description="UUID of the requesting user.")
    primary_food_name: str = Field(..., max_length=120)
    meal_type: str = Field(..., description="breakfast | lunch | dinner | snack")
    locale: Optional[str] = Field(
        "en",
        max_length=12,
        description="IETF language tag (e.g. 'en', 'en-IN'). Drives Gemini's choice of culturally-correct side names.",
    )

    @validator("meal_type")
    def _check_meal_type(cls, v: str) -> str:
        allowed = {"breakfast", "lunch", "dinner", "snack"}
        if v not in allowed:
            raise ValueError(f"meal_type must be one of {sorted(allowed)}")
        return v


class CompanionSuggestionOut(BaseModel):
    name: str
    source: str = Field(..., description="'history' | 'global'")
    confidence: float
    est_calories: int
    est_protein_g: float
    est_carbs_g: float
    est_fat_g: float
    typical_portion_g: float
    cuisine_tag: str
    why: str


class CompanionsResponse(BaseModel):
    suggestions: List[CompanionSuggestionOut] = Field(default_factory=list)


class RejectCompanionRequest(BaseModel):
    user_id: str
    primary_food_name: str = Field(..., max_length=120)
    companion_name: str = Field(..., max_length=120)


# ─── Endpoints ─────────────────────────────────────────────────────────────


@router.post("/companions", response_model=CompanionsResponse)
@limiter.limit("30/minute")
async def get_companions(
    body: CompanionsRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Ranked companion suggestions for a primary food — history + cached global.

    The frontend uses this when the user taps a single-item food in Recent
    ("add sides?" flow) or when the user opts into "Suggest more sides"
    while already looking at a historic group. An empty `suggestions` list
    is a perfectly valid response — it tells the client to log the primary
    silently without showing a sheet.
    """
    if str(current_user.get("id")) != str(body.user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    try:
        db = get_supabase_db()
        suggestions = await resolve_companions(
            db=db,
            user_id=body.user_id,
            primary_name=body.primary_food_name,
            meal_type=body.meal_type,
            locale=body.locale or "en",
        )
        out = [CompanionSuggestionOut(**s.to_dict()) for s in suggestions]
        logger.info(
            f"[Companions] user={body.user_id} primary={body.primary_food_name!r} "
            f"meal={body.meal_type} → {len(out)} suggestion(s)"
        )
        return CompanionsResponse(suggestions=out)

    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(f"[Companions] resolver failed: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/companions/reject", status_code=204)
@limiter.limit("60/minute")
async def reject_companion(
    body: RejectCompanionRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Teach the resolver to stop suggesting a specific pair for this user.

    Idempotent — the upsert just no-ops if the row already exists.
    """
    if str(current_user.get("id")) != str(body.user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    record_rejected_pair(
        db,
        user_id=body.user_id,
        primary_name=body.primary_food_name,
        companion_name=body.companion_name,
    )
