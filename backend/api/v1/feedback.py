"""
Workout and Exercise Feedback API endpoints.

Allows users to rate workouts (1-5 stars) with optional comments
for both overall workout and individual exercises.
"""

from fastapi import APIRouter, HTTPException
from typing import List
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    ExerciseFeedbackCreate, ExerciseFeedback,
    WorkoutFeedbackCreate, WorkoutFeedback, WorkoutFeedbackWithExercises
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Workout Feedback Endpoints
# ============================================

@router.post("/workout/{workout_id}", response_model=WorkoutFeedbackWithExercises)
async def submit_workout_feedback(workout_id: str, feedback: WorkoutFeedbackCreate):
    """
    Submit feedback for a completed workout.

    Includes overall rating (1-5 stars) and optional individual exercise feedback.
    This is called after a user completes or exits a workout.
    """
    logger.info(f"Submitting workout feedback: workout_id={workout_id}, rating={feedback.overall_rating}")

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
        else:
            # Insert new feedback
            result = db.client.table("workout_feedback").insert(
                workout_feedback_record
            ).execute()
            if not result.data:
                raise HTTPException(status_code=500, detail="Failed to create workout feedback")
            workout_feedback_id = result.data[0]["id"]

        # Process individual exercise feedback if provided
        exercise_feedback_list = []
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
                else:
                    # Insert new
                    ex_result = db.client.table("exercise_feedback").insert(
                        ex_record
                    ).execute()

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

        # Get the updated workout feedback
        final_result = db.client.table("workout_feedback").select("*").eq(
            "id", workout_feedback_id
        ).execute()

        if not final_result.data:
            raise HTTPException(status_code=500, detail="Failed to retrieve workout feedback")

        wf = final_result.data[0]
        logger.info(f"Workout feedback submitted: id={workout_feedback_id}")

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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/workout/{workout_id}", response_model=WorkoutFeedbackWithExercises)
async def get_workout_feedback(workout_id: str, user_id: str):
    """Get feedback for a specific workout."""
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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/recent", response_model=List[WorkoutFeedback])
async def get_user_recent_feedback(user_id: str, limit: int = 10):
    """Get recent workout feedback for a user."""
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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/stats")
async def get_user_feedback_stats(user_id: str):
    """Get feedback statistics for a user."""
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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/exercise/{exercise_name}/stats")
async def get_exercise_feedback_stats(exercise_name: str, user_id: str = None):
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
        raise HTTPException(status_code=500, detail=str(e))
