"""
Workout Modifier Service.

Handles adding/removing exercises and modifying workouts based on AI intent.
"""
import json
from typing import List, Optional, Dict, Any
from datetime import datetime
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.chat import CoachIntent

logger = get_logger(__name__)


class WorkoutModifier:
    """Service to modify workouts based on AI coach intent."""

    def __init__(self):
        self.db = get_supabase_db()

    def add_exercises_to_workout(
        self,
        workout_id: int,
        exercise_names: List[str],
        muscle_groups: Optional[List[str]] = None
    ) -> bool:
        """
        Add exercises to a workout.

        Returns True if successful, False otherwise.
        """
        try:
            # Fetch current workout
            workout = self.db.get_workout(workout_id)

            if not workout:
                logger.error(f"Workout {workout_id} not found")
                return False

            exercises_data = workout.get("exercises")
            modification_history = workout.get("modification_history") or []

            # Handle exercises (could be string or list)
            if isinstance(exercises_data, str):
                exercises = json.loads(exercises_data) if exercises_data else []
            else:
                exercises = exercises_data or []

            # Handle modification_history (could be string or list)
            if isinstance(modification_history, str):
                history = json.loads(modification_history) if modification_history else []
            else:
                history = modification_history or []

            logger.info(f"Adding {len(exercise_names)} exercises to workout {workout_id}")

            # Add new exercises
            for exercise_name in exercise_names:
                # Create exercise entry
                new_exercise = {
                    "exercise_id": f"ex_{exercise_name.lower().replace(' ', '_')}",
                    "name": exercise_name,
                    "sets": 3,
                    "reps": 12,
                    "rest_seconds": 60,
                }

                # Check if exercise already exists
                if not any(ex.get("name", "").lower() == exercise_name.lower() for ex in exercises):
                    exercises.append(new_exercise)
                    logger.info(f"Added exercise: {exercise_name}")
                else:
                    logger.info(f"Exercise already exists: {exercise_name}")

            # Update modification history
            history.append({
                "type": "add_exercises",
                "exercises": exercise_names,
                "timestamp": datetime.now().isoformat(),
                "method": "ai_coach"
            })

            # Update workout in database
            update_data = {
                "exercises": exercises,
                "modification_history": history,
                "last_modified_method": "ai_coach",
            }

            self.db.update_workout(workout_id, update_data)

            # Log the workout change
            self._log_workout_change(
                workout_id=workout_id,
                user_id=workout.get("user_id"),
                change_type="add_exercises",
                field_changed="exercises",
                new_value=json.dumps({"added": exercise_names}),
                change_source="ai_coach",
                change_reason="User requested to add exercises"
            )

            logger.info(f"Successfully updated workout {workout_id} with {len(exercise_names)} exercises")
            return True

        except Exception as e:
            logger.error(f"Failed to add exercises to workout {workout_id}: {e}")
            return False

    def remove_exercises_from_workout(
        self,
        workout_id: int,
        exercise_names: List[str]
    ) -> bool:
        """
        Remove exercises from a workout.

        Returns True if successful, False otherwise.
        """
        try:
            # Fetch current workout
            workout = self.db.get_workout(workout_id)

            if not workout:
                logger.error(f"Workout {workout_id} not found")
                return False

            exercises_data = workout.get("exercises")
            modification_history = workout.get("modification_history") or []

            # Handle exercises (could be string or list)
            if isinstance(exercises_data, str):
                exercises = json.loads(exercises_data) if exercises_data else []
            else:
                exercises = exercises_data or []

            # Handle modification_history (could be string or list)
            if isinstance(modification_history, str):
                history = json.loads(modification_history) if modification_history else []
            else:
                history = modification_history or []

            logger.info(f"Removing {len(exercise_names)} exercises from workout {workout_id}")

            # Remove specified exercises (case-insensitive match)
            exercise_names_lower = [name.lower() for name in exercise_names]
            original_count = len(exercises)
            exercises = [
                ex for ex in exercises
                if ex.get("name", "").lower() not in exercise_names_lower
            ]
            removed_count = original_count - len(exercises)

            # Update modification history
            history.append({
                "type": "remove_exercises",
                "exercises": exercise_names,
                "removed_count": removed_count,
                "timestamp": datetime.now().isoformat(),
                "method": "ai_coach"
            })

            # Update workout in database
            update_data = {
                "exercises": exercises,
                "modification_history": history,
                "last_modified_method": "ai_coach",
            }

            self.db.update_workout(workout_id, update_data)

            # Log the workout change
            self._log_workout_change(
                workout_id=workout_id,
                user_id=workout.get("user_id"),
                change_type="remove_exercises",
                field_changed="exercises",
                new_value=json.dumps({"removed": exercise_names, "count": removed_count}),
                change_source="ai_coach",
                change_reason="User requested to remove exercises"
            )

            logger.info(f"Successfully removed {removed_count} exercises from workout {workout_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to remove exercises from workout {workout_id}: {e}")
            return False

    def modify_workout_intensity(
        self,
        workout_id: int,
        modification: str = "adjust"
    ) -> bool:
        """
        Modify workout intensity (increase/decrease sets, reps, or rest).

        IMPORTANT: Respects user's fitness level ceiling to prevent
        beginners from getting inappropriate volume.

        Returns True if successful, False otherwise.
        """
        try:
            # Fetch current workout
            workout = self.db.get_workout(workout_id)

            if not workout:
                logger.error(f"Workout {workout_id} not found")
                return False

            # Get user's fitness level for ceiling enforcement
            user_id = workout.get("user_id")
            user = self.db.get_user(user_id) if user_id else None
            fitness_level = (user.get("fitness_level") if user else None) or "intermediate"

            # Define fitness level ceilings (matches AdaptiveWorkoutService)
            FITNESS_CEILINGS = {
                "beginner": {"sets_max": 3, "reps_max": 12, "reps_min": 6},
                "intermediate": {"sets_max": 5, "reps_max": 15, "reps_min": 4},
                "advanced": {"sets_max": 8, "reps_max": 20, "reps_min": 1},
            }
            ceiling = FITNESS_CEILINGS.get(fitness_level.lower(), FITNESS_CEILINGS["intermediate"])

            exercises_data = workout.get("exercises")
            modification_history = workout.get("modification_history") or []

            # Handle exercises (could be string or list)
            if isinstance(exercises_data, str):
                exercises = json.loads(exercises_data) if exercises_data else []
            else:
                exercises = exercises_data or []

            # Handle modification_history (could be string or list)
            if isinstance(modification_history, str):
                history = json.loads(modification_history) if modification_history else []
            else:
                history = modification_history or []

            logger.info(f"Modifying intensity for workout {workout_id}: {modification} (fitness_level={fitness_level})")

            # Adjust intensity based on modification type, respecting fitness level ceilings
            if "easier" in modification.lower() or "reduce" in modification.lower():
                # Make workout easier: reduce sets/reps, increase rest
                for ex in exercises:
                    ex["sets"] = max(1, ex.get("sets", 3) - 1)
                    ex["reps"] = max(ceiling["reps_min"], ex.get("reps", 12) - 2)
                    ex["rest_seconds"] = min(120, ex.get("rest_seconds", 60) + 15)
            elif "harder" in modification.lower() or "increase" in modification.lower():
                # Make workout harder: increase sets/reps, reduce rest
                # CRITICAL: Cap at user's fitness level ceiling
                for ex in exercises:
                    ex["sets"] = min(ceiling["sets_max"], ex.get("sets", 3) + 1)
                    ex["reps"] = min(ceiling["reps_max"], ex.get("reps", 12) + 2)
                    ex["rest_seconds"] = max(30, ex.get("rest_seconds", 60) - 10)
                logger.info(f"Applied fitness level ceiling: sets_max={ceiling['sets_max']}, reps_max={ceiling['reps_max']}")

            # Update modification history
            history.append({
                "type": "modify_intensity",
                "modification": modification,
                "timestamp": datetime.now().isoformat(),
                "method": "ai_coach"
            })

            # Update workout in database
            update_data = {
                "exercises": exercises,
                "modification_history": history,
                "last_modified_method": "ai_coach",
            }

            self.db.update_workout(workout_id, update_data)

            # Log the workout change
            self._log_workout_change(
                workout_id=workout_id,
                user_id=workout.get("user_id"),
                change_type="modify_intensity",
                field_changed="exercises",
                new_value=json.dumps({"modification": modification}),
                change_source="ai_coach",
                change_reason=f"User requested intensity modification: {modification}"
            )

            logger.info(f"Successfully modified intensity for workout {workout_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to modify intensity for workout {workout_id}: {e}")
            return False

    def _log_workout_change(
        self,
        workout_id: int,
        user_id: int,
        change_type: str,
        field_changed: str,
        new_value: str,
        change_source: str = "ai_coach",
        change_reason: Optional[str] = None,
        old_value: Optional[str] = None
    ):
        """Log a workout change to the workout_changes table."""
        try:
            change_data = {
                "workout_id": workout_id,
                "user_id": user_id,
                "change_type": change_type,
                "field_changed": field_changed,
                "old_value": old_value,
                "new_value": new_value,
                "change_source": change_source,
                "change_reason": change_reason,
            }
            self.db.create_workout_change(change_data)
            logger.debug(f"Logged workout change: {change_type} for workout {workout_id}")
        except Exception as e:
            logger.warning(f"Failed to log workout change: {e}")
