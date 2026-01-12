package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.fitwiz.wearos.data.models.SessionStatus
import com.fitwiz.wearos.data.models.WearWorkoutSession

/**
 * Room entity for workout sessions
 */
@Entity(tableName = "workout_sessions")
data class WorkoutSessionEntity(
    @PrimaryKey
    val id: String,
    val workoutId: String?,
    val workoutName: String,
    val deviceId: String,
    val startedAt: Long,
    val endedAt: Long? = null,
    val status: String,
    val totalSets: Int = 0,
    val totalReps: Int = 0,
    val totalVolumeKg: Float = 0f,
    val totalRestSeconds: Int = 0,
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val caloriesBurned: Int? = null,
    val syncedToPhone: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

fun WorkoutSessionEntity.toWearWorkoutSession(): WearWorkoutSession {
    return WearWorkoutSession(
        id = id,
        workoutId = workoutId,
        workoutName = workoutName,
        deviceId = deviceId,
        startedAt = startedAt,
        endedAt = endedAt,
        status = SessionStatus.valueOf(status),
        totalSets = totalSets,
        totalReps = totalReps,
        totalVolumeKg = totalVolumeKg,
        totalRestSeconds = totalRestSeconds,
        avgHeartRate = avgHeartRate,
        maxHeartRate = maxHeartRate,
        caloriesBurned = caloriesBurned,
        syncedToPhone = syncedToPhone
    )
}

fun WearWorkoutSession.toEntity(): WorkoutSessionEntity {
    return WorkoutSessionEntity(
        id = id,
        workoutId = workoutId,
        workoutName = workoutName,
        deviceId = deviceId,
        startedAt = startedAt,
        endedAt = endedAt,
        status = status.name,
        totalSets = totalSets,
        totalReps = totalReps,
        totalVolumeKg = totalVolumeKg,
        totalRestSeconds = totalRestSeconds,
        avgHeartRate = avgHeartRate,
        maxHeartRate = maxHeartRate,
        caloriesBurned = caloriesBurned,
        syncedToPhone = syncedToPhone
    )
}
