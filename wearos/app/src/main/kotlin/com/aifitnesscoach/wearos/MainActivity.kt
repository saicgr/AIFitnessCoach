package com.fitwiz.wearos

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.fitwiz.wearos.data.sync.SyncWorker
import com.fitwiz.wearos.presentation.navigation.Screen
import com.fitwiz.wearos.presentation.screens.home.HomeScreen
import com.fitwiz.wearos.presentation.screens.workout.*
import com.fitwiz.wearos.presentation.screens.nutrition.*
import com.fitwiz.wearos.presentation.screens.fasting.FastingScreen
import com.fitwiz.wearos.presentation.theme.FitWizWearTheme
import com.fitwiz.wearos.presentation.viewmodel.WorkoutViewModel
import com.fitwiz.wearos.presentation.viewmodel.NutritionViewModel
import com.fitwiz.wearos.presentation.viewmodel.FastingViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Schedule background sync
        SyncWorker.schedule(this)

        // Check for deep link from tile
        val destination = intent?.getStringExtra("destination")

        setContent {
            FitWizWearTheme {
                FitWizWearNavigation(
                    initialDestination = destination
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}

@Composable
fun FitWizWearNavigation(
    navController: NavHostController = rememberSwipeDismissableNavController(),
    initialDestination: String? = null
) {
    // Handle initial destination from tile
    LaunchedEffect(initialDestination) {
        initialDestination?.let { dest ->
            when (dest) {
                "workout_detail" -> navController.navigate(Screen.WorkoutDetail.route)
                "nutrition" -> navController.navigate(Screen.NutritionSummary.route)
                "fasting" -> navController.navigate(Screen.Fasting.route)
                "food_log" -> navController.navigate(Screen.FoodLog.route)
            }
        }
    }

    SwipeDismissableNavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        // ==================== Home ====================
        composable(Screen.Home.route) {
            HomeScreen(
                onWorkoutClick = {
                    navController.navigate(Screen.WorkoutDetail.route)
                },
                onFoodClick = {
                    navController.navigate(Screen.FoodLog.route)
                },
                onFastingClick = {
                    navController.navigate(Screen.Fasting.route)
                },
                onWaterClick = {
                    // Water logging is handled inline in HomeScreen
                }
            )
        }

        // ==================== Workout ====================
        composable(Screen.WorkoutDetail.route) {
            val workoutViewModel: WorkoutViewModel = hiltViewModel()
            WorkoutDetailScreen(
                viewModel = workoutViewModel,
                onStartWorkout = {
                    navController.navigate(Screen.ActiveWorkout.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.ActiveWorkout.route) {
            val workoutViewModel: WorkoutViewModel = hiltViewModel()
            ActiveWorkoutScreen(
                viewModel = workoutViewModel,
                onCompleteSet = {
                    navController.navigate(Screen.SetInput.route.replace("{exerciseIndex}", "0"))
                },
                onWorkoutComplete = {
                    navController.navigate(Screen.WorkoutSummary.route) {
                        popUpTo(Screen.Home.route) { inclusive = false }
                    }
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.SetInput.route) {
            val workoutViewModel: WorkoutViewModel = hiltViewModel()
            SetInputScreen(
                viewModel = workoutViewModel,
                onConfirm = {
                    navController.popBackStack()
                },
                onStartRest = {
                    navController.navigate(Screen.RestTimer.route) {
                        popUpTo(Screen.ActiveWorkout.route) { inclusive = false }
                    }
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.RestTimer.route) {
            val workoutViewModel: WorkoutViewModel = hiltViewModel()
            RestTimerScreen(
                viewModel = workoutViewModel,
                onTimerComplete = {
                    navController.popBackStack()
                },
                onSkip = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.WorkoutSummary.route) {
            val workoutViewModel: WorkoutViewModel = hiltViewModel()
            WorkoutSummaryScreen(
                viewModel = workoutViewModel,
                onDone = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                }
            )
        }

        // ==================== Nutrition ====================
        composable(Screen.FoodLog.route) {
            val nutritionViewModel: NutritionViewModel = hiltViewModel()
            FoodLogScreen(
                viewModel = nutritionViewModel,
                onNavigateToConfirm = {
                    navController.navigate(Screen.FoodConfirmation.route)
                },
                onNavigateToQuickAdd = {
                    navController.navigate(Screen.QuickAddCalories.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.FoodConfirmation.route) {
            val nutritionViewModel: NutritionViewModel = hiltViewModel()
            FoodConfirmScreen(
                viewModel = nutritionViewModel,
                onConfirm = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onRedo = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.QuickAddCalories.route) {
            val nutritionViewModel: NutritionViewModel = hiltViewModel()
            QuickAddScreen(
                viewModel = nutritionViewModel,
                onConfirm = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(Screen.NutritionSummary.route) {
            val nutritionViewModel: NutritionViewModel = hiltViewModel()
            NutritionSummaryScreen(
                viewModel = nutritionViewModel,
                onAddFood = {
                    navController.navigate(Screen.FoodLog.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }

        // ==================== Fasting ====================
        composable(Screen.Fasting.route) {
            val fastingViewModel: FastingViewModel = hiltViewModel()
            FastingScreen(
                viewModel = fastingViewModel,
                onBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}
