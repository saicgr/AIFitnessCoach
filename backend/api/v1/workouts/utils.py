"""
Shared utilities and helper functions for workout endpoints.

This module re-exports all utilities from focused sub-modules for
backwards compatibility. New code should import directly from the
specific sub-module when possible.

Sub-modules:
- schedule_utils: Training splits, focus areas, workout type inference
- validation_utils: Exercise parameter caps, safety nets, set/rep limits
- user_preference_utils: DB fetch helpers for user preferences
- readiness_utils: Readiness, mood, injuries, comeback
- progression_utils: Rep preferences, mastery, workout patterns
- hormonal_utils: Cycle phase, kegels, gender-specific adjustments
- focus_validation_utils: Focus area matching, muscle profiles
"""
import json
import time
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import Workout
from services.gemini_service import GeminiService
from services.rag_service import WorkoutRAGService

logger = get_logger(__name__)

# ============================================================================
# Core utilities that remain in this file (small, foundational)
# ============================================================================

# Initialize workout RAG service (lazy loading)
_workout_rag_service: Optional[WorkoutRAGService] = None


def get_workout_rag_service() -> WorkoutRAGService:
    """Get or create the workout RAG service instance."""
    global _workout_rag_service
    if _workout_rag_service is None:
        gemini_service = GeminiService()
        _workout_rag_service = WorkoutRAGService(gemini_service)
    return _workout_rag_service


def invalidate_upcoming_workouts(
    user_id: str,
    reason: str,
    only_next: bool = False,
) -> int:
    """Delete upcoming non-completed workouts so the next /today call regenerates them."""
    try:
        db = get_supabase_db()
        today_str = date.today().isoformat()

        query = db.client.table("workouts").select("id, scheduled_date, status").eq(
            "user_id", user_id
        ).gt(
            "scheduled_date", today_str
        ).eq(
            "is_completed", False
        )

        rows = query.execute()
        if not rows.data:
            return 0

        ids_to_delete = [
            r["id"] for r in rows.data
            if r.get("status") != "generating"
        ]

        if only_next:
            dated = sorted(
                [(r["id"], r.get("scheduled_date", "")) for r in rows.data if r.get("status") != "generating"],
                key=lambda x: x[1],
            )
            ids_to_delete = [dated[0][0]] if dated else []

        if not ids_to_delete:
            return 0

        deleted = db.client.table("workouts").delete().in_("id", ids_to_delete).execute()
        count = len(deleted.data) if deleted.data else 0
        logger.info(f"[INVALIDATE] Deleted {count} upcoming workouts for user {user_id} ({reason})")
        return count

    except Exception as e:
        logger.warning(f"[INVALIDATE] Failed to invalidate workouts for user {user_id} ({reason}): {e}", exc_info=True)
        return 0


def parse_json_field(value, default):
    """Parse a field that could be a JSON string or already parsed."""
    if value is None:
        return default
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return default
    return value if isinstance(value, (list, dict)) else default


def normalize_goals_list(goals) -> List[str]:
    """Normalize goals to a list of strings from various DB formats."""
    if goals is None:
        return []

    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except json.JSONDecodeError:
            return [goals] if goals.strip() else []

    if not isinstance(goals, list):
        return []

    result = []
    for item in goals:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            goal_name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)
            )
            if goal_name and isinstance(goal_name, str):
                result.append(goal_name.strip())

    return result


def get_intensity_from_fitness_level(fitness_level: Optional[str]) -> str:
    """Derive workout intensity/difficulty from user's fitness level."""
    if not fitness_level:
        return "medium"

    level_lower = fitness_level.lower().strip()
    if level_lower == "beginner":
        return "easy"
    elif level_lower == "advanced":
        return "hard"
    else:
        return "medium"


