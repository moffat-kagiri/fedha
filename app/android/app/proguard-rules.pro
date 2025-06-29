# Flutter and Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Handle missing Google Play Core classes (for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep our custom classes
-keep class com.fedha.app.** { *; }
-keep class com.fedha.fedha.** { *; }

# Keep method channels and handlers
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# Keep BroadcastReceiver classes
-keep class * extends android.content.BroadcastReceiver { *; }

# Keep Activity classes
-keep class * extends android.app.Activity { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity { *; }

# Keep notification related classes
-keep class androidx.core.app.** { *; }
-keep class android.app.NotificationManager { *; }

# Keep SMS related classes
-keep class android.provider.Telephony** { *; }
-keep class android.telephony.** { *; }

# Hive and reflection-based libraries
-keep class * extends hive.** { *; }
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Prevent obfuscation of method names for method channels
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel.* <methods>;
}

# Ignore missing Play Core classes (we don't use deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
