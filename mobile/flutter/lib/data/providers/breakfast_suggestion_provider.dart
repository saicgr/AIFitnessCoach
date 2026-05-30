/// Meal-slot suggestion provider — was `breakfastSuggestionProvider`,
/// generalised into a `family<MealSlot>` so lunch + dinner reuse the same
/// code path. Backed by `/api/v1/coach/daily-insight` with a per-slot
/// `source` discriminator that routes to a dedicated prompt branch in
/// `backend/services/gemini/daily_insight_prompt.py`.
///
/// CACHING
/// - Backend persists per `(user_id, local_date, source, stat_context)`,
///   server-side dedup is free.
/// - Client in-memory TTL of 4 hours keyed by `(slot, userId, YYYY-MM-DD)`,
///   scoped to provider lifetime via `autoDispose` + `keepAlive()`. Refetch
///   later in the slot window picks up new RAG signal from food logs.
///
/// FALLBACK
/// - On network error / missing session / pre-tz-init / no server branch
///   yet for this slot, returns a [DailyCoachInsight] carrying the
///   deterministic per-slot copy with `isFallback=true`. The UI never
///   blocks on the network.
///
/// MIGRATION NOTE
/// - The legacy `breakfastSuggestionProvider` symbol is kept as an alias
///   pointing at `mealSlotSuggestionProvider(MealSlot.breakfast)` so call
///   sites that haven't been migrated keep compiling. New code should use
///   the family directly.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/providers/timezone_provider.dart';
import '../services/api_client.dart';
import 'daily_coach_insight_provider.dart';

/// Which meal slot a suggestion targets. Maps 1:1 to the `meal_type` value
/// stored on `food_logs` rows.
enum MealSlot {
  breakfast,
  lunch,
  dinner,
}

extension MealSlotX on MealSlot {
  /// String value stored on `food_logs.meal_type`.
  String get mealType {
    switch (this) {
      case MealSlot.breakfast:
        return 'breakfast';
      case MealSlot.lunch:
        return 'lunch';
      case MealSlot.dinner:
        return 'dinner';
    }
  }

  /// Source discriminator the backend's `daily_insight.py` accepts. All
  /// three slots route to dedicated prompt branches in
  /// `services/gemini/daily_insight_prompt.py` (lunch + dinner branches
  /// shipped alongside this client change).
  String? get serverSource {
    switch (this) {
      case MealSlot.breakfast:
        return 'nutrition_card_morning';
      case MealSlot.lunch:
        return 'nutrition_card_lunch';
      case MealSlot.dinner:
        return 'nutrition_card_dinner';
    }
  }
}

/// Deterministic per-slot fallback copy. Mirrors the macro framing the
/// original `_BreakfastSlotRow` used. Lunch + dinner targets are sized to
/// roughly half-day balance (breakfast nudges toward energy start, lunch
/// toward sustained protein, dinner toward recovery + lower carbs).
String mealSlotFallbackBody(MealSlot slot) {
  switch (slot) {
    case MealSlot.breakfast:
      return 'Aim 30g protein + 50g carbs.';
    case MealSlot.lunch:
      return 'Aim 35g protein + 60g carbs.';
    case MealSlot.dinner:
      return 'Aim 35g protein + 30g carbs.';
  }
}

String mealSlotFallbackHeadline(MealSlot slot) {
  switch (slot) {
    case MealSlot.breakfast:
      return 'Breakfast suggestion';
    case MealSlot.lunch:
      return 'Lunch suggestion';
    case MealSlot.dinner:
      return 'Dinner suggestion';
  }
}

/// Legacy alias — kept so existing call sites keep compiling while the
/// migration to `mealSlotSuggestionProvider` proceeds. Delete when the
/// nutrition card stops rendering `_BreakfastSlotRow` (Phase 2).
const String kBreakfastSuggestionFallbackBody = 'Aim 30g protein + 50g carbs.';

/// In-memory TTL cache. Key = `${slot.name}|${userId}|${YYYY-MM-DD}`.
const Duration _kMealInsightTtl = Duration(hours: 4);
final Map<String, _CachedInsight> _kMealInsightCache = {};

class _CachedInsight {
  final DateTime fetchedAt;
  final DailyCoachInsight insight;
  _CachedInsight(this.fetchedAt, this.insight);
}

/// Per-slot meal suggestion for today, user-local. `autoDispose` so it's
/// released when the home tab is left; the module-level cache holds the
/// last value, so re-subscribing is cheap.
final mealSlotSuggestionProvider =
    FutureProvider.autoDispose.family<DailyCoachInsight, MealSlot>(
  (ref, slot) async {
    // Keep alive so leaving/returning Home doesn't tear this down and refetch.
    ref.keepAlive();
    final tzState = ref.watch(timezoneProvider);
    if (tzState.isLoading) {
      return _fallback(slot);
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return _fallback(slot);
    }

    // Backend branch not shipped for this slot → return deterministic
    // fallback without burning a network call.
    final serverSource = slot.serverSource;
    if (serverSource == null) {
      return _fallback(slot);
    }

    final now = DateTime.now();
    final dateString =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final cacheKey = '${slot.name}|${session.user.id}|$dateString';

    final cached = _kMealInsightCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _kMealInsightTtl) {
      return cached.insight;
    }

    final api = ref.read(apiClientProvider);
    try {
      // Path is `/coach/daily-insight` (NOT `/api/v1/coach/daily-insight`) —
      // the api client baseUrl already carries `/api/v1`.
      final res = await api.get<Map<String, dynamic>>(
        '/coach/daily-insight',
        queryParameters: {
          'date': dateString,
          'tz': tzState.timezone,
          'source': serverSource,
        },
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return _fallback(slot);
      }
      final insight = DailyCoachInsight.fromJson(data);
      // Only cache real server responses — a fallback shouldn't poison the
      // cache and prevent a real retry on the next render.
      if (!insight.isFallback && insight.body.trim().isNotEmpty) {
        _kMealInsightCache[cacheKey] =
            _CachedInsight(DateTime.now(), insight);
      }
      return insight;
    } catch (_) {
      return _fallback(slot);
    }
  },
);

/// Legacy provider alias. New code should call
/// `mealSlotSuggestionProvider(MealSlot.breakfast)` directly.
final breakfastSuggestionProvider =
    FutureProvider.autoDispose<DailyCoachInsight>((ref) {
  return ref.watch(mealSlotSuggestionProvider(MealSlot.breakfast).future);
});

DailyCoachInsight _fallback(MealSlot slot) => DailyCoachInsight(
      headline: mealSlotFallbackHeadline(slot),
      body: mealSlotFallbackBody(slot),
      leadingPillar: 'nourish',
      isFallback: true,
    );
