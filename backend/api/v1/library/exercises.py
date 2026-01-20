"""
Exercise library API endpoints.

This module handles exercise library operations:
- GET /exercises - List exercises with filters
- GET /exercises/grouped - Get exercises grouped by body part
- GET /exercises/{exercise_id} - Get a single exercise
- GET /exercises/body-parts - Get all body parts
- GET /exercises/equipment - Get all equipment types
- GET /exercises/types - Get all exercise types
- GET /exercises/filter-options - Get all filter options
"""
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, HTTPException, Query

from core.supabase_db import get_supabase_db
from core.logger import get_logger

from .models import LibraryExercise, ExercisesByBodyPart
from .utils import (
    fetch_all_rows,
    fetch_fuzzy_search_results,
    normalize_body_part,
    row_to_library_exercise,
    derive_exercise_type,
    sort_by_relevance,
)

router = APIRouter()
logger = get_logger(__name__)


@router.get("/exercises/filter-options", response_model=Dict[str, Any])
async def get_filter_options():
    """
    Get all available filter options for exercises.
    Returns body parts, equipment types, exercise types, goals, suitable_for, and avoids with counts.
    Now reads from database columns instead of deriving at runtime.
    """
    try:
        db = get_supabase_db()

        # Get all exercises from cleaned view with all needed fields including new columns
        all_rows = await fetch_all_rows(
            db, "exercise_library_cleaned",
            "name, target_muscle, body_part, equipment, video_url, goals, suitable_for, avoid_if"
        )

        # Count dictionaries
        body_part_counts: Dict[str, int] = {}
        equipment_counts: Dict[str, int] = {}
        exercise_type_counts: Dict[str, int] = {}
        goal_counts: Dict[str, int] = {}
        suitable_counts: Dict[str, int] = {}
        avoid_counts: Dict[str, int] = {}

        for row in all_rows:
            bp = normalize_body_part(row.get("target_muscle") or row.get("body_part", ""))
            eq = row.get("equipment", "")
            video_url = row.get("video_url", "")

            # Body part
            body_part_counts[bp] = body_part_counts.get(bp, 0) + 1

            # Equipment (normalize)
            if eq and eq.strip():
                eq_simplified = eq.strip()
                equipment_counts[eq_simplified] = equipment_counts.get(eq_simplified, 0) + 1
            else:
                equipment_counts["Bodyweight"] = equipment_counts.get("Bodyweight", 0) + 1

            # Exercise type (still derived from video path)
            et = derive_exercise_type(video_url, bp)
            exercise_type_counts[et] = exercise_type_counts.get(et, 0) + 1

            # Goals (from database column)
            goals = row.get("goals") or []
            for goal in goals:
                goal_counts[goal] = goal_counts.get(goal, 0) + 1

            # Suitable for (from database column)
            suitable = row.get("suitable_for") or []
            for s in suitable:
                suitable_counts[s] = suitable_counts.get(s, 0) + 1

            # Avoids (from database column)
            avoids = row.get("avoid_if") or []
            for a in avoids:
                avoid_counts[a] = avoid_counts.get(a, 0) + 1

        # Sort each by count
        def sorted_options(counts: Dict[str, int], limit: int = None) -> List[Dict[str, Any]]:
            sorted_list = sorted(
                [{"name": name, "count": count} for name, count in counts.items()],
                key=lambda x: x["count"],
                reverse=True
            )
            return sorted_list[:limit] if limit else sorted_list

        result = {
            "body_parts": sorted_options(body_part_counts),
            "equipment": sorted_options(equipment_counts, limit=20),  # Top 20 equipment
            "exercise_types": sorted_options(exercise_type_counts),
            "goals": sorted_options(goal_counts),
            "suitable_for": sorted_options(suitable_counts),
            "avoid_if": sorted_options(avoid_counts),
            "total_exercises": len(all_rows)
        }

        logger.info(f"Filter options: {len(result['body_parts'])} body parts, {len(result['goals'])} goals, {len(result['suitable_for'])} suitable_for")
        return result

    except Exception as e:
        logger.error(f"Error getting filter options: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/exercises/equipment", response_model=List[Dict[str, Any]])
