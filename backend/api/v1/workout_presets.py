"""Workout Customization Studio presets — saved param sets the user can
re-apply with one tap. Applying a preset = POST /workouts/customize with these
params. Table: workout_presets (migration 2214)."""
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_client import get_supabase
from core.logger import get_logger
from models.workout_studio import WorkoutPreset, WorkoutPresetCreate, WorkoutPresetUpdate

logger = get_logger(__name__)
router = APIRouter(prefix="/workout-presets")


def _client():
    return get_supabase().client


@router.get("", response_model=List[WorkoutPreset])
async def list_presets(current_user: dict = Depends(get_current_user)):
    try:
        rows = _client().table("workout_presets").select("*").eq(
            "user_id", current_user["id"]
        ).order("updated_at", desc=True).execute()
        return [WorkoutPreset(**r) for r in (rows.data or [])]
    except Exception as e:
        logger.error(f"[presets] list failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_presets")


@router.post("", response_model=WorkoutPreset)
async def create_preset(
    request: WorkoutPresetCreate,
    current_user: dict = Depends(get_current_user),
):
    try:
        now = datetime.now(timezone.utc).isoformat()
        res = _client().table("workout_presets").insert({
            "user_id": current_user["id"],
            "name": request.name,
            "params": request.params.model_dump(),
            "created_at": now,
            "updated_at": now,
        }).execute()
        if not res.data:
            raise safe_internal_error(Exception("insert failed"), "workout_presets")
        return WorkoutPreset(**res.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[presets] create failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_presets")


@router.put("/{preset_id}", response_model=WorkoutPreset)
async def update_preset(
    preset_id: str,
    request: WorkoutPresetUpdate,
    current_user: dict = Depends(get_current_user),
):
    try:
        client = _client()
        existing = client.table("workout_presets").select("user_id").eq(
            "id", preset_id
        ).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Preset not found")
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Not your preset")

        update = {"updated_at": datetime.now(timezone.utc).isoformat()}
        if request.name is not None:
            update["name"] = request.name
        if request.params is not None:
            update["params"] = request.params.model_dump()
        res = client.table("workout_presets").update(update).eq("id", preset_id).execute()
        return WorkoutPreset(**res.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[presets] update failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_presets")


@router.delete("/{preset_id}")
async def delete_preset(
    preset_id: str,
    current_user: dict = Depends(get_current_user),
):
    try:
        client = _client()
        existing = client.table("workout_presets").select("user_id").eq(
            "id", preset_id
        ).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Preset not found")
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Not your preset")
        client.table("workout_presets").delete().eq("id", preset_id).execute()
        return {"success": True}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[presets] delete failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_presets")
