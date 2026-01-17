# 🚀 Nova Voice Assistant - Quick Start Guide

Get your offline AI voice assistant running in under 30 minutes!

## ⚡ Fastest Path to Running

### Step 1: Clone & Setup (5 minutes)

```bash
# Clone the repository
git clone https://github.com/yourusername/nova-voice-assistant.git
cd nova-voice-assistant

# Install dependencies
flutter pub get

# Verify Flutter is ready
flutter doctor
```

### Step 2: Download Models (10-15 minutes)

**Option A: Automated Script (Coming Soon)**
```bash
./scripts/download_models.sh
```

**Option B: Manual Download**

Create directories:
```bash
mkdir -p assets/models/{parakeet,lfm2,kokoro}
```

Download models:

1. **Parakeet STT** → `assets/models/parakeet/`
   - [Download encoder.onnx](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx)
   - ~700MB

2. **LFM-2 LLM** → `assets/models/lfm2/`
   - Download `LFM-2-1B-Q4_K_M.gguf` from HuggingFace
   - ~1.2GB

3. **Kokoro TTS** → `assets/models/kokoro/`
   - [Download model.onnx](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX)
   - ~92MB

### Step 3: Run on Device (5 minutes)

**For Android:**
```bash
# Connect Android device with USB debugging enabled
flutter run --release
```

**For iOS:**
```bash
cd ios
pod install
cd ..

# Open in Xcode and run, or:
flutter run --release
```

### Step 4: Test! 🎉

1. Open the app
2. Wait for models to load (first launch: ~30 seconds)
3. Tap and hold the microphone button
4. Speak your question
5. Release and wait for response

---

## 📁 Project Structure Overview

```
nova_voice_assistant/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/                     # UI screens
│   │   ├── welcome_screen.dart     # Onboarding
│   │   ├── chat_screen.dart        # Main chat UI
│   │   └── settings_screen.dart    # Settings
│   ├── providers/                   # State management
│   │   ├── voice_agent_provider.dart  # Core orchestrator
│   │   ├── chat_provider.dart      # Chat history
│   │   └── settings_provider.dart  # App settings
│   ├── services/                    # Business logic
│   │   ├── stt_service.dart        # Speech-to-Text
│   │   ├── llm_service.dart        # Text generation
│   │   ├── tts_service.dart        # Text-to-Speech
│   │   ├── audio_recorder_service.dart
│   │   ├── audio_player_service.dart
│   │   └── model_loader_service.dart
│   ├── widgets/                     # Reusable UI components
│   │   ├── mic_button.dart
│   │   ├── chat_bubble.dart
│   │   └── waveform_visualizer.dart
│   ├── models/                      # Data models
│   │   └── chat_message.dart
│   └── utils/
│       └── platform_channels.dart   # Native bridge
├── android/                         # Android native code
│   └── app/src/main/kotlin/
│       ├── MainActivity.kt
│       ├── ParakeetNative.kt       # STT wrapper
│       ├── LFM2Native.kt           # LLM wrapper
│       └── KokoroNative.kt         # TTS wrapper
├── ios/                            # iOS native code
│   └── Runner/
│       ├── AppDelegate.swift
│       ├── ParakeetNative.swift
│       ├── LFM2Native.swift
│       └── KokoroNative.swift
└── assets/
    └── models/                     # AI models (not in git)
        ├── parakeet/
        ├── lfm2/
        └── kokoro/
```

---

## 🎯 Key Concepts

### Voice Agent Pipeline

```
User Speech → STT → LLM → TTS → AI Voice Output
     ↓         ↓     ↓     ↓          ↓
  Parakeet → LFM-2 → Kokoro → Audio Player
```

### State Flow

1. **Idle** - Ready for input
2. **Listening** - Recording audio
3. **Transcribing** - Converting speech to text
4. **Thinking** - Generating AI response
5. **Speaking** - Playing synthesized voice
6. **Error** - Something went wrong

### Model Sizes & Requirements

| Model | Size | RAM Usage | Purpose |
|-------|------|-----------|---------|
| Parakeet | 700MB | ~1GB | Speech recognition |
| LFM-2 1B | 1.2GB | ~2GB | Text generation |
| Kokoro | 92MB | ~500MB | Voice synthesis |
| **Total** | **~2GB** | **~4-6GB** | Full pipeline |

