"""
Program library API endpoints.

This module handles program library operations:
- GET /programs - List programs with filters
- GET /programs/grouped - Get programs grouped by category
- GET /programs/{program_id} - Get a single program
- GET /programs/categories - Get all program categories
"""
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, HTTPException, Query

from core.supabase_db import get_supabase_db
from core.logger import get_logger

from .models import LibraryProgram, ProgramsByCategory
from .utils import row_to_library_program

router = APIRouter()
logger = get_logger(__name__)


@router.get("/programs/categories", response_model=List[Dict[str, Any]])
async def get_program_categories():
    """
    Get all unique program categories with counts.
    Returns a list of categories that can be used for filtering.
    """
    try:
        db = get_supabase_db()

        # Get all programs
        result = db.client.table("programs").select("program_category").execute()

        # Count by category
        category_counts: Dict[str, int] = {}
        for row in result.data:
            cat = row.get("program_category", "Other")
            category_counts[cat] = category_counts.get(cat, 0) + 1

        # Sort by count descending
        sorted_cats = sorted(
            [{"name": name, "count": count} for name, count in category_counts.items()],
            key=lambda x: x["count"],
            reverse=True
        )

        logger.info(f"Listed {len(sorted_cats)} program categories")
        return sorted_cats

    except Exception as e:
        logger.error(f"Error getting program categories: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/programs", response_model=List[LibraryProgram])
async def list_programs(
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """
    List programs from the library with optional filters.

    - category: Filter by program category (e.g., "Celebrity Workout", "Goal-Based")
    - difficulty: Filter by difficulty level (e.g., "Beginner", "Intermediate")
    - search: Search by program name
    """
    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("programs").select("*")

        if category:
            query = query.eq("program_category", category)
        if difficulty:
            query = query.ilike("difficulty_level", f"%{difficulty}%")
        if search:
            query = query.ilike("program_name", f"%{search}%")

        # Execute query
        result = query.order("program_name").range(offset, offset + limit - 1).execute()

        programs = [row_to_library_program(row) for row in result.data]

        logger.info(f"Listed {len(programs)} programs (category={category}, difficulty={difficulty})")
        return programs

    except Exception as e:
        logger.error(f"Error listing programs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/programs/grouped", response_model=List[ProgramsByCategory])
async def get_programs_grouped(
    limit_per_group: int = Query(default=10, ge=1, le=50),
):
    """
    Get programs grouped by category.
    Returns a limited number of programs per group for browsing.
    """
    try:
        db = get_supabase_db()

        # Get all programs
        result = db.client.table("programs").select("*").execute()

        # Group by category
        groups: Dict[str, List[LibraryProgram]] = {}
        for row in result.data:
            program = row_to_library_program(row)
            cat = program.category or "Other"
            if cat not in groups:
                groups[cat] = []
            groups[cat].append(program)

        # Create response with limited programs per group
        grouped = []
        for category, programs in sorted(groups.items()):
            # Sort by name and limit
            programs_sorted = sorted(programs, key=lambda x: x.name)[:limit_per_group]
            grouped.append(ProgramsByCategory(
                category=category,
                count=len(programs),
                programs=programs_sorted
            ))

        # Sort by count descending
        grouped.sort(key=lambda x: x.count, reverse=True)

        logger.info(f"Listed programs in {len(grouped)} category groups")
        return grouped

    except Exception as e:
        logger.error(f"Error getting grouped programs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/programs/{program_id}", response_model=Dict[str, Any])
async def get_program(program_id: str):
    """Get a single program by ID with full details including workouts."""
    try:
        db = get_supabase_db()

        result = db.client.table("programs").select("*").eq("id", program_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Program not found")

        row = result.data[0]

        # Return full program data including workouts
        return {
            "id": row.get("id"),
            "name": row.get("program_name"),
            "category": row.get("program_category"),
            "subcategory": row.get("program_subcategory"),
            "difficulty_level": row.get("difficulty_level"),
            "duration_weeks": row.get("duration_weeks"),
            "sessions_per_week": row.get("sessions_per_week"),
            "session_duration_minutes": row.get("session_duration_minutes"),
            "tags": row.get("tags"),
            "goals": row.get("goals"),
            "description": row.get("description"),
            "short_description": row.get("short_description"),
            "celebrity_name": row.get("celebrity_name"),
            "workouts": row.get("workouts"),  # Include full workouts data
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting program {program_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
