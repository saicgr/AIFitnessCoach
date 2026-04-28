"""
Daily and weekly nutrition report endpoints.

Item 14 from the bug-sweep plan: after the user logs dinner the daily report
should be available; every Sunday a weekly report should fire. Both are
delivered via in-app banner + push notification (see notification_service for
the cron wiring) and tap-through to the unified ShareableSheet.

These endpoints are aggregation-only — they reuse the existing
`get_daily_nutrition_summary` / `get_weekly_nutrition_summary` helpers and
add an AI narrative + tomorrow-improvement suggestions on top.
"""
from datetime import datetime, timedelta, date as date_type
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.db.nutrition_db_helpers import (
    get_daily_nutrition_summary,
    get_weekly_nutrition_summary,
)
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.gemini_service import GeminiService

router = APIRouter()
logger = get_logger(__name__)


class DailyNutritionReport(BaseModel):
    date: str
    calories_consumed: int
    calorie_target: int
    macros: dict = Field(default_factory=dict)
    inflammation_score: Optional[float] = None
    inflammation_top_contributors: List[str] = Field(default_factory=list)
    top_foods: List[dict] = Field(default_factory=list)
    ai_summary: str = ""
    tomorrow_suggestions: List[str] = Field(default_factory=list)
    user_first_name: Optional[str] = None


class WeeklyNutritionReport(BaseModel):
    week_start: str
    week_end: str
    daily_calories: List[int] = Field(default_factory=list)
    daily_macros: List[dict] = Field(default_factory=list)
    weekly_avg_calories: int = 0
    days_hit_calorie_goal: int = 0
    days_hit_protein_goal: int = 0
    top_foods: List[dict] = Field(default_factory=list)
    inflammation_trend: List[float] = Field(default_factory=list)
    week_over_week_delta: dict = Field(default_factory=dict)
    ai_narrative: str = ""
    user_first_name: Optional[str] = None


def _resolve_first_name(db, user_id: str) -> Optional[str]:
    try:
        row = (
            db.client.table("users")
            .select("first_name,full_name,email")
            .eq("id", user_id)
            .single()
            .execute()
        )
        d = row.data or {}
        if d.get("first_name"):
            return d["first_name"]
        if d.get("full_name"):
            return d["full_name"].split(" ")[0]
        if d.get("email"):
            return d["email"].split("@")[0]
    except Exception:
        pass
    return None


