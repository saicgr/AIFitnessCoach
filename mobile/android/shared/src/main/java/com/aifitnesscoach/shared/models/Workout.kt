package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Workout model matching backend API response.
 * Note: exercises_json is returned as a JSON string from the backend,
 * not as a native array. Use getExercises() to parse it.
 */
@Serializable
data class Workout(
    val id: String? = null,
    @SerialName("user_id") val userId: String,
    val name: String,
    val type: String? = null,
    val difficulty: String? = null,
    @SerialName("scheduled_date") val scheduledDate: String? = null,
    @SerialName("is_completed") val isCompleted: Boolean = false,
    @SerialName("exercises_json") val exercisesJson: String? = null,  // JSON array string
    @SerialName("duration_minutes") val durationMinutes: Int? = null,
    @SerialName("generation_method") val generationMethod: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
) {
    /** Parse exercises from JSON string */
    fun getExercises(): List<WorkoutExercise> {
        if (exercisesJson.isNullOrBlank()) return emptyList()
        return try {
            kotlinx.serialization.json.Json { ignoreUnknownKeys = true }
                .decodeFromString<List<WorkoutExercise>>(exercisesJson)
        } catch (e: Exception) {
            emptyList()
        }
    }
}

@Serializable
data class WorkoutExercise(
    val id: String? = null,
    @SerialName("exercise_id") val exerciseId: String? = null,
    @SerialName("library_id") val libraryId: String? = null,
    val name: String,
    val sets: Int? = null,
    val reps: Int? = null,
    @SerialName("rest_seconds") val restSeconds: Int? = null,
    @SerialName("duration_seconds") val durationSeconds: Int? = null,
    val weight: Double? = null,
    val notes: String? = null,
    @SerialName("gif_url") val gifUrl: String? = null,
    @SerialName("video_url") val videoUrl: String? = null,
    @SerialName("body_part") val bodyPart: String? = null,
    val equipment: String? = null,
    @SerialName("muscle_group") val muscleGroup: String? = null,
    @SerialName("primary_muscle") val primaryMuscle: String? = null,
    @SerialName("secondary_muscles") val secondaryMuscles: List<String>? = null,
    @SerialName("is_completed") val isCompleted: Boolean = false
)

@Serializable
data class WorkoutGenerateRequest(
    @SerialName("user_id") val userId: String,
    @SerialName("start_date") val startDate: String? = null,
    @SerialName("workout_type") val workoutType: String? = null,
    val duration: Int? = null,
    val focus: String? = null
)

@Serializable
data class GenerateMonthlyRequest(
    @SerialName("user_id") val userId: String,
    @SerialName("month_start_date") val monthStartDate: String,
    @SerialName("selected_days") val selectedDays: List<Int>,
    @SerialName("duration_minutes") val durationMinutes: Int = 45,
    val weeks: Int = 2  // Default to 2 weeks for mobile (faster)
)

@Serializable
data class GenerateMonthlyResponse(
    val workouts: List<Workout>,
    @SerialName("total_generated") val totalGenerated: Int
)

@Serializable
data class RegenerateWorkoutRequest(
    @SerialName("workout_id") val workoutId: String,
    @SerialName("user_id") val userId: String,
    @SerialName("duration_minutes") val durationMinutes: Int? = 45,
    @SerialName("fitness_level") val fitnessLevel: String? = null,  // beginner/intermediate/advanced
    val difficulty: String? = null,  // easy/medium/hard
    val equipment: List<String>? = null,
    @SerialName("focus_areas") val focusAreas: List<String>? = null
)
