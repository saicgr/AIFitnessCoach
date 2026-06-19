"""Nutrition preferences and dynamic targets endpoints."""
import asyncio
from core.db import get_supabase_db
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, local_date_to_utc_range, user_today_date
from core.logger import get_logger

from api.v1.nutrition.models import (
    NutritionPreferencesResponse,
    NutritionPreferencesUpdate,
    DynamicTargetsResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.get("/preferences/{user_id}", response_model=NutritionPreferencesResponse)
async def get_nutrition_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's nutrition preferences.

    Returns nutrition goals, targets, dietary restrictions, and settings.
    """
    logger.info(f"Getting nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Synchronous Supabase call — offload to a thread so it doesn't block
        # this async worker's event loop under concurrent load.
        result = await asyncio.get_event_loop().run_in_executor(
            None,
            lambda: db.client.table("nutrition_preferences")
            .select("*")
            .eq("user_id", user_id)
            .maybe_single()
            .execute(),
        )

        if not result or not result.data:
            # Return default preferences
            return NutritionPreferencesResponse(user_id=user_id)

        data = result.data
        # Get nutrition_goals, fallback to single goal in array if not present
        nutrition_goals = data.get("nutrition_goals") or []
        if not nutrition_goals and data.get("nutrition_goal"):
            nutrition_goals = [data.get("nutrition_goal")]

        # goal_weight_kg is stored as target_weight_kg in the users table
        goal_weight_kg = None
        try:
            user_result = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: db.client.table("users")
                .select("target_weight_kg")
                .eq("id", user_id)
                .maybe_single()
                .execute(),
            )
            if user_result and user_result.data:
                goal_weight_kg = user_result.data.get("target_weight_kg")
        except Exception:
            pass

        return NutritionPreferencesResponse(
            id=data.get("id"),
            user_id=data.get("user_id", user_id),
            nutrition_goals=nutrition_goals,
            nutrition_goal=data.get("nutrition_goal") or (nutrition_goals[0] if nutrition_goals else "maintain"),
            rate_of_change=data.get("rate_of_change"),
            goal_weight_kg=goal_weight_kg,
            goal_date=str(data["goal_date"]) if data.get("goal_date") else None,
            weeks_to_goal=data.get("weeks_to_goal"),
            calculated_bmr=data.get("calculated_bmr"),
            calculated_tdee=data.get("calculated_tdee"),
            target_calories=data.get("target_calories"),
            target_protein_g=data.get("target_protein_g"),
            target_carbs_g=data.get("target_carbs_g"),
            target_fat_g=data.get("target_fat_g"),
            target_fiber_g=data.get("target_fiber_g", 25),
            diet_type=data.get("diet_type", "balanced"),
            custom_carb_percent=data.get("custom_carb_percent"),
            custom_protein_percent=data.get("custom_protein_percent"),
            custom_fat_percent=data.get("custom_fat_percent"),
            allergies=data.get("allergies") or [],
            dietary_restrictions=data.get("dietary_restrictions") or [],
            disliked_foods=data.get("disliked_foods") or [],
            meal_pattern=data.get("meal_pattern", "3_meals"),
            cooking_skill=data.get("cooking_skill", "intermediate"),
            cooking_time_minutes=data.get("cooking_time_minutes", 30),
            budget_level=data.get("budget_level", "moderate"),
            show_ai_feedback_after_logging=data.get("show_ai_feedback_after_logging", True),
            calm_mode_enabled=data.get("calm_mode_enabled", False),
            show_weekly_instead_of_daily=data.get("show_weekly_instead_of_daily", False),
            adjust_calories_for_training=data.get("adjust_calories_for_training", True),
            adjust_calories_for_rest=data.get("adjust_calories_for_rest", False),
            nutrition_onboarding_completed=data.get("nutrition_onboarding_completed", False),
            onboarding_completed_at=datetime.fromisoformat(str(data.get("onboarding_completed_at")).replace("Z", "+00:00")) if data.get("onboarding_completed_at") else None,
            last_recalculated_at=datetime.fromisoformat(str(data.get("last_recalculated_at")).replace("Z", "+00:00")) if data.get("last_recalculated_at") else None,
            created_at=datetime.fromisoformat(str(data.get("created_at")).replace("Z", "+00:00")) if data.get("created_at") else None,
            updated_at=datetime.fromisoformat(str(data.get("updated_at")).replace("Z", "+00:00")) if data.get("updated_at") else None,
            weekly_checkin_enabled=data.get("weekly_checkin_enabled", True),
            last_weekly_checkin_at=datetime.fromisoformat(str(data.get("last_weekly_checkin_at")).replace("Z", "+00:00")) if data.get("last_weekly_checkin_at") else None,
            weekly_checkin_dismiss_count=data.get("weekly_checkin_dismiss_count", 0),
            # Gap 6 / Gap 7 — optional-tracker toggles + limits.
            hydration_tracking_enabled=data.get("hydration_tracking_enabled", True),
            sugar_tracking_enabled=data.get("sugar_tracking_enabled", False),
            caffeine_tracking_enabled=data.get("caffeine_tracking_enabled", False),
            alcohol_tracking_enabled=data.get("alcohol_tracking_enabled", False),
            sugar_limit_g=data.get("sugar_limit_g", 36),
            caffeine_limit_mg=data.get("caffeine_limit_mg", 400),
            alcohol_limit_units=data.get("alcohol_limit_units", 2),
            # Per-meal P/C/F targets (migration 2275).
            per_meal_targets_enabled=data.get("per_meal_targets_enabled", False),
            per_meal_macro_targets=data.get("per_meal_macro_targets"),
            # Per-weekday (high/base day) targets (migration 2276).
            per_weekday_targets=data.get("per_weekday_targets"),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/preferences/{user_id}", response_model=NutritionPreferencesResponse)
async def update_nutrition_preferences(user_id: str, request: NutritionPreferencesUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update user's nutrition preferences.

    Allows updating goals, targets, dietary restrictions, and settings.
    """
    logger.info(f"Updating nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Build update data, only including non-None fields
        update_data = {}
        for field, value in request.model_dump().items():
            if value is not None:
                update_data[field] = value

        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            # Update existing
            result = db.client.table("nutrition_preferences")\
                .update(update_data)\
                .eq("user_id", user_id)\
                .execute()
        else:
            # Insert new
            update_data["user_id"] = user_id
            result = db.client.table("nutrition_preferences")\
                .insert(update_data)\
                .execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to update preferences"), "nutrition")

        # This endpoint carries the calorie/macro TARGETS (the app's Edit
        # Daily Targets sheet saves through here). A target change makes every
        # cached payload that bakes in the goals stale: the daily-summary ring
        # denominators, food patterns, and the home bootstrap. Bust them so the
        # next read recomputes live against the new targets — and so a stale
        # summary snapshot can never be served back to the client and blank the
        # day's already-logged food (the summary is computed live from
        # food_logs, so a fresh recompute always returns the real meals).
        # Mirrors PUT /targets/{user_id}. Best-effort: a cache miss must not
        # fail the write. Imported locally to avoid an import cycle.
        try:
            from api.v1.nutrition.summaries import invalidate_daily_summary_cache
            from api.v1.nutrition.food_patterns import invalidate_patterns_cache
            from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
            await invalidate_daily_summary_cache(user_id)
            await invalidate_patterns_cache(user_id)
            await invalidate_bootstrap_cache(user_id)
        except Exception as cache_exc:
            logger.warning(
                f"Preference update cache invalidation failed for {user_id}: {cache_exc}",
                exc_info=True,
            )

        # Return the updated preferences
        return await get_nutrition_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update nutrition preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ─── Per-meal P/C/F targets (migration 2275) ──────────────────────────────────
# Default per-meal calorie weights. Filtered to the user's ACTIVE meals and
# re-normalized to sum to 1.0 (so 3-meal users get ~0.30/0.35/0.35).
_DEFAULT_MEAL_SPLIT = {
    "breakfast": 0.25,
    "lunch": 0.30,
    "dinner": 0.35,
    "snacks": 0.10,
}
_ALL_MEAL_TYPES = ["breakfast", "lunch", "dinner", "snacks"]


def _active_meal_types(prefs: dict) -> List[str]:
    """Resolve the user's active meal types from nutrition_preferences.

    Reads `meals_per_day` (int) first, then `meal_pattern` (e.g. "3_meals",
    "4_meals", "5_meals"). 4+ meals include snacks; 3 meals do not. Defaults to
    4 meals (with snacks) when nothing is set. Always returns meal types in the
    canonical breakfast→lunch→dinner→snacks order.
    """
    n: Optional[int] = None

    raw_n = prefs.get("meals_per_day")
    if raw_n is not None:
        try:
            n = int(raw_n)
        except (TypeError, ValueError):
            n = None

    if n is None:
        pattern = prefs.get("meal_pattern")
        if isinstance(pattern, str):
            # Pull the leading integer out of patterns like "3_meals"/"4 meals".
            digits = "".join(ch for ch in pattern if ch.isdigit())
            if digits:
                try:
                    n = int(digits)
                except ValueError:
                    n = None

    if n is None:
        n = 4  # default: full breakfast/lunch/dinner/snacks split

    if n >= 4:
        return list(_ALL_MEAL_TYPES)            # breakfast, lunch, dinner, snacks
    # 3 (or fewer) meals → no snacks bucket.
    return ["breakfast", "lunch", "dinner"]


def _normalized_split(active_meals: List[str], stored_split: Optional[dict]) -> dict:
    """Build a per-meal weight map summing to 1.0 over the active meals.

    Uses `stored_split` when present (a JSONB `split`), else the default split.
    Filters to active meals and re-normalizes. Falls back to an even split if
    the source weights sum to zero (e.g. all-zero or missing keys).
    """
    source = stored_split if isinstance(stored_split, dict) and stored_split else _DEFAULT_MEAL_SPLIT

    raw: dict = {}
    for meal in active_meals:
        try:
            raw[meal] = float(source.get(meal, 0) or 0)
        except (TypeError, ValueError):
            raw[meal] = 0.0

    total = sum(raw.values())
    if total <= 0:
        # No usable weights — split evenly so we never divide by zero.
        even = 1.0 / len(active_meals) if active_meals else 0.0
        return {meal: even for meal in active_meals}

    return {meal: raw[meal] / total for meal in active_meals}


def _compute_per_meal_targets(daily: dict, prefs: dict) -> Optional[dict]:
    """Split a daily dynamic target into per-meal P/C/F + calorie targets.

    Args:
        daily: the already-computed daily target with keys
            target_protein_g / target_carbs_g / target_fat_g / target_calories
            (ints, AFTER the training/fasting/cycle adjustments).
        prefs: the nutrition_preferences row (dict). Reads
            per_meal_targets_enabled, per_meal_macro_targets (the JSONB config),
            and meals_per_day/meal_pattern to resolve active meals.

    Returns:
        None when the feature is disabled. Otherwise a dict keyed by active meal
        type → {target_protein_g, target_carbs_g, target_fat_g, target_calories}
        (all ints, floored at 0).

    Modes (from per_meal_macro_targets.mode):
        "auto" (or null config): each macro is split across active meals by the
            re-normalized per-meal weight.
        "custom": meals listed in `overrides` use those explicit P/C/F grams
            (calories derived 4·P + 4·C + 9·F). The remaining daily macros (daily
            minus the override sums, floored at 0) are auto-split across the
            active meals WITHOUT an override, by their re-normalized weights.
    """
    if not prefs.get("per_meal_targets_enabled"):
        return None

    active_meals = _active_meal_types(prefs)
    if not active_meals:
        return None

    daily_protein = float(daily.get("target_protein_g") or 0)
    daily_carbs = float(daily.get("target_carbs_g") or 0)
    daily_fat = float(daily.get("target_fat_g") or 0)

    config = prefs.get("per_meal_macro_targets")
    if not isinstance(config, dict):
        config = {}
    mode = config.get("mode") or "auto"
    stored_split = config.get("split")
    overrides = config.get("overrides") if isinstance(config.get("overrides"), dict) else {}

    weights = _normalized_split(active_meals, stored_split)

    def _meal_entry(protein: float, carbs: float, fat: float) -> dict:
        p = max(0, int(round(protein)))
        c = max(0, int(round(carbs)))
        f = max(0, int(round(fat)))
        return {
            "target_protein_g": p,
            "target_carbs_g": c,
            "target_fat_g": f,
            "target_calories": 4 * p + 4 * c + 9 * f,
        }

    result: dict = {}

    if mode == "custom" and overrides:
        # 1) Honor explicit overrides for the active meals that have one.
        used_protein = used_carbs = used_fat = 0.0
        override_meals = []
        for meal in active_meals:
            ov = overrides.get(meal)
            if isinstance(ov, dict):
                p = float(ov.get("protein_g") or 0)
                c = float(ov.get("carbs_g") or 0)
                f = float(ov.get("fat_g") or 0)
                result[meal] = _meal_entry(p, c, f)
                used_protein += p
                used_carbs += c
                used_fat += f
                override_meals.append(meal)

        # 2) Auto-split the REMAINING daily macros across the active meals that
        #    have no override, by their weights re-normalized over JUST those
        #    meals (floored at 0 so an over-allocating override can't go negative).
        remaining_meals = [m for m in active_meals if m not in override_meals]
        if remaining_meals:
            rem_protein = max(0.0, daily_protein - used_protein)
            rem_carbs = max(0.0, daily_carbs - used_carbs)
            rem_fat = max(0.0, daily_fat - used_fat)
            rem_weights = _normalized_split(remaining_meals, stored_split)
            for meal in remaining_meals:
                w = rem_weights[meal]
                result[meal] = _meal_entry(
                    rem_protein * w, rem_carbs * w, rem_fat * w
                )
    else:
        # Auto mode — split each macro by the per-meal weight.
        for meal in active_meals:
            w = weights[meal]
            result[meal] = _meal_entry(
                daily_protein * w, daily_carbs * w, daily_fat * w
            )

    return result


# ─── Per-weekday (high/base day) targets (migration 2276) ─────────────────────
def _resolve_weekday_target(
    prefs: dict,
    target_weekday: int,
    has_workout: bool,
) -> Optional[dict]:
    """Resolve the per-weekday override for a date, if enabled.

    Args:
        prefs: the nutrition_preferences row (dict). Reads `per_weekday_targets`.
        target_weekday: target_date.weekday() (0=Mon..6=Sun).
        has_workout: whether the date is a training day (scheduled OR logged) —
            reused to bind "high" days to the workout schedule.

    Returns:
        None when the feature is off (NULL config, not a dict, or enabled is
        falsy) → the caller keeps the existing training/rest behavior unchanged.
        Otherwise a dict:
            {protein_g, carbs_g, fat_g, calories, is_high_day, target_source}
        with the absolute macros for the resolved day type (calories derived
        4·P + 4·C + 9·F) and the attribution flags. This REPLACES the automatic
        training/rest calorie bump for the date.

    Fail-open: any parsing fault returns None (caller falls back to the
    existing day-type logic), never raises.
    """
    config = prefs.get("per_weekday_targets")
    if not isinstance(config, dict):
        return None
    if not config.get("enabled"):
        return None

    bind = bool(config.get("bind_to_training_days"))
    if bind:
        is_high = bool(has_workout)
    else:
        high_days_raw = config.get("high_days")
        high_days = []
        if isinstance(high_days_raw, list):
            for d in high_days_raw:
                try:
                    high_days.append(int(d))
                except (TypeError, ValueError):
                    continue
        is_high = target_weekday in high_days

    macros = config.get("high") if is_high else config.get("base")
    if not isinstance(macros, dict):
        # Enabled but the relevant day-type block is missing/malformed — fall
        # back to existing behavior rather than zeroing the user's targets.
        return None

    try:
        p = max(0, int(round(float(macros.get("protein_g") or 0))))
        c = max(0, int(round(float(macros.get("carbs_g") or 0))))
        f = max(0, int(round(float(macros.get("fat_g") or 0))))
    except (TypeError, ValueError):
        return None

    # An all-zero override is meaningless — treat as not configured.
    if p == 0 and c == 0 and f == 0:
        return None

    return {
        "protein_g": p,
        "carbs_g": c,
        "fat_g": f,
        "calories": 4 * p + 4 * c + 9 * f,
        "is_high_day": is_high,
        "target_source": "weekday_high" if is_high else "weekday_base",
    }


@router.get("/dynamic-targets/{user_id}", response_model=DynamicTargetsResponse)
async def get_dynamic_nutrition_targets(
    request: Request,
    user_id: str,
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format, defaults to today"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get dynamic nutrition targets for a specific date.

    Adjusts base targets based on:
    - Whether it's a training day (workout scheduled/completed)
    - Whether it's a fasting day (for 5:2, ADF protocols)
    - User's preferences for training/rest day adjustments
    """
    logger.info(f"Getting dynamic nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        # Parse target date
        if date:
            target_date = datetime.fromisoformat(date).date()
        else:
            target_date = user_today_date(request, db, user_id)

        target_date_str = target_date.isoformat()

        # Get user's base preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        prefs = (prefs_result.data if prefs_result else None) or {}

        base_calories = prefs.get("target_calories") or 2000
        base_protein = prefs.get("target_protein_g") or 150
        base_carbs = prefs.get("target_carbs_g") or 200
        base_fat = prefs.get("target_fat_g") or 65
        base_fiber = prefs.get("target_fiber_g") or 25
        adjust_for_training = prefs.get("adjust_calories_for_training", True)
        adjust_for_rest = prefs.get("adjust_calories_for_rest", False)

        # Check if today is a training day per the user's workout schedule
        # workout_days is stored as 0-indexed (0=Mon, 1=Tue, ..., 6=Sun)
        # Python's weekday() is also 0=Mon, 1=Tue, ..., 6=Sun
        is_scheduled_training_day = False
        gym_profile_result = db.client.table("gym_profiles")\
            .select("workout_days")\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .maybe_single()\
            .execute()

        if gym_profile_result and gym_profile_result.data:
            workout_days = gym_profile_result.data.get("workout_days") or []
            is_scheduled_training_day = target_date.weekday() in workout_days

        # Check if there's a workout logged today (timezone-aware UTC range)
        utc_start, utc_end = local_date_to_utc_range(target_date_str, user_tz)
        workout_result = db.client.table("workout_logs")\
            .select("id")\
            .eq("user_id", user_id)\
            .gte("completed_at", utc_start)\
            .lt("completed_at", utc_end)\
            .execute()

        has_workout_log = bool(workout_result and workout_result.data)

        # A day counts as a training day if:
        # 1. It's in the user's workout_days schedule, OR
        # 2. There's an actual completed workout log for it
        has_workout = is_scheduled_training_day or has_workout_log

        # Check if it's a fasting day (for 5:2 or ADF protocols)
        is_fasting_day = False
        fasting_prefs = db.client.table("fasting_preferences")\
            .select("default_protocol, fasting_days")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if fasting_prefs and fasting_prefs.data:
            protocol = fasting_prefs.data.get("default_protocol", "")
            fasting_days = fasting_prefs.data.get("fasting_days") or []

            if protocol in ["5:2", "adf"]:
                day_name = target_date.strftime("%A").lower()
                is_fasting_day = day_name in [d.lower() for d in fasting_days]

        # ── Per-weekday (high/base day) override (migration 2276) ──────────
        # Resolved FIRST so it can REPLACE the automatic training/rest calorie
        # bump for this date — the weekday override is the absolute target, so
        # there's no double-count and today never shows a surprise number. Fasting
        # + cycle adjustments still layer on after (existing order). Fail-open:
        # _resolve_weekday_target returns None on any fault → unchanged behavior.
        weekday_override = None
        is_high_day = None
        target_source = None
        try:
            weekday_override = _resolve_weekday_target(
                prefs, target_date.weekday(), has_workout
            )
        except Exception as wd_err:
            logger.warning(
                f"Per-weekday target resolution skipped for user {user_id}: {wd_err}",
                exc_info=True,
            )
            weekday_override = None

        # Calculate adjustments
        calorie_adjustment = 0
        adjustment_reason = None

        if weekday_override is not None:
            # Weekday override sets the day's base macros directly and REPLACES
            # the training/rest calorie bump. Fasting still reduces from here.
            base_protein = weekday_override["protein_g"]
            base_carbs = weekday_override["carbs_g"]
            base_fat = weekday_override["fat_g"]
            base_calories = weekday_override["calories"]
            is_high_day = weekday_override["is_high_day"]
            target_source = weekday_override["target_source"]

            if is_fasting_day:
                calorie_adjustment = -int(base_calories * 0.75)  # 25% of normal
                adjustment_reason = "Fasting day - reduced calories"
        else:
            if is_fasting_day:
                # Fasting day: significant calorie reduction
                calorie_adjustment = -int(base_calories * 0.75)  # 25% of normal
                adjustment_reason = "Fasting day - reduced calories"
            elif has_workout and adjust_for_training:
                # Training day: increase calories
                calorie_adjustment = 200
                adjustment_reason = "Training day - extra fuel for workout and recovery"
                target_source = "training"
            elif not has_workout and adjust_for_rest:
                # Rest day: slight decrease
                calorie_adjustment = -100
                adjustment_reason = "Rest day - slightly reduced intake"
                target_source = "rest"
            else:
                target_source = "base"

        target_calories = base_calories + calorie_adjustment

        # Adjust protein on training days — SKIPPED when a weekday override is
        # active (the override's absolute macros already encode the day type).
        target_protein = base_protein
        if weekday_override is None and has_workout and adjust_for_training:
            target_protein = int(base_protein * 1.1)  # 10% more protein

        # Adjust carbs on training days — SKIPPED under a weekday override.
        target_carbs = base_carbs
        if weekday_override is None and has_workout and adjust_for_training:
            target_carbs = int(base_carbs * 1.15)  # 15% more carbs for glycogen

        target_fat = base_fat

        # ── Cycle-phase-aware adjustment (Phase H) ─────────────────────────
        # Layered LAST, on top of the training/fasting/rest adjustments, so
        # the luteal calorie bump and the phase macro shift stack with the
        # day-type logic above. Entirely a no-op unless the user opted in to
        # `hormonal_profiles.cycle_sync_nutrition` and has a real prediction.
        cycle_sync_applied = False
        cycle_phase = None
        cycle_calorie_adjustment = 0
        cycle_adjustment_reason = None
        try:
            from services.cycle.cycle_nutrition import (
                get_cycle_phase_if_synced,
                adjust_calories_for_phase,
                adjust_macro_split_for_phase,
            )

            cycle_phase = get_cycle_phase_if_synced(db.client, user_id, target_date)
            if cycle_phase is not None:
                cycle_sync_applied = True

                # Calorie bump (luteal only). Layered on the already
                # day-type-adjusted target.
                target_calories, cycle_calorie_adjustment, cycle_cal_reason = (
                    adjust_calories_for_phase(target_calories, cycle_phase)
                )

                # Phase-shifted macro split. Derive the *current* split
                # from the (post-training-adjustment) macro grams so the
                # phase delta layers over the user's real split, then
                # re-apply the shifted split to the final calorie total.
                cur_carb_kcal = target_carbs * 4
                cur_protein_kcal = target_protein * 4
                cur_fat_kcal = target_fat * 9
                cur_total = cur_carb_kcal + cur_protein_kcal + cur_fat_kcal
                if cur_total > 0:
                    base_carb_pct = round(cur_carb_kcal * 100 / cur_total)
                    base_protein_pct = round(cur_protein_kcal * 100 / cur_total)
                    base_fat_pct = 100 - base_carb_pct - base_protein_pct
                    (shift_carb_pct, shift_protein_pct, shift_fat_pct), macro_reason = (
                        adjust_macro_split_for_phase(
                            base_carb_pct, base_protein_pct, base_fat_pct, cycle_phase
                        )
                    )
                    if macro_reason is not None:
                        target_protein = int((target_calories * shift_protein_pct / 100) / 4)
                        target_carbs = int((target_calories * shift_carb_pct / 100) / 4)
                        target_fat = int((target_calories * shift_fat_pct / 100) / 9)
                else:
                    macro_reason = None

                # Surface a single combined attribution string the UI can
                # show as the "cycle adjustment" label.
                cycle_adjustment_reason = cycle_cal_reason or macro_reason
                if cycle_cal_reason and macro_reason and cycle_cal_reason != macro_reason:
                    cycle_adjustment_reason = f"{cycle_cal_reason}; {macro_reason}"
        except Exception as cycle_err:
            # A cycle-tracking fault must never break the daily targets.
            logger.warning(
                f"Cycle-aware nutrition adjustment skipped for user {user_id}: {cycle_err}",
                exc_info=True,
            )
            cycle_sync_applied = False
            cycle_phase = None
            cycle_calorie_adjustment = 0
            cycle_adjustment_reason = None

        # Per-meal P/C/F targets (migration 2275). Derived from the FINAL daily
        # target so it automatically inherits every training/fasting/cycle
        # adjustment above. None unless the user opted in. Fail-open: a fault in
        # the split must never break the daily targets the whole nutrition tab
        # depends on.
        per_meal_targets = None
        try:
            per_meal_targets = _compute_per_meal_targets(
                {
                    "target_protein_g": target_protein,
                    "target_carbs_g": target_carbs,
                    "target_fat_g": target_fat,
                    "target_calories": target_calories,
                },
                prefs,
            )
        except Exception as meal_err:
            logger.warning(
                f"Per-meal target split skipped for user {user_id}: {meal_err}",
                exc_info=True,
            )
            per_meal_targets = None

        return DynamicTargetsResponse(
            target_calories=target_calories,
            target_protein_g=target_protein,
            target_carbs_g=target_carbs,
            target_fat_g=target_fat,
            target_fiber_g=base_fiber,
            is_training_day=has_workout,
            is_fasting_day=is_fasting_day,
            is_rest_day=not has_workout and not is_fasting_day,
            adjustment_reason=adjustment_reason,
            calorie_adjustment=calorie_adjustment,
            cycle_sync_applied=cycle_sync_applied,
            cycle_phase=cycle_phase,
            cycle_calorie_adjustment=cycle_calorie_adjustment,
            cycle_adjustment_reason=cycle_adjustment_reason,
            per_meal_targets=per_meal_targets,
            is_high_day=is_high_day,
            target_source=target_source,
        )

    except Exception as e:
        logger.error(f"Failed to get dynamic nutrition targets: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")



# ─── L3 "It remembers you" — standing food-logging rules ──────────────────────
# A user can define standing rules ("no bun", "0-cal sweetener", "we cook
# low-oil South Indian", "skim milk not whole"). They are stored as a JSONB
# array on nutrition_preferences.food_logging_rules and auto-injected into
# every food photo + text analysis (see services/food_logging_rules_service.py).

import uuid as _uuid
from pydantic import BaseModel as _BaseModel, Field as _Field
from services.food_logging_rules_service import (
    fetch_food_logging_rules,
    detect_rule_conflicts,
    MAX_RULES,
)


class FoodLoggingRuleCreate(_BaseModel):
    """Payload to add a new standing rule."""
    text: str = _Field(..., min_length=1, max_length=200)


class FoodLoggingRuleUpdate(_BaseModel):
    """Payload to edit a rule. Either field may be supplied."""
    text: Optional[str] = _Field(None, min_length=1, max_length=200)
    enabled: Optional[bool] = None


def _persist_rules(db, user_id: str, rules: List[dict]) -> None:
    """Write the full rules array back to nutrition_preferences (upsert)."""
    payload = {
        "food_logging_rules": rules,
        "updated_at": datetime.utcnow().isoformat(),
    }
    existing = (
        db.client.table("nutrition_preferences")
        .select("id")
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )
    if existing and existing.data:
        db.client.table("nutrition_preferences").update(payload).eq("user_id", user_id).execute()
    else:
        payload["user_id"] = user_id
        db.client.table("nutrition_preferences").insert(payload).execute()


def _rules_response(rules: List[dict]) -> dict:
    """Shape the standard response: rules + any detected conflicts (C9)."""
    return {
        "rules": rules,
        "conflicts": detect_rule_conflicts(rules),
        "max_rules": MAX_RULES,
    }


@router.get("/preferences/{user_id}/food-logging-rules")
async def list_food_logging_rules(user_id: str, current_user: dict = Depends(get_current_user)):
    """List the user's standing food-logging rules + any conflicting pairs."""
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        rules = fetch_food_logging_rules(db, user_id)
        return _rules_response(rules)
    except Exception as e:
        logger.error(f"Failed to list food-logging rules: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/preferences/{user_id}/food-logging-rules")
async def add_food_logging_rule(
    user_id: str,
    body: FoodLoggingRuleCreate,
    current_user: dict = Depends(get_current_user),
):
    """Add a new standing rule. Rejects when the per-user cap is reached."""
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        rules = fetch_food_logging_rules(db, user_id)
        if len(rules) >= MAX_RULES:
            raise HTTPException(
                status_code=400,
                detail=f"You can have at most {MAX_RULES} standing rules. Delete one to add another.",
            )
        new_rule = {
            "id": str(_uuid.uuid4()),
            "text": body.text.strip()[:200],
            "created_at": datetime.utcnow().isoformat(),
            "enabled": True,
        }
        rules.append(new_rule)
        _persist_rules(db, user_id, rules)
        return _rules_response(rules)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add food-logging rule: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.patch("/preferences/{user_id}/food-logging-rules/{rule_id}")
async def update_food_logging_rule(
    user_id: str,
    rule_id: str,
    body: FoodLoggingRuleUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Edit a rule's text or toggle it enabled/disabled (C9 — stale-rule review)."""
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        rules = fetch_food_logging_rules(db, user_id)
        found = False
        for r in rules:
            if r.get("id") == rule_id:
                if body.text is not None:
                    r["text"] = body.text.strip()[:200]
                if body.enabled is not None:
                    r["enabled"] = body.enabled
                found = True
                break
        if not found:
            raise HTTPException(status_code=404, detail="Rule not found.")
        _persist_rules(db, user_id, rules)
        return _rules_response(rules)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update food-logging rule: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/preferences/{user_id}/food-logging-rules/{rule_id}")
async def delete_food_logging_rule(
    user_id: str,
    rule_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a standing rule."""
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        rules = fetch_food_logging_rules(db, user_id)
        remaining = [r for r in rules if r.get("id") != rule_id]
        if len(remaining) == len(rules):
            raise HTTPException(status_code=404, detail="Rule not found.")
        _persist_rules(db, user_id, remaining)
        return _rules_response(remaining)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete food-logging rule: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")
