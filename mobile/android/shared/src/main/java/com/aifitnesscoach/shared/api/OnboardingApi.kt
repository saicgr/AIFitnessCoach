package com.aifitnesscoach.shared.api

import com.aifitnesscoach.shared.models.OnboardingParseRequest
import com.aifitnesscoach.shared.models.OnboardingParseResponse
import com.aifitnesscoach.shared.models.OnboardingValidateRequest
import com.aifitnesscoach.shared.models.OnboardingValidateResponse
import com.aifitnesscoach.shared.models.OnboardingSaveConversationRequest
import com.aifitnesscoach.shared.models.OnboardingSaveConversationResponse
import retrofit2.http.Body
import retrofit2.http.POST

interface OnboardingApi {
    @POST("api/v1/onboarding/parse-response")
    suspend fun parseResponse(@Body request: OnboardingParseRequest): OnboardingParseResponse

    @POST("api/v1/onboarding/validate-data")
    suspend fun validateData(@Body request: OnboardingValidateRequest): OnboardingValidateResponse

    @POST("api/v1/onboarding/save-conversation")
    suspend fun saveConversation(@Body request: OnboardingSaveConversationRequest): OnboardingSaveConversationResponse
}
