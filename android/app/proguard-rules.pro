# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core deferred-components — referenced by the Flutter engine embedding but
# not present in APKs distributed outside the Play Store (Firebase App Distribution,
# direct install). Suppress R8 missing-class errors; these code paths are never
# reached in a non-Play-Store build.
-dontwarn com.google.android.play.core.**

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
