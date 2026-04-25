import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load android/key.properties if it exists. Used as a fallback for local
// builds when KEYSTORE_PASSWORD / KEY_PASSWORD env vars aren't exported.
// CI should prefer env vars (set via GitHub Actions / Codemagic secrets).
// The file is gitignored — see android/key.properties.example.
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

fun keystoreProp(name: String): String? =
    System.getenv(name)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(
            when (name) {
                "KEYSTORE_PATH" -> "storeFile"
                "KEYSTORE_PASSWORD" -> "storePassword"
                "KEY_ALIAS" -> "keyAlias"
                "KEY_PASSWORD" -> "keyPassword"
                else -> name
            }
        )?.takeIf { it.isNotBlank() }

android {
    namespace = "com.aifitnesscoach.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Use shared debug keystore from project for consistent SHA-1 across dev machines
    signingConfigs {
        getByName("debug") {
            storeFile = file("../keystores/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        create("release") {
            // Release builds REQUIRE every credential. Resolution order:
            //   1. Environment variables (KEYSTORE_PATH / KEYSTORE_PASSWORD /
            //      KEY_ALIAS / KEY_PASSWORD) — preferred for CI/CD.
            //   2. android/key.properties — fallback for local laptop builds
            //      (gitignored; see key.properties.example).
            //   3. Hard fail with a clear message — never silently sign with
            //      an empty password.
            storeFile = file(
                keystoreProp("KEYSTORE_PATH")
                    ?: "../keystores/release.keystore"
            )
            storePassword = keystoreProp("KEYSTORE_PASSWORD")
                ?: error("KEYSTORE_PASSWORD missing — set env var or android/key.properties (see key.properties.example).")
            keyAlias = keystoreProp("KEY_ALIAS") ?: "fitwiz"
            keyPassword = keystoreProp("KEY_PASSWORD")
                ?: error("KEY_PASSWORD missing — set env var or android/key.properties (see key.properties.example).")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aifitnesscoach.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26  // Required for Health Connect
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Enable R8 minification and resource shrinking for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // ABI splits disabled — app bundles handle per-ABI splitting automatically.
    // Only enable for direct APK installs (not Play Store uploads).
    splits {
        abi {
            isEnable = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // CameraX for photo capture and barcode scanning
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")

    // ML Kit Barcode Scanning (on-device)
    implementation("com.google.mlkit:barcode-scanning:17.2.0")

    // Guava for ListenableFuture (required by CameraX)
    implementation("com.google.guava:guava:31.1-android")

    // Wearable Data Layer API for watch sync
    implementation("com.google.android.gms:play-services-wearable:19.0.0")

    // Wear OS Remote Interactions for prompting watch app install
    implementation("androidx.wear:wear-remote-interactions:1.1.0")

    // Coroutines for async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")

    // Gson for JSON serialization
    implementation("com.google.code.gson:gson:2.10.1")
}
