"""
Workout versioning (SCD2), regeneration, revert, summary, warmup/stretch,
program customization, and generation-params endpoints.

Sub-router included by workouts_db.py main router.
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List
from datetime import datetime
import json
import time

from core.logger import get_logger
from core.rate_limiter import limiter
from core.timezone_utils import resolve_timezone
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import (
    Workout, RegenerateWorkoutRequest, RevertWorkoutRequest,
    WorkoutVersionInfo, UpdateProgramRequest, UpdateProgramResponse,
)
from services.gemini_service import GeminiService
from services.exercise_rag_service import get_exercise_rag_service
from services.warmup_stretch_service import get_warmup_stretch_service
from services.langgraph_agents.workout_insights.graph import generate_workout_insights

from .workouts_db_helpers import (
    ensure_workout_data_dict,
    normalize_goals_list,
    parse_json_field,
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    get_workout_rag_service,
    build_exercise_reasoning,
    build_workout_reasoning,
)

router = APIRouter()
logger = get_logger(__name__)


async def _background_index_rag(workout: Workout):
    """Background task: Index workout to RAG (non-critical)."""
    try:
        await index_workout_to_rag(workout)
    except Exception as e:
        logger.warning(f"Background: Failed to index workout to RAG: {e}", exc_info=True)


@router.post("/regenerate", response_model=Workout)
@limiter.limit("5/minute")
async def regenerate_workout(request: Request, body: RegenerateWorkoutRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Regenerate a workout with new settings while preserving version history (SCD2).

    This endpoint:
    1. Gets the existing workout
    2. Generates a new workout using AI based on provided settings
    3. Creates a new version, marking the old one as superseded
    4. Returns the new version
    """
    logger.info(f"Regenerating workout {body.workout_id} for user {body.user_id}")

    try:
        db = get_supabase_db()

        existing = db.get_workout(body.workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        user = db.get_user(body.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = body.fitness_level or user.get("fitness_level") or "intermediate"
        equipment = body.equipment if body.equipment is not None else parse_json_field(user.get("equipment"), [])
        goals = normalize_goals_list(user.get("goals"))
        preferences = parse_json_field(user.get("preferences"), {})
        dumbbell_count = body.dumbbell_count if body.dumbbell_count is not None else preferences.get("dumbbell_count", 2)
        kettlebell_count = body.kettlebell_count if body.kettlebell_count is not None else preferences.get("kettlebell_count", 1)

        user_age = user.get("age")
        user_activity_level = user.get("activity_level")
        user_dob = user.get("date_of_birth")
        user_difficulty = body.difficulty

        injuries = body.injuries or []
        if not injuries:
            user_injuries = parse_json_field(user.get("active_injuries"), [])
            if user_injuries:
                injuries = user_injuries

        if injuries:
            logger.info(f"Regenerating workout avoiding exercises for injuries: {injuries}")

        workout_type_override = body.workout_type
        if workout_type_override:
            logger.info(f"Regenerating with workout type override: {workout_type_override}")

        focus_areas = body.focus_areas or []

        logger.info(f"Regenerating workout with: fitness_level={fitness_level}, equipment={equipment}, "
                     f"dumbbell_count={dumbbell_count}, kettlebell_count={kettlebell_count}, "
                     f"difficulty={user_difficulty}, workout_type={workout_type_override}, "
                     f"duration_minutes={body.duration_minutes}, injuries={injuries}, focus_areas={focus_areas}")

        gemini_service = GeminiService()
        exercise_rag = get_exercise_rag_service()
        if not focus_areas:
            existing_exercises = parse_json_field(existing.get("exercises_json") or existing.get("exercises"), [])
            if existing_exercises:
                target_muscles = set()
                for ex in existing_exercises:
                    if isinstance(ex, dict) and ex.get("target_muscles"):
                        muscles = ex.get("target_muscles")
                        if isinstance(muscles, list):
                            target_muscles.update(muscles)
                        elif isinstance(muscles, str):
                            target_muscles.add(muscles)
                if target_muscles:
                    focus_areas = list(target_muscles)[:2]

        focus_area = focus_areas[0] if focus_areas else "full_body"

        target_duration = body.duration_minutes or 45
        exercise_count = max(3, min(10, target_duration // 7))
        logger.info(f"Target duration: {target_duration} mins -> {exercise_count} exercises")

        try:
            rag_exercises = await exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=equipment if isinstance(equipment, list) else [],
                fitness_level=fitness_level,
                goals=goals if isinstance(goals, list) else [],
                count=exercise_count,
                avoid_exercises=[],
                injuries=injuries if injuries else None,
                dumbbell_count=dumbbell_count,
                kettlebell_count=kettlebell_count,
            )

            if rag_exercises:
                logger.info(f"RAG selected {len(rag_exercises)} exercises for regeneration")
                workout_data = await gemini_service.generate_workout_from_library(
                    exercises=rag_exercises,
                    fitness_level=fitness_level,
                    goals=goals if isinstance(goals, list) else [],
                    duration_minutes=body.duration_minutes or 45,
                    focus_areas=focus_areas if focus_areas else [focus_area],
                    age=user_age,
                    activity_level=user_activity_level,
                    user_dob=user_dob,
                )
            else:
                logger.error("RAG returned no exercises for regeneration")
                raise ValueError(f"RAG returned no exercises for focus_area={focus_area}")

            exercises = workout_data.get("exercises", [])
            workout_name = body.workout_name or workout_data.get("name", "Regenerated Workout")
            workout_type = workout_type_override or workout_data.get("type", existing.get("type", "strength"))
            difficulty = user_difficulty or workout_data.get("difficulty", "medium")

        except Exception as ai_error:
            logger.error(f"AI workout regeneration failed: {ai_error}", exc_info=True)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate new workout: {str(ai_error)}"
            )

        used_rag = rag_exercises is not None and len(rag_exercises) > 0

        new_workout_data = {
            "user_id": body.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": existing.get("scheduled_date"),
            "exercises_json": exercises,
            "duration_minutes": body.duration_minutes or 45,
            "equipment": json.dumps(equipment) if equipment else "[]",
            "is_completed": False,
            "generation_method": "rag_regenerate" if used_rag else "ai_regenerate",
            "generation_source": "regenerate_endpoint",
            "generation_metadata": json.dumps({
                "regenerated_from": body.workout_id,
                "previous_version": existing.get("version_number", 1),
                "fitness_level": fitness_level,
                "equipment": equipment,
                "difficulty": difficulty,
                "workout_type": workout_type,
                "workout_type_override": workout_type_override,
                "used_rag": used_rag,
                "focus_area": focus_area,
                "injuries_considered": injuries if injuries else [],
            }),
        }

        new_workout = db.supersede_workout(body.workout_id, new_workout_data)
        logger.info(f"Workout regenerated: old_id={body.workout_id}, new_id={new_workout['id']}, version={new_workout.get('version_number')}")

        log_workout_change(
            workout_id=new_workout["id"],
            user_id=body.user_id,
            change_type="regenerated",
            change_source="regenerate_endpoint",
            new_value={
                "name": workout_name,
                "exercises_count": len(exercises),
                "previous_workout_id": body.workout_id
            }
        )

        regenerated = row_to_workout(new_workout)
        background_tasks.add_task(_background_index_rag, regenerated)

        async def _bg_record_regeneration_analytics():
            try:
                predefined_focus_areas = [
                    "full_body", "upper_body", "lower_body", "core", "back", "chest",
                    "shoulders", "arms", "legs", "glutes", "cardio", "flexibility"
                ]
                custom_focus_area = None
                if focus_areas:
                    for fa in focus_areas:
                        if fa and fa.lower() not in [p.lower() for p in predefined_focus_areas]:
                            custom_focus_area = fa
                            break

                predefined_injuries = [
                    "shoulder", "knee", "back", "wrist", "ankle", "hip", "neck", "elbow"
                ]
                custom_injury = None
                if injuries:
                    for inj in injuries:
                        if inj and inj.lower() not in [p.lower() for p in predefined_injuries]:
                            custom_injury = inj
                            break

                db.record_workout_regeneration(
                    user_id=body.user_id,
                    original_workout_id=body.workout_id,
                    new_workout_id=new_workout["id"],
                    difficulty=user_difficulty,
                    duration_minutes=body.duration_minutes,
                    workout_type=workout_type_override,
                    equipment=equipment if isinstance(equipment, list) else [],
                    focus_areas=focus_areas if focus_areas else [],
                    injuries=injuries if injuries else [],
                    custom_focus_area=custom_focus_area,
                    custom_injury=custom_injury,
                    generation_method="rag_regenerate" if used_rag else "ai_regenerate",
                    used_rag=used_rag,
                    generation_time_ms=None,
                )
                logger.info(f"Background: Recorded regeneration analytics for workout {new_workout['id']}")

                if custom_focus_area or custom_injury:
                    try:
                        from services.custom_inputs_rag_service import get_custom_inputs_rag_service
                        custom_rag = get_custom_inputs_rag_service()

                        if custom_focus_area:
                            await custom_rag.index_custom_input(
                                input_type="focus_area",
                                input_value=custom_focus_area,
                                user_id=body.user_id,
                            )
                        if custom_injury:
                            await custom_rag.index_custom_input(
                                input_type="injury",
                                input_value=custom_injury,
                                user_id=body.user_id,
                            )
                    except Exception as chroma_error:
                        logger.warning(f"Background: Failed to index custom inputs to ChromaDB: {chroma_error}", exc_info=True)
            except Exception as analytics_error:
                logger.warning(f"Background: Failed to record regeneration analytics: {analytics_error}", exc_info=True)

        background_tasks.add_task(_bg_record_regeneration_analytics)

        async def _bg_log_regeneration():
            try:
                await log_user_activity(
                    user_id=body.user_id,
                    action="workout_regeneration",
                    endpoint="/api/v1/workouts-db/regenerate",
                    message=f"Regenerated workout: {workout_name}",
                    metadata={
                        "original_workout_id": body.workout_id,
                        "new_workout_id": new_workout["id"],
                        "difficulty": user_difficulty,
                        "duration_minutes": body.duration_minutes,
                        "workout_type": workout_type_override,
                        "exercises_count": len(exercises),
                        "used_rag": used_rag,
                    },
                    status_code=200
                )
            except Exception as e:
                logger.warning(f"Background: Failed to log regeneration activity: {e}", exc_info=True)

        background_tasks.add_task(_bg_log_regeneration)

        return regenerated

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to regenerate workout: {e}", exc_info=True)
        await log_user_error(
            user_id=body.user_id,
            action="workout_regeneration",
            error=e,
            endpoint="/api/v1/workouts-db/regenerate",
            metadata={"workout_id": body.workout_id},
            status_code=500
        )
        raise safe_internal_error(e, "workouts_db")


@router.get("/{workout_id}/versions", response_model=List[WorkoutVersionInfo])
@limiter.limit("5/minute")
async def get_workout_versions(request: Request, workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get all versions of a workout (version history)."""
    logger.info(f"Getting versions for workout {workout_id}")

    try:
        db = get_supabase_db()
        versions = db.get_workout_versions(workout_id)

        if not versions:
            raise HTTPException(status_code=404, detail="Workout not found")

        version_infos = []
        for v in versions:
            exercises = v.get("exercises_json", [])
            if isinstance(exercises, str):
                try:
                    exercises = json.loads(exercises)
                except Exception:
                    exercises = []

            version_infos.append(WorkoutVersionInfo(
                id=str(v.get("id")),
                version_number=v.get("version_number", 1),
                name=v.get("name", ""),
                is_current=v.get("is_current", False),
                valid_from=v.get("valid_from"),
                valid_to=v.get("valid_to"),
                generation_method=v.get("generation_method"),
                exercises_count=len(exercises) if isinstance(exercises, list) else 0
            ))

        return version_infos

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout versions: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/revert", response_model=Workout)
async def revert_workout(request: RevertWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """Revert a workout to a previous version (creates a NEW version with old content)."""
    logger.info(f"Reverting workout {request.workout_id} to version {request.target_version}")

    try:
        db = get_supabase_db()
        reverted = db.revert_workout(request.workout_id, request.target_version)

        log_workout_change(
            workout_id=reverted["id"],
            user_id=reverted.get("user_id"),
            change_type="reverted",
            change_source="revert_endpoint",
            new_value={
                "reverted_to_version": request.target_version,
                "original_workout_id": request.workout_id
            }
        )

        reverted_workout = row_to_workout(reverted)
        await index_workout_to_rag(reverted_workout)
        return reverted_workout

    except ValueError:
        raise HTTPException(status_code=404, detail="Workout version not found")
    except Exception as e:
        logger.error(f"Failed to revert workout: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.get("/{workout_id}/summary")
async def get_workout_ai_summary(workout_id: str, force_regenerate: bool = False,
    current_user: dict = Depends(get_current_user),
):
    """Generate an AI summary/description of a workout explaining the intention and benefits."""
    logger.info(f"Getting AI summary for workout {workout_id} (force_regenerate={force_regenerate})")
    try:
        db = get_supabase_db()

        result = db.client.table("workouts").select("*").eq("id", workout_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = result.data[0]
        user_id = workout_data.get("user_id")

        if not force_regenerate:
            cached = db.client.table("workout_summaries").select("summary").eq(
                "workout_id", workout_id
            ).eq("user_id", user_id).execute()

            if cached.data:
                logger.info(f"Returning cached summary for workout {workout_id}")
                return {"summary": cached.data[0]["summary"], "cached": True}

        exercises = parse_json_field(workout_data.get("exercises_json"), [])
        target_muscles = parse_json_field(workout_data.get("target_muscles"), [])

        user_result = db.client.table("users").select("goals, fitness_level").eq("id", user_id).execute()
        user_goals = []
        fitness_level = "intermediate"
        if user_result.data:
            user_goals = normalize_goals_list(user_result.data[0].get("goals"))
            fitness_level = user_result.data[0].get("fitness_level", "intermediate")

        start_time = time.time()
        summary = await generate_workout_insights(
            workout_id=workout_id,
            workout_name=workout_data.get("name", "Workout"),
            exercises=exercises,
            duration_minutes=workout_data.get("duration_minutes", 45),
            workout_type=workout_data.get("type"),
            difficulty=workout_data.get("difficulty"),
            user_goals=user_goals,
            fitness_level=fitness_level,
        )
        generation_time_ms = int((time.time() - start_time) * 1000)

        duration_minutes = workout_data.get("duration_minutes", 0)
        calories_estimate = duration_minutes * 6 if duration_minutes else len(exercises) * 5

        summary_record = {
            "workout_id": workout_id,
            "user_id": user_id,
            "summary": summary,
            "workout_name": workout_data.get("name"),
            "workout_type": workout_data.get("type"),
            "exercise_count": len(exercises),
            "duration_minutes": duration_minutes,
            "calories_estimate": calories_estimate,
            "model_used": "gpt-4o-mini",
            "generation_time_ms": generation_time_ms,
            "generated_at": datetime.utcnow().isoformat()
        }

        try:
            existing = db.client.table("workout_summaries").select("id").eq(
                "workout_id", workout_id
            ).eq("user_id", user_id).execute()

            if existing.data:
                db.client.table("workout_summaries").update(summary_record).eq(
                    "id", existing.data[0]["id"]
                ).execute()
            else:
                db.client.table("workout_summaries").insert(summary_record).execute()
        except Exception as store_error:
            logger.warning(f"Failed to store workout summary: {store_error}", exc_info=True)

        return {"summary": summary, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout summary: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


# ==================== WARMUP & STRETCHES ====================

@router.get("/{workout_id}/warmup")
async def get_workout_warmup(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get warmup exercises for a workout."""
    try:
        service = get_warmup_stretch_service()
        warmup = service.get_warmup_for_workout(workout_id)
        if not warmup:
            raise HTTPException(status_code=404, detail="Warmup not found for this workout")
        return warmup
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get warmup: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.get("/{workout_id}/stretches")
async def get_workout_stretches(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get cool-down stretches for a workout."""
    try:
        service = get_warmup_stretch_service()
        stretches = service.get_stretches_for_workout(workout_id)
        if not stretches:
            raise HTTPException(status_code=404, detail="Stretches not found for this workout")
        return stretches
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get stretches: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/{workout_id}/warmup")
async def create_workout_warmup(workout_id: str, duration_minutes: int = 5,
    current_user: dict = Depends(get_current_user),
):
    """Generate and create warmup exercises for an existing workout."""
    try:
        db = get_supabase_db()
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        service = get_warmup_stretch_service()
        warmup = await service.create_warmup_for_workout(
            workout_id, exercises, duration_minutes, user_id=user_id
        )
        if not warmup:
            raise safe_internal_error(ValueError("Failed to create warmup"), "workouts_db_versioning")
        return warmup

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create warmup: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/{workout_id}/stretches")
async def create_workout_stretches(workout_id: str, duration_minutes: int = 5,
    current_user: dict = Depends(get_current_user),
):
    """Generate and create cool-down stretches for an existing workout."""
    try:
        db = get_supabase_db()
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        service = get_warmup_stretch_service()
        stretches = await service.create_stretches_for_workout(
            workout_id, exercises, duration_minutes, user_id=user_id
        )
        if not stretches:
            raise safe_internal_error(ValueError("Failed to create stretches"), "workouts_db_versioning")
        return stretches

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create stretches: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/{workout_id}/warmup-and-stretches")
async def create_workout_warmup_and_stretches(
    workout_id: str,
    warmup_duration: int = 5,
    stretch_duration: int = 5,
    current_user: dict = Depends(get_current_user),
):
    """Generate and create both warmup and stretches for an existing workout."""
    try:
        db = get_supabase_db()
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        service = get_warmup_stretch_service()
        result = await service.generate_warmup_and_stretches_for_workout(
            workout_id, exercises, warmup_duration, stretch_duration, user_id=user_id
        )
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create warmup and stretches: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


# ==================== EXIT STATS & PROGRAM ====================

@router.get("/user/{user_id}/exit-stats")
async def get_user_exit_stats(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get exit statistics for a user."""
    try:
        db = get_supabase_db()
        result = db.client.table("workout_exits").select("*").eq("user_id", user_id).execute()

        if not result.data:
            return {
                "total_exits": 0, "exits_by_reason": {},
                "avg_progress_at_exit": 0, "total_time_spent_seconds": 0
            }

        exits = result.data
        total_exits = len(exits)
        exits_by_reason = {}
        for exit in exits:
            reason = exit["exit_reason"]
            exits_by_reason[reason] = exits_by_reason.get(reason, 0) + 1

        avg_progress = sum(e["progress_percentage"] for e in exits) / total_exits if total_exits > 0 else 0
        total_time = sum(e["time_spent_seconds"] for e in exits)

        return {
            "total_exits": total_exits, "exits_by_reason": exits_by_reason,
            "avg_progress_at_exit": round(avg_progress, 1), "total_time_spent_seconds": total_time
        }

    except Exception as e:
        logger.error(f"Failed to get user exit stats: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/update-program", response_model=UpdateProgramResponse)
@limiter.limit("5/minute")
async def update_program(request: Request, body: UpdateProgramRequest,
    current_user: dict = Depends(get_current_user),
):
    """Update user's program preferences and delete future incomplete workouts."""
    logger.info(f"Updating program for user {body.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(body.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        current_prefs = user.get("preferences", {})
        if isinstance(current_prefs, str):
            try:
                current_prefs = json.loads(current_prefs)
            except json.JSONDecodeError:
                current_prefs = {}

        updated_prefs = dict(current_prefs)
        if body.difficulty is not None:
            updated_prefs["intensity_preference"] = body.difficulty
        if body.duration_minutes is not None:
            updated_prefs["workout_duration"] = body.duration_minutes
        if body.workout_type is not None:
            updated_prefs["training_split"] = body.workout_type
        if body.workout_days is not None:
            updated_prefs["days_per_week"] = len(body.workout_days)
            day_map = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}
            selected_indices = [day_map.get(d, 0) for d in body.workout_days]
            updated_prefs["selected_days"] = sorted(selected_indices)
        if body.dumbbell_count is not None:
            updated_prefs["dumbbell_count"] = body.dumbbell_count
        if body.kettlebell_count is not None:
            updated_prefs["kettlebell_count"] = body.kettlebell_count

        update_data = {"preferences": updated_prefs}
        if body.equipment is not None:
            update_data["equipment"] = body.equipment
        if body.injuries is not None:
            update_data["active_injuries"] = body.injuries

        db.update_user(body.user_id, update_data)

        from core.timezone_utils import user_today_date
        today = user_today_date(request, db, body.user_id).isoformat()
        all_workouts = db.list_workouts(body.user_id, limit=1000)

        workouts_to_delete = []
        for w in all_workouts:
            scheduled_date = w.get("scheduled_date")
            is_completed = w.get("is_completed", False)
            if hasattr(scheduled_date, 'isoformat'):
                scheduled_date = scheduled_date.isoformat()
            elif hasattr(scheduled_date, 'strftime'):
                scheduled_date = scheduled_date.strftime('%Y-%m-%d')
            if not is_completed and scheduled_date and scheduled_date >= today:
                workouts_to_delete.append(w)

        for w in workouts_to_delete:
            try:
                db.delete_workout_changes_by_workout(w["id"])
            except Exception as e:
                logger.warning(f"Could not delete workout changes for {w['id']}: {e}", exc_info=True)

        deleted_count = 0
        for w in workouts_to_delete:
            try:
                db.delete_workout(w["id"])
                deleted_count += 1
            except Exception as e:
                logger.error(f"Failed to delete workout {w['id']}: {e}", exc_info=True)

        try:
            rag_service = get_workout_rag_service()
            await rag_service.index_program_preferences(
                user_id=body.user_id,
                difficulty=body.difficulty,
                duration_minutes=body.duration_minutes,
                workout_type=body.workout_type,
                workout_days=body.workout_days,
                equipment=body.equipment,
                focus_areas=body.focus_areas,
                injuries=body.injuries,
                workout_environment=body.workout_environment,
                change_reason="program_customization",
            )
        except Exception as e:
            logger.warning(f"Could not index preferences to RAG: {e}", exc_info=True)

        await log_user_activity(
            user_id=body.user_id,
            action="program_customization",
            endpoint="/api/v1/workouts-db/update-program",
            message=f"Updated program, deleted {deleted_count} future workouts",
            metadata={
                "difficulty": body.difficulty,
                "duration_minutes": body.duration_minutes,
                "workout_type": body.workout_type,
                "workout_days": body.workout_days,
                "workouts_deleted": deleted_count,
            },
            status_code=200
        )

        return UpdateProgramResponse(
            success=True,
            message=f"Program updated. {deleted_count} future workouts deleted for regeneration.",
            workouts_deleted=deleted_count,
            preferences_updated=True
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update program: {e}", exc_info=True)
        await log_user_error(
            user_id=body.user_id,
            action="program_customization",
            error=e,
            endpoint="/api/v1/workouts-db/update-program",
            status_code=500
        )
        raise safe_internal_error(e, "workouts_db")


@router.get("/{workout_id}/generation-params")
async def get_workout_generation_params(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get the generation parameters and AI reasoning for a workout."""
    logger.info(f"Getting generation parameters for workout {workout_id}")
    try:
        db = get_supabase_db()

        result = db.client.table("workouts").select("*").eq("id", workout_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = result.data[0]
        user_id = workout_data.get("user_id")

        user_result = db.client.table("users").select(
            "fitness_level, goals, equipment, active_injuries, age, weight_kg, height_cm, gender"
        ).eq("id", user_id).execute()

        user_profile = {}
        if user_result.data:
            ud = user_result.data[0]
            user_profile = {
                "fitness_level": ud.get("fitness_level", "intermediate"),
                "goals": normalize_goals_list(ud.get("goals")),
                "equipment": parse_json_field(ud.get("equipment"), []),
                "injuries": parse_json_field(ud.get("active_injuries"), []),
                "age": ud.get("age"),
                "weight_kg": ud.get("weight_kg"),
                "height_cm": ud.get("height_cm"),
                "gender": ud.get("gender"),
            }

        program_preferences = {}
        try:
            regen_result = db.client.table("workout_regenerations").select("*").eq(
                "user_id", user_id
            ).order("created_at", desc=True).limit(1).execute()
            if regen_result.data:
                regen = regen_result.data[0]
                program_preferences = {
                    "difficulty": regen.get("selected_difficulty"),
                    "duration_minutes": regen.get("selected_duration_minutes"),
                    "workout_type": regen.get("selected_workout_type"),
                    "training_split": regen.get("selected_training_split"),
                    "workout_days": parse_json_field(regen.get("selected_workout_days"), []),
                    "focus_areas": parse_json_field(regen.get("selected_focus_areas"), []),
                    "equipment": parse_json_field(regen.get("selected_equipment"), []),
                }
        except Exception as e:
            logger.warning(f"Could not fetch program preferences: {e}", exc_info=True)

        exercises = parse_json_field(workout_data.get("exercises_json"), [])
        workout_type = workout_data.get("type", "strength")
        difficulty = workout_data.get("difficulty", "intermediate")
        target_muscles = parse_json_field(workout_data.get("target_muscles"), [])
        workout_name = workout_data.get("name", "Workout")

        exercise_reasoning = []
        workout_reasoning = ""

        try:
            from services.gemini_service import GeminiService
            gemini = GeminiService()

            ai_reasoning = await gemini.generate_exercise_reasoning(
                workout_name=workout_name,
                exercises=exercises,
                user_profile=user_profile,
                program_preferences=program_preferences,
                workout_type=workout_type,
                difficulty=difficulty,
            )

            if ai_reasoning.get("workout_reasoning") and ai_reasoning.get("exercise_reasoning"):
                workout_reasoning = ai_reasoning["workout_reasoning"]

                ai_exercise_map = {
                    r.get("exercise_name", "").lower(): r.get("reasoning", "")
                    for r in ai_reasoning.get("exercise_reasoning", [])
                }

                for i, ex in enumerate(exercises):
                    ex_name = ex.get("name", f"Exercise {i+1}")
                    muscle_group = ex.get("muscle_group") or ex.get("primary_muscle") or ex.get("body_part", "general")
                    equip = ex.get("equipment", "bodyweight")

                    ai_reason = ai_exercise_map.get(ex_name.lower(), "")
                    if ai_reason:
                        reasoning = ai_reason
                    else:
                        reasoning = build_exercise_reasoning(
                            exercise_name=ex_name, muscle_group=muscle_group,
                            equipment=equip, sets=ex.get("sets", 3), reps=ex.get("reps", "8-12"),
                            workout_type=workout_type, difficulty=difficulty,
                            user_goals=user_profile.get("goals", []),
                            user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                            user_equipment=user_profile.get("equipment", []),
                        )

                    exercise_reasoning.append({
                        "exercise_name": ex_name, "reasoning": reasoning,
                        "muscle_group": muscle_group, "equipment": equip,
                    })
            else:
                raise ValueError("AI returned empty reasoning")

        except Exception as ai_error:
            logger.warning(f"AI reasoning failed, using static fallback: {ai_error}", exc_info=True)

            for i, ex in enumerate(exercises):
                ex_name = ex.get("name", f"Exercise {i+1}")
                muscle_group = ex.get("muscle_group") or ex.get("primary_muscle") or ex.get("body_part", "general")
                equip = ex.get("equipment", "bodyweight")

                reasoning = build_exercise_reasoning(
                    exercise_name=ex_name, muscle_group=muscle_group,
                    equipment=equip, sets=ex.get("sets", 3), reps=ex.get("reps", "8-12"),
                    workout_type=workout_type, difficulty=difficulty,
                    user_goals=user_profile.get("goals", []),
                    user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                    user_equipment=user_profile.get("equipment", []),
                )
                exercise_reasoning.append({
                    "exercise_name": ex_name, "reasoning": reasoning,
                    "muscle_group": muscle_group, "equipment": equip,
                })

            workout_reasoning = build_workout_reasoning(
                workout_name=workout_name, workout_type=workout_type,
                difficulty=difficulty, target_muscles=target_muscles,
                exercise_count=len(exercises),
                duration_minutes=workout_data.get("duration_minutes", 45),
                user_goals=user_profile.get("goals", []),
                user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                training_split=program_preferences.get("training_split"),
            )

        return {
            "workout_id": workout_id,
            "workout_name": workout_data.get("name"),
            "workout_type": workout_type,
            "difficulty": difficulty,
            "duration_minutes": workout_data.get("duration_minutes"),
            "generation_method": workout_data.get("generation_method", "ai"),
            "user_profile": user_profile,
            "program_preferences": program_preferences,
            "workout_reasoning": workout_reasoning,
            "exercise_reasoning": exercise_reasoning,
            "target_muscles": target_muscles,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout generation params: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")
