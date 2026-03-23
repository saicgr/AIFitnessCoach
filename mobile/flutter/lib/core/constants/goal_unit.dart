/// Unit types for personal goals
enum GoalUnit {
  reps,
  seconds,
  minutes,
  kg,
  km,
  miles,
  steps,
  calories,
}

extension GoalUnitExt on GoalUnit {
  String get label {
    switch (this) {
      case GoalUnit.reps: return 'reps';
      case GoalUnit.seconds: return 'sec';
      case GoalUnit.minutes: return 'min';
      case GoalUnit.kg: return 'kg';
      case GoalUnit.km: return 'km';
      case GoalUnit.miles: return 'mi';
      case GoalUnit.steps: return 'steps';
      case GoalUnit.calories: return 'cal';
    }
  }

  String get fullLabel {
    switch (this) {
      case GoalUnit.reps: return 'reps';
      case GoalUnit.seconds: return 'seconds';
      case GoalUnit.minutes: return 'minutes';
      case GoalUnit.kg: return 'kg';
      case GoalUnit.km: return 'km';
      case GoalUnit.miles: return 'miles';
      case GoalUnit.steps: return 'steps';
      case GoalUnit.calories: return 'calories';
    }
  }

  bool get isDecimal => this == GoalUnit.kg || this == GoalUnit.km || this == GoalUnit.miles;

  /// Format a value with its unit (smart display)
  String format(num value) {
    switch (this) {
      case GoalUnit.seconds:
        final secs = value.toInt();
        if (secs >= 60) {
          final m = secs ~/ 60;
          final s = secs % 60;
          return s == 0 ? '$m min' : '$m min $s sec';
        }
        return '$secs sec';
      case GoalUnit.minutes:
        return '${value.toInt()} min';
      case GoalUnit.kg:
        final d = value.toDouble();
        return d == d.truncate() ? '${d.toInt()} kg' : '${d.toStringAsFixed(1)} kg';
      case GoalUnit.km:
        final d = value.toDouble();
        return d == d.truncate() ? '${d.toInt()} km' : '${d.toStringAsFixed(1)} km';
      case GoalUnit.miles:
        final d = value.toDouble();
        return d == d.truncate() ? '${d.toInt()} mi' : '${d.toStringAsFixed(1)} mi';
      case GoalUnit.steps:
        return '${value.toInt()} steps';
      case GoalUnit.calories:
        return '${value.toInt()} cal';
      case GoalUnit.reps:
        return '${value.toInt()} reps';
    }
  }

  static GoalUnit fromString(String? s) {
    switch (s) {
      case 'seconds': return GoalUnit.seconds;
      case 'minutes': return GoalUnit.minutes;
      case 'kg': return GoalUnit.kg;
      case 'km': return GoalUnit.km;
      case 'miles': return GoalUnit.miles;
      case 'steps': return GoalUnit.steps;
      case 'calories': return GoalUnit.calories;
      default: return GoalUnit.reps;
    }
  }
}
