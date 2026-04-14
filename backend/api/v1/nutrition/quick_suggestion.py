"""One-tap meal suggestion endpoint for the home-screen widget / Siri / Action Button.

Contract: given a user and (optional) meal type, return a single structured
meal suggestion with emoji, title, calories, macros, and component food items
ready for auto-logging. No chat markdown — the widget renders native UI.

Cost guardrails:
  - Per-user, per-meal-slot, per-hour in-memory cache (30 min TTL) means a
    widget that reloads every 15 min only pays for one Gemini call per slot.
  - Structured output with a tight pydantic schema keeps `max_output_tokens`
    small (<400) and forces valid JSON, so there is no parsing fallback path.
  - Transient Gemini failures serve the last cached payload marked `stale=True`
    instead of erroring the widget.
"""
from __future__ import annotations

import asyncio
import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from google.genai import types
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter
from models.gemini_schemas import (
    QuickSuggestionFoodItem,
    QuickSuggestionGeminiResponse,
)
from services.gemini.constants import gemini_generate_with_retry
from services.langgraph_agents.tools.nutrition_context_helpers import (
    fetch_daily_nutrition_context,
    fetch_recent_favorites,
    fetch_todays_workout,
)

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


# ─── Response model ────────────────────────────────────────────────────────

class QuickSuggestionResponse(BaseModel):
    """Shape consumed by the iOS/Android widget and Flutter service."""

    emoji: str = Field(..., description="One-glyph meal summary emoji")
    meal_slot: str = Field(..., description="breakfast|lunch|dinner|snack|fasting")
    title: str = Field(..., description="Short meal title")
    subtitle: str = Field(..., description="One-line reasoning")
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    food_items: List[QuickSuggestionFoodItem] = Field(default_factory=list)
    generated_at: str = Field(..., description="ISO8601 UTC timestamp")
    cache_until: str = Field(..., description="ISO8601 UTC timestamp")
    stale: bool = Field(default=False, description="True if Gemini call failed and we served stale cache")
    logged_already: List[str] = Field(
        default_factory=list,
        description="Meal types already logged today; the widget can show '✓ Breakfast logged' in subtitle",
    )


# ─── Module-level in-process cache (30 min TTL) ─────────────────────────────

# Keyed by (user_id, meal_slot, hour_bucket). Matches the /meal-context cache
# pattern in chat_meal_context.py — no Redis round-trip for the happy path.
_CACHE: Dict[str, Tuple[float, QuickSuggestionResponse]] = {}
_CACHE_TTL_SECONDS = 30 * 60
_CACHE_MAX = 2000


def _cache_get(key: str) -> Optional[QuickSuggestionResponse]:
    hit = _CACHE.get(key)
    if not hit:
        return None
    ts, payload = hit
    if time.time() - ts > _CACHE_TTL_SECONDS:
        _CACHE.pop(key, None)
        return None
    return payload


def _cache_put(key: str, value: QuickSuggestionResponse) -> None:
    _CACHE[key] = (time.time(), value)
    if len(_CACHE) > _CACHE_MAX:
        # Evict oldest 10% when over capacity — cheap linear scan, fine at this size.
        drop_n = _CACHE_MAX // 10
        oldest = sorted(_CACHE.items(), key=lambda kv: kv[1][0])[:drop_n]
        for k, _ in oldest:
            _CACHE.pop(k, None)


# ─── Meal-slot inference ───────────────────────────────────────────────────

# Simple time-of-day table. The widget's wife-user is in Central US so summer
# DST is handled by zoneinfo. Boundaries chosen to bias toward "suggest the
# next meal" (e.g. 10am → lunch, 4pm → dinner) so a mid-slot tap still useful.
_SLOT_TABLE: List[Tuple[int, int, str]] = [
    (4, 10, "breakfast"),
    (10, 15, "lunch"),
    (15, 21, "dinner"),
    (21, 24, "snack"),
    (0, 4, "snack"),  # late-night wraparound
]


def _infer_slot(tz_str: str, logged_today: List[str]) -> str:
    """Pick the next meal slot based on local time + already-logged meals.

    Strategy:
      1. Compute the natural slot for the current local hour.
      2. If that slot is already logged, roll forward to the next un-logged
         slot in breakfast → lunch → dinner → snack order. This is what makes
         the widget "auto-advance" throughout the day — user logs breakfast,
         widget immediately shows a lunch idea.
    """
    try:
        now_local = datetime.now(ZoneInfo(tz_str))
    except ZoneInfoNotFoundError:
        now_local = datetime.utcnow()
    hour = now_local.hour
    natural = "snack"
    for lo, hi, slot in _SLOT_TABLE:
        if lo <= hour < hi:
            natural = slot
            break

    order = ["breakfast", "lunch", "dinner", "snack"]
    logged_lower = {(s or "").lower() for s in logged_today}
    if natural not in logged_lower:
        return natural
    # Roll forward from natural position.
    try:
        start_idx = order.index(natural)
    except ValueError:
        start_idx = 0
    for offset in range(1, len(order) + 1):
        candidate = order[(start_idx + offset) % len(order)]
        if candidate not in logged_lower:
            return candidate
    return "snack"  # all logged — rare; show a snack idea


