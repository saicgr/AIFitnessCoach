package com.fitwiz.wearos.presentation.screens.workout

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.*
import com.fitwiz.wearos.data.models.WearExercise
import com.fitwiz.wearos.data.models.WearWorkout
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.WorkoutViewModel

/**
 * Workout Detail Screen - Shows workout info and exercises
 */
@Composable
fun WorkoutDetailScreen(
    viewModel: WorkoutViewModel = hiltViewModel(),
    onStartWorkout: () -> Unit,
    onBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberScalingLazyListState()

    val workout = uiState.todaysWorkout

    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) }
    ) {
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (workout == null) {
            NoWorkoutContent(
                onCreateSample = { viewModel.createSampleWorkout() }
            )
        } else {
            WorkoutContent(
                workout = workout,
                listState = listState,
                onStartWorkout = onStartWorkout
            )
        }
    }
}

@Composable
private fun NoWorkoutContent(
    onCreateSample: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Workout",
                style = FitWizTypography.displayLarge
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "No Workout",
                style = FitWizTypography.titleMedium,
                color = FitWizColors.TextPrimary
            )
            Text(
                text = "Sync from phone",
                style = FitWizTypography.bodySmall,
                color = FitWizColors.TextMuted,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = onCreateSample,
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = FitWizColors.Primary
                )
            ) {
                Text("Demo", style = FitWizTypography.labelMedium)
            }
        }
    }
}

@Composable
private fun WorkoutContent(
    workout: WearWorkout,
    listState: androidx.wear.compose.foundation.lazy.ScalingLazyListState,
    onStartWorkout: () -> Unit
) {
    ScalingLazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        contentPadding = PaddingValues(
            top = 32.dp,
            bottom = 16.dp,
            start = 8.dp,
            end = 8.dp
        )
    ) {
        // Header
        item {
            WorkoutHeader(workout)
            Spacer(modifier = Modifier.height(12.dp))
        }

        // Start Button
        item {
            Button(
                onClick = onStartWorkout,
                modifier = Modifier
                    .fillMaxWidth(0.85f)
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = FitWizColors.Success
                )
            ) {
                Text(
                    text = "START WORKOUT",
                    style = FitWizTypography.labelLarge
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        // Exercises List
        item {
            Text(
                text = "EXERCISES",
                style = FitWizTypography.labelSmall,
                color = FitWizColors.TextMuted,
                modifier = Modifier.padding(start = 8.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
        }

        items(workout.exercises) { exercise ->
            ExercisePreviewCard(exercise)
            Spacer(modifier = Modifier.height(4.dp))
        }
    }
}

@Composable
private fun WorkoutHeader(workout: WearWorkout) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "Workout",
            style = FitWizTypography.displayMedium
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = workout.name,
            style = FitWizTypography.titleLarge,
            color = FitWizColors.TextPrimary,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Spacer(modifier = Modifier.height(4.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Duration
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "Time",
                    style = FitWizTypography.bodySmall,
                    color = FitWizColors.TextMuted
                )
                Spacer(modifier = Modifier.width(2.dp))
                Text(
                    text = "${workout.estimatedDuration} min",
                    style = FitWizTypography.bodySmall,
                    color = FitWizColors.TextSecondary
                )
            }
            // Exercises count
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "${workout.exercises.size} exercises",
                    style = FitWizTypography.bodySmall,
                    color = FitWizColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun ExercisePreviewCard(exercise: WearExercise) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(FitWizColors.Surface)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Order number
        Box(
            modifier = Modifier
                .size(24.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(FitWizColors.Primary.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "${exercise.orderIndex + 1}",
                style = FitWizTypography.labelSmall,
                color = FitWizColors.Primary
            )
        }

        Spacer(modifier = Modifier.width(8.dp))

        // Exercise info
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = exercise.name,
                style = FitWizTypography.bodyMedium,
                color = FitWizColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${exercise.sets}x${exercise.targetReps}" +
                        (exercise.suggestedWeight?.let { " @ ${it.toInt()}kg" } ?: ""),
                style = FitWizTypography.bodySmall,
                color = FitWizColors.TextMuted
            )
        }
    }
}
