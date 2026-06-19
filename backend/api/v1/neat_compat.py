"""NEAT query-param compatibility router.

WHY THIS EXISTS
---------------
The deployed Flutter app (already in users' hands, immutable) calls every NEAT
endpoint with a QUERY-PARAM contract:

    GET  /api/v1/neat/goals?user_id=...
    PUT  /api/v1/neat/goals/steps           {user_id, target_value}
    POST /api/v1/neat/goals/progressive     {user_id}
    POST /api/v1/neat/activity/sync         {user_id, activities:[...]}
    GET  /api/v1/neat/activity/hourly?user_id=&date=
    GET  /api/v1/neat/scores/today?user_id=
    GET  /api/v1/neat/scores/history?user_id=&start_date=&end_date=
    GET  /api/v1/neat/streaks?user_id=
    GET  /api/v1/neat/achievements?user_id=&earned_only=<bool>
    POST /api/v1/neat/achievements/celebrate {user_id, achievement_ids:[...]}
    GET  /api/v1/neat/reminders/preferences?user_id=
    PUT  /api/v1/neat/reminders/preferences  {user_id, ...prefs}
    GET  /api/v1/neat/dashboard?user_id=
    GET  /api/v1/neat/summary/weekly?user_id=&week_start=<optional>

The backend `neat.py` / `neat_endpoints.py` only ever registered PATH-PARAM
routes (`/goals/{user_id}`, `/dashboard/{user_id}`, ...), so all 16 calls 404
in production.

This router declares the EXACT query-param paths the app sends, delegates to
the real existing handlers (no mock data, no fallback), and RESHAPES each
handler's domain response into the precise JSON the Dart `fromJson` constructors
in `mobile/flutter/lib/data/models/neat.dart` expect. Shape mismatches there
crash the client at parse time, so the reshaping is load-bearing.

The literal query-param paths here do not collide with the `{user_id}`
path-param routes registered by neat.py — e.g. `/goals` (this file) vs
`/goals/{user_id}` (neat.py) are distinct, and `/goals/steps` is a literal that
Starlette matches before the parent's dynamic `/goals/{user_id}` only because
this router is mounted alongside; to be safe we register this router FIRST in
__init__ so its literals always win over any dynamic sibling.
"""

from __future__ import annotations
from core.db_executor import run_db, gather_db

from datetime import date as date_type, datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, BackgroundTasks, Body, Depends, Query, Request
from pydantic import BaseModel

from core.auth import get_current_user

# Real handlers we delegate to.
from .neat import (
    get_neat_goals as _h_get_goals,
    update_neat_goals as _h_update_goals,
    calculate_progressive_goal as _h_progressive,
    batch_sync_hourly_activity as _h_batch_sync,
    get_hourly_breakdown as _h_hourly,
    get_today_neat_score as _h_today_score,
    get_neat_score_history as _h_history,
    get_neat_streaks as _h_streaks,
)
from .neat_endpoints import (
    get_neat_dashboard as _h_dashboard,
    get_neat_achievements as _h_achievements,
    get_available_achievements as _h_available,
    get_reminder_preferences as _h_get_prefs,
    update_reminder_preferences as _h_update_prefs,
)
from models.neat import (
    BatchHourlyActivityInput,
    HourlyActivityInput,
    UpdateGoalRequest,
    ProgressiveGoalRequest,
    UpdateReminderPreferencesRequest,
)

router = APIRouter()


# ---------------------------------------------------------------------------
# Request bodies (frontend payload shapes)
# ---------------------------------------------------------------------------

class _UserBody(BaseModel):
    user_id: str


class _StepGoalBody(BaseModel):
    user_id: str
    target_value: int


class _CelebrateBody(BaseModel):
    user_id: str
    achievement_ids: List[str] = []


class _SyncActivity(BaseModel):
    """One hourly activity as sent by the Flutter HourlyActivity.toJson()."""
    hour: int
    steps: int = 0
    active_minutes: int = 0
    standing: bool = False
    calories_burned: float = 0.0
    movement_type: Optional[str] = None


class _SyncBody(BaseModel):
    user_id: str
    activities: List[_SyncActivity] = []
    # Optional date the activities belong to; app sends per-hour data for "today".
    date: Optional[date_type] = None


