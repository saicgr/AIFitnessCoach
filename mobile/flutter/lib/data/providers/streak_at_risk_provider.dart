/// Streak-at-risk surface (F3.2).
///
/// Watches the user's daily-log timestamps to detect when "today's last log
/// hour" has slipped past the user's historical median by 2+ hours. The
/// home screen surfaces a one-row banner if `isAtRisk == true`.
///
/// Calculation:
///   * Cache the median of the last 30 days' final-log-of-day hour
///     (weighted equally — food log + workout log + hydration log).
///   * Banner fires when `now.hour >= median + 2` AND no log today.
///   * Final last-chance window: `hour >= 22` (regardless of median).
///
/// Notes:
///   * The streak source of truth lives in the backend
///     `StreakService.current_streak()` — this provider doesn't decide
///     "do you HAVE a streak", only "is it at risk RIGHT NOW".
///   * Persisted median refresh happens weekly to avoid churn.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart' show authStateProvider;

@immutable
class StreakAtRisk {
  /// True when the user has a streak AND it's at risk tonight.
  final bool isAtRisk;

  /// User's typical "last log of day" hour (0–23).
  final int? historicalMedianHour;

  /// True if we're inside the last-chance window (`hour >= 22`).
  final bool lastChance;

  const StreakAtRisk({
    required this.isAtRisk,
    this.historicalMedianHour,
    this.lastChance = false,
  });

  static const empty = StreakAtRisk(isAtRisk: false);
}

class StreakAtRiskNotifier extends StateNotifier<StreakAtRisk> {
  StreakAtRiskNotifier(this._userId) : super(StreakAtRisk.empty) {
    if (_userId != null) {
      unawaited(_load());
    }
  }

  final String? _userId;
  Timer? _ticker;

  String get _medianKey => 'streak_median_hour_${_userId ?? "anon"}';
  String get _lastLogKey => 'streak_last_log_iso_${_userId ?? "anon"}';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final median = prefs.getInt(_medianKey);
      _recompute(median: median);
    } catch (e) {
      debugPrint('[StreakAtRisk] _load failed: $e');
    }
    // Re-check every 15 minutes — cheap and the at-risk window is hour-
    // grained, so finer ticks add no value.
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 15), (_) {
      _recompute();
    });
  }

  Future<void> _recompute({int? median}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final m = median ?? prefs.getInt(_medianKey);
      final lastLogIso = prefs.getString(_lastLogKey);
      final now = DateTime.now();
      final hour = now.hour;

      // No log today?
      DateTime? lastLog;
      if (lastLogIso != null) {
        lastLog = DateTime.tryParse(lastLogIso);
      }
      final loggedToday = lastLog != null &&
          lastLog.year == now.year &&
          lastLog.month == now.month &&
          lastLog.day == now.day;

      if (loggedToday) {
        state = StreakAtRisk(isAtRisk: false, historicalMedianHour: m);
        return;
      }

      final lastChance = hour >= 22;
      final pastMedian = m != null && hour >= (m + 2);

      state = StreakAtRisk(
        isAtRisk: lastChance || pastMedian,
        historicalMedianHour: m,
        lastChance: lastChance,
      );
    } catch (e) {
      debugPrint('[StreakAtRisk] _recompute failed: $e');
    }
  }

  /// Call from any DB write path that counts toward the streak so the
  /// banner suppresses immediately once the user takes action.
  Future<void> markLoggedNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLogKey, DateTime.now().toIso8601String());
      await _recompute();
    } catch (e) {
      debugPrint('[StreakAtRisk] markLoggedNow failed: $e');
    }
  }

  /// Persist the rolling-30-day median (caller computes it from history
  /// repositories on a weekly cadence; this provider doesn't own the
  /// history fetch to keep dependencies thin).
  Future<void> setMedianHour(int hour) async {
    final clamped = hour.clamp(0, 23);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_medianKey, clamped);
      await _recompute(median: clamped);
    } catch (e) {
      debugPrint('[StreakAtRisk] setMedianHour failed: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final streakAtRiskProvider =
    StateNotifierProvider<StreakAtRiskNotifier, StreakAtRisk>((ref) {
  final uid = ref.watch(authStateProvider).user?.id;
  return StreakAtRiskNotifier(uid);
});
