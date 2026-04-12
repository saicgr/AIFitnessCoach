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
from core.db import get_supabase_db
from typing import List, Dict, Any, Optional
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from core.logger import get_logger
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


class AssignProgramRequest(BaseModel):
    """Request body for assigning a program to a user."""
    user_id: str
    program_id: str
    custom_name: Optional[str] = None
    target_race_date: Optional[str] = None  # For HYROX programs
    division: Optional[str] = None  # For HYROX programs
    desired_weeks: Optional[int] = None  # User's chosen duration
    sessions_per_week: Optional[int] = None  # User's chosen frequency


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
        logger.error(f"Error listing branded programs: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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
        logger.error(f"Error fetching featured programs: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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
        logger.error(f"Error getting program categories: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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

        # Use user-selected duration or fall back to program defaults
        duration_weeks = request.desired_weeks or program.get("duration_weeks", 12)
        sessions_per_week = request.sessions_per_week or program.get("sessions_per_week", 5)
        total_workouts = duration_weeks * sessions_per_week

        # Find the best matching variant if user selected duration/sessions
        variant_id = None
        if request.desired_weeks or request.sessions_per_week:
            variants_result = db.client.table("program_variants").select(
                "id, duration_weeks, sessions_per_week"
            ).eq("base_program_id", request.program_id).eq(
                "sessions_per_week", sessions_per_week
            ).order("duration_weeks").execute()

            if variants_result.data:
                # Pick smallest anchor >= desired_weeks, or largest if none
                for v in variants_result.data:
                    if v["duration_weeks"] >= duration_weeks:
                        variant_id = v["id"]
                        break
                if not variant_id:
                    variant_id = variants_result.data[-1]["id"]

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

        # Add variant tracking fields
        if variant_id:
            assignment_data["variant_id"] = variant_id
        if request.desired_weeks:
            assignment_data["desired_weeks"] = request.desired_weeks
        if request.sessions_per_week:
            assignment_data["sessions_per_week"] = request.sessions_per_week

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
            raise safe_internal_error(ValueError("Failed to assign program"), "library")

        assignment = result.data[0]
        program_data = row_to_branded_program(program)

        logger.info(f"Assigned program {request.program_id} to user {request.user_id}")
        return row_to_user_program(assignment, program_data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error assigning program: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


@router.get("/branded-programs/current", response_model=Optional[Dict[str, Any]])
async def get_current_program(user_id: str = Query(...)):
    """
    Get the user's current active program.
    Returns null if no active program (this is an expected state, not an error).
    """
    try:
        db = get_supabase_db()

        # Get active assignment
        result = db.client.table("user_program_assignments").select("*").eq("user_id", user_id).eq("is_active", True).eq("status", "active").order("started_at", desc=True).limit(1).execute()

        if not result.data:
            return None

        assignment = result.data[0]

        # Get program details
        program_id = assignment.get("branded_program_id")
        program_data = None

        if program_id:
            program_result = db.client.table("branded_programs").select("*").eq("id", program_id).execute()
            if program_result.data:
                program_data = row_to_branded_program(program_result.data[0])

        return row_to_user_program(assignment, program_data)

    except Exception as e:
        logger.error(f"Error getting current program for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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
        logger.error(f"Error renaming program: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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
        logger.error(f"Error ending program: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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
        logger.error(f"Error getting program history: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


@router.get("/branded-programs/{program_id}/durations", response_model=Dict[str, Any])
async def get_program_durations(program_id: str):
    """
    Get available duration variants for a branded program.
    Returns anchor durations, min/max weeks, and sessions_per_week options.
    """
    try:
        db = get_supabase_db()

        # Get the program name
        program_result = db.client.table("branded_programs").select("id, name").eq("id", program_id).execute()
        if not program_result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        program_name = program_result.data[0]["name"]

        # Get all variants for this program
        variants_result = (
            db.client.table("program_variants")
            .select("id, duration_weeks, sessions_per_week, intensity_level, variant_name")
            .eq("base_program_id", program_id)
            .order("duration_weeks")
            .execute()
        )

        variants = variants_result.data or []

        # Build available durations list and anchor weeks
        available_durations = []
        anchor_weeks_set = set()
        sessions_set = set()

        for v in variants:
            dw = v.get("duration_weeks")
            spw = v.get("sessions_per_week")
            if dw and spw:
                available_durations.append({
                    "variant_id": v["id"],
                    "duration_weeks": dw,
                    "sessions_per_week": spw,
                    "intensity_level": v.get("intensity_level"),
                })
                anchor_weeks_set.add(dw)
                sessions_set.add(spw)

        anchor_weeks = sorted(anchor_weeks_set)
        min_weeks = min(anchor_weeks) if anchor_weeks else 1
        max_weeks = max(anchor_weeks) if anchor_weeks else 12
        available_sessions = sorted(sessions_set)

        logger.info(f"Got {len(available_durations)} variants for program {program_id}: anchors={anchor_weeks}")
        return {
            "program_id": program_id,
            "program_name": program_name,
            "available_durations": available_durations,
            "min_weeks": min_weeks,
            "max_weeks": max_weeks,
            "anchor_weeks": anchor_weeks,
            "available_sessions_per_week": available_sessions,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting durations for program {program_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


@router.get("/branded-programs/{program_id}/weeks", response_model=List[Dict[str, Any]])
async def get_program_weeks(
    program_id: str,
    desired_weeks: int = Query(..., ge=1, le=52),
    sessions_per_week: int = Query(..., ge=1, le=7),
):
    """
    Get week-by-week workout data for a program at the desired duration.
    Uses ProgramDurationService to derive weeks from anchor data.
    """
    try:
        from services.program_duration_service import ProgramDurationService

        db = get_supabase_db()

        # Get program name
        program_result = db.client.table("branded_programs").select("id, name").eq("id", program_id).execute()
        if not program_result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        program_name = program_result.data[0]["name"]

        service = ProgramDurationService(db.client)
        weeks = await service.get_program_for_duration(
            program_name, desired_weeks, sessions_per_week
        )

        if not weeks:
            raise HTTPException(
                status_code=404,
                detail=f"No week data found for {program_name} at {desired_weeks}w/{sessions_per_week}x per week"
            )

        logger.info(f"Got {len(weeks)} weeks for program {program_id} ({desired_weeks}w, {sessions_per_week}/wk)")
        return weeks

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting weeks for program {program_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")


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
        logger.error(f"Error getting program {program_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "branded_programs")
