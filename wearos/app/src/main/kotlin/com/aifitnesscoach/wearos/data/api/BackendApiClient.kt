package com.fitwiz.wearos.data.api

import android.util.Log
import com.fitwiz.wearos.data.local.SecureStorage
import com.fitwiz.wearos.data.models.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Client for direct communication with backend API from watch.
 * Used as fallback when phone is not connected.
 */
@Singleton
class BackendApiClient @Inject constructor(
    private val api: FitWizApi,
    private val secureStorage: SecureStorage
) {
    companion object {
        private const val TAG = "BackendApiClient"
    }

    // Current user ID - loaded from SecureStorage on init
    private var userId: String? = secureStorage.getUserId()

    init {
        Log.d(TAG, "Initialized with userId: ${userId?.take(8) ?: "none"}...")
    }

    fun setUserId(id: String) {
        userId = id
        secureStorage.saveUserId(id)
        Log.d(TAG, "User ID set and persisted: ${id.take(8)}...")
    }

    fun getUserId(): String? {
        // Fallback to SecureStorage if in-memory is null
        if (userId == null) {
            userId = secureStorage.getUserId()
        }
        return userId
    }

    fun isAuthenticated(): Boolean = secureStorage.isAuthenticated()

    // ==================== Workout ====================

    suspend fun getTodaysWorkout(): WearWorkout? = withContext(Dispatchers.IO) {
        val uid = userId ?: run {
            Log.w(TAG, "No user ID set")
            return@withContext null
        }

        try {
            val response = api.getTodaysWorkout(uid)
            if (response.isSuccessful) {
                response.body()?.toWearWorkout()
            } else {
                Log.e(TAG, "Failed to get today's workout: ${response.code()}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting today's workout", e)
            null
        }
    }

    suspend fun logWorkoutSet(
        workoutId: String,
        setLog: WearSetLog
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val request = SetLogRequest(
                sessionId = setLog.sessionId,
                exerciseId = setLog.exerciseId,
                exerciseName = setLog.exerciseName,
                setNumber = setLog.setNumber,
                actualReps = setLog.actualReps,
                weightKg = setLog.weightKg,
                rpe = setLog.rpe,
                rir = setLog.rir,
                loggedAt = setLog.loggedAt
            )
            val response = api.logWorkoutSet(workoutId, request)
            response.isSuccessful && response.body()?.success == true
        } catch (e: Exception) {
            Log.e(TAG, "Error logging workout set", e)
            false
        }
    }

    suspend fun completeWorkout(
        workoutId: String,
        session: WearWorkoutSession
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val request = WorkoutCompletionRequest(
                sessionId = session.id,
                startedAt = session.startedAt,
                endedAt = session.endedAt ?: System.currentTimeMillis(),
                totalSets = session.totalSets,
                totalReps = session.totalReps,
                totalVolumeKg = session.totalVolumeKg,
                avgHeartRate = session.avgHeartRate,
                maxHeartRate = session.maxHeartRate,
                caloriesBurned = session.caloriesBurned
            )
            val response = api.completeWorkout(workoutId, request)
            response.isSuccessful && response.body()?.success == true
        } catch (e: Exception) {
            Log.e(TAG, "Error completing workout", e)
            false
        }
    }

    // ==================== Nutrition ====================

    suspend fun getNutritionSummary(date: String): WearNutritionSummary? = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext null

        try {
            val response = api.getNutritionSummary(uid, date)
            if (response.isSuccessful) {
                response.body()?.toWearNutritionSummary()
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting nutrition summary", e)
            null
        }
    }

    suspend fun logFood(foodEntry: WearFoodEntry): Boolean = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext false

        try {
            val request = FoodLogRequest(
                userId = uid,
                inputType = foodEntry.inputType.name,
                rawInput = foodEntry.rawInput,
                foodName = foodEntry.foodName,
                calories = foodEntry.calories,
                proteinG = foodEntry.proteinG,
                carbsG = foodEntry.carbsG,
                fatG = foodEntry.fatG,
                mealType = foodEntry.mealType.name,
                loggedAt = foodEntry.loggedAt
            )
            val response = api.quickLogFood(request)
            response.isSuccessful && response.body()?.success == true
        } catch (e: Exception) {
            Log.e(TAG, "Error logging food", e)
            false
        }
    }

    // ==================== Fasting ====================

    suspend fun getCurrentFastingSession(): WearFastingSession? = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext null

        try {
            val response = api.getCurrentFastingSession(uid)
            if (response.isSuccessful) {
                response.body()?.toWearFastingSession()
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting fasting session", e)
            null
        }
    }

    suspend fun logFastingEvent(
        session: WearFastingSession,
        eventType: FastingEventType
    ): Boolean = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext false

        try {
            val request = FastingEventRequest(
                userId = uid,
                sessionId = session.id,
                eventType = eventType.name,
                protocol = session.protocol.name,
                targetDurationMinutes = session.targetDurationMinutes,
                elapsedMinutes = (session.elapsedMs / 60000).toInt(),
                eventAt = System.currentTimeMillis()
            )
            val response = api.logFastingEvent(request)
            response.isSuccessful && response.body()?.success == true
        } catch (e: Exception) {
            Log.e(TAG, "Error logging fasting event", e)
            false
        }
    }

    // ==================== Activity/Health ====================

    suspend fun syncActivity(
        date: String,
        steps: Int,
        caloriesBurned: Int,
        distanceMeters: Float,
        activeMinutes: Int,
        heartRateSamples: List<Pair<Long, Int>>? = null
    ): Boolean = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext false

        try {
            val request = ActivitySyncRequest(
                userId = uid,
                date = date,
                steps = steps,
                caloriesBurned = caloriesBurned,
                distanceMeters = distanceMeters,
                activeMinutes = activeMinutes,
                heartRateSamples = heartRateSamples?.map { HeartRateSample(it.first, it.second) }
            )
            val response = api.syncActivity(request)
            response.isSuccessful && response.body()?.success == true
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing activity", e)
            false
        }
    }

    suspend fun getActivityGoals(): ActivityGoalsResponse? = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext null

        try {
            val response = api.getActivityGoals(uid)
            if (response.isSuccessful) {
                response.body()
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting activity goals", e)
            null
        }
    }

    // ==================== Bulk Sync ====================

    suspend fun syncAllPendingData(
        workoutSets: List<WearSetLog>? = null,
        workoutCompletions: List<WearWorkoutSession>? = null,
        foodLogs: List<WearFoodEntry>? = null,
        fastingEvents: List<Pair<WearFastingSession, FastingEventType>>? = null
    ): Boolean = withContext(Dispatchers.IO) {
        val uid = userId ?: return@withContext false

        try {
            val request = WatchSyncRequest(
                userId = uid,
                workoutSets = workoutSets?.map { setLog ->
                    SetLogRequest(
                        sessionId = setLog.sessionId,
                        exerciseId = setLog.exerciseId,
                        exerciseName = setLog.exerciseName,
                        setNumber = setLog.setNumber,
                        actualReps = setLog.actualReps,
                        weightKg = setLog.weightKg,
                        rpe = setLog.rpe,
                        rir = setLog.rir,
                        loggedAt = setLog.loggedAt
                    )
                },
                workoutCompletions = workoutCompletions?.map { session ->
                    WorkoutCompletionRequest(
                        sessionId = session.id,
                        startedAt = session.startedAt,
                        endedAt = session.endedAt ?: System.currentTimeMillis(),
                        totalSets = session.totalSets,
                        totalReps = session.totalReps,
                        totalVolumeKg = session.totalVolumeKg,
                        avgHeartRate = session.avgHeartRate,
                        maxHeartRate = session.maxHeartRate,
                        caloriesBurned = session.caloriesBurned
                    )
                },
                foodLogs = foodLogs?.map { food ->
                    FoodLogRequest(
                        userId = uid,
                        inputType = food.inputType.name,
                        rawInput = food.rawInput,
                        foodName = food.foodName,
                        calories = food.calories,
                        proteinG = food.proteinG,
                        carbsG = food.carbsG,
                        fatG = food.fatG,
                        mealType = food.mealType.name,
                        loggedAt = food.loggedAt
                    )
                },
                fastingEvents = fastingEvents?.map { (session, eventType) ->
                    FastingEventRequest(
                        userId = uid,
                        sessionId = session.id,
                        eventType = eventType.name,
                        protocol = session.protocol.name,
                        targetDurationMinutes = session.targetDurationMinutes,
                        elapsedMinutes = (session.elapsedMs / 60000).toInt(),
                        eventAt = System.currentTimeMillis()
                    )
                }
            )
            val response = api.syncWatchData(request)
            val success = response.isSuccessful && response.body()?.success == true
            if (success) {
                Log.d(TAG, "✅ Synced ${response.body()?.syncedItems} items to backend")
            }
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing all pending data", e)
            false
        }
    }
}

