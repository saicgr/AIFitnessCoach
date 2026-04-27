package com.fitwiz.wearos.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Room entity for storing daily health data aggregates.
 * Stores both watch-collected and phone-synced health data.
 */
@Entity(
    tableName = "daily_health_data",
    indices = [Index("date", unique = true)]
)
data class DailyHealthDataEntity(
    @PrimaryKey
    val id: String,
    val date: String, // ISO date format "2024-01-15"

    // Steps
    val watchSteps: Int = 0,
    val phoneSteps: Int = 0,
    val totalSteps: Int = 0,

    // Distance in meters
    val watchDistanceMeters: Float = 0f,
    val phoneDistanceMeters: Float = 0f,
    val totalDistanceMeters: Float = 0f,

    // Calories burned
    val watchCalories: Int = 0,
    val phoneCalories: Int = 0,
    val totalCalories: Int = 0,

    // Active minutes
    val watchActiveMinutes: Int = 0,
    val phoneActiveMinutes: Int = 0,
    val totalActiveMinutes: Int = 0,

    // Floors climbed
    val floorsClimbed: Int = 0,

    // Heart rate stats
    val avgHeartRate: Int? = null,
    val maxHeartRate: Int? = null,
    val minHeartRate: Int? = null,
    val restingHeartRate: Int? = null,

    // Sleep data (usually from phone)
    val sleepStartTime: Long? = null,
    val sleepEndTime: Long? = null,
    val sleepDurationMinutes: Int? = null,
    val deepSleepMinutes: Int? = null,
    val lightSleepMinutes: Int? = null,
    val remSleepMinutes: Int? = null,

    // Workouts
    val workoutsCompleted: Int = 0,
    val totalWorkoutMinutes: Int = 0,

    // Goals
    val stepsGoal: Int = 10000,
    val caloriesGoal: Int = 500,
    val activeMinutesGoal: Int = 30,
    val floorsGoal: Int = 10,

    // Timestamps
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val lastWatchSyncAt: Long? = null,
    val lastPhoneSyncAt: Long? = null
)

/**
 * Room entity for individual heart rate samples.
 * Stores each heart rate reading for detailed analysis.
 */
@Entity(
    tableName = "heart_rate_samples",
    indices = [Index("date"), Index("timestamp")]
)
data class HeartRateSampleEntity(
    @PrimaryKey
    val id: String,
    val date: String, // ISO date format
    val timestamp: Long,
    val bpm: Int,
    val source: String = "watch", // "watch", "phone", "workout"
    val activityType: String? = null, // "rest", "workout", "walking", etc.
    val synced: Boolean = false
)

/**
 * Room entity for passive health data points.
 * Stores individual data points from passive monitoring.
 */
@Entity(
    tableName = "passive_health_data",
    indices = [Index("date"), Index("dataType"), Index("synced")]
)
data class PassiveHealthDataEntity(
    @PrimaryKey
    val id: String,
    val date: String,
    val dataType: String, // "steps", "calories", "distance", "floors"
    val value: Float,
    val unit: String,
    val timestamp: Long,
    val source: String = "passive_monitoring",
    val synced: Boolean = false
)
