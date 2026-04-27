package com.fitwiz.wearos.data.local.dao

import androidx.room.*
import com.fitwiz.wearos.data.local.entity.DailyHealthDataEntity
import com.fitwiz.wearos.data.local.entity.HeartRateSampleEntity
import com.fitwiz.wearos.data.local.entity.PassiveHealthDataEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HealthDataDao {

    // ==================== Daily Health Data ====================

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDailyHealth(entity: DailyHealthDataEntity)

    @Update
    suspend fun updateDailyHealth(entity: DailyHealthDataEntity)

    @Query("SELECT * FROM daily_health_data WHERE date = :date")
    suspend fun getDailyHealth(date: String): DailyHealthDataEntity?

    @Query("SELECT * FROM daily_health_data WHERE date = :date")
    fun observeDailyHealth(date: String): Flow<DailyHealthDataEntity?>

    @Query("SELECT * FROM daily_health_data ORDER BY date DESC LIMIT :limit")
    suspend fun getRecentDailyHealth(limit: Int): List<DailyHealthDataEntity>

    @Query("SELECT * FROM daily_health_data ORDER BY date DESC LIMIT :limit")
    fun observeRecentDailyHealth(limit: Int): Flow<List<DailyHealthDataEntity>>

    @Query("SELECT * FROM daily_health_data WHERE date BETWEEN :startDate AND :endDate ORDER BY date ASC")
    suspend fun getDailyHealthRange(startDate: String, endDate: String): List<DailyHealthDataEntity>

    @Query("""
        UPDATE daily_health_data
        SET watchSteps = :steps,
            totalSteps = MAX(watchSteps, phoneSteps, :steps),
            updatedAt = :updatedAt,
            lastWatchSyncAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun updateWatchSteps(date: String, steps: Int, updatedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE daily_health_data
        SET watchCalories = :calories,
            totalCalories = MAX(watchCalories, phoneCalories, :calories),
            updatedAt = :updatedAt,
            lastWatchSyncAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun updateWatchCalories(date: String, calories: Int, updatedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE daily_health_data
        SET watchDistanceMeters = :distance,
            totalDistanceMeters = MAX(watchDistanceMeters, phoneDistanceMeters, :distance),
            updatedAt = :updatedAt,
            lastWatchSyncAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun updateWatchDistance(date: String, distance: Float, updatedAt: Long = System.currentTimeMillis())

    @Query("""
        UPDATE daily_health_data
        SET phoneSteps = :steps,
            phoneCalories = :calories,
            phoneDistanceMeters = :distance,
            phoneActiveMinutes = :activeMinutes,
            floorsClimbed = :floors,
            totalSteps = MAX(watchSteps, :steps),
            totalCalories = MAX(watchCalories, :calories),
            totalDistanceMeters = MAX(watchDistanceMeters, :distance),
            totalActiveMinutes = MAX(watchActiveMinutes, :activeMinutes),
            updatedAt = :updatedAt,
            lastPhoneSyncAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun updatePhoneHealthData(
        date: String,
        steps: Int,
        calories: Int,
        distance: Float,
        activeMinutes: Int,
        floors: Int,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE daily_health_data
        SET sleepStartTime = :startTime,
            sleepEndTime = :endTime,
            sleepDurationMinutes = :durationMinutes,
            deepSleepMinutes = :deepMinutes,
            lightSleepMinutes = :lightMinutes,
            remSleepMinutes = :remMinutes,
            updatedAt = :updatedAt,
            lastPhoneSyncAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun updateSleepData(
        date: String,
        startTime: Long,
        endTime: Long,
        durationMinutes: Int,
        deepMinutes: Int?,
        lightMinutes: Int?,
        remMinutes: Int?,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE daily_health_data
        SET avgHeartRate = :avg,
            maxHeartRate = :max,
            minHeartRate = :min,
            updatedAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun updateHeartRateStats(
        date: String,
        avg: Int?,
        max: Int?,
        min: Int?,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE daily_health_data
        SET workoutsCompleted = workoutsCompleted + 1,
            totalWorkoutMinutes = totalWorkoutMinutes + :durationMinutes,
            updatedAt = :updatedAt
        WHERE date = :date
    """)
    suspend fun incrementWorkoutStats(
        date: String,
        durationMinutes: Int,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("DELETE FROM daily_health_data WHERE date < :beforeDate")
    suspend fun deleteOldData(beforeDate: String)

    // ==================== Heart Rate Samples ====================

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHeartRateSample(sample: HeartRateSampleEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHeartRateSamples(samples: List<HeartRateSampleEntity>)

    @Query("SELECT * FROM heart_rate_samples WHERE date = :date ORDER BY timestamp ASC")
    suspend fun getHeartRateSamplesForDate(date: String): List<HeartRateSampleEntity>

    @Query("SELECT * FROM heart_rate_samples WHERE date = :date ORDER BY timestamp ASC")
    fun observeHeartRateSamplesForDate(date: String): Flow<List<HeartRateSampleEntity>>

    @Query("SELECT * FROM heart_rate_samples WHERE timestamp BETWEEN :startTime AND :endTime ORDER BY timestamp ASC")
    suspend fun getHeartRateSamplesInRange(startTime: Long, endTime: Long): List<HeartRateSampleEntity>

    @Query("SELECT * FROM heart_rate_samples ORDER BY timestamp DESC LIMIT 1")
    suspend fun getLatestHeartRateSample(): HeartRateSampleEntity?

    @Query("SELECT * FROM heart_rate_samples WHERE synced = 0 ORDER BY timestamp ASC")
    suspend fun getUnsyncedHeartRateSamples(): List<HeartRateSampleEntity>

    @Query("UPDATE heart_rate_samples SET synced = 1 WHERE id IN (:ids)")
    suspend fun markHeartRateSamplesSynced(ids: List<String>)

    @Query("DELETE FROM heart_rate_samples WHERE date < :beforeDate")
    suspend fun deleteOldHeartRateSamples(beforeDate: String)

    // ==================== Passive Health Data ====================

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPassiveHealthData(data: PassiveHealthDataEntity)

    @Query("SELECT * FROM passive_health_data WHERE date = :date AND dataType = :type ORDER BY timestamp DESC LIMIT 1")
    suspend fun getLatestPassiveData(date: String, type: String): PassiveHealthDataEntity?

    @Query("SELECT * FROM passive_health_data WHERE synced = 0 ORDER BY timestamp ASC")
    suspend fun getUnsyncedPassiveData(): List<PassiveHealthDataEntity>

    @Query("UPDATE passive_health_data SET synced = 1 WHERE id IN (:ids)")
    suspend fun markPassiveDataSynced(ids: List<String>)

    @Query("DELETE FROM passive_health_data WHERE date < :beforeDate")
    suspend fun deleteOldPassiveData(beforeDate: String)

    // ==================== Aggregations ====================

    @Query("""
        SELECT AVG(bpm) FROM heart_rate_samples
        WHERE date = :date AND activityType = 'rest'
    """)
    suspend fun getRestingHeartRateForDate(date: String): Int?

    @Query("""
        SELECT SUM(totalSteps) FROM daily_health_data
        WHERE date BETWEEN :startDate AND :endDate
    """)
    suspend fun getTotalStepsInRange(startDate: String, endDate: String): Int?

    @Query("""
        SELECT AVG(totalSteps) FROM daily_health_data
        WHERE date BETWEEN :startDate AND :endDate
    """)
    suspend fun getAverageStepsInRange(startDate: String, endDate: String): Float?
}
