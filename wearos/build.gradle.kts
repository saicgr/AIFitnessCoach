// Top-level build file for Zealova Wear OS
//
// MODULE DISABLED 2026-04-25 — see settings.gradle.kts for context.
// Plugins remain declared so the file stays valid; no project applies them
// while `include(":app")` is commented out. Re-enable settings.gradle.kts to
// resume Wear OS development.

plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    id("com.google.dagger.hilt.android") version "2.50" apply false
    id("com.google.devtools.ksp") version "1.9.22-1.0.17" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
