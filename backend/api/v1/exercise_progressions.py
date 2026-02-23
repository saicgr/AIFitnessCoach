"""
Exercise Progressions API - Leverage-based exercise progressions for adaptive difficulty.

This module provides endpoints to:
1. Track exercise mastery levels based on user feedback
2. Suggest progression to harder variants when exercises become too easy
3. Manage progression chains (e.g., Push-up -> Diamond Push-up -> Archer Push-up)
4. Allow users to customize rep range preferences and progression style

The key insight: Instead of just adding more reps when an exercise is too easy,
we suggest progressing to a harder variant (leverage-based progression).

Example chains:
- Push-up: Wall -> Incline -> Knee -> Standard -> Diamond -> Archer -> One-arm
- Row: Inverted Row (high) -> Inverted Row (low) -> Pull-up -> Weighted Pull-up
- Squat: Assisted -> Bodyweight -> Split -> Bulgarian -> Pistol
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum
import uuid
import logging

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

logger = get_logger(__name__)
router = APIRouter()


# =============================================================================
# Enums and Constants
# =============================================================================

class ChainType(str, Enum):
    """Types of progression chains."""
    LEVERAGE = "leverage"  # Body position changes (push-up variants)
    LOAD = "load"  # Weight progression (dumbbells to barbells)
    STABILITY = "stability"  # Stability challenges (bilateral to unilateral)
    RANGE = "range"  # Range of motion (partial to full)
    TEMPO = "tempo"  # Speed/time under tension


class MuscleGroup(str, Enum):
    """Primary muscle groups for filtering chains."""
    CHEST = "chest"
    BACK = "back"
    SHOULDERS = "shoulders"
    BICEPS = "biceps"
    TRICEPS = "triceps"
    CORE = "core"
    QUADRICEPS = "quadriceps"
    HAMSTRINGS = "hamstrings"
    GLUTES = "glutes"
    CALVES = "calves"
    FULL_BODY = "full_body"


class DifficultyFeedback(str, Enum):
    """User feedback on exercise difficulty."""
    TOO_EASY = "too_easy"
    JUST_RIGHT = "just_right"
    TOO_HARD = "too_hard"


class MasteryStatus(str, Enum):
    """Mastery status for an exercise."""
    LEARNING = "learning"  # Still building proficiency
    PROFICIENT = "proficient"  # Comfortable with the exercise
    MASTERED = "mastered"  # Ready to progress
    PROGRESSED = "progressed"  # Moved to a harder variant


class ProgressionStyle(str, Enum):
    """User's preferred progression style."""
    CONSERVATIVE = "conservative"  # Slow, steady progression
    MODERATE = "moderate"  # Balanced approach
    AGGRESSIVE = "aggressive"  # Push to harder variants quickly


class TrainingFocus(str, Enum):
    """User's training focus affecting rep ranges."""
    STRENGTH = "strength"  # Lower reps, higher intensity (1-5)
    HYPERTROPHY = "hypertrophy"  # Moderate reps (6-12)
    ENDURANCE = "endurance"  # Higher reps (12-20+)
    MIXED = "mixed"  # Varied rep ranges


# =============================================================================
# Request/Response Models
# =============================================================================

class ProgressionVariant(BaseModel):
    """A single variant in a progression chain."""
    id: str
    name: str
    order: int = Field(..., ge=0, description="Order in the chain (0 = easiest)")
    difficulty_score: float = Field(..., ge=1.0, le=10.0, description="1-10 difficulty rating")
    description: Optional[str] = None
    cues: List[str] = Field(default_factory=list, description="Form cues for this variant")
    common_mistakes: List[str] = Field(default_factory=list)
    video_url: Optional[str] = None
    prerequisites: List[str] = Field(default_factory=list, description="What user should master first")
    recommended_reps: str = Field(default="8-12", description="Recommended rep range")
    library_exercise_id: Optional[str] = None


class ProgressionChainResponse(BaseModel):
    """A progression chain with all its variants."""
    id: str
    name: str
    muscle_group: MuscleGroup
    chain_type: ChainType
    description: Optional[str] = None
    total_variants: int
    variants: List[ProgressionVariant] = Field(default_factory=list)
    created_at: Optional[datetime] = None


