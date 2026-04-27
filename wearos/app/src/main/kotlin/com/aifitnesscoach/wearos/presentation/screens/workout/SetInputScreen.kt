package com.fitwiz.wearos.presentation.screens.workout

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.*
import com.fitwiz.wearos.data.models.WearExercise
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.WorkoutViewModel

/**
 * Set Input Screen - Adjust reps and weight before logging
 */
@Composable
fun SetInputScreen(
    viewModel: WorkoutViewModel = hiltViewModel(),
    onConfirm: () -> Unit,
    onStartRest: () -> Unit,
    onBack: () -> Unit
) {
    val exercise = viewModel.getCurrentExercise()
    val completedSets = viewModel.getCompletedSetsForCurrentExercise()

    if (exercise == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text("No exercise", color = FitWizColors.TextMuted)
        }
        return
    }

    var reps by remember { mutableIntStateOf(exercise.targetReps) }
    var weight by remember { mutableFloatStateOf(exercise.suggestedWeight ?: 0f) }
    var focusOnReps by remember { mutableStateOf(true) }

    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp)
                .onRotaryScrollEvent { event ->
                    val delta = event.verticalScrollPixels
                    if (focusOnReps) {
                        reps = (reps + if (delta > 0) 1 else -1).coerceIn(1, 99)
                    } else {
                        weight = (weight + if (delta > 0) 2.5f else -2.5f).coerceIn(0f, 500f)
                    }
                    true
                }
                .focusRequester(focusRequester)
                .focusable(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = exercise.name,
                    style = FitWizTypography.titleSmall,
                    color = FitWizColors.TextPrimary,
                    textAlign = TextAlign.Center,
                    maxLines = 1
                )
                Text(
                    text = "Set ${completedSets + 1} of ${exercise.sets}",
                    style = FitWizTypography.labelSmall,
                    color = FitWizColors.TextMuted
                )
            }

            // Input fields
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Reps input
                InputCard(
                    label = "REPS",
                    value = reps.toString(),
                    isSelected = focusOnReps,
                    onTap = { focusOnReps = true },
                    onIncrement = { reps = (reps + 1).coerceAtMost(99) },
                    onDecrement = { reps = (reps - 1).coerceAtLeast(1) }
                )

                // Weight input
                if (exercise.suggestedWeight != null) {
                    InputCard(
                        label = "KG",
                        value = weight.toString(),
                        isSelected = !focusOnReps,
                        onTap = { focusOnReps = false },
                        onIncrement = { weight = (weight + 2.5f).coerceAtMost(500f) },
                        onDecrement = { weight = (weight - 2.5f).coerceAtLeast(0f) }
                    )
                }
            }

            // Confirm button
            Button(
                onClick = {
                    viewModel.logSet(reps, if (exercise.suggestedWeight != null) weight else null)
                    onStartRest()
                },
                modifier = Modifier
                    .fillMaxWidth(0.9f)
                    .height(44.dp),
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = FitWizColors.Success
                )
            ) {
                Text("LOG SET", style = FitWizTypography.labelLarge)
            }
        }
    }
}

@Composable
private fun InputCard(
    label: String,
    value: String,
    isSelected: Boolean,
    onTap: () -> Unit,
    onIncrement: () -> Unit,
    onDecrement: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth(0.95f)
            .clip(RoundedCornerShape(12.dp))
            .background(
                if (isSelected) FitWizColors.Primary.copy(alpha = 0.2f)
                else FitWizColors.Surface
            )
            .clickable(onClick = onTap)
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Decrement button
        Button(
            onClick = onDecrement,
            modifier = Modifier.size(36.dp),
            colors = ButtonDefaults.buttonColors(
                backgroundColor = FitWizColors.Surface
            )
        ) {
            Text("-", style = FitWizTypography.titleMedium, color = FitWizColors.TextPrimary)
        }

        // Value display
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 8.dp)
        ) {
            Text(
                text = value,
                style = FitWizTypography.displaySmall,
                color = if (isSelected) FitWizColors.Primary else FitWizColors.TextPrimary
            )
            Text(
                text = label,
                style = FitWizTypography.labelSmall,
                color = FitWizColors.TextMuted
            )
        }

        // Increment button
        Button(
            onClick = onIncrement,
            modifier = Modifier.size(36.dp),
            colors = ButtonDefaults.buttonColors(
                backgroundColor = FitWizColors.Surface
            )
        ) {
            Text("+", style = FitWizTypography.titleMedium, color = FitWizColors.TextPrimary)
        }
    }
}
