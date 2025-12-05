package com.aifitnesscoach.app.screens.workout

import android.util.Log
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.decode.GifDecoder
import coil.decode.ImageDecoderDecoder
import coil.request.ImageRequest
import com.aifitnesscoach.app.ui.theme.*
import com.aifitnesscoach.shared.api.ApiClient
import com.aifitnesscoach.shared.models.Workout
import com.aifitnesscoach.shared.models.WorkoutExercise
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val TAG = "ActiveWorkoutScreen"

// Data class for tracking sets
data class ActiveSet(
    val setNumber: Int,
    val setType: String = "working", // warmup, working, failure
    var targetWeight: Double = 0.0,
    var targetReps: Int = 0,
    var actualWeight: Double = 0.0,
    var actualReps: Int = 0,
    var isCompleted: Boolean = false
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActiveWorkoutScreen(
    workout: Workout,
    onExitWorkout: () -> Unit,
    onWorkoutComplete: (durationMinutes: Int) -> Unit
) {
    val scope = rememberCoroutineScope()
    val exercises = remember { workout.getExercises() }

    // State
    var currentExerciseIndex by remember { mutableIntStateOf(0) }
    var expandedExerciseIndex by remember { mutableStateOf<Int?>(0) }
    var exerciseSets by remember { mutableStateOf(initializeSets(exercises)) }
    var isPaused by remember { mutableStateOf(false) }
    var isCompleting by remember { mutableStateOf(false) }
    var showExitDialog by remember { mutableStateOf(false) }

    // Timer state
    var totalElapsedSeconds by remember { mutableIntStateOf(0) }
    var restTimer by remember { mutableStateOf<Int?>(null) }
    var isResting by remember { mutableStateOf(false) }

    // Total elapsed time counter
    LaunchedEffect(isPaused) {
        while (!isPaused) {
            delay(1000)
            totalElapsedSeconds++
        }
    }

    // Rest timer
    LaunchedEffect(isResting, restTimer) {
        if (isResting && restTimer != null && restTimer!! > 0) {
            while (restTimer!! > 0) {
                delay(1000)
                restTimer = restTimer!! - 1
            }
            isResting = false
            restTimer = null
        }
    }

    // Calculate progress
    val completedSets = exerciseSets.values.flatten().count { it.isCompleted }
    val totalSets = exerciseSets.values.flatten().size
    val progress = if (totalSets > 0) completedSets.toFloat() / totalSets else 0f

    // Exit confirmation dialog
    if (showExitDialog) {
        AlertDialog(
            onDismissRequest = { showExitDialog = false },
            title = {
                Text(
                    "Leave Workout?",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text(
                    "You've completed $completedSets of $totalSets sets. Are you sure you want to leave?",
                    color = TextSecondary
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showExitDialog = false
                    onExitWorkout()
                }) {
                    Text("Leave", color = Color(0xFFEF4444))
                }
            },
            dismissButton = {
                TextButton(onClick = { showExitDialog = false }) {
                    Text("Keep Going", color = Cyan)
                }
            },
            containerColor = Color(0xFF1A1A1A),
            shape = RoundedCornerShape(20.dp)
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // Header with timer and controls
            WorkoutHeader(
                totalElapsedSeconds = totalElapsedSeconds,
                progress = progress,
                isPaused = isPaused,
                onPauseToggle = { isPaused = !isPaused },
                onExit = { showExitDialog = true }
            )

            // Rest timer overlay
            if (isResting && restTimer != null) {
                RestTimerBanner(
                    seconds = restTimer!!,
                    onSkip = {
                        isResting = false
                        restTimer = null
                    }
                )
            }

            // Exercise list
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                itemsIndexed(exercises) { index, exercise ->
                    val sets = exerciseSets[index] ?: emptyList()
                    val isExpanded = expandedExerciseIndex == index
                    val isComplete = sets.isNotEmpty() && sets.all { it.isCompleted }

                    ExerciseAccordion(
                        exercise = exercise,
                        index = index,
                        sets = sets,
                        isExpanded = isExpanded,
                        isComplete = isComplete,
                        isCurrent = index == currentExerciseIndex,
                        onToggle = {
                            if (expandedExerciseIndex == index) {
                                expandedExerciseIndex = null
                            } else {
                                expandedExerciseIndex = index
                                currentExerciseIndex = index
                            }
                        },
                        onSetComplete = { setIndex ->
                            val updatedSets = sets.toMutableList()
                            updatedSets[setIndex] = updatedSets[setIndex].copy(isCompleted = true)
                            exerciseSets = exerciseSets.toMutableMap().apply {
                                put(index, updatedSets)
                            }
                            // Start rest timer
                            restTimer = exercise.restSeconds ?: 90
                            isResting = true
                        },
                        onWeightChange = { setIndex, weight ->
                            val updatedSets = sets.toMutableList()
                            updatedSets[setIndex] = updatedSets[setIndex].copy(actualWeight = weight)
                            exerciseSets = exerciseSets.toMutableMap().apply {
                                put(index, updatedSets)
                            }
                        },
                        onRepsChange = { setIndex, reps ->
                            val updatedSets = sets.toMutableList()
                            updatedSets[setIndex] = updatedSets[setIndex].copy(actualReps = reps)
                            exerciseSets = exerciseSets.toMutableMap().apply {
                                put(index, updatedSets)
                            }
                        },
                        onAddSet = {
                            val updatedSets = sets.toMutableList()
                            val lastSet = updatedSets.lastOrNull()
                            updatedSets.add(
                                ActiveSet(
                                    setNumber = updatedSets.size + 1,
                                    targetWeight = lastSet?.actualWeight ?: exercise.weight ?: 0.0,
                                    targetReps = lastSet?.actualReps ?: exercise.reps ?: 10,
                                    actualWeight = lastSet?.actualWeight ?: exercise.weight ?: 0.0,
                                    actualReps = lastSet?.actualReps ?: exercise.reps ?: 10
                                )
                            )
                            exerciseSets = exerciseSets.toMutableMap().apply {
                                put(index, updatedSets)
                            }
                        }
                    )
                }

                item {
                    Spacer(modifier = Modifier.height(100.dp))
                }
            }

            // Finish workout button
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
                    .navigationBarsPadding()
            ) {
                Button(
                    onClick = {
                        scope.launch {
                            isCompleting = true
                            val durationMinutes = (totalElapsedSeconds + 30) / 60 // Round to nearest minute
                            try {
                                ApiClient.workoutApi.completeWorkout(workout.id!!)
                                Log.d(TAG, "✅ Workout completed successfully")
                                onWorkoutComplete(durationMinutes)
                            } catch (e: Exception) {
                                Log.e(TAG, "❌ Failed to complete workout: ${e.message}", e)
                                // Still navigate away on error
                                onWorkoutComplete(durationMinutes)
                            } finally {
                                isCompleting = false
                            }
                        }
                    },
                    enabled = !isCompleting,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .height(56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF10B981),
                        contentColor = Color.White
                    )
                ) {
                    if (isCompleting) {
                        CircularProgressIndicator(
                            color = Color.White,
                            modifier = Modifier.size(24.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(
                            Icons.Default.Check,
                            contentDescription = null,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Finish Workout",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun WorkoutHeader(
    totalElapsedSeconds: Int,
    progress: Float,
    isPaused: Boolean,
    onPauseToggle: () -> Unit,
    onExit: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Back/Exit button
            IconButton(
                onClick = onExit,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.1f))
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Exit",
                    tint = TextPrimary
                )
            }

            // Timer
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(Color.White.copy(alpha = 0.1f))
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Timer,
                        contentDescription = null,
                        tint = TextSecondary,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = formatTime(totalElapsedSeconds),
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                }
            }

            // Pause button
            IconButton(
                onClick = onPauseToggle,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(
                        if (isPaused) Cyan else Color.White.copy(alpha = 0.1f)
                    )
            ) {
                Icon(
                    if (isPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                    contentDescription = if (isPaused) "Resume" else "Pause",
                    tint = if (isPaused) Color.White else TextPrimary
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Progress bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(Color.White.copy(alpha = 0.1f))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(progress)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(2.dp))
                    .background(
                        brush = Brush.horizontalGradient(
                            colors = listOf(Cyan, Color(0xFF10B981))
                        )
                    )
            )
        }
    }
}

