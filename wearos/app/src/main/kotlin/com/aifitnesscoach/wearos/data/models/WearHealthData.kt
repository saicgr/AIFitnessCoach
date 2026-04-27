package com.fitwiz.wearos.data.models

/**
 * Health data collected from watch sensors
 */
data class WearHealthData(
    val timestamp: Long = System.currentTimeMillis(),
    val heartRateBpm: Int? = null,
    val caloriesBurned: Int = 0,
    val steps: Int = 0,
    val distanceMeters: Float = 0f,
    val activeMinutes: Int = 0
)

/**
 * Real-time workout health metrics
 */
data class WearWorkoutMetrics(
    val currentHeartRate: Int? = null,
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val minHeartRate: Int? = null,
    val caloriesBurned: Int = 0,
    val activeDurationMs: Long = 0,
    val heartRateZone: HeartRateZone = HeartRateZone.UNKNOWN
)

enum class HeartRateZone(val minPercent: Int, val maxPercent: Int, val displayName: String) {
    UNKNOWN(0, 0, "Unknown"),
    REST(0, 50, "Rest"),
    WARM_UP(50, 60, "Warm Up"),
    FAT_BURN(60, 70, "Fat Burn"),
    CARDIO(70, 80, "Cardio"),
    PEAK(80, 90, "Peak"),
    MAX(90, 100, "Max");

    companion object {
        fun fromHeartRate(bpm: Int, maxHeartRate: Int = 220): HeartRateZone {
            if (maxHeartRate == 0) return UNKNOWN
            val percent = (bpm * 100) / maxHeartRate
            return entries.find { percent in it.minPercent until it.maxPercent } ?: UNKNOWN
        }
    }
}

/**
 * Daily activity summary
 */
data class WearDailyActivity(
    val date: Long, // start of day epoch
    val steps: Int = 0,
    val stepsGoal: Int = 10000,
    val caloriesBurned: Int = 0,
    val caloriesGoal: Int = 500,
    val distanceKm: Float = 0f,
    val activeMinutes: Int = 0,
    val activeMinutesGoal: Int = 30,
    val workoutsCompleted: Int = 0
) {
    val stepsProgress: Float get() = (steps.toFloat() / stepsGoal).coerceIn(0f, 1.5f)
    val caloriesProgress: Float get() = (caloriesBurned.toFloat() / caloriesGoal).coerceIn(0f, 1.5f)
    val activeMinutesProgress: Float get() = (activeMinutes.toFloat() / activeMinutesGoal).coerceIn(0f, 1.5f)
}
