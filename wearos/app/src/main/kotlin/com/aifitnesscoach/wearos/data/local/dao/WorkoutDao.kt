package com.fitwiz.wearos.data.local.dao

import androidx.room.*
import com.fitwiz.wearos.data.local.entity.CachedWorkoutEntity
import com.fitwiz.wearos.data.local.entity.SetLogEntity
import com.fitwiz.wearos.data.local.entity.WorkoutSessionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface WorkoutDao {

    // ==================== Cached Workouts ====================

    @Query("SELECT * FROM cached_workouts WHERE scheduledDate >= :startOfDay AND scheduledDate < :endOfDay LIMIT 1")
    suspend fun getTodaysWorkout(startOfDay: Long, endOfDay: Long): CachedWorkoutEntity?

    @Query("SELECT * FROM cached_workouts WHERE scheduledDate >= :startOfDay AND scheduledDate < :endOfDay LIMIT 1")
    fun observeTodaysWorkout(startOfDay: Long, endOfDay: Long): Flow<CachedWorkoutEntity?>

    @Query("SELECT * FROM cached_workouts WHERE id = :id")
    suspend fun getWorkoutById(id: String): CachedWorkoutEntity?

    @Query("SELECT * FROM cached_workouts ORDER BY scheduledDate DESC")
    fun observeAllWorkouts(): Flow<List<CachedWorkoutEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWorkout(workout: CachedWorkoutEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWorkouts(workouts: List<CachedWorkoutEntity>)

    @Update
    suspend fun updateWorkout(workout: CachedWorkoutEntity)

    @Query("UPDATE cached_workouts SET isCompleted = :isCompleted, updatedAt = :updatedAt WHERE id = :id")
    suspend fun markWorkoutCompleted(id: String, isCompleted: Boolean = true, updatedAt: Long = System.currentTimeMillis())

    @Delete
    suspend fun deleteWorkout(workout: CachedWorkoutEntity)

    @Query("DELETE FROM cached_workouts WHERE scheduledDate < :cutoffDate")
    suspend fun deleteOldWorkouts(cutoffDate: Long)

    // ==================== Workout Sessions ====================

    @Query("SELECT * FROM workout_sessions WHERE status = 'IN_PROGRESS' ORDER BY startedAt DESC LIMIT 1")
    suspend fun getActiveSession(): WorkoutSessionEntity?

    @Query("SELECT * FROM workout_sessions WHERE status = 'IN_PROGRESS' ORDER BY startedAt DESC LIMIT 1")
    fun observeActiveSession(): Flow<WorkoutSessionEntity?>

    @Query("SELECT * FROM workout_sessions WHERE id = :id")
    suspend fun getSessionById(id: String): WorkoutSessionEntity?

    @Query("SELECT * FROM workout_sessions ORDER BY startedAt DESC LIMIT :limit")
    fun observeRecentSessions(limit: Int = 10): Flow<List<WorkoutSessionEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSession(session: WorkoutSessionEntity)

    @Update
    suspend fun updateSession(session: WorkoutSessionEntity)

    @Query("""
        UPDATE workout_sessions
        SET status = :status,
            endedAt = :endedAt,
            totalSets = :totalSets,
            totalReps = :totalReps,
            totalVolumeKg = :totalVolumeKg,
            avgHeartRate = :avgHeartRate,
            maxHeartRate = :maxHeartRate,
            caloriesBurned = :caloriesBurned,
            updatedAt = :updatedAt
        WHERE id = :id
    """)
    suspend fun completeSession(
        id: String,
        status: String = "COMPLETED",
        endedAt: Long = System.currentTimeMillis(),
        totalSets: Int,
        totalReps: Int,
        totalVolumeKg: Float,
        avgHeartRate: Int?,
        maxHeartRate: Int?,
        caloriesBurned: Int?,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("UPDATE workout_sessions SET syncedToPhone = 1, updatedAt = :updatedAt WHERE id = :id")
    suspend fun markSessionSynced(id: String, updatedAt: Long = System.currentTimeMillis())

    @Query("SELECT * FROM workout_sessions WHERE syncedToPhone = 0")
    suspend fun getUnsyncedSessions(): List<WorkoutSessionEntity>

    // ==================== Set Logs ====================

    @Query("SELECT * FROM set_logs WHERE sessionId = :sessionId ORDER BY loggedAt ASC")
    suspend fun getSetLogsForSession(sessionId: String): List<SetLogEntity>

    @Query("SELECT * FROM set_logs WHERE sessionId = :sessionId ORDER BY loggedAt ASC")
    fun observeSetLogsForSession(sessionId: String): Flow<List<SetLogEntity>>

    @Query("SELECT * FROM set_logs WHERE sessionId = :sessionId AND exerciseId = :exerciseId ORDER BY setNumber ASC")
    suspend fun getSetLogsForExercise(sessionId: String, exerciseId: String): List<SetLogEntity>

    @Query("SELECT COUNT(*) FROM set_logs WHERE sessionId = :sessionId AND exerciseId = :exerciseId")
    suspend fun getCompletedSetsCount(sessionId: String, exerciseId: String): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSetLog(setLog: SetLogEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSetLogs(setLogs: List<SetLogEntity>)

    @Update
    suspend fun updateSetLog(setLog: SetLogEntity)

    @Delete
    suspend fun deleteSetLog(setLog: SetLogEntity)

    @Query("DELETE FROM set_logs WHERE sessionId = :sessionId")
    suspend fun deleteSetLogsForSession(sessionId: String)

    @Query("SELECT * FROM set_logs WHERE syncedAt IS NULL")
    suspend fun getUnsyncedSetLogs(): List<SetLogEntity>

    @Query("UPDATE set_logs SET syncedAt = :syncedAt WHERE id = :id")
    suspend fun markSetLogSynced(id: String, syncedAt: Long = System.currentTimeMillis())

    // ==================== Stats Queries ====================

    @Query("SELECT SUM(actualReps * COALESCE(weightKg, 0)) FROM set_logs WHERE sessionId = :sessionId")
    suspend fun getTotalVolumeForSession(sessionId: String): Float?

    @Query("SELECT SUM(actualReps) FROM set_logs WHERE sessionId = :sessionId")
    suspend fun getTotalRepsForSession(sessionId: String): Int?

    @Query("SELECT COUNT(*) FROM set_logs WHERE sessionId = :sessionId")
    suspend fun getTotalSetsForSession(sessionId: String): Int
}