class ExerciseMastery(BaseModel):
    """User's mastery status for a specific exercise."""
    id: str
    user_id: str
    exercise_name: str
    chain_id: Optional[str] = None
    current_variant_order: Optional[int] = None
    status: MasteryStatus
    total_sessions: int = 0
    consecutive_easy_sessions: int = 0
    consecutive_hard_sessions: int = 0
    current_max_reps: int = 0
    current_max_weight: Optional[float] = None
    average_difficulty_rating: Optional[float] = None
    ready_for_progression: bool = False
    suggested_next_variant: Optional[str] = None
    last_performed_at: Optional[datetime] = None
    mastered_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ExerciseMasteryWithChain(ExerciseMastery):
    """Exercise mastery with chain details."""
    chain_name: Optional[str] = None
    next_variant: Optional[ProgressionVariant] = None


class ProgressionSuggestion(BaseModel):
    """A suggestion to progress to a harder exercise variant."""
    exercise_name: str
    current_difficulty_score: float
    suggested_exercise: str
    suggested_difficulty_score: float
    chain_id: str
    chain_name: str
    reason: str
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence in this suggestion")
    stats: Dict[str, Any] = Field(default_factory=dict)


class UpdateMasteryRequest(BaseModel):
    """Request to update mastery after a workout."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    reps_performed: int = Field(..., ge=0, le=1000)
    weight_used: Optional[float] = Field(default=None, ge=0, le=2000)
    difficulty_felt: DifficultyFeedback
    sets_completed: int = Field(default=3, ge=1, le=20)
    notes: Optional[str] = Field(default=None, max_length=500)


class UpdateMasteryResponse(BaseModel):
    """Response from updating mastery."""
    success: bool
    mastery: ExerciseMastery
    progression_unlocked: bool = False
    suggested_next: Optional[str] = None
    message: str


class AcceptProgressionRequest(BaseModel):
    """Request to accept a progression suggestion."""
    current_exercise: str = Field(..., min_length=1, max_length=200)
    new_exercise: str = Field(..., min_length=1, max_length=200)


class AcceptProgressionResponse(BaseModel):
    """Response from accepting a progression."""
    success: bool
    old_exercise: str
    old_status: MasteryStatus
    new_exercise: str
    new_status: MasteryStatus
    message: str


class RepPreferences(BaseModel):
    """User's rep range preferences."""
    training_focus: TrainingFocus = TrainingFocus.HYPERTROPHY
    preferred_min_reps: int = Field(default=6, ge=1, le=50)
    preferred_max_reps: int = Field(default=12, ge=1, le=100)
    avoid_high_reps: bool = False
    progression_style: ProgressionStyle = ProgressionStyle.MODERATE


class RepPreferencesResponse(BaseModel):
    """Response with rep preferences."""
    training_focus: TrainingFocus
    preferred_min_reps: int
    preferred_max_reps: int
    avoid_high_reps: bool
    progression_style: ProgressionStyle
    description: str


# =============================================================================
# Helper Functions
# =============================================================================

def _parse_variant(data: dict) -> ProgressionVariant:
    """Parse a progression variant from database row."""
    return ProgressionVariant(
        id=str(data["id"]),
        name=data["name"],
        order=data.get("variant_order", 0),
        difficulty_score=data.get("difficulty_score", 5.0),
        description=data.get("description"),
        cues=data.get("cues", []) or [],
        common_mistakes=data.get("common_mistakes", []) or [],
        video_url=data.get("video_url"),
        prerequisites=data.get("prerequisites", []) or [],
        recommended_reps=data.get("recommended_reps", "8-12"),
        library_exercise_id=data.get("library_exercise_id"),
    )


def _parse_chain(data: dict) -> ProgressionChainResponse:
    """Parse a progression chain from database row."""
    return ProgressionChainResponse(
        id=str(data["id"]),
        name=data["name"],
        muscle_group=data.get("muscle_group", MuscleGroup.FULL_BODY),
        chain_type=data.get("chain_type", ChainType.LEVERAGE),
        description=data.get("description"),
        total_variants=data.get("total_variants", 0),
        created_at=data.get("created_at"),
    )


