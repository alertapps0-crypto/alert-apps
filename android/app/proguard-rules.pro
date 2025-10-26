# Basic ProGuard / R8 rules for Flutter + common plugins
# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase messaging receiver/intent services if using FCM
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Keep classes referenced by reflection in popular plugins (add more if you see runtime errors)
-keep class androidx.work.** { *; }

# If you add rules above and get missing classes at runtime, adjust accordingly.
# You can add -dontwarn lines for third-party libs if necessary.
