"""
Library utility functions.

This module contains helper functions for the library API:
- Database pagination
- Body part normalization
- Row conversion functions
- Goal/suitability derivation
"""
import re
from typing import List, Dict, Any, Optional

from core.supabase_db import get_supabase_db
from .models import LibraryExercise, LibraryProgram


async def fetch_all_rows(
    db,
    table_name: str,
    select_columns: str = "*",
    order_by: str = None,
    equipment_filter: str = None,
    difficulty_filter: int = None,
    search_filter: str = None,
    use_fuzzy_search: bool = True
) -> List[Dict[str, Any]]:
    """
    Fetch all rows from a Supabase table, handling the 1000 row limit.
    Uses pagination to get all results.
    Optionally applies DB-level filters before fetching.

    Args:
        use_fuzzy_search: If True and search_filter is provided, uses fuzzy search
                         via pg_trgm for typo tolerance (e.g., "benchpress" -> "Bench Press")
    """
    # If fuzzy search is enabled and we have a search filter, use RPC function
    if search_filter and use_fuzzy_search:
        return await fetch_fuzzy_search_results(
            db, search_filter,
            equipment_filter=equipment_filter,
            limit=2000  # Return up to 2000 fuzzy results
        )

    all_rows = []
    page_size = 1000
    offset = 0

    while True:
        query = db.client.table(table_name).select(select_columns)

        # Apply optional DB-level filters
        if equipment_filter:
            query = query.ilike("equipment", f"%{equipment_filter}%")
        if difficulty_filter:
            query = query.eq("difficulty_level", difficulty_filter)
        if search_filter:
            # Fallback to ILIKE if fuzzy search disabled
            query = query.or_(f"name.ilike.%{search_filter}%,original_name.ilike.%{search_filter}%")

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


async def fetch_fuzzy_search_results(
    db,
    search_term: str,
    equipment_filter: str = None,
    body_part_filter: str = None,
    limit: int = 50
) -> List[Dict[str, Any]]:
    """
    Fetch exercises using fuzzy/trigram search for typo tolerance.
    Uses the fuzzy_search_exercises_api RPC function.

    Examples:
    - "benchpress" -> finds "Bench Press"
    - "bicep curl" -> finds "Barbell Curl", "Dumbbell Curl", etc.
    - "pusup" -> finds "Push Up", "Push-Up Variations"
    """
    from core.logger import get_logger
    logger = get_logger(__name__)

    try:
        # Call the RPC function for fuzzy search
        result = db.client.rpc(
            'fuzzy_search_exercises_api',
            {
                'search_term': search_term,
                'equipment_filter': equipment_filter,
                'body_part_filter': body_part_filter,
                'limit_count': limit
            }
        ).execute()

        if result.data:
            logger.info(f"Fuzzy search for '{search_term}' returned {len(result.data)} results")
            return result.data
        else:
            logger.info(f"Fuzzy search for '{search_term}' returned no results")
            return []

    except Exception as e:
        logger.warning(f"Fuzzy search RPC failed, falling back to ILIKE: {e}")
        # Fallback to regular ILIKE search if fuzzy function not available
        query = db.client.table("exercise_library_cleaned").select("*")
        query = query.or_(f"name.ilike.%{search_term}%,original_name.ilike.%{search_term}%,equipment.ilike.%{search_term}%")
        if equipment_filter:
            query = query.ilike("equipment", f"%{equipment_filter}%")
        result = query.limit(limit).execute()
        return result.data if result.data else []


