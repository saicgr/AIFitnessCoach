package com.aifitnesscoach.wearos.presentation.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Typography

/**
 * App Wear OS Theme
 */

// Custom color scheme for Wear OS
private val AppColorScheme = Colors(
    primary = AppColors.Primary,
    primaryVariant = AppColors.PrimaryVariant,
    secondary = AppColors.Secondary,
    secondaryVariant = AppColors.Secondary,
    background = AppColors.Background,
    surface = AppColors.Surface,
    error = AppColors.Error,
    onPrimary = AppColors.TextOnPrimary,
    onSecondary = AppColors.TextPrimary,
    onBackground = AppColors.TextPrimary,
    onSurface = AppColors.TextPrimary,
    onSurfaceVariant = AppColors.TextSecondary,
    onError = AppColors.TextPrimary
)

// Custom typography using Wear Material
private val AppWearTypography = Typography(
    display1 = AppTypography.displayLarge,
    display2 = AppTypography.displayMedium,
    display3 = AppTypography.displaySmall,
    title1 = AppTypography.titleLarge,
    title2 = AppTypography.titleMedium,
    title3 = AppTypography.titleSmall,
    body1 = AppTypography.bodyLarge,
    body2 = AppTypography.bodyMedium,
    button = AppTypography.labelLarge,
    caption1 = AppTypography.labelMedium,
    caption2 = AppTypography.labelSmall,
    caption3 = AppTypography.bodySmall
)

/**
 * Local composition for custom App colors
 */
data class ExtendedColors(
    val workout: androidx.compose.ui.graphics.Color = AppColors.Workout,
    val nutrition: androidx.compose.ui.graphics.Color = AppColors.Nutrition,
    val fasting: androidx.compose.ui.graphics.Color = AppColors.Fasting,
    val water: androidx.compose.ui.graphics.Color = AppColors.Water,
    val heartRate: androidx.compose.ui.graphics.Color = AppColors.HeartRate,
    val success: androidx.compose.ui.graphics.Color = AppColors.Success,
    val warning: androidx.compose.ui.graphics.Color = AppColors.Warning
)

val LocalExtendedColors = staticCompositionLocalOf { ExtendedColors() }

@Composable
fun AppWearTheme(
    content: @Composable () -> Unit
) {
    CompositionLocalProvider(
        LocalExtendedColors provides ExtendedColors()
    ) {
        MaterialTheme(
            colors = AppColorScheme,
            typography = AppWearTypography,
            content = content
        )
    }
}

/**
 * Access extended colors from theme
 */
object AppTheme {
    val extendedColors: ExtendedColors
        @Composable
        get() = LocalExtendedColors.current
}
