package com.aifitnesscoach.app.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.aifitnesscoach.app.auth.AuthRepository
import com.aifitnesscoach.app.auth.AuthState
import com.aifitnesscoach.app.screens.home.HomeScreen
import com.aifitnesscoach.app.screens.auth.LoginScreen
import com.aifitnesscoach.app.screens.onboarding.OnboardingScreen
import com.aifitnesscoach.app.screens.workout.WorkoutDetailScreen
import com.aifitnesscoach.app.screens.workout.ActiveWorkoutScreen
import com.aifitnesscoach.app.screens.chat.ChatScreen
import com.aifitnesscoach.app.screens.library.LibraryScreen
import com.aifitnesscoach.app.screens.metrics.MetricsScreen
import com.aifitnesscoach.app.screens.profile.ProfileScreen
import com.aifitnesscoach.app.screens.nutrition.NutritionScreen
import com.aifitnesscoach.app.screens.achievements.AchievementsScreen
import com.aifitnesscoach.app.screens.settings.SettingsScreen
import com.aifitnesscoach.app.screens.workout.WorkoutCompleteScreen
import com.aifitnesscoach.app.ui.theme.PureBlack
import com.aifitnesscoach.shared.models.Workout

// Colors matching web sidebar
private val Cyan = Color(0xFF06B6D4)
private val Green = Color(0xFF10B981)
private val Purple = Color(0xFFA855F7)
private val Pink = Color(0xFFEC4899)

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Onboarding : Screen("onboarding")
    object Feed : Screen("feed")
    object Home : Screen("home")
    object Library : Screen("library")
    object Chat : Screen("chat")
    object Metrics : Screen("metrics")
    object Profile : Screen("profile")
    object Nutrition : Screen("nutrition")
    object Achievements : Screen("achievements")
    object Settings : Screen("settings")
    object WorkoutDetail : Screen("workout/{workoutId}") {
        fun createRoute(workoutId: String) = "workout/$workoutId"
    }
    object ActiveWorkout : Screen("active-workout")
    object WorkoutComplete : Screen("workout-complete")
}

// Bottom navigation items
data class BottomNavItem(
    val route: String,
    val icon: ImageVector,
    val label: String,
    val color: Color
)

val bottomNavItems = listOf(
    BottomNavItem(Screen.Feed.route, Icons.Default.Home, "Home", Cyan),
    BottomNavItem(Screen.Home.route, Icons.Default.CalendarMonth, "Schedule", Color(0xFF3B82F6)),
    BottomNavItem(Screen.Library.route, Icons.Default.FitnessCenter, "Library", Green),
    BottomNavItem(Screen.Metrics.route, Icons.Default.BarChart, "Metrics", Purple),
    BottomNavItem(Screen.Profile.route, Icons.Default.Person, "Profile", Pink)
)

