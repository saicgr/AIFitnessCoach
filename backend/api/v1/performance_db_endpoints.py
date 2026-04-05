"""Secondary endpoints for performance_db.  Sub-router included by main module."""
Performance logging API endpoints with Supabase.

ENDPOINTS:
- POST /api/v1/performance-db/logs - Create performance log
- GET  /api/v1/performance-db/logs - List performance logs
- POST /api/v1/performance-db/workout-logs - Create workout log
- GET  /api/v1/performance-db/workout-logs - List workout logs
- GET  /api/v1/performance-db/strength-records - Get strength records
- GET  /api/v1/performance-db/weekly-volume - Get weekly volume
- POST /api/v1/performance-db/workout-exit - Log workout exit/quit
- GET  /api/v1/performance-db/workout-exits - List workout exits
- POST /api/v1/performance-db/drink-intake - Log drink intake during workout
- GET  /api/v1/performance-db/drink-intake - List drink intakes
- GET  /api/v1/performance-db/drink-intake/summary/{workout_log_id} - Get drink summary
- POST /api/v1/performance-db/rest-intervals - Log rest interval
- GET  /api/v1/performance-db/rest-intervals - List rest intervals
- GET  /api/v1/performance-db/rest-intervals/stats/{workout_log_id} - Get rest stats

from .performance_db_models import (
    ExerciseLastPerformance,
    StreakResponse,
    DrinkIntakeSummary,
    RestIntervalStats,
    ExerciseProgressionTrend,
    ExerciseStats,
    AllExerciseStats,
    ExerciseHistoryItem,
)

router = APIRouter()

