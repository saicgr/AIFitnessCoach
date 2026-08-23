"""One-tap "Adjust Today" endpoint.

Deterministic rule engine that takes the user's mid-workout inputs (soreness,
energy, minutes available) and mutates the remaining workout in place —
trimming accessories when short on time, dropping intensity when fatigued,
offering reschedule when energy is critically low.

Why deterministic (no LLM): hot path (<100ms target) per
feedback_prefer_local_algo_over_rag.md. The user is staring at the screen
between sets — can't wait 1-3s for Gemini. Plus the decision tree is simple
enough that rules beat an LLM here.

Downstream calls into existing infrastructure:
- services.workout_modifier.WorkoutModifier.modify_workout_intensity("easier")
- services.workout_modifier.WorkoutModifier.remove_exercises_from_workout
- Writes mid-workout readiness row to readiness_scores with source flag
- Writes audit row to workout_changes (via _log_workout_change already in modifier)
"""
# NOTE: deliberately NOT using `from __future__ import annotations` here.
# When enabled, FastAPI's OpenAPI schema generator (Pydantic 2.12 path)
# can't resolve the ForwardRef to QuickAdjustRequest in the endpoint
# signature → /openapi.json crashes with PydanticUserError. Using runtime
# annotations + explicit typing.List/Tuple/Dict everywhere keeps OpenAPI
# generation working on Python 3.9.

import json
from datetime import datetime
from typing import Dict, List, Optional, Tuple

from fastapi import APIRouter, Body, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from services.coach_voice import get_coach_voice, render as render_voice
from services.workout_modifier import WorkoutModifier

logger = get_logger(__name__)
router = APIRouter()


# ── Request / response models ──────────────────────────────────────────────

class QuickAdjustRequest(BaseModel):
    """User's self-assessment + context for the adjustment engine."""
    soreness: int = Field(..., ge=1, le=7, description="1 = no soreness, 7 = very sore")
    energy: int = Field(..., ge=1, le=7, description="1 = exhausted, 7 = peak energy")
    minutes_available: int = Field(..., ge=1, le=240,
                                   description="Minutes the user can still spend")
    # Indices of exercises not yet completed. The engine only mutates these —
    # we never edit completed sets (that would corrupt the workout log).
    exercise_indices_remaining: List[int] = Field(default_factory=list)
    # Optional free-text sore muscle name (e.g. "lower back"). When present,
    # exercises targeting that muscle get preference for removal.
    sore_muscle: Optional[str] = None


class QuickAdjustResponse(BaseModel):
    success: bool
    action: str  # "trim", "ease", "ease_and_trim", "reschedule_suggested", "none"
    exercises_removed: List[str] = Field(default_factory=list)
    sets_dropped_per_exercise: int = 0
    estimated_minutes: int = 0
    coach_message: str
    # Returned so mobile can optimistically update; shape matches workouts.exercises.
    updated_exercises: Optional[List[dict]] = None


# Force-resolve string-form annotations introduced by `from __future__ import
# annotations` at the top of this file. Without this, FastAPI's OpenAPI
# generator (under Pydantic 2.12) crashes with PydanticUserError because the
# ForwardRef('QuickAdjustRequest') in the endpoint signature can't be
# resolved when building the schema. .model_rebuild() materializes the
# fields so TypeAdapter can introspect them.
QuickAdjustRequest.model_rebuild()
QuickAdjustResponse.model_rebuild()


# ── Time estimation ────────────────────────────────────────────────────────

# E2E #146: this used to be a FOURTH divergent duration formula
# (sets * 90s + 30s/exercise, ignoring each exercise's own rest_seconds) —
# never persisted, but still a number the user could see disagree with the
# stored workout's duration_minutes / the reshape endpoint's estimate. Now
# delegates to the same chokepoint program expansion and reshape use. See
# workout_duration_energy.py for the full class writeup.
from .workout_duration_energy import estimate_duration_minutes as _estimate_minutes


# ── Compound vs accessory classification ───────────────────────────────────

