package com.aifitnesscoach.shared.api

import com.aifitnesscoach.shared.models.InsightsResponse
import com.aifitnesscoach.shared.models.GenerateInsightsResponse
import com.aifitnesscoach.shared.models.WeeklyProgressHistoryResponse
import com.aifitnesscoach.shared.models.WeeklyProgress
import retrofit2.http.*

interface InsightsApi {
    /**
     * Get AI-generated micro-insights and current weekly progress
     */
    @GET("api/v1/insights/{user_id}")
    suspend fun getInsights(
        @Path("user_id") userId: String,
        @Query("limit") limit: Int = 5
    ): InsightsResponse

    /**
     * Generate new AI insights based on workout history
     */
    @POST("api/v1/insights/{user_id}/generate")
    suspend fun generateInsights(
        @Path("user_id") userId: String,
        @Query("force_refresh") forceRefresh: Boolean = false
    ): GenerateInsightsResponse

    /**
     * Dismiss (hide) an insight
     */
    @POST("api/v1/insights/{user_id}/dismiss/{insight_id}")
    suspend fun dismissInsight(
        @Path("user_id") userId: String,
        @Path("insight_id") insightId: String
    ): Map<String, String>

    /**
     * Get weekly progress history
     */
    @GET("api/v1/insights/{user_id}/weekly-progress")
    suspend fun getWeeklyProgressHistory(
        @Path("user_id") userId: String,
        @Query("weeks") weeks: Int = 4
    ): WeeklyProgressHistoryResponse

    /**
     * Update current week's progress
     */
    @POST("api/v1/insights/{user_id}/update-weekly-progress")
    suspend fun updateWeeklyProgress(
        @Path("user_id") userId: String
    ): Map<String, Any>
}
