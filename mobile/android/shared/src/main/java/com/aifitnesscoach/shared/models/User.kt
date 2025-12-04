package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String? = null,
    @SerialName("auth_id") val authId: String? = null,
    val username: String? = null,
    val name: String? = null,
    val email: String? = null,
    @SerialName("fitness_level") val fitnessLevel: String? = null,
    val goals: List<String>? = null,
    val equipment: List<String>? = null,
    val preferences: UserPreferences? = null,
    @SerialName("active_injuries") val activeInjuries: List<String>? = null,
    @SerialName("height_cm") val heightCm: Double? = null,
    @SerialName("weight_kg") val weightKg: Double? = null,
    val age: Int? = null,
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
    @SerialName("preferred_time") val preferredTime: String? = null
)

@Serializable
data class GoogleAuthRequest(
    @SerialName("id_token") val idToken: String
)

@Serializable
data class AuthResponse(
    val user: User,
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null
)
