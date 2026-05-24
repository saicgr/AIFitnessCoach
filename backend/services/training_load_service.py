"""
Training Load Service (Banister TRIMP + Acute:Chronic Workload Ratio)
=====================================================================

Computes per-session TRIMP, then daily / acute (7d) / chronic (28d) rolling
loads and the ACWR ratio used by sport scientists to classify training as
detraining, balanced, loading, or overreaching.

References:
- Banister EW (1991). "Modeling Elite Athletic Performance."
- Gabbett TJ (2016). "The training-injury prevention paradox."
  BJSM 50(5): 273-280.

Formulas
--------
- Heart-rate intensity ratio:
    y = (avg_hr - resting_hr) / (max_hr - resting_hr)

- Banister HR-weighted TRIMP per session (Morton 1990 / Banister 1991):
    male:   trimp = duration_min * y * 0.64 * exp(1.92 * y)
    female: trimp = duration_min * y * 0.86 * exp(1.67 * y)

- If no HR data:
    RPE fallback   : trimp = duration_min * rpe        (Foster sRPE)
    Calorie fallback: trimp = calories / 10            (rough proxy)
    Final fallback  : trimp = duration_min * 5         (Z2 equivalent)

- Acute load   = sum(daily TRIMP, last 7 days, right-aligned, inclusive)
- Chronic load = sum(daily TRIMP, last 28 days, right-aligned, inclusive)
- ACWR         = acute / chronic   (None if chronic == 0)

State classification (requires >= 14 days of history):
    acwr < 0.8                  -> detraining
    0.8 <= acwr <= 1.3          -> balanced     (sweet spot)
    1.3 <  acwr <= 1.5          -> loading
    acwr > 1.5                  -> overreaching

This module is self-contained: pass it cardio sessions (list of dicts with
performed_at + HR/duration/RPE/calories), or call the `compute_*` helpers
with a live Supabase `db` to pull from `cardio_logs` + `cardio_sessions`.
"""
from __future__ import annotations

import math
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from typing import Any, Iterable, List, Optional

from pydantic import BaseModel, Field

from core.logger import get_logger

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Public response models
# ---------------------------------------------------------------------------


class TrainingLoadDayPoint(BaseModel):
    """A single day in the training-load timeline."""

    date: date
    daily_trimp: float = Field(..., ge=0)
    acute_load: float = Field(..., ge=0, description="7-day rolling sum of TRIMP")
    chronic_load: float = Field(..., ge=0, description="28-day rolling sum of TRIMP")
    acwr: Optional[float] = Field(default=None, description="acute / chronic (None if chronic==0)")


class TrainingLoadState(BaseModel):
    """Latest computed state + classification + interpretation."""

    as_of: date
    daily_trimp: float
    acute_load: float
    chronic_load: float
    acwr: Optional[float]
    state: str = Field(..., description="detraining | balanced | loading | overreaching | calibration")
    interpretation: str
    days_of_history: int


# ---------------------------------------------------------------------------
# Defaults — used when the user profile is missing fields
# ---------------------------------------------------------------------------

DEFAULT_RESTING_HR = 60
DEFAULT_MAX_HR = 190  # ~Tanaka for 30y
DEFAULT_GENDER = "male"


# ---------------------------------------------------------------------------
# TRIMP per session
# ---------------------------------------------------------------------------


