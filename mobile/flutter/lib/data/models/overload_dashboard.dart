/// Progressive Overload Dashboard models.
///
/// Hand-written immutable models (NO freezed / build_runner — the repo bans
/// running build_runner, so every `fromJson`/`toJson` is authored here) that
/// mirror the backend contract of `GET /api/v1/progress/overload-dashboard`
/// plus the enriched per-muscle drill-down on
/// `GET /api/v1/scores/strength/{muscle_group}`.
///
/// All weights in the payload are kilograms — the UI converts for display via
/// `WeightUtils.formatWorkoutWeight` (the app lifts in lbs). These models keep
/// the raw kg so the conversion stays at the presentation edge.
library;

/// Defensive numeric coercion: JSON decode yields `int` OR `double` for the
/// same field across payloads, and a malformed/missing value must degrade to a
/// sane default rather than throwing mid-parse (the dashboard is a read-only
/// surface — a single bad series point should not blank the whole screen).
double _toDouble(Object? v, [double fallback = 0.0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _toInt(Object? v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _toStr(Object? v, [String fallback = '']) => v?.toString() ?? fallback;

// ============================================================================
// Time series points
// ============================================================================

/// A single `{date, score}` point on the overall sparkline.
class OverloadSparkPoint {
  final DateTime date;
  final int score;

  const OverloadSparkPoint({required this.date, required this.score});

  factory OverloadSparkPoint.fromJson(Map<String, dynamic> j) =>
      OverloadSparkPoint(
        date: DateTime.parse(_toStr(j['date'])),
        score: _toInt(j['score']),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
      };
}

/// A generic `{date, value}` point — used by per-muscle score & volume series.
class OverloadSeriesPoint {
  final DateTime date;
  final double value;

  const OverloadSeriesPoint({required this.date, required this.value});

  factory OverloadSeriesPoint.fromJson(Map<String, dynamic> j) =>
      OverloadSeriesPoint(
        date: DateTime.parse(_toStr(j['date'])),
        value: _toDouble(j['value']),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'value': value,
      };
}

/// A per-exercise e1RM/volume point `{date, e1rm_kg, volume_kg}`.
class OverloadExercisePoint {
  final DateTime date;
  final double e1rmKg;
  final double volumeKg;

  const OverloadExercisePoint({
    required this.date,
    required this.e1rmKg,
    required this.volumeKg,
  });

  factory OverloadExercisePoint.fromJson(Map<String, dynamic> j) =>
      OverloadExercisePoint(
        date: DateTime.parse(_toStr(j['date'])),
        e1rmKg: _toDouble(j['e1rm_kg']),
        volumeKg: _toDouble(j['volume_kg']),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'e1rm_kg': e1rmKg,
        'volume_kg': volumeKg,
      };
}

// ============================================================================
// Overall (T1 hero)
// ============================================================================

class OverloadOverall {
  final int score;
  final String level;
  final double percentile;
  final int delta30d;
  final int delta365d;
  final List<OverloadSparkPoint> sparkline;

  const OverloadOverall({
    required this.score,
    required this.level,
    required this.percentile,
    required this.delta30d,
    required this.delta365d,
    required this.sparkline,
  });

  factory OverloadOverall.fromJson(Map<String, dynamic> j) => OverloadOverall(
        score: _toInt(j['score']),
        level: _toStr(j['level'], 'beginner'),
        percentile: _toDouble(j['percentile']),
        delta30d: _toInt(j['delta_30d']),
        delta365d: _toInt(j['delta_365d']),
        sparkline: _parseList(j['sparkline'], OverloadSparkPoint.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level,
        'percentile': percentile,
        'delta_30d': delta30d,
        'delta_365d': delta365d,
        'sparkline': [for (final p in sparkline) p.toJson()],
      };
}

// ============================================================================
// Per-muscle (T2 radar)
// ============================================================================

class OverloadMuscle {
  final String muscleGroup;
  final int currentScore;
  final int scoreChange;
  final bool isEstablishing;
  final double populationPercentile;
  final List<OverloadSeriesPoint> scoreSeries;
  final List<OverloadSeriesPoint> volumeSeries;

  const OverloadMuscle({
    required this.muscleGroup,
    required this.currentScore,
    required this.scoreChange,
    required this.isEstablishing,
    required this.populationPercentile,
    required this.scoreSeries,
    required this.volumeSeries,
  });

  factory OverloadMuscle.fromJson(Map<String, dynamic> j) => OverloadMuscle(
        muscleGroup: _toStr(j['muscle_group']),
        currentScore: _toInt(j['current_score']),
        scoreChange: _toInt(j['score_change']),
        isEstablishing: j['is_establishing'] == true,
        populationPercentile: _toDouble(j['population_percentile']),
        scoreSeries: _parseList(j['score_series'], OverloadSeriesPoint.fromJson),
        volumeSeries:
            _parseList(j['volume_series'], OverloadSeriesPoint.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'muscle_group': muscleGroup,
        'current_score': currentScore,
        'score_change': scoreChange,
        'is_establishing': isEstablishing,
        'population_percentile': populationPercentile,
        'score_series': [for (final p in scoreSeries) p.toJson()],
        'volume_series': [for (final p in volumeSeries) p.toJson()],
      };
}

// ============================================================================
// Per-exercise (T3)
// ============================================================================

class OverloadTopExercise {
  final String exerciseName;
  final double startingWeight;
  final double currentWeight;
  final double startingE1rm;
  final double currentE1rm;
  final double allTimeBestE1rm;
  final String trend; // improving | maintaining | declining
  final List<OverloadExercisePoint> e1rmSeries;

  const OverloadTopExercise({
    required this.exerciseName,
    required this.startingWeight,
    required this.currentWeight,
    required this.startingE1rm,
    required this.currentE1rm,
    required this.allTimeBestE1rm,
    required this.trend,
    required this.e1rmSeries,
  });

  factory OverloadTopExercise.fromJson(Map<String, dynamic> j) =>
      OverloadTopExercise(
        exerciseName: _toStr(j['exercise_name']),
        startingWeight: _toDouble(j['starting_weight']),
        currentWeight: _toDouble(j['current_weight']),
        startingE1rm: _toDouble(j['starting_e1rm']),
        currentE1rm: _toDouble(j['current_e1rm']),
        allTimeBestE1rm: _toDouble(j['all_time_best_e1rm']),
        trend: _toStr(j['trend'], 'maintaining'),
        e1rmSeries: _parseList(j['e1rm_series'], OverloadExercisePoint.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'starting_weight': startingWeight,
        'current_weight': currentWeight,
        'starting_e1rm': startingE1rm,
        'current_e1rm': currentE1rm,
        'all_time_best_e1rm': allTimeBestE1rm,
        'trend': trend,
        'e1rm_series': [for (final p in e1rmSeries) p.toJson()],
      };

  /// Percent change in working weight (start → current). 0 when starting is 0.
  double get weightChangePct {
    if (startingWeight <= 0) return 0;
    return ((currentWeight - startingWeight) / startingWeight) * 100.0;
  }
}

// ============================================================================
// Recent PRs
// ============================================================================

class OverloadPr {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double estimated1rmKg;
  final DateTime? achievedAt;

  const OverloadPr({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.estimated1rmKg,
    required this.achievedAt,
  });

  factory OverloadPr.fromJson(Map<String, dynamic> j) {
    final raw = j['achieved_at'];
    return OverloadPr(
      exerciseName: _toStr(j['exercise_name']),
      weightKg: _toDouble(j['weight_kg']),
      reps: _toInt(j['reps']),
      estimated1rmKg: _toDouble(j['estimated_1rm_kg']),
      achievedAt: raw == null ? null : DateTime.tryParse(raw.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'weight_kg': weightKg,
        'reps': reps,
        'estimated_1rm_kg': estimated1rmKg,
        'achieved_at': achievedAt?.toIso8601String(),
      };
}

// ============================================================================
// Last workout "what changed"
// ============================================================================

class OverloadMuscleDelta {
  final String muscleGroup;
  final int scoreChange;

  const OverloadMuscleDelta({
    required this.muscleGroup,
    required this.scoreChange,
  });

  factory OverloadMuscleDelta.fromJson(Map<String, dynamic> j) =>
      OverloadMuscleDelta(
        muscleGroup: _toStr(j['muscle_group']),
        scoreChange: _toInt(j['score_change']),
      );

  Map<String, dynamic> toJson() => {
        'muscle_group': muscleGroup,
        'score_change': scoreChange,
      };
}

class OverloadLastWorkout {
  final DateTime? completedAt;
  final List<OverloadMuscleDelta> muscleDeltas;

  const OverloadLastWorkout({
    required this.completedAt,
    required this.muscleDeltas,
  });

  factory OverloadLastWorkout.fromJson(Map<String, dynamic> j) {
    final raw = j['completed_at'];
    return OverloadLastWorkout(
      completedAt: raw == null ? null : DateTime.tryParse(raw.toString()),
      muscleDeltas:
          _parseList(j['muscle_deltas'], OverloadMuscleDelta.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'completed_at': completedAt?.toIso8601String(),
        'muscle_deltas': [for (final d in muscleDeltas) d.toJson()],
      };
}

// ============================================================================
// Root model
// ============================================================================

class OverloadDashboard {
  final String userId;
  final String timeRange;
  final OverloadOverall overall;
  final List<OverloadMuscle> muscles;
  final List<OverloadTopExercise> topExercises;
  final List<OverloadPr> recentPrs;
  final OverloadLastWorkout? lastWorkout;

  const OverloadDashboard({
    required this.userId,
    required this.timeRange,
    required this.overall,
    required this.muscles,
    required this.topExercises,
    required this.recentPrs,
    required this.lastWorkout,
  });

  factory OverloadDashboard.fromJson(Map<String, dynamic> j) {
    final lw = j['last_workout'];
    return OverloadDashboard(
      userId: _toStr(j['user_id']),
      timeRange: _toStr(j['time_range'], '12_weeks'),
      overall: OverloadOverall.fromJson(
        (j['overall'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      muscles: _parseList(j['muscles'], OverloadMuscle.fromJson),
      topExercises:
          _parseList(j['top_exercises'], OverloadTopExercise.fromJson),
      recentPrs: _parseList(j['recent_prs'], OverloadPr.fromJson),
      lastWorkout: lw is Map
          ? OverloadLastWorkout.fromJson(lw.cast<String, dynamic>())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'time_range': timeRange,
        'overall': overall.toJson(),
        'muscles': [for (final m in muscles) m.toJson()],
        'top_exercises': [for (final e in topExercises) e.toJson()],
        'recent_prs': [for (final p in recentPrs) p.toJson()],
        'last_workout': lastWorkout?.toJson(),
      };

  /// True when there is genuinely nothing to show (no overall score, no
  /// muscles, no exercises). Used to drive the explicit empty state instead of
  /// rendering an all-zero dashboard that reads as broken.
  bool get isEmpty =>
      overall.score <= 0 && muscles.isEmpty && topExercises.isEmpty;
}

// ============================================================================
// Per-muscle drill-down (enriched /scores/strength/{muscle_group})
// ============================================================================

/// One contributing exercise inside the per-muscle drill-down sheet.
class ContributingExercise {
  final String exerciseName;
  final double bestE1rmKg;
  final double weeklySets;
  final double contributionPct;
  final bool isMachineDerived;

  const ContributingExercise({
    required this.exerciseName,
    required this.bestE1rmKg,
    required this.weeklySets,
    required this.contributionPct,
    required this.isMachineDerived,
  });

  factory ContributingExercise.fromJson(Map<String, dynamic> j) =>
      ContributingExercise(
        exerciseName: _toStr(j['exercise_name']),
        bestE1rmKg: _toDouble(j['best_e1rm_kg']),
        weeklySets: _toDouble(j['weekly_sets']),
        contributionPct: _toDouble(j['contribution_pct']),
        isMachineDerived: j['is_machine_derived'] == true,
      );
}

/// The enriched detail returned by `GET /scores/strength/{muscle_group}` —
/// only the fields the overload drill-down sheet needs (the legacy
/// `StrengthDetail` model drops these new keys).
class OverloadMuscleDetail {
  final String muscleGroup;
  final List<ContributingExercise> contributingExercises;
  final String? emptyStateHint;
  final double? populationPercentile;
  final bool bestIsMachine;

  const OverloadMuscleDetail({
    required this.muscleGroup,
    required this.contributingExercises,
    required this.emptyStateHint,
    required this.populationPercentile,
    required this.bestIsMachine,
  });

  factory OverloadMuscleDetail.fromJson(
    String muscleGroup,
    Map<String, dynamic> j,
  ) {
    final hint = j['empty_state_hint'];
    final pct = j['population_percentile'];
    return OverloadMuscleDetail(
      muscleGroup: muscleGroup,
      contributingExercises: _parseList(
        j['contributing_exercises'],
        ContributingExercise.fromJson,
      ),
      emptyStateHint: hint?.toString(),
      populationPercentile: pct is num ? pct.toDouble() : null,
      bestIsMachine: j['best_is_machine'] == true,
    );
  }
}

// ============================================================================
// Shared parse helper
// ============================================================================

/// Maps a JSON list into typed models, skipping any non-map entry. Tolerant by
/// design — a single malformed point never throws away the whole series.
List<T> _parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  final out = <T>[];
  for (final e in raw) {
    if (e is Map) {
      out.add(fromJson(e.cast<String, dynamic>()));
    }
  }
  return out;
}
