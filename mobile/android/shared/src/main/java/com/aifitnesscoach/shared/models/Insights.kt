package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * AI-generated micro-insight for users
 */
@Serializable
data class UserInsight(
    val id: String? = null,
    @SerialName("user_id") val userId: String,
    @SerialName("insight_type") val insightType: String,  // 'performance', 'consistency', 'motivation', 'tip', 'milestone'
    val message: String,
    val emoji: String? = null,
    val priority: Int = 1,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("generated_at") val generatedAt: String? = null
)

/**
 * Weekly program progress tracking
 */
@Serializable
data class WeeklyProgress(
    val id: String? = null,
    @SerialName("user_id") val userId: String,
    @SerialName("week_start_date") val weekStartDate: String,
    val year: Int? = null,
    @SerialName("week_number") val weekNumber: Int? = null,
    @SerialName("planned_workouts") val plannedWorkouts: Int = 0,
    @SerialName("completed_workouts") val completedWorkouts: Int = 0,
    @SerialName("total_duration_minutes") val totalDurationMinutes: Int = 0,
    @SerialName("total_calories_burned") val totalCaloriesBurned: Int = 0,
    @SerialName("target_workouts") val targetWorkouts: Int? = null,
    @SerialName("goals_met") val goalsMet: Boolean = false
)

/**
 * Response from insights API
 */
@Serializable
data class InsightsResponse(
    val insights: List<UserInsight> = emptyList(),
    @SerialName("weekly_progress") val weeklyProgress: WeeklyProgress? = null
)

/**
 * Response from generate insights API
 */
@Serializable
data class GenerateInsightsResponse(
    val message: String,
    val generated: Boolean = false,
    @SerialName("insights_count") val insightsCount: Int? = null
)

/**
 * Response from weekly progress history
 */
@Serializable
data class WeeklyProgressHistoryResponse(
    val weeks: List<WeeklyProgress> = emptyList()
)
