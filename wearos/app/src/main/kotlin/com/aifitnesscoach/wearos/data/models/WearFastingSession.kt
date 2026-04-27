package com.fitwiz.wearos.data.models

import java.util.UUID

/**
 * Fasting session model for Wear OS
 */
data class WearFastingSession(
    val id: String = UUID.randomUUID().toString(),
    val protocol: FastingProtocol = FastingProtocol.SIXTEEN_EIGHT,
    val startTime: Long? = null,
    val targetDurationMinutes: Int,
    val pausedAt: Long? = null,
    val pausedDurationMs: Long = 0,
    val endedAt: Long? = null,
    val status: FastingStatus = FastingStatus.NOT_STARTED,
    val syncedToPhone: Boolean = false,
    val phoneFastingRecordId: String? = null
) {
    /**
     * Calculate elapsed time in milliseconds
     */
    val elapsedMs: Long
        get() {
            if (startTime == null) return 0
            val currentTime = when (status) {
                FastingStatus.ACTIVE -> System.currentTimeMillis()
                FastingStatus.PAUSED -> pausedAt ?: System.currentTimeMillis()
                FastingStatus.COMPLETED, FastingStatus.ENDED_EARLY -> endedAt ?: System.currentTimeMillis()
                FastingStatus.NOT_STARTED -> return 0
            }
            return currentTime - startTime - pausedDurationMs
        }

    /**
     * Remaining time in milliseconds
     */
    val remainingMs: Long
        get() = maxOf(0, targetDurationMinutes * 60 * 1000L - elapsedMs)

    /**
     * Progress as a fraction (0.0 to 1.0)
     */
    val progress: Float
        get() {
            if (targetDurationMinutes == 0) return 0f
            return (elapsedMs.toFloat() / (targetDurationMinutes * 60 * 1000L)).coerceIn(0f, 1f)
        }

    /**
     * Format elapsed time as HH:MM
     */
    val elapsedFormatted: String
        get() {
            val totalMinutes = (elapsedMs / 60000).toInt()
            val hours = totalMinutes / 60
            val minutes = totalMinutes % 60
            return "%d:%02d".format(hours, minutes)
        }

    /**
     * Format remaining time as HH:MM
     */
    val remainingFormatted: String
        get() {
            val totalMinutes = (remainingMs / 60000).toInt()
            val hours = totalMinutes / 60
            val minutes = totalMinutes % 60
            return "%d:%02d".format(hours, minutes)
        }
}

enum class FastingProtocol(val fastingHours: Int, val eatingHours: Int, val displayName: String) {
    TWELVE_TWELVE(12, 12, "12:12"),
    FOURTEEN_TEN(14, 10, "14:10"),
    SIXTEEN_EIGHT(16, 8, "16:8"),
    EIGHTEEN_SIX(18, 6, "18:6"),
    TWENTY_FOUR(20, 4, "20:4"),
    OMAD(23, 1, "OMAD"),
    CUSTOM(0, 0, "Custom");

    val targetMinutes: Int get() = fastingHours * 60
}

enum class FastingStatus {
    NOT_STARTED,
    ACTIVE,
    PAUSED,
    COMPLETED,
    ENDED_EARLY
}

/**
 * Fasting event for sync
 */
data class WearFastingEvent(
    val id: String = UUID.randomUUID().toString(),
    val sessionId: String,
    val eventType: FastingEventType,
    val eventAt: Long = System.currentTimeMillis(),
    val protocol: FastingProtocol,
    val targetDurationMinutes: Int,
    val elapsedMinutes: Int,
    val syncedToPhone: Boolean = false
)

enum class FastingEventType {
    START,
    PAUSE,
    RESUME,
    END,
    COMPLETE
}

/**
 * Fasting streak info
 */
data class WearFastingStreak(
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val lastCompletedDate: Long? = null,
    val totalFastsCompleted: Int = 0
)
