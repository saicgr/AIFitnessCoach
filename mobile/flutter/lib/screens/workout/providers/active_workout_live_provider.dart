/// The live, mutated workout for the in-progress session.
///
/// The Easy and Advanced active-workout screens are remounted when the user
/// flips tiers mid-session, and each reads its exercise list from
/// `widget.workout` (the originally-passed snapshot). Set progress survives
/// via [activeWorkoutSessionProvider], but **structural** mutations (an
/// exercise swap, an added exercise) lived only in the mounted screen's local
/// `_exercises` and were lost on a tier switch.
///
/// This provider holds the post-mutation [Workout] so both tiers read the same
/// up-to-date exercise list. It is null until the first mutation; consumers
/// fall back to the originally-passed workout. Guarded by workout id so a
/// stale override from a previous session is never applied, and cleared by
/// [ActiveWorkoutEntry] when a new workout starts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/workout.dart';

final activeWorkoutLiveProvider = StateProvider<Workout?>((ref) => null);