@Composable
fun AppNavigation(
    authRepository: AuthRepository,
    navController: NavHostController = rememberNavController()
) {
    val currentUser by authRepository.currentUser.collectAsState()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // State for active workout and completion
    var activeWorkout by remember { mutableStateOf<Workout?>(null) }
    var completedWorkout by remember { mutableStateOf<Workout?>(null) }
    var workoutDuration by remember { mutableStateOf(0) }

    // Check existing session on app startup
    LaunchedEffect(Unit) {
        authRepository.checkExistingSession()
    }

    // Observe auth state and auto-navigate
    val authState by authRepository.authState.collectAsState()

    LaunchedEffect(authState) {
        when (val state = authState) {
            is AuthState.Authenticated -> {
                val currentRoute = navController.currentDestination?.route
                if (currentRoute == Screen.Login.route) {
                    if (state.isNewUser) {
                        navController.navigate(Screen.Onboarding.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    } else {
                        navController.navigate(Screen.Feed.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    }
                }
            }
            else -> { /* Stay on current screen */ }
        }
    }

    // Screens that show bottom nav and FAB
    val showBottomNav = currentDestination?.route in listOf(
        Screen.Feed.route,
        Screen.Home.route,
        Screen.Library.route,
        Screen.Metrics.route,
        Screen.Profile.route
    )

    Scaffold(
        containerColor = PureBlack,
        floatingActionButton = {
            if (showBottomNav) {
                FloatingActionButton(
                    onClick = {
                        navController.navigate(Screen.Chat.route) {
                            launchSingleTop = true
                        }
                    },
                    containerColor = Purple,
                    contentColor = Color.White,
                    modifier = Modifier.size(56.dp)
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Chat,
                        contentDescription = "AI Coach",
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        },
        floatingActionButtonPosition = FabPosition.End,
        bottomBar = {
            if (showBottomNav) {
                NavigationBar(
                    containerColor = Color(0xFF0A0A0A),
                    tonalElevation = 0.dp,
                    modifier = Modifier.height(80.dp)
                ) {
                    bottomNavItems.forEach { item ->
                        val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true
                        NavigationBarItem(
                            icon = {
                                Icon(
                                    item.icon,
                                    contentDescription = item.label,
                                    modifier = Modifier.size(24.dp)
                                )
                            },
                            label = {
                                Text(
                                    item.label,
                                    style = MaterialTheme.typography.labelSmall
                                )
                            },
                            selected = selected,
                            onClick = {
                                navController.navigate(item.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = item.color,
                                selectedTextColor = item.color,
                                unselectedIconColor = Color(0xFF71717A),
                                unselectedTextColor = Color(0xFF71717A),
                                indicatorColor = item.color.copy(alpha = 0.15f)
                            )
                        )
                    }
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Login.route,
            modifier = Modifier.padding(paddingValues)
        ) {
            composable(Screen.Login.route) {
                LoginScreen(
                    authRepository = authRepository,
                    onLoginSuccess = { isNewUser ->
                        if (isNewUser) {
                            navController.navigate(Screen.Onboarding.route) {
                                popUpTo(Screen.Login.route) { inclusive = true }
                            }
                        } else {
                            navController.navigate(Screen.Feed.route) {
                                popUpTo(Screen.Login.route) { inclusive = true }
                            }
                        }
                    }
                )
            }

            composable(Screen.Onboarding.route) {
                OnboardingScreen(
                    userId = currentUser?.id ?: "",
                    onOnboardingComplete = {
                        navController.navigate(Screen.Feed.route) {
                            popUpTo(Screen.Onboarding.route) { inclusive = true }
                        }
                    }
                )
            }

            composable(Screen.Feed.route) {
                PlaceholderScreen(
                    title = "Home",
                    subtitle = "Social features coming soon",
                    icon = Icons.Default.Home
                )
            }

            composable(Screen.Home.route) {
                val userName = currentUser?.email?.substringBefore("@")
                    ?.replace(".", " ")
                    ?.split(" ")
                    ?.joinToString(" ") { it.replaceFirstChar { c -> c.uppercase() } }
                    ?: "User"

                HomeScreen(
                    userId = currentUser?.id ?: "",
                    userName = userName,
                    userLevel = "Beginner",
                    onWorkoutClick = { workoutId ->
                        navController.navigate(Screen.WorkoutDetail.createRoute(workoutId))
                    },
                    onChatClick = {
                        navController.navigate(Screen.Chat.route)
                    },
                    onLogout = {
                        navController.navigate(Screen.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }

            composable(Screen.Library.route) {
                LibraryScreen()
            }

            composable(Screen.Chat.route) {
                ChatScreen(
                    userId = currentUser?.id ?: "",
                    onBackClick = { navController.popBackStack() }
                )
            }

            composable(Screen.Metrics.route) {
                MetricsScreen(userId = currentUser?.id ?: "")
            }

            composable(Screen.Profile.route) {
                ProfileScreen(
                    userId = currentUser?.id ?: "",
                    userEmail = currentUser?.email ?: "",
                    onLogout = {
                        navController.navigate(Screen.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }

            composable(Screen.WorkoutDetail.route) { backStackEntry ->
                val workoutId = backStackEntry.arguments?.getString("workoutId") ?: return@composable
                WorkoutDetailScreen(
                    workoutId = workoutId,
                    onBackClick = { navController.popBackStack() },
                    onStartWorkout = { workout ->
                        activeWorkout = workout
                        navController.navigate(Screen.ActiveWorkout.route)
                    }
                )
            }

            composable(Screen.ActiveWorkout.route) {
                val workout = activeWorkout
                if (workout != null) {
                    ActiveWorkoutScreen(
                        workout = workout,
                        onExitWorkout = {
                            activeWorkout = null
                            navController.popBackStack()
                        },
                        onWorkoutComplete = { durationMinutes ->
                            // Save workout info for complete screen
                            completedWorkout = workout
                            workoutDuration = durationMinutes
                            activeWorkout = null
                            navController.navigate(Screen.WorkoutComplete.route) {
                                popUpTo(Screen.Home.route)
                            }
                        }
                    )
                }
            }

            composable(Screen.WorkoutComplete.route) {
                val workout = completedWorkout
                if (workout != null) {
                    WorkoutCompleteScreen(
                        workout = workout,
                        userId = currentUser?.id ?: "",
                        actualDurationMinutes = workoutDuration,
                        onDone = {
                            completedWorkout = null
                            workoutDuration = 0
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.Home.route) { inclusive = true }
                            }
                        }
                    )
                }
            }

            composable(Screen.Nutrition.route) {
                NutritionScreen(userId = currentUser?.id ?: "")
            }

            composable(Screen.Achievements.route) {
                AchievementsScreen(userId = currentUser?.id ?: "")
            }

            composable(Screen.Settings.route) {
                SettingsScreen(
                    onBackClick = { navController.popBackStack() },
                    onLogout = {
                        navController.navigate(Screen.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun PlaceholderScreen(
    title: String,
    subtitle: String,
    icon: ImageVector
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
            .statusBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally
        ) {
            Icon(
                icon,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = Cyan
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.headlineMedium,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF71717A)
            )
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Coming Soon",
                style = MaterialTheme.typography.labelLarge,
                color = Cyan
            )
        }
    }
}
