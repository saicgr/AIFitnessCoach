# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Keep app classes for JSON serialization
-keep class com.aifitnesscoach.app.** { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.libraries.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Health Connect
-keep class androidx.health.connect.** { *; }
-keep class androidx.health.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# RevenueCat
-keep class com.revenuecat.** { *; }

# ML Kit (Barcode Scanner)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Google Play Core (for deferred components / split APKs)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Suppress warnings for common libraries
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
