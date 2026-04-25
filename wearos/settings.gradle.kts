// =============================================================================
// WEAR OS MODULE — DISABLED 2026-04-25
// =============================================================================
// Disabled prior to FitWiz consumer-flavor launch on Google Play to avoid
// shipping/maintaining a wearable companion alongside an active trademark
// dispute risk and the smaller surface area we want to test in v1.
//
// The module is a STANDALONE Android Gradle project (not part of the Flutter
// app's `mobile/flutter/android/` build), so commenting out `include(":app")`
// here just makes `./gradlew` from this directory build nothing. The Flutter
// Play Store APK was never affected by this module.
//
// To re-enable later:
//   1. Uncomment `include(":app")` below.
//   2. Rename Kotlin packages from `com.fitwiz.wearos.*` to
//      `com.aifitnesscoach.wearos.*` (use IntelliJ refactor) AND update
//      `namespace` / `applicationId` in `app/build.gradle.kts` — current
//      `com.fitwiz.wearos` namespace shares the `com.fitwiz` root with the
//      registered FITWIZ trademark holder's iOS app.
// =============================================================================

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "FitWizWearOS"
// include(":app")  // DISABLED 2026-04-25 — see banner above before re-enabling.
