import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Provider for managing chat messages and history
class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  static const String STORAGE_KEY = 'chat_history';
  static const int MAX_MESSAGES = 100;

  ChatProvider() {
    _loadHistory();
  }

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get hasMessages => _messages.isNotEmpty;
  int get messageCount => _messages.length;

  /// Add a new chat message
  void addMessage(ChatMessage message) {
    _messages.add(message);
    
    // Trim history if it gets too long
    if (_messages.length > MAX_MESSAGES) {
      _messages.removeRange(0, _messages.length - MAX_MESSAGES);
    }
    
    _saveHistory();
    notifyListeners();
  }

  /// Add user message only (while waiting for assistant response)
  void addUserMessage(String text) {
    // This is a temporary message that will be updated when we get the response
    // For now, we'll just add it directly in addMessage when we have the full exchange
  }

  /// Update the last message
  void updateLastMessage(String userText, String assistantText) {
    if (_messages.isNotEmpty) {
      _messages.removeLast();
    }
    
    addMessage(ChatMessage(
      userMessage: userText,
      assistantMessage: assistantText,
      timestamp: DateTime.now(),
    ));
  }

  /// Clear all messages
  void clearHistory() {
    _messages.clear();
    _saveHistory();
    notifyListeners();
  }

  /// Delete a specific message
  void deleteMessage(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      _saveHistory();
      notifyListeners();
    }
  }

  /// Search messages
  List<ChatMessage> searchMessages(String query) {
    if (query.isEmpty) return _messages;
    
    final lowerQuery = query.toLowerCase();
    return _messages.where((message) {
      return message.userMessage.toLowerCase().contains(lowerQuery) ||
             message.assistantMessage.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get messages from a specific date
  List<ChatMessage> getMessagesByDate(DateTime date) {
    return _messages.where((message) {
      return message.timestamp.year == date.year &&
             message.timestamp.month == date.month &&
             message.timestamp.day == date.day;
    }).toList();
  }

  /// Load chat history from persistent storage
  Future<void> _loadHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(STORAGE_KEY);

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _messages.clear();
        _messages.addAll(
          decoded.map((item) => ChatMessage.fromJson(item)).toList(),
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Failed to load chat history: $e');
      notifyListeners();
    }
  }

  /// Save chat history to persistent storage
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(
        _messages.map((message) => message.toJson()).toList(),
      );
      await prefs.setString(STORAGE_KEY, historyJson);
    } catch (e) {
      debugPrint('Failed to save chat history: $e');
    }
  }

  /// Export chat history as text
  String exportAsText() {
    final buffer = StringBuffer();
    buffer.writeln('Nova Voice Assistant - Chat History');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      buffer.writeln('Conversation ${i + 1} - ${message.timestamp}');
      buffer.writeln();
      buffer.writeln('You: ${message.userMessage}');
      buffer.writeln();
      buffer.writeln('Nova: ${message.assistantMessage}');
      buffer.writeln();
      buffer.writeln('-' * 50);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get statistics about the chat
  Map<String, dynamic> getStatistics() {
    if (_messages.isEmpty) {
      return {
        'totalMessages': 0,
        'averageUserMessageLength': 0,
        'averageAssistantMessageLength': 0,
        'oldestMessage': null,
        'newestMessage': null,
      };
    }

    final userLengths = _messages.map((m) => m.userMessage.length).toList();
    final assistantLengths = _messages.map((m) => m.assistantMessage.length).toList();

    return {
      'totalMessages': _messages.length,
      'averageUserMessageLength': userLengths.reduce((a, b) => a + b) / userLengths.length,
      'averageAssistantMessageLength': assistantLengths.reduce((a, b) => a + b) / assistantLengths.length,
      'oldestMessage': _messages.first.timestamp,
      'newestMessage': _messages.last.timestamp,
    };
  }
}