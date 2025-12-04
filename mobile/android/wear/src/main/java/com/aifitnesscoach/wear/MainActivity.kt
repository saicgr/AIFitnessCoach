package com.aifitnesscoach.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.aifitnesscoach.wear.screens.HomeScreen
import com.aifitnesscoach.wear.screens.WorkoutScreen
import com.aifitnesscoach.wear.theme.WearTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            WearTheme {
                WearNavigation()
            }
        }
    }
}

@Composable
fun WearNavigation() {
    val navController = rememberSwipeDismissableNavController()

    SwipeDismissableNavHost(
        navController = navController,
        startDestination = "home"
    ) {
        composable("home") {
            HomeScreen(
                onStartWorkout = {
                    navController.navigate("workout")
                }
            )
        }

        composable("workout") {
            WorkoutScreen(
                onFinish = {
                    navController.popBackStack()
                }
            )
        }
    }
}
