import 'package:json_annotation/json_annotation.dart';

part 'hydration.g.dart';

/// Where a hydration log entry was created from. Drives the icon + badge
/// shown in the Today's Log row on the Fuel/Water tab so the user can tell
/// at a glance whether they logged via Home quick-add, during a workout,
/// from the Fuel tab itself, or via the AI chat.
enum HydrationSource {
  home('home'),
  workout('workout'),
  nutrition('nutrition'),
  chat('chat'),
  manual('manual'),
  unknown('unknown');

  final String value;
  const HydrationSource(this.value);

  static HydrationSource fromString(String? value) {
    if (value == null) return HydrationSource.manual;
    return HydrationSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HydrationSource.unknown,
    );
  }
}

/// Hydration log entry
@JsonSerializable()
class HydrationLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'drink_type')
  final String drinkType;
  @JsonKey(name: 'amount_ml')
  final int amountMl;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  final String? notes;
  @JsonKey(name: 'logged_at')
  final DateTime? loggedAt;
  /// Surface this log was created from. Backed by the `source` column on
  /// `hydration_logs` (added in migration 1983). Defaults to `'manual'`
  /// for legacy rows so the UI never shows an empty badge.
  final String? source;

  const HydrationLog({
    required this.id,
    required this.userId,
    required this.drinkType,
    required this.amountMl,
    this.workoutId,
    this.notes,
    this.loggedAt,
    this.source,
  });

  factory HydrationLog.fromJson(Map<String, dynamic> json) =>
      _$HydrationLogFromJson(json);
  Map<String, dynamic> toJson() => _$HydrationLogToJson(this);

  HydrationSource get sourceEnum => HydrationSource.fromString(source);
}

/// Daily hydration summary
@JsonSerializable()
class DailyHydrationSummary {
  final String date;
  @JsonKey(name: 'total_ml')
  final int totalMl;
  @JsonKey(name: 'water_ml')
  final int waterMl;
  @JsonKey(name: 'protein_shake_ml')
  final int proteinShakeMl;
  @JsonKey(name: 'sports_drink_ml')
  final int sportsDrinkMl;
  @JsonKey(name: 'other_ml')
  final int otherMl;
  @JsonKey(name: 'goal_ml')
  final int goalMl;
  @JsonKey(name: 'goal_percentage')
  final double goalPercentage;
  final List<HydrationLog> entries;

  const DailyHydrationSummary({
    required this.date,
    this.totalMl = 0,
    this.waterMl = 0,
    this.proteinShakeMl = 0,
    this.sportsDrinkMl = 0,
    this.otherMl = 0,
    this.goalMl = 2500,
    this.goalPercentage = 0,
    this.entries = const [],
  });

  factory DailyHydrationSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyHydrationSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyHydrationSummaryToJson(this);
}

/// Drink type enum for UI
enum DrinkType {
  water('water', 'Water', '💧'),
  proteinShake('protein_shake', 'Protein Shake', '🥤'),
  sportsDrink('sports_drink', 'Sports Drink', '⚡'),
  coffee('coffee', 'Coffee', '☕'),
  other('other', 'Other', '🥛');

  final String value;
  final String label;
  final String emoji;

  const DrinkType(this.value, this.label, this.emoji);

  static DrinkType fromValue(String value) {
    return DrinkType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DrinkType.other,
    );
  }
}

/// Quick add amounts in ml
class QuickAmount {
  final int ml;
  final String label;
  final String? description;

  const QuickAmount(this.ml, this.label, [this.description]);

  static const List<QuickAmount> defaults = [
    QuickAmount(250, '250ml', 'Glass'),
    QuickAmount(500, '500ml', 'Bottle'),
    QuickAmount(750, '750ml', 'Large'),
    QuickAmount(1000, '1L', 'Liter'),
  ];
}
