package com.aifitnesscoach.wearos.presentation.screens.fasting

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import com.aifitnesscoach.wearos.data.models.FastingProtocol
import com.aifitnesscoach.wearos.data.models.FastingStatus
import com.aifitnesscoach.wearos.presentation.theme.AppColors
import com.aifitnesscoach.wearos.presentation.theme.AppTypography
import com.aifitnesscoach.wearos.presentation.viewmodel.FastingViewModel

/**
 * Fasting Screen - Shows current fast status or start options
 */
@Composable
fun FastingScreen(
    viewModel: FastingViewModel = hiltViewModel(),
    onBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val activeSession by viewModel.activeSession.collectAsState()
    val streak by viewModel.fastingStreak.collectAsState()
    val history by viewModel.fastingHistory.collectAsState()

    val listState = rememberScalingLazyListState()

    // Show completion dialog
    if (uiState.showCompletion) {
        FastingCompletionDialog(
            onDismiss = { viewModel.dismissCompletion() }
        )
        return
    }

    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) }
    ) {
        // If there's an active or paused fast, show the timer
        if (activeSession != null && activeSession?.status in listOf(FastingStatus.ACTIVE, FastingStatus.PAUSED)) {
            ActiveFastContent(
                session = activeSession!!,
                isPaused = uiState.isPaused,
                onPause = { viewModel.pauseFast() },
                onResume = { viewModel.resumeFast() },
                onEnd = { viewModel.endFast(completed = false) }
            )
        } else {
            // Show start fast options
            StartFastContent(
                listState = listState,
                streak = streak,
                history = history,
                selectedProtocol = uiState.selectedProtocol,
                onSelectProtocol = { viewModel.selectProtocol(it) },
                onStartFast = { viewModel.startFast(uiState.selectedProtocol) }
            )
        }
    }
}

@Composable
private fun ActiveFastContent(
    session: com.aifitnesscoach.wearos.data.models.WearFastingSession,
    isPaused: Boolean,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onEnd: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Header
        Text(
            text = "FASTING",
            style = AppTypography.titleMedium,
            color = AppColors.Fasting
        )

        // Timer display
        Box(
            modifier = Modifier.size(140.dp),
            contentAlignment = Alignment.Center
        ) {
            // Progress arc
            CircularProgressIndicator(
                progress = session.progress,
                modifier = Modifier.fillMaxSize(),
                indicatorColor = if (isPaused) AppColors.Warning else AppColors.Fasting,
                trackColor = AppColors.ProgressBackground,
                strokeWidth = 10.dp
            )

            // Time display
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = session.elapsedFormatted,
                    style = AppTypography.displayMedium,
                    color = AppColors.TextPrimary
                )
                Text(
                    text = if (isPaused) "PAUSED" else "ELAPSED",
                    style = AppTypography.labelSmall,
                    color = if (isPaused) AppColors.Warning else AppColors.TextMuted
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "${session.remainingFormatted} left",
                    style = AppTypography.bodySmall,
                    color = AppColors.TextSecondary
                )
                Text(
                    text = "${session.protocol.displayName} goal",
                    style = AppTypography.labelSmall,
                    color = AppColors.TextMuted
                )
            }
        }

        // Action buttons
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (isPaused) {
                Button(
                    onClick = onResume,
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AppColors.Success
                    )
                ) {
                    Text("RESUME", style = AppTypography.labelMedium)
                }
            } else {
                Button(
                    onClick = onPause,
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AppColors.Warning
                    )
                ) {
                    Text("PAUSE", style = AppTypography.labelMedium)
                }
            }

            Button(
                onClick = onEnd,
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = AppColors.HeartRate
                )
            ) {
                Text("END", style = AppTypography.labelMedium)
            }
        }
    }
}

