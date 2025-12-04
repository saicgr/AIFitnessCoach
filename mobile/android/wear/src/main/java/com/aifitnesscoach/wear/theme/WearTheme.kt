package com.aifitnesscoach.wear.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme

private val FitnessOrange = Color(0xFFFF6B35)
private val FitnessDarkOrange = Color(0xFFE85A2C)

private val WearColorScheme = ColorScheme(
    primary = FitnessOrange,
    onPrimary = Color.White,
    primaryContainer = FitnessDarkOrange,
    onPrimaryContainer = Color.White,
    secondary = Color(0xFF2196F3),
    onSecondary = Color.White,
    background = Color.Black,
    onBackground = Color.White,
    surface = Color(0xFF1A1A1A),
    onSurface = Color.White,
    error = Color(0xFFCF6679),
    onError = Color.Black
)

@Composable
fun WearTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = WearColorScheme,
        content = content
    )
}
