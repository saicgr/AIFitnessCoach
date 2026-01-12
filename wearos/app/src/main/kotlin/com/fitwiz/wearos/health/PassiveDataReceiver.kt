package com.fitwiz.wearos.health

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.health.services.client.PassiveListenerService
import androidx.health.services.client.data.*
import com.fitwiz.wearos.data.repository.HealthRepository
import com.fitwiz.wearos.data.sync.DataLayerClient
import com.fitwiz.wearos.data.sync.HealthDataSync
import com.fitwiz.wearos.data.sync.SyncManager
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * Service that receives passive health data from Health Services.
 * Runs in the background and receives data even when the app is not active.
 */
@AndroidEntryPoint
class PassiveDataReceiver : PassiveListenerService() {

    @Inject
    lateinit var healthRepository: HealthRepository

    @Inject
    lateinit var syncManager: SyncManager

    @Inject
    lateinit var dataLayerClient: DataLayerClient

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    companion object {
        private const val TAG = "PassiveDataReceiver"
    }

    override fun onNewDataPointsReceived(dataPoints: DataPointContainer) {
        Log.d(TAG, "📊 Received passive data points")

        scope.launch {
            try {
                // Process steps
                dataPoints.getData(DataType.STEPS_DAILY).lastOrNull()?.let { sample ->
                    val steps = sample.value.toInt()
                    healthRepository.updateDailyActivity(steps = steps)
                    Log.d(TAG, "📈 Steps: $steps")

                    // Queue for sync
                    queueHealthDataSync("steps", steps.toFloat(), "count")
                }

                // Process calories
                dataPoints.getData(DataType.CALORIES_DAILY).lastOrNull()?.let { sample ->
                    val calories = sample.value.toFloat()
                    healthRepository.updateDailyActivity(caloriesBurned = calories.toInt())
                    Log.d(TAG, "🔥 Calories: $calories")

                    queueHealthDataSync("calories_passive", calories, "kcal")
                }

                // Process distance
                dataPoints.getData(DataType.DISTANCE_DAILY).lastOrNull()?.let { sample ->
                    val distance = sample.value.toFloat()
                    healthRepository.updateDailyActivity(distanceKm = distance / 1000f)
                    Log.d(TAG, "📍 Distance: ${distance}m")

                    queueHealthDataSync("distance", distance, "meters")
                }

                // Process floors
                dataPoints.getData(DataType.FLOORS_DAILY).lastOrNull()?.let { sample ->
                    val floors = sample.value.toFloat()
                    Log.d(TAG, "🏢 Floors: $floors")

                    queueHealthDataSync("floors", floors, "count")
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error processing passive data", e)
            }
        }
    }

    override fun onUserActivityInfoReceived(info: UserActivityInfo) {
        Log.d(TAG, "👤 User activity state: ${info.userActivityState}")

        // Log the activity state
        Log.d(TAG, "Activity state: ${info.userActivityState}")
    }

    override fun onGoalCompleted(goal: PassiveGoal) {
        Log.d(TAG, "🎯 Goal completed: ${goal.dataTypeCondition.dataType}")

        // Notify user via haptic feedback or notification
        scope.launch {
            try {
                // Send goal completion to phone
                val goalData = mapOf(
                    "goalType" to goal.dataTypeCondition.dataType.name,
                    "completedAt" to System.currentTimeMillis()
                )
                Log.d(TAG, "Goal data: $goalData")
            } catch (e: Exception) {
                Log.e(TAG, "Error handling goal completion", e)
            }
        }
    }

    override fun onHealthEventReceived(event: HealthEvent) {
        Log.d(TAG, "❤️ Health event: ${event.type}")

        when (event.type) {
            HealthEvent.Type.FALL_DETECTED -> {
                Log.w(TAG, "⚠️ Fall detected!")
                // Could trigger emergency notification
            }
            HealthEvent.Type.UNKNOWN -> {
                Log.d(TAG, "Unknown health event")
            }
            else -> {
                Log.d(TAG, "Health event: ${event.type}")
            }
        }
    }

    override fun onPermissionLost() {
        Log.w(TAG, "⚠️ Health permission lost!")
        // Handle permission loss - maybe show notification to user
    }

    private fun queueHealthDataSync(
        dataType: String,
        value: Float,
        unit: String
    ) {
        scope.launch {
            try {
                val now = System.currentTimeMillis()
                val healthData = HealthDataSync(
                    id = UUID.randomUUID().toString(),
                    dataType = dataType,
                    value = value,
                    unit = unit,
                    startTime = now,
                    endTime = now,
                    source = "passive"
                )

                // Try to sync via phone first
                val synced = dataLayerClient.syncHealthData(healthData)
                if (!synced) {
                    Log.d(TAG, "Phone sync failed, will queue for later")
                    // SyncManager will handle fallback
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error queuing health data sync", e)
            }
        }
    }
}

/**
 * BroadcastReceiver for boot completion to restart passive monitoring
 */
class BootCompletedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootCompletedReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device booted, passive monitoring will restart via SyncWorker")
            // PassiveHealthClient will be re-initialized when app starts
        }
    }
}