@Composable
private fun StartFastContent(
    listState: androidx.wear.compose.foundation.lazy.ScalingLazyListState,
    streak: com.aifitnesscoach.wearos.data.models.WearFastingStreak,
    history: List<com.aifitnesscoach.wearos.data.repository.FastingHistoryEntry>,
    selectedProtocol: FastingProtocol,
    onSelectProtocol: (FastingProtocol) -> Unit,
    onStartFast: () -> Unit
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
            Text(
                text = "FASTING",
                style = AppTypography.titleMedium,
                color = AppColors.Fasting
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        // Protocol selection
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(AppColors.Surface)
                    .padding(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = selectedProtocol.displayName,
                    style = AppTypography.displaySmall,
                    color = AppColors.Fasting
                )
                Text(
                    text = "PROTOCOL",
                    style = AppTypography.labelSmall,
                    color = AppColors.TextMuted
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Protocol chips
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    listOf(
                        FastingProtocol.SIXTEEN_EIGHT,
                        FastingProtocol.EIGHTEEN_SIX,
                        FastingProtocol.TWENTY_FOUR
                    ).forEach { protocol ->
                        ProtocolChip(
                            protocol = protocol,
                            isSelected = selectedProtocol == protocol,
                            onClick = { onSelectProtocol(protocol) }
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        // Start button
        item {
            Button(
                onClick = onStartFast,
                modifier = Modifier
                    .fillMaxWidth(0.85f)
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = AppColors.Success
                )
            ) {
                Text("START FAST", style = AppTypography.labelLarge)
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Streak info
        if (streak.currentStreak > 0 || streak.totalFastsCompleted > 0) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    StreakItem(
                        label = "Streak",
                        value = "${streak.currentStreak}",
                        icon = "Fire"
                    )
                    StreakItem(
                        label = "Total",
                        value = "${streak.totalFastsCompleted}",
                        icon = "Done"
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
            }
        }

        // Recent history
        if (history.isNotEmpty()) {
            item {
                Text(
                    text = "RECENT",
                    style = AppTypography.labelSmall,
                    color = AppColors.TextMuted
                )
                Spacer(modifier = Modifier.height(4.dp))
            }

            history.take(3).forEach { entry ->
                item {
                    HistoryItem(entry)
                    Spacer(modifier = Modifier.height(2.dp))
                }
            }
        }
    }
}

@Composable
private fun ProtocolChip(
    protocol: FastingProtocol,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(
                if (isSelected) AppColors.Fasting.copy(alpha = 0.3f)
                else AppColors.Surface
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = protocol.displayName,
            style = AppTypography.labelSmall,
            color = if (isSelected) AppColors.Fasting else AppColors.TextMuted
        )
    }
}

@Composable
private fun StreakItem(
    label: String,
    value: String,
    icon: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = icon, style = AppTypography.bodyMedium, color = AppColors.Fasting)
        Text(
            text = value,
            style = AppTypography.titleMedium,
            color = AppColors.TextPrimary
        )
        Text(
            text = label,
            style = AppTypography.labelSmall,
            color = AppColors.TextMuted
        )
    }
}

@Composable
private fun HistoryItem(entry: com.aifitnesscoach.wearos.data.repository.FastingHistoryEntry) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(AppColors.Surface)
            .padding(8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = entry.formattedDate,
            style = AppTypography.bodySmall,
            color = AppColors.TextMuted
        )
        Text(
            text = entry.formattedDuration,
            style = AppTypography.bodySmall,
            color = AppColors.TextSecondary
        )
        Text(
            text = if (entry.wasCompleted) "OK" else "X",
            style = AppTypography.bodySmall,
            color = if (entry.wasCompleted) AppColors.Success else AppColors.HeartRate
        )
    }
}

@Composable
private fun FastingCompletionDialog(
    onDismiss: () -> Unit
) {
    // Use a simple overlay as Wear Material Dialog API varies
    Box(
            modifier = Modifier
                .fillMaxSize()
                .background(AppColors.Background)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "FAST COMPLETE!",
                    style = AppTypography.titleMedium,
                    color = AppColors.Success,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "Great job! You've completed your fasting goal.",
                    style = AppTypography.bodySmall,
                    color = AppColors.TextSecondary,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = onDismiss,
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AppColors.Success
                    )
                ) {
                    Text("Done")
                }
            }
        }
}
