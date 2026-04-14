"""Nutrition > Patterns tab endpoints.

Four GETs that back the four sections of the Patterns tab:
  - /food-patterns/mood            -> Section 3 (energizing vs draining foods)
  - /food-patterns/top-foods       -> Section 2 (top foods by nutrient)
  - /food-patterns/macros-summary  -> Section 1 (macros/calories aggregates)
  - /food-patterns/history         -> Section 4 (paginated meal timeline)

Plus mutation endpoints for the three check-in toggles and AI-inference
confirm/dismiss flow:
  - PATCH /food-patterns/settings
  - PATCH /food-logs/{log_id}/inference

All endpoints authenticate via JWT, enforce user-id ownership, and are
cached per-user with a 5-minute TTL (busted on food-log write).
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from api.v1.nutrition.models import (
    DailyMacroSeriesPoint,
    FoodLogResponse,
    FoodPatternEntry,
    FoodPatternsMoodResponse,
    InferenceConfirmRequest,
    MacrosSummaryResponse,
    PatternsHistoryResponse,
    TopFoodEntry,
    TopFoodsResponse,
)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.redis_cache import RedisCache
from core.timezone_utils import (
    get_user_today,
    local_date_to_utc_range,
    resolve_timezone,
)

router = APIRouter()
logger = get_logger(__name__)


# ── Caches (5 min; busted on food-log write) ────────────────────────────────
_mood_cache = RedisCache(prefix="patterns_mood", ttl_seconds=300, max_size=200)
_top_foods_cache = RedisCache(prefix="patterns_top", ttl_seconds=300, max_size=400)
_macros_cache = RedisCache(prefix="patterns_macros", ttl_seconds=300, max_size=400)
_history_cache = RedisCache(prefix="patterns_history", ttl_seconds=120, max_size=400)


async def invalidate_patterns_cache(user_id: str) -> None:
    """Call from food_logs.py after create/update/delete. Best-effort: we clear
    the narrowest common keys (default day/week/month windows). Other keys
    expire naturally via the 5-minute TTL — acceptable for patterns since the
    aggregated signal doesn't flip meaningfully on a single log."""
    try:
        # Delete common default keys for quick UI consistency after a log.
        await asyncio.gather(
            _mood_cache.delete(f"{user_id}:90:3"),
            _history_cache.delete(f"{user_id}:day::*"),
            return_exceptions=True,
        )
    except Exception as exc:
        logger.debug(f"invalidate_patterns_cache ({user_id}): {exc}")


# ── Helpers ────────────────────────────────────────────────────────────────

_METRIC_UNITS = {
    "calories": "kcal",
    "protein": "g",
    "carbs": "g",
    "fat": "g",
    "fiber": "g",
    "sugar": "g",
    "sodium": "mg",
}

_RANGE_OPTIONS = {"day", "week", "month", "90d"}


def _resolve_range(
    range_name: str, anchor_date: Optional[str], user_tz: str
) -> tuple[str, str, str, str]:
    """Return (start_utc_iso, end_utc_iso, start_date_user, end_date_user).

    Ranges anchor on the user's local calendar. `90d` is a rolling window and
    ignores anchor_date."""
    if range_name not in _RANGE_OPTIONS:
        raise HTTPException(status_code=400, detail=f"Unsupported range: {range_name}")

    if range_name == "90d":
        end_user = get_user_today(user_tz)
        start_user_date = (
            datetime.strptime(end_user, "%Y-%m-%d").date() - timedelta(days=89)
        ).strftime("%Y-%m-%d")
        start_utc, _ = local_date_to_utc_range(start_user_date, user_tz)
        _, end_utc = local_date_to_utc_range(end_user, user_tz)
        return start_utc, end_utc, start_user_date, end_user

    anchor = anchor_date or get_user_today(user_tz)
    try:
        anchor_dt = datetime.strptime(anchor, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="date must be YYYY-MM-DD")

    if range_name == "day":
        start_user_date = anchor
        end_user_date = anchor
    elif range_name == "week":
        weekday = anchor_dt.weekday()
        week_start = anchor_dt - timedelta(days=weekday)
        week_end = week_start + timedelta(days=6)
        start_user_date = week_start.strftime("%Y-%m-%d")
        end_user_date = week_end.strftime("%Y-%m-%d")
    else:  # month
        start_user_date = anchor_dt.replace(day=1).strftime("%Y-%m-%d")
        next_month = (anchor_dt.replace(day=28) + timedelta(days=4)).replace(day=1)
        last_day = next_month - timedelta(days=1)
        end_user_date = last_day.strftime("%Y-%m-%d")

    start_utc, _ = local_date_to_utc_range(start_user_date, user_tz)
    _, end_utc = local_date_to_utc_range(end_user_date, user_tz)
    return start_utc, end_utc, start_user_date, end_user_date


