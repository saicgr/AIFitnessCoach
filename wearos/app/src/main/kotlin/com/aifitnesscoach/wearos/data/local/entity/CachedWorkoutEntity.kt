package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.fitwiz.wearos.data.models.WearExercise
import com.fitwiz.wearos.data.models.WearWorkout
import com.fitwiz.wearos.data.models.WorkoutType

/**
 * Room entity for cached workouts
 */
@Entity(tableName = "cached_workouts")
data class CachedWorkoutEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val type: String,
    val exercisesJson: String, // JSON serialized exercises
    val estimatedDuration: Int,
    val targetMuscleGroupsJson: String,
    val scheduledDate: Long,
    val isCompleted: Boolean = false,
    val syncedAt: Long? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

fun CachedWorkoutEntity.toWearWorkout(exercises: List<WearExercise>, muscleGroups: List<String>): WearWorkout {
    return WearWorkout(
        id = id,
        name = name,
        type = WorkoutType.valueOf(type),
        exercises = exercises,
        estimatedDuration = estimatedDuration,
        targetMuscleGroups = muscleGroups,
        scheduledDate = scheduledDate,
        isCompleted = isCompleted,
        syncedAt = syncedAt
    )
}

fun WearWorkout.toEntity(exercisesJson: String, muscleGroupsJson: String): CachedWorkoutEntity {
    return CachedWorkoutEntity(
        id = id,
        name = name,
        type = type.name,
        exercisesJson = exercisesJson,
        estimatedDuration = estimatedDuration,
        targetMuscleGroupsJson = muscleGroupsJson,
        scheduledDate = scheduledDate,
        isCompleted = isCompleted,
        syncedAt = syncedAt
    )
}
