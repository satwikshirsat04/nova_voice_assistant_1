import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for loading and managing AI models
class ModelLoaderService {
  bool _sttLoaded = false;
  bool _llmLoaded = false;
  bool _ttsLoaded = false;

  // Model paths in assets
  static const String STT_MODEL_PATH = 'assets/models/parakeet/encoder.onnx';
  static const String LLM_MODEL_PATH = 'assets/models/lfm2/model.gguf';
  static const String TTS_MODEL_PATH = 'assets/models/kokoro/model.onnx';

  /// Load STT model (Parakeet)
  Future<String> loadSTTModel() async {
    if (_sttLoaded) {
      return await _getModelPath('parakeet');
    }

    try {
      final modelPath = await _copyAssetToFile(
        STT_MODEL_PATH,
        'parakeet',
        'encoder.onnx',
      );

      _sttLoaded = true;
      return modelPath;
    } catch (e) {
      throw Exception('Failed to load STT model: $e');
    }
  }

  /// Load LLM model (LFM-2)
  Future<String> loadLLMModel() async {
    if (_llmLoaded) {
      return await _getModelPath('lfm2');
    }

    try {
      final modelPath = await _copyAssetToFile(
        LLM_MODEL_PATH,
        'lfm2',
        'model.gguf',
      );

      _llmLoaded = true;
      return modelPath;
    } catch (e) {
      throw Exception('Failed to load LLM model: $e');
    }
  }

  /// Load TTS model (Kokoro)
  Future<String> loadTTSModel() async {
    if (_ttsLoaded) {
      return await _getModelPath('kokoro');
    }

    try {
      final modelPath = await _copyAssetToFile(
        TTS_MODEL_PATH,
        'kokoro',
        'model.onnx',
      );

      _ttsLoaded = true;
      return modelPath;
    } catch (e) {
      throw Exception('Failed to load TTS model: $e');
    }
  }

  /// Copy asset file to app's document directory
  Future<String> _copyAssetToFile(
    String assetPath,
    String modelDir,
    String fileName,
  ) async {
    try {
      // Get app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelDirectory = Directory('${appDir.path}/models/$modelDir');

      // Create directory if it doesn't exist
      if (!await modelDirectory.exists()) {
        await modelDirectory.create(recursive: true);
      }

      final targetFile = File('${modelDirectory.path}/$fileName');

      // Check if file already exists
      if (await targetFile.exists()) {
        return targetFile.path;
      }

      // Load asset data
      final byteData = await rootBundle.load(assetPath);

      // Write to file
      await targetFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );

      return targetFile.path;
    } catch (e) {
      throw Exception('Failed to copy model file: $e');
    }
  }

  /// Get existing model path
  Future<String> _getModelPath(String modelDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/$modelDir';
  }

  /// Check if model files exist
  Future<bool> checkModelsExist() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');

      if (!await modelsDir.exists()) {
        return false;
      }

      // Check for essential model files
      final sttExists = await File('${modelsDir.path}/parakeet/encoder.onnx').exists();
      final llmExists = await File('${modelsDir.path}/lfm2/model.gguf').exists();
      final ttsExists = await File('${modelsDir.path}/kokoro/model.onnx').exists();

      return sttExists && llmExists && ttsExists;
    } catch (e) {
      return false;
    }
  }

  /// Get total size of model files
  Future<int> getModelsSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');

      if (!await modelsDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in modelsDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Delete all downloaded models
  Future<void> clearModels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');

      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
      }

      _sttLoaded = false;
      _llmLoaded = false;
      _ttsLoaded = false;
    } catch (e) {
      throw Exception('Failed to clear models: $e');
    }
  }

  /// Get model loading status
  Map<String, bool> get modelStatus => {
    'stt': _sttLoaded,
    'llm': _llmLoaded,
    'tts': _ttsLoaded,
  };

  /// Check if all models are loaded
  bool get allModelsLoaded => _sttLoaded && _llmLoaded && _ttsLoaded;
}