// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  role: json['role'] as String,
  content: json['content'] as String,
  intent: json['intent'] as String?,
  agentType: $enumDecodeNullable(_$AgentTypeEnumMap, json['agent_type']),
  createdAt: json['created_at'] as String?,
  actionData: json['action_data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'role': instance.role,
      'content': instance.content,
      'intent': instance.intent,
      'agent_type': _$AgentTypeEnumMap[instance.agentType],
      'created_at': instance.createdAt,
      'action_data': instance.actionData,
    };

const _$AgentTypeEnumMap = {
  AgentType.coach: 'coach',
  AgentType.nutrition: 'nutrition',
  AgentType.workout: 'workout',
  AgentType.injury: 'injury',
  AgentType.hydration: 'hydration',
};

ChatRequest _$ChatRequestFromJson(Map<String, dynamic> json) => ChatRequest(
  message: json['message'] as String,
  userId: json['user_id'] as String,
  userProfile: json['user_profile'] as Map<String, dynamic>?,
  currentWorkout: json['current_workout'] as Map<String, dynamic>?,
  workoutSchedule: json['workout_schedule'] as Map<String, dynamic>?,
  conversationHistory: (json['conversation_history'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  aiSettings: json['ai_settings'] as Map<String, dynamic>?,
  unifiedContext: json['unified_context'] as String?,
);

Map<String, dynamic> _$ChatRequestToJson(ChatRequest instance) =>
    <String, dynamic>{
      'message': instance.message,
      'user_id': instance.userId,
      if (instance.userProfile case final value?) 'user_profile': value,
      if (instance.currentWorkout case final value?) 'current_workout': value,
      if (instance.workoutSchedule case final value?) 'workout_schedule': value,
      if (instance.conversationHistory case final value?)
        'conversation_history': value,
      if (instance.aiSettings case final value?) 'ai_settings': value,
      if (instance.unifiedContext case final value?) 'unified_context': value,
    };

ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) => ChatResponse(
  message: json['message'] as String,
  intent: json['intent'] as String?,
  agentType: $enumDecodeNullable(_$AgentTypeEnumMap, json['agent_type']),
  actionData: json['action_data'] as Map<String, dynamic>?,
  ragContextUsed: json['rag_context_used'] as bool?,
  similarQuestions: (json['similar_questions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ChatResponseToJson(ChatResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'intent': instance.intent,
      'agent_type': _$AgentTypeEnumMap[instance.agentType],
      'action_data': instance.actionData,
      'rag_context_used': instance.ragContextUsed,
      'similar_questions': instance.similarQuestions,
    };

ChatHistoryItem _$ChatHistoryItemFromJson(Map<String, dynamic> json) =>
    ChatHistoryItem(
      id: json['id'] as String?,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String?,
      agentType: $enumDecodeNullable(_$AgentTypeEnumMap, json['agent_type']),
      actionData: json['action_data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChatHistoryItemToJson(ChatHistoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'agent_type': _$AgentTypeEnumMap[instance.agentType],
      'action_data': instance.actionData,
    };
