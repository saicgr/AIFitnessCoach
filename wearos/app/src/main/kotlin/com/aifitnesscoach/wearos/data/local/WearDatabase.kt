package com.aifitnesscoach.wearos.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.aifitnesscoach.wearos.data.local.dao.FastingDao
import com.aifitnesscoach.wearos.data.local.dao.FoodLogDao
import com.aifitnesscoach.wearos.data.local.dao.HealthDataDao
import com.aifitnesscoach.wearos.data.local.dao.SyncQueueDao
import com.aifitnesscoach.wearos.data.local.dao.WorkoutDao
import com.aifitnesscoach.wearos.data.local.entity.*

@Database(
    entities = [
        CachedWorkoutEntity::class,
        WorkoutSessionEntity::class,
        SetLogEntity::class,
        FoodLogEntity::class,
        FastingStateEntity::class,
        FastingHistoryEntity::class,
        SyncQueueEntity::class,
        DailyHealthDataEntity::class,
        HeartRateSampleEntity::class,
        PassiveHealthDataEntity::class
    ],
    version = 2,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class WearDatabase : RoomDatabase() {

    abstract fun workoutDao(): WorkoutDao
    abstract fun foodLogDao(): FoodLogDao
    abstract fun fastingDao(): FastingDao
    abstract fun syncQueueDao(): SyncQueueDao
    abstract fun healthDataDao(): HealthDataDao

    companion object {
        const val DATABASE_NAME = "aifitnesscoach_wear_db"
    }
}
