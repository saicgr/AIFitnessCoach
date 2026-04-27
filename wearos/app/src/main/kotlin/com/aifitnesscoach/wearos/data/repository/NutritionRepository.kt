package com.fitwiz.wearos.data.repository

import android.util.Log
import com.fitwiz.wearos.data.api.BackendApiClient
import com.fitwiz.wearos.data.local.dao.FoodLogDao
import com.fitwiz.wearos.data.local.entity.FoodLogEntity
import com.fitwiz.wearos.data.local.entity.toEntity
import com.fitwiz.wearos.data.local.entity.toWearFoodEntry
import com.fitwiz.wearos.data.models.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NutritionRepository @Inject constructor(
    private val foodLogDao: FoodLogDao,
    private val backendApiClient: BackendApiClient
) {
    companion object {
        private const val TAG = "NutritionRepository"
    }

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    // ==================== Food Logs ====================

    suspend fun logFood(foodEntry: WearFoodEntry) {
        foodLogDao.insertFoodLog(foodEntry.toEntity())
    }

    suspend fun updateFoodLog(foodEntry: WearFoodEntry) {
        foodLogDao.updateFoodLog(foodEntry.toEntity())
    }

    suspend fun deleteFoodLog(id: String) {
        foodLogDao.deleteFoodLogById(id)
    }

    suspend fun getFoodLogById(id: String): WearFoodEntry? {
        return foodLogDao.getFoodLogById(id)?.toWearFoodEntry()
    }

    suspend fun getTodaysFoodLogs(): List<WearFoodEntry> {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        return foodLogDao.getTodaysFoodLogs(startOfDay, endOfDay).map { it.toWearFoodEntry() }
    }

    fun observeTodaysFoodLogs(): Flow<List<WearFoodEntry>> {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        return foodLogDao.observeTodaysFoodLogs(startOfDay, endOfDay)
            .map { list -> list.map { it.toWearFoodEntry() } }
    }

    suspend fun getRecentFoodLogs(limit: Int = 20): List<WearFoodEntry> {
        return foodLogDao.getRecentFoodLogs(limit).map { it.toWearFoodEntry() }
    }

    fun observeRecentFoodLogs(limit: Int = 20): Flow<List<WearFoodEntry>> {
        return foodLogDao.observeRecentFoodLogs(limit)
            .map { list -> list.map { it.toWearFoodEntry() } }
    }

    // ==================== Daily Summary ====================

    /**
     * Get today's nutrition summary.
     * First tries local database, then falls back to backend API if authenticated.
     */
    suspend fun getTodaysSummary(): WearNutritionSummary {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        val meals = foodLogDao.getTodaysFoodLogs(startOfDay, endOfDay).map { it.toWearFoodEntry() }

        // If we have local data, return it
        if (meals.isNotEmpty()) {
            return WearNutritionSummary(
                date = startOfDay,
                totalCalories = foodLogDao.getTotalCaloriesForDay(startOfDay, endOfDay),
                proteinG = foodLogDao.getTotalProteinForDay(startOfDay, endOfDay),
                carbsG = foodLogDao.getTotalCarbsForDay(startOfDay, endOfDay),
                fatG = foodLogDao.getTotalFatForDay(startOfDay, endOfDay),
                fiberG = foodLogDao.getTotalFiberForDay(startOfDay, endOfDay),
                meals = meals
            )
        }

        // No local data - try fetching from backend
        return fetchNutritionFromBackend() ?: WearNutritionSummary(
            date = startOfDay,
            totalCalories = 0,
            proteinG = 0f,
            carbsG = 0f,
            fatG = 0f,
            fiberG = 0f,
            meals = emptyList()
        )
    }

    /**
     * Fetch nutrition summary from backend API.
     * Returns null if not authenticated or API call fails.
     */
    suspend fun fetchNutritionFromBackend(): WearNutritionSummary? {
        if (!backendApiClient.isAuthenticated()) {
            Log.d(TAG, "Not authenticated, skipping backend fetch")
            return null
        }

        return try {
            val today = dateFormat.format(Date())
            Log.d(TAG, "Fetching nutrition from backend for $today")
            val summary = backendApiClient.getNutritionSummary(today)
            if (summary != null) {
                Log.d(TAG, "✅ Got nutrition from backend: ${summary.totalCalories} cal")
            }
            summary
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch nutrition from backend", e)
            null
        }
    }

    fun observeTodaysSummary(): Flow<WearNutritionSummary> {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())

        return foodLogDao.observeTodaysFoodLogs(startOfDay, endOfDay)
            .map { logs ->
                val meals = logs.map { it.toWearFoodEntry() }
                WearNutritionSummary(
                    date = startOfDay,
                    totalCalories = meals.sumOf { it.calories },
                    proteinG = meals.mapNotNull { it.proteinG }.sum(),
                    carbsG = meals.mapNotNull { it.carbsG }.sum(),
                    fatG = meals.mapNotNull { it.fatG }.sum(),
                    fiberG = meals.mapNotNull { it.fiberG }.sum(),
                    meals = meals
                )
            }
    }

    fun observeTotalCaloriesToday(): Flow<Int> {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        return foodLogDao.observeTotalCaloriesForDay(startOfDay, endOfDay)
    }

    // ==================== Meal Type Queries ====================

    suspend fun getFoodLogsForMeal(mealType: MealType): List<WearFoodEntry> {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        return foodLogDao.getFoodLogsForMeal(startOfDay, endOfDay, mealType.name)
            .map { it.toWearFoodEntry() }
    }

    suspend fun getCaloriesForMeal(mealType: MealType): Int {
        val (startOfDay, endOfDay) = getDayBounds(System.currentTimeMillis())
        return foodLogDao.getCaloriesForMeal(startOfDay, endOfDay, mealType.name)
    }

    // ==================== Suggestions ====================

    suspend fun getRecentFoodNames(limit: Int = 10): List<String> {
        return foodLogDao.getRecentFoodNames(limit)
    }

    suspend fun searchFoodLogs(query: String, limit: Int = 10): List<WearFoodEntry> {
        return foodLogDao.searchFoodLogs(query, limit).map { it.toWearFoodEntry() }
    }

    // ==================== Water ====================

    suspend fun logWater(amountMl: Int) {
        // Water logging - currently a no-op as water tracking
        // is synced to phone via DataLayer
        // TODO: Add local water tracking storage if needed
    }

    // ==================== Sync ====================

    suspend fun getUnsyncedFoodLogs(): List<WearFoodEntry> {
        return foodLogDao.getUnsyncedFoodLogs().map { it.toWearFoodEntry() }
    }

    suspend fun markFoodLogSynced(id: String, phoneFoodLogId: String?) {
        foodLogDao.markFoodLogSynced(id, phoneFoodLogId)
    }

    // ==================== Helpers ====================

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