# Conservative "compound" classifier. Uses whole-word tokenization to avoid
# false positives like "leg press" → compound (it's an accessory). Prefer
# precise keywords here: naming varies (e.g. "barbell row", "pendlay row"),
# but accessory variants almost never embed these word tokens.
_COMPOUND_TOKENS = {
    "squat", "squats",
    "deadlift", "deadlifts",
    "bench",            # Bench Press / Close Grip Bench / Incline Bench
    # Pull-up / pullup / Pull Up all tokenize differently — cover each form.
    # Tokenization splits on non-alnum so "Pull-Ups" → ["pull","ups"]; we
    # also treat a bare "pull" (as in Pull Up) as a compound indicator.
    "pull", "pullup", "pullups", "chin", "chinup", "chinups",
    "row", "rows",      # Barbell Row / Bent-Over Row / Pendlay Row
    "thrust", "thrusts",  # Hip Thrust
    "clean", "cleans", "snatch", "snatches",
    "ohp", "overhead",  # Overhead Press / OHP
}

# Exact exercise-name substrings that should never be treated as compounds
# even when a token overlap would suggest otherwise. "Leg press" and "chest
# press" are clearly accessories; "seated overhead triceps extension" isn't
# a true compound lift. Ordered longest-first to win over shorter overlaps.
_FORCE_ACCESSORY_SUBSTRINGS = (
    "seated overhead triceps",
    "overhead triceps",
    "leg press",
    "chest press",
    "shoulder press machine",  # Machine-guided — accessory-like
    "decline bench",  # Decline bench press is a variation, still compound;
                      # but decline bench crunch is not. Keep off this list
                      # unless it's unambiguously accessory.
)


def _is_compound(exercise_name: str) -> bool:
    """Return True when the exercise is a compound (don't remove first).

    Checks: forced-accessory substrings override everything; otherwise
    tokenize and match against _COMPOUND_TOKENS.
    """
    n = (exercise_name or "").lower()
    for sub in _FORCE_ACCESSORY_SUBSTRINGS:
        if sub in n:
            return False
    # Tokenize on non-alphanumeric boundaries so "Pull-Ups" -> ["pull", "ups"].
    import re as _re
    tokens = set(t for t in _re.split(r"[^a-z]+", n) if t)
    return bool(tokens & _COMPOUND_TOKENS)


def _picks_to_remove(
    exercises: List[Dict],
    indices_remaining: List[int],
    target_minutes: int,
    sore_muscle: Optional[str],
) -> List[int]:
    """Return indices to remove, in removal order, so total time fits budget.

    Strategy:
      1. Prefer removing exercises targeting the sore muscle (if provided).
      2. Then accessories (non-compounds).
      3. Only touch compounds as a last resort.
      4. Never remove more than 60% of remaining exercises (prevents
         collapsing the workout — at that point we suggest reschedule).
    """
    if not indices_remaining:
        return []

    # Compute current total time.
    remaining_ex = [exercises[i] for i in indices_remaining if i < len(exercises)]
    current_min = _estimate_minutes(remaining_ex)
    if current_min <= target_minutes:
        return []

    # Score each remaining index by removal priority (higher = remove first).
    scored: List[Tuple[int, int]] = []
    sore_lower = (sore_muscle or "").lower().strip()
    for idx in indices_remaining:
        if idx >= len(exercises):
            continue
        ex = exercises[idx]
        name = ex.get("name", "") or ex.get("exercise_name", "") or ""
        muscle = (ex.get("muscle_group") or ex.get("primary_muscle") or "").lower()
        score = 0
        if sore_lower and (sore_lower in muscle or sore_lower in name.lower()):
            score += 10  # sore-muscle match — remove first
        if not _is_compound(name):
            score += 5   # accessory — remove before compounds
        scored.append((idx, score))

    # Highest score first. Stable on ties.
    scored.sort(key=lambda t: -t[1])

    # Budget: don't remove more than 60% of remaining.
    max_removals = max(1, int(len(indices_remaining) * 0.6))
    to_remove: List[int] = []

    # Greedy — add until we fit or hit the cap.
    working = list(remaining_ex)
    working_idx = list(indices_remaining)
    for idx, _score in scored:
        if len(to_remove) >= max_removals:
            break
        if _estimate_minutes(working) <= target_minutes:
            break
        if idx in working_idx:
            pos = working_idx.index(idx)
            working.pop(pos)
            working_idx.pop(pos)
            to_remove.append(idx)

    return to_remove


# ── The endpoint ───────────────────────────────────────────────────────────

