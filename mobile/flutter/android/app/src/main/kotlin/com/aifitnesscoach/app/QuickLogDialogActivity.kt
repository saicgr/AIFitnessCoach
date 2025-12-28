package com.aifitnesscoach.app

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.Window
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Native Android dialog that shows meal logging options WITHOUT launching the Flutter app
 * This provides instant popup experience directly from the home screen widget
 *
 * State Flow:
 * 1. MEAL_TYPE_SELECTION → User selects meal type (breakfast/lunch/dinner/snack)
 * 2. INPUT_MODE_SELECTION → User selects input method (describe/photo/barcode)
 * 3. INPUT_ACTIVE → User interacts with selected input method
 * 4. LOADING → Processing meal through Flutter
 * 5. RESULT → Display nutrition data with confirmation
 */
class QuickLogDialogActivity : Activity() {

    companion object {
        private const val TAG = "QuickLogDialog"
        private const val CHANNEL = "com.aifitnesscoach.app/widget_actions"
        private const val WIDGET_ENGINE_ID = "widget_engine"

        // Request codes for activities
        const val REQUEST_PHOTO_CAPTURE = 1001
        const val REQUEST_BARCODE_SCAN = 1002
    }

    // Dialog state
    private enum class DialogState {
        MEAL_TYPE_SELECTION,
        INPUT_MODE_SELECTION,
        INPUT_ACTIVE,
        LOADING,
        RESULT
    }

    private var currentState = DialogState.MEAL_TYPE_SELECTION
    private var selectedMealType = "snack"
    private var selectedInputMode = "describe"

    // UI References
    private lateinit var dialog: AlertDialog
    private lateinit var dialogView: View
    private lateinit var contentContainer: FrameLayout

    // Meal type buttons
    private lateinit var btnBreakfast: Button
    private lateinit var btnLunch: Button
    private lateinit var btnDinner: Button
    private lateinit var btnSnack: Button

    // Input mode buttons
    private lateinit var btnDescribe: Button
    private lateinit var btnPhoto: Button
    private lateinit var btnBarcode: Button

    // Action buttons
    private lateinit var btnCancel: Button
    private lateinit var btnGoToApp: Button

    // Flutter MethodChannel
    private var methodChannel: MethodChannel? = null
    private var userId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d(TAG, "QuickLogDialogActivity created - showing native dialog")

        // Make this activity completely transparent
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.setBackgroundDrawableResource(android.R.color.transparent)

        // Initialize Flutter MethodChannel
        initializeFlutterChannel()