def get_all_equipment(user: dict) -> List[str]:
    """Get combined list of standard and custom equipment for a user."""
    standard = parse_json_field(user.get("equipment"), [])
    custom = parse_json_field(user.get("custom_equipment"), [])

    if not isinstance(standard, list):
        standard = []
    if not isinstance(custom, list):
        custom = []

    all_equipment = list(standard)
    for item in custom:
        if item and item not in all_equipment:
            all_equipment.append(item)

    return all_equipment


# Module-level cache for exercise library media URLs
_exercise_library_cache: Optional[Dict[str, Dict]] = None
_exercise_library_cache_time: float = 0
_EXERCISE_LIBRARY_CACHE_TTL = 300  # 5 minutes


def _get_exercise_library_url_map(db) -> Dict[str, Dict]:
    """Get cached exercise library URL map."""
    global _exercise_library_cache, _exercise_library_cache_time

    now = time.time()
    if _exercise_library_cache is not None and (now - _exercise_library_cache_time) < _EXERCISE_LIBRARY_CACHE_TTL:
        return _exercise_library_cache

    result = db.client.table("exercise_library_cleaned").select(
        "name, gif_url, video_url, image_url"
    ).execute()

    url_map: Dict[str, Dict] = {}
    if result.data:
        for row in result.data:
            lib_name = (row.get("name") or "").lower().strip()
            if lib_name:
                url_map[lib_name] = {
                    "gif_url": row.get("gif_url"),
                    "video_url": row.get("video_url"),
                    "image_s3_path": row.get("image_url"),
                }

    _exercise_library_cache = url_map
    _exercise_library_cache_time = now
    return url_map


def enrich_exercises_with_video_urls(exercises: List[Dict], db=None) -> List[Dict]:
    """Enrich exercises with video/image URLs from the exercise library."""
    if not exercises:
        return exercises

    if db is None:
        db = get_supabase_db()

    exercise_names = []
    name_mapping = {}
    for ex in exercises:
        name = ex.get("name", "")
        if name:
            normalized = name.lower().strip()
            exercise_names.append(normalized)
            name_mapping[normalized] = name

    if not exercise_names:
        return exercises

    try:
        url_map = _get_exercise_library_url_map(db)

        if not url_map:
            logger.debug("No exercises found in library for media enrichment")
            return exercises

        from api.v1.library.utils import presign_s3_path, resolve_image_url

        enriched_count = 0
        for ex in exercises:
            ex_name = (ex.get("name") or "").lower().strip()
            if ex_name in url_map:
                urls = url_map[ex_name]
                if not ex.get("gif_url") and urls.get("gif_url"):
                    ex["gif_url"] = urls["gif_url"]
                    enriched_count += 1
                if not ex.get("video_url") and urls.get("video_url"):
                    # Presign S3 paths so clients get HTTPS URLs, not s3:// URIs
                    ex["video_url"] = presign_s3_path(urls["video_url"])
                    enriched_count += 1
                if not ex.get("image_s3_path") and urls.get("image_s3_path"):
                    ex["image_s3_path"] = resolve_image_url(urls["image_s3_path"])
                    enriched_count += 1

        if enriched_count > 0:
            logger.info(f"✅ Enriched {enriched_count} exercise media URLs from library")

    except Exception as e:
        logger.warning(f"⚠️ Failed to enrich exercises with media URLs: {e}", exc_info=True)

    return exercises


