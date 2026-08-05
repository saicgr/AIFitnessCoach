/// Shared test doubles for the heavy Home `StateNotifierProvider`s that
/// normally wire straight into Supabase/Dio on construction (`WorkoutsNotifier`,
/// `TodayWorkoutNotifier`, `XPNotifier`). A bare widget test has no Supabase
/// session, so letting the real notifiers construct risks a synchronous crash
/// or a stray network call.
///
/// `extends StateNotifier<...> implements <RealNotifier>` is the same pattern
/// `test/screens/workout/no_scroll_tiers_test.dart` already uses for
/// `WorkoutUiModeNotifier` — it satisfies the provider's concrete Notifier
/// type (so `.overrideWith` type-checks) without running the real
/// constructor, and Dart's `noSuchMethod` forwarding means we don't have to
/// stub every member the real class happens to declare.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitwiz/data/models/today_workout.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/providers/today_workout_provider.dart';
import 'package:fitwiz/data/providers/xp_provider.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';

class StubWorkoutsNotifier extends StateNotifier<AsyncValue<List<Workout>>>
    implements WorkoutsNotifier {
  StubWorkoutsNotifier(AsyncValue<List<Workout>> initial) : super(initial);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubTodayWorkoutNotifier
    extends StateNotifier<AsyncValue<TodayWorkoutResponse?>>
    implements TodayWorkoutNotifier {
  StubTodayWorkoutNotifier(AsyncValue<TodayWorkoutResponse?> initial)
      : super(initial);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubXPNotifier extends StateNotifier<XPState> implements XPNotifier {
  StubXPNotifier([XPState initial = const XPState()]) : super(initial);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
