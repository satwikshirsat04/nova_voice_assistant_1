/// Model representing a single chat exchange
class ChatMessage {
  final String userMessage;
  final String assistantMessage;
  final DateTime timestamp;
  final String? audioPath; // Optional: path to recorded audio
  final Duration? duration; // Optional: response duration

  ChatMessage({
    required this.userMessage,
    required this.assistantMessage,
    required this.timestamp,
    this.audioPath,
    this.duration,
  });

  /// Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userMessage: json['userMessage'] as String,
      assistantMessage: json['assistantMessage'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      audioPath: json['audioPath'] as String?,
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'] as int)
          : null,
    );
  }

  /// Convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'userMessage': userMessage,
      'assistantMessage': assistantMessage,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
      'duration': duration?.inMilliseconds,
    };
  }

  /// Create a copy with modified fields
  ChatMessage copyWith({
    String? userMessage,
    String? assistantMessage,
    DateTime? timestamp,
    String? audioPath,
    Duration? duration,
  }) {
    return ChatMessage(
      userMessage: userMessage ?? this.userMessage,
      assistantMessage: assistantMessage ?? this.assistantMessage,
      timestamp: timestamp ?? this.timestamp,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(user: $userMessage, assistant: $assistantMessage, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.userMessage == userMessage &&
        other.assistantMessage == assistantMessage &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return userMessage.hashCode ^ 
           assistantMessage.hashCode ^ 
           timestamp.hashCode;
  }
}