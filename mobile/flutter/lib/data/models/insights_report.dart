/// Data models for the Insights screen — report data, totals, and AI narratives.

class InsightsReport {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final List<InsightsPeriodGroup> groups;
  final String startDate;
  final String endDate;
  final String groupBy;

  const InsightsReport({
    required this.totals,
    this.previousTotals,
    required this.groups,
    required this.startDate,
    required this.endDate,
    required this.groupBy,
  });

  factory InsightsReport.fromJson(Map<String, dynamic> json) {
    return InsightsReport(
      totals: InsightsTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
      previousTotals: json['previous_totals'] != null
          ? InsightsTotals.fromJson(json['previous_totals'] as Map<String, dynamic>)
          : null,
      groups: (json['groups'] as List<dynamic>? ?? [])
          .map((g) => InsightsPeriodGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      groupBy: json['group_by'] as String? ?? 'week',
    );
  }
}

class InsightsTotals {
  final int workoutsCompleted;
  final int workoutsScheduled;
  final int totalTimeMinutes;
  final int totalCalories;
  final int totalExercises;
  final int maxStreak;
  final int totalPrs;
  final double? avgNutritionAdherence;
  final double? avgReadiness;
  final Map<String, int>? moodDistribution;
  final double? weightChangeKg;
  final double? bodyFatChange;

  const InsightsTotals({
    this.workoutsCompleted = 0,
    this.workoutsScheduled = 0,
    this.totalTimeMinutes = 0,
    this.totalCalories = 0,
    this.totalExercises = 0,
    this.maxStreak = 0,
    this.totalPrs = 0,
    this.avgNutritionAdherence,
    this.avgReadiness,
    this.moodDistribution,
    this.weightChangeKg,
    this.bodyFatChange,
  });

  factory InsightsTotals.fromJson(Map<String, dynamic> json) {
    return InsightsTotals(
      workoutsCompleted: (json['workouts_completed'] as num?)?.toInt() ?? 0,
      workoutsScheduled: (json['workouts_scheduled'] as num?)?.toInt() ?? 0,
      totalTimeMinutes: (json['total_time_minutes'] as num?)?.toInt() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      totalExercises: (json['total_exercises'] as num?)?.toInt() ?? 0,
      maxStreak: (json['max_streak'] as num?)?.toInt() ?? 0,
      totalPrs: (json['total_prs'] as num?)?.toInt() ?? 0,
      avgNutritionAdherence: (json['avg_nutrition_adherence'] as num?)?.toDouble(),
      avgReadiness: (json['avg_readiness'] as num?)?.toDouble(),
      moodDistribution: json['mood_distribution'] != null
          ? (json['mood_distribution'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toInt()))
          : null,
      weightChangeKg: (json['weight_change_kg'] as num?)?.toDouble(),
      bodyFatChange: (json['body_fat_change'] as num?)?.toDouble(),
    );
  }

  double get completionRate {
    if (workoutsScheduled == 0) return 0;
    return (workoutsCompleted / workoutsScheduled) * 100;
  }
}

class InsightsPeriodGroup {
  final String periodStart;
  final String periodEnd;
  final Map<String, dynamic>? workouts;
  final Map<String, dynamic>? nutrition;
  final Map<String, dynamic>? readiness;
  final Map<String, dynamic>? measurements;

  const InsightsPeriodGroup({
    required this.periodStart,
    required this.periodEnd,
    this.workouts,
    this.nutrition,
    this.readiness,
    this.measurements,
  });

  factory InsightsPeriodGroup.fromJson(Map<String, dynamic> json) {
    return InsightsPeriodGroup(
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      workouts: json['workouts'] as Map<String, dynamic>?,
      nutrition: json['nutrition'] as Map<String, dynamic>?,
      readiness: json['readiness'] as Map<String, dynamic>?,
      measurements: json['measurements'] as Map<String, dynamic>?,
    );
  }
}

class InsightsAiNarrative {
  final String summary;
  final List<String> highlights;
  final String encouragement;
  final List<String> tips;

  const InsightsAiNarrative({
    required this.summary,
    required this.highlights,
    required this.encouragement,
    required this.tips,
  });

  factory InsightsAiNarrative.fromJson(Map<String, dynamic> json) {
    return InsightsAiNarrative(
      summary: json['summary'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      encouragement: json['encouragement'] as String? ?? '',
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
