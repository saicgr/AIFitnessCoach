"""Daily/weekly nutrition summaries and targets endpoints."""
import asyncio
from core.db import get_supabase_db
from datetime import datetime, timedelta, date, timezone
from typing import List, Optional, Set

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, get_user_today, to_utc_iso
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from api.v1.nutrition.helpers import resign_food_image_url
from models.schemas import UpdateNutritionTargetsRequest

from api.v1.nutrition.models import (
    FoodLogResponse,
    DailyNutritionResponse,
    WeeklyNutritionResponse,
    NutritionTargetsResponse,
    OptionalTrackersResponse,
    TrackerSeriesPoint,
)

from core.redis_cache import RedisCache
# Cross-module invalidation: a target change alters aggregates rendered by the
# Patterns tab and the home bootstrap payload, so both must be busted too.
from api.v1.nutrition.food_patterns import invalidate_patterns_cache
from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache

router = APIRouter()
logger = get_logger(__name__)

# 60s cache for daily summaries — prevents redundant DB hits on tab switches
_daily_summary_cache = RedisCache(prefix="nutrition_daily", ttl_seconds=60, max_size=100)


async def invalidate_daily_summary_cache(user_id: str, date: str = None):
    """Invalidate the cached daily summary after a meal is logged/deleted.

    The cache key is ``{user_id}:{local_date}`` where ``local_date`` is the
    USER's timezone-local date (see `get_daily_summary`). When no explicit
    date is given we must NOT guess it from a UTC "today" — for any non-UTC
    user that misses the real key, so a stale pre-log summary keeps serving
    and a freshly-logged meal appears to vanish on the next refetch. So bust
    EVERY cached date for this user via a prefix delete (keys are per-user,
    they re-populate in one query)."""
    if date:
        await _daily_summary_cache.delete(f"{user_id}:{date}")
    else:
        await _daily_summary_cache.delete_prefix(f"{user_id}:")

async def _apply_burn_fields(
    db, user_id: str, local_date: str, user_tz: str, response: "DailyNutritionResponse"
) -> None:
    """F4 — overlay live exercise-burn fields onto a daily summary in place.

    Sets ``calories_burned_today`` / ``net_calorie_remainder`` / ``burn_adjusted``
    on ``response`` using the SAME logic as the nutrition-agent context helper
    (active energy only, de-duped across sources, clamped to [0,4000], gated on
    the ``adjust_calories_for_training`` preference). When the pref is off or
    burn==0, ``burn_adjusted=False`` and ``net_calorie_remainder`` mirrors the
    plain remainder (or stays null when no calorie target is set). Best-effort:
    any failure leaves the macro summary untouched (burn fields default to 0/
    null/false). Runs off the cache so the burn term is never stale."""
    try:
        from services.langgraph_agents.tools.nutrition_context_helpers import (
            _fetch_active_calories_and_pref,
        )
        burned, pref_on = await _fetch_active_calories_and_pref(
            user_id, local_date, user_tz
        )
        response.calories_burned_today = burned

        targets = await asyncio.get_event_loop().run_in_executor(
            None, lambda: db.get_user_nutrition_targets(user_id)
        )
        cal_target = (targets or {}).get("daily_calorie_target")
        if cal_target is None:
            response.net_calorie_remainder = None
            response.burn_adjusted = False
            return

        base_remainder = int(cal_target) - int(response.total_calories or 0)
        burn_adjusted = bool(pref_on and burned > 0)
        response.burn_adjusted = burn_adjusted
        response.net_calorie_remainder = (
            base_remainder + burned if burn_adjusted else base_remainder
        )
    except Exception as e:
        logger.warning(f"[F4] burn-field overlay skipped for {user_id}: {e}")