def compute_session_trimp(
    duration_minutes: float,
    avg_hr: Optional[float] = None,
    resting_hr: Optional[int] = None,
    max_hr: Optional[int] = None,
    gender: str = DEFAULT_GENDER,
    rpe: Optional[float] = None,
    calories: Optional[float] = None,
) -> float:
    """Banister HR-weighted TRIMP for a single session.

    Returns 0.0 if duration is non-positive — every other branch yields a
    positive value (we deliberately do not silently zero out cardio that
    lacks HR; the RPE / calorie / final fallback always fires).
    """
    if duration_minutes is None or duration_minutes <= 0:
        return 0.0

    # 1) Best case: HR-weighted Banister TRIMP.
    if avg_hr is not None and avg_hr > 0:
        rest = resting_hr if (resting_hr and resting_hr > 0) else DEFAULT_RESTING_HR
        peak = max_hr if (max_hr and max_hr > rest) else DEFAULT_MAX_HR
        if peak <= rest:
            # Degenerate profile — fall through to RPE/calorie fallback.
            pass
        else:
            y = (float(avg_hr) - rest) / (peak - rest)
            # Clamp y to [0.0, 1.0] — avg_hr below resting or above max is
            # a wearable bug, not an athletic feat.
            y = max(0.0, min(1.0, y))
            if (gender or "").lower().startswith("f"):
                k1, k2 = 0.86, 1.67
            else:
                k1, k2 = 0.64, 1.92
            return float(duration_minutes) * y * k1 * math.exp(k2 * y)

    # 2) RPE fallback (Foster sRPE — duration_min * RPE/10 scale).
    if rpe is not None and rpe > 0:
        return float(duration_minutes) * float(rpe)

    # 3) Calorie fallback — rough proxy: 10 kcal ~ 1 TRIMP unit.
    if calories is not None and calories > 0:
        return float(calories) / 10.0

    # 4) Final fallback — assume Zone 2 effort.
    return float(duration_minutes) * 5.0


# ---------------------------------------------------------------------------
# Rolling-window helpers
# ---------------------------------------------------------------------------


def _rolling_sum(daily: List[float], window: int) -> List[float]:
    """Right-aligned, inclusive rolling sum over `daily`.

    Index i sums daily[max(0, i-window+1) : i+1] — so day 0 returns daily[0],
    day 6 (with window=7) returns sum(daily[0:7]).
    """
    out: List[float] = []
    running = 0.0
    from collections import deque

    q: deque = deque()
    for v in daily:
        q.append(v)
        running += v
        if len(q) > window:
            running -= q.popleft()
        out.append(running)
    return out


# ---------------------------------------------------------------------------
# Daily aggregation
# ---------------------------------------------------------------------------


@dataclass
class _RawSession:
    when: date
    duration_minutes: float
    avg_hr: Optional[float]
    rpe: Optional[float]
    calories: Optional[float]


def _to_date(value: Any) -> Optional[date]:
    if value is None:
        return None
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, datetime):
        return value.astimezone(timezone.utc).date() if value.tzinfo else value.date()
    if isinstance(value, str):
        try:
            # Handles "2026-05-24" or full ISO timestamp.
            if "T" in value or " " in value:
                # Z suffix → +00:00 for fromisoformat
                v = value.replace("Z", "+00:00")
                return datetime.fromisoformat(v).astimezone(timezone.utc).date()
            return date.fromisoformat(value)
        except Exception:
            return None
    return None


def _aggregate_daily_trimp(
    sessions: Iterable[_RawSession],
    *,
    resting_hr: Optional[int],
    max_hr: Optional[int],
    gender: str,
) -> dict:
    by_day: dict[date, float] = defaultdict(float)
    for s in sessions:
        by_day[s.when] += compute_session_trimp(
            duration_minutes=s.duration_minutes,
            avg_hr=s.avg_hr,
            resting_hr=resting_hr,
            max_hr=max_hr,
            gender=gender,
            rpe=s.rpe,
            calories=s.calories,
        )
    return by_day


def _build_history(
    by_day: dict,
    *,
    start: date,
    end: date,
) -> List[TrainingLoadDayPoint]:
    days = (end - start).days + 1
    daily_series: List[float] = []
    date_series: List[date] = []
    cursor = start
    for _ in range(days):
        daily_series.append(float(by_day.get(cursor, 0.0)))
        date_series.append(cursor)
        cursor += timedelta(days=1)

    acute_series = _rolling_sum(daily_series, 7)
    chronic_series = _rolling_sum(daily_series, 28)

    points: List[TrainingLoadDayPoint] = []
    for i, d in enumerate(date_series):
        chronic = chronic_series[i]
        acwr = (acute_series[i] / chronic) if chronic > 0 else None
        points.append(
            TrainingLoadDayPoint(
                date=d,
                daily_trimp=round(daily_series[i], 2),
                acute_load=round(acute_series[i], 2),
                chronic_load=round(chronic_series[i], 2),
                acwr=round(acwr, 3) if acwr is not None else None,
            )
        )
    return points


# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------


