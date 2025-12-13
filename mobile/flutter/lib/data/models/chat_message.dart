import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

/// Chat message model
@JsonSerializable()
class ChatMessage extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? intent;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const ChatMessage({
    this.id,
    this.userId,
    required this.role,
    required this.content,
    this.intent,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// Check if message is from user
  bool get isUser => role == 'user';

  /// Check if message is from assistant
  bool get isAssistant => role == 'assistant';

  /// Get timestamp as DateTime
  DateTime? get timestamp {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, userId, role, content, createdAt];
}

/// Chat request model
@JsonSerializable()
class ChatRequest {
  final String message;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'user_profile')
  final Map<String, dynamic>? userProfile;
  @JsonKey(name: 'current_workout')
  final Map<String, dynamic>? currentWorkout;
  @JsonKey(name: 'workout_schedule')
  final Map<String, dynamic>? workoutSchedule;
  @JsonKey(name: 'conversation_history')
  final List<Map<String, dynamic>>? conversationHistory;

  const ChatRequest({
    required this.message,
    required this.userId,
    this.userProfile,
    this.currentWorkout,
    this.workoutSchedule,
    this.conversationHistory,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}

/// Chat response model
@JsonSerializable()
class ChatResponse {
  final String message;
  final String? intent;
  @JsonKey(name: 'action_data')
  final Map<String, dynamic>? actionData;
  @JsonKey(name: 'rag_context_used')
  final bool? ragContextUsed;
  @JsonKey(name: 'similar_questions')
  final List<String>? similarQuestions;

  const ChatResponse({
    required this.message,
    this.intent,
    this.actionData,
    this.ragContextUsed,
    this.similarQuestions,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
}

/// Chat history item
@JsonSerializable()
class ChatHistoryItem {
  final String? id;  // UUID string from backend
  final String role;
  final String content;
  final String? timestamp;
  @JsonKey(name: 'action_data')
  final Map<String, dynamic>? actionData;

  const ChatHistoryItem({
    this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.actionData,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$ChatHistoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$ChatHistoryItemToJson(this);

  /// Convert to ChatMessage
  ChatMessage toChatMessage() => ChatMessage(
        id: id,
        role: role,
        content: content,
        createdAt: timestamp,
      );
}
