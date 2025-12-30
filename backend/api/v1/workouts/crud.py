"""
Workout CRUD API endpoints.

This module handles basic create, read, update, delete operations for workouts:
- POST / - Create a new workout
- GET / - List workouts for a user
- GET /{id} - Get workout by ID
- PUT /{id} - Update workout
- DELETE /{id} - Delete workout
- POST /{id}/complete - Mark workout as completed (with PR detection & strength recalc)
"""
import json
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any

from fastapi import APIRouter, HTTPException, Query, BackgroundTasks
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.db import get_supabase_db as get_db
from core.logger import get_logger
from models.schemas import Workout, WorkoutCreate, WorkoutUpdate

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
)

# Import services for PR detection and strength calculation
from services.personal_records_service import PersonalRecordsService
from services.strength_calculator_service import StrengthCalculatorService, MuscleGroup
from services.ai_insights_service import ai_insights_service

router = APIRouter()
logger = get_logger(__name__)


# Response model for workout completion with PRs
class PersonalRecordInfo(BaseModel):
    """PR info returned after workout completion."""
    exercise_name: str
    weight_kg: float
    reps: int
    estimated_1rm_kg: float
    previous_1rm_kg: Optional[float] = None
    improvement_kg: Optional[float] = None
    improvement_percent: Optional[float] = None
    is_all_time_pr: bool = True
    celebration_message: Optional[str] = None


class WorkoutCompletionResponse(BaseModel):
    """Extended response for workout completion including PRs."""
    workout: Workout
    personal_records: List[PersonalRecordInfo] = []
    strength_scores_updated: bool = False
    message: str = "Workout completed successfully"


