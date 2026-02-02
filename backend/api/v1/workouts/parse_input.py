"""
Workout input parsing API endpoints.

This module handles AI-powered parsing of natural language workout input:
- POST /parse-input - Parse text/image/voice input into structured exercises (legacy)
- POST /parse-input-v2 - Dual-mode parsing: sets for current exercise + new exercises
- POST /add-exercises-batch - Add multiple parsed exercises to a workout
"""
import json
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import Workout
from services.gemini_service import GeminiService
from services.exercise_library_service import get_exercise_library_service
from core.rate_limiter import limiter

from .utils import row_to_workout, parse_json_field

logger = get_logger("workout_parse_input")

router = APIRouter(tags=["workout-parse-input"])


# =============================================================================
# REQUEST/RESPONSE MODELS
# =============================================================================

class ParseWorkoutInputRequest(BaseModel):
    """Request to parse natural language workout input (legacy)."""
    user_id: str = Field(..., description="User ID")
    workout_id: str = Field(..., description="Workout ID to add exercises to")
    input_text: Optional[str] = Field(default=None, description="Natural language text input")
    image_base64: Optional[str] = Field(default=None, description="Base64 encoded image")
    voice_transcript: Optional[str] = Field(default=None, description="Transcribed voice input")
    use_kg: bool = Field(default=False, description="User's weight unit preference")


class ParseWorkoutInputV2Request(BaseModel):
    """Request for dual-mode workout input parsing.

    Supports BOTH:
    1. Set logging: "135*8, 145*6" -> logs sets for current exercise
    2. Add exercise: "3x10 deadlift at 135" -> adds new exercise
    """
    user_id: str = Field(..., description="User ID")
    workout_id: str = Field(..., description="Workout ID")
    # Context for set logging
    current_exercise_name: Optional[str] = Field(default=None, description="Name of current exercise (for set logging)")
    current_exercise_index: Optional[int] = Field(default=None, description="Index of current exercise in workout")
    last_set_weight: Optional[float] = Field(default=None, description="Weight from last logged set (for +10, same, drop shortcuts)")
    last_set_reps: Optional[int] = Field(default=None, description="Reps from last logged set (for shortcuts)")
    # Input types
    input_text: Optional[str] = Field(default=None, description="Natural language text input")
    image_base64: Optional[str] = Field(default=None, description="Base64 encoded image")
    voice_transcript: Optional[str] = Field(default=None, description="Transcribed voice input")
    use_kg: bool = Field(default=False, description="User's weight unit preference")


class ParsedExerciseItem(BaseModel):
    """A single parsed exercise."""
    name: str
    sets: int = 3
    reps: int = 10
    weight_kg: Optional[float] = None
    weight_lbs: Optional[float] = None
    weight_unit: str = "lbs"
    rest_seconds: int = 60
    original_text: str
    confidence: float = 1.0
    notes: Optional[str] = None


class ParseWorkoutInputResponse(BaseModel):
    """Response with parsed exercises (legacy)."""
    exercises: List[ParsedExerciseItem]
    summary: str
    warnings: List[str] = []


# V2 Response Models for dual-mode parsing
class SetToLogResponse(BaseModel):
    """A single set to log for the current exercise."""
    weight: float = Field(..., description="Weight value (0 for bodyweight)")
    reps: int = Field(..., description="Number of reps")
    unit: str = Field(default="lbs", description="Weight unit")
    is_bodyweight: bool = Field(default=False, description="True for bodyweight exercises")
    is_failure: bool = Field(default=False, description="True if to failure/AMRAP")
    is_warmup: bool = Field(default=False, description="True if warmup set")
    original_input: str = Field(default="", description="Original text that produced this set")
    notes: Optional[str] = None


class ExerciseToAddResponse(BaseModel):
    """A new exercise to add to the workout."""
    name: str = Field(..., description="Exercise name")
    sets: int = Field(default=3, description="Number of sets")
    reps: int = Field(default=10, description="Reps per set")
    weight_kg: Optional[float] = None
    weight_lbs: Optional[float] = None
    rest_seconds: int = Field(default=60, description="Rest between sets")
    is_bodyweight: bool = Field(default=False, description="True for bodyweight exercises")
    original_text: str = Field(default="", description="Original text")
    confidence: float = Field(default=1.0, description="Parsing confidence")
    notes: Optional[str] = None


class ParseWorkoutInputV2Response(BaseModel):
    """Response for dual-mode workout input parsing.

    Contains BOTH:
    - sets_to_log: Sets for the current exercise (just weight*reps)
    - exercises_to_add: New exercises to add (contains exercise names)
    """
    sets_to_log: List[SetToLogResponse] = Field(default=[], description="Sets to log for current exercise")
    exercises_to_add: List[ExerciseToAddResponse] = Field(default=[], description="New exercises to add")
    summary: str = Field(..., description="Human-readable summary")
    warnings: List[str] = Field(default=[], description="Any parsing warnings")


