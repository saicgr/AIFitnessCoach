"""
Workout generation API endpoints.

This module handles AI-powered workout generation:
- POST /generate - Generate a single workout
- POST /generate-weekly - Generate workouts for a week
- POST /generate-monthly - Generate workouts for a month
- POST /generate-remaining - Generate remaining workouts for a month
- POST /swap - Swap workout date
- POST /swap-exercise - Swap an exercise within a workout
"""
import json
import asyncio
from datetime import datetime, timedelta
from typing import List, AsyncGenerator

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    Workout, GenerateWorkoutRequest, SwapWorkoutsRequest, SwapExerciseRequest,
    AddExerciseRequest,
    GenerateWeeklyRequest, GenerateWeeklyResponse,
    GenerateMonthlyRequest, GenerateMonthlyResponse,
)
from services.gemini_service import GeminiService
from services.exercise_library_service import get_exercise_library_service
from services.exercise_rag_service import get_exercise_rag_service
from services.warmup_stretch_service import get_warmup_stretch_service
from core.rate_limiter import limiter

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    get_all_equipment,
    get_recently_used_exercises,
    get_workout_focus,
    calculate_workout_date,
    calculate_monthly_dates,
    extract_name_words,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post("/generate", response_model=Workout)
async def generate_workout(request: GenerateWorkoutRequest):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {request.user_id}")

    try:
        db = get_supabase_db()

        if request.fitness_level and request.goals and request.equipment:
            fitness_level = request.fitness_level
            goals = request.goals
            equipment = request.equipment
            intensity_preference = "medium"  # Default when no user data
        else:
            user = db.get_user(request.user_id)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            fitness_level = request.fitness_level or user.get("fitness_level")
            goals = request.goals or user.get("goals", [])
            equipment = request.equipment or user.get("equipment", [])
            preferences = parse_json_field(user.get("preferences"), {})
            intensity_preference = preferences.get("intensity_preference", "medium")

        # Fetch user's custom exercises
        logger.info(f"🏋️ [Workout Generation] Fetching custom exercises for user: {request.user_id}")
        custom_exercises = []
        try:
            custom_result = db.client.table("exercises").select(
                "name", "primary_muscle", "equipment", "default_sets", "default_reps"
            ).eq("is_custom", True).eq("created_by_user_id", request.user_id).execute()
            if custom_result.data:
                custom_exercises = custom_result.data
                exercise_names = [ex.get("name") for ex in custom_exercises]
                logger.info(f"✅ [Workout Generation] Found {len(custom_exercises)} custom exercises: {exercise_names}")
            else:
                logger.info(f"🏋️ [Workout Generation] No custom exercises found for user {request.user_id}")
        except Exception as e:
            logger.warning(f"⚠️ [Workout Generation] Failed to fetch custom exercises: {e}")

        gemini_service = GeminiService()

        try:
            workout_data = await gemini_service.generate_workout_plan(
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=request.duration_minutes or 45,
                focus_areas=request.focus_areas,
                intensity_preference=intensity_preference,
                custom_exercises=custom_exercises if custom_exercises else None
            )

            exercises = workout_data.get("exercises", [])
            workout_name = workout_data.get("name", "Generated Workout")
            workout_type = workout_data.get("type", request.workout_type or "strength")
            difficulty = workout_data.get("difficulty", intensity_preference)

        except Exception as ai_error:
            logger.error(f"AI workout generation failed: {ai_error}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate workout: {str(ai_error)}"
            )

        workout_db_data = {
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": request.duration_minutes or 45,
            "generation_method": "ai",
            "generation_source": "gemini_generation",
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Workout generated: id={created['id']}")

        log_workout_change(
            workout_id=created['id'],
            user_id=request.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={"name": workout_name, "exercises_count": len(exercises)}
        )

        generated_workout = row_to_workout(created)
        await index_workout_to_rag(generated_workout)

        return generated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-stream")
@limiter.limit("5/minute")
async def generate_workout_streaming(request: Request, body: GenerateWorkoutRequest):
    """
    Generate a workout with streaming response for faster perceived performance.

    Returns Server-Sent Events (SSE) with:
    - event: chunk - Partial workout data as it's generated
    - event: done - Final complete workout data
    - event: error - Error message if generation fails

    Time to first content is typically <500ms vs 3-8s for full generation.
    """
    logger.info(f"🚀 Streaming workout generation for user {body.user_id}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()

        try:
            db = get_supabase_db()

            # Get user data
            if body.fitness_level and body.goals and body.equipment:
                fitness_level = body.fitness_level
                goals = body.goals
                equipment = body.equipment
                intensity_preference = "medium"
            else:
                user = db.get_user(body.user_id)
                if not user:
                    yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                    return

                fitness_level = body.fitness_level or user.get("fitness_level")
                goals = body.goals or user.get("goals", [])
                equipment = body.equipment or user.get("equipment", [])
                preferences = parse_json_field(user.get("preferences"), {})
                intensity_preference = preferences.get("intensity_preference", "medium")

            gemini_service = GeminiService()

            # Send initial acknowledgment (time to first byte)
            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'ttfb_ms': first_chunk_time})}\n\n"

            # Stream the workout generation
            accumulated_text = ""
            chunk_count = 0

            async for chunk in gemini_service.generate_workout_plan_streaming(
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=body.duration_minutes or 45,
                focus_areas=body.focus_areas,
                intensity_preference=intensity_preference
            ):
                accumulated_text += chunk
                chunk_count += 1

                # Send progress updates every few chunks
                if chunk_count % 3 == 0:
                    elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                    yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': len(accumulated_text), 'elapsed_ms': elapsed_ms})}\n\n"

            # Parse the complete response
            try:
                # Extract JSON from potential markdown code blocks
                content = accumulated_text.strip()
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                workout_data = json.loads(content)
                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", "Generated Workout")
                workout_type = workout_data.get("type", body.workout_type or "strength")
                difficulty = workout_data.get("difficulty", intensity_preference)

            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse streaming response: {e}")
                yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data'})}\n\n"
                return

            # Save to database
            workout_db_data = {
                "user_id": body.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "scheduled_date": datetime.now().isoformat(),
                "exercises_json": exercises,
                "duration_minutes": body.duration_minutes or 45,
                "generation_method": "ai",
                "generation_source": "streaming_generation",
            }

            created = db.create_workout(workout_db_data)
            total_time_ms = (datetime.now() - start_time).total_seconds() * 1000

            logger.info(f"✅ Streaming workout complete: {len(exercises)} exercises in {total_time_ms:.0f}ms")

            # Log the change
            log_workout_change(
                workout_id=created['id'],
                user_id=body.user_id,
                change_type="generated",
                change_source="streaming_generation",
                new_value={"name": workout_name, "exercises_count": len(exercises)}
            )

            # Convert to Workout model
            generated_workout = row_to_workout(created)

            # Index to RAG asynchronously (don't wait)
            asyncio.create_task(index_workout_to_rag(generated_workout))

            # Send final complete response
            # Parse exercises from exercises_json (which is a string)
            exercises_list = json.loads(generated_workout.exercises_json) if generated_workout.exercises_json else []

            workout_response = {
                "id": generated_workout.id,
                "user_id": generated_workout.user_id,
                "name": generated_workout.name,
                "type": generated_workout.type,
                "difficulty": generated_workout.difficulty,
                "scheduled_date": generated_workout.scheduled_date.isoformat() if generated_workout.scheduled_date else None,
                "exercises": exercises_list,
                "exercises_json": generated_workout.exercises_json,
                "duration_minutes": generated_workout.duration_minutes,
                "total_time_ms": total_time_ms,
                "chunk_count": chunk_count,
            }

            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except Exception as e:
            logger.error(f"❌ Streaming workout generation failed: {e}")
            yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Disable nginx buffering
        }
    )