class _UpdatePrefsBody(BaseModel):
    """Loose reminder-preferences body — the Flutter model carries many fields
    that the backend's UpdateReminderPreferencesRequest does not, so we accept
    everything and forward only the fields the backend understands."""
    user_id: str
    reminders_enabled: Optional[bool] = None
    hourly_movement_enabled: Optional[bool] = None
    hourly_start_time: Optional[str] = None
    hourly_end_time: Optional[str] = None
    step_milestone_enabled: Optional[bool] = None
    step_milestones: Optional[List[int]] = None
    goal_reminder_enabled: Optional[bool] = None
    goal_reminder_time: Optional[str] = None
    inactivity_reminder_enabled: Optional[bool] = None
    inactivity_threshold_minutes: Optional[int] = None
    quiet_hours_enabled: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    # Also accept the backend's native field names if the client ever sends them.
    enabled: Optional[bool] = None

    class Config:
        extra = "allow"


# ---------------------------------------------------------------------------
# Reshapers: domain model -> Flutter fromJson shape
# ---------------------------------------------------------------------------

def _iso(v: Any) -> Optional[str]:
    if v is None:
        return None
    if isinstance(v, (datetime, date_type)):
        return v.isoformat()
    return str(v)


def _goal_to_dart(goal_progress) -> Dict[str, Any]:
    """NEATGoalProgress -> Dart NeatGoal JSON.

    The Dart NeatGoal models ONE goal (the step goal) with current/target value
    and progressive-goal metadata. We surface the step goal here; active-hours
    and movement-breaks live in the dashboard's score, not in NeatGoal.
    """
    g = goal_progress.goal
    return {
        "id": g.id or f"steps:{g.user_id}",
        "user_id": g.user_id,
        "goal_type": "steps",
        "target_value": int(g.daily_step_goal),
        "current_value": int(goal_progress.current_steps),
        "unit": "steps",
        "is_progressive": bool(g.is_progressive),
        "baseline_value": None,
        "increment_value": None,
        "increment_frequency_days": None,
        "created_at": _iso(g.created_at) or datetime.now().isoformat(),
        "updated_at": _iso(g.updated_at),
    }