        // Show the native dialog
        showQuickLogDialog()
    }

    private fun initializeFlutterChannel() {
        try {
            val flutterEngine = FlutterEngineCache.getInstance().get(WIDGET_ENGINE_ID)
            if (flutterEngine != null) {
                methodChannel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    CHANNEL
                )
                Log.d(TAG, "✅ MethodChannel initialized")

                // Get userId from Flutter
                getUserId()
            } else {
                Log.e(TAG, "❌ Flutter engine not found in cache")
                showError("App not initialized. Please open the app first.")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to initialize MethodChannel: $e")
            showError("Failed to connect to app backend")
        }
    }

    private fun getUserId() {
        methodChannel?.invokeMethod("getUserId", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                userId = result as? String
                Log.d(TAG, "✅ Got userId: $userId")

                if (userId == null) {
                    showError("Please log in to the app first")
                    finish()
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "❌ Failed to get userId: $errorMessage")
                if (errorCode == "NOT_LOGGED_IN") {
                    runOnUiThread {
                        Toast.makeText(this@QuickLogDialogActivity, "Please log in to the app first", Toast.LENGTH_LONG).show()
                    }
                    finish()
                } else {
                    showError("Failed to get user session")
                    finish()
                }
            }

            override fun notImplemented() {
                Log.e(TAG, "❌ getUserId not implemented")
                runOnUiThread {
                    Toast.makeText(this@QuickLogDialogActivity, "Please update the app", Toast.LENGTH_LONG).show()
                }
                finish()
            }
        })
    }

    private fun showQuickLogDialog() {
        dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_quick_log_expanded, null)

        dialog = AlertDialog.Builder(this)
            .setView(dialogView)
            .setCancelable(true)
            .create()

        // Make dialog background transparent
        dialog.window?.setBackgroundDrawableResource(android.R.color.transparent)

        // Initialize UI references
        initializeViews()

        // Set up button listeners
        setupMealTypeButtons()
        setupInputModeButtons()
        setupActionButtons()

        // Start in meal type selection state
        updateUIForState()

        // Finish this activity when dialog is dismissed
        dialog.setOnDismissListener {
            Log.d(TAG, "Dialog dismissed")
            finish()
        }

        dialog.show()
    }

    private fun initializeViews() {
        // Content container
        contentContainer = dialogView.findViewById(R.id.content_container)

        // Meal type buttons
        btnBreakfast = dialogView.findViewById(R.id.btn_breakfast)
        btnLunch = dialogView.findViewById(R.id.btn_lunch)
        btnDinner = dialogView.findViewById(R.id.btn_dinner)
        btnSnack = dialogView.findViewById(R.id.btn_snack)

        // Input mode buttons
        btnDescribe = dialogView.findViewById(R.id.btn_describe)
        btnPhoto = dialogView.findViewById(R.id.btn_photo)
        btnBarcode = dialogView.findViewById(R.id.btn_barcode)

        // Action buttons
        btnCancel = dialogView.findViewById(R.id.btn_cancel)
        btnGoToApp = dialogView.findViewById(R.id.btn_go_to_app)
    }

    private fun setupMealTypeButtons() {
        btnBreakfast.setOnClickListener {
            selectMealType("breakfast", btnBreakfast)
        }
        btnLunch.setOnClickListener {
            selectMealType("lunch", btnLunch)
        }
        btnDinner.setOnClickListener {
            selectMealType("dinner", btnDinner)
        }
        btnSnack.setOnClickListener {
            selectMealType("snack", btnSnack)
        }
    }

    private fun selectMealType(mealType: String, button: Button) {
        selectedMealType = mealType
        Log.d(TAG, "Selected meal type: $mealType")

        // Update button styles
        resetMealTypeButtons()
        button.setBackgroundColor(0xFF6366F1.toInt()) // Purple highlight

        // Move to input mode selection if not already there
        if (currentState == DialogState.MEAL_TYPE_SELECTION) {
            currentState = DialogState.INPUT_MODE_SELECTION
            updateUIForState()
        }
    }

    private fun resetMealTypeButtons() {
        val defaultColor = 0xFF3A3A3A.toInt()
        btnBreakfast.setBackgroundColor(defaultColor)
        btnLunch.setBackgroundColor(defaultColor)
        btnDinner.setBackgroundColor(defaultColor)
        btnSnack.setBackgroundColor(defaultColor)
    }

    private fun setupInputModeButtons() {
        btnDescribe.setOnClickListener {
            selectInputMode("describe", btnDescribe)
        }
        btnPhoto.setOnClickListener {
            selectInputMode("photo", btnPhoto)
        }
        btnBarcode.setOnClickListener {
            selectInputMode("barcode", btnBarcode)
        }
    }

    private fun selectInputMode(mode: String, button: Button) {
        selectedInputMode = mode
        Log.d(TAG, "Selected input mode: $mode")

        // Update button styles
        resetInputModeButtons()
        button.setBackgroundColor(0xFF6366F1.toInt()) // Purple highlight

        // Show input UI
        currentState = DialogState.INPUT_ACTIVE
        updateUIForState()
    }

    private fun resetInputModeButtons() {
        val defaultColor = 0xFF3A3A3A.toInt()
        btnDescribe.setBackgroundColor(defaultColor)
        btnPhoto.setBackgroundColor(defaultColor)
        btnBarcode.setBackgroundColor(defaultColor)
    }

    private fun setupActionButtons() {
        btnCancel.setOnClickListener {
            Log.d(TAG, "Cancel clicked")
            dialog.dismiss()
            finish()
        }

        btnGoToApp.setOnClickListener {
            Log.d(TAG, "Go to App clicked")
            launchApp()
            dialog.dismiss()
            finish()
        }
    }

    private fun updateUIForState() {
        contentContainer.removeAllViews()

        when (currentState) {
            DialogState.MEAL_TYPE_SELECTION -> {
                // No content, just showing meal type buttons
            }
            DialogState.INPUT_MODE_SELECTION -> {
                // No content, just showing input mode buttons
            }
            DialogState.INPUT_ACTIVE -> {
                showInputUI()
            }
            DialogState.LOADING -> {
                showLoadingUI()
            }
            DialogState.RESULT -> {
                // Result UI will be shown by showResultUI()
            }
        }
    }

    private fun showInputUI() {
        when (selectedInputMode) {
            "describe" -> showDescribeInput()
            "photo" -> showPhotoInput()
            "barcode" -> showBarcodeInput()
        }
    }

    private fun showDescribeInput() {
        val inputView = LayoutInflater.from(this).inflate(R.layout.dialog_input_describe, contentContainer, false)
        contentContainer.addView(inputView)

        val etDescription = inputView.findViewById<EditText>(R.id.et_meal_description)
        val btnAnalyze = inputView.findViewById<Button>(R.id.btn_analyze)

        btnAnalyze.setOnClickListener {
            val description = etDescription.text.toString().trim()
            if (description.isEmpty()) {
                Toast.makeText(this, "Please describe your meal", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            if (userId == null) {
                showError("User not logged in. Please open the app first.")
                return@setOnClickListener
            }

            Log.d(TAG, "Analyzing meal: $description")
            analyzeMealFromText(description)
        }
    }

    private fun showPhotoInput() {
        val inputView = LayoutInflater.from(this).inflate(R.layout.dialog_input_photo, contentContainer, false)
        contentContainer.addView(inputView)

        val btnTakePhoto = inputView.findViewById<Button>(R.id.btn_take_photo)
        val btnChooseGallery = inputView.findViewById<Button>(R.id.btn_choose_gallery)

        btnTakePhoto.setOnClickListener {
            Log.d(TAG, "Take photo clicked")
            launchPhotoCapture(PhotoCaptureActivity.MODE_CAMERA)
        }

        btnChooseGallery.setOnClickListener {
            Log.d(TAG, "Choose gallery clicked")
            launchPhotoCapture(PhotoCaptureActivity.MODE_GALLERY)
        }
    }

    private fun showBarcodeInput() {
        val inputView = LayoutInflater.from(this).inflate(R.layout.dialog_input_barcode, contentContainer, false)
        contentContainer.addView(inputView)

        val btnStartScanner = inputView.findViewById<Button>(R.id.btn_start_scanner)

        btnStartScanner.setOnClickListener {
            Log.d(TAG, "Start scanner clicked")
            launchBarcodeScanner()
        }
    }

    private fun showLoadingUI() {
        val loadingView = LayoutInflater.from(this).inflate(R.layout.dialog_loading, contentContainer, false)
        contentContainer.addView(loadingView)

        val tvMessage = loadingView.findViewById<TextView>(R.id.tv_loading_message)
        tvMessage.text = when (selectedInputMode) {
            "describe" -> "Analyzing your meal..."
            "photo" -> "Processing image..."
            "barcode" -> "Looking up product..."
            else -> "Loading..."
        }
    }

    private fun analyzeMealFromText(description: String) {
        currentState = DialogState.LOADING
        updateUIForState()

        val args = mapOf(
            "userId" to userId,
            "description" to description,
            "mealType" to selectedMealType
        )

        methodChannel?.invokeMethod("logMealFromText", args, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "✅ Meal logged successfully: $result")

                if (result !is Map<*, *>) {
                    showError("Invalid response format")
                    return
                }

                val data = result as Map<String, Any>
                if (data["success"] == true) {
                    showResultUI(
                        productName = data["productName"] as? String ?: "Unknown",
                        calories = (data["calories"] as? Number)?.toInt() ?: 0,
                        protein = (data["protein"] as? Number)?.toDouble() ?: 0.0,
                        carbs = (data["carbs"] as? Number)?.toDouble() ?: 0.0,
                        fat = (data["fat"] as? Number)?.toDouble() ?: 0.0
                    )
                } else {
                    showError(data["error"] as? String ?: "Failed to log meal")
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "❌ Error logging meal: $errorMessage")
                showError(errorMessage ?: "Failed to log meal")
            }

            override fun notImplemented() {
                Log.e(TAG, "❌ logMealFromText not implemented")
                showError("Feature not available")
            }
        })
    }

    private fun showResultUI(
        productName: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        currentState = DialogState.RESULT
        contentContainer.removeAllViews()

        val resultView = LayoutInflater.from(this).inflate(R.layout.dialog_result_confirmation, contentContainer, false)
        contentContainer.addView(resultView)

        resultView.findViewById<TextView>(R.id.tv_product_name).text = productName
        resultView.findViewById<TextView>(R.id.tv_calories).text = "$calories calories"
        resultView.findViewById<TextView>(R.id.tv_protein).text = "${protein.toInt()}g"
        resultView.findViewById<TextView>(R.id.tv_carbs).text = "${carbs.toInt()}g"
        resultView.findViewById<TextView>(R.id.tv_fat).text = "${fat.toInt()}g"

        Log.d(TAG, "✅ Result displayed: $productName - $calories cal")
    }

    private fun showError(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()

            // Reset to input state
            currentState = DialogState.INPUT_ACTIVE
            updateUIForState()
        }
    }

    private fun launchApp() {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = android.net.Uri.parse("aifitnesscoach://nutrition")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        startActivity(intent)
        overridePendingTransition(0, 0)
    }

    private fun launchPhotoCapture(mode: String) {
        val intent = Intent(this, PhotoCaptureActivity::class.java).apply {
            putExtra(PhotoCaptureActivity.EXTRA_MODE, mode)
        }
        startActivityForResult(intent, REQUEST_PHOTO_CAPTURE)
    }

    private fun launchBarcodeScanner() {
        val intent = Intent(this, BarcodeScannerActivity::class.java)
        startActivityForResult(intent, REQUEST_BARCODE_SCAN)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            REQUEST_PHOTO_CAPTURE -> {
                if (resultCode == RESULT_OK) {
                    val imagePath = data?.getStringExtra(PhotoCaptureActivity.EXTRA_IMAGE_PATH)
                    if (imagePath != null) {
                        Log.d(TAG, "Photo captured: $imagePath")
                        analyzeMealFromImage(imagePath)
                    }
                }
            }
            REQUEST_BARCODE_SCAN -> {
                if (resultCode == RESULT_OK) {
                    val barcode = data?.getStringExtra(BarcodeScannerActivity.EXTRA_BARCODE)
                    if (barcode != null) {
                        Log.d(TAG, "Barcode scanned: $barcode")
                        lookupAndLogBarcode(barcode)
                    }
                }
            }
        }
    }

    private fun analyzeMealFromImage(imagePath: String) {
        if (userId == null) {
            showError("User not logged in. Please open the app first.")
            return
        }

        currentState = DialogState.LOADING
        updateUIForState()

        val args = mapOf(
            "userId" to userId,
            "imagePath" to imagePath,
            "mealType" to selectedMealType
        )

        methodChannel?.invokeMethod("logMealFromImage", args, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "✅ Image meal logged successfully: $result")

                if (result !is Map<*, *>) {
                    showError("Invalid response format")
                    return
                }

                val data = result as Map<String, Any>
                if (data["success"] == true) {
                    showResultUI(
                        productName = data["productName"] as? String ?: "Meal from photo",
                        calories = (data["calories"] as? Number)?.toInt() ?: 0,
                        protein = (data["protein"] as? Number)?.toDouble() ?: 0.0,
                        carbs = (data["carbs"] as? Number)?.toDouble() ?: 0.0,
                        fat = (data["fat"] as? Number)?.toDouble() ?: 0.0
                    )
                } else {
                    showError(data["error"] as? String ?: "Failed to analyze image")
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "❌ Error analyzing image: $errorMessage")
                showError(errorMessage ?: "Failed to analyze image")
            }

            override fun notImplemented() {
                Log.e(TAG, "❌ logMealFromImage not implemented")
                showError("Feature not available")
            }
        })
    }

    private fun lookupAndLogBarcode(barcode: String) {
        if (userId == null) {
            showError("User not logged in. Please open the app first.")
            return
        }

        currentState = DialogState.LOADING
        updateUIForState()

        val args = mapOf(
            "userId" to userId,
            "barcode" to barcode,
            "mealType" to selectedMealType
        )

        methodChannel?.invokeMethod("logMealFromBarcode", args, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "✅ Barcode meal logged successfully: $result")

                if (result !is Map<*, *>) {
                    showError("Invalid response format")
                    return
                }

                val data = result as Map<String, Any>
                if (data["success"] == true) {
                    showResultUI(
                        productName = data["productName"] as? String ?: "Product",
                        calories = (data["calories"] as? Number)?.toInt() ?: 0,
                        protein = (data["protein"] as? Number)?.toDouble() ?: 0.0,
                        carbs = (data["carbs"] as? Number)?.toDouble() ?: 0.0,
                        fat = (data["fat"] as? Number)?.toDouble() ?: 0.0
                    )
                } else {
                    showError(data["error"] as? String ?: "Product not found")
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "❌ Error logging barcode: $errorMessage")
                showError(errorMessage ?: "Failed to log barcode")
            }

            override fun notImplemented() {
                Log.e(TAG, "❌ logMealFromBarcode not implemented")
                showError("Feature not available")
            }
        })
    }
}
