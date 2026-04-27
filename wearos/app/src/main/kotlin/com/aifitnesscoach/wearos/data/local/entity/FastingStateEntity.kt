package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.fitwiz.wearos.data.models.FastingProtocol
import com.fitwiz.wearos.data.models.FastingStatus
import com.fitwiz.wearos.data.models.WearFastingSession

/**
 * Room entity for fasting state - only one active at a time
 */
@Entity(
    tableName = "fasting_state",
    indices = [Index("status")]
)
data class FastingStateEntity(
    @PrimaryKey
    val id: String,
    val protocol: String,
    val startTime: Long?,
    val targetDurationMinutes: Int,
    val pausedAt: Long?,
    val pausedDurationMs: Long = 0,
    val endedAt: Long?,
    val status: String,
    val syncedToPhone: Boolean = false,
    val phoneFastingRecordId: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

fun FastingStateEntity.toWearFastingSession(): WearFastingSession {
    return WearFastingSession(
        id = id,
        protocol = FastingProtocol.valueOf(protocol),
        startTime = startTime,
        targetDurationMinutes = targetDurationMinutes,
        pausedAt = pausedAt,
        pausedDurationMs = pausedDurationMs,
        endedAt = endedAt,
        status = FastingStatus.valueOf(status),
        syncedToPhone = syncedToPhone,
        phoneFastingRecordId = phoneFastingRecordId
    )
}

fun WearFastingSession.toEntity(): FastingStateEntity {
    return FastingStateEntity(
        id = id,
        protocol = protocol.name,
        startTime = startTime,
        targetDurationMinutes = targetDurationMinutes,
        pausedAt = pausedAt,
        pausedDurationMs = pausedDurationMs,
        endedAt = endedAt,
        status = status.name,
        syncedToPhone = syncedToPhone,
        phoneFastingRecordId = phoneFastingRecordId
    )
}

/**
 * Room entity for fasting history
 */
@Entity(
    tableName = "fasting_history",
    indices = [Index("startTime")]
)
data class FastingHistoryEntity(
    @PrimaryKey
    val id: String,
    val protocol: String,
    val startTime: Long,
    val endTime: Long,
    val targetDurationMinutes: Int,
    val actualDurationMinutes: Int,
    val wasCompleted: Boolean,
    val createdAt: Long = System.currentTimeMillis()
)
