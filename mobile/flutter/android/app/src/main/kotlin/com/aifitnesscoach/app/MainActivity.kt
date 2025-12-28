package com.aifitnesscoach.app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.aifitnesscoach.app/widget_actions"
        private const val WIDGET_ENGINE_ID = "widget_engine"
    }

    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Pre-warm Flutter engine for widget actions
        warmUpFlutterEngine()

        handleIntent(intent)
    }

    private fun warmUpFlutterEngine() {
        // Check if engine already cached
        if (FlutterEngineCache.getInstance().get(WIDGET_ENGINE_ID) == null) {
            try {
                val engine = FlutterEngine(this)
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put(WIDGET_ENGINE_ID, engine)
                Log.d("MainActivity", "✅ Flutter engine pre-warmed for widgets")
            } catch (e: Exception) {
                Log.e("MainActivity", "❌ Failed to pre-warm Flutter engine: $e")
            }
        }
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        // Use cached engine if available
        return FlutterEngineCache.getInstance().get(WIDGET_ENGINE_ID) ?: super.provideFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        Log.d("MainActivity", "MethodChannel configured for widget actions")
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