@router.post("/workout-exit", response_model=WorkoutExit)
async def create_workout_exit(data: WorkoutExitCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a workout exit log entry."""
    try:
        db = get_supabase_db()

        exit_data = {
            "user_id": data.user_id,
            "workout_id": data.workout_id,
            "exit_reason": data.exit_reason,
            "exit_notes": data.exit_notes,
            "exercises_completed": data.exercises_completed,
            "total_exercises": data.total_exercises,
            "sets_completed": data.sets_completed,
            "time_spent_seconds": data.time_spent_seconds,
            "progress_percentage": data.progress_percentage,
        }

        created = db.create_workout_exit(exit_data)
        logger.info(f"Workout exit created: id={created['id']}, user_id={data.user_id}, reason={data.exit_reason}")
        return row_to_workout_exit(created)

    except Exception as e:
        logger.error(f"Error creating workout exit: {e}")
        raise safe_internal_error(e, "performance_db")


@router.get("/workout-exits", response_model=List[WorkoutExit])
async def list_workout_exits(
    user_id: str,
    workout_id: Optional[str] = None,
    limit: int = Query(default=50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    """List workout exits for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_workout_exits(user_id=user_id, workout_id=workout_id, limit=limit)
        logger.info(f"Listed {len(rows)} workout exits for user {user_id}")
        return [row_to_workout_exit(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing workout exits: {e}")
        raise safe_internal_error(e, "performance_db")


# ============ Drink Intake Tracking ============

def row_to_drink_intake(row: dict) -> DrinkIntake:
    """Convert a Supabase row dict to DrinkIntake model."""
    return DrinkIntake(
        id=row.get("id"),
        user_id=row.get("user_id"),
        workout_log_id=row.get("workout_log_id"),
        amount_ml=row.get("amount_ml", 0),
        drink_type=row.get("drink_type", "water"),
        notes=row.get("notes"),
        logged_at=row.get("logged_at"),
    )


@router.post("/drink-intake", response_model=DrinkIntake)
async def create_drink_intake(data: DrinkIntakeCreate,
    current_user: dict = Depends(get_current_user),
):
    """Log drink intake during workout."""
    try:
        db = get_supabase_db()

        intake_data = {
            "user_id": data.user_id,
            "workout_log_id": data.workout_log_id,
            "amount_ml": data.amount_ml,
            "drink_type": data.drink_type,
            "notes": data.notes,
        }

        created = db.create_drink_intake(intake_data)
        logger.info(f"Drink intake created: id={created['id']}, user_id={data.user_id}, amount={data.amount_ml}ml")
        return row_to_drink_intake(created)

    except Exception as e:
        logger.error(f"Error creating drink intake: {e}")
        raise safe_internal_error(e, "performance_db")


@router.get("/drink-intake", response_model=List[DrinkIntake])
async def list_drink_intakes(
    user_id: str,
    workout_log_id: Optional[str] = None,
    limit: int = Query(default=100, ge=1, le=500),
    current_user: dict = Depends(get_current_user),
):
    """List drink intakes for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_drink_intakes(user_id=user_id, workout_log_id=workout_log_id, limit=limit)
        logger.info(f"Listed {len(rows)} drink intakes for user {user_id}")
        return [row_to_drink_intake(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing drink intakes: {e}")
        raise safe_internal_error(e, "performance_db")


class DrinkIntakeSummary(BaseModel):
    """Summary of drink intake for a workout."""
    workout_log_id: str
    total_ml: int
    intake_count: int


@router.get("/drink-intake/summary/{workout_log_id}", response_model=DrinkIntakeSummary)
async def get_drink_intake_summary(workout_log_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get drink intake summary for a workout."""
    try:
        db = get_supabase_db()
        total = db.get_workout_total_drink_intake(workout_log_id)
        intakes = db.list_drink_intakes(user_id="", workout_log_id=workout_log_id, limit=500)
        logger.info(f"Drink intake summary for workout {workout_log_id}: {total}ml")
        return DrinkIntakeSummary(
            workout_log_id=workout_log_id,
            total_ml=total,
            intake_count=len(intakes),
        )

    except Exception as e:
        logger.error(f"Error getting drink intake summary: {e}")
        raise safe_internal_error(e, "performance_db")


# ============ Rest Interval Tracking ============

def row_to_rest_interval(row: dict) -> RestInterval:
    """Convert a Supabase row dict to RestInterval model."""
    return RestInterval(
        id=row.get("id"),
        user_id=row.get("user_id"),
        workout_log_id=row.get("workout_log_id"),
        exercise_index=row.get("exercise_index", 0),
        exercise_name=row.get("exercise_name", ""),
        set_number=row.get("set_number"),
        rest_duration_seconds=row.get("rest_duration_seconds", 0),
        prescribed_rest_seconds=row.get("prescribed_rest_seconds"),
        rest_type=row.get("rest_type", "between_sets"),
        notes=row.get("notes"),
        logged_at=row.get("logged_at"),
    )


@router.post("/rest-intervals", response_model=RestInterval)
async def create_rest_interval(data: RestIntervalCreate,
    current_user: dict = Depends(get_current_user),
):
    """Log rest interval during workout."""
    try:
        db = get_supabase_db()

        # Get rest duration from either field (rest_duration_seconds or rest_seconds)
        rest_duration = data.get_rest_duration

        # Get exercise info - prefer provided name/index, use defaults as fallback
        exercise_name = data.exercise_name or "Unknown"
        exercise_index = data.exercise_index or 0

        interval_data = {
            "user_id": data.user_id,
            "workout_log_id": data.workout_log_id,
            "exercise_index": exercise_index,
            "exercise_name": exercise_name,
            "set_number": data.set_number,
            "rest_duration_seconds": rest_duration,
            "prescribed_rest_seconds": data.prescribed_rest_seconds,
            "rest_type": data.rest_type,
            "notes": data.notes,
        }

        created = db.create_rest_interval(interval_data)
        logger.info(f"Rest interval created: id={created['id']}, user_id={data.user_id}, duration={rest_duration}s")
        return row_to_rest_interval(created)

    except Exception as e:
        logger.error(f"Error creating rest interval: {e}")
        raise safe_internal_error(e, "performance_db")


@router.get("/rest-intervals", response_model=List[RestInterval])
async def list_rest_intervals(
    user_id: str,
    workout_log_id: Optional[str] = None,
    limit: int = Query(default=200, ge=1, le=500),
    current_user: dict = Depends(get_current_user),
):
    """List rest intervals for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_rest_intervals(user_id=user_id, workout_log_id=workout_log_id, limit=limit)
        logger.info(f"Listed {len(rows)} rest intervals for user {user_id}")
        return [row_to_rest_interval(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing rest intervals: {e}")
        raise safe_internal_error(e, "performance_db")


class RestIntervalStats(BaseModel):
    """Statistics for rest intervals in a workout."""
    workout_log_id: str
    total_rest_seconds: int
    avg_rest_seconds: float
    interval_count: int
    between_sets_count: int
    between_exercises_count: int


@router.get("/rest-intervals/stats/{workout_log_id}", response_model=RestIntervalStats)
async def get_rest_interval_stats(workout_log_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get rest interval statistics for a workout."""
    try:
        db = get_supabase_db()
        stats = db.get_workout_rest_stats(workout_log_id)
        logger.info(f"Rest interval stats for workout {workout_log_id}: {stats['interval_count']} intervals")
        return RestIntervalStats(
            workout_log_id=workout_log_id,
            **stats,
        )

    except Exception as e:
        logger.error(f"Error getting rest interval stats: {e}")
        raise safe_internal_error(e, "performance_db")


# ============ Exercise Stats (Per-Exercise Performance History) ============

class ExerciseProgressionTrend(BaseModel):
    """Progression trend for an exercise."""
    trend: str  # "increasing", "stable", "decreasing", "insufficient_data", "unknown"
    change_percent: Optional[float] = None
    message: str


class ExerciseStats(BaseModel):
    """Statistics for a single exercise."""
    exercise_name: Optional[str] = None
    total_sets: int
    total_volume: Optional[float] = None  # weight * reps in kg
    max_weight: Optional[float] = None
    max_reps: Optional[int] = None
    estimated_1rm: Optional[float] = None
    avg_rpe: Optional[float] = None
    last_workout_date: Optional[str] = None
    progression: Optional[ExerciseProgressionTrend] = None
    has_data: bool = False
    message: Optional[str] = None


class AllExerciseStats(BaseModel):
    """Stats for all exercises a user has performed."""
    exercises: dict  # exercise_name -> ExerciseStats
    total_exercises_tracked: int
    total_sets_all: int
    has_data: bool


class ExerciseHistoryItem(BaseModel):
    """Single item in exercise history list."""
    exercise_name: str
    total_sets: int
    total_volume: Optional[float] = None
    max_weight: Optional[float] = None
    max_reps: Optional[int] = None
    estimated_1rm: Optional[float] = None
    avg_rpe: Optional[float] = None
    last_workout_date: Optional[str] = None
    progression: Optional[ExerciseProgressionTrend] = None
    has_data: bool = True


@router.get("/exercise-stats/{user_id}", response_model=AllExerciseStats)
async def get_all_exercise_stats(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get performance stats for all exercises a user has performed.

    Returns aggregated stats including:
    - Total sets per exercise
    - Total volume (weight * reps)
    - Max weight and reps
    - Estimated 1RM using Brzycki formula
    - Average RPE
    - Progression trend (increasing/stable/decreasing)
    """
    try:
        from services.adaptive_workout_service import get_adaptive_workout_service
        db = get_supabase_db()
        adaptive_service = get_adaptive_workout_service(db.client)

        stats = await adaptive_service.get_exercise_stats(user_id)

        if not stats.get("has_data", False):
            return AllExerciseStats(
                exercises={},
                total_exercises_tracked=0,
                total_sets_all=0,
                has_data=False,
            )

        logger.info(f"Retrieved stats for {stats.get('total_exercises_tracked', 0)} exercises for user {user_id}")

        return AllExerciseStats(
            exercises=stats.get("exercises", {}),
            total_exercises_tracked=stats.get("total_exercises_tracked", 0),
            total_sets_all=stats.get("total_sets_all", 0),
            has_data=True,
        )

    except Exception as e:
        logger.error(f"Error getting exercise stats: {e}")
        raise safe_internal_error(e, "performance_db")


@router.get("/exercise-stats/{user_id}/{exercise_name}", response_model=ExerciseStats)
async def get_single_exercise_stats(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get detailed stats for a specific exercise.

    Returns:
    - Total sets logged
    - Total volume (weight * reps in kg)
    - Max weight used
    - Max reps achieved
    - Estimated 1RM (Brzycki formula)
    - Average RPE
    - Last workout date
    - Progression trend
    """
    try:
        from services.adaptive_workout_service import get_adaptive_workout_service
        db = get_supabase_db()
        adaptive_service = get_adaptive_workout_service(db.client)

        # URL-decode the exercise name (handles spaces encoded as %20)
        from urllib.parse import unquote
        decoded_name = unquote(exercise_name)

        stats = await adaptive_service.get_exercise_stats(user_id, decoded_name)

        if not stats.get("has_data", False):
            return ExerciseStats(
                exercise_name=decoded_name,
                total_sets=0,
                has_data=False,
                message=f"No performance data found for '{decoded_name}'"
            )

        logger.info(f"Retrieved stats for '{decoded_name}' for user {user_id}: {stats.get('total_sets', 0)} sets")

        # Parse progression if it exists
        progression_data = stats.get("progression")
        progression = None
        if progression_data:
            progression = ExerciseProgressionTrend(
                trend=progression_data.get("trend", "unknown"),
                change_percent=progression_data.get("change_percent"),
                message=progression_data.get("message", ""),
            )

        return ExerciseStats(
            exercise_name=decoded_name,
            total_sets=stats.get("total_sets", 0),
            total_volume=stats.get("total_volume"),
            max_weight=stats.get("max_weight"),
            max_reps=stats.get("max_reps"),
            estimated_1rm=stats.get("estimated_1rm"),
            avg_rpe=stats.get("avg_rpe"),
            last_workout_date=stats.get("last_workout_date"),
            progression=progression,
            has_data=True,
        )

    except Exception as e:
        logger.error(f"Error getting exercise stats for '{exercise_name}': {e}")
        raise safe_internal_error(e, "performance_db")


@router.get("/exercise-history/{user_id}", response_model=List[ExerciseHistoryItem])
async def get_exercise_history(
    user_id: str,
    limit: int = Query(default=20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's exercise history with stats for each exercise.

    Returns a list of exercises sorted by total sets (most performed first).
    Includes stats like max weight, estimated 1RM, and progression trend.
    """
    try:
        from services.adaptive_workout_service import get_adaptive_workout_service
        db = get_supabase_db()
        adaptive_service = get_adaptive_workout_service(db.client)

        history = await adaptive_service.get_user_exercise_history(user_id, limit)

        if not history:
            logger.info(f"No exercise history found for user {user_id}")
            return []

        logger.info(f"Retrieved exercise history for user {user_id}: {len(history)} exercises")

        # Convert to response model
        result = []
        for item in history:
            progression_data = item.get("progression")
            progression = None
            if progression_data and isinstance(progression_data, dict):
                progression = ExerciseProgressionTrend(
                    trend=progression_data.get("trend", "unknown"),
                    change_percent=progression_data.get("change_percent"),
                    message=progression_data.get("message", ""),
                )

            result.append(ExerciseHistoryItem(
                exercise_name=item.get("exercise_name", "Unknown"),
                total_sets=item.get("total_sets", 0),
                total_volume=item.get("total_volume"),
                max_weight=item.get("max_weight"),
                max_reps=item.get("max_reps"),
                estimated_1rm=item.get("estimated_1rm"),
                avg_rpe=item.get("avg_rpe"),
                last_workout_date=item.get("last_workout_date"),
                progression=progression,
                has_data=item.get("has_data", True),
            ))

        return result

    except Exception as e:
        logger.error(f"Error getting exercise history: {e}")
        raise safe_internal_error(e, "performance_db")
