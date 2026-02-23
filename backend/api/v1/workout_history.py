"""
Workout History Import API - Manual entry of past workouts for AI learning.

This module allows users to:
1. Import individual past workout exercises (manual entry)
2. Bulk import workout history (spreadsheet/CSV)
3. View their imported history
4. Delete imported entries

The imported data feeds into the strength history system so the AI
can generate workouts with appropriate weights from day one.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal
import logging

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/workout-history", tags=["Workout History Import"])


# =============================================================================
# Request/Response Models
# =============================================================================

class WorkoutHistoryEntry(BaseModel):
    """Single workout history entry for import."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    weight_kg: float = Field(..., ge=0, le=1000)
    reps: int = Field(..., ge=1, le=100)
    sets: int = Field(default=1, ge=1, le=20)
    performed_at: Optional[datetime] = None
    notes: Optional[str] = Field(default=None, max_length=500)

    @validator('exercise_name')
    def clean_exercise_name(cls, v):
        return v.strip()


class BulkImportRequest(BaseModel):
    """Request for bulk importing multiple workout entries."""
    user_id: str
    entries: List[WorkoutHistoryEntry] = Field(..., min_items=1, max_items=100)
    source: str = Field(default="manual", pattern="^(manual|import|spreadsheet)$")


class SingleImportRequest(BaseModel):
    """Request for importing a single workout entry."""
    user_id: str
    exercise_name: str = Field(..., min_length=1, max_length=200)
    weight_kg: float = Field(..., ge=0, le=1000)
    reps: int = Field(..., ge=1, le=100)
    sets: int = Field(default=1, ge=1, le=20)
    performed_at: Optional[datetime] = None
    notes: Optional[str] = Field(default=None, max_length=500)


class WorkoutHistoryResponse(BaseModel):
    """Response for a single workout history entry."""
    id: str
    exercise_name: str
    weight_kg: float
    reps: int
    sets: int
    performed_at: datetime
    notes: Optional[str]
    source: str
    created_at: datetime


class ImportSummary(BaseModel):
    """Summary of import operation."""
    imported_count: int
    failed_count: int
    exercises_affected: List[str]
    message: str


class StrengthSummary(BaseModel):
    """Summary of user's strength data from imports."""
    exercise_name: str
    max_weight_kg: float
    last_weight_kg: float
    total_sessions: int
    last_performed: datetime
    source: str  # "imported" or "completed_workouts" or "both"


# =============================================================================
# API Endpoints
# =============================================================================

