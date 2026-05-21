"""
Exercise Progressions API - Skill-based exercise progressions for adaptive difficulty.

This module provides endpoints to:
1. Track exercise mastery levels based on user feedback
2. Suggest progression to harder variants when exercises become too easy
3. Manage progression chains (e.g., Wall Pushups -> Standard Pushups -> One-Arm Pushups)
4. Allow users to customize rep range preferences and progression style

The key insight: Instead of just adding more reps when an exercise is too easy,
we suggest progressing to a harder variant (skill-based progression).

This module is aligned to the REAL deployed schema (migrations 081 + 089):
  - exercise_progression_chains  (id, name, description, category, created_at)
  - exercise_progression_steps   (id, chain_id, exercise_name, step_order,
                                  difficulty_level, prerequisites, unlock_criteria,
                                  tips, video_url, created_at)
  - user_exercise_mastery        (id, user_id, exercise_name, consecutive_easy_sessions,
                                  consecutive_hard_sessions, total_sessions,
                                  ready_for_progression, suggested_next_variant,
                                  progression_chain_id, last_progression_suggested_at,
                                  progression_declined_at, decline_reason,
                                  progression_accepted_count, progression_declined_count,
                                  first_performed_at, last_performed_at, created_at,
                                  updated_at, current_max_reps, current_max_weight_kg,
                                  current_difficulty_level, current_max_weight,
                                  mastery_level, progression_status)

NOTE on the progression chain "step order":
  exercise_progression_steps.step_order is the canonical position of a variant in its
  chain (1 = easiest). user_exercise_mastery has NO stored current_variant_order column,
  so the current step is always DERIVED by looking up the user's exercise_name in
  exercise_progression_steps.

Example chains (deployed seed data):
- Pushup Mastery: Wall Pushups -> ... -> One-Arm Pushups
- Pullup Journey: Dead Hang -> ... -> One-Arm Pullups
- Squat Progressions: Assisted Squats -> ... -> Pistol Squats
"""
import json

from core.db import get_supabase_db

from .exercise_progressions_models import *  # noqa: F401, F403
from .exercise_progressions_endpoints import router as _endpoints_router


from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum
import uuid
import logging

from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

logger = get_logger(__name__)
router = APIRouter()


# =============================================================================
# Helper Functions
# =============================================================================

# Mapping of difficulty feedback -> numeric weight, used for status/score logic.
_DIFFICULTY_WEIGHT = {
    DifficultyFeedback.TOO_EASY: 3.0,
    DifficultyFeedback.JUST_RIGHT: 2.0,
    DifficultyFeedback.TOO_HARD: 1.0,
}


def _parse_prerequisites(raw: Any) -> List[str]:
    """Parse the prerequisites column.

    In the deployed schema (migration 081) prerequisites is a TEXT column holding a
    JSON-encoded array string, e.g. '["Wall Pushups: 20 reps x 3 sets"]'. Older or
    alternate rows may already be a Python list. Handle both robustly.
    """
    if raw is None:
        return []
    if isinstance(raw, list):
        return [str(item) for item in raw]
    if isinstance(raw, str):
        text = raw.strip()
        if not text:
            return []
        try:
            parsed = json.loads(text)
            if isinstance(parsed, list):
                return [str(item) for item in parsed]
            return [str(parsed)]
        except (json.JSONDecodeError, ValueError):
            # Not JSON — treat the whole string as a single prerequisite.
            return [text]
    return []


def _recommended_reps_from_criteria(unlock_criteria: Any) -> str:
    """Derive a human-readable recommended rep range from the unlock_criteria JSONB.

    unlock_criteria looks like {"reps": 12, "sets": 3, "consecutive_sessions": 3} or,
    for isometric holds, {"hold_seconds": 30, "sets": 3, ...}. There is no dedicated
    recommended_reps column in the real schema, so we synthesize one.
    """
    if not isinstance(unlock_criteria, dict):
        return "8-12"
    if "reps" in unlock_criteria:
        reps = unlock_criteria["reps"]
        try:
            reps_int = int(reps)
            # Present as a small range around the target for a natural rep prescription.
            low = max(1, reps_int - 2)
            return f"{low}-{reps_int}"
        except (TypeError, ValueError):
            return str(reps)
    if "min_reps" in unlock_criteria:
        low = unlock_criteria.get("min_reps")
        high = unlock_criteria.get("max_reps", low)
        return f"{low}-{high}"
    if "hold_seconds" in unlock_criteria:
        return f"{unlock_criteria['hold_seconds']}s hold"
    return "8-12"