@router.post("/swap")
async def swap_workout_date(request: SwapWorkoutsRequest):
    """Move a workout to a new date, swapping if another workout exists there."""
    logger.info(f"Swapping workout {request.workout_id} to {request.new_date}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        old_date = workout.get("scheduled_date")
        user_id = workout.get("user_id")

        # Check for existing workout on new date
        existing_workouts = db.get_workouts_by_date_range(user_id, request.new_date, request.new_date)

        if existing_workouts:
            existing = existing_workouts[0]
            db.update_workout(existing["id"], {"scheduled_date": old_date, "last_modified_method": "date_swap"})
            log_workout_change(existing["id"], user_id, "date_swap", "scheduled_date", request.new_date, old_date)

        db.update_workout(request.workout_id, {"scheduled_date": request.new_date, "last_modified_method": "date_swap"})
        log_workout_change(request.workout_id, user_id, "date_swap", "scheduled_date", old_date, request.new_date)

        return {"success": True, "old_date": old_date, "new_date": request.new_date}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/swap-exercise", response_model=Workout)
async def swap_exercise_in_workout(request: SwapExerciseRequest):
    """Swap an exercise within a workout with a new exercise from the library."""
    logger.info(f"Swapping exercise '{request.old_exercise_name}' with '{request.new_exercise_name}' in workout {request.workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Parse exercises
        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        # Find and replace the exercise
        exercise_found = False
        for i, exercise in enumerate(exercises):
            if exercise.get("name", "").lower() == request.old_exercise_name.lower():
                exercise_found = True

                # Get new exercise details from library
                exercise_lib = get_exercise_library_service()
                new_exercise_data = exercise_lib.search_exercises(request.new_exercise_name, limit=1)

                if new_exercise_data:
                    new_ex = new_exercise_data[0]
                    # Preserve sets/reps from old exercise, update other fields
                    exercises[i] = {
                        **exercise,  # Keep original sets, reps, rest_seconds
                        "name": new_ex.get("name", request.new_exercise_name),
                        "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part") or exercise.get("muscle_group"),
                        "equipment": new_ex.get("equipment") or exercise.get("equipment"),
                        "notes": new_ex.get("instructions") or exercise.get("notes", ""),
                        "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                        "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                        "library_id": new_ex.get("id"),
                    }
                else:
                    # Just update the name if exercise not found in library
                    exercises[i]["name"] = request.new_exercise_name
                break

        if not exercise_found:
            raise HTTPException(status_code=404, detail=f"Exercise '{request.old_exercise_name}' not found in workout")

        # Update the workout
        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_swap"
        }

        updated = db.update_workout(request.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        # Log the change
        log_workout_change(
            request.workout_id,
            workout.get("user_id"),
            "exercise_swap",
            "exercises_json",
            request.old_exercise_name,
            request.new_exercise_name
        )

        updated_workout = row_to_workout(updated)
        logger.info(f"Exercise swapped successfully in workout {request.workout_id}")

        # Re-index to RAG
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/add-exercise", response_model=Workout)
async def add_exercise_to_workout(request: AddExerciseRequest):
    """Add a new exercise to an existing workout."""
    logger.info(f"Adding exercise '{request.exercise_name}' to workout {request.workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Parse existing exercises
        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        # Get exercise details from library
        exercise_lib = get_exercise_library_service()
        exercise_data = exercise_lib.search_exercises(request.exercise_name, limit=1)

        if exercise_data:
            new_ex = exercise_data[0]
            new_exercise = {
                "name": new_ex.get("name", request.exercise_name),
                "sets": request.sets,
                "reps": request.reps,
                "rest_seconds": request.rest_seconds,
                "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part"),
                "equipment": new_ex.get("equipment"),
                "notes": new_ex.get("instructions", ""),
                "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                "library_id": new_ex.get("id"),
            }
        else:
            # Create basic exercise entry if not found in library
            new_exercise = {
                "name": request.exercise_name,
                "sets": request.sets,
                "reps": request.reps,
                "rest_seconds": request.rest_seconds,
            }

        # Append the new exercise
        exercises.append(new_exercise)

        # Update the workout
        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_add"
        }

        updated = db.update_workout(request.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        # Log the change
        log_workout_change(
            request.workout_id,
            workout.get("user_id"),
            "exercise_add",
            "exercises_json",
            None,
            request.exercise_name
        )

        updated_workout = row_to_workout(updated)
        logger.info(f"Exercise '{request.exercise_name}' added successfully to workout {request.workout_id}")

        # Re-index to RAG
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-weekly", response_model=GenerateWeeklyResponse)
async def generate_weekly_workouts(request: GenerateWeeklyRequest):
    """Generate workouts for multiple days in a week."""
    logger.info(f"Generating weekly workouts for user {request.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        # Get all equipment including custom user-added equipment
        equipment = get_all_equipment(user)
        preferences = parse_json_field(user.get("preferences"), {})
        training_split = preferences.get("training_split", "full_body")
        intensity_preference = preferences.get("intensity_preference", "medium")
        # Get workout type preference (strength, cardio, mixed) - addresses competitor feedback
        workout_type_preference = preferences.get("workout_type_preference", "strength")
        # Get custom program description for custom training goals
        custom_program_description = preferences.get("custom_program_description")
        # Get equipment counts for single dumbbell/kettlebell filtering
        dumbbell_count = preferences.get("dumbbell_count", 2)
        kettlebell_count = preferences.get("kettlebell_count", 1)
        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")
        # Get focus areas for custom programs
        focus_areas = parse_json_field(user.get("focus_areas"), [])

        # Fetch user's custom exercises for weekly generation
        logger.info(f"🏋️ [Weekly Generation] Fetching custom exercises for user: {request.user_id}")
        custom_exercises = []
        try:
            custom_result = db.client.table("exercises").select(
                "name", "primary_muscle", "equipment", "default_sets", "default_reps"
            ).eq("is_custom", True).eq("created_by_user_id", request.user_id).execute()
            if custom_result.data:
                custom_exercises = custom_result.data
                exercise_names = [ex.get("name") for ex in custom_exercises]
                logger.info(f"✅ [Weekly Generation] Found {len(custom_exercises)} custom exercises: {exercise_names}")
            else:
                logger.info(f"🏋️ [Weekly Generation] No custom exercises found for user {request.user_id}")
        except Exception as e:
            logger.warning(f"⚠️ [Weekly Generation] Failed to fetch custom exercises: {e}")

        workout_focus_map = get_workout_focus(training_split, request.selected_days, focus_areas)
        generated_workouts = []
        gemini_service = GeminiService()
        exercise_rag = get_exercise_rag_service()

        # Start with exercises from recent days to ensure cross-week variety
        used_exercises: List[str] = await get_recently_used_exercises(request.user_id, days=7)
        logger.info(f"Starting weekly generation with {len(used_exercises)} recently used exercises")

        # Get adaptive workout service for varied parameters
        from services.adaptive_workout_service import get_adaptive_workout_service
        adaptive_service = get_adaptive_workout_service(db.client)

        for day_index in request.selected_days:
            workout_date = calculate_workout_date(request.week_start_date, day_index)
            focus = workout_focus_map[day_index]

            # Get adaptive parameters for this workout
            try:
                adaptive_params = await adaptive_service.get_adaptive_parameters(
                    user_id=request.user_id,
                    workout_type=focus,
                    user_goals=goals if isinstance(goals, list) else [],
                )
            except Exception as adapt_err:
                logger.warning(f"Adaptive params failed for weekly: {adapt_err}, using defaults")
                adaptive_params = None

            try:
                # Use RAG to intelligently select exercises with adaptive params
                rag_exercises = await exercise_rag.select_exercises_for_workout(
                    focus_area=focus,
                    equipment=equipment if isinstance(equipment, list) else [],
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    count=6,
                    avoid_exercises=used_exercises,
                    workout_params=adaptive_params,
                    dumbbell_count=dumbbell_count,
                    kettlebell_count=kettlebell_count,
                    user_id=request.user_id,  # For custom goal keywords
                )

                if rag_exercises:
                    used_exercises.extend([ex.get("name", "") for ex in rag_exercises])

                    # Get the effective workout focus from adaptive params (maps focus->workout type)
                    effective_focus = adaptive_params.get("workout_focus", "hypertrophy") if adaptive_params else "hypertrophy"

                    # Apply supersets if appropriate (only for hypertrophy/endurance/hiit)
                    if adaptive_params and adaptive_service.should_use_supersets(
                        effective_focus, request.duration_minutes or 45, len(rag_exercises)
                    ):
                        rag_exercises = adaptive_service.create_superset_pairs(rag_exercises)
                        logger.info(f"Applied supersets to weekly {focus} ({effective_focus}) workout")

                    # Add AMRAP finisher if appropriate
                    if adaptive_params and adaptive_service.should_include_amrap(
                        effective_focus, fitness_level or "intermediate"
                    ):
                        amrap_exercise = adaptive_service.create_amrap_finisher(rag_exercises, effective_focus)
                        rag_exercises.append(amrap_exercise)
                        logger.info(f"Added AMRAP finisher: {amrap_exercise['name']}")

                    workout_data = await gemini_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level,
                        intensity_preference=intensity_preference,
                        custom_program_description=custom_program_description,
                        workout_type_preference=workout_type_preference
                    )
                else:
                    workout_data = await gemini_service.generate_workout_plan(
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        equipment=equipment if isinstance(equipment, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level,
                        intensity_preference=intensity_preference,
                        custom_program_description=custom_program_description,
                        workout_type_preference=workout_type_preference,
                        custom_exercises=custom_exercises if custom_exercises else None
                    )

                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", f"{focus.title()} Workout")
                workout_type = workout_data.get("type", "strength")
                difficulty = workout_data.get("difficulty", intensity_preference)

            except Exception as e:
                logger.error(f"Error generating workout: {e}")
                exercises = [{"name": "Push-ups", "sets": 3, "reps": 12}, {"name": "Squats", "sets": 3, "reps": 15}]
                workout_name = f"{focus.title()} Workout"
                workout_type = "strength"
                difficulty = intensity_preference

            workout_db_data = {
                "user_id": request.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "scheduled_date": workout_date.isoformat(),
                "exercises_json": exercises,
                "duration_minutes": request.duration_minutes or 45,
                "generation_method": "ai",
                "generation_source": "weekly_generation",
            }

            created = db.create_workout(workout_db_data)
            workout = row_to_workout(created)
            await index_workout_to_rag(workout)
            generated_workouts.append(workout)

        return GenerateWeeklyResponse(workouts=generated_workouts)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate weekly workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-monthly", response_model=GenerateMonthlyResponse)
async def generate_monthly_workouts(request: GenerateMonthlyRequest):
    """Generate workouts for a full month."""
    logger.info(f"Generating monthly workouts for user {request.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        equipment = get_all_equipment(user)  # Includes custom equipment
        preferences = parse_json_field(user.get("preferences"), {})
        training_split = preferences.get("training_split", "full_body")
        intensity_preference = preferences.get("intensity_preference", "medium")
        # Get custom program description for custom training goals
        custom_program_description = preferences.get("custom_program_description")
        # Get equipment counts for single dumbbell/kettlebell filtering
        dumbbell_count = preferences.get("dumbbell_count", 2)
        kettlebell_count = preferences.get("kettlebell_count", 1)

        # Get injuries and health conditions for workout safety
        active_injuries = parse_json_field(user.get("active_injuries"), [])
        health_conditions = preferences.get("health_conditions", [])

        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        # Get focus areas for custom programs
        focus_areas = parse_json_field(user.get("focus_areas"), [])

        # Fetch user's custom exercises for monthly generation
        logger.info(f"🏋️ [Monthly Generation] Fetching custom exercises for user: {request.user_id}")
        custom_exercises = []
        try:
            custom_result = db.client.table("exercises").select(
                "name", "primary_muscle", "equipment", "default_sets", "default_reps"
            ).eq("is_custom", True).eq("created_by_user_id", request.user_id).execute()
            if custom_result.data:
                custom_exercises = custom_result.data
                exercise_names = [ex.get("name") for ex in custom_exercises]
                logger.info(f"✅ [Monthly Generation] Found {len(custom_exercises)} custom exercises: {exercise_names}")
            else:
                logger.info(f"🏋️ [Monthly Generation] No custom exercises found for user {request.user_id}")
        except Exception as e:
            logger.warning(f"⚠️ [Monthly Generation] Failed to fetch custom exercises: {e}")

        logger.info(f"User data - fitness_level: {fitness_level}, goals: {goals}, equipment: {equipment}, dumbbell_count: {dumbbell_count}, kettlebell_count: {kettlebell_count}")
        if active_injuries or health_conditions:
            logger.info(f"User health info - injuries: {active_injuries}, conditions: {health_conditions}")

        # Cap weeks at 4 to prevent generating workouts too far in the future
        MAX_GENERATION_WEEKS = 4
        weeks = min(request.weeks or 4, MAX_GENERATION_WEEKS)

        # Also cap the date range to prevent generating workouts beyond 4 weeks from today
        today = datetime.now().date()
        max_horizon = today + timedelta(days=28)  # 4 weeks from today

        workout_dates = calculate_monthly_dates(request.month_start_date, request.selected_days, weeks)

        # Filter out any dates beyond our horizon
        workout_dates = [d for d in workout_dates if d.date() <= max_horizon]

        logger.info(f"Calculated {len(workout_dates)} workout dates for {weeks} weeks on days {request.selected_days} (capped at {max_horizon})")

        if not workout_dates:
            logger.warning("No workout dates calculated - returning empty response")
            return GenerateMonthlyResponse(workouts=[], total_generated=0)

        workout_focus_map = get_workout_focus(training_split, request.selected_days, focus_areas)

        used_name_words: List[str] = []
        generated_workouts = []
        gemini_service = GeminiService()

        BATCH_SIZE = 4

        # Get exercise RAG service for intelligent selection
        exercise_rag = get_exercise_rag_service()

        # Get adaptive workout service for varied parameters
        from services.adaptive_workout_service import get_adaptive_workout_service
        adaptive_service = get_adaptive_workout_service(db.client)

        # Track used exercises for variety - use a thread-safe approach
        used_exercises: List[str] = await get_recently_used_exercises(request.user_id, days=7)
        logger.info(f"Starting with {len(used_exercises)} recently used exercises to ensure variety")

        async def generate_single_workout(
            workout_date: datetime,
            index: int,
            avoid_words: List[str],
            exercises_to_avoid: List[str]
        ):
            weekday = workout_date.weekday()
            focus = workout_focus_map.get(weekday, "full_body")

            # Get adaptive parameters for this workout based on focus and user history
            try:
                adaptive_params = await adaptive_service.get_adaptive_parameters(
                    user_id=request.user_id,
                    workout_type=focus,
                    user_goals=goals if isinstance(goals, list) else [],
                )
                logger.info(f"Adaptive params for {focus}: sets={adaptive_params.get('sets')}, reps={adaptive_params.get('reps')}")
            except Exception as adapt_err:
                logger.warning(f"Adaptive params failed: {adapt_err}, using defaults")
                adaptive_params = None

            try:
                # Use RAG to intelligently select exercises from ChromaDB/Supabase
                rag_exercises = await exercise_rag.select_exercises_for_workout(
                    focus_area=focus,
                    equipment=equipment if isinstance(equipment, list) else [],
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    count=6,
                    avoid_exercises=exercises_to_avoid,
                    injuries=active_injuries if active_injuries else None,
                    workout_params=adaptive_params,
                    dumbbell_count=dumbbell_count,
                    kettlebell_count=kettlebell_count,
                    user_id=request.user_id,  # For custom goal keywords
                )

                # Return the exercises used so they can be tracked after batch completes
                exercises_used = []
                if rag_exercises:
                    exercises_used = [ex.get("name", "") for ex in rag_exercises]

                    # Get the effective workout focus from adaptive params
                    effective_focus = adaptive_params.get("workout_focus", "hypertrophy") if adaptive_params else "hypertrophy"

                    # Apply supersets if appropriate
                    if adaptive_params and adaptive_service.should_use_supersets(
                        effective_focus, request.duration_minutes or 45, len(rag_exercises)
                    ):
                        rag_exercises = adaptive_service.create_superset_pairs(rag_exercises)
                        logger.info(f"Applied supersets to {focus} ({effective_focus}) workout")

                    # Add AMRAP finisher if appropriate
                    if adaptive_params and adaptive_service.should_include_amrap(
                        effective_focus, fitness_level or "intermediate"
                    ):
                        amrap_exercise = adaptive_service.create_amrap_finisher(rag_exercises, effective_focus)
                        rag_exercises.append(amrap_exercise)
                        logger.info(f"Added AMRAP finisher: {amrap_exercise['name']}")

                    # Use AI to create a creative workout name
                    workout_data = await gemini_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level,
                        intensity_preference=intensity_preference,
                        custom_program_description=custom_program_description
                    )
                else:
                    # No fallback - RAG must return exercises
                    logger.error(f"RAG returned no exercises for {focus}")
                    raise ValueError(f"RAG returned no exercises for focus={focus}")

                return {
                    "success": True,
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": workout_data.get("name", f"{focus.title()} Workout"),
                    "type": workout_data.get("type", "strength"),
                    "difficulty": workout_data.get("difficulty", intensity_preference),
                    "exercises": workout_data.get("exercises", []),
                    "exercises_used": exercises_used,
                }

            except Exception as e:
                logger.error(f"Error generating workout for {workout_date}: {e}")
                raise  # No fallback - let errors propagate

        for batch_start in range(0, len(workout_dates), BATCH_SIZE):
            batch_end = min(batch_start + BATCH_SIZE, len(workout_dates))
            batch_dates = workout_dates[batch_start:batch_end]

            # Create STAGGERED avoid lists for each workout in the batch
            # Each concurrent workout gets a different offset of exercises to avoid
            # This ensures variety even when workouts are generated in parallel
            tasks = []
            for i, date in enumerate(batch_dates):
                # Stagger by 8 exercises per workout in the batch
                # Workout 0: last 30 exercises, Workout 1: last 38, Workout 2: last 46, etc.
                offset = i * 8
                if used_exercises:
                    avoid_list = used_exercises[-(30 + offset):].copy()
                else:
                    avoid_list = []
                tasks.append(generate_single_workout(
                    date,
                    batch_start + i,
                    used_name_words.copy(),
                    avoid_list
                ))
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            for result in batch_results:
                if isinstance(result, Exception):
                    continue

                name_words = extract_name_words(result["name"])
                used_name_words.extend(name_words)

                # Track used exercises for variety in next batches
                exercises_used_in_workout = result.get("exercises_used", [])
                if exercises_used_in_workout:
                    used_exercises.extend(exercises_used_in_workout)
                    logger.debug(f"Added {len(exercises_used_in_workout)} exercises to avoid list. Total: {len(used_exercises)}")

                workout_db_data = {
                    "user_id": request.user_id,
                    "name": result["name"],
                    "type": result["type"],
                    "difficulty": result["difficulty"],
                    "scheduled_date": result["workout_date"].isoformat(),
                    "exercises_json": result["exercises"],
                    "duration_minutes": request.duration_minutes or 45,
                    "generation_method": "ai",
                    "generation_source": "monthly_generation",
                }

                created = db.create_workout(workout_db_data)
                workout = row_to_workout(created)
                await index_workout_to_rag(workout)
                generated_workouts.append(workout)

                # Generate warmup and stretches alongside workout
                try:
                    warmup_stretch_service = get_warmup_stretch_service()
                    exercises = result["exercises"]

                    # Generate and save warmup
                    await warmup_stretch_service.create_warmup_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None,
                        user_id=request.user_id
                    )

                    # Generate and save stretches
                    await warmup_stretch_service.create_stretches_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None,
                        user_id=request.user_id
                    )
                    logger.info(f"Generated warmup and stretches for workout {workout.id}")
                except Exception as ws_error:
                    logger.warning(f"Failed to generate warmup/stretches for workout {workout.id}: {ws_error}")

        return GenerateMonthlyResponse(workouts=generated_workouts, total_generated=len(generated_workouts))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate monthly workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-monthly-stream")
