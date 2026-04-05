"""
Workout modification operations: swap dates, swap exercises, add exercises, extend.

Endpoints:
- POST /swap - Move a workout to a new date
- POST /swap-exercise - Swap an exercise within a workout
- POST /add-exercise - Add a new exercise to an existing workout
- POST /extend - Extend a workout with additional AI-generated exercises
"""
from core.db import get_supabase_db
import json
import re
import uuid
import asyncio
from datetime import datetime
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from models.schemas import (
    Workout, SwapWorkoutsRequest, SwapExerciseRequest,
    AddExerciseRequest, ExtendWorkoutRequest,
)
from services.gemini_service import GeminiService
from services.exercise_library_service import get_exercise_library_service

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    normalize_goals_list,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    get_user_staple_exercises,
    get_staple_names,
)
from .focus_validation_utils import (
    get_all_muscles_for_exercise,
    compare_muscle_profiles,
)
from .generation_helpers import normalize_exercise_numeric_fields

router = APIRouter()
logger = get_logger(__name__)


@router.post("/swap")
@limiter.limit("10/minute")
async def swap_workout_date(request: Request, payload: SwapWorkoutsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Move a workout to a new date, swapping if another workout exists there."""
    logger.info(f"Swapping workout {payload.workout_id} to {payload.new_date}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(payload.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        old_date = workout.get("scheduled_date")
        user_id = workout.get("user_id")

        existing_workouts = db.get_workouts_by_date_range(user_id, payload.new_date, payload.new_date)

        if existing_workouts:
            existing = existing_workouts[0]
            db.update_workout(existing["id"], {"scheduled_date": old_date, "last_modified_method": "date_swap"})
            log_workout_change(existing["id"], user_id, "date_swap", "scheduled_date", payload.new_date, old_date)

        db.update_workout(payload.workout_id, {"scheduled_date": payload.new_date, "last_modified_method": "date_swap"})
        log_workout_change(payload.workout_id, user_id, "date_swap", "scheduled_date", old_date, payload.new_date)

        return {"success": True, "old_date": old_date, "new_date": payload.new_date}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap workout: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/swap-exercise", response_model=Workout)
@limiter.limit("10/minute")
async def swap_exercise_in_workout(request: Request, payload: SwapExerciseRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Swap an exercise within a workout with a new exercise from the library."""
    logger.info(f"Swapping exercise '{payload.old_exercise_name}' with '{payload.new_exercise_name}' in workout {payload.workout_id}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(payload.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        # Get muscle profiles for comparison (optional)
        muscle_comparison = None
        muscle_profile_warning = None
        try:
            old_muscles = await get_all_muscles_for_exercise(payload.old_exercise_name)
            new_muscles = await get_all_muscles_for_exercise(payload.new_exercise_name)

            if old_muscles and new_muscles:
                muscle_comparison = compare_muscle_profiles(old_muscles, new_muscles)
                if muscle_comparison.get("warning"):
                    muscle_profile_warning = muscle_comparison["warning"]
                    logger.warning(
                        f"Exercise swap muscle profile warning: {muscle_profile_warning} "
                        f"(similarity: {muscle_comparison.get('similarity_score', 0):.0%})"
                    )
        except Exception as e:
            logger.warning(f"Non-critical: Failed to get muscle profiles for swap comparison: {e}")

        exercise_found = False
        i = 0
        for i, exercise in enumerate(exercises):
            if exercise.get("name", "").lower() == payload.old_exercise_name.lower():
                exercise_found = True

                exercise_lib = get_exercise_library_service()
                new_exercise_data = exercise_lib.search_exercises(payload.new_exercise_name, limit=1)

                if not new_exercise_data:
                    try:
                        cleaned_result = db.client.table("exercise_library_cleaned") \
                            .select("id, name, target_muscle, body_part, equipment, gif_url, video_url, secondary_muscles, instructions") \
                            .ilike("name", payload.new_exercise_name) \
                            .limit(1) \
                            .execute()
                        if cleaned_result.data:
                            row = cleaned_result.data[0]
                            new_exercise_data = [{
                                **row,
                                "name": row.get("name", payload.new_exercise_name),
                                "muscle_group": row.get("target_muscle") or row.get("body_part", ""),
                            }]
                            logger.info(f"Found exercise in exercise_library_cleaned: {row.get('name')}")
                    except Exception as e:
                        logger.warning(f"Fallback exercise_library_cleaned lookup failed: {e}")

                if new_exercise_data:
                    new_ex = new_exercise_data[0]
                    exercises[i] = {
                        **exercise,
                        "name": new_ex.get("name", payload.new_exercise_name),
                        "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part") or exercise.get("muscle_group"),
                        "equipment": new_ex.get("equipment") or exercise.get("equipment"),
                        "notes": new_ex.get("instructions") or exercise.get("notes", ""),
                        "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                        "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                        "library_id": new_ex.get("id"),
                        "secondary_muscles": new_ex.get("secondary_muscles", []),
                    }
                    if payload.duration_seconds is not None:
                        exercises[i]["duration_seconds"] = payload.duration_seconds
                        exercises[i]["is_timed"] = True
                    if payload.speed_mph is not None:
                        exercises[i]["speed_mph"] = payload.speed_mph
                    if payload.incline_percent is not None:
                        exercises[i]["incline_percent"] = payload.incline_percent
                    if payload.rpm is not None:
                        exercises[i]["rpm"] = payload.rpm
                    if payload.resistance_level is not None:
                        exercises[i]["resistance_level"] = payload.resistance_level
                    if payload.stroke_rate_spm is not None:
                        exercises[i]["stroke_rate_spm"] = payload.stroke_rate_spm

                    if muscle_profile_warning:
                        exercises[i]["muscle_profile_warning"] = muscle_profile_warning
                        exercises[i]["muscle_similarity_score"] = muscle_comparison.get("similarity_score", 1.0)
                else:
                    exercises[i]["name"] = payload.new_exercise_name
                break

        if not exercise_found:
            raise HTTPException(status_code=404, detail=f"Exercise '{payload.old_exercise_name}' not found in workout")

        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_swap"
        }

        updated = db.update_workout(payload.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        log_workout_change(
            payload.workout_id,
            workout.get("user_id"),
            "exercise_swap",
            "exercises_json",
            payload.old_exercise_name,
            payload.new_exercise_name
        )

        try:
            db.client.table("exercise_swaps").insert({
                "user_id": workout.get("user_id"),
                "workout_id": payload.workout_id,
                "original_exercise": payload.old_exercise_name,
                "new_exercise": payload.new_exercise_name,
                "swap_reason": payload.reason,
                "swap_source": payload.swap_source or "ai_suggestion",
                "exercise_index": i,
                "workout_phase": "main",
            }).execute()
            logger.info(f"Logged swap to exercise_swaps: {payload.old_exercise_name} -> {payload.new_exercise_name}")
        except Exception as e:
            logger.warning(f"Failed to log swap to exercise_swaps: {e}")

        updated_workout = row_to_workout(updated)

        if muscle_profile_warning:
            logger.info(f"Exercise swapped in workout {payload.workout_id} with warning: {muscle_profile_warning}")
        else:
            logger.info(f"Exercise swapped successfully in workout {payload.workout_id}")

        async def _bg_index():
            try:
                await index_workout_to_rag(updated_workout)
            except Exception as e:
                logger.warning(f"Background: Failed to index swapped workout to RAG: {e}")

        background_tasks.add_task(_bg_index)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap exercise: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/add-exercise", response_model=Workout)
@limiter.limit("10/minute")
async def add_exercise_to_workout(request: Request, payload: AddExerciseRequest, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Add a new exercise to an existing workout."""
    section = payload.section or "main"
    logger.info(f"Adding exercise '{payload.exercise_name}' to workout {payload.workout_id} (section: {section})")
    try:
        db = get_supabase_db()

        workout = db.get_workout(payload.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercise_lib = get_exercise_library_service()
        if payload.exercise_id:
            ex_by_id = exercise_lib.get_exercise_by_id(payload.exercise_id)
            exercise_data = [ex_by_id] if ex_by_id else exercise_lib.search_exercises(payload.exercise_name, limit=1)
        else:
            exercise_data = exercise_lib.search_exercises(payload.exercise_name, limit=1)

        exercise_name = payload.exercise_name
        muscle_group = None
        if exercise_data:
            ex_info = exercise_data[0]
            exercise_name = ex_info.get("name", payload.exercise_name)
            muscle_group = ex_info.get("target_muscle") or ex_info.get("body_part")

        if section == "main":
            exercises_json = workout.get("exercises_json", "[]")
            if isinstance(exercises_json, str):
                exercises = json.loads(exercises_json)
            else:
                exercises = exercises_json

            reps_str = str(payload.reps) if payload.reps else "10"
            reps_match = re.search(r'\d+', reps_str)
            reps_int = int(reps_match.group()) if reps_match else 10

            if exercise_data:
                new_ex = exercise_data[0]
                new_exercise = {
                    "name": new_ex.get("name", payload.exercise_name),
                    "sets": payload.sets,
                    "reps": reps_int,
                    "rest_seconds": payload.rest_seconds,
                    "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part"),
                    "equipment": new_ex.get("equipment"),
                    "notes": new_ex.get("instructions", ""),
                    "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                    "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                    "library_id": new_ex.get("id"),
                }
            else:
                new_exercise = {
                    "name": payload.exercise_name,
                    "sets": payload.sets,
                    "reps": reps_int,
                    "rest_seconds": payload.rest_seconds,
                }

            exercises.append(new_exercise)

            update_data = {
                "exercises_json": json.dumps(exercises),
                "last_modified_at": datetime.now().isoformat(),
                "last_modified_method": "exercise_add"
            }

            updated = db.update_workout(payload.workout_id, update_data)
            if not updated:
                raise HTTPException(status_code=500, detail="Failed to update workout")

            log_workout_change(
                payload.workout_id,
                workout.get("user_id"),
                "exercise_add",
                "exercises_json",
                None,
                payload.exercise_name
            )

            updated_workout = row_to_workout(updated)
            logger.info(f"Exercise '{payload.exercise_name}' added successfully to workout {payload.workout_id} (main)")

            async def _bg_index():
                try:
                    await index_workout_to_rag(updated_workout)
                except Exception as e:
                    logger.warning(f"Background: Failed to index workout to RAG after exercise add: {e}")

            background_tasks.add_task(_bg_index)

            return updated_workout

        elif section == "warmup":
            new_warmup_exercise = {
                "name": exercise_name,
                "sets": 1, "reps": None,
                "duration_seconds": payload.duration_seconds or 30,
                "rest_seconds": 10,
                "equipment": (exercise_data[0].get("equipment") if exercise_data else None) or "none",
                "muscle_group": muscle_group or "general",
                "notes": None,
                "is_timed": True if payload.duration_seconds else False,
                "speed_mph": payload.speed_mph,
                "incline_percent": payload.incline_percent,
                "rpm": payload.rpm,
                "resistance_level": payload.resistance_level,
                "stroke_rate_spm": payload.stroke_rate_spm,
            }

            warmup_result = db.client.table("warmups").select("*").eq(
                "workout_id", payload.workout_id
            ).eq("is_current", True).execute()

            if warmup_result.data:
                warmup_row = warmup_result.data[0]
                existing_exercises = warmup_row.get("exercises_json", "[]")
                if isinstance(existing_exercises, str):
                    warmup_exercises = json.loads(existing_exercises)
                else:
                    warmup_exercises = existing_exercises or []

                warmup_exercises.append(new_warmup_exercise)

                db.client.table("warmups").update({
                    "exercises_json": json.dumps(warmup_exercises),
                    "updated_at": datetime.now().isoformat(),
                }).eq("id", warmup_row["id"]).execute()

                logger.info(f"Exercise '{exercise_name}' added to existing warmup for workout {payload.workout_id}")
            else:
                new_warmup_id = str(uuid.uuid4())
                db.client.table("warmups").insert({
                    "id": new_warmup_id,
                    "workout_id": payload.workout_id,
                    "exercises_json": json.dumps([new_warmup_exercise]),
                    "duration_minutes": 5,
                    "is_current": True,
                    "version_number": 1,
                    "created_at": datetime.now().isoformat(),
                    "updated_at": datetime.now().isoformat(),
                }).execute()

                logger.info(f"Exercise '{exercise_name}' added with new warmup for workout {payload.workout_id}")

            return row_to_workout(workout)

        elif section == "stretches":
            new_stretch_exercise = {
                "name": exercise_name,
                "sets": 1, "reps": 1,
                "duration_seconds": payload.duration_seconds or 30,
                "rest_seconds": 0,
                "equipment": (exercise_data[0].get("equipment") if exercise_data else None) or "none",
                "muscle_group": muscle_group or "general",
                "notes": None,
                "is_timed": True if payload.duration_seconds else False,
                "speed_mph": payload.speed_mph,
                "incline_percent": payload.incline_percent,
                "rpm": payload.rpm,
                "resistance_level": payload.resistance_level,
                "stroke_rate_spm": payload.stroke_rate_spm,
            }

            stretch_result = db.client.table("stretches").select("*").eq(
                "workout_id", payload.workout_id
            ).eq("is_current", True).execute()

            if stretch_result.data:
                stretch_row = stretch_result.data[0]
                existing_exercises = stretch_row.get("exercises_json", "[]")
                if isinstance(existing_exercises, str):
                    stretch_exercises = json.loads(existing_exercises)
                else:
                    stretch_exercises = existing_exercises or []

                stretch_exercises.append(new_stretch_exercise)

                db.client.table("stretches").update({
                    "exercises_json": json.dumps(stretch_exercises),
                    "updated_at": datetime.now().isoformat(),
                }).eq("id", stretch_row["id"]).execute()

                logger.info(f"Exercise '{exercise_name}' added to existing stretches for workout {payload.workout_id}")
            else:
                new_stretch_id = str(uuid.uuid4())
                db.client.table("stretches").insert({
                    "id": new_stretch_id,
                    "workout_id": payload.workout_id,
                    "exercises_json": json.dumps([new_stretch_exercise]),
                    "duration_minutes": 5,
                    "is_current": True,
                    "version_number": 1,
                    "created_at": datetime.now().isoformat(),
                    "updated_at": datetime.now().isoformat(),
                }).execute()

                logger.info(f"Exercise '{exercise_name}' added with new stretches for workout {payload.workout_id}")

            return row_to_workout(workout)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add exercise: {e}")
        raise safe_internal_error(e, "generation")


@router.post("/extend", response_model=Workout)
@limiter.limit("10/minute")
async def extend_workout(request: Request, payload: ExtendWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """Extend an existing workout with additional AI-generated exercises."""
    logger.info(f"🔥 Extending workout {payload.workout_id} for user {payload.user_id}")

    try:
        db = get_supabase_db()

        workout_result = db.client.table("workouts").select("*").eq(
            "id", payload.workout_id
        ).eq("user_id", payload.user_id).execute()

        if not workout_result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        existing_workout = workout_result.data[0]
        existing_exercises_json = existing_workout.get("exercises_json")

        if isinstance(existing_exercises_json, str):
            existing_exercises = json.loads(existing_exercises_json)
        else:
            existing_exercises = existing_exercises_json or []

        if not existing_exercises:
            raise HTTPException(status_code=400, detail="Workout has no exercises to extend")

        existing_muscle_groups = list(set(
            ex.get("muscle_group", "").lower() for ex in existing_exercises
            if ex.get("muscle_group")
        ))
        existing_exercise_names = [ex.get("name", "").lower() for ex in existing_exercises]

        logger.info(f"📋 Existing workout has {len(existing_exercises)} exercises targeting: {existing_muscle_groups}")

        user = db.get_user(payload.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level", "intermediate")
        equipment = user.get("equipment", [])
        goals = user.get("goals", [])

        avoided_exercises, avoided_muscles, staple_exercises = await asyncio.gather(
            get_user_avoided_exercises(payload.user_id),
            get_user_avoided_muscles(payload.user_id),
            get_user_staple_exercises(payload.user_id, scheduled_date=getattr(payload, 'scheduled_date', None)),
        )
        staple_names = get_staple_names(staple_exercises) if staple_exercises else []

        workout_difficulty = existing_workout.get("difficulty", "medium")
        if payload.intensity == "lighter":
            target_intensity = "easy" if workout_difficulty == "medium" else "medium"
        elif payload.intensity == "harder":
            target_intensity = "hard" if workout_difficulty == "medium" else "hard"
        else:
            target_intensity = workout_difficulty

        gemini_service = GeminiService()

        focus_instruction = ""
        if payload.focus_same_muscles:
            focus_instruction = f"""
🎯 FOCUS: Generate exercises for the SAME muscle groups as the original workout.
Target muscles: {', '.join(existing_muscle_groups)}
This user wants MORE VOLUME for these muscles."""
        else:
            focus_instruction = f"""
🎯 FOCUS: Generate exercises for COMPLEMENTARY muscle groups.
Already worked: {', '.join(existing_muscle_groups)}
Select exercises for OTHER muscle groups to create a more balanced workout."""

        extension_prompt = f"""Generate {payload.additional_exercises} additional exercises to EXTEND an existing workout.

ORIGINAL WORKOUT CONTEXT:
- Existing exercises: {', '.join(existing_exercise_names)}
- Muscle groups worked: {', '.join(existing_muscle_groups)}
- User fitness level: {fitness_level}
- Available equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Target intensity: {target_intensity}

{focus_instruction}

⚠️ CRITICAL CONSTRAINTS:
- Do NOT repeat any exercises already in the workout: {', '.join(existing_exercise_names)}
- Do NOT include these avoided exercises: {', '.join(avoided_exercises) if avoided_exercises else 'None'}
- Staple exercises to consider including: {', '.join(staple_names) if staple_names else 'None'}

Return ONLY a JSON array of exercises (no wrapper object):
[
  {{
    "name": "Exercise name",
    "sets": 3,
    "reps": 12,
    "weight_kg": 10,
    "rest_seconds": 60,
    "equipment": "equipment used",
    "muscle_group": "primary muscle",
    "notes": "Form tips"
  }}
]

Generate exactly {payload.additional_exercises} exercises that complement the existing workout."""

        try:
            raw_response = await gemini_service.chat(
                user_message=extension_prompt,
                system_prompt="You are a fitness expert. Return ONLY valid JSON arrays/objects with no additional text or markdown formatting."
            )

            parsed_response = gemini_service._extract_json_robust(raw_response)

            if parsed_response is None:
                try:
                    parsed_response = json.loads(raw_response.strip())
                except json.JSONDecodeError:
                    logger.error(f"Failed to parse extension response: {raw_response[:500]}")
                    raise ValueError("Failed to parse AI response as JSON")

            if isinstance(parsed_response, list):
                new_exercises = parsed_response
            else:
                new_exercises = parsed_response.get("exercises", []) if isinstance(parsed_response, dict) else []

            new_exercises = normalize_exercise_numeric_fields(new_exercises)

            if avoided_exercises:
                new_exercises = [
                    ex for ex in new_exercises
                    if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
                ]

            new_exercises = [
                ex for ex in new_exercises
                if ex.get("name", "").lower() not in existing_exercise_names
            ]

            if not new_exercises:
                raise HTTPException(status_code=500, detail="Failed to generate valid extension exercises")

            logger.info(f"✅ Generated {len(new_exercises)} extension exercises")

        except Exception as ai_error:
            logger.error(f"AI extension generation failed: {ai_error}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate extension exercises: {str(ai_error)}"
            )

        combined_exercises = existing_exercises + new_exercises
        new_duration = (existing_workout.get("duration_minutes") or 45) + payload.additional_duration_minutes

        update_data = {
            "exercises_json": json.dumps(combined_exercises),
            "duration_minutes": new_duration,
        }

        updated_result = db.client.table("workouts").update(
            update_data
        ).eq("id", payload.workout_id).execute()

        if not updated_result.data:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        log_workout_change(
            workout_id=payload.workout_id,
            user_id=payload.user_id,
            change_type="extended",
            change_source="user_request",
            new_value={
                "added_exercises": len(new_exercises),
                "new_total_exercises": len(combined_exercises),
                "new_duration": new_duration
            }
        )

        logger.info(f"🎉 Workout extended: {len(existing_exercises)} → {len(combined_exercises)} exercises, {new_duration} minutes")

        return row_to_workout(updated_result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to extend workout: {e}")
        raise safe_internal_error(e, "generation")
