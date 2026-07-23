"""
User history snapshot API.

Endpoint:
  GET /api/v1/user/history-snapshot?tz=America/Chicago

Returns the rich historical signal block that powers:
- Home workout-card resolver (server-side mode picking)
- Coach morning/evening brief prompts
- Pillar detail screens' momentum chips
- Chat seeding ("did I PR?" / "what did I miss this week?")

Pure SQL aggregation — zero LLM calls. 30 min in-memory TTL cache per user.

Per CLAUDE.md / feedback_no_silent_fallbacks.md:
- NO mock data
- NO fallback to wrong values — if a column doesn't exist, the field is
  simply omitted (never defaulted to a misleading zero).
- Every Supabase block is try/except wrapped individually so one failing
  table never 500s the whole endpoint.

Schema reality (verified against information_schema 2026-05-24):
  workouts.scheduled_date is timestamptz (NOT date). is_completed bool +
    completed_at timestamptz. No volume_kg/top_set/rpe columns — derived
    from exercises_json sets. template_id for similar-workout matching.
  food_logs.logged_at (UTC ts), total_calories int, protein_g/fiber_g num,
    meal_type, deleted_at.
  daily_activity.activity_date date, sleep_minutes int, sleep_start/end ts.
    NO sleep_score column — omitted from response.
  personal_records: exercise_name, weight_kg, reps, estimated_1rm_kg,
    achieved_at, muscle_group.
  hydration_logs: amount_ml int, local_date date.
  users: daily_calorie_target, daily_protein_target_g, target_water_ml.
  weight_logs: weight_kg, logged_at.
"""
from __future__ import annotations

import logging
import statistics
import time
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from zoneinfo import ZoneInfo

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import (
    local_day_bounds,
    local_range_bounds,
    resolve_timezone,
    user_today_date,
    utc_to_local_date,
)

logger = logging.getLogger("user_history_snapshot")

router = APIRouter()


# ---------------------------------------------------------------------------
# In-process TTL cache. Keyed by (user_id, local_date_iso). 30 min TTL.
# Sized small — this is per-process, eviction is lazy on read.
# ---------------------------------------------------------------------------
_CACHE_TTL_SECONDS = 30 * 60
_SNAPSHOT_CACHE: Dict[Tuple[str, str], Tuple[float, Dict[str, Any]]] = {}


def _cache_get(user_id: str, local_date_iso: str) -> Optional[Dict[str, Any]]:
    key = (user_id, local_date_iso)
    entry = _SNAPSHOT_CACHE.get(key)
    if not entry:
        return None
    inserted_at, payload = entry
    if time.time() - inserted_at > _CACHE_TTL_SECONDS:
        _SNAPSHOT_CACHE.pop(key, None)
        return None
    return payload


def _cache_put(user_id: str, local_date_iso: str, payload: Dict[str, Any]) -> None:
    _SNAPSHOT_CACHE[(user_id, local_date_iso)] = (time.time(), payload)


# ---------------------------------------------------------------------------
# Muscle group normalisation. The exercises_json uses verbose strings like
# "Chest (Pectoralis Major)" — collapse to a small canonical vocabulary the
# coach prompt + UI can show.
# ---------------------------------------------------------------------------
_MUSCLE_GROUP_ALIASES = {
    "chest": "chest", "pectoralis": "chest",
    "back": "back", "lats": "back", "latissimus": "back", "rhomboid": "back",
    "shoulder": "shoulders", "deltoid": "shoulders",
    "bicep": "biceps", "tricep": "triceps", "forearm": "forearms",
    "quad": "quads", "hamstring": "hams", "glute": "glutes",
    "calf": "calves", "calves": "calves",
    "core": "core", "abs": "core", "oblique": "core",
}


def _canonical_muscle(raw: Optional[str]) -> Optional[str]:
    if not raw:
        return None
    low = raw.lower()
    for key, canon in _MUSCLE_GROUP_ALIASES.items():
        if key in low:
            return canon
    # Body-part fallbacks (exercises_json sets body_part too)
    if "upper arm" in low:
        return "triceps"
    return None


def _exercises_iter(exercises_json: Any) -> List[Dict[str, Any]]:
    """Defensive parse — exercises_json should be a list of dicts."""
    if isinstance(exercises_json, list):
        return [e for e in exercises_json if isinstance(e, dict)]
    return []


def _derive_workout_metrics(exercises_json: Any) -> Dict[str, Any]:
    """Sum tonnage and find top set across exercises_json sets.

    Each exercise typically has `set_targets: [{target_weight_kg, target_reps,...}]`.
    Top set = max estimated 1RM via Epley (w * (1 + reps/30)).
    """
    total_volume_kg = 0.0
    top_set: Optional[Dict[str, Any]] = None
    top_est_1rm = -1.0
    for ex in _exercises_iter(exercises_json):
        sets = ex.get("set_targets") or []
        ex_name = ex.get("name")
        for s in sets:
            if not isinstance(s, dict):
                continue
            try:
                w = float(s.get("target_weight_kg") or s.get("weight_kg") or 0)
                r = int(s.get("target_reps") or s.get("reps") or 0)
            except (TypeError, ValueError):
                continue
            if w > 0 and r > 0:
                total_volume_kg += w * r
                est_1rm = w * (1.0 + r / 30.0)
                if est_1rm > top_est_1rm:
                    top_est_1rm = est_1rm
                    top_set = {
                        "exercise": ex_name,
                        "value": f"{int(w) if w.is_integer() else round(w, 1)}x{r}",
                    }
    out: Dict[str, Any] = {}
    if total_volume_kg > 0:
        out["volume_kg"] = round(total_volume_kg)
    if top_set:
        out["top_set"] = top_set
    return out


