"""
Calibration Workout API endpoints.

Provides endpoints for the strength calibration workflow:
- GET /calibration/status - Get user's calibration status
- POST /calibration/generate - Generate a new calibration workout
- POST /calibration/start/{calibration_id} - Start a calibration workout
- POST /calibration/complete/{calibration_id} - Complete calibration with results
- POST /calibration/accept-adjustments/{calibration_id} - Accept suggested adjustments
- POST /calibration/decline-adjustments/{calibration_id} - Decline adjustments
- POST /calibration/skip - Skip calibration entirely
- GET /calibration/results/{calibration_id} - Get calibration results
- GET /calibration/baselines - Get user's strength baselines
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
import uuid
import json

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from services.gemini_service import GeminiService

router = APIRouter(prefix="/calibration", tags=["Calibration"])
logger = get_logger(__name__)


# ============================================
# Enums and Models
# ============================================

class CalibrationStatus(str, Enum):
    """Status of a user's calibration."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    SKIPPED = "skipped"


class CalibrationWorkoutStatus(str, Enum):
    """Status of a calibration workout."""
    GENERATED = "generated"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class CalibrationExercise(BaseModel):
    """An exercise in a calibration workout."""
    id: str
    name: str
    target_muscle: str
    equipment: Optional[str] = None
    instructions: Optional[str] = None
    is_compound: bool = False
    test_type: str = "max_reps"  # "max_reps", "max_weight", "time"
    suggested_weight: Optional[float] = None
    weight_unit: str = "lbs"


class CalibrationWorkout(BaseModel):
    """A calibration workout for assessing user strength."""
    id: str
    user_id: str
    status: CalibrationWorkoutStatus = CalibrationWorkoutStatus.GENERATED
    exercises: List[CalibrationExercise]
    estimated_duration_minutes: int = 20
    instructions: Optional[str] = None
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    ai_analysis: Optional[str] = None
    suggested_adjustments: Optional[Dict[str, Any]] = None
    user_accepted_adjustments: Optional[bool] = None


class CalibrationStatusResponse(BaseModel):
    """Response for calibration status check."""
    status: CalibrationStatus
    calibration_completed: bool = False
    calibration_skipped: bool = False
    calibration_workout_id: Optional[str] = None
    last_calibrated_at: Optional[datetime] = None
    can_recalibrate: bool = True


class ExercisePerformance(BaseModel):
    """Performance data for a single exercise in calibration."""
    exercise_id: str
    exercise_name: str
    weight_used: Optional[float] = None
    weight_unit: str = "lbs"
    reps_completed: Optional[int] = None
    time_seconds: Optional[int] = None
    rpe: Optional[int] = Field(None, ge=1, le=10, description="Rate of Perceived Exertion 1-10")
    notes: Optional[str] = None
    felt_easy: bool = False
    felt_hard: bool = False


class CalibrationResult(BaseModel):
    """Results from a completed calibration workout."""
    exercise_performances: List[ExercisePerformance]
    overall_difficulty: Optional[str] = Field(
        None,
        description="too_easy, just_right, too_hard"
    )
    user_notes: Optional[str] = None
    total_duration_minutes: Optional[int] = None


class StrengthBaseline(BaseModel):
    """A strength baseline for a muscle group or exercise."""
    id: str
    user_id: str
    exercise_name: Optional[str] = None
    muscle_group: Optional[str] = None
    baseline_weight: Optional[float] = None
    baseline_reps: Optional[int] = None
    estimated_1rm: Optional[float] = None
    weight_unit: str = "lbs"
    confidence_level: float = Field(default=0.8, ge=0.0, le=1.0)
    source: str = "calibration"  # "calibration", "workout_history", "manual"
    calibration_id: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None


class SuggestedAdjustment(BaseModel):
    """A suggested adjustment based on calibration results."""
    adjustment_type: str  # "fitness_level", "weight_suggestion", "rep_range"
    current_value: Any
    suggested_value: Any
    reason: str
    confidence: float = Field(default=0.8, ge=0.0, le=1.0)


