"""
Data collection helpers for FitWiz MCP report generation.

Each `collect_*` function returns a plain dict that the corresponding Jinja2
template consumes. Every query is guarded: missing tables / empty data produce
safe defaults (zeros, empty lists, None) rather than raising, so templates can
always render — even for brand-new users with no history.

The top-level entrypoint is `collect_report_data()` which dispatches on
report_type and always returns a dict with these minimal top-level keys:
    - user           (dict): name, primary_goal, bodyweight_kg, bodyweight_lb
    - date_range     (dict): start_date, end_date, days, label
    - report_type    (str)
    - generated_at   (str ISO timestamp)
Plus report-specific sections (workouts / strength / nutrition / habits / ...).
"""
from __future__ import annotations

import asyncio
import logging
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Safe Supabase query helper
# ---------------------------------------------------------------------------

def _safe_query(fn, default: Any = None) -> Any:
    """
    Run a sync Supabase query and swallow any exception, returning `default`.

    Rationale: reports must never 500 just because an optional table is empty,
    missing, or RLS-blocked. We log the exception for observability but return
    the default so the template renders a graceful "No data" section.
    """
    try:
        result = fn()
        # Supabase client returns an APIResponse with a `.data` attribute
        data = getattr(result, "data", result)
        if data is None:
            return default if default is not None else []
        return data
    except Exception as e:  # noqa: BLE001 — intentional broad catch
        logger.warning("report data query failed, using default: %s", e)
        return default if default is not None else []


def _get_client():
    """Lazy-import the Supabase client so module import doesn't require env."""
    from core.supabase_client import get_supabase
    return get_supabase().client


# ---------------------------------------------------------------------------
# Shared building blocks
# ---------------------------------------------------------------------------

def _iso(d: date) -> str:
    return d.isoformat()


def _date_range_label(start: date, end: date) -> str:
    days = (end - start).days + 1
    if days <= 7:
        return "Weekly"
    if days <= 14:
        return "Bi-weekly"
    if days <= 35:
        return "Monthly"
    return f"{days}-day"


def _collect_user(user_id: str) -> Dict[str, Any]:
    """Fetch user profile + latest bodyweight. Always returns a dict."""
    client = _get_client()

    user_row = _safe_query(
        lambda: client.table("users").select("*").eq("id", user_id).limit(1).execute(),
        default=[],
    )
    user = user_row[0] if user_row else {}

    # Latest weight log (kg) — graceful fallback
    weight_rows = _safe_query(
        lambda: client.table("weight_logs")
        .select("weight_kg, logged_at")
        .eq("user_id", user_id)
        .order("logged_at", desc=True)
        .limit(1)
        .execute(),
        default=[],
    )
    latest_weight_kg: Optional[float] = None
    if weight_rows:
        try:
            latest_weight_kg = float(weight_rows[0].get("weight_kg")) if weight_rows[0].get("weight_kg") is not None else None
        except (TypeError, ValueError):
            latest_weight_kg = None

    name = user.get("name") or user.get("display_name") or user.get("full_name") or "Athlete"
    primary_goal = (
        user.get("primary_goal")
        or user.get("goal")
        or (user.get("goals") if isinstance(user.get("goals"), str) else None)
        or "General fitness"
    )

    bodyweight_lb: Optional[float] = None
    if latest_weight_kg is not None:
        bodyweight_lb = round(latest_weight_kg * 2.20462, 1)

    return {
        "name": name,
        "primary_goal": primary_goal,
        "bodyweight_kg": round(latest_weight_kg, 1) if latest_weight_kg is not None else None,
        "bodyweight_lb": bodyweight_lb,
        "raw": user,  # templates may peek if needed
    }


# ---------------------------------------------------------------------------
# Workouts section
# ---------------------------------------------------------------------------

