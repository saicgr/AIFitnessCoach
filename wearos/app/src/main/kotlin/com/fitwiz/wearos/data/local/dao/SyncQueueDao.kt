package com.fitwiz.wearos.data.local.dao

import androidx.room.*
import com.fitwiz.wearos.data.local.entity.SyncQueueEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SyncQueueDao {

    // ==================== Queue Management ====================

    @Query("SELECT * FROM sync_queue WHERE status = 'pending' ORDER BY priority DESC, createdAt ASC")
    suspend fun getPendingItems(): List<SyncQueueEntity>

    @Query("SELECT * FROM sync_queue WHERE status = 'pending' ORDER BY priority DESC, createdAt ASC")
    fun observePendingItems(): Flow<List<SyncQueueEntity>>

    @Query("SELECT COUNT(*) FROM sync_queue WHERE status = 'pending'")
    suspend fun getPendingCount(): Int

    @Query("SELECT COUNT(*) FROM sync_queue WHERE status = 'pending'")
    fun observePendingCount(): Flow<Int>

    @Query("SELECT * FROM sync_queue WHERE id = :id")
    suspend fun getItemById(id: String): SyncQueueEntity?

    @Query("SELECT * FROM sync_queue WHERE syncType = :syncType AND status = 'pending' ORDER BY createdAt ASC")
    suspend fun getPendingItemsByType(syncType: String): List<SyncQueueEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItem(item: SyncQueueEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItems(items: List<SyncQueueEntity>)

    @Update
    suspend fun updateItem(item: SyncQueueEntity)

    @Delete
    suspend fun deleteItem(item: SyncQueueEntity)

    @Query("DELETE FROM sync_queue WHERE id = :id")
    suspend fun deleteItemById(id: String)

    // ==================== Status Updates ====================

    @Query("UPDATE sync_queue SET status = 'syncing' WHERE id = :id")
    suspend fun markSyncing(id: String)

    @Query("UPDATE sync_queue SET status = 'completed', syncedAt = :syncedAt WHERE id = :id")
    suspend fun markCompleted(id: String, syncedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE sync_queue
        SET status = 'failed',
            retryCount = retryCount + 1,
            errorMessage = :errorMessage
        WHERE id = :id
    """)
    suspend fun markFailed(id: String, errorMessage: String?)

    @Query("""
        UPDATE sync_queue
        SET status = 'pending',
            errorMessage = NULL
        WHERE id = :id AND retryCount < maxRetries
    """)
    suspend fun retryItem(id: String)

    // ==================== Batch Operations ====================

    @Query("UPDATE sync_queue SET status = 'pending' WHERE status = 'syncing'")
    suspend fun resetStuckItems()

    @Query("DELETE FROM sync_queue WHERE status = 'completed'")
    suspend fun clearCompletedItems()

    @Query("DELETE FROM sync_queue WHERE status = 'failed' AND retryCount >= maxRetries")
    suspend fun clearFailedItems()

    @Query("DELETE FROM sync_queue WHERE createdAt < :cutoffDate AND status IN ('completed', 'failed')")
    suspend fun clearOldItems(cutoffDate: Long)

    // ==================== Stats ====================

    @Query("SELECT COUNT(*) FROM sync_queue WHERE status = 'failed'")
    suspend fun getFailedCount(): Int

    @Query("SELECT * FROM sync_queue WHERE status = 'failed' ORDER BY createdAt DESC LIMIT :limit")
    suspend fun getFailedItems(limit: Int = 10): List<SyncQueueEntity>

    @Query("SELECT syncType, COUNT(*) as count FROM sync_queue WHERE status = 'pending' GROUP BY syncType")
    suspend fun getPendingCountByType(): List<SyncTypeCount>
}

data class SyncTypeCount(
    val syncType: String,
    val count: Int
)
