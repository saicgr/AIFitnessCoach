package com.fitwiz.wearos.data.api

import retrofit2.Response
import retrofit2.http.*

/**
 * Retrofit API interface for direct backend communication from watch.
 * Used as fallback when phone is not connected.
 */
interface FitWizApi {

    // ==================== Workout ====================

    @GET("workouts/today/{userId}")
    suspend fun getTodaysWorkout(
        @Path("userId") userId: String
    ): Response<WorkoutResponse>

    @POST("workouts/{workoutId}/log")
    suspend fun logWorkoutSet(
        @Path("workoutId") workoutId: String,
        @Body setLog: SetLogRequest
    ): Response<SetLogResponse>

    @POST("workouts/{workoutId}/complete")
    suspend fun completeWorkout(
        @Path("workoutId") workoutId: String,
        @Body completion: WorkoutCompletionRequest
    ): Response<WorkoutCompletionResponse>

    // ==================== Nutrition ====================

    @GET("nutrition/summary/{userId}")
    suspend fun getNutritionSummary(
        @Path("userId") userId: String,
        @Query("date") date: String
    ): Response<NutritionSummaryResponse>

    @POST("nutrition/quick-log")
    suspend fun quickLogFood(
        @Body foodLog: FoodLogRequest
    ): Response<FoodLogResponse>

    // ==================== Fasting ====================

    @GET("fasting/current/{userId}")
    suspend fun getCurrentFastingSession(
        @Path("userId") userId: String
    ): Response<FastingSessionResponse>

    @POST("fasting/event")
    suspend fun logFastingEvent(
        @Body event: FastingEventRequest
    ): Response<FastingEventResponse>

    // ==================== Activity/Health ====================

    @POST("activity/sync")
    suspend fun syncActivity(
        @Body activity: ActivitySyncRequest
    ): Response<ActivitySyncResponse>

    @GET("activity/goals/{userId}")
    suspend fun getActivityGoals(
        @Path("userId") userId: String
    ): Response<ActivityGoalsResponse>

    // ==================== User ====================

    @GET("users/{userId}/profile")
    suspend fun getUserProfile(
        @Path("userId") userId: String
    ): Response<UserProfileResponse>

    // ==================== Sync ====================

    @POST("sync/watch")
    suspend fun syncWatchData(
        @Body syncRequest: WatchSyncRequest
    ): Response<WatchSyncResponse>
}

// ==================== Request Models ====================

data class SetLogRequest(
    val sessionId: String,
    val exerciseId: String,
    val exerciseName: String,
    val setNumber: Int,
    val actualReps: Int,
    val weightKg: Float? = null,
    val rpe: Int? = null,
    val rir: Int? = null,
    val loggedAt: Long
)

data class WorkoutCompletionRequest(
    val sessionId: String,
    val startedAt: Long,
    val endedAt: Long,
    val totalSets: Int,
    val totalReps: Int,
    val totalVolumeKg: Float,
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val caloriesBurned: Int? = null
)

data class FoodLogRequest(
    val userId: String,
    val inputType: String,
    val rawInput: String? = null,
    val foodName: String? = null,
    val calories: Int,
    val proteinG: Float? = null,
    val carbsG: Float? = null,
    val fatG: Float? = null,
    val mealType: String,
    val loggedAt: Long,
    val source: String = "watch"
)

data class FastingEventRequest(
    val userId: String,
    val sessionId: String,
    val eventType: String, // START, PAUSE, RESUME, END, COMPLETE
    val protocol: String,
    val targetDurationMinutes: Int,
    val elapsedMinutes: Int,
    val eventAt: Long
)

data class ActivitySyncRequest(
    val userId: String,
    val date: String,
    val steps: Int,
    val caloriesBurned: Int,
    val distanceMeters: Float,
    val activeMinutes: Int,
    val heartRateSamples: List<HeartRateSample>? = null,
    val source: String = "watch"
)

data class HeartRateSample(
    val timestamp: Long,
    val bpm: Int
)

data class WatchSyncRequest(
    val userId: String,
    val workoutSets: List<SetLogRequest>? = null,
    val workoutCompletions: List<WorkoutCompletionRequest>? = null,
    val foodLogs: List<FoodLogRequest>? = null,
    val fastingEvents: List<FastingEventRequest>? = null,
    val activityData: ActivitySyncRequest? = null
)

// ==================== Response Models ====================

data class WorkoutResponse(
    val id: String,
    val name: String,
    val type: String,
    val exercises: List<ExerciseResponse>,
    val estimatedDuration: Int,
    val targetMuscleGroups: List<String>,
    val scheduledDate: String
)

data class ExerciseResponse(
    val id: String,
    val name: String,
    val targetSets: Int,
    val targetReps: String,
    val targetWeightKg: Float?,
    val restSeconds: Int,
    val videoUrl: String?,
    val thumbnailUrl: String?,
    val muscleGroup: String? = null,
    val orderIndex: Int? = null
)

data class SetLogResponse(
    val id: String,
    val success: Boolean
)

data class WorkoutCompletionResponse(
    val id: String,
    val success: Boolean,
    val xpEarned: Int?
)

data class NutritionSummaryResponse(
    val date: String,
    val totalCalories: Int,
    val calorieGoal: Int,
    val proteinG: Float,
    val proteinGoalG: Float,
    val carbsG: Float,
    val carbsGoalG: Float,
    val fatG: Float,
    val fatGoalG: Float,
    val waterMl: Int,
    val waterGoalMl: Int,
    val meals: List<MealResponse>?
)

data class MealResponse(
    val id: String,
    val name: String,
    val calories: Int,
    val mealType: String,
    val loggedAt: Long
)

data class FoodLogResponse(
    val id: String,
    val success: Boolean
)

data class FastingSessionResponse(
    val id: String?,
    val protocol: String?,
    val status: String?,
    val startedAt: Long?,
    val targetDurationMinutes: Int?,
    val elapsedMinutes: Int?
)

data class FastingEventResponse(
    val id: String,
    val success: Boolean
)

data class ActivitySyncResponse(
    val success: Boolean,
    val message: String?
)

data class ActivityGoalsResponse(
    val stepsGoal: Int,
    val activeMinutesGoal: Int,
    val caloriesBurnedGoal: Int,
    val sleepHoursGoal: Float,
    val waterMlGoal: Int
)

data class UserProfileResponse(
    val id: String,
    val name: String,
    val email: String?,
    val weightKg: Float?,
    val heightCm: Float?,
    val fitnessLevel: String?,
    val dailyCalorieGoal: Int?
)

data class WatchSyncResponse(
    val success: Boolean,
    val syncedItems: Int,
    val errors: List<String>?
)
