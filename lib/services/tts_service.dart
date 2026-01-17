import 'dart:typed_data';
import '../utils/platform_channels.dart';

/// Service for Text-to-Speech using Kokoro ONNX model
class TTSService {
  bool _isInitialized = false;
  String _currentVoice = 'female';
  double _speed = 1.0;

  /// Initialize the TTS model
  Future<void> initialize(String modelPath) async {
    if (_isInitialized) return;
    
    try {
      final loaded = await PlatformChannels.loadTTSModel(modelPath);
      if (!loaded) {
        throw Exception('Failed to load TTS model');
      }
      _isInitialized = true;
    } catch (e) {
      throw Exception('TTS initialization failed: $e');
    }
  }

  /// Synthesize text to speech
  /// Returns PCM audio data (16-bit, 16kHz, mono)
  Future<Uint8List> synthesize(
    String text, {
    double? speed,
    String? voice,
  }) async {
    if (!_isInitialized) {
      throw Exception('TTS service not initialized');
    }

    if (text.isEmpty) {
      return Uint8List(0);
    }

    try {
      // Prepare text for TTS
      final preparedText = _prepareText(text);
      
      // Use provided values or defaults
      final ttsSpeed = speed ?? _speed;
      final ttsVoice = voice ?? _currentVoice;
      
      // Call native TTS synthesis
      final audioData = await PlatformChannels.synthesize(
        preparedText,
        speed: ttsSpeed,
        voice: ttsVoice,
      );
      
      return audioData;
    } catch (e) {
      throw Exception('Speech synthesis failed: $e');
    }
  }

  /// Synthesize text to speech with streaming
  /// Returns stream of audio chunks for real-time playback
  Stream<Uint8List> synthesizeStream(String text) {
    if (!_isInitialized) {
      throw Exception('TTS service not initialized');
    }
    
    final preparedText = _prepareText(text);
    return PlatformChannels.synthesizeStream(preparedText);
  }

  /// Prepare text for TTS (clean up, handle abbreviations, etc.)
  String _prepareText(String text) {
    // Remove extra whitespace
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Expand common abbreviations for better pronunciation
    final abbreviations = {
      'Dr.': 'Doctor',
      'Mr.': 'Mister',
      'Mrs.': 'Misses',
      'Ms.': 'Miss',
      'Prof.': 'Professor',
      'St.': 'Street',
      'Ave.': 'Avenue',
      'etc.': 'etcetera',
      'e.g.': 'for example',
      'i.e.': 'that is',
      'vs.': 'versus',
      'approx.': 'approximately',
    };
    
    abbreviations.forEach((abbr, full) {
      text = text.replaceAll(abbr, full);
    });
    
    // Handle numbers and dates (basic)
    text = _expandNumbers(text);
    
    // Remove URLs (they don't sound good when read aloud)
    text = text.replaceAll(RegExp(r'https?://\S+'), 'link');
    
    // Remove markdown/special characters that don't translate to speech
    text = text.replaceAll(RegExp(r'[*_`#]'), '');
    
    // Ensure text ends with punctuation for proper intonation
    if (text.isNotEmpty && !_endsWithPunctuation(text)) {
      text += '.';
    }
    
    return text;
  }

  /// Expand numbers to words (basic implementation)
  String _expandNumbers(String text) {
    // This is a simplified version - you may want a more robust solution
    final numberWords = {
      '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
      '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine',
      '10': 'ten', '11': 'eleven', '12': 'twelve', '13': 'thirteen',
      '14': 'fourteen', '15': 'fifteen', '16': 'sixteen', '17': 'seventeen',
      '18': 'eighteen', '19': 'nineteen', '20': 'twenty',
    };
    
    // Replace single/double digit numbers
    numberWords.forEach((num, word) {
      text = text.replaceAll(RegExp('\\b$num\\b'), word);
    });
    
    return text;
  }

  /// Check if text ends with punctuation
  bool _endsWithPunctuation(String text) {
    if (text.isEmpty) return false;
    final lastChar = text[text.length - 1];
    return lastChar == '.' || lastChar == '!' || lastChar == '?';
  }

  /// Set voice (female/male)
  void setVoice(String voice) {
    _currentVoice = voice;
  }

  /// Set speech speed (0.5 - 2.0)
  void setSpeed(double speed) {
    _speed = speed.clamp(0.5, 2.0);
  }

  /// Get current voice
  String get voice => _currentVoice;

  /// Get current speed
  double get speed => _speed;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}