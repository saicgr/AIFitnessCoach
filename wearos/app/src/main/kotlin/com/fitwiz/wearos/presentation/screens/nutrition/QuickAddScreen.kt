package com.fitwiz.wearos.presentation.screens.nutrition

import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.*
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.NutritionViewModel

/**
 * Quick Add Screen - Just enter calories
 */
@Composable
fun QuickAddScreen(
    viewModel: NutritionViewModel = hiltViewModel(),
    onConfirm: () -> Unit,
    onBack: () -> Unit
) {
    var calories by remember { mutableIntStateOf(200) }
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
                .padding(16.dp)
                .onRotaryScrollEvent { event ->
                    val delta = event.verticalScrollPixels
                    val increment = if (kotlin.math.abs(delta) > 50) 50 else 10
                    calories = (calories + if (delta > 0) increment else -increment).coerceIn(1, 9999)
                    true
                }
                .focusRequester(focusRequester)
                .focusable(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header
            Text(
                text = "QUICK ADD",
                style = FitWizTypography.titleMedium,
                color = FitWizColors.Nutrition
            )

            // Calorie input
            Column(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .background(FitWizColors.Surface)
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Button(
                        onClick = { calories = (calories - 50).coerceAtLeast(1) },
                        modifier = Modifier.size(40.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Surface
                        )
                    ) {
                        Text("-", style = FitWizTypography.titleLarge)
                    }

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    ) {
                        Text(
                            text = "$calories",
                            style = FitWizTypography.displayMedium,
                            color = FitWizColors.Nutrition
                        )
                        Text(
                            text = "calories",
                            style = FitWizTypography.bodySmall,
                            color = FitWizColors.TextMuted
                        )
                    }

                    Button(
                        onClick = { calories = (calories + 50).coerceAtMost(9999) },
                        modifier = Modifier.size(40.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Surface
                        )
                    ) {
                        Text("+", style = FitWizTypography.titleLarge)
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Quick preset buttons
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    QuickPresetButton(value = 100, onClick = { calories = 100 })
                    QuickPresetButton(value = 200, onClick = { calories = 200 })
                    QuickPresetButton(value = 300, onClick = { calories = 300 })
                    QuickPresetButton(value = 500, onClick = { calories = 500 })
                }
            }

            Text(
                text = "Use crown to adjust",
                style = FitWizTypography.labelSmall,
                color = FitWizColors.TextMuted
            )

            // Log button
            Button(
                onClick = {
                    viewModel.quickAddCalories(calories)
                    onConfirm()
                },
                modifier = Modifier
                    .fillMaxWidth(0.85f)
                    .height(44.dp),
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = FitWizColors.Success
                )
            ) {
                Text("LOG $calories cal", style = FitWizTypography.labelLarge)
            }
        }
    }
}

@Composable
private fun QuickPresetButton(
    value: Int,
    onClick: () -> Unit
) {
    CompactButton(
        onClick = onClick,
        colors = ButtonDefaults.secondaryButtonColors()
    ) {
        Text(
            text = "$value",
            style = FitWizTypography.labelSmall
        )
    }
}
