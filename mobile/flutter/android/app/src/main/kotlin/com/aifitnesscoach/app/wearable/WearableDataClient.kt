package com.aifitnesscoach.app.wearable

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.wearable.*
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.common.util.concurrent.ListenableFuture
import com.google.gson.Gson
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Client for sending data from phone to Wear OS watch.
 * Handles bidirectional sync for workouts, nutrition, and health data.
 */
class WearableDataClient(private val context: Context) {

    // Lazy initialization to avoid errors on devices without Wearable API
    private val dataClient: DataClient by lazy { Wearable.getDataClient(context) }
    private val messageClient: MessageClient by lazy { Wearable.getMessageClient(context) }
    private val nodeClient: NodeClient by lazy { Wearable.getNodeClient(context) }
    private val capabilityClient: CapabilityClient by lazy { Wearable.getCapabilityClient(context) }
    private val gson = Gson()

    // Check if Wearable API is available on this device
    private val isWearableApiAvailable: Boolean by lazy {
        try {
            val result = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context)
            if (result != ConnectionResult.SUCCESS) {
                Log.d(TAG, "Google Play Services not available: $result")
                return@lazy false
            }
            // Try to check if Wearable API specifically is available
            // by attempting a simple operation
            true
        } catch (e: Exception) {
            Log.d(TAG, "Wearable API availability check failed: ${e.message}")
            false
        }
    }

    companion object {
        private const val TAG = "WearableDataClient"

        // Watch app package name (same as phone app for Play Store linking)
        const val WATCH_APP_PACKAGE = "com.aifitnesscoach.app"

        // Capability for watch app
        const val FITWIZ_WATCH_CAPABILITY = "fitwiz_watch"

        // Data paths (phone -> watch)
        const val PATH_WORKOUT_TODAY = "/fitwiz/workout/today"
        const val PATH_NUTRITION_SUMMARY = "/fitwiz/nutrition/summary"
        const val PATH_HEALTH_GOALS = "/fitwiz/health/goals"
        const val PATH_HEALTH_DATA = "/fitwiz/health/data"
        const val PATH_USER_PROFILE = "/fitwiz/user/profile"
        const val PATH_AUTH_CREDENTIALS = "/fitwiz/auth/credentials"

        // Message paths
        const val MSG_SYNC_COMPLETE = "/fitwiz/msg/sync/complete"
        const val MSG_WORKOUT_UPDATED = "/fitwiz/msg/workout/updated"
        const val MSG_AUTH_SYNC = "/fitwiz/msg/auth/sync"
    }

    // ==================== Connection Status ====================

    /**
     * Check if watch is connected (any WearOS device, regardless of FitWiz app)
     */
    suspend fun isWatchConnected(): Boolean {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, returning false for isWatchConnected")
            return false
        }
        return try {
            val nodes = nodeClient.connectedNodes.await()
            nodes.isNotEmpty()
        } catch (e: ApiException) {
            // API_UNAVAILABLE is expected on devices without Wear OS support
            Log.d(TAG, "Wearable API not available on this device")
            false
        } catch (e: Exception) {
            Log.d(TAG, "Watch not connected: ${e.message}")
            false
        }
    }

    /**
     * Check if any WearOS device is connected (paired and reachable).
     * This detects the presence of a watch even if FitWiz app is NOT installed on it.
     * Use this to determine whether to show "Install on Watch" prompt.
     */
    suspend fun hasConnectedWearDevice(): Boolean {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, returning false for hasConnectedWearDevice")
            return false
        }
        return try {
            val nodes = nodeClient.connectedNodes.await()
            val hasDevice = nodes.isNotEmpty()
            Log.d(TAG, "hasConnectedWearDevice: $hasDevice (${nodes.size} nodes)")
            hasDevice
        } catch (e: ApiException) {
            // API_UNAVAILABLE is expected on devices without Wear OS support
            Log.d(TAG, "Wearable API not available on this device")
            false
        } catch (e: Exception) {
            Log.d(TAG, "Error checking for Wear devices: ${e.message}")
            false
        }
    }

    /**
     * Check if FitWiz watch app is installed on the connected watch.
     * Uses capability discovery to find watches with FitWiz installed.
     */
    suspend fun isWatchAppInstalled(): Boolean {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, returning false for isWatchAppInstalled")
            return false
        }
        return try {
            val capabilityInfo = capabilityClient
                .getCapability(FITWIZ_WATCH_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
                .await()
            val hasApp = capabilityInfo.nodes.isNotEmpty()
            Log.d(TAG, "isWatchAppInstalled: $hasApp (${capabilityInfo.nodes.size} nodes with capability)")
            hasApp
        } catch (e: ApiException) {
            // API_UNAVAILABLE is expected on devices without Wear OS support
            Log.d(TAG, "Wearable API not available on this device")
            false
        } catch (e: Exception) {
            Log.d(TAG, "Error checking watch app installation: ${e.message}")
            false
        }
    }

    /**
     * Prompt the user to install FitWiz watch app from Play Store on their connected watch.
     * Opens Play Store on the watch directly via RemoteActivityHelper.
     *
     * @param activity The activity context required for RemoteActivityHelper
     * @return true if the prompt was sent successfully, false otherwise
     */
    suspend fun promptWatchAppInstall(activity: Activity): Boolean {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, cannot prompt watch app install")
            return false
        }
        return try {
            val nodes = nodeClient.connectedNodes.await()
            val watchNode = nodes.firstOrNull()

            if (watchNode == null) {
                Log.d(TAG, "No connected watch to prompt installation")
                return false
            }

            val playStoreIntent = Intent(Intent.ACTION_VIEW)
                .setData(Uri.parse("market://details?id=$WATCH_APP_PACKAGE"))
                .addCategory(Intent.CATEGORY_BROWSABLE)

            val remoteActivityHelper = RemoteActivityHelper(activity, java.util.concurrent.Executors.newSingleThreadExecutor())

            // Start Play Store on the watch - use suspendCancellableCoroutine to await ListenableFuture
            suspendCancellableCoroutine<Void?> { continuation ->
                val future: ListenableFuture<Void> = remoteActivityHelper.startRemoteActivity(playStoreIntent, watchNode.id)
                future.addListener({
                    try {
                        future.get()
                        continuation.resume(null) { }
                    } catch (e: Exception) {
                        continuation.resumeWithException(e)
                    }
                }, java.util.concurrent.Executors.newSingleThreadExecutor())
            }

            Log.i(TAG, "✅ Prompted watch app install on node: ${watchNode.displayName}")
            true
        } catch (e: ApiException) {
            Log.d(TAG, "Wearable API not available on this device")
            false
        } catch (e: Exception) {
            Log.d(TAG, "Failed to prompt watch app install: ${e.message}")
            false
        }
    }

    /**
     * Get connected watch node ID
     */
    suspend fun getWatchNodeId(): String? {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, returning null for getWatchNodeId")
            return null
        }
        return try {
            val capabilityInfo = capabilityClient
                .getCapability(FITWIZ_WATCH_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
                .await()

            // Find best node (prefer nearby)
            capabilityInfo.nodes.firstOrNull { it.isNearby }?.id
                ?: capabilityInfo.nodes.firstOrNull()?.id
        } catch (e: ApiException) {
            Log.d(TAG, "Wearable API not available on this device")
            null
        } catch (e: Exception) {
            Log.d(TAG, "Error getting watch node: ${e.message}")
            // Fallback to any connected node
            try {
                nodeClient.connectedNodes.await().firstOrNull()?.id
            } catch (e2: Exception) {
                null
            }
        }
    }

    // ==================== Send Data to Watch ====================

    /**
     * Send today's workout plan to watch
     */
    suspend fun sendWorkoutToWatch(workoutJson: String): Boolean {
        return putData(PATH_WORKOUT_TODAY, workoutJson)
    }

    /**
     * Send nutrition summary to watch
     */
    suspend fun sendNutritionSummaryToWatch(summaryJson: String): Boolean {
        return putData(PATH_NUTRITION_SUMMARY, summaryJson)
    }

    /**
     * Send health goals to watch (step goal, calorie goal, etc.)
     */
    suspend fun sendHealthGoalsToWatch(goalsJson: String): Boolean {
        return putData(PATH_HEALTH_GOALS, goalsJson)
    }

    /**
     * Send health data from phone's Health Connect to watch
     */
    suspend fun sendHealthDataToWatch(healthDataJson: String): Boolean {
        return putData(PATH_HEALTH_DATA, healthDataJson)
    }

    /**
     * Send user profile to watch
     */
    suspend fun sendUserProfileToWatch(profileJson: String): Boolean {
        return putData(PATH_USER_PROFILE, profileJson)
    }

    /**
     * Send user credentials to watch for authentication
     * This syncs the logged-in user's credentials to the watch
     */
    suspend fun sendUserCredentialsToWatch(
        userId: String,
        authToken: String,
        refreshToken: String? = null,
        expiryMs: Long? = null
    ): Boolean {
        val credentials = UserCredentialsSync(
            userId = userId,
            authToken = authToken,
            refreshToken = refreshToken,
            expiryMs = expiryMs
        )
        val credentialsJson = gson.toJson(credentials)

        // Send via both data layer (persistent) and message (immediate)
        val dataResult = putData(PATH_AUTH_CREDENTIALS, credentialsJson)
        val messageResult = sendMessage(MSG_AUTH_SYNC, credentialsJson.toByteArray())

        Log.d(TAG, "Credentials sync - data: $dataResult, message: $messageResult")
        return dataResult || messageResult
    }

    // ==================== Send Messages ====================

    /**
     * Notify watch that sync is complete
     */
    suspend fun notifySyncComplete(): Boolean {
        return sendMessage(MSG_SYNC_COMPLETE, byteArrayOf())
    }

    /**
     * Notify watch that workout was updated
     */
    suspend fun notifyWorkoutUpdated(): Boolean {
        return sendMessage(MSG_WORKOUT_UPDATED, byteArrayOf())
    }

    // ==================== Helper Methods ====================

    private suspend fun putData(path: String, jsonData: String): Boolean {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, cannot send data to $path")
            return false
        }
        return try {
            val putDataRequest = PutDataMapRequest.create(path).apply {
                dataMap.putString("data", jsonData)
                dataMap.putLong("timestamp", System.currentTimeMillis())
            }
                .asPutDataRequest()
                .setUrgent() // Sync immediately

            dataClient.putDataItem(putDataRequest).await()
            Log.d(TAG, "✅ Data sent to $path")
            true
        } catch (e: ApiException) {
            Log.d(TAG, "Wearable API not available on this device")
            false
        } catch (e: Exception) {
            Log.d(TAG, "Failed to send data to $path: ${e.message}")
            false
        }
    }

    private suspend fun sendMessage(path: String, data: ByteArray): Boolean {
        if (!isWearableApiAvailable) {
            Log.d(TAG, "Wearable API not available, cannot send message to $path")
            return false
        }
        val nodeId = getWatchNodeId() ?: run {
            Log.d(TAG, "No watch connected for message: $path")
            return false
        }

        return try {
            messageClient.sendMessage(nodeId, path, data).await()
            Log.d(TAG, "✅ Message sent: $path")
            true
        } catch (e: ApiException) {
            Log.d(TAG, "Wearable API not available on this device")
            false
        } catch (e: Exception) {
            Log.d(TAG, "Failed to send message: $path: ${e.message}")
            false
        }
    }

    // ==================== Data Models for Phone -> Watch ====================

    /**
     * Convert workout data to JSON for watch
     */
    fun createWorkoutJson(workout: PhoneWorkout): String {
        return gson.toJson(workout)
    }

    /**
     * Convert nutrition summary to JSON for watch
     */
    fun createNutritionSummaryJson(summary: PhoneNutritionSummary): String {
        return gson.toJson(summary)
    }

    /**
     * Convert health goals to JSON for watch
     */
    fun createHealthGoalsJson(goals: PhoneHealthGoals): String {
        return gson.toJson(goals)
    }
}

