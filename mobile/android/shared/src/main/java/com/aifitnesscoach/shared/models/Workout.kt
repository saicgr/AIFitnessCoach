package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Workout(
    val id: String? = null,
    @SerialName("user_id") val userId: String,
    val name: String,
    val type: String? = null,
    val difficulty: String? = null,
    @SerialName("scheduled_date") val scheduledDate: String? = null,
    @SerialName("is_completed") val isCompleted: Boolean = false,
    @SerialName("exercises_json") val exercises: List<WorkoutExercise>? = null,
    @SerialName("duration_minutes") val durationMinutes: Int? = null,
    @SerialName("generation_method") val generationMethod: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
data class WorkoutExercise(
    val id: String? = null,
    @SerialName("exercise_id") val exerciseId: String? = null,
    val name: String,
    val sets: Int? = null,
    val reps: String? = null, // Can be "8-12" or "10"
    @SerialName("rest_seconds") val restSeconds: Int? = null,
    @SerialName("duration_seconds") val durationSeconds: Int? = null,
    val weight: Double? = null,
    val notes: String? = null,
    @SerialName("gif_url") val gifUrl: String? = null,
    @SerialName("video_url") val videoUrl: String? = null,
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
