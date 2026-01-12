package com.fitwiz.wearos.data.sync

import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.android.gms.wearable.*
import com.google.gson.Gson
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Client for communicating with phone app via Wearable Data Layer API
 */
@Singleton
class DataLayerClient @Inject constructor(
    @ApplicationContext private val context: Context,
    private val gson: Gson
) {
    private val dataClient: DataClient = Wearable.getDataClient(context)
    private val messageClient: MessageClient = Wearable.getMessageClient(context)
    private val nodeClient: NodeClient = Wearable.getNodeClient(context)

    companion object {
        private const val TAG = "DataLayerClient"

        // Data paths for syncing
        const val PATH_WORKOUT_TODAY = "/fitwiz/workout/today"
        const val PATH_WORKOUT_SET = "/fitwiz/workout/set"
        const val PATH_WORKOUT_COMPLETE = "/fitwiz/workout/complete"
        const val PATH_NUTRITION_LOG = "/fitwiz/nutrition/log"
        const val PATH_NUTRITION_SUMMARY = "/fitwiz/nutrition/summary"
        const val PATH_FASTING_STATE = "/fitwiz/fasting/state"
        const val PATH_FASTING_EVENT = "/fitwiz/fasting/event"
        const val PATH_SYNC_REQUEST = "/fitwiz/sync/request"
        const val PATH_SYNC_PENDING = "/fitwiz/sync/pending"
        const val PATH_HEALTH_DATA = "/fitwiz/health/data"

        // Auth paths for credential sync
        const val PATH_AUTH_CREDENTIALS = "/fitwiz/auth/credentials"
        const val MSG_AUTH_SYNC = "/fitwiz/msg/auth/sync"

        // Message paths for immediate actions
        const val MSG_WORKOUT_START = "/fitwiz/msg/workout/start"
        const val MSG_WORKOUT_END = "/fitwiz/msg/workout/end"
        const val MSG_FASTING_START = "/fitwiz/msg/fasting/start"
        const val MSG_FASTING_END = "/fitwiz/msg/fasting/end"
    }

    // ==================== Node Discovery ====================

    suspend fun getConnectedNodes(): List<Node> {
        return try {
            nodeClient.connectedNodes.await()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get connected nodes", e)
            emptyList()
        }
    }

    suspend fun isPhoneConnected(): Boolean {
        return getConnectedNodes().isNotEmpty()
    }

    suspend fun getPhoneNodeId(): String? {
        return getConnectedNodes().firstOrNull()?.id
    }

    // ==================== Data Layer Operations ====================

    suspend fun <T> putData(path: String, data: T): Boolean {
        return try {
            val json = gson.toJson(data)
            val request = PutDataMapRequest.create(path).apply {
                dataMap.putString("data", json)
                dataMap.putLong("timestamp", System.currentTimeMillis())
            }.asPutDataRequest().setUrgent()

            dataClient.putDataItem(request).await()
            Log.d(TAG, "Data put successfully at $path")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to put data at $path", e)
            false
        }
    }

    suspend fun <T> getData(path: String, clazz: Class<T>): T? {
        return try {
            val dataItems = dataClient.getDataItems(
                Uri.parse("wear://*$path")
            ).await()

            dataItems.firstOrNull()?.let { item ->
                val dataMap = DataMapItem.fromDataItem(item).dataMap
                val json = dataMap.getString("data")
                gson.fromJson(json, clazz)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get data from $path", e)
            null
        }
    }

    suspend fun deleteData(path: String): Boolean {
        return try {
            val dataItems = dataClient.getDataItems(
                Uri.parse("wear://*$path")
            ).await()

            dataItems.forEach { item ->
                dataClient.deleteDataItems(item.uri).await()
            }
            Log.d(TAG, "Data deleted at $path")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete data at $path", e)
            false
        }
    }

    // ==================== Message Operations ====================

    suspend fun sendMessage(path: String, data: Any? = null): Boolean {
        val nodeId = getPhoneNodeId() ?: run {
            Log.w(TAG, "No phone connected")
            return false
        }

        return try {
            val payload = data?.let { gson.toJson(it).toByteArray() } ?: ByteArray(0)
            messageClient.sendMessage(nodeId, path, payload).await()
            Log.d(TAG, "Message sent to $path")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send message to $path", e)
            false
        }
    }

    // ==================== Specific Sync Operations ====================

    suspend fun syncWorkoutSet(setLog: WorkoutSetSync): Boolean {
        return putData("$PATH_WORKOUT_SET/${setLog.id}", setLog)
    }

    suspend fun syncWorkoutComplete(workoutComplete: WorkoutCompleteSync): Boolean {
        return putData("$PATH_WORKOUT_COMPLETE/${workoutComplete.sessionId}", workoutComplete) &&
                sendMessage(MSG_WORKOUT_END, workoutComplete)
    }

    suspend fun syncFoodLog(foodLog: FoodLogSync): Boolean {
        return putData("$PATH_NUTRITION_LOG/${foodLog.id}", foodLog)
    }

    suspend fun syncFastingEvent(event: FastingEventSync): Boolean {
        return putData("$PATH_FASTING_EVENT/${event.id}", event)
    }

    suspend fun syncHealthData(healthData: HealthDataSync): Boolean {
        return putData("$PATH_HEALTH_DATA/${healthData.id}", healthData)
    }

    suspend fun requestTodaysWorkout(): Boolean {
        return sendMessage(PATH_SYNC_REQUEST, SyncRequest(type = "workout_today"))
    }

    suspend fun requestNutritionSummary(): Boolean {
        return sendMessage(PATH_SYNC_REQUEST, SyncRequest(type = "nutrition_summary"))
    }

    // ==================== Listener Registration ====================

    fun addDataListener(listener: DataClient.OnDataChangedListener) {
        dataClient.addListener(listener)
    }

    fun removeDataListener(listener: DataClient.OnDataChangedListener) {
        dataClient.removeListener(listener)
    }

    fun addMessageListener(listener: MessageClient.OnMessageReceivedListener) {
        messageClient.addListener(listener)
    }

    fun removeMessageListener(listener: MessageClient.OnMessageReceivedListener) {
        messageClient.removeListener(listener)
    }
}

// Sync data classes
data class WorkoutSetSync(
    val id: String,
    val sessionId: String,
    val exerciseId: String,
    val exerciseName: String,
    val setNumber: Int,
    val actualReps: Int,
    val weightKg: Float?,
    val loggedAt: Long
)

data class WorkoutCompleteSync(
    val sessionId: String,
    val workoutId: String?,
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
    val foodName: String?,
    val calories: Int,
    val proteinG: Float?,
    val carbsG: Float?,
    val fatG: Float?,
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

data class SyncRequest(
    val type: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class HealthDataSync(
    val id: String,
    val dataType: String, // "steps", "heart_rate", "calories", "distance", "sleep"
    val value: Float,
    val unit: String, // "count", "bpm", "kcal", "meters", "minutes"
    val startTime: Long,
    val endTime: Long,
    val source: String = "wear_os", // "wear_os", "health_connect", "passive"
    val syncedAt: Long = System.currentTimeMillis()
)

/**
 * Aggregated daily health data for syncing to backend
 */
data class DailyHealthSync(
    val id: String,
    val date: String, // ISO date format "2024-01-15"
    val steps: Int = 0,
    val caloriesBurned: Int = 0,
    val distanceMeters: Float = 0f,
    val activeMinutes: Int = 0,
    val floorsClimbed: Int = 0,
    val heartRateSamples: List<HeartRateSyncSample>? = null,
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val minHeartRate: Int? = null,
    val sleepDurationMinutes: Int? = null,
    val source: String = "wear_os",
    val syncedAt: Long = System.currentTimeMillis()
)

data class HeartRateSyncSample(
    val timestamp: Long,
    val bpm: Int
)

/**
 * User credentials synced from phone
 */
data class UserCredentialsSync(
    val userId: String,
    val authToken: String,
    val refreshToken: String? = null,
    val expiryMs: Long? = null,
    val syncedAt: Long = System.currentTimeMillis()
)
