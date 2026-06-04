/// Per-exercise strength score + best lift, backing the Gravl-style hexagon
/// badge + "Best lift from the last 3 months" card on the active-workout screen.
///
/// Source: `GET /api/v1/scores/exercise/{exercise_name}` (deterministic; reuses
/// the same StrengthCalculatorService that powers the per-muscle scores).
///
/// Hand-written JSON (no json_serializable) — the repo cannot run build_runner.
library;

class ExerciseBestLift {
  final double weightKg;
  final int reps;
  final double estimated1rmKg;
  final DateTime? achievedAt;

  const ExerciseBestLift({
    required this.weightKg,
    required this.reps,
    required this.estimated1rmKg,
    this.achievedAt,
  });

  factory ExerciseBestLift.fromJson(Map<String, dynamic> json) {
    return ExerciseBestLift(
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble() ?? 0,
      achievedAt: _parseDate(json['achieved_at']),
    );
  }
}

class ExerciseScorePoint {
  final DateTime? date;
  final double e1rm;

  const ExerciseScorePoint({required this.date, required this.e1rm});

  factory ExerciseScorePoint.fromJson(Map<String, dynamic> json) {
    return ExerciseScorePoint(
      date: _parseDate(json['date']),
      e1rm: (json['e1rm'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExerciseStrengthScore {
  final String exerciseName;
  final bool hasData;
  final int score;
  final String level;
  final double bodyweightRatio;
  final ExerciseBestLift? best;
  final List<ExerciseScorePoint> history;

  const ExerciseStrengthScore({
    required this.exerciseName,
    required this.hasData,
    required this.score,
    required this.level,
    this.bodyweightRatio = 0,
    this.best,
    this.history = const [],
  });

  /// "Elite", "Advanced", … for display.
  String get levelDisplay =>
      level.isEmpty ? '' : level[0].toUpperCase() + level.substring(1);

  factory ExerciseStrengthScore.fromJson(Map<String, dynamic> json) {
    final bestJson = json['best'];
    final historyJson = json['history'];
    return ExerciseStrengthScore(
      exerciseName: json['exercise_name'] as String? ?? '',
      hasData: json['has_data'] as bool? ?? false,
      score: (json['score'] as num?)?.toInt() ?? 0,
      level: json['level'] as String? ?? 'beginner',
      bodyweightRatio: (json['bodyweight_ratio'] as num?)?.toDouble() ?? 0,
      best: bestJson is Map<String, dynamic>
          ? ExerciseBestLift.fromJson(bestJson)
          : null,
      history: historyJson is List
          ? historyJson
              .whereType<Map<String, dynamic>>()
              .map(ExerciseScorePoint.fromJson)
              .toList()
          : const [],
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}
