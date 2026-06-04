/// B9 — Streak-freeze status + streak timeframe providers.
///
/// Backs the refreshed streak UI (freeze chip with "next free freeze" copy),
/// the freeze-earned celebration, and the week/month/all timeframe sheet.
///
/// Endpoints (backend/api/v1/xp.py):
///   GET /xp/freeze-status     -> StreakFreezeStatus (also auto-earns)
///   GET /xp/streak-timeframe  -> StreakTimeframe
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

@immutable
class StreakFreezeLedgerEntry {
  final int delta; // +1 earned, -1 used
  final String reason; // auto_earn_10wk | manual_use | auto_protect | admin_gift
  final int balanceAfter;
  final int? streakDay;
  final String? eventDate;
  final String? createdAt;

  const StreakFreezeLedgerEntry({
    required this.delta,
    required this.reason,
    required this.balanceAfter,
    this.streakDay,
    this.eventDate,
    this.createdAt,
  });

  factory StreakFreezeLedgerEntry.fromJson(Map<String, dynamic> j) =>
      StreakFreezeLedgerEntry(
        delta: (j['delta'] as num?)?.toInt() ?? 0,
        reason: j['reason'] as String? ?? '',
        balanceAfter: (j['balance_after'] as num?)?.toInt() ?? 0,
        streakDay: (j['streak_day'] as num?)?.toInt(),
        eventDate: j['event_date'] as String?,
        createdAt: j['created_at'] as String?,
      );

  bool get isEarned => delta > 0;

  /// Human-readable label for the ledger row.
  String get label {
    switch (reason) {
      case 'auto_earn_10wk':
        return 'Earned a freeze';
      case 'manual_use':
        return 'Used a freeze';
      case 'auto_protect':
        return 'A freeze saved your streak';
      case 'admin_gift':
        return 'Freeze gifted';
      default:
        return isEarned ? 'Earned a freeze' : 'Used a freeze';
    }
  }
}

@immutable
class StreakFreezeStatus {
  final int freezesAvailable;
  final int currentStreak;
  final int freezesEarnedTotal;
  final int streakPerFreeze;
  final int streakUntilNextFreeze;
  final bool justEarnedFreeze;
  final List<StreakFreezeLedgerEntry> recentLedger;

  const StreakFreezeStatus({
    this.freezesAvailable = 0,
    this.currentStreak = 0,
    this.freezesEarnedTotal = 0,
    this.streakPerFreeze = 70,
    this.streakUntilNextFreeze = 70,
    this.justEarnedFreeze = false,
    this.recentLedger = const [],
  });

  factory StreakFreezeStatus.fromJson(Map<String, dynamic> j) =>
      StreakFreezeStatus(
        freezesAvailable: (j['freezes_available'] as num?)?.toInt() ?? 0,
        currentStreak: (j['current_streak'] as num?)?.toInt() ?? 0,
        freezesEarnedTotal: (j['freezes_earned_total'] as num?)?.toInt() ?? 0,
        streakPerFreeze: (j['streak_per_freeze'] as num?)?.toInt() ?? 70,
        streakUntilNextFreeze:
            (j['streak_until_next_freeze'] as num?)?.toInt() ?? 70,
        justEarnedFreeze: j['just_earned_freeze'] as bool? ?? false,
        recentLedger: ((j['recent_ledger'] as List?) ?? [])
            .map((e) =>
                StreakFreezeLedgerEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  /// Progress (0.0–1.0) toward the next auto-earned freeze.
  double get progressToNextFreeze {
    if (streakPerFreeze <= 0) return 0.0;
    final earnedWithin = streakPerFreeze - streakUntilNextFreeze;
    return (earnedWithin / streakPerFreeze).clamp(0.0, 1.0);
  }
}

@immutable
class StreakTimeframeDay {
  final String date;
  final bool active;
  final bool frozen;
  final bool isToday;

  const StreakTimeframeDay({
    required this.date,
    this.active = false,
    this.frozen = false,
    this.isToday = false,
  });

  factory StreakTimeframeDay.fromJson(Map<String, dynamic> j) =>
      StreakTimeframeDay(
        date: j['date'] as String? ?? '',
        active: j['active'] as bool? ?? false,
        frozen: j['frozen'] as bool? ?? false,
        isToday: j['is_today'] as bool? ?? false,
      );
}

@immutable
class StreakTimeframe {
  final String timeframe; // week | month | all
  final int currentStreak;
  final int longestStreak;
  final int activeDays;
  final int totalDays;
  final int freezesUsed;
  final List<StreakTimeframeDay> days;

  const StreakTimeframe({
    this.timeframe = 'week',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.activeDays = 0,
    this.totalDays = 0,
    this.freezesUsed = 0,
    this.days = const [],
  });

  factory StreakTimeframe.fromJson(Map<String, dynamic> j) => StreakTimeframe(
        timeframe: j['timeframe'] as String? ?? 'week',
        currentStreak: (j['current_streak'] as num?)?.toInt() ?? 0,
        longestStreak: (j['longest_streak'] as num?)?.toInt() ?? 0,
        activeDays: (j['active_days'] as num?)?.toInt() ?? 0,
        totalDays: (j['total_days'] as num?)?.toInt() ?? 0,
        freezesUsed: (j['freezes_used'] as num?)?.toInt() ?? 0,
        days: ((j['days'] as List?) ?? [])
            .map((e) =>
                StreakTimeframeDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Live freeze status. Calling this also runs the 10-week auto-earn server-side
/// (so the celebration can fire when `justEarnedFreeze` is true). autoDispose +
/// keepAlive so it's instant on revisit but refreshable.
final streakFreezeStatusProvider =
    FutureProvider.autoDispose<StreakFreezeStatus>((ref) async {
  final link = ref.keepAlive();
  ref.onDispose(link.close);
  final api = ref.read(apiClientProvider);
  try {
    final resp = await api.get('/xp/freeze-status');
    return StreakFreezeStatus.fromJson(
        Map<String, dynamic>.from(resp.data as Map));
  } catch (e) {
    debugPrint('🧊 [StreakFreeze] freeze-status failed: $e');
    return const StreakFreezeStatus();
  }
});

/// Streak timeframe (week | month | all) for the timeframe sheet.
final streakTimeframeProvider = FutureProvider.autoDispose
    .family<StreakTimeframe, String>((ref, timeframe) async {
  final api = ref.read(apiClientProvider);
  try {
    final resp = await api.get(
      '/xp/streak-timeframe',
      queryParameters: {'timeframe': timeframe},
    );
    return StreakTimeframe.fromJson(
        Map<String, dynamic>.from(resp.data as Map));
  } catch (e) {
    debugPrint('🧊 [StreakFreeze] streak-timeframe($timeframe) failed: $e');
    return StreakTimeframe(timeframe: timeframe);
  }
});
