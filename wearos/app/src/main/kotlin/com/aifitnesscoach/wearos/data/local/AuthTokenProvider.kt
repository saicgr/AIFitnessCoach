package com.fitwiz.wearos.data.local

import javax.inject.Inject
import javax.inject.Singleton

/**
 * Provides auth token for network requests.
 * Acts as a bridge between SecureStorage and OkHttp interceptor.
 */
@Singleton
class AuthTokenProvider @Inject constructor(
    private val secureStorage: SecureStorage
) {
    fun getAuthToken(): String? = secureStorage.getAuthToken()

    fun getUserId(): String? = secureStorage.getUserId()

    fun isAuthenticated(): Boolean = secureStorage.isAuthenticated()
}