def _hhmm(dt: Optional[datetime], tz: ZoneInfo) -> Optional[str]:
    if not dt:
        return None
    try:
        if isinstance(dt, str):
            dt = datetime.fromisoformat(dt.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        local = dt.astimezone(tz)
        return local.strftime("%H:%M")
    except Exception:
        return None


def _direction(curr: Optional[float], prev: Optional[float], threshold: float = 0.05) -> str:
    """Compare two periods. threshold = relative change deemed material."""
    if curr is None or prev is None or prev == 0:
        return "unknown"
    delta = (curr - prev) / abs(prev)
    if delta > threshold:
        return "up"
    if delta < -threshold:
        return "down"
    return "stable"


# ---------------------------------------------------------------------------
# Per-section collectors. Each catches its own exception so a single failure
# doesn't 500 the endpoint.
# ---------------------------------------------------------------------------
def _yesterday_block(sb, user_id: str, yesterday_iso: str, tz: ZoneInfo,
                     calorie_target: Optional[int], protein_target: Optional[float],
                     hydration_target_cups: Optional[int]) -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    # Workout
    try:
        # scheduled_date is timestamptz; match by date prefix.
        start_iso = f"{yesterday_iso}T00:00:00+00:00"
        end_iso = f"{yesterday_iso}T23:59:59+00:00"
        wr = sb.client.table("workouts").select(
            "id, name, exercises_json, completed_at, duration_minutes, "
            "is_completed, scheduled_date"
        ).eq("user_id", user_id).gte(
            "scheduled_date", start_iso
        ).lte("scheduled_date", end_iso).limit(1).execute()
        if wr and wr.data:
            row = wr.data[0]
            completed = bool(row.get("completed_at")) or bool(row.get("is_completed"))
            w_out: Dict[str, Any] = {
                "scheduled": True,
                "completed": completed,
                "name": row.get("name"),
                "duration_min": row.get("duration_minutes"),
            }
            metrics = _derive_workout_metrics(row.get("exercises_json"))
            w_out.update(metrics)
            # PRs achieved during this workout (best-effort).
            try:
                pr = sb.client.table("personal_records").select(
                    "exercise_name, weight_kg, reps, achieved_at"
                ).eq("user_id", user_id).eq("workout_id", row["id"]).execute()
                w_out["new_prs"] = [
                    {
                        "exercise": p.get("exercise_name"),
                        "value": f"{int(p['weight_kg']) if p.get('weight_kg') is not None else '?'}x{p.get('reps') or '?'}",
                        # achieved_at is UTC — slicing it would show an evening
                        # PR as the next day for western users.
                        "date": utc_to_local_date(p.get("achieved_at"), tz.key),
                    }
                    for p in (pr.data or [])
                ]
            except Exception as e:
                logger.warning(f"[history_snapshot] yday PR lookup failed: {e}")
            out["workout"] = w_out
        else:
            out["workout"] = {"scheduled": False, "completed": False}
    except Exception as e:
        logger.warning(f"[history_snapshot] yesterday workout failed: {e}")

    # Nutrition
    try:
        # logged_at is UTC timestamptz — the window has to be the user's LOCAL
        # day mapped into UTC, half-open. Gluing the local date onto "+00:00"
        # spans 20:00 the previous evening → 19:59 for a UTC-4 user, which
        # counted last night's dinners as this day's calories.
        start_iso, end_iso = local_day_bounds(yesterday_iso, tz.key)
        fl = sb.client.table("food_logs").select(
            "total_calories, protein_g, fiber_g, logged_at, meal_type, deleted_at"
        ).eq("user_id", user_id).gte(
            "logged_at", start_iso
        ).lt("logged_at", end_iso).is_("deleted_at", "null").execute()
        rows = fl.data or []
        if rows:
            cal = sum(int(r.get("total_calories") or 0) for r in rows)
            prot = sum(float(r.get("protein_g") or 0) for r in rows)
            fib = sum(float(r.get("fiber_g") or 0) for r in rows)
            times = sorted([r.get("logged_at") for r in rows if r.get("logged_at")])
            first_hhmm = _hhmm(times[0], tz) if times else None
            last_hhmm = _hhmm(times[-1], tz) if times else None
            nut: Dict[str, Any] = {
                "calories_logged": cal,
                "protein_logged_g": round(prot, 1),
                "fiber_g": round(fib, 1),
                "meals_logged_count": len(rows),
                "first_meal_at": first_hhmm,
                "last_meal_at": last_hhmm,
            }
            if calorie_target:
                nut["calories_target"] = calorie_target
            if protein_target:
                nut["protein_target_g"] = float(protein_target)
            out["nutrition"] = nut
        else:
            out["nutrition"] = {"meals_logged_count": 0}
    except Exception as e:
        logger.warning(f"[history_snapshot] yesterday nutrition failed: {e}")

    # Sleep (from daily_activity; NO score column — omit `score` field)
    try:
        da = sb.client.table("daily_activity").select(
            "sleep_minutes, sleep_start, sleep_end, activity_date"
        ).eq("user_id", user_id).eq(
            "activity_date", yesterday_iso
        ).maybe_single().execute()
        if da and da.data and (da.data.get("sleep_minutes") or 0) > 0:
            sleep_block: Dict[str, Any] = {
                "minutes": int(da.data["sleep_minutes"]),
            }
            bedtime = _hhmm(da.data.get("sleep_start"), tz)
            wake = _hhmm(da.data.get("sleep_end"), tz)
            if bedtime:
                sleep_block["bedtime"] = bedtime
            if wake:
                sleep_block["wake"] = wake
            out["sleep"] = sleep_block
    except Exception as e:
        logger.warning(f"[history_snapshot] yesterday sleep failed: {e}")

    # Hydration
    try:
        hr = sb.client.table("hydration_logs").select(
            "amount_ml, drink_type"
        ).eq("user_id", user_id).eq("local_date", yesterday_iso).execute()
        if hr and hr.data:
            # Convert ml to ~8oz cups (≈240ml) for the §1b.7 contract.
            total_ml = sum(int(r.get("amount_ml") or 0) for r in (hr.data or []))
            cups = round(total_ml / 240.0)
            hyd: Dict[str, Any] = {"cups": cups, "ml": total_ml}
            if hydration_target_cups:
                hyd["goal"] = hydration_target_cups
            out["hydration"] = hyd
    except Exception as e:
        logger.warning(f"[history_snapshot] yesterday hydration failed: {e}")

    return out


def _seven_day_patterns(sb, user_id: str, today_local: date, tz: ZoneInfo,
                        calorie_target: Optional[int],
                        protein_target: Optional[float],
                        hydration_target_cups: Optional[int]) -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    start_local = today_local - timedelta(days=7)
    start_iso = f"{start_local.isoformat()}T00:00:00+00:00"
    end_iso = f"{today_local.isoformat()}T00:00:00+00:00"

    # Workout completion rate over last 7d (scheduled workouts only).
    try:
        wr = sb.client.table("workouts").select(
            "id, completed_at, is_completed, scheduled_date"
        ).eq("user_id", user_id).gte(
            "scheduled_date", start_iso
        ).lt("scheduled_date", end_iso).execute()
        rows = wr.data or []
        if rows:
            done = sum(1 for r in rows
                       if r.get("completed_at") or r.get("is_completed"))
            out["workout_completion_rate"] = round(done / len(rows), 2)
            out["workouts_scheduled_7d"] = len(rows)
            out["workouts_completed_7d"] = done
    except Exception as e:
        logger.warning(f"[history_snapshot] 7d workout failed: {e}")

    # Food log aggregates over last 7d.
    try:
        # logged_at is UTC timestamptz; the shared start_iso/end_iso above are
        # local dates glued to "+00:00" and are shifted by the user's offset.
        # The /7.0 denominators below only hold if this window is exactly the
        # seven whole LOCAL days [today-7, today), so derive it from the zone.
        food_start_iso, food_end_iso = local_range_bounds(
            start_local.isoformat(),
            (today_local - timedelta(days=1)).isoformat(),
            tz.key,
        )
        fl = sb.client.table("food_logs").select(
            "total_calories, protein_g, logged_at, meal_type, deleted_at"
        ).eq("user_id", user_id).gte(
            "logged_at", food_start_iso
        ).lt("logged_at", food_end_iso).is_("deleted_at", "null").execute()
        rows = fl.data or []
        # Bucket per local date.
        by_day: Dict[str, Dict[str, Any]] = defaultdict(
            lambda: {"cal": 0, "protein": 0.0, "meals": Counter()}
        )
        for r in rows:
            ts = r.get("logged_at")
            if not ts:
                continue
            try:
                dt = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(tz)
            except Exception:
                continue
            d = dt.date().isoformat()
            by_day[d]["cal"] += int(r.get("total_calories") or 0)
            by_day[d]["protein"] += float(r.get("protein_g") or 0)
            mt = (r.get("meal_type") or "").lower()
            if mt:
                by_day[d]["meals"][mt] += 1
        days = sorted(by_day.keys())
        # Breakfast log rate = days with a breakfast / 7.
        if days:
            breakfast_days = sum(
                1 for d in days if by_day[d]["meals"].get("breakfast")
            )
            out["breakfast_log_rate"] = round(breakfast_days / 7.0, 2)
            # Recurring skipped meal: which meal type appears in <30% of days.
            for slot in ("breakfast", "lunch", "dinner"):
                rate = sum(1 for d in days if by_day[d]["meals"].get(slot)) / 7.0
                if rate < 0.3:
                    out.setdefault("recurring_skipped_meal", slot)
                    break
            if calorie_target:
                avg_cal = statistics.mean(by_day[d]["cal"] for d in days)
                out["avg_calories_vs_target"] = round(avg_cal / calorie_target, 2)
            if protein_target:
                avg_pro = statistics.mean(by_day[d]["protein"] for d in days)
                out["avg_protein_vs_target"] = round(avg_pro / float(protein_target), 2)
                hit_days = sum(
                    1 for d in days
                    if by_day[d]["protein"] >= float(protein_target) * 0.95
                )
                out["protein_target_hit_rate"] = round(hit_days / 7.0, 2)
    except Exception as e:
        logger.warning(f"[history_snapshot] 7d food failed: {e}")

    # Sleep patterns from daily_activity.
    try:
        da = sb.client.table("daily_activity").select(
            "sleep_minutes, sleep_start, sleep_end, activity_date"
        ).eq("user_id", user_id).gte(
            "activity_date", start_local.isoformat()
        ).lt("activity_date", today_local.isoformat()).execute()
        rows = [r for r in (da.data or []) if (r.get("sleep_minutes") or 0) > 0]
        if rows:
            bedtimes_minutes = []
            wakes_minutes = []
            for r in rows:
                bt = r.get("sleep_start")
                wk = r.get("sleep_end")
                if bt:
                    try:
                        dt = datetime.fromisoformat(bt.replace("Z", "+00:00")).astimezone(tz)
                        # Normalise: a bedtime past midnight wraps; treat as hour+24.
                        m = dt.hour * 60 + dt.minute
                        if dt.hour < 12:  # post-midnight bedtime
                            m += 24 * 60
                        bedtimes_minutes.append(m)
                    except Exception:
                        pass
                if wk:
                    try:
                        dt = datetime.fromisoformat(wk.replace("Z", "+00:00")).astimezone(tz)
                        wakes_minutes.append(dt.hour * 60 + dt.minute)
                    except Exception:
                        pass
            if bedtimes_minutes:
                avg_bt = int(statistics.mean(bedtimes_minutes)) % (24 * 60)
                out["avg_bedtime"] = f"{avg_bt // 60:02d}:{avg_bt % 60:02d}"
                if len(bedtimes_minutes) >= 2:
                    out["bedtime_consistency_minutes"] = int(
                        statistics.pstdev(bedtimes_minutes)
                    )
            if wakes_minutes:
                avg_wk = int(statistics.mean(wakes_minutes))
                out["avg_wake"] = f"{avg_wk // 60:02d}:{avg_wk % 60:02d}"
    except Exception as e:
        logger.warning(f"[history_snapshot] 7d sleep failed: {e}")

    # Hydration goal hit rate.
    if hydration_target_cups:
        try:
            hr = sb.client.table("hydration_logs").select(
                "amount_ml, local_date"
            ).eq("user_id", user_id).gte(
                "local_date", start_local.isoformat()
            ).lt("local_date", today_local.isoformat()).execute()
            by_day = defaultdict(int)
            for r in (hr.data or []):
                by_day[r.get("local_date")] += int(r.get("amount_ml") or 0)
            target_ml = hydration_target_cups * 240
            hit = sum(1 for v in by_day.values() if v >= target_ml)
            out["water_goal_hit_rate"] = round(hit / 7.0, 2)
        except Exception as e:
            logger.warning(f"[history_snapshot] 7d hydration failed: {e}")

    return out


def _recurring_skipped_muscle_groups(workouts_7d: List[Dict[str, Any]],
                                     days_since: Dict[str, int]) -> List[str]:
    """A muscle group is 'recurring skipped' if it hasn't been hit in 7+ days."""
    return sorted([m for m, d in days_since.items() if d >= 7])


def _strain_volume_signals(sb, user_id: str, today_local: date) -> Dict[str, Any]:
    """Per-day completed-workout volume across the last 30 days.

    Powers the Strain Coach card on the home screen (see
    `mobile/flutter/lib/services/strain_recommendation_service.dart`).

    Output fields (all units kg-reps):
      - `yesterday_volume_kg`     — sum of `weight_kg * reps` across all sets
        completed on the user's local "yesterday". 0.0 if no completed workout.
      - `volume_30d_median_kg`    — median across ONLY non-zero days in the
        30d window. 0.0 if there's no history. Using non-zero-only median
        prevents rest days from dragging the baseline to zero (which would
        falsely classify every workout as "hard").
      - `prior_two_days_hard_count` — count of (yesterday, day-before-yesterday)
        where that day's volume >= 1.2 * median. 0 / 1 / 2.

    NO `workout_sets` table exists in this schema (verified 2026-05-24 via
    information_schema). Volume is derived from `workouts.exercises_json`
    using `_derive_workout_metrics`, which is the canonical path already
    used by `_thirty_day_trends` for the 30d-vs-60d volume direction.

    Per CLAUDE.md / feedback_no_silent_fallbacks.md: on query failure we
    return zeros so the client can degrade naturally — the algorithm reads
    `volume_30d_median_kg == 0` as "no baseline, skip the strain branch".
    """
    out: Dict[str, Any] = {
        "yesterday_volume_kg": 0.0,
        "volume_30d_median_kg": 0.0,
        "prior_two_days_hard_count": 0,
    }
    try:
        # 30d lookback window: [today - 30, today). Yesterday = today - 1.
        # We pull one extra hour of buffer at each end to be safe against any
        # tz-stored-in-utc edge rows. Filtering to completed workouts only.
        window_start = today_local - timedelta(days=30)
        window_start_iso = f"{window_start.isoformat()}T00:00:00+00:00"
        window_end_iso = f"{today_local.isoformat()}T00:00:00+00:00"
        wr = sb.client.table("workouts").select(
            "exercises_json, scheduled_date, completed_at, is_completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", window_start_iso
        ).lt("scheduled_date", window_end_iso).execute()

        # Bucket per-day volume (date prefix of scheduled_date, which is
        # timestamptz). Multiple workouts on the same day sum together.
        by_day: Dict[str, float] = defaultdict(float)
        for r in (wr.data or []):
            if not (r.get("completed_at") or r.get("is_completed")):
                continue
            sched = (r.get("scheduled_date") or "")[:10]
            if not sched:
                continue
            metrics = _derive_workout_metrics(r.get("exercises_json"))
            v = metrics.get("volume_kg") or 0
            if v:
                by_day[sched] += float(v)

        yesterday_iso = (today_local - timedelta(days=1)).isoformat()
        day_before_iso = (today_local - timedelta(days=2)).isoformat()

        yvol = float(by_day.get(yesterday_iso, 0.0))
        out["yesterday_volume_kg"] = round(yvol, 1)

        # Median over non-zero days only — rest days shouldn't deflate the baseline.
        non_zero_vols = [v for v in by_day.values() if v > 0]
        if non_zero_vols:
            median_val = float(statistics.median(non_zero_vols))
            out["volume_30d_median_kg"] = round(median_val, 1)

            # Hard day = volume >= 1.2 * median (matches strain algo threshold).
            threshold = median_val * 1.2
            hard_count = 0
            if yvol >= threshold:
                hard_count += 1
            day_before_vol = float(by_day.get(day_before_iso, 0.0))
            if day_before_vol >= threshold:
                hard_count += 1
            out["prior_two_days_hard_count"] = hard_count
    except Exception as e:
        logger.warning(f"[history_snapshot] strain volume signals failed: {e}")
    return out


def _thirty_day_trends(sb, user_id: str, today_local: date,
                       tz: ZoneInfo) -> Dict[str, Any]:
    """Compare last 30d vs prior 30d for volume/sleep/weight."""
    out: Dict[str, Any] = {}
    end_iso = f"{today_local.isoformat()}T00:00:00+00:00"
    p1_start = today_local - timedelta(days=30)
    p1_start_iso = f"{p1_start.isoformat()}T00:00:00+00:00"
    p2_start = today_local - timedelta(days=60)
    p2_start_iso = f"{p2_start.isoformat()}T00:00:00+00:00"

    # Volume trend from completed workouts.
    try:
        wr = sb.client.table("workouts").select(
            "exercises_json, scheduled_date, completed_at, is_completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", p2_start_iso
        ).lt("scheduled_date", end_iso).execute()
        vol_p1 = 0.0
        vol_p2 = 0.0
        for r in (wr.data or []):
            if not (r.get("completed_at") or r.get("is_completed")):
                continue
            sched = r.get("scheduled_date") or ""
            metrics = _derive_workout_metrics(r.get("exercises_json"))
            v = metrics.get("volume_kg") or 0
            if sched >= p1_start_iso:
                vol_p1 += v
            else:
                vol_p2 += v
        if vol_p1 or vol_p2:
            out["volume_direction"] = _direction(vol_p1, vol_p2)
            if vol_p2 > 0:
                out["volume_change_pct"] = round((vol_p1 - vol_p2) / vol_p2, 2)
    except Exception as e:
        logger.warning(f"[history_snapshot] 30d volume failed: {e}")

    # Weight trend from weight_logs.
    try:
        # logged_at is UTC timestamptz — the shared *_iso bounds above are local
        # dates glued to "+00:00", so derive the 60-local-day window from the
        # user's zone instead, and split the two periods on the LOCAL day a row
        # belongs to (an evening weigh-in must not fall into the prior period).
        w_start_iso, w_end_iso = local_range_bounds(
            p2_start.isoformat(),
            (today_local - timedelta(days=1)).isoformat(),
            tz.key,
        )
        wl = sb.client.table("weight_logs").select(
            "weight_kg, logged_at"
        ).eq("user_id", user_id).gte(
            "logged_at", w_start_iso
        ).lt("logged_at", w_end_iso).order("logged_at").execute()
        rows = wl.data or []
        p1_split = p1_start.isoformat()
        p1 = [float(r["weight_kg"]) for r in rows
              if r.get("weight_kg") is not None
              and utc_to_local_date(r.get("logged_at"), tz.key) >= p1_split]
        p2 = [float(r["weight_kg"]) for r in rows
              if r.get("weight_kg") is not None
              and utc_to_local_date(r.get("logged_at"), tz.key) < p1_split]
        if p1 and p2:
            avg_p1 = statistics.mean(p1)
            avg_p2 = statistics.mean(p2)
            change = round(avg_p1 - avg_p2, 1)
            out["weight_change_kg"] = change
            if abs(change) < 0.5:
                out["weight_direction"] = "stable"
            elif change > 0:
                out["weight_direction"] = "gaining"
            else:
                out["weight_direction"] = "losing"
    except Exception as e:
        logger.warning(f"[history_snapshot] 30d weight failed: {e}")

    # Sleep minutes trend (no score column — use minutes).
    try:
        da = sb.client.table("daily_activity").select(
            "sleep_minutes, activity_date"
        ).eq("user_id", user_id).gte(
            "activity_date", p2_start.isoformat()
        ).lt("activity_date", today_local.isoformat()).execute()
        p1m, p2m = [], []
        for r in (da.data or []):
            sm = r.get("sleep_minutes")
            if not sm:
                continue
            ad = r.get("activity_date") or ""
            if ad >= p1_start.isoformat():
                p1m.append(int(sm))
            else:
                p2m.append(int(sm))
        if p1m and p2m:
            avg_p1 = statistics.mean(p1m)
            avg_p2 = statistics.mean(p2m)
            out["sleep_minutes_direction"] = _direction(avg_p1, avg_p2, threshold=0.03)
            out["sleep_minutes_change"] = int(avg_p1 - avg_p2)
    except Exception as e:
        logger.warning(f"[history_snapshot] 30d sleep failed: {e}")

    return out


def _prs_since(sb, user_id: str, since_iso: str, until_iso: str,
               tz_str: str) -> List[Dict[str, Any]]:
    """PRs inside the half-open UTC window [since_iso, until_iso).

    personal_records.achieved_at is written as a naive ``datetime.now()`` by
    personal_records_service, i.e. UTC on our servers — so it is filtered and
    bucketed here as a UTC instant.
    """
    try:
        pr = sb.client.table("personal_records").select(
            "exercise_name, weight_kg, reps, estimated_1rm_kg, achieved_at"
        ).eq("user_id", user_id).gte(
            "achieved_at", since_iso
        ).lt("achieved_at", until_iso).order(
            "achieved_at", desc=True
        ).limit(50).execute()
        out = []
        for p in (pr.data or []):
            w = p.get("weight_kg")
            r = p.get("reps")
            if w is not None and r is not None:
                value = f"{int(w) if float(w).is_integer() else round(float(w), 1)}x{r}"
            elif p.get("estimated_1rm_kg") is not None:
                value = f"e1RM {round(float(p['estimated_1rm_kg']), 1)}kg"
            else:
                value = None
            out.append({
                "exercise": p.get("exercise_name"),
                "value": value,
                # Local day, not the UTC prefix — a 9pm PR belongs to that night.
                "date": utc_to_local_date(p.get("achieved_at"), tz_str),
            })
        return out
    except Exception as e:
        logger.warning(f"[history_snapshot] prs lookup failed: {e}")
        return []


def _today_workout_row(sb, user_id: str, today_iso: str) -> Optional[Dict[str, Any]]:
    try:
        start_iso = f"{today_iso}T00:00:00+00:00"
        end_iso = f"{today_iso}T23:59:59+00:00"
        wr = sb.client.table("workouts").select(
            "id, name, template_id, exercises_json, scheduled_date"
        ).eq("user_id", user_id).gte(
            "scheduled_date", start_iso
        ).lte("scheduled_date", end_iso).limit(1).execute()
        if wr and wr.data:
            return wr.data[0]
    except Exception as e:
        logger.warning(f"[history_snapshot] today workout failed: {e}")
    return None


def _last_similar_workout(sb, user_id: str, today_row: Optional[Dict[str, Any]],
                          today_iso: str) -> Optional[Dict[str, Any]]:
    """Match today's workout against past 90d by template_id (or name fallback)."""
    if not today_row:
        return None
    try:
        ninety_iso = f"{(date.fromisoformat(today_iso) - timedelta(days=90)).isoformat()}T00:00:00+00:00"
        today_start_iso = f"{today_iso}T00:00:00+00:00"
        q = sb.client.table("workouts").select(
            "id, name, exercises_json, completed_at, is_completed, scheduled_date, "
            "duration_minutes, template_id"
        ).eq("user_id", user_id).gte(
            "scheduled_date", ninety_iso
        ).lt("scheduled_date", today_start_iso).order("scheduled_date", desc=True)
        if today_row.get("template_id"):
            q = q.eq("template_id", today_row["template_id"])
        else:
            q = q.eq("name", today_row.get("name") or "")
        res = q.limit(1).execute()
        if not (res and res.data):
            return None
        row = res.data[0]
        completed = bool(row.get("completed_at") or row.get("is_completed"))
        metrics = _derive_workout_metrics(row.get("exercises_json"))
        out = {
            "workout_id": row.get("id"),
            "date": (row.get("scheduled_date") or "")[:10],
            "completion": 1.0 if completed else 0.0,
            "duration_min": row.get("duration_minutes"),
        }
        out.update(metrics)
        return out
    except Exception as e:
        logger.warning(f"[history_snapshot] last similar workout failed: {e}")
        return None


def _days_since_muscle_group(sb, user_id: str, today_iso: str) -> Dict[str, int]:
    """Scan last 30d of completed workouts, parse exercises_json, derive
    days-since for each canonical muscle group."""
    out: Dict[str, int] = {}
    try:
        thirty_iso = f"{(date.fromisoformat(today_iso) - timedelta(days=30)).isoformat()}T00:00:00+00:00"
        today_start_iso = f"{today_iso}T00:00:00+00:00"
        wr = sb.client.table("workouts").select(
            "exercises_json, scheduled_date, completed_at, is_completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", thirty_iso
        ).lt("scheduled_date", today_start_iso).order(
            "scheduled_date", desc=True
        ).execute()
        today_d = date.fromisoformat(today_iso)
        latest_by_muscle: Dict[str, str] = {}
        for r in (wr.data or []):
            if not (r.get("completed_at") or r.get("is_completed")):
                continue
            sched = (r.get("scheduled_date") or "")[:10]
            if not sched:
                continue
            for ex in _exercises_iter(r.get("exercises_json")):
                m = _canonical_muscle(ex.get("muscle_group") or ex.get("body_part"))
                if not m:
                    continue
                if m not in latest_by_muscle or sched > latest_by_muscle[m]:
                    latest_by_muscle[m] = sched
        for m, sched in latest_by_muscle.items():
            try:
                out[m] = (today_d - date.fromisoformat(sched)).days
            except Exception:
                continue
    except Exception as e:
        logger.warning(f"[history_snapshot] days_since_muscle failed: {e}")
    return out


def _pr_opportunity(sb, user_id: str,
                    today_row: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    """For each primary exercise in today's workout, look up the user's best
    top set in personal_records and target +5% weight (rep-matched)."""
    if not today_row:
        return None
    try:
        names = []
        for ex in _exercises_iter(today_row.get("exercises_json"))[:8]:
            n = ex.get("name")
            if n:
                names.append(n)
        if not names:
            return None
        # Pull current bests for these exercise names.
        pr = sb.client.table("personal_records").select(
            "exercise_name, weight_kg, reps, estimated_1rm_kg, achieved_at"
        ).eq("user_id", user_id).in_("exercise_name", names).order(
            "achieved_at", desc=True
        ).limit(50).execute()
        best: Dict[str, Dict[str, Any]] = {}
        for p in (pr.data or []):
            n = p.get("exercise_name")
            if not n:
                continue
            cand_1rm = p.get("estimated_1rm_kg")
            if cand_1rm is None and p.get("weight_kg") and p.get("reps"):
                cand_1rm = float(p["weight_kg"]) * (1.0 + int(p["reps"]) / 30.0)
            if cand_1rm is None:
                continue
            cur = best.get(n)
            if not cur or (cur.get("e1rm") or 0) < cand_1rm:
                best[n] = {
                    "weight_kg": p.get("weight_kg"),
                    "reps": p.get("reps"),
                    "e1rm": cand_1rm,
                }
        if not best:
            return None
        # Pick the exercise with the strongest baseline (most recent + heaviest).
        pick_name, pick = max(best.items(), key=lambda kv: kv[1].get("e1rm") or 0)
        w = pick.get("weight_kg")
        r = pick.get("reps")
        if not w or not r:
            return None
        target_w = round(float(w) * 1.05 * 2) / 2  # round to nearest 0.5kg
        return {
            "exercise": pick_name,
            "current_top": f"{int(w) if float(w).is_integer() else round(float(w), 1)}x{r}",
            "target": f"{int(target_w) if target_w.is_integer() else target_w}x{max(int(r) - 2, 1)}",
            "confidence": "medium",
        }
    except Exception as e:
        logger.warning(f"[history_snapshot] pr_opportunity failed: {e}")
        return None


def _open_loops(seven: Dict[str, Any], days_since: Dict[str, int],
                thirty: Dict[str, Any]) -> List[str]:
    out: List[str] = []
    if seven.get("recurring_skipped_meal"):
        slot = seven["recurring_skipped_meal"]
        rate = seven.get("breakfast_log_rate") if slot == "breakfast" else None
        hit_count = int(round((rate or 0) * 7)) if rate is not None else None
        if hit_count is not None:
            out.append(f"Logged {slot} only {hit_count} of last 7 days")
        else:
            out.append(f"{slot.capitalize()} skipped most days this week")
    overdue = sorted([(m, d) for m, d in days_since.items() if d >= 7],
                     key=lambda kv: -kv[1])
    for muscle, days in overdue[:2]:
        out.append(f"{muscle.capitalize()} unworked for {days} days")
    if thirty.get("sleep_minutes_direction") == "down":
        delta = abs(thirty.get("sleep_minutes_change") or 0)
        if delta >= 10:
            out.append(f"Sleep down {delta} min/night across the month")
    completion = seven.get("workout_completion_rate")
    scheduled = seven.get("workouts_scheduled_7d")
    if completion is not None and scheduled and completion < 0.6:
        out.append(
            f"Workout completion at {int(completion * 100)}% this week"
        )
    return out


def _wins_this_week(seven: Dict[str, Any],
                    prs_7d: List[Dict[str, Any]],
                    thirty: Dict[str, Any]) -> List[str]:
    out: List[str] = []
    rate = seven.get("protein_target_hit_rate")
    if rate is not None and rate >= 0.7:
        out.append(f"Hit protein {int(round(rate * 7))} of 7 days")
    for pr in prs_7d[:2]:
        ex = pr.get("exercise")
        v = pr.get("value")
        if ex and v:
            out.append(f"PR {ex} {v}")
    cr = seven.get("workout_completion_rate")
    if cr is not None and cr >= 0.85:
        out.append(f"Closed {int(round(cr * 100))}% of scheduled workouts")
    if thirty.get("volume_direction") == "up":
        pct = thirty.get("volume_change_pct")
        if pct is not None:
            out.append(f"Volume up {int(round(pct * 100))}% vs prior month")
    return out


# ---------------------------------------------------------------------------
# Response model — fields are intentionally optional to mirror the
# graceful-omission pattern used by collectors.
# ---------------------------------------------------------------------------
class HistorySnapshotResponse(BaseModel):
    local_date: str
    tz: str
    yesterday: Dict[str, Any] = {}
    seven_day_patterns: Dict[str, Any] = {}
    thirty_day_trends: Dict[str, Any] = {}
    prs_last_7d: List[Dict[str, Any]] = []
    prs_last_30d: List[Dict[str, Any]] = []
    last_similar_workout: Optional[Dict[str, Any]] = None
    days_since_muscle_group: Dict[str, int] = {}
    pr_opportunity_today: Optional[Dict[str, Any]] = None
    open_loops: List[str] = []
    wins_this_week: List[str] = []
    # Strain Coach signals (per-day volume aggregates derived from
    # `workouts.exercises_json`). See `_strain_volume_signals` for semantics.
    # Top-level (not nested) so the Flutter `UserHistorySnapshot.fromJson`
    # parser can read them with a single `json['yesterday_volume_kg']` lookup.
    yesterday_volume_kg: float = 0.0
    volume_30d_median_kg: float = 0.0
    prior_two_days_hard_count: int = 0
    generated_at: str
    cached: bool = False


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------
@router.get("/history-snapshot", response_model=HistorySnapshotResponse)
async def history_snapshot(
    request: Request,
    tz: Optional[str] = Query(None, description="IANA tz override; header X-User-Timezone wins"),
    refresh: bool = Query(False, description="Force regenerate, bypassing 30 min cache"),
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        tz_resolved = resolve_timezone(request, sb, user_id)
        if tz_resolved == "UTC" and tz:
            tz_resolved = tz
        try:
            tzinfo = ZoneInfo(tz_resolved)
        except Exception:
            tzinfo = ZoneInfo("UTC")
            tz_resolved = "UTC"

        today_local = user_today_date(request, sb, user_id)
        today_iso = today_local.isoformat()
        yesterday_iso = (today_local - timedelta(days=1)).isoformat()

        # ---- Cache hit? ---------------------------------------------------
        if not refresh:
            cached = _cache_get(user_id, today_iso)
            if cached is not None:
                payload = dict(cached)
                payload["cached"] = True
                return HistorySnapshotResponse(**payload)

        # ---- User targets (best-effort) -----------------------------------
        calorie_target: Optional[int] = None
        protein_target: Optional[float] = None
        hydration_target_cups: Optional[int] = None
        try:
            ur = sb.client.table("users").select(
                "daily_calorie_target, daily_protein_target_g, target_water_ml"
            ).eq("id", user_id).maybe_single().execute()
            if ur and ur.data:
                calorie_target = ur.data.get("daily_calorie_target")
                pt = ur.data.get("daily_protein_target_g")
                protein_target = float(pt) if pt is not None else None
                wt = ur.data.get("target_water_ml")
                if wt:
                    hydration_target_cups = max(1, round(float(wt) / 240.0))
        except Exception as e:
            logger.warning(f"[history_snapshot] users targets failed: {e}")

        # ---- Assemble each block (each is internally try/except wrapped) --
        yesterday = _yesterday_block(
            sb, user_id, yesterday_iso, tzinfo,
            calorie_target, protein_target, hydration_target_cups,
        )
        seven = _seven_day_patterns(
            sb, user_id, today_local, tzinfo,
            calorie_target, protein_target, hydration_target_cups,
        )
        thirty = _thirty_day_trends(sb, user_id, today_local, tzinfo)

        # PR lookback windows are LOCAL calendar days (last 7 / last 30 through
        # the end of today), converted to UTC — achieved_at is stored in UTC.
        prs_7d_since, prs_until = local_range_bounds(
            (today_local - timedelta(days=7)).isoformat(), today_iso, tz_resolved
        )
        prs_30d_since, _ = local_day_bounds(
            (today_local - timedelta(days=30)).isoformat(), tz_resolved
        )
        prs_7d = _prs_since(sb, user_id, prs_7d_since, prs_until, tz_resolved)
        prs_30d = _prs_since(sb, user_id, prs_30d_since, prs_until, tz_resolved)

        today_row = _today_workout_row(sb, user_id, today_iso)
        similar = _last_similar_workout(sb, user_id, today_row, today_iso)
        days_since = _days_since_muscle_group(sb, user_id, today_iso)
        # Fold "recurring skipped muscle groups" into the seven_day block now
        # that we have the muscle-group history scan.
        recurring_skipped = _recurring_skipped_muscle_groups([], days_since)
        if recurring_skipped:
            seven["recurring_skipped_muscle_groups"] = recurring_skipped

        pr_opp = _pr_opportunity(sb, user_id, today_row)
        open_loops = _open_loops(seven, days_since, thirty)
        wins = _wins_this_week(seven, prs_7d, thirty)
        # Strain signals: per-day completed-workout volume aggregates that
        # feed the home-screen Strain Coach card (yesterday vs 30d median).
        strain = _strain_volume_signals(sb, user_id, today_local)

        payload: Dict[str, Any] = {
            "local_date": today_iso,
            "tz": tz_resolved,
            "yesterday": yesterday,
            "seven_day_patterns": seven,
            "thirty_day_trends": thirty,
            "prs_last_7d": prs_7d,
            "prs_last_30d": prs_30d,
            "last_similar_workout": similar,
            "days_since_muscle_group": days_since,
            "pr_opportunity_today": pr_opp,
            "open_loops": open_loops,
            "wins_this_week": wins,
            "yesterday_volume_kg": strain["yesterday_volume_kg"],
            "volume_30d_median_kg": strain["volume_30d_median_kg"],
            "prior_two_days_hard_count": strain["prior_two_days_hard_count"],
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "cached": False,
        }

        _cache_put(user_id, today_iso, payload)
        return HistorySnapshotResponse(**payload)
    except Exception as e:
        raise safe_internal_error(e, "user_history_snapshot")
