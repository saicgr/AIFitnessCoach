package com.fitwiz.wearos.data.models

import java.util.UUID

/**
 * Workout model for Wear OS
 * Represents a workout plan synced from the phone
 */
data class WearWorkout(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val type: WorkoutType,
    val exercises: List<WearExercise>,
    val estimatedDuration: Int, // minutes
    val targetMuscleGroups: List<String>,
    val scheduledDate: Long, // epoch millis
    val isCompleted: Boolean = false,
    val syncedAt: Long? = null
)

enum class WorkoutType {
    PUSH,
    PULL,
    LEGS,
    UPPER,
    LOWER,
    FULL_BODY,
    CARDIO,
    HIIT,
    CUSTOM
}

/**
 * Exercise within a workout
 */
data class WearExercise(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val muscleGroup: String,
    val sets: Int,
    val targetReps: Int,
    val suggestedWeight: Float?, // kg
    val restSeconds: Int,
    val notes: String? = null,
    val thumbnailUrl: String? = null,
    val orderIndex: Int
)

/**
 * A logged set during workout
 */
data class WearSetLog(
    val id: String = UUID.randomUUID().toString(),
    val sessionId: String,
    val exerciseId: String,
    val exerciseName: String,
    val setNumber: Int,
    val targetReps: Int?,
    val actualReps: Int,
    val weightKg: Float?,
    val rpe: Int? = null, // 1-10
    val rir: Int? = null, // 0-10
    val restSecondsAfter: Int? = null,
    val loggedAt: Long = System.currentTimeMillis(),
    val syncedAt: Long? = null
)

/**
 * Active workout session
 */
data class WearWorkoutSession(
    val id: String = UUID.randomUUID().toString(),
    val workoutId: String?,
    val workoutName: String,
    val deviceId: String,
    val startedAt: Long = System.currentTimeMillis(),
    val endedAt: Long? = null,
    val status: SessionStatus = SessionStatus.IN_PROGRESS,
    val totalSets: Int = 0,
    val totalReps: Int = 0,
    val totalVolumeKg: Float = 0f,
    val totalRestSeconds: Int = 0,
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val caloriesBurned: Int? = null,
    val syncedToPhone: Boolean = false
)

enum class SessionStatus {
    IN_PROGRESS,
    COMPLETED,
    ABANDONED
}
