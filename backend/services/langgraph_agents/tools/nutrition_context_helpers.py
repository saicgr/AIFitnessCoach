"""
Context pre-fetch helpers for the nutrition agent.

These run BEFORE the LLM call (via `_build_agent_state`) so the agent has
the user's full day context as part of its system prompt — no tool round
trips needed for the common preset queries like "What can I eat now?".

Each function is independent and tolerates failure — if any helper raises,
`_build_agent_state` catches it via `asyncio.gather(return_exceptions=True)`
and marks `context_partial=True` without blocking the rest of the state.

The three public helpers return plain dicts / lists (no LangChain `@tool`
decoration). Thin `@tool`-wrapped versions live in `nutrition_tools.py` for
freeform agent queries that fall outside the preset pill flow.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from core.supabase_client import get_supabase
from core.timezone_utils import get_user_today, local_date_to_utc_range

logger = logging.getLogger(__name__)


# ── Daily nutrition context ────────────────────────────────────────────────

async def fetch_daily_nutrition_context(
    user_id: str,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """Aggregate today's logged meals + targets + macro remainders.

    Returns a dict shaped to plug directly into the nutrition agent's system
    prompt and into the `/meal-context` endpoint response. All arithmetic is
    done in Python (not SQL) so we can be precise about which fields are
    truly known vs unknown (target missing ⇒ calorie_remainder=None).
    """
    db = get_supabase_db()
    today = get_user_today(timezone_str)

    # Daily summary (totals + meal list) — helper handles tz conversion.
    summary = db.get_daily_nutrition_summary(
        user_id, today, timezone_str=timezone_str
    )

    # User's targets (preferences-first, users-table fallback).
    targets = db.get_user_nutrition_targets(user_id)

    # Consumed totals from the summary (zero-safe).
    cal_consumed = int(summary.get("total_calories") or 0)
    p_consumed = float(summary.get("total_protein_g") or 0)
    c_consumed = float(summary.get("total_carbs_g") or 0)
    f_consumed = float(summary.get("total_fat_g") or 0)
    fib_consumed = float(summary.get("total_fiber_g") or 0)

    # Targets may be None when user hasn't set them.
    cal_target = targets.get("daily_calorie_target")
    p_target = targets.get("daily_protein_target_g")
    c_target = targets.get("daily_carbs_target_g")
    f_target = targets.get("daily_fat_target_g")

    def _remainder(consumed, target):
        if target is None:
            return None
        return max(-9999, target - consumed)  # allow negative when over

    cal_remainder = _remainder(cal_consumed, cal_target)
    over_budget = cal_remainder is not None and cal_remainder < 0

    # Meal-type coverage today (avoid proposing a 4th breakfast).
    meals = summary.get("meals") or []
    meal_types_logged = sorted({
        (m.get("meal_type") or "").lower()
        for m in meals
        if m.get("meal_type")
    })

    # Ultra-processed rows today.
    ultra_processed_count = sum(
        1 for m in meals if m.get("is_ultra_processed") is True
    )

    return {
        "date": today,
        "timezone": timezone_str,
        "total_calories": cal_consumed,
        "total_protein_g": round(p_consumed, 1),
        "total_carbs_g": round(c_consumed, 1),
        "total_fat_g": round(f_consumed, 1),
        "total_fiber_g": round(fib_consumed, 1),
        "target_calories": cal_target,
        "target_protein_g": p_target,
        "target_carbs_g": c_target,
        "target_fat_g": f_target,
        "calorie_remainder": cal_remainder,
        "macros_remaining": {
            "protein_g": _remainder(p_consumed, p_target),
            "carbs_g": _remainder(c_consumed, c_target),
            "fat_g": _remainder(f_consumed, f_target),
        },
        "meal_count": len(meals),
        "meal_types_logged": meal_types_logged,
        "ultra_processed_count_today": ultra_processed_count,
        "over_budget": over_budget,
    }


# ── Recent favorites ───────────────────────────────────────────────────────

async def fetch_recent_favorites(
    user_id: str,
    limit: int = 5,
    exclude_days: int = 0,
) -> List[Dict[str, Any]]:
    """Return the user's most-logged saved foods.

    If `exclude_days > 0`, skip saved foods whose `last_logged_at` falls
    within the last N days — useful for the "show me a favorite I haven't
    had recently" pill.

    Returns an empty list when the user has no saved_foods rows.
    """
    client = get_supabase().client
    query = (
        client.table("saved_foods")
        .select(
            "id, name, total_calories, total_protein_g, total_carbs_g, "
            "total_fat_g, times_logged, last_logged_at"
        )
        .eq("user_id", user_id)
        .order("times_logged", desc=True)
        .limit(limit * 3 if exclude_days > 0 else limit)
    )
    resp = query.execute()
    rows = resp.data or []

    if exclude_days > 0:
        cutoff = datetime.utcnow() - timedelta(days=exclude_days)
        filtered: List[Dict[str, Any]] = []
        for row in rows:
            last = row.get("last_logged_at")
            if not last:
                filtered.append(row)
                continue
            try:
                last_dt = datetime.fromisoformat(last.replace("Z", "+00:00"))
                if last_dt.replace(tzinfo=None) < cutoff:
                    filtered.append(row)
            except Exception:
                # Bad timestamp — keep the row rather than silently dropping
                filtered.append(row)
            if len(filtered) >= limit:
                break
        rows = filtered[:limit]
    else:
        rows = rows[:limit]

    # Shape down to what the agent / frontend actually needs.
    out: List[Dict[str, Any]] = []
    for row in rows:
        last = row.get("last_logged_at")
        days_ago: Optional[int] = None
        if last:
            try:
                last_dt = datetime.fromisoformat(last.replace("Z", "+00:00"))
                delta = datetime.utcnow() - last_dt.replace(tzinfo=None)
                days_ago = max(0, delta.days)
            except Exception:
                days_ago = None
        out.append({
            "id": row.get("id"),
            "name": row.get("name"),
            "total_calories": row.get("total_calories"),
            "total_protein_g": float(row.get("total_protein_g") or 0),
            "total_carbs_g": float(row.get("total_carbs_g") or 0),
            "total_fat_g": float(row.get("total_fat_g") or 0),
            "times_logged": row.get("times_logged") or 0,
            "last_logged_days_ago": days_ago,
        })
    return out


# ── Today's workout ────────────────────────────────────────────────────────

async def fetch_todays_workout(
    user_id: str,
    timezone_str: str = "UTC",
) -> Optional[Dict[str, Any]]:
    """Today's scheduled workout in the user's timezone.

    Returns a compact dict suitable for injection into the system prompt, or
    `None` if no workout is scheduled today (rest day).

    Uses the existing `db.list_workouts` helper (applies `is_current=True`
    and status!='generating' filters automatically).
    """
    db = get_supabase_db()
    today = get_user_today(timezone_str)
    utc_start, utc_end = local_date_to_utc_range(today, timezone_str)

    workouts = db.list_workouts(
        user_id,
        from_date=utc_start,
        to_date=utc_end,
        order_asc=True,
        limit=1,
    )
    if not workouts:
        return None

    w = workouts[0]
    # Extract scheduled time-of-day from the scheduled_date (which is a tz-aware ts).
    sched_time: Optional[str] = None
    sched_raw = w.get("scheduled_date")
    if sched_raw:
        try:
            # Normalize to ISO + strip microseconds
            if isinstance(sched_raw, str):
                dt = datetime.fromisoformat(sched_raw.replace("Z", "+00:00"))
            else:
                dt = sched_raw
            sched_time = dt.strftime("%H:%M")
        except Exception:
            sched_time = None

    # Derive primary muscle groups from exercises_json if present.
    primary_muscles: List[str] = []
    try:
        exs = w.get("exercises_json") or []
        seen = set()
        for ex in exs:
            muscle = (ex.get("primary_muscle") or ex.get("muscle_group") or "").strip().lower()
            if muscle and muscle not in seen:
                seen.add(muscle)
                primary_muscles.append(muscle)
        primary_muscles = primary_muscles[:4]  # cap for prompt brevity
    except Exception:
        primary_muscles = []

    return {
        "id": w.get("id"),
        "name": w.get("name"),
        "type": w.get("type"),
        "is_completed": bool(w.get("is_completed")),
        "duration_minutes": w.get("duration_minutes"),
        "scheduled_date": sched_raw if isinstance(sched_raw, str) else None,
        "scheduled_time_local": sched_time,
        "primary_muscles": primary_muscles,
        "exercise_count": len(w.get("exercises_json") or []),
    }