# ─── Prompt builder ────────────────────────────────────────────────────────

_SYSTEM_INSTRUCTION = (
    "You are a pragmatic nutrition coach generating ONE meal suggestion for a home-screen widget. "
    "Be specific and realistic (real foods, normal portions, supermarket ingredients). "
    "Pick ONE meal that fits the user's remaining macros; do not return options or alternatives. "
    "Prefer the user's recent favorites when the macros fit. "
    "Keep the title under 40 characters and the subtitle under 80 characters. "
    "Subtitle must explain in one sentence why this fits (e.g., 'Leaves 40g protein for dinner after leg day'). "
    "Ingredient components must sum approximately to the totals (±5 cal / ±1 g)."
)


def _build_prompt(
    meal_slot: str,
    daily_ctx: Dict[str, Any],
    favs: List[Dict[str, Any]],
    workout: Optional[Dict[str, Any]],
) -> str:
    """Compact user message packed with everything the LLM needs in one shot."""
    cal_rem = daily_ctx.get("calorie_remainder")
    macros_rem = daily_ctx.get("macros_remaining") or {}
    target_cal = daily_ctx.get("target_calories")
    over = daily_ctx.get("over_budget")
    meal_types = daily_ctx.get("meal_types_logged") or []

    lines = [
        f"Meal slot: {meal_slot}",
        f"Calories remaining today: {cal_rem if cal_rem is not None else 'unknown (no target)'}",
        f"Daily target: {target_cal if target_cal is not None else 'unknown'} kcal",
        f"Macros remaining — "
        f"P: {macros_rem.get('protein_g', '?')}g  "
        f"C: {macros_rem.get('carbs_g', '?')}g  "
        f"F: {macros_rem.get('fat_g', '?')}g",
        f"Over budget: {bool(over)}",
        f"Meals already logged today: {', '.join(meal_types) if meal_types else 'none'}",
    ]
    if workout:
        wo_name = workout.get("name") or "Workout"
        done = "done" if workout.get("is_completed") else "planned"
        muscles = workout.get("primary_muscles") or []
        lines.append(
            f"Today's workout: {wo_name} ({done})"
            + (f" · primary: {', '.join(muscles)}" if muscles else "")
        )
    if favs:
        fav_lines = ", ".join(
            f"{f.get('name')} ({int(f.get('total_calories') or 0)} cal)"
            for f in favs[:5]
        )
        lines.append(f"User favorites (prefer when they fit): {fav_lines}")

    lines.append(
        "\nReturn ONE meal suggestion as structured JSON. "
        "Include 1-4 food_items whose calories/macros sum to the totals."
    )
    return "\n".join(lines)


# ─── Gemini call ───────────────────────────────────────────────────────────

async def _generate_suggestion(
    user_id: str,
    meal_slot: str,
    daily_ctx: Dict[str, Any],
    favs: List[Dict[str, Any]],
    workout: Optional[Dict[str, Any]],
) -> QuickSuggestionGeminiResponse:
    prompt = _build_prompt(meal_slot, daily_ctx, favs, workout)
    response = await gemini_generate_with_retry(
        model=settings.gemini_model,
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=_SYSTEM_INSTRUCTION,
            response_mime_type="application/json",
            response_schema=QuickSuggestionGeminiResponse,
            max_output_tokens=600,
            temperature=0.6,  # some variety across refreshes
        ),
        user_id=user_id,
        method_name="quick_meal_suggestion",
        timeout=20,
    )
    parsed = response.parsed
    if parsed is None:
        raise RuntimeError("Gemini returned an unparseable quick-suggestion response")
    return parsed


# ─── Endpoint ──────────────────────────────────────────────────────────────