def row_to_workout(row: dict, enrich_videos: bool = True) -> Workout:
    """Convert a Supabase row dict to Workout model."""
    exercises_json = row.get("exercises_json") or row.get("exercises")

    if isinstance(exercises_json, str):
        try:
            exercises_list = json.loads(exercises_json)
        except json.JSONDecodeError:
            exercises_list = []
    elif isinstance(exercises_json, list):
        exercises_list = exercises_json
    else:
        exercises_list = []

    if enrich_videos and exercises_list:
        exercises_list = enrich_exercises_with_video_urls(exercises_list)

    exercises_json = json.dumps(exercises_list) if exercises_list else "[]"

    generation_metadata = row.get("generation_metadata")
    if isinstance(generation_metadata, (dict, list)):
        generation_metadata = json.dumps(generation_metadata)

    modification_history = row.get("modification_history")
    if isinstance(modification_history, (dict, list)):
        modification_history = json.dumps(modification_history)

    return Workout(
        id=str(row.get("id")),
        user_id=str(row.get("user_id")),
        name=row.get("name") or "Workout",
        type=row.get("type") or "strength",
        difficulty=row.get("difficulty") or "intermediate",
        description=row.get("description"),
        scheduled_date=row.get("scheduled_date"),
        is_completed=row.get("is_completed", False),
        exercises_json=exercises_json,
        duration_minutes=row.get("duration_minutes", 45),
        created_at=row.get("created_at"),
        generation_method=row.get("generation_method"),
        generation_source=row.get("generation_source"),
        generation_metadata=generation_metadata,
        generated_at=row.get("generated_at"),
        last_modified_method=row.get("last_modified_method"),
        last_modified_at=row.get("last_modified_at"),
        modification_history=modification_history,
        version_number=row.get("version_number", 1),
        is_current=row.get("is_current", True),
        valid_from=row.get("valid_from"),
        valid_to=row.get("valid_to"),
        parent_workout_id=row.get("parent_workout_id"),
        superseded_by=row.get("superseded_by"),
        completed_at=row.get("completed_at"),
        completion_method=row.get("completion_method"),
    )


def log_workout_change(
    workout_id: str,
    user_id: str,
    change_type: str,
    field_changed: str = None,
    old_value=None,
    new_value=None,
    change_source: str = "api",
    change_reason: str = None
):
    """Log a change to a workout for audit trail."""
    try:
        db = get_supabase_db()
        change_data = {
            "workout_id": workout_id,
            "user_id": user_id,
            "change_type": change_type,
            "field_changed": field_changed,
            "old_value": json.dumps(old_value) if old_value is not None else None,
            "new_value": json.dumps(new_value) if new_value is not None else None,
            "change_source": change_source,
            "change_reason": change_reason,
        }
        db.create_workout_change(change_data)
        logger.debug(f"Logged workout change: workout_id={workout_id}, type={change_type}")
    except Exception as e:
        logger.error(f"Failed to log workout change: {e}", exc_info=True)


async def index_workout_to_rag(workout: Workout):
    """Index a workout to RAG for retrieval (fire-and-forget)."""
    try:
        rag_service = get_workout_rag_service()
        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json
        scheduled_date = workout.scheduled_date
        if hasattr(scheduled_date, 'isoformat'):
            scheduled_date = scheduled_date.isoformat()
        await rag_service.index_workout(
            workout_id=workout.id,
            user_id=workout.user_id,
            name=workout.name,
            workout_type=workout.type,
            difficulty=workout.difficulty,
            exercises=exercises,
            scheduled_date=str(scheduled_date),
            is_completed=workout.is_completed,
            generation_method=workout.generation_method,
        )
    except Exception as e:
        logger.error(f"Failed to index workout to RAG: {e}", exc_info=True)


