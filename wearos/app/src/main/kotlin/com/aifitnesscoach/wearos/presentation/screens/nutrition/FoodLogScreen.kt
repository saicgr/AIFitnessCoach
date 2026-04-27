package com.fitwiz.wearos.presentation.screens.nutrition

import android.app.Activity
import android.content.Intent
import android.speech.RecognizerIntent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.*
import com.fitwiz.wearos.data.models.FoodInputType
import com.fitwiz.wearos.presentation.theme.FitWizColors
import com.fitwiz.wearos.presentation.theme.FitWizTypography
import com.fitwiz.wearos.presentation.viewmodel.NutritionViewModel
import com.fitwiz.wearos.voice.VoiceInputManager
import java.util.*

/**
 * Food Log Screen - Voice/keyboard input options
 */
@Composable
fun FoodLogScreen(
    viewModel: NutritionViewModel = hiltViewModel(),
    onNavigateToConfirm: () -> Unit,
    onNavigateToQuickAdd: () -> Unit,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    val pendingEntry by viewModel.pendingEntry.collectAsState()

    val listState = rememberScalingLazyListState()

    // Voice input launcher
    val voiceLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val voiceResult = result.data
                ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                ?.firstOrNull()

            voiceResult?.let { input ->
                viewModel.parseInput(input, FoodInputType.VOICE)
                onNavigateToConfirm()
            }
        }
    }

    // Remote input launcher (keyboard)
    val keyboardLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val voiceInputManager = VoiceInputManager()
            val textResult = voiceInputManager.extractVoiceResult(result.data)

            textResult?.let { input ->
                viewModel.parseInput(input, FoodInputType.KEYBOARD)
                onNavigateToConfirm()
            }
        }
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
            // Header
            item {
                Text(
                    text = "LOG FOOD",
                    style = FitWizTypography.titleMedium,
                    color = FitWizColors.Nutrition
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Voice input option
            item {
                InputOptionCard(
                    icon = "MIC",
                    title = "VOICE",
                    subtitle = "\"chicken salad...\"",
                    onClick = {
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                            putExtra(RecognizerIntent.EXTRA_PROMPT, "What did you eat?")
                        }
                        voiceLauncher.launch(intent)
                    }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            // Keyboard input option
            item {
                InputOptionCard(
                    icon = "KEY",
                    title = "TYPE",
                    subtitle = "Search or type food",
                    onClick = {
                        val voiceInputManager = VoiceInputManager()
                        val intent = voiceInputManager.createRemoteInputIntent(
                            prompt = "What did you eat?",
                            recentSuggestions = uiState.recentFoodNames
                        )
                        keyboardLauncher.launch(intent)
                    }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            // Quick add option
            item {
                InputOptionCard(
                    icon = "CAL",
                    title = "QUICK ADD",
                    subtitle = "Just enter calories",
                    onClick = onNavigateToQuickAdd
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Recent foods
            if (uiState.recentFoodNames.isNotEmpty()) {
                item {
                    Text(
                        text = "RECENT",
                        style = FitWizTypography.labelSmall,
                        color = FitWizColors.TextMuted
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                }

                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        uiState.recentFoodNames.take(3).forEach { name ->
                            RecentFoodChip(
                                name = name,
                                onClick = {
                                    viewModel.parseInput(name, FoodInputType.KEYBOARD)
                                    onNavigateToConfirm()
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InputOptionCard(
    icon: String,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(FitWizColors.Surface)
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = icon,
            style = FitWizTypography.displaySmall,
            color = FitWizColors.Nutrition
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column {
            Text(
                text = title,
                style = FitWizTypography.titleSmall,
                color = FitWizColors.Nutrition
            )
            Text(
                text = subtitle,
                style = FitWizTypography.bodySmall,
                color = FitWizColors.TextMuted
            )
        }
    }
}

@Composable
private fun RecentFoodChip(
    name: String,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(FitWizColors.Nutrition.copy(alpha = 0.2f))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = name.take(10),
            style = FitWizTypography.labelSmall,
            color = FitWizColors.Nutrition,
            maxLines = 1
        )
    }
}
