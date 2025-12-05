package com.aifitnesscoach.app.screens.home

import android.util.Log
import androidx.compose.animation.core.*
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aifitnesscoach.app.ui.theme.*
import com.aifitnesscoach.shared.api.ApiClient
import com.aifitnesscoach.shared.models.Workout
import com.aifitnesscoach.shared.models.UserInsight
import com.aifitnesscoach.shared.models.WeeklyProgress
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

private const val TAG = "HomeScreen"

// Accent colors
private val Teal = Color(0xFF14B8A6)
private val LimeGreen = Color(0xFFD4FF00)
private val Orange = Color(0xFFF59E0B)

// Helper function to get emoji icon for exercise based on name/muscle/body part
private fun getExerciseIcon(name: String, muscleGroup: String?, bodyPart: String?): String {
    val nameLower = name.lowercase()
    val muscleLower = muscleGroup?.lowercase() ?: ""
    val bodyLower = bodyPart?.lowercase() ?: ""

    return when {
        // Cardio exercises
        nameLower.contains("run") || nameLower.contains("sprint") -> "🏃"
        nameLower.contains("jump") || nameLower.contains("burpee") -> "🔥"
        nameLower.contains("cycle") || nameLower.contains("bike") -> "🚴"
        nameLower.contains("row") -> "🚣"
        nameLower.contains("swim") -> "🏊"

        // Upper body
        nameLower.contains("push") || nameLower.contains("press") || nameLower.contains("bench") -> "💪"
        nameLower.contains("pull") || nameLower.contains("chin") -> "🏋️"
        nameLower.contains("curl") -> "💪"
        nameLower.contains("shoulder") || nameLower.contains("delt") -> "🏋️"
        nameLower.contains("tricep") -> "💪"

        // Core
        nameLower.contains("plank") || nameLower.contains("core") || nameLower.contains("ab") -> "🎯"
        nameLower.contains("crunch") || nameLower.contains("sit-up") -> "🎯"

        // Lower body
        nameLower.contains("squat") -> "🦵"
        nameLower.contains("lunge") -> "🦵"
        nameLower.contains("deadlift") || nameLower.contains("hip") -> "🦵"
        nameLower.contains("calf") || nameLower.contains("leg") -> "🦵"

        // Flexibility/stretching
        nameLower.contains("stretch") || nameLower.contains("yoga") -> "🧘"
        nameLower.contains("foam") || nameLower.contains("roll") -> "🧘"

        // By muscle group
        muscleLower.contains("chest") || muscleLower.contains("pec") -> "💪"
        muscleLower.contains("back") || muscleLower.contains("lat") -> "🏋️"
        muscleLower.contains("leg") || muscleLower.contains("quad") || muscleLower.contains("ham") -> "🦵"
        muscleLower.contains("core") || muscleLower.contains("ab") -> "🎯"
        muscleLower.contains("arm") || muscleLower.contains("bicep") -> "💪"
        muscleLower.contains("shoulder") -> "🏋️"

        // By body part
        bodyLower.contains("upper") -> "💪"
        bodyLower.contains("lower") -> "🦵"
        bodyLower.contains("core") -> "🎯"

        // Default
        else -> "🏋️"
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    userId: String,
    userName: String = "User",
    userLevel: String = "Beginner",
    onWorkoutClick: (String) -> Unit,
    onChatClick: () -> Unit,
    onLogout: () -> Unit = {}
) {
    val scope = rememberCoroutineScope()
    var workouts by remember { mutableStateOf<List<Workout>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Dialogs
    var showGenerateDialog by remember { mutableStateOf(false) }
    var showRegenerateDialog by remember { mutableStateOf<Workout?>(null) }
    var showRescheduleDialog by remember { mutableStateOf<Workout?>(null) }
    var showDeleteDialog by remember { mutableStateOf<Workout?>(null) }
    var showWorkoutMenu by remember { mutableStateOf<Workout?>(null) }
    var isGenerating by remember { mutableStateOf(false) }
    var isRegenerating by remember { mutableStateOf(false) }

    // Stat badge dialogs
    var showDoneDialog by remember { mutableStateOf(false) }
    var showLevelDialog by remember { mutableStateOf(false) }
    var showStreakDialog by remember { mutableStateOf(false) }

    // AI Insights state
    var aiInsights by remember { mutableStateOf<List<UserInsight>>(emptyList()) }
    var serverWeeklyProgress by remember { mutableStateOf<WeeklyProgress?>(null) }

    // Refresh workouts function
    val refreshWorkouts: suspend () -> Unit = {
        try {
            val fetchedWorkouts = ApiClient.workoutApi.getWorkouts(userId)
            workouts = fetchedWorkouts.sortedBy { it.scheduledDate }
        } catch (e: Exception) {
            Log.e(TAG, "Error refreshing workouts", e)
        }
    }

    // Fetch workouts from API
    LaunchedEffect(userId) {
        if (userId.isNotEmpty()) {
            isLoading = true
            errorMessage = null
            try {
                Log.d(TAG, "Fetching workouts for user: $userId")
                val fetchedWorkouts = ApiClient.workoutApi.getWorkouts(userId)
                Log.d(TAG, "Fetched ${fetchedWorkouts.size} workouts")
                workouts = fetchedWorkouts.sortedBy { it.scheduledDate }

                // Fetch AI insights and weekly progress in parallel
                try {
                    // Generate insights if needed (this is cached, so fast if already generated)
                    ApiClient.insightsApi.generateInsights(userId)
                    // Fetch insights
                    val insightsResponse = ApiClient.insightsApi.getInsights(userId)
                    aiInsights = insightsResponse.insights
                    serverWeeklyProgress = insightsResponse.weeklyProgress
                    Log.d(TAG, "Fetched ${aiInsights.size} AI insights")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to fetch AI insights (non-critical)", e)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching workouts", e)
                errorMessage = "Failed to load workouts"
            } finally {
                isLoading = false
            }
        }
    }

    // Get next workout (closest upcoming or today's workout)
    val nextWorkout = remember(workouts) {
        val today = LocalDate.now().toString()
        workouts
            .filter { !it.isCompleted && (it.scheduledDate?.take(10) ?: "") >= today }
            .minByOrNull { it.scheduledDate ?: "" }
    }

    // Get upcoming workouts (excluding next workout)
    val upcomingWorkouts = remember(workouts, nextWorkout) {
        val today = LocalDate.now().toString()
        workouts
            .filter { !it.isCompleted && (it.scheduledDate?.take(10) ?: "") >= today && it.id != nextWorkout?.id }
            .sortedBy { it.scheduledDate }
            .take(5)
    }

    // Count completed workouts
    val completedCount = remember(workouts) {
        workouts.count { it.isCompleted }
    }

    // Calculate weekly progress
    val weeklyProgress = remember(workouts) {
        val today = LocalDate.now()
        val startOfWeek = today.minusDays(today.dayOfWeek.value.toLong() - 1)
        val endOfWeek = startOfWeek.plusDays(6)

        val thisWeekWorkouts = workouts.filter { workout ->
            val date = workout.scheduledDate?.take(10)?.let { LocalDate.parse(it) }
            date != null && !date.isBefore(startOfWeek) && !date.isAfter(endOfWeek)
        }
        val completedThisWeek = thisWeekWorkouts.count { it.isCompleted }
        val totalThisWeek = thisWeekWorkouts.size.coerceAtLeast(1)

        Pair(completedThisWeek, totalThisWeek)
    }

    // Calculate streak (consecutive days with completed workouts)
    val streakData = remember(workouts) {
        val completedDates = workouts
            .filter { it.isCompleted }
            .mapNotNull { it.scheduledDate?.take(10)?.let { d -> LocalDate.parse(d) } }
            .distinct()
            .sortedDescending()

        var currentStreak = 0
        var checkDate = LocalDate.now()

        // Check if today or yesterday has a workout (allow for current day)
        if (completedDates.isNotEmpty()) {
            val mostRecent = completedDates.first()
            val daysDiff = ChronoUnit.DAYS.between(mostRecent, checkDate)
            if (daysDiff > 1) {
                // Streak broken
                currentStreak = 0
            } else {
                checkDate = mostRecent
                for (date in completedDates) {
                    if (date == checkDate) {
                        currentStreak++
                        checkDate = checkDate.minusDays(1)
                    } else if (date.isBefore(checkDate)) {
                        break
                    }
                }
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var prevDate: LocalDate? = null
        for (date in completedDates.sortedDescending()) {
            if (prevDate == null || ChronoUnit.DAYS.between(date, prevDate) == 1L) {
                tempStreak++
            } else {
                longestStreak = maxOf(longestStreak, tempStreak)
                tempStreak = 1
            }
            prevDate = date
        }
        longestStreak = maxOf(longestStreak, tempStreak)

        Triple(currentStreak, longestStreak, completedDates.size)
    }

    // Today's goal based on next workout
    val todaysGoal = remember(nextWorkout) {
        nextWorkout?.let { workout ->
            val type = workout.type?.replace("_", " ")?.replaceFirstChar { it.uppercase() } ?: "Workout"
            val difficulty = when (workout.difficulty?.lowercase()) {
                "easy", "beginner" -> "Light"
                "hard", "advanced" -> "Intense"
                else -> "Moderate"
            }
            "$difficulty $type"
        } ?: "Rest & Recovery"
    }

    // Coach tip based on context
    val coachTip = remember(nextWorkout, streakData, completedCount) {
        when {
            streakData.first >= 7 -> "You're on a 🔥 ${streakData.first}-day streak! Keep the momentum going!"
            streakData.first >= 3 -> "Great consistency! You're building a solid habit."
            nextWorkout?.difficulty?.lowercase() == "hard" -> "Today's workout is intense. Make sure you're well hydrated!"
            completedCount == 0 -> "Welcome! Complete your first workout to start your fitness journey."
            nextWorkout?.type?.lowercase()?.contains("cardio") == true -> "Cardio day! Focus on steady breathing and pacing."
            nextWorkout?.type?.lowercase()?.contains("strength") == true -> "Strength day! Focus on proper form over speed."
            else -> "Stay consistent and trust the process. Every workout counts!"
        }
    }

    // Week-over-week comparison for insights
    val weeklyInsight = remember(workouts) {
        val today = LocalDate.now()
        val startOfThisWeek = today.minusDays(today.dayOfWeek.value.toLong() - 1)
        val startOfLastWeek = startOfThisWeek.minusDays(7)
        val endOfLastWeek = startOfThisWeek.minusDays(1)

        // This week's stats
        val thisWeekWorkouts = workouts.filter { workout ->
            val date = workout.scheduledDate?.take(10)?.let { LocalDate.parse(it) }
            date != null && !date.isBefore(startOfThisWeek) && !date.isAfter(today)
        }
        val thisWeekCompleted = thisWeekWorkouts.count { it.isCompleted }
        val thisWeekMinutes = thisWeekWorkouts.filter { it.isCompleted }.sumOf { it.durationMinutes ?: 0 }

        // Last week's stats
        val lastWeekWorkouts = workouts.filter { workout ->
            val date = workout.scheduledDate?.take(10)?.let { LocalDate.parse(it) }
            date != null && !date.isBefore(startOfLastWeek) && !date.isAfter(endOfLastWeek)
        }
        val lastWeekCompleted = lastWeekWorkouts.count { it.isCompleted }
        val lastWeekMinutes = lastWeekWorkouts.filter { it.isCompleted }.sumOf { it.durationMinutes ?: 0 }

        // Calculate percentage change
        val minutesChange = if (lastWeekMinutes > 0) {
            ((thisWeekMinutes - lastWeekMinutes).toFloat() / lastWeekMinutes * 100).toInt()
        } else if (thisWeekMinutes > 0) {
            100 // If no last week data but have this week, show 100% improvement
        } else {
            0
        }

        val workoutChange = thisWeekCompleted - lastWeekCompleted

        // Generate insight message
        val insightMessage = when {
            thisWeekMinutes > lastWeekMinutes && lastWeekMinutes > 0 ->
                "You trained ${minutesChange}% more than last week! 📈"
            thisWeekMinutes < lastWeekMinutes && lastWeekMinutes > 0 ->
                "You trained ${-minutesChange}% less than last week. Let's pick it up! 💪"
            thisWeekCompleted > lastWeekCompleted ->
                "You completed $workoutChange more workout${if (workoutChange > 1) "s" else ""} than last week! 🎯"
            thisWeekCompleted == lastWeekCompleted && thisWeekCompleted > 0 ->
                "Consistent effort! Same as last week. Keep it going! ✨"
            thisWeekMinutes > 0 ->
                "You've logged $thisWeekMinutes minutes of training this week! 🏋️"
            else ->
                "Start your first workout to track your weekly progress! 🚀"
        }

        Triple(insightMessage, thisWeekMinutes, thisWeekCompleted)
    }

    // Generate Workout Dialog
    if (showGenerateDialog) {
        GenerateWorkoutDialog(
            isGenerating = isGenerating,
            onDismiss = { showGenerateDialog = false },
            onGenerate = { workoutType, duration ->
                scope.launch {
                    isGenerating = true
                    try {
                        ApiClient.workoutApi.generateWorkout(
                            com.aifitnesscoach.shared.models.WorkoutGenerateRequest(
                                userId = userId,
                                workoutType = workoutType,
                                duration = duration
                            )
                        )
                        refreshWorkouts()
                        showGenerateDialog = false
                    } catch (e: Exception) {
                        Log.e(TAG, "Error generating workout", e)
                    } finally {
                        isGenerating = false
                    }
                }
            }
        )
    }

    // Regenerate Workout Dialog
    showRegenerateDialog?.let { workout ->
        RegenerateWorkoutDialog(
            workout = workout,
            isRegenerating = isRegenerating,
            onDismiss = { showRegenerateDialog = null },
            onRegenerate = { duration, difficulty, equipment ->
                scope.launch {
                    isRegenerating = true
                    try {
                        // Map difficulty to fitness_level for backend
                        val fitnessLevel = when (difficulty) {
                            "easy" -> "beginner"
                            "medium" -> "intermediate"
                            "hard" -> "advanced"
                            else -> "intermediate"
                        }
                        ApiClient.workoutApi.regenerateWorkout(
                            com.aifitnesscoach.shared.models.RegenerateWorkoutRequest(
                                workoutId = workout.id!!,
                                userId = userId,
                                durationMinutes = duration,
                                fitnessLevel = fitnessLevel,
                                difficulty = difficulty,
                                equipment = equipment.ifEmpty { null }
                            )
                        )
                        refreshWorkouts()
                        showRegenerateDialog = null
                    } catch (e: Exception) {
                        Log.e(TAG, "Error regenerating workout", e)
                    } finally {
                        isRegenerating = false
                    }
                }
            }
        )
    }

    // Reschedule Dialog
    showRescheduleDialog?.let { workout ->
        RescheduleDialog(
            workout = workout,
            onDismiss = { showRescheduleDialog = null },
            onReschedule = { newDate ->
                scope.launch {
                    try {
                        ApiClient.workoutApi.rescheduleWorkout(workout.id!!, newDate)
                        refreshWorkouts()
                        showRescheduleDialog = null
                    } catch (e: Exception) {
                        Log.e(TAG, "Error rescheduling workout", e)
                    }
                }
            }
        )
    }

    // Delete Confirmation Dialog
    showDeleteDialog?.let { workout ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = {
                Text("Delete Workout?", color = TextPrimary, fontWeight = FontWeight.Bold)
            },
            text = {
                Text("Are you sure you want to delete \"${workout.name}\"?", color = TextSecondary)
            },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        try {
                            ApiClient.workoutApi.deleteWorkout(workout.id!!)
                            refreshWorkouts()
                            showDeleteDialog = null
                        } catch (e: Exception) {
                            Log.e(TAG, "Error deleting workout", e)
                        }
                    }
                }) {
                    Text("Delete", color = Color(0xFFEF4444))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = null }) {
                    Text("Cancel", color = Cyan)
                }
            },
            containerColor = Color(0xFF1A1A1A),
            shape = RoundedCornerShape(20.dp)
        )
    }

    // Workout Action Menu
    showWorkoutMenu?.let { workout ->
        WorkoutActionMenu(
            workout = workout,
            onDismiss = { showWorkoutMenu = null },
            onView = {
                showWorkoutMenu = null
                workout.id?.let { onWorkoutClick(it) }
            },
            onReschedule = {
                showWorkoutMenu = null
                showRescheduleDialog = workout
            },
            onDelete = {
                showWorkoutMenu = null
                showDeleteDialog = workout
            }
        )
    }

    // Stat Badge Dialogs
    if (showDoneDialog) {
        val completedWorkouts = workouts.filter { it.isCompleted }
        CompletedWorkoutsDialog(
            completedCount = completedCount,
            recentWorkouts = completedWorkouts.takeLast(5).reversed(),
            onDismiss = { showDoneDialog = false }
        )
    }

    if (showLevelDialog) {
        LevelInfoDialog(
            userLevel = userLevel,
            completedCount = completedCount,
            onDismiss = { showLevelDialog = false }
        )
    }

    if (showStreakDialog) {
        StreakInfoDialog(
            currentStreak = streakData.first,
            longestStreak = streakData.second,
            onDismiss = { showStreakDialog = false }
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
        when {
            isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(color = Cyan, modifier = Modifier.size(48.dp))
                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Loading your workouts...", color = TextSecondary, fontSize = 16.sp)
                    }
                }
            }
            else -> {
                // Track scroll position for sticky button
                val lazyListState = rememberLazyListState()
                val showStickyButton by remember {
                    derivedStateOf {
                        // Show sticky button when scrolled past item index 3 (past the Next Workout card)
                        lazyListState.firstVisibleItemIndex >= 3 && nextWorkout != null
                    }
                }

                Box(modifier = Modifier.fillMaxSize()) {
                    LazyColumn(
                        state = lazyListState,
                        modifier = Modifier
                            .fillMaxSize()
                            .statusBarsPadding()
                            .navigationBarsPadding(),
                        contentPadding = PaddingValues(bottom = 100.dp)
                    ) {
                    // Header with user info
                    item {
                        HeaderSection(
                            userName = userName,
                            userLevel = userLevel,
                            completedCount = completedCount,
                            currentStreak = streakData.first,
                            onProfileClick = onLogout,
                            onDoneClick = { showDoneDialog = true },
                            onLevelClick = { showLevelDialog = true },
                            onStreakClick = { showStreakDialog = true }
                        )
                    }

                    // ─────────────────────────────────────────
                    // TODAY Section
                    // ─────────────────────────────────────────
                    item {
                        SectionHeader(title = "TODAY")
                    }

                    // 1️⃣ Today's Goal (top priority)
                    item {
                        TodaysGoalSection(
                            todaysGoal = todaysGoal,
                            weeklyCompleted = weeklyProgress.first,
                            weeklyTotal = weeklyProgress.second
                        )
                    }

                    // 2️⃣ Next Workout Hero Card (main CTA)
                    item {
                        if (nextWorkout != null) {
                            NextWorkoutHeroCard(
                                workout = nextWorkout,
                                onStartClick = { nextWorkout.id?.let { onWorkoutClick(it) } },
                                onSkipClick = { showDeleteDialog = nextWorkout },
                                onRegenerateClick = { showRegenerateDialog = nextWorkout },
                                onRescheduleClick = { showRescheduleDialog = nextWorkout }
                            )
                        } else {
                            EmptyStateCard(
                                onGenerateClick = { showGenerateDialog = true }
                            )
                        }
                    }

                    // Section divider
                    item {
                        SectionDivider()
                    }

                    // ─────────────────────────────────────────
                    // YOUR WEEK Section
                    // ─────────────────────────────────────────
                    item {
                        SectionHeader(title = "YOUR WEEK")
                    }

                    // 3️⃣ Weekly Progress Section (combined with insight)
                    item {
                        WeeklyProgramProgressBar(
                            weeklyProgress = serverWeeklyProgress,
                            localProgress = weeklyProgress,
                            insightMessage = weeklyInsight.first
                        )
                    }

                    // 4️⃣ Coach Tip (supporting content)
                    item {
                        CoachTipSection(
                            tip = coachTip,
                            onChatClick = onChatClick
                        )
                    }

                    // AI Micro-Insights (optional, dismissable)
                    if (aiInsights.isNotEmpty()) {
                        item {
                            AiMicroInsightsSection(
                                insights = aiInsights,
                                onDismiss = { insightId ->
                                    scope.launch {
                                        try {
                                            ApiClient.insightsApi.dismissInsight(userId, insightId)
                                            aiInsights = aiInsights.filter { it.id != insightId }
                                        } catch (e: Exception) {
                                            Log.e(TAG, "Failed to dismiss insight", e)
                                        }
                                    }
                                }
                            )
                        }
                    }

                    // ─────────────────────────────────────────
                    // UPCOMING Section (limited to 2 + See All)
                    // ─────────────────────────────────────────
                    if (upcomingWorkouts.isNotEmpty()) {
                        item {
                            SectionDivider()
                        }

                        item {
                            var showAllUpcoming by remember { mutableStateOf(false) }
                            val displayWorkouts = if (showAllUpcoming) upcomingWorkouts else upcomingWorkouts.take(2)

                            Column {
                                SectionHeader(
                                    title = "UPCOMING",
                                    subtitle = "${upcomingWorkouts.size} workouts"
                                )

                                displayWorkouts.forEach { workout ->
                                    UpcomingWorkoutCard(
                                        workout = workout,
                                        onClick = { workout.id?.let { onWorkoutClick(it) } },
                                        onLongPress = { showWorkoutMenu = workout }
                                    )
                                }

                                // Show "See All" button if more than 2 workouts
                                if (upcomingWorkouts.size > 2 && !showAllUpcoming) {
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 16.dp)
                                            .clip(RoundedCornerShape(12.dp))
                                            .background(Color.White.copy(alpha = 0.05f))
                                            .clickable { showAllUpcoming = true }
                                            .padding(vertical = 12.dp),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Text(
                                                text = "See ${upcomingWorkouts.size - 2} more workouts",
                                                fontSize = 13.sp,
                                                color = Cyan,
                                                fontWeight = FontWeight.Medium
                                            )
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Icon(
                                                Icons.Default.ExpandMore,
                                                contentDescription = null,
                                                tint = Cyan,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                    // Sticky Start Workout FAB (appears when scrolled past the workout card)
                    // Slides in from the right with fluid spring animation
                    AnimatedVisibility(
                        visible = showStickyButton,
                        enter = slideInHorizontally(
                            initialOffsetX = { it },
                            animationSpec = spring(
                                dampingRatio = Spring.DampingRatioMediumBouncy,
                                stiffness = Spring.StiffnessMedium
                            )
                        ) + fadeIn(
                            animationSpec = tween(300)
                        ) + scaleIn(
                            initialScale = 0.8f,
                            animationSpec = spring(
                                dampingRatio = Spring.DampingRatioMediumBouncy,
                                stiffness = Spring.StiffnessMedium
                            )
                        ),
                        exit = slideOutHorizontally(
                            targetOffsetX = { it },
                            animationSpec = tween(200, easing = FastOutSlowInEasing)
                        ) + fadeOut(
                            animationSpec = tween(150)
                        ) + scaleOut(
                            targetScale = 0.8f,
                            animationSpec = tween(200)
                        ),
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(end = 76.dp, bottom = 16.dp) // Position left of AI Coach FAB
                    ) {
                        ExtendedFloatingActionButton(
                            onClick = { nextWorkout?.id?.let { onWorkoutClick(it) } },
                            containerColor = Cyan,
                            contentColor = Color.White,
                            icon = {
                                Icon(
                                    Icons.Default.PlayArrow,
                                    contentDescription = null,
                                    modifier = Modifier.size(24.dp)
                                )
                            },
                            text = {
                                Text(
                                    "Start",
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 15.sp
                                )
                            }
                        )
                    }
                } // End inner Box

                // Loading overlay for generating
                if (isGenerating) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.7f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            CircularProgressIndicator(color = Cyan, modifier = Modifier.size(48.dp))
                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Generating workout...", color = TextPrimary, fontSize = 16.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HeaderSection(
    userName: String,
    userLevel: String,
    completedCount: Int,
    currentStreak: Int,
    onProfileClick: () -> Unit,
    onDoneClick: () -> Unit,
    onLevelClick: () -> Unit,
    onStreakClick: () -> Unit
) {
    // Streak color based on value
    val streakColor = when {
        currentStreak >= 7 -> Color(0xFFEF4444) // Red - on fire!
        currentStreak >= 3 -> Color(0xFFF59E0B) // Amber - heating up
        currentStreak > 0 -> Color(0xFF10B981) // Green - getting started
        else -> TextMuted
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // User avatar and name
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Cyan.copy(alpha = 0.2f))
                    .clickable(onClick = onProfileClick),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = userName.firstOrNull()?.uppercase() ?: "U",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Cyan
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = "Welcome back,",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
                Text(
                    text = userName,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
            }
        }

        // Stats - now tappable (smaller, more subtle)
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            StatBadge(
                value = completedCount.toString(),
                label = "Done",
                onClick = onDoneClick
            )
            StatBadge(
                value = when (userLevel.lowercase()) {
                    "beginner" -> "Bgn"
                    "intermediate" -> "Int"
                    "advanced" -> "Adv"
                    else -> userLevel.take(3)
                },
                label = "Level",
                onClick = onLevelClick
            )
            // Streak badge with flame indicator
            StreakBadge(
                streak = currentStreak,
                streakColor = streakColor,
                onClick = onStreakClick
            )
        }
    }
}

// Enhanced streak badge with flame icon - made smaller to not compete
@Composable
private fun StreakBadge(
    streak: Int,
    streakColor: Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .widthIn(min = 44.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(streakColor.copy(alpha = 0.08f))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 6.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (streak > 0) {
                Text(
                    text = "🔥",
                    fontSize = 10.sp
                )
                Spacer(modifier = Modifier.width(2.dp))
            }
            Text(
                text = streak.toString(),
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color = streakColor.copy(alpha = 0.8f),  // Slightly muted
                maxLines = 1
            )
        }
        Text(
            text = "Streak",
            fontSize = 8.sp,
            color = if (streak > 0) streakColor.copy(alpha = 0.8f) else TextMuted,
            maxLines = 1
        )
    }
}

@Composable
private fun StatBadge(
    value: String,
    label: String,
    onClick: () -> Unit
) {
    // Made smaller and more subtle to not compete with Today's Goal
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .widthIn(min = 44.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Color.White.copy(alpha = 0.03f))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 6.dp)
    ) {
        Text(
            text = value,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextSecondary,  // Reduced from TextPrimary
            maxLines = 1
        )
        Text(
            text = label,
            fontSize = 8.sp,
            color = TextMuted.copy(alpha = 0.7f),  // More subtle
            maxLines = 1
        )
    }
}

