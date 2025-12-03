"""
Library API endpoints for browsing exercises and programs.

ENDPOINTS:
- GET /api/v1/library/exercises - List exercises with body part grouping
- GET /api/v1/library/exercises/body-parts - Get all unique body parts
- GET /api/v1/library/exercises/{id} - Get exercise details
- GET /api/v1/library/programs - List programs with category filtering
- GET /api/v1/library/programs/categories - Get all unique program categories
- GET /api/v1/library/programs/{id} - Get program details
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


# ==================== Response Models ====================

class LibraryExercise(BaseModel):
    """Exercise from the library."""
    id: str  # UUID in database
    name: str  # Cleaned name (Title Case, no gender suffix)
    original_name: str  # Original name (for video lookup)
    body_part: str
    equipment: Optional[str] = None  # Can be null in database
    target_muscle: Optional[str] = None
    secondary_muscles: Optional[str] = None
    instructions: Optional[str] = None
    difficulty_level: Optional[int] = None
    category: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None


class LibraryProgram(BaseModel):
    """Program from the library."""
    id: str  # UUID in database
    name: str
    category: str
    subcategory: Optional[str] = None
    difficulty_level: Optional[str] = None
    duration_weeks: Optional[int] = None
    sessions_per_week: Optional[int] = None
    session_duration_minutes: Optional[int] = None
    tags: Optional[List[str]] = None
    goals: Optional[List[str]] = None
    description: Optional[str] = None
    short_description: Optional[str] = None
    celebrity_name: Optional[str] = None


class ExercisesByBodyPart(BaseModel):
    """Exercises grouped by body part."""
    body_part: str
    count: int
    exercises: List[LibraryExercise]


class ProgramsByCategory(BaseModel):
    """Programs grouped by category."""
    category: str
    count: int
    programs: List[LibraryProgram]


# ==================== Helper Functions ====================

async def fetch_all_rows(db, table_name: str, select_columns: str = "*", order_by: str = None):
    """
    Fetch all rows from a Supabase table, handling the 1000 row limit.
    Uses pagination to get all results.
    """
    all_rows = []
    page_size = 1000
    offset = 0

    while True:
        query = db.client.table(table_name).select(select_columns)
        if order_by:
            query = query.order(order_by)
        result = query.range(offset, offset + page_size - 1).execute()

        if not result.data:
            break

        all_rows.extend(result.data)

        if len(result.data) < page_size:
            break

        offset += page_size

    return all_rows


def normalize_body_part(target_muscle: str) -> str:
    """
    Normalize target_muscle to a simple body part category.
    The exercise_library has very detailed target_muscle values.
    We want to group them into broader categories.
    """
    if not target_muscle:
        return "Other"

    target_lower = target_muscle.lower()

    # Map to broader categories
    if any(x in target_lower for x in ["chest", "pectoralis"]):
        return "Chest"
    elif any(x in target_lower for x in ["back", "latissimus", "rhomboid", "trapezius"]):
        return "Back"
    elif any(x in target_lower for x in ["shoulder", "deltoid"]):
        return "Shoulders"
    elif any(x in target_lower for x in ["bicep", "brachii"]):
        return "Biceps"
    elif any(x in target_lower for x in ["tricep"]):
        return "Triceps"
    elif any(x in target_lower for x in ["forearm", "wrist"]):
        return "Forearms"
    elif any(x in target_lower for x in ["quad", "thigh"]):
        return "Quadriceps"
    elif any(x in target_lower for x in ["hamstring"]):
        return "Hamstrings"
    elif any(x in target_lower for x in ["glute"]):
        return "Glutes"
    elif any(x in target_lower for x in ["calf", "gastrocnemius", "soleus"]):
        return "Calves"
    elif any(x in target_lower for x in ["abdominal", "rectus abdominis", "core", "oblique"]):
        return "Core"
    elif any(x in target_lower for x in ["lower back", "erector"]):
        return "Lower Back"
    elif any(x in target_lower for x in ["hip", "adduct", "abduct"]):
        return "Hips"
    elif any(x in target_lower for x in ["neck"]):
        return "Neck"
    else:
        return "Other"


def row_to_library_exercise(row: dict, from_cleaned_view: bool = True) -> LibraryExercise:
    """Convert a Supabase row to LibraryExercise model.

    Args:
        row: Database row
        from_cleaned_view: True if row is from exercise_library_cleaned view,
                          False if from base exercise_library table

    View columns: id, name, original_name, body_part, equipment, target_muscle,
                  secondary_muscles, instructions, difficulty_level, category,
                  gif_url, video_url
    """
    if from_cleaned_view:
        # From cleaned view - uses 'name' and 'original_name' columns
        return LibraryExercise(
            id=row.get("id"),
            name=row.get("name", ""),
            original_name=row.get("original_name", ""),
            body_part=normalize_body_part(row.get("target_muscle") or row.get("body_part", "")),
            equipment=row.get("equipment", ""),
            target_muscle=row.get("target_muscle"),
            secondary_muscles=row.get("secondary_muscles"),
            instructions=row.get("instructions"),
            difficulty_level=row.get("difficulty_level"),
            category=row.get("category"),
            gif_url=row.get("gif_url"),
            video_url=row.get("video_url"),
        )
    else:
        # From base table - clean name manually
        original_name = row.get("exercise_name", "")
        import re
        cleaned_name = re.sub(r'_(Female|Male|female|male)$', '', original_name).strip()
        return LibraryExercise(
            id=row.get("id"),
            name=cleaned_name,
            original_name=original_name,
            body_part=normalize_body_part(row.get("target_muscle") or row.get("body_part", "")),
            equipment=row.get("equipment", ""),
            target_muscle=row.get("target_muscle"),
            secondary_muscles=row.get("secondary_muscles"),
            instructions=row.get("instructions"),
            difficulty_level=row.get("difficulty_level"),
            category=row.get("category"),
            gif_url=row.get("gif_url"),
            video_url=row.get("video_s3_path"),
        )


def row_to_library_program(row: dict) -> LibraryProgram:
    """Convert a Supabase row to LibraryProgram model."""
    return LibraryProgram(
        id=row.get("id"),
        name=row.get("program_name", ""),
        category=row.get("program_category", ""),
        subcategory=row.get("program_subcategory"),
        difficulty_level=row.get("difficulty_level"),
        duration_weeks=row.get("duration_weeks"),
        sessions_per_week=row.get("sessions_per_week"),
        session_duration_minutes=row.get("session_duration_minutes"),
        tags=row.get("tags") if isinstance(row.get("tags"), list) else [],
        goals=row.get("goals") if isinstance(row.get("goals"), list) else [],
        description=row.get("description"),
        short_description=row.get("short_description"),
        celebrity_name=row.get("celebrity_name"),
    )


# ==================== Exercise Endpoints ====================

@router.get("/exercises/body-parts", response_model=List[Dict[str, Any]])
async def get_body_parts():
    """
    Get all unique body parts with exercise counts.
    Returns a list of body parts that can be used for filtering.
    Uses the cleaned/deduplicated view.
    """
    try:
        db = get_supabase_db()

        # Get all exercises from cleaned view (deduplicated) using pagination
        all_rows = await fetch_all_rows(db, "exercise_library_cleaned", "target_muscle, body_part")

        # Count by normalized body part
        body_part_counts: Dict[str, int] = {}
        for row in all_rows:
            bp = normalize_body_part(row.get("target_muscle") or row.get("body_part", ""))
            body_part_counts[bp] = body_part_counts.get(bp, 0) + 1

        # Sort by count descending
        sorted_parts = sorted(
            [{"name": name, "count": count} for name, count in body_part_counts.items()],
            key=lambda x: x["count"],
            reverse=True
        )

        logger.info(f"Listed {len(sorted_parts)} body parts (total: {sum(bp['count'] for bp in sorted_parts)} exercises)")
        return sorted_parts

    except Exception as e:
        logger.error(f"Error getting body parts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/exercises", response_model=List[LibraryExercise])
async def list_exercises(
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    difficulty: Optional[int] = None,
    search: Optional[str] = None,
    limit: int = Query(default=2000, ge=1, le=5000),
    offset: int = Query(default=0, ge=0),
):
    """
    List exercises from the exercise library with optional filters.
    Uses deduplicated view (exercise_library_cleaned) to avoid male/female duplicates.

    - body_part: Filter by body part (e.g., "Chest", "Back", "Legs")
    - equipment: Filter by equipment type
    - difficulty: Filter by difficulty level (1-5)
    - search: Search by exercise name (cleaned name)
    """
    try:
        db = get_supabase_db()

        # For large limits, use pagination to bypass Supabase 1000 row limit
        page_size = 1000
        all_rows = []
        current_offset = offset

        while len(all_rows) < limit:
            # Build query using cleaned/deduplicated view
            query = db.client.table("exercise_library_cleaned").select("*")

            if equipment:
                query = query.ilike("equipment", f"%{equipment}%")
            if difficulty:
                query = query.eq("difficulty_level", difficulty)
            if search:
                # Search in both cleaned name and original name
                # Note: The view uses 'name' and 'original_name' columns
                query = query.or_(f"name.ilike.%{search}%,original_name.ilike.%{search}%")

            # Calculate how many rows we still need
            rows_needed = min(page_size, limit - len(all_rows))

            # Execute query with pagination
            # Note: The view uses 'name' column, not 'exercise_name_cleaned'
            result = query.order("name").range(
                current_offset, current_offset + rows_needed - 1
            ).execute()

            if not result.data:
                break

            all_rows.extend(result.data)

            if len(result.data) < rows_needed:
                break  # No more rows available

            current_offset += rows_needed

        # Convert to exercises (from cleaned view)
        # View already handles deduplication and name cleaning
        exercises = [row_to_library_exercise(row, from_cleaned_view=True) for row in all_rows]

        # Filter by normalized body part if specified
        if body_part:
            exercises = [e for e in exercises if e.body_part.lower() == body_part.lower()]

        logger.info(f"Listed {len(exercises)} exercises (body_part={body_part}, equipment={equipment}, deduplicated from {len(all_rows)})")
        return exercises

    except Exception as e:
        logger.error(f"Error listing exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/exercises/grouped", response_model=List[ExercisesByBodyPart])
async def get_exercises_grouped(
    limit_per_group: int = Query(default=10, ge=1, le=50),
):
    """
    Get exercises grouped by body part.
    Returns a limited number of exercises per group for browsing.
    Uses deduplicated view to avoid male/female duplicates.
    """
    try:
        db = get_supabase_db()

        # Get all exercises from cleaned/deduplicated view using pagination
        all_rows = await fetch_all_rows(db, "exercise_library_cleaned")

        # Group by normalized body part
        groups: Dict[str, List[LibraryExercise]] = {}
        for row in all_rows:
            exercise = row_to_library_exercise(row, from_cleaned_view=True)
            bp = exercise.body_part
            if bp not in groups:
                groups[bp] = []
            groups[bp].append(exercise)

        # Create response with limited exercises per group
        grouped = []
        for body_part, exercises in sorted(groups.items()):
            # Sort by name and limit
            exercises_sorted = sorted(exercises, key=lambda x: x.name)[:limit_per_group]
            grouped.append(ExercisesByBodyPart(
                body_part=body_part,
                count=len(exercises),
                exercises=exercises_sorted
            ))

        # Sort by count descending
        grouped.sort(key=lambda x: x.count, reverse=True)

        logger.info(f"Listed exercises in {len(grouped)} body part groups")
        return grouped

    except Exception as e:
        logger.error(f"Error getting grouped exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/exercises/{exercise_id}", response_model=LibraryExercise)
async def get_exercise(exercise_id: str):
    """Get a single exercise by ID with full details.
    Tries cleaned view first, falls back to base table.
    """
    try:
        db = get_supabase_db()

        # Try cleaned view first (has deduplicated exercises)
        result = db.client.table("exercise_library_cleaned").select("*").eq("id", exercise_id).execute()

        if result.data:
            return row_to_library_exercise(result.data[0], from_cleaned_view=True)

        # Fall back to base table (for exercises not in cleaned view)
        result = db.client.table("exercise_library").select("*").eq("id", exercise_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return row_to_library_exercise(result.data[0], from_cleaned_view=False)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting exercise {exercise_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Program Endpoints ====================

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
