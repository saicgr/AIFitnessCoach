"""
Workout and Exercise Feedback API endpoints.

Allows users to rate workouts (1-5 stars) with optional comments
for both overall workout and individual exercises.

Also includes AI Coach feedback using RAG for personalized workout analysis.
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
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
                raise HTTPException(status_code=500, detail="Failed to insert workout feedback")
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
                        )

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
            logger.warning(f"Failed to index feedback in ChromaDB: {e}")

        # Get the updated workout feedback
        final_result = db.client.table("workout_feedback").select("*").eq(
            "id", workout_feedback_id
        ).execute()

        if not final_result.data:
            raise HTTPException(status_code=500, detail="Failed to retrieve workout feedback")

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
        logger.error(f"Failed to submit workout feedback: {e}")
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
        logger.error(f"Failed to get workout feedback: {e}")
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
        logger.error(f"Failed to get user feedback: {e}")
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
        logger.error(f"Failed to get feedback stats: {e}")
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
        logger.error(f"Failed to get exercise feedback stats: {e}")
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
            logger.warning(f"Failed to index workout session: {e}")

        return AICoachFeedbackResponse(
            feedback=feedback,
            indexed=indexed,
            workout_log_id=body.workout_log_id,
        )

    except Exception as e:
        logger.error(f"Failed to generate AI Coach feedback: {e}")
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
        logger.error(f"Failed to get AI Coach workout history: {e}")
        raise safe_internal_error(e, "endpoint")

@router.get("/ai-coach/exercise-progress/{user_id}/{exercise_name}")
async def get_exercise_progress(
    user_id: str,
    exercise_name: str,
    limit: int = 10,
    current_user: dict = Depends(get_current_user),
):
    """
    Get weight progression history for a specific exercise.

    This allows the frontend to display charts showing
    how the user has progressed on specific exercises over time.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting exercise progress for user {user_id}, exercise {exercise_name}")

    try:
        rag_service = get_feedback_rag_service()

        history = await rag_service.get_exercise_weight_history(
            user_id=user_id,
            exercise_name=exercise_name,
            n_results=limit,
        )

        return {
            "user_id": user_id,
            "exercise_name": exercise_name,
            "data_points": len(history),
            "history": history,
        }

    except Exception as e:
        logger.error(f"Failed to get exercise progress: {e}")
        raise safe_internal_error(e, "endpoint")

@router.get("/ai-coach/stats")
async def get_ai_coach_rag_stats(current_user: dict = Depends(get_current_user)):
    """Get statistics for the AI Coach RAG system."""
    try:
        rag_service = get_feedback_rag_service()
        return rag_service.get_stats()
    except Exception as e:
        logger.error(f"Failed to get AI Coach stats: {e}")
        raise safe_internal_error(e, "endpoint")

