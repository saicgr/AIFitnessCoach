package com.aifitnesscoach.app.wearable

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.*
import com.google.gson.Gson
import kotlinx.coroutines.*

/**
 * Service that listens for data and messages from the Wear OS watch.
 * Receives workout logs, food entries, fasting events, and sync requests.
 */
class PhoneDataLayerListenerService : WearableListenerService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val gson = Gson()

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

    private suspend fun sendTodaysWorkoutToWatch() {
        // TODO: Get today's workout from Flutter/local storage and send to watch
        Log.d(TAG, "Sending today's workout to watch (to be implemented)")
    }

    private suspend fun sendNutritionSummaryToWatch() {
        // TODO: Get nutrition summary from Flutter/local storage and send to watch
        Log.d(TAG, "Sending nutrition summary to watch (to be implemented)")
    }

    private suspend fun sendHealthGoalsToWatch() {
        // TODO: Get health goals from Flutter/local storage and send to watch
        Log.d(TAG, "Sending health goals to watch (to be implemented)")
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