@router.post("/{workout_id}/quick-adjust", response_model=QuickAdjustResponse)
@limiter.limit("20/minute")
async def quick_adjust_workout(
    # `workouts.id` is a UUID (see core/db/workout_db.py:get_workout -> workout_id: str).
    # This was declared `int`, so FastAPI 422'd every real id before the handler ran,
    # and the Flutter client papered over it with `int.tryParse(id) ?? 0` — sending
    # /workouts/0/quick-adjust. Both sides fixed together.
    workout_id: str,
    # Explicit `Body(...)` so FastAPI's OpenAPI schema generation under
    # `from __future__ import annotations` doesn't fall back to treating
    # this ForwardRef as a Query parameter (which crashes /openapi.json
    # with PydanticUserError class-not-fully-defined).
    request_body: QuickAdjustRequest = Body(...),
    request: Request = None,  # injected by slowapi rate limiter
    current_user: dict = Depends(get_current_user),
):
    """Adjust the remaining workout in place based on soreness/energy/time.

    Decision tree (deterministic, runs in <10ms locally):

        energy ≤ 2                     → suggest reschedule (no mutation)
        minutes_available ≤ 5          → suggest reschedule (no mutation)
        minutes_available × 1.15 < est → trim accessories
        soreness ≥ 5 AND energy ≤ 3    → ease (modify_workout_intensity easier)
        soreness ≥ 5 OR  energy ≤ 3    → ease OR trim depending on time budget
        else                           → no-op (kept for symmetry / telemetry)

    All mutations write to workout_changes (via WorkoutModifier._log_workout_change)
    and a mid-workout row in readiness_scores so the user's soreness/energy
    signal can inform future workout generation.
    """
    user_id = str(current_user["id"])
    logger.info(
        f"🎯 [QuickAdjust] workout={workout_id} user={user_id} "
        f"sore={request_body.soreness} energy={request_body.energy} "
        f"mins={request_body.minutes_available}"
    )

    db = get_supabase_db()
    workout = db.get_workout(workout_id)
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    if str(workout.get("user_id")) != user_id:
        raise HTTPException(status_code=403, detail="Not your workout")

    # Record the mid-workout readiness check in readiness_scores so downstream
    # systems (next-workout generator, adaptive service) can use it. Composite
    # score uses an inverted Hooper-style mapping — lower is fresher, matches
    # existing readiness conventions.
    try:
        db.client.table("readiness_scores").insert({
            "user_id": user_id,
            "readiness_score": max(0, min(100, (request_body.energy - 1) * 100 // 6)),
            "sleep_quality": None,
            "muscle_soreness": request_body.soreness,
            "stress_level": None,
            "energy_level": request_body.energy,
            "mood": None,
            "submitted_at": datetime.utcnow().isoformat(),
        }).execute()
    except Exception as e:
        # Don't block adjustment on analytics insert. Logs are enough for debug.
        logger.warning(f"[QuickAdjust] readiness insert failed (non-fatal): {e}")

    # Normalize exercises into a List[Dict] we can mutate.
    # `workouts` has no `exercises` column — the array lives in `exercises_json`.
    exercises_data = workout.get("exercises_json")
    if isinstance(exercises_data, str):
        exercises = json.loads(exercises_data) if exercises_data else []
    else:
        exercises = exercises_data or []

    indices = request_body.exercise_indices_remaining or list(range(len(exercises)))

    # Route through the decision tree.
    current_min = _estimate_minutes([exercises[i] for i in indices if i < len(exercises)])

    # Branch 1 — critically low energy or time: suggest reschedule.
    if request_body.energy <= 2 or request_body.minutes_available <= 5:
        voice = await get_coach_voice(user_id, supabase=db)
        msg = render_voice(
            "quick_adjust_summary",
            voice,
            {
                "sets_remaining": 0,
                "exercises_remaining": 0,
                "minutes": request_body.minutes_available,
            },
            channel="in_app",
            selection_salt=f"reschedule:{workout_id}",
        )
        # Clear the coach line with a reschedule-specific hint appended.
        coach_message = f"{msg} Reschedule today?" if msg else "Let's save this for tomorrow."
        return QuickAdjustResponse(
            success=True,
            action="reschedule_suggested",
            coach_message=coach_message,
            estimated_minutes=current_min,
        )

    # Branch 2 — time pressure. Trim first.
    exercises_removed: List[str] = []
    removed_indices: List[int] = []
    if request_body.minutes_available * 1.15 < current_min:
        removed_indices = _picks_to_remove(
            exercises, indices, request_body.minutes_available,
            sore_muscle=request_body.sore_muscle,
        )
        if removed_indices:
            modifier = WorkoutModifier()
            names_to_remove = [
                exercises[i].get("name") or exercises[i].get("exercise_name") or ""
                for i in removed_indices if i < len(exercises)
            ]
            names_to_remove = [n for n in names_to_remove if n]
            if names_to_remove:
                # Check the result — this used to be discarded, so a failed write
                # (e.g. the phantom-column 42703 this endpoint shipped with) still
                # reported the exercises as removed in the response.
                if modifier.remove_exercises_from_workout(workout_id, names_to_remove):
                    exercises_removed = names_to_remove
                else:
                    logger.error(
                        f"[QuickAdjust] failed to remove {names_to_remove} from "
                        f"workout {workout_id} — reporting no removal"
                    )

    # The 60%-removal cap in `_picks_to_remove` deliberately never guts the
    # workout, so trimming exercises alone can still leave the plan longer
    # than the minutes the user actually has (E2E #146: a 45-min budget
    # coming back ~48 min). Check what trimming actually bought us before
    # deciding whether ease is still needed.
    if removed_indices:
        post_trim_workout = db.get_workout(workout_id) or {}
        post_trim_raw = post_trim_workout.get("exercises_json")
        if isinstance(post_trim_raw, str):
            post_trim_exercises = json.loads(post_trim_raw) if post_trim_raw else []
        else:
            post_trim_exercises = post_trim_raw or exercises
        post_trim_min = _estimate_minutes(post_trim_exercises)
    else:
        post_trim_min = current_min
    still_over_budget = post_trim_min > request_body.minutes_available

    # Branch 3 — ease intensity if sore/tired, OR the time budget is still
    # not met after trimming. The minutes the user gave is a ceiling, not a
    # soft hint — respected even when soreness/energy alone wouldn't have
    # triggered easing.
    sets_dropped = 0
    applied_ease = False
    if (request_body.soreness >= 5 and request_body.energy <= 3) or still_over_budget:
        modifier = WorkoutModifier()
        if modifier.modify_workout_intensity(workout_id, "easier"):
            applied_ease = True
            sets_dropped = 1  # matches WorkoutModifier._easier rule: -1 set

    # Re-read workout to get authoritative updated state for the response.
    updated_workout = db.get_workout(workout_id) or {}
    updated_exercises_raw = updated_workout.get("exercises_json")
    if isinstance(updated_exercises_raw, str):
        updated_exercises = json.loads(updated_exercises_raw) if updated_exercises_raw else []
    else:
        updated_exercises = updated_exercises_raw or []

    new_min = _estimate_minutes(updated_exercises)
    total_sets_remaining = sum(int(e.get("sets") or 3) for e in updated_exercises)

    if not exercises_removed and not applied_ease:
        action = "none"
    elif exercises_removed and applied_ease:
        action = "ease_and_trim"
    elif exercises_removed:
        action = "trim"
    else:
        action = "ease"

    voice = await get_coach_voice(user_id, supabase=db)
    if action == "none":
        # Nothing was trimmed or eased — use the honest no-op copy instead of
        # quick_adjust_summary's "Got it — trimmed to..." / "ADJUSTED." lines,
        # which contradicted a no-mutation outcome (E2E #146).
        coach_message = render_voice(
            "quick_adjust_no_change",
            voice,
            {"minutes": new_min},
            channel="in_app",
            selection_salt=f"quick_adjust:{workout_id}:{action}",
        )
    else:
        coach_message = render_voice(
            "quick_adjust_summary",
            voice,
            {
                "sets_remaining": total_sets_remaining,
                "exercises_remaining": len(updated_exercises),
                "minutes": new_min,
            },
            channel="in_app",
            selection_salt=f"quick_adjust:{workout_id}:{action}",
        )
        # Itemize what actually changed rather than just the resulting totals —
        # "trimmed to 23 sets" alone didn't say what moved (E2E #146).
        changes: List[str] = []
        if exercises_removed:
            removed_list = ", ".join(exercises_removed[:3])
            if len(exercises_removed) > 3:
                removed_list += f" +{len(exercises_removed) - 3} more"
            changes.append(f"removed {removed_list}")
        if applied_ease:
            changes.append("-1 set, -2 reps on remaining exercises")
        if changes:
            coach_message = f"{coach_message} ({'; '.join(changes)})"

    return QuickAdjustResponse(
        success=True,
        action=action,
        exercises_removed=exercises_removed,
        sets_dropped_per_exercise=sets_dropped,
        estimated_minutes=new_min,
        coach_message=coach_message,
        updated_exercises=updated_exercises,
    )
