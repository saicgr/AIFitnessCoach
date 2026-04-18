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
      if (e['_is_just_added'] == true) 'just_added': 'true',
    };
  }

  /// Build warmup exercises from API data or fallback to defaults, then
  /// append any optimistic entries awaiting server confirmation.
  List<Map<String, String>> _getWarmupExercises() {
    final List<Map<String, String>> base;
    if (_warmupData != null && _warmupData!.isNotEmpty) {
      base = _warmupData!.map(_timedTile).toList();
    } else {
      base = const [
        {'name': 'Jumping Jacks', 'duration': '60 sec'},
        {'name': 'Arm Circles', 'duration': '30 sec'},
        {'name': 'Hip Circles', 'duration': '30 sec'},
        {'name': 'Leg Swings', 'duration': '30 sec each'},
        {'name': 'Light Cardio', 'duration': '2-3 min'},
      ];
    }
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

  /// Build stretch exercises from API data or fallback to defaults, then
  /// append any optimistic entries awaiting server confirmation.
  List<Map<String, String>> _getStretchExercises() {
    final List<Map<String, String>> base;
    if (_stretchData != null && _stretchData!.isNotEmpty) {
      base = _stretchData!.map(_timedTile).toList();
    } else {
      base = const [
        {'name': 'Quad Stretch', 'duration': '30 sec each'},
        {'name': 'Hamstring Stretch', 'duration': '30 sec each'},
        {'name': 'Shoulder Stretch', 'duration': '30 sec each'},
        {'name': 'Chest Opener', 'duration': '30 sec'},
        {'name': 'Cat-Cow Stretch', 'duration': '60 sec'},
      ];
    }
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
