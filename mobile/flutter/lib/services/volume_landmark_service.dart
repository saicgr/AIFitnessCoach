import 'dart:convert';

import 'package:flutter/services.dart';

import 'mrv_learning_service.dart';

/// Volume landmarks (MEV/MAV/MRV) for a muscle at a given fitness level.
class VolumeLandmarks {
  /// Minimum Effective Volume - weekly sets below this produce no growth.
  final int mev;

  /// Maximum Adaptive Volume - sweet spot for most growth.
  final int mav;

  /// Maximum Recoverable Volume - weekly sets above this impair recovery.
  final int mrv;

  const VolumeLandmarks({
    required this.mev,
    required this.mav,
    required this.mrv,
  });
}

/// Volume status for a muscle group relative to its landmarks.
enum VolumeStatus {
  /// Below MEV - not enough stimulus for growth
  belowMev,

  /// Between MEV and MRV - productive training zone
  productive,

  /// Near MRV (within 2 sets) - approaching recovery limit
  nearMrv,

  /// Above MRV - overreaching, recovery impaired
  overreaching,
}

/// Service that loads and personalizes research-backed volume landmarks.
///
/// Based on Israetel et al. 2019 - Scientific Principles of Hypertrophy Training.
/// MEV/MAV/MRV values per muscle group adjusted by fitness level, RPE feedback,
/// and recovery scores.
class VolumeLandmarkService {
  static Map<String, Map<String, VolumeLandmarks>>? _cache;

  /// Load volume landmarks from bundled JSON asset.
  ///
  /// Caches in memory after first load.
  static Future<Map<String, Map<String, VolumeLandmarks>>> _loadAll() async {
    if (_cache != null) return _cache!;

    final jsonStr =
        await rootBundle.loadString('assets/data/volume_landmarks.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final result = <String, Map<String, VolumeLandmarks>>{};
    for (final muscleEntry in data.entries) {
      if (muscleEntry.key.startsWith('_')) continue; // skip metadata
      final levelMap = muscleEntry.value as Map<String, dynamic>;
      final levels = <String, VolumeLandmarks>{};
      for (final levelEntry in levelMap.entries) {
        final vals = levelEntry.value as Map<String, dynamic>;
        levels[levelEntry.key] = VolumeLandmarks(
          mev: vals['mev'] as int,
          mav: vals['mav'] as int,
          mrv: vals['mrv'] as int,
        );
      }
      result[muscleEntry.key] = levels;
    }

    _cache = result;
    return result;
  }

  /// Get volume landmarks for a specific fitness level.
  ///
  /// Returns a map of muscle -> VolumeLandmarks.
  static Future<Map<String, VolumeLandmarks>> getLandmarks(
    String fitnessLevel,
  ) async {
    final all = await _loadAll();
    final level = fitnessLevel.toLowerCase();
    final effectiveLevel =
        ['beginner', 'intermediate', 'advanced'].contains(level)
            ? level
            : 'intermediate';

    final result = <String, VolumeLandmarks>{};
    for (final entry in all.entries) {
      final landmarks = entry.value[effectiveLevel];
      if (landmarks != null) {
        result[entry.key] = landmarks;
      }
    }
    return result;
  }

  /// Personalize volume landmarks based on RPE feedback and recovery.
  ///
  /// Adjustments:
  /// - Recovery < 60% -> MRV * 0.85 (reduce max to prevent overtraining)
  /// - Recovery > 90% -> MRV * 1.05 (allow slightly more volume)
  /// - Avg RPE < 6.5 for 3+ sessions -> MEV * 1.10 (need more stimulus)
  static Map<String, VolumeLandmarks> personalize(
    Map<String, VolumeLandmarks> base, {
    Map<String, double> recoveryScores = const {},
    double? globalAvgRpe,
    int rpeLowSessionCount = 0,
  }) {
    final result = <String, VolumeLandmarks>{};

    for (final entry in base.entries) {
      final muscle = entry.key;
      var landmarks = entry.value;

      // Recovery-based MRV adjustment
      final recovery = recoveryScores[muscle];
      if (recovery != null) {
        if (recovery < 60) {
          landmarks = VolumeLandmarks(
            mev: landmarks.mev,
            mav: landmarks.mav,
            mrv: (landmarks.mrv * 0.85).round(),
          );
        } else if (recovery > 90) {
          landmarks = VolumeLandmarks(
            mev: landmarks.mev,
            mav: landmarks.mav,
            mrv: (landmarks.mrv * 1.05).round(),
          );
        }
      }

      // RPE-based MEV adjustment
      if (globalAvgRpe != null &&
          globalAvgRpe < 6.5 &&
          rpeLowSessionCount >= 3) {
        landmarks = VolumeLandmarks(
          mev: (landmarks.mev * 1.10).round(),
          mav: landmarks.mav,
          mrv: landmarks.mrv,
        );
      }

      result[muscle] = landmarks;
    }

    return result;
  }

  /// Apply individual MRV learning on top of population-personalized landmarks.
  ///
  /// [personalized] is the result of [personalize()] (population + recovery/RPE adjustments).
  /// [learned] contains per-muscle learned MRV data from [MrvLearningService].
  static Map<String, VolumeLandmarks> applyIndividualLearning(
    Map<String, VolumeLandmarks> personalized,
    Map<String, PersonalVolumeLandmarks> learned,
  ) {
    if (learned.isEmpty) return personalized;

    final result = Map<String, VolumeLandmarks>.from(personalized);
    for (final entry in learned.entries) {
      final muscle = entry.key;
      final personal = entry.value;
      final base = personalized[muscle];
      if (base == null) continue;

      final weight = personal.confidence.clamp(0.0, 0.8);
      final blendedMrv = (base.mrv * (1 - weight) + personal.learnedMrv * weight).round();

      // Sanity bounds: +/-50% of base MRV
      if (blendedMrv >= (base.mrv * 0.5).round() &&
          blendedMrv <= (base.mrv * 1.5).round()) {
        result[muscle] = VolumeLandmarks(
          mev: base.mev,
          mav: base.mav,
          mrv: blendedMrv,
        );
      }
    }

    return result;
  }

  /// Get volume status for a muscle given current weekly sets.
  static VolumeStatus getVolumeStatus(
    int currentSets,
    VolumeLandmarks landmarks,
  ) {
    if (currentSets < landmarks.mev) return VolumeStatus.belowMev;
    if (currentSets > landmarks.mrv) return VolumeStatus.overreaching;
    if (currentSets >= landmarks.mrv - 2) return VolumeStatus.nearMrv;
    return VolumeStatus.productive;
  }
}