---

## 🔧 Configuration

### Adjust Performance

Edit `lib/providers/voice_agent_provider.dart`:

```dart
// For better quality (slower)
contextSize: 2048,
temperature: 0.7,
maxTokens: 256,

// For faster response (lower quality)
contextSize: 1024,
temperature: 0.5,
maxTokens: 128,
```

### Change Voice

Edit `lib/providers/settings_provider.dart`:

```dart
// Default voice
_assistantVoice = 'female';

// Or change to
_assistantVoice = 'male';
```

### Modify System Prompt

Edit `lib/services/llm_service.dart`:

```dart
static const String SYSTEM_PROMPT = '''
You are Nova, a helpful AI assistant.
Be concise and friendly.
''';
```

---

## 🐛 Common Issues & Fixes

### Issue: "Model file not found"

**Solution:**
```bash
# Verify models exist
ls -lh assets/models/parakeet/
ls -lh assets/models/lfm2/
ls -lh assets/models/kokoro/

# Rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: App crashes on launch

**Solution:**
- Check device has 6GB+ RAM
- Close other apps
- Try smaller quantized models (Q4 instead of Q8)
- Check logs: `flutter logs`

### Issue: Response is too slow (>2 seconds)

**Solution:**
```dart
// Reduce context size
contextSize: 1024,  // instead of 2048

// Reduce max tokens
maxTokens: 128,  // instead of 256

// Increase threads (if device supports)
threads: 6,  // instead of 4
```

### Issue: No microphone permission

**Solution:**

**Android**: Check `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**iOS**: Check `ios/Runner/Info.plist`
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Required for voice input</string>
```

---

## 📱 Testing Checklist

Before submitting or deploying:

- [ ] Models load successfully on first launch
- [ ] Voice recording works (waveform visible)
- [ ] Transcription is accurate
- [ ] LLM generates relevant responses
- [ ] TTS sounds natural
- [ ] Response time <700ms
- [ ] App doesn't crash after 10+ conversations
- [ ] Settings persist across restarts
- [ ] Chat history saves correctly
- [ ] Works without internet connection

---

## 🎨 Customization Ideas

### Change Theme Colors

Edit `lib/main.dart`:

```dart
primaryColor: const Color(0xFF2E5BFF),  // Your brand color
scaffoldBackgroundColor: const Color(0xFF0A1128),
```

### Add Custom Responses

Edit `lib/services/llm_service.dart`:

```dart
// Add custom post-processing
String _cleanResponse(String response) {
  // Add your custom logic
  if (response.contains("weather")) {
    response += " Stay safe!";
  }
  return response;
}
```

### Modify UI

- Welcome screen: `lib/screens/welcome_screen.dart`
- Chat interface: `lib/screens/chat_screen.dart`
- Mic button: `lib/widgets/mic_button.dart`
- Waveform: `lib/widgets/waveform_visualizer.dart`

---

## 🚀 Next Steps

### Add Features

1. **Wake Word Detection**
   - Implement in `audio_recorder_service.dart`
   - Use Porcupine or Snowboy

2. **Conversation Context**
   - Already supported via `chat_provider.dart`
   - Extend history management

3. **Multi-language**
   - Add language parameter to services
   - Download additional models

### Optimize Further

1. **Model Quantization**
   - Use INT4 quantization for LLM
   - Reduces size by 50%

2. **Lazy Loading**
   - Load models on-demand
   - Reduces initial startup time

3. **Caching**
   - Cache common responses
   - Implement in `llm_service.dart`

---

## 📚 Resources

### Documentation
- [Full Documentation](README.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Architecture Details](ARCHITECTURE.md)

### Model Resources
- [Parakeet Models](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx)
- [LFM-2 Models](https://huggingface.co/models?search=lfm)
- [Kokoro TTS](https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX)

### Community
- GitHub Issues
- Discord Server (Coming Soon)
- Stack Overflow Tag: `nova-voice-assistant`

---

## 🎉 You're Ready!

Your Nova Voice Assistant is now running! Try these commands:

- "What's the weather like today?"
- "Tell me a joke"
- "Remind me to call John at 3 PM"
- "What's 25 times 17?"
- "Explain quantum computing"

**Have fun building with AI!** 🤖✨