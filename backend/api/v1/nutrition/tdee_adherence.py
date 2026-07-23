"""Detailed TDEE analysis, adherence tracking, and recommendation options endpoints."""
from core.db import get_supabase_db
from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, local_range_bounds, get_user_today, utc_to_local_date
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity
from services.adaptive_tdee_service import get_adaptive_tdee_service, FoodLogSummary, WeightLog as ServiceWeightLog
from services.adherence_tracking_service import get_adherence_tracking_service, NutritionTargets as ServiceNutritionTargets, NutritionActuals
from services.metabolic_adaptation_service import get_metabolic_adaptation_service, TDEEHistoryEntry

from api.v1.nutrition.models import (
    DetailedTDEEResponse,
    AdherenceSummaryResponse,
    RecommendationOption,
    RecommendationOptionsResponse,
    SelectRecommendationRequest,
)

router = APIRouter()
logger = get_logger(__name__)

# The four columns that together constitute a *configured* nutrition plan.
# All-or-nothing: a row with calories but no macro split cannot be scored
# (`calculate_macro_adherence` does `target <= 0`, which raises TypeError on
# a NULL) and must never be back-filled with invented macros.
_TARGET_COLUMNS = ("target_calories", "target_protein_g", "target_carbs_g", "target_fat_g")

# Machine-readable reason header on the "nothing to score" response, so a client
# can tell WHICH unknown it is (no plan configured vs. plan configured but the
# window is empty) instead of inferring it from the body.
_REASON_HEADER = "X-Nutrition-Adherence-Unavailable"
_REASON_NO_TARGETS = "targets-not-configured"
_REASON_NO_LOGS = "no-logs-in-window"


class _NoConfiguredTargets(Exception):
    """Internal control-flow signal: the user has no nutrition targets set.

    Distinct from a real failure so the caller can log it at INFO and leave
    the derived score as *unknown* rather than substituting a number.
    """


def _configured_targets(prefs: Optional[dict]) -> Optional[ServiceNutritionTargets]:
    """Return the user's nutrition targets, or ``None`` if they never set any.

    Having no nutrition targets is a NORMAL state (fresh account, onboarding
    that skipped the nutrition step) — not an error, and not something to
    paper over. There is deliberately NO ``2000 / 150 / 200 / 65`` fallback
    here: a fabricated target would (a) score an unconfigured user against a
    plan they never chose, and (b) feed a bogus adherence number into the
    recommendation engine, which then picks their deficit. This mirrors the
    frontend contract — `currentCalorieTarget` / `hasConfiguredTargets` in
    `nutrition_preferences_provider.dart` are nullable by design.

    Returns None when the row is missing, when ANY of the four target columns
    is NULL, or when any of them is non-positive.
    """
    if not prefs:
        return None
    values: dict = {}
    for column in _TARGET_COLUMNS:
        raw = prefs.get(column)
        if raw is None:
            return None
        try:
            numeric = float(raw)
        except (TypeError, ValueError):
            return None
        if numeric <= 0:
            return None
        values[column] = numeric
    return ServiceNutritionTargets(
        calories=int(values["target_calories"]),
        protein_g=values["target_protein_g"],
        carbs_g=values["target_carbs_g"],
        fat_g=values["target_fat_g"],
    )


def _adherence_unavailable(reason: str) -> Response:
    """``200 OK`` with a JSON ``null`` body — "there is no adherence to report".

    Why a JSON ``null`` and not a 204, and not a populated body:

    * **Not a populated 200 body.** The shipped Flutter client's
      `AdherenceSummary.fromJson` coerces every null field to `0.0` /
      `'medium'`, so ANY object body renders a "0% adherence / MEDIUM
      sustainability" ring — a fabricated grade for someone with nothing to
      grade.
    * **Not a 204.** This was the round-1 choice and it was wrong at the client
      boundary. `NutritionRepository.getAdherenceSummary` branches on
      `response.data == null`, and Dio 5.9.2's default `FusedTransformer`
      only yields `null` for a body it recognises as JSON
      (`fused_transformer.dart:60-63` gates on the *content-type* header).
      FastAPI's 204 carries no content-type, so the transformer falls through
      to `utf8.decode(responseBytes)` (`:99-105`) and hands the client the
      empty **string** `''` — which is not null, so the client proceeds to
      `AdherenceSummary.fromJson('' as Map<String, dynamic>)` and throws a
      TypeError. It ends up null only via the catch-all, logged as an error.
    * **A JSON `null` at 200** sets `content-type: application/json`, so the
      transformer takes the fast path, `jsonDecode('null')` → `null`, and the
      client's *intended* `response.data == null → return null` branch fires.
      `AdherenceCard` then renders its "not enough data" empty state. No
      exception, no fabricated ring, no 404 noise on every home render.

    `reason` is echoed in `X-Nutrition-Adherence-Unavailable` so a client can
    distinguish the two unknowns (and distinguish both from an error, which is
    a 5xx). Nothing in the shipped client reads it yet — see the
    findingsNotFixed note for the exact client change that would.
    """
    return Response(
        content="null",
        media_type="application/json",
        status_code=200,
        headers={_REASON_HEADER: reason},
    )


