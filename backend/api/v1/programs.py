"""
Branded Programs and User Program Assignments API endpoints.

ENDPOINTS:
- GET  /api/v1/programs/branded - List all branded programs
- GET  /api/v1/programs/branded/{program_id} - Get single branded program details
- POST /api/v1/programs/assign/{user_id} - Assign a program to user
- GET  /api/v1/programs/user/{user_id}/current - Get user's current active program
- GET  /api/v1/programs/user/{user_id}/history - Get user's program history
- PATCH /api/v1/programs/user/{user_id}/rename - Rename current program
- PATCH /api/v1/programs/user/{user_id}/complete - Mark program as completed
- GET  /api/v1/programs/featured - Get featured programs for home screen
"""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import Optional, List
from pydantic import BaseModel
from enum import Enum

from core.supabase_client import get_supabase
from core.logger import get_logger
from services.user_context_service import user_context_service, EventType


class ProgramCategory(str, Enum):
    """Program categories."""
    strength = "strength"
    hypertrophy = "hypertrophy"
    weight_loss = "weight_loss"
    athletic = "athletic"
    functional = "functional"
    bodyweight = "bodyweight"
    powerlifting = "powerlifting"
    crossfit = "crossfit"
    beginner = "beginner"
    celebrity = "celebrity"
    sport_specific = "sport_specific"


class DifficultyLevel(str, Enum):
    """Program difficulty levels."""
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"
    elite = "elite"


# Request/Response Models

class BrandedProgram(BaseModel):
    """Branded program details."""
    id: str
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    difficulty: Optional[str] = None
    duration_weeks: Optional[int] = None
    sessions_per_week: Optional[int] = None
    session_duration_minutes: Optional[int] = None
    equipment_required: Optional[List[str]] = []
    goals: Optional[List[str]] = []
    tags: Optional[List[str]] = []
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    is_featured: bool = False
    is_premium: bool = False
    popularity_score: Optional[int] = 0
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class BrandedProgramDetail(BrandedProgram):
    """Branded program with full workout structure."""
    workouts: Optional[dict] = None
    overview: Optional[str] = None
    author: Optional[str] = None
    source_url: Optional[str] = None


class ProgramAssignRequest(BaseModel):
    """Request body for assigning a program to a user."""
    branded_program_id: Optional[str] = None
    custom_program_name: Optional[str] = None


class UserProgramAssignment(BaseModel):
    """User's program assignment details."""
    id: str
    user_id: str
    branded_program_id: Optional[str] = None
    custom_program_name: Optional[str] = None
    program_name: str  # Resolved name (branded or custom)
    started_at: str
    completed_at: Optional[str] = None
    is_active: bool = True
    week_number: int = 1
    created_at: str
    updated_at: str


class ProgramRenameRequest(BaseModel):
    """Request body for renaming a program."""
    custom_program_name: str


class FeaturedProgramsResponse(BaseModel):
    """Response for featured programs."""
    featured: List[BrandedProgram]
    popular: List[BrandedProgram]
    new_releases: List[BrandedProgram]


router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# BRANDED PROGRAMS ENDPOINTS
# =============================================================================


