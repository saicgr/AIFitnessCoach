package com.aifitnesscoach.wearos.presentation.screens.workout

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.*
import com.aifitnesscoach.wearos.presentation.theme.AppColors
import com.aifitnesscoach.wearos.presentation.theme.AppTypography
import com.aifitnesscoach.wearos.presentation.viewmodel.WorkoutViewModel

/**
 * Workout Summary Screen - Shows completed workout stats
 */
@Composable
fun WorkoutSummaryScreen(
    viewModel: WorkoutViewModel = hiltViewModel(),
    onDone: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val activeSession by viewModel.activeSession.collectAsState()
    val setLogs by viewModel.setLogs.collectAsState()
    val workoutMetrics by viewModel.workoutMetrics.collectAsState()

    val listState = rememberScalingLazyListState()

    // Calculate stats
    val totalSets = setLogs.size
    val totalReps = setLogs.sumOf { it.actualReps }
    val totalVolume = setLogs.sumOf { (it.actualReps * (it.weightKg ?: 0f)).toDouble() }.toFloat()
    val duration = activeSession?.let {
        val durationMs = (it.endedAt ?: System.currentTimeMillis()) - it.startedAt
        durationMs / 1000 / 60 // minutes
    } ?: 0

    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) }
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
            // Celebration header
            item {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "WORKOUT",
                        style = AppTypography.titleMedium,
                        color = AppColors.TextPrimary
                    )
                    Text(
                        text = "COMPLETE!",
                        style = AppTypography.titleLarge,
                        color = AppColors.Success
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Stats card
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(AppColors.Surface)
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Duration
                    StatRow(
                        icon = "Time",
                        label = "Duration",
                        value = "${duration}:00"
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Calories (if available)
                    workoutMetrics.caloriesBurned.takeIf { it > 0 }?.let { calories ->
                        StatRow(
                            icon = "Cal",
                            label = "Calories",
                            value = "$calories cal"
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }

                    // Total volume
                    StatRow(
                        icon = "Vol",
                        label = "Volume",
                        value = "${totalVolume.toInt()} kg"
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Sets & Reps
                    StatRow(
                        icon = "Sets",
                        label = "Sets/Reps",
                        value = "$totalSets sets / $totalReps reps"
                    )

                    // Heart rate stats (if available)
                    workoutMetrics.avgHeartRate?.let { avgHr ->
                        Spacer(modifier = Modifier.height(8.dp))
                        StatRow(
                            icon = "HR",
                            label = "Avg HR",
                            value = "$avgHr bpm"
                        )
                    }

                    workoutMetrics.maxHeartRate?.let { maxHr ->
                        Spacer(modifier = Modifier.height(4.dp))
                        StatRow(
                            icon = "Max",
                            label = "Max HR",
                            value = "$maxHr bpm"
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Sync status
            item {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "o",
                        style = AppTypography.bodySmall,
                        color = AppColors.Success
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Syncing to phone...",
                        style = AppTypography.bodySmall,
                        color = AppColors.TextMuted
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Done button
            item {
                Button(
                    onClick = {
                        viewModel.resetCompletedState()
                        onDone()
                    },
                    modifier = Modifier
                        .fillMaxWidth(0.85f)
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AppColors.Success
                    )
                ) {
                    Text("DONE", style = AppTypography.labelLarge)
                }
            }
        }
    }
}

@Composable
private fun StatRow(
    icon: String,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = icon,
                style = AppTypography.bodyMedium,
                color = AppColors.Primary
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = label,
                style = AppTypography.bodyMedium,
                color = AppColors.TextMuted
            )
        }
        Text(
            text = value,
            style = AppTypography.bodyMedium,
            color = AppColors.TextPrimary
        )
    }
}
