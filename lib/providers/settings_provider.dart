import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for app settings
class SettingsProvider with ChangeNotifier {
  // Voice settings
  String _assistantVoice = 'female';
  String _wakeWord = 'Hey Nova';
  bool _wakeWordEnabled = false;
  
  // Model settings
  String _llmModel = 'LFM-2 1B';
  double _temperature = 0.7;
  int _maxTokens = 256;
  
  // App settings
  bool _offlineMode = true;
  bool _autoReminders = false;
  bool _soundEffects = true;
  double _speechSpeed = 1.0;
  
  // UI settings
  bool _showTranscription = true;
  bool _showWaveform = true;
  String _theme = 'dark';

  // Storage keys
  static const String _voiceKey = 'assistant_voice';
  static const String _wakeWordKey = 'wake_word';
  static const String _wakeWordEnabledKey = 'wake_word_enabled';
  static const String _llmModelKey = 'llm_model';
  static const String _temperatureKey = 'temperature';
  static const String _maxTokensKey = 'max_tokens';
  static const String _offlineModeKey = 'offline_mode';
  static const String _autoRemindersKey = 'auto_reminders';
  static const String _soundEffectsKey = 'sound_effects';
  static const String _speechSpeedKey = 'speech_speed';
  static const String _showTranscriptionKey = 'show_transcription';
  static const String _showWaveformKey = 'show_waveform';
  static const String _themeKey = 'theme';

  SettingsProvider() {
    _loadSettings();
  }

  // Getters
  String get assistantVoice => _assistantVoice;
  String get wakeWord => _wakeWord;
  bool get wakeWordEnabled => _wakeWordEnabled;
  String get llmModel => _llmModel;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  bool get offlineMode => _offlineMode;
  bool get autoReminders => _autoReminders;
  bool get soundEffects => _soundEffects;
  double get speechSpeed => _speechSpeed;
  bool get showTranscription => _showTranscription;
  bool get showWaveform => _showWaveform;
  String get theme => _theme;

  // Setters with persistence
  Future<void> setAssistantVoice(String voice) async {
    _assistantVoice = voice;
    await _saveString(_voiceKey, voice);
    notifyListeners();
  }

  Future<void> setWakeWord(String word) async {
    _wakeWord = word;
    await _saveString(_wakeWordKey, word);
    notifyListeners();
  }

  Future<void> setWakeWordEnabled(bool enabled) async {
    _wakeWordEnabled = enabled;
    await _saveBool(_wakeWordEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setLLMModel(String model) async {
    _llmModel = model;
    await _saveString(_llmModelKey, model);
    notifyListeners();
  }

  Future<void> setTemperature(double temp) async {
    _temperature = temp.clamp(0.0, 2.0);
    await _saveDouble(_temperatureKey, _temperature);
    notifyListeners();
  }

  Future<void> setMaxTokens(int tokens) async {
    _maxTokens = tokens.clamp(64, 1024);
    await _saveInt(_maxTokensKey, _maxTokens);
    notifyListeners();
  }

  Future<void> setOfflineMode(bool enabled) async {
    _offlineMode = enabled;
    await _saveBool(_offlineModeKey, enabled);
    notifyListeners();
  }

  Future<void> setAutoReminders(bool enabled) async {
    _autoReminders = enabled;
    await _saveBool(_autoRemindersKey, enabled);
    notifyListeners();
  }

  Future<void> setSoundEffects(bool enabled) async {
    _soundEffects = enabled;
    await _saveBool(_soundEffectsKey, enabled);
    notifyListeners();
  }

  Future<void> setSpeechSpeed(double speed) async {
    _speechSpeed = speed.clamp(0.5, 2.0);
    await _saveDouble(_speechSpeedKey, _speechSpeed);
    notifyListeners();
  }

  Future<void> setShowTranscription(bool show) async {
    _showTranscription = show;
    await _saveBool(_showTranscriptionKey, show);
    notifyListeners();
  }

  Future<void> setShowWaveform(bool show) async {
    _showWaveform = show;
    await _saveBool(_showWaveformKey, show);
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _theme = theme;
    await _saveString(_themeKey, theme);
    notifyListeners();
  }

  /// Load all settings from persistent storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _assistantVoice = prefs.getString(_voiceKey) ?? 'female';
      _wakeWord = prefs.getString(_wakeWordKey) ?? 'Hey Nova';
      _wakeWordEnabled = prefs.getBool(_wakeWordEnabledKey) ?? false;
      _llmModel = prefs.getString(_llmModelKey) ?? 'LFM-2 1B';
      _temperature = prefs.getDouble(_temperatureKey) ?? 0.7;
      _maxTokens = prefs.getInt(_maxTokensKey) ?? 256;
      _offlineMode = prefs.getBool(_offlineModeKey) ?? true;
      _autoReminders = prefs.getBool(_autoRemindersKey) ?? false;
      _soundEffects = prefs.getBool(_soundEffectsKey) ?? true;
      _speechSpeed = prefs.getDouble(_speechSpeedKey) ?? 1.0;
      _showTranscription = prefs.getBool(_showTranscriptionKey) ?? true;
      _showWaveform = prefs.getBool(_showWaveformKey) ?? true;
      _theme = prefs.getString(_themeKey) ?? 'dark';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _assistantVoice = 'female';
    _wakeWord = 'Hey Nova';
    _wakeWordEnabled = false;
    _llmModel = 'LFM-2 1B';
    _temperature = 0.7;
    _maxTokens = 256;
    _offlineMode = true;
    _autoReminders = false;
    _soundEffects = true;
    _speechSpeed = 1.0;
    _showTranscription = true;
    _showWaveform = true;
    _theme = 'dark';

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  // Helper methods for saving
  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }
}