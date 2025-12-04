package com.aifitnesscoach.shared.api

import com.aifitnesscoach.shared.models.ChatMessage
import com.aifitnesscoach.shared.models.ChatRequest
import com.aifitnesscoach.shared.models.ChatResponse
import retrofit2.http.*

interface ChatApi {
    @POST("api/v1/chat/send")
    suspend fun sendMessage(@Body request: ChatRequest): ChatResponse

    @GET("api/v1/chat/history/{user_id}")
    suspend fun getChatHistory(@Path("user_id") userId: String): List<ChatMessage>
}
