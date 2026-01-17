import '../utils/platform_channels.dart';

/// Service for text generation using LFM-2 LLM
class LLMService {
  bool _isInitialized = false;
  final List<Map<String, String>> _conversationHistory = [];
  
  static const int MAX_HISTORY = 10;
  static const String SYSTEM_PROMPT = '''You are Nova, a helpful AI voice assistant. 
You provide concise, friendly, and accurate responses. 
Keep your answers brief and conversational, suitable for voice interaction.
Avoid long explanations unless specifically asked.''';

  /// Initialize the LLM model
  Future<void> initialize(
    String modelPath, {
    int contextSize = 2048,
    int threads = 4,
  }) async {
    if (_isInitialized) return;
    
    try {
      final loaded = await PlatformChannels.loadLLMModel(
        modelPath,
        contextSize: contextSize,
        threads: threads,
      );
      
      if (!loaded) {
        throw Exception('Failed to load LLM model');
      }
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('LLM initialization failed: $e');
    }
  }

  /// Generate response from user input
  Future<String> generate(
    String userInput, {
    int maxTokens = 256,
    double temperature = 0.7,
    double topP = 0.9,
  }) async {
    if (!_isInitialized) {
      throw Exception('LLM service not initialized');
    }

    try {
      // Add user input to history
      _conversationHistory.add({
        'role': 'user',
        'content': userInput,
      });
      
      // Trim history if too long
      if (_conversationHistory.length > MAX_HISTORY * 2) {
        _conversationHistory.removeRange(0, _conversationHistory.length - MAX_HISTORY * 2);
      }
      
      // Build prompt with conversation context
      final prompt = _buildPrompt();
      
      // Generate response
      final response = await PlatformChannels.generate(
        prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
      );
      
      // Clean up response
      final cleanedResponse = _cleanResponse(response);
      
      // Add assistant response to history
      _conversationHistory.add({
        'role': 'assistant',
        'content': cleanedResponse,
      });
      
      return cleanedResponse;
    } catch (e) {
      throw Exception('Text generation failed: $e');
    }
  }

  /// Generate streaming response (token by token)
  Stream<String> generateStream(
    String userInput, {
    int maxTokens = 256,
    double temperature = 0.7,
  }) {
    if (!_isInitialized) {
      throw Exception('LLM service not initialized');
    }
    
    // Add user input to history
    _conversationHistory.add({
      'role': 'user',
      'content': userInput,
    });
    
    final prompt = _buildPrompt();
    
    return PlatformChannels.generateStream(
      prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  /// Build prompt with system message and conversation history
  String _buildPrompt() {
    final buffer = StringBuffer();
    
    // Add system prompt
    buffer.writeln('<|system|>');
    buffer.writeln(SYSTEM_PROMPT);
    buffer.writeln('<|end|>');
    
    // Add conversation history
    for (final message in _conversationHistory) {
      final role = message['role'];
      final content = message['content'];
      
      if (role == 'user') {
        buffer.writeln('<|user|>');
        buffer.writeln(content);
        buffer.writeln('<|end|>');
      } else if (role == 'assistant') {
        buffer.writeln('<|assistant|>');
        buffer.writeln(content);
        buffer.writeln('<|end|>');
      }
    }
    
    // Add final assistant prompt
    buffer.write('<|assistant|>');
    
    return buffer.toString();
  }

  /// Clean up generated response
  String _cleanResponse(String response) {
    // Remove special tokens
    response = response
        .replaceAll('<|end|>', '')
        .replaceAll('<|system|>', '')
        .replaceAll('<|user|>', '')
        .replaceAll('<|assistant|>', '');
    
    // Trim whitespace
    response = response.trim();
    
    // Remove incomplete sentences at the end
    if (response.isNotEmpty && !_endsWithPunctuation(response)) {
      final lastPunctuation = _findLastPunctuation(response);
      if (lastPunctuation > 0) {
        response = response.substring(0, lastPunctuation + 1);
      }
    }
    
    return response;
  }

  /// Check if text ends with punctuation
  bool _endsWithPunctuation(String text) {
    if (text.isEmpty) return false;
    final lastChar = text[text.length - 1];
    return lastChar == '.' || lastChar == '!' || lastChar == '?';
  }

  /// Find index of last punctuation
  int _findLastPunctuation(String text) {
    for (int i = text.length - 1; i >= 0; i--) {
      if (text[i] == '.' || text[i] == '!' || text[i] == '?') {
        return i;
      }
    }
    return -1;
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get conversation history
  List<Map<String, String>> get history => List.unmodifiable(_conversationHistory);
}