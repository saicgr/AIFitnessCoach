"""
Feedback Analysis Service - Analyzes exercise feedback to adjust future workout difficulty.

This service strengthens the feedback loop by:
1. Analyzing recent exercise difficulty feedback (too_easy, just_right, too_hard)
2. Calculating a difficulty adjustment score (-2 to +2)
3. Using this adjustment to shift the difficulty ceiling for exercise selection

The adjustment score works as follows:
- If mostly "too_easy" -> suggest harder exercises (+1 or +2)
- If mostly "too_hard" -> suggest easier exercises (-1 or -2)
- If mostly "just_right" -> no change (0)
"""
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
import logging

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


@dataclass
class FeedbackAnalysis:
    """Result of analyzing user feedback."""
    difficulty_adjustment: int  # -2 to +2
    too_easy_count: int
    just_right_count: int
    too_hard_count: int
    total_feedback_count: int
    confidence: float  # 0-1, based on amount of data
    recommendation: str  # Human-readable explanation

    def to_dict(self) -> Dict[str, Any]:
        return {
            "difficulty_adjustment": self.difficulty_adjustment,
            "too_easy_count": self.too_easy_count,
            "just_right_count": self.just_right_count,
            "too_hard_count": self.too_hard_count,
            "total_feedback_count": self.total_feedback_count,
            "confidence": round(self.confidence, 2),
            "recommendation": self.recommendation,
        }


# Minimum feedback entries required for confident adjustment
MIN_FEEDBACK_FOR_ADJUSTMENT = 3

# Threshold percentages for determining adjustment
STRONG_THRESHOLD = 0.7  # 70% or more of feedback in one direction
MODERATE_THRESHOLD = 0.5  # 50% or more of feedback in one direction


