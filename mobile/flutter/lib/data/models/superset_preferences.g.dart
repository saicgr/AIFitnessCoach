// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superset_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupersetPreferences _$SupersetPreferencesFromJson(Map<String, dynamic> json) =>
    SupersetPreferences(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      supersetsEnabled: json['supersets_enabled'] as bool? ?? true,
      preferAntagonistPairs: json['prefer_antagonist_pairs'] as bool? ?? true,
      preferCompoundSets: json['prefer_compound_sets'] as bool? ?? false,
      maxSupersetPairs: (json['max_superset_pairs'] as num?)?.toInt() ?? 3,
      supersetRestSeconds:
          (json['superset_rest_seconds'] as num?)?.toInt() ?? 30,
      postSupersetRestSeconds:
          (json['post_superset_rest_seconds'] as num?)?.toInt() ?? 90,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SupersetPreferencesToJson(
  SupersetPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'supersets_enabled': instance.supersetsEnabled,
  'prefer_antagonist_pairs': instance.preferAntagonistPairs,
  'prefer_compound_sets': instance.preferCompoundSets,
  'max_superset_pairs': instance.maxSupersetPairs,
  'superset_rest_seconds': instance.supersetRestSeconds,
  'post_superset_rest_seconds': instance.postSupersetRestSeconds,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

SupersetSuggestion _$SupersetSuggestionFromJson(Map<String, dynamic> json) =>
    SupersetSuggestion(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String?,
      exercise1Name: json['exercise1_name'] as String,
      exercise1Id: json['exercise1_id'] as String?,
      exercise1Index: (json['exercise1_index'] as num).toInt(),
      exercise2Name: json['exercise2_name'] as String,
      exercise2Id: json['exercise2_id'] as String?,
      exercise2Index: (json['exercise2_index'] as num).toInt(),
      pairingType:
          $enumDecodeNullable(
            _$SupersetPairingTypeEnumMap,
            json['pairing_type'],
          ) ??
          SupersetPairingType.antagonist,
      pairingReason: json['pairing_reason'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.8,
      timeSavedSeconds: (json['time_saved_seconds'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SupersetSuggestionToJson(SupersetSuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workout_id': instance.workoutId,
      'exercise1_name': instance.exercise1Name,
      'exercise1_id': instance.exercise1Id,
      'exercise1_index': instance.exercise1Index,
      'exercise2_name': instance.exercise2Name,
      'exercise2_id': instance.exercise2Id,
      'exercise2_index': instance.exercise2Index,
      'pairing_type': _$SupersetPairingTypeEnumMap[instance.pairingType]!,
      'pairing_reason': instance.pairingReason,
      'confidence_score': instance.confidenceScore,
      'time_saved_seconds': instance.timeSavedSeconds,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$SupersetPairingTypeEnumMap = {
  SupersetPairingType.antagonist: 'antagonist',
  SupersetPairingType.compound: 'compound',
  SupersetPairingType.upperLower: 'upper_lower',
  SupersetPairingType.pushPull: 'push_pull',
  SupersetPairingType.preExhaust: 'pre_exhaust',
  SupersetPairingType.postExhaust: 'post_exhaust',
  SupersetPairingType.custom: 'custom',
};

FavoriteSupersetPair _$FavoriteSupersetPairFromJson(
  Map<String, dynamic> json,
) => FavoriteSupersetPair(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  exercise1Name: json['exercise1_name'] as String,
  exercise1Id: json['exercise1_id'] as String?,
  exercise2Name: json['exercise2_name'] as String,
  exercise2Id: json['exercise2_id'] as String?,
  pairingType:
      $enumDecodeNullable(_$SupersetPairingTypeEnumMap, json['pairing_type']) ??
      SupersetPairingType.antagonist,
  notes: json['notes'] as String?,
  timesUsed: (json['times_used'] as num?)?.toInt() ?? 0,
  lastUsedAt: json['last_used_at'] == null
      ? null
      : DateTime.parse(json['last_used_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$FavoriteSupersetPairToJson(
  FavoriteSupersetPair instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'exercise1_name': instance.exercise1Name,
  'exercise1_id': instance.exercise1Id,
  'exercise2_name': instance.exercise2Name,
  'exercise2_id': instance.exercise2Id,
  'pairing_type': _$SupersetPairingTypeEnumMap[instance.pairingType]!,
  'notes': instance.notes,
  'times_used': instance.timesUsed,
  'last_used_at': instance.lastUsedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

ActiveSupersetPair _$ActiveSupersetPairFromJson(Map<String, dynamic> json) =>
    ActiveSupersetPair(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      supersetGroup: (json['superset_group'] as num).toInt(),
      exercise1Index: (json['exercise1_index'] as num).toInt(),
      exercise2Index: (json['exercise2_index'] as num).toInt(),
      restBetweenSeconds: (json['rest_between_seconds'] as num?)?.toInt() ?? 30,
      restAfterSeconds: (json['rest_after_seconds'] as num?)?.toInt() ?? 90,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActiveSupersetPairToJson(ActiveSupersetPair instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workout_id': instance.workoutId,
      'superset_group': instance.supersetGroup,
      'exercise1_index': instance.exercise1Index,
      'exercise2_index': instance.exercise2Index,
      'rest_between_seconds': instance.restBetweenSeconds,
      'rest_after_seconds': instance.restAfterSeconds,
      'created_at': instance.createdAt.toIso8601String(),
    };

SupersetHistoryEntry _$SupersetHistoryEntryFromJson(
  Map<String, dynamic> json,
) => SupersetHistoryEntry(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  workoutId: json['workout_id'] as String,
  exercise1Name: json['exercise1_name'] as String,
  exercise2Name: json['exercise2_name'] as String,
  pairingType:
      $enumDecodeNullable(_$SupersetPairingTypeEnumMap, json['pairing_type']) ??
      SupersetPairingType.antagonist,
  wasCompleted: json['was_completed'] as bool? ?? true,
  userRating: (json['user_rating'] as num?)?.toInt(),
  performedAt: DateTime.parse(json['performed_at'] as String),
);

Map<String, dynamic> _$SupersetHistoryEntryToJson(
  SupersetHistoryEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'workout_id': instance.workoutId,
  'exercise1_name': instance.exercise1Name,
  'exercise2_name': instance.exercise2Name,
  'pairing_type': _$SupersetPairingTypeEnumMap[instance.pairingType]!,
  'was_completed': instance.wasCompleted,
  'user_rating': instance.userRating,
  'performed_at': instance.performedAt.toIso8601String(),
};
