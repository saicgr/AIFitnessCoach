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
    goals: Optional[List[str]] = None  # Derived fitness goals
    suitable_for: Optional[List[str]] = None  # Suitability categories
    avoid_if: Optional[List[str]] = None  # Injury considerations


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
                  gif_url, video_url, goals, suitable_for, avoid_if
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
            goals=row.get("goals", []),
            suitable_for=row.get("suitable_for", []),
            avoid_if=row.get("avoid_if", []),
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
            goals=row.get("goals", []),
            suitable_for=row.get("suitable_for", []),
            avoid_if=row.get("avoid_if", []),
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


# ==================== Filter Option Endpoints ====================

def derive_exercise_type(video_url: str, body_part: str) -> str:
    """
    Derive exercise type from video path folder or body part.
    Video paths look like: s3://ai-fitness-coach/VERTICAL VIDEOS/Yoga/...
    """
    if not video_url:
        # Fallback based on body part
        if body_part and body_part.lower() in ['core', 'other']:
            return 'Functional'
        return 'Strength'

    video_lower = video_url.lower()

    # Check video path for exercise type indicators
    if 'yoga' in video_lower:
        return 'Yoga'
    elif 'stretch' in video_lower or 'mobility' in video_lower:
        return 'Stretching'
    elif 'hiit' in video_lower or 'cardio' in video_lower:
        return 'Cardio'
    elif 'calisthenics' in video_lower or 'functional' in video_lower:
        return 'Functional'
    elif 'abdominals' in video_lower or 'abs' in video_lower:
        return 'Core'
    elif any(x in video_lower for x in ['chest', 'back', 'shoulders', 'arms', 'legs', 'bicep', 'tricep']):
        return 'Strength'
    else:
        return 'Strength'


def derive_goals(name: str, body_part: str, target_muscle: str, video_url: str) -> List[str]:
    """
    Derive fitness goals this exercise supports based on name, muscles, and type.
    """
    goals = []
    name_lower = name.lower() if name else ""
    bp_lower = body_part.lower() if body_part else ""
    tm_lower = target_muscle.lower() if target_muscle else ""
    video_lower = video_url.lower() if video_url else ""

    # Testosterone boosting - compound movements targeting large muscle groups
    testosterone_keywords = ['squat', 'deadlift', 'bench press', 'row', 'pull-up', 'pullup',
                           'lunge', 'leg press', 'hip thrust', 'clean', 'snatch']
    if any(kw in name_lower for kw in testosterone_keywords) or bp_lower in ['quadriceps', 'glutes', 'back', 'chest']:
        goals.append('Testosterone Boost')

    # Weight loss / Fat burn - high intensity, cardio, full body
    fat_burn_keywords = ['jump', 'burpee', 'hiit', 'cardio', 'mountain climber', 'plank jack',
                        'high knee', 'sprint', 'skater', 'squat jump', 'box jump']
    if any(kw in name_lower for kw in fat_burn_keywords) or 'cardio' in video_lower or 'hiit' in video_lower:
        goals.append('Fat Burn')

    # Muscle building - strength exercises with weights
    muscle_keywords = ['press', 'curl', 'extension', 'row', 'fly', 'raise', 'pulldown', 'dip']
    if any(kw in name_lower for kw in muscle_keywords):
        goals.append('Muscle Building')

    # Flexibility - yoga, stretching
    flex_keywords = ['stretch', 'yoga', 'pose', 'flexibility', 'mobility', 'pigeon', 'cobra']
    if any(kw in name_lower for kw in flex_keywords) or 'yoga' in video_lower or 'stretch' in video_lower:
        goals.append('Flexibility')

    # Core strength
    core_keywords = ['crunch', 'plank', 'sit-up', 'ab ', 'core', 'twist', 'russian', 'hollow']
    if any(kw in name_lower for kw in core_keywords) or bp_lower == 'core':
        goals.append('Core Strength')

    # Pelvic floor / Hip health
    pelvic_keywords = ['kegel', 'pelvic', 'hip', 'glute bridge', 'clamshell', 'bird dog', 'dead bug']
    if any(kw in name_lower for kw in pelvic_keywords) or bp_lower in ['hips', 'glutes']:
        goals.append('Pelvic Health')

    # Posture improvement
    posture_keywords = ['face pull', 'reverse fly', 'row', 'scapula', 'thoracic', 'cat cow', 'superman']
    if any(kw in name_lower for kw in posture_keywords) or 'back' in bp_lower:
        goals.append('Posture')

    return goals if goals else ['General Fitness']


