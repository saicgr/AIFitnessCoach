"""
Training Program Service - Dynamically loads training programs from database.

This service:
1. Loads programs from the 'programs' table (excluding celebrity workouts)
2. Builds keyword maps for RAG search
3. Builds detection maps for onboarding extraction
4. Caches results for performance
"""
from typing import Dict, List, Optional, Tuple
import re
from datetime import datetime, timedelta

from core.supabase_client import get_supabase
from core.logger import get_logger

logger = get_logger(__name__)

# Cache settings
_cache_ttl = timedelta(hours=1)  # Refresh cache every hour
_last_refresh: Optional[datetime] = None
_training_program_keywords: Dict[str, str] = {}
_training_program_map: Dict[str, List[str]] = {}


def _normalize_program_name(name: str) -> str:
    """Normalize program name for matching (lowercase, remove special chars)."""
    # Remove common suffixes
    name = re.sub(r'\s+(workout|training|program|fitness|regime|conditioning)$', '', name, flags=re.IGNORECASE)
    # Remove numbers and special characters
    name = re.sub(r'[0-9\-_]+', ' ', name)
    # Lowercase and strip
    return name.lower().strip()


def _extract_keywords_from_program(program: dict) -> str:
    """
    Extract search keywords from a program's metadata.

    Combines:
    - tags (e.g., ["HIIT", "Strength", "Muscle Building"])
    - goals (e.g., ["Build Muscle", "Lose Fat"])
    - description keywords
    - subcategory
    """
    keywords = []

    # Add tags
    tags = program.get('tags', []) or []
    keywords.extend(tags)

    # Add goals
    goals = program.get('goals', []) or []
    keywords.extend(goals)

    # Add subcategory
    subcategory = program.get('program_subcategory', '')
    if subcategory:
        keywords.append(subcategory)

    # Extract key terms from description (simple approach)
    description = program.get('description', '') or ''
    # Extract fitness-related terms from description
    fitness_terms = [
        'strength', 'power', 'muscle', 'endurance', 'cardio', 'agility',
        'flexibility', 'mobility', 'conditioning', 'explosive', 'functional',
        'compound', 'isolation', 'hypertrophy', 'metabolic', 'HIIT',
        'running', 'swimming', 'cycling', 'boxing', 'martial arts',
        'bodyweight', 'resistance', 'plyometric', 'core', 'stability'
    ]
    desc_lower = description.lower()
    for term in fitness_terms:
        if term.lower() in desc_lower:
            keywords.append(term)

    # Deduplicate and join
    unique_keywords = list(set(kw.lower() for kw in keywords if kw))
    return ' '.join(unique_keywords)


def _map_program_to_goals(program: dict) -> List[str]:
    """
    Map a program to base goals for the goals extraction system.

    Returns a list like: ["HYROX", "Improve Endurance", "Increase Strength"]
    """
    result_goals = []

    # Add the program name (normalized) as a goal identifier
    program_name = program.get('program_name', '')
    # Extract key identifier (e.g., "HYROX" from "HYROX 8-Week Training")
    name_parts = program_name.split()
    if name_parts:
        # Use first significant word as identifier
        for part in name_parts:
            if len(part) > 2 and part.lower() not in ['the', 'and', 'for', 'week', 'day']:
                result_goals.append(part)
                break

    # Map program goals to standard goals
    program_goals = program.get('goals', []) or []
    goal_mapping = {
        'build muscle': 'Build Muscle',
        'lose fat': 'Lose Weight',
        'lose weight': 'Lose Weight',
        'increase strength': 'Increase Strength',
        'athletic performance': 'Improve Endurance',
        'endurance': 'Improve Endurance',
        'flexibility': 'Flexibility',
        'toning': 'Build Muscle',
        'wellness': 'General Fitness',
    }

    for goal in program_goals:
        goal_lower = goal.lower()
        if goal_lower in goal_mapping:
            mapped = goal_mapping[goal_lower]
            if mapped not in result_goals:
                result_goals.append(mapped)
        else:
            # Keep as-is if not in mapping
            if goal not in result_goals:
                result_goals.append(goal)

    return result_goals