class CalibrationAnalysis(BaseModel):
    """AI analysis of calibration results."""
    summary: str
    strength_level: str  # "beginner", "intermediate", "advanced"
    suggested_fitness_level: str
    adjustments: List[SuggestedAdjustment]
    muscle_group_analysis: Dict[str, Dict[str, Any]]
    recommendations: List[str]


class CalibrationResultsResponse(BaseModel):
    """Complete results for a calibration workout."""
    calibration_id: str
    status: CalibrationWorkoutStatus
    completed_at: Optional[datetime] = None
    exercise_performances: List[ExercisePerformance]
    ai_analysis: Optional[CalibrationAnalysis] = None
    suggested_adjustments: Optional[Dict[str, Any]] = None
    user_accepted_adjustments: Optional[bool] = None
    baselines_created: int = 0


class GenerateCalibrationRequest(BaseModel):
    """Request to generate a calibration workout."""
    focus_muscles: Optional[List[str]] = None
    available_equipment: Optional[List[str]] = None
    duration_preference: Optional[int] = Field(default=20, ge=10, le=45)


class AcceptAdjustmentsRequest(BaseModel):
    """Request to accept specific adjustments."""
    accept_all: bool = True
    accepted_adjustment_types: Optional[List[str]] = None


# ============================================
# Helper Functions
# ============================================

async def _get_user_profile(user_id: str) -> Optional[dict]:
    """Get user profile data."""
    try:
        supabase = get_supabase().client
        result = supabase.table("users").select(
            "id, fitness_level, goals, equipment, date_of_birth, gender, weight_unit, "
            "calibration_completed, calibration_skipped, last_calibrated_at"
        ).eq("id", user_id).execute()

        if result.data:
            return result.data[0]
        return None
    except Exception as e:
        logger.error(f"Failed to get user profile: {e}")
        return None


async def _get_latest_calibration(user_id: str) -> Optional[dict]:
    """Get the user's most recent calibration workout."""
    try:
        supabase = get_supabase().client
        result = supabase.table("calibration_workouts").select("*").eq(
            "user_id", user_id
        ).order("created_at", desc=True).limit(1).execute()

        if result.data:
            return result.data[0]
        return None
    except Exception as e:
        logger.error(f"Failed to get latest calibration: {e}")
        return None


def _parse_exercises(exercises_json: str) -> List[CalibrationExercise]:
    """Parse exercises from JSON string."""
    try:
        exercises_data = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
        return [CalibrationExercise(**ex) for ex in exercises_data]
    except Exception as e:
        logger.error(f"Failed to parse exercises: {e}")
        return []


def _calculate_estimated_1rm(weight: float, reps: int) -> float:
    """
    Calculate estimated 1RM using Brzycki formula.
    1RM = weight * (36 / (37 - reps))
    """
    if reps >= 37:
        reps = 36  # Cap at 36 reps for formula validity
    if reps <= 0 or weight <= 0:
        return 0.0
    return round(weight * (36 / (37 - reps)), 1)


# ============================================
# Calibration Status Endpoint
# ============================================