def derive_suitable_for(name: str, body_part: str, equipment: str, video_url: str) -> List[str]:
    """
    Derive who this exercise is suitable for based on intensity and requirements.
    """
    suitable = []
    name_lower = name.lower() if name else ""
    bp_lower = body_part.lower() if body_part else ""
    eq_lower = equipment.lower() if equipment else ""
    video_lower = video_url.lower() if video_url else ""

    # Beginner friendly - bodyweight, simple movements
    beginner_safe = ['wall', 'assisted', 'modified', 'seated', 'lying', 'supported']
    high_impact = ['jump', 'burpee', 'box jump', 'plyometric', 'sprint', 'snatch', 'clean']

    is_bodyweight = not equipment or 'bodyweight' in eq_lower or eq_lower == ''
    is_high_impact = any(kw in name_lower for kw in high_impact)
    is_beginner_mod = any(kw in name_lower for kw in beginner_safe)

    if (is_bodyweight and not is_high_impact) or is_beginner_mod:
        suitable.append('Beginner Friendly')

    # Senior friendly - low impact, seated, stability focused
    senior_safe = ['chair', 'seated', 'wall', 'balance', 'standing', 'stretch', 'yoga']
    if any(kw in name_lower for kw in senior_safe) and not is_high_impact:
        suitable.append('Senior Friendly')

    # Pregnancy safe - no lying flat, no high impact, no heavy abs
    pregnancy_unsafe = ['crunch', 'sit-up', 'lying leg raise', 'plank', 'burpee', 'jump',
                       'heavy', 'deadlift', 'v-up', 'twist']
    pregnancy_safe = ['cat cow', 'bird dog', 'kegel', 'pelvic tilt', 'wall sit',
                     'seated', 'standing', 'arm', 'shoulder']
    if any(kw in name_lower for kw in pregnancy_safe) and not any(kw in name_lower for kw in pregnancy_unsafe):
        suitable.append('Pregnancy Safe')

    # Low impact - good for joint issues
    if not is_high_impact and ('stretch' in video_lower or 'yoga' in video_lower or is_bodyweight):
        suitable.append('Low Impact')

    # Home workout friendly
    home_equipment = ['bodyweight', 'dumbbell', 'resistance band', 'yoga mat', 'chair', '']
    if not equipment or any(eq in eq_lower for eq in home_equipment):
        suitable.append('Home Workout')

    return suitable if suitable else ['Gym']


def derive_avoids(name: str, body_part: str, equipment: str) -> List[str]:
    """
    Derive what body parts/conditions this exercise might stress.
    Helps users with injuries filter out exercises.
    """
    avoids = []
    name_lower = name.lower() if name else ""
    bp_lower = body_part.lower() if body_part else ""

    # Exercises that stress the knees
    knee_stress = ['squat', 'lunge', 'leg press', 'leg extension', 'jump', 'step-up', 'pistol']
    if any(kw in name_lower for kw in knee_stress) or bp_lower in ['quadriceps', 'glutes']:
        avoids.append('Stresses Knees')

    # Exercises that stress the lower back
    back_stress = ['deadlift', 'bent over', 'good morning', 'hyperextension', 'row', 'clean', 'snatch']
    if any(kw in name_lower for kw in back_stress):
        avoids.append('Stresses Lower Back')

    # Exercises that stress shoulders
    shoulder_stress = ['overhead', 'press', 'raise', 'pull-up', 'dip', 'push-up', 'fly']
    if any(kw in name_lower for kw in shoulder_stress) or bp_lower == 'shoulders':
        avoids.append('Stresses Shoulders')

    # Exercises that stress wrists
    wrist_stress = ['push-up', 'plank', 'handstand', 'front rack', 'wrist']
    if any(kw in name_lower for kw in wrist_stress):
        avoids.append('Stresses Wrists')

    # High impact on joints
    high_impact = ['jump', 'burpee', 'box jump', 'plyometric', 'sprint', 'running']
    if any(kw in name_lower for kw in high_impact):
        avoids.append('High Impact')

    return avoids


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
    exercise_type: Optional[str] = None,
    difficulty: Optional[int] = None,
    search: Optional[str] = None,
    goal: Optional[str] = None,
    suitable_for: Optional[str] = None,
    avoid_if: Optional[str] = None,
    limit: int = Query(default=2000, ge=1, le=5000),
    offset: int = Query(default=0, ge=0),
):
    """
    List exercises from the exercise library with optional filters.
    Uses deduplicated view (exercise_library_cleaned) to avoid male/female duplicates.

    - body_part: Filter by body part (e.g., "Chest", "Back", "Legs")
    - equipment: Filter by equipment type (e.g., "Dumbbells", "Bodyweight")
    - exercise_type: Filter by exercise type (e.g., "Strength", "Yoga", "Stretching", "Cardio")
    - difficulty: Filter by difficulty level (1-5)
    - search: Search by exercise name (cleaned name)
    - goal: Filter by fitness goal (e.g., "Testosterone Boost", "Fat Burn", "Muscle Building")
    - suitable_for: Filter by suitability (e.g., "Beginner Friendly", "Pregnancy Safe", "Low Impact")
    - avoid_if: EXCLUDE exercises that stress certain areas (e.g., "Stresses Knees", "High Impact")
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

        # Filter by exercise type (derived from video path)
        if exercise_type:
            def matches_type(ex: LibraryExercise) -> bool:
                derived_type = derive_exercise_type(ex.video_url or "", ex.body_part)
                return derived_type.lower() == exercise_type.lower()
            exercises = [e for e in exercises if matches_type(e)]

        # Filter by goal (from database column)
        if goal:
            exercises = [e for e in exercises if e.goals and goal in e.goals]

        # Filter by suitable_for (from database column)
        if suitable_for:
            exercises = [e for e in exercises if e.suitable_for and suitable_for in e.suitable_for]

        # Filter by avoid_if - EXCLUDE exercises that stress certain body parts
        # This is a negative filter - we exclude exercises that match
        if avoid_if:
            exercises = [e for e in exercises if not (e.avoid_if and avoid_if in e.avoid_if)]

        logger.info(f"Listed {len(exercises)} exercises (body_part={body_part}, equipment={equipment}, type={exercise_type}, goal={goal}, suitable_for={suitable_for}, avoid_if={avoid_if})")
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
