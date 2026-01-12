package com.fitwiz.wearos.presentation.screens.workout

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.*
import com.fitwiz.wearos.data.models.WearExercise
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.WorkoutViewModel

/**
 * Active Workout Screen - Shows current exercise with swipe navigation
 */
@Composable
fun ActiveWorkoutScreen(
    viewModel: WorkoutViewModel = hiltViewModel(),
    onCompleteSet: () -> Unit,
    onWorkoutComplete: () -> Unit,
    onBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val currentExerciseIndex by viewModel.currentExerciseIndex.collectAsState()
    val workoutMetrics by viewModel.workoutMetrics.collectAsState()

    val workout = uiState.todaysWorkout
    val currentExercise = viewModel.getCurrentExercise()
    val completedSets = viewModel.getCompletedSetsForCurrentExercise()

    if (workout == null || currentExercise == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
        return
    }

    val totalExercises = workout.exercises.size
    val isLastExercise = viewModel.isLastExercise()
    val isExerciseComplete = completedSets >= currentExercise.sets

    // Handle swipe gestures
    var swipeOffset by remember { mutableFloatStateOf(0f) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragEnd = {
                        if (swipeOffset > 100 && !viewModel.isFirstExercise()) {
                            viewModel.previousExercise()
                        } else if (swipeOffset < -100 && !viewModel.isLastExercise()) {
                            viewModel.nextExercise()
                        }
                        swipeOffset = 0f
                    },
                    onHorizontalDrag = { _, dragAmount ->
                        swipeOffset += dragAmount
                    }
                )
            }
    ) {
        Scaffold(
            timeText = {
                // Heart rate indicator instead of time
                HeartRateIndicator(bpm = workoutMetrics.currentHeartRate)
            },
            vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                // Progress indicator
                ExerciseProgress(
                    currentIndex = currentExerciseIndex,
                    totalExercises = totalExercises,
                    completedSets = completedSets,
                    totalSets = currentExercise.sets
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Exercise info card
                ExerciseCard(
                    exercise = currentExercise,
                    completedSets = completedSets
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Action button
                if (isExerciseComplete && isLastExercise) {
                    // Finish workout button
                    Button(
                        onClick = {
                            viewModel.completeWorkout()
                            onWorkoutComplete()
                        },
                        modifier = Modifier
                            .fillMaxWidth(0.9f)
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Success
                        )
                    ) {
                        Text("FINISH", style = FitWizTypography.labelLarge)
                    }
                } else if (isExerciseComplete) {
                    // Next exercise button
                    Button(
                        onClick = { viewModel.nextExercise() },
                        modifier = Modifier
                            .fillMaxWidth(0.9f)
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Secondary
                        )
                    ) {
                        Text("NEXT", style = FitWizTypography.labelLarge)
                    }
                } else {
                    // Complete set button
                    Button(
                        onClick = onCompleteSet,
                        modifier = Modifier
                            .fillMaxWidth(0.9f)
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Primary
                        )
                    ) {
                        Text("COMPLETE SET", style = FitWizTypography.labelLarge)
                    }
                }

                // Navigation hint
                Row(
                    modifier = Modifier.padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (!viewModel.isFirstExercise()) {
                        Text(
                            text = "< Prev",
                            style = FitWizTypography.labelSmall,
                            color = FitWizColors.TextMuted
                        )
                    }
                    if (!viewModel.isLastExercise()) {
                        Text(
                            text = "Next >",
                            style = FitWizTypography.labelSmall,
                            color = FitWizColors.TextMuted
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun HeartRateIndicator(bpm: Int?) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "HR",
            style = FitWizTypography.bodySmall,
            color = FitWizColors.HeartRate
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = if (bpm != null) "$bpm BPM" else "-- BPM",
            style = FitWizTypography.bodySmall,
            color = FitWizColors.HeartRate
        )
    }
}

@Composable
private fun ExerciseProgress(
    currentIndex: Int,
    totalExercises: Int,
    completedSets: Int,
    totalSets: Int
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Exercise progress text
        Text(
            text = "Exercise ${currentIndex + 1} of $totalExercises",
            style = FitWizTypography.labelSmall,
            color = FitWizColors.TextMuted
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Set progress dots
        Row(
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth()
        ) {
            repeat(totalSets) { index ->
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .padding(2.dp)
                        .clip(CircleShape)
                        .background(
                            if (index < completedSets) FitWizColors.Success
                            else FitWizColors.ProgressBackground
                        )
                )
            }
        }

        Text(
            text = "Set ${completedSets + 1} of $totalSets",
            style = FitWizTypography.labelSmall,
            color = FitWizColors.TextSecondary
        )
    }
}

@Composable
private fun ExerciseCard(
    exercise: WearExercise,
    completedSets: Int
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(FitWizColors.Surface)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Exercise name
        Text(
            text = exercise.name,
            style = FitWizTypography.titleMedium,
            color = FitWizColors.TextPrimary,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Target reps
        Text(
            text = "${exercise.targetReps} reps",
            style = FitWizTypography.displaySmall,
            color = FitWizColors.Primary
        )

        // Suggested weight
        exercise.suggestedWeight?.let { weight ->
            Text(
                text = "@ ${weight.toInt()} kg",
                style = FitWizTypography.bodyMedium,
                color = FitWizColors.TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Muscle group chip
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(8.dp))
                .background(FitWizColors.Primary.copy(alpha = 0.2f))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(
                text = exercise.muscleGroup,
                style = FitWizTypography.labelSmall,
                color = FitWizColors.Primary
            )
        }
    }
}
