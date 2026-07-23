"""Food logging endpoints (image, text, direct)."""
from core.db import get_supabase_db
from datetime import datetime, timedelta, date as date_type
from typing import List, Optional, Tuple
import uuid
import base64
import json
import time
import asyncio

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, UploadFile, File, Form, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today, get_user_now_iso, target_date_to_utc_iso, _safe_zone
from core.rate_limiter import limiter
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from models.schemas import FoodLog, FoodItem

# All micronutrient keys that Gemini can return and food_logs stores
_MICRONUTRIENT_KEYS = [
    # Vitamins
    'vitamin_a_ug', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg', 'vitamin_k_ug',
    'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b6_mg',
    'vitamin_b9_ug', 'vitamin_b12_ug', 'choline_mg',
    # Minerals
    'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'selenium_ug',
    'potassium_mg', 'sodium_mg', 'phosphorus_mg', 'copper_mg', 'manganese_mg', 'iodine_ug',
    # Fatty acids & other
    'omega3_g', 'omega6_g', 'sugar_g', 'cholesterol_mg', 'caffeine_mg',
    # Gap 7 — opt-in tracker inputs (now extracted by the nutrition prompt).
    'alcohol_g', 'added_sugar_g',
]


# Mirror of the food_logs_source_type_check DB constraint (migrations
# 1960/2272/2273). The client can send arbitrary source_type strings, and a
# value outside this set raises a 23514 that surfaces as a 500 (see
# log_food_direct). Coerce anything unrecognized to 'manual' so a future
# client provenance never bricks a log — extend BOTH this set and the DB
# constraint when a new provenance is worth keeping distinct.
_VALID_FOOD_SOURCE_TYPES = frozenset({
    'text', 'image', 'barcode', 'restaurant',
    'menu', 'buffet', 'watch', 'history', 'manual',
    'scheduled_log', 'meal_plan', 'chat',
})


def _normalize_source_type(source_type: Optional[str]) -> str:
    """Clamp a client-supplied source_type to the food_logs DB allowlist.

    Returns 'manual' for None/empty/unknown values so an unexpected client
    provenance can never trip the food_logs_source_type_check (23514).
    """
    if source_type and source_type in _VALID_FOOD_SOURCE_TYPES:
        return source_type
    if source_type and source_type not in _VALID_FOOD_SOURCE_TYPES:
        logger.warning(
            f"[food-log] unknown source_type={source_type!r} coerced to 'manual'"
        )
    return 'manual'


def _extract_micronutrients(food_analysis: dict) -> dict:
    """Extract all micronutrient values from a Gemini food analysis response."""
    micros = {}
    for key in _MICRONUTRIENT_KEYS:
        value = food_analysis.get(key)
        if value is not None:
            micros[key] = value
    return micros


# supabase-py's .execute() is synchronous — run inline in an async handler it
# blocks the event loop for the full DB round-trip, stalling every in-flight
# request (same fix as api/v1/stats.py `_stats_pool`). All pre-response DB
# reads/writes on the food-logging hot path go through this pool.
from concurrent.futures import ThreadPoolExecutor
_foodlog_pool = ThreadPoolExecutor(max_workers=8, thread_name_prefix="foodlog")


async def _run_blocking(fn):
    """Run a blocking DB call in the food-logging thread pool."""
    return await asyncio.get_running_loop().run_in_executor(_foodlog_pool, fn)


