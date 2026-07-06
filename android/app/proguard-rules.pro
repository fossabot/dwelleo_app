# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# freeRASP
-keep class com.aheaditec.freerasplib.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings { *; }
