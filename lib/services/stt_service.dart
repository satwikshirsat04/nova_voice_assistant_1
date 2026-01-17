import 'dart:typed_data';
import '../utils/platform_channels.dart';

/// Service for Speech-to-Text using Parakeet ONNX model
class STTService {
  bool _isInitialized = false;

  /// Initialize the STT model
  Future<void> initialize(String modelPath) async {
    if (_isInitialized) return;
    
    try {
      final loaded = await PlatformChannels.loadSTTModel(modelPath);
      if (!loaded) {
        throw Exception('Failed to load STT model');
      }
      _isInitialized = true;
    } catch (e) {
      throw Exception('STT initialization failed: $e');
    }
  }

  /// Transcribe audio data to text
  /// 
  /// [audioData] should be PCM 16-bit mono audio at 16kHz sample rate
  Future<String> transcribe(List<int> audioData) async {
    if (!_isInitialized) {
      throw Exception('STT service not initialized');
    }

    try {
      // Convert to Uint8List for platform channel
      final audioBytes = Uint8List.fromList(audioData);
      
      // Call native transcription
      final transcript = await PlatformChannels.transcribe(audioBytes);
      
      // Clean up transcript
      return _cleanTranscript(transcript);
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  /// Clean and normalize transcript text
  String _cleanTranscript(String text) {
    if (text.isEmpty) return text;
    
    // Trim whitespace
    text = text.trim();
    
    // Capitalize first letter
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }
    
    // Add period if missing
    if (text.isNotEmpty && !text.endsWith('.') && !text.endsWith('?') && !text.endsWith('!')) {
      text += '.';
    }
    
    return text;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}