def sort_by_relevance(exercises: List['LibraryExercise'], search_query: str) -> List['LibraryExercise']:
    """
    Sort exercises by relevance to the search query.

    Ranking priority:
    1. Exact match (case-insensitive) - highest priority
    2. Name starts with search query
    3. Name contains search as a complete word
    4. Other matches - alphabetical

    This ensures "Push Up" appears before "Incline Push Up" when searching "push up".
    """
    if not search_query:
        return exercises

    search_lower = search_query.lower().strip()

    def relevance_score(exercise: 'LibraryExercise') -> tuple:
        name_lower = (exercise.name or "").lower()

        # Tier 1: Exact match (score 0)
        if name_lower == search_lower:
            return (0, name_lower)

        # Tier 2: Name starts with search query (score 1)
        if name_lower.startswith(search_lower):
            return (1, name_lower)

        # Tier 3: Search is a complete word in the name (score 2)
        # e.g., "Push Up" contains "push up" as complete words
        import re
        pattern = r'\b' + re.escape(search_lower) + r'\b'
        if re.search(pattern, name_lower):
            return (2, name_lower)

        # Tier 4: Partial match (score 3)
        if search_lower in name_lower:
            return (3, name_lower)

        # Tier 5: Everything else (score 4)
        return (4, name_lower)

    return sorted(exercises, key=relevance_score)


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
            image_url=row.get("image_url"),
            goals=row.get("goals", []),
            suitable_for=row.get("suitable_for", []),
            avoid_if=row.get("avoid_if", []),
            movement_pattern=row.get("movement_pattern"),
            mechanic_type=row.get("mechanic_type"),
            force_type=row.get("force_type"),
            plane_of_motion=row.get("plane_of_motion"),
            energy_system=row.get("energy_system"),
            default_duration_seconds=row.get("default_duration_seconds"),
            default_rep_range_min=row.get("default_rep_range_min"),
            default_rep_range_max=row.get("default_rep_range_max"),
            default_rest_seconds=row.get("default_rest_seconds"),
            default_tempo=row.get("default_tempo"),
            default_incline_percent=row.get("default_incline_percent"),
            default_speed_mph=row.get("default_speed_mph"),
            default_resistance_level=row.get("default_resistance_level"),
            default_rpm=row.get("default_rpm"),
            stroke_rate_spm=row.get("stroke_rate_spm"),
            contraindicated_conditions=row.get("contraindicated_conditions"),
            impact_level=row.get("impact_level"),
            form_complexity=row.get("form_complexity"),
            stability_requirement=row.get("stability_requirement"),
            is_dynamic_stretch=row.get("is_dynamic_stretch"),
            hold_seconds_min=row.get("hold_seconds_min"),
            hold_seconds_max=row.get("hold_seconds_max"),
            single_dumbbell_friendly=row.get("single_dumbbell_friendly"),
            single_kettlebell_friendly=row.get("single_kettlebell_friendly"),
        )
    else:
        # From base table - clean name manually
        original_name = row.get("exercise_name", "")
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
            image_url=row.get("image_s3_path"),
            goals=row.get("goals", []),
            suitable_for=row.get("suitable_for", []),
            avoid_if=row.get("avoid_if", []),
        )


def row_to_library_program(row: dict) -> LibraryProgram:
    """Convert a Supabase row from branded_programs table to LibraryProgram model.

    branded_programs fields: name, category, difficulty_level, duration_weeks,
    sessions_per_week, description, goals, tagline, split_type, is_featured,
    is_premium, requires_gym, icon_name, color_hex
    """
    # Calculate approximate session duration based on sessions per week
    sessions_per_week = row.get("sessions_per_week", 4)
    session_duration = 45 if sessions_per_week <= 4 else 60  # Default estimates

    # Use goals as tags since branded_programs doesn't have a separate tags field
    goals = row.get("goals") if isinstance(row.get("goals"), list) else []

    return LibraryProgram(
        id=row.get("id"),
        name=row.get("name", ""),  # branded_programs uses 'name' not 'program_name'
        category=row.get("category", ""),  # branded_programs uses 'category' not 'program_category'
        subcategory=row.get("split_type"),  # Map split_type to subcategory
        difficulty_level=row.get("difficulty_level"),
        duration_weeks=row.get("duration_weeks"),
        sessions_per_week=sessions_per_week,
        session_duration_minutes=session_duration,
        tags=goals,  # Use goals as tags
        goals=goals,
        description=row.get("description"),
        short_description=row.get("tagline"),  # Map tagline to short_description
        celebrity_name=None,  # branded_programs doesn't have celebrity_name
    )


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
