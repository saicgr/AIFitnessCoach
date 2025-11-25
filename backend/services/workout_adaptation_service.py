"""
Workout Adaptation Service - Adapts workouts based on various factors.

Handles:
- Missed muscle compensation
- Recovery-based modifications
- Time constraint adjustments
- Injury substitutions
"""
from typing import List, Dict, Any, Optional
from core import (
    MUSCLE_TO_EXERCISES, EXERCISE_TIME_ESTIMATES,
    get_exercise_priority, is_exercise_contraindicated, find_safe_substitute
)


class WorkoutAdaptationService:
    """Adapts workouts based on various factors."""

    def adapt_for_missed_muscles(
        self,
        exercises: List[Dict[str, Any]],
        missed_muscles: List[str],
        available_time: Optional[int] = None,
    ) -> tuple[List[Dict[str, Any]], List[str]]:
        """Add exercises to compensate for missed muscle groups."""
        changes = []
        current_exercises = [e.get("name", "").lower() for e in exercises]

        for muscle in missed_muscles:
            muscle_lower = muscle.lower()
            potential_exercises = MUSCLE_TO_EXERCISES.get(muscle_lower, [])

            for exercise_name in potential_exercises:
                if exercise_name.lower() not in current_exercises:
                    new_exercise = self._create_exercise(
                        name=exercise_name,
                        sets=3,
                        reps=12,
                        reason=f"compensating for missed {muscle}",
                    )
                    exercises.append(new_exercise)
                    changes.append(f"Added {exercise_name} to compensate for missed {muscle}")
                    break

        return exercises, changes

    def adapt_for_recovery(
        self,
        exercises: List[Dict[str, Any]],
        fatigue_level: int,
    ) -> tuple[List[Dict[str, Any]], List[str]]:
        """Reduce workout intensity based on fatigue level (1-10)."""
        changes = []

        if fatigue_level >= 8:
            reduction_factor = 0.6
            changes.append("Reduced volume by 40% due to high fatigue")
        elif fatigue_level >= 6:
            reduction_factor = 0.8
            changes.append("Reduced volume by 20% due to moderate fatigue")
        else:
            return exercises, changes

        for exercise in exercises:
            original_sets = exercise.get("sets", 3)
            new_sets = max(2, int(original_sets * reduction_factor))
            if new_sets != original_sets:
                exercise["sets"] = new_sets
                exercise["recovery_adjusted"] = True

        return exercises, changes

    def adapt_for_time(
        self,
        exercises: List[Dict[str, Any]],
        available_time: int,
    ) -> tuple[List[Dict[str, Any]], List[str]]:
        """Shorten workout to fit available time."""
        changes = []
        current_duration = self._estimate_workout_duration(exercises)

        if current_duration <= available_time:
            return exercises, changes

        prioritized = sorted(
            exercises,
            key=lambda e: get_exercise_priority(e.get("name", "")),
            reverse=True,
        )

        while self._estimate_workout_duration(prioritized) > available_time and len(prioritized) > 2:
            removed = prioritized.pop()
            changes.append(f"Removed {removed.get('name', 'exercise')} to save time")

        if self._estimate_workout_duration(prioritized) > available_time:
            for exercise in prioritized:
                if exercise.get("sets", 3) > 2:
                    exercise["sets"] = exercise.get("sets", 3) - 1
            changes.append("Reduced sets per exercise to fit time constraint")

        return prioritized, changes

    def adapt_for_injuries(
        self,
        exercises: List[Dict[str, Any]],
        injuries: List[str],
    ) -> tuple[List[Dict[str, Any]], List[str]]:
        """Substitute exercises that aggravate injuries."""
        changes = []

        for injury in injuries:
            injury_lower = injury.lower()
            new_exercises = []

            for exercise in exercises:
                exercise_name = exercise.get("name", "")

                if is_exercise_contraindicated(exercise_name, injury_lower):
                    substitute = find_safe_substitute(exercise_name, injury_lower)
                    if substitute:
                        new_exercise = exercise.copy()
                        new_exercise["name"] = substitute
                        new_exercise["substituted_for"] = exercise_name
                        new_exercise["injury_modification"] = True
                        new_exercises.append(new_exercise)
                        changes.append(f"Substituted {exercise_name} with {substitute} due to {injury}")
                    else:
                        changes.append(f"Removed {exercise_name} due to {injury} injury")
                else:
                    new_exercises.append(exercise)

            exercises = new_exercises

        return exercises, changes

    def _create_exercise(
        self,
        name: str,
        sets: int,
        reps: int,
        reason: str,
    ) -> Dict[str, Any]:
        """Create a new exercise entry."""
        return {
            "name": name.title(),
            "sets": sets,
            "reps": reps,
            "rest_seconds": 90,
            "added_reason": reason,
            "is_adaptation": True,
        }

    def _estimate_workout_duration(self, exercises: List[Dict[str, Any]]) -> int:
        """Estimate workout duration in minutes."""
        total_minutes = 5  # Warm-up

        for exercise in exercises:
            sets = exercise.get("sets", 3)
            rest_seconds = exercise.get("rest_seconds", 90)
            time_per_set = 1 + (rest_seconds / 60)
            total_minutes += sets * time_per_set

        return int(total_minutes)
