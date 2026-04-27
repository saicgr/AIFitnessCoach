package com.fitwiz.wearos.presentation.screens.workout

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.*
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.WorkoutViewModel
import kotlinx.coroutines.delay

/**
 * Rest Timer Screen - Countdown between sets with haptic feedback
 */
@Composable
fun RestTimerScreen(
    viewModel: WorkoutViewModel = hiltViewModel(),
    onTimerComplete: () -> Unit,
    onSkip: () -> Unit
) {
    val exercise = viewModel.getCurrentExercise()
    val context = LocalContext.current

    val initialTime = exercise?.restSeconds ?: 60
    var remainingSeconds by remember { mutableIntStateOf(initialTime) }
    val progress by remember(remainingSeconds) {
        derivedStateOf { remainingSeconds.toFloat() / initialTime }
    }

    // Haptic feedback
    LaunchedEffect(remainingSeconds) {
        when (remainingSeconds) {
            10, 5 -> vibrateGently(context)
            3, 2, 1 -> vibrateStrong(context)
            0 -> {
                vibrateDouble(context)
                delay(500)
                onTimerComplete()
            }
        }
    }

    // Countdown timer
    LaunchedEffect(Unit) {
        while (remainingSeconds > 0) {
            delay(1000)
            remainingSeconds--
        }
    }

    // Pulsing animation for last 5 seconds
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (remainingSeconds <= 5) 1.1f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) }
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
                text = "REST",
                style = FitWizTypography.titleMedium,
                color = FitWizColors.Warning
            )

            // Timer display
            Box(
                modifier = Modifier
                    .size((120 * pulseScale).dp),
                contentAlignment = Alignment.Center
            ) {
                // Progress ring
                CircularProgressIndicator(
                    progress = progress,
                    modifier = Modifier.fillMaxSize(),
                    indicatorColor = if (remainingSeconds <= 5) FitWizColors.HeartRate else FitWizColors.Warning,
                    trackColor = FitWizColors.ProgressBackground,
                    strokeWidth = 8.dp
                )

                // Time display
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    val minutes = remainingSeconds / 60
                    val seconds = remainingSeconds % 60
                    Text(
                        text = "%d:%02d".format(minutes, seconds),
                        style = FitWizTypography.displayLarge,
                        color = if (remainingSeconds <= 5) FitWizColors.HeartRate else FitWizColors.TextPrimary
                    )
                }
            }

            // Next exercise preview
            exercise?.let { ex ->
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Next:",
                        style = FitWizTypography.labelSmall,
                        color = FitWizColors.TextMuted
                    )
                    Text(
                        text = if (viewModel.getCompletedSetsForCurrentExercise() < ex.sets) {
                            "${ex.name} - Set ${viewModel.getCompletedSetsForCurrentExercise() + 1}"
                        } else {
                            "Next exercise"
                        },
                        style = FitWizTypography.bodySmall,
                        color = FitWizColors.TextSecondary,
                        textAlign = TextAlign.Center,
                        maxLines = 1
                    )
                }
            }

            // Action buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Skip button
                Button(
                    onClick = onSkip,
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = FitWizColors.Surface
                    )
                ) {
                    Text("SKIP", style = FitWizTypography.labelMedium)
                }

                // Add time button
                Button(
                    onClick = { remainingSeconds += 30 },
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = FitWizColors.Warning.copy(alpha = 0.3f)
                    )
                ) {
                    Text("+30s", style = FitWizTypography.labelMedium)
                }
            }
        }
    }
}

private fun vibrateGently(context: Context) {
    val vibrator = getVibrator(context) ?: return
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        vibrator.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(50)
    }
}

private fun vibrateStrong(context: Context) {
    val vibrator = getVibrator(context) ?: return
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        vibrator.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(100)
    }
}

private fun vibrateDouble(context: Context) {
    val vibrator = getVibrator(context) ?: return
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        vibrator.vibrate(
            VibrationEffect.createWaveform(
                longArrayOf(0, 100, 100, 100),
                -1
            )
        )
    } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(longArrayOf(0, 100, 100, 100), -1)
    }
}

private fun getVibrator(context: Context): Vibrator? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
        vibratorManager?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }
}
