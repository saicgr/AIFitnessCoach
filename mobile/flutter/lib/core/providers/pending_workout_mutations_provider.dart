import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds optimistic exercise additions that haven't hit the server yet (or
/// are in-flight), keyed by `'<workoutId>:<section>'` where section is one
/// of `'main'`, `'warmup'`, `'stretches'`. Each pending entry carries the
/// full detail the user configured — sets/reps/rest/weight/duration/cardio
/// params/etc. — plus `_temp_id` + `_is_just_added` flags so the UI can
/// render a highlight and later dedupe against server data.
///
/// The workout detail screen merges these entries into the exercises list
/// it displays, so the moment a staple is added the row appears without
/// waiting for the network round-trip.
class PendingWorkoutMutationsState {
  final Map<String, List<Map<String, dynamic>>> addsByKey;
  final int revision;

  const PendingWorkoutMutationsState({
    this.addsByKey = const {},
    this.revision = 0,
  });

  List<Map<String, dynamic>> addsFor({
    required String workoutId,
    required String section,
  }) {
    return addsByKey['$workoutId:$section'] ?? const [];
  }

  bool get isEmpty => addsByKey.values.every((l) => l.isEmpty);

  PendingWorkoutMutationsState copyWith({
    Map<String, List<Map<String, dynamic>>>? addsByKey,
    int? revision,
  }) =>
      PendingWorkoutMutationsState(
        addsByKey: addsByKey ?? this.addsByKey,
        revision: revision ?? this.revision,
      );
}

class PendingWorkoutMutationsNotifier
    extends StateNotifier<PendingWorkoutMutationsState> {
  PendingWorkoutMutationsNotifier()
      : super(const PendingWorkoutMutationsState());

  static String _makeKey(String workoutId, String section) =>
      '$workoutId:$section';

  /// Inserts an optimistic exercise entry. Returns the `tempId` the caller
  /// should keep so it can call [remove] later (on both success and failure).
  ///
  /// `exerciseData` is a free-form map matching the shape the UI expects
  /// — must include at minimum `'name'`. For warmup/stretch entries it
  /// should include `'duration_seconds'` + any cardio params. For main
  /// entries it should include `sets`/`reps`/`rest_seconds`/`weight` etc.
  String addOptimistic({
    required String workoutId,
    required String section,
    required Map<String, dynamic> exerciseData,
  }) {
    final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
    final enriched = <String, dynamic>{
      ...exerciseData,
      '_temp_id': tempId,
      '_is_just_added': true,
    };

    final key = _makeKey(workoutId, section);
    final current = Map<String, List<Map<String, dynamic>>>.from(state.addsByKey);
    current[key] = [...(current[key] ?? const []), enriched];
    state = state.copyWith(
      addsByKey: current,
      revision: state.revision + 1,
    );
    if (kDebugMode) {
      debugPrint(
        '⚡ [PendingMutations] Added optimistic ${exerciseData['name']} to '
        '$key (tempId=$tempId)',
      );
    }
    return tempId;
  }

  /// Removes the entry with the given `tempId` from any section/workout.
  void remove(String tempId) {
    final next = <String, List<Map<String, dynamic>>>{};
    var removed = false;
    state.addsByKey.forEach((key, list) {
      final filtered = list
          .where((e) => e['_temp_id'] != tempId)
          .toList(growable: false);
      if (filtered.length != list.length) removed = true;
      if (filtered.isNotEmpty) next[key] = filtered;
    });
    if (removed) {
      state = state.copyWith(
        addsByKey: next,
        revision: state.revision + 1,
      );
      if (kDebugMode) {
        debugPrint('🧹 [PendingMutations] Removed tempId=$tempId');
      }
    }
  }

  /// Clears all pending additions for the given workout (all sections).
  /// Called on navigation away or explicit workout reload.
  void clearForWorkout(String workoutId) {
    final next = <String, List<Map<String, dynamic>>>{};
    state.addsByKey.forEach((key, list) {
      if (!key.startsWith('$workoutId:')) next[key] = list;
    });
    if (next.length != state.addsByKey.length) {
      state = state.copyWith(
        addsByKey: next,
        revision: state.revision + 1,
      );
    }
  }
}

/// Provider exposing pending (optimistic) exercise additions.
/// Read from the workout detail screen; written by mutation providers like
/// `staplesProvider` when a user adds a staple with "add to today's workout".
final pendingWorkoutMutationsProvider = StateNotifierProvider<
    PendingWorkoutMutationsNotifier, PendingWorkoutMutationsState>((ref) {
  return PendingWorkoutMutationsNotifier();
});