async def _is_hydration_tracking_enabled(db, user_id: str) -> bool:
    """Whether the user has hydration tracking on (Gap 6 preference).

    Defaults to True (preserves current always-on behavior) when the preference
    row or column is missing, so this is safe to call before the Gap 6 migration
    has run. When False, the food text/voice logger skips its hydration pre-pass
    entirely — no extra LLM call, matching Amy's opt-out-to-save-cost design.
    """
    try:
        res = await _run_blocking(
            lambda: db.client.table("nutrition_preferences")
            .select("hydration_tracking_enabled")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        if res and res.data and res.data.get("hydration_tracking_enabled") is not None:
            return bool(res.data["hydration_tracking_enabled"])
    except Exception as e:
        logger.debug(f"hydration_tracking_enabled read fell back to default: {e}")
    return True


async def _enrich_log_tips_in_background(
    food_log_id: str,
    user_id: str,
    food_analysis: dict,
    meal_type: Optional[str],
    mood_before: Optional[str],
) -> None:
    """Deferred coach-tips for /log-text cache hits (defer_hit_tips=True).

    Runs AFTER the response is sent: computes the contextual tips Gemini call
    that used to block the endpoint for ~5s, then persists the resulting
    ai_feedback / health_score onto the food_logs row so the log detail view
    still gets its tip on the next fetch. Best-effort — a tips failure must
    never surface as a logging error.
    """
    try:
        from services.food_analysis_cache_service import get_food_analysis_cache_service
        cache_service = get_food_analysis_cache_service()
        await cache_service._enrich_cache_hit_with_tips(
            food_analysis, meal_type, mood_before, user_id
        )
        update: dict = {}
        if food_analysis.get("ai_suggestion"):
            update["ai_feedback"] = food_analysis["ai_suggestion"]
        if food_analysis.get("health_score") is not None:
            update["health_score"] = food_analysis["health_score"]
        if not update:
            return
        db = get_supabase_db()
        await _run_blocking(
            lambda: db.client.table("food_logs")
            .update(update)
            .eq("id", food_log_id)
            .execute()
        )
        # Bust the day-summary cache so the tip shows on the next fetch.
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        await invalidate_daily_summary_cache(user_id)
        logger.info(f"[DeferredTips] persisted tips for log {food_log_id}")
    except Exception as e:
        logger.warning(f"[DeferredTips] enrichment failed for {food_log_id}: {e}")


async def _await_and_persist_text_hydration(
    db, hydration_task, user_id: str, user_tz: Optional[str]
) -> Optional[dict]:
    """Await the Gap-1 hydration detection task and persist any beverage found.

    Returns ``{amount_ml, drink_type}`` when a hydration entry was written, else
    ``None``. Never raises — a hydration failure must not break the food log.
    """
    if hydration_task is None:
        return None
    try:
        detected = await hydration_task
    except Exception as e:
        logger.warning(f"[HydrationSplit] task await failed: {e}")
        return None
    if not detected:
        return None
    try:
        from api.v1.hydration import persist_hydration_entry
        from core.timezone_utils import get_user_today

        local_date = get_user_today(user_tz) if user_tz else None
        if not local_date:
            from datetime import date as _date
            local_date = _date.today().isoformat()
        await persist_hydration_entry(
            db,
            user_id=user_id,
            amount_ml=detected["amount_ml"],
            drink_type=detected.get("drink_type", "water"),
            local_date=local_date,
            source="nutrition",
        )
        return detected
    except Exception as e:
        logger.warning(f"[HydrationSplit] persist failed: {e}")
        return None


from services.gemini.parsers import derive_meal_totals, enforce_macro_integrity
from services.gemini_service import GeminiService
from services.nutrition_rag_service import get_nutrition_rag_service
from services.food_analysis_cache_service import get_food_analysis_cache_service
from services.saved_foods_rag_service import get_saved_foods_rag_service
from services.food_analysis.personal_history import (
    lookup_personal_history_for_foods,
)
from services.food_analysis.mood_inference import (
    build_insert_patch,
    infer_mood_from_nutrition,
)

from api.v1.nutrition.models import (
    LogTextRequest,
    LogDirectRequest,
    LogFoodResponse,
    AnalyzeTextRequest,
    FoodReviewRequest,
)
from api.v1.nutrition.helpers import (
    upload_food_image_to_s3,
    _REGIONAL_KEYWORDS,
)

router = APIRouter()
logger = get_logger(__name__)


def _compute_sleep_risk_flag(
    user_id: str,
    food_items: List[dict],
    user_tz: str,
    logged_at_iso: Optional[str] = None,
) -> Optional[dict]:
    """Phase E1 — flag a logged food for sleep-disrupting content.

    Caffeine / alcohol / heavy-meal items logged inside the user's wind-down
    window (vs the ``health_goals`` bedtime goal) are flagged. Returns the
    flag dict (``{has_flag, flags, message}``) when something fired, else
    ``None``. Best-effort: unknown content is never flagged (no false alarms)
    and any failure simply yields ``None`` — sleep flagging never blocks a log.
    """
    try:
        from services.sleep_aware_nutrition import flag_food_items_for_sleep
        import pytz

        db = get_supabase_db()
        goals = db.get_health_goals(user_id) or {}
        bedtime_goal = goals.get("bedtime_goal")
        if not bedtime_goal:
            return None  # no bedtime goal => cannot place a wind-down window

        # The log's wall-clock time in the user's local timezone. Uses the
        # log's OWN timestamp when we have one — a meal backfilled onto a past
        # date must be measured against that evening's wind-down window, not
        # against whatever time it happens to be while the user backfills.
        try:
            tz = pytz.timezone(user_tz)
        except Exception:
            tz = pytz.UTC
        logged_at_local = datetime.now(tz)
        if logged_at_iso:
            try:
                logged_at_local = datetime.fromisoformat(
                    str(logged_at_iso).replace("Z", "+00:00")
                ).astimezone(tz)
            except ValueError:
                pass  # keep "now" — a bad stamp must not suppress the flag

        result = flag_food_items_for_sleep(
            food_items, logged_at_local, bedtime_goal
        )
        return result if result.get("has_flag") else None
    except Exception as e:
        logger.warning(f"sleep-risk flag skipped for {user_id}: {e}")
        return None


# How far back the streak recompute looks for logged days. Matches the reach
# of the app's date strip (53 weeks) so any day the user can actually backfill
# is inside the window.
_STREAK_WINDOW_DAYS = 400
# PostgREST caps an un-ranged select at 1000 rows. A truncated window is
# indistinguishable from "the user stopped logging" — i.e. it would reset a
# real streak — so the fetch pages explicitly instead of trusting one page.
_STREAK_PAGE_SIZE = 1000


def _contiguous_run(dates_desc: List[date_type]) -> int:
    """Length of the consecutive-day run starting at ``dates_desc[0]``."""
    if not dates_desc:
        return 0
    run = 1
    for i in range(1, len(dates_desc)):
        if (dates_desc[i - 1] - dates_desc[i]).days == 1:
            run += 1
        else:
            break
    return run


def _logged_local_dates(db, user_id: str, tz, since_iso: str) -> List[date_type]:
    """Distinct LOCAL dates (newest first) the user has surviving food logs on.

    Soft-deleted rows are excluded — a deleted meal is not a logged day.
    Stops paging as soon as the newest run is already terminated by a real
    gap (older rows can no longer extend it), so the common case is one query.
    """
    dates: set = set()
    offset = 0
    while True:
        rows = (
            db.client.table("food_logs")
            .select("logged_at")
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .gte("logged_at", since_iso)
            .order("logged_at", desc=True)
            .range(offset, offset + _STREAK_PAGE_SIZE - 1)
            .execute()
        ).data or []
        for r in rows:
            raw = r.get("logged_at")
            if not raw:
                continue
            dates.add(
                datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
                .astimezone(tz)
                .date()
            )
        if len(rows) < _STREAK_PAGE_SIZE:
            break
        ordered = sorted(dates, reverse=True)
        if _contiguous_run(ordered) < len(ordered):
            break
        offset += _STREAK_PAGE_SIZE
    return sorted(dates, reverse=True)


def _update_nutrition_streak(
    user_id: str, user_tz: str, log_logged_at: Optional[str] = None
) -> None:
    """Recalculate and persist the nutrition streak after any food log.

    Derived from the local dates the user actually HAS food logs on, never
    from "server now". The old incremental version anchored on today: logging
    a past day (Nutrition tab → previous date) with a last_logged_date two or
    more days back fell into the "gap" branch and reset a real streak to 1,
    while stamping last_logged_date as today — a day with no food on it. A
    recompute makes any order of logging (today, yesterday, last week)
    converge on the same answer, so a backfill can no longer destroy a streak.

    Idempotent — calling it twice for the same log is safe. Runs as a
    BackgroundTask so it never blocks the log response.
    """
    try:
        db = get_supabase_db()

        tz = _safe_zone(user_tz)
        today_local: date_type = datetime.now(tz).date()

        result = db.client.table("nutrition_streaks") \
            .select("*") \
            .eq("user_id", user_id) \
            .maybe_single() \
            .execute()
        data: dict = (result.data if result else None) or {}

        total_logged: int = data.get("total_days_logged", 0) or 0
        longest: int = data.get("longest_streak_ever", 0) or 0

        window_start = (today_local - timedelta(days=_STREAK_WINDOW_DAYS)).isoformat()
        since_iso, _ = local_date_to_utc_range(window_start, user_tz)
        logged_dates = _logged_local_dates(db, user_id, tz, since_iso)

        # A streak freeze (/streak/{id}/freeze) credits days that have NO food
        # logs by advancing last_logged_date to the freeze day (it writes only
        # last_logged_date — there is no frozen-days table). The run derived
        # from food_logs alone breaks across those days and would reset a streak
        # the user paid a freeze to keep. last_logged_date is only ever set to a
        # real log day (normal recompute / self-heal) or ADVANCED past the
        # newest log by a freeze, so any gap between the newest real log at-or-
        # before it and last_logged_date is freeze-covered: bridge EVERY day in
        # that gap, not just the endpoint. Crediting only the single endpoint
        # (the prior fix) left a hole whenever the user spent two freezes in a
        # row — only the latest survives in last_logged_date — and the run still
        # broke on the earlier frozen day, resetting the streak.
        raw_last = data.get("last_logged_date")
        if raw_last:
            frozen_through = date_type.fromisoformat(str(raw_last)[:10])
            if frozen_through <= today_local:
                anchor = max(
                    (d for d in logged_dates if d <= frozen_through), default=None
                )
                if anchor is not None and anchor < frozen_through:
                    bridge = {
                        anchor + timedelta(days=i)
                        for i in range(1, (frozen_through - anchor).days + 1)
                    }
                    logged_dates = sorted(set(logged_dates) | bridge, reverse=True)

        if not logged_dates:
            # Nothing to derive a streak from (read failed, or every log for
            # this user is soft-deleted). Leave the stored streak untouched
            # rather than fabricating one.
            return

        most_recent = logged_dates[0]
        run = _contiguous_run(logged_dates)
        # The streak is live only while the newest logged day is today or
        # yesterday — same rule as the self-heal in streaks.py.
        current_streak = run if (today_local - most_recent).days <= 1 else 0

        # total_days_logged counts distinct days across ALL time, which the
        # window can't see — so only count THIS log, and only when it is the
        # first surviving log on its own local day.
        counted_date = today_local.isoformat()
        if log_logged_at:
            try:
                counted_date = (
                    datetime.fromisoformat(str(log_logged_at).replace("Z", "+00:00"))
                    .astimezone(tz)
                    .date()
                    .isoformat()
                )
            except ValueError:
                logger.warning(
                    f"[streak] unparseable logged_at {log_logged_at!r} for {user_id}; "
                    f"counting the day as {counted_date}"
                )
        day_start, day_end = local_date_to_utc_range(counted_date, user_tz)
        same_day = (
            db.client.table("food_logs")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .gte("logged_at", day_start)
            .lte("logged_at", day_end)
            .limit(1)
            .execute()
        )
        raw_count = getattr(same_day, "count", None) if same_day else None
        if raw_count is None:
            # A missing/garbled PostgREST count must NOT be read as "0 logs
            # today" — right after the insert the real count is >= 1, so 0 is
            # impossible and would wrongly treat every count failure as the
            # first log of the day, inflating total_days_logged. Leave the
            # cumulative counter untouched rather than fabricate a value.
            logger.warning(
                f"[streak] same-day count unavailable for {user_id}; "
                f"leaving total_days_logged at {total_logged}"
            )
            new_total = total_logged
        else:
            # Only the FIRST surviving log on a local day advances the all-time
            # counter (the just-inserted row makes the count 1).
            new_total = total_logged + 1 if raw_count <= 1 else total_logged

        update = {
            "current_streak_days": current_streak,
            "total_days_logged": new_total,
            "longest_streak_ever": max(longest, run),
            "last_logged_date": most_recent.isoformat(),
        }
        if current_streak > 0:
            update["streak_start_date"] = (
                most_recent - timedelta(days=run - 1)
            ).isoformat()
        else:
            # A dead streak (current_streak_days == 0) must not keep a stale
            # streak_start_date, or the client renders a 0-day streak that still
            # claims a start date. Clear it alongside the 0.
            update["streak_start_date"] = None

        db.client.table("nutrition_streaks") \
            .upsert({"user_id": user_id, **update}, on_conflict="user_id") \
            .execute()
    except Exception as exc:
        logger.error(f"Failed to update nutrition streak for {user_id}: {exc}")


# ============================================


@router.post("/log-image", response_model=LogFoodResponse)
@limiter.limit("10/minute")
async def log_food_from_image(
    request: Request,
    background_tasks: BackgroundTasks,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
    caption: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Log food from an image using Gemini Vision.

    This endpoint:
    1. Uploads image to S3 and analyzes with Gemini Vision IN PARALLEL (no delay)
    2. Extracts food items with weight/count fields for portion editing
    3. Creates a food log entry with image URL
    """
    logger.info(f"Logging food from image for user {user_id}, meal_type={meal_type}")

    # SECURITY: Validate file type and size before processing
    ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'}
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB

    if image.content_type and image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}")

    verify_user_ownership(current_user, user_id)

    try:
        # Read and encode image
        image_bytes = await image.read()
        if len(image_bytes) > MAX_IMAGE_SIZE:
            raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')

        # Determine mime type
        content_type = image.content_type or 'image/jpeg'

        # Run Gemini analysis and S3 upload IN PARALLEL (no added delay for user)
        logger.info(f"Analyzing image + uploading to S3: size={len(image_bytes)} bytes, mime_type={content_type}")
        gemini_service = GeminiService()

        # L3 — standing food-logging rules for the non-streaming image path.
        from services.food_logging_rules_service import (
            fetch_food_logging_rules,
            build_rules_prompt_block,
        )
        _fl_rules = fetch_food_logging_rules(get_supabase_db(), user_id)
        _fl_rules_block = build_rules_prompt_block(
            _fl_rules, has_per_log_instruction=False,
        )

        # Both tasks run concurrently - total time = max(gemini_time, s3_time)
        food_analysis, (image_url, storage_key) = await asyncio.gather(
            gemini_service.analyze_food_image(
                image_base64=image_base64,
                mime_type=content_type,
                user_id=user_id,
                standing_rules_block=_fl_rules_block,
            ),
            upload_food_image_to_s3(
                file_bytes=image_bytes,
                user_id=user_id,
                content_type=content_type,
                source="camera",
                meal_type=meal_type,
            ),
        )
        logger.info(f"Gemini analysis result: {food_analysis}")
        logger.info(f"S3 upload complete: {image_url}")

        if not food_analysis or not food_analysis.get('food_items'):
            logger.warning(f"No food items identified in image. Analysis result: {food_analysis}")
            raise HTTPException(
                status_code=400,
                detail="Could not identify any food items in the image"
            )

        # Apply calorie estimate bias (AI estimates only, not barcode)
        bias = await get_user_calorie_bias(user_id)
        if bias != 0:
            food_analysis = apply_calorie_bias(food_analysis, bias)

        # Extract data from analysis (includes weight_g, unit, count, weight_per_unit_g)
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Extract all micronutrients from Gemini analysis
        micronutrients = _extract_micronutrients(food_analysis)

        # Create food log with image URL
        db = get_supabase_db()

        # Apply the user's personal cal/P/C/F corrections for foods they've
        # edited before. Runs AFTER the calorie-bias heuristic so explicit
        # user overrides trump the global bias.
        from services.food_override_service import apply_user_food_overrides
        food_items, override_totals, num_overridden = apply_user_food_overrides(
            db, user_id, food_items,
        )
        if num_overridden:
            logger.info(
                f"Applied {num_overridden} user food override(s) on /log-image for user {user_id}"
            )
            total_calories = override_totals["total_calories"]
            protein_g = override_totals["protein_g"]
            carbs_g = override_totals["carbs_g"]
            fat_g = override_totals["fat_g"]

        # Resolve timezone for logged_at timestamp
        user_tz = resolve_timezone(request, db, user_id)
        user_tz_logged_at = get_user_now_iso(user_tz)

        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=food_analysis.get('feedback'),
            health_score=None,
            logged_at=user_tz_logged_at,
            image_url=image_url,
            image_storage_key=storage_key,
            source_type="image",
            input_type="image",
            user_query=caption if caption else None,
            **micronutrients,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food from image as {food_log_id}")

        # User-history RAG (§1b.9) — refresh the day's nutrition doc in
        # the `user_nutrition_history` Chroma collection. Best-effort
        # BackgroundTask; Chroma failures never block the log response.
        try:
            from services.chroma.user_history_collection import (
                refresh_nutrition_day_from_db as _uh_refresh_nutrition,
            )
            _day_iso = (created_log.get('logged_at') or '')[:10] if created_log else None
            if _day_iso and user_id:
                background_tasks.add_task(_uh_refresh_nutrition, user_id, _day_iso)
        except Exception as _e:
            logger.warning(f"[user_history_rag] image hook skipped: {_e}")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(user_id)
        await invalidate_bootstrap_cache(user_id)

        # Background: update nutrition streak (tz reused from above; the
        # streak is credited to the LOG's own local day, not server-now).
        background_tasks.add_task(
            _update_nutrition_streak,
            user_id=user_id,
            user_tz=user_tz,
            log_logged_at=(created_log or {}).get('logged_at') or user_tz_logged_at,
        )

        # Background: Log activity analytics (non-critical, don't block response)
        background_tasks.add_task(
            log_user_activity,
            user_id=user_id,
            action="food_log_image",
            endpoint="/api/v1/nutrition/log-image",
            message=f"Logged {len(food_items)} food items from image ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "meal_type": meal_type,
                "total_calories": total_calories,
                "food_items_count": len(food_items),
            },
            status_code=200,
        )

        # Calculate confidence based on image analysis factors
        # Higher confidence for clearer images with identifiable foods
        confidence_score = 0.7  # Base confidence for image analysis
        if len(food_items) == 1:
            confidence_score = 0.8  # Single item is more accurate
        elif len(food_items) > 5:
            confidence_score = 0.6  # Complex meals have lower confidence

        confidence_level = "high" if confidence_score >= 0.75 else "medium" if confidence_score >= 0.5 else "low"

        # Phase E1 — flag caffeine/alcohol/heavy-meal logged near bedtime.
        sleep_risk = _compute_sleep_risk_flag(
            user_id, food_items, user_tz, user_tz_logged_at
        )

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type="image",
            sleep_risk=sleep_risk,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from image: {e}", exc_info=True)
        # Background: Log error analytics (non-critical)
        background_tasks.add_task(
            log_user_error,
            user_id=user_id,
            action="food_log_image",
            error=e,
            endpoint="/api/v1/nutrition/log-image",
            metadata={"meal_type": meal_type},
            status_code=500,
        )
        raise safe_internal_error(e, "nutrition")


@router.post("/log-text", response_model=LogFoodResponse)
@limiter.limit("10/minute")
async def log_food_from_text(body: LogTextRequest, background_tasks: BackgroundTasks, request: Request, current_user: dict = Depends(get_current_user)):
    """
    Log food from a text description using Gemini with goal-based analysis.

    This endpoint:
    1. Fetches user's fitness goals and nutrition targets
    2. Parses the text description with Gemini (with goal context)
    3. Extracts food items with per-item rankings
    4. Creates a food log entry with AI suggestions

    Example descriptions:
    - "2 eggs, toast with butter, and orange juice"
    - "chicken salad with grilled chicken, lettuce, tomatoes, and ranch dressing"
    - "a bowl of oatmeal with banana and honey"
    """
    # Never trust client-supplied body.user_id — see log_food_direct. The chat
    # path sends the Supabase auth_id, not the backend users.id. Overwrite with
    # the authoritative id resolved by get_current_user.
    body.user_id = current_user["id"]

    logger.info(f"Logging food from text for user {body.user_id}: {body.description[:50]}...")

    try:
        db = get_supabase_db()

        # Personal food history — if user has re-logged this food before with
        # bad mood/energy, we want Gemini to cite it. Needs only the raw
        # description, so it starts FIRST and overlaps the user fetch + RAG
        # below (previously these three ran sequentially, ~1.5-3.5s serial).
        # Exceptions are consumed inside the task so an orphaned task (e.g.
        # when analyze_food raises) never logs "exception never retrieved".
        candidate_names = [p.strip() for p in body.description.split(",") if p.strip()]

        async def _history_lookup() -> list:
            try:
                return await lookup_personal_history_for_foods(
                    body.user_id, candidate_names
                )
            except Exception as hist_err:
                logger.warning(f"personal history lookup failed: {hist_err}")
                return []

        history_task = asyncio.create_task(_history_lookup())

        # User row (goals + targets) and the Gap-6 hydration pref are
        # independent blocking reads — run them concurrently in the pool.
        def _fetch_user_enriched():
            try:
                u = db.get_user(body.user_id)
                return db.enrich_user_with_nutrition_targets(u) if u else None
            except Exception as e:
                logger.warning(f"Could not fetch user goals/targets: {e}", exc_info=True)
                return None

        async def _hydration_pref() -> bool:
            if getattr(body, "skip_hydration", False):
                return False
            return await _is_hydration_tracking_enabled(db, body.user_id)

        user, hydration_enabled = await asyncio.gather(
            _run_blocking(_fetch_user_enriched),
            _hydration_pref(),
        )

        # Gap 1 — water-in-text. When hydration tracking is on, kick off a
        # language-agnostic Flash-Lite pass that detects a beverage in the entry
        # ("2 eggs and a glass of water" / "deux oeufs et un verre d'eau"). It
        # runs concurrently with the food analysis below so it adds no latency;
        # we await it after the food log is created. Gated on the user's pref so
        # an opted-out user pays zero extra LLM cost (see Gap 6).
        hydration_task = None
        if hydration_enabled:
            from services.food_analysis.hydration_split import detect_hydration_in_text
            hydration_task = asyncio.create_task(
                detect_hydration_in_text(body.description, body.user_id)
            )

        user_goals = None
        nutrition_targets = None
        if user:
            # Parse goals from JSON string
            goals_str = user.get('goals', '[]')
            if isinstance(goals_str, str):
                import json
                try:
                    user_goals = json.loads(goals_str)
                except json.JSONDecodeError:
                    user_goals = []
            elif isinstance(goals_str, list):
                user_goals = goals_str

            # Get nutrition targets
            nutrition_targets = {
                'daily_calorie_target': user.get('daily_calorie_target'),
                'daily_protein_target_g': user.get('daily_protein_target_g'),
                'daily_carbs_target_g': user.get('daily_carbs_target_g'),
                'daily_fat_target_g': user.get('daily_fat_target_g'),
            }
            logger.info(f"User goals: {user_goals}, targets: {nutrition_targets}")

        # Get RAG context from nutrition knowledge base (if user has goals).
        # Runs while the personal-history task above is still in flight.
        rag_context = None
        if user_goals:
            try:
                nutrition_rag = get_nutrition_rag_service()
                rag_context = await nutrition_rag.get_context_for_goals(
                    food_description=body.description,
                    user_goals=user_goals,
                    n_results=5,
                )
                if rag_context:
                    logger.info(f"Retrieved RAG context ({len(rag_context)} chars) for goals: {user_goals}")
            except Exception as e:
                logger.warning(f"Could not fetch RAG context: {e}", exc_info=True)

        personal_history = await history_task

        # Parse description through cache service (DB-first, then Gemini).
        # defer_hit_tips: a cache HIT returns instantly with macros only — the
        # ~5s synchronous coach-tips Gemini call (measured: it dominated this
        # endpoint's latency) moves to a background task that updates the row
        # after the response. A cache MISS still runs the full Gemini schema
        # with coaching prose inline. Same product pattern as the streaming
        # endpoint's deferred `coach_tips` event.
        cache_service = get_food_analysis_cache_service()
        food_analysis = await cache_service.analyze_food(
            description=body.description,
            user_goals=user_goals,
            nutrition_targets=nutrition_targets,
            rag_context=rag_context,
            use_cache=True,
            user_id=body.user_id,
            mood_before=body.mood_before,
            meal_type=body.meal_type,
            personal_history=personal_history or None,
            defer_hit_tips=True,
        )

        # Cache-hit paths skip Gemini's prompt, so the personal_history_note is
        # missing — synthesize it from history rows.
        if (
            food_analysis
            and personal_history
            and food_analysis.get("cache_source") != "gemini_fresh"
        ):
            cache_service.apply_personal_history_to_cache_hit(
                food_analysis, personal_history
            )

        if not food_analysis or not food_analysis.get('food_items'):
            # Gap 1 — a beverage-only entry ("a glass of water") parses to zero
            # food items. Instead of 400-ing, log the hydration and return a
            # success with empty food_items so the client shows "water logged".
            user_tz_water = await _run_blocking(
                lambda: resolve_timezone(request, db, body.user_id)
            ) if request else None
            hydration_only = await _await_and_persist_text_hydration(
                db, hydration_task, body.user_id, user_tz_water
            )
            if hydration_only:
                return LogFoodResponse(
                    success=True,
                    food_log_id="hydration_only",
                    food_items=[],
                    total_calories=0,
                    protein_g=0.0,
                    carbs_g=0.0,
                    fat_g=0.0,
                    fiber_g=0.0,
                    source_type="text",
                    hydration_logged=hydration_only,
                )
            raise HTTPException(
                status_code=400,
                detail="Could not parse any food items from the description"
            )

        # Apply calorie estimate bias (AI estimates only, not DB-sourced)
        bias = await get_user_calorie_bias(body.user_id)
        cache_source = food_analysis.get('cache_source')
        is_ai_estimate = cache_source in (None, 'gemini_fresh', 'analysis_cache')
        if bias != 0 and is_ai_estimate:
            food_analysis = apply_calorie_bias(food_analysis, bias)

        # Extract data from analysis
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Extract enhanced analysis fields
        overall_meal_score = food_analysis.get('overall_meal_score')
        health_score = food_analysis.get('health_score')
        health_score_reasons = food_analysis.get('health_score_reasons')
        goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
        ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
        encouragements = food_analysis.get('encouragements', [])
        warnings = food_analysis.get('warnings', [])
        recommended_swap = food_analysis.get('recommended_swap')

        # Extract all micronutrients from Gemini analysis
        micronutrients = _extract_micronutrients(food_analysis)

        # Apply per-user food overrides — their personal cal/P/C/F corrections
        # for foods they've edited before. Runs AFTER bias so explicit user
        # overrides trump the calorie-bias heuristic. (Blocking DB lookup →
        # pool.)
        from services.food_override_service import apply_user_food_overrides
        food_items, override_totals, num_overridden = await _run_blocking(
            lambda: apply_user_food_overrides(db, body.user_id, food_items)
        )
        if num_overridden:
            logger.info(
                f"Applied {num_overridden} user food override(s) on /log-text for user {body.user_id}"
            )
            total_calories = override_totals["total_calories"]
            protein_g = override_totals["protein_g"]
            carbs_g = override_totals["carbs_g"]
            fat_g = override_totals["fat_g"]

        # Resolve timezone ONCE and reuse it for logged_at, the streak
        # background task, sleep-risk flags, and hydration persist (was
        # resolved 3x per request, each a potential blocking DB fallback).
        user_tz = await _run_blocking(
            lambda: resolve_timezone(request, db, body.user_id)
        )
        user_tz_logged_at = get_user_now_iso(user_tz) if request else None

        # Passive mood inference — respect the user toggle before running.
        inference_patch: dict = {}
        try:
            prefs = await _run_blocking(
                lambda: db.client.table("user_nutrition_preferences")
                .select("passive_inference_enabled").eq("user_id", body.user_id).maybe_single().execute()
            )
            inference_enabled = True
            if prefs and prefs.data and prefs.data.get("passive_inference_enabled") is not None:
                inference_enabled = bool(prefs.data["passive_inference_enabled"])
            if inference_enabled and getattr(body, "mood_after", None) is None:
                inferred = infer_mood_from_nutrition(
                    {
                        "total_calories": total_calories,
                        "protein_g": protein_g,
                        "carbs_g": carbs_g,
                        "fat_g": fat_g,
                        "fiber_g": fiber_g,
                        "sugar_g": micronutrients.get("sugar_g"),
                        "sodium_mg": micronutrients.get("sodium_mg"),
                        "added_sugar_g": food_analysis.get("added_sugar_g"),
                        "alcohol_g": food_analysis.get("alcohol_g"),
                        "caffeine_mg": food_analysis.get("caffeine_mg"),
                        "omega3_g": micronutrients.get("omega3_g"),
                        "is_ultra_processed": food_analysis.get("is_ultra_processed"),
                    }
                )
                inference_patch = build_insert_patch(inferred)
        except Exception as inf_err:
            logger.warning(f"passive inference skipped: {inf_err}")

        # Save to database (blocking insert → pool)
        created_log = await _run_blocking(lambda: db.create_food_log(
            user_id=body.user_id,
            meal_type=body.meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=ai_suggestion,
            health_score=health_score,
            health_score_reasons=health_score_reasons,
            logged_at=user_tz_logged_at,
            source_type="text",
            input_type=body.input_type or "text",
            user_query=body.description,
            **micronutrients,
            **inference_patch,
        ))

        # Get the food log ID from the created record
        food_log_id = created_log.get('id') if created_log else "unknown"

        logger.info(f"Successfully logged food from text as {food_log_id}")

        # Deferred coach tips (defer_hit_tips): a cache hit returned without
        # the ~5s tips Gemini call — compute + persist them after the response.
        if (
            food_log_id != "unknown"
            and food_analysis.get("cache_hit")
            and not (ai_suggestion or encouragements or warnings)
        ):
            background_tasks.add_task(
                _enrich_log_tips_in_background,
                food_log_id,
                body.user_id,
                food_analysis,
                body.meal_type,
                body.mood_before,
            )

        # User-history RAG (§1b.9) — refresh today's nutrition doc.
        try:
            from services.chroma.user_history_collection import (
                refresh_nutrition_day_from_db as _uh_refresh_nutrition,
            )
            _day_iso = (created_log.get('logged_at') or '')[:10] if created_log else None
            if _day_iso and body.user_id:
                background_tasks.add_task(_uh_refresh_nutrition, body.user_id, _day_iso)
        except Exception as _e:
            logger.warning(f"[user_history_rag] text hook skipped: {_e}")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(body.user_id)
        await invalidate_bootstrap_cache(body.user_id)

        # Background: update nutrition streak (reuses the tz resolved above;
        # credited to the LOG's own local day, not server-now)
        background_tasks.add_task(
            _update_nutrition_streak,
            user_id=body.user_id,
            user_tz=user_tz,
            log_logged_at=(created_log or {}).get('logged_at') or user_tz_logged_at,
        )

        # Background: Log activity analytics (non-critical, don't block response)
        background_tasks.add_task(
            log_user_activity,
            user_id=body.user_id,
            action="food_log_text",
            endpoint="/api/v1/nutrition/log-text",
            message=f"Logged {len(food_items)} food items from text ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "meal_type": body.meal_type,
                "total_calories": total_calories,
                "food_items_count": len(food_items),
                "health_score": health_score,
            },
            status_code=200,
        )

        # Text descriptions are generally more accurate than images
        confidence_score = 0.85  # Base confidence for text
        if len(body.description) < 20:
            confidence_score = 0.7  # Short descriptions have less context
        elif "about" in body.description.lower() or "roughly" in body.description.lower():
            confidence_score = 0.65  # Approximate language reduces confidence

        confidence_level = "high" if confidence_score >= 0.75 else "medium" if confidence_score >= 0.5 else "low"

        # Phase E1 — flag caffeine/alcohol/heavy-meal logged near bedtime.
        # (health_goals lookup is blocking → pool; tz reused from above.)
        sleep_risk = await _run_blocking(
            lambda: _compute_sleep_risk_flag(
                body.user_id, food_items, user_tz, user_tz_logged_at
            )
        )

        # Gap 1 — water-in-text. Await the concurrent hydration detection and
        # persist any beverage found ("...and a glass of water") so a single
        # entry logs both food and hydration.
        hydration_logged = await _await_and_persist_text_hydration(
            db, hydration_task, body.user_id, user_tz
        )

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            overall_meal_score=overall_meal_score,
            health_score=health_score,
            health_score_reasons=health_score_reasons,
            goal_alignment_percentage=goal_alignment_percentage,
            ai_suggestion=ai_suggestion,
            encouragements=encouragements,
            warnings=warnings,
            recommended_swap=recommended_swap,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type="text",
            sleep_risk=sleep_risk,
            hydration_logged=hydration_logged,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from text: {e}", exc_info=True)
        # Background: Log error analytics (non-critical)
        background_tasks.add_task(
            log_user_error,
            user_id=body.user_id,
            action="food_log_text",
            error=e,
            endpoint="/api/v1/nutrition/log-text",
            metadata={
                "meal_type": body.meal_type,
                "description": body.description[:100] if body.description else None,
            },
            status_code=500,
        )
        raise safe_internal_error(e, "nutrition")


# ============================================
# Direct Food Logging (for restaurant mode, manual adjustments)
# ============================================


@router.post("/log-direct", response_model=LogFoodResponse)
@limiter.limit("10/minute")
async def log_food_direct(
    body: LogDirectRequest,
    request: Request,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Log pre-analyzed food directly without AI processing.

    Used for:
    - Restaurant mode with portion adjustments
    - Manual food entry
    - Adjusted servings from previous logs

    The caller provides the nutrition data directly, which is logged as-is.
    """
    # SECURITY + CORRECTNESS: never trust the client-supplied body.user_id.
    # The chat path sends the Supabase auth_id, not the backend users.id —
    # which caused a food_logs_user_id_fkey 500. get_current_user has already
    # resolved the authoritative backend users.id; overwrite body.user_id with
    # it so every downstream use (insert, overrides, streak, cache, edits) is
    # correct. Also closes an IDOR — a caller could otherwise log food onto
    # another user's account by passing a different user_id.
    body.user_id = current_user["id"]

    # Durable guard: clamp source_type to the food_logs DB allowlist so an
    # unexpected client provenance coerces to 'manual' instead of raising a
    # 23514 (food_logs_source_type_check) that surfaces as a 500.
    body.source_type = _normalize_source_type(body.source_type)

    logger.info(f"Logging food directly for user {body.user_id}, source: {body.source_type}")

    # Debug: Log incoming values
    logger.info(
        f"[LOG-DIRECT] RECEIVED VALUES | "
        f"user={body.user_id} | "
        f"calories={body.total_calories} | "
        f"protein={body.total_protein} | "
        f"carbs={body.total_carbs} | "
        f"fat={body.total_fat} | "
        f"food_items_count={len(body.food_items)}"
    )
    if body.food_items:
        for idx, item in enumerate(body.food_items[:3]):  # Log first 3 items
            logger.info(f"[LOG-DIRECT] ITEM[{idx}] | name={item.get('name')} | calories={item.get('calories')}")

    try:
        db = get_supabase_db()

        # Idempotency short-circuit (migration 2245). If the client reused its
        # idempotency_key on a replay (double-tap, offline-queue replay, or a
        # 401-refresh Dio retry), the meal is already logged — return the
        # existing row and skip EVERY side effect (streak bump, score
        # enrichment Gemini call, cache invalidation). The unique index on
        # create_food_log is the race safety net for two replays landing at
        # once; this pre-check handles the common sequential replay cheaply.
        if body.idempotency_key:
            try:
                prior = await _run_blocking(
                    lambda: db.client.table("food_logs")
                    .select("*")
                    .eq("user_id", body.user_id)
                    .eq("idempotency_key", body.idempotency_key)
                    .is_("deleted_at", "null")
                    .limit(1)
                    .execute()
                )
                if prior.data:
                    existing = prior.data[0]
                    logger.info(
                        f"[LOG-DIRECT] Idempotent replay (key={body.idempotency_key}) "
                        f"— returning existing log {existing.get('id')}, skipping side effects"
                    )
                    return LogFoodResponse(
                        success=True,
                        food_log_id=existing.get("id"),
                        food_items=existing.get("food_items") or body.food_items,
                        total_calories=existing.get("total_calories") or body.total_calories,
                        protein_g=float(existing.get("protein_g") or body.total_protein),
                        carbs_g=float(existing.get("carbs_g") or body.total_carbs),
                        fat_g=float(existing.get("fat_g") or body.total_fat),
                        fiber_g=float(existing.get("fiber_g") or 0.0),
                        overall_meal_score=body.overall_meal_score,
                        health_score=existing.get("health_score") or body.health_score,
                        source_type=existing.get("source_type") or body.source_type,
                        confidence_score=0.9,
                        confidence_level="high",
                    )
            except Exception as idem_err:
                # Pre-check is best-effort; the unique index still guards the insert.
                logger.warning(f"[LOG-DIRECT] idempotency pre-check skipped: {idem_err}")

        # Build micronutrients dict from request
        micronutrients = {}
        micronutrient_fields = [
            'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
            'vitamin_a_ug', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg', 'vitamin_k_ug',
            'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg', 'vitamin_b6_mg',
            'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
            'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
            'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
            # Gap 7 — caffeine + alcohol from the analyzed meal (added_sugar_g is
            # passed explicitly to create_food_log below).
            'caffeine_mg', 'alcohol_g',
        ]
        for field in micronutrient_fields:
            value = getattr(body, field, None)
            if value is not None:
                micronutrients[field] = value

        # Resolve timezone ONCE and reuse it for logged_at, the streak
        # background task, and sleep-risk flags (was resolved up to 3x per
        # request, each a potential blocking DB fallback).
        user_tz = await _run_blocking(
            lambda: resolve_timezone(request, db, body.user_id)
        )

        # Client-supplied logged_at wins (used when the user is viewing a past
        # date in the Nutrition tab — the log must belong to THAT date, not
        # "now"). The app sends a naive local wall-clock stamp
        # (`DateTime(y, m, d, h, m, s).toIso8601String()`), so a value without
        # an offset is the USER's clock, not the server's: reading it as UTC
        # shifted every backfilled meal by the whole offset and rolled
        # early-morning meals onto the previous day.
        user_tz_logged_at = None
        if body.logged_at:
            from datetime import datetime as _dt, timezone as _tz, timedelta as _td
            try:
                parsed = _dt.fromisoformat(body.logged_at.replace("Z", "+00:00"))
            except ValueError as e:
                # Never fall back to server-now: that relocates the user's meal
                # to a different day without telling anyone.
                logger.warning(f"[LOG-DIRECT] Invalid logged_at '{body.logged_at}': {e}")
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid logged_at '{body.logged_at}' — expected ISO-8601",
                )
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=_safe_zone(user_tz))
            # A meal cannot be eaten in the future, and the client offers no
            # future-date picker — a stamp more than an hour ahead is therefore
            # a fast device clock on a live "now" log, never an intentional
            # backfill. Clamp it to server-now (the meal's true moment is ~now)
            # instead of 400-ing: the Flutter offline queue classifies 4xx as
            # permanent and QUARANTINES the body, silently losing the meal.
            # Clamping keeps it on the correct real day; honouring the skewed
            # stamp is what would push it onto the wrong (future) day. Past
            # timestamps are still honoured exactly as sent — the date strip
            # reaches 53 weeks back, so legitimate backfills are untouched.
            now_utc = _dt.now(_tz.utc)
            if parsed > now_utc + _td(hours=1):
                logger.warning(
                    f"[LOG-DIRECT] logged_at {body.logged_at} is >1h in the "
                    f"future for user {body.user_id}; clamping to server-now "
                    f"(device clock skew)"
                )
                parsed = now_utc
            user_tz_logged_at = parsed.astimezone(_tz.utc).isoformat()
        elif request:
            user_tz_logged_at = get_user_now_iso(user_tz)

        # Apply per-user food overrides. Skip any item the client just edited
        # in the Log Meal sheet — those are the user's fresh corrections and
        # we'd otherwise double-apply a stale override on top of them.
        # (Blocking DB lookup → pool.)
        edited_indices = (
            {e.food_item_index for e in (body.item_edits or [])}
        )
        from services.food_override_service import apply_user_food_overrides
        applied_items, override_totals, num_overridden = await _run_blocking(
            lambda: apply_user_food_overrides(
                db, body.user_id, list(body.food_items), skip_indices=edited_indices,
            )
        )
        if num_overridden:
            logger.info(
                f"[LOG-DIRECT] Applied {num_overridden} user food override(s) for user {body.user_id}"
            )
            body.food_items = applied_items
            body.total_calories = override_totals["total_calories"]
            body.total_protein = int(round(override_totals["protein_g"]))
            body.total_carbs = int(round(override_totals["carbs_g"]))
            body.total_fat = int(round(override_totals["fat_g"]))

        # DERIVE meal totals from the items before persisting — never trust the
        # client's meal-level numbers. Gemini (and any client that echoed its 0
        # totals) can post "N kcal · 0P/0C/0F" while every item carries real
        # macros; the menu-scan path in particular sends totals the client
        # computed from possibly-zero fields. Sum the items, then run the
        # integrity gate so a genuinely-unknown-macro item is nulled + labelled,
        # not written as a confident 0.
        _persist_payload = enforce_macro_integrity(
            derive_meal_totals(
                {
                    "food_items": body.food_items,
                    "total_calories": body.total_calories,
                    "total_protein": body.total_protein,
                    "total_carbs": body.total_carbs,
                    "total_fat": body.total_fat,
                    "total_fiber": body.total_fiber,
                },
                "log-direct",
            ),
            "log-direct",
        )
        body.food_items = _persist_payload["food_items"]
        if _persist_payload.get("total_calories") is not None:
            body.total_calories = _persist_payload["total_calories"]
        body.total_protein = _persist_payload.get("total_protein")
        body.total_carbs = _persist_payload.get("total_carbs")
        body.total_fat = _persist_payload.get("total_fat")
        body.total_fiber = _persist_payload.get("total_fiber")

        # Create food log directly. The idempotency_key (when the client sent
        # one) makes this insert dedupe against migration 2245's unique index —
        # a replayed POST returns the existing row instead of a duplicate.
        # (Blocking insert → pool.)
        created_log = await _run_blocking(lambda: db.create_food_log(
            user_id=body.user_id,
            meal_type=body.meal_type,
            food_items=body.food_items,
            idempotency_key=body.idempotency_key,
            total_calories=body.total_calories,
            protein_g=body.total_protein,
            carbs_g=body.total_carbs,
            fat_g=body.total_fat,
            fiber_g=body.total_fiber,
            # Honor the vision/text-analysis feedback the client already ran. Only
            # fall back to the generic placeholder when the caller provided nothing
            # — otherwise we'd clobber Gemini's real description of the meal.
            ai_feedback=(
                body.ai_feedback
                or f"Logged via {body.source_type}" + (f": {body.notes}" if body.notes else "")
            ),
            health_score=body.health_score or body.overall_meal_score,
            health_score_reasons=body.health_score_reasons,
            logged_at=user_tz_logged_at,
            image_url=body.image_url,
            image_storage_key=body.image_storage_key,
            source_type=body.source_type,
            input_type=body.input_type,
            user_query=body.user_query,
            inflammation_score=body.inflammation_score,
            is_ultra_processed=body.is_ultra_processed,
            inflammation_triggers=body.inflammation_triggers,
            added_sugar_g=body.added_sugar_g,
            glycemic_load=body.glycemic_load,
            fodmap_rating=body.fodmap_rating,
            fodmap_reason=body.fodmap_reason,
            **micronutrients,
        ))

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food directly as {food_log_id}")

        # User-history RAG (§1b.9) — refresh today's nutrition doc.
        try:
            from services.chroma.user_history_collection import (
                refresh_nutrition_day_from_db as _uh_refresh_nutrition,
            )
            _day_iso = (created_log.get('logged_at') or '')[:10] if created_log else None
            if _day_iso and body.user_id:
                background_tasks.add_task(_uh_refresh_nutrition, body.user_id, _day_iso)
        except Exception as _e:
            logger.warning(f"[user_history_rag] direct hook skipped: {_e}")

        # Persist any pre-save per-field edits made in the Log Meal sheet.
        # Done after the food_log row exists so the FK points somewhere.
        if body.item_edits and food_log_id != "unknown":
            try:
                edit_rows = [e.dict() for e in body.item_edits]
                inserted = db.insert_food_log_edits(
                    user_id=body.user_id,
                    food_log_id=food_log_id,
                    edits=edit_rows,
                    edit_source='pre_save_log_meal',
                )
                logger.info(f"[LOG-DIRECT] Recorded {inserted} pre-save item edits for {food_log_id}")
            except Exception as edit_err:
                # Audit failures must never block a successful log
                logger.warning(f"[LOG-DIRECT] Failed to record pre-save item edits: {edit_err}")

            # Feed the user's corrections back into user_food_overrides so the
            # next log of the same food defaults to their numbers. UPSERT once
            # per edited item index (not per field) — if they edited 3 of 4
            # fields on one item, we want one override row with the final
            # values, not three separate UPSERTs racing against each other.
            try:
                edited_indices = {e.food_item_index for e in body.item_edits}
                for idx in edited_indices:
                    if 0 <= idx < len(body.food_items):
                        db.upsert_user_food_override(
                            user_id=body.user_id,
                            food_item=body.food_items[idx],
                        )
            except Exception as ov_err:
                # Override learning is best-effort — never fail the log
                logger.warning(
                    f"[LOG-DIRECT] Failed to upsert user_food_overrides: {ov_err}"
                )

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(body.user_id)
        await invalidate_bootstrap_cache(body.user_id)

        # Background: update nutrition streak (reuses the tz resolved above).
        # Passing the log's OWN timestamp is what keeps a past-date backfill
        # from being credited to — and resetting — today's streak.
        background_tasks.add_task(
            _update_nutrition_streak,
            user_id=body.user_id,
            user_tz=user_tz,
            log_logged_at=(created_log or {}).get('logged_at') or user_tz_logged_at,
        )

        # Backfill rich scoring (inflammation, NOVA, FODMAP, micronutrients)
        # for log modes that don't supply them. Runs after the response is
        # sent so the user sees their meal logged instantly; the Daily card,
        # Vitamins & Minerals, and Inflammation Score chips fill in within
        # a few seconds via Gemini analysis seeded with the locked macros.
        # Skipping when the headline scoring fields are already populated
        # avoids redundant Gemini calls + cost on text/photo flows that
        # already produced full scoring upstream. Covers: barcode, saved
        # foods, quick log, manual entry, restaurant menu re-log, app
        # screenshot OCR, nutrition label OCR — every mode that funnels
        # through /log-direct without computing scores upstream.
        # Fire when EITHER headline score is missing. Barcode supplies a NOVA
        # inflammation_score but no health_score, so the old all-null gate left
        # barcode (and any path with partial scores) permanently un-enriched;
        # enrich_food_log_scores re-checks the row + serves ~95% from the
        # override-DB cache, so over-triggering is cheap.
        if (
            food_log_id != "unknown"
            and (body.inflammation_score is None or body.health_score is None)
        ):
            from services.food_score_enrichment import enrich_food_log_scores
            background_tasks.add_task(
                enrich_food_log_scores, food_log_id, body.user_id
            )

        # Restaurant mode has lower confidence due to portion estimation
        confidence_score = 0.6 if body.source_type == "restaurant" else 0.9
        confidence_level = "medium" if body.source_type == "restaurant" else "high"

        # Phase E1 — flag caffeine/alcohol/heavy-meal logged near bedtime.
        # Covers menu-scan and direct logging (input_type="menu_scan" etc.).
        # (health_goals lookup is blocking → pool; tz reused from above.)
        sleep_risk = await _run_blocking(
            lambda: _compute_sleep_risk_flag(
                body.user_id, body.food_items, user_tz, user_tz_logged_at
            )
        )

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=body.food_items,
            total_calories=body.total_calories,
            protein_g=float(body.total_protein),
            carbs_g=float(body.total_carbs),
            fat_g=float(body.total_fat),
            fiber_g=float(body.total_fiber) if body.total_fiber else 0.0,
            overall_meal_score=body.overall_meal_score,
            health_score=body.health_score or body.overall_meal_score,
            health_score_reasons=body.health_score_reasons,
            ai_suggestion=None,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type=body.source_type,
            sleep_risk=sleep_risk,
            inflammation_score=body.inflammation_score,
            is_ultra_processed=body.is_ultra_processed,
            inflammation_triggers=body.inflammation_triggers,
            added_sugar_g=body.added_sugar_g,
            glycemic_load=body.glycemic_load,
            fodmap_rating=body.fodmap_rating,
            fodmap_reason=body.fodmap_reason,
        )
    except HTTPException:
        # A deliberate 4xx (e.g. an unusable client logged_at) must reach the
        # client as-is — the bare `except Exception` below would otherwise
        # relabel it as a 500 and hide what the caller sent wrong.
        raise
    except Exception as e:
        logger.error(f"Error logging food directly: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ============================================
# Streaming Food Logging Endpoints
# ============================================


@router.post("/log-text-stream")
@limiter.limit("10/minute")
async def log_food_from_text_streaming(request: Request, body: LogTextRequest, current_user: dict = Depends(get_current_user)):
    """
    Log food from text description with streaming progress updates via SSE.

    Provides real-time feedback during food analysis:
    - Step 1: Loading user profile and goals
    - Step 2: Analyzing food with AI
    - Step 3: Calculating nutrition
    - Step 4: Saving to database

    Returns SSE events with progress updates and final food log.
    """
    # Never trust client-supplied body.user_id — see log_food_direct.
    body.user_id = current_user["id"]

    logger.info(f"[STREAM] Logging food from text for user {body.user_id}: {body.description[:50]}...")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(step: int, total: int, message: str, detail: str = None):
            data = {
                "type": "progress",
                "step": step,
                "total_steps": total,
                "message": message,
                "detail": detail,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            data = {"type": "error", "error": error, "elapsed_ms": elapsed_ms()}
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Load user profile and goals
            yield send_progress(1, 4, "Loading your profile...", "Fetching nutrition goals")

            db = get_supabase_db()

            user_goals = None
            nutrition_targets = None
            try:
                user = db.get_user(body.user_id)
                if user:
                    user = db.enrich_user_with_nutrition_targets(user)
                    goals_str = user.get('goals', '[]')
                    if isinstance(goals_str, str):
                        try:
                            user_goals = json.loads(goals_str)
                        except json.JSONDecodeError:
                            user_goals = []
                    elif isinstance(goals_str, list):
                        user_goals = goals_str

                    nutrition_targets = {
                        'daily_calorie_target': user.get('daily_calorie_target'),
                        'daily_protein_target_g': user.get('daily_protein_target_g'),
                        'daily_carbs_target_g': user.get('daily_carbs_target_g'),
                        'daily_fat_target_g': user.get('daily_fat_target_g'),
                    }
            except Exception as e:
                logger.warning(f"[STREAM] Could not fetch user goals: {e}", exc_info=True)

            # Step 2: Check cache and analyze with AI
            yield send_progress(2, 4, "Analyzing your food...", "Checking food database")

            # Use caching service for faster lookups
            cache_service = get_food_analysis_cache_service()

            # First try cache (saved foods + overrides + common foods + cached AI responses)
            cache_task = asyncio.create_task(cache_service.analyze_food(
                description=body.description,
                user_goals=user_goals,
                nutrition_targets=nutrition_targets,
                rag_context=None,  # Skip RAG on cache hit for speed
                use_cache=True,
                user_id=body.user_id,
                mood_before=body.mood_before,
                meal_type=body.meal_type,
            ))
            while not cache_task.done():
                try:
                    await asyncio.wait_for(asyncio.shield(cache_task), timeout=10.0)
                except asyncio.TimeoutError:
                    yield ": keep-alive\n\n"
            food_analysis = cache_task.result()

            # If cache hit, log it
            if food_analysis and food_analysis.get("cache_hit"):
                cache_source = food_analysis.get("cache_source", "cache")
                logger.info(f"[STREAM] 🎯 Cache HIT ({cache_source}) for: {body.description[:50]}...")
            else:
                # Cache miss - get RAG context for better AI response
                rag_context = None
                if user_goals:
                    try:
                        nutrition_rag = get_nutrition_rag_service()
                        rag_context = await nutrition_rag.get_context_for_goals(
                            food_description=body.description,
                            user_goals=user_goals,
                            n_results=3,  # Reduced from 5 for speed
                        )
                    except Exception as e:
                        logger.warning(f"[STREAM] Could not fetch RAG context: {e}", exc_info=True)

                # Re-analyze with RAG context (cache will save for next time)
                analysis_task = asyncio.create_task(cache_service.analyze_food(
                    description=body.description,
                    user_goals=user_goals,
                    nutrition_targets=nutrition_targets,
                    rag_context=rag_context,
                    use_cache=True,  # Will cache this new result
                    user_id=body.user_id,
                    mood_before=body.mood_before,
                    meal_type=body.meal_type,
                ))
                while not analysis_task.done():
                    try:
                        await asyncio.wait_for(asyncio.shield(analysis_task), timeout=10.0)
                    except asyncio.TimeoutError:
                        yield ": keep-alive\n\n"
                food_analysis = analysis_task.result()

            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error("Could not identify any food items from your description")
                return

            # Apply calorie estimate bias (AI estimates only)
            bias = await get_user_calorie_bias(body.user_id)
            if bias != 0:
                food_analysis = apply_calorie_bias(food_analysis, bias)

            # Step 3: Calculate nutrition
            yield send_progress(3, 4, "Calculating nutrition...", f"Found {len(food_analysis.get('food_items', []))} items")

            food_items = food_analysis.get('food_items', [])
            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)
            overall_meal_score = food_analysis.get('overall_meal_score')
            health_score = food_analysis.get('health_score')
            health_score_reasons = food_analysis.get('health_score_reasons')
            goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
            ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
            encouragements = food_analysis.get('encouragements', [])
            warnings = food_analysis.get('warnings', [])
            recommended_swap = food_analysis.get('recommended_swap')

            # Extract micronutrients from analysis
            micronutrients = {}
            micronutrient_keys = [
                'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
                'vitamin_a_ug', 'vitamin_a_iu', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg',
                'vitamin_k_ug', 'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg',
                'vitamin_b6_mg', 'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
                'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
                'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
                # Gap 7 — opt-in tracker inputs.
                'caffeine_mg', 'alcohol_g', 'added_sugar_g',
            ]
            for key in micronutrient_keys:
                value = food_analysis.get(key)
                if value is not None:
                    # Convert vitamin_a_iu to vitamin_a_ug (1 IU = 0.3 ug retinol)
                    if key == 'vitamin_a_iu':
                        micronutrients['vitamin_a_ug'] = float(value) * 0.3
                    else:
                        micronutrients[key] = float(value) if value else None

            # Step 4: Save to database
            yield send_progress(4, 4, "Saving your meal...", "Almost done!")

            # Resolve timezone for logged_at timestamp
            stream_user_tz = resolve_timezone(request, db, body.user_id)
            stream_logged_at = get_user_now_iso(stream_user_tz)

            created_log = db.create_food_log(
                user_id=body.user_id,
                meal_type=body.meal_type,
                food_items=food_items,
                total_calories=total_calories,
                protein_g=protein_g,
                carbs_g=carbs_g,
                fat_g=fat_g,
                fiber_g=fiber_g,
                ai_feedback=ai_suggestion,
                health_score=health_score,
                health_score_reasons=health_score_reasons,
                logged_at=stream_logged_at,
                **micronutrients,
            )

            food_log_id = created_log.get('id') if created_log else "unknown"
            logger.info(f"[STREAM] Successfully logged food from text as {food_log_id}")

            # Invalidate daily summary cache so the next fetch returns fresh data
            from api.v1.nutrition.summaries import invalidate_daily_summary_cache
            from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
            await invalidate_daily_summary_cache(body.user_id)
            await invalidate_bootstrap_cache(body.user_id)

            # Send the completed food log
            cache_hit = food_analysis.get("cache_hit", False) if food_analysis else False
            cache_source = food_analysis.get("cache_source") if food_analysis else None

            response_data = {
                "success": True,
                "food_log_id": food_log_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "overall_meal_score": overall_meal_score,
                "health_score": health_score,
                "health_score_reasons": health_score_reasons,
                "goal_alignment_percentage": goal_alignment_percentage,
                "ai_suggestion": ai_suggestion,
                "encouragements": encouragements,
                "warnings": warnings,
                "recommended_swap": recommended_swap,
                "total_time_ms": elapsed_ms(),
                "cache_hit": cache_hit,
                "cache_source": cache_source,
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Food logging error: {e}", exc_info=True)
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


@router.post("/analyze-text")
@limiter.limit("10/minute")
async def analyze_food_text(
    request: Request,
    body: AnalyzeTextRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Analyze food from text description (non-streaming).

    DOES NOT save to database - returns analysis only for user review.
    Use /log-direct to save after user confirmation.

    Returns the full analysis result as JSON with an 8s timeout.
    On timeout, returns HTTP 504.
    """
    logger.info(f"[ANALYZE-TEXT] Analyzing food for user {current_user['id']}: {body.description[:80]}...")

    cache_service = get_food_analysis_cache_service()
    try:
        result = await asyncio.wait_for(
            cache_service.analyze_food(
                description=body.description,
                user_id=current_user["id"],
                use_cache=True,
            ),
            timeout=8.0,
        )
        if result:
            return result
        raise HTTPException(status_code=422, detail="Could not analyze food")
    except asyncio.TimeoutError:
        logger.warning(f"[ANALYZE-TEXT] Timed out for: {body.description[:80]}", exc_info=True)
        raise HTTPException(status_code=504, detail="Analysis timed out")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[ANALYZE-TEXT] Error: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")



@router.post("/food-review")
@limiter.limit("20/minute")
async def review_food(
    request: Request,
    body: FoodReviewRequest,
    current_user: dict = Depends(get_current_user),
):
    """AI-powered food review based on user goals."""
    logger.info(f"[FOOD-REVIEW] Reviewing '{body.food_name}' for user {current_user['id']}")

    cache_service = get_food_analysis_cache_service()
    macros = {
        "calories": body.calories,
        "protein_g": body.protein_g,
        "carbs_g": body.carbs_g,
        "fat_g": body.fat_g,
    }
    try:
        result = await asyncio.wait_for(
            cache_service.review_food(
                food_name=body.food_name,
                macros=macros,
                user_id=current_user["id"],
            ),
            timeout=10.0,
        )
        return result
    except asyncio.TimeoutError:
        logger.warning(f"[FOOD-REVIEW] Timed out for: {body.food_name}", exc_info=True)
        raise HTTPException(status_code=504, detail="Food review timed out")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[FOOD-REVIEW] Error: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


