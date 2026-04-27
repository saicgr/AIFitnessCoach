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
import com.fitwiz.wearos.data.repository.NutritionRepository
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.guava.future
import javax.inject.Inject

/**
 * Tile showing daily calorie intake
 */
@AndroidEntryPoint
class CaloriesTileService : TileService() {

    @Inject
    lateinit var nutritionRepository: NutritionRepository

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        private const val RESOURCES_VERSION = "1"

        private val COLOR_NUTRITION = argb(0xFF4CAF50.toInt())
        private val COLOR_SURFACE = argb(0xFF1A1A2E.toInt())
        private val COLOR_TEXT = argb(0xFFFFFFFF.toInt())
        private val COLOR_TEXT_MUTED = argb(0xFF9E9E9E.toInt())
        private val COLOR_PROGRESS_BG = argb(0xFF2D2D3D.toInt())
    }

    override fun onTileRequest(request: TileRequest): ListenableFuture<TileBuilders.Tile> {
        return scope.future {
            val summary = nutritionRepository.getTodaysSummary()

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
                                            caloriesLayout(
                                                current = summary.totalCalories,
                                                goal = summary.calorieGoal,
                                                progress = summary.calorieProgress,
                                                protein = summary.proteinG.toInt(),
                                                carbs = summary.carbsG.toInt(),
                                                fat = summary.fatG.toInt()
                                            )
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

    private fun caloriesLayout(
        current: Int,
        goal: Int,
        progress: Float,
        protein: Int,
        carbs: Int,
        fat: Int
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
                                                    .setValue("nutrition")
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
                            .setText("🥗")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(20f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("$current")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(24f))
                                    .setWeight(FONT_WEIGHT_BOLD)
                                    .setColor(COLOR_TEXT)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("/ $goal cal")
                            .setFontStyle(
                                FontStyle.Builder()
                                    .setSize(sp(11f))
                                    .setColor(COLOR_TEXT_MUTED)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(4f)).build())
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
                                                    .setColor(COLOR_NUTRITION)
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
                    .addContent(Spacer.Builder().setHeight(dp(6f)).build())
                    // Macros summary
                    .addContent(
                        Row.Builder()
                            .setWidth(wrap())
                            .setVerticalAlignment(VERTICAL_ALIGN_CENTER)
                            .addContent(macroChip("P", protein))
                            .addContent(Spacer.Builder().setWidth(dp(4f)).build())
                            .addContent(macroChip("C", carbs))
                            .addContent(Spacer.Builder().setWidth(dp(4f)).build())
                            .addContent(macroChip("F", fat))
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(6f)).build())
                    // Log button
                    .addContent(
                        Box.Builder()
                            .setWidth(wrap())
                            .setHeight(wrap())
                            .setModifiers(
                                Modifiers.Builder()
                                    .setBackground(
                                        Background.Builder()
                                            .setColor(COLOR_NUTRITION)
                                            .setCorner(
                                                Corner.Builder()
                                                    .setRadius(dp(10f))
                                                    .build()
                                            )
                                            .build()
                                    )
                                    .setPadding(
                                        Padding.Builder()
                                            .setStart(dp(10f))
                                            .setEnd(dp(10f))
                                            .setTop(dp(3f))
                                            .setBottom(dp(3f))
                                            .build()
                                    )
                                    .build()
                            )
                            .addContent(
                                Text.Builder()
                                    .setText("+ LOG")
                                    .setFontStyle(
                                        FontStyle.Builder()
                                            .setSize(sp(10f))
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

    private fun macroChip(label: String, value: Int): LayoutElement {
        return Text.Builder()
            .setText("$label:${value}g")
            .setFontStyle(
                FontStyle.Builder()
                    .setSize(sp(9f))
                    .setColor(COLOR_TEXT_MUTED)
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
