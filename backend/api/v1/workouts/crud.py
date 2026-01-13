"""
Workout CRUD API endpoints.

This module handles basic create, read, update, delete operations for workouts:
- POST / - Create a new workout
- GET / - List workouts for a user
- GET /{id} - Get workout by ID
- PUT /{id} - Update workout
- DELETE /{id} - Delete workout
- POST /{id}/complete - Mark workout as completed (with PR detection & strength recalc)
- GET /{id}/comparison - Get performance comparison for a completed workout
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
from services.fitness_score_calculator_service import FitnessScoreCalculatorService
from services.nutrition_calculator_service import NutritionCalculatorService
from services.performance_comparison_service import PerformanceComparisonService
from services.user_context_service import user_context_service

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


class ExerciseComparisonInfo(BaseModel):
    """Comparison data for a single exercise vs previous session."""
    exercise_name: str
    exercise_id: Optional[str] = None

    # Current session
    current_sets: int = 0
    current_reps: int = 0
    current_volume_kg: float = 0.0
    current_max_weight_kg: Optional[float] = None
    current_1rm_kg: Optional[float] = None
    current_time_seconds: Optional[int] = None

    # Previous session
    previous_sets: Optional[int] = None
    previous_reps: Optional[int] = None
    previous_volume_kg: Optional[float] = None
    previous_max_weight_kg: Optional[float] = None
    previous_1rm_kg: Optional[float] = None
    previous_time_seconds: Optional[int] = None
    previous_date: Optional[datetime] = None

    # Differences
    volume_diff_kg: Optional[float] = None
    volume_diff_percent: Optional[float] = None
    weight_diff_kg: Optional[float] = None
    weight_diff_percent: Optional[float] = None
    rm_diff_kg: Optional[float] = None
    rm_diff_percent: Optional[float] = None
    time_diff_seconds: Optional[int] = None
    time_diff_percent: Optional[float] = None
    reps_diff: Optional[int] = None
    sets_diff: Optional[int] = None

    # Status: 'improved', 'maintained', 'declined', 'first_time'
    status: str = 'first_time'


class WorkoutComparisonInfo(BaseModel):
    """Comparison data for overall workout vs previous similar workout."""
    # Current workout
    current_duration_seconds: int = 0
    current_total_volume_kg: float = 0.0
    current_total_sets: int = 0
    current_total_reps: int = 0
    current_exercises: int = 0
    current_calories: int = 0

    # Previous workout
    has_previous: bool = False
    previous_duration_seconds: Optional[int] = None
    previous_total_volume_kg: Optional[float] = None
    previous_total_sets: Optional[int] = None
    previous_total_reps: Optional[int] = None
    previous_performed_at: Optional[datetime] = None

    # Differences
    duration_diff_seconds: Optional[int] = None
    duration_diff_percent: Optional[float] = None
    volume_diff_kg: Optional[float] = None
    volume_diff_percent: Optional[float] = None

    # Overall status
    overall_status: str = 'first_time'


class PerformanceComparisonInfo(BaseModel):
    """Complete performance comparison for workout completion."""
    workout_comparison: WorkoutComparisonInfo
    exercise_comparisons: List[ExerciseComparisonInfo] = []
    improved_count: int = 0
    maintained_count: int = 0
    declined_count: int = 0
    first_time_count: int = 0


class WorkoutCompletionResponse(BaseModel):
    """Extended response for workout completion including PRs and performance comparison."""
    workout: Workout
    personal_records: List[PersonalRecordInfo] = []
    performance_comparison: Optional[PerformanceComparisonInfo] = None
    strength_scores_updated: bool = False
    fitness_score_updated: bool = False
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


@router.delete("/cleanup/{user_id}")
async def cleanup_old_workouts(
    user_id: str,
    keep_count: int = Query(default=1, ge=1, le=10, description="Number of future workouts to keep")
):
    """
    Clean up old workouts for a user, keeping only the specified number of upcoming workouts.

    This is useful after migrating from batch generation to JIT (one-at-a-time) generation.
    Keeps incomplete workouts scheduled for today or later (up to keep_count).
    All other workouts are deleted.

    Args:
        user_id: The user ID
        keep_count: Number of future/current workouts to keep (default: 1)

    Returns:
        Summary of cleanup operation
    """
    logger.info(f"[Cleanup] Starting cleanup for user {user_id}, keeping {keep_count} workout(s)")

    try:
        db = get_supabase_db()

        # Get all workouts for user
        today = date.today().isoformat()
        all_workouts = db.client.table("workouts") \
            .select("id, scheduled_date, is_completed, name") \
            .eq("user_id", user_id) \
            .order("scheduled_date", desc=True) \
            .execute()

        if not all_workouts.data:
            logger.info(f"[Cleanup] No workouts found for user {user_id}")
            return {"message": "No workouts to clean up", "deleted_count": 0}

        # Separate completed from incomplete workouts
        completed = []
        incomplete_future = []
        incomplete_past = []

        for w in all_workouts.data:
            sched = w.get("scheduled_date", "")[:10] if w.get("scheduled_date") else ""
            if w.get("is_completed"):
                completed.append(w)
            elif sched >= today:
                incomplete_future.append(w)
            else:
                incomplete_past.append(w)

        # Sort incomplete future by date ascending (earliest first)
        incomplete_future.sort(key=lambda x: x.get("scheduled_date", ""))

        # Keep only the first keep_count incomplete future workouts
        workouts_to_keep = incomplete_future[:keep_count]
        workouts_to_delete = incomplete_future[keep_count:] + incomplete_past

        # Keep IDs of workouts we're keeping (completed ones are always kept)
        keep_ids = {w["id"] for w in workouts_to_keep} | {w["id"] for w in completed}

        deleted_count = 0
        deleted_names = []

        for workout in workouts_to_delete:
            workout_id = workout["id"]
            try:
                # Delete related records first
                db.delete_workout_changes_by_workout(workout_id)
                db.delete_workout_logs_by_workout(workout_id)
                db.delete_workout(workout_id)
                deleted_count += 1
                deleted_names.append(workout.get("name", "Unknown"))
                logger.info(f"[Cleanup] Deleted workout: {workout.get('name')} ({workout_id})")
            except Exception as e:
                logger.error(f"[Cleanup] Failed to delete workout {workout_id}: {e}")

        logger.info(f"[Cleanup] Completed for user {user_id}: deleted {deleted_count}, kept {len(workouts_to_keep)} upcoming + {len(completed)} completed")

        return {
            "message": f"Cleanup complete. Deleted {deleted_count} workout(s).",
            "deleted_count": deleted_count,
            "deleted_names": deleted_names[:10],  # Return first 10 names
            "kept_upcoming": len(workouts_to_keep),
            "kept_completed": len(completed),
        }

    except Exception as e:
        logger.error(f"[Cleanup] Failed: {e}")
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
        supabase = get_db().client  # Use .client to get the Supabase client with .table() method

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        user_id = existing.get("user_id")

        # Mark workout as completed with timestamp
        from datetime import timezone
        now = datetime.now(timezone.utc)
        update_data = {
            "is_completed": True,
            "completed_at": now.isoformat(),
            "last_modified_at": now.isoformat(),
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
        # Background: Populate performance_logs for efficient history queries
        # =====================================================================
        # Get workout_log_id for this workout (needed for performance_logs)
        workout_log_response = supabase.table("workout_logs").select(
            "id"
        ).eq("workout_id", workout_id).order("completed_at", desc=True).limit(1).execute()

        if workout_log_response.data:
            perf_log_workout_log_id = workout_log_response.data[0].get("id")
            background_tasks.add_task(
                populate_performance_logs,
                user_id=user_id,
                workout_id=workout_id,
                workout_log_id=perf_log_workout_log_id,
                exercises=exercises,
                supabase=supabase,
            )

        # =====================================================================
        # Background: Recalculate Strength Scores and Fitness Score
        # =====================================================================
        background_tasks.add_task(
            recalculate_user_strength_scores,
            user_id=user_id,
            supabase=supabase,
        )

        # Also recalculate the overall fitness score
        background_tasks.add_task(
            recalculate_user_fitness_score,
            user_id=user_id,
            supabase=supabase,
        )

        # =====================================================================
        # Generate Next Workout (one-at-a-time generation)
        # =====================================================================
        # Instead of batch-generating 2 weeks of workouts, we generate just
        # the next workout after each completion. This provides immediate
        # feedback and workouts appear one-by-one in the Upcoming section.
        background_tasks.add_task(
            _generate_next_workout_for_user,
            user_id=user_id,
        )

        await index_workout_to_rag(workout)

        # =====================================================================
        # Performance Comparison - Track improvements/setbacks vs previous session
        # =====================================================================
        performance_comparison: Optional[PerformanceComparisonInfo] = None

        try:
            comparison_service = PerformanceComparisonService()

            # Build workout stats from the completed workout
            total_volume = 0.0
            total_sets = 0
            total_reps = 0

            exercises = existing.get("exercises") or existing.get("exercises_json") or []
            if isinstance(exercises, str):
                exercises = json.loads(exercises)

            exercises_performance = []
            for ex in exercises:
                sets = ex.get("sets", [])
                # Handle case where sets is an integer count instead of a list
                if isinstance(sets, int) or not isinstance(sets, list):
                    sets = []
                completed_sets = [s for s in sets if s.get("completed", True)]
                ex_volume = sum(
                    (s.get("reps", 0) or s.get("reps_completed", 0)) * s.get("weight_kg", 0)
                    for s in completed_sets
                )
                ex_reps = sum(s.get("reps", 0) or s.get("reps_completed", 0) for s in completed_sets)
                total_volume += ex_volume
                total_sets += len(completed_sets)
                total_reps += ex_reps

                exercises_performance.append({
                    "exercise_name": ex.get("name", ""),
                    "exercise_id": ex.get("id") or ex.get("exercise_id"),
                    "sets": sets,
                })

            # Get workout log for this workout (if exists)
            workout_log_response = supabase.table("workout_logs").select(
                "id, total_time_seconds"
            ).eq("workout_id", workout_id).order("completed_at", desc=True).limit(1).execute()

            workout_log_id = None
            duration_seconds = 0
            if workout_log_response.data:
                workout_log_id = workout_log_response.data[0].get("id")
                duration_seconds = workout_log_response.data[0].get("total_time_seconds", 0)

            # Build current workout stats
            workout_stats = {
                "workout_name": workout.name,
                "workout_type": workout.type,
                "total_sets": total_sets,
                "total_reps": total_reps,
                "total_volume_kg": total_volume,
                "duration_seconds": duration_seconds,
                "calories": 0,  # Will be calculated from duration
                "new_prs_count": len(detected_prs),
                "completed_at": datetime.now(),
            }

            # Build and store performance summaries
            if workout_log_id:
                workout_summary, exercise_summaries = comparison_service.build_performance_summary(
                    workout_log_id=workout_log_id,
                    user_id=user_id,
                    workout_id=workout_id,
                    exercises_performance=exercises_performance,
                    workout_stats=workout_stats,
                )

                # Store workout performance summary
                try:
                    supabase.table("workout_performance_summary").upsert(
                        workout_summary,
                        on_conflict="workout_log_id"
                    ).execute()
                except Exception as e:
                    logger.warning(f"Failed to store workout summary: {e}")

                # Store exercise performance summaries
                for ex_summary in exercise_summaries:
                    try:
                        supabase.table("exercise_performance_summary").upsert(
                            ex_summary,
                            on_conflict="workout_log_id,exercise_name"
                        ).execute()
                    except Exception as e:
                        logger.warning(f"Failed to store exercise summary: {e}")

            # Calculate comparisons for each exercise
            exercise_comparisons: List[ExerciseComparisonInfo] = []

            for ex_perf in exercises_performance:
                ex_name = ex_perf.get("exercise_name", "")
                if not ex_name:
                    continue

                # Get previous performance for this exercise
                prev_response = supabase.rpc(
                    "get_previous_exercise_performance",
                    {
                        "p_user_id": user_id,
                        "p_exercise_name": ex_name,
                        "p_current_workout_log_id": workout_log_id,
                        "p_limit": 1,
                    }
                ).execute()

                previous_performances = prev_response.data if prev_response.data else []

                # Build current performance dict
                sets = ex_perf.get("sets", [])
                completed_sets = [s for s in sets if s.get("completed", True)]
                weights = [s.get("weight_kg", 0) for s in completed_sets if s.get("weight_kg", 0) > 0]
                reps_list = [s.get("reps", 0) or s.get("reps_completed", 0) for s in completed_sets]

                current_perf = {
                    "exercise_id": ex_perf.get("exercise_id"),
                    "total_sets": len(completed_sets),
                    "total_reps": sum(reps_list),
                    "total_volume_kg": sum(r * w for r, w in zip(reps_list, weights) if w > 0),
                    "max_weight_kg": max(weights) if weights else None,
                    "estimated_1rm_kg": None,  # Will be calculated
                }

                # Calculate 1RM
                if completed_sets:
                    best_1rm = 0
                    for s in completed_sets:
                        reps = s.get("reps", 0) or s.get("reps_completed", 0)
                        weight = s.get("weight_kg", 0)
                        if weight > 0 and 0 < reps < 37:
                            set_1rm = weight * (36 / (37 - reps))
                            best_1rm = max(best_1rm, set_1rm)
                    if best_1rm > 0:
                        current_perf["estimated_1rm_kg"] = round(best_1rm, 2)

                comparison = comparison_service.compute_exercise_comparison(
                    exercise_name=ex_name,
                    current_performance=current_perf,
                    previous_performances=previous_performances,
                )

                # Check if this exercise has a PR
                comparison.is_pr = any(
                    pr.exercise_name.lower() == ex_name.lower()
                    for pr in detected_prs
                )

                exercise_comparisons.append(ExerciseComparisonInfo(
                    exercise_name=comparison.exercise_name,
                    exercise_id=comparison.exercise_id,
                    current_sets=comparison.current_sets,
                    current_reps=comparison.current_reps,
                    current_volume_kg=comparison.current_volume_kg,
                    current_max_weight_kg=comparison.current_max_weight_kg,
                    current_1rm_kg=comparison.current_1rm_kg,
                    current_time_seconds=comparison.current_time_seconds,
                    previous_sets=comparison.previous_sets,
                    previous_reps=comparison.previous_reps,
                    previous_volume_kg=comparison.previous_volume_kg,
                    previous_max_weight_kg=comparison.previous_max_weight_kg,
                    previous_1rm_kg=comparison.previous_1rm_kg,
                    previous_time_seconds=comparison.previous_time_seconds,
                    previous_date=comparison.previous_date,
                    volume_diff_kg=comparison.volume_diff_kg,
                    volume_diff_percent=comparison.volume_diff_percent,
                    weight_diff_kg=comparison.weight_diff_kg,
                    weight_diff_percent=comparison.weight_diff_percent,
                    rm_diff_kg=comparison.rm_diff_kg,
                    rm_diff_percent=comparison.rm_diff_percent,
                    time_diff_seconds=comparison.time_diff_seconds,
                    time_diff_percent=comparison.time_diff_percent,
                    reps_diff=comparison.reps_diff,
                    sets_diff=comparison.sets_diff,
                    status=comparison.status,
                ))

            # Count statuses
            improved_count = sum(1 for e in exercise_comparisons if e.status == 'improved')
            maintained_count = sum(1 for e in exercise_comparisons if e.status == 'maintained')
            declined_count = sum(1 for e in exercise_comparisons if e.status == 'declined')
            first_time_count = sum(1 for e in exercise_comparisons if e.status == 'first_time')

            # Get previous workout for overall comparison
            if workout_log_id:
                prev_workout_response = supabase.table("workout_performance_summary").select(
                    "*"
                ).eq("user_id", user_id).neq(
                    "workout_log_id", workout_log_id
                ).order("performed_at", desc=True).limit(1).execute()
                prev_workout_stats = prev_workout_response.data[0] if prev_workout_response.data else None
            else:
                # No current workout log to exclude, just get the most recent
                prev_workout_response = supabase.table("workout_performance_summary").select(
                    "*"
                ).eq("user_id", user_id).order("performed_at", desc=True).limit(1).execute()
                prev_workout_stats = prev_workout_response.data[0] if prev_workout_response.data else None

            workout_comparison = comparison_service.compute_workout_comparison(
                current_stats=workout_stats,
                previous_stats=prev_workout_stats,
            )

            performance_comparison = PerformanceComparisonInfo(
                workout_comparison=WorkoutComparisonInfo(
                    current_duration_seconds=workout_comparison.current_duration_seconds,
                    current_total_volume_kg=workout_comparison.current_total_volume_kg,
                    current_total_sets=workout_comparison.current_total_sets,
                    current_total_reps=workout_comparison.current_total_reps,
                    current_exercises=workout_comparison.current_exercises,
                    current_calories=workout_comparison.current_calories,
                    has_previous=workout_comparison.has_previous,
                    previous_duration_seconds=workout_comparison.previous_duration_seconds,
                    previous_total_volume_kg=workout_comparison.previous_total_volume_kg,
                    previous_total_sets=workout_comparison.previous_total_sets,
                    previous_total_reps=workout_comparison.previous_total_reps,
                    previous_performed_at=workout_comparison.previous_performed_at,
                    duration_diff_seconds=workout_comparison.duration_diff_seconds,
                    duration_diff_percent=workout_comparison.duration_diff_percent,
                    volume_diff_kg=workout_comparison.volume_diff_kg,
                    volume_diff_percent=workout_comparison.volume_diff_percent,
                    overall_status=workout_comparison.overall_status,
                ),
                exercise_comparisons=exercise_comparisons,
                improved_count=improved_count,
                maintained_count=maintained_count,
                declined_count=declined_count,
                first_time_count=first_time_count,
            )

            logger.info(f"Performance comparison: {improved_count} improved, {declined_count} declined, {maintained_count} maintained")

            # Log performance comparison view for analytics
            try:
                await user_context_service.log_performance_comparison_viewed(
                    user_id=user_id,
                    workout_id=str(workout_id),
                    workout_log_id=workout_log_id or "",
                    improved_count=improved_count,
                    declined_count=declined_count,
                    first_time_count=first_time_count,
                    exercises_compared=len(exercise_comparisons),
                    duration_diff_seconds=workout_comparison.duration_diff_seconds,
                    volume_diff_percentage=workout_comparison.volume_diff_percent,
                )
            except Exception as log_error:
                logger.warning(f"Failed to log performance comparison view: {log_error}")
                # Non-critical, continue

        except Exception as e:
            logger.error(f"Error calculating performance comparison: {e}")
            # Continue even if comparison fails

        # Build response message
        if detected_prs:
            pr_count = len(detected_prs)
            message = f"Workout completed! You set {pr_count} new personal record{'s' if pr_count > 1 else ''}!"
        else:
            message = "Workout completed successfully!"

        return WorkoutCompletionResponse(
            workout=workout,
            personal_records=detected_prs,
            performance_comparison=performance_comparison,
            strength_scores_updated=True,
            fitness_score_updated=True,
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
            "id, exercises_json, completed_at"
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
            exercises = workout.get("exercises_json", [])
            if isinstance(exercises, str):
                exercises = json.loads(exercises)
            for exercise in exercises:
                if isinstance(exercise, dict):
                    sets = exercise.get("sets", [])
                    # Handle case where sets is an integer count instead of a list
                    if isinstance(sets, int) or not isinstance(sets, list):
                        continue
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


async def recalculate_user_fitness_score(user_id: str, supabase):
    """
    Background task to recalculate overall fitness score after workout completion.

    The fitness score combines:
    - Strength score (40%)
    - Consistency score (30%)
    - Nutrition score (20%)
    - Readiness score (10%)
    """
    try:
        logger.info(f"Background: Recalculating fitness score for user {user_id}")

        fitness_service = FitnessScoreCalculatorService()
        strength_service = StrengthCalculatorService()
        nutrition_service = NutritionCalculatorService()

        # 1. Get strength score (overall)
        strength_response = supabase.from_("latest_strength_scores").select(
            "muscle_group, strength_score"
        ).eq("user_id", user_id).execute()

        if strength_response.data:
            score_objects = {
                r["muscle_group"]: type('obj', (object,), {'strength_score': r["strength_score"] or 0})()
                for r in strength_response.data
            }
            strength_score, _ = strength_service.calculate_overall_strength_score(score_objects)
        else:
            strength_score = 0

        # 2. Get consistency score (workout completion rate for last 30 days)
        thirty_days_ago = (date.today() - timedelta(days=30)).isoformat()

        # Count scheduled workouts
        scheduled_response = supabase.table("workouts").select(
            "id", count="exact"
        ).eq(
            "user_id", user_id
        ).gte(
            "scheduled_date", thirty_days_ago
        ).execute()
        scheduled_count = scheduled_response.count or 0

        # Count completed workouts
        completed_response = supabase.table("workouts").select(
            "id", count="exact"
        ).eq(
            "user_id", user_id
        ).eq(
            "is_completed", True
        ).gte(
            "scheduled_date", thirty_days_ago
        ).execute()
        completed_count = completed_response.count or 0

        consistency_score = fitness_service.calculate_consistency_score(
            scheduled=scheduled_count,
            completed=completed_count,
        )

        # 3. Get nutrition score (current week)
        week_start, week_end = nutrition_service.get_current_week_range()

        nutrition_response = supabase.table("nutrition_scores").select(
            "nutrition_score"
        ).eq(
            "user_id", user_id
        ).eq(
            "week_start", week_start.isoformat()
        ).maybe_single().execute()

        nutrition_score = nutrition_response.data.get("nutrition_score", 0) if nutrition_response and nutrition_response.data else 0

        # 4. Get readiness score (7-day average)
        seven_days_ago = (date.today() - timedelta(days=7)).isoformat()
        readiness_response = supabase.table("readiness_scores").select(
            "readiness_score"
        ).eq(
            "user_id", user_id
        ).gte(
            "score_date", seven_days_ago
        ).execute()

        readiness_scores = [r["readiness_score"] for r in (readiness_response.data or [])]
        readiness_score = round(sum(readiness_scores) / len(readiness_scores)) if readiness_scores else 50

        # 5. Get previous fitness score
        previous_response = supabase.table("fitness_scores").select(
            "overall_fitness_score"
        ).eq(
            "user_id", user_id
        ).order(
            "calculated_at", desc=True
        ).limit(1).maybe_single().execute()

        previous_score = previous_response.data.get("overall_fitness_score") if previous_response and previous_response.data else None

        # 6. Calculate overall fitness score
        score = fitness_service.calculate_fitness_score(
            user_id=user_id,
            strength_score=strength_score,
            readiness_score=readiness_score,
            consistency_score=consistency_score,
            nutrition_score=nutrition_score,
            previous_score=previous_score,
        )

        # 7. Save to database
        record_data = {
            "user_id": user_id,
            "calculated_date": date.today().isoformat(),
            "strength_score": score.strength_score,
            "readiness_score": score.readiness_score,
            "consistency_score": score.consistency_score,
            "nutrition_score": score.nutrition_score,
            "overall_fitness_score": score.overall_fitness_score,
            "fitness_level": score.fitness_level.value,
            "strength_weight": score.strength_weight,
            "consistency_weight": score.consistency_weight,
            "nutrition_weight": score.nutrition_weight,
            "readiness_weight": score.readiness_weight,
            "focus_recommendation": score.focus_recommendation,
            "previous_score": score.previous_score,
            "score_change": score.score_change,
            "trend": score.trend,
            "calculated_at": datetime.now().isoformat(),
        }

        supabase.table("fitness_scores").insert(record_data).execute()

        logger.info(f"Background: Updated fitness score for user {user_id}: {score.overall_fitness_score} ({score.fitness_level.value})")

    except Exception as e:
        logger.error(f"Background: Failed to recalculate fitness score: {e}")


async def _generate_next_workout_for_user(user_id: str, retry_count: int = 0):
    """
    Background task to generate the next single workout for a user.

    Called after workout completion to enable one-at-a-time (JIT) workout generation.
    This ensures workouts appear one-by-one in the Upcoming section instead of
    batch-generating 2 weeks of workouts all at once.

    Key principle: A workout should ALWAYS exist for the user. After completing
    today's workout, the next workout day's workout is immediately generated.

    Args:
        user_id: The user's ID
        retry_count: Number of retry attempts (max 2)
    """
    import traceback

    try:
        logger.info(f"[JIT Generation] Starting next workout generation for user {user_id} (attempt {retry_count + 1})")

        # Import here to avoid circular dependency
        from .background import generate_next_workout
        from fastapi import BackgroundTasks

        # Create a BackgroundTasks instance for the endpoint
        background_tasks = BackgroundTasks()

        # Call the generate-next endpoint logic
        result = await generate_next_workout(user_id, background_tasks)

        # Log the result with context
        if result.get("needs_generation"):
            logger.info(f"[JIT Generation] Scheduled generation for user {user_id}: job_id={result.get('job_id')}, next_date={result.get('next_workout_date')}")
        elif result.get("already_generating"):
            logger.info(f"[JIT Generation] Already generating for user {user_id}: job_id={result.get('job_id')}")
        elif not result.get("needs_generation") and result.get("success"):
            logger.info(f"[JIT Generation] Workout already exists for user {user_id} on {result.get('next_workout_date')}")
        else:
            logger.warning(f"[JIT Generation] Unexpected result for user {user_id}: {result}")

        # Execute any scheduled background tasks
        for task in background_tasks.tasks:
            await task()

        logger.info(f"[JIT Generation] Completed for user {user_id}: {result}")

    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"[JIT Generation] Failed for user {user_id}: {e}\n{error_trace}")

        # Retry up to 2 times with exponential backoff
        if retry_count < 2:
            import asyncio
            wait_time = (retry_count + 1) * 5  # 5s, 10s
            logger.info(f"[JIT Generation] Retrying in {wait_time}s for user {user_id} (attempt {retry_count + 2})")
            await asyncio.sleep(wait_time)
            await _generate_next_workout_for_user(user_id, retry_count + 1)
        else:
            logger.error(f"[JIT Generation] All retries exhausted for user {user_id}. User may need to manually generate.")


async def populate_performance_logs(
    user_id: str,
    workout_id: str,
    workout_log_id: str,
    exercises: List[Dict],
    supabase,
):
    """
    Background task to populate performance_logs table with individual set data.

    This enables efficient exercise history queries for AI weight suggestions
    instead of parsing large JSON blobs from workout_logs.

    Args:
        user_id: The user's ID
        workout_id: The workout's ID
        workout_log_id: The workout_log's ID
        exercises: List of exercise dicts with sets data
        supabase: Supabase client
    """
    try:
        logger.info(f"Background: Populating performance_logs for workout_log {workout_log_id}")

        records_to_insert = []
        recorded_at = datetime.now().isoformat()

        for exercise in exercises:
            exercise_name = exercise.get("name", "")
            exercise_id = exercise.get("id") or exercise.get("exercise_id") or exercise.get("libraryId", "")

            if not exercise_name:
                continue

            # Get AI-recommended set type info from exercise definition
            # These fields are set by Gemini during workout generation
            ai_recommended_drop_set = exercise.get("is_drop_set", False)
            ai_recommended_failure_set = exercise.get("is_failure_set", False)
            total_sets_count = len(exercise.get("sets", []))

            sets = exercise.get("sets", [])

            for set_data in sets:
                # Only log completed sets
                if not set_data.get("completed", True):
                    continue

                set_number = set_data.get("set_number", 1)
                reps_completed = set_data.get("reps_completed") or set_data.get("reps", 0)
                weight_kg = set_data.get("weight_kg") or set_data.get("weight", 0)
                rpe = set_data.get("rpe")
                rir = set_data.get("rir")
                set_type = set_data.get("set_type", "working")
                tempo = set_data.get("tempo")
                is_completed = set_data.get("completed", True)
                failed_at_rep = set_data.get("failed_at_rep")
                notes = set_data.get("notes")

                # Skip sets with no meaningful data
                if reps_completed <= 0 and weight_kg <= 0:
                    continue

                # Determine if this set type was AI-recommended
                # AI recommends: drop_set for is_drop_set exercises, failure for is_failure_set on final set
                is_ai_recommended = False
                if set_type == "drop_set" and ai_recommended_drop_set:
                    is_ai_recommended = True
                elif set_type == "failure" and ai_recommended_failure_set and set_number == total_sets_count:
                    # Failure sets are typically recommended for the final set only
                    is_ai_recommended = True
                elif set_type == "amrap" and ai_recommended_failure_set and set_number == total_sets_count:
                    # AMRAP is another form of failure set
                    is_ai_recommended = True
                elif set_type == "working" and not ai_recommended_drop_set and not ai_recommended_failure_set:
                    # If AI didn't recommend special sets and user did working sets, that's following AI
                    is_ai_recommended = True
                elif set_type == "warmup":
                    # Warmup sets are user-selected, not AI-recommended (AI doesn't specifically recommend warmups)
                    is_ai_recommended = False

                record = {
                    "workout_log_id": workout_log_id,
                    "user_id": user_id,
                    "exercise_id": str(exercise_id) if exercise_id else exercise_name.lower().replace(" ", "_"),
                    "exercise_name": exercise_name,
                    "set_number": set_number,
                    "reps_completed": reps_completed,
                    "weight_kg": float(weight_kg) if weight_kg else 0.0,
                    "rpe": float(rpe) if rpe is not None else None,
                    "rir": int(rir) if rir is not None else None,
                    "set_type": set_type,
                    "is_ai_recommended_set_type": is_ai_recommended,
                    "tempo": tempo,
                    "is_completed": is_completed,
                    "failed_at_rep": failed_at_rep,
                    "notes": notes,
                    "recorded_at": recorded_at,
                }

                records_to_insert.append(record)

        if records_to_insert:
            # Batch insert all records
            supabase.table("performance_logs").insert(records_to_insert).execute()
            logger.info(f"Background: Inserted {len(records_to_insert)} performance_log records for workout_log {workout_log_id}")
        else:
            logger.info(f"Background: No performance_log records to insert for workout_log {workout_log_id}")

    except Exception as e:
        logger.error(f"Background: Failed to populate performance_logs for workout_log {workout_log_id}: {e}")
