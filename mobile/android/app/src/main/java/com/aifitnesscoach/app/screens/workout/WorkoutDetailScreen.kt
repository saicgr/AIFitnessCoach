package com.aifitnesscoach.app.screens.workout

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aifitnesscoach.app.ui.theme.*
import com.aifitnesscoach.shared.api.ApiClient
import com.aifitnesscoach.shared.models.Exercise
import com.aifitnesscoach.shared.models.Workout
import com.aifitnesscoach.shared.models.WorkoutExercise
import kotlinx.coroutines.launch

private const val TAG = "WorkoutDetailScreen"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkoutDetailScreen(
    workoutId: String,
    onBackClick: () -> Unit,
    onStartWorkout: ((Workout) -> Unit)? = null
) {
    val scope = rememberCoroutineScope()
    var workout by remember { mutableStateOf<Workout?>(null) }
    var exercises by remember { mutableStateOf<List<WorkoutExercise>>(emptyList()) }
    var warmupExercises by remember { mutableStateOf<List<Exercise>>(emptyList()) }
    var stretchExercises by remember { mutableStateOf<List<Exercise>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var expandedWarmup by remember { mutableStateOf(false) }
    var expandedCooldown by remember { mutableStateOf(false) }

    // Load workout from API
    LaunchedEffect(workoutId) {
        isLoading = true
        error = null
        try {
            Log.d(TAG, "🔍 Fetching workout: $workoutId")
            val loadedWorkout = ApiClient.workoutApi.getWorkout(workoutId)
            workout = loadedWorkout
            exercises = loadedWorkout.getExercises()
            Log.d(TAG, "✅ Loaded workout: ${loadedWorkout.name} with ${exercises.size} exercises")

            // Load warmup and stretches
            try {
                warmupExercises = ApiClient.workoutApi.getWarmup(workoutId)
                stretchExercises = ApiClient.workoutApi.getStretches(workoutId)
                Log.d(TAG, "✅ Loaded ${warmupExercises.size} warmup, ${stretchExercises.size} stretch exercises")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Warmup/stretches not available: ${e.message}")
                // Create default warmup exercises
                warmupExercises = listOf(
                    Exercise(name = "Jumping Jacks", defaultDurationSeconds = 60),
                    Exercise(name = "Arm Circles", defaultDurationSeconds = 30),
                    Exercise(name = "Leg Swings", defaultDurationSeconds = 30),
                    Exercise(name = "Hip Circles", defaultDurationSeconds = 30)
                )
                stretchExercises = listOf(
                    Exercise(name = "Quad Stretch", defaultDurationSeconds = 30),
                    Exercise(name = "Hamstring Stretch", defaultDurationSeconds = 30),
                    Exercise(name = "Shoulder Stretch", defaultDurationSeconds = 30),
                    Exercise(name = "Child's Pose", defaultDurationSeconds = 60)
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to load workout: ${e.message}", e)
            error = e.message ?: "Failed to load workout"
        } finally {
            isLoading = false
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
        // Top gradient
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(250.dp)
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Cyan.copy(alpha = 0.15f),
                            Color.Transparent
                        )
                    )
                )
        )

        when {
            isLoading -> {
                // Loading state
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(color = Cyan)
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Loading workout...",
                            color = TextSecondary,
                            fontSize = 14.sp
                        )
                    }
                }
            }
            error != null -> {
                // Error state
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .statusBarsPadding()
                ) {
                    // Top bar with back button
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 8.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = onBackClick) {
                            Icon(
                                Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = TextPrimary
                            )
                        }
                    }

                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(32.dp)
                        ) {
                            Icon(
                                Icons.Default.Error,
                                contentDescription = null,
                                tint = Color(0xFFEF4444),
                                modifier = Modifier.size(48.dp)
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "Failed to load workout",
                                color = TextPrimary,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = error ?: "Unknown error",
                                color = TextSecondary,
                                fontSize = 14.sp
                            )
                            Spacer(modifier = Modifier.height(24.dp))
                            Button(
                                onClick = {
                                    scope.launch {
                                        isLoading = true
                                        error = null
                                        try {
                                            val loadedWorkout = ApiClient.workoutApi.getWorkout(workoutId)
                                            workout = loadedWorkout
                                            exercises = loadedWorkout.getExercises()
                                        } catch (e: Exception) {
                                            error = e.message
                                        } finally {
                                            isLoading = false
                                        }
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Cyan)
                            ) {
                                Text("Retry")
                            }
                        }
                    }
                }
            }
            workout != null -> {
                // Content
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .statusBarsPadding()
                ) {
                    // Custom top bar
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 8.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = onBackClick) {
                            Icon(
                                Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = TextPrimary
                            )
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Text(
                            text = workout?.name ?: "Workout",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                    }

                    LazyColumn(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Workout summary in glass card
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(20.dp))
                                    .background(
                                        brush = Brush.verticalGradient(
                                            colors = listOf(
                                                Color.White.copy(alpha = 0.1f),
                                                Color.White.copy(alpha = 0.05f)
                                            )
                                        )
                                    )
                                    .border(
                                        width = 1.dp,
                                        brush = Brush.verticalGradient(
                                            colors = listOf(
                                                Color.White.copy(alpha = 0.2f),
                                                Color.White.copy(alpha = 0.05f)
                                            )
                                        ),
                                        shape = RoundedCornerShape(20.dp)
                                    )
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(20.dp),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    WorkoutStat(
                                        icon = Icons.Default.FitnessCenter,
                                        label = "Exercises",
                                        value = "${exercises.size}"
                                    )
                                    WorkoutStat(
                                        icon = Icons.Default.Timer,
                                        label = "Est. Time",
                                        value = "${workout?.durationMinutes ?: 45} min"
                                    )
                                    WorkoutStat(
                                        icon = Icons.Default.Speed,
                                        label = "Difficulty",
                                        value = workout?.difficulty?.replaceFirstChar { it.uppercase() } ?: "Medium"
                                    )
                                }
                            }
                        }

                        // Workout type tag
                        workout?.type?.let { type ->
                            item {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.Start
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(8.dp))
                                            .background(Cyan.copy(alpha = 0.2f))
                                            .padding(horizontal = 12.dp, vertical = 6.dp)
                                    ) {
                                        Text(
                                            text = type.replaceFirstChar { it.uppercase() },
                                            color = Cyan,
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                    }
                                }
                            }
                        }

                        // Warmup section
                        item {
                            Spacer(modifier = Modifier.height(4.dp))
                            WarmupCooldownSection(
                                title = "Warmup",
                                icon = Icons.Default.Whatshot,
                                exercises = warmupExercises,
                                color = Color(0xFFF59E0B),
                                isExpanded = expandedWarmup,
                                onToggle = { expandedWarmup = !expandedWarmup }
                            )
                        }

                        item {
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Main Workout",
                                fontSize = 20.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = TextPrimary
                            )
                        }

                        itemsIndexed(exercises) { index, exercise ->
                            ExerciseCard(exercise = exercise, index = index + 1)
                        }

                        // Cooldown section
                        item {
                            Spacer(modifier = Modifier.height(8.dp))
                            WarmupCooldownSection(
                                title = "Cooldown & Stretches",
                                icon = Icons.Default.SelfImprovement,
                                exercises = stretchExercises,
                                color = Color(0xFF10B981),
                                isExpanded = expandedCooldown,
                                onToggle = { expandedCooldown = !expandedCooldown }
                            )
                        }

                        item {
                            Spacer(modifier = Modifier.height(80.dp)) // Space for bottom bar
                        }
                    }

                    // Bottom action bar
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                brush = Brush.verticalGradient(
                                    colors = listOf(
                                        Color.White.copy(alpha = 0.08f),
                                        Color.White.copy(alpha = 0.04f)
                                    )
                                )
                            )
                            .border(
                                width = 1.dp,
                                brush = Brush.verticalGradient(
                                    colors = listOf(
                                        Color.White.copy(alpha = 0.15f),
                                        Color.Transparent
                                    )
                                ),
                                shape = RoundedCornerShape(0.dp)
                            )
                            .navigationBarsPadding()
                    ) {
                        Button(
                            onClick = {
                                workout?.let { w ->
                                    onStartWorkout?.invoke(w)
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp)
                                .height(56.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Cyan,
                                contentColor = Color.White
                            )
                        ) {
                            Icon(
                                Icons.Default.PlayArrow,
                                contentDescription = null,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Start Workout",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WorkoutStat(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(Cyan.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = Cyan,
                modifier = Modifier.size(22.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = value,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        Text(
            text = label,
            fontSize = 12.sp,
            color = TextSecondary
        )
    }
}

@Composable
private fun ExerciseCard(exercise: WorkoutExercise, index: Int) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.08f),
                        Color.White.copy(alpha = 0.04f)
                    )
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.12f),
                        Color.White.copy(alpha = 0.04f)
                    )
                ),
                shape = RoundedCornerShape(16.dp)
            )
            .clickable { /* TODO: Show exercise details */ }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Exercise number
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(
                        brush = Brush.linearGradient(
                            colors = listOf(
                                Cyan.copy(alpha = 0.2f),
                                CyanDark.copy(alpha = 0.2f)
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "$index",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Cyan
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = exercise.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    exercise.sets?.let { sets ->
                        ExerciseDetailChip(
                            icon = Icons.Default.Repeat,
                            text = "$sets sets"
                        )
                    }
                    exercise.reps?.let { reps ->
                        ExerciseDetailChip(
                            icon = Icons.Default.Numbers,
                            text = "$reps reps"
                        )
                    }
                    exercise.durationSeconds?.let { duration ->
                        if (duration > 0) {
                            ExerciseDetailChip(
                                icon = Icons.Default.Timer,
                                text = "${duration}s"
                            )
                        }
                    }
                }

                // Show muscle group if available
                exercise.muscleGroup?.let { muscle ->
                    Spacer(modifier = Modifier.height(6.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(Cyan.copy(alpha = 0.15f))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = muscle,
                            fontSize = 11.sp,
                            color = Cyan.copy(alpha = 0.9f)
                        )
                    }
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View details",
                tint = TextMuted,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

@Composable
private fun ExerciseDetailChip(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = TextMuted,
            modifier = Modifier.size(14.dp)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = text,
            fontSize = 13.sp,
            color = TextSecondary
        )
    }
}

@Composable
private fun WarmupCooldownSection(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    exercises: List<Exercise>,
    color: Color,
    isExpanded: Boolean,
    onToggle: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        color.copy(alpha = 0.15f),
                        color.copy(alpha = 0.05f)
                    )
                )
            )
            .border(
                width = 1.dp,
                color = color.copy(alpha = 0.2f),
                shape = RoundedCornerShape(16.dp)
            )
            .clickable { onToggle() }
    ) {
        Column {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(color.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        icon,
                        contentDescription = null,
                        tint = color,
                        modifier = Modifier.size(22.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = title,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )
                    Text(
                        text = "${exercises.size} exercises • ~${exercises.sumOf { it.defaultDurationSeconds ?: 30 } / 60} min",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                }

                Icon(
                    if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = TextMuted,
                    modifier = Modifier.size(24.dp)
                )
            }

            // Expanded content
            if (isExpanded) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 16.dp, end = 16.dp, bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    exercises.forEachIndexed { index, exercise ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color.White.copy(alpha = 0.05f))
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(28.dp)
                                    .clip(CircleShape)
                                    .background(color.copy(alpha = 0.2f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "${index + 1}",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = color
                                )
                            }

                            Spacer(modifier = Modifier.width(12.dp))

                            Text(
                                text = exercise.name,
                                fontSize = 14.sp,
                                color = TextPrimary,
                                modifier = Modifier.weight(1f)
                            )

                            Text(
                                text = "${exercise.defaultDurationSeconds ?: 30}s",
                                fontSize = 12.sp,
                                color = TextSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}
