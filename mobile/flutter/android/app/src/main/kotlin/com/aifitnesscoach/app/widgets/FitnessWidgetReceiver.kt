package com.aifitnesscoach.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.aifitnesscoach.app.R

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
            // Data will be populated by home_widget package from Flutter
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
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
