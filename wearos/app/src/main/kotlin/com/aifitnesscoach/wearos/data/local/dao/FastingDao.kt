package com.fitwiz.wearos.data.local.dao

import androidx.room.*
import com.fitwiz.wearos.data.local.entity.FastingHistoryEntity
import com.fitwiz.wearos.data.local.entity.FastingStateEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface FastingDao {

    // ==================== Current Fasting State ====================

    @Query("SELECT * FROM fasting_state WHERE status IN ('ACTIVE', 'PAUSED') ORDER BY createdAt DESC LIMIT 1")
    suspend fun getActiveFastingSession(): FastingStateEntity?

    @Query("SELECT * FROM fasting_state WHERE status IN ('ACTIVE', 'PAUSED') ORDER BY createdAt DESC LIMIT 1")
    fun observeActiveFastingSession(): Flow<FastingStateEntity?>

    @Query("SELECT * FROM fasting_state ORDER BY createdAt DESC LIMIT 1")
    suspend fun getLatestFastingSession(): FastingStateEntity?

    @Query("SELECT * FROM fasting_state WHERE id = :id")
    suspend fun getFastingSessionById(id: String): FastingStateEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFastingSession(session: FastingStateEntity)

    @Update
    suspend fun updateFastingSession(session: FastingStateEntity)

    @Query("""
        UPDATE fasting_state
        SET status = 'ACTIVE',
            startTime = :startTime,
            pausedAt = NULL,
            pausedDurationMs = 0,
            endedAt = NULL,
            updatedAt = :updatedAt
        WHERE id = :id
    """)
    suspend fun startFast(id: String, startTime: Long = System.currentTimeMillis(), updatedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE fasting_state
        SET status = 'PAUSED',
            pausedAt = :pausedAt,
            updatedAt = :updatedAt
        WHERE id = :id
    """)
    suspend fun pauseFast(id: String, pausedAt: Long = System.currentTimeMillis(), updatedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE fasting_state
        SET status = 'ACTIVE',
            pausedAt = NULL,
            pausedDurationMs = pausedDurationMs + :additionalPauseDuration,
            updatedAt = :updatedAt
        WHERE id = :id
    """)
    suspend fun resumeFast(id: String, additionalPauseDuration: Long, updatedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE fasting_state
        SET status = :status,
            endedAt = :endedAt,
            updatedAt = :updatedAt
        WHERE id = :id
    """)
    suspend fun endFast(id: String, status: String, endedAt: Long = System.currentTimeMillis(), updatedAt: Long = System.currentTimeMillis())

    @Query("UPDATE fasting_state SET syncedToPhone = 1, phoneFastingRecordId = :phoneFastingRecordId, updatedAt = :updatedAt WHERE id = :id")
    suspend fun markFastingSynced(id: String, phoneFastingRecordId: String?, updatedAt: Long = System.currentTimeMillis())

    @Query("SELECT * FROM fasting_state WHERE syncedToPhone = 0")
    suspend fun getUnsyncedFastingSessions(): List<FastingStateEntity>

    @Delete
    suspend fun deleteFastingSession(session: FastingStateEntity)

    // ==================== Fasting History ====================

    @Query("SELECT * FROM fasting_history ORDER BY startTime DESC LIMIT :limit")
    suspend fun getFastingHistory(limit: Int = 30): List<FastingHistoryEntity>

    @Query("SELECT * FROM fasting_history ORDER BY startTime DESC LIMIT :limit")
    fun observeFastingHistory(limit: Int = 30): Flow<List<FastingHistoryEntity>>

    @Query("SELECT * FROM fasting_history WHERE startTime >= :startOfDay AND startTime < :endOfDay ORDER BY startTime DESC")
    suspend fun getFastingHistoryForDay(startOfDay: Long, endOfDay: Long): List<FastingHistoryEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFastingHistory(history: FastingHistoryEntity)

    @Query("DELETE FROM fasting_history WHERE startTime < :cutoffDate")
    suspend fun deleteOldHistory(cutoffDate: Long)

    // ==================== Streak Calculations ====================

    @Query("SELECT COUNT(*) FROM fasting_history WHERE wasCompleted = 1")
    suspend fun getTotalCompletedFasts(): Int

    @Query("SELECT * FROM fasting_history WHERE wasCompleted = 1 ORDER BY startTime DESC LIMIT 1")
    suspend fun getLastCompletedFast(): FastingHistoryEntity?

    @Query("""
        SELECT COUNT(*) FROM fasting_history
        WHERE wasCompleted = 1
        AND startTime >= :startDate
    """)
    suspend fun getCompletedFastsAfterDate(startDate: Long): Int

    // Get consecutive days with completed fasts for streak calculation
    @Query("""
        SELECT DISTINCT DATE(startTime / 1000, 'unixepoch') as fastDate
        FROM fasting_history
        WHERE wasCompleted = 1
        ORDER BY startTime DESC
        LIMIT :maxDays
    """)
    suspend fun getRecentFastDates(maxDays: Int = 365): List<String>
}