@router.post("/import", response_model=ImportSummary)
async def import_workout_history(request: SingleImportRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Import a single past workout entry.

    This allows users to manually enter their workout history
    so the AI can learn their strength levels immediately.
    """
    logger.info(f"Importing single workout entry for user {request.user_id}: {request.exercise_name}")

    try:
        db = get_supabase_db()

        # Default to now if no date provided
        performed_at = request.performed_at or datetime.utcnow()

        result = db.client.table("workout_history_imports").insert({
            "user_id": request.user_id,
            "exercise_name": request.exercise_name.strip(),
            "weight_kg": request.weight_kg,
            "reps": request.reps,
            "sets": request.sets,
            "performed_at": performed_at.isoformat(),
            "notes": request.notes,
            "source": "manual",
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to import workout entry")

        logger.info(f"Successfully imported workout entry: {request.exercise_name} @ {request.weight_kg}kg")

        return ImportSummary(
            imported_count=1,
            failed_count=0,
            exercises_affected=[request.exercise_name],
            message=f"Successfully imported {request.exercise_name} at {request.weight_kg}kg"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error importing workout entry: {e}")
        raise safe_internal_error(e, "workout_history")


@router.post("/import/bulk", response_model=ImportSummary)
async def bulk_import_workout_history(request: BulkImportRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Bulk import multiple workout history entries.

    Useful for importing from spreadsheets or other fitness apps.
    Maximum 100 entries per request.
    """
    logger.info(f"Bulk importing {len(request.entries)} entries for user {request.user_id}")

    try:
        db = get_supabase_db()

        imported_count = 0
        failed_count = 0
        exercises_affected = set()

        # Prepare all entries
        entries_to_insert = []
        for entry in request.entries:
            try:
                performed_at = entry.performed_at or datetime.utcnow()
                entries_to_insert.append({
                    "user_id": request.user_id,
                    "exercise_name": entry.exercise_name.strip(),
                    "weight_kg": float(entry.weight_kg),
                    "reps": entry.reps,
                    "sets": entry.sets,
                    "performed_at": performed_at.isoformat(),
                    "notes": entry.notes,
                    "source": request.source,
                })
                exercises_affected.add(entry.exercise_name.strip())
            except Exception as e:
                logger.warning(f"Failed to prepare entry: {e}")
                failed_count += 1

        # Bulk insert
        if entries_to_insert:
            result = db.client.table("workout_history_imports").insert(entries_to_insert).execute()
            imported_count = len(result.data) if result.data else 0

        logger.info(f"Bulk import complete: {imported_count} imported, {failed_count} failed")

        return ImportSummary(
            imported_count=imported_count,
            failed_count=failed_count,
            exercises_affected=list(exercises_affected),
            message=f"Imported {imported_count} entries for {len(exercises_affected)} exercises"
        )

    except Exception as e:
        logger.error(f"Error in bulk import: {e}")
        raise safe_internal_error(e, "workout_history")


@router.get("/user/{user_id}", response_model=List[WorkoutHistoryResponse])
async def get_user_workout_history(
    user_id: str,
    exercise_name: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's imported workout history.

    Returns entries sorted by performed_at date (most recent first).
    """
    logger.info(f"Getting workout history for user {user_id}")

    try:
        db = get_supabase_db()

        # Build query step by step
        query = db.client.table("workout_history_imports").select("*").eq("user_id", user_id)

        if exercise_name:
            query = query.ilike("exercise_name", f"%{exercise_name}%")

        # Apply ordering and pagination last
        end_offset = offset + limit - 1
        result = query.order("performed_at", desc=True).range(offset, end_offset).execute()

        entries = []
        for row in result.data or []:
            entries.append(WorkoutHistoryResponse(
                id=row["id"],
                exercise_name=row["exercise_name"],
                weight_kg=float(row["weight_kg"]),
                reps=row["reps"],
                sets=row["sets"],
                performed_at=datetime.fromisoformat(row["performed_at"].replace("Z", "+00:00")),
                notes=row.get("notes"),
                source=row["source"],
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            ))

        return entries

    except Exception as e:
        logger.error(f"Error getting workout history: {e}")
        raise safe_internal_error(e, "workout_history")


@router.get("/user/{user_id}/strength-summary", response_model=List[StrengthSummary])
async def get_strength_summary(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get aggregated strength summary from all sources.

    Combines data from:
    1. Imported workout history
    2. Completed workouts (ChromaDB)

    This is what the AI uses to determine appropriate weights.
    """
    logger.info(f"Getting strength summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Get imported history aggregated by exercise
        result = db.client.rpc(
            "get_strength_summary_by_user",
            {"p_user_id": user_id}
        ).execute()

        # If RPC doesn't exist, fall back to manual query
        if not result.data:
            # Manual aggregation
            history_result = db.client.table("workout_history_imports") \
                .select("exercise_name, weight_kg, performed_at") \
                .eq("user_id", user_id) \
                .order("performed_at", desc=True) \
                .execute()

            # Aggregate by exercise
            exercise_data = {}
            for row in history_result.data or []:
                name = row["exercise_name"].lower()
                weight = float(row["weight_kg"])
                performed = datetime.fromisoformat(row["performed_at"].replace("Z", "+00:00"))

                if name not in exercise_data:
                    exercise_data[name] = {
                        "exercise_name": row["exercise_name"],
                        "max_weight_kg": weight,
                        "last_weight_kg": weight,
                        "total_sessions": 1,
                        "last_performed": performed,
                    }
                else:
                    exercise_data[name]["total_sessions"] += 1
                    if weight > exercise_data[name]["max_weight_kg"]:
                        exercise_data[name]["max_weight_kg"] = weight
                    # First entry is most recent due to ordering

            summaries = []
            for data in exercise_data.values():
                summaries.append(StrengthSummary(
                    exercise_name=data["exercise_name"],
                    max_weight_kg=data["max_weight_kg"],
                    last_weight_kg=data["last_weight_kg"],
                    total_sessions=data["total_sessions"],
                    last_performed=data["last_performed"],
                    source="imported",
                ))

            return summaries

        return [StrengthSummary(**row) for row in result.data]

    except Exception as e:
        logger.error(f"Error getting strength summary: {e}")
        raise safe_internal_error(e, "workout_history")


@router.delete("/user/{user_id}/entry/{entry_id}")
async def delete_workout_history_entry(user_id: str, entry_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a specific imported workout history entry."""
    logger.info(f"Deleting workout history entry {entry_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_history_imports") \
            .delete() \
            .eq("id", entry_id) \
            .eq("user_id", user_id) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Entry not found")

        return {"message": "Entry deleted successfully", "id": entry_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting entry: {e}")
        raise safe_internal_error(e, "workout_history")


@router.delete("/user/{user_id}/clear")
async def clear_workout_history(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Clear all imported workout history for a user."""
    logger.info(f"Clearing all workout history for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_history_imports") \
            .delete() \
            .eq("user_id", user_id) \
            .execute()

        deleted_count = len(result.data) if result.data else 0

        return {
            "message": f"Cleared {deleted_count} entries",
            "deleted_count": deleted_count
        }

    except Exception as e:
        logger.error(f"Error clearing history: {e}")
        raise safe_internal_error(e, "workout_history")