class FeedbackAnalysisService:
    """
    Service for analyzing exercise difficulty feedback and calculating adjustments.

    This service queries the exercise_feedback and workout_feedback tables to
    understand how users feel about their workout difficulty and uses this to
    adjust future workout generation.
    """

    def __init__(self):
        pass

    async def analyze_user_feedback(
        self,
        user_id: str,
        days: int = 14,
        exercise_name: Optional[str] = None,
    ) -> FeedbackAnalysis:
        """
        Analyze a user's recent exercise feedback to calculate difficulty adjustment.

        Args:
            user_id: The user's ID
            days: Number of days of feedback to analyze (default 14)
            exercise_name: Optional - analyze feedback for a specific exercise only

        Returns:
            FeedbackAnalysis with difficulty adjustment score and breakdown
        """
        try:
            db = get_supabase_db()
            cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

            # Query exercise feedback from database
            query = db.client.table("exercise_feedback").select(
                "exercise_name, difficulty_felt, rating, would_do_again, created_at"
            ).eq("user_id", user_id).gte("created_at", cutoff_date)

            if exercise_name:
                query = query.ilike("exercise_name", f"%{exercise_name}%")

            result = query.execute()

            exercise_feedback = result.data or []

            # Also get workout-level difficulty feedback
            workout_query = db.client.table("workout_feedback").select(
                "overall_difficulty, overall_rating, energy_level, created_at"
            ).eq("user_id", user_id).gte("created_at", cutoff_date)

            workout_result = workout_query.execute()
            workout_feedback = workout_result.data or []

            # Analyze the feedback
            return self._calculate_adjustment(exercise_feedback, workout_feedback, user_id)

        except Exception as e:
            logger.error(f"Failed to analyze user feedback: {e}")
            # Return neutral adjustment on error
            return FeedbackAnalysis(
                difficulty_adjustment=0,
                too_easy_count=0,
                just_right_count=0,
                too_hard_count=0,
                total_feedback_count=0,
                confidence=0.0,
                recommendation="Unable to analyze feedback due to error",
            )

    def _calculate_adjustment(
        self,
        exercise_feedback: List[Dict],
        workout_feedback: List[Dict],
        user_id: str = "unknown",
    ) -> FeedbackAnalysis:
        """
        Calculate the difficulty adjustment based on collected feedback.

        Weighting:
        - Exercise-level difficulty_felt: Primary signal (weight 2)
        - Workout-level overall_difficulty: Secondary signal (weight 1)

        Args:
            exercise_feedback: List of exercise feedback entries
            workout_feedback: List of workout feedback entries

        Returns:
            FeedbackAnalysis with calculated adjustment
        """
        # Count difficulty categories
        too_easy_count = 0
        just_right_count = 0
        too_hard_count = 0

        # Analyze exercise-level feedback (weight 2x)
        for feedback in exercise_feedback:
            difficulty = (feedback.get("difficulty_felt") or "").lower()
            if difficulty == "too_easy":
                too_easy_count += 2  # Weight 2
            elif difficulty == "just_right":
                just_right_count += 2  # Weight 2
            elif difficulty == "too_hard":
                too_hard_count += 2  # Weight 2

        # Analyze workout-level feedback (weight 1x)
        for feedback in workout_feedback:
            difficulty = (feedback.get("overall_difficulty") or "").lower()
            if difficulty == "too_easy":
                too_easy_count += 1  # Weight 1
            elif difficulty == "just_right":
                just_right_count += 1  # Weight 1
            elif difficulty == "too_hard":
                too_hard_count += 1  # Weight 1

        # Calculate totals
        total_weighted = too_easy_count + just_right_count + too_hard_count
        total_feedback_count = len(exercise_feedback) + len(workout_feedback)

        # If no feedback, return neutral
        if total_weighted == 0:
            return FeedbackAnalysis(
                difficulty_adjustment=0,
                too_easy_count=0,
                just_right_count=0,
                too_hard_count=0,
                total_feedback_count=0,
                confidence=0.0,
                recommendation="No difficulty feedback available yet - using default difficulty",
            )

        # Calculate percentages
        too_easy_pct = too_easy_count / total_weighted
        just_right_pct = just_right_count / total_weighted
        too_hard_pct = too_hard_count / total_weighted

        # Calculate confidence based on amount of data
        # Confidence increases with more feedback, maxing out at ~10 entries
        confidence = min(1.0, total_feedback_count / 10)

        # Low confidence = reduce the adjustment magnitude
        if total_feedback_count < MIN_FEEDBACK_FOR_ADJUSTMENT:
            confidence *= 0.5  # Reduce confidence for very few samples

        # Calculate adjustment score (-2 to +2)
        adjustment = 0
        recommendation = ""

        if too_easy_pct >= STRONG_THRESHOLD:
            # Strong signal: workout is too easy
            adjustment = 2
            recommendation = (
                f"Strong signal ({int(too_easy_pct * 100)}% of feedback says 'too easy') - "
                f"significantly increasing exercise difficulty"
            )
        elif too_easy_pct >= MODERATE_THRESHOLD:
            # Moderate signal: workout is somewhat easy
            adjustment = 1
            recommendation = (
                f"Moderate signal ({int(too_easy_pct * 100)}% of feedback says 'too easy') - "
                f"slightly increasing exercise difficulty"
            )
        elif too_hard_pct >= STRONG_THRESHOLD:
            # Strong signal: workout is too hard
            adjustment = -2
            recommendation = (
                f"Strong signal ({int(too_hard_pct * 100)}% of feedback says 'too hard') - "
                f"significantly reducing exercise difficulty"
            )
        elif too_hard_pct >= MODERATE_THRESHOLD:
            # Moderate signal: workout is somewhat hard
            adjustment = -1
            recommendation = (
                f"Moderate signal ({int(too_hard_pct * 100)}% of feedback says 'too hard') - "
                f"slightly reducing exercise difficulty"
            )
        else:
            # Balanced or mostly "just right"
            adjustment = 0
            if just_right_pct >= MODERATE_THRESHOLD:
                recommendation = (
                    f"Good balance ({int(just_right_pct * 100)}% says 'just right') - "
                    f"maintaining current difficulty level"
                )
            else:
                recommendation = (
                    f"Mixed feedback (easy: {int(too_easy_pct * 100)}%, right: {int(just_right_pct * 100)}%, "
                    f"hard: {int(too_hard_pct * 100)}%) - maintaining current difficulty"
                )

        # Apply confidence to adjustment (if low confidence, we're more conservative)
        if confidence < 0.5 and abs(adjustment) == 2:
            adjustment = adjustment // 2  # Reduce strong adjustments if low confidence
            recommendation += f" (reduced due to low confidence: {int(confidence * 100)}%)"

        logger.info(
            f"[Feedback Analysis] User {user_id}: adjustment={adjustment}, "
            f"easy={too_easy_count}, right={just_right_count}, hard={too_hard_count}, "
            f"confidence={confidence:.2f}"
        )

        return FeedbackAnalysis(
            difficulty_adjustment=adjustment,
            too_easy_count=too_easy_count // 2 + len([f for f in workout_feedback if f.get("overall_difficulty", "").lower() == "too_easy"]),  # Convert back to actual counts
            just_right_count=just_right_count // 2 + len([f for f in workout_feedback if f.get("overall_difficulty", "").lower() == "just_right"]),
            too_hard_count=too_hard_count // 2 + len([f for f in workout_feedback if f.get("overall_difficulty", "").lower() == "too_hard"]),
            total_feedback_count=total_feedback_count,
            confidence=confidence,
            recommendation=recommendation,
        )

    async def get_exercise_specific_adjustment(
        self,
        user_id: str,
        exercise_name: str,
        days: int = 30,
    ) -> int:
        """
        Get difficulty adjustment for a specific exercise.

        This allows fine-grained adjustment per exercise rather than
        a blanket adjustment for all exercises.

        Args:
            user_id: The user's ID
            exercise_name: Name of the exercise
            days: Number of days of feedback to analyze

        Returns:
            Difficulty adjustment (-2 to +2) for this specific exercise
        """
        analysis = await self.analyze_user_feedback(
            user_id=user_id,
            days=days,
            exercise_name=exercise_name,
        )

        # For exercise-specific analysis, require at least 2 data points
        if analysis.total_feedback_count < 2:
            return 0

        return analysis.difficulty_adjustment

    async def get_feedback_summary(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get a comprehensive feedback summary for a user.

        This is useful for displaying to users and for debugging.

        Args:
            user_id: The user's ID
            days: Number of days of feedback to analyze

        Returns:
            Dict with detailed feedback analysis
        """
        analysis = await self.analyze_user_feedback(user_id, days)

        return {
            "user_id": user_id,
            "analysis_period_days": days,
            "analysis": analysis.to_dict(),
            "analyzed_at": datetime.now().isoformat(),
        }


# Singleton instance
_feedback_analysis_service: Optional[FeedbackAnalysisService] = None


def get_feedback_analysis_service() -> FeedbackAnalysisService:
    """Get or create the singleton FeedbackAnalysisService instance."""
    global _feedback_analysis_service
    if _feedback_analysis_service is None:
        _feedback_analysis_service = FeedbackAnalysisService()
    return _feedback_analysis_service


async def get_user_difficulty_adjustment(
    user_id: str,
    days: int = 14,
    log_adjustment: bool = False,
    workout_type: Optional[str] = None,
) -> Tuple[int, str]:
    """
    Convenience function to get the difficulty adjustment for a user.

    This is the primary function called by workout generation to get
    the feedback-based difficulty adjustment.

    Args:
        user_id: The user's ID
        days: Number of days of feedback to analyze
        log_adjustment: Whether to log this adjustment to user context
        workout_type: Type of workout being generated (for logging)

    Returns:
        Tuple of (adjustment_score, recommendation_message)
    """
    service = get_feedback_analysis_service()
    analysis = await service.analyze_user_feedback(user_id, days)

    # Optionally log the adjustment for tracking effectiveness
    if log_adjustment and analysis.difficulty_adjustment != 0:
        try:
            from services.user_context_service import user_context_service
            await user_context_service.log_difficulty_adjustment(
                user_id=user_id,
                adjustment=analysis.difficulty_adjustment,
                recommendation=analysis.recommendation,
                feedback_counts={
                    "too_easy_count": analysis.too_easy_count,
                    "just_right_count": analysis.just_right_count,
                    "too_hard_count": analysis.too_hard_count,
                    "total_feedback_count": analysis.total_feedback_count,
                },
                confidence=analysis.confidence,
                workout_type=workout_type,
            )
        except Exception as e:
            logger.warning(f"Failed to log difficulty adjustment: {e}")

    return analysis.difficulty_adjustment, analysis.recommendation


# ============================================
# Progression Mastery Integration
# ============================================

@dataclass
class ProgressionSuggestion:
    """Suggestion for exercise progression based on user feedback."""
    exercise_name: str
    consecutive_easy_sessions: int
    suggested_next_variant: Optional[str]
    chain_id: Optional[str]
    difficulty_increase: Optional[float]
    last_suggested_at: Optional[datetime]
    can_suggest: bool  # False if recently suggested/declined


@dataclass
class ExerciseMasteryUpdate:
    """Result of updating exercise mastery based on feedback."""
    exercise_name: str
    consecutive_easy_sessions: int
    consecutive_hard_sessions: int
    ready_for_progression: bool
    suggested_next_variant: Optional[str]
    was_updated: bool


# Minimum consecutive easy sessions before suggesting progression
MIN_EASY_SESSIONS_FOR_PROGRESSION = 2

# Days to wait before suggesting progression again after decline
PROGRESSION_COOLDOWN_DAYS = 7


async def update_exercise_mastery(
    user_id: str,
    exercise_name: str,
    difficulty_felt: str,
) -> ExerciseMasteryUpdate:
    """
    Update user's exercise mastery based on feedback difficulty.

    This is called after each exercise feedback submission to track
    consecutive "too easy" or "too hard" ratings.

    Args:
        user_id: The user's ID
        exercise_name: Name of the exercise
        difficulty_felt: The difficulty feedback ("too_easy", "just_right", "too_hard")

    Returns:
        ExerciseMasteryUpdate with updated mastery status
    """
    try:
        db = get_supabase_db()
        now = datetime.now()

        # Get or create mastery record
        existing = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).ilike("exercise_name", exercise_name).execute()

        if existing.data:
            mastery = existing.data[0]
            consecutive_easy = mastery.get("consecutive_easy_sessions", 0)
            consecutive_hard = mastery.get("consecutive_hard_sessions", 0)
            total_sessions = mastery.get("total_sessions", 0) + 1

            # Update consecutive counts based on feedback
            if difficulty_felt == "too_easy":
                consecutive_easy += 1
                consecutive_hard = 0  # Reset hard counter
            elif difficulty_felt == "too_hard":
                consecutive_hard += 1
                consecutive_easy = 0  # Reset easy counter
            else:  # just_right
                consecutive_easy = 0
                consecutive_hard = 0

            # Check if ready for progression
            ready_for_progression = consecutive_easy >= MIN_EASY_SESSIONS_FOR_PROGRESSION
            suggested_next_variant = None
            chain_id = None

            if ready_for_progression:
                # Find next variant in progression chain
                next_variant = await _find_next_exercise_variant(exercise_name)
                if next_variant:
                    suggested_next_variant = next_variant.get("next_exercise")
                    chain_id = next_variant.get("chain_id")

            # Update mastery record
            update_data = {
                "consecutive_easy_sessions": consecutive_easy,
                "consecutive_hard_sessions": consecutive_hard,
                "total_sessions": total_sessions,
                "ready_for_progression": ready_for_progression,
                "suggested_next_variant": suggested_next_variant,
                "progression_chain_id": chain_id,
                "last_performed_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }

            db.client.table("user_exercise_mastery").update(
                update_data
            ).eq("id", mastery["id"]).execute()

            logger.info(
                f"[Mastery] Updated {exercise_name} for user {user_id}: "
                f"easy={consecutive_easy}, hard={consecutive_hard}, "
                f"ready={ready_for_progression}"
            )

            return ExerciseMasteryUpdate(
                exercise_name=exercise_name,
                consecutive_easy_sessions=consecutive_easy,
                consecutive_hard_sessions=consecutive_hard,
                ready_for_progression=ready_for_progression,
                suggested_next_variant=suggested_next_variant,
                was_updated=True,
            )
        else:
            # Create new mastery record
            consecutive_easy = 1 if difficulty_felt == "too_easy" else 0
            consecutive_hard = 1 if difficulty_felt == "too_hard" else 0

            insert_data = {
                "user_id": user_id,
                "exercise_name": exercise_name,
                "consecutive_easy_sessions": consecutive_easy,
                "consecutive_hard_sessions": consecutive_hard,
                "total_sessions": 1,
                "ready_for_progression": False,
                "first_performed_at": now.isoformat(),
                "last_performed_at": now.isoformat(),
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }

            db.client.table("user_exercise_mastery").insert(insert_data).execute()

            logger.info(
                f"[Mastery] Created mastery record for {exercise_name}, user {user_id}"
            )

            return ExerciseMasteryUpdate(
                exercise_name=exercise_name,
                consecutive_easy_sessions=consecutive_easy,
                consecutive_hard_sessions=consecutive_hard,
                ready_for_progression=False,
                suggested_next_variant=None,
                was_updated=True,
            )

    except Exception as e:
        logger.error(f"Failed to update exercise mastery: {e}")
        return ExerciseMasteryUpdate(
            exercise_name=exercise_name,
            consecutive_easy_sessions=0,
            consecutive_hard_sessions=0,
            ready_for_progression=False,
            suggested_next_variant=None,
            was_updated=False,
        )


async def get_exercises_ready_for_progression(
    user_id: str,
) -> List[ProgressionSuggestion]:
    """
    Get all exercises where user is ready for progression.

    Returns exercises with 2+ consecutive "too easy" ratings that have
    a valid next variant in their progression chain.

    This is called after workout completion to show progression suggestions.

    Args:
        user_id: The user's ID

    Returns:
        List of ProgressionSuggestion objects for exercises ready to progress
    """
    try:
        db = get_supabase_db()
        now = datetime.now()
        cooldown_cutoff = (now - timedelta(days=PROGRESSION_COOLDOWN_DAYS)).isoformat()

        # Get all exercises marked ready for progression
        result = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("ready_for_progression", True).execute()

        suggestions = []
        for mastery in result.data or []:
            exercise_name = mastery.get("exercise_name", "")
            consecutive_easy = mastery.get("consecutive_easy_sessions", 0)
            suggested_variant = mastery.get("suggested_next_variant")
            chain_id = mastery.get("progression_chain_id")
            last_suggested = mastery.get("last_progression_suggested_at")
            declined_at = mastery.get("progression_declined_at")

            # Check cooldown - don't suggest if recently declined
            can_suggest = True
            if declined_at:
                if declined_at > cooldown_cutoff:
                    can_suggest = False

            # Also check if we suggested recently
            if last_suggested:
                if last_suggested > cooldown_cutoff:
                    # Already suggested recently, check if it was accepted
                    accepted_count = mastery.get("progression_accepted_count", 0)
                    declined_count = mastery.get("progression_declined_count", 0)
                    # If more declined than accepted, apply cooldown
                    if declined_count > accepted_count:
                        can_suggest = False

            # Get difficulty increase if we have chain info
            difficulty_increase = None
            if chain_id and suggested_variant:
                next_info = await _find_next_exercise_variant(exercise_name)
                if next_info:
                    difficulty_increase = next_info.get("difficulty_increase")

            suggestions.append(ProgressionSuggestion(
                exercise_name=exercise_name,
                consecutive_easy_sessions=consecutive_easy,
                suggested_next_variant=suggested_variant,
                chain_id=chain_id,
                difficulty_increase=difficulty_increase,
                last_suggested_at=datetime.fromisoformat(last_suggested) if last_suggested else None,
                can_suggest=can_suggest,
            ))

        # Filter to only those we can suggest (respect cooldown)
        suggestionable = [s for s in suggestions if s.can_suggest and s.suggested_next_variant]

        logger.info(
            f"[Progression] Found {len(suggestions)} ready exercises for user {user_id}, "
            f"{len(suggestionable)} can be suggested"
        )

        return suggestionable

    except Exception as e:
        logger.error(f"Failed to get exercises ready for progression: {e}")
        return []


async def _find_next_exercise_variant(
    exercise_name: str,
) -> Optional[Dict[str, Any]]:
    """
    Find the next variant in an exercise's progression chain.

    Args:
        exercise_name: Current exercise name

    Returns:
        Dict with chain_id, next_exercise, difficulty_increase or None
    """
    try:
        db = get_supabase_db()

        # Try to find in variant chains
        # First, find which chain this exercise belongs to
        step_result = db.client.table("exercise_variant_steps").select(
            "chain_id, variant_order, difficulty_modifier"
        ).ilike("exercise_name", exercise_name).execute()

        if not step_result.data:
            # Try matching base exercise name
            chain_result = db.client.table("exercise_variant_chains").select(
                "id"
            ).ilike("base_exercise_name", f"%{exercise_name}%").execute()

            if chain_result.data:
                # Get first step in chain
                chain_id = chain_result.data[0]["id"]
                first_step = db.client.table("exercise_variant_steps").select(
                    "exercise_name, variant_order, difficulty_modifier"
                ).eq("chain_id", chain_id).order("variant_order").limit(1).execute()

                if first_step.data:
                    # Get second step (next variant)
                    next_step = db.client.table("exercise_variant_steps").select(
                        "exercise_name, variant_order, difficulty_modifier"
                    ).eq("chain_id", chain_id).eq(
                        "variant_order", first_step.data[0]["variant_order"] + 1
                    ).execute()

                    if next_step.data:
                        return {
                            "chain_id": chain_id,
                            "current_exercise": first_step.data[0]["exercise_name"],
                            "next_exercise": next_step.data[0]["exercise_name"],
                            "difficulty_increase": float(next_step.data[0]["difficulty_modifier"]) - float(first_step.data[0]["difficulty_modifier"]),
                        }
            return None

        # Found the step, now get the next one
        current_step = step_result.data[0]
        chain_id = current_step["chain_id"]
        current_order = current_step["variant_order"]
        current_difficulty = float(current_step["difficulty_modifier"])

        next_step = db.client.table("exercise_variant_steps").select(
            "exercise_name, variant_order, difficulty_modifier"
        ).eq("chain_id", chain_id).eq(
            "variant_order", current_order + 1
        ).execute()

        if next_step.data:
            return {
                "chain_id": str(chain_id),
                "current_exercise": exercise_name,
                "next_exercise": next_step.data[0]["exercise_name"],
                "difficulty_increase": float(next_step.data[0]["difficulty_modifier"]) - current_difficulty,
            }

        return None  # At top of chain

    except Exception as e:
        logger.error(f"Failed to find next exercise variant: {e}")
        return None


async def record_challenge_exercise_completion(
    user_id: str,
    exercise_name: str,
    difficulty_felt: str,
    completed: bool,
    workout_id: Optional[str] = None,
    performance_data: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Record completion (or skip) of a challenge exercise.

    This tracks challenge exercise performance separately to determine:
    1. If user is ready to have this exercise in main workout
    2. If difficulty level should be adjusted for future challenges

    Args:
        user_id: The user's ID
        exercise_name: Name of the challenge exercise
        difficulty_felt: "too_easy", "just_right", or "too_hard"
        completed: Whether the user actually completed the challenge
        workout_id: Optional workout ID for tracking
        performance_data: Optional dict with sets, reps, weight, etc.

    Returns:
        Dict with updated challenge mastery status
    """
    try:
        db = get_supabase_db()
        now = datetime.now()

        # Get or create challenge mastery record
        existing = db.client.table("user_challenge_mastery").select("*").eq(
            "user_id", user_id
        ).ilike("exercise_name", exercise_name).execute()

        if existing.data:
            mastery = existing.data[0]
            total_attempts = mastery.get("total_attempts", 0) + 1
            successful_completions = mastery.get("successful_completions", 0)
            consecutive_successes = mastery.get("consecutive_successes", 0)

            if completed:
                successful_completions += 1
                if difficulty_felt in ["too_easy", "just_right"]:
                    consecutive_successes += 1
                else:
                    consecutive_successes = 0  # Reset if too hard
            else:
                consecutive_successes = 0  # Reset on skip/fail

            # Check if ready to move to main workout (2-3 successful completions)
            ready_for_main_workout = consecutive_successes >= 2

            update_data = {
                "total_attempts": total_attempts,
                "successful_completions": successful_completions,
                "consecutive_successes": consecutive_successes,
                "last_difficulty_felt": difficulty_felt,
                "ready_for_main_workout": ready_for_main_workout,
                "last_attempted_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }

            db.client.table("user_challenge_mastery").update(
                update_data
            ).eq("id", mastery["id"]).execute()

            logger.info(
                f"[Challenge] Updated {exercise_name} for user {user_id}: "
                f"attempts={total_attempts}, successes={successful_completions}, "
                f"consecutive={consecutive_successes}, ready_for_main={ready_for_main_workout}"
            )

            return {
                "exercise_name": exercise_name,
                "total_attempts": total_attempts,
                "successful_completions": successful_completions,
                "consecutive_successes": consecutive_successes,
                "ready_for_main_workout": ready_for_main_workout,
                "was_updated": True,
            }
        else:
            # Create new challenge mastery record
            successful_completions = 1 if completed else 0
            consecutive_successes = 1 if (completed and difficulty_felt != "too_hard") else 0

            insert_data = {
                "user_id": user_id,
                "exercise_name": exercise_name,
                "total_attempts": 1,
                "successful_completions": successful_completions,
                "consecutive_successes": consecutive_successes,
                "last_difficulty_felt": difficulty_felt,
                "ready_for_main_workout": False,
                "first_attempted_at": now.isoformat(),
                "last_attempted_at": now.isoformat(),
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }

            db.client.table("user_challenge_mastery").insert(insert_data).execute()

            logger.info(
                f"[Challenge] Created mastery record for {exercise_name}, user {user_id}"
            )

            return {
                "exercise_name": exercise_name,
                "total_attempts": 1,
                "successful_completions": successful_completions,
                "consecutive_successes": consecutive_successes,
                "ready_for_main_workout": False,
                "was_updated": True,
            }

    except Exception as e:
        logger.error(f"Failed to record challenge exercise completion: {e}")
        return {
            "exercise_name": exercise_name,
            "error": str(e),
            "was_updated": False,
        }


async def get_challenges_ready_for_main_workout(
    user_id: str,
) -> List[Dict[str, Any]]:
    """
    Get challenge exercises that the user has mastered and are ready
    to be included in their main workout.

    These are exercises where the user has completed the challenge
    successfully 2+ times consecutively with "just_right" or "too_easy" feedback.

    Args:
        user_id: The user's ID

    Returns:
        List of exercises ready to move to main workout
    """
    try:
        db = get_supabase_db()

        result = db.client.table("user_challenge_mastery").select("*").eq(
            "user_id", user_id
        ).eq("ready_for_main_workout", True).execute()

        ready_exercises = []
        for mastery in result.data or []:
            ready_exercises.append({
                "exercise_name": mastery.get("exercise_name"),
                "consecutive_successes": mastery.get("consecutive_successes", 0),
                "total_attempts": mastery.get("total_attempts", 0),
                "successful_completions": mastery.get("successful_completions", 0),
                "last_difficulty_felt": mastery.get("last_difficulty_felt"),
            })

        logger.info(
            f"[Challenge] Found {len(ready_exercises)} challenge exercises "
            f"ready for main workout for user {user_id}"
        )

        return ready_exercises

    except Exception as e:
        logger.error(f"Failed to get challenges ready for main workout: {e}")
        return []


async def record_progression_response(
    user_id: str,
    exercise_name: str,
    new_exercise_name: str,
    accepted: bool,
    decline_reason: Optional[str] = None,
) -> bool:
    """
    Record user's response to a progression suggestion.

    Updates mastery record and logs the progression event.

    Args:
        user_id: The user's ID
        exercise_name: Current exercise name
        new_exercise_name: Suggested progression exercise
        accepted: Whether user accepted the progression
        decline_reason: Optional reason if declined

    Returns:
        True if successfully recorded
    """
    try:
        db = get_supabase_db()
        now = datetime.now()

        # Get mastery record
        mastery_result = db.client.table("user_exercise_mastery").select("*").eq(
            "user_id", user_id
        ).ilike("exercise_name", exercise_name).execute()

        if not mastery_result.data:
            logger.warning(f"No mastery record found for {exercise_name}")
            return False

        mastery = mastery_result.data[0]
        chain_id = mastery.get("progression_chain_id")

        if accepted:
            # Reset counters since user is moving to new exercise
            update_data = {
                "consecutive_easy_sessions": 0,
                "ready_for_progression": False,
                "suggested_next_variant": None,
                "last_progression_suggested_at": now.isoformat(),
                "progression_accepted_count": mastery.get("progression_accepted_count", 0) + 1,
                "updated_at": now.isoformat(),
            }

            # Log the progression
            from services.user_context_service import user_context_service
            await user_context_service.log_progression_accepted(
                user_id=user_id,
                from_exercise=exercise_name,
                to_exercise=new_exercise_name,
            )
        else:
            # Mark as declined with cooldown
            update_data = {
                "progression_declined_at": now.isoformat(),
                "decline_reason": decline_reason,
                "last_progression_suggested_at": now.isoformat(),
                "progression_declined_count": mastery.get("progression_declined_count", 0) + 1,
                "updated_at": now.isoformat(),
            }

            # Log the decline
            from services.user_context_service import user_context_service
            await user_context_service.log_progression_declined(
                user_id=user_id,
                from_exercise=exercise_name,
                to_exercise=new_exercise_name,
                reason=decline_reason,
            )

        db.client.table("user_exercise_mastery").update(
            update_data
        ).eq("id", mastery["id"]).execute()

        # Record in progression history
        history_record = {
            "user_id": user_id,
            "from_exercise": exercise_name,
            "to_exercise": new_exercise_name,
            "chain_id": chain_id,
            "action": "accepted" if accepted else "declined",
            "reason": decline_reason,
            "context": {
                "consecutive_easy_sessions": mastery.get("consecutive_easy_sessions", 0),
                "total_sessions": mastery.get("total_sessions", 0),
            },
            "created_at": now.isoformat(),
        }

        db.client.table("progression_history").insert(history_record).execute()

        logger.info(
            f"[Progression] Recorded {'acceptance' if accepted else 'decline'} "
            f"for {exercise_name} -> {new_exercise_name}"
        )

        return True

    except Exception as e:
        logger.error(f"Failed to record progression response: {e}")
        return False
