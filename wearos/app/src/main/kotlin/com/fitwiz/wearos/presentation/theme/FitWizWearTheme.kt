package com.fitwiz.wearos.presentation.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Typography

/**
 * FitWiz Wear OS Theme
 */

// Custom color scheme for Wear OS
private val FitWizColorScheme = Colors(
    primary = FitWizColors.Primary,
    primaryVariant = FitWizColors.PrimaryVariant,
    secondary = FitWizColors.Secondary,
    secondaryVariant = FitWizColors.Secondary,
    background = FitWizColors.Background,
    surface = FitWizColors.Surface,
    error = FitWizColors.Error,
    onPrimary = FitWizColors.TextOnPrimary,
    onSecondary = FitWizColors.TextPrimary,
    onBackground = FitWizColors.TextPrimary,
    onSurface = FitWizColors.TextPrimary,
    onSurfaceVariant = FitWizColors.TextSecondary,
    onError = FitWizColors.TextPrimary
)

// Custom typography using Wear Material
private val FitWizWearTypography = Typography(
    display1 = FitWizTypography.displayLarge,
    display2 = FitWizTypography.displayMedium,
    display3 = FitWizTypography.displaySmall,
    title1 = FitWizTypography.titleLarge,
    title2 = FitWizTypography.titleMedium,
    title3 = FitWizTypography.titleSmall,
    body1 = FitWizTypography.bodyLarge,
    body2 = FitWizTypography.bodyMedium,
    button = FitWizTypography.labelLarge,
    caption1 = FitWizTypography.labelMedium,
    caption2 = FitWizTypography.labelSmall,
    caption3 = FitWizTypography.bodySmall
)

/**
 * Local composition for custom FitWiz colors
 */
data class ExtendedColors(
    val workout: androidx.compose.ui.graphics.Color = FitWizColors.Workout,
    val nutrition: androidx.compose.ui.graphics.Color = FitWizColors.Nutrition,
    val fasting: androidx.compose.ui.graphics.Color = FitWizColors.Fasting,
    val water: androidx.compose.ui.graphics.Color = FitWizColors.Water,
    val heartRate: androidx.compose.ui.graphics.Color = FitWizColors.HeartRate,
    val success: androidx.compose.ui.graphics.Color = FitWizColors.Success,
    val warning: androidx.compose.ui.graphics.Color = FitWizColors.Warning
)

val LocalExtendedColors = staticCompositionLocalOf { ExtendedColors() }

@Composable
fun FitWizWearTheme(
    content: @Composable () -> Unit
) {
    CompositionLocalProvider(
        LocalExtendedColors provides ExtendedColors()
    ) {
        MaterialTheme(
            colors = FitWizColorScheme,
            typography = FitWizWearTypography,
            content = content
        )
    }
}

/**
 * Access extended colors from theme
 */
object FitWizTheme {
    val extendedColors: ExtendedColors
        @Composable
        get() = LocalExtendedColors.current
}
