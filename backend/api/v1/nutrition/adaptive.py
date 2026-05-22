"""Adaptive TDEE calculation endpoints."""
from core.db import get_supabase_db
from datetime import datetime, date, timedelta
from typing import Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from api.v1.nutrition.models import AdaptiveCalculationResponse

router = APIRouter()
logger = get_logger(__name__)

# Hold the calorie target steady from 7 days before the predicted period
# through the end of the period — the pre-period / period week (Phase G, 1.3).
_PERIOD_HOLD_LEAD_DAYS = 7


def _cycle_target_hold_note(db, user_id: str, today_str: str) -> Optional[str]:
    """Return a recommendation note when the calorie target should be HELD
    steady because the user is in their pre-period / period week.

    Returns None — i.e. no hold, normal adaptive behaviour — for any user
    without menstrual tracking enabled, without a usable cycle prediction,
    or whose "today" falls outside the hold window. This keeps the whole
    cycle-aware path a strict no-op for non-tracking users.

    The note is surfaced on `AdaptiveCalculationResponse.recommendation` so
    whatever turns the adaptive TDEE into a recommended calorie target sees
    the hold signal (machine-readable prefix `CYCLE_HOLD:`).
    """
    # Gate on menstrual tracking — defensive: the table/column may be absent.
    try:
        profile_res = (
            db.client.table("hormonal_profiles")
            .select("menstrual_tracking_enabled")
            .eq("user_id", user_id)
            .execute()
        )
    except Exception as profile_err:  # noqa: BLE001
        logger.warning(f"hormonal_profiles lookup failed (cycle hold off): {profile_err}")
        return None
    if not profile_res.data or not profile_res.data[0].get("menstrual_tracking_enabled"):
        return None

    try:
        today = datetime.strptime(today_str, "%Y-%m-%d").date()
    except ValueError:
        return None

    # Run the single prediction path used everywhere else in the feature.
    try:
        from services.cycle.cycle_predictor import predict_for_user

        prediction = predict_for_user(db.client, user_id, today)
    except Exception as pred_err:  # noqa: BLE001
        logger.warning(f"Cycle prediction failed (cycle hold off): {pred_err}")
        return None

    if not prediction or not prediction.get("predictions_available"):
        return None

    next_period = prediction.get("next_period_date")
    if isinstance(next_period, str):
        try:
            next_period = date.fromisoformat(next_period)
        except ValueError:
            next_period = None
    if not isinstance(next_period, date):
        return None

    window_start = next_period - timedelta(days=_PERIOD_HOLD_LEAD_DAYS)
    avg_period = prediction.get("stats", {}).get("avg_period_length") or 5
    window_end = next_period + timedelta(days=int(round(avg_period)) - 1)

    if window_start <= today <= window_end:
        return (
            "CYCLE_HOLD: Calorie target held steady through the pre-period and "
            "period week. Luteal water retention can read as fat gain, so no "
            "calorie cut is applied until the period ends."
        )
    return None


