"""
Share data service — DETERMINISTIC assembly for share cards (F3, F16).

Zero LLM calls. Pure SQL aggregation + the existing score->grade mapping. The
only non-deterministic dependency is the F2 insight line, which is itself
cached/deterministic-first (services.share_ai_service.insight_line).

  F3  day_in_proof(user_id, date)
        The cross-domain card only Zealova can make: that day's top PR + meal
        letter-grade + current streak + one cached insight line.
  F16 on_this_day(user_id, date)
        Workouts + meals logged on this month/day in prior years.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db.facade import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


# --------------------------------------------------------------------------- #
# Score -> letter grade. Mirrors api/v1/neat.py::score_to_grade cutoffs exactly
# so the meal grade is consistent app-wide (zero AI).
# --------------------------------------------------------------------------- #
def score_to_grade(score: Optional[float]) -> Optional[str]:
    if score is None:
        return None
    s = float(score)
    if s >= 90: return "A+"
    if s >= 85: return "A"
    if s >= 80: return "A-"
    if s >= 75: return "B+"
    if s >= 70: return "B"
    if s >= 65: return "B-"
    if s >= 60: return "C+"
    if s >= 55: return "C"
    if s >= 50: return "C-"
    if s >= 45: return "D+"
    if s >= 40: return "D"
    return "F"


def _day_bounds(date_iso: str) -> tuple[str, str]:
    """[midnight, next-midnight) UTC ISO bounds for a YYYY-MM-DD date."""
    d = datetime.fromisoformat(date_iso).date()
    start = datetime(d.year, d.month, d.day, tzinfo=timezone.utc)
    return start.isoformat(), (start + timedelta(days=1)).isoformat()


def _current_streak(user_id: str) -> int:
    db = get_supabase_db()
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


def _top_pr_for_day(user_id: str, date_iso: str) -> Optional[Dict[str, Any]]:
    db = get_supabase_db()
    start, end = _day_bounds(date_iso)
    try:
        resp = (
            db.client.table("personal_records")
            .select("exercise_name, record_value, record_unit, improvement_percent, "
                    "weight_kg, estimated_1rm_kg, is_all_time_pr, achieved_at")
            .eq("user_id", user_id)
            .gte("achieved_at", start).lt("achieved_at", end)
            .order("record_value", desc=True).limit(1).execute()
        )
    except Exception as e:
        logger.warning(f"[ShareData] PR query failed: {e}")
        return None
    if not resp.data:
        return None
    r = resp.data[0]
    value = r.get("record_value")
    unit = r.get("record_unit") or "kg"
    return {
        "exercise": r.get("exercise_name"),
        "value": f"{_fmt_num(value)} {unit}".strip(),
        "raw_value": value,
        "unit": unit,
        "pct": round(float(r.get("improvement_percent") or 0), 1),
        "all_time": bool(r.get("is_all_time_pr")),
    }


def _meal_grade_for_day(user_id: str, date_iso: str) -> Optional[Dict[str, Any]]:
    """Average health_score across that day's non-deleted food logs -> grade."""
    db = get_supabase_db()
    start, end = _day_bounds(date_iso)
    try:
        resp = (
            db.client.table("food_logs")
            .select("health_score, total_calories, protein_g")
            .eq("user_id", user_id)
            .gte("logged_at", start).lt("logged_at", end)
            .is_("deleted_at", "null")
            .execute()
        )
    except Exception as e:
        logger.warning(f"[ShareData] food query failed: {e}")
        return None
    rows = resp.data or []
    scores = [r["health_score"] for r in rows if r.get("health_score") is not None]
    if not scores:
        return None
    avg = sum(scores) / len(scores)
    cals = sum(int(r.get("total_calories") or 0) for r in rows)
    protein = sum(float(r.get("protein_g") or 0) for r in rows)
    return {
        "score": round(avg, 1),
        "grade": score_to_grade(avg),
        "meals_logged": len(rows),
        "total_calories": cals,
        "protein_g": round(protein),
    }


def _top_workout_for_day(user_id: str, date_iso: str) -> Optional[Dict[str, Any]]:
    db = get_supabase_db()
    start, end = _day_bounds(date_iso)
    try:
        resp = (
            db.client.table("workouts")
            .select("id, name, type, duration_minutes, estimated_calories, completed_at")
            .eq("user_id", user_id).eq("is_completed", True)
            .gte("completed_at", start).lt("completed_at", end)
            .order("completed_at", desc=True).limit(1).execute()
        )
    except Exception as e:
        logger.warning(f"[ShareData] workout query failed: {e}")
        return None
    if not resp.data:
        return None
    w = resp.data[0]
    return {
        "id": w.get("id"),
        "name": w.get("name"),
        "type": w.get("type"),
        "duration_minutes": w.get("duration_minutes"),
        "estimated_calories": w.get("estimated_calories"),
    }