// ==================== Extension Functions ====================

private fun WorkoutResponse.toWearWorkout(): WearWorkout {
    return WearWorkout(
        id = id,
        name = name,
        type = parseWorkoutType(type),
        exercises = exercises.mapIndexed { index, it -> it.toWearExercise(index) },
        estimatedDuration = estimatedDuration,
        targetMuscleGroups = targetMuscleGroups,
        scheduledDate = parseScheduledDate(scheduledDate)
    )
}

private fun parseWorkoutType(type: String): WorkoutType {
    return try {
        WorkoutType.valueOf(type.uppercase())
    } catch (e: Exception) {
        WorkoutType.CUSTOM
    }
}

private fun parseScheduledDate(dateStr: String): Long {
    return try {
        java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).parse(dateStr)?.time ?: System.currentTimeMillis()
    } catch (e: Exception) {
        System.currentTimeMillis()
    }
}

private fun ExerciseResponse.toWearExercise(fallbackIndex: Int): WearExercise {
    return WearExercise(
        id = id,
        name = name,
        muscleGroup = muscleGroup ?: "",
        sets = targetSets,
        targetReps = parseTargetReps(targetReps),
        suggestedWeight = targetWeightKg,
        restSeconds = restSeconds,
        thumbnailUrl = thumbnailUrl,
        orderIndex = orderIndex ?: fallbackIndex
    )
}

private fun parseTargetReps(repsStr: String): Int {
    // Handle formats like "8-12", "10", "8-10 reps"
    return try {
        repsStr.replace(Regex("[^0-9-]"), "")
            .split("-")
            .firstOrNull()
            ?.toIntOrNull() ?: 10
    } catch (e: Exception) {
        10
    }
}

private fun NutritionSummaryResponse.toWearNutritionSummary(): WearNutritionSummary {
    return WearNutritionSummary(
        date = parseNutritionDate(date),
        totalCalories = totalCalories,
        calorieGoal = calorieGoal,
        proteinG = proteinG,
        carbsG = carbsG,
        fatG = fatG
    )
}

private fun parseNutritionDate(dateStr: String): Long {
    return try {
        java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).parse(dateStr)?.time ?: System.currentTimeMillis()
    } catch (e: Exception) {
        System.currentTimeMillis()
    }
}

private fun FastingSessionResponse.toWearFastingSession(): WearFastingSession? {
    if (id == null || protocol == null || status == null) return null

    return WearFastingSession(
        id = id,
        protocol = FastingProtocol.valueOf(protocol),
        status = FastingStatus.valueOf(status),
        startTime = startedAt,
        targetDurationMinutes = targetDurationMinutes ?: 0
    )
}
