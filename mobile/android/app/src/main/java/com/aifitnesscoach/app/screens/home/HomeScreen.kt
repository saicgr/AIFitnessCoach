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
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

private const val TAG = "HomeScreen"

// Accent colors
private val Teal = Color(0xFF14B8A6)
private val LimeGreen = Color(0xFFD4FF00)
private val Orange = Color(0xFFF59E0B)

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
                LazyColumn(
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
                            onProfileClick = onLogout
                        )
                    }

                    // Next Workout Hero Card
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

                    // Upcoming Workouts Section
                    if (upcomingWorkouts.isNotEmpty()) {
                        item {
                            Spacer(modifier = Modifier.height(24.dp))
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Upcoming This Week",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = TextPrimary
                                )
                                Text(
                                    text = "${upcomingWorkouts.size} workouts",
                                    fontSize = 12.sp,
                                    color = TextMuted
                                )
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                        }

                        items(upcomingWorkouts) { workout ->
                            UpcomingWorkoutCard(
                                workout = workout,
                                onClick = { workout.id?.let { onWorkoutClick(it) } },
                                onLongPress = { showWorkoutMenu = workout }
                            )
                        }
                    }
                }

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
    onProfileClick: () -> Unit
) {
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

        // Stats
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatBadge(value = completedCount.toString(), label = "Done")
            StatBadge(value = userLevel.take(3), label = "Level")
            StatBadge(value = "0", label = "Streak")
        }
    }
}

@Composable
private fun StatBadge(value: String, label: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .widthIn(min = 56.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White.copy(alpha = 0.05f))
            .padding(horizontal = 10.dp, vertical = 8.dp)
    ) {
        Text(
            text = value,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary,
            maxLines = 1
        )
        Text(
            text = label,
            fontSize = 9.sp,
            color = TextMuted,
            maxLines = 1
        )
    }
}

@Composable
private fun NextWorkoutHeroCard(
    workout: Workout,
    onStartClick: () -> Unit,
    onSkipClick: () -> Unit,
    onRegenerateClick: () -> Unit,
    onRescheduleClick: () -> Unit
) {
    val exercises = workout.getExercises()

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
            // Label
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

            Spacer(modifier = Modifier.height(8.dp))

            // Duration and exercises
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "${workout.durationMinutes ?: 45} mins",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Box(
                    modifier = Modifier
                        .size(4.dp)
                        .clip(CircleShape)
                        .background(TextMuted)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "${exercises.size} exercises",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Quick action buttons row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                QuickActionButton(
                    icon = Icons.Default.SkipNext,
                    label = "Skip",
                    onClick = onSkipClick
                )
                QuickActionButton(
                    icon = Icons.Default.Refresh,
                    label = "Regenerate",
                    onClick = onRegenerateClick
                )
                QuickActionButton(
                    icon = Icons.Default.Schedule,
                    label = "Reschedule",
                    onClick = onRescheduleClick
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Start workout button
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
        }
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

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun UpcomingWorkoutCard(
    workout: Workout,
    onClick: () -> Unit,
    onLongPress: () -> Unit
) {
    val exercises = workout.getExercises()
    val scheduledDate = workout.scheduledDate?.take(10)?.let { LocalDate.parse(it) }
    val daysUntil = scheduledDate?.let { ChronoUnit.DAYS.between(LocalDate.now(), it).toInt() }

    val dayLabel = when (daysUntil) {
        0 -> "Today"
        1 -> "Tomorrow"
        else -> scheduledDate?.format(DateTimeFormatter.ofPattern("EEE, MMM d")) ?: ""
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
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Day indicator
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.width(50.dp)
            ) {
                Text(
                    text = scheduledDate?.dayOfWeek?.name?.take(3) ?: "",
                    fontSize = 11.sp,
                    color = TextMuted
                )
                Text(
                    text = scheduledDate?.dayOfMonth?.toString() ?: "",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Cyan
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Workout info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = workout.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "${workout.durationMinutes ?: 45} min",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(
                        modifier = Modifier
                            .size(3.dp)
                            .clip(CircleShape)
                            .background(TextMuted)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "${exercises.size} exercises",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                }
            }

            // Play button
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Cyan.copy(alpha = 0.2f))
                    .clickable(onClick = onClick),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.PlayArrow,
                    contentDescription = "Start workout",
                    tint = Cyan,
                    modifier = Modifier.size(22.dp)
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
