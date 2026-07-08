# CameraX — used by mobile_scanner for the camera preview and frame analysis.
# R8 strips these by default; keeping them prevents the null-object-reference crash
# that occurs when CameraX tries to bind the use case on first launch.
-keep class androidx.camera.** { *; }
-keep interface androidx.camera.** { *; }
-keepclassmembers class androidx.camera.** { *; }

# Google ML Kit Barcode Scanning — the actual barcode/QR detection engine.
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }

# ML Kit's other script recognizers (Chinese, Japanese, Korean, Devanagari) are opt-in deps we don't include.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# mobile_scanner Flutter plugin bridge.
-keep class dev.steenbakker.mobile_scanner.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# Flutter standard keep rules (in case flutter.proguard is not applied automatically).
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core classes referenced by Flutter's deferred-components code but not present
# unless the app uses Play Store dynamic delivery. We don't, so suppress the warnings.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