class BatchAddExercisesRequest(BaseModel):
    """Request to add multiple exercises to a workout."""
    workout_id: str = Field(..., description="Workout ID to add exercises to")
    user_id: str = Field(..., description="User ID for ownership verification")
    exercises: List[ParsedExerciseItem] = Field(..., description="Exercises to add")
    use_kg: bool = Field(default=False, description="User's weight unit preference")


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/parse-input", response_model=ParseWorkoutInputResponse)
@limiter.limit("20/minute")
async def parse_workout_input(request: Request, body: ParseWorkoutInputRequest):
    """
    Parse natural language workout input using AI.

    Accepts text, image, or voice transcript and returns structured exercise data.

    Examples:
    - "3x10 deadlift at 135, 5x5 squat at 140"
    - "bench press 4 sets of 8 at 80"
    - Photo of workout log
    """
    logger.info(f"🤖 [ParseInput] Request from user {body.user_id}: text={bool(body.input_text)}, image={bool(body.image_base64)}, voice={bool(body.voice_transcript)}")

    # Validate at least one input is provided
    if not body.input_text and not body.image_base64 and not body.voice_transcript:
        raise HTTPException(
            status_code=400,
            detail="At least one of input_text, image_base64, or voice_transcript is required"
        )

    try:
        # Parse using Gemini
        gemini = GeminiService()
        user_unit = "kg" if body.use_kg else "lbs"

        result = await gemini.parse_workout_input(
            input_text=body.input_text,
            image_base64=body.image_base64,
            voice_transcript=body.voice_transcript,
            user_unit_preference=user_unit,
        )

        # Convert to response model
        exercises = []
        for ex in result.get("exercises", []):
            exercises.append(ParsedExerciseItem(
                name=ex.get("name", "Unknown Exercise"),
                sets=ex.get("sets", 3),
                reps=ex.get("reps", 10),
                weight_kg=ex.get("weight_kg"),
                weight_lbs=ex.get("weight_lbs"),
                weight_unit=ex.get("weight_unit", "lbs"),
                rest_seconds=ex.get("rest_seconds", 60),
                original_text=ex.get("original_text", ""),
                confidence=ex.get("confidence", 1.0),
                notes=ex.get("notes"),
            ))

        logger.info(f"✅ [ParseInput] Parsed {len(exercises)} exercises for user {body.user_id}")

        return ParseWorkoutInputResponse(
            exercises=exercises,
            summary=result.get("summary", f"Parsed {len(exercises)} exercises"),
            warnings=result.get("warnings", []),
        )

    except Exception as e:
        logger.error(f"❌ [ParseInput] Failed to parse input: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to parse workout input: {str(e)}")


@router.post("/parse-input-v2", response_model=ParseWorkoutInputV2Response)
@limiter.limit("20/minute")
async def parse_workout_input_v2(request: Request, body: ParseWorkoutInputV2Request):
    """
    Parse workout input with dual-mode support.

    Supports TWO use cases simultaneously:
    1. **Set logging**: "135*8, 145*6" -> logs sets for CURRENT exercise
    2. **Add exercise**: "3x10 deadlift at 135" -> adds NEW exercise

    Smart shortcuts supported:
    - "+10" -> add 10 to last weight, keep same reps
    - "-10" -> subtract 10 from last weight
    - "same" -> repeat last set exactly
    - "drop" -> 10% weight reduction

    Examples:
    - "20*5\\n25*6\\n35*12" -> Log 3 sets for current exercise
    - "3x10 deadlift at 135" -> Add Deadlift exercise
    - "20*5\\n25*6\\n3x10 bench at 135" -> Log 2 sets AND add Bench Press
    """
    logger.info(
        f"🤖 [ParseInputV2] Request from user {body.user_id}: "
        f"exercise={body.current_exercise_name}, "
        f"text={bool(body.input_text)}, image={bool(body.image_base64)}"
    )

    # Validate at least one input is provided
    if not body.input_text and not body.image_base64 and not body.voice_transcript:
        raise HTTPException(
            status_code=400,
            detail="At least one of input_text, image_base64, or voice_transcript is required"
        )

    try:
        gemini = GeminiService()
        user_unit = "kg" if body.use_kg else "lbs"

        # Call the new dual-mode parsing method
        result = await gemini.parse_workout_input_v2(
            input_text=body.input_text,
            image_base64=body.image_base64,
            voice_transcript=body.voice_transcript,
            user_unit_preference=user_unit,
            current_exercise_name=body.current_exercise_name,
            last_set_weight=body.last_set_weight,
            last_set_reps=body.last_set_reps,
        )

        # Convert to response models
        sets_to_log = []
        for s in result.get("sets_to_log", []):
            sets_to_log.append(SetToLogResponse(
                weight=s.get("weight", 0),
                reps=s.get("reps", 0),
                unit=s.get("unit", user_unit),
                is_bodyweight=s.get("is_bodyweight", False),
                is_failure=s.get("is_failure", False),
                is_warmup=s.get("is_warmup", False),
                original_input=s.get("original_input", ""),
                notes=s.get("notes"),
            ))

        exercises_to_add = []
        for ex in result.get("exercises_to_add", []):
            # Calculate both kg and lbs
            weight_kg = ex.get("weight_kg")
            weight_lbs = ex.get("weight_lbs")

            if weight_kg is None and weight_lbs is not None:
                weight_kg = round(weight_lbs / 2.20462, 1)
            elif weight_lbs is None and weight_kg is not None:
                weight_lbs = round(weight_kg * 2.20462, 1)

            exercises_to_add.append(ExerciseToAddResponse(
                name=ex.get("name", "Unknown Exercise"),
                sets=ex.get("sets", 3),
                reps=ex.get("reps", 10),
                weight_kg=weight_kg,
                weight_lbs=weight_lbs,
                rest_seconds=ex.get("rest_seconds", 60),
                is_bodyweight=ex.get("is_bodyweight", False),
                original_text=ex.get("original_text", ""),
                confidence=ex.get("confidence", 1.0),
                notes=ex.get("notes"),
            ))

        # Build summary
        summary_parts = []
        if sets_to_log:
            exercise_name = body.current_exercise_name or "current exercise"
            summary_parts.append(f"Log {len(sets_to_log)} set{'s' if len(sets_to_log) > 1 else ''} for {exercise_name}")
        if exercises_to_add:
            names = [ex.name for ex in exercises_to_add]
            summary_parts.append(f"Add {', '.join(names)}")

        summary = result.get("summary", "; ".join(summary_parts) if summary_parts else "No data parsed")

        logger.info(
            f"✅ [ParseInputV2] Parsed {len(sets_to_log)} sets, "
            f"{len(exercises_to_add)} exercises for user {body.user_id}"
        )

        return ParseWorkoutInputV2Response(
            sets_to_log=sets_to_log,
            exercises_to_add=exercises_to_add,
            summary=summary,
            warnings=result.get("warnings", []),
        )

    except Exception as e:
        logger.error(f"❌ [ParseInputV2] Failed to parse input: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to parse workout input: {str(e)}")


