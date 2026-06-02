import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// The user's habitual meal for a slot (Gap 16) — backs the proactive
/// "your usual?" surfacing in the meal nudge. Server-computed from 30-day
/// logging frequency (`GET /nutrition/usual-meal`). Null when there isn't
/// enough history for a confident usual.
@immutable
class UsualMeal {
  final String mealType;
  final String? label; // "Your usual (5x in last 30 days)"
  final String? summary; // comma-joined item names
  final int totalCalories;
  final List<String> itemNames;

  const UsualMeal({
    required this.mealType,
    this.label,
    this.summary,
    this.totalCalories = 0,
    this.itemNames = const [],
  });
}

/// Family keyed by meal slot ('breakfast'|'lunch'|'dinner'|'snack').
final usualMealProvider =
    FutureProvider.autoDispose.family<UsualMeal?, String>((ref, slot) async {
  ref.keepAlive();
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/nutrition/usual-meal',
      queryParameters: {'meal_type': slot},
    );
    final data = response.data ?? const {};
    if (data['found'] != true) return null;
    final names = (data['item_names'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    return UsualMeal(
      mealType: (data['meal_type'] as String?) ?? slot,
      label: data['label'] as String?,
      summary: data['summary'] as String?,
      totalCalories: (data['total_calories'] as num?)?.toInt() ?? 0,
      itemNames: names,
    );
  } catch (e) {
    debugPrint('❌ [UsualMealProvider] $slot: $e');
    return null;
  }
});