@router.get("/tdee/{user_id}/detailed", response_model=DetailedTDEEResponse)
async def get_detailed_tdee(request: Request, user_id: str, days: int = Query(default=14, ge=7, le=30), current_user: dict = Depends(get_current_user)):
    """
    Get TDEE with confidence intervals, weight trend, and metabolic adaptation status.

    This endpoint provides MacroFactor-style detailed TDEE calculation:
    - EMA-smoothed weight trends
    - Confidence intervals (e.g., "2,150 ±120 cal")
    - Metabolic adaptation detection
    - Data quality scoring
    """
    # Ownership check — this endpoint reads another person's weight history and
    # calorie intake. Its siblings (`/recommendations/{user_id}/options`,
    # `/recommendations/{user_id}/select`) have always enforced this; it was
    # missing here and on `/adherence/{user_id}/summary`, so any authenticated
    # user could read any other user's data by swapping the path id.
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    logger.info(f"Getting detailed TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        tdee_service = get_adaptive_tdee_service()
        adaptation_service = get_metabolic_adaptation_service()

        # Get food logs for the period.
        # start_date/end_date are LOCAL calendar days; `logged_at` is a UTC
        # timestamptz, so the window has to be converted before it can filter
        # the column. Bare date strings made `.lte(end_date)` mean midnight UTC,
        # which dropped the entire current local day from the analysis.
        end_date = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        start_date = end_date - timedelta(days=days)
        window_start, window_end = local_range_bounds(
            start_date.isoformat(), end_date.isoformat(), user_tz
        )

        food_logs_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", window_start)\
            .lt("logged_at", window_end)\
            .execute()

        # Aggregate food logs by day
        daily_calories = {}
        for log in food_logs_result.data or []:
            # Bucket by the user's LOCAL day — the raw UTC date rolls an
            # evening log onto the next day and splits one day's meals in two.
            local_day = utc_to_local_date(log["logged_at"], user_tz)
            if not local_day:
                continue
            log_date = date.fromisoformat(local_day)
            if log_date not in daily_calories:
                daily_calories[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0}
            daily_calories[log_date]["calories"] += log.get("total_calories", 0) or 0
            daily_calories[log_date]["protein"] += float(log.get("protein_g", 0) or 0)
            daily_calories[log_date]["carbs"] += float(log.get("carbs_g", 0) or 0)
            daily_calories[log_date]["fat"] += float(log.get("fat_g", 0) or 0)

        food_logs = [
            FoodLogSummary(
                date=d,
                total_calories=int(data["calories"]),
                protein_g=data["protein"],
                carbs_g=data["carbs"],
                fat_g=data["fat"],
            )
            for d, data in daily_calories.items()
        ]

        # Get weight logs — same local-day window as the food logs, so the
        # weight trend and the intake average cover the same span. The upper
        # bound is new: an unbounded `.gte` collected future-dated entries too.
        weight_logs_result = db.client.table("weight_logs")\
            .select("id, user_id, weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", window_start)\
            .lt("logged_at", window_end)\
            .order("logged_at")\
            .execute()

        weight_logs = [
            ServiceWeightLog(
                id=log["id"],
                user_id=log["user_id"],
                weight_kg=float(log["weight_kg"]),
                logged_at=datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")),
            )
            for log in weight_logs_result.data or []
        ]

        # Calculate TDEE with confidence intervals
        calculation = tdee_service.calculate_tdee_with_confidence(food_logs, weight_logs, days)

        if not calculation:
            return DetailedTDEEResponse(
                tdee=0,
                confidence_low=0,
                confidence_high=0,
                uncertainty_display="N/A",
                uncertainty_calories=0,
                data_quality_score=0.0,
                weight_change_kg=0.0,
                avg_daily_intake=0,
                start_weight_kg=0.0,
                end_weight_kg=0.0,
                days_analyzed=days,
                food_logs_count=len(food_logs),
                weight_logs_count=len(weight_logs),
                weight_trend={"status": "insufficient_data", "message": "Need at least 5 food logs and 2 weight entries"},
                metabolic_adaptation=None,
                confidence_level="insufficient_data",
            )

        # Get weight trend
        trend = tdee_service.get_weight_trend(weight_logs)

        # Check for metabolic adaptation
        # Get historical TDEE calculations
        history_result = db.client.table("adaptive_nutrition_calculations")\
            .select("id, user_id, calculated_at, calculated_tdee, weight_change_kg, avg_daily_intake, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(8)\
            .execute()

        tdee_history = [
            TDEEHistoryEntry(
                id=h["id"],
                user_id=h["user_id"],
                calculated_at=datetime.fromisoformat(str(h["calculated_at"]).replace("Z", "+00:00")),
                calculated_tdee=h.get("calculated_tdee") or 0,
                weight_change_kg=float(h.get("weight_change_kg") or 0),
                avg_daily_intake=h.get("avg_daily_intake") or 0,
                data_quality_score=float(h.get("data_quality_score") or 0),
            )
            for h in history_result.data or []
        ]

        # Get user's current goal
        prefs_result = db.client.table("nutrition_preferences")\
            .select("nutrition_goal, target_calories")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        current_goal = prefs_result.data.get("nutrition_goal", "maintain") if prefs_result and prefs_result.data else "maintain"
        current_deficit = 500  # Default deficit

        if prefs_result and prefs_result.data and prefs_result.data.get("target_calories"):
            current_deficit = calculation.tdee - prefs_result.data.get("target_calories", calculation.tdee)

        # Detect metabolic adaptation
        adaptation = adaptation_service.detect_metabolic_adaptation(
            tdee_history, current_goal, abs(current_deficit)
        )

        # Store this calculation in history
        try:
            db.client.table("tdee_calculation_history").insert({
                "user_id": user_id,
                "period_start": start_date.isoformat(),
                "period_end": end_date.isoformat(),
                "days_analyzed": calculation.days_analyzed,
                "food_logs_count": calculation.food_logs_count,
                "weight_logs_count": calculation.weight_logs_count,
                "start_weight_kg": calculation.start_weight_kg,
                "end_weight_kg": calculation.end_weight_kg,
                "weight_change_kg": calculation.weight_change_kg,
                "avg_daily_intake": calculation.avg_daily_intake,
                "calculated_tdee": calculation.tdee,
                "confidence_low": calculation.confidence_low,
                "confidence_high": calculation.confidence_high,
                "uncertainty_calories": calculation.uncertainty_calories,
                "data_quality_score": calculation.data_quality_score,
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to store TDEE history: {e}", exc_info=True)

        return DetailedTDEEResponse(
            tdee=calculation.tdee,
            confidence_low=calculation.confidence_low,
            confidence_high=calculation.confidence_high,
            uncertainty_display=f"±{calculation.uncertainty_calories}",
            uncertainty_calories=calculation.uncertainty_calories,
            data_quality_score=calculation.data_quality_score,
            weight_change_kg=calculation.weight_change_kg,
            avg_daily_intake=calculation.avg_daily_intake,
            start_weight_kg=calculation.start_weight_kg,
            end_weight_kg=calculation.end_weight_kg,
            days_analyzed=calculation.days_analyzed,
            food_logs_count=calculation.food_logs_count,
            weight_logs_count=calculation.weight_logs_count,
            weight_trend={
                "smoothed_weight_kg": trend.smoothed_weight if trend else None,
                "raw_weight_kg": trend.raw_weight if trend else None,
                "direction": trend.trend_direction if trend else "stable",
                "weekly_rate_kg": trend.weekly_rate_kg if trend else 0,
                "confidence": trend.confidence if trend else "low",
            },
            metabolic_adaptation=adaptation.to_dict() if adaptation else None,
            confidence_level="high" if calculation.data_quality_score >= 0.7 else "medium" if calculation.data_quality_score >= 0.4 else "low",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get detailed TDEE: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get(
    "/adherence/{user_id}/summary",
    response_model=Optional[AdherenceSummaryResponse],
    responses={
        200: {
            "description": (
                "Either an adherence summary, or a JSON `null` body meaning "
                "\"there is nothing to score\". `null` is returned when the user "
                "has no configured nutrition targets, or has targets but logged "
                "no food inside the requested window. Both are NORMAL states "
                "(fresh account / nutrition onboarding skipped / hasn't logged "
                "lately), NOT errors — the reason is in the "
                "`X-Nutrition-Adherence-Unavailable` header "
                "(`targets-not-configured` | `no-logs-in-window`). Errors are "
                "5xx, so `null` never means \"something broke\"."
            )
        }
    },
)
async def get_adherence_summary(request: Request, user_id: str, weeks: int = Query(default=4, ge=1, le=12), current_user: dict = Depends(get_current_user)):
    """
    Get adherence summary with sustainability score.

    Returns:
    - Weekly adherence breakdown
    - Overall sustainability rating (high/medium/low)
    - Recommendations based on adherence patterns

    Returns a **JSON `null` body (HTTP 200)** when there is nothing to score —
    either the user never configured nutrition targets, or they have targets but
    logged no food inside the requested window. The reason is in the
    `X-Nutrition-Adherence-Unavailable` header.

    The no-targets case used to be a 404 ("Nutrition preferences not found"),
    which fired on EVERY home render for any account that skipped nutrition
    onboarding — a permanent error in the logs and on the client for a state
    that is entirely normal. See `_adherence_unavailable` for why a JSON `null`
    at 200 and not a 204 (a 204 does NOT reach the client's null branch —
    Dio hands it the empty string).
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    logger.info(f"Getting adherence summary for user {user_id} over {weeks} weeks")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        adherence_service = get_adherence_tracking_service()

        # Get user's nutrition targets
        prefs_result = db.client.table("nutrition_preferences")\
            .select("target_calories, target_protein_g, target_carbs_g, target_fat_g, nutrition_goal")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        # `.maybe_single()` returns None (the response object itself) on 0 rows,
        # so the result object — not just `.data` — has to be guarded.
        prefs = (prefs_result.data if prefs_result else None) or None
        targets = _configured_targets(prefs)
        if targets is None:
            # No row at all, or a row whose target columns are still NULL.
            # Nothing to score — say so cleanly instead of 404-ing forever.
            logger.info(
                f"No configured nutrition targets for user {user_id} — "
                f"returning a null adherence body (row_present={prefs is not None})"
            )
            return _adherence_unavailable(_REASON_NO_TARGETS)

        # Get daily nutrition summaries for the period.
        # `timedelta(weeks=weeks * 7)` was a unit bug: for the default weeks=4
        # it looked back 28 WEEKS, pulled ~7x the food_logs needed on every
        # home render, and reported weeks_analyzed=29 for a 4-week request.
        end_date = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        start_date = end_date - timedelta(weeks=weeks)
        # The window is LOCAL calendar days but `logged_at` is a UTC
        # timestamptz. Filtering it with the bare date strings made
        # `.lte(end_date)` mean midnight UTC, so today's logs never reached the
        # numerator while the coverage denominator below still counted today —
        # every adherence percentage came out structurally low.
        window_start, window_end = local_range_bounds(
            start_date.isoformat(), end_date.isoformat(), user_tz
        )

        # Get food logs aggregated by day
        food_logs_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", window_start)\
            .lt("logged_at", window_end)\
            .execute()

        # Aggregate by day
        daily_totals = {}
        for log in food_logs_result.data or []:
            # Local day, not the UTC date — otherwise an evening meal scores
            # against tomorrow's targets.
            local_day = utc_to_local_date(log["logged_at"], user_tz)
            if not local_day:
                continue
            log_date = date.fromisoformat(local_day)
            if log_date not in daily_totals:
                daily_totals[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0, "meals": 0}
            daily_totals[log_date]["calories"] += log.get("total_calories", 0) or 0
            daily_totals[log_date]["protein"] += float(log.get("protein_g", 0) or 0)
            daily_totals[log_date]["carbs"] += float(log.get("carbs_g", 0) or 0)
            daily_totals[log_date]["fat"] += float(log.get("fat_g", 0) or 0)
            daily_totals[log_date]["meals"] += 1

        if not daily_totals:
            # Targets are set but the user logged NOTHING in the window. The
            # scoring path would emit average_adherence=0.0 / rating="low" —
            # a manufactured "you failed" score for someone who simply hasn't
            # started logging. Report "no data" the same way as "no targets".
            logger.info(
                f"No food logs in the last {weeks} week(s) for user {user_id} — "
                "returning a null adherence body rather than a 0% score"
            )
            return _adherence_unavailable(_REASON_NO_LOGS)

        # Calculate daily adherence
        daily_adherences = []
        for log_date, totals in daily_totals.items():
            actuals = NutritionActuals(
                date=log_date,
                calories=int(totals["calories"]),
                protein_g=totals["protein"],
                carbs_g=totals["carbs"],
                fat_g=totals["fat"],
                meals_logged=totals["meals"],
            )
            adherence = adherence_service.calculate_daily_adherence(targets, actuals)
            daily_adherences.append(adherence)

        # Group by week and calculate summaries.
        #
        # Two rules here, both of which the pre-fix loop broke:
        #  1. A calendar week with NO logged days is *unknown*, not 0%. The
        #     service now leaves its averages null and excludes it from the
        #     adherence/consistency means (it still counts toward logging
        #     coverage, which is a real observation).
        #  2. The first and last buckets are usually PARTIAL — the window starts
        #     mid-week and ends today — so their coverage denominator is the
        #     number of in-window days, not a flat 7. Charging a user for the
        #     rest of this week (days that haven't happened) is fabrication too.
        weekly_summaries = []
        current_week_start = start_date - timedelta(days=start_date.weekday())  # Monday

        while current_week_start <= end_date:
            week_end = current_week_start + timedelta(days=6)
            week_adherences = [
                a for a in daily_adherences
                if current_week_start <= a.date <= week_end
            ]
            in_window_start = max(current_week_start, start_date)
            in_window_end = min(week_end, end_date)
            days_in_window = (in_window_end - in_window_start).days + 1
            summary = adherence_service.calculate_weekly_summary(
                week_adherences,
                current_week_start,
                days_in_week=max(days_in_window, 0),
            )
            weekly_summaries.append(summary)
            current_week_start += timedelta(days=7)

        # Calculate sustainability score. None = no week in the window had a
        # logged day, so there is nothing to grade.
        sustainability = adherence_service.calculate_sustainability_score(weekly_summaries)
        if sustainability is None:
            # Defensive: `daily_totals` was non-empty, so at least one week
            # should have data. If bucketing ever drops them all (timezone
            # skew putting a log outside every bucket), report unknown rather
            # than crash or invent a score.
            logger.warning(
                f"Adherence bucketing produced no scored week for user {user_id} "
                f"despite {len(daily_totals)} logged day(s) in the window "
                f"[{start_date} .. {end_date}] — returning a null adherence body"
            )
            return _adherence_unavailable(_REASON_NO_LOGS)

        # Only weeks that actually contain logged days are returned. An empty
        # week has null averages, and the shipped client coerces nulls to 0.0 —
        # which would draw a "0% adherence" bar in the weekly mini-chart for a
        # week the user simply didn't log. Omitting it shows fewer bars, but
        # every bar shown is a real measurement.
        #
        # NOT truncated with `[-weeks:]`: the window already bounds this to the
        # requested span, and slicing it would report `weeks_analyzed` /
        # chart bars over a different set of weeks than `average_adherence` was
        # computed from. Chart bars == weeks analyzed == weeks that fed the
        # average, exactly.
        returned_weeks = [s for s in weekly_summaries if s.has_data]
        return AdherenceSummaryResponse(
            weekly_adherence=[s.to_dict() for s in returned_weeks],
            average_adherence=sustainability.avg_adherence,
            sustainability_score=sustainability.score,
            sustainability_rating=sustainability.rating.value,
            recommendation=sustainability.recommendation,
            # Weeks that actually contributed a measurement — NOT every calendar
            # week the window touched. The client renders this as "weeks
            # analyzed" next to a chart of exactly `returned_weeks`.
            weeks_analyzed=len(returned_weeks),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get adherence summary: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/recommendations/{user_id}/options", response_model=RecommendationOptionsResponse)
async def get_recommendation_options(request: Request, user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get multiple recommendation options for user to choose from.

    MacroFactor-style multi-option recommendations:
    - Aggressive (if adherence >80% and no adaptation)
    - Moderate (always shown, recommended)
    - Conservative (if adherence <70% or adaptation detected)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    logger.info(f"Getting recommendation options for user {user_id}")

    try:
        db = get_supabase_db()
        adherence_service = get_adherence_tracking_service()
        adaptation_service = get_metabolic_adaptation_service()

        # Get latest adaptive TDEE
        tdee_result = db.client.table("adaptive_nutrition_calculations")\
            .select("calculated_tdee, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .execute()

        tdee_rows = tdee_result.data or []
        tdee_data = tdee_rows[0] if tdee_rows else None
        if not tdee_data or not tdee_data.get("calculated_tdee"):
            # Fall back to nutrition preferences TDEE
            prefs = db.client.table("nutrition_preferences")\
                .select("calculated_tdee, nutrition_goal")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()

            prefs_data = getattr(prefs, 'data', None)
            if not prefs_data or not prefs_data.get("calculated_tdee"):
                raise HTTPException(
                    status_code=400,
                    detail="No TDEE available. Please log food and weight data first."
                )

            # No `or 2000` fallback: the guard above already proved
            # calculated_tdee is present and truthy, and inventing a TDEE would
            # silently set a real person's calorie target off a made-up number.
            current_tdee = int(prefs_data["calculated_tdee"])
            current_goal = prefs_data.get("nutrition_goal") or "maintain"
        else:
            current_tdee = int(tdee_data["calculated_tdee"])
            # Get goal from preferences
            prefs = db.client.table("nutrition_preferences")\
                .select("nutrition_goal")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()
            prefs_data = getattr(prefs, 'data', None)
            current_goal = (prefs_data.get("nutrition_goal") or "maintain") if prefs_data else "maintain"

        # Get adherence score via service (avoid calling route handler directly).
        # adherence_score stays None when it cannot be honestly computed — an
        # unknown adherence is NOT 50% adherence.
        adherence_score: Optional[float] = None
        try:
            prefs_for_adh = db.client.table("nutrition_preferences")\
                .select("target_calories, target_protein_g, target_carbs_g, target_fat_g")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()
            adh_prefs = getattr(prefs_for_adh, 'data', None) or {}
            adh_targets = _configured_targets(adh_prefs)
            if adh_targets is None:
                # Same rule as /adherence/summary: no configured targets means
                # there is nothing to be adherent TO. Scoring them against an
                # invented 2000/150/200/65 plan used to decide which deficit we
                # recommended to them.
                raise _NoConfiguredTargets()
            # Resolve the tz once and use it for BOTH the local end date and the
            # UTC window below — same-day agreement between the logs that feed
            # the numerator and the coverage denominator further down. Filtering
            # the timestamptz `logged_at` with bare local date strings made
            # `.lte(end_date)` mean midnight UTC and silently dropped today.
            user_tz = resolve_timezone(request, db, user_id)
            end_date = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
            start_date = end_date - timedelta(weeks=4)
            window_start, window_end = local_range_bounds(
                start_date.isoformat(), end_date.isoformat(), user_tz
            )
            food_logs_result = db.client.table("food_logs")\
                .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
                .eq("user_id", user_id)\
                .is_("deleted_at", "null")\
                .gte("logged_at", window_start)\
                .lt("logged_at", window_end)\
                .execute()
            daily_totals: dict = {}
            for log in food_logs_result.data or []:
                local_day = utc_to_local_date(log["logged_at"], user_tz)
                if not local_day:
                    continue
                log_date = date.fromisoformat(local_day)
                if log_date not in daily_totals:
                    daily_totals[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0, "meals": 0}
                daily_totals[log_date]["calories"] += log.get("total_calories", 0) or 0
                daily_totals[log_date]["protein"] += float(log.get("protein_g", 0) or 0)
                daily_totals[log_date]["carbs"] += float(log.get("carbs_g", 0) or 0)
                daily_totals[log_date]["fat"] += float(log.get("fat_g", 0) or 0)
                daily_totals[log_date]["meals"] += 1
            daily_adherences = []
            for log_date, totals in daily_totals.items():
                actuals = NutritionActuals(
                    date=log_date,
                    calories=int(totals["calories"]),
                    protein_g=totals["protein"],
                    carbs_g=totals["carbs"],
                    fat_g=totals["fat"],
                    meals_logged=totals["meals"],
                )
                daily_adherences.append(adherence_service.calculate_daily_adherence(adh_targets, actuals))
            weekly_summaries = []
            week_start = start_date - timedelta(days=start_date.weekday())
            while week_start <= end_date:
                week_end = week_start + timedelta(days=6)
                week_adh = [a for a in daily_adherences if week_start <= a.date <= week_end]
                # Same partial-week coverage denominator as /adherence/summary.
                in_window_days = (
                    min(week_end, end_date) - max(week_start, start_date)
                ).days + 1
                weekly_summaries.append(
                    adherence_service.calculate_weekly_summary(
                        week_adh, week_start, days_in_week=max(in_window_days, 0)
                    )
                )
                week_start += timedelta(days=7)
            sustainability = adherence_service.calculate_sustainability_score(weekly_summaries)
            # None = not a single logged day in the last 4 weeks. That is an
            # UNKNOWN adherence, not a zero and not a 0.5 — leave it null so
            # `_generate_recommendation_options` falls back to the moderate
            # default instead of unlocking or forcing an option.
            adherence_score = sustainability.score if sustainability else None
            if sustainability is None:
                logger.info(
                    f"No logged days in the last 4 weeks for user {user_id} — "
                    "adherence_score left unknown (null) for recommendation options"
                )
        except _NoConfiguredTargets:
            logger.info(
                f"No configured nutrition targets for user {user_id} — "
                "adherence_score left unknown (null) for recommendation options"
            )
        except Exception as adh_err:
            # Was `adherence_score = 0.5` — a silent fabrication that read as
            # "50% adherent" downstream and steered which deficit we
            # recommended. Unknown must stay unknown.
            logger.warning(f"Failed to compute adherence score, leaving it unknown: {adh_err}", exc_info=True)
            adherence_score = None

        # Get TDEE history for adaptation detection
        history_result = db.client.table("adaptive_nutrition_calculations")\
            .select("id, user_id, calculated_at, calculated_tdee, weight_change_kg, avg_daily_intake, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(8)\
            .execute()

        tdee_history = [
            TDEEHistoryEntry(
                id=h["id"],
                user_id=h["user_id"],
                calculated_at=datetime.fromisoformat(str(h["calculated_at"]).replace("Z", "+00:00")),
                calculated_tdee=h.get("calculated_tdee") or 0,
                weight_change_kg=float(h.get("weight_change_kg") or 0),
                avg_daily_intake=h.get("avg_daily_intake") or 0,
                data_quality_score=float(h.get("data_quality_score") or 0),
            )
            for h in history_result.data or []
        ]

        # Detect metabolic adaptation
        adaptation = adaptation_service.detect_metabolic_adaptation(tdee_history, current_goal, 500)

        # Generate recommendation options
        options = _generate_recommendation_options(
            current_tdee=current_tdee,
            goal=current_goal,
            adherence_score=adherence_score,
            has_adaptation=adaptation is not None,
        )

        return RecommendationOptionsResponse(
            current_tdee=current_tdee,
            current_goal=current_goal,
            adherence_score=adherence_score,
            has_adaptation=adaptation is not None,
            adaptation_details=adaptation.to_dict() if adaptation else None,
            options=options,
            recommended_option=next((o.option_type for o in options if o.is_recommended), "moderate"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get recommendation options: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


def _generate_recommendation_options(
    current_tdee: int,
    goal: str,
    adherence_score: Optional[float],
    has_adaptation: bool,
) -> List[RecommendationOption]:
    """Generate 2-3 recommendation options based on user context.

    ``adherence_score`` is Optional: ``None`` means "we genuinely do not know
    how adherent this user is" (no configured targets, or the computation
    failed). Unknown is treated conservatively — never as a high score that
    would unlock the aggressive deficit, and never as a low score that would
    push them to the conservative one. They simply get the moderate default.
    """
    options = []
    known_adherence = adherence_score is not None

    if goal in ["lose_fat", "lose_weight"]:
        # Aggressive option (only if PROVEN high adherence and no adaptation).
        # Unknown adherence must not unlock a 750 kcal deficit.
        if known_adherence and adherence_score >= 0.8 and not has_adaptation:
            aggressive_cals = current_tdee - 750
            options.append(RecommendationOption(
                option_type="aggressive",
                calories=aggressive_cals,
                protein_g=int((aggressive_cals * 0.35) / 4),
                carbs_g=int((aggressive_cals * 0.35) / 4),
                fat_g=int((aggressive_cals * 0.30) / 9),
                expected_weekly_change_kg=-0.68,
                sustainability_rating="low",
                description="Faster results, requires strict adherence. Best for short-term pushes.",
                is_recommended=False,
            ))

        # Moderate option (always shown, usually recommended)
        moderate_cals = current_tdee - 500
        options.append(RecommendationOption(
            option_type="moderate",
            calories=moderate_cals,
            protein_g=int((moderate_cals * 0.30) / 4),
            carbs_g=int((moderate_cals * 0.40) / 4),
            fat_g=int((moderate_cals * 0.30) / 9),
            expected_weekly_change_kg=-0.45,
            sustainability_rating="medium",
            description="Balanced approach. Steady progress without extreme restriction.",
            # Unknown adherence still lands here — moderate is the safe default.
            is_recommended=not has_adaptation and (not known_adherence or adherence_score >= 0.6),
        ))

        # Conservative option (for PROVEN low adherence, or adaptation)
        if has_adaptation or (known_adherence and adherence_score < 0.7):
            conservative_cals = current_tdee - 250
            options.append(RecommendationOption(
                option_type="conservative",
                calories=conservative_cals,
                protein_g=int((conservative_cals * 0.30) / 4),
                carbs_g=int((conservative_cals * 0.40) / 4),
                fat_g=int((conservative_cals * 0.30) / 9),
                expected_weekly_change_kg=-0.23,
                sustainability_rating="high",
                description="Slower but more sustainable. Better for long-term success.",
                is_recommended=has_adaptation or (known_adherence and adherence_score < 0.6),
            ))

    elif goal == "build_muscle":
        # Lean bulk
        lean_cals = current_tdee + 250
        options.append(RecommendationOption(
            option_type="lean_bulk",
            calories=lean_cals,
            protein_g=int((lean_cals * 0.30) / 4),
            carbs_g=int((lean_cals * 0.45) / 4),
            fat_g=int((lean_cals * 0.25) / 9),
            expected_weekly_change_kg=0.20,
            sustainability_rating="high",
            description="Minimize fat gain while building muscle. Slow and steady.",
            is_recommended=True,
        ))

        # Standard bulk
        standard_cals = current_tdee + 400
        options.append(RecommendationOption(
            option_type="standard_bulk",
            calories=standard_cals,
            protein_g=int((standard_cals * 0.28) / 4),
            carbs_g=int((standard_cals * 0.47) / 4),
            fat_g=int((standard_cals * 0.25) / 9),
            expected_weekly_change_kg=0.35,
            sustainability_rating="medium",
            description="Faster muscle gain, some fat gain expected.",
            is_recommended=False,
        ))

    else:  # maintain
        options.append(RecommendationOption(
            option_type="maintenance",
            calories=current_tdee,
            protein_g=int((current_tdee * 0.25) / 4),
            carbs_g=int((current_tdee * 0.45) / 4),
            fat_g=int((current_tdee * 0.30) / 9),
            expected_weekly_change_kg=0.0,
            sustainability_rating="high",
            description="Maintain current weight and body composition.",
            is_recommended=True,
        ))

    # Ensure at least one option is recommended
    if not any(o.is_recommended for o in options) and options:
        options[0].is_recommended = True

    return options


@router.post("/recommendations/{user_id}/select")
async def select_recommendation(user_id: str, request: SelectRecommendationRequest, http_request: Request, current_user: dict = Depends(get_current_user)):
    """
    User selects a recommendation option to apply.

    This updates the user's nutrition targets to match the selected option.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    logger.info(f"User {user_id} selecting recommendation: {request.option_type}")

    try:
        # Get available options
        options_response = await get_recommendation_options(http_request, user_id, current_user=current_user)

        # Find selected option
        selected = None
        for opt in options_response.options:
            if opt.option_type == request.option_type:
                selected = opt
                break

        if not selected:
            raise HTTPException(
                status_code=404,
                detail=f"Option '{request.option_type}' not found. Available options: {[o.option_type for o in options_response.options]}"
            )

        db = get_supabase_db()

        # Update user's nutrition targets.
        # PostgREST happily reports success for an UPDATE that matched ZERO
        # rows, so a user with no nutrition_preferences row used to get
        # {"success": true} back while nothing was written. Check the returned
        # representation and tell them the truth instead.
        update_result = db.client.table("nutrition_preferences")\
            .update({
                "target_calories": selected.calories,
                "target_protein_g": selected.protein_g,
                "target_carbs_g": selected.carbs_g,
                "target_fat_g": selected.fat_g,
                "last_recalculated_at": datetime.utcnow().isoformat(),
            })\
            .eq("user_id", user_id)\
            .execute()

        if not getattr(update_result, "data", None):
            logger.warning(
                f"select_recommendation matched 0 nutrition_preferences rows for user {user_id}"
            )
            raise HTTPException(
                status_code=409,
                detail=(
                    "Nutrition preferences have not been set up for this account yet. "
                    "Complete nutrition setup before applying a recommendation."
                ),
            )

        # Log the decision for analytics
        await log_user_activity(
            user_id=user_id,
            action="recommendation_selected",
            endpoint="/api/v1/nutrition/recommendations/select",
            message=f"Selected {request.option_type} plan: {selected.calories} cal",
            metadata={
                "option_type": request.option_type,
                "calories": selected.calories,
                "protein_g": selected.protein_g,
                "carbs_g": selected.carbs_g,
                "fat_g": selected.fat_g,
                "expected_weekly_change_kg": selected.expected_weekly_change_kg,
            },
            status_code=200
        )

        return {
            "success": True,
            "message": f"Applied {request.option_type} plan",
            "applied": {
                "option_type": selected.option_type,
                "calories": selected.calories,
                "protein_g": selected.protein_g,
                "carbs_g": selected.carbs_g,
                "fat_g": selected.fat_g,
                "description": selected.description,
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to select recommendation: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

