import 'package:flutter/foundation.dart';
import '../services/stt_service.dart';
import '../services/llm_service.dart';
import '../services/tts_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../services/model_loader_service.dart';
import '../models/chat_message.dart';

enum VoiceAgentState {
  idle,
  listening,
  transcribing,
  thinking,
  speaking,
  error,
}

class VoiceAgentProvider with ChangeNotifier {
  final ModelLoaderService _modelLoader;
  late final STTService _sttService;
  late final LLMService _llmService;
  late final TTSService _ttsService;
  late final AudioRecorderService _audioRecorder;
  late final AudioPlayerService _audioPlayer;

  VoiceAgentState _state = VoiceAgentState.idle;
  String _transcribedText = '';
  String _generatedResponse = '';
  String _errorMessage = '';
  bool _modelsLoaded = false;
  double _loadingProgress = 0.0;

  VoiceAgentProvider(this._modelLoader) {
    _sttService = STTService();
    _llmService = LLMService();
    _ttsService = TTSService();
    _audioRecorder = AudioRecorderService();
    _audioPlayer = AudioPlayerService();
  }

  // Getters
  VoiceAgentState get state => _state;
  String get transcribedText => _transcribedText;
  String get generatedResponse => _generatedResponse;
  String get errorMessage => _errorMessage;
  bool get modelsLoaded => _modelsLoaded;
  double get loadingProgress => _loadingProgress;
  bool get isProcessing => _state != VoiceAgentState.idle && _state != VoiceAgentState.error;

  // Initialize and load models
  Future<void> initializeModels() async {
    try {
      _updateState(VoiceAgentState.idle);
      _loadingProgress = 0.0;
      notifyListeners();

      // Load STT Model (Parakeet)
      _loadingProgress = 0.1;
      notifyListeners();
      await _modelLoader.loadSTTModel();
      
      _loadingProgress = 0.4;
      notifyListeners();
      
      // Load LLM Model (LFM-2)
      await _modelLoader.loadLLMModel();
      
      _loadingProgress = 0.7;
      notifyListeners();
      
      // Load TTS Model (Kokoro)
      await _modelLoader.loadTTSModel();
      
      _loadingProgress = 1.0;
      _modelsLoaded = true;
      notifyListeners();
      
      debugPrint('All models loaded successfully');
    } catch (e) {
      _errorMessage = 'Failed to load models: $e';
      _updateState(VoiceAgentState.error);
      debugPrint('Model loading error: $e');
    }
  }

  // Main voice interaction pipeline
  Future<ChatMessage?> processVoiceInput(List<int> audioData) async {
    if (!_modelsLoaded) {
      _errorMessage = 'Models not loaded';
      _updateState(VoiceAgentState.error);
      return null;
    }

    try {
      // Step 1: Transcribe audio to text
      _updateState(VoiceAgentState.transcribing);
      _transcribedText = await _sttService.transcribe(audioData);
      
      if (_transcribedText.isEmpty) {
        _errorMessage = 'No speech detected';
        _updateState(VoiceAgentState.error);
        return null;
      }
      
      debugPrint('Transcribed: $_transcribedText');

      // Step 2: Generate LLM response
      _updateState(VoiceAgentState.thinking);
      _generatedResponse = await _llmService.generate(_transcribedText);
      
      if (_generatedResponse.isEmpty) {
        _errorMessage = 'Failed to generate response';
        _updateState(VoiceAgentState.error);
        return null;
      }
      
      debugPrint('LLM Response: $_generatedResponse');

      // Step 3: Convert response to speech
      _updateState(VoiceAgentState.speaking);
      final audioResponse = await _ttsService.synthesize(_generatedResponse);
      
      // Step 4: Play audio response
      await _audioPlayer.playAudio(audioResponse);
      
      _updateState(VoiceAgentState.idle);
      
      // Return chat message for history
      return ChatMessage(
        userMessage: _transcribedText,
        assistantMessage: _generatedResponse,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      _errorMessage = 'Processing error: $e';
      _updateState(VoiceAgentState.error);
      debugPrint('Voice processing error: $e');
      return null;
    }
  }

  // Start recording
  Future<void> startListening() async {
    if (_state != VoiceAgentState.idle) return;
    
    try {
      _updateState(VoiceAgentState.listening);
      await _audioRecorder.startRecording();
    } catch (e) {
      _errorMessage = 'Failed to start recording: $e';
      _updateState(VoiceAgentState.error);
    }
  }

  // Stop recording and process
  Future<ChatMessage?> stopListening() async {
    if (_state != VoiceAgentState.listening) return null;
    
    try {
      final audioData = await _audioRecorder.stopRecording();
      
      if (audioData == null || audioData.isEmpty) {
        _updateState(VoiceAgentState.idle);
        return null;
      }
      
      return await processVoiceInput(audioData);
    } catch (e) {
      _errorMessage = 'Failed to stop recording: $e';
      _updateState(VoiceAgentState.error);
      return null;
    }
  }

  // Cancel current operation
  void cancelOperation() {
    _audioRecorder.cancelRecording();
    _audioPlayer.stop();
    _updateState(VoiceAgentState.idle);
  }

  // Get audio level for waveform visualization
  Stream<double> getAudioLevel() {
    return _audioRecorder.audioLevelStream;
  }

  void _updateState(VoiceAgentState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}