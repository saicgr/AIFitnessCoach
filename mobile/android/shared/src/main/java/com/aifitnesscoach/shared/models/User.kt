package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * User model matching backend API response.
 * Note: Backend returns goals, equipment, active_injuries, and preferences as JSON strings,
 * not as native arrays/objects. This is because the backend's row_to_user() function
 * converts JSONB fields to JSON strings via json.dumps().
 */
@Serializable
data class User(
    val id: String? = null,
    @SerialName("auth_id") val authId: String? = null,
    val username: String? = null,
    val name: String? = null,
    val email: String? = null,
    @SerialName("fitness_level") val fitnessLevel: String? = null,
    val goals: String? = null,  // JSON array string: "[\"Build Muscle\"]"
    val equipment: String? = null,  // JSON array string
    val preferences: String? = null,  // JSON object string
    @SerialName("active_injuries") val activeInjuries: String? = null,  // JSON array string
    @SerialName("height_cm") val heightCm: Double? = null,
    @SerialName("weight_kg") val weightKg: Double? = null,
    val age: Int? = null,
    @SerialName("date_of_birth") val dateOfBirth: String? = null,  // ISO date string: "1990-05-15"
    val gender: String? = null,
    @SerialName("body_fat_percent") val bodyFatPercent: Double? = null,
    @SerialName("resting_heart_rate") val restingHeartRate: Int? = null,
    @SerialName("onboarding_completed") val onboardingCompleted: Boolean = false,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
data class UserPreferences(
    @SerialName("workout_duration") val workoutDuration: Int? = null,
    @SerialName("workout_days") val workoutDays: List<String>? = null,
    @SerialName("preferred_time") val preferredTime: String? = null,
    @SerialName("days_per_week") val daysPerWeek: Int? = null,
    @SerialName("selected_days") val selectedDays: List<Int>? = null,
    @SerialName("training_split") val trainingSplit: String? = null,
    @SerialName("intensity_preference") val intensityPreference: String? = null,
    val name: String? = null,
    val age: Int? = null,
    val gender: String? = null,
    @SerialName("height_cm") val heightCm: Double? = null,
    @SerialName("weight_kg") val weightKg: Double? = null,
    @SerialName("target_weight_kg") val targetWeightKg: Double? = null,
    @SerialName("health_conditions") val healthConditions: List<String>? = null
)

/**
 * Request model for updating user profile.
 * Backend expects goals, equipment, active_injuries, and preferences as JSON strings.
 */
@Serializable
data class UserUpdateRequest(
    @SerialName("fitness_level") val fitnessLevel: String? = null,
    val goals: String? = null,  // JSON array string: "[\"Build Muscle\"]"
    val equipment: String? = null,  // JSON array string
    @SerialName("active_injuries") val activeInjuries: String? = null,  // JSON array string
    val preferences: String? = null,  // JSON object string
    @SerialName("onboarding_completed") val onboardingCompleted: Boolean? = null,
    @SerialName("days_per_week") val daysPerWeek: Int? = null,
    @SerialName("workout_duration") val workoutDuration: Int? = null,
    @SerialName("training_split") val trainingSplit: String? = null,
    @SerialName("intensity_preference") val intensityPreference: String? = null,
    @SerialName("preferred_time") val preferredTime: String? = null,
    val name: String? = null,
    val gender: String? = null,
    val age: Int? = null,
    @SerialName("date_of_birth") val dateOfBirth: String? = null,  // ISO date string: "1990-05-15"
    @SerialName("height_cm") val heightCm: Double? = null,
    @SerialName("weight_kg") val weightKg: Double? = null,
    @SerialName("target_weight_kg") val targetWeightKg: Double? = null,
    @SerialName("selected_days") val selectedDays: String? = null  // JSON array string: "[0, 2, 4]"
)

@Serializable
data class GoogleAuthRequest(
    @SerialName("access_token") val accessToken: String
)

@Serializable
data class AuthResponse(
    val user: User,
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null
)
