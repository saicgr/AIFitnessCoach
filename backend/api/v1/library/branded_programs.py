"""
Branded Program API endpoints.

This module handles branded program operations for the Flutter app:
- GET /branded-programs - List all branded programs
- GET /branded-programs/featured - Get featured programs
- GET /branded-programs/categories - Get program categories
- GET /branded-programs/{program_id} - Get a single program
- POST /branded-programs/assign - Assign a program to a user
- GET /branded-programs/current - Get user's current program
- PATCH /branded-programs/current/rename - Rename user's program
- DELETE /branded-programs/current - End user's current program
- GET /branded-programs/history - Get user's program history
"""
from typing import List, Dict, Any, Optional
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class AssignProgramRequest(BaseModel):
    """Request body for assigning a program to a user."""
    user_id: str
    program_id: str
    custom_name: Optional[str] = None
    target_race_date: Optional[str] = None  # For HYROX programs
    division: Optional[str] = None  # For HYROX programs


class RenameProgramRequest(BaseModel):
    """Request body for renaming a program."""
    user_id: str
    custom_name: str


def row_to_branded_program(row: Dict[str, Any]) -> Dict[str, Any]:
    """Convert a database row to branded program API response format."""
    sessions_per_week = row.get("sessions_per_week", 4)
    session_duration = 45 if sessions_per_week <= 4 else 60

    return {
        "id": row.get("id"),
        "name": row.get("name"),
        "category": row.get("category"),
        "subcategory": row.get("split_type"),
        "difficulty_level": row.get("difficulty_level"),
        "duration_weeks": row.get("duration_weeks"),
        "sessions_per_week": sessions_per_week,
        "session_duration_minutes": session_duration,
        "tags": row.get("goals", []),
        "goals": row.get("goals", []),
        "description": row.get("description"),
        "short_description": row.get("tagline"),
        "tagline": row.get("tagline"),
        "celebrity_name": None,
        "is_featured": row.get("is_featured", False),
        "is_popular": row.get("is_featured", False),  # Use featured as popular
        "is_premium": row.get("is_premium", False),
        "requires_gym": row.get("requires_gym", True),
        "icon_name": row.get("icon_name"),
        "color_hex": row.get("color_hex"),
        "created_at": str(row.get("created_at")) if row.get("created_at") else None,
        "program_type": row.get("program_type"),
        "program_metadata": row.get("program_metadata"),
        "minimum_equipment": row.get("minimum_equipment", []),
    }


