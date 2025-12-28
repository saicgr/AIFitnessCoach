package com.aifitnesscoach.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Window
import android.view.WindowManager

/**
 * Transparent dialog activity that launches the main app and triggers the quick log overlay
 * This appears instantly without navigation delays
 */
class QuickLogDialogActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make this activity completely transparent
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.setBackgroundDrawableResource(android.R.color.transparent)

        // Launch main app with deep link in background
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = android.net.Uri.parse("aifitnesscoach://nutrition/log")
            // Don't use NEW_TASK - we want to reuse existing task
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)

        // Finish this transparent activity immediately
        finish()
    }
}
