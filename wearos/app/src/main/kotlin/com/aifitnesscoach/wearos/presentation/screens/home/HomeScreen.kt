package com.aifitnesscoach.wearos.presentation.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.*
import com.aifitnesscoach.wearos.presentation.theme.AppColors
import com.aifitnesscoach.wearos.presentation.theme.AppTheme
import com.aifitnesscoach.wearos.presentation.theme.AppTypography
import com.aifitnesscoach.wearos.presentation.viewmodel.HomeViewModel
import java.text.NumberFormat
import java.util.Locale

/**
 * Home Screen with 2x2 Quick Action Grid
 * Shows: Workout, Food, Fasting, Water buttons
 * Plus stats for calories burned, macros, etc.
 */
@Composable
fun HomeScreen(
    viewModel: HomeViewModel = hiltViewModel(),
    onWorkoutClick: () -> Unit,
    onFoodClick: () -> Unit,
    onFastingClick: () -> Unit,
    onWaterClick: () -> Unit
) {
    val listState = rememberScalingLazyListState()
    val screenWidth = LocalConfiguration.current.screenWidthDp
    val uiState by viewModel.uiState.collectAsState()

    var showWaterDialog by remember { mutableStateOf(false) }
    val numberFormat = remember { NumberFormat.getNumberInstance(Locale.US) }

    // Responsive sizing
    val cardSize = when {
        screenWidth < 200 -> 70.dp
        screenWidth < 240 -> 80.dp
        else -> 90.dp
    }

    val spacing = when {
        screenWidth < 200 -> 4.dp
        screenWidth < 240 -> 6.dp
        else -> 8.dp
    }

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
            // Quick Stats Bar
            item {
                QuickStatsBar(
                    caloriesBurned = uiState.caloriesBurned,
                    waterCups = uiState.waterCups,
                    waterGoal = uiState.waterGoal,
                    steps = uiState.steps,
                    heartRate = uiState.currentHeartRate
                )
                Spacer(modifier = Modifier.height(spacing))
            }

            // 2x2 Quick Action Grid
            item {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(spacing)
                ) {
                    // Top row: Workout + Food
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(spacing)
                    ) {
                        QuickActionCard(
                            icon = "\uD83C\uDFCB\uFE0F",  // Weight lifter emoji
                            label = "WORKOUT",
                            value = uiState.todaysWorkoutName ?: "Start",
                            color = AppColors.Workout,
                            size = cardSize,
                            onClick = onWorkoutClick
                        )
                        QuickActionCard(
                            icon = "\uD83E\uDD57",  // Salad emoji
                            label = "FOOD",
                            value = "${numberFormat.format(uiState.caloriesConsumed)}cal",
                            color = AppColors.Nutrition,
                            size = cardSize,
                            onClick = onFoodClick
                        )
                    }

                    // Bottom row: Fasting + Water
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(spacing)
                    ) {
                        QuickActionCard(
                            icon = "\u23F0",  // Alarm clock emoji
                            label = "FASTING",
                            value = "16:8",
                            color = AppColors.Fasting,
                            size = cardSize,
                            onClick = onFastingClick
                        )
                        QuickActionCard(
                            icon = "\uD83D\uDCA7",  // Water drop emoji
                            label = "WATER",
                            value = "${uiState.waterCups} cups",
                            color = AppColors.Water,
                            size = cardSize,
                            onClick = { showWaterDialog = true }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(spacing))
            }

            // Macros Summary Bar
            item {
                MacrosSummaryBar(
                    protein = uiState.proteinG,
                    carbs = uiState.carbsG,
                    fat = uiState.fatG
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Detailed Stats Section (scrolled down)
            item {
                DetailedStatsCard(
                    caloriesConsumed = uiState.caloriesConsumed,
                    caloriesGoal = uiState.caloriesGoalNutrition,
                    caloriesBurned = uiState.caloriesBurned,
                    steps = uiState.steps,
                    heartRate = uiState.currentHeartRate
                )
            }
        }
    }

    // Water Dialog
    if (showWaterDialog) {
        WaterLogDialog(
            currentCups = uiState.waterCups,
            goalCups = uiState.waterGoal,
            onDismiss = { showWaterDialog = false },
            onUpdate = { newCups ->
                viewModel.logWater(newCups)
                showWaterDialog = false
            }
        )
    }
}

@Composable
private fun QuickStatsBar(
    caloriesBurned: Int,
    waterCups: Int,
    waterGoal: Int,
    steps: Int,
    heartRate: Int?
) {
    val numberFormat = remember { NumberFormat.getNumberInstance(Locale.US) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        // Steps
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "\uD83D\uDC5F",  // Shoe emoji
                style = AppTypography.bodySmall
            )
            Spacer(modifier = Modifier.width(2.dp))
            Text(
                text = numberFormat.format(steps),
                style = AppTypography.bodySmall,
                color = AppColors.TextSecondary
            )
        }

        // Heart rate
        heartRate?.let { hr ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "\u2764\uFE0F",  // Heart emoji
                    style = AppTypography.bodySmall
                )
                Spacer(modifier = Modifier.width(2.dp))
                Text(
                    text = "$hr",
                    style = AppTypography.bodySmall,
                    color = AppColors.HeartRate
                )
            }
        }

        // Calories burned
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "\uD83D\uDD25",  // Fire emoji
                style = AppTypography.bodySmall
            )
            Spacer(modifier = Modifier.width(2.dp))
            Text(
                text = "$caloriesBurned",
                style = AppTypography.bodySmall,
                color = AppColors.TextSecondary
            )
        }
    }
}

