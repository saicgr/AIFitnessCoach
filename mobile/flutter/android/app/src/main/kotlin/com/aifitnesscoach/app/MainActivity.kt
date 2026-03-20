package com.aifitnesscoach.app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.aifitnesscoach.app.wearable.WearableMethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.aifitnesscoach.app/widget_actions"
    }

    private var methodChannel: MethodChannel? = null
    private var wearableChannel: WearableMethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    // Widget engine pre-warming removed from MainActivity to prevent
    // "FlutterEngine already attached to another activity" crash.
    // Creating a second engine with DartEntrypoint.createDefault() inside
    // FlutterFragmentActivity conflicts with the Activity's own engine.
    // Widget actions should use the main engine via methodChannel instead.

    // Do NOT override provideFlutterEngine — the widget engine is a separate
    // pre-warmed engine for widget actions only.  Returning it here caused
    // "FlutterEngine already attached to another activity" crashes when
    // deep links (e.g. fitwiz://chat) triggered a new activity lifecycle.

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        Log.d("MainActivity", "MethodChannel configured for widget actions")

        // Initialize wearable communication channel
        // Pass activity provider lambda for methods that need Activity context (like promptWatchAppInstall)
        wearableChannel = WearableMethodChannel(this, flutterEngine) { this }
        Log.d("MainActivity", "✅ WearableMethodChannel initialized for watch sync")
    }

    override fun onDestroy() {
        wearableChannel?.dispose()
        wearableChannel = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data = intent?.data

        Log.d("MainActivity", "handleIntent: action=$action, data=$data")

        // Intercept nutrition/log deep link and send to Flutter via MethodChannel
        if (action == Intent.ACTION_VIEW && data != null) {
            val path = data.path
            Log.d("MainActivity", "Deep link detected: path=$path, full=$data")

            if (path == "/log" || data.toString().contains("nutrition/log")) {
                Log.d("MainActivity", "Intercepting /log deep link, sending to Flutter")
                // Send message to Flutter to show overlay WITHOUT navigation
                methodChannel?.invokeMethod("showQuickLogOverlay", null)
                // Don't let the deep link propagate to go_router
                return
            }
        }
    }
}
