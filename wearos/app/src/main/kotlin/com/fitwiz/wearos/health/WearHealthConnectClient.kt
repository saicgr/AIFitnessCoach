package com.fitwiz.wearos.health

import android.content.Context
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Client for Health Connect integration on Wear OS.
 * Reads and writes health data to the shared Health Connect repository.
 */
@Singleton
class WearHealthConnectClient @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var healthConnectClient: HealthConnectClient? = null

    private val _isAvailable = MutableStateFlow(false)
    val isAvailable: StateFlow<Boolean> = _isAvailable.asStateFlow()

    private val _hasPermissions = MutableStateFlow(false)
    val hasPermissions: StateFlow<Boolean> = _hasPermissions.asStateFlow()

    companion object {
        private const val TAG = "WearHealthConnectClient"

        // Permissions needed
        val PERMISSIONS = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(DistanceRecord::class),
            HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class),
            HealthPermission.getWritePermission(ExerciseSessionRecord::class),
            HealthPermission.getWritePermission(StepsRecord::class),
            HealthPermission.getWritePermission(DistanceRecord::class),
            HealthPermission.getWritePermission(TotalCaloriesBurnedRecord::class)
        )
    }

    /**
     * Initialize the Health Connect client
     */
    fun initialize(): Boolean {
        return try {
            val availability = HealthConnectClient.getSdkStatus(context)
            when (availability) {
                HealthConnectClient.SDK_AVAILABLE -> {
                    healthConnectClient = HealthConnectClient.getOrCreate(context)
                    _isAvailable.value = true
                    Log.d(TAG, "✅ Health Connect available")
                    true
                }
                HealthConnectClient.SDK_UNAVAILABLE -> {
                    Log.w(TAG, "Health Connect not available on this device")
                    _isAvailable.value = false
                    false
                }
                HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> {
                    Log.w(TAG, "Health Connect requires update")
                    _isAvailable.value = false
                    false
                }
                else -> {
                    Log.w(TAG, "Unknown Health Connect status: $availability")
                    _isAvailable.value = false
                    false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Health Connect", e)
            _isAvailable.value = false
            false
        }
    }

    /**
     * Check if permissions are granted
     */
    suspend fun checkPermissions(): Boolean {
        val client = healthConnectClient ?: return false

        return try {
            val granted = client.permissionController.getGrantedPermissions()
            val hasAll = PERMISSIONS.all { it in granted }
            _hasPermissions.value = hasAll
            Log.d(TAG, "Permissions check: $hasAll (granted: ${granted.size}/${PERMISSIONS.size})")
            hasAll
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check permissions", e)
            false
        }
    }

    /**
     * Get today's steps from Health Connect
     */
    suspend fun getTodaysSteps(): Int {
        val client = healthConnectClient ?: return 0

        return try {
            val today = LocalDate.now()
            val startOfDay = today.atStartOfDay(ZoneId.systemDefault()).toInstant()
            val now = Instant.now()

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            val totalSteps = response.records.sumOf { it.count.toInt() }
            Log.d(TAG, "Today's steps from Health Connect: $totalSteps")
            totalSteps
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get steps", e)
            0
        }
    }

    /**
     * Get today's distance from Health Connect
     */
    suspend fun getTodaysDistance(): Double {
        val client = healthConnectClient ?: return 0.0

        return try {
            val today = LocalDate.now()
            val startOfDay = today.atStartOfDay(ZoneId.systemDefault()).toInstant()
            val now = Instant.now()

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = DistanceRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            val totalDistance = response.records.sumOf { it.distance.inMeters }
            Log.d(TAG, "Today's distance from Health Connect: ${totalDistance}m")
            totalDistance
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get distance", e)
            0.0
        }
    }

    /**
     * Get today's calories from Health Connect
     */
    suspend fun getTodaysCalories(): Double {
        val client = healthConnectClient ?: return 0.0

        return try {
            val today = LocalDate.now()
            val startOfDay = today.atStartOfDay(ZoneId.systemDefault()).toInstant()
            val now = Instant.now()

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = TotalCaloriesBurnedRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            val totalCalories = response.records.sumOf { it.energy.inKilocalories }
            Log.d(TAG, "Today's calories from Health Connect: $totalCalories kcal")
            totalCalories
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get calories", e)
            0.0
        }
    }

    /**
     * Get recent heart rate samples
     */
    suspend fun getRecentHeartRate(durationMinutes: Long = 60): List<HeartRateSample> {
        val client = healthConnectClient ?: return emptyList()

        return try {
            val now = Instant.now()
            val start = now.minus(durationMinutes, ChronoUnit.MINUTES)

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(start, now)
                )
            )

            val samples = response.records.flatMap { record ->
                record.samples.map { sample ->
                    HeartRateSample(
                        bpm = sample.beatsPerMinute.toInt(),
                        timestamp = sample.time.toEpochMilli()
                    )
                }
            }

            Log.d(TAG, "Got ${samples.size} heart rate samples from Health Connect")
            samples
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get heart rate", e)
            emptyList()
        }
    }

    /**
     * Get last night's sleep data
     */
    suspend fun getLastNightSleep(): SleepSummary? {
        val client = healthConnectClient ?: return null

        return try {
            val today = LocalDate.now()
            val yesterday = today.minusDays(1)
            val startOfYesterday = yesterday.atStartOfDay(ZoneId.systemDefault()).toInstant()
            val now = Instant.now()

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = SleepSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfYesterday, now)
                )
            )

            // Find the most recent sleep session
            val latestSession = response.records.maxByOrNull { it.endTime }

            latestSession?.let { session ->
                val durationMinutes = ChronoUnit.MINUTES.between(session.startTime, session.endTime)

                SleepSummary(
                    startTime = session.startTime.toEpochMilli(),
                    endTime = session.endTime.toEpochMilli(),
                    durationMinutes = durationMinutes.toInt(),
                    title = session.title ?: "Sleep"
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get sleep data", e)
            null
        }
    }

    /**
     * Write a workout session to Health Connect
     */
    suspend fun writeWorkoutSession(
        exerciseType: Int,
        startTime: Instant,
        endTime: Instant,
        title: String,
        caloriesBurned: Double? = null,
        heartRateSamples: List<HeartRateSample>? = null
    ): Boolean {
        val client = healthConnectClient ?: return false

        return try {
            val records = mutableListOf<Record>()

            // Create exercise session
            val exerciseSession = ExerciseSessionRecord(
                startTime = startTime,
                endTime = endTime,
                exerciseType = exerciseType,
                startZoneOffset = null,
                endZoneOffset = null,
                title = title
            )
            records.add(exerciseSession)

            // Add calories if provided
            caloriesBurned?.let { calories ->
                val caloriesRecord = TotalCaloriesBurnedRecord(
                    startTime = startTime,
                    endTime = endTime,
                    energy = androidx.health.connect.client.units.Energy.kilocalories(calories),
                    startZoneOffset = null,
                    endZoneOffset = null
                )
                records.add(caloriesRecord)
            }

            // Add heart rate samples if provided
            heartRateSamples?.takeIf { it.isNotEmpty() }?.let { samples ->
                val heartRateRecord = HeartRateRecord(
                    startTime = startTime,
                    endTime = endTime,
                    samples = samples.map { sample ->
                        HeartRateRecord.Sample(
                            time = Instant.ofEpochMilli(sample.timestamp),
                            beatsPerMinute = sample.bpm.toLong()
                        )
                    },
                    startZoneOffset = null,
                    endZoneOffset = null
                )
                records.add(heartRateRecord)
            }

            client.insertRecords(records)
            Log.d(TAG, "✅ Wrote workout to Health Connect: $title")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write workout to Health Connect", e)
            false
        }
    }

    /**
     * Get a combined health summary for today
     */
    suspend fun getTodaysSummary(): HealthConnectSummary {
        return HealthConnectSummary(
            steps = getTodaysSteps(),
            distanceMeters = getTodaysDistance(),
            caloriesBurned = getTodaysCalories(),
            lastSleep = getLastNightSleep(),
            timestamp = System.currentTimeMillis()
        )
    }
}

/**
 * Sleep summary from Health Connect
 */
data class SleepSummary(
    val startTime: Long,
    val endTime: Long,
    val durationMinutes: Int,
    val title: String
)

/**
 * Combined health data summary
 */
data class HealthConnectSummary(
    val steps: Int,
    val distanceMeters: Double,
    val caloriesBurned: Double,
    val lastSleep: SleepSummary?,
    val timestamp: Long
)
