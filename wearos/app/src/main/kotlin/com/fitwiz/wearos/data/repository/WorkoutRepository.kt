package com.fitwiz.wearos.data.repository

import android.util.Log
import com.fitwiz.wearos.data.api.BackendApiClient
import com.fitwiz.wearos.data.local.dao.WorkoutDao
import com.fitwiz.wearos.data.local.entity.*
import com.fitwiz.wearos.data.models.*
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WorkoutRepository @Inject constructor(
    private val workoutDao: WorkoutDao,
    private val gson: Gson,
    private val backendApiClient: BackendApiClient
) {
    companion object {
        private const val TAG = "WorkoutRepository"
    }

    // ==================== Workouts ====================

    /**
     * Get today's workout.
     * First tries local database, then falls back to backend API if authenticated.
     */
    suspend fun getTodaysWorkout(): WearWorkout? {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        val localWorkout = workoutDao.getTodaysWorkout(startOfDay, endOfDay)?.toWearWorkoutWithJson()

        // If we have local data, return it
        if (localWorkout != null) {
            Log.d(TAG, "Returning local workout: ${localWorkout.name}")
            return localWorkout
        }

        // No local data - try fetching from backend
        return fetchWorkoutFromBackend()
    }

    /**
     * Fetch today's workout from backend API.
     * Caches the result locally for offline access.
     */
    suspend fun fetchWorkoutFromBackend(): WearWorkout? {
        if (!backendApiClient.isAuthenticated()) {
            Log.d(TAG, "Not authenticated, skipping backend fetch")
            return null
        }

        return try {
            Log.d(TAG, "Fetching workout from backend")
            val workout = backendApiClient.getTodaysWorkout()
            if (workout != null) {
                Log.d(TAG, "✅ Got workout from backend: ${workout.name}")
                // Cache locally
                saveWorkout(workout)
            }
            workout
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch workout from backend", e)
            null
        }
    }

    fun observeTodaysWorkout(): Flow<WearWorkout?> {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        return workoutDao.observeTodaysWorkout(startOfDay, endOfDay)
            .map { it?.toWearWorkoutWithJson() }
    }

    suspend fun getWorkoutById(id: String): WearWorkout? {
        return workoutDao.getWorkoutById(id)?.toWearWorkoutWithJson()
    }

    suspend fun saveWorkout(workout: WearWorkout) {
        val exercisesJson = gson.toJson(workout.exercises)
        val muscleGroupsJson = gson.toJson(workout.targetMuscleGroups)
        workoutDao.insertWorkout(workout.toEntity(exercisesJson, muscleGroupsJson))
    }

    suspend fun saveWorkouts(workouts: List<WearWorkout>) {
        val entities = workouts.map { workout ->
            val exercisesJson = gson.toJson(workout.exercises)
            val muscleGroupsJson = gson.toJson(workout.targetMuscleGroups)
            workout.toEntity(exercisesJson, muscleGroupsJson)
        }
        workoutDao.insertWorkouts(entities)
    }

    suspend fun markWorkoutCompleted(workoutId: String) {
        workoutDao.markWorkoutCompleted(workoutId)
    }

    // ==================== Workout Sessions ====================

    suspend fun getActiveSession(): WearWorkoutSession? {
        return workoutDao.getActiveSession()?.toWearWorkoutSession()
    }

    fun observeActiveSession(): Flow<WearWorkoutSession?> {
        return workoutDao.observeActiveSession().map { it?.toWearWorkoutSession() }
    }

    suspend fun startWorkoutSession(workout: WearWorkout, deviceId: String): WearWorkoutSession {
        val session = WearWorkoutSession(
            id = UUID.randomUUID().toString(),
            workoutId = workout.id,
            workoutName = workout.name,
            deviceId = deviceId,
            startedAt = System.currentTimeMillis()
        )
        workoutDao.insertSession(session.toEntity())
        return session
    }

    suspend fun updateSession(session: WearWorkoutSession) {
        workoutDao.updateSession(session.toEntity())
    }

    suspend fun completeSession(
        sessionId: String,
        avgHeartRate: Int?,
        maxHeartRate: Int?,
        caloriesBurned: Int?
    ) {
        val totalSets = workoutDao.getTotalSetsForSession(sessionId)
        val totalReps = workoutDao.getTotalRepsForSession(sessionId) ?: 0
        val totalVolume = workoutDao.getTotalVolumeForSession(sessionId) ?: 0f

        workoutDao.completeSession(
            id = sessionId,
            totalSets = totalSets,
            totalReps = totalReps,
            totalVolumeKg = totalVolume,
            avgHeartRate = avgHeartRate,
            maxHeartRate = maxHeartRate,
            caloriesBurned = caloriesBurned
        )
    }

    suspend fun abandonSession(sessionId: String) {
        val session = workoutDao.getSessionById(sessionId)
        if (session != null) {
            workoutDao.updateSession(
                session.copy(
                    status = SessionStatus.ABANDONED.name,
                    endedAt = System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis()
                )
            )
        }
    }

    // ==================== Set Logs ====================

    suspend fun logSet(setLog: WearSetLog) {
        workoutDao.insertSetLog(setLog.toEntity())
    }

    suspend fun getSetLogsForSession(sessionId: String): List<WearSetLog> {
        return workoutDao.getSetLogsForSession(sessionId).map { it.toWearSetLog() }
    }

    fun observeSetLogsForSession(sessionId: String): Flow<List<WearSetLog>> {
        return workoutDao.observeSetLogsForSession(sessionId).map { list ->
            list.map { it.toWearSetLog() }
        }
    }

    suspend fun getCompletedSetsCount(sessionId: String, exerciseId: String): Int {
        return workoutDao.getCompletedSetsCount(sessionId, exerciseId)
    }

    suspend fun getSetLogsForExercise(sessionId: String, exerciseId: String): List<WearSetLog> {
        return workoutDao.getSetLogsForExercise(sessionId, exerciseId).map { it.toWearSetLog() }
    }

    // ==================== Sync ====================

    suspend fun getUnsyncedSessions(): List<WearWorkoutSession> {
        return workoutDao.getUnsyncedSessions().map { it.toWearWorkoutSession() }
    }

    suspend fun getUnsyncedSetLogs(): List<WearSetLog> {
        return workoutDao.getUnsyncedSetLogs().map { it.toWearSetLog() }
    }

    suspend fun markSessionSynced(sessionId: String) {
        workoutDao.markSessionSynced(sessionId)
    }

    suspend fun markSetLogSynced(setLogId: String) {
        workoutDao.markSetLogSynced(setLogId)
    }

    // ==================== Stats ====================

    suspend fun getSessionStats(sessionId: String): SessionStats {
        return SessionStats(
            totalSets = workoutDao.getTotalSetsForSession(sessionId),
            totalReps = workoutDao.getTotalRepsForSession(sessionId) ?: 0,
            totalVolumeKg = workoutDao.getTotalVolumeForSession(sessionId) ?: 0f
        )
    }

    // ==================== Helpers ====================

    private fun CachedWorkoutEntity.toWearWorkoutWithJson(): WearWorkout {
        val exercises: List<WearExercise> = try {
            val type = object : TypeToken<List<WearExercise>>() {}.type
            gson.fromJson(exercisesJson, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }

        val muscleGroups: List<String> = try {
            val type = object : TypeToken<List<String>>() {}.type
            gson.fromJson(targetMuscleGroupsJson, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }

        return toWearWorkout(exercises, muscleGroups)
    }

    private fun getDayBounds(timestamp: Long): Pair<Long, Long> {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = timestamp
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfDay = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        val endOfDay = calendar.timeInMillis
        return startOfDay to endOfDay
    }
}

data class SessionStats(
    val totalSets: Int,
    val totalReps: Int,
    val totalVolumeKg: Float
)
