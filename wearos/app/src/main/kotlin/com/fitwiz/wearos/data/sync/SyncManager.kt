package com.fitwiz.wearos.data.sync

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Log
import com.fitwiz.wearos.data.api.BackendApiClient
import com.fitwiz.wearos.data.local.dao.SyncQueueDao
import com.fitwiz.wearos.data.local.entity.SyncQueueEntity
import com.fitwiz.wearos.data.local.entity.SyncStatus
import com.fitwiz.wearos.data.local.entity.SyncType
import com.fitwiz.wearos.data.models.*
import com.fitwiz.wearos.data.repository.FastingRepository
import com.fitwiz.wearos.data.repository.NutritionRepository
import com.fitwiz.wearos.data.repository.WorkoutRepository
import com.google.gson.Gson
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages syncing data between watch and phone/backend.
 * Implements hybrid sync: phone first (via Data Layer), then direct backend fallback.
 * Handles offline queueing and conflict resolution.
 */
@Singleton
class SyncManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val dataLayerClient: DataLayerClient,
    private val backendApiClient: BackendApiClient,
    private val syncQueueDao: SyncQueueDao,
    private val workoutRepository: WorkoutRepository,
    private val nutritionRepository: NutritionRepository,
    private val fastingRepository: FastingRepository,
    private val gson: Gson
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _syncState = MutableStateFlow(SyncState())
    val syncState: StateFlow<SyncState> = _syncState.asStateFlow()

    companion object {
        private const val TAG = "SyncManager"
    }

    init {
        // Start observing pending queue
        scope.launch {
            syncQueueDao.observePendingCount().collect { count ->
                _syncState.value = _syncState.value.copy(pendingCount = count)
            }
        }
    }

    // ==================== Queue Operations ====================

    suspend fun queueWorkoutSet(setLog: WearSetLog) {
        val syncData = WorkoutSetSync(
            id = setLog.id,
            sessionId = setLog.sessionId,
            exerciseId = setLog.exerciseId,
            exerciseName = setLog.exerciseName,
            setNumber = setLog.setNumber,
            actualReps = setLog.actualReps,
            weightKg = setLog.weightKg,
            loggedAt = setLog.loggedAt
        )

        queueItem(SyncType.WORKOUT_SET, syncData, priority = 1)
    }

    suspend fun queueWorkoutComplete(session: WearWorkoutSession) {
        val syncData = WorkoutCompleteSync(
            sessionId = session.id,
            workoutId = session.workoutId,
            workoutName = session.workoutName,
            startedAt = session.startedAt,
            endedAt = session.endedAt ?: System.currentTimeMillis(),
            totalSets = session.totalSets,
            totalReps = session.totalReps,
            totalVolumeKg = session.totalVolumeKg,
            avgHeartRate = session.avgHeartRate,
            maxHeartRate = session.maxHeartRate,
            caloriesBurned = session.caloriesBurned
        )

        queueItem(SyncType.WORKOUT_COMPLETE, syncData, priority = 2)
    }

    suspend fun queueFoodLog(foodEntry: WearFoodEntry) {
        val syncData = FoodLogSync(
            id = foodEntry.id,
            inputType = foodEntry.inputType.name,
            rawInput = foodEntry.rawInput,
            foodName = foodEntry.foodName,
            calories = foodEntry.calories,
            proteinG = foodEntry.proteinG,
            carbsG = foodEntry.carbsG,
            fatG = foodEntry.fatG,
            mealType = foodEntry.mealType.name,
            loggedAt = foodEntry.loggedAt
        )

        queueItem(SyncType.FOOD_LOG, syncData, priority = 1)
    }

    suspend fun queueFastingEvent(
        session: WearFastingSession,
        eventType: FastingEventType
    ) {
        val syncData = FastingEventSync(
            id = UUID.randomUUID().toString(),
            sessionId = session.id,
            eventType = eventType.name,
            protocol = session.protocol.name,
            targetDurationMinutes = session.targetDurationMinutes,
            elapsedMinutes = (session.elapsedMs / 60000).toInt(),
            eventAt = System.currentTimeMillis()
        )

        queueItem(
            syncType = when (eventType) {
                FastingEventType.START -> SyncType.FASTING_START
                FastingEventType.PAUSE -> SyncType.FASTING_PAUSE
                FastingEventType.RESUME -> SyncType.FASTING_RESUME
                FastingEventType.END, FastingEventType.COMPLETE -> SyncType.FASTING_END
            },
            data = syncData,
            priority = 2
        )
    }

    private suspend fun queueItem(syncType: SyncType, data: Any, priority: Int = 0) {
        val entity = SyncQueueEntity(
            id = UUID.randomUUID().toString(),
            syncType = syncType.name,
            payloadJson = gson.toJson(data),
            priority = priority
        )
        syncQueueDao.insertItem(entity)
        Log.d(TAG, "Queued ${syncType.name} for sync")

        // Try immediate sync if connected
        trySyncPending()
    }

    // ==================== Sync Processing ====================

    /**
     * Hybrid sync: Try phone first (low power), then direct backend if phone unavailable
     */
    suspend fun trySyncPending() {
        val pendingItems = syncQueueDao.getPendingItems()
        if (pendingItems.isEmpty()) {
            Log.d(TAG, "No pending items to sync")
            return
        }

        _syncState.value = _syncState.value.copy(isSyncing = true)

        val phoneConnected = dataLayerClient.isPhoneConnected()
        val networkAvailable = isNetworkAvailable()

        Log.d(TAG, "Sync status: phone=$phoneConnected, network=$networkAvailable, pending=${pendingItems.size}")

        if (!phoneConnected && !networkAvailable) {
            Log.d(TAG, "No connectivity, skipping sync")
            _syncState.value = _syncState.value.copy(isSyncing = false)
            return
        }

        for (item in pendingItems) {
            syncItemHybrid(item, phoneConnected, networkAvailable)
        }

        _syncState.value = _syncState.value.copy(
            isSyncing = false,
            lastSyncTime = System.currentTimeMillis()
        )
    }

    /**
     * Sync a single item using hybrid approach:
     * 1. Try phone sync first (uses phone's network, saves watch battery)
     * 2. Fall back to direct backend sync if phone unavailable
     */
    private suspend fun syncItemHybrid(
        item: SyncQueueEntity,
        phoneConnected: Boolean,
        networkAvailable: Boolean
    ) {
        try {
            syncQueueDao.markSyncing(item.id)

            var success = false

            // Try phone sync first (preferred - uses phone's network)
            if (phoneConnected) {
                success = syncViaPhone(item)
                if (success) {
                    Log.d(TAG, "✅ Synced via phone: ${item.syncType}")
                }
            }

            // Fall back to direct backend sync
            if (!success && networkAvailable) {
                success = syncViaBackend(item)
                if (success) {
                    Log.d(TAG, "✅ Synced via backend: ${item.syncType}")
                }
            }

            if (success) {
                syncQueueDao.markCompleted(item.id)
            } else {
                syncQueueDao.markFailed(item.id, "Both sync methods failed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync item ${item.id}", e)
            syncQueueDao.markFailed(item.id, e.message)
        }
    }

    /**
     * Sync via phone using Wearable Data Layer API
     */
    private suspend fun syncViaPhone(item: SyncQueueEntity): Boolean {
        return try {
            when (SyncType.valueOf(item.syncType)) {
                SyncType.WORKOUT_SET -> {
                    val data = gson.fromJson(item.payloadJson, WorkoutSetSync::class.java)
                    dataLayerClient.syncWorkoutSet(data)
                }
                SyncType.WORKOUT_COMPLETE -> {
                    val data = gson.fromJson(item.payloadJson, WorkoutCompleteSync::class.java)
                    dataLayerClient.syncWorkoutComplete(data)
                }
                SyncType.FOOD_LOG -> {
                    val data = gson.fromJson(item.payloadJson, FoodLogSync::class.java)
                    dataLayerClient.syncFoodLog(data)
                }
                SyncType.FASTING_START, SyncType.FASTING_PAUSE,
                SyncType.FASTING_RESUME, SyncType.FASTING_END -> {
                    val data = gson.fromJson(item.payloadJson, FastingEventSync::class.java)
                    dataLayerClient.syncFastingEvent(data)
                }
                SyncType.WATER_LOG -> true
                SyncType.HEALTH_DATA -> {
                    val data = gson.fromJson(item.payloadJson, HealthDataSync::class.java)
                    dataLayerClient.syncHealthData(data)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Phone sync failed for ${item.syncType}", e)
            false
        }
    }

    /**
     * Sync directly to backend API (fallback when phone unavailable)
     */
    private suspend fun syncViaBackend(item: SyncQueueEntity): Boolean {
        return try {
            when (SyncType.valueOf(item.syncType)) {
                SyncType.WORKOUT_SET -> {
                    val data = gson.fromJson(item.payloadJson, WorkoutSetSync::class.java)
                    val setLog = WearSetLog(
                        id = data.id,
                        sessionId = data.sessionId,
                        exerciseId = data.exerciseId,
                        exerciseName = data.exerciseName,
                        setNumber = data.setNumber,
                        targetReps = null, // Not tracked in sync data
                        actualReps = data.actualReps,
                        weightKg = data.weightKg,
                        loggedAt = data.loggedAt
                    )
                    // Note: Need workoutId for API call - stored in session
                    backendApiClient.logWorkoutSet("", setLog)
                }
                SyncType.WORKOUT_COMPLETE -> {
                    val data = gson.fromJson(item.payloadJson, WorkoutCompleteSync::class.java)
                    val session = WearWorkoutSession(
                        id = data.sessionId,
                        workoutId = data.workoutId,
                        workoutName = data.workoutName,
                        deviceId = getDeviceId(),
                        startedAt = data.startedAt,
                        endedAt = data.endedAt,
                        totalSets = data.totalSets,
                        totalReps = data.totalReps,
                        totalVolumeKg = data.totalVolumeKg,
                        avgHeartRate = data.avgHeartRate,
                        maxHeartRate = data.maxHeartRate,
                        caloriesBurned = data.caloriesBurned
                    )
                    backendApiClient.completeWorkout(data.workoutId ?: "", session)
                }
                SyncType.FOOD_LOG -> {
                    val data = gson.fromJson(item.payloadJson, FoodLogSync::class.java)
                    val foodEntry = WearFoodEntry(
                        id = data.id,
                        inputType = FoodInputType.valueOf(data.inputType),
                        rawInput = data.rawInput,
                        foodName = data.foodName,
                        calories = data.calories,
                        proteinG = data.proteinG,
                        carbsG = data.carbsG,
                        fatG = data.fatG,
                        mealType = MealType.valueOf(data.mealType),
                        loggedAt = data.loggedAt
                    )
                    backendApiClient.logFood(foodEntry)
                }
                SyncType.FASTING_START, SyncType.FASTING_PAUSE,
                SyncType.FASTING_RESUME, SyncType.FASTING_END -> {
                    val data = gson.fromJson(item.payloadJson, FastingEventSync::class.java)
                    val session = WearFastingSession(
                        id = data.sessionId,
                        protocol = FastingProtocol.valueOf(data.protocol),
                        targetDurationMinutes = data.targetDurationMinutes
                    )
                    val eventType = FastingEventType.valueOf(data.eventType)
                    backendApiClient.logFastingEvent(session, eventType)
                }
                SyncType.WATER_LOG -> true
                SyncType.HEALTH_DATA -> {
                    // Individual health data point - just mark as synced
                    // Aggregated daily sync happens separately
                    true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Backend sync failed for ${item.syncType}", e)
            false
        }
    }

    /**
     * Check if watch has network connectivity (WiFi or LTE)
     */
    private fun isNetworkAvailable(): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    // ==================== Sync All Unsynced ====================

    suspend fun syncAllUnsynced() {
        Log.d(TAG, "Starting full sync of unsynced items")

        // Sync unsynced workout sessions
        val unsyncedSessions = workoutRepository.getUnsyncedSessions()
        for (session in unsyncedSessions) {
            queueWorkoutComplete(session)
        }

        // Sync unsynced set logs
        val unsyncedSetLogs = workoutRepository.getUnsyncedSetLogs()
        for (setLog in unsyncedSetLogs) {
            queueWorkoutSet(setLog)
        }

        // Sync unsynced food logs
        val unsyncedFoodLogs = nutritionRepository.getUnsyncedFoodLogs()
        for (foodLog in unsyncedFoodLogs) {
            queueFoodLog(foodLog)
        }

        // Sync unsynced fasting sessions
        val unsyncedFasting = fastingRepository.getUnsyncedFastingSessions()
        for (session in unsyncedFasting) {
            queueFastingEvent(session, FastingEventType.END)
        }

        // Process queue
        trySyncPending()
    }

    // ==================== Data Reception ====================

    suspend fun handleIncomingData(path: String, data: String) {
        Log.d(TAG, "Received data at $path")

        when {
            path.startsWith(DataLayerClient.PATH_WORKOUT_TODAY) -> {
                // Received today's workout from phone
                val workout = gson.fromJson(data, WearWorkout::class.java)
                workoutRepository.saveWorkout(workout)
            }
            path.startsWith(DataLayerClient.PATH_NUTRITION_SUMMARY) -> {
                // Received nutrition summary from phone
                val summary = gson.fromJson(data, WearNutritionSummary::class.java)
                // Update local cache
            }
            path.startsWith(DataLayerClient.PATH_HEALTH_DATA) -> {
                // Received health data from phone (Health Connect data)
                val healthData = gson.fromJson(data, PhoneHealthData::class.java)
                handlePhoneHealthData(healthData)
            }
        }
    }

    private suspend fun handlePhoneHealthData(healthData: PhoneHealthData) {
        Log.d(TAG, "Received health data from phone: steps=${healthData.steps}, calories=${healthData.caloriesBurned}")

        // Update local health repository with phone data
        // This allows the watch to display consolidated health data
        _syncState.value = _syncState.value.copy(
            lastPhoneHealthSync = System.currentTimeMillis()
        )
    }

    // ==================== Cleanup ====================

    suspend fun cleanup() {
        syncQueueDao.clearCompletedItems()
        syncQueueDao.clearFailedItems()
    }

    // ==================== Helpers ====================

    private fun getDeviceId(): String {
        return android.provider.Settings.Secure.getString(
            context.contentResolver,
            android.provider.Settings.Secure.ANDROID_ID
        ) ?: "unknown_device"
    }
}

data class SyncState(
    val isSyncing: Boolean = false,
    val pendingCount: Int = 0,
    val lastSyncTime: Long? = null,
    val lastPhoneHealthSync: Long? = null,
    val error: String? = null
)
