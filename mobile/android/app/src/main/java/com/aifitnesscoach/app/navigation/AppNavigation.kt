package com.aifitnesscoach.app.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.aifitnesscoach.app.screens.home.HomeScreen
import com.aifitnesscoach.app.screens.auth.LoginScreen
import com.aifitnesscoach.app.screens.onboarding.OnboardingScreen
import com.aifitnesscoach.app.screens.workout.WorkoutDetailScreen
import com.aifitnesscoach.app.screens.chat.ChatScreen

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Onboarding : Screen("onboarding")
    object Home : Screen("home")
    object WorkoutDetail : Screen("workout/{workoutId}") {
        fun createRoute(workoutId: String) = "workout/$workoutId"
    }
    object Chat : Screen("chat")
}

@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Login.route
    ) {
        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = { isNewUser ->
                    if (isNewUser) {
                        navController.navigate(Screen.Onboarding.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    } else {
                        navController.navigate(Screen.Home.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    }
                }
            )
        }

        composable(Screen.Onboarding.route) {
            OnboardingScreen(
                onOnboardingComplete = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Home.route) {
            HomeScreen(
                onWorkoutClick = { workoutId ->
                    navController.navigate(Screen.WorkoutDetail.createRoute(workoutId))
                },
                onChatClick = {
                    navController.navigate(Screen.Chat.route)
                }
            )
        }

        composable(Screen.WorkoutDetail.route) { backStackEntry ->
            val workoutId = backStackEntry.arguments?.getString("workoutId") ?: return@composable
            WorkoutDetailScreen(
                workoutId = workoutId,
                onBackClick = { navController.popBackStack() }
            )
        }

        composable(Screen.Chat.route) {
            ChatScreen(
                onBackClick = { navController.popBackStack() }
            )
        }
    }
}
