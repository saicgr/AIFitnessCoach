package com.fitwiz.wearos.tiles

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.*
import androidx.wear.protolayout.LayoutElementBuilders.*
import androidx.wear.protolayout.ModifiersBuilders.*
import androidx.wear.protolayout.ResourceBuilders.*
import androidx.wear.protolayout.TimelineBuilders.*
import androidx.wear.tiles.*
import androidx.wear.tiles.RequestBuilders.ResourcesRequest
import androidx.wear.tiles.RequestBuilders.TileRequest
import com.fitwiz.wearos.MainActivity
import com.fitwiz.wearos.data.models.FastingStatus
import com.fitwiz.wearos.data.repository.FastingRepository
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.guava.future
import javax.inject.Inject

/**
 * Tile showing fasting timer status
 */
@AndroidEntryPoint
class FastingTileService : TileService() {

    @Inject
    lateinit var fastingRepository: FastingRepository

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        private const val RESOURCES_VERSION = "1"

        private val COLOR_FASTING = argb(0xFFFF9800.toInt())
        private val COLOR_SURFACE = argb(0xFF1A1A2E.toInt())
        private val COLOR_TEXT = argb(0xFFFFFFFF.toInt())
        private val COLOR_TEXT_MUTED = argb(0xFF9E9E9E.toInt())
        private val COLOR_SUCCESS = argb(0xFF4CAF50.toInt())
        private val COLOR_PROGRESS_BG = argb(0xFF2D2D3D.toInt())
    }

    override fun onTileRequest(request: TileRequest): ListenableFuture<TileBuilders.Tile> {
        return scope.future {
            val session = fastingRepository.getActiveFastingSession()
            val streak = fastingRepository.getFastingStreak()

            TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setFreshnessIntervalMillis(60_000) // 1 minute for timer updates
                .setTileTimeline(
                    Timeline.Builder()
                        .addTimelineEntry(
                            TimelineEntry.Builder()
                                .setLayout(
                                    Layout.Builder()
                                        .setRoot(
                                            if (session != null && session.status in listOf(FastingStatus.ACTIVE, FastingStatus.PAUSED)) {
                                                activeFastLayout(
                                                    elapsed = session.elapsedFormatted,
                                                    remaining = session.remainingFormatted,
                                                    progress = session.progress,
                                                    isPaused = session.status == FastingStatus.PAUSED
                                                )
                                            } else {
                                                noFastLayout(streak.currentStreak)
                                            }
                                        )
                                        .build()
                                )
                                .build()
                        )
                        .build()
                )
                .build()
        }
    }

    private fun activeFastLayout(
        elapsed: String,
        remaining: String,
        progress: Float,
        isPaused: Boolean
    ): LayoutElement {
        return Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setModifiers(
                Modifiers.Builder()
                    .setClickable(
                        Clickable.Builder()
                            .setOnClick(
                                ActionBuilders.LaunchAction.Builder()
                                    .setAndroidActivity(
                                        ActionBuilders.AndroidActivity.Builder()
                                            .setClassName(MainActivity::class.java.name)
                                            .setPackageName(packageName)
                                            .addKeyToExtraMapping(
                                                "destination",
                                                ActionBuilders.AndroidStringExtra.Builder()
                                                    .setValue("fasting")
                                                    .build()
                                            )
                                            .build()
                                    )
                                    .build()
                            )
                            .build()
                    )
                    .setBackground(
                        Background.Builder()
                            .setColor(COLOR_SURFACE)
                            .build()
                    )
                    .build()
            )
            .addContent(
                Column.Builder()
                    .setWidth(expand())
                    .setHeight(expand())
                    .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
                    .setModifiers(
                        Modifiers.Builder()
                            .setPadding(
                                Padding.Builder()
                                    .setAll(dp(12f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("⏰")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(20f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText(elapsed)
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(24f))
                                    .setWeight(FONT_WEIGHT_BOLD)
                                    .setColor(if (isPaused) COLOR_TEXT_MUTED else COLOR_TEXT)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText(if (isPaused) "PAUSED" else "$remaining left")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(11f))
                                    .setColor(if (isPaused) COLOR_FASTING else COLOR_TEXT_MUTED)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(6f)).build())
                    // Progress bar
                    .addContent(
                        Box.Builder()
                            .setWidth(dp(80f))
                            .setHeight(dp(6f))
                            .setModifiers(
                                Modifiers.Builder()
                                    .setBackground(
                                        Background.Builder()
                                            .setColor(COLOR_PROGRESS_BG)
                                            .setCorner(
                                                Corner.Builder()
                                                    .setRadius(dp(3f))
                                                    .build()
                                            )
                                            .build()
                                    )
                                    .build()
                            )
                            .addContent(
                                Box.Builder()
                                    .setWidth(dp(80f * progress.coerceIn(0f, 1f)))
                                    .setHeight(dp(6f))
                                    .setModifiers(
                                        Modifiers.Builder()
                                            .setBackground(
                                                Background.Builder()
                                                    .setColor(COLOR_FASTING)
                                                    .setCorner(
                                                        Corner.Builder()
                                                            .setRadius(dp(3f))
                                                            .build()
                                                    )
                                                    .build()
                                            )
                                            .build()
                                    )
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
    }

    private fun noFastLayout(streak: Int): LayoutElement {
        return Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setModifiers(
                Modifiers.Builder()
                    .setClickable(
                        Clickable.Builder()
                            .setOnClick(
                                ActionBuilders.LaunchAction.Builder()
                                    .setAndroidActivity(
                                        ActionBuilders.AndroidActivity.Builder()
                                            .setClassName(MainActivity::class.java.name)
                                            .setPackageName(packageName)
                                            .addKeyToExtraMapping(
                                                "destination",
                                                ActionBuilders.AndroidStringExtra.Builder()
                                                    .setValue("fasting")
                                                    .build()
                                            )
                                            .build()
                                    )
                                    .build()
                            )
                            .build()
                    )
                    .setBackground(
                        Background.Builder()
                            .setColor(COLOR_SURFACE)
                            .build()
                    )
                    .build()
            )
            .addContent(
                Column.Builder()
                    .setWidth(expand())
                    .setHeight(expand())
                    .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
                    .setModifiers(
                        Modifiers.Builder()
                            .setPadding(
                                Padding.Builder()
                                    .setAll(dp(16f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("⏰")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(28f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(4f)).build())
                    .addContent(
                        Text.Builder()
                            .setText("Fasting")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(14f))
                                    .setWeight(FONT_WEIGHT_BOLD)
                                    .setColor(COLOR_TEXT)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText(if (streak > 0) "🔥 $streak day streak" else "Tap to start")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(11f))
                                    .setColor(COLOR_TEXT_MUTED)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(8f)).build())
                    .addContent(
                        Box.Builder()
                            .setWidth(wrap())
                            .setHeight(wrap())
                            .setModifiers(
                                Modifiers.Builder()
                                    .setBackground(
                                        Background.Builder()
                                            .setColor(COLOR_SUCCESS)
                                            .setCorner(
                                                Corner.Builder()
                                                    .setRadius(dp(12f))
                                                    .build()
                                            )
                                            .build()
                                    )
                                    .setPadding(
                                        Padding.Builder()
                                            .setStart(dp(12f))
                                            .setEnd(dp(12f))
                                            .setTop(dp(4f))
                                            .setBottom(dp(4f))
                                            .build()
                                    )
                                    .build()
                            )
                            .addContent(
                                Text.Builder()
                                    .setText("▶ START")
                                    .setFontStyle(
                                        FontStyle.Builder()
                                            .setSize(sp(11f))
                                            .setWeight(FONT_WEIGHT_BOLD)
                                            .setColor(COLOR_TEXT)
                                            .build()
                                    )
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
    }

    override fun onTileResourcesRequest(request: ResourcesRequest): ListenableFuture<Resources> {
        return Futures.immediateFuture(
            Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build()
        )
    }
}
