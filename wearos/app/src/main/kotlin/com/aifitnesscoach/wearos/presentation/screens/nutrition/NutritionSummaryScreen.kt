package com.aifitnesscoach.wearos.presentation.screens.nutrition

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.*
import com.aifitnesscoach.wearos.data.models.MealType
import com.aifitnesscoach.wearos.data.models.WearFoodEntry
import com.aifitnesscoach.wearos.presentation.theme.AppColors
import com.aifitnesscoach.wearos.presentation.theme.AppTypography
import com.aifitnesscoach.wearos.presentation.viewmodel.NutritionViewModel

/**
 * Nutrition Summary Screen - Daily calorie and macro totals
 */
@Composable
fun NutritionSummaryScreen(
    viewModel: NutritionViewModel = hiltViewModel(),
    onAddFood: () -> Unit,
    onBack: () -> Unit
) {
    val summary by viewModel.nutritionSummary.collectAsState()
    val listState = rememberScalingLazyListState()

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
            // Header
            item {
                Text(
                    text = "TODAY",
                    style = AppTypography.titleMedium,
                    color = AppColors.Nutrition
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Calorie progress ring
            item {
                CalorieProgressRing(
                    current = summary.totalCalories,
                    goal = summary.calorieGoal,
                    progress = summary.calorieProgress
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Macros summary
            item {
                MacrosSummary(
                    protein = summary.proteinG,
                    proteinGoal = summary.proteinGoalG,
                    carbs = summary.carbsG,
                    carbsGoal = summary.carbsGoalG,
                    fat = summary.fatG,
                    fatGoal = summary.fatGoalG
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Add food button
            item {
                Button(
                    onClick = onAddFood,
                    modifier = Modifier
                        .fillMaxWidth(0.85f)
                        .height(44.dp),
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AppColors.Nutrition
                    )
                ) {
                    Text("+ LOG FOOD", style = AppTypography.labelLarge)
                }
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Meal breakdown
            if (summary.meals.isNotEmpty()) {
                item {
                    Text(
                        text = "TODAY'S MEALS",
                        style = AppTypography.labelSmall,
                        color = AppColors.TextMuted
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                }

                // Group by meal type
                val mealsByType = summary.meals.groupBy { it.mealType }
                MealType.entries.forEach { mealType ->
                    val meals = mealsByType[mealType] ?: emptyList()
                    if (meals.isNotEmpty()) {
                        item {
                            MealSection(mealType, meals)
                            Spacer(modifier = Modifier.height(4.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CalorieProgressRing(
    current: Int,
    goal: Int,
    progress: Float
) {
    Box(
        modifier = Modifier.size(100.dp),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            progress = progress.coerceIn(0f, 1f),
            modifier = Modifier.fillMaxSize(),
            indicatorColor = AppColors.Nutrition,
            trackColor = AppColors.ProgressBackground,
            strokeWidth = 8.dp
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "$current",
                style = AppTypography.displaySmall,
                color = AppColors.TextPrimary
            )
            Text(
                text = "/ $goal cal",
                style = AppTypography.labelSmall,
                color = AppColors.TextMuted
            )
        }
    }
}

@Composable
private fun MacrosSummary(
    protein: Float,
    proteinGoal: Float,
    carbs: Float,
    carbsGoal: Float,
    fat: Float,
    fatGoal: Float
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        MacroItem(
            label = "P",
            value = protein.toInt(),
            goal = proteinGoal.toInt(),
            color = AppColors.HeartRate
        )
        MacroItem(
            label = "C",
            value = carbs.toInt(),
            goal = carbsGoal.toInt(),
            color = AppColors.Warning
        )
        MacroItem(
            label = "F",
            value = fat.toInt(),
            goal = fatGoal.toInt(),
            color = AppColors.Secondary
        )
    }
}

@Composable
private fun MacroItem(
    label: String,
    value: Int,
    goal: Int,
    color: androidx.compose.ui.graphics.Color
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = label,
            style = AppTypography.labelSmall,
            color = color
        )
        Text(
            text = "${value}g",
            style = AppTypography.bodyMedium,
            color = AppColors.TextPrimary
        )
        Text(
            text = "/${goal}g",
            style = AppTypography.labelSmall,
            color = AppColors.TextMuted
        )
    }
}

@Composable
private fun MealSection(
    mealType: MealType,
    meals: List<WearFoodEntry>
) {
    val label = when (mealType) {
        MealType.BREAKFAST -> "AM"
        MealType.LUNCH -> "MD"
        MealType.DINNER -> "PM"
        MealType.SNACK -> "SN"
    }

    val totalCals = meals.sumOf { it.calories }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(AppColors.Surface)
            .padding(8.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = label, style = AppTypography.bodySmall, color = AppColors.Nutrition)
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = mealType.name.lowercase().replaceFirstChar { it.uppercase() },
                    style = AppTypography.labelSmall,
                    color = AppColors.TextSecondary
                )
            }
            Text(
                text = "$totalCals cal",
                style = AppTypography.labelSmall,
                color = AppColors.Nutrition
            )
        }

        meals.forEach { meal ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 20.dp, top = 2.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = meal.foodName?.take(15) ?: "Food",
                    style = AppTypography.bodySmall,
                    color = AppColors.TextMuted
                )
                Text(
                    text = "${meal.calories}",
                    style = AppTypography.bodySmall,
                    color = AppColors.TextMuted
                )
            }
        }
    }
}
