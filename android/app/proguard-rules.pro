# Flutter core classes
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# RevenueCat (Purchases) - CRITICAL
-keep class com.revenuecat.purchases.** { *; }
-keep class com.revenuecat.** { *; }

# Prevent obfuscation of your Data Models (Adjust package name!)
# Replace 'com.example.dime_meridian' with your actual package name from AndroidManifest.xml
-keep class com.dimemeridian.app.** { *; }

# Suppress warnings for Google Play Core (Split Install / Deferred Components)
# These are referenced by Flutter Engine but not always used by the app.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**