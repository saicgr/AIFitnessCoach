"""
Menstrual-cycle tools for the LangGraph cycle agent.

Read tools fetch fresh real data on demand:
  * get_cycle_status   — current phase, cycle day, next-period / fertile estimates
  * get_cycle_history  — recent logged periods + cycle stats
  * get_recent_symptoms — digest of the last ~30 days of daily logs

Action tools DO things, surfacing the change through the chat `action_data`
mechanism so the frontend can apply / confirm it:
  * log_cycle_symptom        — write a symptom/mood/energy entry to hormone_logs
  * log_period_event         — log a period start or end into cycle_periods
  * set_cycle_sync_preference — flip cycle-sync workout / nutrition flags
  * suggest_phase_workout    — phase-appropriate workout suggestion (advisory)
  * suggest_phase_meals      — phase-appropriate nutrition suggestion (advisory)

SAFETY: these tools never give contraceptive advice and never diagnose. All
dates are estimates. Red-flag interpretation lives in the agent's system prompt.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.logger import get_logger
from core.supabase_client import get_supabase
from services.cycle.cycle_predictor import predict_for_user

logger = get_logger(__name__)


def _today() -> date:
    """Server-local today. The agent passes the user's tz-resolved date when it
    can; this is the safe fallback for tool calls that omit it."""
    return datetime.utcnow().date()


def _parse_date(value: Optional[str]) -> Optional[date]:
    if not value:
        return None
    try:
        return date.fromisoformat(value[:10])
    except Exception:
        return None


# ---------------------------------------------------------------------------
# READ TOOLS
# ---------------------------------------------------------------------------
@tool
def get_cycle_status(user_id: str, today: Optional[str] = None) -> Dict[str, Any]:
    """Get the user's CURRENT cycle status — phase, cycle day, and the
    next-period / fertile-window estimates.

    Use this whenever the user asks about where they are in their cycle,
    when their period is due, when they ovulate, or whether they are in a
    fertile window. All dates are ESTIMATES, never guarantees.

    Args:
        user_id: The user's UUID.
        today: Optional ISO date (YYYY-MM-DD) for the user's local "today".
            Defaults to the server date when omitted.

    Returns:
        Dict with current_phase, current_cycle_day, next_period_date (+window),
        ovulation_date, fertile window, confidence, and notes.
    """
    logger.info(f"[CycleTool] get_cycle_status for {user_id}")
    try:
        client = get_supabase().client
        ref_day = _parse_date(today) or _today()
        prediction = predict_for_user(client, str(user_id), ref_day)
        return {
            "success": True,
            "action": "get_cycle_status",
            "predictions_available": prediction.get("predictions_available", False),
            "current_phase": prediction.get("current_phase"),
            "current_cycle_day": prediction.get("current_cycle_day"),
            "in_period": prediction.get("in_period"),
            "next_period_date": str(prediction.get("next_period_date") or ""),
            "next_period_window_start": str(prediction.get("next_period_window_start") or ""),
            "next_period_window_end": str(prediction.get("next_period_window_end") or ""),
            "days_until_next_period": prediction.get("days_until_next_period"),
            "period_late_by": prediction.get("period_late_by"),
            "confidence": prediction.get("confidence"),
            "ovulation_date": str(prediction.get("ovulation_date") or ""),
            "ovulation_status": prediction.get("ovulation_status"),
            "fertile_window_start": str(prediction.get("fertile_window_start") or ""),
            "fertile_window_end": str(prediction.get("fertile_window_end") or ""),
            "conception_chance": prediction.get("conception_chance"),
            "tracking_mode": prediction.get("tracking_mode"),
            "notes": prediction.get("notes", []),
            "message": "Current cycle status retrieved.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] get_cycle_status error: {e}", exc_info=True)
        return {"success": False, "action": "get_cycle_status", "error": str(e)}


@tool
def get_cycle_history(user_id: str, limit: int = 12) -> Dict[str, Any]:
    """Get the user's recent logged periods and aggregate cycle statistics.

    Use this when the user asks whether their cycle is regular, how long
    their cycles run, or to reference their own history ("my last period
    was...").

    Args:
        user_id: The user's UUID.
        limit: Max number of recent periods to return (default 12).

    Returns:
        Dict with `periods` (recent start/end dates) and `stats`
        (avg/min/max cycle length, regularity, avg period length).
    """
    logger.info(f"[CycleTool] get_cycle_history for {user_id}")
    try:
        client = get_supabase().client
        periods_res = (
            client.table("cycle_periods")
            .select("start_date,end_date")
            .eq("user_id", str(user_id))
            .order("start_date", desc=True)
            .limit(int(limit))
            .execute()
        )
        periods = periods_res.data or []
        # Stats come from the predictor's own computation for consistency.
        prediction = predict_for_user(client, str(user_id), _today())
        return {
            "success": True,
            "action": "get_cycle_history",
            "periods": periods,
            "period_count": len(periods),
            "stats": prediction.get("stats", {}),
            "message": f"Found {len(periods)} logged periods.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] get_cycle_history error: {e}", exc_info=True)
        return {"success": False, "action": "get_cycle_history", "error": str(e)}


@tool
def get_recent_symptoms(user_id: str, days: int = 30) -> Dict[str, Any]:
    """Get a digest of the user's recently logged symptoms, mood, energy,
    sleep and BBT.

    Use this when the user asks why they feel a certain way, references a
    symptom pattern ("I've been so tired"), or wants to know what they
    logged recently.

    Args:
        user_id: The user's UUID.
        days: How many days back to summarize (default 30).

    Returns:
        Dict with day count, top symptoms, average energy/sleep, latest BBT.
    """
    logger.info(f"[CycleTool] get_recent_symptoms for {user_id} ({days}d)")
    try:
        client = get_supabase().client
        cutoff = (_today() - timedelta(days=int(days))).isoformat()
        logs_res = (
            client.table("hormone_logs")
            .select("log_date,energy_level,sleep_quality,mood,symptoms,"
                    "basal_body_temperature,period_flow")
            .eq("user_id", str(user_id))
            .gte("log_date", cutoff)
            .order("log_date")
            .execute()
        )
        rows = logs_res.data or []

        symptom_counts: Dict[str, int] = {}
        for r in rows:
            for s in (r.get("symptoms") or []):
                symptom_counts[s] = symptom_counts.get(s, 0) + 1
        top_symptoms = [
            {"symptom": s, "days": c}
            for s, c in sorted(symptom_counts.items(), key=lambda kv: kv[1], reverse=True)[:6]
        ]

        energy = [r["energy_level"] for r in rows if r.get("energy_level") is not None]
        sleep = [r["sleep_quality"] for r in rows if r.get("sleep_quality") is not None]
        bbt_rows = [r for r in rows if r.get("basal_body_temperature") is not None]

        return {
            "success": True,
            "action": "get_recent_symptoms",
            "days_logged": len(rows),
            "top_symptoms": top_symptoms,
            "avg_energy": round(sum(energy) / len(energy), 1) if energy else None,
            "avg_sleep_quality": round(sum(sleep) / len(sleep), 1) if sleep else None,
            "latest_bbt_celsius": bbt_rows[-1]["basal_body_temperature"] if bbt_rows else None,
            "bbt_readings": len(bbt_rows),
            "message": f"Summarized {len(rows)} logged days.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] get_recent_symptoms error: {e}", exc_info=True)
        return {"success": False, "action": "get_recent_symptoms", "error": str(e)}


# ---------------------------------------------------------------------------
# ACTION TOOLS
# ---------------------------------------------------------------------------
@tool
def log_cycle_symptom(
    user_id: str,
    symptoms: Optional[List[str]] = None,
    mood: Optional[str] = None,
    energy_level: Optional[int] = None,
    sleep_quality: Optional[int] = None,
    period_flow: Optional[str] = None,
    notes: Optional[str] = None,
    log_date: Optional[str] = None,
) -> Dict[str, Any]:
    """Log a symptom / mood / energy entry to the user's daily hormone log.

    Use this when the user reports how they feel today ("I've been cramping",
    "feeling low energy", "bad cramps and a headache"). Upserts onto the
    given day so repeated logging the same day merges instead of duplicating.

    Args:
        user_id: The user's UUID.
        symptoms: List of symptom slugs (e.g. ["cramps", "headache",
            "bloating", "fatigue"]).
        mood: One of excellent|good|stable|low|irritable|anxious|depressed.
        energy_level: 1-10.
        sleep_quality: 1-10.
        period_flow: none|spotting|light|medium|heavy.
        notes: Free-text note.
        log_date: ISO date (YYYY-MM-DD); defaults to today.

    Returns:
        Result dict with action='log_cycle_symptom' for the frontend handler.
    """
    logger.info(f"[CycleTool] log_cycle_symptom for {user_id}")
    try:
        client = get_supabase().client
        the_day = (_parse_date(log_date) or _today()).isoformat()

        entry: Dict[str, Any] = {"user_id": str(user_id), "log_date": the_day}
        if symptoms:
            entry["symptoms"] = symptoms
        if mood:
            entry["mood"] = mood
        if energy_level is not None:
            entry["energy_level"] = max(1, min(10, int(energy_level)))
        if sleep_quality is not None:
            entry["sleep_quality"] = max(1, min(10, int(sleep_quality)))
        if period_flow:
            entry["period_flow"] = period_flow
        if notes:
            entry["notes"] = notes

        result = (
            client.table("hormone_logs")
            .upsert(entry, on_conflict="user_id,log_date")
            .execute()
        )
        saved = result.data[0] if result.data else entry

        return {
            "success": True,
            "action": "log_cycle_symptom",
            "log_id": saved.get("id"),
            "log_date": the_day,
            "symptoms": symptoms or [],
            "mood": mood,
            "energy_level": entry.get("energy_level"),
            "sleep_quality": entry.get("sleep_quality"),
            "period_flow": period_flow,
            "message": f"Logged your cycle entry for {the_day}.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] log_cycle_symptom error: {e}", exc_info=True)
        return {"success": False, "action": "log_cycle_symptom", "error": str(e)}


@tool
def log_period_event(
    user_id: str,
    event: str = "start",
    event_date: Optional[str] = None,
    period_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Log a period START or END into the canonical cycle history.

    Use this when the user says their period started ("my period started
    today", "I started bleeding yesterday") or ended ("my period is over").
    A start creates a new `cycle_periods` row; an end sets the end_date on
    the most recent open period. Any write recomputes predictions.

    Args:
        user_id: The user's UUID.
        event: "start" (new period) or "end" (close the latest period).
        event_date: ISO date (YYYY-MM-DD); defaults to today.
        period_id: Optional explicit period row id when ending a specific one.

    Returns:
        Result dict with action='log_period_event' for the frontend handler.
    """
    logger.info(f"[CycleTool] log_period_event '{event}' for {user_id}")
    try:
        client = get_supabase().client
        the_day = (_parse_date(event_date) or _today()).isoformat()
        ev = (event or "start").lower().strip()

        if ev == "start":
            result = (
                client.table("cycle_periods")
                .upsert(
                    {"user_id": str(user_id), "start_date": the_day},
                    on_conflict="user_id,start_date",
                )
                .execute()
            )
            row = result.data[0] if result.data else {}
            return {
                "success": True,
                "action": "log_period_event",
                "event": "start",
                "period_id": row.get("id"),
                "start_date": the_day,
                "message": f"Logged your period start on {the_day}. "
                           "Predictions have been refreshed.",
            }

        # event == "end": close the latest open period.
        target_id = period_id
        if not target_id:
            latest = (
                client.table("cycle_periods")
                .select("id,start_date,end_date")
                .eq("user_id", str(user_id))
                .order("start_date", desc=True)
                .limit(1)
                .execute()
            )
            if not latest.data:
                return {
                    "success": False,
                    "action": "log_period_event",
                    "error": "No logged period found to close.",
                }
            target_id = latest.data[0]["id"]

        client.table("cycle_periods").update({"end_date": the_day}).eq(
            "id", target_id
        ).eq("user_id", str(user_id)).execute()
        return {
            "success": True,
            "action": "log_period_event",
            "event": "end",
            "period_id": target_id,
            "end_date": the_day,
            "message": f"Logged your period end on {the_day}.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] log_period_event error: {e}", exc_info=True)
        return {"success": False, "action": "log_period_event", "error": str(e)}


@tool
def set_cycle_sync_preference(
    user_id: str,
    sync_workouts: Optional[bool] = None,
    sync_nutrition: Optional[bool] = None,
) -> Dict[str, Any]:
    """Turn cycle-syncing of workouts and/or nutrition on or off.

    Use this when the user asks to adapt their training or eating to their
    cycle ("sync my workouts to my cycle", "stop adjusting my calories for
    my period"). Updates the user's `hormonal_profiles` flags.

    Args:
        user_id: The user's UUID.
        sync_workouts: True/False to enable/disable cycle-synced workouts.
        sync_nutrition: True/False to enable/disable cycle-synced nutrition.

    Returns:
        Result dict with action='set_cycle_sync_preference'.
    """
    logger.info(f"[CycleTool] set_cycle_sync_preference for {user_id}")
    try:
        client = get_supabase().client
        update: Dict[str, Any] = {"user_id": str(user_id)}
        if sync_workouts is not None:
            update["cycle_sync_workouts"] = bool(sync_workouts)
        if sync_nutrition is not None:
            update["cycle_sync_nutrition"] = bool(sync_nutrition)

        if len(update) == 1:
            return {
                "success": False,
                "action": "set_cycle_sync_preference",
                "error": "Nothing to update — specify sync_workouts or sync_nutrition.",
            }

        client.table("hormonal_profiles").upsert(
            update, on_conflict="user_id"
        ).execute()
        return {
            "success": True,
            "action": "set_cycle_sync_preference",
            "cycle_sync_workouts": update.get("cycle_sync_workouts"),
            "cycle_sync_nutrition": update.get("cycle_sync_nutrition"),
            "message": "Updated your cycle-sync preferences.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] set_cycle_sync_preference error: {e}", exc_info=True)
        return {"success": False, "action": "set_cycle_sync_preference", "error": str(e)}


# Phase-appropriate guidance — deterministic, evidence-informed, advisory only.
_PHASE_WORKOUT = {
    "menstrual": {
        "intensity": "light",
        "focus": "Gentle movement — walking, light yoga, mobility, easy "
                 "swimming. Keep it low-pressure; honor lower energy.",
    },
    "follicular": {
        "intensity": "moderate-to-high",
        "focus": "Rising energy and recovery favor strength training, "
                 "progressive overload, and skill or HIIT work.",
    },
    "ovulation": {
        "intensity": "high",
        "focus": "Peak energy window — a good time for PRs, heavy lifting, "
                 "and high-intensity intervals.",
    },
    "luteal": {
        "intensity": "moderate, tapering",
        "focus": "Steady-state cardio, moderate strength, Pilates. Late "
                 "luteal: more recovery work as energy dips.",
    },
}

_PHASE_MEALS = {
    "menstrual": "Iron- and magnesium-rich foods (leafy greens, lentils, "
                 "pumpkin seeds, dark chocolate); warm, comforting meals; "
                 "stay hydrated to ease cramps.",
    "follicular": "Lighter, fresh foods; lean protein and complex carbs to "
                  "fuel rising training volume; fermented foods for gut health.",
    "ovulation": "Antioxidant-rich produce, fiber, and adequate protein; "
                 "anti-inflammatory fats (olive oil, fatty fish).",
    "luteal": "Complex carbs (oats, sweet potato, quinoa) and magnesium to "
              "ease cravings and mood dips; calcium-rich foods; steady "
              "protein. A small calorie increase is normal late luteal.",
}


@tool
def suggest_phase_workout(
    user_id: str, phase: Optional[str] = None
) -> Dict[str, Any]:
    """Suggest a workout style appropriate to the user's current cycle phase.

    Advisory only — frames training around energy patterns, never as a
    medical prescription. If `phase` is omitted, the current estimated phase
    is looked up.

    Args:
        user_id: The user's UUID.
        phase: Optional menstrual|follicular|ovulation|luteal override.

    Returns:
        Result dict with action='suggest_phase_workout' and a suggestion.
    """
    logger.info(f"[CycleTool] suggest_phase_workout for {user_id}")
    try:
        the_phase = (phase or "").lower().strip()
        if the_phase not in _PHASE_WORKOUT:
            client = get_supabase().client
            prediction = predict_for_user(client, str(user_id), _today())
            the_phase = prediction.get("current_phase") or ""

        guidance = _PHASE_WORKOUT.get(the_phase)
        if not guidance:
            return {
                "success": False,
                "action": "suggest_phase_workout",
                "error": "Cycle phase unavailable — log a period to enable "
                         "phase-based suggestions.",
            }
        return {
            "success": True,
            "action": "suggest_phase_workout",
            "phase": the_phase,
            "recommended_intensity": guidance["intensity"],
            "focus": guidance["focus"],
            "message": f"Workout guidance for the {the_phase} phase.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] suggest_phase_workout error: {e}", exc_info=True)
        return {"success": False, "action": "suggest_phase_workout", "error": str(e)}


@tool
def suggest_phase_meals(
    user_id: str, phase: Optional[str] = None
) -> Dict[str, Any]:
    """Suggest nutrition emphasis appropriate to the user's current cycle phase.

    Advisory only — general wellness guidance, never medical advice. If
    `phase` is omitted, the current estimated phase is looked up.

    Args:
        user_id: The user's UUID.
        phase: Optional menstrual|follicular|ovulation|luteal override.

    Returns:
        Result dict with action='suggest_phase_meals' and a suggestion.
    """
    logger.info(f"[CycleTool] suggest_phase_meals for {user_id}")
    try:
        the_phase = (phase or "").lower().strip()
        if the_phase not in _PHASE_MEALS:
            client = get_supabase().client
            prediction = predict_for_user(client, str(user_id), _today())
            the_phase = prediction.get("current_phase") or ""

        guidance = _PHASE_MEALS.get(the_phase)
        if not guidance:
            return {
                "success": False,
                "action": "suggest_phase_meals",
                "error": "Cycle phase unavailable — log a period to enable "
                         "phase-based suggestions.",
            }
        return {
            "success": True,
            "action": "suggest_phase_meals",
            "phase": the_phase,
            "nutrition_focus": guidance,
            "message": f"Nutrition guidance for the {the_phase} phase.",
        }
    except Exception as e:
        logger.error(f"[CycleTool] suggest_phase_meals error: {e}", exc_info=True)
        return {"success": False, "action": "suggest_phase_meals", "error": str(e)}


# Public registries
CYCLE_READ_TOOLS = [get_cycle_status, get_cycle_history, get_recent_symptoms]
CYCLE_ACTION_TOOLS = [
    log_cycle_symptom,
    log_period_event,
    set_cycle_sync_preference,
    suggest_phase_workout,
    suggest_phase_meals,
]
CYCLE_TOOLS = CYCLE_READ_TOOLS + CYCLE_ACTION_TOOLS
