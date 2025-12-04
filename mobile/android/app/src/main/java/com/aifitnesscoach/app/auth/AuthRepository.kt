package com.aifitnesscoach.app.auth

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.NoCredentialException
import com.aifitnesscoach.shared.api.ApiClient
import com.aifitnesscoach.shared.auth.AuthResult
import com.aifitnesscoach.shared.auth.SupabaseAuth
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.flow.MutableStateFlow
import retrofit2.HttpException
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class AuthRepository(private val context: Context) {
    private val credentialManager = CredentialManager.create(context)

    // Google Web Client ID from GCP console
    // This should match the OAuth client ID configured in Supabase > Authentication > Providers > Google
    private val googleWebClientId = "763543360320-hjregsh5hn0lvp610sjr36m34f9fh2bj.apps.googleusercontent.com"

    private val _authState = MutableStateFlow<AuthState>(AuthState.Loading)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    private val _currentUser = MutableStateFlow<UserInfo?>(null)
    val currentUser: StateFlow<UserInfo?> = _currentUser.asStateFlow()

    // Legacy Google Sign-In client (fallback for emulators)
    private val googleSignInClient: GoogleSignInClient by lazy {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(googleWebClientId)
            .requestEmail()
            .build()
        GoogleSignIn.getClient(context, gso)
    }

    // Launcher for legacy sign-in (will be set by Activity)
    private var signInLauncher: ActivityResultLauncher<Intent>? = null

    fun setSignInLauncher(launcher: ActivityResultLauncher<Intent>) {
        signInLauncher = launcher
    }

    suspend fun checkExistingSession() {
        Log.d(TAG, "🔍 Checking existing session...")
        _authState.value = AuthState.Loading
        when (val result = SupabaseAuth.getCurrentSession()) {
            is AuthResult.Success -> {
                Log.d(TAG, "✅ Found existing session for: ${result.email}")
                ApiClient.setAuthToken(result.accessToken)

                // Set user info right away so we can navigate
                _currentUser.value = UserInfo(
                    id = result.userId,
                    email = result.email
                )

                // Try to verify with backend but with a timeout
                val backendUser = try {
                    Log.d(TAG, "Calling backend googleAuth for existing session...")
                    kotlinx.coroutines.withTimeout(5000) {
                        val authRequest = com.aifitnesscoach.shared.models.GoogleAuthRequest(
                            accessToken = result.accessToken
                        )
                        ApiClient.userApi.googleAuth(authRequest)
                    }
                } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
                    Log.w(TAG, "⏱️ Backend verification timed out, proceeding with session")
                    null
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to verify backend user: ${e.message}", e)
                    null
                }

                // Update user ID if we got it from backend
                if (backendUser != null && backendUser.id != null) {
                    Log.i(TAG, "✅ Backend user verified: id=${backendUser.id}, onboarding=${backendUser.onboardingCompleted}")
                    _currentUser.value = UserInfo(
                        id = backendUser.id!!,
                        email = result.email
                    )
                }

                val isNewUser = backendUser?.let { !it.onboardingCompleted } ?: false
                _authState.value = AuthState.Authenticated(isNewUser = isNewUser)
                Log.i(TAG, "🎯 Auth state set to Authenticated, isNewUser=$isNewUser")
            }
            is AuthResult.NotLoggedIn -> {
                Log.d(TAG, "📭 No existing session found")
                _authState.value = AuthState.NotAuthenticated
            }
            is AuthResult.Error -> {
                Log.e(TAG, "❌ Error checking session: ${result.message}")
                _authState.value = AuthState.NotAuthenticated
            }
        }
    }

    suspend fun signInWithGoogle(): Result<Boolean> {
        return try {
            _authState.value = AuthState.Loading

            // Try Credential Manager first (works on real devices)
            try {
                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(googleWebClientId)
                    .setAutoSelectEnabled(false)
                    .build()

                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()

                val response = credentialManager.getCredential(
                    request = request,
                    context = context
                )

                handleCredentialManagerSignIn(response)
            } catch (e: NoCredentialException) {
                // Fallback to legacy Google Sign-In (for emulators)
                Log.w(TAG, "Credential Manager failed, using legacy sign-in", e)
                startLegacySignIn()
                Result.success(false) // Will be updated by handleSignInResult
            }
        } catch (e: Exception) {
            Log.e(TAG, "Google sign-in failed", e)
            _authState.value = AuthState.Error(e.message ?: "Sign in failed")
            Result.failure(e)
        }
    }

    private fun startLegacySignIn() {
        val signInIntent = googleSignInClient.signInIntent
        signInLauncher?.launch(signInIntent) ?: run {
            Log.e(TAG, "Sign-in launcher not set")
            _authState.value = AuthState.Error("Sign-in not available")
        }
    }

    suspend fun handleSignInResult(data: Intent?): Result<Boolean> {
        return try {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            val account = task.getResult(ApiException::class.java)
            val idToken = account.idToken

            if (idToken != null) {
                handleGoogleIdToken(idToken)
            } else {
                Log.e(TAG, "ID token is null")
                _authState.value = AuthState.Error("Failed to get ID token")
                Result.failure(Exception("Failed to get ID token"))
            }
        } catch (e: ApiException) {
            Log.e(TAG, "Google sign-in failed with code: ${e.statusCode}", e)
            _authState.value = AuthState.Error("Sign in failed: ${e.message}")
            Result.failure(e)
        }
    }

    private suspend fun handleCredentialManagerSignIn(response: GetCredentialResponse): Result<Boolean> {
        val credential = response.credential

        return when {
            credential is CustomCredential &&
                    credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL -> {
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                val idToken = googleIdTokenCredential.idToken
                handleGoogleIdToken(idToken)
            }
            else -> {
                Log.e(TAG, "Unexpected credential type: ${credential.type}")
                _authState.value = AuthState.Error("Invalid credential type")
                Result.failure(Exception("Invalid credential type"))
            }
        }
    }

    private suspend fun handleGoogleIdToken(idToken: String): Result<Boolean> {
        return when (val result = SupabaseAuth.signInWithGoogleIdToken(idToken)) {
            is AuthResult.Success -> {
                ApiClient.setAuthToken(result.accessToken)

                // CRITICAL: Call backend googleAuth endpoint to ensure user exists in our database
                // The web frontend does this in AuthCallback.tsx - we must do the same!
                // This creates/retrieves the user from our backend database using the Supabase session
                val backendUser = try {
                    Log.d(TAG, "Calling backend googleAuth to ensure user exists in database...")
                    val authRequest = com.aifitnesscoach.shared.models.GoogleAuthRequest(
                        accessToken = result.accessToken
                    )
                    val response = ApiClient.userApi.googleAuth(authRequest)
                    Log.i(TAG, "✅ Backend user created/retrieved: id=${response.id}, onboarding=${response.onboardingCompleted}")
                    response
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to create/retrieve backend user: ${e.message}", e)
                    null
                }

                // Use backend user ID if available (it's the real database ID)
                val userId = backendUser?.id ?: result.userId
                val isNewUser = backendUser?.let { !it.onboardingCompleted } ?: checkUserNeedsOnboarding(userId)

                _currentUser.value = UserInfo(
                    id = userId,
                    email = result.email
                )

                _authState.value = AuthState.Authenticated(isNewUser = isNewUser)
                Log.i(TAG, "Successfully signed in: ${result.email}, isNewUser: $isNewUser")
                Result.success(isNewUser)
            }
            is AuthResult.Error -> {
                Log.e(TAG, "Supabase auth failed: ${result.message}")
                _authState.value = AuthState.Error(result.message)
                Result.failure(Exception(result.message))
            }
            is AuthResult.NotLoggedIn -> {
                _authState.value = AuthState.NotAuthenticated
                Result.failure(Exception("Not logged in"))
            }
        }
    }

    /**
     * Check if user needs onboarding by calling backend API.
     * Returns true if user doesn't exist or hasn't completed onboarding.
     */
    private suspend fun checkUserNeedsOnboarding(userId: String): Boolean {
        return try {
            val user = ApiClient.userApi.getUser(userId)
            val needsOnboarding = !user.onboardingCompleted
            Log.d(TAG, "User ${userId} onboardingCompleted: ${user.onboardingCompleted}")
            needsOnboarding
        } catch (e: HttpException) {
            if (e.code() == 404) {
                // User doesn't exist in our database - definitely needs onboarding
                Log.d(TAG, "User $userId not found in database, needs onboarding")
                true
            } else {
                // Other HTTP error - assume new user to be safe
                Log.e(TAG, "Error checking user status: ${e.code()}", e)
                true
            }
        } catch (e: Exception) {
            // Network or other error - assume new user to be safe
            Log.e(TAG, "Error checking user status", e)
            true
        }
    }

    suspend fun signOut() {
        SupabaseAuth.signOut()
        googleSignInClient.signOut()
        ApiClient.setAuthToken(null)
        _currentUser.value = null
        _authState.value = AuthState.NotAuthenticated
    }

    companion object {
        private const val TAG = "AuthRepository"
    }
}

sealed class AuthState {
    data object Loading : AuthState()
    data object NotAuthenticated : AuthState()
    data class Authenticated(val isNewUser: Boolean) : AuthState()
    data class Error(val message: String) : AuthState()
}

data class UserInfo(
    val id: String,
    val email: String
)
