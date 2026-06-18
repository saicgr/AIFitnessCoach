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

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from api.v1.nutrition.models import (
    BucketFood,
    DailyMacroSeriesPoint,
    DigestionLogRequest,
    DigestionLogResponse,
    DigestionPatternsResponse,
    DigestionRegularityPoint,
    DigestionSeriesPoint,
    DigestionTagCorrelation,
    FoodLogResponse,
    FoodPatternEntry,
    FoodPatternsMoodResponse,
    InferenceConfirmRequest,
    MacrosBaseline,
    MacrosSummaryResponse,
    NutrientGoal,
    NutrientTrack,
    PatternBucket,
    PatternsHistoryResponse,
    SymptomCorrelationEntry,
    SymptomCounts,
    TagCorrelationEntry,
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
    """Call from food_logs.py after create/update/delete (and from any write
    that changes nutrition aggregates, e.g. a target update).

    Every Patterns cache key is user-scoped and prefixed ``{user_id}:`` — the
    remainder embeds free-form variation (``days``/``min_logs`` for mood,
    ``metric``/``range``/date-window for top-foods + macros, and pagination
    ``limit``/``offset`` for history). Deleting only a couple of hardcoded
    default keys leaves every other variant serving stale data. So bust the
    whole per-user namespace for all four caches via a SCAN prefix delete;
    keys re-populate in one query on the next read."""
    try:
        prefix = f"{user_id}:"
        await asyncio.gather(
            _mood_cache.delete_prefix(prefix),
            _top_foods_cache.delete_prefix(prefix),
            _macros_cache.delete_prefix(prefix),
            _history_cache.delete_prefix(prefix),
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
    range_name: str,
    anchor_date: Optional[str],
    user_tz: str,
    days_override: Optional[int] = None,
) -> tuple[str, str, str, str]:
    """Return (start_utc_iso, end_utc_iso, start_date_user, end_date_user).

    Ranges anchor on the user's local calendar. `90d` is a rolling window and
    ignores anchor_date.

    When [days_override] is supplied it takes priority over [range_name] and
    produces a rolling window of exactly that many days ending today. This is
    used by the Trends engine, which needs arbitrary windows (180d / 365d /
    all-time) that the fixed day/week/month/90d buckets don't cover. A value of
    0 means "all history" — we cap it at 5 years to bound the query."""
    if days_override is not None and days_override >= 0:
        end_user = get_user_today(user_tz)
        # 0 ⇒ all history (capped at ~5y so the DB query stays bounded).
        span = days_override if days_override > 0 else 1825
        start_user_date = (
            datetime.strptime(end_user, "%Y-%m-%d").date()
            - timedelta(days=span - 1)
        ).strftime("%Y-%m-%d")
        start_utc, _ = local_date_to_utc_range(start_user_date, user_tz)
        _, end_utc = local_date_to_utc_range(end_user, user_tz)
        return start_utc, end_utc, start_user_date, end_user

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

        # Run the mood/energy RPC and the new symptom/tag correlation RPC
        # concurrently — both read food_logs over the same window.
        rpc_resp, corr_resp = await asyncio.gather(
            asyncio.to_thread(
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
            ),
            asyncio.to_thread(
                lambda: db.client.rpc(
                    "get_symptom_tag_correlations",
                    {
                        "p_user_id": user_id,
                        "p_days": days,
                        # min_logs for correlation buckets is intentionally lower
                        # than the per-food check-in threshold — a tag→symptom
                        # link is meaningful at 2 co-occurrences.
                        "p_min_logs": min(2, min_logs),
                    },
                ).execute()
            ),
            return_exceptions=True,
        )
        if isinstance(rpc_resp, Exception):
            raise rpc_resp
        rows = getattr(rpc_resp, "data", None) or []
        # Correlation RPC is additive context — never fail the endpoint on it.
        if isinstance(corr_resp, Exception):
            logger.warning(f"symptom/tag correlations skipped for {user_id}: {corr_resp}")
            corr_rows = []
        else:
            corr_rows = getattr(corr_resp, "data", None) or []

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
                symptom_counts=SymptomCounts(
                    bloated=int(row.get("bloated_count") or 0),
                    tired=int(row.get("tired_count") or 0),
                    stressed=int(row.get("stressed_count") or 0),
                    sluggish=int(row.get("sluggish_count") or 0),
                    foggy=int(row.get("foggy_count") or 0),
                    nauseous=int(row.get("nauseous_count") or 0),
                    energized=int(row.get("energized_count") or 0),
                    satisfied=int(row.get("satisfied_count") or 0),
                    good_digestion=int(row.get("good_digestion_count") or 0),
                    bloated_pct=float(row.get("bloated_pct") or 0),
                    tired_pct=float(row.get("tired_pct") or 0),
                    energized_pct=float(row.get("energized_pct") or 0),
                ),
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

        # Split the flattened correlation rows into the two typed buckets.
        symptom_correlations: list[SymptomCorrelationEntry] = []
        tag_correlations: list[TagCorrelationEntry] = []
        for cr in corr_rows:
            kind = cr.get("bucket_kind")
            if kind == "symptom":
                symptom_correlations.append(SymptomCorrelationEntry(
                    symptom=cr.get("symptom") or "",
                    food_name=cr.get("food_name") or "",
                    occurrences=int(cr.get("occurrences") or 0),
                    total_with_signal=int(cr.get("total_with_signal") or 0),
                    pct=float(cr.get("pct") or 0),
                    last_image_url=cr.get("last_image_url"),
                    last_logged_at=_iso(cr.get("last_logged_at")),
                ))
            elif kind == "tag":
                tag_correlations.append(TagCorrelationEntry(
                    tag=cr.get("tag") or "",
                    symptom=cr.get("symptom") or "",
                    occurrences=int(cr.get("occurrences") or 0),
                    total_with_signal=int(cr.get("total_with_signal") or 0),
                    pct=float(cr.get("pct") or 0),
                    last_image_url=cr.get("last_image_url"),
                    last_logged_at=_iso(cr.get("last_logged_at")),
                ))

        # FE-D card shape — group the flat correlation entries into buckets.
        # symptom_buckets: one per symptom, top contributing foods.
        # tag_buckets: one per tag, the symptoms it precedes (symptom carried in
        # the BucketFood.food_name slot so the card renders uniformly).
        symptom_buckets = _group_buckets(
            symptom_correlations,
            key_of=lambda e: e.symptom,
            food_of=lambda e: BucketFood(
                food_name=e.food_name, image_url=e.last_image_url,
                occurrences=e.occurrences, last_logged_at=e.last_logged_at,
            ),
        )
        tag_buckets = _group_buckets(
            tag_correlations,
            key_of=lambda e: e.tag,
            food_of=lambda e: BucketFood(
                food_name=e.symptom, image_url=e.last_image_url,
                occurrences=e.occurrences, last_logged_at=e.last_logged_at,
            ),
        )

        response = FoodPatternsMoodResponse(
            energizing_foods=energizing[:15],
            draining_foods=draining[:15],
            total_logs_analyzed=total_logs_analyzed,
            days_window=days,
            oldest_log_date=oldest,
            checkin_disabled=checkin_disabled,
            inference_enabled=bool(inference_enabled),
            symptom_correlations=symptom_correlations[:30],
            tag_correlations=tag_correlations[:30],
            symptom_buckets=symptom_buckets,
            tag_buckets=tag_buckets,
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
    days: Optional[int] = Query(
        default=None,
        ge=0,
        le=1825,
        description=(
            "Rolling-window override in days (Trends engine). When set, "
            "supersedes `range`; 0 means all history."
        ),
    ),
    baseline: bool = Query(
        default=False,
        description=(
            "When true, also compute the average over the immediately-"
            "preceding window of the same length (e.g. current 4wk vs prior "
            "weeks) and return per-macro delta + trend in `baseline`."
        ),
    ),
    include_baseline: bool = Query(
        default=False,
        description="FE-D alias for `baseline` — enables the baseline + nutrient_tracks fields.",
    ),
    baseline_weeks: Optional[int] = Query(
        default=None, ge=1, le=52,
        description=(
            "FE-D — current/baseline window length in WEEKS (e.g. 4 ⇒ 28-day "
            "current vs prior 28 days). Sets the rolling window when `days` is "
            "not supplied."
        ),
    ),
    current_user: dict = Depends(get_current_user),
):
    _ensure_owner(current_user, user_id)

    # FE-D aliasing: include_baseline ⇒ baseline; baseline_weeks ⇒ days window.
    baseline = baseline or include_baseline
    if baseline_weeks and days is None:
        days = baseline_weeks * 7

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    start_utc, end_utc, start_d, end_d = _resolve_range(
        range, date, user_tz, days_override=days
    )

    cache_key = f"{user_id}:{range}:days{days}:{start_d}:{end_d}:b{int(baseline)}"
    cached = await _macros_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
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

        def _window_avgs(win_start_utc: str, win_end_utc: str):
            """Return (daily_series, days_counted, avgs-dict) for a UTC window."""
            wresp = db.client.table("food_logs")\
                .select("logged_at,total_calories,protein_g,carbs_g,fat_g,fiber_g")\
                .eq("user_id", user_id)\
                .is_("deleted_at", "null")\
                .gte("logged_at", win_start_utc)\
                .lt("logged_at", win_end_utc)\
                .order("logged_at")\
                .execute()
            wrows = wresp.data or []
            dmap: dict[str, DailyMacroSeriesPoint] = {}
            for row in wrows:
                ld = _to_local_date(row["logged_at"])
                bucket = dmap.get(ld) or DailyMacroSeriesPoint(date=ld)
                bucket.calories += int(row.get("total_calories") or 0)
                bucket.protein_g += float(row.get("protein_g") or 0)
                bucket.carbs_g += float(row.get("carbs_g") or 0)
                bucket.fat_g += float(row.get("fat_g") or 0)
                bucket.fiber_g += float(row.get("fiber_g") or 0)
                dmap[ld] = bucket
            series = [dmap[k] for k in sorted(dmap.keys())]
            n = len(series)
            denom = n or 1
            avgs = {
                "calories": int(sum(p.calories for p in series) / denom) if n else 0,
                "protein_g": round(sum(p.protein_g for p in series) / denom, 1) if n else 0.0,
                "carbs_g": round(sum(p.carbs_g for p in series) / denom, 1) if n else 0.0,
                "fat_g": round(sum(p.fat_g for p in series) / denom, 1) if n else 0.0,
                "fiber_g": round(sum(p.fiber_g for p in series) / denom, 1) if n else 0.0,
            }
            return series, n, avgs

        daily_series, days_counted, cur = _window_avgs(start_utc, end_utc)

        # Pull goals from nutrition_preferences (null-safe).
        goals_resp = db.client.table("nutrition_preferences")\
            .select("target_calories,target_protein_g,target_carbs_g,target_fat_g,target_fiber_g")\
            .eq("user_id", user_id).maybe_single().execute()
        goals = (goals_resp.data if goals_resp else None) or {}

        baseline_obj: Optional[MacrosBaseline] = None
        if baseline:
            # The prior window is the same calendar length, immediately before
            # the current one. Compute it on the user's local calendar then map
            # to UTC, mirroring _resolve_range.
            try:
                cur_start = datetime.strptime(start_d, "%Y-%m-%d").date()
                cur_end = datetime.strptime(end_d, "%Y-%m-%d").date()
                span_days = (cur_end - cur_start).days + 1
                prior_end = cur_start - timedelta(days=1)
                prior_start = prior_end - timedelta(days=span_days - 1)
                prior_start_s = prior_start.strftime("%Y-%m-%d")
                prior_end_s = prior_end.strftime("%Y-%m-%d")
                p_start_utc, _ = local_date_to_utc_range(prior_start_s, user_tz)
                _, p_end_utc = local_date_to_utc_range(prior_end_s, user_tz)
                _pser, prior_n, prior = _window_avgs(p_start_utc, p_end_utc)

                def _trend(delta: float, eps: float) -> str:
                    if delta > eps:
                        return "up"
                    if delta < -eps:
                        return "down"
                    return "flat"

                cal_d = (cur["calories"] - prior["calories"])
                p_d = round(cur["protein_g"] - prior["protein_g"], 1)
                c_d = round(cur["carbs_g"] - prior["carbs_g"], 1)
                f_d = round(cur["fat_g"] - prior["fat_g"], 1)
                fib_d = round(cur["fiber_g"] - prior["fiber_g"], 1)
                baseline_obj = MacrosBaseline(
                    prior_start_date=prior_start_s,
                    prior_end_date=prior_end_s,
                    prior_days_counted=prior_n,
                    current_days_counted=days_counted,
                    prior_avg_calories=prior["calories"],
                    prior_avg_protein_g=prior["protein_g"],
                    prior_avg_carbs_g=prior["carbs_g"],
                    prior_avg_fat_g=prior["fat_g"],
                    prior_avg_fiber_g=prior["fiber_g"],
                    calories_delta=cal_d,
                    protein_delta_g=p_d,
                    carbs_delta_g=c_d,
                    fat_delta_g=f_d,
                    fiber_delta_g=fib_d,
                    calories_trend=_trend(cal_d, 25),       # ±25 kcal = flat
                    protein_trend=_trend(p_d, 2),           # ±2 g = flat
                    carbs_trend=_trend(c_d, 5),
                    fat_trend=_trend(f_d, 2),
                    fiber_trend=_trend(fib_d, 1),
                )
            except Exception as be:
                # Baseline is additive — never fail the summary on it.
                logger.warning(f"macros baseline skipped for {user_id}: {be}")
                baseline_obj = None

        # FE-D card shape — goals[] + nutrient_tracks[] + window labels. Built
        # only when baseline is requested (tracks need the prior-window avg the
        # baseline computed). Fail-open: any miss leaves the lists empty.
        nut_goals: list[NutrientGoal] = []
        nut_tracks: list[NutrientTrack] = []
        current_label: Optional[str] = None
        baseline_label: Optional[str] = None
        if baseline:
            try:
                _wk = baseline_weeks or max(1, round((days or days_counted or 28) / 7))
                current_label = "This month" if _wk == 4 else f"Last {_wk} wks"
                baseline_label = f"Prev {_wk} wks"
                _specs = [
                    ("calories", "Calories", "kcal", "calories",
                     goals.get("target_calories"), lambda p: p.calories),
                    ("protein", "Protein", "g", "protein_g",
                     goals.get("target_protein_g"), lambda p: p.protein_g),
                    ("carbs", "Carbs", "g", "carbs_g",
                     goals.get("target_carbs_g"), lambda p: p.carbs_g),
                    ("fat", "Fat", "g", "fat_g",
                     goals.get("target_fat_g"), lambda p: p.fat_g),
                    ("fiber", "Fiber", "g", "fiber_g",
                     goals.get("target_fiber_g"), lambda p: p.fiber_g),
                ]
                for key, label, unit, cur_key, goal_val, series_fn in _specs:
                    cur_val = cur.get(cur_key, 0)
                    nut_goals.append(NutrientGoal(
                        key=key, label=label,
                        current=float(cur_val or 0),
                        goal=float(goal_val) if goal_val is not None else None,
                        unit=unit,
                    ))
                    base_val = None
                    if baseline_obj is not None:
                        base_val = float(getattr(baseline_obj, f"prior_avg_{cur_key}", 0) or 0)
                    nut_tracks.append(NutrientTrack(
                        key=key, label=label,
                        current=float(cur_val or 0),
                        goal=float(goal_val) if goal_val is not None else None,
                        baseline=base_val,
                        unit=unit,
                        series=[round(float(series_fn(p) or 0), 1) for p in daily_series],
                    ))
            except Exception as ne:
                logger.warning(f"macros nutrient_tracks skipped for {user_id}: {ne}")
                nut_goals = []
                nut_tracks = []

        response = MacrosSummaryResponse(
            range=range,
            start_date=start_d,
            end_date=end_d,
            days_counted=days_counted if daily_series else 0,
            avg_calories=cur["calories"] if daily_series else 0,
            avg_protein_g=cur["protein_g"] if daily_series else 0.0,
            avg_carbs_g=cur["carbs_g"] if daily_series else 0.0,
            avg_fat_g=cur["fat_g"] if daily_series else 0.0,
            avg_fiber_g=cur["fiber_g"] if daily_series else 0.0,
            calorie_goal=goals.get("target_calories"),
            protein_goal=goals.get("target_protein_g"),
            carbs_goal=goals.get("target_carbs_g"),
            fat_goal=goals.get("target_fat_g"),
            fiber_goal=goals.get("target_fiber_g"),
            daily_series=daily_series,
            baseline=baseline_obj,
            goals=nut_goals,
            nutrient_tracks=nut_tracks,
            current_label=current_label,
            baseline_label=baseline_label,
        )
        await _macros_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_macros_summary failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


# ── 3b. Micronutrients summary (Custom Trends) ──────────────────────────────

# Every micronutrient column on food_logs (migration 038). Daily SUMS of each
# are returned so the Custom Trends chart can plot any single micronutrient.
_MICRO_COLUMNS = [
    "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu", "vitamin_e_mg",
    "vitamin_k_ug", "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg",
    "vitamin_b5_mg", "vitamin_b6_mg", "vitamin_b7_ug", "vitamin_b9_ug",
    "vitamin_b12_ug", "choline_mg", "calcium_mg", "iron_mg", "magnesium_mg",
    "zinc_mg", "selenium_ug", "potassium_mg", "sodium_mg", "phosphorus_mg",
    "copper_mg", "manganese_mg", "iodine_ug", "chromium_ug", "molybdenum_ug",
    "omega3_g", "omega6_g", "saturated_fat_g", "trans_fat_g",
    "monounsaturated_fat_g", "polyunsaturated_fat_g", "cholesterol_mg",
    "sugar_g", "added_sugar_g", "caffeine_mg", "alcohol_g",
]

_micros_cache = RedisCache(prefix="patterns_micros", ttl_seconds=300, max_size=400)


class MicrosDailyPoint(BaseModel):
    date: str
    # Per-day SUM of each micronutrient. Populated dynamically.

    class Config:
        extra = "allow"


class MicrosSummaryResponse(BaseModel):
    range: str
    start_date: str
    end_date: str
    days_counted: int
    micronutrient_columns: list[str]
    daily_series: list[dict]


@router.get("/food-patterns/micros-summary/{user_id}", response_model=MicrosSummaryResponse)
async def get_micros_summary(
    user_id: str,
    request: Request,
    range: str = Query(default="week"),  # noqa: A002
    date: Optional[str] = Query(default=None),
    days: Optional[int] = Query(
        default=None, ge=0, le=1825,
        description=(
            "Rolling-window override in days (Trends engine). When set, "
            "supersedes `range`; 0 means all history."
        ),
    ),
    current_user: dict = Depends(get_current_user),
):
    """Per-day SUMS of every micronutrient column on food_logs (migration 038).

    Mirrors `macros-summary`: a `days` rolling window bucketed by the user's
    local date. Days with no food logs are simply absent from `daily_series`.
    """
    _ensure_owner(current_user, user_id)

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    start_utc, end_utc, start_d, end_d = _resolve_range(
        range, date, user_tz, days_override=days
    )

    cache_key = f"{user_id}:{range}:days{days}:{start_d}:{end_d}"
    cached = await _micros_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        select_cols = "logged_at," + ",".join(_MICRO_COLUMNS)
        resp = db.client.table("food_logs")\
            .select(select_cols)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", start_utc)\
            .lt("logged_at", end_utc)\
            .order("logged_at")\
            .execute()
        rows = resp.data or []

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

        # date -> {col: running sum}
        daily_map: dict[str, dict] = {}
        for row in rows:
            local_date = _to_local_date(row["logged_at"])
            bucket = daily_map.get(local_date)
            if bucket is None:
                bucket = {col: 0.0 for col in _MICRO_COLUMNS}
                daily_map[local_date] = bucket
            for col in _MICRO_COLUMNS:
                val = row.get(col)
                if val is not None:
                    try:
                        bucket[col] += float(val)
                    except (TypeError, ValueError):
                        pass

        daily_series = []
        for d in sorted(daily_map.keys()):
            bucket = daily_map[d]
            point = {"date": d}
            for col in _MICRO_COLUMNS:
                point[col] = round(bucket[col], 3)
            daily_series.append(point)

        response = MicrosSummaryResponse(
            range=range,
            start_date=start_d,
            end_date=end_d,
            days_counted=len(daily_series),
            micronutrient_columns=_MICRO_COLUMNS,
            daily_series=daily_series,
        )
        await _micros_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_micros_summary failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


# ── 3c. Digestion patterns + log (Phase 6, gut-health) ──────────────────────

_digestion_patterns_cache = RedisCache(
    prefix="patterns_digestion", ttl_seconds=300, max_size=200
)


@router.get(
    "/food-patterns/digestion/{user_id}",
    response_model=DigestionPatternsResponse,
)
async def get_digestion_patterns(
    user_id: str,
    days: int = Query(default=90, ge=7, le=365),
    lag_min_hours: float = Query(default=6, ge=0, le=168),
    lag_max_hours: float = Query(default=72, ge=1, le=336),
    current_user: dict = Depends(get_current_user),
):
    """Regularity series + food-tag→gut correlations over LAGGED windows.

    Digestion lags ingestion (transit up to ~72h), so tag correlations look at
    food consumed in the [lag_min_hours, lag_max_hours] window BEFORE each
    Bristol entry. Fail-open: no data ⇒ empty series + empty correlations."""
    _ensure_owner(current_user, user_id)

    cache_key = f"{user_id}:{days}:{lag_min_hours}:{lag_max_hours}"
    cached = await _digestion_patterns_cache.get(cache_key)
    if cached is not None:
        return cached

    try:
        db = get_supabase_db()
        rpc_resp = await asyncio.to_thread(
            lambda: db.client.rpc(
                "get_digestion_patterns",
                {
                    "p_user_id": user_id,
                    "p_days": days,
                    "p_lag_min_hours": lag_min_hours,
                    "p_lag_max_hours": lag_max_hours,
                    "p_min_logs": 2,
                },
            ).execute()
        )
        rows = getattr(rpc_resp, "data", None) or []

        regularity: list[DigestionRegularityPoint] = []
        tag_corr: list[DigestionTagCorrelation] = []
        for r in rows:
            kind = r.get("result_kind")
            if kind == "regularity_day":
                regularity.append(DigestionRegularityPoint(
                    date=r.get("day") or "",
                    worst_bristol=int(r.get("worst_bristol") or 0),
                    avg_bristol=float(r.get("avg_bristol") or 0),
                    entry_count=int(r.get("entry_count") or 0),
                ))
            elif kind == "tag_correlation":
                tag_corr.append(DigestionTagCorrelation(
                    tag=r.get("tag") or "",
                    irregular_count=int(r.get("irregular_count") or 0),
                    regular_count=int(r.get("regular_count") or 0),
                    total_count=int(r.get("total_count") or 0),
                    irregular_pct=float(r.get("irregular_pct") or 0),
                ))

        regularity.sort(key=lambda p: p.date)
        tag_corr.sort(key=lambda t: t.irregular_pct, reverse=True)
        total_entries = sum(p.entry_count for p in regularity)

        # FE-D card shape derived from the same rows.
        series = [
            DigestionSeriesPoint(date=p.date, count=p.entry_count, avg_bristol=p.avg_bristol)
            for p in regularity
        ]
        n_days = len(regularity)
        avg_per_day = round(total_entries / n_days, 2) if n_days else 0.0
        # regularity_pct = share of entries in the ideal 3-5 band, approximated
        # from each day's avg_bristol weighted by that day's entry count.
        ideal_entries = sum(
            p.entry_count for p in regularity if 3.0 <= p.avg_bristol <= 5.0
        )
        regularity_pct = round(ideal_entries / total_entries * 100, 1) if total_entries else 0.0
        # typical_bristol = rounded mean of the per-day averages (modal-ish).
        typical_bristol = (
            round(sum(p.avg_bristol for p in regularity) / n_days) if n_days else None
        )
        # correlations as PatternBucket: one per tag, foods carrying the tag's
        # irregular-count so the card renders like the other Patterns sections.
        correlations = [
            PatternBucket(
                key=t.tag, label=_humanize(t.tag),
                count=t.total_count, confidence_pct=t.irregular_pct,
                foods=[BucketFood(food_name=t.tag, occurrences=t.irregular_count)],
            )
            for t in tag_corr[:20]
        ]

        response = DigestionPatternsResponse(
            days_window=days,
            lag_min_hours=lag_min_hours,
            lag_max_hours=lag_max_hours,
            regularity_series=regularity,
            tag_correlations=tag_corr[:20],
            total_entries=total_entries,
            series=series,
            correlations=correlations,
            avg_per_day=avg_per_day,
            regularity_pct=regularity_pct,
            typical_bristol=typical_bristol,
        )
        await _digestion_patterns_cache.set(cache_key, response.model_dump())
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"get_digestion_patterns failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


@router.post("/digestion", response_model=DigestionLogResponse)
async def create_digestion_log(
    body: DigestionLogRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Write one gut-health (Bristol-scale) entry to digestion_logs.

    Mirrors the food-log POST shape: the owning user is taken from the JWT (never
    trusted from the body). `logged_at` defaults to the user-tz "now" when
    omitted so a quick tap lands on the right day."""
    user_id = str(current_user.get("id") or current_user.get("sub"))
    db = get_supabase_db()

    # Resolve logged_at — explicit ISO wins; else user-tz now (matches log-direct).
    logged_at = body.logged_at
    if not logged_at:
        user_tz = resolve_timezone(request, db, user_id)
        from zoneinfo import ZoneInfo
        try:
            tz = ZoneInfo(user_tz)
        except Exception:
            tz = ZoneInfo("UTC")
        logged_at = datetime.now(tz).isoformat()

    insert = {
        "user_id": user_id,
        "logged_at": logged_at,
        "bristol_type": body.bristol_type,
        "urgency": body.urgency,
        "duration_seconds": body.duration_seconds,
        "tags": body.tags,
        "notes": body.notes,
        "source": body.source or "manual",
    }
    if body.idempotency_key:
        insert["idempotency_key"] = body.idempotency_key

    def _row_to_resp(row: dict) -> DigestionLogResponse:
        return DigestionLogResponse(
            id=str(row.get("id")),
            user_id=str(row.get("user_id")),
            logged_at=_iso(row.get("logged_at")) or logged_at,
            bristol_type=int(row.get("bristol_type")),
            urgency=row.get("urgency"),
            duration_seconds=row.get("duration_seconds"),
            tags=row.get("tags"),
            notes=row.get("notes"),
            source=row.get("source"),
            idempotency_key=row.get("idempotency_key"),
            created_at=_iso(row.get("created_at")) or "",
        )

    try:
        try:
            resp = db.client.table("digestion_logs").insert(insert).execute()
        except Exception as insert_err:
            # Idempotency (migration 2261): a replayed POST (double-tap, offline
            # replay, 401-refresh retry) hits the unique (user_id,
            # idempotency_key) index — return the existing row as success so the
            # client's optimistic UI reconciles to one entry. Mirrors food_logs.
            err_text = str(insert_err).lower()
            is_dupe = body.idempotency_key and (
                "duplicate key" in err_text or "unique" in err_text
                or "23505" in err_text
                or "uq_digestion_logs_user_idempotency_key" in err_text
            )
            if is_dupe:
                existing = (
                    db.client.table("digestion_logs").select("*")
                    .eq("user_id", user_id)
                    .eq("idempotency_key", body.idempotency_key)
                    .limit(1).execute()
                )
                if existing.data:
                    return _row_to_resp(existing.data[0])
            raise
        rows = resp.data or []
        if not rows:
            raise safe_internal_error(
                Exception("insert returned no row"), "nutrition_patterns"
            )
        # Digestion entries change the gut-correlation surface → bust its cache.
        try:
            await _digestion_patterns_cache.delete_prefix(f"{user_id}:")
        except Exception as ce:
            logger.debug(f"digestion cache bust skipped for {user_id}: {ce}")
        return _row_to_resp(rows[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"create_digestion_log failed for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_patterns")


@router.get("/digestion/{user_id}", response_model=list[DigestionLogResponse])
async def list_digestion_logs(
    user_id: str,
    request: Request,
    date_str: Optional[str] = Query(
        default=None,
        description="User-local day (YYYY-MM-DD). When set, returns only that day's entries.",
    ),
    limit: int = Query(default=100, ge=1, le=500),
    current_user: dict = Depends(get_current_user),
):
    """Raw digestion_logs for the gut card. With `date_str`, scoped to that
    user-local day (mirrors the food-log date-window convention)."""
    _ensure_owner(current_user, user_id)
    db = get_supabase_db()
    try:
        q = db.client.table("digestion_logs").select("*").eq("user_id", user_id)
        if date_str and len(date_str) == 10:
            user_tz = resolve_timezone(request, db, user_id)
            start_utc, end_utc = local_date_to_utc_range(date_str, user_tz)
            q = q.gte("logged_at", start_utc).lt("logged_at", end_utc)
        resp = q.order("logged_at", desc=True).limit(limit).execute()
        rows = resp.data or []
        return [
            DigestionLogResponse(
                id=str(r.get("id")),
                user_id=str(r.get("user_id")),
                logged_at=_iso(r.get("logged_at")) or "",
                bristol_type=int(r.get("bristol_type") or 0),
                urgency=r.get("urgency"),
                duration_seconds=r.get("duration_seconds"),
                tags=r.get("tags"),
                notes=r.get("notes"),
                source=r.get("source"),
                idempotency_key=r.get("idempotency_key"),
                created_at=_iso(r.get("created_at")) or "",
            )
            for r in rows
        ]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"list_digestion_logs failed for {user_id}: {e}", exc_info=True)
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

def _humanize(token: str) -> str:
    """'good_digestion' → 'Good Digestion'. Open-vocab safe."""
    if not token:
        return ""
    return token.replace("_", " ").replace("-", " ").strip().title()


def _group_buckets(entries, key_of, food_of):
    """Group flat correlation entries into PatternBucket list (FE-D card shape).

    `key_of(entry)` → the bucket key; `food_of(entry)` → a BucketFood. The
    bucket's `count` is the sum of its foods' occurrences; `confidence_pct` is
    the max single-food pct in the bucket (the strongest co-occurrence). Buckets
    are sorted by count desc; foods within a bucket by occurrences desc."""
    grouped: dict[str, dict] = {}
    for e in entries:
        key = key_of(e)
        if not key:
            continue
        b = grouped.setdefault(key, {"foods": [], "count": 0, "conf": 0.0})
        b["foods"].append(food_of(e))
        b["count"] += int(getattr(e, "occurrences", 0) or 0)
        b["conf"] = max(b["conf"], float(getattr(e, "pct", 0) or 0))
    out: list[PatternBucket] = []
    for key, b in grouped.items():
        foods = sorted(b["foods"], key=lambda f: f.occurrences, reverse=True)[:6]
        out.append(PatternBucket(
            key=key,
            label=_humanize(key),
            count=b["count"],
            confidence_pct=round(b["conf"], 1),
            foods=foods,
        ))
    out.sort(key=lambda x: x.count, reverse=True)
    return out[:12]


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
        health_score_reasons=row.get("health_score_reasons"),
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
        tags=row.get("tags"),
        symptoms=row.get("symptoms"),
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
