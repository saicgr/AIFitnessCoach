import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// A protein/carbs/fat triple in grams — the unit the recommendation contract
/// uses for the daily target, every per-meal split row, and the per-day
/// high/base macro sets. Calories are carried separately on [DailyRec] only.
class MacroTriple {
  final int proteinG;
  final int carbsG;
  final int fatG;

  const MacroTriple({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  /// Parses `{protein_g, carbs_g, fat_g}`. Tolerant of missing keys (→ 0) but
  /// never invents — a fully-absent block yields a 0/0/0 triple the caller can
  /// detect via [isEmpty].
  factory MacroTriple.fromJson(Map<String, dynamic> json) {
    int g(String k) {
      final v = json[k];
      if (v is num) return v.round();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return MacroTriple(
      proteinG: g('protein_g'),
      carbsG: g('carbs_g'),
      fatG: g('fat_g'),
    );
  }

  bool get isEmpty => proteinG == 0 && carbsG == 0 && fatG == 0;
}

/// The whole-day calorie + macro recommendation, plus the user's CURRENT
/// targets (so the sheet can render up/down/same delta chips) and the coach's
/// reasoning. Mirrors the backend `daily` block exactly.
class DailyRec {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  /// The user's current targets, echoed back by the backend so the delta chips
  /// don't depend on a second read. Null only on a malformed payload.
  final int? currentCalories;
  final int? currentProteinG;
  final int? currentCarbsG;
  final int? currentFatG;

  /// The coach's "why" for these daily numbers (Fraunces line in the UI).
  final String reasoning;

  const DailyRec({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.currentCalories,
    required this.currentProteinG,
    required this.currentCarbsG,
    required this.currentFatG,
    required this.reasoning,
  });

  factory DailyRec.fromJson(Map<String, dynamic> json) {
    int g(String k) {
      final v = json[k];
      if (v is num) return v.round();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int? gn(Map<String, dynamic>? m, String k) {
      final v = m?[k];
      if (v is num) return v.round();
      if (v is String) return int.tryParse(v);
      return null;
    }

    final current = json['current'] is Map
        ? Map<String, dynamic>.from(json['current'] as Map)
        : null;

    return DailyRec(
      calories: g('calories'),
      proteinG: g('protein_g'),
      carbsG: g('carbs_g'),
      fatG: g('fat_g'),
      currentCalories: gn(current, 'calories'),
      currentProteinG: gn(current, 'protein_g'),
      currentCarbsG: gn(current, 'carbs_g'),
      currentFatG: gn(current, 'fat_g'),
      reasoning: (json['reasoning'] as String?)?.trim() ?? '',
    );
  }
}

/// The per-meal split recommendation: a macro triple per meal id
/// (`breakfast`/`lunch`/`dinner`/`snacks`, whatever the user's meal pattern
/// has) plus whether the AI suggests enabling the per-meal feature.
class PerMealRec {
  /// True when the AI thinks the user benefits from a per-meal split.
  final bool enabledSuggested;

  /// meal id → recommended {protein_g, carbs_g, fat_g}. Order preserved.
  final Map<String, MacroTriple> meals;

  final String reasoning;

  const PerMealRec({
    required this.enabledSuggested,
    required this.meals,
    required this.reasoning,
  });

  factory PerMealRec.fromJson(Map<String, dynamic> json) {
    final meals = <String, MacroTriple>{};
    final rawMeals = json['meals'];
    if (rawMeals is Map) {
      rawMeals.forEach((mealId, vals) {
        if (mealId is String && vals is Map) {
          meals[mealId] = MacroTriple.fromJson(Map<String, dynamic>.from(vals));
        }
      });
    }
    return PerMealRec(
      enabledSuggested: json['enabled_suggested'] == true,
      meals: meals,
      reasoning: (json['reasoning'] as String?)?.trim() ?? '',
    );
  }

  bool get isEmpty => meals.isEmpty;
}

/// The per-day (high/base) recommendation: which weekdays are "high" (carb-up /
/// training days), the high + base macro sets, and whether the AI suggests
/// binding the high days to the user's training schedule.
class PerDayRec {
  final bool enabledSuggested;

  /// When true, the high days follow the user's workout schedule rather than
  /// the explicit [highDays] list.
  final bool bindToTrainingDays;

  /// High weekdays as Python weekday ints (0 = Mon … 6 = Sun) — matches the
  /// backend dynamic-targets compare and `gym_profiles.workout_days`.
  final List<int> highDays;

  final MacroTriple high;
  final MacroTriple base;

  final String reasoning;

  const PerDayRec({
    required this.enabledSuggested,
    required this.bindToTrainingDays,
    required this.highDays,
    required this.high,
    required this.base,
    required this.reasoning,
  });

  factory PerDayRec.fromJson(Map<String, dynamic> json) {
    final highDays = <int>[];
    final rawDays = json['high_days'];
    if (rawDays is List) {
      for (final d in rawDays) {
        if (d is num) highDays.add(d.toInt());
      }
    }
    MacroTriple triple(String key) {
      final v = json[key];
      if (v is Map) {
        return MacroTriple.fromJson(Map<String, dynamic>.from(v));
      }
      return const MacroTriple(proteinG: 0, carbsG: 0, fatG: 0);
    }

    return PerDayRec(
      enabledSuggested: json['enabled_suggested'] == true,
      bindToTrainingDays: json['bind_to_training_days'] == true,
      highDays: highDays,
      high: triple('high'),
      base: triple('base'),
      reasoning: (json['reasoning'] as String?)?.trim() ?? '',
    );
  }

  bool get isEmpty => high.isEmpty && base.isEmpty;
}

/// The full AI "Recommend Targets" response. Mirrors EXACTLY the JSON the
/// backend returns from `POST /nutrition/ai-recommend-targets`, so the preview
/// sheet stays presentation-only and the contract lives in one place.
///
/// Per project rule `feedback_no_silent_fallbacks`, the repository never
/// fabricates this — a failed fetch throws and the sheet surfaces a retry.
class NutritionTargetsRecommendation {
  /// `"high"` | `"medium"` | `"low"`. Low usually means the backend fell back
  /// to a deterministic recommendation (model unavailable / too little data).
  final String confidence;

  /// One-line "based on …" summary (days analyzed, weight trend, training days).
  final String basis;

  final DailyRec daily;
  final PerMealRec perMeal;
  final PerDayRec perDay;

  /// Human notes for any value the backend floored/ceilinged to a safe range,
  /// e.g. "Fat was raised to 50g — below the essential-fat floor for your
  /// weight". Empty when nothing was clamped.
  final List<String> clamped;

  final String generatedAt;
  final bool cached;

  const NutritionTargetsRecommendation({
    required this.confidence,
    required this.basis,
    required this.daily,
    required this.perMeal,
    required this.perDay,
    required this.clamped,
    required this.generatedAt,
    required this.cached,
  });

  factory NutritionTargetsRecommendation.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    Map<String, dynamic> section(String key) {
      final v = json[key];
      if (v is Map) return Map<String, dynamic>.from(v);
      return const <String, dynamic>{};
    }

    return NutritionTargetsRecommendation(
      confidence: (json['confidence'] as String?)?.trim().toLowerCase() ?? 'medium',
      basis: (json['basis'] as String?)?.trim() ?? '',
      daily: DailyRec.fromJson(section('daily')),
      perMeal: PerMealRec.fromJson(section('per_meal')),
      perDay: PerDayRec.fromJson(section('per_day')),
      clamped: stringList(json['clamped']),
      generatedAt: (json['generated_at'] as String?)?.trim() ?? '',
      cached: json['cached'] == true,
    );
  }
}

/// Repository wrapping the on-demand AI target-recommendation fetch. Uses the
/// same [ApiClient] / Dio pattern as `ProgressAnalysisRepository` so auth, base
/// URL and the `user_id` source all match the rest of the AI features.
class AiTargetRecommendationRepository {
  final ApiClient _api;

  const AiTargetRecommendationRepository(this._api);

  /// Fetches (and, server-side, caches) the AI target recommendation.
  ///
  /// - [contextWindowDays] how many days of logs to analyze (default 14).
  /// - [force] true bypasses the server cache to regenerate fresh.
  ///
  /// Throws on any failure (not signed in, network, malformed body) — the
  /// sheet surfaces the error with a retry. No silent fallback to fake data.
  Future<NutritionTargetsRecommendation> fetchRecommendation({
    int contextWindowDays = 14,
    bool force = false,
  }) async {
    final userId = await _api.getUserId();
    if (userId == null) {
      throw Exception('Not signed in');
    }

    final res = await _api.post(
      '/nutrition/ai-recommend-targets',
      data: <String, dynamic>{
        'user_id': userId,
        'context_window_days': contextWindowDays,
        'force': force,
      },
      options: Options(
        // On-demand AI generation can take several seconds; give it room.
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    final data = res.data;
    if (res.statusCode == 200 && data is Map) {
      return NutritionTargetsRecommendation.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    throw Exception('Could not build your recommendation');
  }
}

/// Provider for the [AiTargetRecommendationRepository] (one per [ApiClient]).
final aiTargetRecommendationRepositoryProvider =
    Provider<AiTargetRecommendationRepository>((ref) {
  return AiTargetRecommendationRepository(ref.watch(apiClientProvider));
});