@router.get("/summary/daily/{user_id}", response_model=DailyNutritionResponse)
async def get_daily_summary(
    user_id: str,
    request: Request,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
    tz: Optional[str] = Query(default=None, description="IANA timezone fallback (e.g. America/Chicago)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get daily nutrition summary for a user.

    Returns total calories, macros, and list of meals for the day.
    """
    try:
        db = get_supabase_db()
        # `tz` query param is a client-supplied fallback so day-boundary
        # queries work even when the X-User-Timezone header is absent (e.g.
        # cold start before prefs are loaded). Header still takes priority via
        # resolve_timezone; we only use `tz` if resolution would otherwise fall
        # back to UTC.
        user_tz = resolve_timezone(request, db, user_id)
        if user_tz == "UTC" and tz:
            from core.timezone_utils import _is_valid_tz  # type: ignore[attr-defined]
            if _is_valid_tz(tz):
                user_tz = tz

        if date is None:
            date = get_user_today(user_tz)

        # Check cache first (60s TTL)
        cache_key = f"{user_id}:{date}"
        cached = await _daily_summary_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache hit for daily summary {cache_key}")
            resp = DailyNutritionResponse(**cached)
            # F4 — the BURN term must never be served stale (active energy can
            # change minute-to-minute as HealthKit/Google Fit sync). Recompute
            # it live on a cache hit and overlay it on the cached macro totals.
            await _apply_burn_fields(db, user_id, date, user_tz, resp)
            return resp

        logger.info(f"Getting daily nutrition summary for user {user_id}, date={date}, tz={user_tz}")

        # Get summary (timezone-aware) — includes meals, no need to query again.
        # The Supabase client is synchronous; run it in a thread so the blocking
        # DB round-trip doesn't stall this async worker's event loop (which, under
        # concurrent load, would serialize every other request on the worker).
        summary = await asyncio.get_event_loop().run_in_executor(
            None,
            lambda: db.get_daily_nutrition_summary(user_id, date, timezone_str=user_tz),
        )

        meal_responses = []
        for log in (summary.get("meals") or [])[:20]:
            meal_responses.append(FoodLogResponse(
                id=log.get("id"),
                user_id=log.get("user_id"),
                meal_type=log.get("meal_type"),
                logged_at=to_utc_iso(log.get("logged_at")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                health_score_reasons=log.get("health_score_reasons"),
                ai_feedback=log.get("ai_feedback"),
                notes=log.get("notes"),
                mood_before=log.get("mood_before"),
                mood_after=log.get("mood_after"),
                energy_level=log.get("energy_level"),
                inflammation_score=log.get("inflammation_score"),
                is_ultra_processed=log.get("is_ultra_processed"),
                # Row-level provenance — drives the thumbnail / source icon in the
                # nutrition tab. Omitted here previously, which meant image-logged
                # foods rendered without their photo in the daily summary view.
                image_url=resign_food_image_url(log.get("image_url")),
                source_type=log.get("source_type"),
                user_query=log.get("user_query"),
                idempotency_key=log.get("idempotency_key"),
                # Key micronutrients (optional surfacing in row detail)
                sodium_mg=log.get("sodium_mg"),
                sugar_g=log.get("sugar_g"),
                saturated_fat_g=log.get("saturated_fat_g"),
                cholesterol_mg=log.get("cholesterol_mg"),
                potassium_mg=log.get("potassium_mg"),
                calcium_mg=log.get("calcium_mg"),
                iron_mg=log.get("iron_mg"),
                vitamin_a_ug=log.get("vitamin_a_ug"),
                vitamin_c_mg=log.get("vitamin_c_mg"),
                vitamin_d_iu=log.get("vitamin_d_iu"),
                vitamin_e_mg=log.get("vitamin_e_mg"),
                vitamin_k_ug=log.get("vitamin_k_ug"),
                vitamin_b6_mg=log.get("vitamin_b6_mg"),
                vitamin_b12_ug=log.get("vitamin_b12_ug"),
                vitamin_b9_ug=log.get("vitamin_b9_ug"),
                magnesium_mg=log.get("magnesium_mg"),
                zinc_mg=log.get("zinc_mg"),
                phosphorus_mg=log.get("phosphorus_mg"),
                selenium_ug=log.get("selenium_ug"),
                copper_mg=log.get("copper_mg"),
                manganese_mg=log.get("manganese_mg"),
                omega3_g=log.get("omega3_g"),
                created_at=to_utc_iso(log.get("created_at") or log.get("logged_at")),
            ))

        response = DailyNutritionResponse(
            date=date,
            total_calories=summary.get("total_calories", 0) or 0,
            total_protein_g=summary.get("total_protein_g", 0) or 0,
            total_carbs_g=summary.get("total_carbs_g", 0) or 0,
            total_fat_g=summary.get("total_fat_g", 0) or 0,
            total_fiber_g=summary.get("total_fiber_g", 0) or 0,
            meal_count=summary.get("meal_count", 0) or 0,
            avg_health_score=summary.get("avg_health_score"),
            meals=meal_responses,
        )

        # Cache the response BEFORE overlaying the (live) burn term so the
        # cached payload stays burn-neutral — the burn fields are recomputed on
        # every cache hit (see above) and on this cold path just below.
        await _daily_summary_cache.set(cache_key, response.dict())

        # F4 — burn-adjusted remainder (live).
        await _apply_burn_fields(db, user_id, date, user_tz, response)

        return response

    except Exception as e:
        logger.error(f"Failed to get daily summary: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/optional-trackers/{user_id}", response_model=OptionalTrackersResponse)
async def get_optional_trackers(
    user_id: str,
    request: Request,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
    tz: Optional[str] = Query(default=None, description="IANA timezone fallback"),
    days: int = Query(default=1, ge=1, le=30, description="How many trailing days of history to include in `series`"),
    current_user: dict = Depends(get_current_user),
):
    """Gap 7 — today's added-sugar / caffeine / alcohol totals + the user's
    per-tracker limits and on/off flags. Sums micronutrients already stored on
    each food log (no new extraction); the client renders a counter card per
    enabled tracker with an over-limit nudge. When ``days``>1, also returns a
    daily `series` (oldest→newest) for the per-tracker detail screen."""
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        if user_tz == "UTC" and tz:
            from core.timezone_utils import _is_valid_tz  # type: ignore[attr-defined]
            if _is_valid_tz(tz):
                user_tz = tz
        if date is None:
            date = get_user_today(user_tz)

        def _sum_day(day_str: str) -> tuple:
            s = db.get_daily_nutrition_summary(user_id, day_str, timezone_str=user_tz)
            sug = caf = alc = 0.0
            for log in (s.get("meals") or []):
                sug += float(log.get("added_sugar_g") or log.get("sugar_g") or 0)
                caf += float(log.get("caffeine_mg") or 0)
                alc += float(log.get("alcohol_g") or 0)
            return sug, caf, alc

        # Today's totals (always) + optional trailing history.
        from datetime import date as _date_cls
        base_day = _date_cls.fromisoformat(date)

        def _build():
            today = _sum_day(date)
            hist = []
            if days > 1:
                for i in range(days - 1, -1, -1):
                    d = (base_day - timedelta(days=i)).isoformat()
                    sug, caf, alc = (today if d == date else _sum_day(d))
                    hist.append((d, sug, caf, alc))
            return today, hist

        (sugar_g, caffeine_mg, alcohol_g), history = await asyncio.get_event_loop().run_in_executor(
            None, _build
        )

        # Read the user's tracker flags + limits from nutrition_preferences.
        flags = {}
        try:
            res = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: db.client.table("nutrition_preferences")
                .select(
                    "sugar_tracking_enabled, caffeine_tracking_enabled, "
                    "alcohol_tracking_enabled, sugar_limit_g, caffeine_limit_mg, "
                    "alcohol_limit_units"
                )
                .eq("user_id", user_id)
                .maybe_single()
                .execute(),
            )
            flags = (res.data if res and res.data else {}) or {}
        except Exception as e:
            logger.debug(f"optional-trackers prefs read fell back to defaults: {e}")

        # 1 US standard drink ≈ 14 g of pure ethanol.
        def _units(g: float) -> float:
            return round(g / 14.0, 1) if g else 0.0

        series = [
            TrackerSeriesPoint(
                date=d,
                sugar_g=round(sug, 1),
                caffeine_mg=round(caf, 1),
                alcohol_units=_units(alc),
            )
            for (d, sug, caf, alc) in history
        ]

        return OptionalTrackersResponse(
            date=date,
            sugar_tracking_enabled=bool(flags.get("sugar_tracking_enabled", False)),
            caffeine_tracking_enabled=bool(flags.get("caffeine_tracking_enabled", False)),
            alcohol_tracking_enabled=bool(flags.get("alcohol_tracking_enabled", False)),
            sugar_g=round(sugar_g, 1),
            caffeine_mg=round(caffeine_mg, 1),
            alcohol_units=_units(alcohol_g),
            sugar_limit_g=int(flags.get("sugar_limit_g") or 36),
            caffeine_limit_mg=int(flags.get("caffeine_limit_mg") or 400),
            alcohol_limit_units=int(flags.get("alcohol_limit_units") or 2),
            series=series,
        )
    except Exception as e:
        logger.error(f"Failed to get optional trackers: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/summary/weekly/{user_id}", response_model=WeeklyNutritionResponse)
async def get_weekly_summary(
    user_id: str,
    request: Request,
    current_user: dict = Depends(get_current_user),
    start_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD), defaults to 7 days ago"),
):
    """
    Get weekly nutrition summary for a user.

    Returns daily summaries for 7 days starting from start_date.
    """
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        if start_date is None:
            from datetime import timedelta
            from zoneinfo import ZoneInfo
            user_now = datetime.now(ZoneInfo(user_tz) if user_tz != "UTC" else ZoneInfo("UTC"))
            start_date = (user_now - timedelta(days=6)).strftime("%Y-%m-%d")

        logger.info(f"Getting weekly nutrition summary for user {user_id}, start_date={start_date}, tz={user_tz}")

        # Get weekly summary (timezone-aware)
        daily_summaries = db.get_weekly_nutrition_summary(user_id, start_date, timezone_str=user_tz)

        # Calculate totals
        total_calories = 0
        total_meals = 0

        for day in daily_summaries:
            total_calories += day.get("total_calories", 0) or 0
            total_meals += day.get("meal_count", 0) or 0

        days_with_data = len([d for d in daily_summaries if d.get("total_calories")])
        avg_daily_calories = total_calories / days_with_data if days_with_data > 0 else 0

        # Calculate end date
        from datetime import timedelta
        start = datetime.strptime(start_date, "%Y-%m-%d")
        end_date = (start + timedelta(days=6)).strftime("%Y-%m-%d")

        return WeeklyNutritionResponse(
            start_date=start_date,
            end_date=end_date,
            daily_summaries=daily_summaries,
            total_calories=total_calories,
            average_daily_calories=avg_daily_calories,
            total_meals=total_meals,
        )

    except Exception as e:
        logger.error(f"Failed to get weekly summary: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/targets/{user_id}", response_model=NutritionTargetsResponse)
async def get_nutrition_targets(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get user's nutrition targets."""
    logger.info(f"Getting nutrition targets for user {user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        targets = db.get_user_nutrition_targets(user_id)

        return NutritionTargetsResponse(
            user_id=user_id,
            daily_calorie_target=targets.get("daily_calorie_target"),
            daily_protein_target_g=targets.get("daily_protein_target_g"),
            daily_carbs_target_g=targets.get("daily_carbs_target_g"),
            daily_fat_target_g=targets.get("daily_fat_target_g"),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition targets: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/targets/{user_id}", response_model=NutritionTargetsResponse)
async def update_nutrition_targets(user_id: str, request: UpdateNutritionTargetsRequest, current_user: dict = Depends(get_current_user)):
    """Update user's nutrition targets."""
    logger.info(f"Updating nutrition targets for user {user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Update targets
        updated = db.update_user_nutrition_targets(
            user_id=user_id,
            daily_calorie_target=request.daily_calorie_target,
            daily_protein_target_g=request.daily_protein_target_g,
            daily_carbs_target_g=request.daily_carbs_target_g,
            daily_fat_target_g=request.daily_fat_target_g,
        )

        # Invalidate every cache whose payload bakes in the calorie/macro
        # goals. Without this a changed target keeps rendering old totals /
        # progress rings until each TTL lapses. All three helpers are
        # user-scoped prefix deletes, so they bust every per-date / per-window
        # variant. Best-effort: a cache miss here must not fail the write.
        try:
            await invalidate_daily_summary_cache(user_id)
            await invalidate_patterns_cache(user_id)
            await invalidate_bootstrap_cache(user_id)
        except Exception as cache_exc:
            logger.warning(
                f"Target update cache invalidation failed for {user_id}: {cache_exc}",
                exc_info=True,
            )

        return NutritionTargetsResponse(
            user_id=user_id,
            daily_calorie_target=updated.get("daily_calorie_target"),
            daily_protein_target_g=updated.get("daily_protein_target_g"),
            daily_carbs_target_g=updated.get("daily_carbs_target_g"),
            daily_fat_target_g=updated.get("daily_fat_target_g"),
        )

    except Exception as e:
        logger.error(f"Failed to update nutrition targets: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ============================================================================
# Training-vs-Rest nutrition split
# ============================================================================
# Compares average protein + calories on TRAINING days vs REST days over a
# rolling window. Answers "do I eat differently when I lift?" Feeds the
# Stats-tab "Fueling: Training vs Rest" card.

class FuelingGroupResponse(BaseModel):
    """Averages for one day-group (training or rest)."""
    avg_protein_g: float
    avg_calories: float
    days: int  # number of LOGGED days in this group (days with >=1 food log)


class TrainingVsRestResponse(BaseModel):
    training: FuelingGroupResponse
    rest: FuelingGroupResponse


def _completed_workout_local_dates(
    db, user_id: str, start_iso: str, tz_name: str
) -> Set[str]:
    """Return the set of user-local ISO dates (YYYY-MM-DD) on which the user
    completed at least one logged set.

    Source of truth: `performance_logs` (the per-set table used by the volume
    trend + PR pipeline). A day is a "training day" if it has >=1 completed
    set with reps_completed > 0. recorded_at is UTC timestamptz; we convert to
    the user's local date so a late-night session lands on the right calendar
    day. NO fabrication — a user with no logged sets gets an empty set and
    every day is classified as rest.
    """
    from zoneinfo import ZoneInfo

    tz = ZoneInfo(tz_name) if tz_name and tz_name != "UTC" else timezone.utc
    # Pad the lower bound by 1 day so a UTC timestamp just before the local
    # window start still gets considered (re-bucketed by local date below).
    cutoff = (
        datetime.fromisoformat(f"{start_iso}T00:00:00")
        .replace(tzinfo=tz) - timedelta(days=1)
    ).astimezone(timezone.utc)

    rows = (
        db.client.table("performance_logs")
        .select("recorded_at, reps_completed, is_completed")
        .eq("user_id", user_id)
        .gte("recorded_at", cutoff.isoformat())
        .execute()
    )

    out: Set[str] = set()
    for row in (rows.data or []):
        if row.get("is_completed") is False:
            continue
        reps = row.get("reps_completed")
        if not isinstance(reps, (int, float)) or reps <= 0:
            continue
        ra = row.get("recorded_at")
        if not ra:
            continue
        try:
            ts = datetime.fromisoformat(str(ra).replace("Z", "+00:00"))
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            out.add(ts.astimezone(tz).date().isoformat())
        except Exception:
            continue
    return out


@router.get("/training-vs-rest/{user_id}", response_model=TrainingVsRestResponse)
@router.get("/training-vs-rest", response_model=TrainingVsRestResponse)
async def get_training_vs_rest(
    request: Request,
    user_id: Optional[str] = None,
    days: int = Query(30, ge=1, le=180, description="Rolling window size in days"),
    tz: Optional[str] = Query(default=None, description="IANA tz fallback (e.g. America/Chicago)"),
    current_user: dict = Depends(get_current_user),
):
    """Average protein + calories on training days vs rest days.

    For each of the last `days` calendar days in the user's local timezone:
      - Classify the day as TRAINING (>=1 completed logged set that date) or
        REST (no completed set that date).
      - Pull that day's nutrition totals via get_daily_nutrition_summary
        (timezone-aware, the same helper the daily summary card uses).
      - Only days that actually have food logged (total_calories>0 OR
        meal_count>0) are averaged — unlogged days would drag both averages
        toward zero and lie about intake. `days` in each group reflects the
        count of LOGGED days, so the client can show "n=X days".

    Volume is irrelevant here; calories are kcal and protein is grams, both as
    stored. NO fabrication: groups with no logged days return zeros + days=0.
    """
    # Path param wins; query param `user_id` is not accepted (path-only here).
    if user_id is None:
        raise HTTPException(status_code=422, detail="user_id is required")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        user_tz = resolve_timezone(request, db, user_id)
        if user_tz == "UTC" and tz:
            from core.timezone_utils import _is_valid_tz  # type: ignore[attr-defined]
            if _is_valid_tz(tz):
                user_tz = tz

        today_local = date.fromisoformat(get_user_today(user_tz))
        # Inclusive window: today and the previous (days-1) days.
        start_local = today_local - timedelta(days=days - 1)

        training_dates = _completed_workout_local_dates(
            db, user_id, start_local.isoformat(), user_tz
        )

        train_cal = train_protein = 0.0
        train_days = 0
        rest_cal = rest_protein = 0.0
        rest_days = 0

        cursor = start_local
        while cursor <= today_local:
            d_iso = cursor.isoformat()
            summary = db.get_daily_nutrition_summary(
                user_id, d_iso, timezone_str=user_tz
            )
            calories = float(summary.get("total_calories") or 0)
            protein = float(summary.get("total_protein_g") or 0)
            meal_count = int(summary.get("meal_count") or 0)

            # Skip days with nothing logged — they are not "0 calorie days",
            # they are simply unobserved. Including them would understate both
            # averages and mislead the user. (feedback_no_silent_fallbacks +
            # feedback_no_dashboard_deferral: surface only honest observations.)
            if meal_count > 0 or calories > 0:
                if d_iso in training_dates:
                    train_cal += calories
                    train_protein += protein
                    train_days += 1
                else:
                    rest_cal += calories
                    rest_protein += protein
                    rest_days += 1

            cursor += timedelta(days=1)

        def _avg(total: float, n: int) -> float:
            return round(total / n, 1) if n > 0 else 0.0

        logger.info(
            f"🥗 [training-vs-rest] user={user_id} days={days} "
            f"train_days={train_days} rest_days={rest_days}"
        )

        return TrainingVsRestResponse(
            training=FuelingGroupResponse(
                avg_protein_g=_avg(train_protein, train_days),
                avg_calories=_avg(train_cal, train_days),
                days=train_days,
            ),
            rest=FuelingGroupResponse(
                avg_protein_g=_avg(rest_protein, rest_days),
                avg_calories=_avg(rest_cal, rest_days),
                days=rest_days,
            ),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get training-vs-rest split: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

