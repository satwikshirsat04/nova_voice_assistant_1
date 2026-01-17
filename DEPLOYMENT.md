# Nova Voice Assistant - Deployment Guide

Complete guide for building and deploying your offline AI voice assistant to Android and iOS.

## 📋 Prerequisites

### Development Environment
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code with Flutter extensions
- Xcode 14+ (for iOS development, macOS only)

### Android Requirements
- Android SDK API 24+ (Android 7.0+)
- NDK r25b or higher
- Gradle 7.0+
- 8GB RAM minimum on development machine

### iOS Requirements
- macOS 12+ (Monterey or higher)
- Xcode 14+
- CocoaPods 1.11+
- iOS deployment target 12.0+

## 🔧 Initial Setup

### 1. Clone and Install Dependencies

```bash
# Clone repository
git clone https://github.com/yourusername/nova-voice-assistant.git
cd nova-voice-assistant

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### 2. Download AI Models

Create the models directory structure:
```bash
mkdir -p assets/models/{parakeet,lfm2,kokoro}
```

#### Parakeet STT Model
```bash
cd assets/models/parakeet
# Download from: https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx
# Required files:
# - encoder.onnx (~700MB)
# - decoder.onnx
# - vocab.json
```

#### LFM-2 LLM Model
```bash
cd assets/models/lfm2
# Download quantized GGUF model
# Recommended: LFM-2-1B-Q4_K_M.gguf (1.2GB)
# Or: LFM-2-2B-Q4_K_M.gguf (2.1GB)
```

#### Kokoro TTS Model
```bash
cd assets/models/kokoro
# Download from: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX
# Required files:
# - model.onnx (~92MB)
# - config.json
```

### 3. Update pubspec.yaml

Ensure models are included in assets:
```yaml
flutter:
  assets:
    - assets/models/parakeet/
    - assets/models/lfm2/
    - assets/models/kokoro/
```

## 📱 Android Deployment

### 1. Setup Native Libraries

#### Install ONNX Runtime
Already configured in `build.gradle`:
```gradle
dependencies {
    implementation 'com.microsoft.onnxruntime:onnxruntime-android:1.17.0'
}
```

#### Build llama.cpp for Android
```bash
# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Build for Android
mkdir build-android && cd build-android
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF

make -j4

# Copy library to project
cp libllama.so ../nova-voice-assistant/android/app/src/main/jniLibs/arm64-v8a/
```

### 2. Configure Build

Update `android/app/build.gradle`:
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 24
        targetSdk 34
        
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
}
```

### 3. Generate Signing Key

```bash
keytool -genkey -v -keystore ~/nova-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias nova
```

Create `android/key.properties`:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=nova
storeFile=/path/to/nova-keystore.jks
```

### 4. Build APK/AAB

```bash
# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### 5. Install on Device

```bash
# Install APK
flutter install

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 🍎 iOS Deployment

### 1. Setup CocoaPods

```bash
cd ios
pod install
cd ..
```

### 2. Configure Xcode Project

Open `ios/Runner.xcworkspace` in Xcode:

1. **Set Team & Bundle ID**
   - Select Runner target
   - General tab → Team → Select your team
   - Bundle Identifier → `com.yourcompany.novavoiceassistant`

2. **Enable Capabilities**
   - Signing & Capabilities
   - Add "Background Modes" (if needed)

3. **Configure Build Settings**
   - Build Settings → Deployment → iOS Deployment Target → 12.0
   - Build Settings → Build Options → Enable Bitcode → No

### 3. Add Privacy Permissions

Update `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Nova needs access to your microphone for voice conversations.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Nova uses speech recognition for offline voice processing.</string>
```

### 4. Build llama.cpp for iOS

```bash
# Clone llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Build for iOS (arm64)
mkdir build-ios && cd build-ios
cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DLLAMA_BUILD_TESTS=OFF

make -j4

# Create XCFramework
xcodebuild -create-xcframework \
  -library libllama.a \
  -output LlamaCpp.xcframework

