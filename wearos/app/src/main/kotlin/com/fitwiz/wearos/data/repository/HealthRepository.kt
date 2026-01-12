package com.fitwiz.wearos.data.repository

import android.content.Context
import android.util.Log
import androidx.health.services.client.HealthServices
import androidx.health.services.client.HealthServicesClient
import androidx.health.services.client.ExerciseClient
import androidx.health.services.client.data.*
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.guava.await
import com.fitwiz.wearos.data.models.WearHealthData
import com.fitwiz.wearos.data.models.WearWorkoutMetrics
import com.fitwiz.wearos.data.models.WearDailyActivity
import com.fitwiz.wearos.data.models.HeartRateZone
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class HealthRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val healthServicesClient: HealthServicesClient = HealthServices.getClient(context)
    val exerciseClient: ExerciseClient = healthServicesClient.exerciseClient

    private val _currentMetrics = MutableStateFlow(WearWorkoutMetrics())
    val currentMetrics: StateFlow<WearWorkoutMetrics> = _currentMetrics.asStateFlow()

    private val _dailyActivity = MutableStateFlow(WearDailyActivity(date = getStartOfDay()))
    val dailyActivity: StateFlow<WearDailyActivity> = _dailyActivity.asStateFlow()

    private var heartRateHistory = mutableListOf<Int>()

    companion object {
        private const val TAG = "HealthRepository"
    }

    // ==================== Exercise Capabilities ====================

    suspend fun getExerciseCapabilities(): ExerciseTypeCapabilities? {
        return try {
            val capabilities = exerciseClient.getCapabilitiesAsync().await()
            capabilities.typeToCapabilities[ExerciseType.STRENGTH_TRAINING]
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get exercise capabilities", e)
            null
        }
    }

    suspend fun isHeartRateSupported(): Boolean {
        return try {
            val capabilities = getExerciseCapabilities()
            capabilities?.supportedDataTypes?.contains(DataType.HEART_RATE_BPM) == true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check heart rate support", e)
            false
        }
    }

    // ==================== Metrics Updates ====================

    fun updateHeartRate(bpm: Int) {
        heartRateHistory.add(bpm)

        val avgHr = if (heartRateHistory.isNotEmpty()) {
            heartRateHistory.average().toInt()
        } else null

        val maxHr = heartRateHistory.maxOrNull()
        val minHr = heartRateHistory.minOrNull()

        _currentMetrics.value = _currentMetrics.value.copy(
            currentHeartRate = bpm,
            avgHeartRate = avgHr,
            maxHeartRate = maxHr,
            minHeartRate = minHr,
            heartRateZone = HeartRateZone.fromHeartRate(bpm, 190) // Assuming max HR of 190
        )
    }

    fun updateCaloriesBurned(calories: Int) {
        _currentMetrics.value = _currentMetrics.value.copy(
            caloriesBurned = calories
        )
    }

    fun updateActiveDuration(durationMs: Long) {
        _currentMetrics.value = _currentMetrics.value.copy(
            activeDurationMs = durationMs
        )
    }

    fun updateDailyActivity(
        steps: Int? = null,
        caloriesBurned: Int? = null,
        distanceKm: Float? = null,
        activeMinutes: Int? = null
    ) {
        _dailyActivity.value = _dailyActivity.value.copy(
            steps = steps ?: _dailyActivity.value.steps,
            caloriesBurned = caloriesBurned ?: _dailyActivity.value.caloriesBurned,
            distanceKm = distanceKm ?: _dailyActivity.value.distanceKm,
            activeMinutes = activeMinutes ?: _dailyActivity.value.activeMinutes
        )
    }

    fun incrementWorkoutsCompleted() {
        _dailyActivity.value = _dailyActivity.value.copy(
            workoutsCompleted = _dailyActivity.value.workoutsCompleted + 1
        )
    }

    // ==================== Reset ====================

    fun resetWorkoutMetrics() {
        heartRateHistory.clear()
        _currentMetrics.value = WearWorkoutMetrics()
    }

    fun resetDailyActivity() {
        _dailyActivity.value = WearDailyActivity(date = getStartOfDay())
    }

    // ==================== Helpers ====================

    fun getCurrentHealthSnapshot(): WearHealthData {
        return WearHealthData(
            timestamp = System.currentTimeMillis(),
            heartRateBpm = _currentMetrics.value.currentHeartRate,
            caloriesBurned = _dailyActivity.value.caloriesBurned,
            steps = _dailyActivity.value.steps,
            distanceMeters = _dailyActivity.value.distanceKm * 1000,
            activeMinutes = _dailyActivity.value.activeMinutes
        )
    }

    fun getWorkoutSummaryMetrics(): WearWorkoutMetrics {
        return _currentMetrics.value
    }

    private fun getStartOfDay(): Long {
        return Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }
}
