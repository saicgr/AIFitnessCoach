package com.aifitnesscoach.shared.auth

import com.aifitnesscoach.shared.BuildConfig
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import io.github.jan.supabase.gotrue.providers.builtin.IDToken
import io.github.jan.supabase.postgrest.Postgrest
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

object SupabaseAuth {
    private val supabaseUrl = BuildConfig.SUPABASE_URL.ifEmpty {
        "https://hpbzfahijszqmgsybuor.supabase.co"
    }
    private val supabaseKey = BuildConfig.SUPABASE_KEY.ifEmpty {
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwYnpmYWhpanN6cW1nc3lidW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNjEzOTYsImV4cCI6MjA3OTgzNzM5Nn0.udv4b7UPhLLEfiWo7qd5ezqNTZ7KBXqzW_CwroNowAM"
    }

    val client by lazy {
        createSupabaseClient(
            supabaseUrl = supabaseUrl,
            supabaseKey = supabaseKey
        ) {
            install(Auth)
            install(Postgrest)
        }
    }

    val auth get() = client.auth

    /**
     * Sign in with Google ID Token (from Android Credential Manager)
     */
    suspend fun signInWithGoogleIdToken(idToken: String, accessToken: String? = null): AuthResult {
        return try {
            auth.signInWith(IDToken) {
                this.idToken = idToken
                this.provider = Google
                accessToken?.let { this.accessToken = it }
            }

            val session = auth.currentSessionOrNull()
            val user = auth.currentUserOrNull()

            if (session != null && user != null) {
                AuthResult.Success(
                    userId = user.id,
                    email = user.email ?: "",
                    accessToken = session.accessToken,
                    isNewUser = user.createdAt == user.updatedAt // Rough check for new user
                )
            } else {
                AuthResult.Error("Failed to get session after sign in")
            }
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Unknown error during Google sign in")
        }
    }

    /**
     * Get current session if logged in.
     * Waits for session to be loaded from storage first.
     */
    suspend fun getCurrentSession(): AuthResult {
        return try {
            // Wait for session to be loaded from storage
            // The sessionStatus flow emits when session state changes
            kotlinx.coroutines.withTimeout(5000) {
                auth.sessionStatus.first { status ->
                    // Wait until it's either Authenticated or NotAuthenticated (not Loading)
                    status is io.github.jan.supabase.gotrue.SessionStatus.Authenticated ||
                    status is io.github.jan.supabase.gotrue.SessionStatus.NotAuthenticated
                }
            }

            val session = auth.currentSessionOrNull()
            val user = auth.currentUserOrNull()

            if (session != null && user != null) {
                AuthResult.Success(
                    userId = user.id,
                    email = user.email ?: "",
                    accessToken = session.accessToken,
                    isNewUser = false
                )
            } else {
                AuthResult.NotLoggedIn
            }
        } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
            // Timeout waiting for session - assume not logged in
            AuthResult.NotLoggedIn
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Failed to get session")
        }
    }

    /**
     * Sign out
     */
    suspend fun signOut() {
        try {
            auth.signOut()
        } catch (e: Exception) {
            // Ignore sign out errors
        }
    }

    /**
     * Flow of auth state changes
     */
    val authStateFlow: Flow<Boolean> = auth.sessionStatus.map { status ->
        status is io.github.jan.supabase.gotrue.SessionStatus.Authenticated
    }

    /**
     * Get current access token for API calls
     */
    suspend fun getAccessToken(): String? {
        return auth.currentSessionOrNull()?.accessToken
    }
}

sealed class AuthResult {
    data class Success(
        val userId: String,
        val email: String,
        val accessToken: String,
        val isNewUser: Boolean
    ) : AuthResult()

    data class Error(val message: String) : AuthResult()

    data object NotLoggedIn : AuthResult()
}