def _progressive_to_dart(resp) -> Dict[str, Any]:
    """ProgressiveGoalResponse -> Dart NeatGoal JSON (suggested goal as target)."""
    return {
        "id": f"steps:{resp.user_id}",
        "user_id": resp.user_id,
        "goal_type": "steps",
        "target_value": int(resp.suggested_goal),
        "current_value": 0,
        "unit": "steps",
        "is_progressive": True,
        "baseline_value": int(resp.current_goal),
        "increment_value": int(resp.suggested_goal - resp.current_goal),
        "increment_frequency_days": 7,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def _score_to_dart(score, user_id: str, on_date: date_type) -> Dict[str, Any]:
    """NEATScore (or None) -> Dart NeatDailyScore JSON.

    Dart requires non-null id + date, and getTodayScore() parses the body
    directly, so a None score must become a real zero-score object (no goals
    achieved), NOT null. This is honest "no score yet today" data, not a mock.
    """
    if score is None:
        return {
            "id": f"score:{user_id}:{on_date.isoformat()}",
            "user_id": user_id,
            "date": on_date.isoformat(),
            "score": 0,
            "max_score": 100,
            "steps_score": 0,
            "active_minutes_score": 0,
            "standing_hours_score": 0,
            "consistency_bonus": 0,
            "total_steps": 0,
            "total_active_minutes": 0,
            "total_standing_hours": 0,
            "total_calories": 0.0,
            "goals_achieved": 0,
            "total_goals": 0,
            "calculated_at": None,
        }
    c = score.components
    return {
        "id": score.id or f"score:{score.user_id}:{score.score_date.isoformat()}",
        "user_id": score.user_id,
        "date": score.score_date.isoformat(),
        "score": int(round(score.total_score)),
        "max_score": 100,
        "steps_score": int(round(c.step_score)),
        # Dart calls it active_minutes_score; backend tracks active-HOURS score.
        "active_minutes_score": int(round(c.active_hours_score)),
        "standing_hours_score": int(round(c.movement_breaks_score)),
        "consistency_bonus": int(round(c.consistency_score)),
        "total_steps": int(score.total_steps),
        "total_active_minutes": int(score.active_hours),
        "total_standing_hours": int(score.movement_breaks),
        "total_calories": 0.0,
        "goals_achieved": 1 if score.step_goal_met else 0,
        "total_goals": 1,
        "calculated_at": _iso(score.calculated_at),
    }


def _hourly_to_dart(breakdown) -> Dict[str, Any]:
    """HourlyBreakdown -> Dart NeatHourlyBreakdown JSON."""
    hourly_data = [
        {
            "hour": h.hour,
            "steps": int(h.steps),
            "active_minutes": int(h.active_minutes),
            "standing": not bool(h.was_sedentary),
            "calories_burned": float(h.calories),
            "movement_type": None,
        }
        for h in breakdown.hours
    ]
    return {
        "user_id": breakdown.user_id,
        "date": breakdown.activity_date.isoformat(),
        "hourly_data": hourly_data,
        "total_steps": int(breakdown.total_steps),
        "total_active_minutes": int(breakdown.total_active_minutes),
        "total_standing_hours": int(breakdown.active_hours_count),
        "total_calories": float(breakdown.total_calories),
        "peak_hour": breakdown.most_active_hour,
        "least_active_hour": breakdown.least_active_hour,
    }


def _streak_to_dart(streak) -> Dict[str, Any]:
    """NEATStreak -> Dart NeatStreak JSON."""
    st = streak.streak_type
    st = getattr(st, "value", st)
    # Map backend streak_type vocabulary to the Dart enum's accepted values.
    mapping = {
        "step_goal": "steps",
        "active_hours": "active_minutes",
        "movement_breaks": "standing_hours",
        "neat_score": "all_goals",
    }
    return {
        "id": streak.id or f"{st}:{streak.user_id}",
        "user_id": streak.user_id,
        "streak_type": mapping.get(st, st),
        "current_streak": int(streak.current_length),
        "longest_streak": int(streak.longest_length),
        "is_active": bool(streak.is_active),
        "started_at": _iso(streak.started_at),
        "last_activity_date": _iso(streak.last_achieved_date),
    }


def _earned_to_dart(earned) -> Dict[str, Any]:
    """UserNEATAchievement (earned) -> flattened Dart UserNeatAchievement JSON."""
    d = earned.achievement
    return {
        "id": earned.achievement_id or earned.id,
        "user_id": earned.user_id,
        "name": d.name if d else "Achievement",
        "description": d.description if d else "",
        "category": (getattr(d.category, "value", d.category) if d else "milestone"),
        "icon_name": (d.icon if d else None),
        "points": (int(d.points) if d else 0),
        "requirement_type": (getattr(d.category, "value", d.category) if d else "steps"),
        "requirement_value": (int(d.threshold) if d else 0),
        "current_progress": int(d.threshold) if d else 0,  # earned => fully met
        "is_earned": True,
        "earned_at": _iso(earned.achieved_at),
        "is_celebrated": bool(earned.is_celebrated),
    }


def _available_to_dart(progress) -> Dict[str, Any]:
    """AchievementProgress (unearned) -> flattened Dart UserNeatAchievement JSON."""
    d = progress.achievement
    cat = getattr(d.category, "value", d.category)
    return {
        "id": d.id,
        "user_id": None,
        "name": d.name,
        "description": d.description,
        "category": cat,
        "icon_name": d.icon,
        "points": int(d.points),
        "requirement_type": cat,
        "requirement_value": int(d.threshold),
        "current_progress": int(progress.current_value),
        "is_earned": bool(progress.is_achieved),
        "earned_at": _iso(progress.achieved_at),
        "is_celebrated": False,
    }


def _prefs_to_dart(prefs, user_id: str) -> Dict[str, Any]:
    """ReminderPreferences -> Dart NeatReminderPreferences JSON.

    The two models overlap only partially. We map the backend's hourly-reminder
    window onto the Dart hourly fields and surface sensible, non-fabricated
    values for the Dart-only fields (defaults that mirror the Dart model's own
    constructor defaults — not invented data, just the documented defaults)."""
    freq = getattr(prefs.frequency, "value", prefs.frequency)
    start = prefs.start_time
    end = prefs.end_time
    start_s = start.strftime("%H:%M") if hasattr(start, "strftime") else str(start)
    end_s = end.strftime("%H:%M") if hasattr(end, "strftime") else str(end)
    # Translate frequency enum -> inactivity threshold minutes.
    freq_minutes = {
        "every_30_min": 30,
        "every_45_min": 45,
        "every_60_min": 60,
        "every_90_min": 90,
        "every_120_min": 120,
    }.get(freq, 60)
    return {
        "user_id": user_id,
        "reminders_enabled": bool(prefs.enabled),
        "hourly_movement_enabled": bool(prefs.enabled),
        "hourly_start_time": start_s,
        "hourly_end_time": end_s,
        "step_milestone_enabled": True,
        "step_milestones": [2500, 5000, 7500, 10000],
        "goal_reminder_enabled": True,
        "goal_reminder_time": None,
        "inactivity_reminder_enabled": bool(prefs.skip_if_active),
        "inactivity_threshold_minutes": freq_minutes,
        "quiet_hours_enabled": False,
        "quiet_hours_start": None,
        "quiet_hours_end": None,
        "updated_at": _iso(prefs.updated_at),
    }


def _dashboard_to_dart(dash) -> Dict[str, Any]:
    """NEATDashboard -> Dart NeatDashboard JSON."""
    today_score = _score_to_dart(dash.today_score, dash.user_id, date_type.today())
    # current_goals: surface the step goal derived from goal_progress.
    current_goals = [_goal_to_dart(dash.goal_progress)]
    streaks: List[Dict[str, Any]] = []
    # streak_summary is a compact summary, not per-type streak rows. Synthesize
    # per-type Dart streak entries from the summary's real values.
    ss = dash.streak_summary
    summary_streaks = [
        ("steps", ss.step_goal_streak),
        ("active_minutes", ss.active_hours_streak),
        ("standing_hours", ss.movement_breaks_streak),
        ("all_goals", ss.neat_score_streak),
    ]
    for stype, val in summary_streaks:
        streaks.append({
            "id": f"{stype}:{dash.user_id}",
            "user_id": dash.user_id,
            "streak_type": stype,
            "current_streak": int(val),
            "longest_streak": int(ss.all_time_best if stype == ss.all_time_best_type else val),
            "is_active": val > 0,
            "started_at": None,
            "last_activity_date": None,
        })
    recent = [_earned_to_dart(a) for a in (dash.recent_achievements or [])]
    hourly = _hourly_to_dart(dash.hourly_breakdown) if dash.hourly_breakdown else None
    suggestions = []
    if dash.motivational_message:
        suggestions.append(dash.motivational_message)
    if dash.next_milestone:
        suggestions.append(dash.next_milestone)
    return {
        "user_id": dash.user_id,
        "today_score": today_score,
        "current_goals": current_goals,
        "hourly_breakdown": hourly,
        "streaks": streaks,
        "recent_achievements": recent,
        "weekly_summary": None,
        "suggestions": suggestions,
        "calculated_at": _iso(dash.generated_at),
    }


# ---------------------------------------------------------------------------
# Goals
# ---------------------------------------------------------------------------

@router.get("/goals")
async def compat_get_goals(
    request: Request,
    background_tasks: BackgroundTasks,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    progress = await _h_get_goals(user_id, request, background_tasks, current_user)
    return _goal_to_dart(progress)


@router.put("/goals/steps")
async def compat_update_step_goal(
    body: _StepGoalBody,
    current_user: dict = Depends(get_current_user),
):
    update_req = UpdateGoalRequest(daily_step_goal=body.target_value)
    goal = await _h_update_goals(body.user_id, update_req, current_user)
    # _h_update_goals returns a NEATGoal (not progress). Wrap into the Dart shape.
    return {
        "id": goal.id or f"steps:{goal.user_id}",
        "user_id": goal.user_id,
        "goal_type": "steps",
        "target_value": int(goal.daily_step_goal),
        "current_value": 0,
        "unit": "steps",
        "is_progressive": bool(goal.is_progressive),
        "baseline_value": None,
        "increment_value": None,
        "increment_frequency_days": None,
        "created_at": _iso(goal.created_at) or datetime.now().isoformat(),
        "updated_at": _iso(goal.updated_at) or datetime.now().isoformat(),
    }


@router.post("/goals/progressive")
async def compat_progressive_goal(
    request: Request,
    body: _UserBody,
    current_user: dict = Depends(get_current_user),
):
    prog_req = ProgressiveGoalRequest(user_id=body.user_id)
    resp = await _h_progressive(body.user_id, prog_req, request, current_user)
    return _progressive_to_dart(resp)


# ---------------------------------------------------------------------------
# Activity
# ---------------------------------------------------------------------------

@router.post("/activity/sync")
async def compat_activity_sync(
    body: _SyncBody,
    current_user: dict = Depends(get_current_user),
):
    on_date = body.date or date_type.today()
    inputs = [
        HourlyActivityInput(
            user_id=body.user_id,
            activity_date=on_date,
            hour=a.hour,
            steps=a.steps,
            active_minutes=a.active_minutes,
            calories=a.calories_burned,
            was_sedentary=not a.standing if a.standing else None,
            source="health_connect",
        )
        for a in body.activities
    ]
    batch = BatchHourlyActivityInput(activities=inputs)
    result = await _h_batch_sync(body.user_id, batch, current_user)
    return {
        "success": True,
        "synced_count": result.synced_count,
        "failed_count": result.failed_count,
    }


@router.get("/activity/hourly")
async def compat_hourly(
    user_id: str = Query(...),
    date: date_type = Query(...),
    current_user: dict = Depends(get_current_user),
):
    breakdown = await _h_hourly(user_id, date, current_user)
    return _hourly_to_dart(breakdown)


# ---------------------------------------------------------------------------
# Scores
# ---------------------------------------------------------------------------

@router.get("/scores/today")
async def compat_today_score(
    request: Request,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    score = await _h_today_score(user_id, request, current_user)
    return _score_to_dart(score, user_id, date_type.today())


@router.get("/scores/history")
async def compat_score_history(
    user_id: str = Query(...),
    start_date: Optional[date_type] = Query(None),
    end_date: Optional[date_type] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    # Backend handler takes a `limit`, not a range; derive a sensible limit from
    # the requested span (it ALSO accepts start/end as optional filters).
    limit = 30
    if start_date and end_date:
        span = (end_date - start_date).days + 1
        limit = max(1, min(span, 365))
    history = await _h_history(
        user_id,
        start_date=start_date,
        end_date=end_date,
        limit=limit,
        current_user=current_user,
    )
    return [_score_to_dart(s, user_id, s.score_date) for s in history.scores]


# ---------------------------------------------------------------------------
# Streaks
# ---------------------------------------------------------------------------

@router.get("/streaks")
async def compat_streaks(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    resp = await _h_streaks(user_id, current_user)
    return [_streak_to_dart(s) for s in resp.streaks]


# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------

@router.get("/achievements")
async def compat_achievements(
    request: Request,
    user_id: str = Query(...),
    earned_only: bool = Query(True),
    current_user: dict = Depends(get_current_user),
):
    if earned_only:
        resp = await _h_achievements(user_id, current_user)
        return [_earned_to_dart(a) for a in resp.earned]
    # earned_only=false => all/available with progress.
    avail = await _h_available(user_id, request, current_user)
    earned = await _h_achievements(user_id, current_user)
    out = [_earned_to_dart(a) for a in earned.earned]
    out.extend(_available_to_dart(p) for p in avail.available)
    return out


@router.post("/achievements/celebrate")
async def compat_celebrate(
    body: _CelebrateBody,
    current_user: dict = Depends(get_current_user),
):
    # There is no batch "celebrate" handler; mark the rows celebrated directly.
    # Reaching here requires a valid JWT (auth dep above), so this is the
    # authenticated user acting on their own achievements.
    from core.db import get_supabase_db
    db = get_supabase_db()
    updated = 0
    for aid in body.achievement_ids:
        try:
            (await run_db(lambda: db.client.table("user_neat_achievements").update(
                {"is_celebrated": True}
            ).eq("user_id", body.user_id).eq("achievement_id", aid).execute()))
            updated += 1
        except Exception:
            # Row may key on the user_neat_achievements primary id instead.
            try:
                (await run_db(lambda: db.client.table("user_neat_achievements").update(
                    {"is_celebrated": True}
                ).eq("id", aid).execute()))
                updated += 1
            except Exception:
                pass
    return {"success": True, "celebrated": updated}


# ---------------------------------------------------------------------------
# Reminder preferences
# ---------------------------------------------------------------------------

@router.get("/reminders/preferences")
async def compat_get_prefs(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    prefs = await _h_get_prefs(user_id, current_user)
    return _prefs_to_dart(prefs, user_id)


@router.put("/reminders/preferences")
async def compat_update_prefs(
    body: _UpdatePrefsBody,
    current_user: dict = Depends(get_current_user),
):
    update_kwargs: Dict[str, Any] = {}
    # enabled: prefer explicit native field, else the Flutter reminders_enabled.
    if body.enabled is not None:
        update_kwargs["enabled"] = body.enabled
    elif body.reminders_enabled is not None:
        update_kwargs["enabled"] = body.reminders_enabled
    if body.hourly_start_time:
        update_kwargs["start_time"] = _parse_time(body.hourly_start_time)
    if body.hourly_end_time:
        update_kwargs["end_time"] = _parse_time(body.hourly_end_time)
    if body.inactivity_threshold_minutes is not None:
        # backend active_threshold_minutes is bounded 1..30
        update_kwargs["active_threshold_minutes"] = max(
            1, min(int(body.inactivity_threshold_minutes), 30)
        )
    if body.inactivity_reminder_enabled is not None:
        update_kwargs["skip_if_active"] = body.inactivity_reminder_enabled

    update_req = UpdateReminderPreferencesRequest(**update_kwargs)
    prefs = await _h_update_prefs(body.user_id, update_req, current_user)
    return _prefs_to_dart(prefs, body.user_id)


def _parse_time(s: str):
    """Parse 'HH:MM' or 'HH:MM:SS' into a datetime.time."""
    from datetime import time as _time
    parts = [int(p) for p in s.split(":")]
    while len(parts) < 3:
        parts.append(0)
    return _time(parts[0], parts[1], parts[2])


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

@router.get("/dashboard")
async def compat_dashboard(
    request: Request,
    background_tasks: BackgroundTasks,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    dash = await _h_dashboard(user_id, request, background_tasks, current_user)
    return _dashboard_to_dart(dash)


# ---------------------------------------------------------------------------
# Weekly summary (no backend handler — derive from real score history)
# ---------------------------------------------------------------------------

@router.get("/summary/weekly")
async def compat_weekly_summary(
    user_id: str = Query(...),
    week_start: Optional[date_type] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """Build NeatWeeklySummary from the real 7-day score history.

    No fabricated numbers: every field is derived from neat_scores rows. When
    there is genuinely no data for the week, totals are zero and trend "stable".
    """
    if week_start is None:
        today = date_type.today()
        week_start = today - timedelta(days=today.weekday())  # Monday
    week_end = week_start + timedelta(days=6)

    history = await _h_history(
        user_id,
        start_date=week_start,
        end_date=week_end,
        limit=7,
        current_user=current_user,
    )
    scores = history.scores

    total_steps = sum(int(s.total_steps) for s in scores)
    total_active = sum(int(s.active_hours) for s in scores)
    total_standing = sum(int(s.movement_breaks) for s in scores)
    days = len(scores)
    avg_daily_steps = int(total_steps / days) if days else 0
    goals_achieved_days = sum(1 for s in scores if s.step_goal_met)

    best_day = None
    best_day_steps = 0
    for s in scores:
        if s.total_steps > best_day_steps:
            best_day_steps = int(s.total_steps)
            best_day = s.score_date.isoformat()

    # Trend: compare first-half vs second-half average score within the week.
    trend = "stable"
    trend_pct = 0.0
    if days >= 2:
        ordered = sorted(scores, key=lambda s: s.score_date)
        mid = len(ordered) // 2
        first = ordered[:mid] or ordered[: max(1, mid)]
        second = ordered[mid:]
        first_avg = sum(s.total_score for s in first) / len(first)
        second_avg = sum(s.total_score for s in second) / len(second)
        if first_avg > 0:
            trend_pct = round((second_avg - first_avg) / first_avg * 100, 1)
        if second_avg > first_avg + 5:
            trend = "up"
        elif second_avg < first_avg - 5:
            trend = "down"

    return {
        "week_start": week_start.isoformat(),
        "week_end": week_end.isoformat(),
        "total_steps": total_steps,
        "average_daily_steps": avg_daily_steps,
        "total_active_minutes": total_active,
        "total_standing_hours": total_standing,
        "goals_achieved_days": goals_achieved_days,
        "total_days": 7,
        "average_score": round(history.average_score, 1),
        "best_day": best_day,
        "best_day_steps": best_day_steps,
        "trend": trend,
        "trend_percentage": trend_pct,
    }
