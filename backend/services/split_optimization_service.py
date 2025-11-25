"""
Split Optimization Service - AI-optimized weekly training splits.

Handles:
- Creating optimal weekly splits based on muscle recovery
- Prioritizing undertrained muscles
- Balancing training frequency
"""
from typing import List, Dict, Any
from models.performance import MuscleGroupVolume
from core import MUSCLE_TO_EXERCISES


class SplitOptimizationService:
    """Creates AI-optimized weekly training splits."""

    def optimize_weekly_split(
        self,
        user_id: int,
        muscle_volumes: List[MuscleGroupVolume],
        available_days: int = 4,
    ) -> List[Dict[str, Any]]:
        """
        Create an AI-optimized weekly split based on muscle group needs.

        Replaces traditional "leg day" / "arm day" with intelligent
        distribution based on recovery status and volume requirements.
        """
        # Group muscles by recovery status
        needs_more = [m for m in muscle_volumes if m.recovery_status == "undertrained"]
        recovered = [m for m in muscle_volumes if m.recovery_status == "recovered"]

        workout_days = []

        for day in range(available_days):
            day_exercises = []

            # Prioritize undertrained muscles
            if needs_more:
                muscle = needs_more[day % len(needs_more)]
                exercises = MUSCLE_TO_EXERCISES.get(muscle.muscle_group, [])
                if exercises:
                    day_exercises.append({
                        "muscle_group": muscle.muscle_group,
                        "exercises": exercises[:2],
                        "priority": "high",
                        "reason": "Undertrained - needs more volume",
                    })

            # Add recovered muscles
            if recovered:
                muscle = recovered[day % len(recovered)]
                exercises = MUSCLE_TO_EXERCISES.get(muscle.muscle_group, [])
                if exercises:
                    day_exercises.append({
                        "muscle_group": muscle.muscle_group,
                        "exercises": exercises[:1],
                        "priority": "normal",
                        "reason": "Maintaining progress",
                    })

            workout_days.append({
                "day": day + 1,
                "focus": [e["muscle_group"] for e in day_exercises],
                "exercise_plan": day_exercises,
            })

        return workout_days

    def get_recommended_frequency(
        self,
        muscle_volumes: List[MuscleGroupVolume],
    ) -> Dict[str, int]:
        """Get recommended training frequency per muscle group."""
        recommendations = {}

        for volume in muscle_volumes:
            if volume.recovery_status == "undertrained":
                recommendations[volume.muscle_group] = 3  # 3x per week
            elif volume.recovery_status == "overtrained":
                recommendations[volume.muscle_group] = 1  # 1x per week
            else:
                recommendations[volume.muscle_group] = 2  # 2x per week

        return recommendations
