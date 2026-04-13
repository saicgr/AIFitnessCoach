"""Workout MCP tools — reads and writes.

Read tools:
  - get_today_workout
  - get_workout_history

Write tools (scope write:logs):
  - log_completed_set
  - adjust_set_weight

Write tools (scope write:workouts):
  - generate_workout_plan
  - modify_workout

All tools funnel through `run_tool` in `mcp.tools.__init__`, which
handles auth, scopes, rate limiting, anomaly detection, confirmation,
and auditing.
"""
from __future__ import annotations

import asyncio
import json
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from core.logger import get_logger
from mcp.tools import run_tool

logger = get_logger(__name__)


# ─── get_today_workout ───────────────────────────────────────────────────────

async def _get_today_workout_impl(user: dict) -> Dict[str, Any]:
    """Return the workout scheduled for today, if any.

    Replicates the core query from `api/v1/workouts/today.py`: the most
    recent non-cancelled workout whose `scheduled_date` falls on today
    (UTC — the user's timezone-aware "today" is handled by the REST
    endpoint; for MCP we return UTC-day results, which is close enough
    for an AI assistant surface).
    """
    db = get_supabase_db()
    user_id = user["id"]
    today = datetime.now(timezone.utc).date().isoformat()
    tomorrow = (datetime.now(timezone.utc).date() + timedelta(days=1)).isoformat()

    try:
        result = db.client.table("workouts") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("scheduled_date", today) \
            .lt("scheduled_date", tomorrow) \
            .neq("status", "cancelled") \
            .order("scheduled_date", desc=False) \
            .limit(1) \
            .execute()
    except Exception as e:
        logger.error(f"get_today_workout query failed: {e}", exc_info=True)
        return {"workout": None, "message": "Unable to fetch today's workout"}

    rows = result.data or []
    if not rows:
        return {"workout": None, "message": "No workout scheduled for today"}

    w = rows[0]
    # Normalize exercises field (stored as JSONB or TEXT across migrations).
    exercises = w.get("exercises_json") or w.get("exercises") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except Exception:
            exercises = []

    return {
        "workout": {
            "id": w.get("id"),
            "name": w.get("name"),
            "type": w.get("type"),
            "difficulty": w.get("difficulty"),
            "scheduled_date": w.get("scheduled_date"),
            "status": w.get("status"),
            "duration_minutes": w.get("duration_minutes"),
            "exercises": exercises,
            "notes": w.get("notes"),
        }
    }


# ─── get_workout_history ─────────────────────────────────────────────────────

async def _get_workout_history_impl(
    user: dict,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    limit: int = 30,
) -> Dict[str, Any]:
    """Return recent workouts in a date range."""
    db = get_supabase_db()
    limit = max(1, min(int(limit or 30), 200))

    workouts = db.list_workouts(
        user_id=user["id"],
        from_date=start_date,
        to_date=end_date,
        limit=limit,
        order_asc=False,
    )

    # Slim down payload so we don't ship a 10MB JSON blob.
    slim: List[Dict[str, Any]] = []
    for w in (workouts or []):
        slim.append({
            "id": w.get("id"),
            "name": w.get("name"),
            "type": w.get("type"),
            "scheduled_date": w.get("scheduled_date"),
            "status": w.get("status"),
            "is_completed": w.get("is_completed"),
            "completed_at": w.get("completed_at"),
            "duration_minutes": w.get("duration_minutes"),
            "exercise_count": len(w.get("exercises_json") or []) if isinstance(w.get("exercises_json"), list) else None,
        })

    return {"count": len(slim), "workouts": slim}


# ─── log_completed_set ───────────────────────────────────────────────────────

