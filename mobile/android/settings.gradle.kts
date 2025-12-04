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

rootProject.name = "AIFitnessCoach"

include(":app")        // Phone & Tablet app
include(":wear")       // Wear OS (Galaxy Watch) app
include(":shared")     // Shared code (API, models, etc.)
