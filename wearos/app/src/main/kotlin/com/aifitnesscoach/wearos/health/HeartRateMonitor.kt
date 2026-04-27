package com.fitwiz.wearos.health

import android.content.Context
import android.util.Log
import androidx.health.services.client.HealthServices
import androidx.health.services.client.MeasureCallback
import androidx.health.services.client.MeasureClient
import androidx.health.services.client.data.*
import com.fitwiz.wearos.data.repository.HealthRepository
import com.fitwiz.wearos.data.sync.DataLayerClient
import com.fitwiz.wearos.data.sync.HealthDataSync
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages heart rate monitoring using Health Services MeasureClient.
 * Provides on-demand heart rate readings and periodic background samples.
 */
@Singleton
class HeartRateMonitor @Inject constructor(
    @ApplicationContext private val context: Context,
    private val healthRepository: HealthRepository,
    private val dataLayerClient: DataLayerClient
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val measureClient: MeasureClient = HealthServices.getClient(context).measureClient

    private val _isMonitoring = MutableStateFlow(false)
    val isMonitoring: StateFlow<Boolean> = _isMonitoring.asStateFlow()

    private val _currentHeartRate = MutableStateFlow<Int?>(null)
    val currentHeartRate: StateFlow<Int?> = _currentHeartRate.asStateFlow()

    private val _heartRateHistory = MutableStateFlow<List<HeartRateSample>>(emptyList())
    val heartRateHistory: StateFlow<List<HeartRateSample>> = _heartRateHistory.asStateFlow()

    private val _availability = MutableStateFlow(DataTypeAvailability.UNKNOWN)
    val availability: StateFlow<DataTypeAvailability> = _availability.asStateFlow()

    companion object {
        private const val TAG = "HeartRateMonitor"
        private const val MAX_HISTORY_SIZE = 60 // Keep last 60 samples
        private const val SYNC_INTERVAL_MS = 5000L // 5 seconds throttle for battery efficiency
    }

    // Throttle sync to phone for battery efficiency
    private var lastSyncTime = 0L

    private val heartRateCallback = object : MeasureCallback {
        override fun onAvailabilityChanged(
            dataType: DeltaDataType<*, *>,
            availability: Availability
        ) {
            if (dataType == DataType.HEART_RATE_BPM) {
                val hrAvailability = availability as? DataTypeAvailability
                    ?: DataTypeAvailability.UNKNOWN
                _availability.value = hrAvailability
                Log.d(TAG, "Heart rate availability: $hrAvailability")
            }
        }

        override fun onDataReceived(data: DataPointContainer) {
            data.getData(DataType.HEART_RATE_BPM).lastOrNull()?.let { sample ->
                val bpm = sample.value.toInt()
                onHeartRateReceived(bpm)
            }
        }
    }

    /**
     * Check if heart rate measurement is supported
     */
    suspend fun isHeartRateSupported(): Boolean {
        return try {
            val capabilities = measureClient.getCapabilitiesAsync().await()
            capabilities.supportedDataTypesMeasure.contains(DataType.HEART_RATE_BPM)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check heart rate support", e)
            false
        }
    }

    /**
     * Start continuous heart rate monitoring
     */
    suspend fun startMonitoring(): Boolean {
        if (_isMonitoring.value) {
            Log.d(TAG, "Already monitoring heart rate")
            return true
        }

        return try {
            if (!isHeartRateSupported()) {
                Log.w(TAG, "Heart rate not supported on this device")
                return false
            }

            measureClient.registerMeasureCallback(DataType.HEART_RATE_BPM, heartRateCallback)
            _isMonitoring.value = true
            Log.d(TAG, "✅ Started heart rate monitoring")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start heart rate monitoring", e)
            false
        }
    }

    /**
     * Stop heart rate monitoring
     */
    suspend fun stopMonitoring(): Boolean {
        if (!_isMonitoring.value) {
            return true
        }

        return try {
            measureClient.unregisterMeasureCallbackAsync(DataType.HEART_RATE_BPM, heartRateCallback).await()
            _isMonitoring.value = false
            Log.d(TAG, "Stopped heart rate monitoring")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop heart rate monitoring", e)
            false
        }
    }

    /**
     * Take a single heart rate measurement
     */
    suspend fun takeSingleMeasurement(): Int? {
        return try {
            if (!isHeartRateSupported()) {
                Log.w(TAG, "Heart rate not supported")
                return null
            }

            var result: Int? = null

            val callback = object : MeasureCallback {
                override fun onAvailabilityChanged(
                    dataType: DeltaDataType<*, *>,
                    availability: Availability
                ) {
                    Log.d(TAG, "Single measure availability: $availability")
                }

                override fun onDataReceived(data: DataPointContainer) {
                    data.getData(DataType.HEART_RATE_BPM).lastOrNull()?.let { sample ->
                        result = sample.value.toInt()
                    }
                }
            }

            measureClient.registerMeasureCallback(DataType.HEART_RATE_BPM, callback)
            kotlinx.coroutines.delay(5000) // Wait up to 5 seconds for reading
            measureClient.unregisterMeasureCallbackAsync(DataType.HEART_RATE_BPM, callback).await()

            result?.let {
                onHeartRateReceived(it)
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to take single HR measurement", e)
            null
        }
    }

    private fun onHeartRateReceived(bpm: Int) {
        _currentHeartRate.value = bpm
        healthRepository.updateHeartRate(bpm)

        // Add to history
        val sample = HeartRateSample(
            bpm = bpm,
            timestamp = System.currentTimeMillis()
        )

        val updatedHistory = (_heartRateHistory.value + sample).takeLast(MAX_HISTORY_SIZE)
        _heartRateHistory.value = updatedHistory

        Log.d(TAG, "❤️ Heart rate: $bpm bpm")

        // Sync to phone
        scope.launch {
            syncHeartRate(bpm)
        }
    }

    private suspend fun syncHeartRate(bpm: Int) {
        try {
            val now = System.currentTimeMillis()

            // Throttle sync to phone for battery efficiency (every 5 seconds)
            if (now - lastSyncTime < SYNC_INTERVAL_MS) {
                return
            }
            lastSyncTime = now

            val healthData = HealthDataSync(
                id = UUID.randomUUID().toString(),
                dataType = "heart_rate",
                value = bpm.toFloat(),
                unit = "bpm",
                startTime = now,
                endTime = now,
                source = "measure_client"
            )
            dataLayerClient.syncHealthData(healthData)
            Log.d(TAG, "📤 Synced heart rate to phone: $bpm bpm")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync heart rate", e)
        }
    }

    /**
     * Get heart rate statistics for the current session
     */
    fun getSessionStats(): HeartRateStats? {
        val history = _heartRateHistory.value
        if (history.isEmpty()) return null

        val bpms = history.map { it.bpm }
        return HeartRateStats(
            min = bpms.minOrNull() ?: 0,
            max = bpms.maxOrNull() ?: 0,
            avg = bpms.average().toInt(),
            latest = bpms.lastOrNull() ?: 0,
            sampleCount = history.size
        )
    }

    /**
     * Get heart rate zone based on max heart rate
     */
    fun getHeartRateZone(bpm: Int, maxHr: Int = 190): HeartRateZoneInfo {
        val percentage = (bpm.toFloat() / maxHr) * 100

        return when {
            percentage < 50 -> HeartRateZoneInfo(
                zone = 1,
                name = "Rest",
                color = 0xFF4CAF50.toInt(), // Green
                minPercent = 0,
                maxPercent = 50
            )
            percentage < 60 -> HeartRateZoneInfo(
                zone = 2,
                name = "Warm Up",
                color = 0xFF8BC34A.toInt(), // Light Green
                minPercent = 50,
                maxPercent = 60
            )
            percentage < 70 -> HeartRateZoneInfo(
                zone = 3,
                name = "Fat Burn",
                color = 0xFFFFEB3B.toInt(), // Yellow
                minPercent = 60,
                maxPercent = 70
            )
            percentage < 80 -> HeartRateZoneInfo(
                zone = 4,
                name = "Cardio",
                color = 0xFFFF9800.toInt(), // Orange
                minPercent = 70,
                maxPercent = 80
            )
            percentage < 90 -> HeartRateZoneInfo(
                zone = 5,
                name = "Peak",
                color = 0xFFF44336.toInt(), // Red
                minPercent = 80,
                maxPercent = 90
            )
            else -> HeartRateZoneInfo(
                zone = 6,
                name = "Max",
                color = 0xFF9C27B0.toInt(), // Purple
                minPercent = 90,
                maxPercent = 100
            )
        }
    }

    /**
     * Clear heart rate history
     */
    fun clearHistory() {
        _heartRateHistory.value = emptyList()
        _currentHeartRate.value = null
    }
}

/**
 * Single heart rate sample
 */
data class HeartRateSample(
    val bpm: Int,
    val timestamp: Long
)

/**
 * Heart rate statistics
 */
data class HeartRateStats(
    val min: Int,
    val max: Int,
    val avg: Int,
    val latest: Int,
    val sampleCount: Int
)

/**
 * Heart rate zone information
 */
data class HeartRateZoneInfo(
    val zone: Int,
    val name: String,
    val color: Int,
    val minPercent: Int,
    val maxPercent: Int
)
