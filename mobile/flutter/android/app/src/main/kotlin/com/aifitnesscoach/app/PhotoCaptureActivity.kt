package com.aifitnesscoach.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.File
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Camera activity for capturing photos or selecting from gallery
 * Returns image path to QuickLogDialogActivity for meal logging
 */
class PhotoCaptureActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "PhotoCapture"
        private const val REQUEST_CAMERA_PERMISSION = 100
        private const val REQUEST_GALLERY_PICK = 200
        const val EXTRA_IMAGE_PATH = "image_path"
        const val EXTRA_MODE = "mode"
        const val MODE_CAMERA = "camera"
        const val MODE_GALLERY = "gallery"
    }

    private var previewView: PreviewView? = null
    private var imageCapture: ImageCapture? = null
    private lateinit var cameraExecutor: ExecutorService
    private var photoFile: File? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_photo_capture)

        Log.d(TAG, "PhotoCaptureActivity created")

        cameraExecutor = Executors.newSingleThreadExecutor()

        val mode = intent.getStringExtra(EXTRA_MODE) ?: MODE_CAMERA

        when (mode) {
            MODE_CAMERA -> {
                if (checkCameraPermission()) {
                    startCamera()
                } else {
                    requestCameraPermission()
                }
            }
            MODE_GALLERY -> openGallery()
        }
    }

    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            REQUEST_CAMERA_PERMISSION
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Camera permission granted")
                startCamera()
            } else {
                Log.e(TAG, "Camera permission denied")
                Toast.makeText(this, "Camera permission is required", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun startCamera() {
        previewView = findViewById(R.id.camera_preview)

        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener({
            try {
                val cameraProvider = cameraProviderFuture.get()

                // Preview
                val preview = Preview.Builder()
                    .build()
                    .also {
                        it.setSurfaceProvider(previewView?.surfaceProvider)
                    }

                // ImageCapture
                imageCapture = ImageCapture.Builder()
                    .setTargetRotation(windowManager.defaultDisplay.rotation)
                    .build()

                // Select back camera
                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                // Unbind all use cases before rebinding
                cameraProvider.unbindAll()

                // Bind use cases to camera
                cameraProvider.bindToLifecycle(
                    this,
                    cameraSelector,
                    preview,
                    imageCapture
                )

                Log.d(TAG, "Camera started successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start camera: $e")
                Toast.makeText(this, "Failed to start camera", Toast.LENGTH_SHORT).show()
                finish()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    fun onCaptureClick(view: View) {
        Log.d(TAG, "Capture button clicked")

        val imageCapture = imageCapture ?: run {
            Log.e(TAG, "ImageCapture not initialized")
            return
        }

        // Create file to save photo
        photoFile = createImageFile()

        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile!!).build()

        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(this),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    Log.d(TAG, "Photo saved: ${photoFile?.absolutePath}")
                    returnPhotoResult(photoFile!!.absolutePath)
                }

                override fun onError(exc: ImageCaptureException) {
                    Log.e(TAG, "Photo capture failed: ${exc.message}")
                    Toast.makeText(
                        this@PhotoCaptureActivity,
                        "Failed to capture photo: ${exc.message}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        )
    }

    fun onCancelClick(view: View) {
        Log.d(TAG, "Cancel clicked")
        setResult(RESULT_CANCELED)
        finish()
    }

    private fun openGallery() {
        Log.d(TAG, "Opening gallery")
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        startActivityForResult(intent, REQUEST_GALLERY_PICK)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_GALLERY_PICK && resultCode == RESULT_OK) {
            val selectedImageUri = data?.data
            if (selectedImageUri != null) {
                Log.d(TAG, "Gallery image selected: $selectedImageUri")
                val photoPath = copyImageToAppDir(selectedImageUri)
                returnPhotoResult(photoPath)
            } else {
                Log.e(TAG, "Failed to get gallery image URI")
                setResult(RESULT_CANCELED)
                finish()
            }
        } else {
            setResult(RESULT_CANCELED)
            finish()
        }
    }

    private fun copyImageToAppDir(uri: Uri): String {
        try {
            val inputStream: InputStream? = contentResolver.openInputStream(uri)
            val photoFile = createImageFile()

            inputStream?.use { input ->
                photoFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            Log.d(TAG, "Image copied to: ${photoFile.absolutePath}")
            return photoFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy image: $e")
            throw e
        }
    }

    private fun createImageFile(): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val storageDir = externalCacheDir ?: cacheDir
        return File(storageDir, "meal_$timeStamp.jpg")
    }

    private fun returnPhotoResult(imagePath: String) {
        val intent = Intent()
        intent.putExtra(EXTRA_IMAGE_PATH, imagePath)
        setResult(RESULT_OK, intent)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
    }
}
