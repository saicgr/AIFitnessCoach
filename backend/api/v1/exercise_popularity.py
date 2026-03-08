"""
Exercise Popularity API - Collaborative filtering data for exercise selection.

Aggregates anonymized performance logs to provide population-level signals:
- Exercise popularity (unique users)
- PR rate (how often users hit PRs)
- Average RPE (exercise comfort)

Score = popularity * 0.4 + low_rpe * 0.3 + pr_rate * 0.3
"""
from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from core.supabase_client import get_supabase
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)

# In-memory cache (refreshed on startup or after TTL)
_popularity_cache: dict = {}
_cache_timestamp: float = 0
_CACHE_TTL_SECONDS = 3600  # 1 hour


def _parse_popularity_rows(rows: list) -> dict:
    """Parse RPC response rows into nested dict: muscle -> goal -> exercise -> score."""
    result = {}
    for row in rows:
        muscle = (row.get("muscle_group") or "").lower()
        goal = (row.get("goal") or "hypertrophy").lower()
        exercise = (row.get("exercise_name") or "").lower()
        score = float(row.get("score", 0))

        if muscle not in result:
            result[muscle] = {}
        if goal not in result[muscle]:
            result[muscle][goal] = {}
        result[muscle][goal][exercise] = score
    return result


async def _get_popularity_data(
    user_id: Optional[str] = None,
    fitness_level: Optional[str] = None,
) -> dict:
    """Load or return cached popularity data from performance_logs.

    When user_id is provided, bypasses the global cache and makes a fresh
    RPC call with exclude_user_id to prevent self-reinforcing loops.
    """
    import time
    global _popularity_cache, _cache_timestamp

    # When excluding a specific user, always make a fresh call (no global cache)
    if user_id:
        try:
            supabase = get_supabase()
            params = {"exclude_user_id": user_id}
            if fitness_level:
                params["fitness_level_filter"] = fitness_level

            response = supabase.rpc(
                "get_exercise_popularity_stats",
                params,
            ).execute()

            if response.data:
                return _parse_popularity_rows(response.data)
        except Exception as e:
            logger.warning(f"Failed to load user-excluded popularity data: {e}")
        # Fall through to global cache
        return _popularity_cache

    now = time.time()
    if _popularity_cache and (now - _cache_timestamp) < _CACHE_TTL_SECONDS:
        return _popularity_cache

    try:
        supabase = get_supabase()
        params = {}
        if fitness_level:
            params["fitness_level_filter"] = fitness_level

        # Query aggregated exercise stats from performance_logs
        # This is a simplified aggregation - the full version runs as a batch job
        response = supabase.rpc(
            "get_exercise_popularity_stats",
            params,
        ).execute()

        if response.data:
            result = _parse_popularity_rows(response.data)
            _popularity_cache = result
            _cache_timestamp = now
            return result

    except Exception as e:
        logger.warning(f"Failed to load popularity data from DB: {e}")

    # Return cached data even if stale, or empty dict
    return _popularity_cache


@router.get("/exercise-popularity/{muscle_group}")
async def get_exercise_popularity(
    muscle_group: str,
    fitness_level: Optional[str] = Query(None),
    goal: Optional[str] = Query("hypertrophy"),
    user_id: Optional[str] = Query(None, description="Exclude this user's data to prevent self-reinforcing loops"),
):
    """
    Get exercise popularity scores for a muscle group.

    Returns a map of exercise_name -> score (0.0 to 1.0).
    Higher scores indicate more popular/effective exercises based on
    population-level data.
    """
    data = await _get_popularity_data(user_id=user_id, fitness_level=fitness_level)
    muscle = muscle_group.lower()
    effective_goal = (goal or "hypertrophy").lower()

    muscle_data = data.get(muscle, {})
    if not muscle_data:
        # Return empty rather than 404 - muscle may not have enough data
        return {
            "muscle_group": muscle,
            "goal": effective_goal,
            "exercises": {},
            "user_id_excluded": user_id is not None,
        }

    exercises = muscle_data.get(effective_goal, muscle_data.get("hypertrophy", {}))

    return {
        "muscle_group": muscle,
        "goal": effective_goal,
        "fitness_level": fitness_level,
        "user_id_excluded": user_id is not None,
        "exercises": exercises,
    }
