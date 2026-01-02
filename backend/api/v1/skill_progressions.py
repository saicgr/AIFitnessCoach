"""
Skill Progressions API endpoints.

Tracks bodyweight skill progressions like:
- Push-up progressions (wall -> incline -> knee -> full -> diamond -> archer -> one-arm)
- Pull-up progressions (dead hang -> negatives -> band-assisted -> full -> muscle-up)
- Squat progressions (assisted -> bodyweight -> pistol)
- Handstand progressions (wall hold -> freestanding -> handstand pushup)
"""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
from datetime import datetime
import uuid

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.skill_progression import (
    ProgressionChain,
    ProgressionChainWithSteps,
    ProgressionStep,
    UserSkillProgress,
    UserSkillProgressWithChain,
    UserSkillProgressWithHistory,
    LogAttemptRequest,
    LogAttemptResponse,
    UnlockNextResponse,
    StartChainResponse,
    SkillProgressSummary,
    UserSkillsSummary,
    SkillAttempt,
    UnlockCriteria,
    SkillCategory,
    DifficultyLevel,
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Helper Functions
# ============================================

def _parse_chain(data: dict) -> ProgressionChain:
    """Parse a progression chain from database row."""
    return ProgressionChain(
        id=str(data["id"]),
        name=data["name"],
        description=data["description"],
        category=data["category"],
        icon=data.get("icon"),
        target_muscles=data.get("target_muscles", []),
        estimated_weeks_to_master=data.get("estimated_weeks_to_master"),
        total_steps=data.get("total_steps", 0),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


def _parse_step(data: dict) -> ProgressionStep:
    """Parse a progression step from database row."""
    unlock_criteria_data = data.get("unlock_criteria", {}) or {}
    unlock_criteria = UnlockCriteria(
        min_reps=unlock_criteria_data.get("min_reps"),
        min_sets=unlock_criteria_data.get("min_sets"),
        min_hold_seconds=unlock_criteria_data.get("min_hold_seconds"),
        min_consecutive_days=unlock_criteria_data.get("min_consecutive_days"),
        custom_requirement=unlock_criteria_data.get("custom_requirement"),
    )

    return ProgressionStep(
        id=str(data["id"]),
        chain_id=str(data["chain_id"]),
        exercise_name=data["exercise_name"],
        step_order=data["step_order"],
        difficulty_level=data["difficulty_level"],
        prerequisites=data.get("prerequisites", []),
        unlock_criteria=unlock_criteria,
        tips=data.get("tips", []),
        common_mistakes=data.get("common_mistakes", []),
        video_url=data.get("video_url"),
        image_url=data.get("image_url"),
        description=data.get("description"),
        sets_recommendation=data.get("sets_recommendation", "3"),
        reps_recommendation=data.get("reps_recommendation", "8-12"),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


def _parse_progress(data: dict) -> UserSkillProgress:
    """Parse user skill progress from database row."""
    return UserSkillProgress(
        id=str(data["id"]),
        user_id=data["user_id"],
        chain_id=str(data["chain_id"]),
        current_step_order=data.get("current_step_order", 0),
        unlocked_steps=data.get("unlocked_steps", [0]),
        attempts_at_current=data.get("attempts_at_current", 0),
        best_reps_at_current=data.get("best_reps_at_current", 0),
        best_hold_at_current=data.get("best_hold_at_current"),
        is_completed=data.get("is_completed", False),
        is_active=data.get("is_active", True),
        started_at=data.get("started_at"),
        last_attempt_at=data.get("last_attempt_at"),
        completed_at=data.get("completed_at"),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


def _check_unlock_criteria(
    criteria: UnlockCriteria,
    reps: int,
    sets: int,
    hold_seconds: Optional[int] = None,
) -> bool:
    """Check if the unlock criteria is met."""
    # Check reps requirement
    if criteria.min_reps and reps < criteria.min_reps:
        return False

    # Check sets requirement
    if criteria.min_sets and sets < criteria.min_sets:
        return False

    # Check hold time requirement
    if criteria.min_hold_seconds:
        if hold_seconds is None or hold_seconds < criteria.min_hold_seconds:
            return False

    return True


# ============================================
# Progression Chains Endpoints
# ============================================

@router.get("/chains", response_model=List[ProgressionChain])
async def get_all_progression_chains(
    category: Optional[SkillCategory] = None,
):
    """
    Get all available progression chains.

    Optionally filter by category (push, pull, legs, core, balance, flexibility).
    """
    logger.info(f"Getting all progression chains, category filter: {category}")

    try:
        db = get_supabase_db()
        query = db.client.table("skill_progression_chains").select("*")

        if category:
            query = query.eq("category", category.value)

        result = query.order("category").order("name").execute()

        return [_parse_chain(c) for c in result.data]

    except Exception as e:
        logger.error(f"Failed to get progression chains: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chains/{chain_id}", response_model=ProgressionChainWithSteps)
async def get_progression_chain(chain_id: str):
    """
    Get a specific progression chain with all its steps.
    """
    logger.info(f"Getting progression chain: {chain_id}")

    try:
        db = get_supabase_db()

        # Get the chain
        chain_result = db.client.table("skill_progression_chains").select("*").eq(
            "id", chain_id
        ).execute()

        if not chain_result.data:
            raise HTTPException(status_code=404, detail="Progression chain not found")

        chain = _parse_chain(chain_result.data[0])

        # Get all steps for this chain
        steps_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).order("step_order").execute()

        steps = [_parse_step(s) for s in steps_result.data]

        return ProgressionChainWithSteps(
            **chain.model_dump(),
            steps=steps,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get progression chain: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chains/{chain_id}/steps", response_model=List[ProgressionStep])
async def get_chain_steps(chain_id: str):
    """
    Get all steps for a progression chain.
    """
    logger.info(f"Getting steps for chain: {chain_id}")

    try:
        db = get_supabase_db()

        # Verify chain exists
        chain_result = db.client.table("skill_progression_chains").select("id").eq(
            "id", chain_id
        ).execute()

        if not chain_result.data:
            raise HTTPException(status_code=404, detail="Progression chain not found")

        # Get all steps
        steps_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).order("step_order").execute()

        return [_parse_step(s) for s in steps_result.data]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get chain steps: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# User Progress Endpoints
# ============================================

@router.get("/user/{user_id}/progress", response_model=List[UserSkillProgressWithChain])
async def get_user_skill_progress(
    user_id: str,
    active_only: bool = False,
):
    """
    Get user's progress on all chains they've started.

    Set active_only=true to only get progressions the user is actively working on.
    """
    logger.info(f"Getting skill progress for user: {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("user_skill_progress").select(
            "*, skill_progression_chains(*)"
        ).eq("user_id", user_id)

        if active_only:
            query = query.eq("is_active", True)

        result = query.order("last_attempt_at", desc=True).execute()

        progress_list = []
        for p in result.data:
            progress = _parse_progress(p)

            # Parse chain info
            chain = None
            if p.get("skill_progression_chains"):
                chain = _parse_chain(p["skill_progression_chains"])

            # Get current and next step
            current_step = None
            next_step = None

            if chain:
                steps_result = db.client.table("skill_progression_steps").select("*").eq(
                    "chain_id", progress.chain_id
                ).order("step_order").execute()

                for s in steps_result.data:
                    if s["step_order"] == progress.current_step_order:
                        current_step = _parse_step(s)
                    elif s["step_order"] == progress.current_step_order + 1:
                        next_step = _parse_step(s)

            progress_list.append(UserSkillProgressWithChain(
                **progress.model_dump(),
                chain=chain,
                current_step=current_step,
                next_step=next_step,
            ))

        return progress_list

    except Exception as e:
        logger.error(f"Failed to get user skill progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/progress/{chain_id}", response_model=UserSkillProgressWithHistory)
async def get_user_chain_progress(user_id: str, chain_id: str):
    """
    Get user's progress on a specific chain, including recent attempt history.
    """
    logger.info(f"Getting progress for user {user_id} on chain {chain_id}")

    try:
        db = get_supabase_db()

        # Get user progress
        progress_result = db.client.table("user_skill_progress").select(
            "*, skill_progression_chains(*)"
        ).eq("user_id", user_id).eq("chain_id", chain_id).execute()

        if not progress_result.data:
            raise HTTPException(
                status_code=404,
                detail="User has not started this progression chain"
            )

        p = progress_result.data[0]
        progress = _parse_progress(p)

        # Parse chain
        chain = None
        if p.get("skill_progression_chains"):
            chain = _parse_chain(p["skill_progression_chains"])

        # Get current step
        current_step = None
        steps_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).eq("step_order", progress.current_step_order).execute()

        if steps_result.data:
            current_step = _parse_step(steps_result.data[0])

        # Get recent attempts
        attempts_result = db.client.table("skill_attempt_logs").select("*").eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).order("attempted_at", desc=True).limit(10).execute()

        recent_attempts = [
            SkillAttempt(
                reps=a["reps"],
                sets=a.get("sets", 1),
                hold_seconds=a.get("hold_seconds"),
                success=a.get("success", False),
                notes=a.get("notes"),
                attempted_at=a["attempted_at"],
            )
            for a in attempts_result.data
        ]

        return UserSkillProgressWithHistory(
            **progress.model_dump(),
            chain=chain,
            current_step=current_step,
            recent_attempts=recent_attempts,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user chain progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/summary", response_model=UserSkillsSummary)
async def get_user_skills_summary(user_id: str):
    """
    Get a summary of all user's skill progressions.
    """
    logger.info(f"Getting skills summary for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get all user progress with chain info
        progress_result = db.client.table("user_skill_progress").select(
            "*, skill_progression_chains(*)"
        ).eq("user_id", user_id).execute()

        active_progressions = []
        completed_progressions = []

        for p in progress_result.data:
            chain_data = p.get("skill_progression_chains", {})
            if not chain_data:
                continue

            total_steps = chain_data.get("total_steps", 1)
            completed_steps = len(p.get("unlocked_steps", [0]))
            progress_percentage = min(100, (completed_steps / max(1, total_steps)) * 100)

            # Get current step name
            current_step_result = db.client.table("skill_progression_steps").select(
                "exercise_name"
            ).eq("chain_id", p["chain_id"]).eq(
                "step_order", p.get("current_step_order", 0)
            ).execute()

            current_step_name = "Unknown"
            if current_step_result.data:
                current_step_name = current_step_result.data[0]["exercise_name"]

            summary = SkillProgressSummary(
                chain_id=str(p["chain_id"]),
                chain_name=chain_data["name"],
                category=chain_data["category"],
                current_step_name=current_step_name,
                progress_percentage=progress_percentage,
                total_steps=total_steps,
                completed_steps=completed_steps,
                is_completed=p.get("is_completed", False),
                last_attempt_at=p.get("last_attempt_at"),
            )

            if p.get("is_completed", False):
                completed_progressions.append(summary)
            elif p.get("is_active", True):
                active_progressions.append(summary)

        # Find a recommended next chain (one not started yet)
        started_chain_ids = [p["chain_id"] for p in progress_result.data]

        recommended = None
        all_chains = db.client.table("skill_progression_chains").select("*").execute()
        for c in all_chains.data:
            if c["id"] not in started_chain_ids:
                recommended = _parse_chain(c)
                break

        return UserSkillsSummary(
            total_chains_started=len(progress_result.data),
            total_chains_completed=len(completed_progressions),
            active_progressions=active_progressions,
            completed_progressions=completed_progressions,
            recommended_next_chain=recommended,
        )

    except Exception as e:
        logger.error(f"Failed to get user skills summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Progression Actions Endpoints
# ============================================

@router.post("/user/{user_id}/start-chain/{chain_id}", response_model=StartChainResponse)
async def start_progression_chain(user_id: str, chain_id: str):
    """
    Start tracking a new progression chain for a user.

    This creates the initial progress record with the first step unlocked.
    """
    logger.info(f"Starting chain {chain_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Check if chain exists
        chain_result = db.client.table("skill_progression_chains").select("*").eq(
            "id", chain_id
        ).execute()

        if not chain_result.data:
            raise HTTPException(status_code=404, detail="Progression chain not found")

        chain = _parse_chain(chain_result.data[0])

        # Check if user already started this chain
        existing = db.client.table("user_skill_progress").select("id").eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="User has already started this progression chain"
            )

        # Get the first step
        first_step_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).eq("step_order", 0).execute()

        first_step = None
        if first_step_result.data:
            first_step = _parse_step(first_step_result.data[0])

        # Create progress record
        now = datetime.utcnow().isoformat()
        progress_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "chain_id": chain_id,
            "current_step_order": 0,
            "unlocked_steps": [0],
            "attempts_at_current": 0,
            "best_reps_at_current": 0,
            "is_completed": False,
            "is_active": True,
            "started_at": now,
            "created_at": now,
            "updated_at": now,
        }

        result = db.client.table("user_skill_progress").insert(progress_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create progress record")

        progress = _parse_progress(result.data[0])

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="skill_chain_started",
            endpoint=f"/api/v1/skill-progressions/user/{user_id}/start-chain/{chain_id}",
            message=f"Started {chain.name} progression",
            metadata={"chain_id": chain_id, "chain_name": chain.name},
            status_code=200
        )

        return StartChainResponse(
            success=True,
            message=f"Started {chain.name} progression! Your first exercise is: {first_step.exercise_name if first_step else 'Unknown'}",
            progress=progress,
            chain=chain,
            first_step=first_step,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to start progression chain: {e}")
        await log_user_error(
            user_id=user_id,
            action="skill_chain_started",
            error=e,
            endpoint=f"/api/v1/skill-progressions/user/{user_id}/start-chain/{chain_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}/progress/{chain_id}/log-attempt", response_model=LogAttemptResponse)
async def log_skill_attempt(
    user_id: str,
    chain_id: str,
    request: LogAttemptRequest,
):
    """
    Log an attempt at the current progression level.

    This records the attempt and checks if the user can unlock the next step.
    """
    logger.info(f"Logging attempt for user {user_id} on chain {chain_id}: {request.reps} reps")

    try:
        db = get_supabase_db()

        # Get user progress
        progress_result = db.client.table("user_skill_progress").select("*").eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).execute()

        if not progress_result.data:
            raise HTTPException(
                status_code=404,
                detail="User has not started this progression chain"
            )

        progress_data = progress_result.data[0]

        # Get current step for unlock criteria
        current_step_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).eq("step_order", progress_data["current_step_order"]).execute()

        if not current_step_result.data:
            raise HTTPException(status_code=404, detail="Current step not found")

        current_step = _parse_step(current_step_result.data[0])

        # Log the attempt
        now = datetime.utcnow().isoformat()
        attempt_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "chain_id": chain_id,
            "step_order": progress_data["current_step_order"],
            "reps": request.reps,
            "sets": request.sets,
            "hold_seconds": request.hold_seconds,
            "success": request.success,
            "notes": request.notes,
            "attempted_at": now,
        }

        db.client.table("skill_attempt_logs").insert(attempt_data).execute()

        # Check if this is a new best
        is_new_best = False
        best_reps = progress_data.get("best_reps_at_current", 0)
        best_hold = progress_data.get("best_hold_at_current")

        if request.reps > best_reps:
            best_reps = request.reps
            is_new_best = True

        if request.hold_seconds and (best_hold is None or request.hold_seconds > best_hold):
            best_hold = request.hold_seconds
            is_new_best = True

        # Check unlock criteria
        unlock_criteria_met = _check_unlock_criteria(
            current_step.unlock_criteria,
            request.reps,
            request.sets,
            request.hold_seconds,
        )

        # Check if there's a next step to unlock
        next_step_result = db.client.table("skill_progression_steps").select("id").eq(
            "chain_id", chain_id
        ).eq("step_order", progress_data["current_step_order"] + 1).execute()

        can_unlock_next = unlock_criteria_met and len(next_step_result.data) > 0

        # Update progress
        update_data = {
            "attempts_at_current": progress_data.get("attempts_at_current", 0) + 1,
            "best_reps_at_current": best_reps,
            "best_hold_at_current": best_hold,
            "last_attempt_at": now,
            "updated_at": now,
        }

        update_result = db.client.table("user_skill_progress").update(
            update_data
        ).eq("id", progress_data["id"]).execute()

        progress = _parse_progress(update_result.data[0])

        # Build response message
        message_parts = []
        if is_new_best:
            message_parts.append(f"New personal best: {request.reps} reps!")
        if unlock_criteria_met:
            message_parts.append("You've met the unlock criteria!")
        if can_unlock_next:
            message_parts.append("You can now unlock the next step.")

        message = " ".join(message_parts) if message_parts else f"Attempt logged: {request.reps} reps"

        return LogAttemptResponse(
            success=True,
            message=message,
            progress=progress,
            is_new_best=is_new_best,
            can_unlock_next=can_unlock_next,
            unlock_criteria_met=unlock_criteria_met,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log skill attempt: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}/progress/{chain_id}/unlock-next", response_model=UnlockNextResponse)
