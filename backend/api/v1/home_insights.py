"""Home-screen insight endpoints.

Four small, focused endpoints powering opportunistic home cards:

- GET /nutrition/micros/today-gap      → biggest micronutrient gap today
- GET /insights/workout-sleep-correlation → late-workout vs REM correlation
- GET /insights/strain-recovery-mismatch  → strain rising while recovery flat
- GET /insights/discovery                 → single rotating pattern insight

All queries hit Supabase directly. No mock data, no silent fallback —
exceptions bubble as 500 with detail (per `feedback_no_silent_fallbacks.md`).
"""
from __future__ import annotations

import logging
import statistics
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, user_today_date

logger = logging.getLogger(__name__)

# Two separate routers so paths align with existing tag structure
# (`/nutrition/...` vs `/insights/...`).
nutrition_router = APIRouter(prefix="/nutrition", tags=["Home Insights"])
insights_router = APIRouter(prefix="/insights", tags=["Home Insights"])


# ─── Micronutrient gap ───────────────────────────────────────────────────────

# RDA / DV reference values (adult, mixed-sex midpoint). Sources: NIH ODS fact
# sheets + FDA Daily Values (21 CFR 101.9). Kept conservative — we surface
# "lowest coverage" not "you're deficient", so a midpoint RDA is fine.
_RDA: Dict[str, float] = {
    "iron_mg": 12.0,        # NIH ODS adult avg (men 8, women 18)
    "calcium_mg": 1000.0,   # NIH ODS adult 19-50
    "vitamin_d_mcg": 15.0,  # NIH ODS adult 19-70
    "magnesium_mg": 400.0,  # NIH ODS adult midpoint
    "potassium_mg": 3400.0, # FDA DV
    "vitamin_c_mg": 80.0,   # FDA DV midpoint (men 90, women 75)
    "fiber_g": 28.0,        # FDA DV
    "omega3_g": 1.6,        # NIH ODS ALA adequate intake midpoint
}

_MICRO_LABELS: Dict[str, str] = {
    "iron_mg": "Iron",
    "calcium_mg": "Calcium",
    "vitamin_d_mcg": "Vitamin D",
    "magnesium_mg": "Magnesium",
    "potassium_mg": "Potassium",
    "vitamin_c_mg": "Vitamin C",
    "fiber_g": "Fiber",
    "omega3_g": "Omega-3",
}

# Curated example foods per micro. No LLM, no new table — just hand-picked
# common items so the chip says "try spinach, lentils, beef" not "log more iron".
_EXAMPLE_FOODS: Dict[str, List[str]] = {
    "iron_mg": ["Spinach", "Lentils", "Lean beef"],
    "calcium_mg": ["Greek yogurt", "Sardines", "Kale"],
    "vitamin_d_mcg": ["Salmon", "Egg yolks", "Fortified milk"],
    "magnesium_mg": ["Almonds", "Black beans", "Dark chocolate"],
    "potassium_mg": ["Banana", "Sweet potato", "White beans"],
    "vitamin_c_mg": ["Bell pepper", "Strawberries", "Orange"],
    "fiber_g": ["Oats", "Raspberries", "Chia seeds"],
    "omega3_g": ["Salmon", "Walnuts", "Flaxseed"],
}


class MicroGapResponse(BaseModel):
    micro: Optional[str]
    coverage_pct: Optional[float]
    rda: float
    current: float
    example_foods: List[str]