def _parse_step(data: dict) -> ProgressionStep:
    """Parse a progression step from an exercise_progression_steps database row."""
    unlock_criteria = data.get("unlock_criteria") or {}
    if not isinstance(unlock_criteria, dict):
        unlock_criteria = {}
    return ProgressionStep(
        id=str(data["id"]),
        name=data["exercise_name"],
        order=data.get("step_order", 0) or 0,
        difficulty_level=data.get("difficulty_level") or 5,
        tips=data.get("tips"),
        video_url=data.get("video_url"),
        prerequisites=_parse_prerequisites(data.get("prerequisites")),
        unlock_criteria=unlock_criteria,
        recommended_reps=_recommended_reps_from_criteria(unlock_criteria),
    )


def _parse_chain(data: dict) -> ProgressionChainResponse:
    """Parse a progression chain from an exercise_progression_chains database row."""
    return ProgressionChainResponse(
        id=str(data["id"]),
        name=data["name"],
        category=data.get("category"),
        description=data.get("description"),
        total_steps=0,
        created_at=data.get("created_at"),
    )


def _parse_mastery(data: dict) -> ExerciseMastery:
    """Parse exercise mastery from a user_exercise_mastery database row.

    The real table stores the chain reference in `progression_chain_id` and the
    status string in `progression_status`. There is no current_variant_order column
    (current_step_order is derived elsewhere), no mastered_at, and no
    average_difficulty_rating column.
    """
    # progression_status may be NULL on legacy rows — fall back to LEARNING.
    raw_status = data.get("progression_status")
    try:
        status = MasteryStatus(raw_status) if raw_status else MasteryStatus.LEARNING
    except ValueError:
        status = MasteryStatus.LEARNING

    # current_max_weight may live in either current_max_weight or current_max_weight_kg.
    max_weight = data.get("current_max_weight")
    if max_weight is None:
        max_weight = data.get("current_max_weight_kg")

    return ExerciseMastery(
        id=str(data["id"]),
        user_id=str(data["user_id"]),
        exercise_name=data["exercise_name"],
        chain_id=str(data["progression_chain_id"]) if data.get("progression_chain_id") else None,
        current_step_order=None,  # derived by caller via exercise_progression_steps lookup
        status=status,
        total_sessions=data.get("total_sessions", 0) or 0,
        consecutive_easy_sessions=data.get("consecutive_easy_sessions", 0) or 0,
        consecutive_hard_sessions=data.get("consecutive_hard_sessions", 0) or 0,
        current_max_reps=data.get("current_max_reps", 0) or 0,
        current_max_weight=float(max_weight) if max_weight is not None else None,
        ready_for_progression=data.get("ready_for_progression", False) or False,
        suggested_next_variant=data.get("suggested_next_variant"),
        progression_accepted_count=data.get("progression_accepted_count", 0) or 0,
        progression_declined_count=data.get("progression_declined_count", 0) or 0,
        first_performed_at=data.get("first_performed_at"),
        last_performed_at=data.get("last_performed_at"),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


def _lookup_step_order(db, exercise_name: str, chain_id: Optional[str] = None) -> Optional[int]:
    """Find the step_order of an exercise within its progression chain.

    user_exercise_mastery does not store the step order, so we derive it from
    exercise_progression_steps by matching the exercise name. If chain_id is known we
    scope the lookup to that chain to disambiguate exercises that appear in multiple
    chains.
    """
    try:
        query = db.client.table("exercise_progression_steps").select(
            "step_order, chain_id"
        ).ilike("exercise_name", exercise_name)
        if chain_id:
            query = query.eq("chain_id", chain_id)
        result = query.limit(1).execute()
        if result.data:
            return result.data[0].get("step_order")
        return None
    except Exception as e:
        logger.error(f"Error looking up step order for {exercise_name}: {e}", exc_info=True)
        return None


def calculate_mastery_score(exercise_data: dict) -> float:
    """
    Calculate a mastery score based on exercise performance data.

    Factors (the real schema has no average_difficulty_rating column, so the score
    is built from session count, consistency, and max reps only):
    - Total sessions performed (more practice = higher score)  -> up to 0.4
    - Consistency (consecutive easy sessions indicate mastery)  -> up to 0.35
    - Max reps achieved relative to typical rep ranges          -> up to 0.25

    Returns a score from 0.0 to 1.0
    """
    score = 0.0

    # Total sessions factor (up to 0.4)
    total_sessions = exercise_data.get("total_sessions", 0) or 0
    score += min(total_sessions / 10, 1.0) * 0.4

    # Consecutive easy sessions factor (up to 0.35)
    consecutive_easy = exercise_data.get("consecutive_easy_sessions", 0) or 0
    if consecutive_easy >= 3:
        score += 0.35
    elif consecutive_easy == 2:
        score += 0.23
    elif consecutive_easy == 1:
        score += 0.12

    # Max reps factor (up to 0.25)
    max_reps = exercise_data.get("current_max_reps", 0) or 0
    if max_reps >= 15:
        score += 0.25
    elif max_reps >= 12:
        score += 0.18
    elif max_reps >= 8:
        score += 0.12
    elif max_reps >= 5:
        score += 0.06

    return min(score, 1.0)


async def check_progression_readiness(user_id: str, exercise_name: str) -> dict:
    """
    Determine if user is ready to progress to the next variant.

    Returns dict with:
    - ready: bool
    - reason: str explaining why/why not
    - confidence: float 0-1
    - suggested_next: optional next exercise name
    """
    try:
        db = get_supabase_db()

        # Get user's mastery data for this exercise
        mastery_result = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", exercise_name).execute()

        if not mastery_result.data:
            return {
                "ready": False,
                "reason": "No training history for this exercise",
                "confidence": 0.0,
                "suggested_next": None
            }

        mastery = mastery_result.data[0]

        # Calculate readiness based on criteria
        consecutive_easy = mastery.get("consecutive_easy_sessions", 0) or 0
        total_sessions = mastery.get("total_sessions", 0) or 0
        max_reps = mastery.get("current_max_reps", 0) or 0

        # Primary criterion: 2+ consecutive "too easy" sessions
        if consecutive_easy >= 2:
            return {
                "ready": True,
                "reason": f"Rated 'too easy' for {consecutive_easy} consecutive sessions",
                "confidence": 0.9,
                "suggested_next": mastery.get("suggested_next_variant")
            }

        # Secondary criterion: High volume with good performance
        if total_sessions >= 5 and max_reps >= 15:
            return {
                "ready": True,
                "reason": f"High performance: {max_reps} reps achieved over {total_sessions} sessions",
                "confidence": 0.7,
                "suggested_next": mastery.get("suggested_next_variant")
            }

        # Not ready yet
        reason_parts = []
        if consecutive_easy < 2:
            reason_parts.append(f"Need {2 - consecutive_easy} more 'too easy' sessions")
        if total_sessions < 5:
            reason_parts.append(f"Only {total_sessions}/5 total sessions completed")

        return {
            "ready": False,
            "reason": ". ".join(reason_parts) if reason_parts else "Keep training",
            "confidence": 0.0,
            "suggested_next": mastery.get("suggested_next_variant")
        }

    except Exception as e:
        logger.error(f"Error checking progression readiness: {e}", exc_info=True)
        return {
            "ready": False,
            "reason": f"Error: {str(e)}",
            "confidence": 0.0,
            "suggested_next": None
        }


async def get_next_variant(exercise_name: str) -> Optional[dict]:
    """
    Find the next harder variant in the progression chain.

    Returns dict with step info or None if no progression exists.
    """
    try:
        db = get_supabase_db()

        # Find the current step in any chain (case-insensitive match on exercise name).
        current_result = db.client.table("exercise_progression_steps").select(
            "id, chain_id, step_order"
        ).ilike("exercise_name", exercise_name).execute()

        if not current_result.data:
            # Exercise not in a progression chain
            return None

        current = current_result.data[0]
        chain_id = current["chain_id"]
        current_order = current["step_order"]

        # Get the next step in the same chain
        next_result = db.client.table("exercise_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).eq("step_order", current_order + 1).execute()

        if not next_result.data:
            # Already at the top of the chain
            return None

        next_step = next_result.data[0]

        # Get chain info
        chain_result = db.client.table("exercise_progression_chains").select(
            "name"
        ).eq("id", chain_id).execute()

        chain_name = chain_result.data[0]["name"] if chain_result.data else "Unknown Chain"

        return {
            "step": _parse_step(next_step),
            "chain_id": chain_id,
            "chain_name": chain_name,
        }

    except Exception as e:
        logger.error(f"Error getting next variant for {exercise_name}: {e}", exc_info=True)
        return None


# =============================================================================
# Progression Chains Endpoints
# =============================================================================

@router.get("/chains", response_model=List[ProgressionChainResponse])
async def get_progression_chains(
    category: Optional[str] = Query(
        default=None,
        description="Filter by chain category (e.g. pushup, pullup, squat, handstand)",
    ),
    muscle_group: Optional[str] = Query(
        default=None,
        description="Deprecated alias for `category` (chains have no muscle_group column)",
    ),
    current_user: dict = Depends(get_current_user),
):
    """
    Get all progression chains with their steps.

    Optionally filter by category. The legacy `muscle_group` query parameter is
    accepted as an alias for `category` for backward compatibility — the real
    exercise_progression_chains table has no muscle_group column.
    """
    # muscle_group is a legacy alias; category takes precedence if both are provided.
    effective_category = category or muscle_group
    logger.info(f"Getting progression chains: category={effective_category}")

    try:
        db = get_supabase_db()
        query = db.client.table("exercise_progression_chains").select("*")

        if effective_category:
            query = query.eq("category", effective_category)

        result = query.order("category").order("name").execute()

        chains = []
        for row in result.data or []:
            chain = _parse_chain(row)

            # Get steps for this chain
            steps_result = db.client.table("exercise_progression_steps").select("*").eq(
                "chain_id", row["id"]
            ).order("step_order").execute()

            chain.steps = [_parse_step(s) for s in steps_result.data or []]
            chain.total_steps = len(chain.steps)
            chains.append(chain)

        return chains

    except Exception as e:
        logger.error(f"Failed to get progression chains: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


@router.get("/chains/{chain_id}", response_model=ProgressionChainResponse)
async def get_progression_chain(chain_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get a specific progression chain with all its steps.
    """
    logger.info(f"Getting progression chain: {chain_id}")

    try:
        db = get_supabase_db()

        # Get the chain
        chain_result = db.client.table("exercise_progression_chains").select("*").eq(
            "id", chain_id
        ).execute()

        if not chain_result.data:
            raise HTTPException(status_code=404, detail="Progression chain not found")

        chain = _parse_chain(chain_result.data[0])

        # Get all steps
        steps_result = db.client.table("exercise_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).order("step_order").execute()

        chain.steps = [_parse_step(s) for s in steps_result.data or []]
        chain.total_steps = len(chain.steps)

        return chain

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get progression chain: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


# =============================================================================
# User Mastery Endpoints
# =============================================================================

@router.get("/user/{user_id}/mastery", response_model=List[ExerciseMasteryWithChain])
async def get_user_mastery(
    user_id: str,
    ready_only: bool = Query(default=False, description="Only return exercises ready for progression"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's exercise mastery levels for all exercises they've performed.

    Returns exercises with mastery status, including whether they're ready
    to progress and what the suggested next step is.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting mastery for user {user_id}, ready_only={ready_only}")

    try:
        db = get_supabase_db()

        query = db.client.table("user_exercise_mastery").select("*").eq("user_id", user_id)

        if ready_only:
            query = query.eq("ready_for_progression", True)

        result = query.order("last_performed_at", desc=True).execute()

        mastery_list = []
        for row in result.data or []:
            mastery = _parse_mastery(row)

            chain_name = None
            next_step = None
            chain_id = mastery.chain_id

            if chain_id:
                chain_result = db.client.table("exercise_progression_chains").select(
                    "name"
                ).eq("id", chain_id).execute()

                if chain_result.data:
                    chain_name = chain_result.data[0]["name"]

            # Derive the current step order from the steps table (no stored column).
            current_step_order = _lookup_step_order(db, mastery.exercise_name, chain_id)
            mastery.current_step_order = current_step_order

            # Get next step if ready for progression and we know the current position.
            if mastery.ready_for_progression and current_step_order is not None and chain_id:
                next_result = db.client.table("exercise_progression_steps").select("*").eq(
                    "chain_id", chain_id
                ).eq("step_order", current_step_order + 1).execute()

                if next_result.data:
                    next_step = _parse_step(next_result.data[0])

            mastery_with_chain = ExerciseMasteryWithChain(
                **mastery.model_dump(),
                chain_name=chain_name,
                next_step=next_step,
            )
            mastery_list.append(mastery_with_chain)

        return mastery_list

    except Exception as e:
        logger.error(f"Failed to get user mastery: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


@router.get("/user/{user_id}/suggestions", response_model=List[ProgressionSuggestion])
async def get_progression_suggestions(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get progression suggestions for exercises the user is ready to advance on.

    Based on:
    - consecutive_easy_sessions >= 2, OR
    - total_sessions >= 5 with high performance
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting progression suggestions for user {user_id}")

    try:
        db = get_supabase_db()

        # Get exercises ready for progression
        ready_result = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("ready_for_progression", True).execute()

        suggestions = []
        for row in ready_result.data or []:
            chain_id = row.get("progression_chain_id")
            if not chain_id:
                continue

            # Derive the user's current step order from the steps table.
            current_order = _lookup_step_order(db, row["exercise_name"], chain_id)
            if current_order is None:
                continue

            # Get current step (for its difficulty level)
            current_result = db.client.table("exercise_progression_steps").select("*").eq(
                "chain_id", chain_id
            ).eq("step_order", current_order).execute()

            if not current_result.data:
                continue

            current = current_result.data[0]

            # Get next step
            next_result = db.client.table("exercise_progression_steps").select("*").eq(
                "chain_id", chain_id
            ).eq("step_order", current_order + 1).execute()

            if not next_result.data:
                continue  # Already at top of chain

            next_step = next_result.data[0]

            # Get chain name
            chain_result = db.client.table("exercise_progression_chains").select(
                "name"
            ).eq("id", chain_id).execute()

            chain_name = chain_result.data[0]["name"] if chain_result.data else "Unknown"

            # Build suggestion
            consecutive_easy = row.get("consecutive_easy_sessions", 0) or 0
            total_sessions = row.get("total_sessions", 0) or 0
            max_reps = row.get("current_max_reps", 0) or 0

            if consecutive_easy >= 2:
                reason = f"Rated 'too easy' {consecutive_easy} times in a row"
                confidence = 0.9
            else:
                reason = f"Consistently high performance ({max_reps} reps over {total_sessions} sessions)"
                confidence = 0.7

            suggestions.append(ProgressionSuggestion(
                exercise_name=row["exercise_name"],
                current_difficulty_level=current.get("difficulty_level") or 5,
                suggested_exercise=next_step["exercise_name"],
                suggested_difficulty_level=next_step.get("difficulty_level") or 6,
                chain_id=str(chain_id),
                chain_name=chain_name,
                reason=reason,
                confidence=confidence,
                stats={
                    "total_sessions": total_sessions,
                    "consecutive_easy_sessions": consecutive_easy,
                    "current_max_reps": max_reps,
                    "current_max_weight": row.get("current_max_weight"),
                }
            ))

        return suggestions

    except Exception as e:
        logger.error(f"Failed to get progression suggestions: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


@router.post("/user/{user_id}/update-mastery", response_model=UpdateMasteryResponse)
async def update_exercise_mastery(user_id: str, request: UpdateMasteryRequest, current_user: dict = Depends(get_current_user)):
    """
    Update exercise mastery after a workout.

    Called after workout completion to track:
    - Reps performed
    - Weight used (if applicable)
    - Difficulty felt (too_easy/just_right/too_hard)

    Updates consecutive_easy_sessions, current_max_reps, and calculates
    whether user is ready for progression.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating mastery for user {user_id}, exercise: {request.exercise_name}")

    try:
        db = get_supabase_db()
        now = datetime.utcnow().isoformat()

        # Get existing mastery record
        existing_result = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).execute()

        if existing_result.data:
            # Update existing record
            existing = existing_result.data[0]

            # Calculate new values
            total_sessions = (existing.get("total_sessions", 0) or 0) + 1
            current_max_reps = max(existing.get("current_max_reps", 0) or 0, request.reps_performed)

            # Update max weight
            current_max_weight = existing.get("current_max_weight")
            if current_max_weight is None:
                current_max_weight = existing.get("current_max_weight_kg")
            if request.weight_used:
                if current_max_weight is None:
                    current_max_weight = request.weight_used
                else:
                    current_max_weight = max(current_max_weight, request.weight_used)

            # Update consecutive easy/hard sessions
            if request.difficulty_felt == DifficultyFeedback.TOO_EASY:
                consecutive_easy = (existing.get("consecutive_easy_sessions", 0) or 0) + 1
                consecutive_hard = 0
            elif request.difficulty_felt == DifficultyFeedback.TOO_HARD:
                consecutive_easy = 0
                consecutive_hard = (existing.get("consecutive_hard_sessions", 0) or 0) + 1
            else:
                consecutive_easy = 0
                consecutive_hard = 0

            # Determine if ready for progression
            ready_for_progression = (
                consecutive_easy >= 2 or
                (total_sessions >= 5 and current_max_reps >= 15)
            )

            # Determine status
            if ready_for_progression:
                status = MasteryStatus.MASTERED
            elif total_sessions >= 3:
                status = MasteryStatus.PROFICIENT
            else:
                status = MasteryStatus.LEARNING

            # Get suggested next variant if ready
            suggested_next = None
            if ready_for_progression:
                next_info = await get_next_variant(request.exercise_name)
                if next_info:
                    suggested_next = next_info["step"].name

            # Update record — only columns that exist on user_exercise_mastery.
            update_data = {
                "total_sessions": total_sessions,
                "consecutive_easy_sessions": consecutive_easy,
                "consecutive_hard_sessions": consecutive_hard,
                "current_max_reps": current_max_reps,
                "current_max_weight": current_max_weight,
                "ready_for_progression": ready_for_progression,
                "suggested_next_variant": suggested_next,
                "progression_status": status.value,
                "last_performed_at": now,
                "updated_at": now,
            }
            if ready_for_progression:
                update_data["last_progression_suggested_at"] = now

            result = db.client.table("user_exercise_mastery").update(update_data).eq(
                "id", existing["id"]
            ).execute()

            mastery = _parse_mastery(result.data[0])

        else:
            # Create new mastery record
            # First, check if exercise is in a progression chain.
            chain_id = None
            current_step = db.client.table("exercise_progression_steps").select(
                "chain_id"
            ).ilike("exercise_name", request.exercise_name).limit(1).execute()

            if current_step.data:
                chain_id = current_step.data[0]["chain_id"]

            # Determine initial values
            consecutive_easy = 1 if request.difficulty_felt == DifficultyFeedback.TOO_EASY else 0
            consecutive_hard = 1 if request.difficulty_felt == DifficultyFeedback.TOO_HARD else 0

            insert_data = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "exercise_name": request.exercise_name,
                "progression_chain_id": chain_id,
                "progression_status": MasteryStatus.LEARNING.value,
                "total_sessions": 1,
                "consecutive_easy_sessions": consecutive_easy,
                "consecutive_hard_sessions": consecutive_hard,
                "current_max_reps": request.reps_performed,
                "current_max_weight": request.weight_used,
                "ready_for_progression": False,
                "first_performed_at": now,
                "last_performed_at": now,
                "created_at": now,
                "updated_at": now,
            }

            result = db.client.table("user_exercise_mastery").insert(insert_data).execute()
            mastery = _parse_mastery(result.data[0])

        # Build response message
        progression_unlocked = mastery.ready_for_progression and mastery.suggested_next_variant is not None

        if progression_unlocked:
            message = f"Great work! You've mastered {request.exercise_name}. Ready to progress to {mastery.suggested_next_variant}!"
        elif mastery.status == MasteryStatus.PROFICIENT:
            message = f"Nice progress! You're getting proficient at {request.exercise_name}."
        else:
            message = f"Session logged for {request.exercise_name}. Keep training!"

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="exercise_mastery_updated",
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/update-mastery",
            message=f"Updated mastery for {request.exercise_name}: {request.difficulty_felt.value}",
            metadata={
                "exercise_name": request.exercise_name,
                "reps": request.reps_performed,
                "difficulty": request.difficulty_felt.value,
                "status": mastery.status.value,
                "ready_for_progression": mastery.ready_for_progression,
            },
            status_code=200
        )

        return UpdateMasteryResponse(
            success=True,
            mastery=mastery,
            progression_unlocked=progression_unlocked,
            suggested_next=mastery.suggested_next_variant,
            message=message,
        )

    except Exception as e:
        logger.error(f"Failed to update exercise mastery: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="exercise_mastery_updated",
            error=e,
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/update-mastery",
            metadata={"exercise_name": request.exercise_name},
            status_code=500
        )
        raise safe_internal_error(e, "exercise_progressions")


@router.post("/user/{user_id}/accept-progression", response_model=AcceptProgressionResponse)
async def accept_progression(user_id: str, request: AcceptProgressionRequest, current_user: dict = Depends(get_current_user)):
    """
    User accepts a progression to a harder exercise variant.

    This:
    1. Marks the old exercise as "progressed" (mastered)
    2. Creates or resets a mastery record for the new exercise
    3. Logs the activity for the user context service
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"User {user_id} accepting progression: {request.current_exercise} -> {request.new_exercise}")

    try:
        db = get_supabase_db()
        now = datetime.utcnow().isoformat()

        # Get current mastery record
        current_result = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", request.current_exercise).execute()

        if not current_result.data:
            raise HTTPException(
                status_code=404,
                detail=f"No mastery record found for {request.current_exercise}"
            )

        current = current_result.data[0]

        # Verify new exercise exists in a progression chain.
        new_step_result = db.client.table("exercise_progression_steps").select(
            "chain_id, step_order"
        ).ilike("exercise_name", request.new_exercise).execute()

        if not new_step_result.data:
            raise HTTPException(
                status_code=400,
                detail=f"{request.new_exercise} is not in a progression chain"
            )

        new_step = new_step_result.data[0]

        # Update old exercise to "progressed", and bump the accepted counter.
        prev_accepted = current.get("progression_accepted_count", 0) or 0
        db.client.table("user_exercise_mastery").update({
            "progression_status": MasteryStatus.PROGRESSED.value,
            "ready_for_progression": False,
            "progression_accepted_count": prev_accepted + 1,
            "updated_at": now,
        }).eq("id", current["id"]).execute()

        # Check if new exercise already has a mastery record
        existing_new = db.client.table("user_exercise_mastery").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.new_exercise).execute()

        if existing_new.data:
            # Reset existing record for the new exercise
            db.client.table("user_exercise_mastery").update({
                "progression_status": MasteryStatus.LEARNING.value,
                "progression_chain_id": new_step["chain_id"],
                "total_sessions": 0,
                "consecutive_easy_sessions": 0,
                "consecutive_hard_sessions": 0,
                "current_max_reps": 0,
                "current_max_weight": None,
                "ready_for_progression": False,
                "suggested_next_variant": None,
                "updated_at": now,
            }).eq("id", existing_new.data[0]["id"]).execute()
        else:
            # Create new mastery record
            insert_data = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "exercise_name": request.new_exercise,
                "progression_chain_id": new_step["chain_id"],
                "progression_status": MasteryStatus.LEARNING.value,
                "total_sessions": 0,
                "consecutive_easy_sessions": 0,
                "consecutive_hard_sessions": 0,
                "current_max_reps": 0,
                "ready_for_progression": False,
                "first_performed_at": now,
                "created_at": now,
                "updated_at": now,
            }

            db.client.table("user_exercise_mastery").insert(insert_data).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="exercise_progression_accepted",
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/accept-progression",
            message=f"Progressed from {request.current_exercise} to {request.new_exercise}",
            metadata={
                "old_exercise": request.current_exercise,
                "new_exercise": request.new_exercise,
                "chain_id": str(new_step["chain_id"]),
            },
            status_code=200
        )

        return AcceptProgressionResponse(
            success=True,
            old_exercise=request.current_exercise,
            old_status=MasteryStatus.PROGRESSED,
            new_exercise=request.new_exercise,
            new_status=MasteryStatus.LEARNING,
            message=f"Congratulations! You've progressed to {request.new_exercise}. Time to master a new challenge!",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to accept progression: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="exercise_progression_accepted",
            error=e,
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/accept-progression",
            metadata={
                "old_exercise": request.current_exercise,
                "new_exercise": request.new_exercise,
            },
            status_code=500
        )
        raise safe_internal_error(e, "exercise_progressions")


# =============================================================================
# Rep Preferences Endpoints
# =============================================================================


# Include secondary endpoints
router.include_router(_endpoints_router)