def row_to_user_program(row: Dict[str, Any], program: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Convert a user_program_assignments row to API response format."""
    return {
        "user_id": row.get("user_id"),
        "program_id": row.get("branded_program_id"),
        "custom_name": row.get("custom_program_name"),
        "started_at": str(row.get("started_at")) if row.get("started_at") else None,
        "current_week": row.get("current_week", 1),
        "is_active": row.get("is_active", True),
        "program": program,
        "target_race_date": str(row.get("target_race_date")) if row.get("target_race_date") else None,
        "division": row.get("division"),
        "current_phase": row.get("current_phase"),
    }


@router.get("/branded-programs", response_model=List[Dict[str, Any]])
async def list_branded_programs(
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """
    List all branded programs with optional filters.
    """
    try:
        db = get_supabase_db()
        query = db.client.table("branded_programs").select("*").eq("is_active", True)

        if category:
            query = query.eq("category", category)
        if difficulty:
            query = query.ilike("difficulty_level", f"%{difficulty}%")
        if search:
            query = query.ilike("name", f"%{search}%")

        result = query.order("is_featured", desc=True).order("name").range(offset, offset + limit - 1).execute()

        programs = [row_to_branded_program(row) for row in result.data]
        logger.info(f"Listed {len(programs)} branded programs")
        return programs

    except Exception as e:
        logger.error(f"Error listing branded programs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/branded-programs/featured", response_model=List[Dict[str, Any]])
async def get_featured_programs():
    """
    Get featured branded programs.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("branded_programs").select("*").eq("is_active", True).eq("is_featured", True).order("name").execute()

        programs = [row_to_branded_program(row) for row in result.data]
        logger.info(f"Listed {len(programs)} featured programs")
        return programs

    except Exception as e:
        logger.error(f"Error fetching featured programs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/branded-programs/categories", response_model=List[Dict[str, Any]])
async def get_program_categories():
    """
    Get all program categories with counts.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("branded_programs").select("category").eq("is_active", True).execute()

        category_counts: Dict[str, int] = {}
        for row in result.data:
            cat = row.get("category", "Other")
            category_counts[cat] = category_counts.get(cat, 0) + 1

        categories = [
            {"name": name, "count": count}
            for name, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True)
        ]

        logger.info(f"Listed {len(categories)} program categories")
        return categories

    except Exception as e:
        logger.error(f"Error getting program categories: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# NOTE: The /{program_id} route is defined at the END of this file
# to prevent it from matching specific routes like /current, /featured, etc.


@router.post("/branded-programs/assign", response_model=Dict[str, Any])
async def assign_program(request: AssignProgramRequest):
    """
    Assign a branded program to a user.
    Deactivates any existing active program for the user.
    """
    try:
        db = get_supabase_db()

        # Get program details
        program_result = db.client.table("branded_programs").select("*").eq("id", request.program_id).eq("is_active", True).execute()

        if not program_result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        program = program_result.data[0]

        # Deactivate any existing active programs for this user
        db.client.table("user_program_assignments").update({
            "is_active": False,
            "status": "abandoned",
            "updated_at": datetime.utcnow().isoformat()
        }).eq("user_id", request.user_id).eq("is_active", True).execute()

        # Calculate total workouts and target end date
        duration_weeks = program.get("duration_weeks", 12)
        sessions_per_week = program.get("sessions_per_week", 5)
        total_workouts = duration_weeks * sessions_per_week

        # Create new assignment
        assignment_data = {
            "user_id": request.user_id,
            "branded_program_id": request.program_id,
            "custom_program_name": request.custom_name or program.get("name"),
            "started_at": datetime.utcnow().isoformat(),
            "total_workouts": total_workouts,
            "is_active": True,
            "status": "active",
            "current_week": 1,
            "workouts_completed": 0,
            "progress_percentage": 0,
        }

        # Add HYROX-specific fields if provided
        if request.target_race_date:
            assignment_data["target_race_date"] = request.target_race_date
        if request.division:
            assignment_data["division"] = request.division

        # Determine initial phase for HYROX programs
        if program.get("program_type") in ["hyrox", "hyrox_home"]:
            assignment_data["current_phase"] = "build"  # Default to build phase

        result = db.client.table("user_program_assignments").insert(assignment_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to assign program")

        assignment = result.data[0]
        program_data = row_to_branded_program(program)

        logger.info(f"Assigned program {request.program_id} to user {request.user_id}")
        return row_to_user_program(assignment, program_data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error assigning program: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/branded-programs/current", response_model=Dict[str, Any])
async def get_current_program(user_id: str = Query(...)):
    """
    Get the user's current active program.
    """
    try:
        db = get_supabase_db()

        # Get active assignment
        result = db.client.table("user_program_assignments").select("*").eq("user_id", user_id).eq("is_active", True).eq("status", "active").order("started_at", desc=True).limit(1).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No active program found")

        assignment = result.data[0]

        # Get program details
        program_id = assignment.get("branded_program_id")
        program_data = None

        if program_id:
            program_result = db.client.table("branded_programs").select("*").eq("id", program_id).execute()
            if program_result.data:
                program_data = row_to_branded_program(program_result.data[0])

        return row_to_user_program(assignment, program_data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting current program for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/branded-programs/current/rename", response_model=Dict[str, Any])
async def rename_current_program(request: RenameProgramRequest):
    """
    Rename the user's current program.
    """
    try:
        db = get_supabase_db()

        # Update the custom name
        result = db.client.table("user_program_assignments").update({
            "custom_program_name": request.custom_name,
            "updated_at": datetime.utcnow().isoformat()
        }).eq("user_id", request.user_id).eq("is_active", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No active program found")

        assignment = result.data[0]

        # Get program details
        program_id = assignment.get("branded_program_id")
        program_data = None

        if program_id:
            program_result = db.client.table("branded_programs").select("*").eq("id", program_id).execute()
            if program_result.data:
                program_data = row_to_branded_program(program_result.data[0])

        logger.info(f"Renamed program for user {request.user_id} to '{request.custom_name}'")
        return row_to_user_program(assignment, program_data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error renaming program: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/branded-programs/current")
async def end_current_program(user_id: str = Query(...)):
    """
    End/deactivate the user's current program.
    """
    try:
        db = get_supabase_db()

        result = db.client.table("user_program_assignments").update({
            "is_active": False,
            "status": "abandoned",
            "updated_at": datetime.utcnow().isoformat()
        }).eq("user_id", user_id).eq("is_active", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No active program found")

        logger.info(f"Ended program for user {user_id}")
        return {"success": True, "message": "Program ended successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error ending program: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/branded-programs/history", response_model=List[Dict[str, Any]])
async def get_program_history(user_id: str = Query(...)):
    """
    Get the user's program history.
    """
    try:
        db = get_supabase_db()

        result = db.client.table("user_program_assignments").select("*").eq("user_id", user_id).order("started_at", desc=True).execute()

        history = []
        for assignment in result.data:
            program_id = assignment.get("branded_program_id")
            program_data = None

            if program_id:
                program_result = db.client.table("branded_programs").select("*").eq("id", program_id).execute()
                if program_result.data:
                    program_data = row_to_branded_program(program_result.data[0])

            history.append(row_to_user_program(assignment, program_data))

        logger.info(f"Listed {len(history)} programs in history for user {user_id}")
        return history

    except Exception as e:
        logger.error(f"Error getting program history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# IMPORTANT: This route MUST be at the end to prevent it from matching
# specific routes like /current, /featured, /categories, /assign, /history
@router.get("/branded-programs/{program_id}", response_model=Dict[str, Any])
async def get_branded_program(program_id: str):
    """
    Get a single branded program by ID.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("branded_programs").select("*").eq("id", program_id).eq("is_active", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        return row_to_branded_program(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting program {program_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