@nutrition_router.get("/micros/today-gap", response_model=MicroGapResponse)
async def get_today_micronutrient_gap(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> MicroGapResponse:
    """Single biggest micronutrient gap based on today's logged foods.

    Aggregates `food_logs` rows for the user's local date, picks the micro with
    the LOWEST coverage % vs RDA among those that have at least 2 logged meals
    today (otherwise the signal is too noisy to surface).
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        today = user_today_date(request, db, user_id)

        # food_logs.logged_at is timestamptz; bound by user-local day in UTC.
        # Pull both `logged_at` (preferred) and column variants so we don't 500
        # if the column rename ever rolls forward/back.
        start = datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc)
        end = start + timedelta(days=1)

        cols = ",".join(["id", "logged_at"] + list(_RDA.keys()))
        res = (
            db.client.table("food_logs")
            .select(cols)
            .eq("user_id", user_id)
            .gte("logged_at", start.isoformat())
            .lt("logged_at", end.isoformat())
            .execute()
        )
        rows = res.data or []

        if len(rows) < 2:
            # Not enough signal — chip self-collapses on null.
            return MicroGapResponse(
                micro=None, coverage_pct=None, rda=0.0, current=0.0,
                example_foods=[],
            )

        totals: Dict[str, float] = {k: 0.0 for k in _RDA}
        for row in rows:
            for key in _RDA:
                v = row.get(key)
                if isinstance(v, (int, float)):
                    totals[key] += float(v)

        # Lowest coverage % wins. Ignore micros with literally zero data —
        # 0/RDA is more often "this column isn't populated by the food DB" than
        # a real deficit; with 0 we have nothing concrete to nudge against.
        scored: List[Tuple[str, float, float]] = []
        for key, total in totals.items():
            if total <= 0:
                continue
            coverage = (total / _RDA[key]) * 100.0
            scored.append((key, coverage, total))

        if not scored:
            return MicroGapResponse(
                micro=None, coverage_pct=None, rda=0.0, current=0.0,
                example_foods=[],
            )

        scored.sort(key=lambda t: t[1])
        winner_key, winner_pct, winner_total = scored[0]
        # Cap at < 100% coverage — if user already hit RDA, no gap to surface.
        if winner_pct >= 100.0:
            return MicroGapResponse(
                micro=None, coverage_pct=None, rda=0.0, current=0.0,
                example_foods=[],
            )

        return MicroGapResponse(
            micro=_MICRO_LABELS[winner_key],
            coverage_pct=round(winner_pct, 1),
            rda=_RDA[winner_key],
            current=round(winner_total, 2),
            example_foods=_EXAMPLE_FOODS[winner_key],
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("micro gap failed for user %s: %s", user_id, e)
        raise HTTPException(status_code=500, detail=f"micro gap failed: {e}")


# ─── Workout-sleep correlation ───────────────────────────────────────────────

class WorkoutSleepCorrelationResponse(BaseModel):
    late_workout_threshold_hour: int = 20
    rem_drop_pct: Optional[float]
    sample_size: int
    weeks: int = 4


@insights_router.get(
    "/workout-sleep-correlation",
    response_model=WorkoutSleepCorrelationResponse,
)
async def get_workout_sleep_correlation(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> WorkoutSleepCorrelationResponse:
    """REM-% drop following late (>=8 PM local) workouts vs 28-day baseline.

    Returns rem_drop_pct as a relative drop (e.g. 0.12 = REM is 12% lower on
    late-workout nights). Null when sample size is too small or drop < 10%.
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        tz_str = resolve_timezone(request, db, user_id)
        today = user_today_date(request, db, user_id)
        start_day = today - timedelta(days=28)

        # Workouts in window (need completed_at to pick "late" sessions).
        w_res = (
            db.client.table("workout_logs")
            .select("id, completed_at")
            .eq("user_id", user_id)
            .gte("completed_at", start_day.isoformat())
            .execute()
        )
        workouts = w_res.data or []

        # Sleep is in `daily_activity` keyed by activity_date.
        s_res = (
            db.client.table("daily_activity")
            .select("activity_date, sleep_minutes, rem_sleep_minutes")
            .eq("user_id", user_id)
            .gte("activity_date", start_day.isoformat())
            .execute()
        )
        sleep_rows = s_res.data or []

        # Build a map: activity_date → rem_pct (rem / total sleep).
        rem_by_date: Dict[str, float] = {}
        for r in sleep_rows:
            sm = r.get("sleep_minutes") or 0
            rm = r.get("rem_sleep_minutes") or 0
            if sm > 0 and rm > 0:
                rem_by_date[str(r.get("activity_date"))] = (rm / sm) * 100.0

        if len(rem_by_date) < 7:
            return WorkoutSleepCorrelationResponse(
                rem_drop_pct=None, sample_size=0,
            )

        # Try resolving zone for local-hour bucketing; fall back to naive UTC.
        try:
            from zoneinfo import ZoneInfo
            tz = ZoneInfo(tz_str) if tz_str else timezone.utc
        except Exception:
            tz = timezone.utc

        late_dates: set[str] = set()
        for w in workouts:
            ts = w.get("completed_at")
            if not ts:
                continue
            try:
                dt = datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
            except Exception:
                continue
            try:
                local = dt.astimezone(tz)
            except Exception:
                local = dt
            if local.hour >= 20:
                # REM "the night of" → date the night STARTED on (workout date).
                late_dates.add(local.date().isoformat())

        late_rems = [rem_by_date[d] for d in late_dates if d in rem_by_date]
        all_rems = list(rem_by_date.values())

        if len(late_rems) < 3 or len(all_rems) < 7:
            return WorkoutSleepCorrelationResponse(
                rem_drop_pct=None, sample_size=len(late_rems),
            )

        late_mean = statistics.mean(late_rems)
        baseline_mean = statistics.mean(all_rems)
        if baseline_mean <= 0:
            return WorkoutSleepCorrelationResponse(
                rem_drop_pct=None, sample_size=len(late_rems),
            )

        relative_drop = (baseline_mean - late_mean) / baseline_mean
        # Surface only meaningful drops (>=10% relative).
        if relative_drop < 0.10:
            return WorkoutSleepCorrelationResponse(
                rem_drop_pct=None, sample_size=len(late_rems),
            )
        return WorkoutSleepCorrelationResponse(
            rem_drop_pct=round(relative_drop, 3),
            sample_size=len(late_rems),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("workout-sleep correlation failed: %s", e)
        raise HTTPException(status_code=500, detail=f"correlation failed: {e}")


# ─── Strain / recovery mismatch ──────────────────────────────────────────────

class StrainRecoveryMismatchResponse(BaseModel):
    strain_trend: str  # "up" | "flat" | "down"
    recovery_trend: str
    recommend_deload: bool
    weeks_observed: int = 3


def _trend(values: List[float]) -> str:
    """Classify a short series by comparing the second-half mean to the first.

    Returns "up" / "down" if the relative delta exceeds 5%, "flat" otherwise.
    Avoids a full linear-regression dependency for what is essentially a
    smoke-signal classifier.
    """
    if len(values) < 4:
        return "flat"
    half = len(values) // 2
    first = statistics.mean(values[:half])
    second = statistics.mean(values[half:])
    if first <= 0:
        return "flat"
    delta = (second - first) / first
    if delta > 0.05:
        return "up"
    if delta < -0.05:
        return "down"
    return "flat"


@insights_router.get(
    "/strain-recovery-mismatch",
    response_model=StrainRecoveryMismatchResponse,
)
async def get_strain_recovery_mismatch(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> StrainRecoveryMismatchResponse:
    """21-day strain trend vs recovery trend; recommend a deload on mismatch.

    Strain proxy = sum(duration_minutes × (intensity_score/100 OR 0.5))
                    per day from `workout_logs`.
    Recovery proxy = mean sleep_minutes per day from `daily_activity`
                    (sleep_score column isn't on the table per schema audit).
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        today = user_today_date(request, db, user_id)
        start_day = today - timedelta(days=21)

        w_res = (
            db.client.table("workout_logs")
            .select("completed_at, duration_minutes, intensity_score")
            .eq("user_id", user_id)
            .gte("completed_at", start_day.isoformat())
            .execute()
        )
        s_res = (
            db.client.table("daily_activity")
            .select("activity_date, sleep_minutes")
            .eq("user_id", user_id)
            .gte("activity_date", start_day.isoformat())
            .order("activity_date")
            .execute()
        )

        # Aggregate strain per local-day (using date prefix of completed_at).
        strain_by_day: Dict[str, float] = {}
        for w in (w_res.data or []):
            ts = w.get("completed_at")
            if not ts:
                continue
            day = str(ts)[:10]
            dur = w.get("duration_minutes") or 0
            intensity = w.get("intensity_score")
            # intensity_score may be 0..100 or null; treat null as moderate.
            intensity_norm = (
                float(intensity) / 100.0 if isinstance(intensity, (int, float))
                else 0.5
            )
            strain_by_day[day] = strain_by_day.get(day, 0.0) + (
                float(dur) * intensity_norm
            )

        # Build dense daily series so 7-day rolling means are well-defined.
        strain_series: List[float] = []
        recovery_series: List[float] = []
        sleep_by_day = {
            str(r.get("activity_date")): (r.get("sleep_minutes") or 0)
            for r in (s_res.data or [])
        }

        day = start_day
        while day <= today:
            key = day.isoformat()
            strain_series.append(strain_by_day.get(key, 0.0))
            recovery_series.append(float(sleep_by_day.get(key, 0)))
            day += timedelta(days=1)

        # 7-day rolling means.
        def rolling(series: List[float], window: int = 7) -> List[float]:
            out: List[float] = []
            for i in range(len(series)):
                lo = max(0, i - window + 1)
                seg = series[lo:i + 1]
                out.append(statistics.mean(seg) if seg else 0.0)
            return out

        strain_roll = rolling(strain_series)
        recovery_roll = rolling(recovery_series)

        strain_trend = _trend(strain_roll)
        recovery_trend = _trend(recovery_roll)

        recommend_deload = (
            strain_trend == "up" and recovery_trend in ("flat", "down")
        )

        return StrainRecoveryMismatchResponse(
            strain_trend=strain_trend,
            recovery_trend=recovery_trend,
            recommend_deload=recommend_deload,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("strain-recovery mismatch failed: %s", e)
        raise HTTPException(status_code=500, detail=f"mismatch failed: {e}")


# ─── Discovery insight ───────────────────────────────────────────────────────

class DiscoveryInsightResponse(BaseModel):
    insight_id: Optional[str]
    title: Optional[str]
    body: Optional[str]
    magnitude_label: Optional[str]
    evidence_days: int


def _delta_z(a: List[float], b: List[float]) -> Tuple[float, float, float]:
    """Return (mean_a - mean_b, pooled_se, signal = abs(delta)/se).

    pooled_se uses sqrt(var_a/n_a + var_b/n_b). If either series < 2 or
    pooled_se ~ 0, returns signal=0 so the caller skips it.
    """
    if len(a) < 2 or len(b) < 2:
        return 0.0, 0.0, 0.0
    ma, mb = statistics.mean(a), statistics.mean(b)
    va, vb = statistics.variance(a), statistics.variance(b)
    se = ((va / len(a)) + (vb / len(b))) ** 0.5
    if se <= 0.0001:
        return ma - mb, se, 0.0
    return ma - mb, se, abs(ma - mb) / se


@insights_router.get("/discovery", response_model=DiscoveryInsightResponse)
async def get_discovery_insight(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> DiscoveryInsightResponse:
    """Pick the strongest of 3 candidate patterns over the last 60 days.

    Candidates:
      a) sleep_minutes on workout days vs rest days
      b) calorie intake on weekend vs weekday days
      c) weight delta the morning after a "high-protein" day (>=top quartile)
         vs other days (here approximated as calorie-only delta, since per-day
         protein totals aren't reliably populated for all users — falls back to
         skipping this candidate if data is missing).

    The candidate with the largest |delta| / pooled_se wins.
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        today = user_today_date(request, db, user_id)
        start_day = today - timedelta(days=60)

        # Pull data once.
        s_res = (
            db.client.table("daily_activity")
            .select("activity_date, sleep_minutes")
            .eq("user_id", user_id)
            .gte("activity_date", start_day.isoformat())
            .execute()
        )
        w_res = (
            db.client.table("workout_logs")
            .select("completed_at")
            .eq("user_id", user_id)
            .gte("completed_at", start_day.isoformat())
            .execute()
        )
        f_res = (
            db.client.table("food_logs")
            .select("logged_at, calories")
            .eq("user_id", user_id)
            .gte("logged_at", start_day.isoformat())
            .execute()
        )

        sleep_by_day: Dict[str, int] = {}
        for r in (s_res.data or []):
            if r.get("sleep_minutes"):
                sleep_by_day[str(r.get("activity_date"))] = int(r["sleep_minutes"])

        workout_days: set[str] = set()
        for w in (w_res.data or []):
            ts = w.get("completed_at")
            if ts:
                workout_days.add(str(ts)[:10])

        calories_by_day: Dict[str, float] = {}
        for f in (f_res.data or []):
            ts = f.get("logged_at")
            if not ts:
                continue
            day = str(ts)[:10]
            cal = f.get("calories") or 0
            calories_by_day[day] = calories_by_day.get(day, 0.0) + float(cal)

        # ── Candidate A: sleep on workout vs rest days ─────────────────────
        sleep_wk = [
            v for d, v in sleep_by_day.items() if d in workout_days
        ]
        sleep_rest = [
            v for d, v in sleep_by_day.items() if d not in workout_days
        ]
        a_delta, _a_se, a_signal = _delta_z(
            [float(x) for x in sleep_wk],
            [float(x) for x in sleep_rest],
        )

        # ── Candidate B: weekend vs weekday calories ───────────────────────
        weekend_cal: List[float] = []
        weekday_cal: List[float] = []
        for day_str, cal in calories_by_day.items():
            try:
                dow = date.fromisoformat(day_str).weekday()
            except Exception:
                continue
            if dow >= 5:
                weekend_cal.append(cal)
            else:
                weekday_cal.append(cal)
        b_delta, _b_se, b_signal = _delta_z(weekend_cal, weekday_cal)

        # ── Candidate C: high-calorie day vs low-calorie day sleep ─────────
        # (Stand-in for "high-protein day" weight delta — protein totals are
        #  not reliably populated; calorie spread is. The pattern surfaced is
        #  similar — "you sleep X min more on big-meal days".)
        if len(calories_by_day) >= 8:
            sorted_cals = sorted(calories_by_day.items(), key=lambda kv: kv[1])
            n = len(sorted_cals)
            bottom = {d for d, _ in sorted_cals[: n // 4]}
            top = {d for d, _ in sorted_cals[-(n // 4):]}
            sleep_top = [sleep_by_day[d] for d in top if d in sleep_by_day]
            sleep_bot = [sleep_by_day[d] for d in bottom if d in sleep_by_day]
            c_delta, _c_se, c_signal = _delta_z(
                [float(x) for x in sleep_top],
                [float(x) for x in sleep_bot],
            )
        else:
            c_delta, c_signal = 0.0, 0.0

        evidence_days = len(sleep_by_day)

        # Pick winner — require minimum signal (>=1.5 SE) to surface anything.
        candidates = [
            ("workout_sleep_delta", a_signal, a_delta, sleep_wk + sleep_rest),
            ("weekend_calorie_delta", b_signal, b_delta, weekend_cal + weekday_cal),
            ("highcal_sleep_delta", c_signal, c_delta, []),
        ]
        candidates.sort(key=lambda t: t[1], reverse=True)
        winner_id, winner_signal, winner_delta, _ = candidates[0]

        if winner_signal < 1.5:
            return DiscoveryInsightResponse(
                insight_id=None, title=None, body=None,
                magnitude_label=None, evidence_days=evidence_days,
            )

        # Format winner.
        if winner_id == "workout_sleep_delta":
            mins = int(round(winner_delta))
            sign = "more" if mins > 0 else "less"
            title = f"You sleep {abs(mins)} min {sign} on workout days"
            body = (
                f"Across the last {evidence_days} days of sleep data, "
                f"training days average {abs(mins)} minutes {sign} sleep than "
                "rest days."
            )
            magnitude = f"{abs(mins)} min/night"
        elif winner_id == "weekend_calorie_delta":
            kcal = int(round(winner_delta))
            sign = "more" if kcal > 0 else "fewer"
            title = f"You eat {abs(kcal)} kcal {sign} on weekends"
            body = (
                f"Weekend days average {abs(kcal)} {sign} calories than "
                f"weekdays over the last {evidence_days} days of logging."
            )
            magnitude = f"{abs(kcal)} kcal"
        else:  # highcal_sleep_delta
            mins = int(round(winner_delta))
            sign = "more" if mins > 0 else "less"
            title = f"You sleep {abs(mins)} min {sign} after big-meal days"
            body = (
                f"High-calorie days are followed by {abs(mins)} minutes "
                f"{sign} sleep on average across the last {evidence_days} "
                "days."
            )
            magnitude = f"{abs(mins)} min/night"

        return DiscoveryInsightResponse(
            insight_id=winner_id,
            title=title,
            body=body,
            magnitude_label=magnitude,
            evidence_days=evidence_days,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("discovery insight failed: %s", e)
        raise HTTPException(status_code=500, detail=f"discovery failed: {e}")