// Today's Goal & Weekly Progress Section
@Composable
private fun TodaysGoalSection(
    todaysGoal: String,
    weeklyCompleted: Int,
    weeklyTotal: Int
) {
    val progress = if (weeklyTotal > 0) weeklyCompleted.toFloat() / weeklyTotal else 0f

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(bottom = 8.dp)
    ) {
        // Today's Goal Card
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(
                    brush = Brush.horizontalGradient(
                        colors = listOf(
                            Cyan.copy(alpha = 0.15f),
                            Color(0xFF10B981).copy(alpha = 0.1f)
                        )
                    )
                )
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Today's Goal",
                        fontSize = 12.sp,
                        color = TextMuted
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = todaysGoal,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Cyan
                    )
                }

                // Weekly progress ring
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(56.dp)
                ) {
                    CircularProgressIndicator(
                        progress = { progress },
                        modifier = Modifier.size(56.dp),
                        strokeWidth = 5.dp,
                        color = Color(0xFF10B981),
                        trackColor = Color.White.copy(alpha = 0.1f)
                    )
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "$weeklyCompleted/$weeklyTotal",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Text(
                            text = "week",
                            fontSize = 8.sp,
                            color = TextMuted
                        )
                    }
                }
            }
        }
    }
}

// AI Coach Tip Section
// Compact collapsible Coach Tip
@Composable
private fun CoachTipSection(
    tip: String,
    onChatClick: () -> Unit
) {
    var isExpanded by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(bottom = 8.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(Color(0xFF1A1A1A))
            .clickable { isExpanded = !isExpanded }
            .padding(10.dp)
    ) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = "🤖", fontSize = 16.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Coach Tip",
                    fontSize = 12.sp,
                    color = Color(0xFFA855F7),
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = null,
                    tint = TextMuted,
                    modifier = Modifier.size(18.dp)
                )
            }

            if (isExpanded) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = tip,
                    fontSize = 13.sp,
                    color = TextSecondary,
                    lineHeight = 18.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color(0xFFA855F7).copy(alpha = 0.1f))
                        .clickable(onClick = onChatClick)
                        .padding(8.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Chat,
                        contentDescription = null,
                        tint = Color(0xFFA855F7),
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Chat with Coach",
                        fontSize = 12.sp,
                        color = Color(0xFFA855F7),
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

@Composable
@OptIn(ExperimentalLayoutApi::class)
private fun NextWorkoutHeroCard(
    workout: Workout,
    onStartClick: () -> Unit,
    onSkipClick: () -> Unit,
    onRegenerateClick: () -> Unit,
    onRescheduleClick: () -> Unit
) {
    val exercises = workout.getExercises()

    // Extract unique equipment from exercises
    val equipmentList = exercises
        .mapNotNull { it.equipment }
        .filter { it.isNotBlank() && it.lowercase() != "body weight" && it.lowercase() != "bodyweight" }
        .distinct()
        .take(4)

    // Difficulty color mapping
    val difficultyColor = when (workout.difficulty?.lowercase()) {
        "easy", "beginner" -> Color(0xFF10B981) // Green
        "medium", "intermediate" -> Color(0xFFF59E0B) // Amber
        "hard", "advanced" -> Color(0xFFEF4444) // Red
        else -> Color(0xFF6B7280) // Gray
    }

    val difficultyLabel = when (workout.difficulty?.lowercase()) {
        "easy", "beginner" -> "Easy"
        "medium", "intermediate" -> "Medium"
        "hard", "advanced" -> "Hard"
        else -> workout.difficulty?.replaceFirstChar { it.uppercase() } ?: "Medium"
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(24.dp))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF1A1A1A),
                        Color(0xFF0D0D0D)
                    )
                )
            )
            .border(
                width = 1.dp,
                color = Cyan.copy(alpha = 0.3f),
                shape = RoundedCornerShape(24.dp)
            )
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            // Top row: Label + Difficulty badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(LimeGreen)
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "NEXT WORKOUT",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }

                // Difficulty badge
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(difficultyColor.copy(alpha = 0.15f))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(difficultyColor)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = difficultyLabel,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = difficultyColor
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Workout title
            Text(
                text = workout.name,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Workout type/focus
            workout.type?.let { type ->
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = type.replace("_", " ").replaceFirstChar { it.uppercase() },
                    fontSize = 14.sp,
                    color = Cyan,
                    fontWeight = FontWeight.Medium
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Stats row: Duration, exercises, estimated calories
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                // Duration
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Schedule,
                        contentDescription = null,
                        tint = TextMuted,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${workout.durationMinutes ?: 45} min",
                        fontSize = 13.sp,
                        color = TextSecondary
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Exercises count
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.FitnessCenter,
                        contentDescription = null,
                        tint = TextMuted,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${exercises.size} exercises",
                        fontSize = 13.sp,
                        color = TextSecondary
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Estimated calories (duration * 6 cal/min for strength training)
                val estimatedCalories = (workout.durationMinutes ?: 45) * 6
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.LocalFireDepartment,
                        contentDescription = null,
                        tint = Color(0xFFF59E0B),
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "~$estimatedCalories cal",
                        fontSize = 13.sp,
                        color = TextSecondary
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // START WORKOUT CTA - Moved higher for better visibility
            Button(
                onClick = onStartClick,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Cyan,
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(
                    Icons.Default.PlayArrow,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Start Workout",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            // Equipment inline text (show max 2 + more)
            if (equipmentList.isNotEmpty() || exercises.any { it.equipment?.lowercase() in listOf("body weight", "bodyweight") }) {
                Spacer(modifier = Modifier.height(8.dp))
                val allEquipment = equipmentList.toMutableList()
                if (exercises.any { it.equipment?.lowercase() in listOf("body weight", "bodyweight") }) {
                    allEquipment.add("Bodyweight")
                }
                val displayEquipment = if (allEquipment.size > 2) {
                    "${allEquipment.take(2).joinToString(" • ")} +${allEquipment.size - 2} more"
                } else {
                    allEquipment.joinToString(" • ")
                }
                Text(
                    text = "🏋️ $displayEquipment",
                    fontSize = 12.sp,
                    color = TextMuted
                )
            }

            // Collapsible exercise preview section
            var isExercisesExpanded by remember { mutableStateOf(false) }

            if (exercises.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White.copy(alpha = 0.03f))
                        .clickable { isExercisesExpanded = !isExercisesExpanded }
                        .padding(12.dp)
                ) {
                    Column {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = "Today's exercises (${exercises.size})",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                color = TextMuted,
                                modifier = Modifier.weight(1f)
                            )
                            Icon(
                                if (isExercisesExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                                contentDescription = if (isExercisesExpanded) "Collapse" else "Expand",
                                tint = TextMuted,
                                modifier = Modifier.size(20.dp)
                            )
                        }

                        // Only show exercises when expanded
                        if (isExercisesExpanded) {
                            Spacer(modifier = Modifier.height(8.dp))
                            exercises.take(6).forEach { exercise ->
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(vertical = 3.dp)
                                ) {
                                    val exerciseIcon = getExerciseIcon(exercise.name, exercise.muscleGroup, exercise.bodyPart)
                                    Text(text = exerciseIcon, fontSize = 14.sp)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = exercise.name,
                                        fontSize = 13.sp,
                                        color = TextPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        modifier = Modifier.weight(1f)
                                    )
                                    val detail = when {
                                        exercise.sets != null && exercise.reps != null -> "${exercise.sets}×${exercise.reps}"
                                        exercise.durationSeconds != null -> "${exercise.durationSeconds}s"
                                        else -> ""
                                    }
                                    if (detail.isNotEmpty()) {
                                        Text(
                                            text = detail,
                                            fontSize = 12.sp,
                                            color = Cyan,
                                            fontWeight = FontWeight.Medium
                                        )
                                    }
                                }
                            }
                            if (exercises.size > 6) {
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "+${exercises.size - 6} more",
                                    fontSize = 11.sp,
                                    color = TextMuted
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Compact quick action buttons row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                CompactActionButton(icon = Icons.Default.SkipNext, label = "Skip", onClick = onSkipClick)
                CompactActionButton(icon = Icons.Default.SwapHoriz, label = "Swap", onClick = onRegenerateClick)
                CompactActionButton(icon = Icons.Default.Schedule, label = "Reschedule", onClick = onRescheduleClick)
            }
        }
    }
}

