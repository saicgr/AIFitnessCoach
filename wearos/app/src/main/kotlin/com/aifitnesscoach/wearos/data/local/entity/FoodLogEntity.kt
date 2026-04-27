package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.fitwiz.wearos.data.models.FoodInputType
import com.fitwiz.wearos.data.models.MealType
import com.fitwiz.wearos.data.models.WearFoodEntry

/**
 * Room entity for food logs
 */
@Entity(
    tableName = "food_logs",
    indices = [Index("loggedAt"), Index("syncedToPhone")]
)
data class FoodLogEntity(
    @PrimaryKey
    val id: String,
    val inputType: String,
    val rawInput: String?,
    val foodName: String?,
    val calories: Int,
    val proteinG: Float?,
    val carbsG: Float?,
    val fatG: Float?,
    val fiberG: Float?,
    val mealType: String,
    val parseConfidence: Float?,
    val loggedAt: Long,
    val syncedToPhone: Boolean = false,
    val phoneFoodLogId: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)

fun FoodLogEntity.toWearFoodEntry(): WearFoodEntry {
    return WearFoodEntry(
        id = id,
        inputType = FoodInputType.valueOf(inputType),
        rawInput = rawInput,
        foodName = foodName,
        calories = calories,
        proteinG = proteinG,
        carbsG = carbsG,
        fatG = fatG,
        fiberG = fiberG,
        mealType = MealType.valueOf(mealType),
        parseConfidence = parseConfidence,
        loggedAt = loggedAt,
        syncedToPhone = syncedToPhone,
        phoneFoodLogId = phoneFoodLogId
    )
}

fun WearFoodEntry.toEntity(): FoodLogEntity {
    return FoodLogEntity(
        id = id,
        inputType = inputType.name,
        rawInput = rawInput,
        foodName = foodName,
        calories = calories,
        proteinG = proteinG,
        carbsG = carbsG,
        fatG = fatG,
        fiberG = fiberG,
        mealType = mealType.name,
        parseConfidence = parseConfidence,
        loggedAt = loggedAt,
        syncedToPhone = syncedToPhone,
        phoneFoodLogId = phoneFoodLogId
    )
}