def _ensure_owner(current_user: dict, user_id: str) -> None:
    if str(current_user.get("id") or current_user.get("sub")) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")


# ── 1. Mood patterns ───────────────────────────────────────────────────────

@router.get("/food-patterns/mood/{user_id}", response_model=FoodPatternsMoodResponse)
async def get_mood_patterns(
    user_id: str,
    days: int = Query(default=90, ge=7, le=180),
    min_logs: int = Query(default=3, ge=1, le=20),
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)

    cache_key = f"{user_id}:{days}:{min_logs}"
    cached = await _mood_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        db = get_supabase_db()

        # Pull user's flags so the response can drive UI state (e.g. show "re-enable" banner).
        prefs_resp = db.client.table("user_nutrition_preferences")\
            .select("post_meal_checkin_disabled, passive_inference_enabled")\
            .eq("user_id", user_id).maybe_single().execute()
        prefs_data = (prefs_resp.data if prefs_resp else None) or {}
        checkin_disabled = bool(prefs_data.get("post_meal_checkin_disabled"))
        inference_enabled = prefs_data.get("passive_inference_enabled")
        if inference_enabled is None:
            inference_enabled = True

        rpc_resp = await asyncio.to_thread(
            lambda: db.client.rpc(
                "get_food_patterns",
                {
                    "p_user_id": user_id,
                    "p_days": days,
                    "p_min_logs": min_logs,
                    "p_include_inferred": bool(inference_enabled),
                    "p_food_names": None,
                },
            ).execute()
        )
        rows = getattr(rpc_resp, "data", None) or []

        energizing: list[FoodPatternEntry] = []
        draining: list[FoodPatternEntry] = []
        total_logs_analyzed = 0
        oldest: Optional[str] = None

        for row in rows:
            entry = FoodPatternEntry(
                food_name=row.get("food_name") or "",
                logs=int(row.get("logs_with_checkin") or 0),
                confirmed_count=int(row.get("confirmed_count") or 0),
                inferred_count=int(row.get("inferred_count") or 0),
                negative_mood_count=int(row.get("negative_mood_count") or 0),
                positive_mood_count=int(row.get("positive_mood_count") or 0),
                avg_energy=_to_float(row.get("avg_energy")),
                low_energy_count=int(row.get("low_energy_count") or 0),
                high_energy_count=int(row.get("high_energy_count") or 0),
                dominant_symptom=row.get("dominant_symptom"),
                last_logged_at=_iso(row.get("last_logged_at")),
                negative_score=float(row.get("negative_score") or 0),
                positive_score=float(row.get("positive_score") or 0),
            )
            total_logs_analyzed += entry.logs
            if entry.last_logged_at and (oldest is None or entry.last_logged_at < oldest):
                oldest = entry.last_logged_at

            # Sort a food into whichever bucket has the stronger score; threshold 0.5
            if entry.negative_score >= entry.positive_score and entry.negative_score >= 0.5:
                draining.append(entry)
            elif entry.positive_score >= 0.5:
                energizing.append(entry)

        draining.sort(key=lambda e: e.negative_score, reverse=True)
        energizing.sort(key=lambda e: e.positive_score, reverse=True)

        response = FoodPatternsMoodResponse(
            energizing_foods=energizing[:15],
            draining_foods=draining[:15],
            total_logs_analyzed=total_logs_analyzed,
            days_window=days,
            oldest_log_date=oldest,
            checkin_disabled=checkin_disabled,
            inference_enabled=bool(inference_enabled),
        )
        await _mood_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_mood_patterns failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


