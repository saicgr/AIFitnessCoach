"""Workout Customization Studio + adaptation endpoints.

All routes wrap the shared `services.workout_builder` engine (instant RAG +
deterministic rules, no LLM). Registered BEFORE crud_router so the dynamic
`/{workout_id}` CRUD handlers don't shadow these sub-paths.

- POST /customize            live preview (no DB row) or persist a new workout
- POST /{workout_id}/adapt   fork (default) or in-place rebuild from params/free-text
- POST /{workout_id}/shuffle re-roll the same params, excluding current exercises
- POST /{workout_id}/feedback thumbs up/down (soft signal; upsert/toggle)
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from core.auth import get_current_user, verify_resource_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

from models.workout_studio import (
    WorkoutBuildParams,
    BuiltWorkout,
    CustomizeRequest,
    AdaptRequest,
    WorkoutThumbsRequest,
)
from services.workout_builder import (
    build_adapted_workout,
    parse_constraints_text,
    persist_built_workout,
)

router = APIRouter()
logger = get_logger(__name__)


def _built_from_prebuilt(prebuilt: BuiltWorkout) -> BuiltWorkout:
    """Use the client's previewed workout verbatim (WYSIWYG)."""
    return prebuilt


@router.post("/customize", response_model=BuiltWorkout)
async def customize_workout(
    request: CustomizeRequest,
    current_user: dict = Depends(get_current_user),
):
    """Build a workout from studio params.

    persist=False -> in-memory preview (no `workouts` row); fired on every
    slider change. persist=True -> create a real workout and return its id;
    if `prebuilt` is supplied we persist it verbatim (what you previewed is
    what you save), otherwise we build fresh.
    """
    try:
        db = get_supabase_db()
        user = db.get_user(current_user["id"]) or {"id": current_user["id"]}

        if request.prebuilt is not None:
            built = request.prebuilt
        else:
            built = await build_adapted_workout(request.params, user)

        if request.name:
            built.name = request.name

        if request.persist:
            wid = persist_built_workout(
                db, current_user["id"], built, request.params,
                generation_source="studio",
            )
            built.workout_id = wid
        return built
    except Exception as e:
        logger.error(f"[studio] customize failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_studio")


@router.post("/{workout_id}/adapt", response_model=BuiltWorkout)
async def adapt_workout(
    workout_id: str,
    request: AdaptRequest,
    current_user: dict = Depends(get_current_user),
):
    """Adapt an existing workout.

    Base params come from the workout's stored studio params (if any), then
    free-text constraints are merged deterministically. replace_in_place
    mutates the source (detail-screen Adjust, client keeps an undo snapshot)
    BUT never on a completed workout — a completed/logged workout always forks
    so history is preserved. Chat adaptation forks by default (keeps original).
    """
    try:
        db = get_supabase_db()
        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")
        verify_resource_ownership(current_user, existing, "Workout")
        user = db.get_user(current_user["id"]) or {"id": current_user["id"]}

        # base params: stored studio params -> request params -> defaults
        meta = existing.get("generation_metadata") or {}
        if isinstance(meta, dict) and meta.get("studio_params"):
            base = WorkoutBuildParams(**meta["studio_params"])
        else:
            base = request.params or WorkoutBuildParams()
        if request.params:
            base = request.params
        if request.constraints_text:
            base = parse_constraints_text(request.constraints_text, base)

        if request.prebuilt is not None:
            built = request.prebuilt
        else:
            built = await build_adapted_workout(base, user)

        # Never mutate a completed/logged workout in place.
        is_completed = bool(existing.get("is_completed"))
        do_in_place = request.replace_in_place and not is_completed
        target_id = workout_id if do_in_place else None
        wid = persist_built_workout(
            db, current_user["id"], built, base,
            existing_workout_id=target_id,
            generation_source="chat" if not do_in_place else "studio",
        )
        built.workout_id = wid
        return built
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[studio] adapt failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_studio")


@router.post("/{workout_id}/shuffle", response_model=BuiltWorkout)
async def shuffle_workout(
    workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Re-roll the same workout with the same params, excluding the current
    exercises so the user gets fresh variety. Replaces in place."""
    try:
        db = get_supabase_db()
        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")
        verify_resource_ownership(current_user, existing, "Workout")
        user = db.get_user(current_user["id"]) or {"id": current_user["id"]}

        meta = existing.get("generation_metadata") or {}
        params = (WorkoutBuildParams(**meta["studio_params"])
                  if isinstance(meta, dict) and meta.get("studio_params")
                  else WorkoutBuildParams())
        current = existing.get("exercises_json") or existing.get("exercises") or []
        params.exclude_current = [e.get("name", "") for e in current if e.get("name")]

        built = await build_adapted_workout(params, user)
        is_completed = bool(existing.get("is_completed"))
        wid = persist_built_workout(
            db, current_user["id"], built, params,
            existing_workout_id=(workout_id if not is_completed else None),
            generation_source="studio",
        )
        built.workout_id = wid
        return built
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[studio] shuffle failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_studio")


@router.post("/{workout_id}/feedback")
async def workout_thumbs(
    workout_id: str,
    request: WorkoutThumbsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Thumbs up/down on a workout. Soft signal (distinct from per-exercise
    'never recommend'). Upsert toggles; thumbs=0 clears the vote."""
    try:
        db = get_supabase_db()
        supabase = db.client
        user_id = current_user["id"]

        if request.thumbs == 0:
            supabase.table("workout_thumbs").delete().eq(
                "user_id", user_id
            ).eq("workout_id", workout_id).execute()
            return {"success": True, "thumbs": 0}

        now = datetime.now(timezone.utc).isoformat()
        supabase.table("workout_thumbs").upsert({
            "user_id": user_id,
            "workout_id": workout_id,
            "thumbs": request.thumbs,
            "reason": request.reason,
            "updated_at": now,
        }, on_conflict="user_id,workout_id").execute()
        return {"success": True, "thumbs": request.thumbs}
    except Exception as e:
        logger.error(f"[studio] thumbs failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_studio")
