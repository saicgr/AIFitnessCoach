import 'package:flutter/foundation.dart';

/// A single snapshot date in the dual-series shape history.
/// Both `targetScores` and `viewerScores` are length-6 lists matching the
/// axis order: Strength, Muscle, Recovery, Consistency, Endurance, Nutrition.
@immutable
class FitnessHistoryPoint {
  final DateTime date;
  final List<double?> targetScores;
  final List<double?> viewerScores;

  const FitnessHistoryPoint({
    required this.date,
    required this.targetScores,
    required this.viewerScores,
  });

  factory FitnessHistoryPoint.fromJson(Map<String, dynamic> json) {
    List<double?> parse(dynamic raw) {
      if (raw is! List) return List.filled(6, null);
      return raw.map((v) => v == null ? null : (v as num).toDouble()).toList();
    }

    return FitnessHistoryPoint(
      date: DateTime.parse(json['date'] as String),
      targetScores: parse(json['target_scores']),
      viewerScores: parse(json['viewer_scores']),
    );
  }

  /// Scores coerced to 0 for radar rendering.
  List<double> targetForRadar() =>
      targetScores.map((v) => v ?? 0.0).toList(growable: false);
  List<double> viewerForRadar() =>
      viewerScores.map((v) => v ?? 0.0).toList(growable: false);
}

/// Full dual-series history for the peek sheet's time scrubber.
/// Points are chronological — `points.first` is the oldest date, `points.last`
/// is the most recent (today's snapshot if the cron ran).
@immutable
class FitnessShapeHistory {
  final List<FitnessHistoryPoint> points;
  final int daysBack;
  final List<String> axisLabels;

  const FitnessShapeHistory({
    required this.points,
    required this.daysBack,
    this.axisLabels = const [
      'Strength', 'Muscle', 'Recovery',
      'Consistency', 'Endurance', 'Nutrition',
    ],
  });

  factory FitnessShapeHistory.fromJson(Map<String, dynamic> json) {
    final list = (json['points'] as List? ?? []);
    return FitnessShapeHistory(
      points: list
          .map((e) => FitnessHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      daysBack: json['days_back'] as int? ?? 90,
      axisLabels: (json['axis_labels'] as List?)?.cast<String>() ??
          const [
            'Strength', 'Muscle', 'Recovery',
            'Consistency', 'Endurance', 'Nutrition',
          ],
    );
  }

  /// True when we have 2+ dates — scrubber meaningful.
  bool get isScrubberUseful => points.length >= 2;

  FitnessHistoryPoint? get latest => points.isEmpty ? null : points.last;
}
