package com.fitwiz.wearos.voice

import com.fitwiz.wearos.data.models.MealType
import com.fitwiz.wearos.data.models.WearFoodEntry
import com.fitwiz.wearos.data.models.FoodInputType
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Parses voice/text input into food entries
 * Uses regex patterns for basic parsing
 * For more accurate parsing, use the backend Gemini API
 */
@Singleton
class FoodParser @Inject constructor() {

    companion object {
        // Regex patterns for calorie extraction
        private val CALORIE_PATTERNS = listOf(
            Regex("""(\d+)\s*(?:calories?|cals?|kcal)""", RegexOption.IGNORE_CASE),
            Regex("""(?:calories?|cals?|kcal)\s*[:=]?\s*(\d+)""", RegexOption.IGNORE_CASE),
            Regex("""(\d+)\s*cal\b""", RegexOption.IGNORE_CASE)
        )

        // Common food calorie estimates (per serving)
        private val FOOD_ESTIMATES = mapOf(
            "egg" to 70,
            "eggs" to 140,
            "banana" to 105,
            "apple" to 95,
            "orange" to 62,
            "chicken breast" to 165,
            "chicken" to 200,
            "rice" to 206,
            "bread" to 79,
            "toast" to 75,
            "coffee" to 5,
            "milk" to 103,
            "yogurt" to 100,
            "salad" to 150,
            "sandwich" to 300,
            "pizza" to 285,
            "burger" to 354,
            "fries" to 312,
            "pasta" to 221,
            "steak" to 271,
            "salmon" to 208,
            "oatmeal" to 158,
            "cereal" to 150,
            "protein shake" to 150,
            "protein bar" to 200,
            "almonds" to 164,
            "peanut butter" to 188,
            "avocado" to 234,
            "cheese" to 113
        )

        // Quantity patterns
        private val QUANTITY_PATTERN = Regex("""(\d+)\s*(piece|pieces|slice|slices|cup|cups|bowl|bowls|serving|servings)?""", RegexOption.IGNORE_CASE)
    }

    /**
     * Parse voice/text input into a food entry
     */
    fun parse(input: String, inputType: FoodInputType = FoodInputType.VOICE): ParseResult {
        val cleanInput = input.trim().lowercase()

        // Try to extract explicit calories first
        val explicitCalories = extractExplicitCalories(cleanInput)
        if (explicitCalories != null) {
            val foodName = extractFoodName(cleanInput)
            return ParseResult(
                success = true,
                entry = WearFoodEntry(
                    inputType = inputType,
                    rawInput = input,
                    foodName = foodName ?: input,
                    calories = explicitCalories,
                    mealType = detectMealType(),
                    parseConfidence = 0.9f
                )
            )
        }

        // Try to estimate calories from known foods
        val estimation = estimateCalories(cleanInput)
        if (estimation != null) {
            return ParseResult(
                success = true,
                entry = WearFoodEntry(
                    inputType = inputType,
                    rawInput = input,
                    foodName = formatFoodName(input),
                    calories = estimation.first,
                    mealType = detectMealType(),
                    parseConfidence = estimation.second
                )
            )
        }

        // Unable to parse - return partial result for user confirmation
        return ParseResult(
            success = false,
            entry = WearFoodEntry(
                inputType = inputType,
                rawInput = input,
                foodName = formatFoodName(input),
                calories = 200, // Default estimate
                mealType = detectMealType(),
                parseConfidence = 0.3f
            ),
            needsConfirmation = true,
            message = "Please confirm or adjust calories"
        )
    }

    /**
     * Extract explicit calorie count from input
     */
    private fun extractExplicitCalories(input: String): Int? {
        for (pattern in CALORIE_PATTERNS) {
            val match = pattern.find(input)
            if (match != null) {
                return match.groupValues[1].toIntOrNull()
            }
        }
        return null
    }

    /**
     * Extract food name (remove calorie mention)
     */
    private fun extractFoodName(input: String): String? {
        var result = input

        // Remove calorie mentions
        for (pattern in CALORIE_PATTERNS) {
            result = pattern.replace(result, "")
        }

        result = result.trim()
        return if (result.isNotEmpty()) formatFoodName(result) else null
    }

    /**
     * Estimate calories based on known foods
     */
    private fun estimateCalories(input: String): Pair<Int, Float>? {
        val words = input.split(" ")

        // Check for quantity
        var quantity = 1
        val quantityMatch = QUANTITY_PATTERN.find(input)
        if (quantityMatch != null) {
            quantity = quantityMatch.groupValues[1].toIntOrNull() ?: 1
        }

        // Find matching food
        for ((food, calories) in FOOD_ESTIMATES) {
            if (input.contains(food)) {
                val totalCalories = calories * quantity
                val confidence = if (quantity > 1) 0.75f else 0.8f
                return totalCalories to confidence
            }
        }

        return null
    }

    /**
     * Detect meal type based on time of day
     */
    private fun detectMealType(): MealType {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        return MealType.fromTime(hour)
    }

    /**
     * Format food name with proper capitalization
     */
    private fun formatFoodName(input: String): String {
        return input
            .trim()
            .split(" ")
            .joinToString(" ") { word ->
                word.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
            }
    }

    /**
     * Quick add - just calories
     */
    fun quickAdd(calories: Int, mealType: MealType? = null): WearFoodEntry {
        return WearFoodEntry(
            inputType = FoodInputType.QUICK_ADD,
            rawInput = "$calories calories",
            foodName = "Quick Entry",
            calories = calories,
            mealType = mealType ?: detectMealType(),
            parseConfidence = 1.0f
        )
    }
}

data class ParseResult(
    val success: Boolean,
    val entry: WearFoodEntry,
    val needsConfirmation: Boolean = false,
    val message: String? = null
)
