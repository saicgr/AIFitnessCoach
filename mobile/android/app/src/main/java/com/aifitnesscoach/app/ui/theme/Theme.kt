package com.aifitnesscoach.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// ========== COLOR PALETTE (Matching React Web App) ==========

// Primary Colors (Cool Tones)
val Cyan = Color(0xFF06B6D4)           // Main brand color
val CyanDark = Color(0xFF0891B2)       // Primary dark variant
val ElectricBlue = Color(0xFF3B82F6)   // Secondary accents
val Teal = Color(0xFF14B8A6)           // Success, completed states

// Warm Highlights (Accent)
val Orange = Color(0xFFF97316)         // Warnings, streaks, energy
val Magenta = Color(0xFFEC4899)        // Special achievements
val Coral = Color(0xFFF43F5E)          // Errors, attention

// Dark Mode Backgrounds
val PureBlack = Color(0xFF000000)      // Main background (OLED optimized)
val NearBlack = Color(0xFF0A0A0A)      // Card surfaces
val Elevated = Color(0xFF141414)       // Elevated surfaces
val GlassSurface = Color(0xFF1A1A1A)   // Glass effect base
val SurfaceLight = Color(0xFF1F1F1F)   // Light surface for inputs
val SurfaceDark = Color(0xFF0D0D0D)    // Dark surface for bottom bars

// Text Colors
val TextPrimary = Color(0xFFFAFAFA)    // Main content
val TextSecondary = Color(0xFFA1A1AA)  // Supporting text
val TextMuted = Color(0xFF71717A)      // Disabled/subtle

// Border Colors
val BorderLight = Color(0x1AFFFFFF)    // 10% white
val BorderMedium = Color(0x26FFFFFF)   // 15% white

// Workout Type Colors (for gradients/badges)
val StrengthColor = Color(0xFF6366F1)  // Indigo
val CardioColor = Color(0xFFEF4444)    // Red
val FlexibilityColor = Color(0xFF14B8A6) // Teal
val HIITColor = Color(0xFFEC4899)      // Magenta

// ========== COLOR SCHEMES ==========

private val DarkColorScheme = darkColorScheme(
    primary = Cyan,
    onPrimary = Color.White,
    primaryContainer = CyanDark,
    onPrimaryContainer = Color.White,
    secondary = ElectricBlue,
    onSecondary = Color.White,
    secondaryContainer = ElectricBlue.copy(alpha = 0.2f),
    onSecondaryContainer = ElectricBlue,
    tertiary = Teal,
    onTertiary = Color.White,
    tertiaryContainer = Teal.copy(alpha = 0.2f),
    onTertiaryContainer = Teal,
    error = Coral,
    onError = Color.White,
    errorContainer = Coral.copy(alpha = 0.2f),
    onErrorContainer = Coral,
    background = PureBlack,
    onBackground = TextPrimary,
    surface = NearBlack,
    onSurface = TextPrimary,
    surfaceVariant = Elevated,
    onSurfaceVariant = TextSecondary,
    outline = BorderMedium,
    outlineVariant = BorderLight,
    inverseSurface = TextPrimary,
    inverseOnSurface = PureBlack,
    inversePrimary = CyanDark
)

private val LightColorScheme = lightColorScheme(
    primary = Cyan,
    onPrimary = Color.White,
    primaryContainer = Cyan.copy(alpha = 0.1f),
    onPrimaryContainer = CyanDark,
    secondary = ElectricBlue,
    onSecondary = Color.White,
    tertiary = Teal,
    onTertiary = Color.White,
    error = Coral,
    onError = Color.White,
    background = Color(0xFFFAFAFA),
    onBackground = Color(0xFF0A0A0A),
    surface = Color.White,
    onSurface = Color(0xFF0A0A0A),
    surfaceVariant = Color(0xFFF4F4F5),
    onSurfaceVariant = Color(0xFF71717A)
)

@Composable
fun AIFitnessCoachTheme(
    darkTheme: Boolean = true, // Default to dark theme to match web app
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            window.navigationBarColor = Color.Transparent.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
