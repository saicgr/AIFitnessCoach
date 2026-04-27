package com.fitwiz.wearos.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * FitWiz Wear OS Color Palette
 * Dark theme optimized for OLED watch displays
 */
object FitWizColors {
    // Primary brand colors
    val Primary = Color(0xFF6C63FF)        // Purple accent
    val PrimaryVariant = Color(0xFF5A52D5)
    val Secondary = Color(0xFF00D9FF)      // Cyan highlights

    // Background colors
    val Background = Color(0xFF0D0D0D)     // Pure dark
    val Surface = Color(0xFF1A1A2E)        // Card backgrounds
    val SurfaceVariant = Color(0xFF252542)

    // Status colors
    val Success = Color(0xFF4CAF50)        // Completed sets
    val Warning = Color(0xFFFF9800)        // Rest timer
    val Error = Color(0xFFFF5252)          // Errors

    // Feature-specific colors
    val HeartRate = Color(0xFFFF5252)      // Red pulse
    val Workout = Color(0xFF6C63FF)        // Purple
    val Nutrition = Color(0xFF4CAF50)      // Green
    val Fasting = Color(0xFFFF9800)        // Orange
    val Water = Color(0xFF00D9FF)          // Cyan

    // Text colors
    val TextPrimary = Color(0xFFFFFFFF)
    val TextSecondary = Color(0xFFB0B0B0)
    val TextMuted = Color(0xFF9E9E9E)
    val TextOnPrimary = Color(0xFFFFFFFF)

    // Progress indicators
    val ProgressBackground = Color(0xFF2A2A4A)
    val ProgressForeground = Primary

    // Button colors
    val ButtonPrimary = Primary
    val ButtonSecondary = Surface
    val ButtonDisabled = Color(0xFF3A3A5A)
}
