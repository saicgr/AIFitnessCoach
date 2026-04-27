package com.fitwiz.wearos.health

import android.content.Context
import android.util.Log
import androidx.health.services.client.HealthServices
import androidx.health.services.client.PassiveMonitoringClient
import androidx.health.services.client.data.*
import com.fitwiz.wearos.data.repository.HealthRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Client for passive health data monitoring (steps, calories, distance).
 * Collects data throughout the day without requiring an active exercise session.
 */
@Singleton
class PassiveHealthClient @Inject constructor(
    @ApplicationContext private val context: Context,
    private val healthRepository: HealthRepository
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val passiveMonitoringClient: PassiveMonitoringClient =
        HealthServices.getClient(context).passiveMonitoringClient

    private val _isRegistered = MutableStateFlow(false)
    val isRegistered: StateFlow<Boolean> = _isRegistered.asStateFlow()

    private val _dailySteps = MutableStateFlow(0)
    val dailySteps: StateFlow<Int> = _dailySteps.asStateFlow()

    private val _dailyCalories = MutableStateFlow(0f)
    val dailyCalories: StateFlow<Float> = _dailyCalories.asStateFlow()

    private val _dailyDistance = MutableStateFlow(0f)
    val dailyDistance: StateFlow<Float> = _dailyDistance.asStateFlow()

    companion object {
        private const val TAG = "PassiveHealthClient"
    }

    /**
     * Check if passive monitoring capabilities are available
     */
    suspend fun getPassiveCapabilities(): Set<DataType<*, *>> {
        return try {
            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
            capabilities.supportedDataTypesPassiveMonitoring
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get passive monitoring capabilities", e)
            emptySet()
        }
    }

    /**
     * Register for passive health data updates
     */
    suspend fun registerForPassiveData(): Boolean {
        return try {
            val capabilities = getPassiveCapabilities()
            Log.d(TAG, "Passive monitoring capabilities: $capabilities")

            // Build list of supported data types
            val dataTypes = mutableSetOf<DataType<*, *>>()

            if (capabilities.contains(DataType.STEPS_DAILY)) {
                dataTypes.add(DataType.STEPS_DAILY)
                Log.d(TAG, "Steps tracking supported")
            }
            if (capabilities.contains(DataType.CALORIES_DAILY)) {
                dataTypes.add(DataType.CALORIES_DAILY)
                Log.d(TAG, "Calories tracking supported")
            }
            if (capabilities.contains(DataType.DISTANCE_DAILY)) {
                dataTypes.add(DataType.DISTANCE_DAILY)
                Log.d(TAG, "Distance tracking supported")
            }
            if (capabilities.contains(DataType.FLOORS_DAILY)) {
                dataTypes.add(DataType.FLOORS_DAILY)
                Log.d(TAG, "Floors tracking supported")
            }

            if (dataTypes.isEmpty()) {
                Log.w(TAG, "No passive data types supported on this device")
                return false
            }

            // Create passive listener config
            val config = PassiveListenerConfig(
                dataTypes = dataTypes,
                shouldUserActivityInfoBeRequested = true,
                dailyGoals = emptySet(),
                healthEventTypes = emptySet()
            )

            // Register callback service
            passiveMonitoringClient.setPassiveListenerServiceAsync(
                PassiveDataReceiver::class.java,
                config
            ).await()

            _isRegistered.value = true
            Log.d(TAG, "✅ Registered for passive health data: $dataTypes")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to register for passive data", e)
            _isRegistered.value = false
            false
        }
    }

    /**
     * Unregister from passive health data updates
     */
    suspend fun unregisterPassiveData(): Boolean {
        return try {
            passiveMonitoringClient.clearPassiveListenerServiceAsync().await()
            _isRegistered.value = false
            Log.d(TAG, "Unregistered from passive health data")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister from passive data", e)
            false
        }
    }

    /**
     * Process incoming passive data update
     * Called by PassiveDataReceiver when data is received
     */
    fun processDataUpdate(dataPoints: DataPointContainer) {
        scope.launch {
            try {
                // Process steps
                dataPoints.getData(DataType.STEPS_DAILY).lastOrNull()?.let { sample ->
                    val steps = sample.value.toInt()
                    _dailySteps.value = steps
                    healthRepository.updateDailyActivity(steps = steps)
                    Log.d(TAG, "📈 Steps updated: $steps")
                }

                // Process calories
                dataPoints.getData(DataType.CALORIES_DAILY).lastOrNull()?.let { sample ->
                    val calories = sample.value.toFloat()
                    _dailyCalories.value = calories
                    healthRepository.updateDailyActivity(caloriesBurned = calories.toInt())
                    Log.d(TAG, "🔥 Calories updated: $calories")
                }

                // Process distance
                dataPoints.getData(DataType.DISTANCE_DAILY).lastOrNull()?.let { sample ->
                    val distance = sample.value.toFloat()
                    _dailyDistance.value = distance
                    healthRepository.updateDailyActivity(distanceKm = distance / 1000f)
                    Log.d(TAG, "📍 Distance updated: ${distance}m")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing passive data update", e)
            }
        }
    }

    /**
     * Process user activity info (walking, running, etc.)
     */
    fun processUserActivityInfo(info: UserActivityInfo) {
        scope.launch {
            Log.d(TAG, "User activity state: ${info.userActivityState}")

            // Log the activity state
            Log.d(TAG, "Activity state: ${info.userActivityState}")
        }
    }

    /**
     * Get current daily health summary
     */
    fun getDailySummary(): PassiveHealthSummary {
        return PassiveHealthSummary(
            steps = _dailySteps.value,
            calories = _dailyCalories.value,
            distanceMeters = _dailyDistance.value,
            timestamp = System.currentTimeMillis()
        )
    }

    /**
     * Reset daily counters (typically called at midnight)
     */
    fun resetDailyCounters() {
        _dailySteps.value = 0
        _dailyCalories.value = 0f
        _dailyDistance.value = 0f
        healthRepository.resetDailyActivity()
        Log.d(TAG, "Daily counters reset")
    }
}

/**
 * Summary of passive health data
 */
data class PassiveHealthSummary(
    val steps: Int,
    val calories: Float,
    val distanceMeters: Float,
    val timestamp: Long
)