@router.post("/add-exercises-batch", response_model=Workout)
@limiter.limit("10/minute")
async def add_exercises_batch(request: Request, body: BatchAddExercisesRequest):
    """
    Add multiple parsed exercises to an existing workout.

    Enriches exercises with library metadata (gif, muscle group, equipment)
    and generates set_targets for consistency with AI-generated workouts.
    """
    logger.info(f"🔍 [BatchAdd] Adding {len(body.exercises)} exercises to workout {body.workout_id}")

    try:
        db = get_supabase_db()

        # Get the workout
        workout_row = db.get_workout(body.workout_id)
        if not workout_row:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Verify ownership
        if workout_row.get("user_id") != body.user_id:
            raise HTTPException(status_code=403, detail="Not authorized to modify this workout")

        # Parse existing exercises
        exercises_json = workout_row.get("exercises_json", "[]")
        existing_exercises = parse_json_field(exercises_json) or []

        # Get exercise library for metadata enrichment
        exercise_lib = get_exercise_library_service()

        # Add each new exercise
        for parsed in body.exercises:
            # Search library for this exercise
            lib_results = exercise_lib.search_exercises(parsed.name, limit=1)

            # Determine weight in kg for storage
            weight_kg = parsed.weight_kg
            if weight_kg is None and parsed.weight_lbs is not None:
                weight_kg = round(parsed.weight_lbs / 2.20462, 1)

            if lib_results:
                lib_ex = lib_results[0]
                new_exercise = {
                    "name": lib_ex.get("name", parsed.name),
                    "sets": parsed.sets,
                    "reps": parsed.reps,
                    "weight_kg": weight_kg,
                    "rest_seconds": parsed.rest_seconds,
                    "muscle_group": lib_ex.get("body_part"),
                    "equipment": lib_ex.get("equipment"),
                    "gif_url": lib_ex.get("gif_url"),
                    "video_url": lib_ex.get("video_url"),
                    "notes": parsed.notes,
                    # Generate set_targets for consistency
                    "set_targets": [
                        {
                            "set_number": i + 1,
                            "set_type": "working",
                            "target_reps": parsed.reps,
                            "target_weight_kg": weight_kg,
                        }
                        for i in range(parsed.sets)
                    ]
                }
            else:
                # Exercise not in library - use parsed data directly
                logger.warning(f"⚠️ [BatchAdd] Exercise '{parsed.name}' not found in library")
                new_exercise = {
                    "name": parsed.name,
                    "sets": parsed.sets,
                    "reps": parsed.reps,
                    "weight_kg": weight_kg,
                    "rest_seconds": parsed.rest_seconds,
                    "notes": parsed.notes,
                    "set_targets": [
                        {
                            "set_number": i + 1,
                            "set_type": "working",
                            "target_reps": parsed.reps,
                            "target_weight_kg": weight_kg,
                        }
                        for i in range(parsed.sets)
                    ]
                }

            existing_exercises.append(new_exercise)

        # Update workout in database
        updated_row = db.update_workout(
            body.workout_id,
            {"exercises_json": json.dumps(existing_exercises)}
        )

        if not updated_row:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        logger.info(f"✅ [BatchAdd] Successfully added {len(body.exercises)} exercises to workout {body.workout_id}")

        return row_to_workout(updated_row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [BatchAdd] Failed to add exercises: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to add exercises: {str(e)}")
