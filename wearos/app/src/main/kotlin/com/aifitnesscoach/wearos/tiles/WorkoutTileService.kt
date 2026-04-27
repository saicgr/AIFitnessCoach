package com.fitwiz.wearos.tiles

import android.content.Context
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
import com.fitwiz.wearos.data.repository.WorkoutRepository
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.guava.future
import javax.inject.Inject

/**
 * Tile showing today's workout with quick start button
 */
@AndroidEntryPoint
class WorkoutTileService : TileService() {

    @Inject
    lateinit var workoutRepository: WorkoutRepository

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        private const val RESOURCES_VERSION = "1"

        // Colors
        private val COLOR_PRIMARY = argb(0xFF6C63FF.toInt())
        private val COLOR_SURFACE = argb(0xFF1A1A2E.toInt())
        private val COLOR_TEXT = argb(0xFFFFFFFF.toInt())
        private val COLOR_TEXT_MUTED = argb(0xFF9E9E9E.toInt())
        private val COLOR_SUCCESS = argb(0xFF4CAF50.toInt())
    }

    override fun onTileRequest(request: TileRequest): ListenableFuture<TileBuilders.Tile> {
        return scope.future {
            val workout = workoutRepository.getTodaysWorkout()

            TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setFreshnessIntervalMillis(300_000) // 5 minutes
                .setTileTimeline(
                    Timeline.Builder()
                        .addTimelineEntry(
                            TimelineEntry.Builder()
                                .setLayout(
                                    Layout.Builder()
                                        .setRoot(
                                            if (workout != null) {
                                                workoutLayout(workout.name, workout.estimatedDuration, workout.exercises.size)
                                            } else {
                                                noWorkoutLayout()
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

    private fun workoutLayout(name: String, duration: Int, exerciseCount: Int): LayoutElement {
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
                                                    .setValue("workout_detail")
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
                            .setText("🏋️")
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
                            .setText(name.take(12))
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(16f))
                                    .setWeight(FONT_WEIGHT_BOLD)
                                    .setColor(COLOR_TEXT)
                                    .build()
                            )
                            .setMaxLines(1)
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("$duration min • $exerciseCount exercises")
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
                                            .setStart(dp(16f))
                                            .setEnd(dp(16f))
                                            .setTop(dp(6f))
                                            .setBottom(dp(6f))
                                            .build()
                                    )
                                    .build()
                            )
                            .addContent(
                                Text.Builder()
                                    .setText("START")
                                    .setFontStyle(
                                        FontStyle.Builder()
                                            .setSize(sp(12f))
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

    private fun noWorkoutLayout(): LayoutElement {
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
                            .setText("🏋️")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(32f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(8f)).build())
                    .addContent(
                        Text.Builder()
                            .setText("No workout")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(14f))
                                    .setColor(COLOR_TEXT_MUTED)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("Sync from phone")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(11f))
                                    .setColor(COLOR_TEXT_MUTED)
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