def _collect_workouts(user_id: str, start: date, end: date) -> Dict[str, Any]:
    """Counts of planned vs completed workouts in range + exercise diversity."""
    client = _get_client()
    rows = _safe_query(
        lambda: client.table("workouts")
        .select("id, scheduled_date, is_completed, completed_at, duration_minutes, exercises, name")
        .eq("user_id", user_id)
        .gte("scheduled_date", _iso(start))
        .lte("scheduled_date", _iso(end))
        .execute(),
        default=[],
    )

    planned = len(rows)
    completed = sum(1 for r in rows if r.get("is_completed") or r.get("completed_at"))
    total_minutes = 0
    unique_exercises: set = set()
    per_day: Dict[str, int] = defaultdict(int)  # YYYY-MM-DD -> completed count
    dow_counts: List[int] = [0] * 7             # Mon=0 ... Sun=6 completed counts
    durations: List[int] = []

    for r in rows:
        completed_flag = r.get("is_completed") or r.get("completed_at")
        if not completed_flag:
            continue
        mins = r.get("duration_minutes") or 0
        try:
            mins_int = int(mins)
        except (TypeError, ValueError):
            mins_int = 0
        total_minutes += mins_int
        if mins_int > 0:
            durations.append(mins_int)

        sd = r.get("scheduled_date") or (r.get("completed_at") or "")[:10]
        if sd:
            per_day[sd] += 1
            try:
                dow = date.fromisoformat(sd).weekday()
                dow_counts[dow] += 1
            except ValueError:
                pass

        ex_list = r.get("exercises") or []
        if isinstance(ex_list, list):
            for ex in ex_list:
                if isinstance(ex, dict):
                    nm = ex.get("name") or ex.get("exercise_name") or ex.get("id")
                    if nm:
                        unique_exercises.add(str(nm).lower().strip())

    avg_duration = round(sum(durations) / len(durations), 1) if durations else 0

    # Per-week planned/completed for adherence report
    weekly: Dict[str, Dict[str, int]] = defaultdict(lambda: {"planned": 0, "completed": 0})
    for r in rows:
        sd = r.get("scheduled_date")
        if not sd:
            continue
        try:
            d = date.fromisoformat(sd)
        except ValueError:
            continue
        week_key = (d - timedelta(days=d.weekday())).isoformat()  # Monday of that week
        weekly[week_key]["planned"] += 1
        if r.get("is_completed") or r.get("completed_at"):
            weekly[week_key]["completed"] += 1

    weekly_list = [
        {
            "week_start": k,
            "planned": v["planned"],
            "completed": v["completed"],
            "adherence_pct": round(100 * v["completed"] / v["planned"]) if v["planned"] else 0,
        }
        for k, v in sorted(weekly.items())
    ]

    dow_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    dow_heatmap = [{"day": dow_labels[i], "count": dow_counts[i]} for i in range(7)]

    return {
        "planned_count": planned,
        "completed_count": completed,
        "adherence_pct": round(100 * completed / planned) if planned else 0,
        "total_minutes": total_minutes,
        "unique_exercises": len(unique_exercises),
        "avg_duration_min": avg_duration,
        "weekly": weekly_list,
        "dow_heatmap": dow_heatmap,
        "raw_rows": rows,  # used by strength extractor
    }


# ---------------------------------------------------------------------------
# Strength section
# ---------------------------------------------------------------------------

_MAJOR_LIFTS = {
    "bench press": ["bench press", "barbell bench press", "bench"],
    "squat": ["squat", "back squat", "barbell squat"],
    "deadlift": ["deadlift", "conventional deadlift", "barbell deadlift"],
    "overhead press": ["overhead press", "ohp", "military press", "shoulder press"],
}


def _normalize_ex_name(s: str) -> str:
    return (s or "").lower().strip()


