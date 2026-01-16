"""
Weight Increments API Endpoints.

Allows users to customize weight step sizes per equipment type (dumbbell, barbell, etc.).
Supports both kg and lbs units.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.activity_logger import log_user_activity

router = APIRouter()


class WeightIncrementsResponse(BaseModel):
    """Response model for weight increments."""
    user_id: str
    dumbbell: float = 2.5
    barbell: float = 2.5
    machine: float = 5.0
    kettlebell: float = 4.0
    cable: float = 2.5
    unit: Literal['kg', 'lbs'] = 'kg'
    updated_at: Optional[datetime] = None


class WeightIncrementsUpdate(BaseModel):
    """Update model for weight increments - all fields optional for partial updates."""
    dumbbell: Optional[float] = Field(None, ge=0.5, le=50, description="Dumbbell increment (0.5-50)")
    barbell: Optional[float] = Field(None, ge=0.5, le=50, description="Barbell increment (0.5-50)")
    machine: Optional[float] = Field(None, ge=0.5, le=50, description="Machine increment (0.5-50)")
    kettlebell: Optional[float] = Field(None, ge=0.5, le=50, description="Kettlebell increment (0.5-50)")
    cable: Optional[float] = Field(None, ge=0.5, le=50, description="Cable increment (0.5-50)")
    unit: Optional[Literal['kg', 'lbs']] = Field(None, description="Unit preference (kg or lbs)")


# Default values (industry standard)
DEFAULTS = {
    'dumbbell': 2.5,
    'barbell': 2.5,
    'machine': 5.0,
    'kettlebell': 4.0,
    'cable': 2.5,
    'unit': 'kg'
}


@router.get("/{user_id}", response_model=WeightIncrementsResponse)
async def get_weight_increments(user_id: str):
    """
    Get user's weight increment preferences.

    Returns defaults if no record exists for the user.
    """
    db = get_supabase_db()
    result = db.client.table("weight_increments").select("*").eq("user_id", user_id).execute()

    if result.data:
        # Remove user_id from db data since we pass it explicitly
        db_data = {k: v for k, v in result.data[0].items() if k != 'user_id'}
        return WeightIncrementsResponse(user_id=user_id, **db_data)

    # Return defaults if no record exists
    return WeightIncrementsResponse(user_id=user_id, **DEFAULTS)


@router.put("/{user_id}", response_model=WeightIncrementsResponse)
async def update_weight_increments(user_id: str, update: WeightIncrementsUpdate):
    """
    Update weight increment preferences (upsert).

    Only updates the fields that are provided in the request body.
    Creates a new record if one doesn't exist.
    """
    db = get_supabase_db()

    # Build update data (only non-None fields)
    update_data = {k: v for k, v in update.dict().items() if v is not None}
    update_data["user_id"] = user_id
    update_data["updated_at"] = datetime.utcnow().isoformat()

    # Upsert: insert or update
    result = db.client.table("weight_increments").upsert(
        update_data,
        on_conflict="user_id"
    ).execute()

    # Log user activity for analytics
    await log_user_activity(
        user_id=user_id,
        action="weight_increments_updated",
        endpoint="/weight-increments",
        metadata=update_data,
        level="INFO"
    )

    if result.data:
        # Remove user_id from db data since we pass it explicitly
        db_data = {k: v for k, v in result.data[0].items() if k != 'user_id'}
        return WeightIncrementsResponse(user_id=user_id, **db_data)

    raise HTTPException(status_code=500, detail="Failed to update weight increments")


@router.delete("/{user_id}")
async def reset_weight_increments(user_id: str):
    """
    Reset weight increments to defaults by deleting user's record.

    The next GET request will return default values.
    """
    db = get_supabase_db()
    db.client.table("weight_increments").delete().eq("user_id", user_id).execute()

    # Log user activity
    await log_user_activity(
        user_id=user_id,
        action="weight_increments_reset",
        endpoint="/weight-increments",
        level="INFO"
    )

    return {"message": "Reset to defaults", "defaults": DEFAULTS}
