package com.fitwiz.wearos.health

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

/**
 * Manager for raw sensor data access.
 * Provides accelerometer and gyroscope data for features like:
 * - Auto rep detection during workouts
 * - Motion detection for activity recognition
 * - Fall detection
 */
@Singleton
class SensorDataManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val sensorManager: SensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val gyroscope: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    private val gravity: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY)
    private val linearAcceleration: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
    private val stepCounter: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    private val stepDetector: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

    private val _isAccelerometerActive = MutableStateFlow(false)
    val isAccelerometerActive: StateFlow<Boolean> = _isAccelerometerActive.asStateFlow()

    private val _isGyroscopeActive = MutableStateFlow(false)
    val isGyroscopeActive: StateFlow<Boolean> = _isGyroscopeActive.asStateFlow()

    companion object {
        private const val TAG = "SensorDataManager"
    }

    /**
     * Get available sensors information
     */
    fun getAvailableSensors(): SensorCapabilities {
        return SensorCapabilities(
            hasAccelerometer = accelerometer != null,
            hasGyroscope = gyroscope != null,
            hasGravity = gravity != null,
            hasLinearAcceleration = linearAcceleration != null,
            hasStepCounter = stepCounter != null,
            hasStepDetector = stepDetector != null
        )
    }

    /**
     * Stream accelerometer data as a Flow
     */
    fun accelerometerFlow(
        samplingRate: Int = SensorManager.SENSOR_DELAY_GAME
    ): Flow<AccelerometerData> = callbackFlow {
        val sensor = accelerometer ?: run {
            Log.w(TAG, "Accelerometer not available")
            close()
            return@callbackFlow
        }

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val data = AccelerometerData(
                    x = event.values[0],
                    y = event.values[1],
                    z = event.values[2],
                    magnitude = sqrt(
                        event.values[0] * event.values[0] +
                        event.values[1] * event.values[1] +
                        event.values[2] * event.values[2]
                    ),
                    timestamp = event.timestamp
                )
                trySend(data)
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
                Log.d(TAG, "Accelerometer accuracy: $accuracy")
            }
        }

        _isAccelerometerActive.value = true
        sensorManager.registerListener(listener, sensor, samplingRate)
        Log.d(TAG, "Accelerometer started")

        awaitClose {
            sensorManager.unregisterListener(listener)
            _isAccelerometerActive.value = false
            Log.d(TAG, "Accelerometer stopped")
        }
    }

    /**
     * Stream gyroscope data as a Flow
     */
    fun gyroscopeFlow(
        samplingRate: Int = SensorManager.SENSOR_DELAY_GAME
    ): Flow<GyroscopeData> = callbackFlow {
        val sensor = gyroscope ?: run {
            Log.w(TAG, "Gyroscope not available")
            close()
            return@callbackFlow
        }

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val data = GyroscopeData(
                    x = event.values[0],
                    y = event.values[1],
                    z = event.values[2],
                    magnitude = sqrt(
                        event.values[0] * event.values[0] +
                        event.values[1] * event.values[1] +
                        event.values[2] * event.values[2]
                    ),
                    timestamp = event.timestamp
                )
                trySend(data)
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
                Log.d(TAG, "Gyroscope accuracy: $accuracy")
            }
        }

        _isGyroscopeActive.value = true
        sensorManager.registerListener(listener, sensor, samplingRate)
        Log.d(TAG, "Gyroscope started")

        awaitClose {
            sensorManager.unregisterListener(listener)
            _isGyroscopeActive.value = false
            Log.d(TAG, "Gyroscope stopped")
        }
    }

    /**
     * Stream linear acceleration (motion without gravity)
     */
    fun linearAccelerationFlow(
        samplingRate: Int = SensorManager.SENSOR_DELAY_GAME
    ): Flow<AccelerometerData> = callbackFlow {
        val sensor = linearAcceleration ?: run {
            Log.w(TAG, "Linear acceleration not available")
            close()
            return@callbackFlow
        }

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val data = AccelerometerData(
                    x = event.values[0],
                    y = event.values[1],
                    z = event.values[2],
                    magnitude = sqrt(
                        event.values[0] * event.values[0] +
                        event.values[1] * event.values[1] +
                        event.values[2] * event.values[2]
                    ),
                    timestamp = event.timestamp
                )
                trySend(data)
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
        }

        sensorManager.registerListener(listener, sensor, samplingRate)

        awaitClose {
            sensorManager.unregisterListener(listener)
        }
    }

    /**
     * Stream step events from step detector
     */
    fun stepDetectorFlow(): Flow<StepEvent> = callbackFlow {
        val sensor = stepDetector ?: run {
            Log.w(TAG, "Step detector not available")
            close()
            return@callbackFlow
        }

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val stepEvent = StepEvent(
                    timestamp = event.timestamp,
                    timeMs = System.currentTimeMillis()
                )
                trySend(stepEvent)
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
        }

        sensorManager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_FASTEST)

        awaitClose {
            sensorManager.unregisterListener(listener)
        }
    }

    /**
     * Get total step count from step counter sensor
     */
    suspend fun getTotalStepCount(): Int? {
        val sensor = stepCounter ?: return null

        return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
            val listener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {
                    continuation.resume(event.values[0].toInt()) {}
                    sensorManager.unregisterListener(this)
                }

                override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
            }

            sensorManager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_FASTEST)

            continuation.invokeOnCancellation {
                sensorManager.unregisterListener(listener)
            }
        }
    }

    /**
     * Create a motion detector for rep counting
     */
    fun createRepDetector(
        thresholdMultiplier: Float = 1.5f,
        minTimeBetweenRepsMs: Long = 500
    ): RepDetector {
        return RepDetector(this, thresholdMultiplier, minTimeBetweenRepsMs)
    }
}

