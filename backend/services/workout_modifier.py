"""
Workout Modifier Service.

Handles adding/removing exercises and modifying workouts based on AI intent.
"""
import json
from typing import List, Optional, Dict, Any
from core.duckdb_database import get_db
from core.logger import get_logger
from models.chat import CoachIntent

logger = get_logger(__name__)


class WorkoutModifier:
    """Service to modify workouts based on AI coach intent."""

    def __init__(self):
        self.db = get_db()

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
            workout_row = self.db.conn.execute(
                "SELECT exercises_json, modification_history FROM workouts WHERE id = ?",
                [workout_id]
            ).fetchone()

            if not workout_row:
                logger.error(f"Workout {workout_id} not found")
                return False

            exercises_json = workout_row[0]
            modification_history = workout_row[1] or "[]"

            # Parse existing exercises
            exercises = json.loads(exercises_json) if exercises_json else []

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
            history = json.loads(modification_history)
            history.append({
                "type": "add_exercises",
                "exercises": exercise_names,
                "timestamp": "now()",
                "method": "ai_coach"
            })

            # Update workout in database
            self.db.conn.execute("""
                UPDATE workouts
                SET exercises_json = ?,
                    modification_history = ?,
                    last_modified_method = 'ai_coach',
                    last_modified_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, [json.dumps(exercises), json.dumps(history), workout_id])

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
            workout_row = self.db.conn.execute(
                "SELECT exercises_json, modification_history FROM workouts WHERE id = ?",
                [workout_id]
            ).fetchone()

            if not workout_row:
                logger.error(f"Workout {workout_id} not found")
                return False

            exercises_json = workout_row[0]
            modification_history = workout_row[1] or "[]"

            # Parse existing exercises
            exercises = json.loads(exercises_json) if exercises_json else []

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
            history = json.loads(modification_history)
            history.append({
                "type": "remove_exercises",
                "exercises": exercise_names,
                "removed_count": removed_count,
                "timestamp": "now()",
                "method": "ai_coach"
            })

            # Update workout in database
            self.db.conn.execute("""
                UPDATE workouts
                SET exercises_json = ?,
                    modification_history = ?,
                    last_modified_method = 'ai_coach',
                    last_modified_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, [json.dumps(exercises), json.dumps(history), workout_id])

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

        Returns True if successful, False otherwise.
        """
        try:
            # Fetch current workout
            workout_row = self.db.conn.execute(
                "SELECT exercises_json, modification_history FROM workouts WHERE id = ?",
                [workout_id]
            ).fetchone()

            if not workout_row:
                logger.error(f"Workout {workout_id} not found")
                return False

            exercises_json = workout_row[0]
            modification_history = workout_row[1] or "[]"

            # Parse existing exercises
            exercises = json.loads(exercises_json) if exercises_json else []

            logger.info(f"Modifying intensity for workout {workout_id}: {modification}")

            # Adjust intensity based on modification type
            if "easier" in modification.lower() or "reduce" in modification.lower():
                # Make workout easier: reduce sets/reps, increase rest
                for ex in exercises:
                    ex["sets"] = max(1, ex.get("sets", 3) - 1)
                    ex["reps"] = max(5, ex.get("reps", 12) - 2)
                    ex["rest_seconds"] = min(120, ex.get("rest_seconds", 60) + 15)
            elif "harder" in modification.lower() or "increase" in modification.lower():
                # Make workout harder: increase sets/reps, reduce rest
                for ex in exercises:
                    ex["sets"] = min(5, ex.get("sets", 3) + 1)
                    ex["reps"] = min(20, ex.get("reps", 12) + 2)
                    ex["rest_seconds"] = max(30, ex.get("rest_seconds", 60) - 10)

            # Update modification history
            history = json.loads(modification_history)
            history.append({
                "type": "modify_intensity",
                "modification": modification,
                "timestamp": "now()",
                "method": "ai_coach"
            })

            # Update workout in database
            self.db.conn.execute("""
                UPDATE workouts
                SET exercises_json = ?,
                    modification_history = ?,
                    last_modified_method = 'ai_coach',
                    last_modified_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, [json.dumps(exercises), json.dumps(history), workout_id])

            logger.info(f"Successfully modified intensity for workout {workout_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to modify intensity for workout {workout_id}: {e}")
            return False
