package com.fitwiz.wearos.data.models

/**
 * Health data synced from phone's Health Connect to the watch.
 * This allows the watch to display consolidated health data
 * from phone-connected fitness apps and devices.
 */
data class PhoneHealthData(
    val steps: Int = 0,
    val distanceMeters: Float = 0f,
    val caloriesBurned: Int = 0,
    val activeMinutes: Int = 0,
    val floorsClimbed: Int = 0,
    val heartRateSamples: List<PhoneHeartRateSample> = emptyList(),
    val sleepData: PhoneSleepData? = null,
    val lastSyncTime: Long = System.currentTimeMillis(),
    val source: String = "phone_health_connect"
)

/**
 * Heart rate sample from phone
 */
data class PhoneHeartRateSample(
    val bpm: Int,
    val timestamp: Long
)

/**
 * Sleep data from phone
 */
data class PhoneSleepData(
    val sleepStartTime: Long,
    val sleepEndTime: Long,
    val totalDurationMinutes: Int,
    val deepSleepMinutes: Int = 0,
    val lightSleepMinutes: Int = 0,
    val remSleepMinutes: Int = 0,
    val awakeDuringNightMinutes: Int = 0,
    val sleepScore: Int? = null
)

/**
 * Combined daily activity data from both watch and phone
 */
data class CombinedDailyActivity(
    val date: Long,

    // Steps
    val watchSteps: Int = 0,
    val phoneSteps: Int = 0,
    val totalSteps: Int = 0, // Deduplicated total

    // Distance
    val watchDistanceMeters: Float = 0f,
    val phoneDistanceMeters: Float = 0f,
    val totalDistanceMeters: Float = 0f,

    // Calories
    val watchCalories: Int = 0,
    val phoneCalories: Int = 0,
    val totalCalories: Int = 0,

    // Active time
    val watchActiveMinutes: Int = 0,
    val phoneActiveMinutes: Int = 0,
    val totalActiveMinutes: Int = 0,

    // Heart rate (from watch sensors)
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val minHeartRate: Int? = null,
    val restingHeartRate: Int? = null,

    // Sleep (usually from phone)
    val sleepData: PhoneSleepData? = null,

    // Floors (from phone or watch barometer)
    val floorsClimbed: Int = 0,

    // Workouts
    val workoutsCompleted: Int = 0,
    val totalWorkoutMinutes: Int = 0,

    // Goal progress
    val stepsGoal: Int = 10000,
    val caloriesGoal: Int = 500,
    val activeMinutesGoal: Int = 30,
    val floorsGoal: Int = 10,

    // Progress percentages
    val stepsProgress: Float = 0f,
    val caloriesProgress: Float = 0f,
    val activeMinutesProgress: Float = 0f
) {
    companion object {
        fun create(
            date: Long,
            watchData: WearDailyActivity,
            phoneData: PhoneHealthData?,
            goals: DailyGoals
        ): CombinedDailyActivity {
            // Use max of watch/phone for steps (assuming some overlap)
            val totalSteps = maxOf(watchData.steps, phoneData?.steps ?: 0)
            val totalDistance = maxOf(watchData.distanceKm * 1000, phoneData?.distanceMeters ?: 0f)
            val totalCalories = maxOf(watchData.caloriesBurned, phoneData?.caloriesBurned ?: 0)
            val totalActiveMinutes = maxOf(watchData.activeMinutes, phoneData?.activeMinutes ?: 0)

            return CombinedDailyActivity(
                date = date,
                watchSteps = watchData.steps,
                phoneSteps = phoneData?.steps ?: 0,
                totalSteps = totalSteps,
                watchDistanceMeters = watchData.distanceKm * 1000,
                phoneDistanceMeters = phoneData?.distanceMeters ?: 0f,
                totalDistanceMeters = totalDistance,
                watchCalories = watchData.caloriesBurned,
                phoneCalories = phoneData?.caloriesBurned ?: 0,
                totalCalories = totalCalories,
                watchActiveMinutes = watchData.activeMinutes,
                phoneActiveMinutes = phoneData?.activeMinutes ?: 0,
                totalActiveMinutes = totalActiveMinutes,
                sleepData = phoneData?.sleepData,
                floorsClimbed = phoneData?.floorsClimbed ?: 0,
                workoutsCompleted = watchData.workoutsCompleted,
                stepsGoal = goals.stepsGoal,
                caloriesGoal = goals.caloriesGoal,
                activeMinutesGoal = goals.activeMinutesGoal,
                floorsGoal = goals.floorsGoal,
                stepsProgress = (totalSteps.toFloat() / goals.stepsGoal).coerceIn(0f, 1f),
                caloriesProgress = (totalCalories.toFloat() / goals.caloriesGoal).coerceIn(0f, 1f),
                activeMinutesProgress = (totalActiveMinutes.toFloat() / goals.activeMinutesGoal).coerceIn(0f, 1f)
            )
        }
    }
}

/**
 * User's daily health goals
 */
data class DailyGoals(
    val stepsGoal: Int = 10000,
    val caloriesGoal: Int = 500,
    val activeMinutesGoal: Int = 30,
    val floorsGoal: Int = 10,
    val waterMlGoal: Int = 2500,
    val sleepHoursGoal: Float = 8f
)

/**
 * Health data sync message format
 * Used for phone -> watch health data sync
 */
data class HealthDataSyncMessage(
    val type: String, // "full_sync", "incremental", "steps_only", etc.
    val healthData: PhoneHealthData,
    val goals: DailyGoals? = null,
    val timestamp: Long = System.currentTimeMillis()
)
