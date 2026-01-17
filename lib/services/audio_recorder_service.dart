import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service for recording audio from microphone
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _audioLevelController = StreamController<double>.broadcast();
  
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _levelTimer;

  // Audio configuration for Parakeet STT
  static const int SAMPLE_RATE = 16000;
  static const int CHANNELS = 1; // Mono
  static const int BIT_DEPTH = 16;

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      // Check and request permission
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: SAMPLE_RATE,
        numChannels: CHANNELS,
        bitRate: 128000,
      );

      // Start recording
      await _recorder.start(
        config,
        path: _currentRecordingPath!,
      );

      _isRecording = true;

      // Start monitoring audio levels
      _startAudioLevelMonitoring();
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stop recording and return audio data
  Future<List<int>?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      // Stop recording
      final path = await _recorder.stop();
      _isRecording = false;

      // Stop level monitoring
      _stopAudioLevelMonitoring();

      if (path == null || !File(path).existsSync()) {
        return null;
      }

      // Read recorded audio file
      final audioFile = File(path);
      final audioBytes = await audioFile.readAsBytes();

      // Clean up temporary file
      await audioFile.delete();
      _currentRecordingPath = null;

      // Extract PCM data from WAV file (skip header)
      return _extractPCMFromWav(audioBytes);
    } catch (e) {
      _isRecording = false;
      _stopAudioLevelMonitoring();
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Cancel recording without returning data
  void cancelRecording() {
    if (!_isRecording) return;

    _recorder.stop();
    _isRecording = false;
    _stopAudioLevelMonitoring();

    // Clean up file
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _currentRecordingPath = null;
    }
  }

  /// Extract PCM data from WAV file
  /// WAV header is typically 44 bytes
  List<int> _extractPCMFromWav(List<int> wavBytes) {
    if (wavBytes.length <= 44) {
      return [];
    }

    // Skip WAV header (first 44 bytes)
    return wavBytes.sublist(44);
  }

  /// Start monitoring audio levels for visualization
  void _startAudioLevelMonitoring() {
    _levelTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        final normalizedLevel = _normalizeAmplitude(amplitude.current);
        _audioLevelController.add(normalizedLevel);
      } catch (e) {
        // Ignore errors during level monitoring
      }
    });
  }

  /// Stop monitoring audio levels
  void _stopAudioLevelMonitoring() {
    _levelTimer?.cancel();
    _levelTimer = null;
    _audioLevelController.add(0.0);
  }

  /// Normalize amplitude to 0.0 - 1.0 range
  double _normalizeAmplitude(double amplitude) {
    // Amplitude is typically in dB (-160 to 0)
    // Normalize to 0.0 - 1.0 for visualization
    const minDb = -60.0;
    const maxDb = 0.0;
    
    final clamped = amplitude.clamp(minDb, maxDb);
    return (clamped - minDb) / (maxDb - minDb);
  }

  /// Stream of audio levels for waveform visualization
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _levelTimer?.cancel();
    _audioLevelController.close();
  }
}