plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "com.aifitnesscoach.wear"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.aifitnesscoach.wear"
        minSdk = 30 // Wear OS 3.0+
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Shared module
    implementation(project(":shared"))

    // Wear OS Compose
    implementation(platform("androidx.compose:compose-bom:2024.11.00"))
    implementation("androidx.wear.compose:compose-material3:1.0.0-alpha29")
    implementation("androidx.wear.compose:compose-foundation:1.4.0")
    implementation("androidx.wear.compose:compose-navigation:1.4.0")

    // Core
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")

    // Wear OS specific
    implementation("androidx.wear:wear:1.3.0")
    implementation("androidx.wear.tiles:tiles:1.4.1")
    implementation("androidx.wear.watchface:watchface-complications-data-source-ktx:1.2.1")

    // Health Services for workout tracking
    implementation("androidx.health:health-services-client:1.1.0-alpha05")

    // Data Layer API for phone-watch communication
    implementation("com.google.android.gms:play-services-wearable:18.2.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