@router.post("/reports/daily", response_model=DailyNutritionReport)
async def daily_nutrition_report(
    report_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Daily nutrition report — fires once per day after the user logs dinner.
    Returns calorie/macro totals, inflammation score + contributors, top
    foods, AI summary, and 1-3 tomorrow-improvement suggestions.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]
        target_date = report_date or datetime.utcnow().date().isoformat()

        summary = get_daily_nutrition_summary(db, user_id, target_date) or {}

        # Inflammation aggregate from food_logs (column added in
        # migrations/add_food_logs_inflammation.sql).
        infl_score: Optional[float] = None
        contributors: List[str] = []
        try:
            rows = (
                db.client.table("food_logs")
                .select("food_name,inflammation_score,inflammation_signals")
                .eq("user_id", user_id)
                .gte("logged_at", f"{target_date}T00:00:00")
                .lte("logged_at", f"{target_date}T23:59:59")
                .execute()
            ).data or []
            scored = [r for r in rows if r.get("inflammation_score") is not None]
            if scored:
                infl_score = sum(r["inflammation_score"] for r in scored) / len(scored)
                # Highest-inflammation foods drive the contributors list
                scored.sort(key=lambda r: r["inflammation_score"], reverse=True)
                contributors = [r["food_name"] for r in scored[:3] if r.get("food_name")]
        except Exception as e:
            logger.warning(f"Inflammation aggregation failed: {e}")

        first_name = _resolve_first_name(db, user_id)

        # AI summary + tomorrow suggestions. Falls back to a deterministic
        # message if Gemini is unavailable so the report still delivers.
        ai_summary, tomorrow = _ai_daily_narrative(
            first_name=first_name,
            calories=summary.get("total_calories", 0),
            target=summary.get("calorie_target", 2000),
            protein=summary.get("total_protein_g", 0),
            inflammation=infl_score,
            contributors=contributors,
        )

        return DailyNutritionReport(
            date=target_date,
            calories_consumed=int(summary.get("total_calories", 0)),
            calorie_target=int(summary.get("calorie_target", 2000)),
            macros={
                "protein_g": summary.get("total_protein_g", 0),
                "carbs_g": summary.get("total_carbs_g", 0),
                "fat_g": summary.get("total_fat_g", 0),
                "fiber_g": summary.get("total_fiber_g", 0),
            },
            inflammation_score=infl_score,
            inflammation_top_contributors=contributors,
            top_foods=summary.get("top_foods", []),
            ai_summary=ai_summary,
            tomorrow_suggestions=tomorrow,
            user_first_name=first_name,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Daily nutrition report failed: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_reports")


@router.post("/reports/weekly", response_model=WeeklyNutritionReport)
async def weekly_nutrition_report(
    week_start: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Weekly nutrition report — fires every Sunday at user-local 09:00.
    Returns 7-day arrays + week-over-week deltas + AI narrative.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Default: most recent ISO week (Mon..Sun)
        today = datetime.utcnow().date()
        if week_start:
            ws = date_type.fromisoformat(week_start)
        else:
            ws = today - timedelta(days=today.weekday())
        we = ws + timedelta(days=6)

        weekly = get_weekly_nutrition_summary(db, user_id, ws.isoformat()) or {}

        daily_cals = weekly.get("daily_calories", []) or []
        daily_macros = weekly.get("daily_macros", []) or []
        weekly_avg = int(sum(daily_cals) / len(daily_cals)) if daily_cals else 0
        target = weekly.get("calorie_target", 2000) or 2000
        protein_target = weekly.get("protein_target_g", 130) or 130
        days_cal = sum(1 for c in daily_cals if abs(c - target) / max(target, 1) <= 0.10)
        days_protein = sum(
            1 for m in daily_macros
            if (m.get("protein_g", 0) or 0) >= protein_target * 0.9
        )

        # Inflammation 7-day trend (avg per day)
        infl_trend: List[float] = []
        try:
            for i in range(7):
                day = ws + timedelta(days=i)
                rows = (
                    db.client.table("food_logs")
                    .select("inflammation_score")
                    .eq("user_id", user_id)
                    .gte("logged_at", f"{day.isoformat()}T00:00:00")
                    .lte("logged_at", f"{day.isoformat()}T23:59:59")
                    .execute()
                ).data or []
                scored = [r["inflammation_score"] for r in rows if r.get("inflammation_score") is not None]
                infl_trend.append(round(sum(scored) / len(scored), 1) if scored else 0.0)
        except Exception:
            infl_trend = []

        # Week-over-week delta
        prev_start = ws - timedelta(days=7)
        prev_weekly = get_weekly_nutrition_summary(db, user_id, prev_start.isoformat()) or {}
        prev_cals = prev_weekly.get("daily_calories", []) or []
        prev_avg = int(sum(prev_cals) / len(prev_cals)) if prev_cals else 0
        delta = {
            "calories_avg_delta": weekly_avg - prev_avg,
            "calories_avg_pct": (
                round((weekly_avg - prev_avg) / max(prev_avg, 1) * 100, 1)
                if prev_avg else 0.0
            ),
        }

        first_name = _resolve_first_name(db, user_id)
        narrative = _ai_weekly_narrative(
            first_name=first_name,
            avg=weekly_avg,
            target=target,
            days_cal=days_cal,
            days_protein=days_protein,
            delta=delta,
        )

        return WeeklyNutritionReport(
            week_start=ws.isoformat(),
            week_end=we.isoformat(),
            daily_calories=daily_cals,
            daily_macros=daily_macros,
            weekly_avg_calories=weekly_avg,
            days_hit_calorie_goal=days_cal,
            days_hit_protein_goal=days_protein,
            top_foods=weekly.get("top_foods", []),
            inflammation_trend=infl_trend,
            week_over_week_delta=delta,
            ai_narrative=narrative,
            user_first_name=first_name,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Weekly nutrition report failed: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_reports")


def _ai_daily_narrative(
    first_name: Optional[str],
    calories: int,
    target: int,
    protein: float,
    inflammation: Optional[float],
    contributors: List[str],
) -> tuple[str, List[str]]:
    """Generate AI summary + 1-3 tomorrow tips. Falls back deterministically."""
    name = first_name or "you"
    diff = calories - target
    diff_pct = abs(diff) / max(target, 1) * 100
    if diff_pct <= 10:
        cal_msg = f"{name.title()}, you nailed your calorie target today."
    elif diff > 0:
        cal_msg = f"{name.title()}, you went over by {diff} kcal today."
    else:
        cal_msg = f"{name.title()}, you came in {abs(diff)} kcal under target."

    tips: List[str] = []
    if protein < 100:
        tips.append("Aim for one extra palm-sized protein source tomorrow.")
    if inflammation is not None and inflammation >= 6:
        tips.append(
            "Inflammation ran high — swap one ultra-processed item for whole-food alternative."
        )
    if not tips:
        tips.append("Keep showing up — consistency beats perfection.")

    try:
        gemini = GeminiService()
        prompt = (
            f"Daily nutrition recap for {name}. Calories {calories}/{target}, "
            f"protein {protein}g, inflammation {inflammation}, "
            f"top contributors {contributors[:3]}. "
            "Write a single warm 2-sentence summary, then list 2-3 concrete "
            "tomorrow-improvement tips. Use first name once, no emojis."
        )
        text = gemini.generate_text_sync(prompt, temperature=0.6, max_output_tokens=180)
        if text:
            lines = [l.strip("-• ").strip() for l in text.splitlines() if l.strip()]
            if len(lines) >= 2:
                return lines[0], lines[1:4]
    except Exception as e:
        logger.warning(f"Gemini daily narrative fallback: {e}")
    return cal_msg, tips


def _ai_weekly_narrative(
    first_name: Optional[str],
    avg: int,
    target: int,
    days_cal: int,
    days_protein: int,
    delta: dict,
) -> str:
    name = first_name or "you"
    pct = delta.get("calories_avg_pct", 0)
    arrow = "↑" if pct > 0 else ("↓" if pct < 0 else "→")
    base = (
        f"{name.title()}, you averaged {avg} kcal/day this week ({arrow} {abs(pct)}% vs last). "
        f"Hit calorie goal {days_cal}/7 days, protein goal {days_protein}/7."
    )
    try:
        gemini = GeminiService()
        prompt = (
            f"Weekly nutrition recap for {name}. Avg {avg}/{target} kcal, "
            f"days_hit_cal {days_cal}/7, days_hit_protein {days_protein}/7, "
            f"week-over-week delta {delta}. Write 3 short sentences. First name once."
        )
        text = gemini.generate_text_sync(prompt, temperature=0.6, max_output_tokens=160)
        return text.strip() if text else base
    except Exception:
        return base
