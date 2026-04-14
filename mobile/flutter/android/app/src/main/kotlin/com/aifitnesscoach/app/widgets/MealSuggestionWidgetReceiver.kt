package com.aifitnesscoach.app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.aifitnesscoach.app.R
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONException
import org.json.JSONObject

/**
 * One-tap "what should I eat?" home-screen widget.
 *
 * Data source
 *   Reads the `meal_suggestion_json` key from the home_widget SharedPreferences
 *   store, which is populated by the Flutter MealSuggestionWidgetService after
 *   each /api/v1/nutrition/quick-suggestion call.
 *
 * Tap targets
 *   - Whole widget  → fitwiz://chat/suggest-food             (open nutrition chat)
 *   - Log it button → fitwiz://nutrition/widget-log          (log the suggestion)
 *   - Refresh button→ fitwiz://chat/suggest-food?action=refresh
 *
 * All three deep links route through DeepLinkService.kt and are handled inside
 * the Flutter app so we don't duplicate business logic in Kotlin.
 *
 * Edge cases
 *   - Empty / malformed JSON   → sign-in placeholder rendering
 *   - `stale` flag from server → "OFFLINE" badge shown, buttons still active
 *   - `isSignedOut`            → buttons hidden, whole surface opens the login flow
 */
class MealSuggestionWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_meal_suggestion)
            val payload = parsePayload(widgetData.getString(KEY_JSON, null))
            bindPayload(views, payload)
            wireClickTargets(context, views, widgetId, payload)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    // ── Parsing ──────────────────────────────────────────────────────────────

    private fun parsePayload(raw: String?): Payload {
        if (raw.isNullOrBlank()) return Payload.signInPlaceholder()
        return try {
            val json = JSONObject(raw)
            Payload(
                emoji = json.optString("emoji", "🍽"),
                mealSlot = json.optString("meal_slot", "snack"),
                title = json.optString("title", ""),
                subtitle = json.optString("subtitle", ""),
                calories = json.optInt("calories", 0),
                proteinG = json.optDouble("protein_g", 0.0),
                carbsG = json.optDouble("carbs_g", 0.0),
                fatG = json.optDouble("fat_g", 0.0),
                stale = json.optBoolean("stale", false),
                isSignedOut = false
            )
        } catch (e: JSONException) {
            // Fail closed: malformed payload shouldn't crash the widget.
            Payload.signInPlaceholder()
        }
    }

    // ── View binding ─────────────────────────────────────────────────────────

    private fun bindPayload(views: RemoteViews, p: Payload) {
        views.setTextViewText(R.id.meal_emoji, p.emoji)
        views.setTextViewText(R.id.meal_slot_label, slotHeadline(p.mealSlot))
        views.setTextViewText(R.id.meal_title, p.title)
        views.setTextViewText(R.id.meal_subtitle, p.subtitle)

        if (p.isSignedOut) {
            views.setViewVisibility(R.id.meal_macros_row, View.GONE)
            views.setViewVisibility(R.id.meal_actions_row, View.GONE)
            views.setViewVisibility(R.id.meal_stale_badge, View.GONE)
            return
        }

        views.setViewVisibility(R.id.meal_macros_row, View.VISIBLE)
        views.setViewVisibility(R.id.meal_actions_row, View.VISIBLE)
        views.setTextViewText(R.id.meal_calories, "${p.calories} cal")
        views.setTextViewText(R.id.meal_protein, "${p.proteinG.toInt()}P")
        views.setTextViewText(R.id.meal_carbs, "${p.carbsG.toInt()}C")
        views.setTextViewText(R.id.meal_fat, "${p.fatG.toInt()}F")
        views.setViewVisibility(
            R.id.meal_stale_badge,
            if (p.stale) View.VISIBLE else View.GONE
        )
    }

    private fun wireClickTargets(
        context: Context,
        views: RemoteViews,
        widgetId: Int,
        p: Payload
    ) {
        // Whole-card tap — opens nutrition chat (or login when signed-out).
        val bodyIntent = deepLinkIntent(
            context,
            if (p.isSignedOut) "fitwiz://chat/suggest-food" else "fitwiz://chat/suggest-food",
            widgetId * 10 + 1
        )
        views.setOnClickPendingIntent(R.id.meal_title, bodyIntent)
        views.setOnClickPendingIntent(R.id.meal_subtitle, bodyIntent)
        views.setOnClickPendingIntent(R.id.meal_emoji, bodyIntent)

        if (p.isSignedOut) return

        val logIntent = deepLinkIntent(
            context,
            "fitwiz://nutrition/widget-log?source=widget",
            widgetId * 10 + 2
        )
        views.setOnClickPendingIntent(R.id.meal_log_button, logIntent)

        val refreshIntent = deepLinkIntent(
            context,
            "fitwiz://chat/suggest-food?source=widget&action=refresh",
            widgetId * 10 + 3
        )
        views.setOnClickPendingIntent(R.id.meal_refresh_button, refreshIntent)
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun deepLinkIntent(
        context: Context,
        deepLink: String,
        requestCode: Int
    ): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
            setPackage(context.packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun slotHeadline(slot: String): String = when (slot) {
        "breakfast" -> "BREAKFAST IDEA"
        "lunch" -> "LUNCH IDEA"
        "dinner" -> "DINNER IDEA"
        "snack" -> "SNACK IDEA"
        "fasting" -> "FASTING"
        else -> "MEAL IDEA"
    }

    // ── Payload type ─────────────────────────────────────────────────────────

    private data class Payload(
        val emoji: String,
        val mealSlot: String,
        val title: String,
        val subtitle: String,
        val calories: Int,
        val proteinG: Double,
        val carbsG: Double,
        val fatG: Double,
        val stale: Boolean,
        val isSignedOut: Boolean
    ) {
        companion object {
            fun signInPlaceholder(): Payload = Payload(
                emoji = "🍽",
                mealSlot = "signed_out",
                title = "Sign in to FitWiz",
                subtitle = "Tap to get personalised meal ideas",
                calories = 0,
                proteinG = 0.0,
                carbsG = 0.0,
                fatG = 0.0,
                stale = false,
                isSignedOut = true
            )
        }
    }

    companion object {
        // Matches the key written by MealSuggestionWidgetService (Flutter).
        private const val KEY_JSON = "meal_suggestion_json"
    }
}
