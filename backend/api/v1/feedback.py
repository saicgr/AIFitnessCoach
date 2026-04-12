"""
Workout and Exercise Feedback API endpoints.

Allows users to rate workouts (1-5 stars) with optional comments
for both overall workout and individual exercises.

Also includes AI Coach feedback using RAG for personalized workout analysis.
"""
from core.db import get_supabase_db

from .feedback_models import *  # noqa: F401, F403
from .feedback_endpoints import router as _endpoints_router


from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import (
    ExerciseFeedbackCreate, ExerciseFeedback,
    WorkoutFeedbackCreate, WorkoutFeedback, WorkoutFeedbackWithExercises
)
from services.gemini_service import GeminiService
from services.workout_feedback_rag_service import (
    WorkoutFeedbackRAGService,
    generate_workout_feedback
)
from services.feedback_analysis_service import (
    update_exercise_mastery,
    get_exercises_ready_for_progression,
    record_progression_response,
)
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter

router = APIRouter()
logger = get_logger(__name__)

# ============================================
# Workout Feedback Endpoints
# ============================================

@router.post("/workout/{workout_id}", response_model=WorkoutFeedbackWithExercises)
async def submit_workout_feedback(
    workout_id: str,
    feedback: WorkoutFeedbackCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Submit feedback for a completed workout.

    Includes overall rating (1-5 stars) and optional individual exercise feedback.
    This is called after a user completes or exits a workout.

    Also stores exercise ratings in ChromaDB for AI workout adaptation.
    """
    if str(current_user["id"]) != str(feedback.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"📝 [Feedback] Received feedback submission for workout={workout_id}")
    logger.info(f"📝 [Feedback] User: {feedback.user_id}")
    logger.info(f"📝 [Feedback] Overall rating: {feedback.overall_rating}/5, difficulty: {feedback.overall_difficulty}")
    logger.info(f"📝 [Feedback] Exercise feedback count: {len(feedback.exercise_feedback or [])}")

    try:
        db = get_supabase_db()

        # Verify workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Create workout feedback record
        workout_feedback_record = {
            "user_id": feedback.user_id,
            "workout_id": workout_id,
            "overall_rating": feedback.overall_rating,
            "energy_level": feedback.energy_level,
            "overall_difficulty": feedback.overall_difficulty,
            "comment": feedback.comment,
            "would_recommend": feedback.would_recommend,
            "completed_at": datetime.utcnow().isoformat(),
        }

        # Check if feedback already exists (upsert)
        existing = db.client.table("workout_feedback").select("id").eq(
            "workout_id", workout_id
        ).eq("user_id", feedback.user_id).execute()

        if existing.data:
            # Update existing feedback
            result = db.client.table("workout_feedback").update(
                workout_feedback_record
            ).eq("id", existing.data[0]["id"]).execute()
            workout_feedback_id = existing.data[0]["id"]
            logger.info(f"✅ [Feedback] Updated existing workout_feedback record: {workout_feedback_id}")
        else:
            # Insert new feedback
            result = db.client.table("workout_feedback").insert(
                workout_feedback_record
            ).execute()
            if not result.data:
                logger.error(f"❌ [Feedback] Failed to insert workout_feedback")
                raise safe_internal_error(ValueError("Failed to insert workout feedback"), "feedback")
            workout_feedback_id = result.data[0]["id"]
            logger.info(f"✅ [Feedback] Inserted new workout_feedback record: {workout_feedback_id}")

        # Process individual exercise feedback if provided
        exercise_feedback_list = []
        exercise_ratings_for_chromadb = []  # Collect for ChromaDB indexing

        if feedback.exercise_feedback:
            for ex_feedback in feedback.exercise_feedback:
                ex_record = {
                    "user_id": feedback.user_id,
                    "workout_id": workout_id,
                    "exercise_name": ex_feedback.exercise_name,
                    "exercise_index": ex_feedback.exercise_index,
                    "rating": ex_feedback.rating,
                    "comment": ex_feedback.comment,
                    "difficulty_felt": ex_feedback.difficulty_felt,
                    "would_do_again": ex_feedback.would_do_again,
                }

                # Check if exercise feedback already exists
                existing_ex = db.client.table("exercise_feedback").select("id").eq(
                    "workout_id", workout_id
                ).eq("user_id", feedback.user_id).eq(
                    "exercise_index", ex_feedback.exercise_index
                ).execute()

                if existing_ex.data:
                    # Update existing
                    ex_result = db.client.table("exercise_feedback").update(
                        ex_record
                    ).eq("id", existing_ex.data[0]["id"]).execute()
                    logger.debug(f"✅ [Feedback] Updated exercise_feedback for {ex_feedback.exercise_name}")
                else:
                    # Insert new
                    ex_result = db.client.table("exercise_feedback").insert(
                        ex_record
                    ).execute()
                    logger.debug(f"✅ [Feedback] Inserted exercise_feedback for {ex_feedback.exercise_name}")

                if ex_result.data:
                    exercise_feedback_list.append(ExerciseFeedback(
                        id=str(ex_result.data[0]["id"]),
                        user_id=ex_result.data[0]["user_id"],
                        workout_id=ex_result.data[0]["workout_id"],
                        exercise_name=ex_result.data[0]["exercise_name"],
                        exercise_index=ex_result.data[0]["exercise_index"],
                        rating=ex_result.data[0]["rating"],
                        comment=ex_result.data[0].get("comment"),
                        difficulty_felt=ex_result.data[0].get("difficulty_felt"),
                        would_do_again=ex_result.data[0].get("would_do_again", True),
                        created_at=ex_result.data[0].get("created_at") or datetime.utcnow()
                    ))

                    # Collect for ChromaDB
                    exercise_ratings_for_chromadb.append({
                        "exercise_name": ex_feedback.exercise_name,
                        "rating": ex_feedback.rating,
                        "difficulty_felt": ex_feedback.difficulty_felt or "just_right",
                        "would_do_again": ex_feedback.would_do_again,
                    })

                    # Update exercise mastery for progression tracking
                    difficulty_felt = ex_feedback.difficulty_felt or "just_right"
                    try:
                        await update_exercise_mastery(
                            user_id=feedback.user_id,
                            exercise_name=ex_feedback.exercise_name,
                            difficulty_felt=difficulty_felt,
                        )
                        logger.debug(
                            f"Updated mastery for {ex_feedback.exercise_name}: {difficulty_felt}"
                        )
                    except Exception as mastery_error:
                        logger.warning(
                            f"Failed to update mastery for {ex_feedback.exercise_name}: {mastery_error}"
                        , exc_info=True)

        # Index feedback in ChromaDB for AI adaptation
        try:
            rag_service = get_feedback_rag_service()
            await rag_service.index_workout_feedback(
                user_id=feedback.user_id,
                workout_id=workout_id,
                overall_rating=feedback.overall_rating,
                overall_difficulty=feedback.overall_difficulty or "just_right",
                energy_level=feedback.energy_level or "good",
                exercise_ratings=exercise_ratings_for_chromadb,
                feedback_at=datetime.utcnow().isoformat(),
            )
            logger.info(f"🎯 Indexed workout feedback in ChromaDB for user {feedback.user_id}")
        except Exception as e:
            logger.warning(f"Failed to index feedback in ChromaDB: {e}", exc_info=True)

        # Get the updated workout feedback
        final_result = db.client.table("workout_feedback").select("*").eq(
            "id", workout_feedback_id
        ).execute()

        if not final_result.data:
            raise safe_internal_error(ValueError("Failed to retrieve workout feedback"), "feedback")

        wf = final_result.data[0]
        logger.info(f"Workout feedback submitted: id={workout_feedback_id}")

        # Log workout feedback submission
        await log_user_activity(
            user_id=feedback.user_id,
            action="workout_feedback",
            endpoint=f"/api/v1/feedback/workout/{workout_id}",
            message=f"Submitted feedback: {feedback.overall_rating}/5 stars",
            metadata={
                "workout_id": workout_id,
                "overall_rating": feedback.overall_rating,
                "energy_level": feedback.energy_level,
                "overall_difficulty": feedback.overall_difficulty,
                "exercise_count": len(exercise_feedback_list),
            },
            status_code=200
        )

        return WorkoutFeedbackWithExercises(
            id=str(wf["id"]),
            user_id=wf["user_id"],
            workout_id=wf["workout_id"],
            overall_rating=wf["overall_rating"],
            energy_level=wf.get("energy_level"),
            overall_difficulty=wf.get("overall_difficulty"),
            comment=wf.get("comment"),
            would_recommend=wf.get("would_recommend", True),
            completed_at=wf.get("completed_at") or datetime.utcnow(),
            created_at=wf.get("created_at") or datetime.utcnow(),
            exercise_feedback=exercise_feedback_list
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to submit workout feedback: {e}", exc_info=True)
        await log_user_error(
            user_id=feedback.user_id,
            action="workout_feedback",
            error=e,
            endpoint=f"/api/v1/feedback/workout/{workout_id}",
            metadata={"workout_id": workout_id},
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

@router.get("/workout/{workout_id}", response_model=WorkoutFeedbackWithExercises)
async def get_workout_feedback(
    workout_id: str,
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get feedback for a specific workout."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting workout feedback: workout_id={workout_id}")

    try:
        db = get_supabase_db()

        # Get workout feedback
        result = db.client.table("workout_feedback").select("*").eq(
            "workout_id", workout_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Feedback not found")

        wf = result.data[0]

        # Get exercise feedback
        ex_result = db.client.table("exercise_feedback").select("*").eq(
            "workout_id", workout_id
        ).eq("user_id", user_id).order("exercise_index").execute()

        exercise_feedback_list = [
            ExerciseFeedback(
                id=str(ex["id"]),
                user_id=ex["user_id"],
                workout_id=ex["workout_id"],
                exercise_name=ex["exercise_name"],
                exercise_index=ex["exercise_index"],
                rating=ex["rating"],
                comment=ex.get("comment"),
                difficulty_felt=ex.get("difficulty_felt"),
                would_do_again=ex.get("would_do_again", True),
                created_at=ex.get("created_at") or datetime.utcnow()
            )
            for ex in ex_result.data
        ]

        return WorkoutFeedbackWithExercises(
            id=str(wf["id"]),
            user_id=wf["user_id"],
            workout_id=wf["workout_id"],
            overall_rating=wf["overall_rating"],
            energy_level=wf.get("energy_level"),
            overall_difficulty=wf.get("overall_difficulty"),
            comment=wf.get("comment"),
            would_recommend=wf.get("would_recommend", True),
            completed_at=wf.get("completed_at") or datetime.utcnow(),
            created_at=wf.get("created_at") or datetime.utcnow(),
            exercise_feedback=exercise_feedback_list
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout feedback: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")

@router.get("/user/{user_id}/recent", response_model=List[WorkoutFeedback])
async def get_user_recent_feedback(
    user_id: str,
    limit: int = 10,
    current_user: dict = Depends(get_current_user),
):
    """Get recent workout feedback for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting recent feedback for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_feedback").select("*").eq(
            "user_id", user_id
        ).order("created_at", desc=True).limit(limit).execute()

        return [
            WorkoutFeedback(
                id=str(wf["id"]),
                user_id=wf["user_id"],
                workout_id=wf["workout_id"],
                overall_rating=wf["overall_rating"],
                energy_level=wf.get("energy_level"),
                overall_difficulty=wf.get("overall_difficulty"),
                comment=wf.get("comment"),
                would_recommend=wf.get("would_recommend", True),
                completed_at=wf.get("completed_at") or datetime.utcnow(),
                created_at=wf.get("created_at") or datetime.utcnow()
            )
            for wf in result.data
        ]

    except Exception as e:
        logger.error(f"Failed to get user feedback: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")

