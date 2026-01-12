package com.aifitnesscoach.app.wearable

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

/**
 * Flutter MethodChannel bridge for wearable communication.
 * Provides methods to send data to watch and receives events from watch.
 */
class WearableMethodChannel(
    private val context: Context,
    flutterEngine: FlutterEngine,
    private val activityProvider: () -> android.app.Activity?
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val wearableClient = WearableDataClient(context)

    private var eventSink: EventChannel.EventSink? = null
    private var broadcastReceiver: BroadcastReceiver? = null

    companion object {
        private const val TAG = "WearableMethodChannel"
        private const val METHOD_CHANNEL = "com.aifitnesscoach.app/wearable"
        private const val EVENT_CHANNEL = "com.aifitnesscoach.app/wearable_events"
    }

    init {
        setupMethodChannel(flutterEngine)
        setupEventChannel(flutterEngine)
        registerBroadcastReceiver()
    }

    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                scope.launch {
                    try {
                        when (call.method) {
                            "isWatchConnected" -> {
                                val connected = wearableClient.isWatchConnected()
                                result.success(connected)
                            }

                            "sendWorkoutToWatch" -> {
                                val workoutJson = call.argument<String>("workout")
                                if (workoutJson != null) {
                                    val success = wearableClient.sendWorkoutToWatch(workoutJson)
                                    result.success(success)
                                } else {
                                    result.error("INVALID_ARGUMENT", "workout is required", null)
                                }
                            }

                            "sendNutritionSummaryToWatch" -> {
                                val summaryJson = call.argument<String>("summary")
                                if (summaryJson != null) {
                                    val success = wearableClient.sendNutritionSummaryToWatch(summaryJson)
                                    result.success(success)
                                } else {
                                    result.error("INVALID_ARGUMENT", "summary is required", null)
                                }
                            }

                            "sendHealthGoalsToWatch" -> {
                                val goalsJson = call.argument<String>("goals")
                                if (goalsJson != null) {
                                    val success = wearableClient.sendHealthGoalsToWatch(goalsJson)
                                    result.success(success)
                                } else {
                                    result.error("INVALID_ARGUMENT", "goals is required", null)
                                }
                            }

                            "sendHealthDataToWatch" -> {
                                val healthJson = call.argument<String>("health")
                                if (healthJson != null) {
                                    val success = wearableClient.sendHealthDataToWatch(healthJson)
                                    result.success(success)
                                } else {
                                    result.error("INVALID_ARGUMENT", "health is required", null)
                                }
                            }

                            "sendUserProfileToWatch" -> {
                                val profileJson = call.argument<String>("profile")
                                if (profileJson != null) {
                                    val success = wearableClient.sendUserProfileToWatch(profileJson)
                                    result.success(success)
                                } else {
                                    result.error("INVALID_ARGUMENT", "profile is required", null)
                                }
                            }

                            "notifySyncComplete" -> {
                                val success = wearableClient.notifySyncComplete()
                                result.success(success)
                            }

                            "notifyWorkoutUpdated" -> {
                                val success = wearableClient.notifyWorkoutUpdated()
                                result.success(success)
                            }

                            "sendUserCredentialsToWatch" -> {
                                val userId = call.argument<String>("userId")
                                val authToken = call.argument<String>("authToken")
                                val refreshToken = call.argument<String>("refreshToken")
                                val expiryMs = call.argument<Long>("expiryMs")

                                if (userId != null && authToken != null) {
                                    val success = wearableClient.sendUserCredentialsToWatch(
                                        userId = userId,
                                        authToken = authToken,
                                        refreshToken = refreshToken,
                                        expiryMs = expiryMs
                                    )
                                    result.success(success)
                                } else {
                                    result.error("INVALID_ARGUMENT", "userId and authToken are required", null)
                                }
                            }

                            "hasConnectedWearDevice" -> {
                                val hasDevice = wearableClient.hasConnectedWearDevice()
                                result.success(hasDevice)
                            }

                            "isWatchAppInstalled" -> {
                                val isInstalled = wearableClient.isWatchAppInstalled()
                                result.success(isInstalled)
                            }

                            "promptWatchAppInstall" -> {
                                val activity = activityProvider()
                                if (activity != null) {
                                    val success = wearableClient.promptWatchAppInstall(activity)
                                    result.success(success)
                                } else {
                                    Log.e(TAG, "Activity not available for promptWatchAppInstall")
                                    result.error("NO_ACTIVITY", "Activity not available", null)
                                }
                            }

                            else -> {
                                result.notImplemented()
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error handling method call: ${call.method}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
            }
    }

    private fun setupEventChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "EventChannel listening")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "EventChannel cancelled")
                }
            })
    }

    private fun registerBroadcastReceiver() {
        broadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "com.aifitnesscoach.app.WEARABLE_DATA") {
                    val eventType = intent.getStringExtra("event_type") ?: return
                    val jsonData = intent.getStringExtra("json_data") ?: "{}"

                    Log.d(TAG, "Received broadcast: $eventType")

                    // Send to Flutter via EventChannel
                    scope.launch(Dispatchers.Main) {
                        eventSink?.success(mapOf(
                            "type" to eventType,
                            "data" to jsonData
                        ))
                    }
                }
            }
        }

        val filter = IntentFilter("com.aifitnesscoach.app.WEARABLE_DATA")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(broadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(broadcastReceiver, filter)
        }
    }

    fun dispose() {
        scope.cancel()
        broadcastReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                Log.w(TAG, "Error unregistering receiver", e)
            }
        }
        broadcastReceiver = null
        eventSink = null
    }
}
