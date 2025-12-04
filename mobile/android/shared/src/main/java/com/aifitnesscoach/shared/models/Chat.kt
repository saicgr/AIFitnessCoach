package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val id: String? = null,
    @SerialName("user_id") val userId: String,
    val role: String, // "user" or "assistant"
    val content: String,
    val intent: String? = null,
    @SerialName("created_at") val createdAt: String? = null
)

@Serializable
data class ChatRequest(
    @SerialName("user_id") val userId: String,
    val message: String,
    @SerialName("conversation_history") val conversationHistory: List<ChatMessage>? = null
)

@Serializable
data class ChatResponse(
    val response: String,
    val intent: String? = null,
    val actions: List<ChatAction>? = null
)

@Serializable
data class ChatAction(
    val type: String,
    val data: Map<String, String>? = null
)
