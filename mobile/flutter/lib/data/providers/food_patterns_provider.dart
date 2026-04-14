import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_patterns.dart';
import '../repositories/nutrition_repository.dart';

/// Query args for the top-foods provider.
class TopFoodsQuery {
  final String userId;
  final String metric;
  final String range;
  final String? date;

  const TopFoodsQuery({
    required this.userId,
    this.metric = 'calories',
    this.range = 'week',
    this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is TopFoodsQuery &&
      other.userId == userId &&
      other.metric == metric &&
      other.range == range &&
      other.date == date;

  @override
  int get hashCode => Object.hash(userId, metric, range, date);
}

class MacrosQuery {
  final String userId;
  final String range;
  final String? date;

  const MacrosQuery({
    required this.userId,
    this.range = 'week',
    this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is MacrosQuery &&
      other.userId == userId &&
      other.range == range &&
      other.date == date;

  @override
  int get hashCode => Object.hash(userId, range, date);
}

class HistoryQuery {
  final String userId;
  final String range;
  final String? date;
  final int offset;

  const HistoryQuery({
    required this.userId,
    this.range = 'week',
    this.date,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery &&
      other.userId == userId &&
      other.range == range &&
      other.date == date &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(userId, range, date, offset);
}

/// Mood/energy patterns for the Patterns tab (Section 3). Always 90-day window.
final foodPatternsMoodProvider = FutureProvider.autoDispose
    .family<FoodPatternsMoodResponse, String>((ref, userId) async {
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getMoodPatterns(userId);
});

/// Top foods by nutrient for Section 2. Re-fires on metric/range change.
final topFoodsProvider = FutureProvider.autoDispose
    .family<TopFoodsResponse, TopFoodsQuery>((ref, query) async {
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getTopFoods(
    query.userId,
    metric: query.metric,
    range: query.range,
    date: query.date,
  );
});

/// Macros/calorie summary for Section 1.
final macrosSummaryProvider = FutureProvider.autoDispose
    .family<MacrosSummaryResponse, MacrosQuery>((ref, query) async {
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getMacrosSummary(
    query.userId,
    range: query.range,
    date: query.date,
  );
});

/// Paginated meal history for Section 4.
final patternsHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, HistoryQuery>((ref, query) async {
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getPatternsHistory(
    query.userId,
    range: query.range,
    date: query.date,
    offset: query.offset,
  );
});

/// Patterns/check-in settings (backed by user_nutrition_preferences).
final patternsSettingsProvider = FutureProvider.autoDispose
    .family<PatternsSettings, String>((ref, userId) async {
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getPatternsSettings(userId);
});
