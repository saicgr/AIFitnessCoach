package com.fitwiz.wearos.data.models

import java.util.UUID

/**
 * Food entry model for Wear OS
 * Supports voice, keyboard, and quick-add input
 */
data class WearFoodEntry(
    val id: String = UUID.randomUUID().toString(),
    val inputType: FoodInputType,
    val rawInput: String?, // Original voice/text input
    val foodName: String?,
    val calories: Int,
    val proteinG: Float? = null,
    val carbsG: Float? = null,
    val fatG: Float? = null,
    val fiberG: Float? = null,
    val mealType: MealType,
    val parseConfidence: Float? = null, // 0.0 to 1.0
    val loggedAt: Long = System.currentTimeMillis(),
    val syncedToPhone: Boolean = false,
    val phoneFoodLogId: String? = null
)

enum class FoodInputType {
    VOICE,
    KEYBOARD,
    QUICK_ADD
}

enum class MealType {
    BREAKFAST,
    LUNCH,
    DINNER,
    SNACK;

    companion object {
        fun fromTime(hourOfDay: Int): MealType {
            return when (hourOfDay) {
                in 5..10 -> BREAKFAST
                in 11..14 -> LUNCH
                in 15..17 -> SNACK
                in 18..21 -> DINNER
                else -> SNACK
            }
        }
    }
}

/**
 * Daily nutrition summary
 */
data class WearNutritionSummary(
    val date: Long, // start of day epoch
    val totalCalories: Int = 0,
    val calorieGoal: Int = 2000,
    val proteinG: Float = 0f,
    val proteinGoalG: Float = 150f,
    val carbsG: Float = 0f,
    val carbsGoalG: Float = 200f,
    val fatG: Float = 0f,
    val fatGoalG: Float = 65f,
    val fiberG: Float = 0f,
    val fiberGoalG: Float = 30f,
    val waterCups: Int = 0,
    val waterGoalCups: Int = 8,
    val meals: List<WearFoodEntry> = emptyList()
) {
    val calorieProgress: Float get() = (totalCalories.toFloat() / calorieGoal).coerceIn(0f, 1.5f)
    val proteinProgress: Float get() = (proteinG / proteinGoalG).coerceIn(0f, 1.5f)
    val carbsProgress: Float get() = (carbsG / carbsGoalG).coerceIn(0f, 1.5f)
    val fatProgress: Float get() = (fatG / fatGoalG).coerceIn(0f, 1.5f)
    val waterProgress: Float get() = (waterCups.toFloat() / waterGoalCups).coerceIn(0f, 1.5f)
}
