package com.aifitnesscoach.shared.api

import com.aifitnesscoach.shared.models.Workout
import com.aifitnesscoach.shared.models.WorkoutGenerateRequest
import retrofit2.http.*

interface WorkoutApi {
    @GET("api/v1/workouts-db/")
    suspend fun getWorkouts(
        @Query("user_id") userId: String,
        @Query("start_date") startDate: String? = null,
        @Query("end_date") endDate: String? = null
    ): List<Workout>

    @GET("api/v1/workouts-db/{workout_id}")
    suspend fun getWorkout(@Path("workout_id") workoutId: String): Workout

    @POST("api/v1/workouts-db/")
    suspend fun createWorkout(@Body workout: Workout): Workout

    @PUT("api/v1/workouts-db/{workout_id}")
    suspend fun updateWorkout(
        @Path("workout_id") workoutId: String,
        @Body workout: Workout
    ): Workout

    @POST("api/v1/workouts-db/{workout_id}/complete")
    suspend fun completeWorkout(@Path("workout_id") workoutId: String): Workout

    @POST("api/v1/workouts-db/generate")
    suspend fun generateWorkout(@Body request: WorkoutGenerateRequest): Workout

    @POST("api/v1/workouts-db/generate-weekly")
    suspend fun generateWeeklyPlan(@Body request: WorkoutGenerateRequest): List<Workout>

    @POST("api/v1/workouts-db/generate-monthly")
    suspend fun generateMonthlyPlan(@Body request: WorkoutGenerateRequest): List<Workout>

    @GET("api/v1/workouts-db/{workout_id}/warmup")
    suspend fun getWarmup(@Path("workout_id") workoutId: String): List<com.aifitnesscoach.shared.models.Exercise>

    @GET("api/v1/workouts-db/{workout_id}/stretches")
    suspend fun getStretches(@Path("workout_id") workoutId: String): List<com.aifitnesscoach.shared.models.Exercise>
}