@router.get("/adaptive/{user_id}", response_model=Optional[AdaptiveCalculationResponse])
async def get_adaptive_calculation(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the latest adaptive TDEE calculation for a user.
    """
    logger.info(f"Getting adaptive calculation for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("adaptive_nutrition_calculations")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        if not result.data:
            return None

        data = result.data
        return AdaptiveCalculationResponse(
            id=data["id"],
            user_id=data["user_id"],
            calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
            period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
            period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
            avg_daily_intake=data.get("avg_daily_intake", 0),
            start_trend_weight_kg=float(data["start_trend_weight_kg"]) if data.get("start_trend_weight_kg") else None,
            end_trend_weight_kg=float(data["end_trend_weight_kg"]) if data.get("end_trend_weight_kg") else None,
            calculated_tdee=data.get("calculated_tdee", 0),
            data_quality_score=float(data.get("data_quality_score", 0)),
            confidence_level=data.get("confidence_level", "low"),
            days_logged=data.get("days_logged", 0),
            weight_entries=data.get("weight_entries", 0),
        )

    except Exception as e:
        logger.error(f"Failed to get adaptive calculation: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/adaptive/{user_id}/calculate", response_model=AdaptiveCalculationResponse)
async def calculate_adaptive_tdee(
    request: Request,
    user_id: str,
    days: int = Query(14, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate adaptive TDEE based on food intake and weight changes.

    Formula: TDEE = Calories In - (Weight Change * 7700 kcal/kg)

    Requires at least 6 days of food logs and 2 weight entries.
    """
    logger.info(f"Calculating adaptive TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        to_date_str = get_user_today(user_tz)
        from_date_obj = datetime.strptime(to_date_str, "%Y-%m-%d") - timedelta(days=days)
        from_date_str = from_date_obj.strftime("%Y-%m-%d")

        # Get food logs for the period
        food_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .execute()

        food_logs = food_result.data or []

        # Get weight logs for the period
        weight_result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .order("logged_at", desc=False)\
            .execute()

        weight_logs = weight_result.data or []

        # Check minimum data requirements
        days_logged = len(set(
            datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            for log in food_logs
        ))
        weight_entries = len(weight_logs)

        if days_logged < 6 or weight_entries < 2:
            # Not enough data, return placeholder calculation
            quality_score = min(days_logged / 6, weight_entries / 2) * 0.5

            calc_data = {
                "user_id": user_id,
                "calculated_at": datetime.utcnow().isoformat(),
                "period_start": from_date_str,
                "period_end": to_date_str,
                "avg_daily_intake": 0,
                "calculated_tdee": 0,
                "data_quality_score": quality_score,
                "confidence_level": "low",
                "days_logged": days_logged,
                "weight_entries": weight_entries,
            }

            try:
                result = db.client.table("adaptive_nutrition_calculations")\
                    .insert(calc_data)\
                    .execute()
                if result.data:
                    data = result.data[0]
                    return AdaptiveCalculationResponse(
                        id=data["id"],
                        user_id=data["user_id"],
                        calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
                        period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
                        period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
                        avg_daily_intake=0,
                        calculated_tdee=0,
                        data_quality_score=quality_score,
                        confidence_level="low",
                        days_logged=days_logged,
                        weight_entries=weight_entries,
                    )
            except Exception as insert_err:
                logger.warning(f"Failed to persist adaptive calculation (non-critical): {insert_err}", exc_info=True)

            # Return response without persisted ID if insert failed
            return AdaptiveCalculationResponse(
                id=str(uuid.uuid4()),
                user_id=user_id,
                calculated_at=datetime.utcnow(),
                period_start=datetime.fromisoformat(from_date_str),
                period_end=datetime.fromisoformat(to_date_str),
                avg_daily_intake=0,
                calculated_tdee=0,
                data_quality_score=quality_score,
                confidence_level="low",
                days_logged=days_logged,
                weight_entries=weight_entries,
            )

        # Calculate average daily calorie intake
        total_calories = 0
        for log in food_logs:
            total_calories += log.get("total_calories", 0) or 0

        avg_daily_intake = int(total_calories / days_logged) if days_logged > 0 else 0

        # Calculate weight trend
        start_weights = [float(log["weight_kg"]) for log in weight_logs[:min(3, len(weight_logs))]]
        end_weights = [float(log["weight_kg"]) for log in weight_logs[-min(3, len(weight_logs)):]]

        start_trend = sum(start_weights) / len(start_weights) if start_weights else None
        end_trend = sum(end_weights) / len(end_weights) if end_weights else None

        if start_trend and end_trend:
            weight_change = end_trend - start_trend
            # 7700 kcal = 1 kg of body weight
            caloric_difference = int(weight_change * 7700 / days)
            calculated_tdee = avg_daily_intake - caloric_difference
        else:
            calculated_tdee = avg_daily_intake

        # Calculate quality score (0-1)
        quality_score = min(1.0, (
            (min(days_logged, 14) / 14) * 0.5 +
            (min(weight_entries, 7) / 7) * 0.5
        ))

        confidence = "low" if quality_score < 0.4 else "medium" if quality_score < 0.7 else "high"

        # --- Cycle-aware target hold (Phase G, MacroFactor request 1.3) -----
        # If menstrual tracking is on and "today" sits in the pre-period /
        # period week [predicted period - 7d .. period end], any adaptive
        # adjustment that would MOVE the recommended calorie target is held:
        # luteal water weight can read as fat gain and trigger a wrong cut.
        # The hold is surfaced on the `recommendation` field so the consumer
        # that turns this TDEE into a target knows not to apply a cut.
        # No-op for users without menstrual tracking.
        cycle_hold_recommendation: Optional[str] = None
        try:
            cycle_hold_recommendation = _cycle_target_hold_note(db, user_id, to_date_str)
        except Exception as hold_err:  # noqa: BLE001
            logger.warning(f"Cycle target-hold check failed (non-critical): {hold_err}")

        # Save calculation
        calc_data = {
            "user_id": user_id,
            "calculated_at": datetime.utcnow().isoformat(),
            "period_start": from_date_str,
            "period_end": to_date_str,
            "avg_daily_intake": avg_daily_intake,
            "start_trend_weight_kg": start_trend,
            "end_trend_weight_kg": end_trend,
            "calculated_tdee": max(1000, calculated_tdee),  # Minimum TDEE
            "data_quality_score": quality_score,
            "confidence_level": confidence,
            "days_logged": days_logged,
            "weight_entries": weight_entries,
        }

        try:
            result = db.client.table("adaptive_nutrition_calculations")\
                .insert(calc_data)\
                .execute()
            if result.data:
                data = result.data[0]
                return AdaptiveCalculationResponse(
                    id=data["id"],
                    user_id=data["user_id"],
                    calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
                    period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
                    period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
                    avg_daily_intake=avg_daily_intake,
                    start_trend_weight_kg=start_trend,
                    end_trend_weight_kg=end_trend,
                    calculated_tdee=max(1000, calculated_tdee),
                    data_quality_score=quality_score,
                    confidence_level=confidence,
                    days_logged=days_logged,
                    weight_entries=weight_entries,
                    recommendation=cycle_hold_recommendation,
                )
        except Exception as insert_err:
            logger.warning(f"Failed to persist adaptive calculation (non-critical): {insert_err}", exc_info=True)

        # Return response without persisted ID if insert failed
        return AdaptiveCalculationResponse(
            id=str(uuid.uuid4()),
            user_id=user_id,
            calculated_at=datetime.utcnow(),
            period_start=datetime.fromisoformat(from_date_str),
            period_end=datetime.fromisoformat(to_date_str),
            avg_daily_intake=avg_daily_intake,
            start_trend_weight_kg=start_trend,
            end_trend_weight_kg=end_trend,
            calculated_tdee=max(1000, calculated_tdee),
            data_quality_score=quality_score,
            confidence_level=confidence,
            days_logged=days_logged,
            weight_entries=weight_entries,
            recommendation=cycle_hold_recommendation,
        )

    except Exception as e:
        logger.error(f"Failed to calculate adaptive TDEE: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ─────────────────────────────────────────────────────────────────────
# Cycle-aware adaptive TDEE — Phase G
#
# Luteal-phase water retention spikes body weight ~1-2 kg without any change
# in fat mass. A naive adaptive-TDEE read of that water either cuts the
# calorie target or shows a discouraging weight trend. This endpoint layers
# the cycle-tracking prediction over the existing adaptive calculation:
#
#   * every weigh-in is tagged with the cycle phase on its logged date
#     (so the frontend can overlay phase bands on the weight chart)        (1.1/1.8/1.18)
#   * the EMA + energy-balance TDEE uses the cycle-aware service, which
#     down-weights luteal/menstrual weigh-ins and widens the confidence
#     interval on a cycle-contaminated window                              (1.2/1.4)
#   * when an adaptive adjustment would MOVE the recommended calorie target
#     and "today" sits inside [predicted period - 7 days .. period end],
#     the target is HELD steady — no calorie cut during the period week    (1.3)
#   * a "same point last cycle" comparison aligns the latest weigh-in with
#     the cycle-day-matched weigh-in from the previous cycle                (1.11)
#
# Every cycle-aware behaviour here is a strict no-op for users without
# menstrual tracking enabled — they get the plain adaptive numbers.
# (The hold window is `_PERIOD_HOLD_LEAD_DAYS`, defined near the top.)
# ─────────────────────────────────────────────────────────────────────


@router.get("/adaptive/{user_id}/cycle-aware")
async def get_cycle_aware_adaptive(
    request: Request,
    user_id: str,
    days: int = Query(28, description="Number of days of weigh-ins to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """Cycle-aware adaptive TDEE + weight trend.

    Returns the standard adaptive TDEE numbers plus, for menstrual-tracking
    users, a cycle-phase-tagged weight series, a "hold the calorie target"
    flag for the period week, and a same-point-last-cycle weight comparison.

    For users without cycle tracking the cycle blocks come back null/false
    and the numbers are identical to the plain adaptive calculation.
    """
    logger.info(f"Cycle-aware adaptive TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)
        today = datetime.strptime(today_str, "%Y-%m-%d").date()
        from_date_str = (today - timedelta(days=days)).strftime("%Y-%m-%d")

        # --- Weigh-ins over the window --------------------------------------
        weight_result = (
            db.client.table("weight_logs")
            .select("id, weight_kg, logged_at, source")
            .eq("user_id", user_id)
            .gte("logged_at", f"{from_date_str}T00:00:00")
            .order("logged_at", desc=False)
            .execute()
        )
        weight_rows = weight_result.data or []

        # --- Is menstrual tracking enabled? ---------------------------------
        # The single gate for every cycle-aware behaviour. Read defensively —
        # the hormonal_profiles table / columns may not exist for this user.
        tracking_enabled = False
        profile: dict = {}
        try:
            profile_res = (
                db.client.table("hormonal_profiles")
                .select("*")
                .eq("user_id", user_id)
                .execute()
            )
            if profile_res.data:
                profile = profile_res.data[0]
                tracking_enabled = bool(profile.get("menstrual_tracking_enabled"))
        except Exception as profile_err:  # noqa: BLE001
            logger.warning(
                f"hormonal_profiles lookup failed (cycle features off): {profile_err}"
            )
            tracking_enabled = False

        # --- Build the cycle-aware service inputs ---------------------------
        from services.adaptive_tdee_service import (
            WeightLog,
            get_adaptive_tdee_service,
            tag_weight_logs_with_cycle_phase,
        )

        weight_logs = []
        for row in weight_rows:
            try:
                logged_at = datetime.fromisoformat(
                    str(row["logged_at"]).replace("Z", "+00:00")
                )
            except (ValueError, KeyError):
                continue
            weight_logs.append(
                WeightLog(
                    id=str(row.get("id", "")),
                    user_id=user_id,
                    weight_kg=float(row["weight_kg"]),
                    logged_at=logged_at,
                    source=row.get("source", "manual"),
                )
            )

        prediction: Optional[dict] = None
        period_starts: list = []
        if tracking_enabled:
            # Load the prediction once — used both for tagging and the
            # period-hold window. predict_for_user reads cycle_periods.
            try:
                from services.cycle.cycle_predictor import predict_for_user

                prediction = predict_for_user(db.client, user_id, today)
            except Exception as pred_err:  # noqa: BLE001
                logger.warning(f"Cycle prediction failed (cycle overlay off): {pred_err}")
                prediction = None

            # Tag every weigh-in with its cycle phase for the chart overlay.
            try:
                periods_res = (
                    db.client.table("cycle_periods")
                    .select("start_date, end_date")
                    .eq("user_id", user_id)
                    .order("start_date")
                    .execute()
                )
                period_rows = periods_res.data or []
                period_starts = [
                    date.fromisoformat(r["start_date"])
                    for r in period_rows
                    if r.get("start_date")
                ]
                period_ends = {
                    date.fromisoformat(r["start_date"]): date.fromisoformat(r["end_date"])
                    for r in period_rows
                    if r.get("start_date") and r.get("end_date")
                }
                if period_starts:
                    tag_weight_logs_with_cycle_phase(
                        weight_logs,
                        period_starts,
                        period_ends=period_ends,
                        cycle_length_default=profile.get("cycle_length_days") or 28,
                        period_length_default=profile.get("typical_period_duration_days") or 5,
                        luteal_length_override=profile.get("luteal_length_days"),
                    )
            except Exception as tag_err:  # noqa: BLE001
                logger.warning(f"Cycle phase tagging failed (overlay off): {tag_err}")

        # --- Cycle-aware weight trend ---------------------------------------
        svc = get_adaptive_tdee_service()
        trend = svc.get_weight_trend(weight_logs) if len(weight_logs) >= 2 else None

        # Phase-tagged series the frontend overlays onto the weight chart.
        weight_series = [
            {
                "id": log.id,
                "weight_kg": round(log.weight_kg, 2),
                "logged_at": log.logged_at.isoformat(),
                "logged_date": log.logged_at.date().isoformat(),
                "source": log.source,
                "cycle_phase": log.cycle_phase,  # None when tracking off
            }
            for log in weight_logs
        ]

        # --- Hold the calorie target during the period week (1.3) -----------
        # When an adaptive adjustment would move the target, the frontend
        # checks `hold_calorie_target`: if true, it must NOT apply the cut.
        hold_calorie_target = False
        hold_window_start: Optional[str] = None
        hold_window_end: Optional[str] = None
        hold_reason: Optional[str] = None
        if tracking_enabled and prediction and prediction.get("predictions_available"):
            next_period = prediction.get("next_period_date")
            # predict() returns date objects; predict_for_user keeps them.
            if isinstance(next_period, str):
                try:
                    next_period = date.fromisoformat(next_period)
                except ValueError:
                    next_period = None
            if isinstance(next_period, date):
                window_start = next_period - timedelta(days=_PERIOD_HOLD_LEAD_DAYS)
                # Period end: stay held until bleeding finishes. Use the
                # current in-period end if we're already bleeding, else the
                # predicted period start + average period length.
                avg_period = prediction.get("stats", {}).get("avg_period_length") or 5
                window_end = next_period + timedelta(days=int(round(avg_period)) - 1)
                hold_window_start = window_start.isoformat()
                hold_window_end = window_end.isoformat()
                if window_start <= today <= window_end:
                    hold_calorie_target = True
                    hold_reason = (
                        "Calorie target held steady through the pre-period and "
                        "period week — luteal water weight can read as fat gain, "
                        "so no calorie cut is applied right now."
                    )

        # --- Same point last cycle comparison (1.11) ------------------------
        same_point_last_cycle: Optional[dict] = None
        if tracking_enabled and weight_logs and len(period_starts) >= 2:
            latest = weight_logs[-1]
            latest_date = latest.logged_at.date()
            # Anchor cycle = latest period start on/before the latest weigh-in.
            sorted_starts = sorted(period_starts)
            anchor = None
            anchor_idx = None
            for i, s in enumerate(sorted_starts):
                if s <= latest_date:
                    anchor, anchor_idx = s, i
            if anchor is not None and anchor_idx is not None and anchor_idx >= 1:
                cycle_day = (latest_date - anchor).days  # 0-based offset
                prev_start = sorted_starts[anchor_idx - 1]
                target_date = prev_start + timedelta(days=cycle_day)
                # Find the weigh-in nearest target_date (within ±3 days) in
                # the previous cycle.
                best = None
                best_gap = 4
                for log in weight_logs:
                    gap = abs((log.logged_at.date() - target_date).days)
                    if gap < best_gap:
                        best, best_gap = log, gap
                if best is not None:
                    delta = round(latest.weight_kg - best.weight_kg, 2)
                    same_point_last_cycle = {
                        "cycle_day": cycle_day + 1,  # 1-based for display
                        "current_weight_kg": round(latest.weight_kg, 2),
                        "current_logged_date": latest_date.isoformat(),
                        "last_cycle_weight_kg": round(best.weight_kg, 2),
                        "last_cycle_logged_date": best.logged_at.date().isoformat(),
                        "last_cycle_phase": best.cycle_phase,
                        "delta_kg": delta,
                        "comparison_gap_days": best_gap,
                    }

        return {
            "user_id": user_id,
            "period_start": from_date_str,
            "period_end": today_str,
            "cycle_tracking_enabled": tracking_enabled,
            "current_cycle_phase": (
                prediction.get("current_phase") if prediction else None
            ),
            "weight_trend": (
                {
                    "smoothed_weight_kg": trend.smoothed_weight,
                    "raw_weight_kg": trend.raw_weight,
                    "trend_direction": trend.trend_direction,
                    "weekly_rate_kg": trend.weekly_rate_kg,
                    "confidence": trend.confidence,
                }
                if trend
                else None
            ),
            "weight_series": weight_series,
            "hold_calorie_target": hold_calorie_target,
            "hold_window_start": hold_window_start,
            "hold_window_end": hold_window_end,
            "hold_reason": hold_reason,
            "same_point_last_cycle": same_point_last_cycle,
        }

    except Exception as e:
        logger.error(f"Failed cycle-aware adaptive TDEE: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


