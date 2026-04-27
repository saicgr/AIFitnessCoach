package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Room entity for pending sync items
 */
@Entity(
    tableName = "sync_queue",
    indices = [Index("status"), Index("priority", "createdAt")]
)
data class SyncQueueEntity(
    @PrimaryKey
    val id: String,
    val syncType: String, // 'workout_set', 'food_log', 'fasting_action', 'workout_complete'
    val payloadJson: String,
    val priority: Int = 0, // Higher = sync first
    val status: String = "pending", // 'pending', 'syncing', 'completed', 'failed'
    val retryCount: Int = 0,
    val maxRetries: Int = 3,
    val errorMessage: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val syncedAt: Long? = null
)

enum class SyncType {
    WORKOUT_SET,
    WORKOUT_COMPLETE,
    FOOD_LOG,
    FASTING_START,
    FASTING_PAUSE,
    FASTING_RESUME,
    FASTING_END,
    WATER_LOG,
    HEALTH_DATA
}

enum class SyncStatus {
    PENDING,
    SYNCING,
    COMPLETED,
    FAILED
}
