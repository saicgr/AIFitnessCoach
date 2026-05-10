/// Pre-warms the Workouts tab so first navigation renders the history grid +
/// week summary instantly.
///
/// Uses Riverpod's container as the cache (the underlying providers —
/// `workoutsProvider`, `workoutScreenSummaryProvider`, `todayWorkoutProvider`
/// — already have their own in-memory + disk caches via `DataCacheService`).
/// Pre-warming here just forces the providers to refresh post-sign-in so the
/// data is fresh by the time the user taps the tab.
///
/// Coordinates with `HomePrewarmer` to avoid double-fetching `workoutsProvider`
/// — both tabs want it warm. We track the last warm time and skip if Home
/// already warmed it within 60s.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/workout_repository.dart';
import 'api_client.dart';

DateTime? _lastWarmedAt;
DateTime? _workoutsProviderLastWarmedAt;
Completer<void>? _inFlight;

const Duration _staleAfter = Duration(minutes: 5);
const Duration _workoutsProviderDedupWindow = Duration(seconds: 60);

class WorkoutsPrewarmer {
  /// No disk persistence here — `workoutsProvider` and `todayWorkoutProvider`
  /// already manage their own DataCacheService-backed disk caches. Kept for
  /// API symmetry with the other prewarmers.
  static Future<void> hydrateFromDisk() async {
    // Intentionally a no-op.
  }

  static Future<void> clearAll() async {
    _lastWarmedAt = null;
    _workoutsProviderLastWarmedAt = null;
  }

  /// Mark `workoutsProvider` as just warmed by an external caller (Home
  /// prewarmer). [WorkoutsPrewarmer.warm] then skips the workoutsProvider
  /// refresh if this was set recently. Saves one duplicate
  /// `GET /workouts/?user_id=...` call per sign-in.
  static void noteWorkoutsProviderWarmed() {
    _workoutsProviderLastWarmedAt = DateTime.now();
  }

  static Future<void> warm(dynamic ref, {bool force = false}) async {
    if (!force &&
        _lastWarmedAt != null &&
        DateTime.now().difference(_lastWarmedAt!) < _staleAfter) {
      return;
    }

    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _inFlight = completer;

    try {
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        debugPrint('🔍 [WorkoutsPrewarmer] no userId yet — skipping');
        return;
      }

      debugPrint('🏋️ [WorkoutsPrewarmer] warming for $userId');

      final futures = <Future<dynamic>>[];

      // workoutsProvider — skip if Home already warmed within 60s.
      final wpAge = _workoutsProviderLastWarmedAt == null
          ? Duration(days: 1)
          : DateTime.now().difference(_workoutsProviderLastWarmedAt!);
      if (force || wpAge > _workoutsProviderDedupWindow) {
        try {
          futures.add(
            ref.read(workoutsProvider.notifier).refresh().catchError((e) {
              debugPrint('⚠️ [WorkoutsPrewarmer] workoutsProvider failed: $e');
            }),
          );
          _workoutsProviderLastWarmedAt = DateTime.now();
        } catch (e) {
          debugPrint('⚠️ [WorkoutsPrewarmer] workoutsProvider read error: $e');
        }
      } else {
        debugPrint(
          '⏭️ [WorkoutsPrewarmer] workoutsProvider skipped '
          '(warmed ${wpAge.inSeconds}s ago by Home)',
        );
      }

      // workoutScreenSummaryProvider is now derived from workoutsProvider —
      // no separate fetch needed. The workoutsProvider warm above hydrates it.

      await Future.wait(futures, eagerError: false);

      _lastWarmedAt = DateTime.now();
      debugPrint('✅ [WorkoutsPrewarmer] warmed ${futures.length} provider(s)');
    } catch (e, st) {
      debugPrint('⚠️ [WorkoutsPrewarmer] warm failed: $e\n$st');
    } finally {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  static Future<void> invalidateAndRefresh(dynamic ref) async {
    _lastWarmedAt = null;
    _workoutsProviderLastWarmedAt = null;
    // screen summary is derived from workoutsProvider, no separate invalidate.
    await warm(ref, force: true);
  }
}
