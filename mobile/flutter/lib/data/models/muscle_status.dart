import 'package:flutter/material.dart';
import 'scores.dart';

/// Training status for a muscle group based on volume landmarks.
enum MuscleStatus {
  needsWork,
  recovering,
  ready,
  needsRest,
  overtrained;

  /// Full display label.
  String get label {
    switch (this) {
      case MuscleStatus.needsWork:
        return 'Needs Work';
      case MuscleStatus.recovering:
        return 'Recovering';
      case MuscleStatus.ready:
        return 'Ready';
      case MuscleStatus.needsRest:
        return 'Needs Rest';
      case MuscleStatus.overtrained:
        return 'Overtrained';
    }
  }

  /// Short label for compact UI.
  String get shortLabel {
    switch (this) {
      case MuscleStatus.needsWork:
        return 'Low';
      case MuscleStatus.recovering:
        return 'High';
      case MuscleStatus.ready:
        return 'Good';
      case MuscleStatus.needsRest:
        return 'Rest';
      case MuscleStatus.overtrained:
        return 'Over';
    }
  }

  /// Icon for this status.
  IconData get icon {
    switch (this) {
      case MuscleStatus.needsWork:
        return Icons.arrow_upward;
      case MuscleStatus.recovering:
        return Icons.update;
      case MuscleStatus.ready:
        return Icons.check_circle;
      case MuscleStatus.needsRest:
        return Icons.hotel;
      case MuscleStatus.overtrained:
        return Icons.warning_rounded;
    }
  }

  /// Status color.
  Color get color {
    switch (this) {
      case MuscleStatus.needsWork:
        return const Color(0xFF3B82F6);
      case MuscleStatus.recovering:
        return const Color(0xFFEAB308);
      case MuscleStatus.ready:
        return const Color(0xFF22C55E);
      case MuscleStatus.needsRest:
        return const Color(0xFFF97316);
      case MuscleStatus.overtrained:
        return const Color(0xFFEF4444);
    }
  }

  /// Number of filled segments (1-5) for the status bar.
  int get filledSegments {
    switch (this) {
      case MuscleStatus.needsWork:
        return 1;
      case MuscleStatus.recovering:
        return 2;
      case MuscleStatus.ready:
        return 3;
      case MuscleStatus.needsRest:
        return 4;
      case MuscleStatus.overtrained:
        return 5;
    }
  }

  /// Short description for info sheet.
  String get description {
    switch (this) {
      case MuscleStatus.needsWork:
        return 'Below minimum effective volume';
      case MuscleStatus.recovering:
        return 'High volume, watch for strength decline';
      case MuscleStatus.ready:
        return 'Optimal training zone';
      case MuscleStatus.needsRest:
        return 'At max recoverable volume — deload soon';
      case MuscleStatus.overtrained:
        return 'Volume far exceeds recovery capacity';
    }
  }
}

/// Volume landmarks (sets/week) for a muscle group.
class VolumeLandmarks {
  final int mev; // Minimum Effective Volume
  final int mavHigh; // Maximum Adaptive Volume (upper bound)
  final int mrv; // Maximum Recoverable Volume

  const VolumeLandmarks({
    required this.mev,
    required this.mavHigh,
    required this.mrv,
  });

  /// Return scaled landmarks based on training level multiplier.
  VolumeLandmarks scaled(double multiplier) {
    return VolumeLandmarks(
      mev: (mev * multiplier).round(),
      mavHigh: (mavHigh * multiplier).round(),
      mrv: (mrv * multiplier).round(),
    );
  }
}

/// RP-based volume landmarks per muscle group (intermediate baseline).
const Map<String, VolumeLandmarks> _baseVolumeLandmarks = {
  'chest': VolumeLandmarks(mev: 10, mavHigh: 20, mrv: 22),
  'upper_back': VolumeLandmarks(mev: 10, mavHigh: 22, mrv: 25),
  'lats': VolumeLandmarks(mev: 10, mavHigh: 22, mrv: 25),
  'shoulders': VolumeLandmarks(mev: 8, mavHigh: 22, mrv: 26),
  'quadriceps': VolumeLandmarks(mev: 8, mavHigh: 18, mrv: 20),
  'hamstrings': VolumeLandmarks(mev: 6, mavHigh: 16, mrv: 20),
  'glutes': VolumeLandmarks(mev: 4, mavHigh: 12, mrv: 16),
  'biceps': VolumeLandmarks(mev: 8, mavHigh: 20, mrv: 26),
  'triceps': VolumeLandmarks(mev: 6, mavHigh: 14, mrv: 18),
  'calves': VolumeLandmarks(mev: 8, mavHigh: 16, mrv: 20),
  'abs': VolumeLandmarks(mev: 4, mavHigh: 16, mrv: 20),
  'traps': VolumeLandmarks(mev: 6, mavHigh: 20, mrv: 26),
  'forearms': VolumeLandmarks(mev: 4, mavHigh: 14, mrv: 18),
  'lower_back': VolumeLandmarks(mev: 4, mavHigh: 10, mrv: 14),
};