def classify_state(
    acwr: Optional[float], days_of_history: int
) -> tuple[str, str]:
    """Return (state, interpretation)."""
    if days_of_history < 14:
        return (
            "calibration",
            "Building your baseline — we need ~14 days of cardio activity to "
            "classify training load reliably.",
        )
    if acwr is None:
        return (
            "detraining",
            "No chronic training load on file. Get a few cardio sessions in "
            "this week to start building your base.",
        )
    if acwr < 0.8:
        return (
            "detraining",
            "Your recent load is well below your baseline. Fitness may decay "
            "if this continues — consider a moderate session this week.",
        )
    if acwr <= 1.3:
        return (
            "balanced",
            "Sweet spot: you're loading at a sustainable rate. Adaptation "
            "without elevated injury risk.",
        )
    if acwr <= 1.5:
        return (
            "loading",
            "Productive overload. You're pushing harder than baseline — keep "
            "an eye on sleep and soreness this week.",
        )
    return (
        "overreaching",
        "High injury risk zone. Recent load is far above your chronic "
        "baseline — consider an easy day or a rest day.",
    )


# ---------------------------------------------------------------------------
# Public entrypoints — work against Supabase
# ---------------------------------------------------------------------------


def _load_user_profile(db, user_id: str) -> dict:
    try:
        res = (
            db.client.table("users")
            .select("id, date_of_birth, gender")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        user = (res.data or [{}])[0]
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[TrainingLoad] user profile lookup failed: {e}")
        user = {}

    # Age
    age = 30
    dob = user.get("date_of_birth")
    if dob:
        try:
            dob_d = date.fromisoformat(str(dob)[:10])
            today = date.today()
            age = today.year - dob_d.year - (
                (today.month, today.day) < (dob_d.month, dob_d.day)
            )
        except Exception:
            age = 30

    gender = (user.get("gender") or DEFAULT_GENDER).lower()

    # Resting / max HR — best effort from cardio_metrics if present.
    resting_hr: Optional[int] = None
    max_hr: Optional[int] = None
    try:
        res = (
            db.client.table("cardio_metrics")
            .select("resting_hr, custom_max_hr")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        if res.data:
            row = res.data[0]
            resting_hr = row.get("resting_hr")
            max_hr = row.get("custom_max_hr")
    except Exception:
        pass

    if max_hr is None:
        # Tanaka formula
        max_hr = int(round(208 - 0.7 * age))

    return {
        "age": age,
        "gender": gender,
        "resting_hr": resting_hr,
        "max_hr": max_hr,
    }


def _load_sessions(db, user_id: str, since: datetime) -> List[_RawSession]:
    """Pull cardio rows for user from `cardio_logs` + `cardio_sessions`."""
    sessions: List[_RawSession] = []

    # cardio_logs — duration in seconds
    try:
        res = (
            db.client.table("cardio_logs")
            .select(
                "performed_at, duration_seconds, avg_heart_rate, rpe, calories"
            )
            .eq("user_id", user_id)
            .gte("performed_at", since.isoformat())
            .execute()
        )
        for row in (res.data or []):
            d = _to_date(row.get("performed_at"))
            if d is None:
                continue
            dur_s = row.get("duration_seconds") or 0
            sessions.append(
                _RawSession(
                    when=d,
                    duration_minutes=float(dur_s) / 60.0,
                    avg_hr=row.get("avg_heart_rate"),
                    rpe=row.get("rpe"),
                    calories=row.get("calories"),
                )
            )
    except Exception as e:
        logger.warning(f"[TrainingLoad] cardio_logs query failed: {e}")

    # cardio_sessions — duration in minutes, no RPE column (use HR or calories)
    try:
        res = (
            db.client.table("cardio_sessions")
            .select(
                "started_at, completed_at, duration_minutes, avg_heart_rate, "
                "calories_burned"
            )
            .eq("user_id", user_id)
            .gte("started_at", since.isoformat())
            .execute()
        )
        for row in (res.data or []):
            d = _to_date(row.get("completed_at") or row.get("started_at"))
            if d is None:
                continue
            sessions.append(
                _RawSession(
                    when=d,
                    duration_minutes=float(row.get("duration_minutes") or 0),
                    avg_hr=row.get("avg_heart_rate"),
                    rpe=None,
                    calories=row.get("calories_burned"),
                )
            )
    except Exception as e:
        logger.warning(f"[TrainingLoad] cardio_sessions query failed: {e}")

    return sessions


def compute_training_load_history(
    db,
    user_id: str,
    days: int = 120,
) -> List[TrainingLoadDayPoint]:
    """Return a per-day TrainingLoadDayPoint series for the last `days` days.

    The series ends today (inclusive). To keep chronic_load[0] honest we
    pull 27 extra days of cardio before the window start so the 28-day
    rolling sum is correct from day 0 of the visible window — but only
    points inside the visible window are returned.
    """
    days = max(1, min(days, 730))
    today = date.today()
    visible_start = today - timedelta(days=days - 1)
    # 27 extra days so chronic-load is right-aligned at the visible_start.
    pull_start = visible_start - timedelta(days=27)
    since_dt = datetime.combine(pull_start, datetime.min.time(), tzinfo=timezone.utc)

    profile = _load_user_profile(db, user_id)
    raw = _load_sessions(db, user_id, since_dt)
    by_day = _aggregate_daily_trimp(
        raw,
        resting_hr=profile["resting_hr"],
        max_hr=profile["max_hr"],
        gender=profile["gender"],
    )
    full = _build_history(by_day, start=pull_start, end=today)
    # Slice to visible window
    return [p for p in full if p.date >= visible_start]


def current_state(db, user_id: str) -> TrainingLoadState:
    """Latest TrainingLoadState — pulls 120d of history under the hood."""
    history = compute_training_load_history(db, user_id, days=120)
    if not history:
        today = date.today()
        return TrainingLoadState(
            as_of=today,
            daily_trimp=0.0,
            acute_load=0.0,
            chronic_load=0.0,
            acwr=None,
            state="calibration",
            interpretation=classify_state(None, 0)[1],
            days_of_history=0,
        )

    # Count distinct days with activity, capped at the visible window length.
    days_active = sum(1 for p in history if p.daily_trimp > 0)
    days_of_history = min(len(history), days_active * 1000 if days_active else 0)
    # Use elapsed-since-first-activity as the calibration metric — that is
    # what gates the classifier per spec.
    first_active = next((p.date for p in history if p.daily_trimp > 0), None)
    if first_active is not None:
        days_of_history = (date.today() - first_active).days + 1
    else:
        days_of_history = 0

    latest = history[-1]
    state, interpretation = classify_state(latest.acwr, days_of_history)
    return TrainingLoadState(
        as_of=latest.date,
        daily_trimp=latest.daily_trimp,
        acute_load=latest.acute_load,
        chronic_load=latest.chronic_load,
        acwr=latest.acwr,
        state=state,
        interpretation=interpretation,
        days_of_history=days_of_history,
    )


# ---------------------------------------------------------------------------
# Pure-data variants (used by tests + future callers that already have rows)
# ---------------------------------------------------------------------------


def compute_history_from_sessions(
    sessions: List[dict],
    *,
    days: int = 120,
    today: Optional[date] = None,
    resting_hr: Optional[int] = None,
    max_hr: Optional[int] = None,
    gender: str = DEFAULT_GENDER,
) -> List[TrainingLoadDayPoint]:
    """Pure-data variant for tests / callers that already have session rows.

    Each session dict supports keys: when (date|str|datetime),
    duration_minutes, avg_hr, rpe, calories.
    """
    today = today or date.today()
    visible_start = today - timedelta(days=days - 1)
    pull_start = visible_start - timedelta(days=27)

    raw: List[_RawSession] = []
    for s in sessions:
        d = _to_date(s.get("when") or s.get("date") or s.get("performed_at"))
        if d is None or d > today or d < pull_start:
            continue
        raw.append(
            _RawSession(
                when=d,
                duration_minutes=float(s.get("duration_minutes") or 0),
                avg_hr=s.get("avg_hr"),
                rpe=s.get("rpe"),
                calories=s.get("calories"),
            )
        )

    by_day = _aggregate_daily_trimp(
        raw, resting_hr=resting_hr, max_hr=max_hr, gender=gender
    )
    full = _build_history(by_day, start=pull_start, end=today)
    return [p for p in full if p.date >= visible_start]
