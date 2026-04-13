"""
Meal-context pre-fetch endpoint.

Powers the AI Coach popup on the meal-log sheet: before the user taps a
preset pill, the popup fetches a lightweight summary of today's calorie
remainder, workout, favorites, and meal-types-logged so it can choose
which pills to render.

Privacy note: this endpoint returns the user's own logged-food / workout
data. No third-party (e.g. Gemini) is called here — pure DB aggregation.
Gemini only sees the data later if the user taps a pill and sends a chat
message.
"""
import asyncio
import time
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from core.auth import get_current_user
from core.logger import get_logger
from core.rate_limiter import limiter
from services.langgraph_agents.tools.nutrition_context_helpers import (
    fetch_daily_nutrition_context,
    fetch_recent_favorites,
    fetch_todays_workout,
)

router = APIRouter()
logger = get_logger(__name__)


# ── Response models ────────────────────────────────────────────────────────

class MacrosRemaining(BaseModel):
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None


class TodayWorkoutSummary(BaseModel):
    id: Optional[str] = None
    name: Optional[str] = None
    type: Optional[str] = None
    is_completed: bool = False
    duration_minutes: Optional[int] = None
    scheduled_time_local: Optional[str] = None
    primary_muscles: List[str] = []
    exercise_count: int = 0


class FavoritePreview(BaseModel):
    id: Optional[str] = None
    name: str
    total_calories: Optional[int] = None
    last_logged_days_ago: Optional[int] = None


class MealContextResponse(BaseModel):
    # Budget / macros
    calorie_remainder: Optional[int] = None
    total_calories: int = 0
    target_calories: Optional[int] = None
    macros_remaining: MacrosRemaining = MacrosRemaining()
    over_budget: bool = False

    # Meals / quality
    meal_types_logged: List[str] = []
    meal_count: int = 0
    ultra_processed_count_today: int = 0

    # Workout (maybe null on rest day)
    today_workout: Optional[TodayWorkoutSummary] = None

    # Favorites
    has_favorites: bool = False
    favorites_preview: List[FavoritePreview] = []

    # Meta
    meal_type: Optional[str] = None
    timezone: str = "UTC"
    context_partial: bool = False
    computed_at_ms: int = 0


# ── Lightweight in-process cache (5 min TTL keyed by user + local date) ────

_CACHE: Dict[str, tuple] = {}  # key -> (ts, MealContextResponse)
_CACHE_TTL = 5 * 60
_CACHE_MAX = 2000


def _cache_get(key: str) -> Optional[MealContextResponse]:
    hit = _CACHE.get(key)
    if not hit:
        return None
    ts, payload = hit
    if time.time() - ts > _CACHE_TTL:
        _CACHE.pop(key, None)
        return None
    return payload


def _cache_put(key: str, value: MealContextResponse) -> None:
    _CACHE[key] = (time.time(), value)
    if len(_CACHE) > _CACHE_MAX:
        # Drop oldest 10%
        drop_n = _CACHE_MAX // 10
        oldest = sorted(_CACHE.items(), key=lambda kv: kv[1][0])[:drop_n]
        for k, _ in oldest:
            _CACHE.pop(k, None)


# ── Endpoint ───────────────────────────────────────────────────────────────

@router.get("/meal-context", response_model=MealContextResponse)
@limiter.limit("60/minute")
async def get_meal_context(
    request: Request,  # required by slowapi limiter
    meal_type: Optional[str] = Query(
        default=None,
        max_length=20,
        description="Meal type the user is logging (breakfast/lunch/dinner/snack)",
    ),
    tz: str = Query(
        default="UTC",
        max_length=64,
        description="IANA timezone name (e.g. America/Chicago)",
    ),
    current_user: dict = Depends(get_current_user),
):
    """Pre-fetch lightweight day context for the AI Coach popup.

    Runs 3 helpers in parallel; any individual failure surfaces as
    `context_partial=true` rather than erroring the whole request (so the
    popup can still show default pills + a banner).
    """
    start = time.monotonic()
    user_id = str(current_user["id"])
    cache_key = f"mctx_v1:{user_id}:{tz}:{meal_type or ''}"

    cached = _cache_get(cache_key)
    if cached:
        logger.debug(f"[MealContext] cache_hit user={user_id[:8]}")
        return cached

    daily_ctx, favs, today_wo = await asyncio.gather(
        fetch_daily_nutrition_context(user_id, tz),
        fetch_recent_favorites(user_id, limit=3, exclude_days=7),
        fetch_todays_workout(user_id, tz),
        return_exceptions=True,
    )

    def _ok(x):
        return x if not isinstance(x, Exception) else None

    dnc = _ok(daily_ctx) or {}
    favs_list = _ok(favs) or []
    wo = _ok(today_wo)
    partial = any(isinstance(r, Exception) for r in (daily_ctx, favs, today_wo))
    if partial:
        for label, val in (("daily_ctx", daily_ctx), ("favs", favs), ("today_wo", today_wo)):
            if isinstance(val, Exception):
                logger.warning(f"[MealContext] {label} fetch failed for user={user_id[:8]}: {val}")

    # Build the response object
    resp = MealContextResponse(
        calorie_remainder=dnc.get("calorie_remainder"),
        total_calories=dnc.get("total_calories", 0) or 0,
        target_calories=dnc.get("target_calories"),
        macros_remaining=MacrosRemaining(
            protein_g=(dnc.get("macros_remaining") or {}).get("protein_g"),
            carbs_g=(dnc.get("macros_remaining") or {}).get("carbs_g"),
            fat_g=(dnc.get("macros_remaining") or {}).get("fat_g"),
        ),
        over_budget=bool(dnc.get("over_budget")),
        meal_types_logged=dnc.get("meal_types_logged", []) or [],
        meal_count=dnc.get("meal_count", 0) or 0,
        ultra_processed_count_today=dnc.get("ultra_processed_count_today", 0) or 0,
        today_workout=TodayWorkoutSummary(**wo) if wo else None,
        has_favorites=len(favs_list) > 0,
        favorites_preview=[
            FavoritePreview(
                id=f.get("id"),
                name=f.get("name", ""),
                total_calories=f.get("total_calories"),
                last_logged_days_ago=f.get("last_logged_days_ago"),
            )
            for f in favs_list
        ],
        meal_type=meal_type,
        timezone=tz,
        context_partial=partial,
        computed_at_ms=int((time.monotonic() - start) * 1000),
    )
    _cache_put(cache_key, resp)
    return resp
