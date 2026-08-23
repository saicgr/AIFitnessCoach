import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today's calendar day (date-only, local time) as a watchable value.
///
/// `DateTime.now()` read once inside a `build()` is only ever as fresh as
/// the widget's last rebuild — nothing re-triggers a rebuild purely because
/// the wall clock ticked past midnight. A session left open overnight kept
/// the Home masthead greeting ("Evening, Sai · Sun, Aug 16") and the
/// TODAY/TOMORROW workout badge stamped with the previous day (register
/// #123) because nothing ever told those widgets the day had changed.
///
/// This notifier schedules a timer for the next local midnight
/// (rescheduling itself every time it fires) and exposes [refreshNow] for
/// callers to force a recompute on app resume — so `ref.watch(...)` is
/// enough to keep date-scoped UI correct whether the app was foregrounded
/// through midnight or only just resumed after.
class CurrentDayNotifier extends StateNotifier<DateTime> {
  CurrentDayNotifier() : super(_today()) {
    _scheduleMidnightTick();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Timer? _timer;

  void _scheduleMidnightTick() {
    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    // A couple of seconds of slack past midnight so a slightly-early timer
    // fire never recomputes to the day that's about to end.
    final delay = nextMidnight.difference(now) + const Duration(seconds: 2);
    _timer?.cancel();
    _timer = Timer(delay, () {
      refreshNow();
      _scheduleMidnightTick();
    });
  }

  /// Recompute "today" immediately — call on app resume so a day rollover
  /// that happened while backgrounded is picked up without waiting for the
  /// midnight timer that was scheduled relative to the old `now`.
  void refreshNow() {
    final today = _today();
    if (today != state) {
      debugPrint('📅 [CurrentDay] Rolled over from $state to $today');
      state = today;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Watch this to rebuild whenever the local calendar day changes (app
/// resume or a midnight rollover while running). Read `DateTime.now()` as
/// usual for the actual value — this provider only exists to trigger the
/// rebuild at the right moment.
final currentLocalDayProvider =
    StateNotifierProvider<CurrentDayNotifier, DateTime>((ref) {
  return CurrentDayNotifier();
});