@Composable
private fun RestTimerBanner(
    seconds: Int,
    onSkip: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.horizontalGradient(
                    colors = listOf(
                        Cyan.copy(alpha = 0.2f),
                        Color(0xFF10B981).copy(alpha = 0.2f)
                    )
                )
            )
            .border(
                width = 1.dp,
                color = Cyan.copy(alpha = 0.3f),
                shape = RoundedCornerShape(16.dp)
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
                    text = "Rest Time",
                    color = TextSecondary,
                    fontSize = 12.sp
                )
                Text(
                    text = formatTime(seconds),
                    color = Cyan,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Button(
                onClick = onSkip,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White.copy(alpha = 0.15f),
                    contentColor = TextPrimary
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Skip", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun ExerciseAccordion(
    exercise: WorkoutExercise,
    index: Int,
    sets: List<ActiveSet>,
    isExpanded: Boolean,
    isComplete: Boolean,
    isCurrent: Boolean,
    onToggle: () -> Unit,
    onSetComplete: (Int) -> Unit,
    onWeightChange: (Int, Double) -> Unit,
    onRepsChange: (Int, Int) -> Unit,
    onAddSet: () -> Unit
) {
    val completedSetsCount = sets.count { it.isCompleted }

    Column {
        // Header row
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(
                    when {
                        isExpanded -> Cyan.copy(alpha = 0.2f)
                        isComplete -> Color(0xFF10B981).copy(alpha = 0.1f)
                        isCurrent -> Color.White.copy(alpha = 0.1f)
                        else -> Color.White.copy(alpha = 0.05f)
                    }
                )
                .clickable { onToggle() }
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Number badge
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(
                            when {
                                isComplete -> Color(0xFF10B981)
                                isExpanded -> Cyan
                                else -> Color.White.copy(alpha = 0.1f)
                            }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (isComplete) {
                        Icon(
                            Icons.Default.Check,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                    } else {
                        Text(
                            text = "${index + 1}",
                            color = if (isExpanded) Color.White else TextSecondary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = exercise.name,
                        color = if (isExpanded) Cyan else TextPrimary,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 15.sp
                    )
                    Text(
                        text = "${exercise.sets ?: sets.size}×${exercise.reps ?: 10} • ${exercise.equipment ?: "Bodyweight"}",
                        color = TextMuted,
                        fontSize = 12.sp
                    )
                }

                Text(
                    text = "$completedSetsCount/${sets.size}",
                    color = TextMuted,
                    fontSize = 12.sp
                )

                Spacer(modifier = Modifier.width(8.dp))

                Icon(
                    if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = TextMuted,
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        // Expanded content
        AnimatedVisibility(
            visible = isExpanded,
            enter = expandVertically() + fadeIn(),
            exit = shrinkVertically() + fadeOut()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 16.dp)
                    .border(
                        width = 2.dp,
                        color = Cyan.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(bottomStart = 12.dp)
                    )
                    .padding(start = 16.dp, top = 12.dp, bottom = 12.dp)
            ) {
                // Exercise video/GIF
                val videoUrl = exercise.gifUrl ?: exercise.videoUrl
                if (!videoUrl.isNullOrBlank()) {
                    ExerciseVideoPlayer(
                        videoUrl = videoUrl,
                        exerciseName = exercise.name
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                }

                // Set header row
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(end = 16.dp, bottom = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Set", color = TextMuted, fontSize = 11.sp, modifier = Modifier.width(40.dp))
                    Text("Weight", color = TextMuted, fontSize = 11.sp, modifier = Modifier.width(70.dp), textAlign = TextAlign.Center)
                    Text("Reps", color = TextMuted, fontSize = 11.sp, modifier = Modifier.width(60.dp), textAlign = TextAlign.Center)
                    Spacer(modifier = Modifier.width(50.dp))
                }

                // Set rows
                sets.forEachIndexed { setIndex, set ->
                    SetRow(
                        set = set,
                        onComplete = { onSetComplete(setIndex) },
                        onWeightChange = { onWeightChange(setIndex, it) },
                        onRepsChange = { onRepsChange(setIndex, it) }
                    )
                }

                // Add set button
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(end = 16.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .border(
                            width = 1.dp,
                            color = Color.White.copy(alpha = 0.15f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        .clickable { onAddSet() }
                        .padding(12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Add,
                            contentDescription = null,
                            tint = TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Add Set",
                            color = TextSecondary,
                            fontSize = 14.sp
                        )
                    }
                }

                // Exercise notes
                exercise.notes?.let { notes ->
                    Spacer(modifier = Modifier.height(12.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(end = 16.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Cyan.copy(alpha = 0.1f))
                            .padding(12.dp)
                    ) {
                        Row {
                            Text("💡", fontSize = 14.sp)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = notes,
                                color = TextSecondary,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SetRow(
    set: ActiveSet,
    onComplete: () -> Unit,
    onWeightChange: (Double) -> Unit,
    onRepsChange: (Int) -> Unit
) {
    val isActive = !set.isCompleted
    var weightText by remember { mutableStateOf(set.actualWeight.toString()) }
    var repsText by remember { mutableStateOf(set.actualReps.toString()) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(end = 16.dp, bottom = 8.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(
                if (set.isCompleted) Color(0xFF10B981).copy(alpha = 0.1f)
                else Color.White.copy(alpha = 0.05f)
            )
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Set number
        Box(
            modifier = Modifier.width(40.dp),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                text = if (set.setType == "warmup") "W" else "${set.setNumber}",
                color = if (set.isCompleted) Color(0xFF10B981) else TextSecondary,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp
            )
        }

        // Weight input
        OutlinedTextField(
            value = weightText,
            onValueChange = { newValue ->
                weightText = newValue
                newValue.toDoubleOrNull()?.let { onWeightChange(it) }
            },
            enabled = isActive,
            modifier = Modifier.width(70.dp),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            singleLine = true,
            textStyle = LocalTextStyle.current.copy(
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                color = TextPrimary
            ),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Cyan,
                unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                disabledBorderColor = Color.White.copy(alpha = 0.1f),
                disabledTextColor = TextSecondary
            ),
            shape = RoundedCornerShape(8.dp)
        )

        Spacer(modifier = Modifier.width(8.dp))

        // Reps input
        OutlinedTextField(
            value = repsText,
            onValueChange = { newValue ->
                repsText = newValue
                newValue.toIntOrNull()?.let { onRepsChange(it) }
            },
            enabled = isActive,
            modifier = Modifier.width(60.dp),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            singleLine = true,
            textStyle = LocalTextStyle.current.copy(
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                color = TextPrimary
            ),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Cyan,
                unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                disabledBorderColor = Color.White.copy(alpha = 0.1f),
                disabledTextColor = TextSecondary
            ),
            shape = RoundedCornerShape(8.dp)
        )

        Spacer(modifier = Modifier.weight(1f))

        // Complete button
        IconButton(
            onClick = onComplete,
            enabled = isActive,
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(
                    if (set.isCompleted) Color(0xFF10B981)
                    else Cyan.copy(alpha = 0.2f)
                )
        ) {
            Icon(
                Icons.Default.Check,
                contentDescription = "Complete set",
                tint = if (set.isCompleted) Color.White else Cyan,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

private fun initializeSets(exercises: List<WorkoutExercise>): Map<Int, List<ActiveSet>> {
    return exercises.mapIndexed { index, exercise ->
        val sets = (1..(exercise.sets ?: 3)).map { setNum ->
            ActiveSet(
                setNumber = setNum,
                targetWeight = exercise.weight ?: 0.0,
                targetReps = exercise.reps ?: 10,
                actualWeight = exercise.weight ?: 0.0,
                actualReps = exercise.reps ?: 10
            )
        }
        index to sets
    }.toMap()
}

private fun formatTime(seconds: Int): String {
    val hours = seconds / 3600
    val mins = (seconds % 3600) / 60
    val secs = seconds % 60
    return if (hours > 0) {
        String.format("%d:%02d:%02d", hours, mins, secs)
    } else {
        String.format("%d:%02d", mins, secs)
    }
}

@Composable
private fun ExerciseVideoPlayer(
    videoUrl: String,
    exerciseName: String
) {
    val context = LocalContext.current
    var isLoading by remember { mutableStateOf(true) }
    var hasError by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(end = 16.dp)
            .aspectRatio(16f / 9f)
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White.copy(alpha = 0.05f))
            .border(
                width = 1.dp,
                color = Cyan.copy(alpha = 0.2f),
                shape = RoundedCornerShape(12.dp)
            ),
        contentAlignment = Alignment.Center
    ) {
        if (hasError) {
            // Error state
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    Icons.Default.VideocamOff,
                    contentDescription = null,
                    tint = TextMuted,
                    modifier = Modifier.size(32.dp)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Video unavailable",
                    color = TextMuted,
                    fontSize = 12.sp
                )
            }
        } else {
            // GIF/Image player
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(videoUrl)
                    .decoderFactory(
                        if (android.os.Build.VERSION.SDK_INT >= 28) {
                            ImageDecoderDecoder.Factory()
                        } else {
                            GifDecoder.Factory()
                        }
                    )
                    .crossfade(true)
                    .build(),
                contentDescription = "Exercise demonstration for $exerciseName",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                onLoading = { isLoading = true },
                onSuccess = { isLoading = false },
                onError = {
                    isLoading = false
                    hasError = true
                }
            )

            // Loading overlay
            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.5f)),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = Cyan,
                        modifier = Modifier.size(32.dp),
                        strokeWidth = 2.dp
                    )
                }
            }
        }

        // Play indicator overlay for videos (not GIFs)
        if (!hasError && !isLoading && videoUrl.endsWith(".mp4", ignoreCase = true)) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.9f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.PlayArrow,
                        contentDescription = "Play",
                        tint = Cyan,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
        }
    }
}
