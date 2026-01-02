/// Live chat session models for real-time customer support.
///
/// These models support:
/// - Live chat sessions with support agents
/// - Real-time messaging with typing indicators
/// - Queue position tracking
/// - Agent availability checking
library;

import 'package:json_annotation/json_annotation.dart';

part 'live_chat_session.g.dart';

/// Status of a live chat session
enum LiveChatStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('active')
  active,
  @JsonValue('ended')
  ended,
}

extension LiveChatStatusExtension on LiveChatStatus {
  String get displayName {
    switch (this) {
      case LiveChatStatus.queued:
        return 'Waiting in Queue';
      case LiveChatStatus.active:
        return 'Connected';
      case LiveChatStatus.ended:
        return 'Chat Ended';
    }
  }

  bool get isActive => this == LiveChatStatus.active;
  bool get isQueued => this == LiveChatStatus.queued;
  bool get isEnded => this == LiveChatStatus.ended;
}

/// Role of message sender in live chat
enum SenderRole {
  @JsonValue('user')
  user,
  @JsonValue('agent')
  agent,
  @JsonValue('system')
  system,
}

extension SenderRoleExtension on SenderRole {
  String get displayName {
    switch (this) {
      case SenderRole.user:
        return 'You';
      case SenderRole.agent:
        return 'Agent';
      case SenderRole.system:
        return 'System';
    }
  }

  bool get isUser => this == SenderRole.user;
  bool get isAgent => this == SenderRole.agent;
  bool get isSystem => this == SenderRole.system;
}

