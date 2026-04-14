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

/// Message delivery status for optimistic UI
enum MessageStatus { pending, sent, delivered, error }

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
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'media_type')
  final String? mediaType; // 'image' or 'video'
  @JsonKey(name: 'media_refs')
  final List<Map<String, dynamic>>? mediaRefs;

  /// Transient local file path for showing user's own photo before S3 URL is available
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localFilePath;

  /// Delivery status for optimistic UI updates
  @JsonKey(includeFromJson: false, includeToJson: false)
  final MessageStatus status;

  /// Transient upload phase shown as overlay on video thumbnail:
  /// 'uploading' (real progress), 'analyzing' (indeterminate), null = done
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? uploadPhase;

  /// Upload progress 0.0–1.0 during 'uploading' phase; null = indeterminate
  @JsonKey(includeFromJson: false, includeToJson: false)
  final double? uploadProgress;

  /// Whether this message is pinned by the user
  @JsonKey(defaultValue: false)
  final bool isPinned;

  /// URL of an attached voice message
  @JsonKey(name: 'audio_url')
  final String? audioUrl;

  /// Duration of the voice message in milliseconds
  @JsonKey(name: 'audio_duration_ms')
  final int? audioDurationMs;

  /// Which coach persona sent this message (for preserving coach identity in history)
  @JsonKey(name: 'coach_persona_id')
  final String? coachPersonaId;

  const ChatMessage({
    this.id,
    this.userId,
    required this.role,
    required this.content,
    this.intent,
    this.agentType,
    this.createdAt,
    this.actionData,
    this.mediaUrl,
    this.mediaType,
    this.mediaRefs,
    this.localFilePath,
    this.status = MessageStatus.sent,
    this.isPinned = false,
    this.audioUrl,
    this.audioDurationMs,
    this.coachPersonaId,
    this.uploadPhase,
    this.uploadProgress,
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

  /// Check if this message has media (image or video)
  bool get hasMedia => (mediaUrl != null && mediaUrl!.isNotEmpty) || localFilePath != null;

  /// Check if this message has a form check result from the AI
  bool get hasFormCheckResult =>
      actionData != null &&
      actionData!['form_check_result'] != null;

  /// Get the form check result data if available
  Map<String, dynamic>? get formCheckResult =>
      actionData?['form_check_result'] as Map<String, dynamic>?;

  @override
  List<Object?> get props => [id, userId, role, content, agentType, createdAt, actionData, mediaUrl, mediaType, mediaRefs, localFilePath, status, isPinned, audioUrl, audioDurationMs, coachPersonaId];

  /// Check if this is a voice message
  bool get isVoiceMessage => audioUrl != null && audioUrl!.isNotEmpty;

  /// Create a copy with updated upload overlay state (use null to clear)
  ChatMessage withUploadState(String? phase, double? progress) {
    return ChatMessage(
      id: id,
      userId: userId,
      role: role,
      content: content,
      intent: intent,
      agentType: agentType,
      createdAt: createdAt,
      actionData: actionData,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaRefs: mediaRefs,
      localFilePath: localFilePath,
      status: status,
      isPinned: isPinned,
      audioUrl: audioUrl,
      audioDurationMs: audioDurationMs,
      coachPersonaId: coachPersonaId,
      uploadPhase: phase,
      uploadProgress: progress,
    );
  }

  /// Create a copy with optional field overrides
  ChatMessage copyWith({
    String? id,
    String? userId,
    String? role,
    String? content,
    String? intent,
    AgentType? agentType,
    String? createdAt,
    Map<String, dynamic>? actionData,
    String? mediaUrl,
    String? mediaType,
    List<Map<String, dynamic>>? mediaRefs,
    String? localFilePath,
    MessageStatus? status,
    bool? isPinned,
    String? audioUrl,
    int? audioDurationMs,
    String? coachPersonaId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      intent: intent ?? this.intent,
      agentType: agentType ?? this.agentType,
      createdAt: createdAt ?? this.createdAt,
      actionData: actionData ?? this.actionData,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      mediaRefs: mediaRefs ?? this.mediaRefs,
      localFilePath: localFilePath ?? this.localFilePath,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      coachPersonaId: coachPersonaId ?? this.coachPersonaId,
    );
  }

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

  /// Check if this message has a single food analysis result (plate scan)
  bool get hasFoodAnalysis =>
      actionData != null &&
      actionData!['action'] == 'food_analysis' &&
      actionData!['food_items'] != null;

  /// True when the Nutrition agent persisted a food_log row (text log,
  /// nutrition label scan, or app screenshot). Drives the "View logged
  /// meal" deep-link in the chat bubble.
  bool get hasFoodLogged =>
      actionData != null &&
      actionData!['action'] == 'food_logged' &&
      actionData!['success'] == true;

  /// Total calories of the just-logged meal (used for the link label).
  int? get loggedMealCalories {
    final v = actionData?['total_calories'];
    if (v is num) return v.toInt();
    return null;
  }

  /// Meal type of the just-logged meal (breakfast/lunch/dinner/snack).
  String? get loggedMealType => actionData?['meal_type'] as String?;

  /// Check if this message has a buffet analysis result
  bool get hasBuffetAnalysis =>
      actionData != null &&
      (actionData!['action'] == 'analyze_multi_food_images' ||
       actionData!['action'] == 'analyze_buffet');

  /// Check if this message has a menu analysis result
  bool get hasMenuAnalysis =>
      actionData != null &&
      actionData!['action'] == 'analyze_menu';

  /// Check if this message has a form comparison result
  bool get hasFormComparison =>
      actionData != null &&
      actionData!['action'] == 'compare_exercise_form';
}

/// Chat request model
@JsonSerializable(includeIfNull: false)
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
  @JsonKey(name: 'media_ref')
  final Map<String, dynamic>? mediaRef;
  @JsonKey(name: 'media_refs')
  final List<Map<String, dynamic>>? mediaRefs;
  @JsonKey(name: 'image_base64')
  final String? imageBase64;

  @JsonKey(name: 'video_frames')
  final List<String>? videoFrames;

  @JsonKey(name: 'media_url')
  final String? mediaUrl;

  /// Force-route to a specific agent, bypassing classifier.
  /// One of AgentType values (e.g. 'nutrition', 'workout', 'coach').
  /// Used by contextual widgets that already know the correct agent.
  @JsonKey(name: 'agent_override')
  final String? agentOverride;

  const ChatRequest({
    required this.message,
    required this.userId,
    this.userProfile,
    this.currentWorkout,
    this.workoutSchedule,
    this.conversationHistory,
    this.aiSettings,
    this.unifiedContext,
    this.mediaRef,
    this.mediaRefs,
    this.imageBase64,
    this.videoFrames,
    this.mediaUrl,
    this.agentOverride,
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
  @JsonKey(name: 'is_pinned', defaultValue: false)
  final bool isPinned;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'audio_duration_ms')
  final int? audioDurationMs;
  @JsonKey(name: 'coach_persona_id')
  final String? coachPersonaId;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'media_type')
  final String? mediaType;

  const ChatHistoryItem({
    this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.agentType,
    this.actionData,
    this.isPinned = false,
    this.audioUrl,
    this.audioDurationMs,
    this.coachPersonaId,
    this.mediaUrl,
    this.mediaType,
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
        isPinned: isPinned,
        audioUrl: audioUrl,
        audioDurationMs: audioDurationMs,
        coachPersonaId: coachPersonaId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
}
