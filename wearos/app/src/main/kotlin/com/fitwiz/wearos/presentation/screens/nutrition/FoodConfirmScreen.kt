package com.fitwiz.wearos.presentation.screens.nutrition

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.*
import com.fitwiz.wearos.data.models.MealType
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.NutritionViewModel

/**
 * Food Confirmation Screen - Confirm/edit parsed food entry
 */
@Composable
fun FoodConfirmScreen(
    viewModel: NutritionViewModel = hiltViewModel(),
    onConfirm: () -> Unit,
    onRedo: () -> Unit
) {
    val pendingEntry by viewModel.pendingEntry.collectAsState()
    val parseResult by viewModel.parseResult.collectAsState()

    val entry = pendingEntry

    if (entry == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text("No food to confirm", color = FitWizColors.TextMuted)
        }
        return
    }

    var calories by remember(entry) { mutableIntStateOf(entry.calories) }
    var mealType by remember(entry) { mutableStateOf(entry.mealType) }

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
                    calories = (calories + if (delta > 0) 10 else -10).coerceIn(1, 9999)
                    viewModel.updatePendingEntry(calories = calories)
                    true
                }
                .focusRequester(focusRequester)
                .focusable(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header
            Text(
                text = "CONFIRM",
                style = FitWizTypography.titleSmall,
                color = FitWizColors.Nutrition
            )

            // Food info card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(FitWizColors.Surface)
                    .padding(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Food name
                Text(
                    text = entry.foodName ?: "Food",
                    style = FitWizTypography.titleMedium,
                    color = FitWizColors.TextPrimary,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Calories (editable)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Button(
                        onClick = {
                            calories = (calories - 50).coerceAtLeast(1)
                            viewModel.updatePendingEntry(calories = calories)
                        },
                        modifier = Modifier.size(32.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Surface
                        )
                    ) {
                        Text("-", style = FitWizTypography.titleMedium)
                    }

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    ) {
                        Text(
                            text = "$calories",
                            style = FitWizTypography.displaySmall,
                            color = FitWizColors.Nutrition
                        )
                        Text(
                            text = "cal",
                            style = FitWizTypography.labelSmall,
                            color = FitWizColors.TextMuted
                        )
                    }

                    Button(
                        onClick = {
                            calories = (calories + 50).coerceAtMost(9999)
                            viewModel.updatePendingEntry(calories = calories)
                        },
                        modifier = Modifier.size(32.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = FitWizColors.Surface
                        )
                    ) {
                        Text("+", style = FitWizTypography.titleMedium)
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Meal type
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    MealType.entries.forEach { type ->
                        MealTypeChip(
                            mealType = type,
                            isSelected = mealType == type,
                            onClick = {
                                mealType = type
                                viewModel.updatePendingEntry(mealType = type)
                            }
                        )
                    }
                }
            }

            // Confidence indicator
            parseResult?.let { result ->
                val confidence = result.entry.parseConfidence ?: 0f
                if (confidence < 0.8f) {
                    Text(
                        text = "Please verify",
                        style = FitWizTypography.labelSmall,
                        color = FitWizColors.Warning
                    )
                }
            }

            // Action buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = {
                        viewModel.cancelPendingEntry()
                        onRedo()
                    },
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = FitWizColors.Surface
                    )
                ) {
                    Text("REDO", style = FitWizTypography.labelMedium)
                }

                Button(
                    onClick = {
                        viewModel.confirmAndLog()
                        onConfirm()
                    },
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = FitWizColors.Success
                    )
                ) {
                    Text("LOG", style = FitWizTypography.labelMedium)
                }
            }
        }
    }
}

@Composable
private fun MealTypeChip(
    mealType: MealType,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val label = when (mealType) {
        MealType.BREAKFAST -> "AM"
        MealType.LUNCH -> "MD"
        MealType.DINNER -> "PM"
        MealType.SNACK -> "SN"
    }

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(
                if (isSelected) FitWizColors.Nutrition.copy(alpha = 0.3f)
                else FitWizColors.Surface
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 6.dp, vertical = 4.dp)
    ) {
        Text(
            text = label,
            style = FitWizTypography.bodySmall,
            color = if (isSelected) FitWizColors.Nutrition else FitWizColors.TextMuted
        )
    }
}
