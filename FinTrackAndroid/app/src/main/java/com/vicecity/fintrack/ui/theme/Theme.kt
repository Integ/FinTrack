package com.vicecity.fintrack.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

val Indigo = Color(0xFF4141C2)
val Mint = Color(0xFF1FA683)
val Coral = Color(0xFFF5614F)
val Ink = Color(0xFF1A1F30)

private val LightColors = lightColorScheme(
    primary = Indigo,
    secondary = Mint,
    tertiary = Coral,
    error = Color(0xFFBA1A1A),
    surface = Color(0xFFFFFBFF),
    surfaceContainer = Color(0xFFF2F0F8),
    surfaceContainerLow = Color(0xFFF8F7FD),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFC1C1FF),
    secondary = Color(0xFF72DDBB),
    tertiary = Color(0xFFFFB4A9),
    surface = Color(0xFF12131A),
    surfaceContainer = Color(0xFF20212A),
    surfaceContainerLow = Color(0xFF1B1C24),
)

@Composable
fun FinTrackTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val colors = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && darkTheme ->
            dynamicDarkColorScheme(context)
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            dynamicLightColorScheme(context)
        darkTheme -> DarkColors
        else -> LightColors
    }
    MaterialTheme(colorScheme = colors, content = content)
}