/**
 * Accelerometer sensor reading
 */
data class AccelerometerData(
    val x: Float,
    val y: Float,
    val z: Float,
    val magnitude: Float,
    val timestamp: Long
)

/**
 * Gyroscope sensor reading
 */
data class GyroscopeData(
    val x: Float,
    val y: Float,
    val z: Float,
    val magnitude: Float,
    val timestamp: Long
)

/**
 * Step detection event
 */
data class StepEvent(
    val timestamp: Long,
    val timeMs: Long
)

/**
 * Available sensor capabilities
 */
data class SensorCapabilities(
    val hasAccelerometer: Boolean,
    val hasGyroscope: Boolean,
    val hasGravity: Boolean,
    val hasLinearAcceleration: Boolean,
    val hasStepCounter: Boolean,
    val hasStepDetector: Boolean
)

/**
 * Simple rep counter using accelerometer data.
 * Detects peaks in acceleration to count repetitions.
 */
class RepDetector(
    private val sensorManager: SensorDataManager,
    private val thresholdMultiplier: Float = 1.5f,
    private val minTimeBetweenRepsMs: Long = 500
) {
    private var lastRepTime = 0L
    private var baselineMagnitude = 9.8f // Gravity baseline
    private val magnitudeWindow = mutableListOf<Float>()

    private val _repCount = MutableStateFlow(0)
    val repCount: StateFlow<Int> = _repCount.asStateFlow()

    private val _isDetecting = MutableStateFlow(false)
    val isDetecting: StateFlow<Boolean> = _isDetecting.asStateFlow()

    companion object {
        private const val WINDOW_SIZE = 10
    }

    /**
     * Start rep detection
     */
    fun startDetection(): Flow<RepEvent> = sensorManager.linearAccelerationFlow()
        .onStart {
            _isDetecting.value = true
            _repCount.value = 0
            lastRepTime = 0
            magnitudeWindow.clear()
        }
        .map { data ->
            // Add to sliding window
            magnitudeWindow.add(data.magnitude)
            if (magnitudeWindow.size > WINDOW_SIZE) {
                magnitudeWindow.removeAt(0)
            }

            // Check for rep (peak detection)
            val avgMagnitude = magnitudeWindow.average().toFloat()
            val threshold = avgMagnitude * thresholdMultiplier
            val now = System.currentTimeMillis()

            if (data.magnitude > threshold &&
                (now - lastRepTime) > minTimeBetweenRepsMs
            ) {
                lastRepTime = now
                _repCount.value++

                RepEvent(
                    repNumber = _repCount.value,
                    magnitude = data.magnitude,
                    timestamp = now
                )
            } else {
                null
            }
        }
        .filterNotNull()
        .onCompletion {
            _isDetecting.value = false
        }

    /**
     * Reset rep count
     */
    fun reset() {
        _repCount.value = 0
        lastRepTime = 0
        magnitudeWindow.clear()
    }
}

/**
 * Rep detection event
 */
data class RepEvent(
    val repNumber: Int,
    val magnitude: Float,
    val timestamp: Long
)
