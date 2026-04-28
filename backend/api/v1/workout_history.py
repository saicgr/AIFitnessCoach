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
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user, verify_user_ownership, verify_resource_ownership
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal
import logging


logger = logging.getLogger(__name__)
router = APIRouter(prefix="/workout-history", tags=["Workout History Import"])


# =============================================================================
# Request/Response Models
# =============================================================================

class WorkoutHistoryEntry(BaseModel):
    """Single workout history entry for import.

    Slim shape = exercise_name + weight_kg + reps + sets. That path still
    powers the manual-entry form. Optional *rich* fields (set_type, rpe, rir,
    duration_seconds, etc.) are accepted too so a JS/mobile client can ship
    the same canonical row shape the WorkoutHistoryImporter pipeline produces.
    """
    exercise_name: str = Field(..., min_length=1, max_length=200)
    # Relaxed: allow null weight (bodyweight) and >=0 reps (matches migration 1964).
    weight_kg: Optional[float] = Field(default=None, ge=-500, le=1000)
    reps: Optional[int] = Field(default=None, ge=0, le=999)
    sets: int = Field(default=1, ge=1, le=20)
    performed_at: Optional[datetime] = None
    notes: Optional[str] = Field(default=None, max_length=500)

    # --- Rich canonical fields (optional; absent = manual-entry path) ---
    workout_name: Optional[str] = Field(default=None, max_length=200)
    set_number: Optional[int] = Field(default=None, ge=0, le=99)
    set_type: Optional[str] = Field(
        default=None,
        pattern="^(working|warmup|failure|dropset|amrap|cluster|rest_pause|backoff|assistance)$",
    )
    rpe: Optional[float] = Field(default=None, ge=0.0, le=10.0)
    rir: Optional[int] = Field(default=None, ge=0, le=10)
    duration_seconds: Optional[int] = Field(default=None, ge=0)
    distance_m: Optional[float] = Field(default=None, ge=0)
    superset_id: Optional[str] = Field(default=None, max_length=64)
    exercise_id: Optional[str] = None
    exercise_name_canonical: Optional[str] = Field(default=None, max_length=200)
    source_app: Optional[str] = Field(default=None, max_length=100)
    original_weight_value: Optional[float] = Field(default=None, ge=-500, le=5000)
    original_weight_unit: Optional[str] = Field(
        default=None, pattern="^(kg|lb|stone)$"
    )

    @validator('exercise_name')
    def clean_exercise_name(cls, v):
        return v.strip()