def _collect_strength(
    user_id: str,
    start: date,
    end: date,
    workout_rows: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """Strength metrics: latest scores, PRs in range, volume by lift, progression curves."""
    client = _get_client()

    # Strength scores — current vs at period start
    scores_now = _safe_query(
        lambda: client.table("strength_scores")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(5)
        .execute(),
        default=[],
    )
    scores_start = _safe_query(
        lambda: client.table("strength_scores")
        .select("*")
        .eq("user_id", user_id)
        .lte("created_at", _iso(start))
        .order("created_at", desc=True)
        .limit(5)
        .execute(),
        default=[],
    )

    def _score_val(row: Dict[str, Any]) -> Optional[float]:
        for k in ("score", "strength_score", "value", "overall_score"):
            if row.get(k) is not None:
                try:
                    return float(row[k])
                except (TypeError, ValueError):
                    continue
        return None

    current_score = _score_val(scores_now[0]) if scores_now else None
    start_score = _score_val(scores_start[0]) if scores_start else None
    delta = None
    if current_score is not None and start_score is not None:
        delta = round(current_score - start_score, 1)

    # PRs in range
    prs = _safe_query(
        lambda: client.table("personal_records")
        .select("*")
        .eq("user_id", user_id)
        .gte("achieved_at", _iso(start))
        .lte("achieved_at", _iso(end) + "T23:59:59")
        .order("achieved_at", desc=True)
        .execute(),
        default=[],
    )
    pr_list: List[Dict[str, Any]] = []
    for pr in prs or []:
        pr_list.append(
            {
                "exercise": pr.get("exercise_name") or pr.get("name") or "Unknown",
                "weight": pr.get("weight") or pr.get("weight_lb") or pr.get("weight_kg"),
                "unit": pr.get("unit") or ("lb" if pr.get("weight_lb") else "kg"),
                "reps": pr.get("reps"),
                "achieved_at": pr.get("achieved_at"),
            }
        )

    # Volume by lift + progression curves from completed workouts
    if workout_rows is None:
        workout_rows = []

    volume_by_exercise: Dict[str, float] = defaultdict(float)
    # progression[lift_key] -> list of (date, max_weight) points
    progression: Dict[str, List[Tuple[str, float]]] = defaultdict(list)

    for w in workout_rows:
        if not (w.get("is_completed") or w.get("completed_at")):
            continue
        ex_list = w.get("exercises") or []
        if not isinstance(ex_list, list):
            continue
        sd = w.get("scheduled_date") or (w.get("completed_at") or "")[:10]
        for ex in ex_list:
            if not isinstance(ex, dict):
                continue
            name = _normalize_ex_name(ex.get("name") or ex.get("exercise_name") or "")
            if not name:
                continue
            sets = ex.get("sets") or []
            if not isinstance(sets, list):
                continue
            max_w_this_session = 0.0
            for s in sets:
                if not isinstance(s, dict):
                    continue
                try:
                    reps = float(s.get("reps") or 0)
                    weight = float(s.get("weight") or s.get("weight_lb") or s.get("weight_kg") or 0)
                except (TypeError, ValueError):
                    continue
                if reps > 0 and weight > 0:
                    volume_by_exercise[name] += reps * weight
                    if weight > max_w_this_session:
                        max_w_this_session = weight

            # Match against major lifts for progression curves
            for key, aliases in _MAJOR_LIFTS.items():
                if any(alias in name for alias in aliases):
                    if sd and max_w_this_session > 0:
                        progression[key].append((sd, max_w_this_session))

    top_volume = sorted(volume_by_exercise.items(), key=lambda kv: kv[1], reverse=True)[:5]
    top_lifts_by_volume = [
        {"name": n.title(), "total_volume": round(v, 1)} for n, v in top_volume
    ]

    # Build progression curves — sorted ascending by date, deduped per day (max)
    progression_curves: Dict[str, List[Dict[str, Any]]] = {}
    for key, points in progression.items():
        daily_max: Dict[str, float] = {}
        for d, w in points:
            if d not in daily_max or w > daily_max[d]:
                daily_max[d] = w
        progression_curves[key] = [
            {"date": d, "weight": round(w, 1)}
            for d, w in sorted(daily_max.items())
        ]

    # Headline "top lifts" for summary — use progression most-recent
    top_lifts_summary: List[Dict[str, Any]] = []
    for key, curve in progression_curves.items():
        if not curve:
            continue
        first = curve[0]["weight"]
        last = curve[-1]["weight"]
        delta_pct = round(100 * (last - first) / first, 1) if first > 0 else 0
        top_lifts_summary.append(
            {
                "name": key.title(),
                "current": last,
                "start": first,
                "unit": "lb",
                "delta_pct": delta_pct,
            }
        )

    return {
        "current_score": round(current_score, 1) if current_score is not None else None,
        "start_score": round(start_score, 1) if start_score is not None else None,
        "delta": delta,
        "prs": pr_list,
        "top_lifts_by_volume": top_lifts_by_volume,
        "top_lifts": top_lifts_summary,
        "progression_curves": progression_curves,
    }


# ---------------------------------------------------------------------------
# Nutrition section
# ---------------------------------------------------------------------------

def _collect_nutrition(user_id: str, start: date, end: date) -> Dict[str, Any]:
    """Averages, top foods, meal-timing split, micros flags."""
    client = _get_client()

    logs = _safe_query(
        lambda: client.table("food_logs")
        .select("*")
        .eq("user_id", user_id)
        .gte("logged_at", _iso(start))
        .lte("logged_at", _iso(end))
        .execute(),
        default=[],
    )

    # Aggregate per-day
    days_span = (end - start).days + 1
    per_day: Dict[str, Dict[str, float]] = defaultdict(
        lambda: {"calories": 0.0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0, "fiber_g": 0.0}
    )
    foods_counter: Counter = Counter()
    meal_calories: Dict[str, float] = defaultdict(float)

    for log in logs or []:
        d = (log.get("logged_at") or "")[:10]
        if not d:
            continue
        try:
            cals = float(log.get("total_calories") or 0)
            protein = float(log.get("protein_g") or 0)
            carbs = float(log.get("carbs_g") or 0)
            fat = float(log.get("fat_g") or 0)
            fiber = float(log.get("fiber_g") or 0)
        except (TypeError, ValueError):
            continue

        per_day[d]["calories"] += cals
        per_day[d]["protein_g"] += protein
        per_day[d]["carbs_g"] += carbs
        per_day[d]["fat_g"] += fat
        per_day[d]["fiber_g"] += fiber

        food_name = log.get("food_name") or log.get("name")
        if food_name:
            foods_counter[str(food_name)] += 1

        meal_type = (log.get("meal_type") or "other").lower()
        meal_calories[meal_type] += cals

    days_logged = len(per_day)
    avg_calories = round(sum(d["calories"] for d in per_day.values()) / days_logged) if days_logged else 0
    avg_protein = round(sum(d["protein_g"] for d in per_day.values()) / days_logged) if days_logged else 0
    avg_carbs = round(sum(d["carbs_g"] for d in per_day.values()) / days_logged) if days_logged else 0
    avg_fat = round(sum(d["fat_g"] for d in per_day.values()) / days_logged) if days_logged else 0
    avg_fiber = round(sum(d["fiber_g"] for d in per_day.values()) / days_logged) if days_logged else 0

    top_foods = [{"name": n, "count": c} for n, c in foods_counter.most_common(10)]

    total_meal_cals = sum(meal_calories.values()) or 1
    meal_distribution = [
        {
            "meal_type": m,
            "calories": round(cals),
            "pct": round(100 * cals / total_meal_cals),
        }
        for m, cals in sorted(meal_calories.items(), key=lambda kv: kv[1], reverse=True)
    ]

    # Micronutrient flags — optional table
    micros = _safe_query(
        lambda: client.table("micronutrients")
        .select("*")
        .eq("user_id", user_id)
        .gte("log_date", _iso(start))
        .lte("log_date", _iso(end))
        .execute(),
        default=[],
    )
    micro_flags: List[Dict[str, Any]] = []
    if micros:
        # Aggregate mean for each numeric field, flag anything < 50% of `target_*` if present
        numeric_sums: Dict[str, float] = defaultdict(float)
        numeric_counts: Dict[str, int] = defaultdict(int)
        for row in micros:
            for k, v in row.items():
                if isinstance(v, (int, float)) and k not in ("id", "user_id"):
                    numeric_sums[k] += float(v)
                    numeric_counts[k] += 1
        for k, total in numeric_sums.items():
            if numeric_counts[k]:
                micro_flags.append({"nutrient": k, "avg": round(total / numeric_counts[k], 2)})

    # Water
    water_rows = _safe_query(
        lambda: client.table("hydration_logs")
        .select("amount_ml, logged_at")
        .eq("user_id", user_id)
        .gte("logged_at", _iso(start))
        .lte("logged_at", _iso(end) + "T23:59:59")
        .execute(),
        default=[],
    )
    water_by_day: Dict[str, float] = defaultdict(float)
    for w in water_rows or []:
        ts = (w.get("logged_at") or "")[:10]
        if ts:
            try:
                water_by_day[ts] += float(w.get("amount_ml") or 0)
            except (TypeError, ValueError):
                continue
    water_trend = [{"date": d, "ml": int(ml)} for d, ml in sorted(water_by_day.items())]
    avg_water_ml = round(sum(water_by_day.values()) / len(water_by_day)) if water_by_day else 0

    return {
        "avg_calories": avg_calories,
        "avg_protein_g": avg_protein,
        "avg_carbs_g": avg_carbs,
        "avg_fat_g": avg_fat,
        "avg_fiber_g": avg_fiber,
        "days_logged": days_logged,
        "days_span": days_span,
        "log_rate_pct": round(100 * days_logged / days_span) if days_span else 0,
        "top_foods": top_foods,
        "meal_distribution": meal_distribution,
        "micro_flags": micro_flags,
        "water_trend": water_trend,
        "avg_water_ml": avg_water_ml,
    }


# ---------------------------------------------------------------------------
# Habits / streaks
# ---------------------------------------------------------------------------

def _collect_habits(user_id: str, start: date, end: date) -> Dict[str, Any]:
    client = _get_client()
    rows = _safe_query(
        lambda: client.table("user_streaks").select("*").eq("user_id", user_id).execute(),
        default=[],
    )
    current = 0
    longest = 0
    for r in rows or []:
        cur = r.get("current_streak") or r.get("current") or 0
        lng = r.get("longest_streak") or r.get("longest") or 0
        try:
            current = max(current, int(cur))
            longest = max(longest, int(lng))
        except (TypeError, ValueError):
            pass
    return {
        "current_streak": current,
        "longest_streak": longest,
    }


# ---------------------------------------------------------------------------
# Workout adherence extras (RPE)
# ---------------------------------------------------------------------------

def _collect_adherence_extras(workout_rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Average RPE across completed sets, pulled from workout.exercises[].sets[]."""
    rpes: List[float] = []
    for w in workout_rows or []:
        if not (w.get("is_completed") or w.get("completed_at")):
            continue
        ex_list = w.get("exercises") or []
        if not isinstance(ex_list, list):
            continue
        for ex in ex_list:
            if not isinstance(ex, dict):
                continue
            sets = ex.get("sets") or []
            if not isinstance(sets, list):
                continue
            for s in sets:
                if isinstance(s, dict) and s.get("rpe") is not None:
                    try:
                        rpes.append(float(s["rpe"]))
                    except (TypeError, ValueError):
                        continue
    avg_rpe = round(sum(rpes) / len(rpes), 1) if rpes else None
    return {"avg_rpe": avg_rpe, "rpe_sample_size": len(rpes)}


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

async def collect_report_data(
    user_id: str,
    report_type: str,
    start: date,
    end: date,
) -> Dict[str, Any]:
    """
    Build the template context dict for the requested report.

    This runs the sync Supabase calls in a thread pool via asyncio.to_thread so
    it doesn't block the event loop (Supabase's Python client is sync-only).
    """

    def _build() -> Dict[str, Any]:
        user = _collect_user(user_id)
        workouts = _collect_workouts(user_id, start, end)
        workout_rows = workouts.pop("raw_rows", [])

        base: Dict[str, Any] = {
            "report_type": report_type,
            "start_date": _iso(start),
            "end_date": _iso(end),
            "date_range": {
                "start_date": _iso(start),
                "end_date": _iso(end),
                "days": (end - start).days + 1,
                "label": _date_range_label(start, end),
            },
            "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "user": user,
        }

        if report_type in ("weekly_summary", "monthly_summary"):
            strength = _collect_strength(user_id, start, end, workout_rows)
            nutrition = _collect_nutrition(user_id, start, end)
            habits = _collect_habits(user_id, start, end)
            base.update(
                {
                    "workouts": workouts,
                    "strength": strength,
                    "nutrition": nutrition,
                    "habits": habits,
                }
            )
        elif report_type == "nutrition_deep_dive":
            nutrition = _collect_nutrition(user_id, start, end)
            base.update({"nutrition": nutrition})
        elif report_type == "strength_progression":
            strength = _collect_strength(user_id, start, end, workout_rows)
            base.update({"workouts": workouts, "strength": strength})
        elif report_type == "workout_adherence":
            extras = _collect_adherence_extras(workout_rows)
            base.update({"workouts": workouts, "adherence": extras})
        else:
            # Unknown type — return a minimal dict so template errors are clear
            base.update({"workouts": workouts})

        return base

    return await asyncio.to_thread(_build)