@Composable
private fun QuickActionCard(
    icon: String,
    label: String,
    value: String,
    color: Color,
    size: androidx.compose.ui.unit.Dp,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(RoundedCornerShape(16.dp))
            .background(color.copy(alpha = 0.2f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = icon,
                style = AppTypography.displaySmall
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = label,
                style = AppTypography.labelSmall,
                color = color,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = value,
                style = AppTypography.bodySmall,
                color = AppColors.TextSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun MacrosSummaryBar(
    protein: Int,
    carbs: Int,
    fat: Int
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        MacroChip(label = "P", value = "${protein}g", color = AppColors.HeartRate)
        MacroChip(label = "C", value = "${carbs}g", color = AppColors.Warning)
        MacroChip(label = "F", value = "${fat}g", color = AppColors.Secondary)
    }
}

@Composable
private fun MacroChip(
    label: String,
    value: String,
    color: Color
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(AppColors.Surface)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = AppTypography.labelSmall,
            color = color
        )
        Text(
            text = ":",
            style = AppTypography.labelSmall,
            color = AppColors.TextMuted
        )
        Text(
            text = value,
            style = AppTypography.labelSmall,
            color = AppColors.TextSecondary
        )
    }
}

@Composable
private fun DetailedStatsCard(
    caloriesConsumed: Int,
    caloriesGoal: Int,
    caloriesBurned: Int,
    steps: Int,
    heartRate: Int?
) {
    val numberFormat = remember { NumberFormat.getNumberInstance(Locale.US) }
    val nutritionProgress = (caloriesConsumed.toFloat() / caloriesGoal).coerceIn(0f, 1f)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AppColors.Surface)
            .padding(16.dp)
    ) {
        Text(
            text = "TODAY'S STATS",
            style = AppTypography.labelMedium,
            color = AppColors.TextMuted
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Nutrition progress
        Text(
            text = "NUTRITION",
            style = AppTypography.labelSmall,
            color = AppColors.Nutrition
        )

        // Use a simple progress bar via Box since LinearProgressIndicator may differ
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .padding(vertical = 4.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(AppColors.ProgressBackground)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(nutritionProgress)
                    .fillMaxHeight()
                    .background(AppColors.Nutrition)
            )
        }

        Text(
            text = "${numberFormat.format(caloriesConsumed)} / ${numberFormat.format(caloriesGoal)} cal",
            style = AppTypography.bodySmall,
            color = AppColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Activity stats
        Text(
            text = "ACTIVITY",
            style = AppTypography.labelSmall,
            color = AppColors.Workout
        )

        Spacer(modifier = Modifier.height(4.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            StatItem(icon = "\uD83D\uDD25", label = "$caloriesBurned cal")
            StatItem(icon = "\uD83D\uDC5F", label = "${numberFormat.format(steps)} steps")
        }

        // Heart rate if available
        heartRate?.let { hr ->
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                StatItem(icon = "\u2764\uFE0F", label = "$hr bpm")
            }
        }
    }
}

@Composable
private fun StatItem(icon: String, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(text = icon, style = AppTypography.bodySmall)
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = label,
            style = AppTypography.bodySmall,
            color = AppColors.TextSecondary
        )
    }
}

@Composable
private fun WaterLogDialog(
    currentCups: Int,
    goalCups: Int,
    onDismiss: () -> Unit,
    onUpdate: (Int) -> Unit
) {
    var cups by remember { mutableIntStateOf(currentCups) }

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
                    text = "\uD83D\uDCA7 WATER",
                    style = AppTypography.titleMedium,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "$cups/$goalCups",
                    style = AppTypography.displayMedium,
                    color = AppColors.Water
                )
                Text(
                    text = "cups",
                    style = AppTypography.bodyMedium,
                    color = AppColors.TextMuted
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Quick adjust buttons
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = { if (cups > 0) cups-- },
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = AppColors.Surface
                        )
                    ) {
                        Text("-1")
                    }
                    Button(
                        onClick = { cups++ },
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = AppColors.Water
                        )
                    ) {
                        Text("+1")
                    }
                    Button(
                        onClick = { cups += 2 },
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = AppColors.Water.copy(alpha = 0.7f)
                        )
                    ) {
                        Text("+2")
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = { onUpdate(cups) },
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AppColors.Success
                    )
                ) {
                    Text("\u2713 Done")
                }
            }
        }
}