async def get_equipment_types():
    """
    Get all unique equipment types with exercise counts.
    Returns a list of equipment that can be used for filtering.
    """
    try:
        db = get_supabase_db()

        # Get all exercises from cleaned view
        all_rows = await fetch_all_rows(db, "exercise_library_cleaned", "equipment")

        # Count by equipment
        equipment_counts: Dict[str, int] = {}
        for row in all_rows:
            eq = row.get("equipment")
            if eq and eq.strip():
                equipment_counts[eq] = equipment_counts.get(eq, 0) + 1
            else:
                equipment_counts["Bodyweight"] = equipment_counts.get("Bodyweight", 0) + 1

        # Sort by count descending
        sorted_equipment = sorted(
            [{"name": name, "count": count} for name, count in equipment_counts.items()],
            key=lambda x: x["count"],
            reverse=True
        )

        logger.info(f"Listed {len(sorted_equipment)} equipment types")
        return sorted_equipment

    except Exception as e:
        logger.error(f"Error getting equipment types: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/exercises/types", response_model=List[Dict[str, Any]])
async def get_exercise_types():
    """
    Get all unique exercise types with counts.
    Types are derived from video paths (Yoga, Stretching, Cardio, Strength, etc.)
    """
    try:
        db = get_supabase_db()

        # Get all exercises from cleaned view
        all_rows = await fetch_all_rows(db, "exercise_library_cleaned", "video_url, body_part, target_muscle")

        # Count by derived exercise type
        type_counts: Dict[str, int] = {}
        for row in all_rows:
            bp = normalize_body_part(row.get("target_muscle") or row.get("body_part", ""))
            et = derive_exercise_type(row.get("video_url", ""), bp)
            type_counts[et] = type_counts.get(et, 0) + 1

        # Sort by count descending
        sorted_types = sorted(
            [{"name": name, "count": count} for name, count in type_counts.items()],
            key=lambda x: x["count"],
            reverse=True
        )

        logger.info(f"Listed {len(sorted_types)} exercise types")
        return sorted_types

    except Exception as e:
        logger.error(f"Error getting exercise types: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
    body_parts: Optional[str] = Query(default=None, alias="body_parts", description="Comma-separated body parts (e.g., 'Chest,Back')"),
    equipment: Optional[str] = Query(default=None, description="Comma-separated equipment (e.g., 'Dumbbells,Barbell')"),
    exercise_types: Optional[str] = Query(default=None, alias="exercise_types", description="Comma-separated types (e.g., 'Strength,Cardio')"),
    difficulty: Optional[int] = None,
    search: Optional[str] = None,
    goals: Optional[str] = Query(default=None, alias="goals", description="Comma-separated goals (e.g., 'Fat Burn,Muscle Building')"),
    suitable_for: Optional[str] = Query(default=None, description="Comma-separated suitability (e.g., 'Beginner Friendly,Low Impact')"),
    avoid_if: Optional[str] = Query(default=None, description="Comma-separated avoid conditions (e.g., 'Stresses Knees,High Impact')"),
    limit: int = Query(default=2000, ge=1, le=5000),
    offset: int = Query(default=0, ge=0),
):
    """
    List exercises from the exercise library with optional filters.
    Uses deduplicated view (exercise_library_cleaned) to avoid male/female duplicates.

    All filter parameters support comma-separated values for multi-select (OR logic within each filter).
    Multiple filters are combined with AND logic.

    - body_parts: Filter by body parts, comma-separated (e.g., "Chest,Back,Legs")
    - equipment: Filter by equipment types, comma-separated (e.g., "Dumbbells,Bodyweight")
    - exercise_types: Filter by exercise types, comma-separated (e.g., "Strength,Yoga,Cardio")
    - difficulty: Filter by difficulty level (1-5)
    - search: Search by exercise name (cleaned name)
    - goals: Filter by fitness goals, comma-separated (e.g., "Testosterone Boost,Fat Burn")
    - suitable_for: Filter by suitability, comma-separated (e.g., "Beginner Friendly,Pregnancy Safe")
    - avoid_if: EXCLUDE exercises that stress certain areas, comma-separated (e.g., "Stresses Knees,High Impact")
    """
    try:
        db = get_supabase_db()

        # Parse comma-separated filter values into lists
        body_parts_list = [bp.strip() for bp in body_parts.split(",")] if body_parts else []
        equipment_list = [eq.strip() for eq in equipment.split(",")] if equipment else []
        exercise_types_list = [et.strip() for et in exercise_types.split(",")] if exercise_types else []
        goals_list = [g.strip() for g in goals.split(",")] if goals else []
        suitable_for_list = [sf.strip() for sf in suitable_for.split(",")] if suitable_for else []
        avoid_if_list = [ai.strip() for ai in avoid_if.split(",")] if avoid_if else []

        # Determine if we need post-filtering (filters that can't be done at DB level)
        needs_post_filter = bool(body_parts_list or len(equipment_list) > 1 or
                                  exercise_types_list or goals_list or
                                  suitable_for_list or avoid_if_list)

        # If post-filtering is needed, we must fetch ALL matching rows first,
        # then filter, then apply limit/offset. Otherwise filters would be
        # applied to a limited subset and miss results.
        if needs_post_filter:
            # Fetch all rows (with DB-level filters only)
            all_rows = await fetch_all_rows(
                db, "exercise_library_cleaned", "*",
                equipment_filter=equipment_list[0] if len(equipment_list) == 1 else None,
                difficulty_filter=difficulty,
                search_filter=search
            )
        else:
            # No post-filtering needed, can use limit/offset at DB level
            page_size = 1000
            all_rows = []
            current_offset = offset

            while len(all_rows) < limit:
                # Build query using cleaned/deduplicated view
                query = db.client.table("exercise_library_cleaned").select("*")

                # Equipment filter - handled at query level for single value
                if len(equipment_list) == 1:
                    query = query.ilike("equipment", f"%{equipment_list[0]}%")
                if difficulty:
                    query = query.eq("difficulty_level", difficulty)
                if search:
                    query = query.or_(f"name.ilike.%{search}%,original_name.ilike.%{search}%")

                # Calculate how many rows we still need
                rows_needed = min(page_size, limit - len(all_rows))

                # Execute query with pagination
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
        exercises = [row_to_library_exercise(row, from_cleaned_view=True) for row in all_rows]

        # Apply relevance sorting when searching (before other filters)
        # NOTE: If using fuzzy search (default), results are already sorted by similarity
        # from the database RPC function. Only apply Python sorting for non-fuzzy fallback.
        # The fuzzy search handles: exact match > prefix match > substring > similarity score
        if search and not needs_post_filter:
            # When fuzzy search was used, results are already well-sorted
            # Only apply Python sort if we fetched without fuzzy search
            pass
        elif search:
            exercises = sort_by_relevance(exercises, search)

        # Apply post-filters
        # Filter by body parts (OR logic - match ANY of the selected body parts)
        if body_parts_list:
            body_parts_lower = [bp.lower() for bp in body_parts_list]
            exercises = [e for e in exercises if e.body_part.lower() in body_parts_lower]

        # Filter by equipment (OR logic - match ANY of the selected equipment)
        if len(equipment_list) > 1:
            equipment_lower = [eq.lower() for eq in equipment_list]
            exercises = [e for e in exercises if any(
                eq in (e.equipment or "").lower() for eq in equipment_lower
            )]

        # Filter by exercise types (OR logic - match ANY of the selected types)
        if exercise_types_list:
            types_lower = [et.lower() for et in exercise_types_list]
            def matches_any_type(ex: LibraryExercise) -> bool:
                derived_type = derive_exercise_type(ex.video_url or "", ex.body_part)
                return derived_type.lower() in types_lower
            exercises = [e for e in exercises if matches_any_type(e)]

        # Filter by goals (OR logic - match ANY of the selected goals)
        if goals_list:
            exercises = [e for e in exercises if e.goals and any(g in e.goals for g in goals_list)]

        # Filter by suitable_for (OR logic - match ANY of the selected suitability)
        if suitable_for_list:
            exercises = [e for e in exercises if e.suitable_for and any(sf in e.suitable_for for sf in suitable_for_list)]

        # Filter by avoid_if - EXCLUDE exercises that match ANY of the avoid conditions
        if avoid_if_list:
            exercises = [e for e in exercises if not (e.avoid_if and any(ai in e.avoid_if for ai in avoid_if_list))]

        # Apply offset and limit AFTER filtering
        if needs_post_filter:
            exercises = exercises[offset:offset + limit]

        logger.info(f"Listed {len(exercises)} exercises (body_parts={body_parts_list}, equipment={equipment_list}, types={exercise_types_list}, goals={goals_list}, suitable_for={suitable_for_list}, avoid_if={avoid_if_list})")
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
