/// Today Score history — daily snapshots, persisted locally.
///
/// Phase 6. Stores one score per day in `SharedPreferences` (a rolling
/// ~90-day list — no Drift, no codegen) and tracks today's *baseline* (the
/// first score of the day) so the card can show momentum ("▲ 12 today").
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One day's recorded score.
@immutable
class ScoreDay {
  /// Local midnight of the day.
  final DateTime date;
  final int score;
  const ScoreDay(this.date, this.score);
}

/// Snapshot of the user's score history.
@immutable
class ScoreHistory {
  /// Ascending by date, up to 90 entries.
  final List<ScoreDay> days;

  /// The first score recorded today — the morning baseline. Null until the
  /// first record of the day.
  final int? todayBaseline;

  const ScoreHistory({this.days = const [], this.todayBaseline});

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// The latest score recorded today, or null if none yet.
  int? get todayScore {
    if (days.isEmpty) return null;
    final last = days.last;
    return _sameDay(last.date, DateTime.now()) ? last.score : null;
  }

  /// How much today's score has moved since this morning's first reading.
  int get todayDelta {
    final base = todayBaseline;
    final cur = todayScore;
    if (base == null || cur == null) return 0;
    return cur - base;
  }

  /// Average score over the last [n] recorded days (most recent), or null.
  int? recentAverage([int n = 7]) {
    if (days.isEmpty) return null;
    final slice = days.length <= n ? days : days.sublist(days.length - n);
    final sum = slice.fold<int>(0, (a, d) => a + d.score);
    return (sum / slice.length).round();
  }
}

class ScoreHistoryNotifier extends StateNotifier<ScoreHistory> {
  ScoreHistoryNotifier() : super(const ScoreHistory()) {
    _load();
  }

  static const _kDaysKey = 'today_score_history_v1';
  static const _kBaselineKey = 'today_score_baseline_v1';
  static const _maxDays = 90;

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kDaysKey) ?? const [];
      final days = <ScoreDay>[];
      for (final entry in raw) {
        final i = entry.lastIndexOf(':');
        if (i <= 0) continue;
        final date = DateTime.tryParse(entry.substring(0, i));
        final score = int.tryParse(entry.substring(i + 1));
        if (date != null && score != null) {
          days.add(ScoreDay(DateTime(date.year, date.month, date.day), score));
        }
      }
      days.sort((a, b) => a.date.compareTo(b.date));

      int? baseline;
      final b = prefs.getString(_kBaselineKey);
      if (b != null) {
        final i = b.lastIndexOf(':');
        if (i > 0 && b.substring(0, i) == _dayKey(DateTime.now())) {
          baseline = int.tryParse(b.substring(i + 1));
        }
      }
      if (mounted) {
        state = ScoreHistory(days: days, todayBaseline: baseline);
      }
    } catch (e) {
      debugPrint('⚠️ [ScoreHistory] load failed: $e');
    }
  }

  /// Record the latest score for today. The first call of the day also sets
  /// the day's baseline. A no-op when the score hasn't changed.
  Future<void> record(int score) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List<ScoreDay>.from(state.days);
    int? baseline = state.todayBaseline;

    final hasToday =
        days.isNotEmpty && ScoreHistory._sameDay(days.last.date, today);

    if (hasToday) {
      if (days.last.score == score) return; // unchanged — skip the write
      days[days.length - 1] = ScoreDay(today, score);
    } else {
      days.add(ScoreDay(today, score));
      baseline = score; // first reading of the day = the baseline
    }
    while (days.length > _maxDays) {
      days.removeAt(0);
    }

    state = ScoreHistory(days: days, todayBaseline: baseline);
    _persist(baseline);
  }

  Future<void> _persist(int? baseline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kDaysKey,
        state.days.map((d) => '${_dayKey(d.date)}:${d.score}').toList(),
      );
      if (baseline != null) {
        await prefs.setString(
            _kBaselineKey, '${_dayKey(DateTime.now())}:$baseline');
      }
    } catch (e) {
      debugPrint('⚠️ [ScoreHistory] persist failed: $e');
    }
  }
}

/// The score-history snapshot. The score card records into it and reads the
/// momentum delta from it.
final scoreHistoryProvider =
    StateNotifierProvider<ScoreHistoryNotifier, ScoreHistory>(
  (ref) => ScoreHistoryNotifier(),
);
