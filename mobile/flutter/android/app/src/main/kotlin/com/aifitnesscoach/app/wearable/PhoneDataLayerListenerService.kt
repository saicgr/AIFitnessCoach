package com.aifitnesscoach.app.wearable

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import com.google.android.gms.wearable.*
import com.google.gson.Gson
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * Service that listens for data and messages from the Wear OS watch.
 * Receives workout logs, food entries, fasting events, and sync requests.
 */
class PhoneDataLayerListenerService : WearableListenerService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val gson = Gson()
    private val dataClient: DataClient by lazy { Wearable.getDataClient(this) }

    companion object {
        private const val TAG = "PhoneDataLayerListener"

        // Path constants - must match watch's DataLayerClient
        const val PATH_WORKOUT_SET = "/fitwiz/workout/set"
        const val PATH_WORKOUT_COMPLETE = "/fitwiz/workout/complete"
        const val PATH_NUTRITION_LOG = "/fitwiz/nutrition/log"
        const val PATH_FASTING_EVENT = "/fitwiz/fasting/event"
        const val PATH_SYNC_REQUEST = "/fitwiz/sync/request"
        const val PATH_HEALTH_DATA = "/fitwiz/health/data"

        // Outgoing paths (phone -> watch)
        const val PATH_WORKOUT_TODAY = "/fitwiz/workout/today"
        const val PATH_NUTRITION_SUMMARY = "/fitwiz/nutrition/summary"
        const val PATH_HEALTH_GOALS = "/fitwiz/health/goals"

        // Message paths
        const val MSG_WORKOUT_START = "/fitwiz/msg/workout/start"
        const val MSG_WORKOUT_END = "/fitwiz/msg/workout/end"
        const val MSG_FASTING_START = "/fitwiz/msg/fasting/start"
        const val MSG_FASTING_END = "/fitwiz/msg/fasting/end"
        const val MSG_SYNC_NOW = "/fitwiz/msg/sync/now"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "onDataChanged: ${dataEvents.count} events")

        dataEvents.forEach { event ->
            if (event.type == DataEvent.TYPE_CHANGED) {
                val dataItem = event.dataItem
                val path = dataItem.uri.path ?: return@forEach

                Log.d(TAG, "Data changed at path: $path")

                scope.launch {
                    try {
                        val dataMap = DataMapItem.fromDataItem(dataItem).dataMap
                        val jsonData = dataMap.getString("data") ?: return@launch

                        when {
                            path.startsWith(PATH_WORKOUT_SET) -> handleWorkoutSet(jsonData)
                            path.startsWith(PATH_WORKOUT_COMPLETE) -> handleWorkoutComplete(jsonData)
                            path.startsWith(PATH_NUTRITION_LOG) -> handleNutritionLog(jsonData)
                            path.startsWith(PATH_FASTING_EVENT) -> handleFastingEvent(jsonData)
                            path.startsWith(PATH_SYNC_REQUEST) -> handleSyncRequest(jsonData)
                            path.startsWith(PATH_HEALTH_DATA) -> handleHealthData(jsonData)
                            else -> Log.d(TAG, "Unknown path: $path")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error processing data: ${e.message}", e)
                    }
                }
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path = messageEvent.path
        Log.d(TAG, "Message received at path: $path")

        scope.launch {
            try {
                when (path) {
                    MSG_WORKOUT_START -> handleWorkoutStartMessage()
                    MSG_WORKOUT_END -> handleWorkoutEndMessage()
                    MSG_FASTING_START -> handleFastingStartMessage()
                    MSG_FASTING_END -> handleFastingEndMessage()
                    MSG_SYNC_NOW -> handleSyncNowMessage()
                    else -> Log.d(TAG, "Unknown message path: $path")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing message: ${e.message}", e)
            }
        }
    }

    override fun onCapabilityChanged(capabilityInfo: CapabilityInfo) {
        Log.d(TAG, "Capability changed: ${capabilityInfo.name}, nodes: ${capabilityInfo.nodes.size}")

        // When watch connects, send current data
        if (capabilityInfo.nodes.isNotEmpty()) {
            scope.launch {
                sendTodaysWorkoutToWatch()
                sendNutritionSummaryToWatch()
                sendHealthGoalsToWatch()
            }
        }
    }

    // ==================== Data Handlers ====================

    private suspend fun handleWorkoutSet(jsonData: String) {
        Log.d(TAG, "Received workout set: $jsonData")
        try {
            val setData = gson.fromJson(jsonData, WorkoutSetSync::class.java)
            // Forward to Flutter via broadcast or store locally then notify
            sendToFlutter("workout_set_logged", jsonData)
            Log.d(TAG, "✅ Workout set processed: ${setData.exerciseName} - ${setData.actualReps} reps")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse workout set", e)
        }
    }

    private suspend fun handleWorkoutComplete(jsonData: String) {
        Log.d(TAG, "Received workout complete: $jsonData")
        try {
            val completeData = gson.fromJson(jsonData, WorkoutCompleteSync::class.java)
            sendToFlutter("workout_completed", jsonData)
            Log.d(TAG, "✅ Workout completed: ${completeData.workoutName} - ${completeData.totalSets} sets")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse workout complete", e)
        }
    }

    private suspend fun handleNutritionLog(jsonData: String) {
        Log.d(TAG, "Received nutrition log: $jsonData")
        try {
            val foodData = gson.fromJson(jsonData, FoodLogSync::class.java)
            sendToFlutter("food_logged", jsonData)
            Log.d(TAG, "✅ Food logged: ${foodData.foodName} - ${foodData.calories} cal")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse nutrition log", e)
        }
    }

    private suspend fun handleFastingEvent(jsonData: String) {
        Log.d(TAG, "Received fasting event: $jsonData")
        try {
            val fastingData = gson.fromJson(jsonData, FastingEventSync::class.java)
            sendToFlutter("fasting_event", jsonData)
            Log.d(TAG, "✅ Fasting event: ${fastingData.eventType}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse fasting event", e)
        }
    }

    private suspend fun handleSyncRequest(jsonData: String) {
        Log.d(TAG, "Received sync request")
        // Watch is requesting data, send current state
        sendTodaysWorkoutToWatch()
        sendNutritionSummaryToWatch()
        sendHealthGoalsToWatch()
    }

    private suspend fun handleHealthData(jsonData: String) {
        Log.d(TAG, "Received health data from watch: $jsonData")
        try {
            val healthData = gson.fromJson(jsonData, WatchHealthData::class.java)
            sendToFlutter("health_data_received", jsonData)
            Log.d(TAG, "✅ Health data: ${healthData.steps} steps, ${healthData.heartRateBpm} bpm")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse health data", e)
        }
    }

    // ==================== Message Handlers ====================

    private suspend fun handleWorkoutStartMessage() {
        Log.d(TAG, "Watch started workout")
        sendToFlutter("workout_started_on_watch", "{}")
    }

    private suspend fun handleWorkoutEndMessage() {
        Log.d(TAG, "Watch ended workout")
        sendToFlutter("workout_ended_on_watch", "{}")
    }

    private suspend fun handleFastingStartMessage() {
        Log.d(TAG, "Watch started fasting")
        sendToFlutter("fasting_started_on_watch", "{}")
    }

    private suspend fun handleFastingEndMessage() {
        Log.d(TAG, "Watch ended fasting")
        sendToFlutter("fasting_ended_on_watch", "{}")
    }

    private suspend fun handleSyncNowMessage() {
        Log.d(TAG, "Watch requested immediate sync")
        sendTodaysWorkoutToWatch()
        sendNutritionSummaryToWatch()
    }

    // ==================== Send Data to Watch ====================

    /**
     * Send today's workout to watch.
     * Reads from Flutter's SharedPreferences cache (FlutterSharedPreferences).
     */
    private suspend fun sendTodaysWorkoutToWatch() {
        try {
            val prefs = getFlutterSharedPreferences()

            // Flutter stores today's workout cache with this key
            val workoutJson = prefs.getString("flutter.today_workout_cache", null)

            if (workoutJson != null) {
                // Parse and reformat for watch
                val watchWorkout = formatWorkoutForWatch(workoutJson)
                if (watchWorkout != null) {
                    val success = putDataToWatch(PATH_WORKOUT_TODAY, watchWorkout)
                    Log.d(TAG, "✅ Today's workout sent to watch: $success")
                } else {
                    Log.d(TAG, "⚠️ No valid workout data to send")
                }
            } else {
                // No cached workout, send empty/rest day signal
                val emptyWorkout = JSONObject().apply {
                    put("isRestDay", true)
                    put("date", getTodayDateString())
                }.toString()
                putDataToWatch(PATH_WORKOUT_TODAY, emptyWorkout)
                Log.d(TAG, "📅 Sent rest day signal to watch")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending workout to watch", e)
        }
    }

    /**
     * Send nutrition summary to watch.
     * Reads from Flutter's SharedPreferences cache.
     */
    private suspend fun sendNutritionSummaryToWatch() {
        try {
            val prefs = getFlutterSharedPreferences()

            // Flutter stores nutrition cache with these keys
            val caloriesConsumed = prefs.getInt("flutter.nutrition_calories_today", 0)
            val calorieGoal = prefs.getInt("flutter.nutrition_calorie_goal", 2000)
            val proteinG = prefs.getFloat("flutter.nutrition_protein_today", 0f)
            val proteinGoal = prefs.getFloat("flutter.nutrition_protein_goal", 150f)
            val carbsG = prefs.getFloat("flutter.nutrition_carbs_today", 0f)
            val carbsGoal = prefs.getFloat("flutter.nutrition_carbs_goal", 250f)
            val fatG = prefs.getFloat("flutter.nutrition_fat_today", 0f)
            val fatGoal = prefs.getFloat("flutter.nutrition_fat_goal", 65f)
            val waterMl = prefs.getInt("flutter.nutrition_water_today", 0)
            val waterGoal = prefs.getInt("flutter.nutrition_water_goal", 2500)

            val summaryJson = JSONObject().apply {
                put("date", getTodayDateString())
                put("totalCalories", caloriesConsumed)
                put("calorieGoal", calorieGoal)
                put("proteinG", proteinG)
                put("proteinGoalG", proteinGoal)
                put("carbsG", carbsG)
                put("carbsGoalG", carbsGoal)
                put("fatG", fatG)
                put("fatGoalG", fatGoal)
                put("waterMl", waterMl)
                put("waterGoalMl", waterGoal)
            }.toString()

            val success = putDataToWatch(PATH_NUTRITION_SUMMARY, summaryJson)
            Log.d(TAG, "✅ Nutrition summary sent to watch: $success (${caloriesConsumed}/${calorieGoal} cal)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending nutrition to watch", e)
        }
    }

    /**
     * Send health goals to watch.
     * Reads from Flutter's SharedPreferences.
     */
    private suspend fun sendHealthGoalsToWatch() {
        try {
            val prefs = getFlutterSharedPreferences()

            // Read health goals from Flutter preferences
            val stepsGoal = prefs.getInt("flutter.health_steps_goal", 10000)
            val activeMinutesGoal = prefs.getInt("flutter.health_active_minutes_goal", 30)
            val caloriesBurnedGoal = prefs.getInt("flutter.health_calories_burned_goal", 500)
            val sleepHoursGoal = prefs.getFloat("flutter.health_sleep_hours_goal", 8f)
            val waterMlGoal = prefs.getInt("flutter.nutrition_water_goal", 2500)

            val goalsJson = JSONObject().apply {
                put("stepsGoal", stepsGoal)
                put("activeMinutesGoal", activeMinutesGoal)
                put("caloriesBurnedGoal", caloriesBurnedGoal)
                put("sleepHoursGoal", sleepHoursGoal)
                put("waterMlGoal", waterMlGoal)
            }.toString()

            val success = putDataToWatch(PATH_HEALTH_GOALS, goalsJson)
            Log.d(TAG, "✅ Health goals sent to watch: $success (${stepsGoal} steps goal)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending health goals to watch", e)
        }
    }

    // ==================== Helper Methods ====================

    /**
     * Get Flutter's SharedPreferences (uses "FlutterSharedPreferences" name).
     */
    private fun getFlutterSharedPreferences(): SharedPreferences {
        return getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    /**
     * Get today's date as ISO string (YYYY-MM-DD).
     */
    private fun getTodayDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        return sdf.format(Date())
    }

    /**
     * Format Flutter's workout data for the watch.
     * Converts from Flutter's TodayWorkoutResponse format to watch format.
     */
    private fun formatWorkoutForWatch(workoutJson: String): String? {
        return try {
            val source = JSONObject(workoutJson)

            // Check if it's a rest day or has no workout
            if (!source.has("workout") || source.isNull("workout")) {
                return JSONObject().apply {
                    put("isRestDay", true)
                    put("date", getTodayDateString())
                }.toString()
            }

            val workout = source.getJSONObject("workout")
            val exercises = workout.optJSONArray("exercises") ?: return null

            // Build watch-compatible format
            val watchExercises = org.json.JSONArray()
            for (i in 0 until exercises.length()) {
                val ex = exercises.getJSONObject(i)
                watchExercises.put(JSONObject().apply {
                    put("id", ex.optString("id", ""))
                    put("name", ex.optString("name", ""))
                    put("targetSets", ex.optInt("sets", 3))
                    put("targetReps", ex.optString("reps", "10"))
                    put("targetWeightKg", ex.optDouble("weight_kg", 0.0))
                    put("restSeconds", ex.optInt("rest_seconds", 60))
                    put("videoUrl", ex.optString("video_url", null))
                    put("thumbnailUrl", ex.optString("thumbnail_url", null))
                })
            }

            JSONObject().apply {
                put("id", workout.optString("id", ""))
                put("name", workout.optString("name", "Today's Workout"))
                put("type", workout.optString("type", "strength"))
                put("exercises", watchExercises)
                put("estimatedDuration", workout.optInt("estimated_duration", 45))
                put("targetMuscleGroups", workout.optJSONArray("target_muscles") ?: org.json.JSONArray())
                put("scheduledDate", source.optString("date", getTodayDateString()))
                put("isRestDay", false)
            }.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Error formatting workout for watch", e)
            null
        }
    }

    /**
     * Put data to watch via Data Layer API.
     */
    private suspend fun putDataToWatch(path: String, jsonData: String): Boolean {
        return try {
            val putDataRequest = PutDataMapRequest.create(path).apply {
                dataMap.putString("data", jsonData)
                dataMap.putLong("timestamp", System.currentTimeMillis())
            }
                .asPutDataRequest()
                .setUrgent()

            dataClient.putDataItem(putDataRequest).await()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send data to $path", e)
            false
        }
    }

    // ==================== Flutter Communication ====================

    private fun sendToFlutter(eventType: String, jsonData: String) {
        // Send broadcast that WearableMethodChannel will receive
        val intent = Intent("com.aifitnesscoach.app.WEARABLE_DATA")
        intent.putExtra("event_type", eventType)
        intent.putExtra("json_data", jsonData)
        sendBroadcast(intent)
        Log.d(TAG, "Sent to Flutter: $eventType")
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}

// ==================== Sync Data Models ====================

data class WorkoutSetSync(
    val id: String,
    val sessionId: String,
    val exerciseId: String,
    val exerciseName: String,
    val setNumber: Int,
    val actualReps: Int,
    val weightKg: Float,
    val loggedAt: Long
)

data class WorkoutCompleteSync(
    val sessionId: String,
    val workoutId: String,
    val workoutName: String,
    val startedAt: Long,
    val endedAt: Long,
    val totalSets: Int,
    val totalReps: Int,
    val totalVolumeKg: Float,
    val avgHeartRate: Int?,
    val maxHeartRate: Int?,
    val caloriesBurned: Int?
)

data class FoodLogSync(
    val id: String,
    val inputType: String,
    val rawInput: String?,
    val foodName: String,
    val calories: Int,
    val proteinG: Float,
    val carbsG: Float,
    val fatG: Float,
    val mealType: String,
    val loggedAt: Long
)

data class FastingEventSync(
    val id: String,
    val sessionId: String,
    val eventType: String,
    val protocol: String,
    val targetDurationMinutes: Int,
    val elapsedMinutes: Int,
    val eventAt: Long
)

data class WatchHealthData(
    val timestamp: Long,
    val steps: Int,
    val heartRateBpm: Int?,
    val caloriesBurned: Int,
    val distanceMeters: Float,
    val activeMinutes: Int
)
