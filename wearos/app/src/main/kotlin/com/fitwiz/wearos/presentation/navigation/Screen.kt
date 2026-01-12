package com.fitwiz.wearos.presentation.navigation

/**
 * Navigation destinations for FitWiz Wear OS
 */
sealed class Screen(val route: String) {
    // Home
    object Home : Screen("home")

    // Workout
    object WorkoutDetail : Screen("workout_detail")
    object ActiveWorkout : Screen("active_workout")
    object SetInput : Screen("set_input/{exerciseIndex}") {
        fun createRoute(exerciseIndex: Int) = "set_input/$exerciseIndex"
    }
    object RestTimer : Screen("rest_timer")
    object WorkoutSummary : Screen("workout_summary")

    // Nutrition
    object FoodLog : Screen("food_log")
    object VoiceInput : Screen("voice_input")
    object KeyboardInput : Screen("keyboard_input")
    object QuickAddCalories : Screen("quick_add_calories")
    object FoodConfirmation : Screen("food_confirmation")
    object NutritionSummary : Screen("nutrition_summary")

    // Fasting
    object Fasting : Screen("fasting")
    object ActiveFast : Screen("active_fast")
    object FastingHistory : Screen("fasting_history")
}