@limiter.limit("3/minute")
async def generate_monthly_workouts_streaming(request: Request, body: GenerateMonthlyRequest):
    """
    Generate workouts for 2 weeks with streaming progress updates via SSE.

    Sends real-time progress as each workout is generated:
    - event: progress - "Generating next workout..." with step count
    - event: workout - Individual workout created (can be used to update UI immediately)
    - event: done - All workouts complete
    - event: error - Error during generation
    """
    import time
    logger.info(f"[STREAM] Generating monthly workouts for user {body.user_id}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(current: int, total: int, message: str, detail: str = None):
            data = {
                "type": "progress",
                "current": current,
                "total": total,
                "message": message,
                "detail": detail,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_workout(workout_data: dict, current: int, total: int):
            data = {
                "type": "workout",
                "workout": workout_data,
                "current": current,
                "total": total,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: workout\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            data = {"type": "error", "error": error, "elapsed_ms": elapsed_ms()}
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            yield send_progress(0, 1, "Loading your profile...", "Fetching preferences")

            db = get_supabase_db()

            user = db.get_user(body.user_id)
            if not user:
                yield send_error("User not found")
                return

            fitness_level = user.get("fitness_level") or "intermediate"
            goals = parse_json_field(user.get("goals"), [])
            equipment = get_all_equipment(user)  # Includes custom equipment
            preferences = parse_json_field(user.get("preferences"), {})
            training_split = preferences.get("training_split", "full_body")
            intensity_preference = preferences.get("intensity_preference", "medium")
            custom_program_description = preferences.get("custom_program_description")
            dumbbell_count = preferences.get("dumbbell_count", 2)
            kettlebell_count = preferences.get("kettlebell_count", 1)
            active_injuries = parse_json_field(user.get("active_injuries"), [])
            user_age = user.get("age")
            user_activity_level = user.get("activity_level")
            focus_areas = parse_json_field(user.get("focus_areas"), [])

            # Always generate exactly 2 weeks
            weeks = 2
            today = datetime.now().date()
            max_horizon = today + timedelta(days=14)

            workout_dates = calculate_monthly_dates(body.month_start_date, body.selected_days, weeks)
            workout_dates = [d for d in workout_dates if d.date() <= max_horizon]

            if not workout_dates:
                yield send_error("No workout dates calculated")
                return

            total_workouts = len(workout_dates)
            logger.info(f"[STREAM] Will generate {total_workouts} workouts for 2 weeks")

            yield send_progress(0, total_workouts, "Planning your workouts...", f"{total_workouts} workouts to generate")

            workout_focus_map = get_workout_focus(training_split, body.selected_days, focus_areas)
            used_name_words: List[str] = []
            generated_workouts = []
            gemini_service = GeminiService()
            exercise_rag = get_exercise_rag_service()

            from services.adaptive_workout_service import get_adaptive_workout_service
            adaptive_service = get_adaptive_workout_service(db.client)

            used_exercises: List[str] = await get_recently_used_exercises(body.user_id, days=7)

            # Generate workouts one at a time with progress updates
            for idx, workout_date in enumerate(workout_dates):
                current = idx + 1
                weekday = workout_date.weekday()
                focus = workout_focus_map.get(weekday, "full_body")

                yield send_progress(current, total_workouts, "Generating next workout...", f"Day {current} of {total_workouts}")

                try:
                    # Get adaptive parameters
                    adaptive_params = None
                    try:
                        adaptive_params = await adaptive_service.get_adaptive_parameters(
                            user_id=body.user_id,
                            workout_type=focus,
                            user_goals=goals if isinstance(goals, list) else [],
                        )
                    except Exception:
                        pass

                    # Select exercises via RAG
                    avoid_list = used_exercises[-30:].copy() if used_exercises else []
                    rag_exercises = await exercise_rag.select_exercises_for_workout(
                        focus_area=focus,
                        equipment=equipment if isinstance(equipment, list) else [],
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        count=6,
                        avoid_exercises=avoid_list,
                        injuries=active_injuries if active_injuries else None,
                        workout_params=adaptive_params,
                        dumbbell_count=dumbbell_count,
                        kettlebell_count=kettlebell_count,
                        user_id=body.user_id,
                    )

                    if not rag_exercises:
                        logger.error(f"[STREAM] RAG returned no exercises for {focus}")
                        continue

                    exercises_used = [ex.get("name", "") for ex in rag_exercises]
                    used_exercises.extend(exercises_used)

                    # Generate workout name with AI
                    workout_data = await gemini_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=body.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=used_name_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level,
                        intensity_preference=intensity_preference,
                        custom_program_description=custom_program_description
                    )

                    name_words = extract_name_words(workout_data.get("name", ""))
                    used_name_words.extend(name_words)

                    # Save to database
                    workout_db_data = {
                        "user_id": body.user_id,
                        "name": workout_data.get("name", f"{focus.title()} Workout"),
                        "type": workout_data.get("type", "strength"),
                        "difficulty": workout_data.get("difficulty", intensity_preference),
                        "scheduled_date": workout_date.isoformat(),
                        "exercises_json": workout_data.get("exercises", []),
                        "duration_minutes": body.duration_minutes or 45,
                        "generation_method": "ai",
                        "generation_source": "streaming_monthly_generation",
                    }

                    created = db.create_workout(workout_db_data)
                    workout = row_to_workout(created)
                    asyncio.create_task(index_workout_to_rag(workout))
                    generated_workouts.append(workout)

                    # Generate warmup/stretches (fire-and-forget)
                    try:
                        warmup_stretch_service = get_warmup_stretch_service()
                        asyncio.create_task(warmup_stretch_service.create_warmup_for_workout(
                            workout_id=workout.id,
                            exercises=workout_data.get("exercises", []),
                            duration_minutes=5,
                            injuries=active_injuries if active_injuries else None,
                            user_id=body.user_id
                        ))
                        asyncio.create_task(warmup_stretch_service.create_stretches_for_workout(
                            workout_id=workout.id,
                            exercises=workout_data.get("exercises", []),
                            duration_minutes=5,
                            injuries=active_injuries if active_injuries else None,
                            user_id=body.user_id
                        ))
                    except Exception:
                        pass

                    # Send the workout that was just created
                    workout_response = {
                        "id": workout.id,
                        "name": workout.name,
                        "type": workout.type,
                        "difficulty": workout.difficulty,
                        "scheduled_date": workout.scheduled_date.isoformat() if workout.scheduled_date else None,
                        "duration_minutes": workout.duration_minutes,
                    }
                    yield send_workout(workout_response, current, total_workouts)

                except Exception as e:
                    logger.error(f"[STREAM] Error generating workout {current}: {e}")
                    # Continue with next workout instead of failing entirely
                    continue

            # Send completion
            done_data = {
                "type": "done",
                "total_generated": len(generated_workouts),
                "total_time_ms": elapsed_ms(),
                "workouts": [
                    {
                        "id": w.id,
                        "name": w.name,
                        "scheduled_date": w.scheduled_date.isoformat() if w.scheduled_date else None,
                    }
                    for w in generated_workouts
                ]
            }
            yield f"event: done\ndata: {json.dumps(done_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Monthly generation error: {e}")
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


@router.post("/generate-remaining", response_model=GenerateMonthlyResponse)
async def generate_remaining_workouts(request: GenerateMonthlyRequest):
    """Generate remaining workouts for the month, skipping existing ones."""
    logger.info(f"Generating remaining workouts for user {request.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        equipment = get_all_equipment(user)  # Includes custom equipment
        preferences = parse_json_field(user.get("preferences"), {})
        training_split = preferences.get("training_split", "full_body")
        intensity_preference = preferences.get("intensity_preference", "medium")
        # Get custom program description for custom training goals
        custom_program_description = preferences.get("custom_program_description")
        # Get equipment counts for single dumbbell/kettlebell filtering
        dumbbell_count = preferences.get("dumbbell_count", 2)
        kettlebell_count = preferences.get("kettlebell_count", 1)

        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        # Get focus areas for custom programs
        focus_areas = parse_json_field(user.get("focus_areas"), [])

        # Extract active injuries for safety filtering
        injuries_data = parse_json_field(user.get("injuries"), [])
        active_injuries = [
            inj.get("type", "") for inj in injuries_data
            if inj.get("status") == "active" and inj.get("type")
        ]
        if active_injuries:
            logger.info(f"User has active injuries for remaining workouts: {active_injuries}")

        # Cap at 4 weeks to prevent generating workouts too far in the future
        MAX_GENERATION_WEEKS = 4
        today = datetime.now().date()
        max_horizon = today + timedelta(days=28)  # 4 weeks from today

        all_workout_dates = calculate_monthly_dates(request.month_start_date, request.selected_days, MAX_GENERATION_WEEKS)

        # Filter out any dates beyond our horizon
        all_workout_dates = [d for d in all_workout_dates if d.date() <= max_horizon]

        # Get existing workout dates
        from calendar import monthrange
        year = int(request.month_start_date[:4])
        month = int(request.month_start_date[5:7])
        last_day = monthrange(year, month)[1]

        existing_workouts = db.get_workouts_by_date_range(
            request.user_id,
            request.month_start_date,
            f"{request.month_start_date[:7]}-{last_day:02d}"
        )
        existing_dates = {str(w.get("scheduled_date", ""))[:10] for w in existing_workouts}

        workout_dates = [d for d in all_workout_dates if str(d.date()) not in existing_dates]

        logger.info(f"Generating remaining workouts: {len(workout_dates)} dates (capped at {max_horizon})")

        if not workout_dates:
            return GenerateMonthlyResponse(workouts=[], total_generated=0)

        workout_focus_map = get_workout_focus(training_split, request.selected_days, focus_areas)

        # Get existing workout names for variety
        existing_names = [w.get("name", "") for w in existing_workouts]
        used_name_words: List[str] = []
        for name in existing_names:
            used_name_words.extend(extract_name_words(name))

        generated_workouts = []
        gemini_service = GeminiService()
        exercise_rag = get_exercise_rag_service()

        # Start with exercises from recent days to ensure cross-week variety
        used_exercises: List[str] = await get_recently_used_exercises(request.user_id, days=7)
        logger.info(f"Starting remaining generation with {len(used_exercises)} recently used exercises")

        # Get adaptive workout service for varied parameters
        from services.adaptive_workout_service import get_adaptive_workout_service
        adaptive_service = get_adaptive_workout_service(db.client)

        BATCH_SIZE = 4

        async def generate_single_workout(
            workout_date: datetime,
            avoid_words: List[str],
            exercises_to_avoid: List[str]
        ):
            weekday = workout_date.weekday()
            focus = workout_focus_map.get(weekday, "full_body")

            # Get adaptive parameters for this workout based on focus and user history
            try:
                adaptive_params = await adaptive_service.get_adaptive_parameters(
                    user_id=request.user_id,
                    workout_type=focus,
                    user_goals=goals if isinstance(goals, list) else [],
                )
                logger.info(f"Adaptive params for regeneration ({focus}): sets={adaptive_params.get('sets')}, reps={adaptive_params.get('reps')}")
            except Exception as adapt_err:
                logger.warning(f"Adaptive params failed for regeneration: {adapt_err}, using defaults")
                adaptive_params = None

            try:
                # Use RAG to intelligently select exercises
                rag_exercises = await exercise_rag.select_exercises_for_workout(
                    focus_area=focus,
                    equipment=equipment if isinstance(equipment, list) else [],
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    count=6,
                    avoid_exercises=exercises_to_avoid,
                    injuries=active_injuries if active_injuries else None,
                    workout_params=adaptive_params,
                    dumbbell_count=dumbbell_count,
                    kettlebell_count=kettlebell_count,
                    user_id=request.user_id,  # For custom goal keywords
                )

                exercises_used = []
                if rag_exercises:
                    exercises_used = [ex.get("name", "") for ex in rag_exercises]

                    # Get the effective workout focus from adaptive params
                    effective_focus = adaptive_params.get("workout_focus", "hypertrophy") if adaptive_params else "hypertrophy"

                    # Apply supersets if appropriate
                    if adaptive_params and adaptive_service.should_use_supersets(
                        effective_focus, request.duration_minutes or 45, len(rag_exercises)
                    ):
                        rag_exercises = adaptive_service.create_superset_pairs(rag_exercises)
                        logger.info(f"Applied supersets to regenerated {focus} ({effective_focus}) workout")

                    # Add AMRAP finisher if appropriate
                    if adaptive_params and adaptive_service.should_include_amrap(
                        effective_focus, fitness_level or "intermediate"
                    ):
                        amrap_exercise = adaptive_service.create_amrap_finisher(rag_exercises, effective_focus)
                        rag_exercises.append(amrap_exercise)
                        logger.info(f"Added AMRAP finisher to regenerated workout: {amrap_exercise['name']}")

                    workout_data = await gemini_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level,
                        intensity_preference=intensity_preference,
                        custom_program_description=custom_program_description
                    )
                else:
                    workout_data = await gemini_service.generate_workout_plan(
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        equipment=equipment if isinstance(equipment, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level,
                        intensity_preference=intensity_preference,
                        custom_program_description=custom_program_description,
                        custom_exercises=custom_exercises if custom_exercises else None
                    )

                return {
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": workout_data.get("name", f"{focus.title()} Workout"),
                    "type": workout_data.get("type", "strength"),
                    "difficulty": workout_data.get("difficulty", intensity_preference),
                    "exercises": workout_data.get("exercises", []),
                    "exercises_used": exercises_used,
                }

            except Exception as e:
                logger.error(f"Error generating remaining workout: {e}")
                return {
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": f"{focus.title()} Workout",
                    "type": "strength",
                    "difficulty": intensity_preference,
                    "exercises": [{"name": "Push-ups", "sets": 3, "reps": 12}],
                    "exercises_used": ["Push-ups"],
                }

        for batch_start in range(0, len(workout_dates), BATCH_SIZE):
            batch_end = min(batch_start + BATCH_SIZE, len(workout_dates))
            batch_dates = workout_dates[batch_start:batch_end]

            # Create STAGGERED avoid lists for each workout in the batch
            # Each concurrent workout gets a different offset of exercises to avoid
            # This ensures variety even when workouts are generated in parallel
            tasks = []
            for i, date in enumerate(batch_dates):
                # Stagger by 8 exercises per workout in the batch
                offset = i * 8
                if used_exercises:
                    avoid_list = used_exercises[-(30 + offset):].copy()
                else:
                    avoid_list = []
                tasks.append(generate_single_workout(
                    date,
                    used_name_words.copy(),
                    avoid_list
                ))
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            for result in batch_results:
                if isinstance(result, Exception):
                    continue

                name_words = extract_name_words(result["name"])
                used_name_words.extend(name_words)

                # Track used exercises for variety in next batches
                exercises_used_in_workout = result.get("exercises_used", [])
                if exercises_used_in_workout:
                    used_exercises.extend(exercises_used_in_workout)

                workout_db_data = {
                    "user_id": request.user_id,
                    "name": result["name"],
                    "type": result["type"],
                    "difficulty": result["difficulty"],
                    "scheduled_date": result["workout_date"].isoformat(),
                    "exercises_json": result["exercises"],
                    "duration_minutes": request.duration_minutes or 45,
                    "generation_method": "ai",
                    "generation_source": "background_generation",
                }

                created = db.create_workout(workout_db_data)
                workout = row_to_workout(created)
                await index_workout_to_rag(workout)

                # Generate warmup and stretches alongside workout
                try:
                    warmup_stretch_service = get_warmup_stretch_service()
                    exercises = result["exercises"]

                    # Generate and save warmup
                    await warmup_stretch_service.create_warmup_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None,
                        user_id=request.user_id
                    )

                    # Generate and save stretches
                    await warmup_stretch_service.create_stretches_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None,
                        user_id=request.user_id
                    )
                    logger.info(f"Generated warmup and stretches for remaining workout {workout.id}")
                except Exception as ws_error:
                    logger.warning(f"Failed to generate warmup/stretches for remaining workout {workout.id}: {ws_error}")

                generated_workouts.append(workout)

        return GenerateMonthlyResponse(workouts=generated_workouts, total_generated=len(generated_workouts))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate remaining workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))
