"""Weekly progress report service.

Pure rollup for the Monday-morning "weekly stats" email (the Google-Health-style
report). Owns NO transport — `_job_weekly_summary` calls `compute_weekly_progress`,
then hands the result to `send_weekly_summary` which renders it with the shared
signature template (`email_signature_template.py`).

Design notes
------------
* Window is the most recent complete **Sun–Sat** user-local week (per
  `feedback_user_local_time_only`). Prior week = the Sun–Sat before it, for
  week-over-week deltas. `daily_activity` is keyed by `activity_date` (already the
  user-local calendar day) so it's queried by date; timestamp tables
  (body_measurements, food_logs, workout_logs, performance_logs, personal_records,
  user_achievements) are queried by UTC bounds derived from the local week.
* Every metric is best-effort: a failed query logs a warning and the tile is
  omitted (auto-hide), so a user with no wearable still gets a useful email
  (`feedback_no_silent_fallbacks` is honored by NOT inventing values — we drop the
  tile instead of showing a fake one).
* Deltas: positive change → orange "up" chip; everything else (regression, no
  change, first week) → muted grey "flat" chip. A bad week never reads red.
* Resting HR + weight: lower is better (`higher_better=False`).
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from typing import Any, Callable, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

logger = logging.getLogger(__name__)

# Daily step goal — a day ring is "full" at this many steps.
STEP_GOAL = 6000
MILE_M = 1609.344
KG_TO_LB = 2.20462

# Weekday labels, Sunday first (matches the email ring row + Google Health).
_DOW = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
_MONTHS = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


# ────────────────────────────────────────────────────────────────────
# Output types
# ────────────────────────────────────────────────────────────────────

@dataclass
class Tile:
    """One metric card. `icon` is a key into ICON_PATHS in the template."""
    icon: str
    value: str
    label: str
    delta: str          # "↑ 1.78" | "No change" | "Baseline" | "240 over target" | ""
    dir: str = "flat"   # 'up' (orange) | 'flat' (muted grey)


@dataclass
class Award:
    icon: str           # 'medal' | 'flame' | 'dumbbell' | 'trophy'
    title: str
    detail: str


@dataclass
class WeeklyProgress:
    week_label: str                       # "Jun 6 – 12"
    has_wearable: bool
    is_first_week: bool
    empty_week: bool

    # Hero — steps (when has_wearable) ──
    total_steps: int = 0
    avg_steps: int = 0
    best_label: Optional[str] = None      # "Sat"
    best_steps: Optional[int] = None
    steps_delta: str = ""
    steps_dir: str = "flat"
    step_goal: int = STEP_GOAL
    day_steps: List[Tuple[str, Optional[int]]] = field(default_factory=list)  # Sun..Sat

    # Hero fallback — workouts (when no wearable) ──
    workouts_this_week: int = 0
    workouts_delta: str = ""
    workouts_dir: str = "flat"
    workouts_subline: str = ""

    quiet_line: str = ""                   # one-line copy for the quiet-week state
    activity_tiles: List[Tile] = field(default_factory=list)
    zealova_tiles: List[Tile] = field(default_factory=list)
    awards: List[Award] = field(default_factory=list)


# ────────────────────────────────────────────────────────────────────
# Time + formatting helpers
# ────────────────────────────────────────────────────────────────────

def _safe_zone(tz: Optional[str]) -> ZoneInfo:
    try:
        return ZoneInfo(tz or "UTC")
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        return ZoneInfo("UTC")


def _week_bounds(tz: str) -> Tuple[date, date, datetime, datetime, datetime]:
    """Most recent complete Sun–Sat week in the user's local calendar.

    Returns (week_start_date, week_end_date, prev_start_dt_utc, week_start_dt_utc,
    week_end_excl_dt_utc) where the UTC datetimes bound the 14-day span (prev week
    start → this week end, exclusive) for timestamp-keyed tables.
    """
    zone = _safe_zone(tz)
    today = datetime.now(zone).date()
    # Most recent Saturday strictly before today. isoweekday: Mon=1..Sun=7, Sat=6.
    days_since_sat = (today.isoweekday() - 6) % 7
    if days_since_sat == 0:
        days_since_sat = 7  # today is Saturday → use last week's Saturday
    week_end = today - timedelta(days=days_since_sat)        # Saturday
    week_start = week_end - timedelta(days=6)                # Sunday
    prev_start = week_start - timedelta(days=7)

    def _utc_midnight(d: date) -> datetime:
        return datetime(d.year, d.month, d.day, tzinfo=zone).astimezone(timezone.utc)

    return (
        week_start,
        week_end,
        _utc_midnight(prev_start),
        _utc_midnight(week_start),
        _utc_midnight(week_end + timedelta(days=1)),  # exclusive end
    )


def _week_label(start: date, end: date) -> str:
    if start.month == end.month:
        return f"{_MONTHS[start.month]} {start.day} – {end.day}"
    return f"{_MONTHS[start.month]} {start.day} – {_MONTHS[end.month]} {end.day}"


def _fmt_int(n: float) -> str:
    return f"{int(round(n)):,}"


def _fmt_1(n: float) -> str:
    return f"{n:.1f}"


def _fmt_minutes(total_min: float) -> str:
    m = int(round(total_min))
    h, mm = divmod(m, 60)
    return f"{h}h {mm:02d}m" if h else f"{mm}m"


def _avg(vals: List[Optional[float]]) -> Optional[float]:
    nums = [v for v in vals if v is not None]
    return sum(nums) / len(nums) if nums else None


def _delta(
    this: Optional[float],
    prior: Optional[float],
    higher_better: bool,
    fmt: Callable[[float], str],
    *,
    first_week: bool = False,
) -> Tuple[str, str]:
    """(chip_text, dir). Positive change → 'up' (orange); else 'flat' (grey)."""
    if first_week or prior is None or this is None:
        return ("Baseline", "flat")
    diff = this - prior
    if abs(diff) < 1e-6:
        return ("No change", "flat")
    arrow = "↑" if diff > 0 else "↓"
    improved = (diff > 0) == higher_better
    return (f"{arrow} {fmt(abs(diff))}", "up" if improved else "flat")


# ────────────────────────────────────────────────────────────────────
# Data fetch
# ────────────────────────────────────────────────────────────────────

def _fetch_daily_activity(db: Any, user_id: str, start: date, end: date) -> List[Dict[str, Any]]:
    try:
        resp = (
            db.client.table("daily_activity").select("*")
            .eq("user_id", user_id)
            .gte("activity_date", start.isoformat())
            .lte("activity_date", end.isoformat())
            .execute()
        )
        return resp.data or []
    except Exception as e:
        logger.warning("[weekly_progress] daily_activity fetch failed for %s: %s", user_id, e)
        return []


def _has_history_before(db: Any, user_id: str, week_start: date) -> bool:
    """True iff the user has any daily_activity strictly before this week."""
    try:
        resp = (
            db.client.table("daily_activity").select("activity_date")
            .eq("user_id", user_id)
            .lt("activity_date", week_start.isoformat())
            .limit(1).execute()
        )
        return bool(resp.data)
    except Exception:
        return True  # fail toward "not first week" so we don't over-show baseline


def _split_weeks(
    rows: List[Dict[str, Any]], week_start: date, week_end: date, prev_start: date
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """Split a 14-day daily_activity span into (this_week, prev_week) by date."""
    this_w, prev_w = [], []
    for r in rows:
        ds = r.get("activity_date")
        if not ds:
            continue
        try:
            d = date.fromisoformat(str(ds)[:10])
        except ValueError:
            continue
        if week_start <= d <= week_end:
            this_w.append(r)
        elif prev_start <= d < week_start:
            prev_w.append(r)
    return this_w, prev_w


def _num(row: Dict[str, Any], key: str) -> Optional[float]:
    v = row.get(key)
    try:
        return float(v) if v is not None else None
    except (TypeError, ValueError):
        return None


def _sum(rows: List[Dict[str, Any]], key: str) -> float:
    return sum((_num(r, key) or 0.0) for r in rows)


def _count_rows(db: Any, table: str, user_id: str, col: str,
                start: datetime, end: datetime) -> int:
    try:
        resp = (
            db.client.table(table).select("id", count="exact")
            .eq("user_id", user_id)
            .gte(col, start.isoformat()).lt(col, end.isoformat())
            .execute()
        )
        if getattr(resp, "count", None) is not None:
            return int(resp.count)
        return len(resp.data or [])
    except Exception as e:
        logger.warning("[weekly_progress] count %s failed for %s: %s", table, user_id, e)
        return 0


# ────────────────────────────────────────────────────────────────────
# Main entry
# ────────────────────────────────────────────────────────────────────

def compute_weekly_progress(db: Any, user_id: str, tz: str,
                            stats: Any = None) -> WeeklyProgress:
    """Roll up the user's most recent complete Sun–Sat week.

    `stats` is the optional `UserStats` already built by the cron (used for the
    daily calorie target + streak); never required.
    """
    week_start, week_end, prev_start_dt, week_start_dt, week_end_dt = _week_bounds(tz)
    prev_end_dt = week_start_dt  # prev week is [prev_start_dt, week_start_dt)

    # ── Wearable: daily_activity (14-day span split into this/prev) ──
    prev_start = prev_start_dt.date()
    span = _fetch_daily_activity(db, user_id, prev_start, week_end)
    this_w, prev_w = _split_weeks(span, week_start, week_end, prev_start)

    has_wearable = any(
        any(_num(r, k) is not None for k in
            ("steps", "calories_burned", "active_minutes", "sleep_minutes", "resting_heart_rate"))
        for r in this_w
    )
    # First-week framing: no comparable prior-week data → baseline copy, no deltas.
    is_first_week = not prev_w and not _has_history_before(db, user_id, week_start)

    # ── Steps hero + day rings ──
    steps_by_dow: Dict[int, int] = {}
    for r in this_w:
        ds = r.get("activity_date")
        s = _num(r, "steps")
        if not ds or s is None:
            continue
        d = date.fromisoformat(str(ds)[:10])
        steps_by_dow[(d.weekday() + 1) % 7] = int(s)  # Sun=0..Sat=6

    day_steps: List[Tuple[str, Optional[int]]] = [
        (_DOW[i], steps_by_dow.get(i)) for i in range(7)
    ]
    total_steps = int(_sum(this_w, "steps"))
    prev_steps = int(_sum(prev_w, "steps")) if prev_w else None
    n_days_with_steps = len([1 for _, s in day_steps if s])
    avg_steps = int(round(total_steps / n_days_with_steps)) if n_days_with_steps else 0
    best_label, best_steps = None, None
    if steps_by_dow:
        bi = max(steps_by_dow, key=steps_by_dow.get)
        best_label, best_steps = _DOW[bi], steps_by_dow[bi]
    steps_delta, steps_dir = _delta(
        total_steps, prev_steps if prev_steps else None, True, _fmt_int,
        first_week=is_first_week,
    )

    # ── Activity tiles (wearable) — omit when this-week metric absent ──
    activity_tiles: List[Tile] = []

    def _wearable_tile(icon: str, label: str, this_val: Optional[float],
                       prior_val: Optional[float], display: str,
                       higher_better: bool, fmt: Callable[[float], str]):
        if this_val is None:
            return
        d_txt, d_dir = _delta(this_val, prior_val, higher_better, fmt, first_week=is_first_week)
        activity_tiles.append(Tile(icon, display, label, d_txt, d_dir))

    if has_wearable:
        miles = _sum(this_w, "distance_meters") / MILE_M
        miles_p = (_sum(prev_w, "distance_meters") / MILE_M) if prev_w else None
        _wearable_tile("pin", "Total miles",
                       miles if miles > 0 else None, miles_p,
                       _fmt_1(miles), True, _fmt_1)

        cal = _avg([_num(r, "calories_burned") for r in this_w])
        cal_p = _avg([_num(r, "calories_burned") for r in prev_w]) if prev_w else None
        _wearable_tile("activity", "Cal burned", cal, cal_p,
                       _fmt_int(cal) if cal else "", True, _fmt_int)

        zone = _sum(this_w, "active_minutes")
        zone_p = _sum(prev_w, "active_minutes") if prev_w else None
        _wearable_tile("timer", "Zone min", zone if zone > 0 else None, zone_p,
                       _fmt_int(zone), True, _fmt_int)

        sleep = _avg([_num(r, "sleep_minutes") for r in this_w])
        sleep_p = _avg([_num(r, "sleep_minutes") for r in prev_w]) if prev_w else None
        _wearable_tile("moon", "Restful sleep", sleep, sleep_p,
                       _fmt_minutes(sleep) if sleep else "", True, _fmt_minutes)

        rhr = _avg([_num(r, "resting_heart_rate") for r in this_w])
        rhr_p = _avg([_num(r, "resting_heart_rate") for r in prev_w]) if prev_w else None
        _wearable_tile("heart", "Resting bpm", rhr, rhr_p,
                       _fmt_int(rhr) if rhr else "", False, _fmt_int)

    # Weight (body_measurements) — separate table ──
    w_this, w_prev = _avg_weight(db, user_id, week_start_dt, week_end_dt), \
        _avg_weight(db, user_id, prev_start_dt, prev_end_dt)
    if w_this is not None:
        d_txt, d_dir = _delta(w_this, w_prev, False, lambda x: f"{x:.1f} kg",
                              first_week=is_first_week)
        activity_tiles.append(Tile("scale", _fmt_1(w_this), "Weight (kg)", d_txt, d_dir))

    # ── App-native tiles ──
    zealova_tiles: List[Tile] = []

    workouts_this = _count_rows(db, "workout_logs", user_id, "completed_at",
                                week_start_dt, week_end_dt)
    workouts_prev = _count_rows(db, "workout_logs", user_id, "completed_at",
                                prev_start_dt, prev_end_dt)
    w_txt, w_dir = _delta(workouts_this, None if is_first_week else workouts_prev,
                          True, _fmt_int)
    zealova_tiles.append(Tile("dumbbell", str(workouts_this), "Workouts", w_txt, w_dir))

    vol_this = _sum_volume_lbs(db, user_id, week_start_dt, week_end_dt)
    vol_prev = _sum_volume_lbs(db, user_id, prev_start_dt, prev_end_dt)
    if vol_this and vol_this > 0:
        d_txt, d_dir = _delta(vol_this, None if is_first_week else vol_prev, True, _fmt_int)
        zealova_tiles.append(Tile("bars", _fmt_int(vol_this), "Lbs lifted", d_txt, d_dir))

    days_this, days_prev, cal_avg, cal_target = _nutrition(
        db, user_id, week_start_dt, week_end_dt, prev_start_dt, prev_end_dt, stats)
    if days_this > 0 or days_prev > 0:
        d_txt, d_dir = _delta(days_this, None if is_first_week else days_prev, True, _fmt_int)
        zealova_tiles.append(Tile("utensils", f"{days_this} / 7", "Days logged", d_txt, d_dir))
    if cal_avg:
        zealova_tiles.append(Tile("salad", _fmt_int(cal_avg), "Cal eaten",
                                  *_target_chip(cal_avg, cal_target)))

    mind_this = _mindfulness_minutes(db, user_id, week_start, week_end)
    mind_prev = _mindfulness_minutes(db, user_id, prev_start_dt.date(), week_start - timedelta(days=1))
    if mind_this > 0 or mind_prev > 0:
        d_txt, d_dir = _delta(mind_this, None if is_first_week else mind_prev, True, _fmt_minutes)
        zealova_tiles.append(Tile("leaf", _fmt_minutes(mind_this), "Mindfulness", d_txt, d_dir))

    streak = _workout_streak(db, user_id, stats)
    if streak > 0:
        zealova_tiles.append(Tile("flame", str(streak), "Day streak", "", "flat"))

    # ── Awards (achievements + PRs this week) ──
    awards = _awards(db, user_id, week_start_dt, week_end_dt)

    # ── Hero fallback (no wearable) + quiet detection ──
    vol_lbs = int(vol_this) if vol_this else 0
    train_min = _training_minutes(db, user_id, week_start_dt, week_end_dt)
    subline_bits = []
    if train_min:
        subline_bits.append(f"{_fmt_minutes(train_min)} training")
    if vol_lbs:
        subline_bits.append(f"{_fmt_int(vol_lbs)} lbs moved")
    workouts_subline = " · ".join(subline_bits)
    workouts_delta, workouts_dir = _delta(
        workouts_this, None if is_first_week else workouts_prev, True, _fmt_int)

    empty_week = (total_steps < 1000 and workouts_this == 0 and days_this <= 1
                  and not awards)
    quiet_line = ""
    if empty_week:
        quiet_line = (
            f"You logged {_fmt_int(total_steps)} steps and {workouts_this} workouts "
            f"this week. No guilt — weeks like this happen."
        )

    return WeeklyProgress(
        week_label=_week_label(week_start, week_end),
        has_wearable=has_wearable,
        is_first_week=is_first_week,
        empty_week=empty_week,
        total_steps=total_steps,
        avg_steps=avg_steps,
        best_label=best_label,
        best_steps=best_steps,
        steps_delta=steps_delta,
        steps_dir=steps_dir,
        day_steps=day_steps,
        workouts_this_week=workouts_this,
        workouts_delta=workouts_delta,
        workouts_dir=workouts_dir,
        workouts_subline=workouts_subline,
        quiet_line=quiet_line,
        activity_tiles=activity_tiles,
        zealova_tiles=zealova_tiles,
        awards=awards,
    )


# ────────────────────────────────────────────────────────────────────
# Per-source fetch helpers (each best-effort → None/0 on any error)
# ────────────────────────────────────────────────────────────────────

def _avg_weight(db: Any, user_id: str, start: datetime, end: datetime) -> Optional[float]:
    try:
        resp = (
            db.client.table("body_measurements").select("weight_kg, measured_at")
            .eq("user_id", user_id)
            .gte("measured_at", start.isoformat()).lt("measured_at", end.isoformat())
            .execute()
        )
        vals = [float(r["weight_kg"]) for r in (resp.data or []) if r.get("weight_kg") is not None]
        return sum(vals) / len(vals) if vals else None
    except Exception as e:
        logger.warning("[weekly_progress] weight fetch failed for %s: %s", user_id, e)
        return None


def _sum_volume_lbs(db: Any, user_id: str, start: datetime, end: datetime) -> Optional[float]:
    try:
        resp = (
            db.client.table("performance_logs").select("weight_kg, reps_completed")
            .eq("user_id", user_id)
            .gte("recorded_at", start.isoformat()).lt("recorded_at", end.isoformat())
            .execute()
        )
        total_kg = sum(
            float(r.get("weight_kg") or 0) * int(r.get("reps_completed") or 0)
            for r in (resp.data or [])
        )
        return total_kg * KG_TO_LB if total_kg > 0 else None
    except Exception as e:
        logger.warning("[weekly_progress] volume fetch failed for %s: %s", user_id, e)
        return None


def _training_minutes(db: Any, user_id: str, start: datetime, end: datetime) -> int:
    try:
        resp = (
            db.client.table("workout_logs").select("duration_minutes, completed_at")
            .eq("user_id", user_id)
            .gte("completed_at", start.isoformat()).lt("completed_at", end.isoformat())
            .execute()
        )
        return int(sum(int(r.get("duration_minutes") or 0) for r in (resp.data or [])))
    except Exception:
        return 0


def _nutrition(db: Any, user_id: str, start: datetime, end: datetime,
               pstart: datetime, pend: datetime, stats: Any
               ) -> Tuple[int, int, Optional[int], Optional[int]]:
    """Return (days_logged_this, days_logged_prev, avg_cal_this, cal_target)."""
    def _days_and_cal(s: datetime, e: datetime) -> Tuple[int, Optional[int]]:
        try:
            resp = (
                db.client.table("food_logs").select("logged_at, total_calories")
                .eq("user_id", user_id)
                .gte("logged_at", s.isoformat()).lt("logged_at", e.isoformat())
                .execute()
            )
            rows = resp.data or []
            days = {str(r["logged_at"])[:10] for r in rows if r.get("logged_at")}
            cals = [float(r["total_calories"]) for r in rows if r.get("total_calories") is not None]
            avg = int(round(sum(cals) / len(days))) if days and cals else None
            return len(days), avg
        except Exception as e:
            logger.warning("[weekly_progress] nutrition fetch failed for %s: %s", user_id, e)
            return 0, None

    days_this, cal_this = _days_and_cal(start, end)
    days_prev, _ = _days_and_cal(pstart, pend)
    target = getattr(stats, "daily_calorie_target", None) if stats else None
    if target is None:
        try:
            resp = db.client.table("users").select("daily_calorie_target").eq("id", user_id).limit(1).execute()
            if resp.data:
                target = resp.data[0].get("daily_calorie_target")
        except Exception:
            target = None
    return days_this, days_prev, cal_this, (int(target) if target else None)


def _target_chip(avg_cal: int, target: Optional[int]) -> Tuple[str, str]:
    """Neutral grey chip vs the user's calorie target (never red)."""
    if not target:
        return ("", "flat")
    diff = avg_cal - target
    if abs(diff) <= max(75, int(target * 0.05)):
        return ("On target", "flat")
    word = "over" if diff > 0 else "under"
    return (f"{_fmt_int(abs(diff))} {word} target", "flat")


