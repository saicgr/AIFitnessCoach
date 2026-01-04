// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestSuggestion _$RestSuggestionFromJson(Map<String, dynamic> json) =>
    RestSuggestion(
      suggestedSeconds: (json['suggested_seconds'] as num).toInt(),
      reasoning: json['reasoning'] as String,
      quickOptionSeconds: (json['quick_option_seconds'] as num).toInt(),
      restCategory: json['rest_category'] as String,
      aiPowered: json['ai_powered'] as bool? ?? true,
    );

Map<String, dynamic> _$RestSuggestionToJson(RestSuggestion instance) =>
    <String, dynamic>{
      'suggested_seconds': instance.suggestedSeconds,
      'reasoning': instance.reasoning,
      'quick_option_seconds': instance.quickOptionSeconds,
      'rest_category': instance.restCategory,
      'ai_powered': instance.aiPowered,
    };
