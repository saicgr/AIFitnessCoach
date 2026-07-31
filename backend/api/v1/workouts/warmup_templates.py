"""
Saved warm-up templates — the "carries forward" half of E2E register #125.

Adding/swapping/removing a move on `warmups` (see `warmup_stretch.py` /
`exercises.py`) only ever mutates the CURRENT workout's row. Every new
workout re-generates a fresh AI warm-up from scratch, throwing the user's
customization away the moment they start their next session. This module
adds ONE saved warm-up per user, optionally scoped to a `workout_type`
(migration 2401_user_warmup_templates.sql), plus the endpoint that seeds a
brand-new workout's `warmups` row from it before generation would otherwise
run.

Routes:
- GET  /workouts/warmup-template?workout_type=...   read the saved template
- PUT  /workouts/warmup-template                     upsert the saved template
- POST /workouts/{workout_id}/warmup/apply-template  seed this workout's
                                                      `warmups` row from it

Client: `mobile/flutter/lib/data/repositories/workout_repository_exercises.dart`
(`fetchWarmupTemplate` / `saveWarmupTemplate` / `applyWarmupTemplate`), called
from `_resolveWarmupPhase` / `_finishWarmupPhase` in
`mobile/flutter/lib/screens/workout/easy/easy_active_workout_state.dart` and
mirrored in the legacy `warmup_phase_screen.dart` path.
"""
import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from starlette.requests import Request

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.rate_limiter import limiter

logger = get_logger(__name__)

# No prefix — routes are registered before crud_router (see __init__.py) so
# the static `/warmup-template` path isn't swallowed by crud's dynamic
# `/{workout_id}` route.
router = APIRouter(tags=["workouts"])


class WarmupTemplateExercise(BaseModel):
    """One saved warm-up move. Mirrors the shape written into
    `warmups.exercises_json` by `add_exercise_to_workout`'s warmup branch
    (workout_operations.py) — same keys, so a template can be written
    straight into a workout's `warmups` row without translation."""
    name: str = Field(..., max_length=200)
    exercise_id: Optional[str] = Field(default=None, max_length=100)
    duration_seconds: Optional[float] = Field(default=None, ge=0, le=600)
    rest_seconds: Optional[float] = Field(default=None, ge=0, le=300)
    equipment: Optional[str] = Field(default=None, max_length=100)
    muscle_group: Optional[str] = Field(default=None, max_length=100)
    is_timed: Optional[bool] = Field(default=True)
    # Extra passthrough fields present on some warm-up items (cardio machine
    # presets). Kept optional so a template round-trips whatever the client
    # sent without the schema silently dropping fields it doesn't know about.
    speed_mph: Optional[float] = None
    incline_percent: Optional[float] = None
    rpm: Optional[float] = None
    resistance_level: Optional[float] = None
    stroke_rate_spm: Optional[float] = None


class SaveWarmupTemplateRequest(BaseModel):
    workout_type: Optional[str] = Field(
        default=None, max_length=50,
        description="Null saves the user's one generic/default template.",
    )
    exercises: List[WarmupTemplateExercise] = Field(..., min_length=0, max_length=20)


def _lookup_template(db, user_id: str, workout_type: Optional[str]) -> Optional[dict]:
    """Type-specific row first, falling back to the generic (workout_type IS
    NULL) row. Returns None on a genuine miss — never a fabricated default."""
    if workout_type:
        res = (
            db.client.table("user_warmup_templates")
            .select("*")
            .eq("user_id", user_id)
            .eq("workout_type", workout_type)
            .maybe_single()
            .execute()
        )
        # maybe_single() returns None (not a response with data=None) on 0
        # rows — guard the response object itself, not just `.data`.
        if res and res.data:
            return res.data

    res = (
        db.client.table("user_warmup_templates")
        .select("*")
        .eq("user_id", user_id)
        .is_("workout_type", "null")
        .maybe_single()
        .execute()
    )
    if res and res.data:
        return res.data
    return None


