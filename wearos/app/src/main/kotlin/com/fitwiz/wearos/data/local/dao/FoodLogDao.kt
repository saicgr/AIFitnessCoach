package com.fitwiz.wearos.data.local.dao

import androidx.room.*
import com.fitwiz.wearos.data.local.entity.FoodLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface FoodLogDao {

    // ==================== Food Logs ====================

    @Query("SELECT * FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay ORDER BY loggedAt DESC")
    suspend fun getTodaysFoodLogs(startOfDay: Long, endOfDay: Long): List<FoodLogEntity>

    @Query("SELECT * FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay ORDER BY loggedAt DESC")
    fun observeTodaysFoodLogs(startOfDay: Long, endOfDay: Long): Flow<List<FoodLogEntity>>

    @Query("SELECT * FROM food_logs WHERE id = :id")
    suspend fun getFoodLogById(id: String): FoodLogEntity?

    @Query("SELECT * FROM food_logs ORDER BY loggedAt DESC LIMIT :limit")
    suspend fun getRecentFoodLogs(limit: Int = 20): List<FoodLogEntity>

    @Query("SELECT * FROM food_logs ORDER BY loggedAt DESC LIMIT :limit")
    fun observeRecentFoodLogs(limit: Int = 20): Flow<List<FoodLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFoodLog(foodLog: FoodLogEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFoodLogs(foodLogs: List<FoodLogEntity>)

    @Update
    suspend fun updateFoodLog(foodLog: FoodLogEntity)

    @Delete
    suspend fun deleteFoodLog(foodLog: FoodLogEntity)

    @Query("DELETE FROM food_logs WHERE id = :id")
    suspend fun deleteFoodLogById(id: String)

    // ==================== Sync ====================

    @Query("SELECT * FROM food_logs WHERE syncedToPhone = 0")
    suspend fun getUnsyncedFoodLogs(): List<FoodLogEntity>

    @Query("UPDATE food_logs SET syncedToPhone = 1, phoneFoodLogId = :phoneFoodLogId WHERE id = :id")
    suspend fun markFoodLogSynced(id: String, phoneFoodLogId: String?)

    // ==================== Daily Summary ====================

    @Query("SELECT COALESCE(SUM(calories), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay")
    suspend fun getTotalCaloriesForDay(startOfDay: Long, endOfDay: Long): Int

    @Query("SELECT COALESCE(SUM(calories), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay")
    fun observeTotalCaloriesForDay(startOfDay: Long, endOfDay: Long): Flow<Int>

    @Query("SELECT COALESCE(SUM(proteinG), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay")
    suspend fun getTotalProteinForDay(startOfDay: Long, endOfDay: Long): Float

    @Query("SELECT COALESCE(SUM(carbsG), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay")
    suspend fun getTotalCarbsForDay(startOfDay: Long, endOfDay: Long): Float

    @Query("SELECT COALESCE(SUM(fatG), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay")
    suspend fun getTotalFatForDay(startOfDay: Long, endOfDay: Long): Float

    @Query("SELECT COALESCE(SUM(fiberG), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay")
    suspend fun getTotalFiberForDay(startOfDay: Long, endOfDay: Long): Float

    // ==================== Meal Type Queries ====================

    @Query("SELECT * FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay AND mealType = :mealType ORDER BY loggedAt DESC")
    suspend fun getFoodLogsForMeal(startOfDay: Long, endOfDay: Long, mealType: String): List<FoodLogEntity>

    @Query("SELECT COALESCE(SUM(calories), 0) FROM food_logs WHERE loggedAt >= :startOfDay AND loggedAt < :endOfDay AND mealType = :mealType")
    suspend fun getCaloriesForMeal(startOfDay: Long, endOfDay: Long, mealType: String): Int

    // ==================== Search & Suggestions ====================

    @Query("SELECT DISTINCT foodName FROM food_logs WHERE foodName IS NOT NULL ORDER BY loggedAt DESC LIMIT :limit")
    suspend fun getRecentFoodNames(limit: Int = 10): List<String>

    @Query("SELECT * FROM food_logs WHERE foodName LIKE '%' || :query || '%' ORDER BY loggedAt DESC LIMIT :limit")
    suspend fun searchFoodLogs(query: String, limit: Int = 10): List<FoodLogEntity>

    // ==================== Cleanup ====================

    @Query("DELETE FROM food_logs WHERE loggedAt < :cutoffDate AND syncedToPhone = 1")
    suspend fun deleteOldSyncedLogs(cutoffDate: Long)
}
