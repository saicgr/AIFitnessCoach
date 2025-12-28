package com.aifitnesscoach.app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.aifitnesscoach.app.R
import com.aifitnesscoach.app.QuickLogDialogActivity

/**
 * Helper to create deep link pending intent
 */
fun createDeepLinkIntent(context: Context, deepLink: String, requestCode: Int): PendingIntent {
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

/**
 * Today's Workout Widget (#1)
 */
class WorkoutWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_workout)

            // Set click action for Start button -> open workout
            val startIntent = createDeepLinkIntent(context, "aifitnesscoach://workout/start", widgetId)
            views.setOnClickPendingIntent(R.id.workout_start_button, startIntent)

            // Whole widget click -> open schedule
            val widgetIntent = createDeepLinkIntent(context, "aifitnesscoach://schedule", widgetId + 1000)
            views.setOnClickPendingIntent(R.id.workout_name, widgetIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Streak & Motivation Widget (#2)
 */
class StreakWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_streak)

            // Click -> open achievements/stats
            val intent = createDeepLinkIntent(context, "aifitnesscoach://achievements", widgetId)
            views.setOnClickPendingIntent(R.id.streak_count, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Quick Water Log Widget (#3)
 */
class WaterWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_water)

            // Click add button -> quick add water
            val addIntent = createDeepLinkIntent(context, "aifitnesscoach://hydration/add?amount=250", widgetId)
            views.setOnClickPendingIntent(R.id.water_add_button, addIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Quick Food Log Widget (#4)
 */
class FoodWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_food)

            // Click log button -> open transparent activity that shows overlay
            val logIntent = Intent(context, QuickLogDialogActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                logIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.food_log_button, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Stats Dashboard Widget (#5)
 */
class StatsWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_stats)

            // Whole widget click -> open stats
            val intent = createDeepLinkIntent(context, "aifitnesscoach://stats", widgetId)
            views.setOnClickPendingIntent(R.id.stats_container, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Quick Social Post Widget (#6)
 */
class SocialWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_social)

            // Click share button -> open social share
            val shareIntent = createDeepLinkIntent(context, "aifitnesscoach://social/share", widgetId)
            views.setOnClickPendingIntent(R.id.share_workout_btn, shareIntent)

            // Whole widget click -> also open social share
            views.setOnClickPendingIntent(R.id.social_container, shareIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Active Challenges Widget (#7)
 */
class ChallengesWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_challenges)

            // Whole widget click -> open challenges
            val intent = createDeepLinkIntent(context, "aifitnesscoach://challenges", widgetId)
            views.setOnClickPendingIntent(R.id.challenges_container, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Achievements Widget (#8)
 */
class AchievementsWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_achievements)

            // Whole widget click -> open achievements
            val intent = createDeepLinkIntent(context, "aifitnesscoach://achievements", widgetId)
            views.setOnClickPendingIntent(R.id.achievements_container, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Personal Goals Widget (#9)
 */
class GoalsWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_goals)

            // Whole widget click -> open goals
            val intent = createDeepLinkIntent(context, "aifitnesscoach://goals", widgetId)
            views.setOnClickPendingIntent(R.id.goals_container, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * Weekly Calendar Widget (#10)
 */
class CalendarWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_calendar)

            // Whole widget click -> open schedule
            val intent = createDeepLinkIntent(context, "aifitnesscoach://schedule", widgetId)
            views.setOnClickPendingIntent(R.id.calendar_container, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/**
 * AI Coach Chat Widget (#11)
 */
class AICoachWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_ai_coach)

            // Click ask button -> open AI chat
            val chatIntent = createDeepLinkIntent(context, "aifitnesscoach://chat", widgetId)
            views.setOnClickPendingIntent(R.id.ai_ask_button, chatIntent)

            // Whole widget click -> also open chat
            views.setOnClickPendingIntent(R.id.ai_coach_container, chatIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
