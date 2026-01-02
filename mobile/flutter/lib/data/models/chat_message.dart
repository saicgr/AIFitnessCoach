import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

/// Agent types for specialized AI responses
enum AgentType {
  @JsonValue('coach')
  coach,
  @JsonValue('nutrition')
  nutrition,
  @JsonValue('workout')
  workout,
  @JsonValue('injury')
  injury,
  @JsonValue('hydration')
  hydration,
}

/// Agent configuration with colors and icons
class AgentConfig {
  final String name;
  final String displayName;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColorDark;
  final Color backgroundColorLight;

  const AgentConfig({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColorDark,
    required this.backgroundColorLight,
  });

  /// Get background color based on brightness
  Color getBackgroundColor(Brightness brightness) {
    return brightness == Brightness.dark ? backgroundColorDark : backgroundColorLight;
  }

  /// Legacy getter for backwards compatibility (returns dark mode color)
  Color get backgroundColor => backgroundColorDark;

  /// Get agent config by type
  static AgentConfig forType(AgentType type) {
    switch (type) {
      case AgentType.coach:
        return const AgentConfig(
          name: 'coach',
          displayName: 'AI Coach',
          icon: Icons.smart_toy,
          primaryColor: Color(0xFF00D9FF), // Cyan
          backgroundColorDark: Color(0xFF1A3A4A),
          backgroundColorLight: Color(0xFFE0F7FA), // Light cyan tint
        );
      case AgentType.nutrition:
        return const AgentConfig(
          name: 'nutrition',
          displayName: 'Nutrition Expert',
          icon: Icons.restaurant_menu,
          primaryColor: Color(0xFF4CAF50), // Green
          backgroundColorDark: Color(0xFF1A3A2A),
          backgroundColorLight: Color(0xFFE8F5E9), // Light green tint
        );
      case AgentType.workout:
        return const AgentConfig(
          name: 'workout',
          displayName: 'Workout Specialist',
          icon: Icons.fitness_center,
          primaryColor: Color(0xFFFF6B35), // Orange
          backgroundColorDark: Color(0xFF3A2A1A),
          backgroundColorLight: Color(0xFFFFF3E0), // Light orange tint
        );
      case AgentType.injury:
        return const AgentConfig(
          name: 'injury',
          displayName: 'Recovery Advisor',
          icon: Icons.healing,
          primaryColor: Color(0xFFE91E63), // Pink
          backgroundColorDark: Color(0xFF3A1A2A),
          backgroundColorLight: Color(0xFFFCE4EC), // Light pink tint
        );
      case AgentType.hydration:
        return const AgentConfig(
          name: 'hydration',
          displayName: 'Hydration Tracker',
          icon: Icons.water_drop,
          primaryColor: Color(0xFF2196F3), // Blue
          backgroundColorDark: Color(0xFF1A2A3A),
          backgroundColorLight: Color(0xFFE3F2FD), // Light blue tint
        );
    }
  }

  /// Get all available agents
  static List<AgentConfig> get allAgents => [
    forType(AgentType.coach),
    forType(AgentType.nutrition),
    forType(AgentType.workout),
    forType(AgentType.injury),
    forType(AgentType.hydration),
  ];
}

/// Chat message model
@JsonSerializable()
class ChatMessage extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? intent;
  @JsonKey(name: 'agent_type')
  final AgentType? agentType;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'action_data')
  final Map<String, dynamic>? actionData;

  const ChatMessage({
    this.id,
    this.userId,
    required this.role,
    required this.content,
    this.intent,
    this.agentType,
    this.createdAt,
    this.actionData,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// Check if message is from user
  bool get isUser => role == 'user';

  /// Check if message is from assistant
  bool get isAssistant => role == 'assistant';

  /// Get the agent config for this message
  AgentConfig get agentConfig => AgentConfig.forType(agentType ?? AgentType.coach);

  /// Get timestamp as DateTime
  DateTime? get timestamp {
    if (createdAt == null || createdAt!.isEmpty) return null;
    try {
      // Try standard ISO8601 format first
      final parsed = DateTime.parse(createdAt!);
      return parsed;
    } catch (e) {
      try {
        // Handle PostgreSQL timestamp format: "2025-12-16 00:19:09+00"
        // Replace space with T for ISO8601 compatibility
        final normalized = createdAt!.replaceFirst(' ', 'T');
        return DateTime.parse(normalized);
      } catch (e2) {
        debugPrint('❌ Failed to parse timestamp: $createdAt - $e2');
        return null;
      }
    }
  }

  @override
  List<Object?> get props => [id, userId, role, content, agentType, createdAt, actionData];

  /// Check if this message has a generated workout
  bool get hasGeneratedWorkout =>
      actionData != null &&
      actionData!['action'] == 'generate_quick_workout' &&
      actionData!['workout_id'] != null;

  /// Get the workout ID if available (handles both int and String from backend)
  String? get workoutId {
    final id = actionData?['workout_id'];
    if (id == null) return null;
    return id.toString(); // Converts int or String to String
  }

  /// Get the workout name if available
  String? get workoutName => actionData?['workout_name'] as String?;
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
  @JsonKey(name: 'ai_settings')
  final Map<String, dynamic>? aiSettings;
  @JsonKey(name: 'unified_context')
  final String? unifiedContext;

  const ChatRequest({
    required this.message,
    required this.userId,
    this.userProfile,
    this.currentWorkout,
    this.workoutSchedule,
    this.conversationHistory,
    this.aiSettings,
    this.unifiedContext,
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
  @JsonKey(name: 'agent_type')
  final AgentType? agentType;
  @JsonKey(name: 'action_data')
  final Map<String, dynamic>? actionData;
  @JsonKey(name: 'rag_context_used')
  final bool? ragContextUsed;
  @JsonKey(name: 'similar_questions')
  final List<String>? similarQuestions;

  const ChatResponse({
    required this.message,
    this.intent,
    this.agentType,
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
  @JsonKey(name: 'agent_type')
  final AgentType? agentType;
  @JsonKey(name: 'action_data')
  final Map<String, dynamic>? actionData;

  const ChatHistoryItem({
    this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.agentType,
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
        agentType: agentType,
        createdAt: timestamp,
        actionData: actionData,
      );
}
