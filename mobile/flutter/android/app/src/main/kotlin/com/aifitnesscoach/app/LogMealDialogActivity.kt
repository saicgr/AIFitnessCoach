package com.aifitnesscoach.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Window
import android.view.WindowManager

/**
 * Dialog-style activity that shows meal logging interface
 * Appears as a popup overlay without fully launching the app
 */
class LogMealDialogActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make this activity appear as a dialog
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT
        )

        // For now, immediately launch the main app with the log meal deep link
        // In the future, we could show a custom UI here
        launchMainAppWithMealLog()
        finish()
    }

    private fun launchMainAppWithMealLog() {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = android.net.Uri.parse("aifitnesscoach://nutrition/log")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        startActivity(intent)
    }
}
