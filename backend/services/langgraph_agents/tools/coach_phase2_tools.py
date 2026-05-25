"""
Phase 2-6 coach tools — exposes the new workouts-overhaul capabilities to
the LangGraph coach agent so users can drive them via chat.

Every tool returns the standard envelope:

    {
      "success": bool,
      "action_data": {...},
      "summary_text": str,
      "requires_confirmation": False,
    }

Tools added in this batch
-------------------------
- `calibrate_equipment` ........ Phase 1 — set bar / sled / cable / plates from chat.
- `get_user_state` ............. Phase 2.A — return assembled user_state for the agent to reason about.
- `regenerate_today` ........... Phase 2.C — unlock today's plan + bump regen_requested_at.
- `start_deload_week` .......... Phase 2.E — force deload now (red-flag autoreg).
- `set_progression_style` ...... Phase 2.F — write user_rep_range_preferences.progression_style.
- `bonus_workout_eligibility` .. Phase 2.H — surface opt-in extra workout.
- `apply_recovery_recommendation` Phase 6 #1 — apply today_readiness recommendation.
- `explain_today_workout` ...... Phase 4 — return why-this-workout breakdown.
- `score_breakdown` ............ Phase 4 — per-exercise strength contribution.

Routing
-------
Add these tools to the coach + workout agent tool sets in
langgraph_service.py. Each tool's docstring follows the `use when:` pattern
so Gemini can route correctly (preserves the convention in this file).
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.db import get_supabase_db
from core.logger import get_logger
from services.user_state_assembler import assemble_user_state, invalidate as invalidate_user_state

logger = get_logger(__name__)


def _ok(action: str, summary: str, **kwargs: Any) -> Dict[str, Any]:
    return {
        "success": True,
        "action_data": {"action": action, **kwargs},
        "summary_text": summary,
        "requires_confirmation": False,
    }


def _err(msg: str) -> Dict[str, Any]:
    return {
        "success": False,
        "action_data": None,
        "summary_text": msg,
        "requires_confirmation": False,
    }


# ------------------------------------------------------------ Phase 1 ------

@tool
def calibrate_equipment(
    user_id: str,
    category: str,
    label: Optional[str] = None,
    bar_empty_weight_kg: Optional[float] = None,
    machine_empty_weight_kg: Optional[float] = None,
    cable_pin_start_kg: Optional[float] = None,
    cable_pin_increment_kg: Optional[float] = None,
    plate_inventory: Optional[Dict[str, int]] = None,
    dumbbell_inventory: Optional[Dict[str, int]] = None,
    weight_unit: str = "lb",
) -> Dict[str, Any]:
    """Create or update an equipment_inventory row with calibration data.

    Use when the user mentions: "my EZ bar is X lb", "my leg press has a Y lb
    sled", "cable steps are Z lb", "I only have these plates / dumbbells".
    The active-workout plate indicator + backend weight prescription read this
    immediately on the next set.

    `category` is one of: barbell, dumbbell, cable, machine, plate_set, kettlebell.
    """
    db = get_supabase_db()
    if category not in {"barbell", "dumbbell", "cable", "machine", "plate_set", "kettlebell", "other"}:
        return _err(f"category must be one of: barbell, dumbbell, cable, machine, plate_set, kettlebell.")
    row: Dict[str, Any] = {
        "user_id": user_id,
        "category": category,
        "weight_unit": weight_unit,
    }
    if label is not None:
        row["label"] = label
    if bar_empty_weight_kg is not None:
        row["bar_empty_weight_kg"] = bar_empty_weight_kg
    if machine_empty_weight_kg is not None:
        row["machine_empty_weight_kg"] = machine_empty_weight_kg
    if cable_pin_start_kg is not None:
        row["cable_pin_start_kg"] = cable_pin_start_kg
    if cable_pin_increment_kg is not None:
        row["cable_pin_increment_kg"] = cable_pin_increment_kg
    if plate_inventory:
        row["plate_inventory"] = plate_inventory
    if dumbbell_inventory:
        row["dumbbell_inventory"] = dumbbell_inventory
    try:
        res = db.client.table("equipment_inventory").insert(row).execute()
    except Exception as e:
        logger.error(f"❌ [calibrate_equipment] insert failed: {e}", exc_info=True)
        return _err(f"Could not save calibration: {e}")
    invalidate_user_state(user_id)
    return _ok(
        action="equipment_calibrated",
        summary=(f"Saved {category} calibration"
                 + (f" — {label}" if label else "")
                 + ". Plate math + weight suggestions now use it."),
        equipment_id=(res.data[0]["id"] if res.data else None),
    )


# ------------------------------------------------------------ Phase 2.A ----

@tool
def get_user_state(user_id: str) -> Dict[str, Any]:
    """Return the assembled UserState snapshot the workout generator uses.

    Use when the user asks "why is today's workout the way it is?", "what does
    Zealova know about me?", or before recommending changes the user wants to
    understand. Returns recovery, soreness, sleep/HRV, weekly volume per
    muscle, calories/protein, active injuries, mesocycle position.
    """
    db = get_supabase_db()
    state = assemble_user_state(user_id, db.client, force=False)
    return _ok(
        action="user_state",
        summary=(
            f"Recovery {int((state.avg_recovery or 0) * 100)}%, "
            f"Hooper {state.hooper_index or '–'}, "
            f"mesocycle week {state.mesocycle_week or '–'}"
            f"{' (deload)' if state.is_deload_week else ''}."
        ),
        state=state.to_jsonable(),
    )


# ------------------------------------------------------------ Phase 2.C ----

@tool
def regenerate_today(user_id: str, reason: Optional[str] = None) -> Dict[str, Any]:
    """Unlock today's weekly plan and request regeneration.

    Use when the user says "regenerate today", "make today easier/harder",
    "I'm too sore — replace today's plan", "I want a different workout today".
    Sets plan_locked=false + regen_requested_at on the active weekly_plans row;
    the next /workouts/today call will regenerate with fresh user_state.
    """
    db = get_supabase_db()
    from datetime import datetime, timezone
    try:
        db.client.table("weekly_plans").update({
            "plan_locked": False,
            "regen_requested_at": datetime.now(timezone.utc).isoformat(),
        }).eq("user_id", user_id).order(
            "week_start_date", desc=True
        ).limit(1).execute()
    except Exception as e:
        return _err(f"Could not request regeneration: {e}")
    invalidate_user_state(user_id)
    return _ok(
        action="regenerate_requested",
        summary="Today's plan unlocked. The next time you open it, it will regenerate.",
        reason=reason,
    )


# ------------------------------------------------------------ Phase 2.E ----

@tool
def start_deload_week(user_id: str, reason: str) -> Dict[str, Any]:
    """Force the current week into deload mode.

    Use when red-flag autoregulation fires (sleep<6h + HRV↓>10% + avg RPE>9 for
    5 sessions), when the user is at clear overreaching (cardio_load_state =
    overreaching), or when a plateau-break protocol triggers. Volume caps at
    60% MRV until the next mesocycle reset.
    """
    db = get_supabase_db()
    from datetime import datetime, timezone
    try:
        db.client.table("mesocycle_state").upsert({
            "user_id": user_id,
            "is_deload_week": True,
            "last_forced_deload_at": datetime.now(timezone.utc).isoformat(),
            "last_trigger": {"reason": reason, "source": "coach_tool"},
        }, on_conflict="user_id").execute()
    except Exception as e:
        return _err(f"Could not force deload: {e}")
    invalidate_user_state(user_id)
    return _ok(
        action="deload_week_started",
        summary=f"Deload week started: {reason}. Volume capped at 60% MRV.",
    )


# ------------------------------------------------------------ Phase 2.F ----

@tool
def set_progression_style(user_id: str, style: str) -> Dict[str, Any]:
    """Persist the user's rep-progression style as their default.

    Use when the user says: "I prefer pyramids", "switch me to RPT", "use
    double progression". One of: straight, pyramid, reverse_pyramid,
    double_progression, rpt, wave, cluster, amrap.
    """
    valid = {"straight", "pyramid", "reverse_pyramid", "double_progression",
             "rpt", "wave", "cluster", "amrap"}
    if style not in valid:
        return _err(f"style must be one of: {sorted(valid)}.")
    db = get_supabase_db()
    try:
        existing = (
            db.client.table("user_rep_range_preferences")
            .select("id")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        if existing.data:
            db.client.table("user_rep_range_preferences").update({
                "progression_style": style,
            }).eq("id", existing.data[0]["id"]).execute()
        else:
            db.client.table("user_rep_range_preferences").insert({
                "user_id": user_id,
                "progression_style": style,
            }).execute()
    except Exception as e:
        return _err(f"Could not save progression style: {e}")
    return _ok(
        action="progression_style_set",
        summary=f"Default progression set to {style}. New workouts will use this scheme.",
    )


# ------------------------------------------------------------ Phase 2.H ----

@tool
def bonus_workout_eligibility(user_id: str) -> Dict[str, Any]:
    """Check whether the user is eligible for an opt-in bonus workout this week.

    Use when the user has completed their planned days and asks "what now?",
    "can I work out today?", "I have extra time" or similar. Returns the
    suggested archetype (push/pull/legs/etc.) based on the most-undertrained
    muscle vs MAV.
    """
    db = get_supabase_db()
    from datetime import date, timedelta
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)
    plan_res = (
        db.client.table("weekly_plans")
        .select("workout_days")
        .eq("user_id", user_id)
        .eq("week_start_date", week_start.isoformat())
        .limit(1)
        .execute()
    )
    if not plan_res.data:
        return _err("No active weekly plan this week.")
    planned = plan_res.data[0].get("workout_days") or {}
    planned_count = sum(
        1 for v in planned.values() if isinstance(v, dict) and not v.get("rest_day")
    )
    logs_res = (
        db.client.table("workout_logs")
        .select("id")
        .eq("user_id", user_id)
        .gte("completed_at", week_start.isoformat())
        .lte("completed_at", (week_end + timedelta(days=1)).isoformat())
        .execute()
    )
    logged = len(logs_res.data or [])
    if logged < planned_count:
        return _ok(
            action="bonus_workout_not_yet",
            summary=f"You've completed {logged} of {planned_count} planned this week. Finish the plan first.",
            logged=logged,
            planned=planned_count,
        )
    # Pick least-trained muscle this week vs MAV
    from services.workout_validator_phase2 import VOLUME_LANDMARKS
    state = assemble_user_state(user_id, db.client, force=True)
    best = max(
        ((m, VOLUME_LANDMARKS[m]["mav"] - state.sets_per_muscle_7d.get(m, 0)) for m in VOLUME_LANDMARKS),
        key=lambda x: x[1],
        default=(None, 0),
    )
    return _ok(
        action="bonus_workout_available",
        summary=(
            f"Nice — week complete. Want an extra session focused on "
            f"{best[0] or 'whichever muscle you prefer'}? "
            f"That muscle is ~{int(best[1])} sets below its weekly MAV."
        ),
        suggested_focus_muscle=best[0],
        set_deficit=int(best[1]),
    )


# ------------------------------------------------------------ Phase 6 #1 ---

@tool
def apply_recovery_recommendation(user_id: str) -> Dict[str, Any]:
    """Apply today's readiness-driven recommendation to the workout.

    Use when the user reports poor sleep, low HRV, high fatigue, or asks
    "should I train hard today?". Reads today_readiness.recommended_intensity
    (already populated daily) + applies it: low → unlock + regen today with
    deload flag; moderate → ship as planned; high → no-op.
    """
    db = get_supabase_db()
    res = (
        db.client.table("today_readiness")
        .select("readiness_score,readiness_level,recommended_intensity,ai_insight")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not res.data:
        return _err("No readiness score yet today — log a wellness check-in.")
    r = res.data[0]
    intensity = (r.get("recommended_intensity") or "moderate").lower()
    if intensity in {"low", "very_low", "rest"}:
        # Force a regen with the deload hint.
        from datetime import datetime, timezone
        db.client.table("weekly_plans").update({
            "plan_locked": False,
            "regen_requested_at": datetime.now(timezone.utc).isoformat(),
        }).eq("user_id", user_id).order(
            "week_start_date", desc=True
        ).limit(1).execute()
        return _ok(
            action="recovery_applied_deload",
            summary=(
                f"Readiness is {r.get('readiness_level')}. Reducing today's volume — "
                f"plan will regenerate. {r.get('ai_insight') or ''}"
            ).strip(),
            readiness=r,
        )
    return _ok(
        action="recovery_applied_proceed",
        summary=(
            f"Readiness is {r.get('readiness_level')}; recommended intensity = {intensity}. "
            f"Proceed with the planned session."
        ),
        readiness=r,
    )


# ------------------------------------------------------------ Phase 4 ------

@tool
def explain_today_workout(user_id: str) -> Dict[str, Any]:
    """Return a human-readable explanation of why today's workout looks the
    way it does — recovery state, mesocycle position, equipment availability,
    rolling RPE trend, sleep, calories.

    Use when user asks "why this workout?", "explain today's plan", "why am I
    doing X today?".
    """
    db = get_supabase_db()
    state = assemble_user_state(user_id, db.client, force=False)
    bullets = []
    if state.avg_recovery is not None:
        bullets.append(f"• Avg recovery {int(state.avg_recovery * 100)}%")
    if state.mesocycle_week:
        suffix = " (deload week)" if state.is_deload_week else ""
        bullets.append(f"• Mesocycle week {state.mesocycle_week}{suffix}")
    if state.hooper_index is not None:
        bullets.append(f"• Hooper index {state.hooper_index} / 28")
    if state.sleep_last_night_hours:
        bullets.append(f"• Sleep last night {state.sleep_last_night_hours:.1f}h")
    if state.weekly_trimp is not None:
        bullets.append(f"• Weekly cardio strain (TRIMP) {state.weekly_trimp:.0f}")
    if state.in_deficit:
        bullets.append("• Currently in a caloric deficit — volume gently capped")
    if state.plateaued_exercises:
        bullets.append(f"• Plateau flag on: {', '.join(state.plateaued_exercises[:3])}")
    if state.injured_body_parts:
        bullets.append(f"• Active injuries: {', '.join(state.injured_body_parts)}")
    summary = "Today's session was tuned for:\n" + ("\n".join(bullets) or "• Default profile (no signals yet — log a workout!)")
    return _ok(
        action="why_this_workout",
        summary=summary,
        user_state=state.to_jsonable(),
    )


# ------------------------------------------------------------ Phase 4 ------

@tool
def score_breakdown(user_id: str, muscle_group: str) -> Dict[str, Any]:
    """Return per-exercise contribution to a muscle's strength score.

    Use when the user asks "how is my chest score calculated?", "what's
    driving my back number?", "which lifts are my strongest for shoulders?".
    Mirrors Gravl's "see the logic / exercises contributing to a muscle's
    strength score" feature.
    """
    from api.v1.scores_breakdown import scores_breakdown as endpoint, estimate_one_rep_max  # noqa: F401
    # Re-implement the data fetch here to avoid going through HTTP.
    from datetime import datetime, timedelta, timezone

    db = get_supabase_db()
    muscle = muscle_group.lower().strip()
    head_res = (
        db.client.table("strength_scores")
        .select("strength_score,strength_level,best_exercise_name,"
                "best_estimated_1rm_kg,bodyweight_ratio,weekly_sets,weekly_volume_kg,trend")
        .eq("user_id", user_id)
        .eq("muscle_group", muscle)
        .order("calculated_at", desc=True)
        .limit(1)
        .execute()
    )
    if not head_res.data:
        return _err(f"No strength score for {muscle} yet — log a workout targeting it.")
    head = head_res.data[0]
    since = (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()
    logs = (
        db.client.table("workout_logs")
        .select("performance_data,completed_at")
        .eq("user_id", user_id)
        .gte("completed_at", since)
        .execute()
    )
    per_exercise: Dict[str, Dict[str, Any]] = {}
    for row in (logs.data or []):
        for ex in (row.get("performance_data") or {}).get("exercises", []):
            if (ex.get("primary_muscle") or "").lower() != muscle:
                continue
            name = ex.get("name") or ex.get("exercise_name")
            if not name:
                continue
            for s in (ex.get("sets") or []):
                w = float(s.get("weight_kg") or 0)
                r = int(s.get("reps") or 0)
                if w <= 0 or r <= 0:
                    continue
                e1rm = estimate_one_rep_max(w, r)
                cur = per_exercise.get(name)
                if not cur or e1rm > cur["e1rm"]:
                    per_exercise[name] = {"exercise_name": name, "e1rm": round(e1rm, 1)}
    items = list(per_exercise.values())
    total = sum(i["e1rm"] for i in items) or 1.0
    for i in items:
        i["contribution_pct"] = round(i["e1rm"] / total * 100, 1)
    items.sort(key=lambda x: x["contribution_pct"], reverse=True)
    top3 = ", ".join(f"{i['exercise_name']} {i['contribution_pct']}%" for i in items[:3])
    return _ok(
        action="strength_breakdown",
        summary=(
            f"{muscle.capitalize()} score {head.get('strength_score')} "
            f"({head.get('strength_level')}). Top contributors: {top3 or 'none yet'}."
        ),
        header=head,
        exercises=items,
    )
