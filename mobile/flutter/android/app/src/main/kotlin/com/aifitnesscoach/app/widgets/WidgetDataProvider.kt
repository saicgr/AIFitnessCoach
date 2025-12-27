package com.aifitnesscoach.app.widgets

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject
import org.json.JSONArray

/**
 * Provides data from Flutter app SharedPreferences to Android widgets.
 */
class WidgetDataProvider(private val context: Context) {

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        // Widget data keys (must match Flutter WidgetService)
        const val KEY_WORKOUT = "workout_data"
        const val KEY_STREAK = "streak_data"
        const val KEY_WATER = "water_data"
        const val KEY_FOOD = "food_data"
        const val KEY_STATS = "stats_data"
        const val KEY_CHALLENGES = "challenges_data"
        const val KEY_ACHIEVEMENTS = "achievements_data"
        const val KEY_GOALS = "goals_data"
        const val KEY_CALENDAR = "calendar_data"
        const val KEY_AI_COACH = "aicoach_data"
    }

    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    // MARK: - Workout Data

    fun getWorkoutData(): WorkoutWidgetData {
        val jsonString = prefs.getString(KEY_WORKOUT, null) ?: return WorkoutWidgetData.placeholder
        return try {
            val json = JSONObject(jsonString)
            WorkoutWidgetData(
                id = json.optString("id", null),
                name = json.optString("name", "No Workout"),
                duration = json.optInt("duration", 0),
                exerciseCount = json.optInt("exercises", 0),
                muscleGroup = json.optString("muscle", ""),
                isRestDay = json.optBoolean("isRestDay", false)
            )
        } catch (e: Exception) {
            WorkoutWidgetData.placeholder
        }
    }

    // MARK: - Streak Data

    fun getStreakData(): StreakWidgetData {
        val jsonString = prefs.getString(KEY_STREAK, null) ?: return StreakWidgetData.placeholder
        return try {
            val json = JSONObject(jsonString)
            StreakWidgetData(
                currentStreak = json.optInt("current", 0),
                longestStreak = json.optInt("longest", 0),
                motivationalMessage = json.optString("message", "Start your journey!"),
                weeklyConsistency = parseWeeklyConsistency(json.optJSONArray("weekly"))
            )
        } catch (e: Exception) {
            StreakWidgetData.placeholder
        }
    }

    // MARK: - Water Data

    fun getWaterData(): WaterWidgetData {
        val jsonString = prefs.getString(KEY_WATER, null) ?: return WaterWidgetData.placeholder
        return try {
            val json = JSONObject(jsonString)
            WaterWidgetData(
                currentMl = json.optInt("current", 0),
                goalMl = json.optInt("goal", 2500),
                percent = json.optInt("percent", 0)
            )
        } catch (e: Exception) {
            WaterWidgetData.placeholder
        }
    }

    // MARK: - Food Data

    fun getFoodData(): FoodWidgetData {
        val jsonString = prefs.getString(KEY_FOOD, null) ?: return FoodWidgetData.placeholder
        return try {
            val json = JSONObject(jsonString)
            FoodWidgetData(
                calories = json.optInt("calories", 0),
                calorieGoal = json.optInt("calorieGoal", 2000),
                protein = json.optInt("protein", 0),
                carbs = json.optInt("carbs", 0),
                fat = json.optInt("fat", 0)
            )
        } catch (e: Exception) {
            FoodWidgetData.placeholder
        }
    }

    // MARK: - Stats Data

    fun getStatsData(): StatsWidgetData {
        val jsonString = prefs.getString(KEY_STATS, null) ?: return StatsWidgetData.placeholder
        return try {
            val json = JSONObject(jsonString)
            StatsWidgetData(
                workoutsCompleted = json.optInt("workouts", 0),
                workoutsGoal = json.optInt("workoutsGoal", 5),
                totalMinutes = json.optInt("minutes", 0),
                caloriesBurned = json.optInt("calories", 0),
                currentStreak = json.optInt("streak", 0),
                prsThisWeek = json.optInt("prs", 0),
                weightChange = json.optDouble("weightChange", 0.0)
            )
        } catch (e: Exception) {
            StatsWidgetData.placeholder
        }
    }

    // MARK: - AI Coach Data

    fun getAICoachData(): AICoachWidgetData {
        val jsonString = prefs.getString(KEY_AI_COACH, null) ?: return AICoachWidgetData.placeholder
        return try {
            val json = JSONObject(jsonString)
            AICoachWidgetData(
                lastMessagePreview = json.optString("lastMessage", ""),
                lastAgent = json.optString("lastAgent", "coach"),
                quickPrompts = parseQuickPrompts(json.optJSONArray("prompts"))
            )
        } catch (e: Exception) {
            AICoachWidgetData.placeholder
        }
    }

    // MARK: - Helper Methods

    private fun parseWeeklyConsistency(array: JSONArray?): List<Boolean> {
        return try {
            (0 until (array?.length() ?: 0)).map { array!!.getBoolean(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun parseQuickPrompts(array: JSONArray?): List<String> {
        return try {
            (0 until (array?.length() ?: 0)).map { array!!.getString(it) }
        } catch (e: Exception) {
            AICoachWidgetData.defaultPrompts
        }
    }
}

// MARK: - Data Models

data class WorkoutWidgetData(
    val id: String?,
    val name: String,
    val duration: Int,
    val exerciseCount: Int,
    val muscleGroup: String,
    val isRestDay: Boolean
) {
    companion object {
        val placeholder = WorkoutWidgetData(
            id = null,
            name = "Upper Body Power",
            duration = 45,
            exerciseCount = 8,
            muscleGroup = "Chest, Shoulders",
            isRestDay = false
        )
    }
}

data class StreakWidgetData(
    val currentStreak: Int,
    val longestStreak: Int,
    val motivationalMessage: String,
    val weeklyConsistency: List<Boolean>
) {
    companion object {
        val placeholder = StreakWidgetData(
            currentStreak = 7,
            longestStreak = 14,
            motivationalMessage = "You're on fire!",
            weeklyConsistency = listOf(true, true, true, false, true, true, false)
        )
    }
}

data class WaterWidgetData(
    val currentMl: Int,
    val goalMl: Int,
    val percent: Int
) {
    companion object {
        val placeholder = WaterWidgetData(
            currentMl = 1500,
            goalMl = 2500,
            percent = 60
        )
    }
}

data class FoodWidgetData(
    val calories: Int,
    val calorieGoal: Int,
    val protein: Int,
    val carbs: Int,
    val fat: Int
) {
    companion object {
        val placeholder = FoodWidgetData(
            calories = 1250,
            calorieGoal = 2000,
            protein = 85,
            carbs = 120,
            fat = 45
        )
    }

    fun getMealTypeForCurrentTime(): String {
        val hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
        return when (hour) {
            in 5..9 -> "Breakfast"
            in 10..13 -> "Lunch"
            in 14..16 -> "Snack"
            in 17..21 -> "Dinner"
            else -> "Late Snack"
        }
    }
}

data class StatsWidgetData(
    val workoutsCompleted: Int,
    val workoutsGoal: Int,
    val totalMinutes: Int,
    val caloriesBurned: Int,
    val currentStreak: Int,
    val prsThisWeek: Int,
    val weightChange: Double
) {
    companion object {
        val placeholder = StatsWidgetData(
            workoutsCompleted = 4,
            workoutsGoal = 5,
            totalMinutes = 245,
            caloriesBurned = 2100,
            currentStreak = 7,
            prsThisWeek = 2,
            weightChange = -0.5
        )
    }
}

data class AICoachWidgetData(
    val lastMessagePreview: String,
    val lastAgent: String,
    val quickPrompts: List<String>
) {
    companion object {
        val defaultPrompts = listOf(
            "What should I eat today?",
            "Modify my workout",
            "I'm feeling tired"
        )

        val placeholder = AICoachWidgetData(
            lastMessagePreview = "Ready to help with your fitness journey!",
            lastAgent = "coach",
            quickPrompts = defaultPrompts
        )
    }
}
