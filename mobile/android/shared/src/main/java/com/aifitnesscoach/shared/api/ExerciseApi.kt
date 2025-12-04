package com.aifitnesscoach.shared.api

import com.aifitnesscoach.shared.models.Exercise
import retrofit2.http.*

interface ExerciseApi {
    @GET("api/v1/exercises/")
    suspend fun getExercises(
        @Query("body_part") bodyPart: String? = null,
        @Query("equipment") equipment: String? = null,
        @Query("difficulty") difficulty: String? = null
    ): List<Exercise>

    @GET("api/v1/exercises/{exercise_id}")
    suspend fun getExercise(@Path("exercise_id") exerciseId: String): Exercise

    @GET("api/v1/library/exercises/body-parts")
    suspend fun getBodyParts(): List<String>

    @GET("api/v1/library/exercises")
    suspend fun getLibraryExercises(): List<Exercise>
}