async def get_recently_used_exercises(user_id: str, days: int = 7) -> List[str]:
    """Get list of exercise names used by user in recent workouts."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        response = db.client.table("workouts").select(
            "exercises_json"
        ).eq("user_id", user_id).gte(
            "scheduled_date", cutoff_date
        ).execute()

        if not response.data:
            return []

        recent_exercises = set()
        for workout in response.data:
            exercises_json = workout.get("exercises_json", [])
            if isinstance(exercises_json, str):
                try:
                    exercises_json = json.loads(exercises_json)
                except json.JSONDecodeError:
                    continue

            for exercise in exercises_json:
                if isinstance(exercise, dict):
                    name = exercise.get("name") or exercise.get("exercise_name")
                    if name:
                        recent_exercises.add(name)

        logger.info(f"Found {len(recent_exercises)} recently used exercises for user {user_id} (last {days} days)")
        return list(recent_exercises)

    except Exception as e:
        logger.error(f"Error getting recently used exercises: {e}", exc_info=True)
        return []


async def get_recent_workout_name_words(user_id: str, days: int = 14) -> List[str]:
    """Get significant words from recent workout names to avoid repetition."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        response = db.client.table("workouts").select("name").eq(
            "user_id", user_id
        ).gte("scheduled_date", cutoff_date).neq("name", "Generating...").execute()

        if not response.data:
            return []

        from .schedule_utils import extract_name_words

        all_words = set()
        for workout in response.data:
            name = workout.get("name")
            if name:
                all_words.update(extract_name_words(name))

        logger.info(f"[NameDedup] {len(all_words)} name words to avoid for user (last {days} days)")
        return list(all_words)
    except Exception as e:
        logger.error(f"Error getting recent workout name words: {e}", exc_info=True)
        return []


# ============================================================================
# Re-exports from sub-modules for backwards compatibility
# ============================================================================

# schedule_utils
from .schedule_utils import (
    resolve_training_split,
    infer_workout_type_from_focus,
    get_workout_focus,
    extract_name_words,
)

# validation_utils
from .validation_utils import (
    validate_and_cap_exercise_parameters,
    enforce_set_rep_limits,
    truncate_exercises_to_duration,
    ABSOLUTE_MAX_REPS,
    ABSOLUTE_MAX_SETS,
    ABSOLUTE_MIN_REST,
    FITNESS_LEVEL_CAPS,
    HELL_MODE_CAPS,
    AGE_CAPS,
    HIGH_REP_EXERCISE_KEYWORDS,
    ADVANCED_EXERCISES_BLOCKLIST,
    is_high_rep_exercise,
    is_advanced_exercise,
    get_age_bracket_from_age,
)

# user_preference_utils
from .user_preference_utils import (
    fuzzy_exercise_match,
    get_user_strength_history,
    get_user_personal_bests,
    format_performance_context,
    get_user_favorite_exercises,
    get_user_consistency_mode,
    get_user_exercise_queue,
    mark_queued_exercises_used,
    get_user_staple_exercises,
    get_staple_names,
    get_user_variation_percentage,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    calculate_working_weight_from_1rm,
    apply_1rm_weights_to_exercises,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    get_user_progression_pace,
    get_user_workout_type_preference,
    get_substitute_exercise,
    auto_substitute_filtered_exercises,
)

# readiness_utils
from .readiness_utils import (
    INJURY_TO_AVOIDED_MUSCLES,
    get_user_readiness_score,
    get_user_latest_mood,
    get_muscles_to_avoid_from_injuries,
    adjust_workout_params_for_readiness,
    get_active_injuries_with_muscles,
    get_user_comeback_status,
    get_comeback_context,
    apply_comeback_adjustments_to_exercises,
    start_comeback_mode_if_needed,
    get_comeback_prompt_context,
)

# progression_utils
from .progression_utils import (
    get_user_rep_preferences,
    get_user_progression_context,
    build_progression_philosophy_prompt,
    get_user_workout_patterns,
    TRAINING_FOCUS_REP_RANGES,
    EXERCISE_PROGRESSION_CHAINS,
)

# hormonal_utils
from .hormonal_utils import (
    get_user_hormonal_context,
    adjust_workout_for_cycle_phase,
    get_kegel_exercises_for_workout,
)

# focus_validation_utils
from .focus_validation_utils import (
    validate_and_filter_focus_mismatches,
    validate_exercise_matches_focus,
    get_all_muscles_for_exercise,
    compare_muscle_profiles,
    get_user_favorite_workouts,
    build_favorite_workouts_context,
    FOCUS_AREA_MUSCLES,
    FOCUS_AREA_EXCLUDED_EXERCISES,
)