@router.get("/ai-coach/achievements/{user_id}")
async def get_user_achievements(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user personal records and achievements from workout history.

    This endpoint analyzes past workout data to detect:
    - Highest weight lifted for each exercise (Personal Records)
    - Highest total volume in a single workout
    - New PRs achieved in the current session
    - Workout streaks and milestones
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting achievements for user {user_id}")

    try:
        rag_service = get_feedback_rag_service()

        # Get all workout history for user
        sessions = await rag_service.get_user_workout_history(
            user_id=user_id,
            n_results=100,  # Get more history for achievements
        )

        # Calculate achievements
        exercise_prs = {}  # {exercise_name: {weight_kg, reps, date, workout_name}}
        workout_volume_record = None  # {total_volume_kg, workout_name, date}
        total_workouts = len(sessions)
        total_volume_lifted = 0.0
        total_calories_burned = 0

        for session in sessions:
            meta = session.get("metadata", {})
            exercises = meta.get("exercises", [])
            session_volume = meta.get("total_volume_kg", 0) or 0
            session_calories = meta.get("calories_burned", 0) or 0
            completed_at = meta.get("completed_at", "")
            workout_name = meta.get("workout_name", "Unknown")

            total_volume_lifted += session_volume
            total_calories_burned += session_calories

            # Check if this workout has highest volume
            if workout_volume_record is None or session_volume > workout_volume_record.get("total_volume_kg", 0):
                workout_volume_record = {
                    "total_volume_kg": session_volume,
                    "workout_name": workout_name,
                    "date": completed_at,
                }

            # Check exercise PRs
            for ex in exercises:
                ex_name = ex.get("name", "Unknown")
                ex_weight = ex.get("weight_kg", 0) or 0
                ex_reps = ex.get("reps", 0) or 0

                if ex_name not in exercise_prs or ex_weight > exercise_prs[ex_name].get("weight_kg", 0):
                    exercise_prs[ex_name] = {
                        "weight_kg": ex_weight,
                        "reps": ex_reps,
                        "date": completed_at,
                        "workout_name": workout_name,
                    }

        # Format response
        exercise_records = [
            {
                "exercise_name": name,
                "weight_kg": data["weight_kg"],
                "reps": data["reps"],
                "date": data["date"],
                "workout_name": data["workout_name"],
            }
            for name, data in sorted(exercise_prs.items(), key=lambda x: x[1]["weight_kg"], reverse=True)
        ]

        return {
            "user_id": user_id,
            "total_workouts": total_workouts,
            "total_volume_lifted_kg": round(total_volume_lifted, 1),
            "total_calories_burned": total_calories_burned,
            "workout_volume_record": workout_volume_record,
            "exercise_personal_records": exercise_records[:20],  # Top 20 exercises
            "achievement_count": len(exercise_records),
        }

    except Exception as e:
        logger.error(f"Failed to get user achievements: {e}")
        raise safe_internal_error(e, "endpoint")

# ============================================
# Progression Suggestion Endpoints
# ============================================

class ProgressionSuggestionResponse(BaseModel):
    """Response model for progression suggestions."""
    exercise_name: str
    suggested_next_variant: str
    consecutive_easy_sessions: int
    difficulty_increase: Optional[float] = None
    chain_id: Optional[str] = None

class ProgressionResponseRequest(BaseModel):
    """Request body for responding to a progression suggestion."""
    user_id: str
    exercise_name: str
    new_exercise_name: str
    accepted: bool
    decline_reason: Optional[str] = None

@router.get("/progression-suggestions/{user_id}", response_model=List[ProgressionSuggestionResponse])
async def get_progression_suggestions(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get exercise progression suggestions for a user.

    Returns exercises where the user has rated difficulty as "too easy"
    for 2+ consecutive sessions and a harder variant is available.

    This endpoint is called after workout completion to show the user
    opportunities to progress to more challenging exercise variations.

    Important considerations:
    - Only suggests once per exercise per week (cooldown period)
    - Respects declined progressions (won't spam)
    - Only returns exercises with valid next variants in chain
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting progression suggestions for user {user_id}")

    try:
        suggestions = await get_exercises_ready_for_progression(user_id)

        return [
            ProgressionSuggestionResponse(
                exercise_name=s.exercise_name,
                suggested_next_variant=s.suggested_next_variant,
                consecutive_easy_sessions=s.consecutive_easy_sessions,
                difficulty_increase=s.difficulty_increase,
                chain_id=s.chain_id,
            )
            for s in suggestions
            if s.suggested_next_variant  # Only include if we have a next variant
        ]

    except Exception as e:
        logger.error(f"Failed to get progression suggestions: {e}")
        raise safe_internal_error(e, "endpoint")

@router.post("/progression-response")
async def respond_to_progression(
    request: ProgressionResponseRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Record user's response to a progression suggestion.

    When a user accepts:
    - The mastery counters are reset
    - The progression is logged for analytics
    - Future workouts can include the new variant

    When a user declines:
    - A cooldown period is applied (won't suggest again for 7 days)
    - The decline reason is logged for improvement
    - The suggestion won't appear again until cooldown expires

    Args:
        request: Contains user_id, exercise names, and accept/decline status

    Returns:
        Success status and any updated information
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(
        f"Recording progression response: {request.exercise_name} -> "
        f"{request.new_exercise_name}, accepted={request.accepted}"
    )

    try:
        success = await record_progression_response(
            user_id=request.user_id,
            exercise_name=request.exercise_name,
            new_exercise_name=request.new_exercise_name,
            accepted=request.accepted,
            decline_reason=request.decline_reason,
        )

        if not success:
            raise HTTPException(
                status_code=400,
                detail="Failed to record progression response"
            )

        # Log activity
        action = "progression_accepted" if request.accepted else "progression_declined"
        await log_user_activity(
            user_id=request.user_id,
            action=action,
            endpoint="/api/v1/feedback/progression-response",
            message=f"{'Accepted' if request.accepted else 'Declined'} progression: "
                    f"{request.exercise_name} -> {request.new_exercise_name}",
            metadata={
                "from_exercise": request.exercise_name,
                "to_exercise": request.new_exercise_name,
                "accepted": request.accepted,
                "decline_reason": request.decline_reason,
            },
            status_code=200
        )

        return {
            "success": True,
            "message": f"Progression {'accepted' if request.accepted else 'declined'}",
            "from_exercise": request.exercise_name,
            "to_exercise": request.new_exercise_name,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to record progression response: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="progression_response",
            error=e,
            endpoint="/api/v1/feedback/progression-response",
            metadata={
                "from_exercise": request.exercise_name,
                "to_exercise": request.new_exercise_name,
            },
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

# ============================================
# Challenge Exercise Feedback Endpoints
# ============================================

class ChallengeExerciseFeedbackRequest(BaseModel):
    """Request body for challenge exercise feedback."""
    user_id: str
    exercise_name: str
    difficulty_felt: str  # "too_easy", "just_right", "too_hard"
    completed: bool
    workout_id: Optional[str] = None
    performance_data: Optional[dict] = None  # {sets_completed, total_reps, avg_weight}

class ChallengeExerciseFeedbackResponse(BaseModel):
    """Response from challenge exercise feedback submission."""
    success: bool
    exercise_name: str
    consecutive_successes: int
    ready_for_main_workout: bool
    message: str

@router.post("/challenge-exercise", response_model=ChallengeExerciseFeedbackResponse)
async def submit_challenge_exercise_feedback(
    request: ChallengeExerciseFeedbackRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Submit feedback for a challenge exercise completion.

    This endpoint tracks beginner users' progress with challenge exercises.
    When they complete challenges successfully 2+ times consecutively,
    the exercise becomes ready to be included in their main workouts.

    Flow:
    1. User completes (or skips) a challenge exercise during workout
    2. Frontend calls this endpoint with completion status and difficulty felt
    3. Backend updates user_challenge_mastery table
    4. If 2+ consecutive successes with "just_right" or "too_easy" feedback,
       the exercise is marked as ready_for_main_workout
    5. Future workout generation can include this exercise in main workout

    Args:
        request: Challenge exercise feedback data

    Returns:
        Updated mastery status including whether exercise is ready for main workout
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(
        f"Recording challenge exercise feedback: {request.exercise_name} "
        f"for user {request.user_id}, completed={request.completed}, "
        f"difficulty={request.difficulty_felt}"
    )

    try:
        from services.feedback_analysis_service import record_challenge_exercise_completion

        result = await record_challenge_exercise_completion(
            user_id=request.user_id,
            exercise_name=request.exercise_name,
            difficulty_felt=request.difficulty_felt,
            completed=request.completed,
            workout_id=request.workout_id,
            performance_data=request.performance_data,
        )

        if not result.get("was_updated", False):
            error_msg = result.get("error", "Unknown error")
            logger.warning(f"Failed to update challenge mastery: {error_msg}")

        # Build response message
        if result.get("ready_for_main_workout", False):
            message = f"Great progress! {request.exercise_name} can now appear in your regular workouts."
        elif request.completed and request.difficulty_felt != "too_hard":
            remaining = 2 - result.get("consecutive_successes", 0)
            if remaining > 0:
                message = f"Keep it up! {remaining} more successful attempt{'s' if remaining > 1 else ''} to master this exercise."
            else:
                message = "You're mastering this challenge!"
        elif not request.completed:
            message = "No worries! Challenge exercises are optional. Try again next time!"
        else:
            message = "Thanks for the feedback! We'll adjust future challenges accordingly."

        # Log activity
        await log_user_activity(
            user_id=request.user_id,
            action="challenge_exercise_feedback",
            endpoint="/api/v1/feedback/challenge-exercise",
            message=f"Challenge: {request.exercise_name} - {'completed' if request.completed else 'skipped'}",
            metadata={
                "exercise_name": request.exercise_name,
                "difficulty_felt": request.difficulty_felt,
                "completed": request.completed,
                "consecutive_successes": result.get("consecutive_successes", 0),
                "ready_for_main": result.get("ready_for_main_workout", False),
                "performance_data": request.performance_data,
            },
            status_code=200
        )

        return ChallengeExerciseFeedbackResponse(
            success=True,
            exercise_name=request.exercise_name,
            consecutive_successes=result.get("consecutive_successes", 0),
            ready_for_main_workout=result.get("ready_for_main_workout", False),
            message=message,
        )

    except Exception as e:
        logger.error(f"Failed to submit challenge exercise feedback: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="challenge_exercise_feedback",
            error=e,
            endpoint="/api/v1/feedback/challenge-exercise",
            metadata={"exercise_name": request.exercise_name},
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

@router.get("/challenge-mastery/{user_id}")
async def get_user_challenge_mastery(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all challenge exercise mastery data for a user.

    Returns which challenge exercises the user has attempted,
    their success rates, and which ones are ready for main workouts.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting challenge mastery for user {user_id}")

    try:
        from services.feedback_analysis_service import get_challenges_ready_for_main_workout

        ready_exercises = await get_challenges_ready_for_main_workout(user_id)

        # Also get all challenge mastery records
        db = get_supabase_db()
        all_mastery = db.client.table("user_challenge_mastery").select("*").eq(
            "user_id", user_id
        ).order("last_attempted_at", desc=True).execute()

        mastery_list = []
        for m in all_mastery.data or []:
            mastery_list.append({
                "exercise_name": m.get("exercise_name"),
                "total_attempts": m.get("total_attempts", 0),
                "successful_completions": m.get("successful_completions", 0),
                "consecutive_successes": m.get("consecutive_successes", 0),
                "last_difficulty_felt": m.get("last_difficulty_felt"),
                "ready_for_main_workout": m.get("ready_for_main_workout", False),
                "first_attempted_at": m.get("first_attempted_at"),
                "last_attempted_at": m.get("last_attempted_at"),
            })

        return {
            "user_id": user_id,
            "total_challenges_attempted": len(mastery_list),
            "ready_for_main_workout_count": len(ready_exercises),
            "ready_exercises": [e["exercise_name"] for e in ready_exercises],
            "mastery_records": mastery_list,
        }

    except Exception as e:
        logger.error(f"Failed to get challenge mastery: {e}")
        raise safe_internal_error(e, "endpoint")
