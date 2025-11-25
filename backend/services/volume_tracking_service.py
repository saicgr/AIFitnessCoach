"""
Volume Tracking Service - Weekly muscle group volume tracking.

Handles:
- Calculating weekly volume per muscle group
- Determining recovery status
- Identifying undertrained/overtrained muscles
"""
from typing import Dict, List
from models.performance import WorkoutPerformance, MuscleGroupVolume
from core import get_muscle_groups, get_target_sets, get_recovery_status


class VolumeTrackingService:
    """Tracks weekly volume per muscle group."""

    def calculate_weekly_volume(
        self,
        workouts: List[WorkoutPerformance],
    ) -> List[MuscleGroupVolume]:
        """Calculate weekly volume per muscle group."""
        muscle_volumes: Dict[str, Dict] = {}

        for workout in workouts:
            for exercise in workout.exercises:
                muscles = get_muscle_groups(exercise.exercise_name)

                for muscle in muscles:
                    if muscle not in muscle_volumes:
                        muscle_volumes[muscle] = {
                            "total_sets": 0,
                            "total_reps": 0,
                            "total_volume_kg": 0,
                            "days_trained": set(),
                        }

                    muscle_volumes[muscle]["total_sets"] += len(exercise.sets)
                    muscle_volumes[muscle]["total_reps"] += exercise.total_reps
                    muscle_volumes[muscle]["total_volume_kg"] += exercise.total_volume
                    muscle_volumes[muscle]["days_trained"].add(
                        workout.scheduled_date.date()
                    )

        # Convert to MuscleGroupVolume objects
        result = []
        for muscle, data in muscle_volumes.items():
            recovery_status = get_recovery_status(muscle, data["total_sets"])

            result.append(MuscleGroupVolume(
                muscle_group=muscle,
                total_sets=data["total_sets"],
                total_reps=data["total_reps"],
                total_volume_kg=data["total_volume_kg"],
                frequency=len(data["days_trained"]),
                target_sets=get_target_sets(muscle),
                recovery_status=recovery_status,
            ))

        return result

    def get_undertrained_muscles(
        self,
        volumes: List[MuscleGroupVolume],
    ) -> List[MuscleGroupVolume]:
        """Get muscles that need more volume."""
        return [v for v in volumes if v.recovery_status == "undertrained"]

    def get_overtrained_muscles(
        self,
        volumes: List[MuscleGroupVolume],
    ) -> List[MuscleGroupVolume]:
        """Get muscles that are overtrained."""
        return [v for v in volumes if v.recovery_status == "overtrained"]