@router.get("/status/{user_id}", response_model=CalibrationStatusResponse)
async def get_calibration_status(user_id: str):
    """
    Get user's calibration status.

    Returns whether calibration is pending, completed, or skipped,
    along with the calibration workout ID if completed.
    """
    logger.info(f"Getting calibration status for user: {user_id}")

    try:
        user = await _get_user_profile(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        calibration_completed = user.get("calibration_completed", False)
        calibration_skipped = user.get("calibration_skipped", False)
        last_calibrated_at = user.get("last_calibrated_at")

        # Determine status
        if calibration_completed:
            status = CalibrationStatus.COMPLETED
        elif calibration_skipped:
            status = CalibrationStatus.SKIPPED
        else:
            # Check if there's an in-progress calibration
            latest = await _get_latest_calibration(user_id)
            if latest and latest.get("status") == "in_progress":
                status = CalibrationStatus.IN_PROGRESS
            else:
                status = CalibrationStatus.PENDING

        # Get calibration workout ID if exists
        calibration_workout_id = None
        if calibration_completed or status == CalibrationStatus.IN_PROGRESS:
            latest = await _get_latest_calibration(user_id)
            if latest:
                calibration_workout_id = latest.get("id")

        # Check if user can recalibrate (allow after 30 days)
        can_recalibrate = True
        if last_calibrated_at:
            try:
                last_date = datetime.fromisoformat(last_calibrated_at.replace("Z", "+00:00"))
                days_since = (datetime.utcnow() - last_date.replace(tzinfo=None)).days
                can_recalibrate = days_since >= 30
            except Exception:
                pass

        return CalibrationStatusResponse(
            status=status,
            calibration_completed=calibration_completed,
            calibration_skipped=calibration_skipped,
            calibration_workout_id=calibration_workout_id,
            last_calibrated_at=last_calibrated_at,
            can_recalibrate=can_recalibrate,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get calibration status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Generate Calibration Workout
# ============================================

@router.post("/generate/{user_id}", response_model=CalibrationWorkout)
async def generate_calibration_workout(
    user_id: str,
    request: Optional[GenerateCalibrationRequest] = None,
):
    """
    Generate a new calibration workout for the user.

    Creates a workout with exercises designed to assess the user's
    strength levels across major muscle groups.
    """
    logger.info(f"Generating calibration workout for user: {user_id}")

    try:
        user = await _get_user_profile(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user's equipment
        equipment = request.available_equipment if request else None
        if not equipment:
            equipment = user.get("equipment", [])

        # Define calibration exercises based on equipment
        # These are key compound movements for strength assessment
        calibration_exercises = []

        # Upper body push
        if "barbell" in equipment or "dumbbells" in equipment:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Bench Press" if "barbell" in equipment else "Dumbbell Bench Press",
                target_muscle="chest",
                equipment="barbell" if "barbell" in equipment else "dumbbells",
                is_compound=True,
                test_type="max_reps",
                instructions="Perform as many reps as possible with a moderate weight you can control.",
            ))
        else:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Push-ups",
                target_muscle="chest",
                equipment="bodyweight",
                is_compound=True,
                test_type="max_reps",
                instructions="Perform as many push-ups as possible with good form.",
            ))

        # Upper body pull
        if "pull_up_bar" in equipment or "pull-up bar" in equipment:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Pull-ups",
                target_muscle="back",
                equipment="pull-up bar",
                is_compound=True,
                test_type="max_reps",
                instructions="Perform as many pull-ups as possible with full range of motion.",
            ))
        elif "dumbbells" in equipment:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Dumbbell Rows",
                target_muscle="back",
                equipment="dumbbells",
                is_compound=True,
                test_type="max_reps",
                instructions="Perform rows with a challenging weight for max reps.",
            ))

        # Lower body
        if "barbell" in equipment:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Barbell Squat",
                target_muscle="legs",
                equipment="barbell",
                is_compound=True,
                test_type="max_reps",
                instructions="Squat to parallel or below with a weight you can control.",
            ))
        else:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Bodyweight Squats",
                target_muscle="legs",
                equipment="bodyweight",
                is_compound=True,
                test_type="max_reps",
                instructions="Perform as many squats as possible with good depth.",
            ))

        # Shoulders
        if "dumbbells" in equipment:
            calibration_exercises.append(CalibrationExercise(
                id=str(uuid.uuid4()),
                name="Dumbbell Shoulder Press",
                target_muscle="shoulders",
                equipment="dumbbells",
                is_compound=True,
                test_type="max_reps",
                instructions="Press overhead with control for max reps.",
            ))

        # Core
        calibration_exercises.append(CalibrationExercise(
            id=str(uuid.uuid4()),
            name="Plank",
            target_muscle="core",
            equipment="bodyweight",
            is_compound=False,
            test_type="time",
            instructions="Hold a plank position for as long as possible.",
        ))

        # Create calibration workout record
        now = datetime.utcnow().isoformat()
        calibration_id = str(uuid.uuid4())

        workout_data = {
            "id": calibration_id,
            "user_id": user_id,
            "status": "generated",
            "exercises_json": json.dumps([ex.model_dump() for ex in calibration_exercises]),
            "estimated_duration_minutes": request.duration_preference if request else 20,
            "instructions": "Complete each exercise to your maximum ability. Rest 2-3 minutes between exercises. Record your performance honestly - this helps us personalize your workouts.",
            "created_at": now,
        }

        supabase = get_supabase().client
        result = supabase.table("calibration_workouts").insert(workout_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save calibration workout")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="calibration_workout_generated",
            endpoint=f"/api/v1/calibration/generate/{user_id}",
            message=f"Generated calibration workout with {len(calibration_exercises)} exercises",
            metadata={
                "calibration_id": calibration_id,
                "exercise_count": len(calibration_exercises),
            },
            status_code=200,
        )

        return CalibrationWorkout(
            id=calibration_id,
            user_id=user_id,
            status=CalibrationWorkoutStatus.GENERATED,
            exercises=calibration_exercises,
            estimated_duration_minutes=request.duration_preference if request else 20,
            instructions=workout_data["instructions"],
            created_at=datetime.fromisoformat(now),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate calibration workout: {e}")
        await log_user_error(
            user_id=user_id,
            action="calibration_workout_generated",
            error=e,
            endpoint=f"/api/v1/calibration/generate/{user_id}",
            status_code=500,
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Start Calibration Workout
# ============================================

@router.post("/start/{calibration_id}")
async def start_calibration_workout(calibration_id: str):
    """
    Mark a calibration workout as started.

    Updates the started_at timestamp and status to in_progress.
    """
    logger.info(f"Starting calibration workout: {calibration_id}")

    try:
        supabase = get_supabase().client

        # Verify calibration exists
        check = supabase.table("calibration_workouts").select(
            "id, user_id, status"
        ).eq("id", calibration_id).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Calibration workout not found")

        calibration = check.data[0]
        user_id = calibration["user_id"]

        if calibration["status"] not in ["generated", "in_progress"]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot start calibration with status: {calibration['status']}"
            )

        # Update status
        now = datetime.utcnow().isoformat()
        result = supabase.table("calibration_workouts").update({
            "status": "in_progress",
            "started_at": now,
        }).eq("id", calibration_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update calibration")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="calibration_workout_started",
            endpoint=f"/api/v1/calibration/start/{calibration_id}",
            message="Started calibration workout",
            metadata={"calibration_id": calibration_id},
            status_code=200,
        )

        return {
            "success": True,
            "message": "Calibration workout started",
            "calibration_id": calibration_id,
            "started_at": now,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to start calibration workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Complete Calibration Workout
# ============================================

@router.post("/complete/{calibration_id}")
async def complete_calibration_workout(
    calibration_id: str,
    results: CalibrationResult,
):
    """
    Complete a calibration workout with performance results.

    Analyzes the results using AI, calculates strength baselines,
    and generates suggested adjustments for the user's profile.
    """
    logger.info(f"Completing calibration workout: {calibration_id}")

    try:
        supabase = get_supabase().client

        # Get calibration workout
        check = supabase.table("calibration_workouts").select("*").eq(
            "id", calibration_id
        ).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Calibration workout not found")

        calibration = check.data[0]
        user_id = calibration["user_id"]

        if calibration["status"] not in ["generated", "in_progress"]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot complete calibration with status: {calibration['status']}"
            )

        # Get user profile for analysis
        user = await _get_user_profile(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        current_fitness_level = user.get("fitness_level", "intermediate")

        # Calculate strength baselines from results
        baselines = []
        now = datetime.utcnow().isoformat()

        for perf in results.exercise_performances:
            baseline_id = str(uuid.uuid4())

            # Calculate estimated 1RM if weight and reps provided
            estimated_1rm = None
            if perf.weight_used and perf.reps_completed:
                estimated_1rm = _calculate_estimated_1rm(perf.weight_used, perf.reps_completed)

            baseline = {
                "id": baseline_id,
                "user_id": user_id,
                "exercise_name": perf.exercise_name,
                "baseline_weight": perf.weight_used,
                "baseline_reps": perf.reps_completed,
                "estimated_1rm": estimated_1rm,
                "weight_unit": perf.weight_unit,
                "confidence_level": 0.9,
                "source": "calibration",
                "calibration_id": calibration_id,
                "created_at": now,
            }
            baselines.append(baseline)

        # Save strength baselines
        if baselines:
            supabase.table("strength_baselines").insert(baselines).execute()

        # Analyze results with Gemini
        gemini = GeminiService()

        analysis_prompt = f"""Analyze this calibration workout performance and provide personalized recommendations.

User's Current Fitness Level: {current_fitness_level}

Exercise Performance Results:
{json.dumps([p.model_dump() for p in results.exercise_performances], indent=2)}

Overall Difficulty Rating: {results.overall_difficulty or "not specified"}
User Notes: {results.user_notes or "none"}

Provide a JSON response with:
1. "summary": A brief 2-3 sentence summary of their performance
2. "strength_level": "beginner", "intermediate", or "advanced" based on the results
3. "suggested_fitness_level": What fitness level we should set for them
4. "adjustments": Array of suggested changes with type, current value, suggested value, and reason
5. "muscle_group_analysis": Analysis for each muscle group tested
6. "recommendations": 3-5 specific recommendations for their training

Return ONLY valid JSON, no markdown or explanation."""

        try:
            ai_response = await gemini.chat(analysis_prompt)

            # Parse AI response
            # Clean up response if it has markdown code blocks
            clean_response = ai_response
            if "```json" in clean_response:
                clean_response = clean_response.split("```json")[1].split("```")[0]
            elif "```" in clean_response:
                clean_response = clean_response.split("```")[1].split("```")[0]

            analysis_data = json.loads(clean_response.strip())

            ai_analysis = CalibrationAnalysis(
                summary=analysis_data.get("summary", "Calibration completed successfully."),
                strength_level=analysis_data.get("strength_level", "intermediate"),
                suggested_fitness_level=analysis_data.get("suggested_fitness_level", current_fitness_level),
                adjustments=[
                    SuggestedAdjustment(**adj) for adj in analysis_data.get("adjustments", [])
                ],
                muscle_group_analysis=analysis_data.get("muscle_group_analysis", {}),
                recommendations=analysis_data.get("recommendations", []),
            )

        except Exception as e:
            logger.warning(f"AI analysis failed, using defaults: {e}")
            # Provide default analysis if AI fails
            ai_analysis = CalibrationAnalysis(
                summary="Calibration completed. We've recorded your baseline strength levels.",
                strength_level="intermediate",
                suggested_fitness_level=current_fitness_level,
                adjustments=[],
                muscle_group_analysis={},
                recommendations=[
                    "Start with the suggested weights and adjust as needed",
                    "Focus on proper form before increasing intensity",
                    "Track your progress to see improvements over time",
                ],
            )

        # Build suggested adjustments
        suggested_adjustments = {
            "fitness_level": {
                "current": current_fitness_level,
                "suggested": ai_analysis.suggested_fitness_level,
                "should_change": ai_analysis.suggested_fitness_level != current_fitness_level,
            },
            "adjustments": [adj.model_dump() for adj in ai_analysis.adjustments],
            "muscle_group_analysis": ai_analysis.muscle_group_analysis,
        }

        # Update calibration workout
        supabase.table("calibration_workouts").update({
            "status": "completed",
            "completed_at": now,
            "results_json": json.dumps([p.model_dump() for p in results.exercise_performances]),
            "ai_analysis": json.dumps(ai_analysis.model_dump()),
            "suggested_adjustments": json.dumps(suggested_adjustments),
            "original_fitness_level": current_fitness_level,
        }).eq("id", calibration_id).execute()

        # Update user's calibration status
        supabase.table("users").update({
            "calibration_completed": True,
            "last_calibrated_at": now,
        }).eq("id", user_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="calibration_workout_completed",
            endpoint=f"/api/v1/calibration/complete/{calibration_id}",
            message=f"Completed calibration workout. Suggested level: {ai_analysis.suggested_fitness_level}",
            metadata={
                "calibration_id": calibration_id,
                "baselines_created": len(baselines),
                "suggested_fitness_level": ai_analysis.suggested_fitness_level,
            },
            status_code=200,
        )

        return {
            "success": True,
            "calibration_id": calibration_id,
            "completed_at": now,
            "analysis": ai_analysis.model_dump(),
            "suggested_adjustments": suggested_adjustments,
            "baselines_created": len(baselines),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete calibration workout: {e}")
        await log_user_error(
            user_id=calibration.get("user_id", "unknown") if 'calibration' in dir() else "unknown",
            action="calibration_workout_completed",
            error=e,
            endpoint=f"/api/v1/calibration/complete/{calibration_id}",
            status_code=500,
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Accept/Decline Adjustments
# ============================================

@router.post("/accept-adjustments/{calibration_id}")
async def accept_calibration_adjustments(
    calibration_id: str,
    request: Optional[AcceptAdjustmentsRequest] = None,
):
    """
    Accept the suggested adjustments from calibration.

    Applies the adjustments to the user's profile, including
    updating their fitness level if recommended.
    """
    logger.info(f"Accepting adjustments for calibration: {calibration_id}")

    try:
        supabase = get_supabase().client

        # Get calibration
        check = supabase.table("calibration_workouts").select("*").eq(
            "id", calibration_id
        ).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Calibration workout not found")

        calibration = check.data[0]
        user_id = calibration["user_id"]

        if calibration["status"] != "completed":
            raise HTTPException(
                status_code=400,
                detail="Can only accept adjustments for completed calibrations"
            )

        # Parse suggested adjustments
        suggested_adjustments = calibration.get("suggested_adjustments")
        if isinstance(suggested_adjustments, str):
            suggested_adjustments = json.loads(suggested_adjustments)

        if not suggested_adjustments:
            raise HTTPException(status_code=400, detail="No adjustments available")

        # Apply fitness level adjustment if suggested
        updates = {}
        fitness_adj = suggested_adjustments.get("fitness_level", {})
        if fitness_adj.get("should_change"):
            updates["fitness_level"] = fitness_adj.get("suggested")

        # Update user if there are changes
        if updates:
            supabase.table("users").update(updates).eq("id", user_id).execute()

        # Mark adjustments as accepted
        supabase.table("calibration_workouts").update({
            "user_accepted_adjustments": True,
        }).eq("id", calibration_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="calibration_adjustments_accepted",
            endpoint=f"/api/v1/calibration/accept-adjustments/{calibration_id}",
            message=f"Accepted calibration adjustments. Updates: {updates}",
            metadata={
                "calibration_id": calibration_id,
                "updates": updates,
            },
            status_code=200,
        )

        return {
            "success": True,
            "message": "Adjustments applied successfully",
            "updates_applied": updates,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to accept adjustments: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/decline-adjustments/{calibration_id}")
async def decline_calibration_adjustments(calibration_id: str):
    """
    Decline the suggested adjustments from calibration.

    Keeps the user's original settings unchanged.
    """
    logger.info(f"Declining adjustments for calibration: {calibration_id}")

    try:
        supabase = get_supabase().client

        # Get calibration
        check = supabase.table("calibration_workouts").select(
            "id, user_id, status"
        ).eq("id", calibration_id).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Calibration workout not found")

        calibration = check.data[0]
        user_id = calibration["user_id"]

        if calibration["status"] != "completed":
            raise HTTPException(
                status_code=400,
                detail="Can only decline adjustments for completed calibrations"
            )

        # Mark adjustments as declined
        supabase.table("calibration_workouts").update({
            "user_accepted_adjustments": False,
        }).eq("id", calibration_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="calibration_adjustments_declined",
            endpoint=f"/api/v1/calibration/decline-adjustments/{calibration_id}",
            message="Declined calibration adjustments",
            metadata={"calibration_id": calibration_id},
            status_code=200,
        )

        return {
            "success": True,
            "message": "Adjustments declined. Your settings remain unchanged.",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to decline adjustments: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Skip Calibration
# ============================================

@router.post("/skip/{user_id}")
async def skip_calibration(user_id: str):
    """
    Skip calibration entirely.

    For users who want to jump straight to workouts without
    completing the calibration process.
    """
    logger.info(f"Skipping calibration for user: {user_id}")

    try:
        supabase = get_supabase().client

        # Verify user exists
        check = supabase.table("users").select("id").eq("id", user_id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="User not found")

        # Update user to mark calibration as skipped
        supabase.table("users").update({
            "calibration_skipped": True,
            "calibration_completed": False,
        }).eq("id", user_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="calibration_skipped",
            endpoint=f"/api/v1/calibration/skip/{user_id}",
            message="User skipped calibration",
            metadata={},
            status_code=200,
        )

        return {
            "success": True,
            "message": "Calibration skipped. You can complete it later from settings.",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to skip calibration: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Get Calibration Results
# ============================================

@router.get("/results/{calibration_id}", response_model=CalibrationResultsResponse)
async def get_calibration_results(calibration_id: str):
    """
    Get the results and analysis for a completed calibration.

    Returns the AI analysis, suggested adjustments, and baseline data.
    """
    logger.info(f"Getting results for calibration: {calibration_id}")

    try:
        supabase = get_supabase().client

        # Get calibration
        result = supabase.table("calibration_workouts").select("*").eq(
            "id", calibration_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Calibration workout not found")

        calibration = result.data[0]

        # Parse results
        results_json = calibration.get("results_json")
        exercise_performances = []
        if results_json:
            perfs = json.loads(results_json) if isinstance(results_json, str) else results_json
            exercise_performances = [ExercisePerformance(**p) for p in perfs]

        # Parse AI analysis
        ai_analysis = None
        analysis_json = calibration.get("ai_analysis")
        if analysis_json:
            analysis_data = json.loads(analysis_json) if isinstance(analysis_json, str) else analysis_json
            ai_analysis = CalibrationAnalysis(**analysis_data)

        # Parse suggested adjustments
        suggested_adjustments = calibration.get("suggested_adjustments")
        if isinstance(suggested_adjustments, str):
            suggested_adjustments = json.loads(suggested_adjustments)

        # Count baselines created
        baselines = supabase.table("strength_baselines").select("id").eq(
            "calibration_id", calibration_id
        ).execute()
        baselines_count = len(baselines.data) if baselines.data else 0

        return CalibrationResultsResponse(
            calibration_id=calibration_id,
            status=CalibrationWorkoutStatus(calibration["status"]),
            completed_at=calibration.get("completed_at"),
            exercise_performances=exercise_performances,
            ai_analysis=ai_analysis,
            suggested_adjustments=suggested_adjustments,
            user_accepted_adjustments=calibration.get("user_accepted_adjustments"),
            baselines_created=baselines_count,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get calibration results: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Get Strength Baselines
# ============================================

@router.get("/baselines/{user_id}", response_model=List[StrengthBaseline])
async def get_strength_baselines(
    user_id: str,
    exercise_name: Optional[str] = Query(None, description="Filter by exercise name"),
    muscle_group: Optional[str] = Query(None, description="Filter by muscle group"),
):
    """
    Get all strength baselines for the user.

    Used for weight suggestions in future workouts.
    """
    logger.info(f"Getting strength baselines for user: {user_id}")

    try:
        supabase = get_supabase().client

        query = supabase.table("strength_baselines").select("*").eq("user_id", user_id)

        if exercise_name:
            query = query.eq("exercise_name", exercise_name)

        if muscle_group:
            query = query.eq("muscle_group", muscle_group)

        result = query.order("created_at", desc=True).execute()

        if not result.data:
            return []

        baselines = []
        for row in result.data:
            baselines.append(StrengthBaseline(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row.get("exercise_name"),
                muscle_group=row.get("muscle_group"),
                baseline_weight=row.get("baseline_weight"),
                baseline_reps=row.get("baseline_reps"),
                estimated_1rm=row.get("estimated_1rm"),
                weight_unit=row.get("weight_unit", "lbs"),
                confidence_level=row.get("confidence_level", 0.8),
                source=row.get("source", "calibration"),
                calibration_id=row.get("calibration_id"),
                created_at=row.get("created_at"),
                updated_at=row.get("updated_at"),
            ))

        return baselines

    except Exception as e:
        logger.error(f"Failed to get strength baselines: {e}")
        raise HTTPException(status_code=500, detail=str(e))
