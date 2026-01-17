import 'package:flutter/services.dart';
import 'dart:typed_data';

/// Platform channels for native model inference
class PlatformChannels {
  // Method channels for different services
  static const MethodChannel _sttChannel = MethodChannel('nova/stt');
  static const MethodChannel _llmChannel = MethodChannel('nova/llm');
  static const MethodChannel _ttsChannel = MethodChannel('nova/tts');
  static const MethodChannel _modelChannel = MethodChannel('nova/model');
  
  // STT Methods
  static Future<bool> loadSTTModel(String modelPath) async {
    try {
      final result = await _sttChannel.invokeMethod<bool>(
        'loadModel',
        {'modelPath': modelPath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to load STT model: ${e.message}');
    }
  }
  
  static Future<String> transcribe(Uint8List audioData) async {
    try {
      final result = await _sttChannel.invokeMethod<String>(
        'transcribe',
        {'audioData': audioData},
      );
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Transcription failed: ${e.message}');
    }
  }
  
  // LLM Methods
  static Future<bool> loadLLMModel(String modelPath, {
    int? contextSize,
    int? threads,
  }) async {
    try {
      final result = await _llmChannel.invokeMethod<bool>(
        'loadModel',
        {
          'modelPath': modelPath,
          'contextSize': contextSize ?? 2048,
          'threads': threads ?? 4,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to load LLM model: ${e.message}');
    }
  }
  
  static Future<String> generate(
    String prompt, {
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async {
    try {
      final result = await _llmChannel.invokeMethod<String>(
        'generate',
        {
          'prompt': prompt,
          'maxTokens': maxTokens ?? 256,
          'temperature': temperature ?? 0.7,
          'topP': topP ?? 0.9,
        },
      );
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Text generation failed: ${e.message}');
    }
  }
  
  static Stream<String> generateStream(
    String prompt, {
    int? maxTokens,
    double? temperature,
  }) {
    final eventChannel = const EventChannel('nova/llm_stream');
    
    return eventChannel.receiveBroadcastStream({
      'prompt': prompt,
      'maxTokens': maxTokens ?? 256,
      'temperature': temperature ?? 0.7,
    }).map((event) => event.toString());
  }
  
  // TTS Methods
  static Future<bool> loadTTSModel(String modelPath) async {
    try {
      final result = await _ttsChannel.invokeMethod<bool>(
        'loadModel',
        {'modelPath': modelPath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to load TTS model: ${e.message}');
    }
  }
  
  static Future<Uint8List> synthesize(
    String text, {
    double? speed,
    String? voice,
  }) async {
    try {
      final result = await _ttsChannel.invokeMethod<Uint8List>(
        'synthesize',
        {
          'text': text,
          'speed': speed ?? 1.0,
          'voice': voice ?? 'female',
        },
      );
      return result ?? Uint8List(0);
    } on PlatformException catch (e) {
      throw Exception('Speech synthesis failed: ${e.message}');
    }
  }
  
  static Stream<Uint8List> synthesizeStream(String text) {
    final eventChannel = const EventChannel('nova/tts_stream');
    
    return eventChannel.receiveBroadcastStream({
      'text': text,
    }).map((event) => event as Uint8List);
  }
  
  // Model Management
  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final result = await _modelChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getModelInfo',
      );
      return result?.cast<String, dynamic>() ?? {};
    } on PlatformException catch (e) {
      throw Exception('Failed to get model info: ${e.message}');
    }
  }
  
  static Future<void> unloadAllModels() async {
    try {
      await _modelChannel.invokeMethod('unloadAll');
    } on PlatformException catch (e) {
      throw Exception('Failed to unload models: ${e.message}');
    }
  }
  
  static Future<bool> isModelLoaded(String modelType) async {
    try {
      final result = await _modelChannel.invokeMethod<bool>(
        'isLoaded',
        {'modelType': modelType},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to check model status: ${e.message}');
    }
  }
}