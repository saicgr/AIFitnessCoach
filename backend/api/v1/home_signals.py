"""
Home-screen secondary signals — small endpoints that feed the home cards that
were previously stubbed in Flutter with `// TODO(backend):` placeholders.

Endpoints (each mounted at its own prefix in api/v1/__init__.py):

  GET /api/v1/home/data-gaps
      Cross-source missing-signal summary. For each connected data source
      (activity/HR, sleep, weight) returns last data timestamp + hours-since.
      Any source with >24h gap is included in `gaps`.

  GET /api/v1/workouts/{workout_id}/training-effect
      Garmin-style aerobic (1-5) + anaerobic (1-5) score for a COMPLETED
      workout_log, plus strain delta vs the user's 14-day mean strain and a
      heuristic primary_benefit label. Aerobic is null when there is no HR
      signal for the session date.

  GET /api/v1/health/rhr-delta
      Today's resting-HR vs 14-day baseline (excluding today). `elevated` is
      true when delta >= 3 bpm for 2 consecutive days (today AND yesterday).

All three endpoints use the existing `get_supabase_db()` + `get_current_user`
auth pattern. Real DB only — when a column/table is missing for a user, the
specific field is set to null rather than crashing the response.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Path, Request

from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import user_today_date
from core.exceptions import safe_internal_error
from core.logger import get_logger

logger = get_logger(__name__)


# ============================================================================
# Routers — one per mount-prefix so they can be hung under the existing
# `/home`, `/workouts`, and `/health` prefixes from api/v1/__init__.py.
# ============================================================================
home_router = APIRouter()
workouts_router = APIRouter()
health_router = APIRouter()
users_router = APIRouter()
wearables_router = APIRouter()


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
def _hours_since(ts: Optional[datetime]) -> Optional[int]:
    if ts is None:
        return None
    now = datetime.now(timezone.utc)
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    delta = now - ts
    return max(0, int(delta.total_seconds() // 3600))


def _parse_ts(raw: Any) -> Optional[datetime]:
    """Parse an ISO timestamp from Postgres; tolerant of trailing 'Z'."""
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return raw
    try:
        s = str(raw)
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        return datetime.fromisoformat(s)
    except Exception:
        return None


def _parse_date(raw: Any) -> Optional[datetime]:
    """Parse a YYYY-MM-DD activity_date into a UTC-midnight timestamp."""
    if raw is None:
        return None
    try:
        if isinstance(raw, datetime):
            return raw
        return datetime.strptime(str(raw), "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except Exception:
        return None


# ----------------------------------------------------------------------------
# 1) GET /api/v1/home/data-gaps
# ----------------------------------------------------------------------------
@home_router.get("/data-gaps", tags=["Home"])
async def get_data_gaps(current_user: dict = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Detect missing-data holes across the user's connected data sources.

    Sources checked:
      - "activity"  : daily_activity.updated_at (any HC/HK activity row)
      - "heart_rate": daily_activity rows where avg_heart_rate IS NOT NULL
      - "sleep"     : daily_activity rows where sleep_minutes IS NOT NULL
      - "weight"    : weight_logs.logged_at
    """
    user_id = str(current_user["id"])
    db = get_supabase_db()

    sources: List[Dict[str, Any]] = []

    # --- activity (any daily_activity row) ---
    try:
        r = (
            db.client.table("daily_activity")
            .select("updated_at, activity_date")
            .eq("user_id", user_id)
            .order("activity_date", desc=True)
            .limit(1)
            .execute()
        )
        rows = r.data or []
        ts = _parse_ts(rows[0].get("updated_at")) if rows else None
        if ts is None and rows:
            # fall back to activity_date midnight if updated_at is null
            ts = _parse_date(rows[0].get("activity_date"))
        sources.append({
            "source": "activity",
            "last_data_at": ts.isoformat() if ts else None,
            "hours_since": _hours_since(ts),
        })
    except Exception as e:
        logger.warning(f"data-gaps: activity probe failed: {e}")
        sources.append({"source": "activity", "last_data_at": None, "hours_since": None})

    # --- heart rate (avg_heart_rate not null) ---
    try:
        r = (
            db.client.table("daily_activity")
            .select("activity_date, updated_at")
            .eq("user_id", user_id)
            .not_.is_("avg_heart_rate", "null")
            .order("activity_date", desc=True)
            .limit(1)
            .execute()
        )
        rows = r.data or []
        ts = _parse_ts(rows[0].get("updated_at")) if rows else None
        if ts is None and rows:
            ts = _parse_date(rows[0].get("activity_date"))
        sources.append({
            "source": "heart_rate",
            "last_data_at": ts.isoformat() if ts else None,
            "hours_since": _hours_since(ts),
        })
    except Exception as e:
        logger.warning(f"data-gaps: heart_rate probe failed: {e}")
        sources.append({"source": "heart_rate", "last_data_at": None, "hours_since": None})

    # --- sleep ---
    try:
        r = (
            db.client.table("daily_activity")
            .select("activity_date, updated_at")
            .eq("user_id", user_id)
            .not_.is_("sleep_minutes", "null")
            .order("activity_date", desc=True)
            .limit(1)
            .execute()
        )
        rows = r.data or []
        ts = _parse_ts(rows[0].get("updated_at")) if rows else None
        if ts is None and rows:
            ts = _parse_date(rows[0].get("activity_date"))
        sources.append({
            "source": "sleep",
            "last_data_at": ts.isoformat() if ts else None,
            "hours_since": _hours_since(ts),
        })
    except Exception as e:
        logger.warning(f"data-gaps: sleep probe failed: {e}")
        sources.append({"source": "sleep", "last_data_at": None, "hours_since": None})

    # --- weight ---
    try:
        r = (
            db.client.table("weight_logs")
            .select("logged_at")
            .eq("user_id", user_id)
            .order("logged_at", desc=True)
            .limit(1)
            .execute()
        )
        rows = r.data or []
        ts = _parse_ts(rows[0].get("logged_at")) if rows else None
        sources.append({
            "source": "weight",
            "last_data_at": ts.isoformat() if ts else None,
            "hours_since": _hours_since(ts),
        })
    except Exception as e:
        logger.warning(f"data-gaps: weight probe failed: {e}")
        sources.append({"source": "weight", "last_data_at": None, "hours_since": None})

    # A "gap" = source where last data is unknown OR > 24h old.
    gaps = [
        s for s in sources
        if s["hours_since"] is None or s["hours_since"] > 24
    ]
    return {"gaps": gaps, "any_gaps": bool(gaps)}