// ==================== Phone -> Watch Data Models ====================

data class PhoneWorkout(
    val id: String,
    val name: String,
    val type: String,
    val exercises: List<PhoneExercise>,
    val estimatedDuration: Int,
    val targetMuscleGroups: List<String>,
    val scheduledDate: String
)

data class PhoneExercise(
    val id: String,
    val name: String,
    val targetSets: Int,
    val targetReps: String,
    val targetWeightKg: Float?,
    val restSeconds: Int,
    val videoUrl: String?,
    val thumbnailUrl: String?
)

data class PhoneNutritionSummary(
    val date: String,
    val totalCalories: Int,
    val calorieGoal: Int,
    val proteinG: Float,
    val proteinGoalG: Float,
    val carbsG: Float,
    val carbsGoalG: Float,
    val fatG: Float,
    val fatGoalG: Float,
    val waterMl: Int,
    val waterGoalMl: Int
)

data class PhoneHealthGoals(
    val stepsGoal: Int,
    val activeMinutesGoal: Int,
    val caloriesBurnedGoal: Int,
    val sleepHoursGoal: Float,
    val waterMlGoal: Int
)

data class PhoneHealthData(
    val timestamp: Long,
    val dailySteps: Int,
    val dailyCalories: Int,
    val weeklyWeightKg: Float?,
    val restingHeartRate: Int?,
    val sleepMinutes: Int?,
    val activeMinutes: Int
)

/**
 * User credentials for syncing to watch
 */
data class UserCredentialsSync(
    val userId: String,
    val authToken: String,
    val refreshToken: String? = null,
    val expiryMs: Long? = null,
    val syncedAt: Long = System.currentTimeMillis()
)
