"""
Program History API Endpoints

Allows users to:
- Save workout program snapshots
- View past program configurations
- Restore previous programs
- Track program success metrics
"""
from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/program-history", tags=["program-history"])


# ===== Request/Response Models =====

class ProgramSnapshotRequest(BaseModel):
    """Request to save a program snapshot"""
    user_id: str
    preferences: dict
    equipment: Optional[List[str]] = None
    injuries: Optional[List[str]] = None
    focus_areas: Optional[List[str]] = None
    program_name: Optional[str] = None
    description: Optional[str] = None
    set_as_current: bool = True


class ProgramHistoryItem(BaseModel):
    """A single program history entry"""
    id: str
    user_id: str
    preferences: dict
    equipment: List[str] = Field(default_factory=list)
    injuries: List[str] = Field(default_factory=list)
    focus_areas: List[str] = Field(default_factory=list)
    program_name: Optional[str] = None
    description: Optional[str] = None
    is_current: bool = False
    created_at: str
    applied_at: Optional[str] = None
    total_workouts_completed: int = 0
    last_workout_date: Optional[str] = None


class ProgramHistoryListResponse(BaseModel):
    """List of program history items"""
    programs: List[ProgramHistoryItem]
    total_count: int


class RestoreProgramRequest(BaseModel):
    """Request to restore a previous program"""
    user_id: str
    program_id: str


class RestoreProgramResponse(BaseModel):
    """Response after restoring a program"""
    success: bool
    message: str
    restored_program: ProgramHistoryItem


# ===== API Endpoints =====

@router.post("/save", response_model=ProgramHistoryItem)
async def save_program_snapshot(request: ProgramSnapshotRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Save current program configuration as a snapshot.

    This is automatically called when user updates their program via Customize Program.
    Stores a snapshot so they can view/restore it later.
    """
    logger.info(f"Saving program snapshot for user {request.user_id}")

    try:
        db = get_supabase_db()

        # If set_as_current, mark all other programs as not current
        if request.set_as_current:
            db.supabase.table("program_history").update({
                "is_current": False
            }).eq("user_id", request.user_id).eq("is_current", True).execute()

        # Insert new program snapshot
        snapshot_data = {
            "user_id": request.user_id,
            "preferences": request.preferences,
            "equipment": request.equipment or [],
            "injuries": request.injuries or [],
            "focus_areas": request.focus_areas or [],
            "program_name": request.program_name,
            "description": request.description,
            "is_current": request.set_as_current,
            "applied_at": datetime.now().isoformat() if request.set_as_current else None,
        }

        result = db.supabase.table("program_history").insert(snapshot_data).execute()

        if result.data:
            program = result.data[0]
            logger.info(f"✅ Saved program snapshot {program['id']} for user {request.user_id}")
            return ProgramHistoryItem(**program)
        else:
            raise Exception("No data returned from insert")

    except Exception as e:
        logger.error(f"❌ Failed to save program snapshot: {e}")
        raise safe_internal_error(e, "program_history")


@router.get("/list/{user_id}", response_model=ProgramHistoryListResponse)
async def list_program_history(user_id: str, limit: int = 20, offset: int = 0,
    current_user: dict = Depends(get_current_user),
):
    """
    Get list of all program snapshots for a user, ordered by most recent first.

    Returns both current and historical programs with metadata like:
    - How many workouts were completed with each program
    - When the program was last used
    - Program name and description
    """
    logger.info(f"Listing program history for user {user_id}")

    try:
        db = get_supabase_db()

        # Get total count
        count_result = db.supabase.table("program_history")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .execute()
        total_count = count_result.count or 0

        # Get programs
        result = db.supabase.table("program_history")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .limit(limit)\
            .offset(offset)\
            .execute()

        programs = [ProgramHistoryItem(**p) for p in result.data] if result.data else []

        logger.info(f"✅ Found {len(programs)} program snapshots for user {user_id}")
        return ProgramHistoryListResponse(programs=programs, total_count=total_count)

    except Exception as e:
        logger.error(f"❌ Failed to list program history: {e}")
        raise safe_internal_error(e, "program_history")


@router.post("/restore", response_model=RestoreProgramResponse)
async def restore_program(request: RestoreProgramRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Restore a previous program configuration.

    This:
    1. Marks the selected program as current
    2. Unmarksall other programs as current
    3. Updates the user's actual preferences in the users table
    4. Sets applied_at timestamp
    5. Returns the restored program

    The user will then need to regenerate workouts with these preferences.
    """
    logger.info(f"Restoring program {request.program_id} for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Get the program to restore
        program_result = db.supabase.table("program_history")\
            .select("*")\
            .eq("id", request.program_id)\
            .eq("user_id", request.user_id)\
            .single()\
            .execute()

        if not program_result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        program = program_result.data

        # Mark all other programs as not current
        db.supabase.table("program_history").update({
            "is_current": False
        }).eq("user_id", request.user_id).eq("is_current", True).execute()

        # Mark this program as current
        db.supabase.table("program_history").update({
            "is_current": True,
            "applied_at": datetime.now().isoformat()
        }).eq("id", request.program_id).execute()

        # Update user's actual preferences in users table
        update_data = {
            "preferences": program["preferences"],
        }
        if program.get("equipment"):
            update_data["equipment"] = program["equipment"]
        if program.get("injuries"):
            update_data["active_injuries"] = program["injuries"]

        db.update_user(request.user_id, update_data)

        logger.info(f"✅ Restored program {request.program_id} for user {request.user_id}")

        # Fetch updated program
        updated_program = db.supabase.table("program_history")\
            .select("*")\
            .eq("id", request.program_id)\
            .single()\
            .execute()

        return RestoreProgramResponse(
            success=True,
            message="Program restored successfully. Please regenerate workouts.",
            restored_program=ProgramHistoryItem(**updated_program.data)
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to restore program: {e}")
        raise safe_internal_error(e, "program_history")


@router.delete("/{program_id}")
async def delete_program_snapshot(program_id: str, user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a program snapshot.

    Cannot delete the current active program.
    """
    logger.info(f"Deleting program {program_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Check if it's the current program
        program = db.supabase.table("program_history")\
            .select("is_current")\
            .eq("id", program_id)\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not program.data:
            raise HTTPException(status_code=404, detail="Program not found")

        if program.data.get("is_current"):
            raise HTTPException(
                status_code=400,
                detail="Cannot delete the current active program"
            )

        # Delete the program
        db.supabase.table("program_history")\
            .delete()\
            .eq("id", program_id)\
            .eq("user_id", user_id)\
            .execute()

        logger.info(f"✅ Deleted program {program_id}")
        return {"success": True, "message": "Program deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to delete program: {e}")
        raise safe_internal_error(e, "program_history")