# Copy to project
cp -r LlamaCpp.xcframework ../nova-voice-assistant/ios/
```

### 5. Build IPA

```bash
# Build for device
flutter build ios --release

# Or build archive in Xcode:
# Product → Archive
# Then distribute to App Store or for testing
```

### 6. TestFlight Distribution

1. Archive the app in Xcode
2. Distribute to App Store Connect
3. Upload to TestFlight
4. Add testers and distribute

## 🚀 Optimization Tips

### Model Optimization

#### Reduce Model Size
```bash
# For LLM, use smaller quantization:
# Q4_K_M (recommended, good balance)
# Q4_K_S (smaller, faster, less quality)
# Q3_K_M (very small, noticeable quality loss)
```

#### Compress Assets
```bash
# Enable asset compression in pubspec.yaml
flutter:
  assets:
    - assets/models/
  uses-material-design: true
  
# Then build with:
flutter build apk --release --split-per-abi
```

### Performance Optimization

#### Android ProGuard
Already configured in `proguard-rules.pro` - enables code shrinking and obfuscation.

#### iOS Optimization
- Enable Whole Module Optimization in build settings
- Set Optimization Level to `-O3` for release builds

### Size Optimization

#### Split APKs by ABI
```bash
flutter build apk --split-per-abi --release
```
Creates separate APKs for each architecture, reducing download size.

#### Dynamic Feature Modules (Advanced)
For models >100MB, consider using dynamic delivery on Play Store.

## 📊 Testing

### Device Testing Matrix

**Android:**
- Minimum: Android 7.0, 4GB RAM
- Recommended: Android 10+, 6GB+ RAM
- Test devices: Pixel 5, Samsung Galaxy S21, OnePlus 9

**iOS:**
- Minimum: iPhone 8, iOS 12.0
- Recommended: iPhone 11 or later, iOS 14+
- Test devices: iPhone 8, iPhone 12, iPhone 14

### Performance Benchmarks

Run performance tests:
```bash
flutter run --profile
# Then use DevTools to profile
flutter pub global activate devtools
flutter pub global run devtools
```

Target metrics:
- Response latency: <700ms
- CPU usage: <45% average
- RAM usage: 4-6GB
- Battery drain: <10%/hour

## 🐛 Troubleshooting

### Common Issues

#### "Model file not found"
- Ensure models are in correct `assets/models/` directories
- Run `flutter clean && flutter pub get`
- Check that models are listed in `pubspec.yaml`

#### "ONNX Runtime error"
- Verify ONNX Runtime version matches in `build.gradle`
- Check model format compatibility
- Ensure device has sufficient RAM

#### "Native library not found"
- For Android: Check `jniLibs` contains correct ABIs
- For iOS: Verify XCFramework is properly linked
- Rebuild native libraries for target platform

#### Out of Memory
- Use smaller quantized models (Q4 instead of Q8)
- Reduce context window size
- Close other apps

## 📝 Release Checklist

- [ ] All models downloaded and placed correctly
- [ ] App icon and splash screen updated
- [ ] Version number incremented in `pubspec.yaml`
- [ ] Tested on minimum supported devices
- [ ] ProGuard rules configured (Android)
- [ ] Signing configured for both platforms
- [ ] Privacy policy and terms of service ready
- [ ] App Store screenshots and descriptions prepared
- [ ] Performance benchmarks meet targets
- [ ] Battery usage optimized
- [ ] Crash reporting integrated (optional)

## 🎯 Next Steps

After successful deployment:

1. **Monitor Analytics**
   - Track crash reports
   - Monitor performance metrics
   - Gather user feedback

2. **Iterate and Improve**
   - Update models as better versions become available
   - Optimize based on real-world usage
   - Add new features based on feedback

3. **Documentation**
   - Create user guides
   - Write troubleshooting FAQs
   - Maintain changelog

---

**Need Help?**

- GitHub Issues: [Project Issues](https://github.com/yourusername/nova-voice-assistant/issues)
- Documentation: [Full Docs](https://docs.yoursite.com)
- Community: [Discord/Forum](https://discord.gg/yourserver)