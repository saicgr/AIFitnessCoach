package com.aifitnesscoach.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Exercise(
    val id: String? = null,
    @SerialName("external_id") val externalId: String? = null,
    val name: String,
    val category: String? = null,
    val subcategory: String? = null,
    @SerialName("difficulty_level") val difficultyLevel: String? = null,
    @SerialName("primary_muscle") val primaryMuscle: String? = null,
    @SerialName("secondary_muscles") val secondaryMuscles: List<String>? = null,
    @SerialName("equipment_required") val equipmentRequired: List<String>? = null,
    @SerialName("body_part") val bodyPart: String? = null,
    val target: String? = null,
    @SerialName("default_sets") val defaultSets: Int? = null,
    @SerialName("default_reps") val defaultReps: Int? = null,
    @SerialName("default_duration_seconds") val defaultDurationSeconds: Int? = null,
    @SerialName("default_rest_seconds") val defaultRestSeconds: Int? = null,
    @SerialName("gif_url") val gifUrl: String? = null,
    @SerialName("video_url") val videoUrl: String? = null,
    val instructions: List<String>? = null,
    @SerialName("is_compound") val isCompound: Boolean? = null,
    @SerialName("is_unilateral") val isUnilateral: Boolean? = null,
    val tags: List<String>? = null
)
