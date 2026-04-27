package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.fitwiz.wearos.data.models.WearSetLog

/**
 * Room entity for set logs
 */
@Entity(
    tableName = "set_logs",
    foreignKeys = [
        ForeignKey(
            entity = WorkoutSessionEntity::class,
            parentColumns = ["id"],
            childColumns = ["sessionId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("sessionId")]
)
data class SetLogEntity(
    @PrimaryKey
    val id: String,
    val sessionId: String,
    val exerciseId: String,
    val exerciseName: String,
    val setNumber: Int,
    val targetReps: Int?,
    val actualReps: Int,
    val weightKg: Float?,
    val rpe: Int? = null,
    val rir: Int? = null,
    val restSecondsAfter: Int? = null,
    val loggedAt: Long,
    val syncedAt: Long? = null
)

fun SetLogEntity.toWearSetLog(): WearSetLog {
    return WearSetLog(
        id = id,
        sessionId = sessionId,
        exerciseId = exerciseId,
        exerciseName = exerciseName,
        setNumber = setNumber,
        targetReps = targetReps,
        actualReps = actualReps,
        weightKg = weightKg,
        rpe = rpe,
        rir = rir,
        restSecondsAfter = restSecondsAfter,
        loggedAt = loggedAt,
        syncedAt = syncedAt
    )
}

fun WearSetLog.toEntity(): SetLogEntity {
    return SetLogEntity(
        id = id,
        sessionId = sessionId,
        exerciseId = exerciseId,
        exerciseName = exerciseName,
        setNumber = setNumber,
        targetReps = targetReps,
        actualReps = actualReps,
        weightKg = weightKg,
        rpe = rpe,
        rir = rir,
        restSecondsAfter = restSecondsAfter,
        loggedAt = loggedAt,
        syncedAt = syncedAt
    )
}
