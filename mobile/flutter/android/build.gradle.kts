buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all subprojects (including plugin dependencies like posthog_flutter)
// to compile with Kotlin language version 1.9 so they work with Kotlin 2.x / Gradle 8.14+.
//
// Also PIN every module's JVM target to 17 — both the Java compile and the
// Kotlin compile. Some plugins (e.g. receive_sharing_intent 1.8.1) declare no
// `compileOptions`, so their Java defaults to 1.8 while Kotlin defaults to the
// JDK toolchain (21). Gradle 8+ then aborts with "Inconsistent JVM-target
// compatibility ... (1.8) and (21)". Forcing BOTH to 17 (the same target the
// :app module uses) makes every module internally consistent, app and plugins
// alike. Must be 17 everywhere — matching only one side just moves the mismatch.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9)
            apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9)
        }
    }
    // PIN every module's JVM target to 17 — BOTH the Java compile and the Kotlin
    // compile — and do it in afterEvaluate so it lands AFTER each plugin declared
    // its own target. Plugins disagree in both directions:
    //   - receive_sharing_intent 1.8.1: no compileOptions → Java 1.8, Kotlin 21
    //   - audioplayers_android 5.2.1:   compileOptions+kotlinOptions both 1.8
    //   - workmanager_android:          kotlinOptions jvmTarget '1.8'
    // Gradle 8+ aborts on any in-module Java≠Kotlin split. Setting these EARLY
    // (plain configureEach / task sourceCompatibility) loses to a plugin's own
    // explicit block; setting them in afterEvaluate wins. Java must go through the
    // AGP `android` extension — AGP rejects `options.release` (issuetracker
    // 278800528) and ignores the raw JavaCompile task's sourceCompatibility when
    // its own compileOptions are set. BaseExtension is the common supertype of the
    // application and library android extensions.
    val pin17: Project.() -> Unit = {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    // Only :app is force-evaluated early (by evaluationDependsOn above) and it
    // already targets 17, so skip it once executed (its options are finalized).
    // Every plugin subproject is still un-evaluated here, so defer to
    // afterEvaluate — which runs after the plugin declared its own target,
    // letting 17 win before the options finalize.
    if (!state.executed) {
        afterEvaluate { pin17() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