@router.get("/warmup-template")
@limiter.limit("30/minute")
async def get_warmup_template(
    request: Request,
    workout_type: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """Read the caller's saved warm-up template. 404 when none is saved yet
    (type-specific AND generic both missing) — the client falls back to
    normal generation, never a hardcoded default."""
    try:
        db = get_supabase_db()
        user_id = str(current_user["id"])
        row = _lookup_template(db, user_id, workout_type)
        if not row:
            raise HTTPException(status_code=404, detail="No saved warm-up template")
        return {
            "workout_type": row.get("workout_type"),
            "exercises": row.get("exercises_json") or [],
            "updated_at": row.get("updated_at"),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to read warm-up template: {e}", exc_info=True)
        raise safe_internal_error(e, "warmup_templates")


@router.put("/warmup-template")
@limiter.limit("20/minute")
async def save_warmup_template(
    request: Request,
    payload: SaveWarmupTemplateRequest,
    current_user: dict = Depends(get_current_user),
):
    """Upsert the caller's saved warm-up (type-specific when `workout_type`
    is set, otherwise the one generic/default template). An empty
    `exercises` list is valid — it records "I want no warm-up here"."""
    try:
        db = get_supabase_db()
        user_id = str(current_user["id"])
        workout_type = payload.workout_type
        exercises = [ex.model_dump(exclude_none=True) for ex in payload.exercises]

        query = (
            db.client.table("user_warmup_templates")
            .select("id")
            .eq("user_id", user_id)
        )
        query = (
            query.eq("workout_type", workout_type)
            if workout_type
            else query.is_("workout_type", "null")
        )
        existing = query.maybe_single().execute()

        now = datetime.now().isoformat()
        if existing and existing.data:
            db.client.table("user_warmup_templates").update({
                "exercises_json": exercises,
                "updated_at": now,
            }).eq("id", existing.data["id"]).execute()
            logger.info(
                f"Updated warm-up template user={user_id} type={workout_type} "
                f"count={len(exercises)}"
            )
        else:
            db.client.table("user_warmup_templates").insert({
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "workout_type": workout_type,
                "exercises_json": exercises,
                "created_at": now,
                "updated_at": now,
            }).execute()
            logger.info(
                f"Created warm-up template user={user_id} type={workout_type} "
                f"count={len(exercises)}"
            )

        return {
            "success": True,
            "workout_type": workout_type,
            "exercises_count": len(exercises),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save warm-up template: {e}", exc_info=True)
        raise safe_internal_error(e, "warmup_templates")


@router.post("/{workout_id}/warmup/apply-template")
@limiter.limit("20/minute")
async def apply_warmup_template(
    request: Request,
    workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Seed this (freshly-started) workout's `warmups` row from the user's
    saved template, so a customization made on a PAST workout carries
    forward instead of every workout re-generating from scratch. 404 when
    the user has no saved template — the client falls back to
    `fetchWarmupAndStretches`/generation exactly as it did before this
    endpoint existed."""
    try:
        db = get_supabase_db()
        user_id = str(current_user["id"])

        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")
        if str(workout.get("user_id")) != user_id:
            raise HTTPException(status_code=403, detail="Not your workout")

        template = _lookup_template(db, user_id, workout.get("type"))
        if not template:
            raise HTTPException(status_code=404, detail="No saved warm-up template")

        exercises = template.get("exercises_json") or []
        now = datetime.now().isoformat()

        # Supersede any existing `is_current` row for this workout (SCD2,
        # same pattern as `warmup_stretch_service_helpers.py`) instead of
        # leaving two is_current=True rows, which would make every reader
        # that does `ORDER BY valid_from DESC LIMIT 1` the only safe one.
        current_result = (
            db.client.table("warmups")
            .select("id, version_number")
            .eq("workout_id", workout_id)
            .eq("is_current", True)
            .execute()
        )
        next_version = 1
        new_id = str(uuid.uuid4())
        if current_result.data:
            current_row = current_result.data[0]
            next_version = (current_row.get("version_number") or 1) + 1
            db.client.table("warmups").update({
                "is_current": False,
                "valid_to": now,
                "superseded_by": new_id,
                "updated_at": now,
            }).eq("id", current_row["id"]).execute()

        db.client.table("warmups").insert({
            "id": new_id,
            "workout_id": workout_id,
            "exercises_json": exercises,
            "duration_minutes": 5,
            "is_current": True,
            "version_number": next_version,
            "valid_from": now,
            "created_at": now,
            "updated_at": now,
        }).execute()

        logger.info(
            f"Applied saved warm-up template to workout={workout_id} "
            f"user={user_id} count={len(exercises)}"
        )
        return {"success": True, "exercises": exercises, "exercises_count": len(exercises)}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to apply warm-up template: {e}", exc_info=True)
        raise safe_internal_error(e, "warmup_templates")
