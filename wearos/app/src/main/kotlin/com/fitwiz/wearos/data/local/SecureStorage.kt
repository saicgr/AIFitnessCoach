package com.fitwiz.wearos.data.local

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Secure storage for sensitive data on Wear OS using EncryptedSharedPreferences.
 * Stores user credentials synced from phone.
 */
@Singleton
class SecureStorage @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    private val encryptedPrefs: SharedPreferences by lazy {
        try {
            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create encrypted prefs, falling back to regular prefs", e)
            // Fallback to regular SharedPreferences if encryption fails
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    companion object {
        private const val TAG = "SecureStorage"
        private const val PREFS_NAME = "fitwiz_secure_prefs"

        // Keys
        private const val KEY_USER_ID = "user_id"
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_TOKEN_EXPIRY = "token_expiry"
        private const val KEY_LAST_SYNC = "last_credential_sync"
    }

    // ==================== User ID ====================

    fun saveUserId(userId: String) {
        encryptedPrefs.edit().putString(KEY_USER_ID, userId).apply()
        Log.d(TAG, "User ID saved: ${userId.take(8)}...")
    }

    fun getUserId(): String? {
        return encryptedPrefs.getString(KEY_USER_ID, null)
    }

    fun hasUserId(): Boolean {
        return getUserId() != null
    }

    // ==================== Auth Token ====================

    fun saveAuthToken(token: String, expiryMs: Long? = null) {
        encryptedPrefs.edit().apply {
            putString(KEY_AUTH_TOKEN, token)
            expiryMs?.let { putLong(KEY_TOKEN_EXPIRY, it) }
        }.apply()
        Log.d(TAG, "Auth token saved")
    }

    fun getAuthToken(): String? {
        val token = encryptedPrefs.getString(KEY_AUTH_TOKEN, null)
        val expiry = encryptedPrefs.getLong(KEY_TOKEN_EXPIRY, 0L)

        // Check if token is expired
        if (expiry > 0 && System.currentTimeMillis() > expiry) {
            Log.w(TAG, "Auth token expired")
            return null
        }

        return token
    }

    fun hasValidToken(): Boolean {
        return getAuthToken() != null
    }

    // ==================== Refresh Token ====================

    fun saveRefreshToken(token: String) {
        encryptedPrefs.edit().putString(KEY_REFRESH_TOKEN, token).apply()
        Log.d(TAG, "Refresh token saved")
    }

    fun getRefreshToken(): String? {
        return encryptedPrefs.getString(KEY_REFRESH_TOKEN, null)
    }

    // ==================== Credential Sync ====================

    fun saveCredentials(userId: String, authToken: String, refreshToken: String? = null, expiryMs: Long? = null) {
        encryptedPrefs.edit().apply {
            putString(KEY_USER_ID, userId)
            putString(KEY_AUTH_TOKEN, authToken)
            refreshToken?.let { putString(KEY_REFRESH_TOKEN, it) }
            expiryMs?.let { putLong(KEY_TOKEN_EXPIRY, it) }
            putLong(KEY_LAST_SYNC, System.currentTimeMillis())
        }.apply()
        Log.d(TAG, "Credentials saved for user: ${userId.take(8)}...")
    }

    fun getLastCredentialSync(): Long {
        return encryptedPrefs.getLong(KEY_LAST_SYNC, 0L)
    }

    fun isAuthenticated(): Boolean {
        return hasUserId() && hasValidToken()
    }

    // ==================== Clear ====================

    fun clearCredentials() {
        encryptedPrefs.edit().apply {
            remove(KEY_USER_ID)
            remove(KEY_AUTH_TOKEN)
            remove(KEY_REFRESH_TOKEN)
            remove(KEY_TOKEN_EXPIRY)
            remove(KEY_LAST_SYNC)
        }.apply()
        Log.d(TAG, "Credentials cleared")
    }

    fun clearAll() {
        encryptedPrefs.edit().clear().apply()
        Log.d(TAG, "All secure storage cleared")
    }
}
