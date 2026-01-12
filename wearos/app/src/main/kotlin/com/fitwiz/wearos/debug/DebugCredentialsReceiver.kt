package com.fitwiz.wearos.debug

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.fitwiz.wearos.BuildConfig
import com.fitwiz.wearos.data.local.SecureStorage

/**
 * Debug-only BroadcastReceiver to inject credentials via ADB for testing.
 *
 * Usage (debug builds only):
 *   adb -s <device> shell am broadcast \
 *     -a com.aifitnesscoach.wearos.DEBUG_SET_CREDENTIALS \
 *     --es user_id "YOUR_USER_ID" \
 *     --es auth_token "YOUR_AUTH_TOKEN"
 *
 * To clear credentials:
 *   adb -s <device> shell am broadcast \
 *     -a com.aifitnesscoach.wearos.DEBUG_CLEAR_CREDENTIALS
 *
 * To check status:
 *   adb -s <device> shell am broadcast \
 *     -a com.aifitnesscoach.wearos.DEBUG_CHECK_CREDENTIALS
 */
class DebugCredentialsReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "DebugCredentials"

        // Action names updated to match new applicationId pattern
        const val ACTION_SET_CREDENTIALS = "com.aifitnesscoach.wearos.DEBUG_SET_CREDENTIALS"
        const val ACTION_CLEAR_CREDENTIALS = "com.aifitnesscoach.wearos.DEBUG_CLEAR_CREDENTIALS"
        const val ACTION_CHECK_CREDENTIALS = "com.aifitnesscoach.wearos.DEBUG_CHECK_CREDENTIALS"

        const val EXTRA_USER_ID = "user_id"
        const val EXTRA_AUTH_TOKEN = "auth_token"
        const val EXTRA_REFRESH_TOKEN = "refresh_token"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")

        // Only allow in debug builds
        if (!BuildConfig.DEBUG) {
            Log.w(TAG, "⚠️ Debug receiver disabled in release builds")
            return
        }

        // Create SecureStorage manually (not using Hilt to avoid injection issues)
        val secureStorage = SecureStorage(context.applicationContext)

        when (intent.action) {
            ACTION_SET_CREDENTIALS -> handleSetCredentials(intent, secureStorage)
            ACTION_CLEAR_CREDENTIALS -> handleClearCredentials(secureStorage)
            ACTION_CHECK_CREDENTIALS -> handleCheckCredentials(secureStorage)
            else -> Log.w(TAG, "Unknown action: ${intent.action}")
        }
    }

    private fun handleSetCredentials(intent: Intent, secureStorage: SecureStorage) {
        val userId = intent.getStringExtra(EXTRA_USER_ID)
        val authToken = intent.getStringExtra(EXTRA_AUTH_TOKEN)
        val refreshToken = intent.getStringExtra(EXTRA_REFRESH_TOKEN)

        Log.d(TAG, "handleSetCredentials - userId: ${userId?.take(8)}, hasToken: ${authToken != null}")

        if (userId.isNullOrBlank()) {
            Log.e(TAG, "❌ Missing user_id")
            return
        }

        if (authToken.isNullOrBlank()) {
            Log.e(TAG, "❌ Missing auth_token")
            return
        }

        try {
            secureStorage.saveCredentials(
                userId = userId,
                authToken = authToken,
                refreshToken = refreshToken
            )

            Log.i(TAG, "✅ Credentials set successfully!")
            Log.i(TAG, "   User ID: ${userId.take(8)}...")
            Log.i(TAG, "   Token: ${authToken.take(20)}...")
            Log.i(TAG, "   Refresh: ${refreshToken?.take(20) ?: "none"}...")
            Log.i(TAG, "")
            Log.i(TAG, "🔄 Please restart the app to use new credentials")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save credentials", e)
        }
    }

    private fun handleClearCredentials(secureStorage: SecureStorage) {
        try {
            secureStorage.clearCredentials()
            Log.i(TAG, "✅ Credentials cleared")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to clear credentials", e)
        }
    }

    private fun handleCheckCredentials(secureStorage: SecureStorage) {
        try {
            val isAuthenticated = secureStorage.isAuthenticated()
            val userId = secureStorage.getUserId()
            val hasToken = secureStorage.hasValidToken()

            Log.i(TAG, "=== Credential Status ===")
            Log.i(TAG, "  Authenticated: $isAuthenticated")
            Log.i(TAG, "  User ID: ${userId?.take(8) ?: "none"}...")
            Log.i(TAG, "  Has Token: $hasToken")
            Log.i(TAG, "========================")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to check credentials", e)
        }
    }
}
