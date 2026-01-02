import 'package:json_annotation/json_annotation.dart';

part 'superset_preferences.g.dart';

/// User preferences for superset configuration
@JsonSerializable()
class SupersetPreferences {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'supersets_enabled')
  final bool supersetsEnabled;
  @JsonKey(name: 'prefer_antagonist_pairs')
  final bool preferAntagonistPairs;
  @JsonKey(name: 'prefer_compound_sets')
  final bool preferCompoundSets;
  @JsonKey(name: 'max_superset_pairs')
  final int maxSupersetPairs;
  @JsonKey(name: 'superset_rest_seconds')
  final int supersetRestSeconds;
  @JsonKey(name: 'post_superset_rest_seconds')
  final int postSupersetRestSeconds;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const SupersetPreferences({
    this.id,
    this.userId,
    this.supersetsEnabled = true,
    this.preferAntagonistPairs = true,
    this.preferCompoundSets = false,
    this.maxSupersetPairs = 3,
    this.supersetRestSeconds = 30,
    this.postSupersetRestSeconds = 90,
    this.createdAt,
    this.updatedAt,
  });

  factory SupersetPreferences.fromJson(Map<String, dynamic> json) =>
      _$SupersetPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$SupersetPreferencesToJson(this);

  /// Create a copy with updated fields
  SupersetPreferences copyWith({
    String? id,
    String? userId,
    bool? supersetsEnabled,
    bool? preferAntagonistPairs,
    bool? preferCompoundSets,
    int? maxSupersetPairs,
    int? supersetRestSeconds,
    int? postSupersetRestSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupersetPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      supersetsEnabled: supersetsEnabled ?? this.supersetsEnabled,
      preferAntagonistPairs: preferAntagonistPairs ?? this.preferAntagonistPairs,
      preferCompoundSets: preferCompoundSets ?? this.preferCompoundSets,
      maxSupersetPairs: maxSupersetPairs ?? this.maxSupersetPairs,
      supersetRestSeconds: supersetRestSeconds ?? this.supersetRestSeconds,
      postSupersetRestSeconds: postSupersetRestSeconds ?? this.postSupersetRestSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get rest description for display
  String get restDescription {
    return '$supersetRestSeconds sec between exercises, $postSupersetRestSeconds sec after superset';
  }

  /// Check if preferences allow supersets
  bool get canUseSupersets => supersetsEnabled && maxSupersetPairs > 0;
}

/// A suggested superset pair for a workout
@JsonSerializable()
class SupersetSuggestion {
  final String id;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'exercise1_name')
  final String exercise1Name;
  @JsonKey(name: 'exercise1_id')
  final String? exercise1Id;
  @JsonKey(name: 'exercise1_index')
  final int exercise1Index;
  @JsonKey(name: 'exercise2_name')
  final String exercise2Name;
  @JsonKey(name: 'exercise2_id')
  final String? exercise2Id;
  @JsonKey(name: 'exercise2_index')
  final int exercise2Index;
  @JsonKey(name: 'pairing_type')
  final SupersetPairingType pairingType;
  @JsonKey(name: 'pairing_reason')
  final String? pairingReason;
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;
  @JsonKey(name: 'time_saved_seconds')
  final int? timeSavedSeconds;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const SupersetSuggestion({
    required this.id,
    this.workoutId,
    required this.exercise1Name,
    this.exercise1Id,
    required this.exercise1Index,
    required this.exercise2Name,
    this.exercise2Id,
    required this.exercise2Index,
    this.pairingType = SupersetPairingType.antagonist,
    this.pairingReason,
    this.confidenceScore = 0.8,
    this.timeSavedSeconds,
    this.createdAt,
  });

  factory SupersetSuggestion.fromJson(Map<String, dynamic> json) =>
      _$SupersetSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$SupersetSuggestionToJson(this);

  /// Get display name for the pairing
  String get pairingDisplayName {
    switch (pairingType) {
      case SupersetPairingType.antagonist:
        return 'Antagonist Pair';
      case SupersetPairingType.compound:
        return 'Compound Set';
      case SupersetPairingType.upperLower:
        return 'Upper/Lower Split';
      case SupersetPairingType.pushPull:
        return 'Push/Pull Pair';
      case SupersetPairingType.preExhaust:
        return 'Pre-Exhaust';
      case SupersetPairingType.postExhaust:
        return 'Post-Exhaust';
      case SupersetPairingType.custom:
        return 'Custom Pair';
    }
  }

  /// Get confidence display (e.g., "High", "Medium", "Low")
  String get confidenceLabel {
    if (confidenceScore >= 0.8) return 'High';
    if (confidenceScore >= 0.5) return 'Medium';
    return 'Low';
  }

  /// Get estimated time saved display string
  String? get timeSavedDisplay {
    if (timeSavedSeconds == null || timeSavedSeconds! <= 0) return null;
    final minutes = timeSavedSeconds! ~/ 60;
    final seconds = timeSavedSeconds! % 60;
    if (minutes > 0) {
      return '$minutes min ${seconds > 0 ? '$seconds sec' : ''} saved';
    }
    return '$seconds sec saved';
  }
}

