import 'dart:typed_data';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Service for playing synthesized audio
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  /// Play audio from PCM bytes
  Future<void> playAudio(Uint8List pcmData) async {
    if (pcmData.isEmpty) return;

    try {
      // Convert PCM to WAV file for playback
      final wavData = _pcmToWav(pcmData);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(wavData);

      // Set audio source
      await _player.setFilePath(tempFile.path);

      // Play audio
      _isPlaying = true;
      await _player.play();

      // Wait for completion
      await _player.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );

      _isPlaying = false;

      // Clean up temporary file
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    } catch (e) {
      _isPlaying = false;
      throw Exception('Audio playback failed: $e');
    }
  }

  /// Play audio from file path
  Future<void> playFromFile(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      _isPlaying = true;
      await _player.play();
      await _player.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
      _isPlaying = false;
    } catch (e) {
      _isPlaying = false;
      throw Exception('Audio playback failed: $e');
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
    }
  }

  /// Pause current playback
  Future<void> pause() async {
    if (_isPlaying) {
      await _player.pause();
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (!_isPlaying && _player.playing) {
      await _player.play();
      _isPlaying = true;
    }
  }

  /// Convert PCM data to WAV format
  /// PCM: 16-bit, 16kHz, mono
  Uint8List _pcmToWav(Uint8List pcmData) {
    const int sampleRate = 16000;
    const int numChannels = 1;
    const int bitsPerSample = 16;

    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    final buffer = BytesBuilder();

    // RIFF header
    buffer.add('RIFF'.codeUnits);
    buffer.add(_int32ToBytes(fileSize));
    buffer.add('WAVE'.codeUnits);

    // fmt chunk
    buffer.add('fmt '.codeUnits);
    buffer.add(_int32ToBytes(16)); // Chunk size
    buffer.add(_int16ToBytes(1)); // Audio format (PCM)
    buffer.add(_int16ToBytes(numChannels));
    buffer.add(_int32ToBytes(sampleRate));
    buffer.add(_int32ToBytes(sampleRate * numChannels * bitsPerSample ~/ 8)); // Byte rate
    buffer.add(_int16ToBytes(numChannels * bitsPerSample ~/ 8)); // Block align
    buffer.add(_int16ToBytes(bitsPerSample));

    // data chunk
    buffer.add('data'.codeUnits);
    buffer.add(_int32ToBytes(dataSize));
    buffer.add(pcmData);

    return buffer.toBytes();
  }

  /// Convert 32-bit integer to little-endian bytes
  Uint8List _int32ToBytes(int value) {
    return Uint8List(4)
      ..[0] = value & 0xFF
      ..[1] = (value >> 8) & 0xFF
      ..[2] = (value >> 16) & 0xFF
      ..[3] = (value >> 24) & 0xFF;
  }

  /// Convert 16-bit integer to little-endian bytes
  Uint8List _int16ToBytes(int value) {
    return Uint8List(2)
      ..[0] = value & 0xFF
      ..[1] = (value >> 8) & 0xFF;
  }

  /// Get current playback position
  Duration get position => _player.position;

  /// Get total duration
  Duration? get duration => _player.duration;

  /// Check if currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}