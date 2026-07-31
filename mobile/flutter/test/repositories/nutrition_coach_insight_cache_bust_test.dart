// E2E register #131 — the Home coach card said "0g of protein" 8 minutes
// after a 601g meal landed. Root cause: `spliceRawLog`/`spliceLog` (the
// food-log CREATE paths) never busted the client's coach-insight disk cache
// (12h TTL, DataCacheService.coachInsightKey) the way `deleteLog` already
// did — so the first Coach open after logging painted stale pre-log prose.
//
// This test proves the CREATE path now busts the cache too. It is
// negative-tested: reverting the `_bustCoachInsightCaches(userId)` call added
// to `spliceRawLog` in
// lib/data/repositories/nutrition_repository_part_food_logging_progress.dart
// makes this test fail (see PR description / task report for the actual
// failing-test output captured before the fix landed).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/models/nutrition.dart';
import 'package:fitwiz/data/repositories/nutrition_repository.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/data/services/data_cache_service.dart';

import '../helpers/test_helpers.dart';

/// Pumps the microtask/timer queue enough times for the fire-and-forget
/// `unawaited(_bustCoachInsightCaches(...))` calls (a `Future.wait` over four
/// `SharedPreferences`-backed removes) to actually resolve before we assert.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-131';

  setUp(() {
    setUpMocks();
    SharedPreferences.setMockInitialValues({});
  });

  /// Primes all four coach-insight-family disk caches for [userId] so a
  /// test can assert they were (or weren't) cleared afterward.
  Future<void> primeCoachInsightCaches() async {
    final cache = DataCacheService.instance;
    for (final key in [
      DataCacheService.coachInsightKey,
      DataCacheService.chatMorningBriefKey,
      DataCacheService.chatEveningRecapKey,
      DataCacheService.chatGreetingKey,
    ]) {
      await cache.cache(key, {'headline': 'stale pre-log prose'}, userId: userId);
    }
  }

  Future<bool> anyCoachInsightCacheStillPresent() async {
    final cache = DataCacheService.instance;
    for (final key in [
      DataCacheService.coachInsightKey,
      DataCacheService.chatMorningBriefKey,
      DataCacheService.chatEveningRecapKey,
      DataCacheService.chatGreetingKey,
    ]) {
      if (await cache.getCached(key, userId: userId) != null) return true;
    }
    return false;
  }

  ProviderContainer buildContainer() {
    final mockApiClient = MockApiClient();
    final container = ProviderContainer(overrides: [
      nutritionRepositoryProvider.overrideWithValue(
        NutritionRepository(mockApiClient),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('E2E #131 — food-log CREATE busts the coach-insight cache', () {
    test('spliceRawLog (recipe / menu / buffet log) busts every coach-insight cache', () async {
      await primeCoachInsightCaches();
      expect(await anyCoachInsightCacheStillPresent(), isTrue,
          reason: 'precondition: caches must be primed before the create');

      final container = buildContainer();
      final notifier = container.read(
        dailyNutritionProvider(todayNutritionKey()).notifier,
      );

      final newLog = FoodLog(
        id: 'log-1',
        userId: userId,
        mealType: 'dinner',
        loggedAt: DateTime.now(),
        foodItems: const [],
        totalCalories: 601,
        proteinG: 60.1,
        createdAt: DateTime.now(),
      );

      // This is the CREATE chokepoint — a recipe log, a browser-panel relog,
      // or (via spliceMenuItem, which delegates to spliceRawLog) a
      // menu/buffet item tick-off.
      notifier.spliceRawLog(newLog, userId);

      await _settle();

      expect(await anyCoachInsightCacheStillPresent(), isFalse,
          reason: 'a food-log CREATE must bust the coach-insight cache '
              '(register #131) — the stale 12h-TTL body must not survive a new log');
    });

    test('spliceLog (direct photo/text log confirm) busts every coach-insight cache', () async {
      await primeCoachInsightCaches();
      expect(await anyCoachInsightCacheStillPresent(), isTrue);

      final container = buildContainer();
      final notifier = container.read(
        dailyNutritionProvider(todayNutritionKey()).notifier,
      );

      final response = LogFoodResponse.fromJson(const {
        'success': true,
        'food_log_id': 'log-2',
        'food_items': <dynamic>[],
        'total_calories': 601,
        'protein_g': 60.1,
      });

      notifier.spliceLog(response, 'dinner', userId);

      await _settle();

      expect(await anyCoachInsightCacheStillPresent(), isFalse,
          reason: 'the direct log-confirm CREATE path must also bust the '
              'coach-insight cache — this was the exact path in the register '
              '#131 repro (a photo/text meal log)');
    });

    test('control: a plain summary load with no write does NOT bust the cache', () async {
      // Guards against a trivially-passing test (e.g. accidentally clearing
      // the cache in setUp). Loading the summary without logging anything
      // must leave a primed cache alone.
      await primeCoachInsightCaches();

      final container = buildContainer();
      final notifier = container.read(
        dailyNutritionProvider(todayNutritionKey()).notifier,
      );
      // Touch state without performing a create/delete/edit.
      // ignore: invalid_use_of_protected_member
      notifier.state;

      await _settle();

      expect(await anyCoachInsightCacheStillPresent(), isTrue,
          reason: 'merely reading state must never bust the cache — only a '
              'genuine write should');
    });
  });
}