@router.post("/", response_model=Workout)
async def create_workout(workout: WorkoutCreate):
    """Create a new workout."""
    logger.info(f"Creating workout for user {workout.user_id}: {workout.name}")
    try:
        db = get_supabase_db()

        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json

        workout_data = {
            "user_id": workout.user_id,
            "name": workout.name,
            "type": workout.type,
            "difficulty": workout.difficulty,
            "scheduled_date": str(workout.scheduled_date),
            "exercises_json": exercises,
            "duration_minutes": workout.duration_minutes,
            "generation_method": workout.generation_method,
            "generation_source": workout.generation_source,
            "generation_metadata": workout.generation_metadata,
        }

        created = db.create_workout(workout_data)
        logger.info(f"Workout created: id={created['id']}")

        log_workout_change(
            workout_id=created['id'],
            user_id=workout.user_id,
            change_type="created",
            change_source=workout.generation_source or "api",
            new_value={"name": workout.name, "type": workout.type, "exercises_count": len(exercises)}
        )

        created_workout = row_to_workout(created)
        await index_workout_to_rag(created_workout)

        return created_workout

    except Exception as e:
        logger.error(f"Failed to create workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[Workout])
async def list_workouts(
    user_id: str,
    is_completed: Optional[bool] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """List workouts for a user with optional filters."""
    logger.info(f"Listing workouts for user {user_id}")
    try:
        db = get_supabase_db()
        rows = db.list_workouts(
            user_id=user_id,
            is_completed=is_completed,
            from_date=str(from_date) if from_date else None,
            to_date=str(to_date) if to_date else None,
            limit=limit,
            offset=offset,
        )
        logger.info(f"Found {len(rows)} workouts for user {user_id}")
        return [row_to_workout(row) for row in rows]

    except Exception as e:
        logger.error(f"Failed to list workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}", response_model=Workout)
async def get_workout(workout_id: str):
    """Get a workout by ID."""
    logger.debug(f"Fetching workout: id={workout_id}")
    try:
        db = get_supabase_db()
        row = db.get_workout(workout_id)

        if not row:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        return row_to_workout(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{workout_id}", response_model=Workout)
async def update_workout(workout_id: str, workout: WorkoutUpdate):
    """Update a workout."""
    logger.info(f"Updating workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found for update: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        update_data = {}
        if workout.name is not None:
            update_data["name"] = workout.name
        if workout.type is not None:
            update_data["type"] = workout.type
        if workout.difficulty is not None:
            update_data["difficulty"] = workout.difficulty
        if workout.scheduled_date is not None:
            update_data["scheduled_date"] = str(workout.scheduled_date)
        if workout.is_completed is not None:
            update_data["is_completed"] = workout.is_completed
        if workout.exercises_json is not None:
            exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json
            update_data["exercises"] = exercises
        if workout.last_modified_method is not None:
            update_data["last_modified_method"] = workout.last_modified_method

        if update_data:
            update_data["last_modified_at"] = datetime.now().isoformat()
            updated = db.update_workout(workout_id, update_data)
            logger.debug(f"Updated {len(update_data)} fields for workout {workout_id}")
        else:
            updated = existing

        # Log field changes
        current_workout = row_to_workout(existing)
        if workout.name is not None and workout.name != current_workout.name:
            log_workout_change(workout_id, current_workout.user_id, "updated", "name", current_workout.name, workout.name)
        if workout.exercises_json is not None:
            log_workout_change(workout_id, current_workout.user_id, "updated", "exercises", None, {"updated": True})

        updated_workout = row_to_workout(updated)
        logger.info(f"Workout updated: id={workout_id}")
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{workout_id}")
async def delete_workout(workout_id: str):
    """Delete a workout and all related records."""
    logger.info(f"Deleting workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found for deletion: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        # Delete related records first
        db.delete_workout_changes_by_workout(workout_id)
        db.delete_workout_logs_by_workout(workout_id)
        db.delete_workout(workout_id)

        logger.info(f"Workout deleted: id={workout_id}")
        return {"message": "Workout deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/complete", response_model=WorkoutCompletionResponse)
async def complete_workout(
    workout_id: str,
    background_tasks: BackgroundTasks,
):
    """
    Mark a workout as completed with PR detection and strength score updates.

    This endpoint:
    1. Marks the workout as completed
    2. Detects any new personal records from the workout exercises
    3. Saves PRs to the database with AI-generated celebration messages
    4. Triggers background recalculation of strength scores
    """
    logger.info(f"Completing workout: id={workout_id}")
    try:
        db = get_supabase_db()
        supabase = get_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        user_id = existing.get("user_id")

        # Mark workout as completed
        update_data = {
            "is_completed": True,
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "completed",
        }
        updated = db.update_workout(workout_id, update_data)
        workout = row_to_workout(updated)

        logger.info(f"Workout completed: id={workout_id}")

        log_workout_change(
            workout_id=workout_id,
            user_id=workout.user_id,
            change_type="completed",
            field_changed="is_completed",
            old_value=False,
            new_value=True,
            change_source="user"
        )

        # =====================================================================
        # PR Detection
        # =====================================================================
        detected_prs: List[PersonalRecordInfo] = []

        try:
            pr_service = PersonalRecordsService()

            # Get exercises from workout
            exercises = existing.get("exercises") or existing.get("exercises_json") or []
            if isinstance(exercises, str):
                exercises = json.loads(exercises)

            if exercises:
                # Get existing PRs for this user
                existing_prs_response = supabase.table("personal_records").select("*").eq(
                    "user_id", user_id
                ).execute()

                existing_prs_by_exercise: Dict[str, List[Dict]] = {}
                for pr in (existing_prs_response.data or []):
                    exercise_key = pr_service._normalize_exercise_name(pr.get("exercise_name", ""))
                    if exercise_key not in existing_prs_by_exercise:
                        existing_prs_by_exercise[exercise_key] = []
                    existing_prs_by_exercise[exercise_key].append(pr)

                # Format exercises for PR detection
                workout_exercises = []
                for ex in exercises:
                    sets = ex.get("sets", [])
                    if sets:
                        workout_exercises.append({
                            "exercise_name": ex.get("name", ""),
                            "exercise_id": ex.get("id") or ex.get("exercise_id"),
                            "workout_id": workout_id,
                            "sets": sets,
                        })

                # Detect PRs
                new_prs = pr_service.detect_prs_in_workout(
                    workout_exercises=workout_exercises,
                    existing_prs_by_exercise=existing_prs_by_exercise,
                )

                logger.info(f"Detected {len(new_prs)} PRs in workout {workout_id}")

                # Save PRs and generate AI celebrations
                for pr in new_prs:
                    # Generate AI celebration message
                    try:
                        ai_celebration = await ai_insights_service.generate_pr_celebration(
                            pr_data={
                                "exercise_name": pr.exercise_name,
                                "weight_kg": pr.weight_kg,
                                "reps": pr.reps,
                                "estimated_1rm_kg": pr.estimated_1rm_kg,
                                "previous_1rm_kg": pr.previous_1rm_kg,
                                "improvement_kg": pr.improvement_kg,
                                "improvement_percent": pr.improvement_percent,
                            },
                            user_profile={"id": user_id},
                        )
                    except Exception as e:
                        logger.warning(f"Failed to generate AI celebration: {e}")
                        ai_celebration = pr.celebration_message

                    # Save to database
                    pr_record = {
                        "user_id": user_id,
                        "exercise_name": pr.exercise_name,
                        "exercise_id": pr.exercise_id,
                        "muscle_group": pr.muscle_group,
                        "weight_kg": pr.weight_kg,
                        "reps": pr.reps,
                        "estimated_1rm_kg": pr.estimated_1rm_kg,
                        "set_type": pr.set_type,
                        "rpe": pr.rpe,
                        "achieved_at": datetime.now().isoformat(),
                        "workout_id": workout_id,
                        "previous_weight_kg": pr.previous_weight_kg,
                        "previous_1rm_kg": pr.previous_1rm_kg,
                        "improvement_kg": pr.improvement_kg,
                        "improvement_percent": pr.improvement_percent,
                        "is_all_time_pr": pr.is_all_time_pr,
                        "celebration_message": ai_celebration,
                    }

                    supabase.table("personal_records").insert(pr_record).execute()

                    detected_prs.append(PersonalRecordInfo(
                        exercise_name=pr.exercise_name,
                        weight_kg=pr.weight_kg,
                        reps=pr.reps,
                        estimated_1rm_kg=pr.estimated_1rm_kg,
                        previous_1rm_kg=pr.previous_1rm_kg,
                        improvement_kg=pr.improvement_kg,
                        improvement_percent=pr.improvement_percent,
                        is_all_time_pr=pr.is_all_time_pr,
                        celebration_message=ai_celebration,
                    ))

                logger.info(f"Saved {len(detected_prs)} PRs for workout {workout_id}")

        except Exception as e:
            logger.error(f"Error during PR detection: {e}")
            # Continue even if PR detection fails

        # =====================================================================
        # Background: Recalculate Strength Scores
        # =====================================================================
        background_tasks.add_task(
            recalculate_user_strength_scores,
            user_id=user_id,
            supabase=supabase,
        )

        await index_workout_to_rag(workout)

        # Build response message
        if detected_prs:
            pr_count = len(detected_prs)
            message = f"Workout completed! You set {pr_count} new personal record{'s' if pr_count > 1 else ''}!"
        else:
            message = "Workout completed successfully!"

        return WorkoutCompletionResponse(
            workout=workout,
            personal_records=detected_prs,
            strength_scores_updated=True,
            message=message,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def recalculate_user_strength_scores(user_id: str, supabase):
    """
    Background task to recalculate strength scores after workout completion.
    """
    try:
        logger.info(f"Background: Recalculating strength scores for user {user_id}")

        strength_service = StrengthCalculatorService()

        # Get user info
        user_response = supabase.table("users").select("weight_kg, gender").eq(
            "id", user_id
        ).maybe_single().execute()

        if not user_response.data:
            logger.warning(f"User not found for strength recalc: {user_id}")
            return

        user = user_response.data
        bodyweight = float(user.get("weight_kg", 70))
        gender = user.get("gender", "male")

        # Get workout data from last 90 days
        start_date = (date.today() - timedelta(days=90)).isoformat()

        workouts_response = supabase.table("workouts").select(
            "id, exercises, completed_at"
        ).eq(
            "user_id", user_id
        ).eq(
            "is_completed", True
        ).gte(
            "scheduled_date", start_date
        ).execute()

        # Extract exercise performances
        workout_data = []
        for workout in (workouts_response.data or []):
            exercises = workout.get("exercises", [])
            if isinstance(exercises, str):
                exercises = json.loads(exercises)
            for exercise in exercises:
                if isinstance(exercise, dict):
                    sets = exercise.get("sets", [])
                    if sets:
                        best_set = max(
                            (s for s in sets if s.get("completed", True)),
                            key=lambda s: float(s.get("weight_kg", 0)) * int(s.get("reps", 0)),
                            default=None,
                        )
                        if best_set:
                            workout_data.append({
                                "exercise_name": exercise.get("name", ""),
                                "weight_kg": float(best_set.get("weight_kg", 0)),
                                "reps": int(best_set.get("reps", 0)),
                                "sets": len(sets),
                            })

        # Calculate scores for all muscle groups
        muscle_scores = strength_service.calculate_all_muscle_scores(
            workout_data, bodyweight, gender
        )

        # Get previous scores for trend calculation
        previous_response = supabase.from_("latest_strength_scores").select(
            "muscle_group, strength_score"
        ).eq("user_id", user_id).execute()

        previous_scores = {
            r["muscle_group"]: r["strength_score"]
            for r in (previous_response.data or [])
        }

        # Save new scores
        now = datetime.now()
        period_end = date.today()
        period_start = period_end - timedelta(days=7)

        for mg, score in muscle_scores.items():
            prev_score = previous_scores.get(mg)

            # Determine trend
            if prev_score is not None:
                if score.strength_score > prev_score + 2:
                    trend = "improving"
                elif score.strength_score < prev_score - 2:
                    trend = "declining"
                else:
                    trend = "maintaining"
                score_change = score.strength_score - prev_score
            else:
                trend = "maintaining"
                score_change = None

            record_data = {
                "user_id": user_id,
                "muscle_group": mg,
                "strength_score": score.strength_score,
                "strength_level": score.strength_level.value,
                "best_exercise_name": score.best_exercise_name,
                "best_estimated_1rm_kg": score.best_estimated_1rm_kg,
                "bodyweight_ratio": score.bodyweight_ratio,
                "weekly_sets": score.weekly_sets,
                "weekly_volume_kg": score.weekly_volume_kg,
                "previous_score": prev_score,
                "score_change": score_change,
                "trend": trend,
                "calculated_at": now.isoformat(),
                "period_start": period_start.isoformat(),
                "period_end": period_end.isoformat(),
            }

            supabase.table("strength_scores").insert(record_data).execute()

        logger.info(f"Background: Updated strength scores for {len(muscle_scores)} muscle groups")

    except Exception as e:
        logger.error(f"Background: Failed to recalculate strength scores: {e}")
