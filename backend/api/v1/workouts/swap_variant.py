"""
Workout variant swap API — chat / card surface for swapping an existing
workout to a lighter (`deload`), moderate (`moderate`), or fully
bodyweight (`bodyweight`) variant.

Endpoint:
  POST /api/v1/workouts/{workout_id}/swap-variant
  Body: { "target_intensity": "deload" | "moderate" | "bodyweight" }

Behaviour:
1. Verify the source workout exists AND belongs to the caller.
2. Try `get_cached_variant()` — if a variant already lives in the
   `workout_variants` cache, return its workout row immediately.
3. On cache miss: `generate_variant()` (pure transform + best-effort
   RAG swaps) → `persist_variant_cache_row()` synchronously so the
   client can navigate to the new workout row by id on this same
   response.
4. Re-fetch the persisted variant row to return canonical fields
   (id, name, duration_minutes, exercise_count).

Errors:
  404 — workout_id not found
  403 — caller does not own the workout
  500 — generator/persistence failure (safe_internal_error)

NO silent fallbacks per project guidelines: if the generator or
persistence layer fails we surface a 500 with a real backend log line so
the chat surface can render an error instead of a silently broken
"variant generated" state.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, Path
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from services.workout.variant_generator import (
    VALID_INTENSITIES,
    generate_variant,
    get_cached_variant,
    persist_variant_cache_row,
)

logger = logging.getLogger("workout_swap_variant")
router = APIRouter()


# ---------------------------------------------------------------------------
# Request / response models
# ---------------------------------------------------------------------------
class SwapVariantRequest(BaseModel):
    target_intensity: str = Field(
        ...,
        description="One of: deload | moderate | bodyweight",
    )


class SwapVariantResponse(BaseModel):
    workout_id: str
    source_workout_id: str
    target_intensity: str
    name: Optional[str] = None
    duration_minutes: Optional[int] = None
    exercise_count: int = 0
    cached: bool = False


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
_SOURCE_SELECT = (
    "id, user_id, name, type, difficulty, scheduled_date, exercises_json, "
    "duration_minutes, intensity_mode, equipment, status"
)


def _fetch_source_workout(sb, workout_id: str) -> Optional[Dict[str, Any]]:
    """Return the source workout row, or None if it doesn't exist."""
    try:
        wr = sb.client.table("workouts").select(_SOURCE_SELECT).eq(
            "id", workout_id
        ).maybe_single().execute()
        if wr and wr.data:
            return wr.data
    except Exception as e:
        logger.warning(f"[swap_variant] source fetch failed for {workout_id}: {e}")
    return None


def _fetch_variant_row(sb, variant_id: str) -> Optional[Dict[str, Any]]:
    """Re-fetch the persisted variant row for canonical response fields."""
    try:
        vr = sb.client.table("workouts").select(
            "id, name, duration_minutes, exercises_json"
        ).eq("id", variant_id).maybe_single().execute()
        if vr and vr.data:
            return vr.data
    except Exception as e:
        logger.warning(f"[swap_variant] variant fetch failed for {variant_id}: {e}")
    return None


def _summarise(variant_id: str, source_id: str, target_intensity: str,
               name: Optional[str], duration_minutes: Optional[int],
               exercises: Any, cached: bool) -> SwapVariantResponse:
    count = len(exercises) if isinstance(exercises, list) else 0
    return SwapVariantResponse(
        workout_id=variant_id,
        source_workout_id=source_id,
        target_intensity=target_intensity,
        name=name,
        duration_minutes=duration_minutes,
        exercise_count=count,
        cached=cached,
    )


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------
@router.post("/{workout_id}/swap-variant", response_model=SwapVariantResponse)
async def swap_workout_variant(
    body: SwapVariantRequest,
    workout_id: str = Path(..., description="Source workout id"),
    current_user: dict = Depends(get_current_user),
):
    target_intensity = (body.target_intensity or "").strip().lower()
    if target_intensity not in VALID_INTENSITIES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid target_intensity={body.target_intensity!r}; "
                f"expected one of {list(VALID_INTENSITIES)}."
            ),
        )

    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        # ---- Ownership / existence check -------------------------------
        source = _fetch_source_workout(sb, workout_id)
        if not source:
            raise HTTPException(status_code=404, detail="Workout not found.")
        if source.get("user_id") != user_id:
            # 403 — never reveal whether the row exists for another user.
            raise HTTPException(
                status_code=403,
                detail="You don't have access to that workout.",
            )

        # ---- Cache lookup ----------------------------------------------
        cached = get_cached_variant(sb, workout_id, target_intensity)
        if cached and cached.get("id"):
            return _summarise(
                variant_id=cached["id"],
                source_id=workout_id,
                target_intensity=target_intensity,
                name=None,  # cached payload omits name; re-fetch for it
                duration_minutes=cached.get("duration_minutes"),
                exercises=cached.get("exercises") or [],
                cached=True,
            ).copy(update=_optional_name(sb, cached["id"]))

        # ---- Generate + persist ----------------------------------------
        try:
            variant = generate_variant(source, target_intensity)
        except ValueError as ve:
            # Bad input — re-raise as 400 with the generator's message.
            raise HTTPException(status_code=400, detail=str(ve))
        except Exception as ge:
            # NO silent fallback — surface the real failure so the chat
            # can render an error instead of pretending success.
            logger.error(
                f"[swap_variant] generate_variant failed for "
                f"workout={workout_id} intensity={target_intensity}: {ge}",
                exc_info=True,
            )
            raise HTTPException(
                status_code=500,
                detail="Couldn't build a variant of this workout. Please try again.",
            )

        persisted = persist_variant_cache_row(sb, source, variant)
        if not persisted:
            logger.error(
                f"[swap_variant] persist_variant_cache_row returned False for "
                f"workout={workout_id} intensity={target_intensity}"
            )
            raise HTTPException(
                status_code=500,
                detail="Couldn't save the variant. Please try again.",
            )

        # Re-look up the cached row to get the canonical variant id + name
        # (the deterministic uuid5 in `variant` matches the cache row, but
        # for safety we go through the cache lookup so future schema
        # changes that remap ids stay correct).
        post_cache = get_cached_variant(sb, workout_id, target_intensity)
        variant_id = (post_cache or {}).get("id") or variant.get("id")
        if not variant_id:
            raise HTTPException(
                status_code=500,
                detail="Variant saved but not retrievable. Please try again.",
            )

        row = _fetch_variant_row(sb, variant_id)
        return _summarise(
            variant_id=variant_id,
            source_id=workout_id,
            target_intensity=target_intensity,
            name=(row or {}).get("name"),
            duration_minutes=(row or {}).get("duration_minutes")
                or variant.get("duration_minutes"),
            exercises=(row or {}).get("exercises_json")
                or variant.get("exercises")
                or [],
            cached=False,
        )
    except HTTPException:
        # Re-raise cleanly so FastAPI returns the intended status.
        raise
    except Exception as e:
        raise safe_internal_error(
            e, "swap_workout_variant",
            workout_id=workout_id,
            target_intensity=target_intensity,
        )


def _optional_name(sb, variant_id: str) -> Dict[str, Any]:
    """Return a dict with `name` for the cached-hit response. Best-effort —
    on failure we just omit the field (response model allows None)."""
    row = _fetch_variant_row(sb, variant_id)
    if not row:
        return {}
    out: Dict[str, Any] = {}
    if row.get("name") is not None:
        out["name"] = row.get("name")
    if row.get("duration_minutes") is not None:
        out["duration_minutes"] = row.get("duration_minutes")
    return out
