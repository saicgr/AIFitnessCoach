package com.fitwiz.wearos.di

import android.content.Context
import androidx.room.Room
import com.fitwiz.wearos.data.local.WearDatabase
import com.fitwiz.wearos.data.local.dao.FastingDao
import com.fitwiz.wearos.data.local.dao.FoodLogDao
import com.fitwiz.wearos.data.local.dao.HealthDataDao
import com.fitwiz.wearos.data.local.dao.SyncQueueDao
import com.fitwiz.wearos.data.local.dao.WorkoutDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideWearDatabase(
        @ApplicationContext context: Context
    ): WearDatabase {
        return Room.databaseBuilder(
            context,
            WearDatabase::class.java,
            WearDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    @Singleton
    fun provideWorkoutDao(database: WearDatabase): WorkoutDao {
        return database.workoutDao()
    }

    @Provides
    @Singleton
    fun provideFoodLogDao(database: WearDatabase): FoodLogDao {
        return database.foodLogDao()
    }

    @Provides
    @Singleton
    fun provideFastingDao(database: WearDatabase): FastingDao {
        return database.fastingDao()
    }

    @Provides
    @Singleton
    fun provideSyncQueueDao(database: WearDatabase): SyncQueueDao {
        return database.syncQueueDao()
    }

    @Provides
    @Singleton
    fun provideHealthDataDao(database: WearDatabase): HealthDataDao {
        return database.healthDataDao()
    }
}
