// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_chat_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveChatMessage _$LiveChatMessageFromJson(Map<String, dynamic> json) =>
    LiveChatMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderRole: $enumDecode(_$SenderRoleEnumMap, json['sender_role']),
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$LiveChatMessageToJson(LiveChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'sender_role': _$SenderRoleEnumMap[instance.senderRole]!,
      'message': instance.message,
      'created_at': instance.createdAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
    };

const _$SenderRoleEnumMap = {
  SenderRole.user: 'user',
  SenderRole.agent: 'agent',
  SenderRole.system: 'system',
};

LiveChatSession _$LiveChatSessionFromJson(Map<String, dynamic> json) =>
    LiveChatSession(
      ticketId: json['ticket_id'] as String,
      status: $enumDecode(_$LiveChatStatusEnumMap, json['status']),
      queuePosition: (json['queue_position'] as num?)?.toInt(),
      agentName: json['agent_name'] as String?,
      agentId: json['agent_id'] as String?,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => LiveChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isAgentTyping: json['is_agent_typing'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      category: json['category'] as String?,
      escalatedFromAi: json['escalated_from_ai'] as bool? ?? false,
      aiContext: json['ai_context'] as String?,
      estimatedWaitMinutes: (json['estimated_wait_minutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LiveChatSessionToJson(LiveChatSession instance) =>
    <String, dynamic>{
      'ticket_id': instance.ticketId,
      'status': _$LiveChatStatusEnumMap[instance.status]!,
      'queue_position': instance.queuePosition,
      'agent_name': instance.agentName,
      'agent_id': instance.agentId,
      'messages': instance.messages,
      'is_agent_typing': instance.isAgentTyping,
      'created_at': instance.createdAt.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'category': instance.category,
      'escalated_from_ai': instance.escalatedFromAi,
      'ai_context': instance.aiContext,
      'estimated_wait_minutes': instance.estimatedWaitMinutes,
    };

const _$LiveChatStatusEnumMap = {
  LiveChatStatus.queued: 'queued',
  LiveChatStatus.active: 'active',
  LiveChatStatus.ended: 'ended',
};

QueuePosition _$QueuePositionFromJson(Map<String, dynamic> json) =>
    QueuePosition(
      position: (json['position'] as num).toInt(),
      estimatedWaitMinutes: (json['estimated_wait_minutes'] as num).toInt(),
      agentsAvailable: (json['agents_available'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$QueuePositionToJson(QueuePosition instance) =>
    <String, dynamic>{
      'position': instance.position,
      'estimated_wait_minutes': instance.estimatedWaitMinutes,
      'agents_available': instance.agentsAvailable,
    };

Availability _$AvailabilityFromJson(Map<String, dynamic> json) => Availability(
  isAvailable: json['is_available'] as bool,
  agentsOnline: (json['agents_online'] as num?)?.toInt() ?? 0,
  currentQueueSize: (json['current_queue_size'] as num?)?.toInt() ?? 0,
  estimatedWaitMinutes: (json['estimated_wait_minutes'] as num?)?.toInt() ?? 0,
  operatingHours: json['operating_hours'] == null
      ? null
      : OperatingHours.fromJson(
          json['operating_hours'] as Map<String, dynamic>,
        ),
  nextAvailableAt: json['next_available_at'] == null
      ? null
      : DateTime.parse(json['next_available_at'] as String),
);

Map<String, dynamic> _$AvailabilityToJson(Availability instance) =>
    <String, dynamic>{
      'is_available': instance.isAvailable,
      'agents_online': instance.agentsOnline,
      'current_queue_size': instance.currentQueueSize,
      'estimated_wait_minutes': instance.estimatedWaitMinutes,
      'operating_hours': instance.operatingHours,
      'next_available_at': instance.nextAvailableAt?.toIso8601String(),
    };

OperatingHours _$OperatingHoursFromJson(Map<String, dynamic> json) =>
    OperatingHours(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      timezone: json['timezone'] as String,
      daysAvailable:
          (json['days_available'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OperatingHoursToJson(OperatingHours instance) =>
    <String, dynamic>{
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'timezone': instance.timezone,
      'days_available': instance.daysAvailable,
    };

StartLiveChatRequest _$StartLiveChatRequestFromJson(
  Map<String, dynamic> json,
) => StartLiveChatRequest(
  category: json['category'] as String,
  initialMessage: json['initial_message'] as String,
  escalatedFromAi: json['escalated_from_ai'] as bool? ?? false,
  aiContext: json['ai_context'] as String?,
);

Map<String, dynamic> _$StartLiveChatRequestToJson(
  StartLiveChatRequest instance,
) => <String, dynamic>{
  'category': instance.category,
  'initial_message': instance.initialMessage,
  'escalated_from_ai': instance.escalatedFromAi,
  'ai_context': instance.aiContext,
};
