# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ONNX Runtime
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep model classes
-keep class com.example.nova_voice_assistant.ParakeetNative { *; }
-keep class com.example.nova_voice_assistant.LFM2Native { *; }
-keep class com.example.nova_voice_assistant.KokoroNative { *; }

# Keep MainActivity
-keep class com.example.nova_voice_assistant.MainActivity { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile