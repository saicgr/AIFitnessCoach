part of 'workout_detail_screen.dart';

/// Warmup and stretch helper methods extracted from _WorkoutDetailScreenState
extension _WorkoutDetailScreenWarmup on _WorkoutDetailScreenState {
  /// Build warmup exercises from API data or fallback to defaults
  List<Map<String, String>> _getWarmupExercises() {
    if (_warmupData != null && _warmupData!.isNotEmpty) {
      return _warmupData!.map((e) {
        final name = e['name']?.toString() ?? 'Exercise';
        final durationSec = (e['duration_seconds'] as num?)?.toInt() ?? 30;
        final parts = <String>[_formatDuration(durationSec)];
        if (e['speed_mph'] != null) parts.add('${(e['speed_mph'] as num).toStringAsFixed(1)} mph');
        if (e['incline_percent'] != null) parts.add('Incline ${(e['incline_percent'] as num).toStringAsFixed(0)}');
        if (e['rpm'] != null) parts.add('${e['rpm']} RPM');
        if (e['resistance_level'] != null) parts.add('Resistance ${e['resistance_level']}');
        if (e['stroke_rate_spm'] != null) parts.add('${e['stroke_rate_spm']} spm');
        return {'name': name, 'duration': parts.join(' | ')};
      }).toList();
    }
    return [
      {'name': 'Jumping Jacks', 'duration': '60 sec'},
      {'name': 'Arm Circles', 'duration': '30 sec'},
      {'name': 'Hip Circles', 'duration': '30 sec'},
      {'name': 'Leg Swings', 'duration': '30 sec each'},
      {'name': 'Light Cardio', 'duration': '2-3 min'},
    ];
  }

  /// Build stretch exercises from API data or fallback to defaults
  List<Map<String, String>> _getStretchExercises() {
    if (_stretchData != null && _stretchData!.isNotEmpty) {
      return _stretchData!.map((e) {
        final name = e['name']?.toString() ?? 'Stretch';
        final durationSec = (e['duration_seconds'] as num?)?.toInt() ?? 30;
        final parts = <String>[_formatDuration(durationSec)];
        if (e['speed_mph'] != null) parts.add('${(e['speed_mph'] as num).toStringAsFixed(1)} mph');
        if (e['incline_percent'] != null) parts.add('Incline ${(e['incline_percent'] as num).toStringAsFixed(0)}');
        if (e['rpm'] != null) parts.add('${e['rpm']} RPM');
        if (e['resistance_level'] != null) parts.add('Resistance ${e['resistance_level']}');
        if (e['stroke_rate_spm'] != null) parts.add('${e['stroke_rate_spm']} spm');
        return {'name': name, 'duration': parts.join(' | ')};
      }).toList();
    }
    return [
      {'name': 'Quad Stretch', 'duration': '30 sec each'},
      {'name': 'Hamstring Stretch', 'duration': '30 sec each'},
      {'name': 'Shoulder Stretch', 'duration': '30 sec each'},
      {'name': 'Chest Opener', 'duration': '30 sec'},
      {'name': 'Cat-Cow Stretch', 'duration': '60 sec'},
    ];
  }
}
