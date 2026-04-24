// Entry gate that picks which active-workout tier to render based on the
// user's workoutUiModeProvider. The two tiers share the same
// todayWorkoutProvider + rest-timer state, so mid-workout tier swaps
// preserve progress automatically.
//
// Simple was retired; the `WorkoutUiMode.simple` enum value is still kept
// for DB back-compat and routes to the Easy screen here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/active_workout_phase_provider.dart';
import '../../core/providers/workout_ui_mode_provider.dart';
import '../../data/models/workout.dart';
import 'active_workout_screen_refactored.dart';
import 'easy/easy_active_workout_screen.dart';

class ActiveWorkoutEntry extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  const ActiveWorkoutEntry({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<ActiveWorkoutEntry> createState() => _ActiveWorkoutEntryState();
}

class _ActiveWorkoutEntryState extends ConsumerState<ActiveWorkoutEntry> {
  @override
  void initState() {
    super.initState();
    // Reset the shared warmup flag for THIS fresh workout BEFORE the child
    // tier mounts. Easy/Simple flip it back to true in their own init;
    // Advanced reads it in its own initState and skips warmup only if still
    // true (i.e. user tier-swapped mid-session).
    //
    // Important: we can't unconditionally do `notifier.state = false` here.
    // If an upstream widget is listening to this StateProvider at the
    // moment /active-workout mounts, Riverpod throws "Tried to modify a
    // provider while the widget tree was building" — the very error this
    // code was getting. And previously, deferring the reset into dispose()
    // crashed too (post-frame fired after ConsumerElement was torn down).
    //
    // Two-tier fix:
    //   • Fast path: if state is already false (default, and the common case
    //     on fresh app launch), no write → no listener notification → no
    //     crash. This covers normal workout-to-workout flow.
    //   • Slow path: if state is stale-true (prior workout didn't clean up),
    //     defer the reset to a post-frame callback with a `mounted` guard
    //     so it runs after the current build completes. Advanced's child
    //     initState will observe `true` for this one frame and skip warmup;
    //     the next fresh workout will see the reset value. That's the
    //     trade-off for avoiding the crash — and the underlying stale-true
    //     bug should be fixed at workout-end time, not here.
    final notifier = ref.read(activeWorkoutWarmupDoneProvider.notifier);
    if (!notifier.state) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeWorkoutWarmupDoneProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(workoutUiModeProvider.select((s) => s.mode));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _buildForMode(mode),
    );
  }

  Widget _buildForMode(WorkoutUiMode mode) {
    switch (mode) {
      case WorkoutUiMode.easy:
      // ignore: deprecated_member_use_from_same_package
      case WorkoutUiMode.simple:
        return EasyActiveWorkoutScreen(
          key: const ValueKey('easy_active_workout'),
          workout: widget.workout,
          challengeId: widget.challengeId,
          challengeData: widget.challengeData,
        );
      case WorkoutUiMode.advanced:
        return ActiveWorkoutScreen(
          key: const ValueKey('advanced_active_workout'),
          workout: widget.workout,
          challengeId: widget.challengeId,
          challengeData: widget.challengeData,
        );
    }
  }
}
