package com.fitwiz.wearos.voice

import android.content.Context
import android.content.Intent
import android.speech.RecognizerIntent
import androidx.core.os.bundleOf
import androidx.wear.input.RemoteInputIntentHelper
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages voice input for Wear OS
 */
@Singleton
class VoiceInputManager @Inject constructor() {

    companion object {
        private const val TAG = "VoiceInputManager"
        const val VOICE_INPUT_KEY = "voice_input"
        const val REQUEST_CODE_VOICE = 1001
    }

    /**
     * Creates an intent for voice input
     */
    fun createVoiceInputIntent(prompt: String = "What did you eat?"): Intent {
        return Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PROMPT, prompt)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
    }

    /**
     * Creates a RemoteInput intent for wear keyboard/voice input
     */
    fun createRemoteInputIntent(
        prompt: String = "What did you eat?",
        allowVoice: Boolean = true,
        recentSuggestions: List<String> = emptyList()
    ): Intent {
        val remoteInputs = listOf(
            android.app.RemoteInput.Builder(VOICE_INPUT_KEY)
                .setLabel(prompt)
                .setChoices(recentSuggestions.take(5).toTypedArray())
                .build()
        )

        return RemoteInputIntentHelper.createActionRemoteInputIntent().also { intent ->
            RemoteInputIntentHelper.putRemoteInputsExtra(intent, remoteInputs)
            RemoteInputIntentHelper.putTitleExtra(intent, prompt)
        }
    }

    /**
     * Extract voice input result from activity result
     */
    fun extractVoiceResult(data: Intent?): String? {
        return data?.let {
            // Try RemoteInput first
            val remoteInputResults = android.app.RemoteInput.getResultsFromIntent(it)
            val remoteResult = remoteInputResults?.getCharSequence(VOICE_INPUT_KEY)?.toString()
            remoteResult
                // Fallback to speech recognizer results
                ?: it.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        }
    }

    /**
     * Check if voice input is available on this device
     */
    fun isVoiceInputAvailable(context: Context): Boolean {
        val intent = createVoiceInputIntent()
        return intent.resolveActivity(context.packageManager) != null
    }
}