// More compact quick action button
@Composable
private fun CompactActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .background(Color.White.copy(alpha = 0.05f))
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Icon(
            icon,
            contentDescription = label,
            tint = TextMuted,
            modifier = Modifier.size(16.dp)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = label,
            fontSize = 11.sp,
            color = TextSecondary
        )
    }
}

@Composable
private fun QuickActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = TextPrimary,
                modifier = Modifier.size(24.dp)
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label,
            fontSize = 11.sp,
            color = TextSecondary
        )
    }
}

@Composable
private fun EmptyStateCard(onGenerateClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(24.dp))
            .background(Color.White.copy(alpha = 0.05f))
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    colors = listOf(Cyan.copy(alpha = 0.3f), Color.Transparent)
                ),
                shape = RoundedCornerShape(24.dp)
            )
            .padding(32.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                Icons.Default.FitnessCenter,
                contentDescription = null,
                tint = Cyan,
                modifier = Modifier.size(64.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "No upcoming workouts",
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Generate a personalized workout to get started",
                fontSize = 14.sp,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(
                onClick = onGenerateClick,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Cyan,
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Generate Workout", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class, ExperimentalLayoutApi::class)
@Composable
private fun UpcomingWorkoutCard(
    workout: Workout,
    onClick: () -> Unit,
    onLongPress: () -> Unit
) {
    val exercises = workout.getExercises()
    val scheduledDate = workout.scheduledDate?.take(10)?.let { LocalDate.parse(it) }
    val daysUntil = scheduledDate?.let { ChronoUnit.DAYS.between(LocalDate.now(), it).toInt() }

    // Expandable preview state
    var isExpanded by remember { mutableStateOf(false) }

    // Difficulty color
    val difficultyColor = when (workout.difficulty?.lowercase()) {
        "easy", "beginner" -> Color(0xFF10B981) // Green
        "medium", "intermediate" -> Color(0xFFF59E0B) // Amber
        "hard", "advanced" -> Color(0xFFEF4444) // Red
        else -> Color(0xFF6B7280) // Gray
    }

    val difficultyLabel = when (workout.difficulty?.lowercase()) {
        "easy", "beginner" -> "Easy"
        "medium", "intermediate" -> "Medium"
        "hard", "advanced" -> "Hard"
        else -> null
    }

    // Get primary muscle groups from exercises
    val muscleGroups = exercises
        .mapNotNull { it.muscleGroup ?: it.bodyPart }
        .filter { it.isNotBlank() }
        .distinct()
        .take(2)

    // Get equipment summary
    val equipmentList = exercises
        .mapNotNull { it.equipment }
        .filter { it.isNotBlank() && it.lowercase() !in listOf("body weight", "bodyweight") }
        .distinct()
        .take(2)

    // Get workout type icon
    val typeIcon = when (workout.type?.lowercase()) {
        "strength" -> "💪"
        "cardio" -> "🏃"
        "hiit" -> "🔥"
        "flexibility", "stretching" -> "🧘"
        "full_body" -> "🏋️"
        else -> "🏋️"
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.05f))
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongPress
            )
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            // Day indicator with type icon
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.width(50.dp)
            ) {
                Text(
                    text = scheduledDate?.dayOfWeek?.name?.take(3) ?: "",
                    fontSize = 10.sp,
                    color = TextMuted
                )
                Text(
                    text = scheduledDate?.dayOfMonth?.toString() ?: "",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Cyan
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = typeIcon,
                    fontSize = 16.sp
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Workout info - expanded
            Column(modifier = Modifier.weight(1f)) {
                // Title row with difficulty badge
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = workout.name,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )
                    // Difficulty indicator dot
                    if (difficultyLabel != null) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(difficultyColor)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Stats row with calories
                val estimatedCalories = (workout.durationMinutes ?: 45) * 6
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "${workout.durationMinutes ?: 45}min",
                        fontSize = 11.sp,
                        color = TextSecondary
                    )
                    Text(
                        text = " • ",
                        fontSize = 11.sp,
                        color = TextMuted
                    )
                    Text(
                        text = "${exercises.size} ex",
                        fontSize = 11.sp,
                        color = TextSecondary
                    )
                    Text(
                        text = " • ",
                        fontSize = 11.sp,
                        color = TextMuted
                    )
                    Text(
                        text = "~${estimatedCalories} cal",
                        fontSize = 11.sp,
                        color = Orange
                    )
                    if (difficultyLabel != null) {
                        Text(
                            text = " • ",
                            fontSize = 11.sp,
                            color = TextMuted
                        )
                        Text(
                            text = difficultyLabel,
                            fontSize = 11.sp,
                            color = difficultyColor,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                // Muscle groups / focus - simplified with icons
                if (muscleGroups.isNotEmpty() || workout.type != null || equipmentList.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Workout type with icon (compact)
                        workout.type?.let { type ->
                            Text(
                                text = "${typeIcon} ${type.replace("_", " ").take(8)}",
                                fontSize = 9.sp,
                                color = Cyan,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        // Muscle groups (1-word labels)
                        muscleGroups.take(2).forEach { muscle ->
                            val shortLabel = muscle.split(" ").first().take(6)
                            Text(
                                text = "• $shortLabel",
                                fontSize = 9.sp,
                                color = TextMuted
                            )
                        }
                        // Equipment (smaller, inline, secondary)
                        if (equipmentList.isNotEmpty()) {
                            Text(
                                text = "🏋️ ${equipmentList.first().take(8)}",
                                fontSize = 8.sp,
                                color = TextMuted.copy(alpha = 0.7f)
                            )
                        }
                    }
                }

                // Collapsible exercise preview - improved truncation
                if (exercises.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(6.dp))

                    // Preview row with expand toggle
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { isExpanded = !isExpanded },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        // Better truncation: "Exercise 1, Exercise 2 +4 more"
                        val previewText = if (!isExpanded) {
                            val firstTwo = exercises.take(2).map { it.name.take(15) }
                            val remaining = exercises.size - 2
                            if (remaining > 0) {
                                "${firstTwo.joinToString(", ")} +$remaining more"
                            } else {
                                firstTwo.joinToString(", ")
                            }
                        } else {
                            "${exercises.size} exercises"
                        }
                        Text(
                            text = previewText,
                            fontSize = 10.sp,
                            color = TextMuted,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f)
                        )
                        Icon(
                            if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                            contentDescription = if (isExpanded) "Collapse" else "Expand",
                            tint = TextMuted,
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    // Expanded exercise list
                    if (isExpanded) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.03f))
                                .padding(8.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            exercises.forEachIndexed { index, exercise ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    // Exercise number
                                    Text(
                                        text = "${index + 1}",
                                        fontSize = 10.sp,
                                        color = Cyan,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.width(16.dp)
                                    )
                                    // Exercise name
                                    Text(
                                        text = exercise.name,
                                        fontSize = 11.sp,
                                        color = TextPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        modifier = Modifier.weight(1f)
                                    )
                                    // Sets/reps or duration
                                    val detail = when {
                                        exercise.sets != null && exercise.reps != null ->
                                            "${exercise.sets}×${exercise.reps}"
                                        exercise.durationSeconds != null ->
                                            "${exercise.durationSeconds}s"
                                        else -> ""
                                    }
                                    if (detail.isNotEmpty()) {
                                        Text(
                                            text = detail,
                                            fontSize = 10.sp,
                                            color = TextMuted
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Play button
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Cyan.copy(alpha = 0.2f))
                    .clickable(onClick = onClick),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.PlayArrow,
                    contentDescription = "Start workout",
                    tint = Cyan,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

// Generate Workout Dialog
@Composable
private fun GenerateWorkoutDialog(
    isGenerating: Boolean,
    onDismiss: () -> Unit,
    onGenerate: (String, Int) -> Unit
) {
    var selectedType by remember { mutableStateOf("strength") }
    var selectedDuration by remember { mutableStateOf(45) }

    val workoutTypes = listOf("strength", "cardio", "hiit", "flexibility", "full_body")
    val durations = listOf(20, 30, 45, 60, 90)

    AlertDialog(
        onDismissRequest = { if (!isGenerating) onDismiss() },
        title = {
            Text("Generate Workout", color = TextPrimary, fontWeight = FontWeight.Bold)
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("Workout Type", color = TextSecondary, fontSize = 14.sp)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    workoutTypes.forEach { type ->
                        FilterChip(
                            selected = selectedType == type,
                            onClick = { selectedType = type },
                            label = {
                                Text(
                                    type.replace("_", " ").replaceFirstChar { it.uppercase() },
                                    fontSize = 12.sp
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = Cyan,
                                selectedLabelColor = Color.White,
                                containerColor = Color.White.copy(alpha = 0.1f),
                                labelColor = TextSecondary
                            )
                        )
                    }
                }

                Text("Duration", color = TextSecondary, fontSize = 14.sp)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    durations.forEach { duration ->
                        FilterChip(
                            selected = selectedDuration == duration,
                            onClick = { selectedDuration = duration },
                            label = { Text("${duration}min", fontSize = 12.sp) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = Cyan,
                                selectedLabelColor = Color.White,
                                containerColor = Color.White.copy(alpha = 0.1f),
                                labelColor = TextSecondary
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onGenerate(selectedType, selectedDuration) },
                enabled = !isGenerating,
                colors = ButtonDefaults.buttonColors(containerColor = Cyan)
            ) {
                if (isGenerating) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Generating...")
                } else {
                    Text("Generate")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isGenerating) {
                Text("Cancel", color = TextSecondary)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// Reschedule Dialog
@Composable
private fun RescheduleDialog(
    workout: Workout,
    onDismiss: () -> Unit,
    onReschedule: (String) -> Unit
) {
    val today = LocalDate.now()
    val weekDates = (0..13).map { today.plusDays(it.toLong()) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Reschedule Workout", color = TextPrimary, fontWeight = FontWeight.Bold)
        },
        text = {
            Column {
                Text(
                    "Move \"${workout.name}\" to:",
                    color = TextSecondary,
                    fontSize = 14.sp
                )
                Spacer(modifier = Modifier.height(12.dp))

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    weekDates.chunked(7).forEach { week ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            week.forEach { date ->
                                val isSelected = selectedDate == date
                                val isToday = date == LocalDate.now()

                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .aspectRatio(1f)
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(
                                            when {
                                                isSelected -> Cyan
                                                isToday -> Cyan.copy(alpha = 0.2f)
                                                else -> Color.White.copy(alpha = 0.05f)
                                            }
                                        )
                                        .clickable { selectedDate = date },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(
                                            text = date.dayOfWeek.name.take(1),
                                            fontSize = 10.sp,
                                            color = if (isSelected) Color.White else TextMuted
                                        )
                                        Text(
                                            text = date.dayOfMonth.toString(),
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (isSelected) Color.White else TextPrimary
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    selectedDate?.let { date ->
                        onReschedule(date.format(DateTimeFormatter.ISO_DATE))
                    }
                },
                enabled = selectedDate != null,
                colors = ButtonDefaults.buttonColors(containerColor = Cyan)
            ) {
                Text("Reschedule")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = TextSecondary)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// Workout Action Menu
@Composable
private fun WorkoutActionMenu(
    workout: Workout,
    onDismiss: () -> Unit,
    onView: () -> Unit,
    onReschedule: () -> Unit,
    onDelete: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(workout.name, color = TextPrimary, fontWeight = FontWeight.Bold, maxLines = 1)
        },
        text = {
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .clickable { onView() }
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Visibility, contentDescription = null, tint = Cyan, modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Text("View Details", color = TextPrimary, fontSize = 16.sp)
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .clickable { onReschedule() }
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = Orange, modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Text("Reschedule", color = TextPrimary, fontSize = 16.sp)
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .clickable { onDelete() }
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Delete, contentDescription = null, tint = Color(0xFFEF4444), modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Text("Delete", color = Color(0xFFEF4444), fontSize = 16.sp)
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = TextSecondary)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// Regenerate Workout Dialog - Comprehensive version matching web UI
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun RegenerateWorkoutDialog(
    workout: Workout,
    isRegenerating: Boolean,
    onDismiss: () -> Unit,
    onRegenerate: (Int, String, List<String>) -> Unit
) {
    // State
    var selectedDuration by remember { mutableStateOf(workout.durationMinutes ?: 45) }
    var selectedDifficulty by remember { mutableStateOf(workout.difficulty ?: "medium") }
    var selectedEquipment by remember { mutableStateOf<Set<String>>(setOf()) }
    var customEquipment by remember { mutableStateOf("") }

    // Equipment presets matching web UI
    val equipmentPresets = listOf(
        "barbell", "dumbbell", "kettlebell", "cable machine",
        "resistance bands", "pull-up bar", "bench", "bodyweight",
        "smith machine", "leg press", "lat pulldown", "rowing machine"
    )

    // Difficulty options
    val difficultyOptions = listOf(
        Triple("easy", "Easy", Color(0xFF10B981)),
        Triple("medium", "Medium", Color(0xFFF59E0B)),
        Triple("hard", "Hard", Color(0xFFEF4444))
    )

    AlertDialog(
        onDismissRequest = { if (!isRegenerating) onDismiss() },
        title = {
            Column {
                Text(
                    "Regenerate Workout",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    workout.name,
                    color = TextSecondary,
                    fontSize = 14.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        },
        text = {
            Column(
                modifier = Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                // Duration Section
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Duration", color = TextSecondary, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        Text(
                            "$selectedDuration min",
                            color = Cyan,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Slider(
                        value = selectedDuration.toFloat(),
                        onValueChange = { selectedDuration = it.toInt() },
                        valueRange = 15f..120f,
                        steps = 20,
                        colors = SliderDefaults.colors(
                            thumbColor = Cyan,
                            activeTrackColor = Cyan,
                            inactiveTrackColor = Color.White.copy(alpha = 0.1f)
                        )
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("15 min", color = TextMuted, fontSize = 12.sp)
                        Text("120 min", color = TextMuted, fontSize = 12.sp)
                    }
                }

                // Difficulty Section
                Column {
                    Text("Difficulty", color = TextSecondary, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        difficultyOptions.forEach { (value, label, color) ->
                            val isSelected = selectedDifficulty == value
                            Button(
                                onClick = { selectedDifficulty = value },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (isSelected) color else Color.White.copy(alpha = 0.1f),
                                    contentColor = if (isSelected) Color.White else TextSecondary
                                ),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(vertical = 12.dp)
                            ) {
                                Text(label, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                            }
                        }
                    }
                }

                // Equipment Section
                Column {
                    Text("Equipment", color = TextSecondary, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                    Spacer(modifier = Modifier.height(8.dp))
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        equipmentPresets.forEach { equipment ->
                            val isSelected = equipment in selectedEquipment
                            FilterChip(
                                selected = isSelected,
                                onClick = {
                                    selectedEquipment = if (isSelected) {
                                        selectedEquipment - equipment
                                    } else {
                                        selectedEquipment + equipment
                                    }
                                },
                                label = {
                                    Text(
                                        equipment.replaceFirstChar { it.uppercase() },
                                        fontSize = 12.sp
                                    )
                                },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = Cyan,
                                    selectedLabelColor = Color.White,
                                    containerColor = Color.White.copy(alpha = 0.1f),
                                    labelColor = TextSecondary
                                )
                            )
                        }
                    }

                    // Custom equipment input
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = customEquipment,
                        onValueChange = { customEquipment = it },
                        placeholder = { Text("Add other equipment...", color = TextMuted) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary,
                            focusedBorderColor = Cyan,
                            unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                            cursorColor = Cyan
                        ),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true,
                        trailingIcon = {
                            if (customEquipment.isNotBlank()) {
                                IconButton(onClick = {
                                    selectedEquipment = selectedEquipment + customEquipment.lowercase().trim()
                                    customEquipment = ""
                                }) {
                                    Icon(Icons.Default.Add, contentDescription = "Add", tint = Cyan)
                                }
                            }
                        }
                    )
                }

                // Helper text
                Text(
                    "This will generate a new workout with these settings",
                    color = TextMuted,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onRegenerate(
                        selectedDuration,
                        selectedDifficulty,
                        selectedEquipment.toList()
                    )
                },
                enabled = !isRegenerating,
                colors = ButtonDefaults.buttonColors(containerColor = Cyan),
                shape = RoundedCornerShape(12.dp)
            ) {
                if (isRegenerating) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Regenerating...")
                } else {
                    Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Regenerate")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isRegenerating) {
                Text("Cancel", color = TextSecondary)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// Completed Workouts Dialog - shows when tapping "Done" stat badge
@Composable
private fun CompletedWorkoutsDialog(
    completedCount: Int,
    recentWorkouts: List<Workout>,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = Color(0xFF10B981),
                    modifier = Modifier.size(28.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        "Completed Workouts",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                    Text(
                        "$completedCount total",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                }
            }
        },
        text = {
            Column {
                if (recentWorkouts.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 24.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                Icons.Default.FitnessCenter,
                                contentDescription = null,
                                tint = TextMuted,
                                modifier = Modifier.size(48.dp)
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                "No completed workouts yet",
                                color = TextMuted,
                                fontSize = 14.sp
                            )
                            Text(
                                "Start a workout to track your progress!",
                                color = TextMuted,
                                fontSize = 12.sp
                            )
                        }
                    }
                } else {
                    Text(
                        "Recent completions:",
                        color = TextSecondary,
                        fontSize = 13.sp
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    recentWorkouts.forEach { workout ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF10B981))
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    workout.name,
                                    color = TextPrimary,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Medium,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    "${workout.durationMinutes ?: 45} min • ${workout.type?.replace("_", " ")?.replaceFirstChar { it.uppercase() } ?: "Workout"}",
                                    color = TextMuted,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close", color = Cyan)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// Level Info Dialog - shows when tapping "Level" stat badge
@Composable
private fun LevelInfoDialog(
    userLevel: String,
    completedCount: Int,
    onDismiss: () -> Unit
) {
    val levelColor = when (userLevel.lowercase()) {
        "beginner" -> Color(0xFF10B981) // Green
        "intermediate" -> Color(0xFFF59E0B) // Amber
        "advanced" -> Color(0xFFEF4444) // Red
        else -> Cyan
    }

    val levelDescription = when (userLevel.lowercase()) {
        "beginner" -> "You're just getting started! Focus on learning proper form and building consistency."
        "intermediate" -> "You've got the basics down. Time to push harder and increase intensity!"
        "advanced" -> "You're crushing it! Keep challenging yourself with complex movements."
        else -> "Keep training to level up!"
    }

    val nextLevelWorkouts = when (userLevel.lowercase()) {
        "beginner" -> 20 - completedCount
        "intermediate" -> 50 - completedCount
        else -> 0
    }

    val nextLevel = when (userLevel.lowercase()) {
        "beginner" -> "Intermediate"
        "intermediate" -> "Advanced"
        else -> null
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(levelColor.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.EmojiEvents,
                        contentDescription = null,
                        tint = levelColor,
                        modifier = Modifier.size(24.dp)
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        userLevel.replaceFirstChar { it.uppercase() },
                        color = levelColor,
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp
                    )
                    Text(
                        "Current Level",
                        color = TextSecondary,
                        fontSize = 13.sp
                    )
                }
            }
        },
        text = {
            Column {
                Text(
                    levelDescription,
                    color = TextSecondary,
                    fontSize = 14.sp,
                    lineHeight = 20.sp
                )

                if (nextLevel != null && nextLevelWorkouts > 0) {
                    Spacer(modifier = Modifier.height(20.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color.White.copy(alpha = 0.05f))
                            .padding(16.dp)
                    ) {
                        Column {
                            Text(
                                "Next: $nextLevel",
                                color = TextPrimary,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            LinearProgressIndicator(
                                progress = { 1f - (nextLevelWorkouts.toFloat() / 20f) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(8.dp)
                                    .clip(RoundedCornerShape(4.dp)),
                                color = levelColor,
                                trackColor = Color.White.copy(alpha = 0.1f)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                "$nextLevelWorkouts more workouts to go",
                                color = TextMuted,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close", color = Cyan)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// Streak Info Dialog - shows when tapping "Streak" stat badge
@Composable
private fun StreakInfoDialog(
    currentStreak: Int,
    longestStreak: Int,
    onDismiss: () -> Unit
) {
    val streakColor = when {
        currentStreak >= 7 -> Color(0xFFEF4444) // Red - on fire!
        currentStreak >= 3 -> Color(0xFFF59E0B) // Amber - heating up
        currentStreak > 0 -> Color(0xFF10B981) // Green - getting started
        else -> TextMuted
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(streakColor.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.LocalFireDepartment,
                        contentDescription = null,
                        tint = streakColor,
                        modifier = Modifier.size(24.dp)
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        "$currentStreak Day Streak",
                        color = streakColor,
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp
                    )
                    Text(
                        if (currentStreak > 0) "Keep it going!" else "Start your streak today!",
                        color = TextSecondary,
                        fontSize = 13.sp
                    )
                }
            }
        },
        text = {
            Column {
                // Streak explanation
                Text(
                    if (currentStreak > 0)
                        "You've worked out $currentStreak days in a row. Consistency is key to reaching your goals!"
                    else
                        "Complete a workout today to start your streak. Building a habit is the first step to success!",
                    color = TextSecondary,
                    fontSize = 14.sp,
                    lineHeight = 20.sp
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Stats row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            "$currentStreak",
                            color = streakColor,
                            fontWeight = FontWeight.Bold,
                            fontSize = 24.sp
                        )
                        Text(
                            "Current",
                            color = TextMuted,
                            fontSize = 12.sp
                        )
                    }
                    Box(
                        modifier = Modifier
                            .width(1.dp)
                            .height(40.dp)
                            .background(Color.White.copy(alpha = 0.1f))
                    )
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            "$longestStreak",
                            color = TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 24.sp
                        )
                        Text(
                            "Best",
                            color = TextMuted,
                            fontSize = 12.sp
                        )
                    }
                }

                // Motivational message based on streak
                if (currentStreak > 0) {
                    Spacer(modifier = Modifier.height(20.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(streakColor.copy(alpha = 0.1f))
                            .padding(12.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.TipsAndUpdates,
                                contentDescription = null,
                                tint = streakColor,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                when {
                                    currentStreak >= 7 -> "You're on fire! Keep the momentum!"
                                    currentStreak >= 3 -> "3+ days strong! You're building a habit."
                                    else -> "Great start! Aim for 3 days in a row."
                                },
                                color = streakColor,
                                fontSize = 13.sp
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close", color = Cyan)
            }
        },
        containerColor = Color(0xFF1A1A1A),
        shape = RoundedCornerShape(20.dp)
    )
}

// AI Micro-Insights Section - Horizontally scrollable insight cards
@Composable
private fun AiMicroInsightsSection(
    insights: List<UserInsight>,
    onDismiss: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(bottom = 12.dp)
    ) {
        // Section header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "🤖",
                    fontSize = 16.sp
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "AI Insights",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFFA855F7)
                )
            }
            Text(
                text = "${insights.size} tips",
                fontSize = 11.sp,
                color = TextMuted
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Horizontal scrollable cards
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(insights) { insight ->
                AiInsightCard(
                    insight = insight,
                    onDismiss = { insight.id?.let { onDismiss(it) } }
                )
            }
        }
    }
}

@Composable
private fun AiInsightCard(
    insight: UserInsight,
    onDismiss: () -> Unit
) {
    // Color based on insight type
    val accentColor = when (insight.insightType) {
        "performance" -> Color(0xFF3B82F6)  // Blue
        "consistency" -> Color(0xFFF59E0B)  // Amber
        "motivation" -> Color(0xFF10B981)   // Green
        "tip" -> Color(0xFFA855F7)          // Purple
        "milestone" -> Color(0xFFEF4444)    // Red
        else -> Cyan
    }

    Box(
        modifier = Modifier
            .width(260.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(accentColor.copy(alpha = 0.1f))
            .border(
                width = 1.dp,
                color = accentColor.copy(alpha = 0.3f),
                shape = RoundedCornerShape(12.dp)
            )
            .padding(12.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = insight.emoji ?: "💡",
                        fontSize = 18.sp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = insight.insightType.replaceFirstChar { it.uppercase() },
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = accentColor
                    )
                }
                // Dismiss button
                Icon(
                    Icons.Default.Close,
                    contentDescription = "Dismiss",
                    tint = TextMuted,
                    modifier = Modifier
                        .size(16.dp)
                        .clickable(onClick = onDismiss)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = insight.message,
                fontSize = 13.sp,
                color = TextPrimary,
                lineHeight = 18.sp,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// Section Header composable for layout organization
@Composable
private fun SectionHeader(
    title: String,
    subtitle: String? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(top = 16.dp, bottom = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = TextMuted,
            letterSpacing = 1.5.sp
        )
        subtitle?.let {
            Text(
                text = it,
                fontSize = 11.sp,
                color = TextMuted
            )
        }
    }
}

// Subtle divider between sections
@Composable
private fun SectionDivider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(vertical = 16.dp)
            .height(1.dp)
            .background(Color.White.copy(alpha = 0.05f))
    )
}

// Weekly Program Progress Bar - Enhanced with coach insight
@Composable
private fun WeeklyProgramProgressBar(
    weeklyProgress: WeeklyProgress?,
    localProgress: Pair<Int, Int>,
    insightMessage: String? = null
) {
    // Use server progress if available, otherwise fall back to local calculation
    val completed = weeklyProgress?.completedWorkouts ?: localProgress.first
    val target = weeklyProgress?.targetWorkouts ?: localProgress.second
    val planned = weeklyProgress?.plannedWorkouts ?: localProgress.second

    val progressPercent = if (target > 0) (completed.toFloat() / target).coerceIn(0f, 1f) else 0f
    val isOnTrack = completed >= (target * LocalDate.now().dayOfWeek.value / 7f)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(bottom = 16.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color(0xFF1A1A1A))
            .padding(12.dp)
    ) {
        Column {
            // Header row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "📅",
                        fontSize = 16.sp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Weekly Program",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )
                }
                // Status badge
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(
                            if (progressPercent >= 1f) Color(0xFF10B981).copy(alpha = 0.2f)
                            else if (isOnTrack) Cyan.copy(alpha = 0.2f)
                            else Orange.copy(alpha = 0.2f)
                        )
                        .padding(horizontal = 8.dp, vertical = 3.dp)
                ) {
                    Text(
                        text = when {
                            progressPercent >= 1f -> "Complete!"
                            isOnTrack -> "On Track"
                            else -> "Catch Up"
                        },
                        fontSize = 10.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = when {
                            progressPercent >= 1f -> Color(0xFF10B981)
                            isOnTrack -> Cyan
                            else -> Orange
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Progress bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.White.copy(alpha = 0.1f))
            ) {
                // Animated progress
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(progressPercent)
                        .clip(RoundedCornerShape(6.dp))
                        .background(
                            brush = Brush.horizontalGradient(
                                colors = listOf(Cyan, Color(0xFF10B981))
                            )
                        )
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Stats row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "$completed of $target workouts",
                    fontSize = 12.sp,
                    color = TextSecondary
                )
                Text(
                    text = "${(progressPercent * 100).toInt()}%",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Cyan
                )
            }

            // Day indicators (Mon-Sun)
            Spacer(modifier = Modifier.height(10.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                val today = LocalDate.now().dayOfWeek.value
                listOf("M", "T", "W", "T", "F", "S", "S").forEachIndexed { index, day ->
                    val dayNum = index + 1
                    val isPast = dayNum < today
                    val isToday = dayNum == today

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .clip(CircleShape)
                                .background(
                                    when {
                                        isToday -> Cyan.copy(alpha = 0.3f)
                                        isPast -> Color.White.copy(alpha = 0.05f)
                                        else -> Color.Transparent
                                    }
                                )
                                .border(
                                    width = if (isToday) 2.dp else 0.dp,
                                    color = if (isToday) Cyan else Color.Transparent,
                                    shape = CircleShape
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = day,
                                fontSize = 10.sp,
                                fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal,
                                color = when {
                                    isToday -> Cyan
                                    isPast -> TextMuted
                                    else -> TextSecondary
                                }
                            )
                        }
                    }
                }
            }

            // Calories and duration (if available from server)
            if (weeklyProgress != null && (weeklyProgress.totalDurationMinutes > 0 || weeklyProgress.totalCaloriesBurned > 0)) {
                Spacer(modifier = Modifier.height(10.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    if (weeklyProgress.totalDurationMinutes > 0) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "${weeklyProgress.totalDurationMinutes}",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = TextPrimary
                            )
                            Text(
                                text = "min trained",
                                fontSize = 10.sp,
                                color = TextMuted
                            )
                        }
                    }
                    if (weeklyProgress.totalCaloriesBurned > 0) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "${weeklyProgress.totalCaloriesBurned}",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Orange
                            )
                            Text(
                                text = "cal burned",
                                fontSize = 10.sp,
                                color = TextMuted
                            )
                        }
                    }
                }
            }

            // Coach insight message (merged from WeeklyInsightCard)
            insightMessage?.let { message ->
                Spacer(modifier = Modifier.height(12.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.White.copy(alpha = 0.03f))
                        .padding(10.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "💡",
                            fontSize = 14.sp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = message,
                            fontSize = 12.sp,
                            color = TextSecondary,
                            lineHeight = 16.sp
                        )
                    }
                }
            }
        }
    }
}