class BulkImportRequest(BaseModel):
    """Request for bulk importing multiple workout entries.

    Backward-compatible with the slim shape used by the manual-entry form;
    also accepts the rich canonical columns added in migration 1964.
    """
    user_id: str
    entries: List[WorkoutHistoryEntry] = Field(..., min_items=1, max_items=500)
    # Expanded to match migration 1964's source CHECK constraint.
    source: str = Field(
        default="manual",
        pattern="^(manual|import|spreadsheet|ai_parsed|synced|program_filled)$",
    )


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
    weight_kg: Optional[float] = None
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
    verify_user_ownership(current_user, request.user_id)
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
            raise safe_internal_error(ValueError("Failed to import workout entry"), "workout_history")

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
        logger.error(f"Error importing workout entry: {e}", exc_info=True)
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
    verify_user_ownership(current_user, request.user_id)
    logger.info(f"Bulk importing {len(request.entries)} entries for user {request.user_id}")

    try:
        db = get_supabase_db()

        imported_count = 0
        failed_count = 0
        exercises_affected = set()

        # Prepare all entries — persist slim OR rich shape depending on what
        # the client sent. Absent rich fields stay absent (no sentinel nulls
        # on columns the user didn't supply).
        entries_to_insert = []
        for entry in request.entries:
            try:
                performed_at = entry.performed_at or datetime.utcnow()
                row: dict = {
                    "user_id": request.user_id,
                    "exercise_name": entry.exercise_name.strip(),
                    "weight_kg": float(entry.weight_kg) if entry.weight_kg is not None else None,
                    "reps": entry.reps,
                    "sets": entry.sets,
                    "performed_at": performed_at.isoformat(),
                    "notes": entry.notes,
                    "source": request.source,
                }
                # Rich columns — only include when the caller populated them so
                # the DB defaults (set_type='working', nullable columns) stand.
                if entry.workout_name is not None:
                    row["workout_name"] = entry.workout_name
                if entry.set_number is not None:
                    row["set_number"] = entry.set_number
                if entry.set_type is not None:
                    row["set_type"] = entry.set_type
                if entry.rpe is not None:
                    row["rpe"] = entry.rpe
                if entry.rir is not None:
                    row["rir"] = entry.rir
                if entry.duration_seconds is not None:
                    row["duration_seconds"] = entry.duration_seconds
                if entry.distance_m is not None:
                    row["distance_m"] = entry.distance_m
                if entry.superset_id is not None:
                    row["superset_id"] = entry.superset_id
                if entry.exercise_id is not None:
                    row["exercise_id"] = entry.exercise_id
                if entry.exercise_name_canonical is not None:
                    row["exercise_name_canonical"] = entry.exercise_name_canonical
                if entry.source_app is not None:
                    row["source_app"] = entry.source_app
                if entry.original_weight_value is not None:
                    row["original_weight_value"] = entry.original_weight_value
                if entry.original_weight_unit is not None:
                    row["original_weight_unit"] = entry.original_weight_unit

                entries_to_insert.append(row)
                exercises_affected.add(entry.exercise_name.strip())
            except Exception as e:
                logger.warning(f"Failed to prepare entry: {e}", exc_info=True)
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
        logger.error(f"Error in bulk import: {e}", exc_info=True)
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
    verify_user_ownership(current_user, user_id)
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
                weight_kg=float(row["weight_kg"]) if row.get("weight_kg") is not None else None,
                reps=row["reps"],
                sets=row["sets"],
                performed_at=datetime.fromisoformat(row["performed_at"].replace("Z", "+00:00")),
                notes=row.get("notes"),
                source=row["source"],
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            ))

        return entries

    except Exception as e:
        logger.error(f"Error getting workout history: {e}", exc_info=True)
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
    verify_user_ownership(current_user, user_id)
    logger.info(f"Getting strength summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Get imported history aggregated by exercise. The RPC is an
        # optimization — if the function hasn't been migrated on this
        # environment (PGRST202: "Could not find the function …"), fall
        # through to the manual aggregation below instead of 500-ing.
        result = None
        try:
            result = db.client.rpc(
                "get_strength_summary_by_user",
                {"p_user_id": user_id}
            ).execute()
        except Exception as rpc_err:
            err_str = str(rpc_err)
            if "PGRST202" in err_str or "Could not find the function" in err_str:
                logger.info("get_strength_summary_by_user RPC missing; using manual aggregation")
                result = None
            else:
                raise

        # If RPC doesn't exist or returned empty, fall back to manual query
        if not result or not result.data:
            # Manual aggregation
            history_result = db.client.table("workout_history_imports") \
                .select("exercise_name, weight_kg, performed_at") \
                .eq("user_id", user_id) \
                .order("performed_at", desc=True) \
                .execute()

            # Aggregate by exercise
            exercise_data = {}
            for row in history_result.data or []:
                if row.get("weight_kg") is None:
                    # Skip historical rows missing weight — they can't contribute
                    # to a strength summary, and silently zeroing them would skew
                    # max/last calculations downstream.
                    continue
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
        logger.error(f"Error getting strength summary: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history")


@router.delete("/user/{user_id}/entry/{entry_id}")
async def delete_workout_history_entry(user_id: str, entry_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a specific imported workout history entry."""
    verify_user_ownership(current_user, user_id)
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
        logger.error(f"Error deleting entry: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history")


@router.delete("/user/{user_id}/clear")
async def clear_workout_history(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Clear all imported workout history for a user."""
    verify_user_ownership(current_user, user_id)
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
        logger.error(f"Error clearing history: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history")
