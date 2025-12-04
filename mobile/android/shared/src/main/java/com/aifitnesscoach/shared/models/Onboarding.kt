package com.aifitnesscoach.shared.models

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.*

@Serializable
data class OnboardingParseRequest(
    @SerialName("user_id") val userId: String,
    val message: String,
    @SerialName("current_data") val currentData: Map<String, @Serializable(with = AnySerializer::class) Any?> = emptyMap(),
    @SerialName("conversation_history") val conversationHistory: List<ConversationMessage> = emptyList()
)

@Serializable
data class ConversationMessage(
    val role: String,
    val content: String
)

@Serializable
data class OnboardingParseResponse(
    @SerialName("extracted_data") val extractedData: Map<String, @Serializable(with = AnySerializer::class) Any?>? = null,
    @SerialName("next_question") val nextQuestion: NextQuestion? = null,
    @SerialName("is_complete") val isComplete: Boolean = false,
    @SerialName("missing_fields") val missingFields: List<String> = emptyList()
)

@Serializable
data class NextQuestion(
    val question: String,
    @SerialName("quick_replies") val quickReplies: List<QuickReply>? = null,
    val component: String? = null,
    @SerialName("multi_select") val multiSelect: Boolean = false
)

@Serializable
data class QuickReply(
    val label: String,
    val value: String
)

@Serializable
data class OnboardingValidateRequest(
    val data: Map<String, @Serializable(with = AnySerializer::class) Any?>
)

@Serializable
data class OnboardingValidateResponse(
    val valid: Boolean,
    val errors: Map<String, String> = emptyMap(),
    val complete: Boolean = false,
    @SerialName("missing_fields") val missingFields: List<String> = emptyList()
)

@Serializable
data class OnboardingSaveConversationRequest(
    @SerialName("user_id") val userId: String,
    val conversation: List<ConversationMessageFull>
)

@Serializable
data class ConversationMessageFull(
    val role: String,
    val content: String,
    val timestamp: String,
    @SerialName("extracted_data") val extractedData: Map<String, @Serializable(with = AnySerializer::class) Any?>? = null
)

@Serializable
data class OnboardingSaveConversationResponse(
    val success: Boolean,
    val message: String? = null
)

// Custom serializer to handle Any type in Maps
object AnySerializer : KSerializer<Any?> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("Any")

    override fun serialize(encoder: Encoder, value: Any?) {
        val jsonEncoder = encoder as JsonEncoder
        val jsonElement = when (value) {
            null -> JsonNull
            is String -> JsonPrimitive(value)
            is Number -> JsonPrimitive(value)
            is Boolean -> JsonPrimitive(value)
            is List<*> -> JsonArray(value.map { serializeAny(it) })
            is Map<*, *> -> JsonObject(value.entries.associate { (k, v) -> k.toString() to serializeAny(v) })
            else -> JsonPrimitive(value.toString())
        }
        jsonEncoder.encodeJsonElement(jsonElement)
    }

    private fun serializeAny(value: Any?): JsonElement = when (value) {
        null -> JsonNull
        is String -> JsonPrimitive(value)
        is Number -> JsonPrimitive(value)
        is Boolean -> JsonPrimitive(value)
        is List<*> -> JsonArray(value.map { serializeAny(it) })
        is Map<*, *> -> JsonObject(value.entries.associate { (k, v) -> k.toString() to serializeAny(v) })
        else -> JsonPrimitive(value.toString())
    }

    override fun deserialize(decoder: Decoder): Any? {
        val jsonDecoder = decoder as JsonDecoder
        return deserializeJsonElement(jsonDecoder.decodeJsonElement())
    }

    private fun deserializeJsonElement(element: JsonElement): Any? = when (element) {
        is JsonNull -> null
        is JsonPrimitive -> when {
            element.isString -> element.content
            element.booleanOrNull != null -> element.boolean
            element.intOrNull != null -> element.int
            element.longOrNull != null -> element.long
            element.doubleOrNull != null -> element.double
            else -> element.content
        }
        is JsonArray -> element.map { deserializeJsonElement(it) }
        is JsonObject -> element.entries.associate { (k, v) -> k to deserializeJsonElement(v) }
    }
}