/// A user's favorite superset pair (saved for reuse)
@JsonSerializable()
class FavoriteSupersetPair {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'exercise1_name')
  final String exercise1Name;
  @JsonKey(name: 'exercise1_id')
  final String? exercise1Id;
  @JsonKey(name: 'exercise2_name')
  final String exercise2Name;
  @JsonKey(name: 'exercise2_id')
  final String? exercise2Id;
  @JsonKey(name: 'pairing_type')
  final SupersetPairingType pairingType;
  final String? notes;
  @JsonKey(name: 'times_used')
  final int timesUsed;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const FavoriteSupersetPair({
    required this.id,
    required this.userId,
    required this.exercise1Name,
    this.exercise1Id,
    required this.exercise2Name,
    this.exercise2Id,
    this.pairingType = SupersetPairingType.antagonist,
    this.notes,
    this.timesUsed = 0,
    this.lastUsedAt,
    required this.createdAt,
  });

  factory FavoriteSupersetPair.fromJson(Map<String, dynamic> json) =>
      _$FavoriteSupersetPairFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteSupersetPairToJson(this);

  /// Get display name for this pair
  String get displayName => '$exercise1Name + $exercise2Name';

  /// Check if this pair was used recently (within last 7 days)
  bool get wasUsedRecently {
    if (lastUsedAt == null) return false;
    return DateTime.now().difference(lastUsedAt!).inDays <= 7;
  }
}

/// An active superset pair within a workout
@JsonSerializable()
class ActiveSupersetPair {
  final String id;
  @JsonKey(name: 'workout_id')
  final String workoutId;
  @JsonKey(name: 'superset_group')
  final int supersetGroup;
  @JsonKey(name: 'exercise1_index')
  final int exercise1Index;
  @JsonKey(name: 'exercise2_index')
  final int exercise2Index;
  @JsonKey(name: 'rest_between_seconds')
  final int restBetweenSeconds;
  @JsonKey(name: 'rest_after_seconds')
  final int restAfterSeconds;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ActiveSupersetPair({
    required this.id,
    required this.workoutId,
    required this.supersetGroup,
    required this.exercise1Index,
    required this.exercise2Index,
    this.restBetweenSeconds = 30,
    this.restAfterSeconds = 90,
    required this.createdAt,
  });

  factory ActiveSupersetPair.fromJson(Map<String, dynamic> json) =>
      _$ActiveSupersetPairFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveSupersetPairToJson(this);

  /// Check if an exercise index is part of this superset
  bool containsExercise(int exerciseIndex) {
    return exerciseIndex == exercise1Index || exerciseIndex == exercise2Index;
  }

  /// Get the partner exercise index for a given exercise
  int? getPartnerIndex(int exerciseIndex) {
    if (exerciseIndex == exercise1Index) return exercise2Index;
    if (exerciseIndex == exercise2Index) return exercise1Index;
    return null;
  }
}

/// History entry for superset usage
@JsonSerializable()
class SupersetHistoryEntry {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'workout_id')
  final String workoutId;
  @JsonKey(name: 'exercise1_name')
  final String exercise1Name;
  @JsonKey(name: 'exercise2_name')
  final String exercise2Name;
  @JsonKey(name: 'pairing_type')
  final SupersetPairingType pairingType;
  @JsonKey(name: 'was_completed')
  final bool wasCompleted;
  @JsonKey(name: 'user_rating')
  final int? userRating;
  @JsonKey(name: 'performed_at')
  final DateTime performedAt;

  const SupersetHistoryEntry({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.exercise1Name,
    required this.exercise2Name,
    this.pairingType = SupersetPairingType.antagonist,
    this.wasCompleted = true,
    this.userRating,
    required this.performedAt,
  });

  factory SupersetHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$SupersetHistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$SupersetHistoryEntryToJson(this);

  /// Get rating display (stars or description)
  String? get ratingDisplay {
    if (userRating == null) return null;
    if (userRating! >= 4) return 'Great pairing';
    if (userRating! >= 3) return 'Good pairing';
    if (userRating! >= 2) return 'Okay pairing';
    return 'Poor pairing';
  }
}

/// Types of superset pairings
@JsonEnum(valueField: 'value')
enum SupersetPairingType {
  @JsonValue('antagonist')
  antagonist('antagonist'),
  @JsonValue('compound')
  compound('compound'),
  @JsonValue('upper_lower')
  upperLower('upper_lower'),
  @JsonValue('push_pull')
  pushPull('push_pull'),
  @JsonValue('pre_exhaust')
  preExhaust('pre_exhaust'),
  @JsonValue('post_exhaust')
  postExhaust('post_exhaust'),
  @JsonValue('custom')
  custom('custom');

  const SupersetPairingType(this.value);
  final String value;

  /// Get human-readable description
  String get description {
    switch (this) {
      case SupersetPairingType.antagonist:
        return 'Opposing muscle groups (e.g., biceps/triceps)';
      case SupersetPairingType.compound:
        return 'Same muscle group, different angles';
      case SupersetPairingType.upperLower:
        return 'Upper body with lower body exercise';
      case SupersetPairingType.pushPull:
        return 'Pushing movement with pulling movement';
      case SupersetPairingType.preExhaust:
        return 'Isolation before compound exercise';
      case SupersetPairingType.postExhaust:
        return 'Compound followed by isolation';
      case SupersetPairingType.custom:
        return 'User-defined pairing';
    }
  }

  /// Get icon name for display
  String get iconName {
    switch (this) {
      case SupersetPairingType.antagonist:
        return 'swap_horiz';
      case SupersetPairingType.compound:
        return 'layers';
      case SupersetPairingType.upperLower:
        return 'height';
      case SupersetPairingType.pushPull:
        return 'compare_arrows';
      case SupersetPairingType.preExhaust:
        return 'arrow_forward';
      case SupersetPairingType.postExhaust:
        return 'arrow_back';
      case SupersetPairingType.custom:
        return 'tune';
    }
  }
}
