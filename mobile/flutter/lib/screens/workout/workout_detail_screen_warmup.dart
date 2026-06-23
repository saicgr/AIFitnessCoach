part of 'workout_detail_screen.dart';

/// Warmup and stretch helper methods extracted from _WorkoutDetailScreenState
extension _WorkoutDetailScreenWarmup on _WorkoutDetailScreenState {
  /// Pending (optimistic) exercise adds for a section on this workout,
  /// pulled from [pendingWorkoutMutationsProvider]. Callers append these
  /// to the API-loaded data so newly-added rows appear in one frame.
  List<Map<String, dynamic>> _pendingFor(String section) {
    final workoutId = _workout?.id;
    if (workoutId == null) return const [];
    return ref
        .read(pendingWorkoutMutationsProvider)
        .addsFor(workoutId: workoutId, section: section);
  }

  /// Map a raw exercise map (from API data or optimistic payload) into the
  /// `{name, duration, isJustAdded}` shape the list tile expects.
  Map<String, String> _timedTile(Map<String, dynamic> e) {
    final name = e['name']?.toString() ?? 'Exercise';
    final durationSec = (e['duration_seconds'] as num?)?.toInt() ?? 30;
    final parts = <String>[_formatDuration(durationSec)];
    if (e['speed_mph'] != null) {
      parts.add('${(e['speed_mph'] as num).toStringAsFixed(1)} mph');
    }
    if (e['incline_percent'] != null) {
      parts.add('Incline ${(e['incline_percent'] as num).toStringAsFixed(0)}');
    }
    if (e['rpm'] != null) parts.add('${e['rpm']} RPM');
    if (e['resistance_level'] != null) {
      parts.add('Resistance ${e['resistance_level']}');
    }
    if (e['stroke_rate_spm'] != null) {
      parts.add('${e['stroke_rate_spm']} spm');
    }
    return {
      'name': name,
      'duration': parts.join(' | '),
      // Carry the library linkage through so the tile can resolve a real
      // exercise illustration via ExerciseImage(exerciseId:). Optional — the
      // backend attaches it at generation; name-only resolution still works.
      if (e['exercise_id'] != null) 'exercise_id': e['exercise_id'].toString(),
      if (e['_is_just_added'] == true) 'just_added': 'true',
    };
  }

  /// Build warmup exercises from the real API data, then append any optimistic
  /// entries awaiting server confirmation.
  ///
  /// Returns an EMPTY list when no real data is loaded yet — the screen renders
  /// a loading skeleton / retry state instead. We deliberately do NOT fall back
  /// to a hardcoded default list: that masked the real per-workout data failing
  /// to load and made every workout show the same warmups (see
  /// `feedback_no_silent_fallbacks`).
  List<Map<String, String>> _getWarmupExercises() {
    final base = (_warmupData != null && _warmupData!.isNotEmpty)
        ? _warmupData!.map(_timedTile).toList()
        : <Map<String, String>>[];
    final pending = _pendingFor('warmup');
    if (pending.isEmpty) return base;

    // Dedupe: if the silent refresh already brought the canonical row in,
    // drop the optimistic entry so the list doesn't briefly show two copies.
    final baseNames = base.map((e) => e['name']?.toLowerCase()).toSet();
    final extras = pending
        .where((e) =>
            !baseNames.contains(e['name']?.toString().toLowerCase()))
        .map(_timedTile);
    return [...base, ...extras];
  }

  /// Construct a (timed) [WorkoutExercise] from a raw warmup/stretch item map
  /// so the row can open the SAME full exercise-detail screen the working
  /// exercises use. Timed moves (`is_timed: true`, no sets×reps) render a
  /// DURATION/HOLD card on that screen instead of a set grid.
  WorkoutExercise _timedExerciseFromRaw(Map<String, dynamic> raw) {
    int? asInt(dynamic v) =>
        v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
    return WorkoutExercise(
      exerciseId: raw['exercise_id']?.toString(),
      nameValue: raw['name']?.toString() ?? 'Exercise',
      durationSeconds: asInt(raw['duration_seconds']),
      holdSeconds: asInt(raw['hold_seconds']),
      isTimed: true,
      sets: 0,
      instructions: raw['instructions']?.toString(),
      primaryMuscle: (raw['primary_muscle'] ??
              raw['muscle_group'] ??
              raw['target_muscle'])
          ?.toString(),
      muscleGroup: raw['muscle_group']?.toString(),
      equipment: raw['equipment']?.toString(),
    );
  }

  /// Open the full exercise-detail screen for a tapped warmup/stretch row.
  /// Prefers the raw API map (richer — carries instructions/muscle/equipment);
  /// falls back to the display tile for optimistic rows that have no raw entry.
  void _openTimedExerciseDetail(
      Map<String, dynamic>? raw, Map<String, String> displayItem) {
    HapticService.selection();
    final exercise = raw != null
        ? _timedExerciseFromRaw(raw)
        : WorkoutExercise(
            nameValue: displayItem['name'] ?? 'Exercise',
            exerciseId: displayItem['exercise_id'],
            isTimed: true,
            sets: 0,
          );
    context.push('/exercise-detail', extra: exercise);
  }

  /// Reorder a warmup ([section] == 'warmup') or stretch ([section] ==
  /// 'stretches') row and persist the new order. Reorders the PERSISTED
  /// underlying list (`_warmupData`/`_stretchData`) — optimistic pending rows
  /// (which have no backing entry) are not reorderable, so a drag that touches
  /// the pending tail is ignored rather than corrupting the saved list.
  void _reorderWarmupStretch(String section, int oldIndex, int newIndex) {
    final list = section == 'warmup' ? _warmupData : _stretchData;
    if (list == null || list.isEmpty) return;
    // SliverReorderableList convention: dropping below shifts the target up one.
    if (newIndex > oldIndex) newIndex -= 1;
    // Only the persisted base range is reorderable.
    if (oldIndex < 0 || oldIndex >= list.length) return;
    newIndex = newIndex.clamp(0, list.length - 1);
    if (oldIndex == newIndex) return;

    HapticService.light();
    setState(() {
      final moved = list.removeAt(oldIndex);
      list.insert(newIndex, moved);
    });

    // Persist the new order; revert + warn on failure so the saved order and
    // the visible order never silently diverge.
    final snapshot = List<Map<String, dynamic>>.from(list);
    ref
        .read(workoutRepositoryProvider)
        .saveWarmupStretchOrder(widget.workoutId, section, snapshot)
        .catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save the new order — try again")),
      );
    });
  }

  /// Build stretch exercises from API data or fallback to defaults, then
  /// append any optimistic entries awaiting server confirmation.
  List<Map<String, String>> _getStretchExercises() {
    final base = (_stretchData != null && _stretchData!.isNotEmpty)
        ? _stretchData!.map(_timedTile).toList()
        : <Map<String, String>>[];
    final pending = _pendingFor('stretches');
    if (pending.isEmpty) return base;

    final baseNames = base.map((e) => e['name']?.toLowerCase()).toSet();
    final extras = pending
        .where((e) =>
            !baseNames.contains(e['name']?.toString().toLowerCase()))
        .map(_timedTile);
    return [...base, ...extras];
  }
}
