package com.aifitnesscoach.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.core.content.FileProvider
import com.aifitnesscoach.app.wearable.WearableMethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.aifitnesscoach.app/widget_actions"
        private const val INSTAGRAM_CHANNEL = "com.fitwiz/instagram_share"
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val INSTAGRAM_STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
    }

    private var methodChannel: MethodChannel? = null
    private var instagramChannel: MethodChannel? = null
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

        instagramChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTAGRAM_CHANNEL)
        instagramChannel?.setMethodCallHandler { call, result -> handleInstagramShare(call, result) }
        Log.d("MainActivity", "✅ Instagram share MethodChannel configured")

        // Initialize wearable communication channel
        // Pass activity provider lambda for methods that need Activity context (like promptWatchAppInstall)
        wearableChannel = WearableMethodChannel(this, flutterEngine) { this }
        Log.d("MainActivity", "✅ WearableMethodChannel initialized for watch sync")
    }

    /**
     * Native side of the `com.fitwiz/instagram_share` MethodChannel.
     *
     * Builds a `com.instagram.share.ADD_TO_STORY` intent targeting Instagram
     * with a FileProvider content:// URI for the captured workout image and
     * launches it. A plain file:// path would crash on Android 7+ with
     * FileUriExposedException; Instagram also won't accept it.
     */
    private fun handleInstagramShare(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "shareToInstagramStories" -> {
                val imagePath = call.argument<String>("imagePath")
                if (imagePath.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENTS", "imagePath required", null)
                    return
                }
                val file = File(imagePath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Image not found at $imagePath", null)
                    return
                }
                val uri: Uri = try {
                    FileProvider.getUriForFile(
                        this,
                        "${packageName}.instagramshare.fileprovider",
                        file
                    )
                } catch (e: IllegalArgumentException) {
                    Log.e("MainActivity", "FileProvider rejected image path: ${e.message}")
                    result.error("FILEPROVIDER_FAILED", e.message, null)
                    return
                }

                val intent = Intent(INSTAGRAM_STORY_ACTION).apply {
                    setDataAndType(uri, "image/png")
                    setPackage(INSTAGRAM_PACKAGE)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

                if (intent.resolveActivity(packageManager) == null) {
                    Log.w("MainActivity", "Instagram not installed or doesn't support ADD_TO_STORY")
                    result.success(false)
                    return
                }

                try {
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Failed to launch Instagram Stories: ${e.message}")
                    result.error("LAUNCH_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDestroy() {
        wearableChannel?.dispose()
        wearableChannel = null
        instagramChannel?.setMethodCallHandler(null)
        instagramChannel = null
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