def _mindfulness_minutes(db: Any, user_id: str, start: date, end: date) -> int:
    try:
        resp = (
            db.client.table("mindfulness_sessions").select("duration_seconds, local_date")
            .eq("user_id", user_id)
            .gte("local_date", start.isoformat()).lte("local_date", end.isoformat())
            .execute()
        )
        secs = sum(int(r.get("duration_seconds") or 0) for r in (resp.data or []))
        return int(round(secs / 60))
    except Exception:
        return 0


def _workout_streak(db: Any, user_id: str, stats: Any) -> int:
    if stats is not None and getattr(stats, "current_streak_days", 0):
        return int(stats.current_streak_days)
    try:
        resp = (
            db.client.table("user_streaks").select("current_streak")
            .eq("user_id", user_id).eq("streak_type", "workout").limit(1).execute()
        )
        if resp.data:
            return int(resp.data[0].get("current_streak") or 0)
    except Exception:
        pass
    return 0


def _awards(db: Any, user_id: str, start: datetime, end: datetime) -> List[Award]:
    """Up to 3 milestones earned this week — PRs first, then achievements."""
    awards: List[Award] = []
    # New PRs (weight) this week.
    try:
        resp = (
            db.client.table("personal_records")
            .select("exercise_name, record_value, record_unit, previous_value, record_type, achieved_at")
            .eq("user_id", user_id)
            .gte("achieved_at", start.isoformat()).lt("achieved_at", end.isoformat())
            .order("record_value", desc=True).limit(3).execute()
        )
        for r in (resp.data or []):
            val, unit = r.get("record_value"), (r.get("record_unit") or "")
            prev = r.get("previous_value")
            detail = f"{_fmt_int(val)} {unit}".strip()
            if prev:
                detail += f" — up from {_fmt_int(prev)} {unit}".rstrip()
            awards.append(Award("dumbbell", f"New PR · {r.get('exercise_name', 'Lift')}", detail))
    except Exception as e:
        logger.warning("[weekly_progress] PR fetch failed for %s: %s", user_id, e)

    # Achievements earned this week (ranked by points).
    try:
        resp = (
            db.client.table("user_achievements")
            .select("achievement_id, earned_at, achievement_types(name, description, points)")
            .eq("user_id", user_id)
            .gte("earned_at", start.isoformat()).lt("earned_at", end.isoformat())
            .execute()
        )
        rows = resp.data or []

        def _pts(r):
            at = r.get("achievement_types") or {}
            return (at.get("points") or 0) if isinstance(at, dict) else 0

        for r in sorted(rows, key=_pts, reverse=True):
            at = r.get("achievement_types") or {}
            name = (at.get("name") if isinstance(at, dict) else None) or "Achievement unlocked"
            desc = (at.get("description") if isinstance(at, dict) else None) or ""
            icon = "flame" if "streak" in name.lower() else "medal"
            awards.append(Award(icon, name, desc))
    except Exception as e:
        logger.warning("[weekly_progress] achievement fetch failed for %s: %s", user_id, e)

    return awards[:3]