def _fmt_num(v: Any) -> str:
    try:
        f = float(v)
        return str(int(f)) if f.is_integer() else f"{f:g}"
    except (TypeError, ValueError):
        return str(v or "")


def day_in_proof(user_id: str, date_iso: str) -> Dict[str, Any]:
    """F3 — deterministic cross-domain card. Includes one cached F2 insight line.
    `has_data` is False when the day has neither a workout, PR, nor a meal grade
    (caller shows an empty state rather than a fabricated card)."""
    pr = _top_pr_for_day(user_id, date_iso)
    grade = _meal_grade_for_day(user_id, date_iso)
    workout = _top_workout_for_day(user_id, date_iso)
    streak = _current_streak(user_id)

    has_data = bool(pr or grade or workout)

    # One cached insight line (F2). Cheap-by-default: it reuses coach insight /
    # deterministic pool before any AI call.
    line = ""
    line_source = "none"
    if has_data:
        try:
            from services import share_ai_service

            stats: Dict[str, Any] = {}
            kind = "workout"
            if pr:
                stats["top_pr"] = {"value": pr["value"], "exercise": pr["exercise"], "pct": pr["pct"]}
            if workout and workout.get("duration_minutes"):
                stats["name"] = workout.get("name") or "Workout"
                stats["metric"] = f"{workout['duration_minutes']} min"
            if not stats and grade:
                kind = "food"
                stats = {"health_score": grade["score"], "metric": f"{grade['protein_g']}g protein"}
            res = share_ai_service.insight_line(
                user_id=user_id, kind=kind, tone="supportive",
                cache_key=f"day:{user_id}:{date_iso}", local_date=date_iso, stats=stats,
            )
            line, line_source = res.get("line", ""), res.get("source", "none")
        except Exception as e:
            logger.warning(f"[ShareData] day_in_proof insight line failed: {e}")

    return {
        "date": date_iso,
        "has_data": has_data,
        "top_pr": pr,
        "meal_grade": grade,
        "workout": workout,
        "streak": streak,
        "insight_line": line,
        "insight_source": line_source,
    }


def on_this_day(user_id: str, date_iso: str) -> Dict[str, Any]:
    """F16 — workouts + meals on this month/day in prior years. Deterministic
    query over completed workouts and food logs whose month+day match and whose
    year is strictly earlier than the requested date's year."""
    target = datetime.fromisoformat(date_iso).date()
    db = get_supabase_db()

    workouts: List[Dict[str, Any]] = []
    meals: List[Dict[str, Any]] = []
    years: List[int] = []

    # Look back up to 5 prior years (cheap; bounded).
    for years_ago in range(1, 6):
        y = target.year - years_ago
        try:
            d = date(y, target.month, target.day)
        except ValueError:
            continue  # Feb 29 in a non-leap prior year
        start = datetime(d.year, d.month, d.day, tzinfo=timezone.utc).isoformat()
        end = (datetime(d.year, d.month, d.day, tzinfo=timezone.utc) + timedelta(days=1)).isoformat()
        found_this_year = False

        try:
            wr = (
                db.client.table("workouts")
                .select("id, name, type, duration_minutes, estimated_calories, completed_at")
                .eq("user_id", user_id).eq("is_completed", True)
                .gte("completed_at", start).lt("completed_at", end)
                .order("completed_at", desc=True).execute()
            )
            for w in (wr.data or []):
                workouts.append({**_workout_brief(w), "years_ago": years_ago, "year": y})
                found_this_year = True
        except Exception as e:
            logger.warning(f"[ShareData] on_this_day workouts {y} failed: {e}")

        try:
            fr = (
                db.client.table("food_logs")
                .select("id, food_name, meal_type, total_calories, protein_g, health_score, logged_at")
                .eq("user_id", user_id)
                .gte("logged_at", start).lt("logged_at", end)
                .is_("deleted_at", "null")
                .order("logged_at", desc=True).execute()
            )
            for m in (fr.data or []):
                meals.append({**_meal_brief(m), "years_ago": years_ago, "year": y})
                found_this_year = True
        except Exception as e:
            logger.warning(f"[ShareData] on_this_day meals {y} failed: {e}")

        if found_this_year:
            years.append(y)

    return {
        "date": date_iso,
        "has_data": bool(workouts or meals),
        "years": sorted(set(years), reverse=True),
        "workouts": workouts,
        "meals": meals,
    }


def _workout_brief(w: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": w.get("id"),
        "name": w.get("name"),
        "type": w.get("type"),
        "duration_minutes": w.get("duration_minutes"),
        "estimated_calories": w.get("estimated_calories"),
        "completed_at": w.get("completed_at"),
    }


def _meal_brief(m: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": m.get("id"),
        "food_name": m.get("food_name"),
        "meal_type": m.get("meal_type"),
        "total_calories": m.get("total_calories"),
        "protein_g": m.get("protein_g"),
        "health_score": m.get("health_score"),
        "grade": score_to_grade(m.get("health_score")),
        "logged_at": m.get("logged_at"),
    }
