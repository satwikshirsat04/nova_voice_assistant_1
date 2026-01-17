name: nova_voice_assistant
description: Offline AI Voice Assistant with Parakeet STT, LFM-2 LLM, and Kokoro TTS
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # UI & Animations
  cupertino_icons: ^1.0.2
  flutter_animate: ^4.5.0
  animated_text_kit: ^4.2.2
  
  # Audio
  record: ^5.0.4
  just_audio: ^0.9.36
  path_provider: ^2.1.1
  
  # Waveform Visualization
  audio_waveforms: ^1.0.5
  
  # State Management
  provider: ^6.1.1
  
  # Platform Channels & FFI
  ffi: ^2.1.0
  
  # Storage
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  
  # Utilities
  permission_handler: ^11.1.0
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/models/
    - assets/images/
    - assets/animations/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700