async def _refresh_cache():
    """Load programs from database and build keyword/detection maps."""
    global _last_refresh, _training_program_keywords, _training_program_map

    try:
        supabase = get_supabase().client

        # Query non-celebrity programs
        result = supabase.table('programs').select(
            'program_name, program_category, program_subcategory, tags, goals, description'
        ).not_(
            'program_category', 'like', 'Celebrity%'
        ).execute()

        programs = result.data or []
        logger.info(f"[TrainingProgramService] Loaded {len(programs)} programs from database")

        new_keywords = {}
        new_map = {}

        for program in programs:
            program_name = program.get('program_name', '')
            if not program_name:
                continue

            # Build keywords for RAG search
            keywords = _extract_keywords_from_program(program)
            if keywords:
                # Use the program identifier as the key
                identifier = _normalize_program_name(program_name).split()[0].title() if program_name else ''
                if identifier and len(identifier) > 2:
                    new_keywords[identifier] = keywords

            # Build detection map for onboarding
            normalized_name = _normalize_program_name(program_name)
            goals = _map_program_to_goals(program)

            if normalized_name and goals:
                new_map[normalized_name] = goals
                # Also add individual words as keys for partial matching
                for word in normalized_name.split():
                    if len(word) > 3 and word not in new_map:
                        new_map[word] = goals

        # Add hardcoded fallbacks for common programs not in DB
        hardcoded_keywords = {
            "HYROX": "functional fitness running lunges burpees rowing sled push farmer carry wall balls ski erg endurance strength hybrid",
            "CrossFit": "functional movements olympic lifts thrusters pull-ups box jumps kettlebell swings burpees muscle-ups high intensity",
            "Powerlifting": "squat bench press deadlift heavy compound maximal strength low reps",
            "Boxing": "punching power core rotation footwork cardio conditioning speed agility",
            "MMA": "grappling striking takedowns conditioning explosive power",
            "Marathon": "running endurance long distance cardio tempo runs intervals",
            "Skinny Fat": "body recomposition fat loss muscle building compound exercises metabolic",
            "Lean Bulk": "hypertrophy muscle building progressive overload compound movements",
        }

        hardcoded_map = {
            'hyrox': ['HYROX', 'Improve Endurance', 'Increase Strength'],
            'crossfit': ['CrossFit', 'Improve Endurance', 'Increase Strength', 'General Fitness'],
            'powerlifting': ['Powerlifting', 'Increase Strength'],
            'boxing': ['Boxing', 'Improve Endurance', 'Increase Strength'],
            'mma': ['MMA', 'Improve Endurance', 'Increase Strength'],
            'marathon': ['Marathon', 'Improve Endurance'],
            'skinny fat': ['Skinny Fat', 'Build Muscle', 'Lose Weight'],
            'lean bulk': ['Lean Bulk', 'Build Muscle'],
        }

        # Merge hardcoded with DB (DB takes precedence)
        for k, v in hardcoded_keywords.items():
            if k not in new_keywords:
                new_keywords[k] = v

        for k, v in hardcoded_map.items():
            if k not in new_map:
                new_map[k] = v

        _training_program_keywords = new_keywords
        _training_program_map = new_map
        _last_refresh = datetime.now()

        logger.info(f"[TrainingProgramService] Built {len(_training_program_keywords)} keyword entries and {len(_training_program_map)} detection entries")

    except Exception as e:
        logger.error(f"[TrainingProgramService] Error loading programs: {e}")
        # Keep existing cache on error


async def get_training_program_keywords() -> Dict[str, str]:
    """
    Get training program keywords for RAG search.

    Returns a dict like:
    {
        "HYROX": "functional fitness running lunges burpees...",
        "Boxing": "punching power core rotation footwork...",
    }
    """
    global _last_refresh

    # Check if cache needs refresh
    if _last_refresh is None or datetime.now() - _last_refresh > _cache_ttl:
        await _refresh_cache()

    return _training_program_keywords


async def get_training_program_map() -> Dict[str, List[str]]:
    """
    Get training program detection map for onboarding extraction.

    Returns a dict like:
    {
        "hyrox": ["HYROX", "Improve Endurance", "Increase Strength"],
        "boxing": ["Boxing", "Improve Endurance", "Increase Strength"],
    }
    """
    global _last_refresh

    # Check if cache needs refresh
    if _last_refresh is None or datetime.now() - _last_refresh > _cache_ttl:
        await _refresh_cache()

    return _training_program_map


def get_training_program_keywords_sync() -> Dict[str, str]:
    """Synchronous version - returns cached data or empty dict."""
    return _training_program_keywords


def get_training_program_map_sync() -> Dict[str, List[str]]:
    """Synchronous version - returns cached data or empty dict."""
    return _training_program_map


