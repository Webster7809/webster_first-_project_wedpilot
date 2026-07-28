# Flutter's default embedding classes.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# flutter_local_notifications uses reflection to find notification icons/actions.
-keep class com.dexterous.** { *; }

# Play Core split-install classes referenced by the Flutter engine's deferred-components
# support, even though this app doesn't use deferred components. Missing-class warnings
# for these are safe to ignore with R8 full mode.
-dontwarn com.google.android.play.core.**
