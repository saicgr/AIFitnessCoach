/// Pre-warms Home tab data not already covered by `BootstrapPrefetchService`
/// or `YouOverviewPrewarmer`.
///
/// Bootstrap already handles: today_workout, nutrition summary, hydration, XP,
/// active gym profile.
/// YouOverviewPrewarmer already handles: xp + trophies + streaks.
///
/// What's left for first-render of Home that fetches network data:
///   • `workoutsProvider` — week carousel
///   • `consistencyProvider` — streak + consistency card
///
/// Also opportunistically precaches the top hero workout illustration so the
/// hero card paints with no image flash. Coordinates with WorkoutsPrewarmer
/// via [WorkoutsPrewarmer.noteWorkoutsProviderWarmed] to avoid double-fetching.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

// Provider symbols are used dynamically through the duck-typed `ref` param;
// no flutter_riverpod import needed in this file. The provider imports below
// ARE required — even with dynamic `ref`, the provider identifiers
// (apiClientProvider, workoutsProvider, consistencyProvider) are resolved at
// compile time by Dart.
import '../providers/consistency_provider.dart';
import '../repositories/workout_repository.dart';
import 'api_client.dart';
import 'workouts_prewarmer.dart';

DateTime? _lastWarmedAt;
Completer<void>? _inFlight;

const Duration _staleAfter = Duration(minutes: 5);

class HomePrewarmer {
  /// No own disk cache — workoutsProvider already manages its own
  /// DataCacheService-backed disk cache, and consistencyProvider has its own
  /// in-memory cache. Kept as a no-op for boot-orchestrator symmetry.
  static Future<void> hydrateFromDisk() async {
    // Intentionally a no-op.
  }

  static Future<void> clearAll() async {
    _lastWarmedAt = null;
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
        debugPrint('🔍 [HomePrewarmer] no userId yet — skipping');
        return;
      }

      debugPrint('🏠 [HomePrewarmer] warming for $userId');

      final futures = <Future<void>>[];

      // workoutsProvider — also wanted by WorkoutsPrewarmer. Tell it we're
      // warming so it skips the duplicate fetch within the next 60s window.
      try {
        futures.add(
          ref
              .read(workoutsProvider.notifier)
              .refresh()
              .catchError((e) {
            debugPrint('⚠️ [HomePrewarmer] workoutsProvider failed: $e');
          }),
        );
        WorkoutsPrewarmer.noteWorkoutsProviderWarmed();
      } catch (e) {
        debugPrint('⚠️ [HomePrewarmer] workoutsProvider read error: $e');
      }

      // consistencyProvider — refresh fetches /consistency/summary.
      try {
        futures.add(
          ref
              .read(consistencyProvider.notifier)
              .refresh(userId: userId)
              .catchError((e) {
            debugPrint('⚠️ [HomePrewarmer] consistencyProvider failed: $e');
          }),
        );
      } catch (e) {
        debugPrint('⚠️ [HomePrewarmer] consistencyProvider read error: $e');
      }

      await Future.wait(futures, eagerError: false);

      // Best-effort hero image precache — pull the top workout's illustration
      // URL out of the just-refreshed workouts state and prime Flutter's
      // ImageCache. If anything goes wrong (no workouts yet, no URL field,
      // no navigator context), silently skip — the carousel will load the
      // image normally on first paint.
      try {
        await _precacheHeroImage(ref);
      } catch (_) {}

      _lastWarmedAt = DateTime.now();
      debugPrint('✅ [HomePrewarmer] warmed ${futures.length} provider(s)');
    } catch (e, st) {
      debugPrint('⚠️ [HomePrewarmer] warm failed: $e\n$st');
    } finally {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Pre-decode the top hero workout illustration into Flutter's ImageCache so
  /// the hero card paints with zero image flash. Best-effort: needs a live
  /// BuildContext (via [WidgetsBinding.instance.rootElement]); if the app
  /// hasn't built its first frame yet, we skip and let the carousel handle
  /// the image lazily.
  static Future<void> _precacheHeroImage(dynamic ref) async {
    // Pull the workouts list — it was just refreshed above.
    final workoutsAsync = ref.read(workoutsProvider);
    final workouts = workoutsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => null,
    );
    if (workouts == null || workouts.isEmpty) return;

    // Best-effort URL extraction. Workout model varies — try common fields.
    String? url;
    final first = workouts.first;
    try {
      // Try via toJson() to avoid hard-coding field names.
      final json = (first as dynamic).toJson() as Map<String, dynamic>?;
      url = (json?['illustration_url'] as String?) ??
          (json?['hero_image_url'] as String?) ??
          (json?['image_url'] as String?);
    } catch (_) {
      // Workout type doesn't expose toJson — skip silently.
      return;
    }
    if (url == null || url.isEmpty) return;

    final ctx = WidgetsBinding.instance.rootElement;
    if (ctx == null) return;

    try {
      await precacheImage(NetworkImage(url), ctx);
      debugPrint('🖼️ [HomePrewarmer] hero image precached');
    } catch (e) {
      debugPrint('⚠️ [HomePrewarmer] precacheImage failed: $e');
    }
  }

  static Future<void> invalidateAndRefresh(dynamic ref) async {
    _lastWarmedAt = null;
    await warm(ref, force: true);
  }
}