def _parse_mastery(data: dict) -> ExerciseMastery:
    """Parse exercise mastery from database row."""
    return ExerciseMastery(
        id=str(data["id"]),
        user_id=data["user_id"],
        exercise_name=data["exercise_name"],
        chain_id=data.get("chain_id"),
        current_variant_order=data.get("current_variant_order"),
        status=data.get("status", MasteryStatus.LEARNING),
        total_sessions=data.get("total_sessions", 0),
        consecutive_easy_sessions=data.get("consecutive_easy_sessions", 0),
        consecutive_hard_sessions=data.get("consecutive_hard_sessions", 0),
        current_max_reps=data.get("current_max_reps", 0),
        current_max_weight=data.get("current_max_weight"),
        average_difficulty_rating=data.get("average_difficulty_rating"),
        ready_for_progression=data.get("ready_for_progression", False),
        suggested_next_variant=data.get("suggested_next_variant"),
        last_performed_at=data.get("last_performed_at"),
        mastered_at=data.get("mastered_at"),
        created_at=data.get("created_at"),
        updated_at=data.get("updated_at"),
    )


def calculate_mastery_score(exercise_data: dict) -> float:
    """
    Calculate a mastery score based on exercise performance data.

    Factors:
    - Total sessions performed (more practice = higher score)
    - Consistency (consecutive easy sessions indicate mastery)
    - Max reps achieved relative to typical rep ranges
    - Difficulty feedback history

    Returns a score from 0.0 to 1.0
    """
    score = 0.0

    # Total sessions factor (up to 0.3)
    total_sessions = exercise_data.get("total_sessions", 0)
    session_score = min(total_sessions / 10, 1.0) * 0.3
    score += session_score

    # Consecutive easy sessions factor (up to 0.3)
    consecutive_easy = exercise_data.get("consecutive_easy_sessions", 0)
    if consecutive_easy >= 3:
        score += 0.3
    elif consecutive_easy == 2:
        score += 0.2
    elif consecutive_easy == 1:
        score += 0.1

    # Max reps factor (up to 0.2)
    max_reps = exercise_data.get("current_max_reps", 0)
    if max_reps >= 15:
        score += 0.2
    elif max_reps >= 12:
        score += 0.15
    elif max_reps >= 8:
        score += 0.1
    elif max_reps >= 5:
        score += 0.05

    # Average difficulty rating factor (up to 0.2)
    # Lower average difficulty = more mastery
    avg_difficulty = exercise_data.get("average_difficulty_rating")
    if avg_difficulty is not None:
        # Scale from 1 (hard) to 3 (easy)
        # 3 = too_easy, 2 = just_right, 1 = too_hard
        if avg_difficulty >= 2.5:
            score += 0.2
        elif avg_difficulty >= 2.0:
            score += 0.15
        elif avg_difficulty >= 1.5:
            score += 0.1

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
        mastery_result = db.client.table("exercise_mastery").select("*").eq(
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
        consecutive_easy = mastery.get("consecutive_easy_sessions", 0)
        total_sessions = mastery.get("total_sessions", 0)
        max_reps = mastery.get("current_max_reps", 0)

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
        logger.error(f"Error checking progression readiness: {e}")
        return {
            "ready": False,
            "reason": f"Error: {str(e)}",
            "confidence": 0.0,
            "suggested_next": None
        }


async def get_next_variant(exercise_name: str) -> Optional[dict]:
    """
    Find the next harder variant in the progression chain.

    Returns dict with variant info or None if no progression exists.
    """
    try:
        db = get_supabase_db()

        # Find the current variant in any chain
        current_result = db.client.table("progression_variants").select(
            "id, chain_id, variant_order"
        ).eq("name", exercise_name).execute()

        if not current_result.data:
            # Exercise not in a progression chain
            return None

        current = current_result.data[0]
        chain_id = current["chain_id"]
        current_order = current["variant_order"]

        # Get the next variant in the same chain
        next_result = db.client.table("progression_variants").select("*").eq(
            "chain_id", chain_id
        ).eq("variant_order", current_order + 1).execute()

        if not next_result.data:
            # Already at the top of the chain
            return None

        next_variant = next_result.data[0]

        # Get chain info
        chain_result = db.client.table("progression_chains").select(
            "name"
        ).eq("id", chain_id).execute()

        chain_name = chain_result.data[0]["name"] if chain_result.data else "Unknown Chain"

        return {
            "variant": _parse_variant(next_variant),
            "chain_id": chain_id,
            "chain_name": chain_name,
        }

    except Exception as e:
        logger.error(f"Error getting next variant for {exercise_name}: {e}")
        return None


# =============================================================================
# Progression Chains Endpoints
# =============================================================================

@router.get("/chains", response_model=List[ProgressionChainResponse])
async def get_progression_chains(
    muscle_group: Optional[MuscleGroup] = None,
    chain_type: Optional[ChainType] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all progression chains.

    Optionally filter by muscle group or chain type.
    """
    logger.info(f"Getting progression chains: muscle_group={muscle_group}, chain_type={chain_type}")

    try:
        db = get_supabase_db()
        query = db.client.table("progression_chains").select("*")

        if muscle_group:
            query = query.eq("muscle_group", muscle_group.value)

        if chain_type:
            query = query.eq("chain_type", chain_type.value)

        result = query.order("muscle_group").order("name").execute()

        chains = []
        for row in result.data or []:
            chain = _parse_chain(row)

            # Get variants for this chain
            variants_result = db.client.table("progression_variants").select("*").eq(
                "chain_id", row["id"]
            ).order("variant_order").execute()

            chain.variants = [_parse_variant(v) for v in variants_result.data or []]
            chain.total_variants = len(chain.variants)
            chains.append(chain)

        return chains

    except Exception as e:
        logger.error(f"Failed to get progression chains: {e}")
        raise safe_internal_error(e, "exercise_progressions")


@router.get("/chains/{chain_id}", response_model=ProgressionChainResponse)
async def get_progression_chain(chain_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get a specific progression chain with all its variants.
    """
    logger.info(f"Getting progression chain: {chain_id}")

    try:
        db = get_supabase_db()

        # Get the chain
        chain_result = db.client.table("progression_chains").select("*").eq(
            "id", chain_id
        ).execute()

        if not chain_result.data:
            raise HTTPException(status_code=404, detail="Progression chain not found")

        chain = _parse_chain(chain_result.data[0])

        # Get all variants
        variants_result = db.client.table("progression_variants").select("*").eq(
            "chain_id", chain_id
        ).order("variant_order").execute()

        chain.variants = [_parse_variant(v) for v in variants_result.data or []]
        chain.total_variants = len(chain.variants)

        return chain

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get progression chain: {e}")
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
    to progress and what the suggested next variant is.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting mastery for user {user_id}, ready_only={ready_only}")

    try:
        db = get_supabase_db()

        query = db.client.table("exercise_mastery").select("*").eq("user_id", user_id)

        if ready_only:
            query = query.eq("ready_for_progression", True)

        result = query.order("last_performed_at", desc=True).execute()

        mastery_list = []
        for row in result.data or []:
            mastery = _parse_mastery(row)

            # Get chain info if available
            chain_name = None
            next_variant = None

            if row.get("chain_id"):
                chain_result = db.client.table("progression_chains").select(
                    "name"
                ).eq("id", row["chain_id"]).execute()

                if chain_result.data:
                    chain_name = chain_result.data[0]["name"]

                # Get next variant if ready for progression
                if mastery.ready_for_progression and mastery.current_variant_order is not None:
                    next_result = db.client.table("progression_variants").select("*").eq(
                        "chain_id", row["chain_id"]
                    ).eq("variant_order", mastery.current_variant_order + 1).execute()

                    if next_result.data:
                        next_variant = _parse_variant(next_result.data[0])

            mastery_with_chain = ExerciseMasteryWithChain(
                **mastery.model_dump(),
                chain_name=chain_name,
                next_variant=next_variant,
            )
            mastery_list.append(mastery_with_chain)

        return mastery_list

    except Exception as e:
        logger.error(f"Failed to get user mastery: {e}")
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
        ready_result = db.client.table("exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("ready_for_progression", True).execute()

        suggestions = []
        for row in ready_result.data or []:
            # Get chain and variant info
            if not row.get("chain_id"):
                continue

            # Get current variant
            current_result = db.client.table("progression_variants").select("*").eq(
                "chain_id", row["chain_id"]
            ).eq("variant_order", row.get("current_variant_order", 0)).execute()

            if not current_result.data:
                continue

            current = current_result.data[0]

            # Get next variant
            next_result = db.client.table("progression_variants").select("*").eq(
                "chain_id", row["chain_id"]
            ).eq("variant_order", row.get("current_variant_order", 0) + 1).execute()

            if not next_result.data:
                continue  # Already at top of chain

            next_variant = next_result.data[0]

            # Get chain name
            chain_result = db.client.table("progression_chains").select(
                "name"
            ).eq("id", row["chain_id"]).execute()

            chain_name = chain_result.data[0]["name"] if chain_result.data else "Unknown"

            # Build suggestion
            consecutive_easy = row.get("consecutive_easy_sessions", 0)
            total_sessions = row.get("total_sessions", 0)
            max_reps = row.get("current_max_reps", 0)

            if consecutive_easy >= 2:
                reason = f"Rated 'too easy' {consecutive_easy} times in a row"
                confidence = 0.9
            else:
                reason = f"Consistently high performance ({max_reps} reps over {total_sessions} sessions)"
                confidence = 0.7

            suggestions.append(ProgressionSuggestion(
                exercise_name=row["exercise_name"],
                current_difficulty_score=current.get("difficulty_score", 5.0),
                suggested_exercise=next_variant["name"],
                suggested_difficulty_score=next_variant.get("difficulty_score", 6.0),
                chain_id=row["chain_id"],
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
        logger.error(f"Failed to get progression suggestions: {e}")
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
        existing_result = db.client.table("exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).execute()

        # Difficulty mapping for average calculation
        difficulty_map = {
            DifficultyFeedback.TOO_EASY: 3.0,
            DifficultyFeedback.JUST_RIGHT: 2.0,
            DifficultyFeedback.TOO_HARD: 1.0,
        }

        if existing_result.data:
            # Update existing record
            existing = existing_result.data[0]

            # Calculate new values
            total_sessions = existing.get("total_sessions", 0) + 1
            current_max_reps = max(existing.get("current_max_reps", 0), request.reps_performed)

            # Update max weight
            current_max_weight = existing.get("current_max_weight")
            if request.weight_used:
                if current_max_weight is None:
                    current_max_weight = request.weight_used
                else:
                    current_max_weight = max(current_max_weight, request.weight_used)

            # Update consecutive easy/hard sessions
            if request.difficulty_felt == DifficultyFeedback.TOO_EASY:
                consecutive_easy = existing.get("consecutive_easy_sessions", 0) + 1
                consecutive_hard = 0
            elif request.difficulty_felt == DifficultyFeedback.TOO_HARD:
                consecutive_easy = 0
                consecutive_hard = existing.get("consecutive_hard_sessions", 0) + 1
            else:
                consecutive_easy = 0
                consecutive_hard = 0

            # Update average difficulty rating
            prev_avg = existing.get("average_difficulty_rating")
            prev_total = existing.get("total_sessions", 0)
            new_rating = difficulty_map[request.difficulty_felt]

            if prev_avg is not None and prev_total > 0:
                avg_difficulty = ((prev_avg * prev_total) + new_rating) / total_sessions
            else:
                avg_difficulty = new_rating

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
                    suggested_next = next_info["variant"].name

            # Update record
            update_data = {
                "total_sessions": total_sessions,
                "consecutive_easy_sessions": consecutive_easy,
                "consecutive_hard_sessions": consecutive_hard,
                "current_max_reps": current_max_reps,
                "current_max_weight": current_max_weight,
                "average_difficulty_rating": avg_difficulty,
                "ready_for_progression": ready_for_progression,
                "suggested_next_variant": suggested_next,
                "status": status.value,
                "last_performed_at": now,
                "updated_at": now,
            }

            if ready_for_progression and not existing.get("mastered_at"):
                update_data["mastered_at"] = now

            result = db.client.table("exercise_mastery").update(update_data).eq(
                "id", existing["id"]
            ).execute()

            mastery = _parse_mastery(result.data[0])

        else:
            # Create new mastery record
            # First, check if exercise is in a progression chain
            chain_id = None
            variant_order = None

            variant_result = db.client.table("progression_variants").select(
                "chain_id, variant_order"
            ).eq("name", request.exercise_name).execute()

            if variant_result.data:
                chain_id = variant_result.data[0]["chain_id"]
                variant_order = variant_result.data[0]["variant_order"]

            # Determine initial values
            consecutive_easy = 1 if request.difficulty_felt == DifficultyFeedback.TOO_EASY else 0
            consecutive_hard = 1 if request.difficulty_felt == DifficultyFeedback.TOO_HARD else 0

            insert_data = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "exercise_name": request.exercise_name,
                "chain_id": chain_id,
                "current_variant_order": variant_order,
                "status": MasteryStatus.LEARNING.value,
                "total_sessions": 1,
                "consecutive_easy_sessions": consecutive_easy,
                "consecutive_hard_sessions": consecutive_hard,
                "current_max_reps": request.reps_performed,
                "current_max_weight": request.weight_used,
                "average_difficulty_rating": difficulty_map[request.difficulty_felt],
                "ready_for_progression": False,
                "last_performed_at": now,
                "created_at": now,
                "updated_at": now,
            }

            result = db.client.table("exercise_mastery").insert(insert_data).execute()
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
        logger.error(f"Failed to update exercise mastery: {e}")
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
    2. Creates a new mastery record for the new exercise
    3. Logs the activity for user context service
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"User {user_id} accepting progression: {request.current_exercise} -> {request.new_exercise}")

    try:
        db = get_supabase_db()
        now = datetime.utcnow().isoformat()

        # Get current mastery record
        current_result = db.client.table("exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", request.current_exercise).execute()

        if not current_result.data:
            raise HTTPException(
                status_code=404,
                detail=f"No mastery record found for {request.current_exercise}"
            )

        current = current_result.data[0]

        # Verify new exercise exists in the progression chain
        new_variant_result = db.client.table("progression_variants").select(
            "chain_id, variant_order"
        ).eq("name", request.new_exercise).execute()

        if not new_variant_result.data:
            raise HTTPException(
                status_code=400,
                detail=f"{request.new_exercise} is not in a progression chain"
            )

        new_variant = new_variant_result.data[0]

        # Update old exercise to "progressed"
        db.client.table("exercise_mastery").update({
            "status": MasteryStatus.PROGRESSED.value,
            "ready_for_progression": False,
            "updated_at": now,
        }).eq("id", current["id"]).execute()

        # Check if new exercise already has a mastery record
        existing_new = db.client.table("exercise_mastery").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.new_exercise).execute()

        if existing_new.data:
            # Reset existing record for the new exercise
            db.client.table("exercise_mastery").update({
                "status": MasteryStatus.LEARNING.value,
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
                "chain_id": new_variant["chain_id"],
                "current_variant_order": new_variant["variant_order"],
                "status": MasteryStatus.LEARNING.value,
                "total_sessions": 0,
                "consecutive_easy_sessions": 0,
                "consecutive_hard_sessions": 0,
                "current_max_reps": 0,
                "ready_for_progression": False,
                "created_at": now,
                "updated_at": now,
            }

            db.client.table("exercise_mastery").insert(insert_data).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="exercise_progression_accepted",
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/accept-progression",
            message=f"Progressed from {request.current_exercise} to {request.new_exercise}",
            metadata={
                "old_exercise": request.current_exercise,
                "new_exercise": request.new_exercise,
                "chain_id": new_variant["chain_id"],
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
        logger.error(f"Failed to accept progression: {e}")
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

@router.get("/user/{user_id}/rep-preferences", response_model=RepPreferencesResponse)
async def get_rep_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's rep range preferences and training focus.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting rep preferences for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("user_rep_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        if result.data:
            prefs = result.data[0]
            training_focus = TrainingFocus(prefs.get("training_focus", "hypertrophy"))
            min_reps = prefs.get("preferred_min_reps", 6)
            max_reps = prefs.get("preferred_max_reps", 12)
            avoid_high = prefs.get("avoid_high_reps", False)
            progression_style = ProgressionStyle(prefs.get("progression_style", "moderate"))
        else:
            # Return defaults
            training_focus = TrainingFocus.HYPERTROPHY
            min_reps = 6
            max_reps = 12
            avoid_high = False
            progression_style = ProgressionStyle.MODERATE

        # Generate description
        if training_focus == TrainingFocus.STRENGTH:
            description = "Strength focus: Lower reps (1-5) with heavier weights"
        elif training_focus == TrainingFocus.HYPERTROPHY:
            description = "Hypertrophy focus: Moderate reps (6-12) for muscle growth"
        elif training_focus == TrainingFocus.ENDURANCE:
            description = "Endurance focus: Higher reps (12-20+) for muscular endurance"
        else:
            description = "Mixed training: Varied rep ranges across workouts"

        if avoid_high:
            description += ". Avoiding high rep sets."

        return RepPreferencesResponse(
            training_focus=training_focus,
            preferred_min_reps=min_reps,
            preferred_max_reps=max_reps,
            avoid_high_reps=avoid_high,
            progression_style=progression_style,
            description=description,
        )

    except Exception as e:
        logger.error(f"Failed to get rep preferences: {e}")
        raise safe_internal_error(e, "exercise_progressions")


@router.put("/user/{user_id}/rep-preferences", response_model=RepPreferencesResponse)
async def update_rep_preferences(user_id: str, request: RepPreferences, current_user: dict = Depends(get_current_user)):
    """
    Update user's rep range preferences.

    This affects how the AI generates workouts:
    - training_focus: Determines overall rep range strategy
    - preferred_min_reps/max_reps: Custom rep range override
    - avoid_high_reps: Never prescribe sets above 15 reps
    - progression_style: How aggressively to suggest harder variants
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating rep preferences for user {user_id}: {request.training_focus}")

    try:
        db = get_supabase_db()
        now = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("user_rep_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        prefs_data = {
            "training_focus": request.training_focus.value,
            "preferred_min_reps": request.preferred_min_reps,
            "preferred_max_reps": request.preferred_max_reps,
            "avoid_high_reps": request.avoid_high_reps,
            "progression_style": request.progression_style.value,
            "updated_at": now,
        }

        if existing.data:
            # Update existing
            db.client.table("user_rep_preferences").update(prefs_data).eq(
                "id", existing.data[0]["id"]
            ).execute()
        else:
            # Insert new
            prefs_data["id"] = str(uuid.uuid4())
            prefs_data["user_id"] = user_id
            prefs_data["created_at"] = now
            db.client.table("user_rep_preferences").insert(prefs_data).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="rep_preferences_updated",
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/rep-preferences",
            message=f"Updated rep preferences: {request.training_focus.value}",
            metadata={
                "training_focus": request.training_focus.value,
                "min_reps": request.preferred_min_reps,
                "max_reps": request.preferred_max_reps,
                "avoid_high_reps": request.avoid_high_reps,
                "progression_style": request.progression_style.value,
            },
            status_code=200
        )

        # Generate description
        if request.training_focus == TrainingFocus.STRENGTH:
            description = "Strength focus: Lower reps (1-5) with heavier weights"
        elif request.training_focus == TrainingFocus.HYPERTROPHY:
            description = "Hypertrophy focus: Moderate reps (6-12) for muscle growth"
        elif request.training_focus == TrainingFocus.ENDURANCE:
            description = "Endurance focus: Higher reps (12-20+) for muscular endurance"
        else:
            description = "Mixed training: Varied rep ranges across workouts"

        if request.avoid_high_reps:
            description += ". Avoiding high rep sets."

        return RepPreferencesResponse(
            training_focus=request.training_focus,
            preferred_min_reps=request.preferred_min_reps,
            preferred_max_reps=request.preferred_max_reps,
            avoid_high_reps=request.avoid_high_reps,
            progression_style=request.progression_style,
            description=description,
        )

    except Exception as e:
        logger.error(f"Failed to update rep preferences: {e}")
        raise safe_internal_error(e, "exercise_progressions")


# =============================================================================
# Utility Endpoints
# =============================================================================

@router.get("/user/{user_id}/check-readiness/{exercise_name}")
async def check_readiness_endpoint(user_id: str, exercise_name: str, current_user: dict = Depends(get_current_user)):
    """
    Check if user is ready to progress on a specific exercise.

    Returns readiness status with reason and suggested next variant.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Checking readiness for user {user_id}, exercise: {exercise_name}")

    result = await check_progression_readiness(user_id, exercise_name)
    return result


@router.get("/next-variant/{exercise_name}")
async def get_next_variant_endpoint(exercise_name: str, current_user: dict = Depends(get_current_user)):
    """
    Get the next harder variant for an exercise.

    Returns variant info or null if not in a progression chain.
    """
    logger.info(f"Getting next variant for: {exercise_name}")

    result = await get_next_variant(exercise_name)

    if result is None:
        return {
            "found": False,
            "message": f"{exercise_name} is not in a progression chain or is already the hardest variant",
        }

    return {
        "found": True,
        "current_exercise": exercise_name,
        "next_variant": result["variant"],
        "chain_id": result["chain_id"],
        "chain_name": result["chain_name"],
    }


@router.get("/chain-types")
async def get_chain_types(current_user: dict = Depends(get_current_user)):
    """Get all available progression chain types with descriptions."""
    return {
        "chain_types": [
            {
                "type": ChainType.LEVERAGE.value,
                "name": "Leverage",
                "description": "Progressions based on body position (e.g., incline to flat to decline)",
            },
            {
                "type": ChainType.LOAD.value,
                "name": "Load",
                "description": "Progressions based on weight or resistance (e.g., bodyweight to weighted)",
            },
            {
                "type": ChainType.STABILITY.value,
                "name": "Stability",
                "description": "Progressions based on stability challenges (e.g., bilateral to unilateral)",
            },
            {
                "type": ChainType.RANGE.value,
                "name": "Range of Motion",
                "description": "Progressions based on movement range (e.g., partial to full ROM)",
            },
            {
                "type": ChainType.TEMPO.value,
                "name": "Tempo",
                "description": "Progressions based on speed/time under tension",
            },
        ]
    }


@router.get("/muscle-groups")
async def get_muscle_groups(current_user: dict = Depends(get_current_user)):
    """Get all available muscle groups for filtering chains."""
    return {
        "muscle_groups": [mg.value for mg in MuscleGroup],
        "grouped": {
            "upper_body": [
                MuscleGroup.CHEST.value,
                MuscleGroup.BACK.value,
                MuscleGroup.SHOULDERS.value,
                MuscleGroup.BICEPS.value,
                MuscleGroup.TRICEPS.value,
            ],
            "lower_body": [
                MuscleGroup.QUADRICEPS.value,
                MuscleGroup.HAMSTRINGS.value,
                MuscleGroup.GLUTES.value,
                MuscleGroup.CALVES.value,
            ],
            "core": [MuscleGroup.CORE.value],
            "full_body": [MuscleGroup.FULL_BODY.value],
        }
    }


# =============================================================================
# Helper Functions for External Use
# =============================================================================

async def get_user_mastery_for_exercise(user_id: str, exercise_name: str) -> Optional[ExerciseMastery]:
    """
    Get mastery data for a specific exercise.
    Used by workout generation to consider mastery when selecting exercises.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", exercise_name).execute()

        if result.data:
            return _parse_mastery(result.data[0])
        return None
    except Exception as e:
        logger.error(f"Error getting mastery for {exercise_name}: {e}")
        return None


async def get_user_ready_progressions(user_id: str) -> List[str]:
    """
    Get list of exercise names the user is ready to progress on.
    Used by workout generation to suggest progressions.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_mastery").select(
            "exercise_name, suggested_next_variant"
        ).eq("user_id", user_id).eq("ready_for_progression", True).execute()

        return [
            row["suggested_next_variant"]
            for row in result.data or []
            if row.get("suggested_next_variant")
        ]
    except Exception as e:
        logger.error(f"Error getting ready progressions for user {user_id}: {e}")
        return []


async def should_suggest_progression(user_id: str, exercise_name: str) -> bool:
    """
    Quick check if we should suggest a harder variant for this exercise.
    Used by workout generation to decide whether to auto-swap.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_mastery").select(
            "ready_for_progression"
        ).eq("user_id", user_id).eq("exercise_name", exercise_name).execute()

        if result.data:
            return result.data[0].get("ready_for_progression", False)
        return False
    except Exception as e:
        logger.error(f"Error checking progression suggestion: {e}")
        return False


async def get_user_rep_range(user_id: str) -> tuple[int, int]:
    """
    Get user's preferred rep range.
    Used by workout generation to set appropriate rep counts.
    Returns (min_reps, max_reps) tuple.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("user_rep_preferences").select(
            "preferred_min_reps, preferred_max_reps"
        ).eq("user_id", user_id).execute()

        if result.data:
            return (
                result.data[0].get("preferred_min_reps", 6),
                result.data[0].get("preferred_max_reps", 12)
            )
        return (6, 12)  # Default hypertrophy range
    except Exception as e:
        logger.error(f"Error getting user rep range: {e}")
        return (6, 12)