# Initialize cache on module load (best effort)
def _init_cache():
    """Initialize cache with hardcoded fallbacks."""
    global _training_program_keywords, _training_program_map

    # Set hardcoded fallbacks immediately
    _training_program_keywords = {
        "HYROX": "functional fitness running lunges burpees rowing sled push farmer carry wall balls ski erg endurance strength hybrid",
        "CrossFit": "functional movements olympic lifts thrusters pull-ups box jumps kettlebell swings burpees muscle-ups high intensity",
        "Powerlifting": "squat bench press deadlift heavy compound maximal strength low reps powerlifting",
        "Bodybuilding": "hypertrophy isolation exercises muscle pump volume training bodybuilding aesthetics",
        "Marathon": "running endurance long distance cardio tempo runs intervals leg strength",
        "Triathlon": "swimming cycling running endurance multi-sport cardio cross-training",
        "Boxing": "punching power core rotation footwork cardio conditioning shadow boxing heavy bag speed agility",
        "MMA": "grappling striking takedowns ground work conditioning explosive power mixed martial arts",
        "Kickboxing": "kicks punches combinations cardio agility core rotation power endurance",
        "Wrestling": "takedowns grappling strength explosiveness conditioning grip strength wrestling",
        "Football": "speed agility power explosiveness sprints lateral movement tackling football",
        "Soccer": "running endurance agility footwork sprints leg strength cardio soccer",
        "Basketball": "jumping vertical leap agility speed lateral movement court conditioning basketball",
        "Rugby": "power strength tackling sprints endurance contact conditioning rugby",
        "Tennis": "agility lateral movement core rotation shoulder stability endurance tennis",
        "Swimming": "upper body pull strength shoulder mobility core stability cardio swimming",
        "Cricket": "rotational power shoulder stability sprints agility throwing cricket",
        "Volleyball": "jumping vertical leap shoulder strength agility lateral movement volleyball",
        "Golf": "rotational power core stability flexibility hip mobility golf swing",
        "Skinny Fat": "body recomposition fat loss muscle building compound exercises metabolic conditioning",
        "Lean Bulk": "hypertrophy muscle building progressive overload compound movements lean gains",
        "Cut": "fat loss muscle preservation high intensity metabolic cardio cutting",
        "Recomp": "body recomposition simultaneous fat loss muscle gain compounds cardio",
        "Calisthenics": "bodyweight exercises pull-ups push-ups dips muscle-ups handstands calisthenics",
        "Strongman": "carries deadlifts pressing stones atlas stones farmer walks strongman",
        "HIIT": "high intensity interval training cardio fat burning metabolic conditioning bursts",
    }

    _training_program_map = {
        'hyrox': ['HYROX', 'Improve Endurance', 'Increase Strength'],
        'crossfit': ['CrossFit', 'Improve Endurance', 'Increase Strength', 'General Fitness'],
        'powerlifting': ['Powerlifting', 'Increase Strength'],
        'bodybuilding': ['Bodybuilding', 'Build Muscle'],
        'marathon': ['Marathon', 'Improve Endurance'],
        'running': ['Marathon', 'Improve Endurance'],
        'triathlon': ['Triathlon', 'Improve Endurance'],
        'boxing': ['Boxing', 'Improve Endurance', 'Increase Strength'],
        'boxer': ['Boxing', 'Improve Endurance', 'Increase Strength'],
        'mma': ['MMA', 'Improve Endurance', 'Increase Strength'],
        'kickboxing': ['Kickboxing', 'Improve Endurance', 'Increase Strength'],
        'wrestling': ['Wrestling', 'Increase Strength', 'Improve Endurance'],
        'football': ['Football', 'Increase Strength', 'Improve Endurance'],
        'footballer': ['Football', 'Increase Strength', 'Improve Endurance'],
        'soccer': ['Soccer', 'Improve Endurance'],
        'basketball': ['Basketball', 'Improve Endurance', 'Increase Strength'],
        'rugby': ['Rugby', 'Increase Strength', 'Improve Endurance'],
        'tennis': ['Tennis', 'Improve Endurance'],
        'swimming': ['Swimming', 'Improve Endurance', 'Build Muscle'],
        'swimmer': ['Swimming', 'Improve Endurance', 'Build Muscle'],
        'cricket': ['Cricket', 'Improve Endurance'],
        'volleyball': ['Volleyball', 'Improve Endurance', 'Increase Strength'],
        'golf': ['Golf', 'General Fitness'],
        'skinny fat': ['Skinny Fat', 'Build Muscle', 'Lose Weight'],
        'lean bulk': ['Lean Bulk', 'Build Muscle'],
        'bulk up': ['Lean Bulk', 'Build Muscle'],
        'cut': ['Cut', 'Lose Weight'],
        'cutting': ['Cut', 'Lose Weight'],
        'recomp': ['Recomp', 'Build Muscle', 'Lose Weight'],
        'calisthenics': ['Calisthenics', 'Build Muscle', 'Increase Strength'],
        'strongman': ['Strongman', 'Increase Strength'],
        'hiit': ['HIIT', 'Lose Weight', 'Improve Endurance'],
        'yoga': ['Yoga', 'Flexibility', 'General Fitness'],
        'pilates': ['Pilates', 'General Fitness', 'Flexibility'],
    }


# Initialize on import
_init_cache()
