import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/api_client.dart';

/// Captures the current user's fitness-profile snapshot once per day.
///
/// Replaces the external cron: when the app opens we fire a fire-and-forget
/// POST that upserts today's row. SharedPreferences debounces so repeat
/// opens on the same calendar day don't re-fire the endpoint.
///
/// Inactive users (never open the app) never get snapshots — which is fine
/// because they're also not on leaderboards; nobody taps them.
class FitnessSnapshotService {
  FitnessSnapshotService(this._ref);

  final Ref _ref;
  static const _prefsKey = 'fitness_snapshot_last_date';

  /// Call on app-open after auth is confirmed. Safe to call multiple times —
  /// the SharedPreferences check makes this a no-op after the first call
  /// each day. Never throws; failures only log.
  Future<void> ensureToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_prefsKey);
      final today = _todayStr();
      if (last == today) return; // already snapshotted today

      final client = _ref.read(apiClientProvider);
      await client.post('/users/me/fitness-snapshot');
      await prefs.setString(_prefsKey, today);
      if (kDebugMode) debugPrint('📸 [FitnessSnapshot] captured for $today');
    } catch (e) {
      // Non-fatal — snapshots are retention data, not critical path.
      if (kDebugMode) debugPrint('⚠️ [FitnessSnapshot] ensureToday failed: $e');
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

final fitnessSnapshotServiceProvider = Provider<FitnessSnapshotService>(
  (ref) => FitnessSnapshotService(ref),
);