# ----------------------------------------------------------------------------
# 2) GET /api/v1/workouts/{workout_id}/training-effect
# ----------------------------------------------------------------------------
def _classify_primary_benefit(
    aerobic: Optional[float],
    anaerobic: float,
    total_time_seconds: int,
) -> str:
    """
    Heuristic primary-benefit label.

      strength   = anaerobic >= 3.5
      tempo      = aerobic >= 2.5 AND anaerobic >= 2.0
      endurance  = aerobic >= 2.5
      recovery   = everything else (short session / low intensity)
    """
    a = aerobic or 0.0
    if anaerobic >= 3.5:
        return "strength"
    if a >= 2.5 and anaerobic >= 2.0:
        return "tempo"
    if a >= 2.5:
        return "endurance"
    return "recovery"


@workouts_router.get("/{workout_id}/training-effect", tags=["Workouts"])
async def get_training_effect(
    workout_id: str = Path(..., description="Workout (parent) id, not workout_log id"),
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Garmin-style training effect for a completed workout.

    Returns aerobic (1-5, null if no HR data), anaerobic (1-5), strain_delta
    vs 14-day mean, and a primary_benefit heuristic.
    """
    user_id = str(current_user["id"])
    db = get_supabase_db()

    try:
        # Find the most recent workout_log row for this workout+user.
        log_resp = (
            db.client.table("workout_logs")
            .select("id, completed_at, total_time_seconds, sets_json")
            .eq("workout_id", workout_id)
            .eq("user_id", user_id)
            .order("completed_at", desc=True)
            .limit(1)
            .execute()
        )
        log_rows = log_resp.data or []
        if not log_rows:
            raise HTTPException(
                status_code=404,
                detail="No completed workout_log for this workout_id",
            )
        log = log_rows[0]
        workout_log_id = log["id"]
        completed_at = _parse_ts(log.get("completed_at"))
        total_time_seconds = int(log.get("total_time_seconds") or 0)

        # ------------------------------------------------------------------
        # Anaerobic effect — from performance_logs working-set count + RPE
        # (or fall back to weight when RPE missing).
        # Scale: 1.0 (few easy sets) → 5.0 (>=20 hard sets).
        # ------------------------------------------------------------------
        perf_resp = (
            db.client.table("performance_logs")
            .select("set_number, reps_completed, weight_kg, rpe, is_completed")
            .eq("workout_log_id", workout_log_id)
            .execute()
        )
        perf_rows = perf_resp.data or []

        completed_sets = [
            p for p in perf_rows
            if p.get("is_completed") is not False
            and (p.get("reps_completed") or 0) > 0
        ]
        n_sets = len(completed_sets)

        # Intensity proxy — mean RPE, or 7.0 default when no RPE recorded.
        rpe_values = [
            float(p["rpe"]) for p in completed_sets
            if p.get("rpe") is not None
        ]
        mean_rpe = sum(rpe_values) / len(rpe_values) if rpe_values else 7.0

        # Map (n_sets, mean_rpe) → 1.0..5.0.
        # Set-count contribution (caps at 20 sets): 0.0..3.0
        set_component = min(3.0, n_sets * 0.15)
        # RPE contribution: rpe 5 → 0.0, rpe 10 → 2.0
        rpe_component = max(0.0, min(2.0, (mean_rpe - 5.0) * 0.4))
        anaerobic_raw = 1.0 + set_component + rpe_component
        anaerobic = round(max(1.0, min(5.0, anaerobic_raw)), 1)

        # ------------------------------------------------------------------
        # Aerobic effect — needs HR data for the session date.
        # We don't store per-set HR, so use daily_activity.avg_heart_rate +
        # max_heart_rate for the calendar date of completion as a proxy.
        # ------------------------------------------------------------------
        aerobic: Optional[float] = None
        if completed_at is not None:
            session_date = completed_at.date().isoformat()
            try:
                da_resp = (
                    db.client.table("daily_activity")
                    .select("avg_heart_rate, max_heart_rate")
                    .eq("user_id", user_id)
                    .eq("activity_date", session_date)
                    .limit(1)
                    .execute()
                )
                da_rows = da_resp.data or []
                if da_rows:
                    avg_hr = da_rows[0].get("avg_heart_rate")
                    max_hr = da_rows[0].get("max_heart_rate")
                    if avg_hr is not None or max_hr is not None:
                        # Crude HR-zone proxy:
                        #   avg_hr 100 → 1.5, 130 → 3.0, 150 → 4.0, 170 → 5.0
                        if avg_hr is not None:
                            aerobic = round(
                                max(1.0, min(5.0, 1.0 + (float(avg_hr) - 90.0) / 20.0)),
                                1,
                            )
                        elif max_hr is not None:
                            aerobic = round(
                                max(1.0, min(5.0, 1.0 + (float(max_hr) - 120.0) / 15.0)),
                                1,
                            )
            except Exception as e:
                logger.warning(f"training-effect: daily_activity probe failed: {e}")
                aerobic = None

        # ------------------------------------------------------------------
        # Strain delta vs 14-day mean — strain proxy = total_time_seconds.
        # ------------------------------------------------------------------
        strain_delta = 0.0
        try:
            since = (datetime.now(timezone.utc) - timedelta(days=14)).isoformat()
            recent = (
                db.client.table("workout_logs")
                .select("total_time_seconds, completed_at")
                .eq("user_id", user_id)
                .gte("completed_at", since)
                .execute()
            )
            recent_rows = [r for r in (recent.data or []) if r.get("id") != workout_log_id]
            recent_times = [
                int(r["total_time_seconds"]) for r in recent_rows
                if r.get("total_time_seconds")
            ]
            if recent_times:
                mean_strain = sum(recent_times) / len(recent_times)
                strain_delta = round((total_time_seconds - mean_strain) / 60.0, 1)
        except Exception as e:
            logger.warning(f"training-effect: strain delta probe failed: {e}")
            strain_delta = 0.0

        primary_benefit = _classify_primary_benefit(
            aerobic, anaerobic, total_time_seconds
        )

        return {
            "workout_id": workout_id,
            "aerobic": aerobic,
            "anaerobic": anaerobic,
            "strain_delta": strain_delta,
            "primary_benefit": primary_benefit,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"training-effect failed for workout_id={workout_id}")
        raise safe_internal_error(e, "Failed to compute training effect")


# ----------------------------------------------------------------------------
# 3) GET /api/v1/health/rhr-delta
# ----------------------------------------------------------------------------
@health_router.get("/rhr-delta", tags=["Health"])
async def get_rhr_delta(current_user: dict = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Today's RHR vs 14-day baseline (excluding today). `elevated` = delta >= 3
    bpm for 2 consecutive days (today AND yesterday).
    """
    user_id = str(current_user["id"])
    db = get_supabase_db()

    try:
        # Pull the last 16 days so we can carve out today/yesterday and still
        # have ~14 baseline days.
        rows_resp = (
            db.client.table("daily_activity")
            .select("activity_date, resting_heart_rate")
            .eq("user_id", user_id)
            .order("activity_date", desc=True)
            .limit(16)
            .execute()
        )
        rows = rows_resp.data or []

        today_iso = datetime.now(timezone.utc).date().isoformat()
        yest_iso = (datetime.now(timezone.utc).date() - timedelta(days=1)).isoformat()

        today_rhr: Optional[int] = None
        yest_rhr: Optional[int] = None
        baseline_values: List[float] = []

        for r in rows:
            d = r.get("activity_date")
            rhr = r.get("resting_heart_rate")
            if rhr is None:
                continue
            if d == today_iso:
                today_rhr = int(rhr)
            elif d == yest_iso:
                yest_rhr = int(rhr)
                baseline_values.append(float(rhr))
            else:
                baseline_values.append(float(rhr))

        baseline = (
            round(sum(baseline_values) / len(baseline_values), 1)
            if baseline_values else None
        )
        delta = (
            round(float(today_rhr) - baseline, 1)
            if (today_rhr is not None and baseline is not None) else None
        )

        # Elevated: today AND yesterday both >= baseline + 3 bpm.
        elevated = False
        if (
            delta is not None
            and delta >= 3.0
            and yest_rhr is not None
            and baseline is not None
            and (float(yest_rhr) - baseline) >= 3.0
        ):
            elevated = True

        return {
            "today_rhr_bpm": today_rhr,
            "baseline_rhr_bpm": baseline,
            "delta_bpm": delta,
            "days_observed": len(baseline_values),
            "elevated": elevated,
        }
    except Exception as e:
        logger.exception("rhr-delta failed")
        raise safe_internal_error(e, "Failed to compute RHR delta")


# ----------------------------------------------------------------------------
# 4) GET /api/v1/users/me/sleep-target
# ----------------------------------------------------------------------------
def _derive_bedtime(wake_hhmm: Optional[str], target_minutes: Optional[int]) -> Optional[str]:
    """Wake (HH:MM) minus target sleep minutes → bedtime HH:MM (wraps 24h)."""
    if not wake_hhmm or not target_minutes:
        return None
    try:
        h, m = wake_hhmm.split(":")
        wake_min = int(h) * 60 + int(m)
        bed_min = (wake_min - int(target_minutes)) % (24 * 60)
        return f"{bed_min // 60:02d}:{bed_min % 60:02d}"
    except Exception:
        return None


@users_router.get("/me/sleep-target", tags=["Users"])
async def get_sleep_target(current_user: dict = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Return the user's sleep-window inputs + derived bedtime.

    Shape:
      {
        "target_sleep_minutes": int,                 # default 480
        "wake_alarm_local_time": str | null,         # HH:MM
        "derived_bedtime_local_time": str | null,    # HH:MM = wake - target
      }
    """
    try:
        db = get_supabase_db()
        res = db.client.table("users") \
            .select("target_sleep_minutes,wake_alarm_local_time") \
            .eq("id", current_user["id"]).limit(1).execute()

        target = 480
        wake = None
        if res.data:
            row = res.data[0]
            # Column may not exist yet in some envs; fall back to defaults.
            target = int(row.get("target_sleep_minutes") or 480)
            wake = row.get("wake_alarm_local_time")

        return {
            "target_sleep_minutes": target,
            "wake_alarm_local_time": wake,
            "derived_bedtime_local_time": _derive_bedtime(wake, target),
        }
    except Exception as e:
        logger.exception("sleep-target failed")
        # Never invent data — fall through to neutral defaults.
        return {
            "target_sleep_minutes": 480,
            "wake_alarm_local_time": None,
            "derived_bedtime_local_time": None,
        }


# ----------------------------------------------------------------------------
# 5) GET /api/v1/workouts/today/schedule
# ----------------------------------------------------------------------------
@workouts_router.get("/today/schedule", tags=["Workouts"])
async def get_today_schedule(
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Lightweight companion to /workouts/today — returns just the scheduled
    local-time HH:MM for today's workout so pre-workout cards can compute
    "minutes until workout" without paying the cost of the full today payload.

    Shape: {"workout_id": str | null, "scheduled_local_time": str | null}
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        # Pick today's scheduled workout in the user's local day (UTC was
        # producing tomorrow's date for CST users overnight). Column is
        # `scheduled_date` — `scheduled_for_date` doesn't exist on workouts.
        today_iso = user_today_date(request, db, user_id).isoformat()
        res = db.client.table("workouts") \
            .select("id,scheduled_local_time,scheduled_date") \
            .eq("user_id", user_id) \
            .eq("scheduled_date", today_iso) \
            .limit(1).execute()

        if not res.data:
            return {"workout_id": None, "scheduled_local_time": None}
        row = res.data[0]
        return {
            "workout_id": row.get("id"),
            "scheduled_local_time": row.get("scheduled_local_time"),
        }
    except Exception:
        logger.exception("today/schedule failed")
        return {"workout_id": None, "scheduled_local_time": None}


# ----------------------------------------------------------------------------
# 6) GET /api/v1/workouts/{workout_id}/planned-vs-actual
# ----------------------------------------------------------------------------
@workouts_router.get("/{workout_id}/planned-vs-actual", tags=["Workouts"])
async def get_planned_vs_actual(
    workout_id: str = Path(...),
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Compare planned (workouts.exercises) vs actual (workout_logs +
    performance_logs) for a completed workout.

    Shape:
      {
        "planned_sets": int | null,
        "actual_sets": int | null,
        "planned_duration_min": int | null,
        "actual_duration_min": int | null,
        "delta_pct": float | null,  # actual_sets / planned_sets * 100 - 100
      }
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Planned side — workouts.exercises_json is a JSON array; sum its set counts.
        w_res = db.client.table("workouts") \
            .select("id,user_id,exercises:exercises_json,duration_minutes") \
            .eq("id", workout_id).limit(1).execute()
        if not w_res.data:
            raise HTTPException(status_code=404, detail="Workout not found")
        w = w_res.data[0]
        if str(w.get("user_id")) != str(user_id):
            raise HTTPException(status_code=403, detail="Access denied")

        planned_sets: Optional[int] = None
        try:
            ex_list = w.get("exercises") or []
            if isinstance(ex_list, list) and ex_list:
                total = 0
                for ex in ex_list:
                    if not isinstance(ex, dict):
                        continue
                    s = ex.get("sets")
                    # Sets may be an int (count) or a list (per-set entries).
                    if isinstance(s, int):
                        total += s
                    elif isinstance(s, list):
                        total += len(s)
                planned_sets = total if total > 0 else None
        except Exception:
            planned_sets = None

        planned_duration_min: Optional[int] = (
            int(w["duration_minutes"]) if w.get("duration_minutes") else None
        )

        # Actual side — most-recent workout_log for this workout.
        log_res = db.client.table("workout_logs") \
            .select("id,total_time_seconds,completed_at") \
            .eq("workout_id", workout_id) \
            .eq("user_id", user_id) \
            .order("completed_at", desc=True).limit(1).execute()

        actual_sets: Optional[int] = None
        actual_duration_min: Optional[int] = None
        if log_res.data:
            log = log_res.data[0]
            ds = log.get("total_time_seconds")
            if ds:
                actual_duration_min = max(0, int(ds) // 60)
            log_id = log.get("id")
            if log_id:
                ps_res = db.client.table("performance_logs") \
                    .select("id", count="exact") \
                    .eq("workout_log_id", log_id).execute()
                # supabase-py exposes count on the response object.
                cnt = getattr(ps_res, "count", None)
                if cnt is None and ps_res.data is not None:
                    cnt = len(ps_res.data)
                actual_sets = int(cnt) if cnt is not None else None

        delta_pct: Optional[float] = None
        if planned_sets and actual_sets is not None and planned_sets > 0:
            delta_pct = round((actual_sets / planned_sets) * 100 - 100, 1)

        return {
            "planned_sets": planned_sets,
            "actual_sets": actual_sets,
            "planned_duration_min": planned_duration_min,
            "actual_duration_min": actual_duration_min,
            "delta_pct": delta_pct,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("planned-vs-actual failed")
        raise safe_internal_error(e, "Failed to compute planned vs actual")


# ----------------------------------------------------------------------------
# 7) GET /api/v1/wearables/battery
# ----------------------------------------------------------------------------
@wearables_router.get("/battery", tags=["Wearables"])
async def get_wearable_battery(current_user: dict = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Return latest stored wearable battery snapshot for the user, or
    {"count": 0} when none is tracked. Device-side write path is out of
    scope for this endpoint.
    """
    try:
        db = get_supabase_db()
        res = db.client.table("wearable_status") \
            .select("source,battery_pct,last_synced_at") \
            .eq("user_id", current_user["id"]).limit(1).execute()
        if not res.data:
            return {"count": 0}
        row = res.data[0]
        return {
            "count": 1,
            "source": row.get("source"),
            "battery_pct": row.get("battery_pct"),
            "last_synced_at": row.get("last_synced_at"),
        }
    except Exception:
        logger.exception("wearables/battery failed")
        return {"count": 0}


# ----------------------------------------------------------------------------
# 8) GET /api/v1/workouts/proposed-reschedule-slot?workout_id=X
# ----------------------------------------------------------------------------
@workouts_router.get("/proposed-reschedule-slot", tags=["Workouts"])
async def get_proposed_reschedule_slot(
    workout_id: str,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Suggest the next available reschedule slot in the next 7 days. Prefers
    rest days, then days with <2 workouts already planned.

    Shape: {"proposed_date": iso-date | null, "proposed_workout_id": str | null}
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Validate the workout belongs to this user (mirrors auth on other
        # /workouts endpoints; not strictly required to suggest a slot but
        # keeps the surface uniform).
        w_res = db.client.table("workouts") \
            .select("id,user_id") \
            .eq("id", workout_id).limit(1).execute()
        if not w_res.data:
            raise HTTPException(status_code=404, detail="Workout not found")
        if str(w_res.data[0].get("user_id")) != str(user_id):
            raise HTTPException(status_code=403, detail="Access denied")

        today = datetime.now(timezone.utc).date()
        end = today + timedelta(days=7)

        # Pull the next-7-day plan window. Use a generous select so we can
        # detect rest days. `workouts.is_rest_day` doesn't exist — only `type`
        # carries the rest marker (type == "rest").
        plan_res = db.client.table("workouts") \
            .select("id,scheduled_date,type") \
            .eq("user_id", user_id) \
            .gte("scheduled_date", today.isoformat()) \
            .lte("scheduled_date", end.isoformat()) \
            .execute()

        rows = plan_res.data or []
        by_date: Dict[str, List[Dict[str, Any]]] = {}
        for r in rows:
            d = r.get("scheduled_date")
            if not d:
                continue
            by_date.setdefault(str(d)[:10], []).append(r)

        # Tomorrow onward — skip today (the user is being asked to reschedule it).
        candidates: List[tuple[int, str, Optional[str]]] = []
        for i in range(1, 8):
            day = (today + timedelta(days=i)).isoformat()
            day_rows = by_date.get(day, [])
            # Rest-day preference — score 0 best.
            is_rest = any(r.get("type") == "rest" for r in day_rows)
            # Low-volume: <2 workouts already on that day (rest days excluded).
            non_rest = [r for r in day_rows if r.get("type") != "rest"]
            count = len(non_rest)
            if is_rest:
                score = 0
            elif count < 2:
                score = 1 + count  # 1 if empty, 2 if one workout
            else:
                continue  # day is already full
            # The "proposed_workout_id" lets the client know if there's an
            # existing rest-day workout row to overwrite vs creating a new one.
            existing_id = day_rows[0].get("id") if day_rows else None
            candidates.append((score, day, existing_id))

        if not candidates:
            return {"proposed_date": None, "proposed_workout_id": None}

        candidates.sort(key=lambda t: (t[0], t[1]))
        _, proposed_date, proposed_id = candidates[0]
        return {
            "proposed_date": proposed_date,
            "proposed_workout_id": proposed_id,
        }
    except HTTPException:
        raise
    except Exception:
        logger.exception("proposed-reschedule-slot failed")
        return {"proposed_date": None, "proposed_workout_id": None}
