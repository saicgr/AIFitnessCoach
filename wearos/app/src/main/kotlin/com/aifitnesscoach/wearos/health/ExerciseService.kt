package com.fitwiz.wearos.health

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.fitwiz.wearos.MainActivity
import com.fitwiz.wearos.R
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import javax.inject.Inject

/**
 * Foreground service for workout tracking
 * Keeps the app running during workouts and shows ongoing notification
 */
@AndroidEntryPoint
class ExerciseService : Service() {

    @Inject
    lateinit var exerciseClientManager: ExerciseClientManager

    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private var isExerciseActive = false

    inner class LocalBinder : Binder() {
        fun getService(): ExerciseService = this@ExerciseService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_EXERCISE -> startExercise()
            ACTION_PAUSE_EXERCISE -> pauseExercise()
            ACTION_RESUME_EXERCISE -> resumeExercise()
            ACTION_END_EXERCISE -> endExercise()
        }
        return START_STICKY
    }

    private fun startExercise() {
        if (isExerciseActive) return

        serviceScope.launch {
            val success = exerciseClientManager.startExercise()
            if (success) {
                isExerciseActive = true
                startForeground(NOTIFICATION_ID, createNotification("Workout in progress"))
            }
        }
    }

    private fun pauseExercise() {
        serviceScope.launch {
            exerciseClientManager.pauseExercise()
            updateNotification("Workout paused")
        }
    }

    private fun resumeExercise() {
        serviceScope.launch {
            exerciseClientManager.resumeExercise()
            updateNotification("Workout in progress")
        }
    }

    private fun endExercise() {
        serviceScope.launch {
            exerciseClientManager.endExercise()
            isExerciseActive = false
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FitWiz Workout",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ongoing workout tracking"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(text: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("FitWiz")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .build()
    }

    private fun updateNotification(text: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, createNotification(text))
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        exerciseClientManager.cleanup()
    }

    companion object {
        private const val CHANNEL_ID = "fitwiz_workout_channel"
        private const val NOTIFICATION_ID = 1

        const val ACTION_START_EXERCISE = "com.fitwiz.wearos.START_EXERCISE"
        const val ACTION_PAUSE_EXERCISE = "com.fitwiz.wearos.PAUSE_EXERCISE"
        const val ACTION_RESUME_EXERCISE = "com.fitwiz.wearos.RESUME_EXERCISE"
        const val ACTION_END_EXERCISE = "com.fitwiz.wearos.END_EXERCISE"

        fun startExercise(context: Context) {
            val intent = Intent(context, ExerciseService::class.java).apply {
                action = ACTION_START_EXERCISE
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun pauseExercise(context: Context) {
            val intent = Intent(context, ExerciseService::class.java).apply {
                action = ACTION_PAUSE_EXERCISE
            }
            context.startService(intent)
        }

        fun resumeExercise(context: Context) {
            val intent = Intent(context, ExerciseService::class.java).apply {
                action = ACTION_RESUME_EXERCISE
            }
            context.startService(intent)
        }

        fun endExercise(context: Context) {
            val intent = Intent(context, ExerciseService::class.java).apply {
                action = ACTION_END_EXERCISE
            }
            context.startService(intent)
        }
    }
}
