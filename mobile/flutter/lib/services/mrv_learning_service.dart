import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import 'volume_landmark_service.dart';

/// Learned personal volume landmarks for a muscle.
class PersonalVolumeLandmarks {
  final String muscle;
  /// Personalized MRV from historical data.
  final int learnedMrv;
  /// Number of weekly data points used.
  final int dataPoints;
  /// Confidence level 0-1 based on data quantity.
  final double confidence;

  const PersonalVolumeLandmarks({
    required this.muscle,
    required this.learnedMrv,
    required this.dataPoints,
    required this.confidence,
  });
}

/// Learns individual MRV from historical volume-response data.
///
/// Requires 3+ mesocycles (12+ weeks) for high confidence.
///
/// Algorithm:
/// 1. Collect (weeklySetCount, performanceChange, recoveryScore, overreaching) per week
/// 2. Overreaching = avgRpe > 9.0 AND recoveryScore < 60 AND performance < -2%
/// 3. Learned MRV = 80th percentile of set counts in non-overreaching weeks
/// 4. Confidence = min(1.0, dataPoints / 16)
/// 5. Blend: finalMrv = popMrv * (1 - conf * 0.8) + learnedMrv * (conf * 0.8)
class MrvLearningService {
  final AppDatabase _db;

  MrvLearningService(this._db);

  /// Learn personal MRV for a muscle from historical volume-response data.
  ///
  /// Returns null if insufficient data (< 4 weeks).
  Future<PersonalVolumeLandmarks?> learnPersonalMrv(
    String userId,
    String muscle,
  ) async {
    final responses = await _db.volumeResponseDao.getResponsesForMuscle(
      userId, muscle, limit: 24,
    );

    if (responses.length < 4) return null;

    // Separate overreaching vs productive weeks
    final productiveWeeks = responses.where((r) => !r.wasOverreaching).toList();
    if (productiveWeeks.isEmpty) return null;

    // Sort by total sets to find 80th percentile
    final setCounts = productiveWeeks.map((r) => r.totalSets).toList()..sort();
    final p80Index = (setCounts.length * 0.80).floor().clamp(0, setCounts.length - 1);
    final learnedMrv = setCounts[p80Index];

    final confidence = min(1.0, responses.length / 16.0);

    return PersonalVolumeLandmarks(
      muscle: muscle,
      learnedMrv: learnedMrv,
      dataPoints: responses.length,
      confidence: confidence,
    );
  }

  /// Record end-of-week volume response for MRV learning.
  Future<void> recordWeeklyResponse({
    required String userId,
    required String muscle,
    required int totalSets,
    required double avgRpe,
    required double performanceChangePct,
    required double recoveryScore,
    String? mesocycleId,
  }) async {
    // Detect overreaching
    final wasOverreaching =
        avgRpe > 9.0 && recoveryScore < 60 && performanceChangePct < -2.0;

    final now = DateTime.now();
    final weekNumber = _isoWeekNumber(now);

    await _db.volumeResponseDao.insertResponse(
      CachedVolumeResponsesCompanion(
        userId: Value(userId),
        muscle: Value(muscle.toLowerCase()),
        weekNumber: Value(weekNumber),
        mesocycleId: Value(mesocycleId),
        totalSets: Value(totalSets),
        avgRpe: Value(avgRpe),
        performanceChange: Value(performanceChangePct),
        recoveryScore7d: Value(recoveryScore),
        wasOverreaching: Value(wasOverreaching),
        recordedAt: Value(now),
      ),
    );

    debugPrint('[MrvLearning] Recorded: $muscle week $weekNumber, '
        '${totalSets}sets, RPE=${avgRpe.toStringAsFixed(1)}, '
        'perf=${performanceChangePct.toStringAsFixed(1)}%, '
        'overreaching=$wasOverreaching');
  }

  /// Get personalized landmarks, blending population + individual data.
  ///
  /// Blend formula: weight = min(confidence, 0.8)
  /// finalMrv = popMrv * (1 - weight) + learnedMrv * weight
  Future<Map<String, VolumeLandmarks>> getPersonalizedLandmarks(
    String userId,
    Map<String, VolumeLandmarks> populationLandmarks,
  ) async {
    final result = Map<String, VolumeLandmarks>.from(populationLandmarks);

    for (final entry in populationLandmarks.entries) {
      final muscle = entry.key;
      final popLandmarks = entry.value;

      final personal = await learnPersonalMrv(userId, muscle);
      if (personal == null) continue;

      final weight = min(personal.confidence, 0.8);
      final blendedMrv = (popLandmarks.mrv * (1 - weight) +
              personal.learnedMrv * weight)
          .round();

      // Only apply if learned MRV is within reasonable bounds (±50% of population)
      if (blendedMrv >= (popLandmarks.mrv * 0.5).round() &&
          blendedMrv <= (popLandmarks.mrv * 1.5).round()) {
        result[muscle] = VolumeLandmarks(
          mev: popLandmarks.mev,
          mav: popLandmarks.mav,
          mrv: blendedMrv,
        );

        debugPrint('[MrvLearning] $muscle: pop MRV=${popLandmarks.mrv}, '
            'learned=${personal.learnedMrv}, blended=$blendedMrv '
            '(conf=${personal.confidence.toStringAsFixed(2)}, weight=${weight.toStringAsFixed(2)})');
      }
    }

    return result;
  }

  static int _isoWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final dayOfWeek = date.weekday;
    final weekNumber = ((dayOfYear - dayOfWeek + 10) / 7).floor();
    if (weekNumber < 1) {
      return _isoWeekNumber(DateTime(date.year - 1, 12, 28));
    }
    if (weekNumber > 52) {
      final dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday < 4) return 1;
    }
    return weekNumber;
  }
}