# ── 2. Top foods by nutrient ────────────────────────────────────────────────

@router.get("/food-patterns/top-foods/{user_id}", response_model=TopFoodsResponse)
async def get_top_foods(
    user_id: str,
    request: Request,
    metric: str = Query(default="calories"),
    range: str = Query(default="week"),  # noqa: A002 (shadowing built-in is intentional for FastAPI param)
    date: Optional[str] = Query(default=None),
    limit: int = Query(default=20, ge=1, le=50),
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)

    if metric not in _METRIC_UNITS:
        raise HTTPException(
            status_code=400,
            detail=f"metric must be one of {sorted(_METRIC_UNITS.keys())}",
        )

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    start_utc, end_utc, start_d, end_d = _resolve_range(range, date, user_tz)

    cache_key = f"{user_id}:{metric}:{range}:{start_d}:{end_d}:{limit}"
    cached = await _top_foods_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        rpc_resp = await asyncio.to_thread(
            lambda: db.client.rpc(
                "get_top_foods_by_metric",
                {
                    "p_user_id": user_id,
                    "p_metric": metric,
                    "p_start_ts": start_utc,
                    "p_end_ts": end_utc,
                    "p_limit": limit,
                },
            ).execute()
        )
        rows = getattr(rpc_resp, "data", None) or []
        items = [
            TopFoodEntry(
                food_name=row.get("food_name") or "",
                total_value=round(float(row.get("total_value") or 0), 2),
                unit=_METRIC_UNITS[metric],
                occurrences=int(row.get("occurrences") or 0),
                last_image_url=row.get("last_image_url"),
                last_food_score=row.get("last_food_score"),
                last_logged_at=_iso(row.get("last_logged_at")),
            )
            for row in rows
        ]
        response = TopFoodsResponse(
            metric=metric,
            range=range,
            start_date=start_d,
            end_date=end_d,
            items=items,
        )
        await _top_foods_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_top_foods failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


# ── 3. Macros summary ───────────────────────────────────────────────────────