const _defaultLandmarks = VolumeLandmarks(mev: 6, mavHigh: 16, mrv: 20);

/// Level-based scaling multiplier.
double _levelMultiplier(StrengthLevel level) {
  switch (level) {
    case StrengthLevel.beginner:
      return 0.70;
    case StrengthLevel.novice:
      return 0.85;
    case StrengthLevel.intermediate:
      return 1.0;
    case StrengthLevel.advanced:
      return 1.15;
    case StrengthLevel.elite:
      return 1.30;
  }
}

/// Determine the training status for a single muscle.
MuscleStatus determineMuscleStatus({
  required StrengthScoreData muscleData,
  ReadinessScore? readiness,
}) {
  final sets = muscleData.weeklySets;
  final trend = muscleData.trendDirection;
  final declining = trend == TrendDirection.declining;

  final baseLandmarks =
      _baseVolumeLandmarks[muscleData.muscleGroup] ?? _defaultLandmarks;
  final landmarks = baseLandmarks.scaled(_levelMultiplier(muscleData.level));

  var effectiveMrv = landmarks.mrv.toDouble();
  if (readiness != null && readiness.readinessScore < 40) {
    effectiveMrv *= 0.8;
  }

  // Decision flow — first match wins
  if (sets > effectiveMrv * 1.2) return MuscleStatus.overtrained;
  if (sets > effectiveMrv && declining) return MuscleStatus.overtrained;
  if (sets >= effectiveMrv) return MuscleStatus.needsRest;
  if (readiness != null &&
      readiness.readinessScore < 40 &&
      sets > landmarks.mavHigh) {
    return MuscleStatus.needsRest;
  }
  if (sets > landmarks.mavHigh) return MuscleStatus.recovering;
  if (sets >= landmarks.mev && declining) return MuscleStatus.recovering;
  if (sets < landmarks.mev) return MuscleStatus.needsWork;

  // MEV..mavHigh, not declining
  return MuscleStatus.ready;
}

/// Compute statuses for all muscles at once.
Map<String, MuscleStatus> computeAllMuscleStatuses({
  required Map<String, StrengthScoreData> muscleScores,
  ReadinessScore? readiness,
}) {
  final result = <String, MuscleStatus>{};
  for (final entry in muscleScores.entries) {
    result[entry.key] = determineMuscleStatus(
      muscleData: entry.value,
      readiness: readiness,
    );
  }
  return result;
}

/// Volume landmarks table data for display in info sheet.
/// Returns list of (displayName, mev, mavRange, mrv).
List<({String name, int mev, String mavRange, int mrv})>
    get volumeGuidelinesTable {
  return [
    (name: 'Chest', mev: 10, mavRange: '12-20', mrv: 22),
    (name: 'Back', mev: 10, mavRange: '14-22', mrv: 25),
    (name: 'Shoulders', mev: 8, mavRange: '16-22', mrv: 26),
    (name: 'Quads', mev: 8, mavRange: '12-18', mrv: 20),
    (name: 'Hamstrings', mev: 6, mavRange: '10-16', mrv: 20),
    (name: 'Biceps', mev: 8, mavRange: '14-20', mrv: 26),
    (name: 'Triceps', mev: 6, mavRange: '10-14', mrv: 18),
    (name: 'Calves', mev: 8, mavRange: '12-16', mrv: 20),
    (name: 'Glutes', mev: 4, mavRange: '8-12', mrv: 16),
    (name: 'Abs', mev: 4, mavRange: '8-16', mrv: 20),
    (name: 'Traps', mev: 6, mavRange: '12-20', mrv: 26),
    (name: 'Lower Back', mev: 4, mavRange: '6-10', mrv: 14),
  ];
}
