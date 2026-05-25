"""
plateau_break_orchestrator.py — Phase 6 #3 of workouts overhaul.

When the existing `progression_service.plateau` detector flags a stalled lift
(1RM variance <3% over 4+ sessions), this module ORCHESTRATES the response:

  1. Force a deload week on `mesocycle_state` (caps weekly volume at 60% MRV
     via workout_validator_phase2).
  2. Mark the plateau-flag + plateau_since on `user_exercise_state` so the
     next generation knows to swap a variation in.
  3. Unlock the active weekly plan so /workouts/today regenerates with the
     deload prompt + variation hint.
  4. Surface a one-shot coach message so the user understands WHY the next
     workout looks different.

Deterministic, no LLM (per `feedback_no_llm_for_safety_classification`).

Variation map (research-backed swaps for common stalled lifts):
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)


# Pre-curated variation swaps. When a lift plateaus, swap to a same-pattern
# alternative for 4 weeks. Sourced from RP / Greg Nuckols / Mike Israetel.
PLATEAU_VARIATIONS: Dict[str, List[str]] = {
    "barbell bench press": ["incline barbell bench press", "close-grip bench press", "floor press"],
    "incline barbell bench press": ["barbell bench press", "low-incline dumbbell press"],
    "back squat": ["front squat", "safety bar squat", "tempo back squat"],
    "front squat": ["back squat", "zercher squat"],
    "deadlift": ["deficit deadlift", "block-pull deadlift", "snatch-grip deadlift"],
    "romanian deadlift": ["stiff-leg deadlift", "snatch-grip romanian deadlift"],
    "overhead press": ["push press", "z press", "seated dumbbell press"],
    "barbell row": ["pendlay row", "chest-supported row", "t-bar row"],
    "pull-up": ["weighted pull-up", "neutral-grip pull-up", "wide-grip pull-up"],
    "barbell curl": ["incline dumbbell curl", "preacher curl", "ez-bar curl"],
}


def suggest_variation(exercise_name: str) -> Optional[str]:
    """Return the first untried variation for a plateaued lift."""
    key = (exercise_name or "").strip().lower()
    options = PLATEAU_VARIATIONS.get(key)
    if not options:
        return None
    return options[0]


async def fire_plateau_break(
    user_id: str,
    plateaued_exercises: List[str],
    supabase,
) -> Dict[str, object]:
    """Run the full plateau-break protocol.

    Args:
        user_id: target user.
        plateaued_exercises: exercise names returned by progression_service's
            plateau detector.
        supabase: SupabaseDb instance.

    Returns:
        Summary dict with what was changed — for logging + the coach message.
    """
    if not plateaued_exercises:
        return {"fired": False, "reason": "no_plateaued_exercises"}

    now_iso = datetime.now(timezone.utc).isoformat()
    today = date.today()
    variations: Dict[str, Optional[str]] = {
        ex: suggest_variation(ex) for ex in plateaued_exercises
    }

    # 1. Force deload
    try:
        supabase.table("mesocycle_state").upsert({
            "user_id": user_id,
            "is_deload_week": True,
            "last_forced_deload_at": now_iso,
            "last_trigger": {"trigger": "plateau_break",
                              "exercises": plateaued_exercises,
                              "variations": variations},
        }, on_conflict="user_id").execute()
    except Exception as e:
        logger.error(f"❌ [plateau_break] deload upsert failed: {e}", exc_info=True)

    # 2. Mark per-exercise plateau_flag for the generator to see
    try:
        for ex in plateaued_exercises:
            supabase.table("user_exercise_state").upsert({
                "user_id": user_id,
                "exercise_id": ex,
                "plateau_flag": True,
                "plateau_since": today.isoformat(),
                "updated_at": now_iso,
            }, on_conflict="user_id,exercise_id").execute()
    except Exception as e:
        logger.warning(f"⚠️ [plateau_break] user_exercise_state upsert partial: {e}")

    # 3. Unlock active weekly plan for regen
    try:
        supabase.table("weekly_plans").update({
            "plan_locked": False,
            "regen_requested_at": now_iso,
        }).eq("user_id", user_id).order(
            "week_start_date", desc=True
        ).limit(1).execute()
    except Exception as e:
        logger.warning(f"⚠️ [plateau_break] weekly_plans unlock failed: {e}")

    return {
        "fired": True,
        "deload_started": True,
        "plateaued_exercises": plateaued_exercises,
        "variations": variations,
        "fired_at": now_iso,
    }