@router.get("/branded", response_model=List[BrandedProgram])
async def list_branded_programs(
    category: Optional[str] = Query(None, description="Filter by category"),
    difficulty: Optional[str] = Query(None, description="Filter by difficulty level"),
    is_featured: Optional[bool] = Query(None, description="Filter featured programs only"),
    is_premium: Optional[bool] = Query(None, description="Filter premium programs"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: dict = Depends(get_current_user),
):
    """
    List all branded workout programs.

    Supports filtering by category, difficulty, featured status, and premium status.
    Results are ordered by popularity score (descending).
    """
    logger.info(f"Listing branded programs: category={category}, difficulty={difficulty}, "
                f"is_featured={is_featured}, is_premium={is_premium}")

    try:
        supabase = get_supabase()

        # Build query
        query = supabase.client.table("branded_programs").select("*")

        if category:
            query = query.eq("category", category)
        if difficulty:
            query = query.eq("difficulty", difficulty)
        if is_featured is not None:
            query = query.eq("is_featured", is_featured)
        if is_premium is not None:
            query = query.eq("is_premium", is_premium)

        # Order by popularity and apply pagination
        query = query.order("popularity_score", desc=True).range(offset, offset + limit - 1)

        result = query.execute()

        programs = []
        for row in result.data or []:
            programs.append(BrandedProgram(
                id=row["id"],
                name=row["name"],
                description=row.get("description"),
                category=row.get("category"),
                subcategory=row.get("subcategory"),
                difficulty=row.get("difficulty"),
                duration_weeks=row.get("duration_weeks"),
                sessions_per_week=row.get("sessions_per_week"),
                session_duration_minutes=row.get("session_duration_minutes"),
                equipment_required=row.get("equipment_required") or [],
                goals=row.get("goals") or [],
                tags=row.get("tags") or [],
                image_url=row.get("image_url"),
                thumbnail_url=row.get("thumbnail_url"),
                is_featured=row.get("is_featured", False),
                is_premium=row.get("is_premium", False),
                popularity_score=row.get("popularity_score", 0),
                created_at=row.get("created_at"),
                updated_at=row.get("updated_at"),
            ))

        logger.info(f"Found {len(programs)} branded programs")
        return programs

    except Exception as e:
        logger.error(f"Failed to list branded programs: {e}")
        raise safe_internal_error(e, "programs")


@router.get("/branded/{program_id}", response_model=BrandedProgramDetail)
async def get_branded_program(program_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get detailed information about a specific branded program.

    Includes full workout structure and overview.
    """
    logger.info(f"Fetching branded program: {program_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("branded_programs")\
            .select("*")\
            .eq("id", program_id)\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        row = result.data

        return BrandedProgramDetail(
            id=row["id"],
            name=row["name"],
            description=row.get("description"),
            category=row.get("category"),
            subcategory=row.get("subcategory"),
            difficulty=row.get("difficulty"),
            duration_weeks=row.get("duration_weeks"),
            sessions_per_week=row.get("sessions_per_week"),
            session_duration_minutes=row.get("session_duration_minutes"),
            equipment_required=row.get("equipment_required") or [],
            goals=row.get("goals") or [],
            tags=row.get("tags") or [],
            image_url=row.get("image_url"),
            thumbnail_url=row.get("thumbnail_url"),
            is_featured=row.get("is_featured", False),
            is_premium=row.get("is_premium", False),
            popularity_score=row.get("popularity_score", 0),
            workouts=row.get("workouts"),
            overview=row.get("overview"),
            author=row.get("author"),
            source_url=row.get("source_url"),
            created_at=row.get("created_at"),
            updated_at=row.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get branded program: {e}")
        raise safe_internal_error(e, "programs")


@router.get("/featured", response_model=FeaturedProgramsResponse)
async def get_featured_programs(
    current_user: dict = Depends(get_current_user),
):
    """
    Get featured programs for the home screen.

    Returns:
    - featured: Programs marked as featured
    - popular: Top programs by popularity score
    - new_releases: Most recently added programs
    """
    logger.info("Fetching featured programs for home screen")

    try:
        supabase = get_supabase()

        # Featured programs
        featured_result = supabase.client.table("branded_programs")\
            .select("*")\
            .eq("is_featured", True)\
            .order("popularity_score", desc=True)\
            .limit(6)\
            .execute()

        # Popular programs (by popularity score)
        popular_result = supabase.client.table("branded_programs")\
            .select("*")\
            .order("popularity_score", desc=True)\
            .limit(10)\
            .execute()

        # New releases (by created_at)
        new_result = supabase.client.table("branded_programs")\
            .select("*")\
            .order("created_at", desc=True)\
            .limit(6)\
            .execute()

        def row_to_program(row: dict) -> BrandedProgram:
            return BrandedProgram(
                id=row["id"],
                name=row["name"],
                description=row.get("description"),
                category=row.get("category"),
                subcategory=row.get("subcategory"),
                difficulty=row.get("difficulty"),
                duration_weeks=row.get("duration_weeks"),
                sessions_per_week=row.get("sessions_per_week"),
                session_duration_minutes=row.get("session_duration_minutes"),
                equipment_required=row.get("equipment_required") or [],
                goals=row.get("goals") or [],
                tags=row.get("tags") or [],
                image_url=row.get("image_url"),
                thumbnail_url=row.get("thumbnail_url"),
                is_featured=row.get("is_featured", False),
                is_premium=row.get("is_premium", False),
                popularity_score=row.get("popularity_score", 0),
                created_at=row.get("created_at"),
                updated_at=row.get("updated_at"),
            )

        return FeaturedProgramsResponse(
            featured=[row_to_program(row) for row in featured_result.data or []],
            popular=[row_to_program(row) for row in popular_result.data or []],
            new_releases=[row_to_program(row) for row in new_result.data or []],
        )

    except Exception as e:
        logger.error(f"Failed to get featured programs: {e}")
        raise safe_internal_error(e, "programs")


# =============================================================================
# USER PROGRAM ASSIGNMENT ENDPOINTS
# =============================================================================


@router.post("/assign/{user_id}", response_model=UserProgramAssignment)
async def assign_program_to_user(user_id: str, request: ProgramAssignRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Assign a program to a user.

    Either branded_program_id or custom_program_name must be provided.
    This marks any existing active program as inactive and creates a new assignment.

    The assignment is also logged to user_context_logs for AI personalization.
    """
    logger.info(f"Assigning program to user {user_id}: branded={request.branded_program_id}, "
                f"custom={request.custom_program_name}")

    # Validate request
    if not request.branded_program_id and not request.custom_program_name:
        raise HTTPException(
            status_code=400,
            detail="Either branded_program_id or custom_program_name must be provided"
        )

    try:
        supabase = get_supabase()

        # Verify user exists
        user_result = supabase.client.table("users")\
            .select("id")\
            .eq("id", user_id)\
            .single()\
            .execute()

        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        # Resolve program name
        program_name = request.custom_program_name
        branded_program = None

        if request.branded_program_id:
            # Fetch branded program details
            program_result = supabase.client.table("branded_programs")\
                .select("id, name")\
                .eq("id", request.branded_program_id)\
                .single()\
                .execute()

            if not program_result.data:
                raise HTTPException(status_code=404, detail="Branded program not found")

            branded_program = program_result.data
            program_name = request.custom_program_name or branded_program["name"]

            # Increment popularity score for the branded program
            supabase.client.rpc(
                "increment_program_popularity",
                {"program_id": request.branded_program_id}
            ).execute()

        # Mark any existing active program as inactive
        supabase.client.table("user_program_assignments")\
            .update({"is_active": False, "updated_at": datetime.utcnow().isoformat()})\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .execute()

        # Create new program assignment
        now = datetime.utcnow().isoformat()
        assignment_data = {
            "user_id": user_id,
            "branded_program_id": request.branded_program_id,
            "custom_program_name": request.custom_program_name,
            "program_name": program_name,
            "started_at": now,
            "is_active": True,
            "week_number": 1,
            "created_at": now,
            "updated_at": now,
        }

        result = supabase.client.table("user_program_assignments")\
            .insert(assignment_data)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create program assignment")

        assignment = result.data[0]

        # Log to user_context_logs for AI personalization
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "program_assignment",
                "action": "assigned",
                "branded_program_id": request.branded_program_id,
                "branded_program_name": branded_program["name"] if branded_program else None,
                "custom_program_name": request.custom_program_name,
                "program_name": program_name,
            },
            context={
                "source": "programs_api",
                "assignment_id": assignment["id"],
            }
        )

        logger.info(f"Program assigned to user {user_id}: {program_name}")

        return UserProgramAssignment(
            id=assignment["id"],
            user_id=assignment["user_id"],
            branded_program_id=assignment.get("branded_program_id"),
            custom_program_name=assignment.get("custom_program_name"),
            program_name=assignment["program_name"],
            started_at=assignment["started_at"],
            completed_at=assignment.get("completed_at"),
            is_active=assignment["is_active"],
            week_number=assignment.get("week_number", 1),
            created_at=assignment["created_at"],
            updated_at=assignment["updated_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to assign program: {e}")
        raise safe_internal_error(e, "programs")


@router.get("/user/{user_id}/current", response_model=Optional[UserProgramAssignment])
async def get_current_program(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's current active program assignment.

    Returns None if no active program is assigned.
    """
    logger.info(f"Fetching current program for user {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("user_program_assignments")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .single()\
            .execute()

        if not result.data:
            return None

        assignment = result.data

        return UserProgramAssignment(
            id=assignment["id"],
            user_id=assignment["user_id"],
            branded_program_id=assignment.get("branded_program_id"),
            custom_program_name=assignment.get("custom_program_name"),
            program_name=assignment["program_name"],
            started_at=assignment["started_at"],
            completed_at=assignment.get("completed_at"),
            is_active=assignment["is_active"],
            week_number=assignment.get("week_number", 1),
            created_at=assignment["created_at"],
            updated_at=assignment["updated_at"],
        )

    except Exception as e:
        # If no record found, return None instead of error
        if "0 rows" in str(e).lower() or "no rows" in str(e).lower():
            return None
        logger.error(f"Failed to get current program: {e}")
        raise safe_internal_error(e, "programs")


@router.get("/user/{user_id}/history", response_model=List[UserProgramAssignment])
async def get_program_history(
    user_id: str,
    limit: int = Query(20, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    include_active: bool = Query(True, description="Include currently active program"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's program assignment history.

    Returns all past and current program assignments ordered by start date (descending).
    """
    logger.info(f"Fetching program history for user {user_id}")

    try:
        supabase = get_supabase()

        query = supabase.client.table("user_program_assignments")\
            .select("*")\
            .eq("user_id", user_id)

        if not include_active:
            query = query.eq("is_active", False)

        query = query.order("started_at", desc=True).range(offset, offset + limit - 1)

        result = query.execute()

        assignments = []
        for row in result.data or []:
            assignments.append(UserProgramAssignment(
                id=row["id"],
                user_id=row["user_id"],
                branded_program_id=row.get("branded_program_id"),
                custom_program_name=row.get("custom_program_name"),
                program_name=row["program_name"],
                started_at=row["started_at"],
                completed_at=row.get("completed_at"),
                is_active=row["is_active"],
                week_number=row.get("week_number", 1),
                created_at=row["created_at"],
                updated_at=row["updated_at"],
            ))

        logger.info(f"Found {len(assignments)} program assignments for user {user_id}")
        return assignments

    except Exception as e:
        logger.error(f"Failed to get program history: {e}")
        raise safe_internal_error(e, "programs")


@router.patch("/user/{user_id}/rename", response_model=UserProgramAssignment)
async def rename_current_program(user_id: str, request: ProgramRenameRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Rename the user's current active program.

    Updates both custom_program_name and program_name fields.
    """
    logger.info(f"Renaming current program for user {user_id} to: {request.custom_program_name}")

    if not request.custom_program_name or not request.custom_program_name.strip():
        raise HTTPException(status_code=400, detail="Program name cannot be empty")

    try:
        supabase = get_supabase()

        # Find current active program
        current_result = supabase.client.table("user_program_assignments")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .single()\
            .execute()

        if not current_result.data:
            raise HTTPException(status_code=404, detail="No active program found")

        assignment_id = current_result.data["id"]
        old_name = current_result.data["program_name"]

        # Update program name
        now = datetime.utcnow().isoformat()
        update_result = supabase.client.table("user_program_assignments")\
            .update({
                "custom_program_name": request.custom_program_name.strip(),
                "program_name": request.custom_program_name.strip(),
                "updated_at": now,
            })\
            .eq("id", assignment_id)\
            .execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to rename program")

        assignment = update_result.data[0]

        # Log the rename action
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "program_assignment",
                "action": "renamed",
                "old_name": old_name,
                "new_name": request.custom_program_name.strip(),
            },
            context={
                "source": "programs_api",
                "assignment_id": assignment_id,
            }
        )

        logger.info(f"Program renamed for user {user_id}: {old_name} -> {request.custom_program_name}")

        return UserProgramAssignment(
            id=assignment["id"],
            user_id=assignment["user_id"],
            branded_program_id=assignment.get("branded_program_id"),
            custom_program_name=assignment.get("custom_program_name"),
            program_name=assignment["program_name"],
            started_at=assignment["started_at"],
            completed_at=assignment.get("completed_at"),
            is_active=assignment["is_active"],
            week_number=assignment.get("week_number", 1),
            created_at=assignment["created_at"],
            updated_at=assignment["updated_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to rename program: {e}")
        raise safe_internal_error(e, "programs")


@router.patch("/user/{user_id}/complete", response_model=UserProgramAssignment)
async def complete_current_program(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Mark the user's current active program as completed.

    Sets completed_at timestamp and is_active to False.
    """
    logger.info(f"Marking current program as completed for user {user_id}")

    try:
        supabase = get_supabase()

        # Find current active program
        current_result = supabase.client.table("user_program_assignments")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .single()\
            .execute()

        if not current_result.data:
            raise HTTPException(status_code=404, detail="No active program found")

        assignment_id = current_result.data["id"]
        program_name = current_result.data["program_name"]

        # Mark as completed
        now = datetime.utcnow().isoformat()
        update_result = supabase.client.table("user_program_assignments")\
            .update({
                "completed_at": now,
                "is_active": False,
                "updated_at": now,
            })\
            .eq("id", assignment_id)\
            .execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to complete program")

        assignment = update_result.data[0]

        # Log the completion
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "program_assignment",
                "action": "completed",
                "program_name": program_name,
                "branded_program_id": current_result.data.get("branded_program_id"),
                "started_at": current_result.data["started_at"],
                "completed_at": now,
            },
            context={
                "source": "programs_api",
                "assignment_id": assignment_id,
            }
        )

        logger.info(f"Program completed for user {user_id}: {program_name}")

        return UserProgramAssignment(
            id=assignment["id"],
            user_id=assignment["user_id"],
            branded_program_id=assignment.get("branded_program_id"),
            custom_program_name=assignment.get("custom_program_name"),
            program_name=assignment["program_name"],
            started_at=assignment["started_at"],
            completed_at=assignment.get("completed_at"),
            is_active=assignment["is_active"],
            week_number=assignment.get("week_number", 1),
            created_at=assignment["created_at"],
            updated_at=assignment["updated_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete program: {e}")
        raise safe_internal_error(e, "programs")


# =============================================================================
# HELPER ENDPOINTS
# =============================================================================


@router.get("/categories", response_model=List[str])
async def list_program_categories(
    current_user: dict = Depends(get_current_user),
):
    """
    Get list of all program categories.

    Returns distinct categories from branded_programs table.
    """
    logger.info("Fetching program categories")

    try:
        supabase = get_supabase()

        result = supabase.client.table("branded_programs")\
            .select("category")\
            .execute()

        # Get unique categories
        categories = list(set(
            row["category"]
            for row in result.data or []
            if row.get("category")
        ))

        return sorted(categories)

    except Exception as e:
        logger.error(f"Failed to get categories: {e}")
        raise safe_internal_error(e, "programs")


@router.patch("/user/{user_id}/week", response_model=UserProgramAssignment)
async def update_program_week(user_id: str, week_number: int = Query(..., ge=1, description="New week number"),
    current_user: dict = Depends(get_current_user),
):
    """
    Update the current week number for user's active program.

    Used to track progress through multi-week programs.
    """
    logger.info(f"Updating program week for user {user_id} to week {week_number}")

    try:
        supabase = get_supabase()

        # Find current active program
        current_result = supabase.client.table("user_program_assignments")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .single()\
            .execute()

        if not current_result.data:
            raise HTTPException(status_code=404, detail="No active program found")

        assignment_id = current_result.data["id"]

        # Update week number
        now = datetime.utcnow().isoformat()
        update_result = supabase.client.table("user_program_assignments")\
            .update({
                "week_number": week_number,
                "updated_at": now,
            })\
            .eq("id", assignment_id)\
            .execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to update week number")

        assignment = update_result.data[0]

        logger.info(f"Program week updated for user {user_id}: week {week_number}")

        return UserProgramAssignment(
            id=assignment["id"],
            user_id=assignment["user_id"],
            branded_program_id=assignment.get("branded_program_id"),
            custom_program_name=assignment.get("custom_program_name"),
            program_name=assignment["program_name"],
            started_at=assignment["started_at"],
            completed_at=assignment.get("completed_at"),
            is_active=assignment["is_active"],
            week_number=assignment.get("week_number", 1),
            created_at=assignment["created_at"],
            updated_at=assignment["updated_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update program week: {e}")
        raise safe_internal_error(e, "programs")
