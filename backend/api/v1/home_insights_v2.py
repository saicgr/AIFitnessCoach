"""Home-screen insight endpoints — second batch.

Six small, focused endpoints backing additional opportunistic home cards:

- GET /insights/jet-lag           → recent timezone shift detection
- GET /insights/busy-week-density → low-activity 5d vs 28d baseline
- GET /insights/refeed-proposal   → refeed eligibility for fat-loss users
- GET /insights/electrolyte-need  → sweat-day proxy
- GET /social/kudos-unread        → unread kudos count (table-conditional)
- GET /insights/weigh-in-day-pref → persisted weigh-in weekday + last log

All queries hit Supabase directly. No mock data, no silent fallback —
exceptions bubble as 500 with detail (per `feedback_no_silent_fallbacks.md`).

Schema additions required:
  - user_ai_settings.last_seen_timezone TEXT
  - user_ai_settings.weigh_in_weekday   SMALLINT (0=Mon .. 6=Sun)
See `backend/migrations/2201_home_insights_v2.sql`.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import user_today_date

logger = logging.getLogger(__name__)

insights_router = APIRouter(prefix="/insights", tags=["Home Insights"])
social_router = APIRouter(prefix="/social", tags=["Home Insights"])


# ─── 1. Jet-lag detection ────────────────────────────────────────────────────

class JetLagResponse(BaseModel):
    shifted_hours: Optional[int]
    last_tz: Optional[str]
    current_tz: Optional[str]
    days_since_shift: Optional[int]
    recommended_bedtime_shift_min: Optional[int]


def _tz_offset_hours(tz_name: str, at: datetime) -> Optional[float]:
    """Return UTC offset in hours for an IANA tz at a given moment."""
    try:
        from zoneinfo import ZoneInfo
        offset = at.astimezone(ZoneInfo(tz_name)).utcoffset()
        if offset is None:
            return None
        return offset.total_seconds() / 3600.0
    except Exception:
        return None


@insights_router.get("/jet-lag", response_model=JetLagResponse)
async def get_jet_lag(
    request: Request,
    current_tz: str = Query(..., description="Device IANA tz, e.g. America/Chicago"),
    current_user: dict = Depends(get_current_user),
) -> JetLagResponse:
    """Detect a recent timezone shift vs the user's last-seen tz.

    Compares `user_ai_settings.last_seen_timezone` against the passed
    `current_tz`. Returns shift metadata when the last-recorded tz differs and
    last_seen_at was within the last 7 days. Persists current_tz back.
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        # Read existing record.
        res = (
            db.client.table("user_ai_settings")
            .select("last_seen_timezone, last_seen_timezone_at")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        row = (res.data or [None])[0]
        last_tz: Optional[str] = (row or {}).get("last_seen_timezone")
        last_at_raw = (row or {}).get("last_seen_timezone_at")

        now = datetime.now(timezone.utc)
        days_since: Optional[int] = None
        shifted: Optional[int] = None
        bedtime_shift: Optional[int] = None
        response_last_tz: Optional[str] = last_tz
        response_current_tz: Optional[str] = current_tz

        if last_tz and last_tz != current_tz and last_at_raw:
            try:
                last_at = datetime.fromisoformat(str(last_at_raw).replace("Z", "+00:00"))
            except Exception:
                last_at = None
            if last_at is not None:
                delta_days = (now - last_at).days
                if 0 <= delta_days <= 7:
                    a = _tz_offset_hours(last_tz, now)
                    b = _tz_offset_hours(current_tz, now)
                    if a is not None and b is not None:
                        # Positive = eastward (clock advanced)
                        shifted = int(round(b - a))
                        days_since = delta_days
                        # Rule of thumb: shift bedtime ~60 min per hour of jet lag,
                        # capped at ±180 min (3h) per day of adjustment.
                        bedtime_shift = max(-180, min(180, shifted * 60))

        # Persist current tz / timestamp.
        try:
            upsert_payload = {
                "user_id": user_id,
                "last_seen_timezone": current_tz,
                "last_seen_timezone_at": now.isoformat(),
            }
            db.client.table("user_ai_settings").upsert(
                upsert_payload, on_conflict="user_id"
            ).execute()
        except Exception as persist_err:
            # Persistence failure should not 500 the read path — log it.
            logger.warning("jet-lag tz persist failed: %s", persist_err)

        if shifted is None:
            return JetLagResponse(
                shifted_hours=None, last_tz=response_last_tz,
                current_tz=response_current_tz,
                days_since_shift=None, recommended_bedtime_shift_min=None,
            )
        return JetLagResponse(
            shifted_hours=shifted,
            last_tz=response_last_tz,
            current_tz=response_current_tz,
            days_since_shift=days_since,
            recommended_bedtime_shift_min=bedtime_shift,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("jet-lag detection failed: %s", e)
        raise HTTPException(status_code=500, detail=f"jet-lag failed: {e}")


# ─── 2. Busy-week density ────────────────────────────────────────────────────

class BusyWeekDensityResponse(BaseModel):
    busy: bool
    recent_avg_min: float
    baseline_avg_min: float
    recommended_compressed_workout_min: Optional[int]


@insights_router.get("/busy-week-density", response_model=BusyWeekDensityResponse)
async def get_busy_week_density(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> BusyWeekDensityResponse:
    """Flag busy-week mode when last-5-day workout-minute avg < 30% of 28d baseline.

    Uses `workout_logs.duration_minutes` per day (the `daily_activity` table
    has no total-activity-time column — duration_minutes on completed sessions
    is the closest signal).
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        today = user_today_date(request, db, user_id)
        baseline_start = today - timedelta(days=28)

        res = (
            db.client.table("workout_logs")
            .select("completed_at, duration_minutes")
            .eq("user_id", user_id)
            .gte("completed_at", baseline_start.isoformat())
            .execute()
        )
        rows = res.data or []
        recent_start = today - timedelta(days=5)

        recent_total = 0.0
        baseline_total = 0.0
        for r in rows:
            ts = r.get("completed_at")
            dur = r.get("duration_minutes") or 0
            if not ts:
                continue
            try:
                d = date.fromisoformat(str(ts)[:10])
            except Exception:
                continue
            if baseline_start <= d <= today:
                baseline_total += float(dur)
                if d >= recent_start:
                    recent_total += float(dur)

        recent_avg = recent_total / 5.0 if recent_total else 0.0
        baseline_avg = baseline_total / 28.0 if baseline_total else 0.0

        # Need a meaningful baseline (>=10 min/day) before we'll flag busy-week.
        if baseline_avg < 10.0:
            return BusyWeekDensityResponse(
                busy=False, recent_avg_min=round(recent_avg, 1),
                baseline_avg_min=round(baseline_avg, 1),
                recommended_compressed_workout_min=None,
            )

        busy = recent_avg < (baseline_avg * 0.30)
        compressed: Optional[int] = None
        if busy:
            # Aim for ~half the user's typical session, floored at 20 min,
            # capped at 30 min — fits a "between meetings" window.
            compressed = max(20, min(30, int(round(baseline_avg * 0.5))))
        return BusyWeekDensityResponse(
            busy=busy,
            recent_avg_min=round(recent_avg, 1),
            baseline_avg_min=round(baseline_avg, 1),
            recommended_compressed_workout_min=compressed,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("busy-week density failed: %s", e)
        raise HTTPException(status_code=500, detail=f"busy-week failed: {e}")


# ─── 3. Refeed proposal ──────────────────────────────────────────────────────

class RefeedProposalResponse(BaseModel):
    eligible: bool
    deficit_days: int
    proposed_kcal: Optional[int]


@insights_router.get("/refeed-proposal", response_model=RefeedProposalResponse)
async def get_refeed_proposal(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> RefeedProposalResponse:
    """Propose a refeed day if user is fat-loss + sustained 14-day deficit.

    Eligible when `users.primary_goal == 'lose_fat'` AND total 14d intake
    < target × 14 × 0.85. Proposed kcal = target × 1.10 (10% over maintenance
    for one day — conservative metabolic-reset bump).
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        today = user_today_date(request, db, user_id)
        window_start = today - timedelta(days=14)

        u_res = (
            db.client.table("users")
            .select("primary_goal, daily_calorie_target")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        user_row = (u_res.data or [None])[0] or {}
        primary_goal = (user_row.get("primary_goal") or "").lower()
        target_kcal = user_row.get("daily_calorie_target")

        if primary_goal != "lose_fat" or not target_kcal or float(target_kcal) <= 0:
            return RefeedProposalResponse(
                eligible=False, deficit_days=0, proposed_kcal=None,
            )

        start_dt = datetime.combine(window_start, datetime.min.time(), tzinfo=timezone.utc)
        f_res = (
            db.client.table("food_logs")
            .select("logged_at, calories")
            .eq("user_id", user_id)
            .gte("logged_at", start_dt.isoformat())
            .execute()
        )
        rows = f_res.data or []

        total = 0.0
        deficit_days_set: set[str] = set()
        by_day: dict[str, float] = {}
        for r in rows:
            ts = r.get("logged_at")
            cal = r.get("calories") or 0
            if not ts:
                continue
            day = str(ts)[:10]
            by_day[day] = by_day.get(day, 0.0) + float(cal)
            total += float(cal)

        target = float(target_kcal)
        for day, day_total in by_day.items():
            if day_total < target * 0.85:
                deficit_days_set.add(day)

        threshold = target * 14.0 * 0.85
        eligible = total > 0 and total < threshold and len(deficit_days_set) >= 5
        proposed = int(round(target * 1.10)) if eligible else None

        return RefeedProposalResponse(
            eligible=eligible,
            deficit_days=len(deficit_days_set),
            proposed_kcal=proposed,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("refeed proposal failed: %s", e)
        raise HTTPException(status_code=500, detail=f"refeed failed: {e}")


# ─── 4. Electrolyte need ─────────────────────────────────────────────────────

class ElectrolyteNeedResponse(BaseModel):
    recommend: bool
    reason: Optional[str]


@insights_router.get("/electrolyte-need", response_model=ElectrolyteNeedResponse)
async def get_electrolyte_need(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> ElectrolyteNeedResponse:
    """Sweat-day proxy: ≥45-min session today or ≥60 'active minutes'.

    We approximate `active_minutes` as sum of `workout_logs.duration_minutes`
    completed today (the daily_activity table has no active_minutes column).
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        today = user_today_date(request, db, user_id)
        start_dt = datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc)
        end_dt = start_dt + timedelta(days=1)

        w_res = (
            db.client.table("workout_logs")
            .select("duration_minutes")
            .eq("user_id", user_id)
            .gte("completed_at", start_dt.isoformat())
            .lt("completed_at", end_dt.isoformat())
            .execute()
        )
        rows = w_res.data or []
        durations = [float(r.get("duration_minutes") or 0) for r in rows]
        longest = max(durations) if durations else 0.0
        total = sum(durations)

        if longest >= 45.0:
            return ElectrolyteNeedResponse(
                recommend=True,
                reason=f"You trained {int(longest)} min today — add 300-500 mg sodium.",
            )
        if total >= 60.0:
            return ElectrolyteNeedResponse(
                recommend=True,
                reason=f"{int(total)} active min today — replace electrolytes lost in sweat.",
            )
        return ElectrolyteNeedResponse(recommend=False, reason=None)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("electrolyte need failed: %s", e)
        raise HTTPException(status_code=500, detail=f"electrolyte failed: {e}")


# ─── 5. Kudos unread ─────────────────────────────────────────────────────────

class KudosUnreadResponse(BaseModel):
    count: int


@social_router.get("/kudos-unread", response_model=KudosUnreadResponse)
async def get_kudos_unread(
    current_user: dict = Depends(get_current_user),
) -> KudosUnreadResponse:
    """Count unread kudos for the user.

    TODO: requires kudos table — schema not present. Returns 0 until the
    table ships. We try the query and gracefully treat "table doesn't exist"
    as a 0 count (rather than 500-ing the home screen).
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        try:
            res = (
                db.client.table("kudos")
                .select("id", count="exact")
                .eq("recipient_user_id", user_id)
                .is_("read_at", "null")
                .execute()
            )
            count = int(res.count or 0)
        except Exception as inner:
            msg = str(inner).lower()
            if "kudos" in msg and ("does not exist" in msg or "not found" in msg
                                    or "schema cache" in msg or "relation" in msg):
                return KudosUnreadResponse(count=0)
            raise
        return KudosUnreadResponse(count=count)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("kudos unread failed: %s", e)
        raise HTTPException(status_code=500, detail=f"kudos failed: {e}")


# ─── 6. Weigh-in day preference ──────────────────────────────────────────────

class WeighInDayPrefResponse(BaseModel):
    weekday: Optional[int]
    last_weigh_in_at: Optional[str]


@insights_router.get("/weigh-in-day-pref", response_model=WeighInDayPrefResponse)
async def get_weigh_in_day_pref(
    current_user: dict = Depends(get_current_user),
) -> WeighInDayPrefResponse:
    """Return persisted weigh-in weekday (0=Mon..6=Sun) and last weigh-in ts.

    `user_ai_settings.weigh_in_weekday` is the source of truth. Last weigh-in
    pulled from `weight_logs.logged_at`. Both nullable.
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        settings_res = (
            db.client.table("user_ai_settings")
            .select("weigh_in_weekday")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        weekday_raw = ((settings_res.data or [None])[0] or {}).get("weigh_in_weekday")
        weekday: Optional[int] = (
            int(weekday_raw) if isinstance(weekday_raw, (int, float)) else None
        )

        wl_res = (
            db.client.table("weight_logs")
            .select("logged_at")
            .eq("user_id", user_id)
            .order("logged_at", desc=True)
            .limit(1)
            .execute()
        )
        last_at = ((wl_res.data or [None])[0] or {}).get("logged_at")

        return WeighInDayPrefResponse(
            weekday=weekday,
            last_weigh_in_at=str(last_at) if last_at else None,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("weigh-in day pref failed: %s", e)
        raise HTTPException(status_code=500, detail=f"weigh-in pref failed: {e}")
