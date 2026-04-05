"""Secondary endpoints for feedback.  Sub-router included by main module."""
Workout and Exercise Feedback API endpoints.

Allows users to rate workouts (1-5 stars) with optional comments
for both overall workout and individual exercises.

Also includes AI Coach feedback using RAG for personalized workout analysis.

from .feedback_models import (
    SetDetail,
    ExercisePerformance,
    PlannedExercise,
    AICoachFeedbackRequest,
    AICoachFeedbackResponse,
    ProgressionSuggestionResponse,
    ProgressionResponseRequest,
    ChallengeExerciseFeedbackRequest,
    ChallengeExerciseFeedbackResponse,
)

router = APIRouter()

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
