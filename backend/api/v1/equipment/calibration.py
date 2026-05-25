"""
Equipment calibration — Phase 1 of workouts overhaul.

Per-user equipment with calibration fields so plate math matches reality
("I told it my EZ bar is 17.5lb. Now suggestions actually work."). Replaces
hardcoded plate ladders / bar weights as primary source of truth; the
const tables remain as fallback only.

Endpoints
---------
GET    /api/v1/equipment/calibration              List current user's rows.
POST   /api/v1/equipment/calibration              Create a row.
PATCH  /api/v1/equipment/calibration/{id}         Update calibration fields.
DELETE /api/v1/equipment/calibration/{id}         Remove a row.

Schema lives in migration 2100_equipment_inventory.sql.
"""
from typing import Optional, Dict

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()


_VALID_CATEGORIES = {
    "barbell", "dumbbell", "cable", "machine", "plate_set", "kettlebell", "other",
}
_VALID_UNITS = {"kg", "lb"}


class CalibrationCreate(BaseModel):
    equipment_type_id: Optional[str] = None
    label: Optional[str] = None
    category: Optional[str] = None
    bar_empty_weight_kg: Optional[float] = None
    machine_empty_weight_kg: Optional[float] = None
    cable_pin_start_kg: Optional[float] = None
    cable_pin_increment_kg: Optional[float] = None
    plate_inventory: Optional[Dict[str, int]] = None
    dumbbell_inventory: Optional[Dict[str, int]] = None
    weight_unit: str = Field(default="kg")
    count: int = Field(default=1, ge=1)
    notes: Optional[str] = None


class CalibrationUpdate(BaseModel):
    """All fields optional — PATCH semantics. No max_length caps on inventory
    dicts (full-gym users legitimately exceed any cap, per
    `feedback_no_arbitrary_backend_caps`)."""
    label: Optional[str] = None
    category: Optional[str] = None
    bar_empty_weight_kg: Optional[float] = None
    machine_empty_weight_kg: Optional[float] = None
    cable_pin_start_kg: Optional[float] = None
    cable_pin_increment_kg: Optional[float] = None
    plate_inventory: Optional[Dict[str, int]] = None
    dumbbell_inventory: Optional[Dict[str, int]] = None
    weight_unit: Optional[str] = None
    count: Optional[int] = Field(default=None, ge=1)
    notes: Optional[str] = None


def _validate_payload(category: Optional[str], weight_unit: Optional[str]) -> None:
    if category is not None and category not in _VALID_CATEGORIES:
        raise HTTPException(
            status_code=422,
            detail=f"category must be one of {sorted(_VALID_CATEGORIES)}",
        )
    if weight_unit is not None and weight_unit not in _VALID_UNITS:
        raise HTTPException(
            status_code=422,
            detail=f"weight_unit must be one of {sorted(_VALID_UNITS)}",
        )


@router.get("/calibration")
async def list_calibration(current_user: dict = Depends(get_current_user)):
    """List current user's equipment_inventory rows."""
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("equipment_inventory")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=False)
        .execute()
    )
    return {"items": res.data or []}


@router.post("/calibration")
async def create_calibration(
    payload: CalibrationCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a new equipment_inventory row for the current user."""
    _validate_payload(payload.category, payload.weight_unit)
    user_id = current_user["id"]
    db = get_supabase_db()
    row = payload.model_dump(exclude_none=True)
    row["user_id"] = user_id
    try:
        ins = db.client.table("equipment_inventory").insert(row).execute()
    except Exception as e:
        logger.error(f"❌ [EquipmentCalibration] insert failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"insert_failed: {e}")
    if not ins.data:
        raise HTTPException(status_code=500, detail="empty_insert_response")
    logger.info(
        f"🏋️ [EquipmentCalibration] user={user_id} created id={ins.data[0].get('id')} "
        f"category={payload.category} label={payload.label!r}"
    )
    return ins.data[0]


@router.patch("/calibration/{calibration_id}")
async def update_calibration(
    calibration_id: str,
    payload: CalibrationUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update one or more calibration fields. Empty patches are rejected."""
    _validate_payload(payload.category, payload.weight_unit)
    updates = payload.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(status_code=422, detail="empty_patch")
    user_id = current_user["id"]
    db = get_supabase_db()
    try:
        res = (
            db.client.table("equipment_inventory")
            .update(updates)
            .eq("id", calibration_id)
            .eq("user_id", user_id)
            .execute()
        )
    except Exception as e:
        logger.error(f"❌ [EquipmentCalibration] update failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"update_failed: {e}")
    if not res.data:
        raise HTTPException(status_code=404, detail="calibration_not_found")
    logger.info(
        f"🏋️ [EquipmentCalibration] user={user_id} updated id={calibration_id} "
        f"fields={sorted(updates.keys())}"
    )
    return res.data[0]


@router.delete("/calibration/{calibration_id}")
async def delete_calibration(
    calibration_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove a calibration row."""
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("equipment_inventory")
        .delete()
        .eq("id", calibration_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="calibration_not_found")
    return {"deleted": True, "id": calibration_id}