/// A message in a live chat session
@JsonSerializable()
class LiveChatMessage {
  final String id;
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  @JsonKey(name: 'sender_role')
  final SenderRole senderRole;
  final String message;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  const LiveChatMessage({
    required this.id,
    required this.ticketId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LiveChatMessageToJson(this);

  /// Check if message has been read
  bool get isRead => readAt != null;

  /// Check if message is from user
  bool get isFromUser => senderRole == SenderRole.user;

  /// Check if message is from agent
  bool get isFromAgent => senderRole == SenderRole.agent;

  /// Check if message is a system message
  bool get isSystemMessage => senderRole == SenderRole.system;

  /// Get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a copy with updated fields
  LiveChatMessage copyWith({
    String? id,
    String? ticketId,
    SenderRole? senderRole,
    String? message,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return LiveChatMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// A live chat session with a support agent
@JsonSerializable()
class LiveChatSession {
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  final LiveChatStatus status;
  @JsonKey(name: 'queue_position')
  final int? queuePosition;
  @JsonKey(name: 'agent_name')
  final String? agentName;
  @JsonKey(name: 'agent_id')
  final String? agentId;
  final List<LiveChatMessage> messages;
  @JsonKey(name: 'is_agent_typing')
  final bool isAgentTyping;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  final String? category;
  @JsonKey(name: 'escalated_from_ai')
  final bool escalatedFromAi;
  @JsonKey(name: 'ai_context')
  final String? aiContext;
  @JsonKey(name: 'estimated_wait_minutes')
  final int? estimatedWaitMinutes;

  const LiveChatSession({
    required this.ticketId,
    required this.status,
    this.queuePosition,
    this.agentName,
    this.agentId,
    this.messages = const [],
    this.isAgentTyping = false,
    required this.createdAt,
    this.endedAt,
    this.category,
    this.escalatedFromAi = false,
    this.aiContext,
    this.estimatedWaitMinutes,
  });

  factory LiveChatSession.fromJson(Map<String, dynamic> json) =>
      _$LiveChatSessionFromJson(json);

  Map<String, dynamic> toJson() => _$LiveChatSessionToJson(this);

  /// Check if chat is currently active
  bool get isActive => status == LiveChatStatus.active;

  /// Check if chat is in queue
  bool get isQueued => status == LiveChatStatus.queued;

  /// Check if chat has ended
  bool get hasEnded => status == LiveChatStatus.ended;

  /// Check if connected to an agent
  bool get isConnected => agentId != null && status == LiveChatStatus.active;

  /// Get the last message in the session
  LiveChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get count of unread messages from agent
  int get unreadCount =>
      messages.where((m) => m.isFromAgent && !m.isRead).length;

  /// Get formatted wait time
  String get formattedWaitTime {
    if (estimatedWaitMinutes == null) return 'Unknown';
    if (estimatedWaitMinutes! < 1) return 'Less than a minute';
    if (estimatedWaitMinutes! == 1) return '1 minute';
    return '$estimatedWaitMinutes minutes';
  }

  /// Create a copy with updated fields
  LiveChatSession copyWith({
    String? ticketId,
    LiveChatStatus? status,
    int? queuePosition,
    String? agentName,
    String? agentId,
    List<LiveChatMessage>? messages,
    bool? isAgentTyping,
    DateTime? createdAt,
    DateTime? endedAt,
    String? category,
    bool? escalatedFromAi,
    String? aiContext,
    int? estimatedWaitMinutes,
  }) {
    return LiveChatSession(
      ticketId: ticketId ?? this.ticketId,
      status: status ?? this.status,
      queuePosition: queuePosition ?? this.queuePosition,
      agentName: agentName ?? this.agentName,
      agentId: agentId ?? this.agentId,
      messages: messages ?? this.messages,
      isAgentTyping: isAgentTyping ?? this.isAgentTyping,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      category: category ?? this.category,
      escalatedFromAi: escalatedFromAi ?? this.escalatedFromAi,
      aiContext: aiContext ?? this.aiContext,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
    );
  }
}

/// Queue position information
@JsonSerializable()
class QueuePosition {
  final int position;
  @JsonKey(name: 'estimated_wait_minutes')
  final int estimatedWaitMinutes;
  @JsonKey(name: 'agents_available')
  final int agentsAvailable;

  const QueuePosition({
    required this.position,
    required this.estimatedWaitMinutes,
    this.agentsAvailable = 0,
  });

  factory QueuePosition.fromJson(Map<String, dynamic> json) =>
      _$QueuePositionFromJson(json);

  Map<String, dynamic> toJson() => _$QueuePositionToJson(this);

  /// Get formatted wait time
  String get formattedWaitTime {
    if (estimatedWaitMinutes < 1) return 'Less than a minute';
    if (estimatedWaitMinutes == 1) return '1 minute';
    return '$estimatedWaitMinutes minutes';
  }

  /// Get position text
  String get positionText {
    if (position == 1) return 'You are next!';
    return 'Position $position in queue';
  }
}

/// Agent availability status
@JsonSerializable()
class Availability {
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'agents_online')
  final int agentsOnline;
  @JsonKey(name: 'current_queue_size')
  final int currentQueueSize;
  @JsonKey(name: 'estimated_wait_minutes')
  final int estimatedWaitMinutes;
  @JsonKey(name: 'operating_hours')
  final OperatingHours? operatingHours;
  @JsonKey(name: 'next_available_at')
  final DateTime? nextAvailableAt;

  const Availability({
    required this.isAvailable,
    this.agentsOnline = 0,
    this.currentQueueSize = 0,
    this.estimatedWaitMinutes = 0,
    this.operatingHours,
    this.nextAvailableAt,
  });

  factory Availability.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityToJson(this);

  /// Get formatted wait time
  String get formattedWaitTime {
    if (!isAvailable) return 'Currently unavailable';
    if (estimatedWaitMinutes < 1) return 'Available now';
    if (estimatedWaitMinutes == 1) return '~1 minute wait';
    return '~$estimatedWaitMinutes minute wait';
  }

  /// Get availability message
  String get availabilityMessage {
    if (isAvailable) {
      if (currentQueueSize == 0) {
        return 'Agents are available to help you now';
      }
      return '$currentQueueSize people ahead of you';
    }
    if (nextAvailableAt != null) {
      return 'Available at ${nextAvailableAt!.hour}:${nextAvailableAt!.minute.toString().padLeft(2, '0')}';
    }
    return 'Live chat is currently offline';
  }
}

/// Operating hours for live chat
@JsonSerializable()
class OperatingHours {
  @JsonKey(name: 'start_time')
  final String startTime; // Format: "HH:mm"
  @JsonKey(name: 'end_time')
  final String endTime; // Format: "HH:mm"
  final String timezone;
  @JsonKey(name: 'days_available')
  final List<String> daysAvailable; // e.g., ["monday", "tuesday", ...]

  const OperatingHours({
    required this.startTime,
    required this.endTime,
    required this.timezone,
    this.daysAvailable = const [],
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) =>
      _$OperatingHoursFromJson(json);

  Map<String, dynamic> toJson() => _$OperatingHoursToJson(this);

  /// Get formatted hours string
  String get formattedHours => '$startTime - $endTime $timezone';
}

/// Request to start a live chat
@JsonSerializable()
class StartLiveChatRequest {
  final String category;
  @JsonKey(name: 'initial_message')
  final String initialMessage;
  @JsonKey(name: 'escalated_from_ai')
  final bool escalatedFromAi;
  @JsonKey(name: 'ai_context')
  final String? aiContext;

  const StartLiveChatRequest({
    required this.category,
    required this.initialMessage,
    this.escalatedFromAi = false,
    this.aiContext,
  });

  factory StartLiveChatRequest.fromJson(Map<String, dynamic> json) =>
      _$StartLiveChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartLiveChatRequestToJson(this);
}

/// Live chat categories
enum LiveChatCategory {
  billing('billing', 'Billing & Payments'),
  technical('technical', 'Technical Support'),
  account('account', 'Account Help'),
  workout('workout', 'Workout Questions'),
  general('general', 'General Inquiry');

  final String value;
  final String displayName;

  const LiveChatCategory(this.value, this.displayName);

  static LiveChatCategory fromValue(String value) {
    return LiveChatCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => LiveChatCategory.general,
    );
  }
}