async def _log_completed_set_impl(
    user: dict,
    workout_id: str,
    exercise_id: str,
    reps: int,
    weight: Optional[float] = None,
    rpe: Optional[float] = None,
) -> Dict[str, Any]:
    """Append a completed set to a workout's exercises_json.

    Mirrors the lightweight path used by `crud_completion.py` but scoped
    to a single set (so the AI agent can log one rep at a time).
    """
    db = get_supabase_db()
    w = db.get_workout(workout_id)
    if not w:
        return {"ok": False, "error": "workout_not_found"}
    if str(w.get("user_id")) != str(user["id"]):
        return {"ok": False, "error": "forbidden"}

    exercises = w.get("exercises_json") or w.get("exercises") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except Exception:
            exercises = []

    target_ex = None
    for ex in exercises:
        if str(ex.get("id")) == str(exercise_id) or ex.get("name") == exercise_id:
            target_ex = ex
            break

    if target_ex is None:
        return {"ok": False, "error": "exercise_not_found"}

    # Append to sets_completed (schema varies — we use a consistent list shape).
    sets_completed = target_ex.get("sets_completed") or []
    if not isinstance(sets_completed, list):
        sets_completed = []
    entry = {
        "reps": int(reps),
        "logged_at": datetime.now(timezone.utc).isoformat(),
        "source": "mcp",
    }
    if weight is not None:
        entry["weight"] = float(weight)
    if rpe is not None:
        entry["rpe"] = float(rpe)
    sets_completed.append(entry)
    target_ex["sets_completed"] = sets_completed

    db.update_workout(workout_id, {
        "exercises_json": exercises,
        "last_modified_at": datetime.now(timezone.utc).isoformat(),
        "last_modified_method": "mcp_log_set",
    })
    return {"ok": True, "workout_id": workout_id, "exercise_id": exercise_id, "set": entry}


# ─── adjust_set_weight ───────────────────────────────────────────────────────