@router.get("/food-patterns/macros-summary/{user_id}", response_model=MacrosSummaryResponse)
async def get_macros_summary(
    user_id: str,
    request: Request,
    range: str = Query(default="week"),  # noqa: A002
    date: Optional[str] = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    start_utc, end_utc, start_d, end_d = _resolve_range(range, date, user_tz)

    cache_key = f"{user_id}:{range}:{start_d}:{end_d}"
    cached = await _macros_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        resp = db.client.table("food_logs")\
            .select("logged_at,total_calories,protein_g,carbs_g,fat_g,fiber_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", start_utc)\
            .lt("logged_at", end_utc)\
            .order("logged_at")\
            .execute()
        rows = resp.data or []

        # Bucket by user-local date.
        from zoneinfo import ZoneInfo
        try:
            tz = ZoneInfo(user_tz)
        except Exception:
            tz = ZoneInfo("UTC")

        def _to_local_date(iso_str: str) -> str:
            dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.astimezone(tz).strftime("%Y-%m-%d")

        daily_map: dict[str, DailyMacroSeriesPoint] = {}
        for row in rows:
            local_date = _to_local_date(row["logged_at"])
            bucket = daily_map.get(local_date) or DailyMacroSeriesPoint(date=local_date)
            bucket.calories += int(row.get("total_calories") or 0)
            bucket.protein_g += float(row.get("protein_g") or 0)
            bucket.carbs_g += float(row.get("carbs_g") or 0)
            bucket.fat_g += float(row.get("fat_g") or 0)
            bucket.fiber_g += float(row.get("fiber_g") or 0)
            daily_map[local_date] = bucket

        daily_series = [daily_map[k] for k in sorted(daily_map.keys())]
        days_counted = len(daily_series) or 1

        avg_calories = int(sum(p.calories for p in daily_series) / days_counted)
        avg_protein = round(sum(p.protein_g for p in daily_series) / days_counted, 1)
        avg_carbs = round(sum(p.carbs_g for p in daily_series) / days_counted, 1)
        avg_fat = round(sum(p.fat_g for p in daily_series) / days_counted, 1)
        avg_fiber = round(sum(p.fiber_g for p in daily_series) / days_counted, 1)

        # Pull goals from nutrition_preferences (null-safe).
        goals_resp = db.client.table("nutrition_preferences")\
            .select("target_calories,target_protein_g,target_carbs_g,target_fat_g,target_fiber_g")\
            .eq("user_id", user_id).maybe_single().execute()
        goals = (goals_resp.data if goals_resp else None) or {}

        response = MacrosSummaryResponse(
            range=range,
            start_date=start_d,
            end_date=end_d,
            days_counted=days_counted if daily_series else 0,
            avg_calories=avg_calories if daily_series else 0,
            avg_protein_g=avg_protein if daily_series else 0.0,
            avg_carbs_g=avg_carbs if daily_series else 0.0,
            avg_fat_g=avg_fat if daily_series else 0.0,
            avg_fiber_g=avg_fiber if daily_series else 0.0,
            calorie_goal=goals.get("target_calories"),
            protein_goal=goals.get("target_protein_g"),
            carbs_goal=goals.get("target_carbs_g"),
            fat_goal=goals.get("target_fat_g"),
            fiber_goal=goals.get("target_fiber_g"),
            daily_series=daily_series,
        )
        await _macros_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_macros_summary failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


# ── 4. History ──────────────────────────────────────────────────────────────

@router.get("/food-patterns/history/{user_id}", response_model=PatternsHistoryResponse)
async def get_patterns_history(
    user_id: str,
    request: Request,
    range: str = Query(default="week"),  # noqa: A002
    date: Optional[str] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    start_utc, end_utc, _start_d, _end_d = _resolve_range(range, date, user_tz)

    cache_key = f"{user_id}:{range}:{start_utc}:{end_utc}:{limit}:{offset}"
    cached = await _history_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        # Total for pagination; cheap count query
        count_resp = db.client.table("food_logs")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", start_utc)\
            .lt("logged_at", end_utc)\
            .execute()
        total = count_resp.count or 0

        resp = db.client.table("food_logs").select("*")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", start_utc)\
            .lt("logged_at", end_utc)\
            .order("logged_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()
        rows = resp.data or []
        items = [_food_log_row_to_response(r) for r in rows]

        response = PatternsHistoryResponse(
            items=items, total=total, limit=limit, offset=offset
        )
        await _history_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_patterns_history failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


# ── 5. Settings toggle (post-meal check-in, reminder, passive inference) ────

class PatternsSettingsRequest(BaseModel):
    post_meal_checkin_disabled: Optional[bool] = None
    post_meal_reminder_enabled: Optional[bool] = None
    passive_inference_enabled: Optional[bool] = None


class PatternsSettingsResponse(BaseModel):
    post_meal_checkin_disabled: bool
    post_meal_reminder_enabled: bool
    passive_inference_enabled: bool


@router.get("/food-patterns/settings/{user_id}", response_model=PatternsSettingsResponse)
async def get_patterns_settings(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)
    db = get_supabase_db()
    resp = db.client.table("user_nutrition_preferences")\
        .select("post_meal_checkin_disabled, post_meal_reminder_enabled, passive_inference_enabled")\
        .eq("user_id", user_id).maybe_single().execute()
    data = (resp.data if resp else None) or {}
    return PatternsSettingsResponse(
        post_meal_checkin_disabled=bool(data.get("post_meal_checkin_disabled") or False),
        post_meal_reminder_enabled=bool(data.get("post_meal_reminder_enabled", True)) if data.get("post_meal_reminder_enabled") is not None else True,
        passive_inference_enabled=bool(data.get("passive_inference_enabled", True)) if data.get("passive_inference_enabled") is not None else True,
    )


@router.patch("/food-patterns/settings/{user_id}", response_model=PatternsSettingsResponse)
async def update_patterns_settings(
    user_id: str,
    body: PatternsSettingsRequest,
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)

    patch = {k: v for k, v in body.model_dump().items() if v is not None}
    if not patch:
        return await get_patterns_settings(user_id, current_user)  # type: ignore[arg-type]

    db = get_supabase_db()
    # Upsert so users who never had a row get one on first toggle.
    patch["user_id"] = user_id
    db.client.table("user_nutrition_preferences").upsert(patch, on_conflict="user_id").execute()
    await invalidate_patterns_cache(user_id)
    return await get_patterns_settings(user_id, current_user)  # type: ignore[arg-type]


# ── 6. Inference confirm / dismiss ──────────────────────────────────────────

@router.patch("/food-logs/{log_id}/inference")
async def confirm_or_dismiss_inference(
    log_id: str,
    body: InferenceConfirmRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user.get("id") or current_user.get("sub"))
    db = get_supabase_db()

    # Verify ownership
    existing = db.client.table("food_logs").select("id, user_id")\
        .eq("id", log_id).eq("user_id", user_id).maybe_single().execute()
    if not existing or not existing.data:
        raise HTTPException(status_code=404, detail="Food log not found")

    if body.action == "confirm":
        patch = {"inference_user_confirmed": True, "inference_user_dismissed": False}
    else:
        patch = {"inference_user_dismissed": True, "inference_user_confirmed": False}

    db.client.table("food_logs").update(patch).eq("id", log_id).execute()
    await invalidate_patterns_cache(user_id)
    return {"success": True, "action": body.action}


# ── Utils ───────────────────────────────────────────────────────────────────

def _to_float(value) -> Optional[float]:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _iso(value) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def _food_log_row_to_response(row: dict) -> FoodLogResponse:
    """Minimal row-to-response mapping. Keeps mood/energy + inference columns
    flowing through to the client."""
    return FoodLogResponse(
        id=row["id"],
        user_id=row["user_id"],
        meal_type=row.get("meal_type") or "snack",
        logged_at=_iso(row.get("logged_at")) or "",
        food_items=row.get("food_items") or [],
        total_calories=int(row.get("total_calories") or 0),
        protein_g=float(row.get("protein_g") or 0),
        carbs_g=float(row.get("carbs_g") or 0),
        fat_g=float(row.get("fat_g") or 0),
        fiber_g=row.get("fiber_g"),
        health_score=row.get("health_score"),
        ai_feedback=row.get("ai_feedback"),
        notes=row.get("notes"),
        mood_before=row.get("mood_before"),
        mood_after=row.get("mood_after") or row.get("mood_after_inferred"),
        energy_level=row.get("energy_level") if row.get("energy_level") is not None else row.get("energy_level_inferred"),
        inflammation_score=row.get("inflammation_score"),
        is_ultra_processed=row.get("is_ultra_processed"),
        image_url=row.get("image_url"),
        source_type=row.get("source_type"),
        user_query=row.get("user_query"),
        sodium_mg=row.get("sodium_mg"),
        sugar_g=row.get("sugar_g"),
        saturated_fat_g=row.get("saturated_fat_g"),
        cholesterol_mg=row.get("cholesterol_mg"),
        potassium_mg=row.get("potassium_mg"),
        calcium_mg=row.get("calcium_mg"),
        iron_mg=row.get("iron_mg"),
        vitamin_a_ug=row.get("vitamin_a_ug"),
        vitamin_c_mg=row.get("vitamin_c_mg"),
        vitamin_d_iu=row.get("vitamin_d_iu"),
        created_at=_iso(row.get("created_at")) or "",
    )