@router.get("/quick-suggestion", response_model=QuickSuggestionResponse)
@limiter.limit("20/minute")
async def get_quick_suggestion(
    request: Request,  # required by slowapi limiter
    meal_type: Optional[str] = Query(
        default=None,
        max_length=20,
        description="Force a specific meal slot: breakfast|lunch|dinner|snack. "
                    "Omit (default) to let the server infer from local time + logged meals.",
    ),
    tz: str = Query(
        default="UTC",
        max_length=64,
        description="IANA timezone name (e.g. America/Chicago)",
    ),
    current_user: dict = Depends(get_current_user),
) -> QuickSuggestionResponse:
    """Return one structured meal suggestion for the widget.

    Cache-key granularity is (user, slot, hour-bucket) — two calls within the
    same hour return the exact same suggestion, so the widget's 15-min
    timeline reload is free. User taps Refresh → we bypass cache via the
    `?force=true` query param (not yet exposed; v2).
    """
    start = time.monotonic()
    user_id = str(current_user["id"])

    # Parallel context fetch — same helpers the chat meal-context endpoint uses.
    daily_ctx_r, favs_r, workout_r = await asyncio.gather(
        fetch_daily_nutrition_context(user_id, tz),
        fetch_recent_favorites(user_id, limit=5, exclude_days=0),
        fetch_todays_workout(user_id, tz),
        return_exceptions=True,
    )

    # Fallback: any individual failure degrades gracefully — Gemini still has
    # enough to suggest something sensible from the meal slot alone.
    daily_ctx = daily_ctx_r if not isinstance(daily_ctx_r, Exception) else {}
    favs = favs_r if not isinstance(favs_r, Exception) else []
    workout = workout_r if not isinstance(workout_r, Exception) else None
    if any(isinstance(r, Exception) for r in (daily_ctx_r, favs_r, workout_r)):
        for label, val in (("daily_ctx", daily_ctx_r), ("favs", favs_r), ("workout", workout_r)):
            if isinstance(val, Exception):
                logger.warning(f"[QuickSuggestion] {label} fetch failed for user={user_id[:8]}: {val}")

    # Resolve meal slot.
    logged_today = (daily_ctx or {}).get("meal_types_logged") or []
    if meal_type and meal_type.lower() in {"breakfast", "lunch", "dinner", "snack"}:
        slot = meal_type.lower()
    else:
        slot = _infer_slot(tz, logged_today)

    # Cache: hour-bucket within the slot so the suggestion is stable for up
    # to an hour and refreshes on the next hour naturally even without user action.
    hour_bucket = datetime.utcnow().strftime("%Y%m%d%H")
    cache_key = f"qs:{user_id}:{slot}:{hour_bucket}"
    cached = _cache_get(cache_key)
    if cached is not None:
        logger.debug(f"[QuickSuggestion] cache_hit user={user_id[:8]} slot={slot}")
        return cached

    # Gemini call — on failure, serve the most recent cached value (any slot,
    # any hour) for this user so the widget never shows a hard error.
    now_utc = datetime.utcnow()
    try:
        parsed = await _generate_suggestion(user_id, slot, daily_ctx or {}, favs, workout)
    except Exception as e:
        logger.warning(f"[QuickSuggestion] Gemini failed for user={user_id[:8]}: {e}")
        fallback = _find_any_cached_for_user(user_id)
        if fallback is not None:
            # Mark stale so the widget can show a subtle "updating…" indicator.
            stale_copy = fallback.model_copy(update={"stale": True})
            return stale_copy
        raise HTTPException(
            status_code=503,
            detail="Meal suggestion temporarily unavailable. Please try again shortly.",
        )

    cache_until = now_utc.replace(minute=(now_utc.minute // 30) * 30 + 30, second=0, microsecond=0)
    resp = QuickSuggestionResponse(
        emoji=parsed.emoji,
        meal_slot=slot,
        title=parsed.title.strip()[:60],
        subtitle=parsed.subtitle.strip()[:120],
        calories=int(parsed.calories),
        protein_g=round(float(parsed.protein_g), 1),
        carbs_g=round(float(parsed.carbs_g), 1),
        fat_g=round(float(parsed.fat_g), 1),
        food_items=parsed.food_items or [],
        generated_at=now_utc.isoformat(timespec="seconds") + "Z",
        cache_until=cache_until.isoformat(timespec="seconds") + "Z",
        stale=False,
        logged_already=[s for s in logged_today if s],
    )
    _cache_put(cache_key, resp)
    logger.info(
        f"[QuickSuggestion] generated user={user_id[:8]} slot={slot} "
        f"cal={resp.calories} took_ms={int((time.monotonic() - start) * 1000)}"
    )
    return resp


def _find_any_cached_for_user(user_id: str) -> Optional[QuickSuggestionResponse]:
    """Find the most recent cached suggestion for this user, any slot/hour.

    Used as a soft fallback when Gemini fails — better to show yesterday's
    lunch idea than a hard error in a home-screen widget.
    """
    prefix = f"qs:{user_id}:"
    best_ts = 0.0
    best_val: Optional[QuickSuggestionResponse] = None
    for k, (ts, val) in _CACHE.items():
        if k.startswith(prefix) and ts > best_ts:
            best_ts = ts
            best_val = val
    return best_val