async def unlock_next_step(user_id: str, chain_id: str):
    """
    Unlock the next step in the progression (when criteria is met).

    This advances the user to the next step and marks the previous step as unlocked.
    """
    logger.info(f"Unlocking next step for user {user_id} on chain {chain_id}")

    try:
        db = get_supabase_db()

        # Get user progress
        progress_result = db.client.table("user_skill_progress").select("*").eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).execute()

        if not progress_result.data:
            raise HTTPException(
                status_code=404,
                detail="User has not started this progression chain"
            )

        progress_data = progress_result.data[0]
        current_step_order = progress_data["current_step_order"]

        # Get current step for unlock criteria
        current_step_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).eq("step_order", current_step_order).execute()

        if not current_step_result.data:
            raise HTTPException(status_code=404, detail="Current step not found")

        current_step = _parse_step(current_step_result.data[0])

        # Check if criteria is met based on best performance
        criteria_met = _check_unlock_criteria(
            current_step.unlock_criteria,
            progress_data.get("best_reps_at_current", 0),
            1,  # Assume at least 1 set for best reps
            progress_data.get("best_hold_at_current"),
        )

        if not criteria_met:
            raise HTTPException(
                status_code=400,
                detail=f"Unlock criteria not met. Need: {current_step.unlock_criteria.min_reps} reps"
            )

        # Get next step
        next_step_result = db.client.table("skill_progression_steps").select("*").eq(
            "chain_id", chain_id
        ).eq("step_order", current_step_order + 1).execute()

        if not next_step_result.data:
            # No more steps - mark chain as completed
            now = datetime.utcnow().isoformat()
            update_data = {
                "is_completed": True,
                "completed_at": now,
                "updated_at": now,
            }

            update_result = db.client.table("user_skill_progress").update(
                update_data
            ).eq("id", progress_data["id"]).execute()

            progress = _parse_progress(update_result.data[0])

            await log_user_activity(
                user_id=user_id,
                action="skill_chain_completed",
                endpoint=f"/api/v1/skill-progressions/user/{user_id}/progress/{chain_id}/unlock-next",
                message=f"Completed progression chain",
                metadata={"chain_id": chain_id},
                status_code=200
            )

            return UnlockNextResponse(
                success=True,
                message="Congratulations! You've completed the entire progression chain!",
                progress=progress,
                unlocked_step=None,
                is_chain_completed=True,
            )

        next_step = _parse_step(next_step_result.data[0])

        # Unlock next step
        unlocked_steps = progress_data.get("unlocked_steps", [0])
        if current_step_order + 1 not in unlocked_steps:
            unlocked_steps.append(current_step_order + 1)

        now = datetime.utcnow().isoformat()
        update_data = {
            "current_step_order": current_step_order + 1,
            "unlocked_steps": unlocked_steps,
            "attempts_at_current": 0,
            "best_reps_at_current": 0,
            "best_hold_at_current": None,
            "updated_at": now,
        }

        update_result = db.client.table("user_skill_progress").update(
            update_data
        ).eq("id", progress_data["id"]).execute()

        progress = _parse_progress(update_result.data[0])

        await log_user_activity(
            user_id=user_id,
            action="skill_step_unlocked",
            endpoint=f"/api/v1/skill-progressions/user/{user_id}/progress/{chain_id}/unlock-next",
            message=f"Unlocked {next_step.exercise_name}",
            metadata={"chain_id": chain_id, "step_order": current_step_order + 1},
            status_code=200
        )

        return UnlockNextResponse(
            success=True,
            message=f"Level up! You've unlocked: {next_step.exercise_name}",
            progress=progress,
            unlocked_step=next_step,
            is_chain_completed=False,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to unlock next step: {e}")
        await log_user_error(
            user_id=user_id,
            action="skill_step_unlocked",
            error=e,
            endpoint=f"/api/v1/skill-progressions/user/{user_id}/progress/{chain_id}/unlock-next",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/user/{user_id}/progress/{chain_id}/toggle-active")
async def toggle_progression_active(user_id: str, chain_id: str, is_active: bool):
    """
    Toggle whether a progression is actively being worked on.

    This helps users focus on specific progressions without losing progress on others.
    """
    logger.info(f"Toggling active status for user {user_id} on chain {chain_id}: {is_active}")

    try:
        db = get_supabase_db()

        # Get user progress
        progress_result = db.client.table("user_skill_progress").select("id").eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).execute()

        if not progress_result.data:
            raise HTTPException(
                status_code=404,
                detail="User has not started this progression chain"
            )

        # Update active status
        now = datetime.utcnow().isoformat()
        update_data = {
            "is_active": is_active,
            "updated_at": now,
        }

        update_result = db.client.table("user_skill_progress").update(
            update_data
        ).eq("id", progress_result.data[0]["id"]).execute()

        progress = _parse_progress(update_result.data[0])

        return {
            "success": True,
            "message": f"Progression {'activated' if is_active else 'paused'}",
            "progress": progress,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to toggle progression active status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/user/{user_id}/progress/{chain_id}")
async def delete_progression_progress(user_id: str, chain_id: str):
    """
    Delete user's progress on a progression chain.

    This is a destructive action and cannot be undone.
    """
    logger.info(f"Deleting progress for user {user_id} on chain {chain_id}")

    try:
        db = get_supabase_db()

        # Delete attempt logs first
        db.client.table("skill_attempt_logs").delete().eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).execute()

        # Delete progress record
        result = db.client.table("user_skill_progress").delete().eq(
            "user_id", user_id
        ).eq("chain_id", chain_id).execute()

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="User has not started this progression chain"
            )

        await log_user_activity(
            user_id=user_id,
            action="skill_progress_deleted",
            endpoint=f"/api/v1/skill-progressions/user/{user_id}/progress/{chain_id}",
            message=f"Deleted progression progress",
            metadata={"chain_id": chain_id},
            status_code=200
        )

        return {
            "success": True,
            "message": "Progression progress deleted successfully",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete progression progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))