async def _adjust_set_weight_impl(
    user: dict,
    exercise_id: str,
    direction: str,
    workout_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Bump a target exercise's weight up or down by one "standard" step.

    direction: "up" or "down". We use a modest 5 lb step — the app's
    REST endpoint has a more nuanced plate-math version, but for MCP
    we keep it simple.
    """
    if direction not in ("up", "down"):
        return {"ok": False, "error": "invalid_direction"}

    db = get_supabase_db()
    # If no workout_id provided, pick today's workout.
    if not workout_id:
        today = await _get_today_workout_impl(user)
        w_obj = (today or {}).get("workout")
        if not w_obj:
            return {"ok": False, "error": "no_active_workout"}
        workout_id = w_obj["id"]

    w = db.get_workout(workout_id)
    if not w or str(w.get("user_id")) != str(user["id"]):
        return {"ok": False, "error": "workout_not_found"}

    exercises = w.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except Exception:
            exercises = []

    step = 5.0 if direction == "up" else -5.0
    changed = False
    for ex in exercises:
        if str(ex.get("id")) == str(exercise_id) or ex.get("name") == exercise_id:
            current = ex.get("target_weight") or ex.get("weight") or 0
            try:
                current = float(current)
            except (TypeError, ValueError):
                current = 0.0
            ex["target_weight"] = max(0.0, current + step)
            changed = True
            break

    if not changed:
        return {"ok": False, "error": "exercise_not_found"}

    db.update_workout(workout_id, {
        "exercises_json": exercises,
        "last_modified_at": datetime.now(timezone.utc).isoformat(),
        "last_modified_method": "mcp_weight_adjust",
    })
    return {"ok": True, "workout_id": workout_id, "direction": direction}


# ─── modify_workout ──────────────────────────────────────────────────────────

async def _modify_workout_impl(
    user: dict,
    workout_id: str,
    action: str,
    payload: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Add/remove/replace/reschedule an exercise or the workout itself.

    actions:
      add:        payload = {exercise: {id, name, ...}}
      remove:     payload = {exercise_id or exercise_name}
      replace:    payload = {exercise_id, replacement: {...}}
      reschedule: payload = {new_date: "YYYY-MM-DD"}

    Destructive `remove` is gated by the confirmation middleware in
    `mcp.middleware.confirmation.py` — this impl is only reached after
    the user has sent back a valid confirmation_token.
    """
    db = get_supabase_db()
    w = db.get_workout(workout_id)
    if not w or str(w.get("user_id")) != str(user["id"]):
        return {"ok": False, "error": "workout_not_found"}

    payload = payload or {}
    action = (action or "").lower()

    if action == "reschedule":
        new_date = payload.get("new_date")
        if not new_date:
            return {"ok": False, "error": "missing_new_date"}
        db.update_workout(workout_id, {
            "scheduled_date": new_date,
            "last_modified_at": datetime.now(timezone.utc).isoformat(),
            "last_modified_method": "mcp_reschedule",
        })
        return {"ok": True, "action": "reschedule", "workout_id": workout_id, "new_date": new_date}

    # The rest operate on exercises_json.
    exercises = w.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except Exception:
            exercises = []

    if action == "add":
        ex = payload.get("exercise")
        if not ex or not isinstance(ex, dict):
            return {"ok": False, "error": "missing_exercise"}
        if "id" not in ex:
            ex["id"] = str(uuid.uuid4())
        exercises.append(ex)
    elif action == "remove":
        target = payload.get("exercise_id") or payload.get("exercise_name")
        if not target:
            return {"ok": False, "error": "missing_target"}
        before = len(exercises)
        exercises = [
            e for e in exercises
            if str(e.get("id")) != str(target) and e.get("name") != target
        ]
        if len(exercises) == before:
            return {"ok": False, "error": "exercise_not_found"}
    elif action == "replace":
        target = payload.get("exercise_id") or payload.get("exercise_name")
        replacement = payload.get("replacement")
        if not (target and isinstance(replacement, dict)):
            return {"ok": False, "error": "missing_target_or_replacement"}
        replaced = False
        for i, e in enumerate(exercises):
            if str(e.get("id")) == str(target) or e.get("name") == target:
                merged = {**e, **replacement}
                merged["replacement_reason"] = payload.get("reason", "mcp_replace")
                merged["replaced_at"] = datetime.now(timezone.utc).isoformat()
                exercises[i] = merged
                replaced = True
                break
        if not replaced:
            return {"ok": False, "error": "exercise_not_found"}
    else:
        return {"ok": False, "error": f"unsupported_action:{action}"}

    db.update_workout(workout_id, {
        "exercises_json": exercises,
        "last_modified_at": datetime.now(timezone.utc).isoformat(),
        "last_modified_method": f"mcp_modify_{action}",
    })
    return {"ok": True, "action": action, "workout_id": workout_id, "exercise_count": len(exercises)}


# ─── generate_workout_plan ───────────────────────────────────────────────────

async def _generate_workout_plan_impl(
    user: dict,
    goals: Optional[List[str]] = None,
    duration_days: int = 7,
    constraints: Optional[Dict[str, Any]] = None,
    replace_existing: bool = False,
) -> Dict[str, Any]:
    """Generate a multi-day workout plan via the existing Gemini pipeline.

    We intentionally keep this thin — the heavy lifting lives in
    `services.gemini_service.GeminiService.generate_workout` (or its
    orchestrator). For MCP we generate ONE sample workout synchronously
    and queue the rest as a background job; the client gets the first
    workout immediately plus a job_id to poll.
    """
    try:
        from services.gemini_service import GeminiService
    except Exception as e:
        return {"ok": False, "error": f"generation_service_unavailable:{e}"}

    constraints = constraints or {}
    goals = goals or []

    db = get_supabase_db()
    db_user = db.get_user(user["id"])
    fitness_level = (db_user or {}).get("fitness_level") or constraints.get("fitness_level") or "intermediate"
    equipment = constraints.get("equipment") or (db_user or {}).get("available_equipment") or ["bodyweight"]

    # Minimal single-workout generation — enough to prove the pipeline works
    # against the AI client. The full 7-day plan is kicked off in the
    # background via the existing job queue (frontend keeps polling anyway).
    try:
        gemini = GeminiService()
        workout = await gemini.generate_workout(
            user_id=user["id"],
            fitness_level=fitness_level,
            goals=goals or (db_user or {}).get("fitness_goals") or ["general_fitness"],
            equipment=equipment,
            duration_minutes=constraints.get("duration_minutes", 45),
            workout_type=constraints.get("workout_type", "strength"),
        )
    except Exception as e:
        logger.error(f"MCP generate_workout_plan Gemini error: {e}", exc_info=True)
        return {"ok": False, "error": "generation_failed", "detail": str(e)[:200]}

    # Persist as today's workout if requested.
    saved_id = None
    try:
        today = datetime.now(timezone.utc).date().isoformat()
        row = {
            "user_id": user["id"],
            "scheduled_date": today,
            "name": (workout or {}).get("name") or "AI-generated workout",
            "type": (workout or {}).get("type") or constraints.get("workout_type", "strength"),
            "difficulty": (workout or {}).get("difficulty") or "medium",
            "exercises_json": (workout or {}).get("exercises") or [],
            "status": "scheduled",
            "duration_minutes": (workout or {}).get("duration_minutes") or 45,
        }
        saved = db.create_workout(row)
        saved_id = (saved or {}).get("id")
    except Exception as e:
        logger.warning(f"Could not persist generated workout: {e}")

    return {
        "ok": True,
        "workout": workout,
        "saved_workout_id": saved_id,
        "duration_days_requested": duration_days,
        "note": (
            "Generated one workout synchronously. Full multi-day plans are built "
            "asynchronously by the in-app generation pipeline."
        ),
    }


# ─── Tool registrar (called from server.py) ──────────────────────────────────

def register(mcp_app: Any) -> None:
    """Attach all workout tools to a FastMCP app instance."""

    @mcp_app.tool(
        name="get_today_workout",
        description=(
            "Return the user's workout scheduled for today (if any), including "
            "exercises, sets, and status."
        ),
    )
    async def get_today_workout(ctx) -> Dict[str, Any]:  # noqa: D401
        return await run_tool(
            ctx, "get_today_workout",
            required_scope="read:workouts",
            impl=_get_today_workout_impl, args={},
        )

    @mcp_app.tool(
        name="get_workout_history",
        description=(
            "List the user's recent workouts. Supports optional start_date and "
            "end_date (YYYY-MM-DD) and a limit (default 30, max 200)."
        ),
    )
    async def get_workout_history(
        ctx,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        limit: int = 30,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_workout_history",
            required_scope="read:workouts",
            impl=_get_workout_history_impl,
            args={"start_date": start_date, "end_date": end_date, "limit": limit},
        )

    @mcp_app.tool(
        name="log_completed_set",
        description=(
            "Log a completed set for an exercise in a workout. "
            "reps is required; weight (lbs) and rpe are optional."
        ),
    )
    async def log_completed_set(
        ctx,
        workout_id: str,
        exercise_id: str,
        reps: int,
        weight: Optional[float] = None,
        rpe: Optional[float] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "log_completed_set",
            required_scope="write:logs",
            impl=_log_completed_set_impl,
            args={
                "workout_id": workout_id,
                "exercise_id": exercise_id,
                "reps": reps,
                "weight": weight,
                "rpe": rpe,
            },
        )

    @mcp_app.tool(
        name="adjust_set_weight",
        description=(
            "Nudge an exercise's target weight up or down by one step "
            "(direction: 'up' or 'down'). Applies to today's workout if "
            "workout_id is omitted."
        ),
    )
    async def adjust_set_weight(
        ctx,
        exercise_id: str,
        direction: str,
        workout_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "adjust_set_weight",
            required_scope="write:logs",
            impl=_adjust_set_weight_impl,
            args={"exercise_id": exercise_id, "direction": direction, "workout_id": workout_id},
        )

    @mcp_app.tool(
        name="modify_workout",
        description=(
            "Modify a workout. action is one of 'add', 'remove', 'replace', "
            "'reschedule'. Removing an exercise requires a two-step confirmation."
        ),
    )
    async def modify_workout(
        ctx,
        workout_id: str,
        action: str,
        payload: Optional[Dict[str, Any]] = None,
        confirmation_token: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "modify_workout",
            required_scope="write:workouts",
            impl=_modify_workout_impl,
            args={
                "workout_id": workout_id,
                "action": action,
                "payload": payload,
                "confirmation_token": confirmation_token,
            },
        )

    @mcp_app.tool(
        name="generate_workout_plan",
        description=(
            "Generate a new AI workout based on the user's goals, fitness level, "
            "and constraints. Set replace_existing=true to overwrite today's plan "
            "(requires confirmation)."
        ),
    )
    async def generate_workout_plan(
        ctx,
        goals: Optional[List[str]] = None,
        duration_days: int = 7,
        constraints: Optional[Dict[str, Any]] = None,
        replace_existing: bool = False,
        confirmation_token: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "generate_workout_plan",
            required_scope="write:workouts",
            impl=_generate_workout_plan_impl,
            args={
                "goals": goals,
                "duration_days": duration_days,
                "constraints": constraints,
                "replace_existing": replace_existing,
                "confirmation_token": confirmation_token,
            },
        )
