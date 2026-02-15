import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../repositories/nutrition_repository.dart';

/// Provider for weekly summary data (days logged, avg calories/protein, weight change)
final weeklySummaryProvider =
    FutureProvider.autoDispose.family<WeeklySummaryData?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return repo.getWeeklySummary(userId);
  },
);

/// Provider for detailed TDEE with confidence intervals
final detailedTDEEProvider =
    FutureProvider.autoDispose.family<DetailedTDEE?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return repo.getDetailedTDEE(userId);
  },
);

/// Provider for adherence summary with sustainability score
final adherenceSummaryProvider =
    FutureProvider.autoDispose.family<AdherenceSummary?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return repo.getAdherenceSummary(userId);
  },
);

/// Provider for weekly nutrition data with daily breakdown (for charts)
final weeklyNutritionProvider =
    FutureProvider.autoDispose.family<WeeklyNutritionData?, String>(
  (ref, userId) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return repo.getWeeklyNutrition(userId);
  },
);