@router.get("/user/{user_id}/stats")
async def get_user_feedback_stats(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get feedback statistics for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting feedback stats for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get all workout feedback
        result = db.client.table("workout_feedback").select("*").eq(
            "user_id", user_id
        ).execute()

        if not result.data:
            return {
                "total_feedback": 0,
                "average_rating": 0,
                "rating_distribution": {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0},
                "energy_level_distribution": {},
                "difficulty_distribution": {}
            }

        feedbacks = result.data
        total = len(feedbacks)

        # Calculate average rating
        avg_rating = sum(f["overall_rating"] for f in feedbacks) / total

        # Rating distribution
        rating_dist = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
        for f in feedbacks:
            rating_dist[str(f["overall_rating"])] += 1

        # Energy level distribution
        energy_dist = {}
        for f in feedbacks:
            if f.get("energy_level"):
                energy_dist[f["energy_level"]] = energy_dist.get(f["energy_level"], 0) + 1

        # Difficulty distribution
        diff_dist = {}
        for f in feedbacks:
            if f.get("overall_difficulty"):
                diff_dist[f["overall_difficulty"]] = diff_dist.get(f["overall_difficulty"], 0) + 1

        return {
            "total_feedback": total,
            "average_rating": round(avg_rating, 2),
            "rating_distribution": rating_dist,
            "energy_level_distribution": energy_dist,
            "difficulty_distribution": diff_dist
        }

    except Exception as e:
        logger.error(f"Failed to get feedback stats: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")

@router.get("/exercise/{exercise_name}/stats")
async def get_exercise_feedback_stats(
    exercise_name: str,
    user_id: str = None,
    current_user: dict = Depends(get_current_user),
):
    """Get feedback statistics for a specific exercise."""
    logger.info(f"Getting feedback stats for exercise: {exercise_name}")

    try:
        db = get_supabase_db()

        query = db.client.table("exercise_feedback").select("*").eq(
            "exercise_name", exercise_name
        )

        if user_id:
            query = query.eq("user_id", user_id)

        result = query.execute()

        if not result.data:
            return {
                "exercise_name": exercise_name,
                "total_feedback": 0,
                "average_rating": 0,
                "would_do_again_percentage": 0,
                "difficulty_distribution": {}
            }

        feedbacks = result.data
        total = len(feedbacks)

        avg_rating = sum(f["rating"] for f in feedbacks) / total
        would_do_again_count = sum(1 for f in feedbacks if f.get("would_do_again", True))

        diff_dist = {}
        for f in feedbacks:
            if f.get("difficulty_felt"):
                diff_dist[f["difficulty_felt"]] = diff_dist.get(f["difficulty_felt"], 0) + 1

        return {
            "exercise_name": exercise_name,
            "total_feedback": total,
            "average_rating": round(avg_rating, 2),
            "would_do_again_percentage": round(would_do_again_count / total * 100, 1),
            "difficulty_distribution": diff_dist
        }

    except Exception as e:
        logger.error(f"Failed to get exercise feedback stats: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")

# ============================================
# AI Coach Feedback Endpoints (RAG-powered)
# ============================================

class SetDetail(BaseModel):
    """Individual set detail for an exercise."""
    reps: int
    weight_kg: float

class ExercisePerformance(BaseModel):
    """Exercise performance data for a workout session."""
    name: str
    sets: int
    reps: int
    weight_kg: float
    time_seconds: int = 0  # Time spent on this exercise
    set_details: List[SetDetail] = []  # Individual set data

class PlannedExercise(BaseModel):
    """Planned exercise from workout definition (for skip detection)."""
    name: str
    target_sets: int = 3
    target_reps: int = 10
    target_weight_kg: float = 0.0

class AICoachFeedbackRequest(BaseModel):
    """Request body for AI Coach feedback generation."""
    user_id: str
    workout_log_id: str
    workout_id: str
    workout_name: str
    workout_type: str = "strength"
    exercises: List[ExercisePerformance]
    planned_exercises: List[PlannedExercise] = []  # For skip detection
    total_time_seconds: int
    total_rest_seconds: int = 0
    avg_rest_seconds: float = 0.0
    calories_burned: int = 0
    total_sets: int = 0
    total_reps: int = 0
    total_volume_kg: float = 0.0
    # Coach personality settings
    coach_name: Optional[str] = None
    coaching_style: Optional[str] = None  # "motivational", "drill_sergeant", "buddy", "zen_master"
    communication_tone: Optional[str] = None  # "encouraging", "direct", "friendly"
    encouragement_level: Optional[float] = None  # 0.0-1.0
    # Trophy/achievement context for personalized feedback
    earned_prs: Optional[List[dict]] = None
    earned_achievements: Optional[List[dict]] = None
    total_workouts_completed: Optional[int] = None
    next_milestone: Optional[dict] = None

class AICoachFeedbackResponse(BaseModel):
    """Response from AI Coach feedback generation."""
    feedback: str
    indexed: bool = False
    workout_log_id: str

# Singleton services (lazy initialization)
_gemini_service: Optional[GeminiService] = None
_feedback_rag_service: Optional[WorkoutFeedbackRAGService] = None

def get_gemini_service() -> GeminiService:
    """Get or create Gemini service singleton."""
    global _gemini_service
    if _gemini_service is None:
        _gemini_service = GeminiService()
    return _gemini_service

def get_feedback_rag_service() -> WorkoutFeedbackRAGService:
    """Get or create Workout Feedback RAG service singleton."""
    global _feedback_rag_service
    if _feedback_rag_service is None:
        _feedback_rag_service = WorkoutFeedbackRAGService(get_gemini_service())
    return _feedback_rag_service

@router.post("/ai-coach", response_model=AICoachFeedbackResponse)
@limiter.limit("5/minute")
async def generate_ai_coach_feedback(
    request: Request,
    body: AICoachFeedbackRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate AI Coach feedback for a completed workout.

    This endpoint:
    1. Stores the workout session data in ChromaDB for future RAG retrieval
    2. Retrieves past workout history for comparison
    3. Generates short, personalized feedback using the AI Coach

    The feedback includes:
    - Performance summary (time, calories, sets)
    - Weight progression compared to previous sessions
    - Rest pattern analysis
    - Motivational note
    """
    if str(current_user["id"]) != str(body.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"📝 [AI Coach] Generating feedback for user {body.user_id}, workout {body.workout_name}")
    logger.info(f"📝 [AI Coach] Completed exercises: {len(body.exercises)}")
    logger.info(f"📝 [AI Coach] Planned exercises: {len(body.planned_exercises)}")

    try:
        gemini_service = get_gemini_service()
        rag_service = get_feedback_rag_service()

        # Convert exercises to dict format with enhanced data
        exercises_data = [
            {
                "name": ex.name,
                "sets": ex.sets,
                "reps": ex.reps,
                "weight_kg": ex.weight_kg,
                "time_seconds": ex.time_seconds,
                "set_details": [{"reps": s.reps, "weight_kg": s.weight_kg} for s in ex.set_details],
            }
            for ex in body.exercises
        ]

        # Convert planned exercises to dict format
        planned_exercises_data = [
            {
                "name": ex.name,
                "target_sets": ex.target_sets,
                "target_reps": ex.target_reps,
                "target_weight_kg": ex.target_weight_kg,
            }
            for ex in body.planned_exercises
        ]

        # Prepare current session data
        current_session = {
            "workout_log_id": body.workout_log_id,
            "workout_id": body.workout_id,
            "workout_name": body.workout_name,
            "workout_type": body.workout_type,
            "exercises": exercises_data,
            "planned_exercises": planned_exercises_data,  # For skip detection
            "total_time_seconds": body.total_time_seconds,
            "total_rest_seconds": body.total_rest_seconds,
            "avg_rest_seconds": body.avg_rest_seconds,
            "calories_burned": body.calories_burned,
            "total_sets": body.total_sets,
            "total_reps": body.total_reps,
            "total_volume_kg": body.total_volume_kg,
            "completed_at": datetime.utcnow().isoformat(),
        }

        # Generate AI feedback with coach personality and trophy context
        feedback = await generate_workout_feedback(
            gemini_service=gemini_service,
            rag_service=rag_service,
            user_id=body.user_id,
            current_session=current_session,
            coach_name=body.coach_name,
            coaching_style=body.coaching_style,
            communication_tone=body.communication_tone,
            encouragement_level=body.encouragement_level,
            # Trophy/achievement context
            earned_prs=body.earned_prs,
            earned_achievements=body.earned_achievements,
            total_workouts_completed=body.total_workouts_completed,
            next_milestone=body.next_milestone,
        )

        # Index the workout session for future RAG retrieval
        indexed = False
        try:
            # Fetch user preferences for RAG context
            from api.v1.workouts.utils import (
                get_user_training_intensity,
                get_user_progression_pace,
                get_user_1rm_data,
            )

            training_intensity = await get_user_training_intensity(body.user_id)
            progression_pace = await get_user_progression_pace(body.user_id)
            user_1rm_data = await get_user_1rm_data(body.user_id)

            await rag_service.index_workout_session(
                workout_log_id=body.workout_log_id,
                workout_id=body.workout_id,
                user_id=body.user_id,
                workout_name=body.workout_name,
                workout_type=body.workout_type,
                exercises=exercises_data,
                total_time_seconds=body.total_time_seconds,
                total_rest_seconds=body.total_rest_seconds,
                avg_rest_seconds=body.avg_rest_seconds,
                calories_burned=body.calories_burned,
                total_sets=body.total_sets,
                total_reps=body.total_reps,
                total_volume_kg=body.total_volume_kg,
                completed_at=current_session["completed_at"],
                # Pass user preferences for RAG context
                training_intensity_percent=training_intensity,
                progression_pace=progression_pace,
                has_1rm_data=bool(user_1rm_data),
            )
            indexed = True
            logger.info(f"Indexed workout session {body.workout_log_id} for RAG (intensity={training_intensity}%, pace={progression_pace})")
        except Exception as e:
            logger.warning(f"Failed to index workout session: {e}", exc_info=True)

        return AICoachFeedbackResponse(
            feedback=feedback,
            indexed=indexed,
            workout_log_id=body.workout_log_id,
        )

    except Exception as e:
        logger.error(f"Failed to generate AI Coach feedback: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")

@router.get("/ai-coach/history/{user_id}")
async def get_ai_coach_workout_history(
    user_id: str,
    limit: int = 10,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's workout history stored in the RAG system.

    This allows the frontend to display past workout summaries
    and the AI Coach's analysis of workout patterns.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting AI Coach workout history for user {user_id}")

    try:
        rag_service = get_feedback_rag_service()

        sessions = await rag_service.get_user_workout_history(
            user_id=user_id,
            n_results=limit,
        )

        # Format response
        history = []
        for session in sessions:
            meta = session.get("metadata", {})
            history.append({
                "workout_log_id": meta.get("workout_log_id"),
                "workout_id": meta.get("workout_id"),
                "workout_name": meta.get("workout_name"),
                "workout_type": meta.get("workout_type"),
                "exercise_count": meta.get("exercise_count"),
                "total_time_seconds": meta.get("total_time_seconds"),
                "calories_burned": meta.get("calories_burned"),
                "total_sets": meta.get("total_sets"),
                "total_reps": meta.get("total_reps"),
                "total_volume_kg": meta.get("total_volume_kg"),
                "completed_at": meta.get("completed_at"),
            })

        return {
            "user_id": user_id,
            "session_count": len(history),
            "sessions": history,
        }

    except Exception as e:
        logger.error(f"Failed to get AI Coach workout history: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# Include secondary endpoints
router.include_router(_endpoints_router)
