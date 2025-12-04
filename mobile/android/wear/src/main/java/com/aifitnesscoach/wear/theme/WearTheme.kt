package com.aifitnesscoach.wear.theme

import androidx.compose.runtime.Composable
import androidx.wear.compose.material3.MaterialTheme

@Composable
fun WearTheme(content: @Composable () -> Unit) {
    // Use default Wear Material3 theme
    // Custom theming requires stable API - alpha29 ColorScheme API is unstable
    MaterialTheme(
        content = content
    )
}
