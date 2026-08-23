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

/// Which time-of-day greeting bucket ("Morning" / "Afternoon" / "Evening")
/// applies right now, keyed purely off the boundary hours a greeting widget
/// cares about (12:00 and 17:00).
///
/// `currentLocalDayProvider` only ticks at midnight, so a widget that reads
/// `DateTime.now().hour` once and only rebuilds off that provider stays
/// stamped with whatever greeting bucket was current at its last rebuild —
/// the header could open at 2pm ("Afternoon") and, absent any other rebuild
/// trigger, still read "Afternoon" at 10pm (register #295, the same family
/// as #123). This notifier schedules a timer to the next boundary crossing
/// (rescheduling itself each time it fires) so watching it is enough to
/// stay correct across a session left open through a bucket change.
enum GreetingBucket { morning, afternoon, evening }

class CurrentGreetingBucketNotifier extends StateNotifier<GreetingBucket> {
  CurrentGreetingBucketNotifier() : super(_bucketFor(DateTime.now())) {
    _scheduleNextBoundary();
  }

  static GreetingBucket _bucketFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return GreetingBucket.morning;
    if (hour < 17) return GreetingBucket.afternoon;
    return GreetingBucket.evening;
  }

  Timer? _timer;

  void _scheduleNextBoundary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final boundaries = [
      today.add(const Duration(hours: 12)),
      today.add(const Duration(hours: 17)),
      today.add(const Duration(days: 1, hours: 12)),
    ];
    final next = boundaries.firstWhere((b) => b.isAfter(now));
    // A couple of seconds of slack so a slightly-early timer fire never
    // recomputes to the bucket that's about to start.
    final delay = next.difference(now) + const Duration(seconds: 2);
    _timer?.cancel();
    _timer = Timer(delay, () {
      refreshNow();
      _scheduleNextBoundary();
    });
  }

  /// Recompute the current bucket immediately — call on app resume so a
  /// boundary crossed while backgrounded is picked up without waiting for
  /// the timer that was scheduled relative to the pre-background `now`.
  void refreshNow() {
    final bucket = _bucketFor(DateTime.now());
    if (bucket != state) {
      debugPrint('🕒 [GreetingBucket] Rolled over to $bucket');
      state = bucket;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Watch this to rebuild whenever the time-of-day greeting bucket changes
/// (app resume or a boundary rollover while running). Read
/// `DateTime.now()` as usual for the actual value — this provider only
/// exists to trigger the rebuild at the right moment.
final currentGreetingBucketProvider =
    StateNotifierProvider<CurrentGreetingBucketNotifier, GreetingBucket>((ref) {
  return CurrentGreetingBucketNotifier();
});
