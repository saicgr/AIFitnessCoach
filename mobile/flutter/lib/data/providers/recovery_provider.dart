import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../services/health_service.dart';

// ============================================
// Sleep Provider (merged from sleep_provider.dart)
// ============================================

/// Provider that fetches last night's sleep data from Health Connect.
/// Returns null if Health Connect is not connected.
final sleepProvider = FutureProvider.autoDispose<SleepSummary?>((ref) async {
  final syncState = ref.watch(healthSyncProvider);
  if (!syncState.isConnected) return null;

  final healthService = ref.watch(healthServiceProvider);
  try {
    final sleep = await healthService.getSleepData(days: 1);
    if (!sleep.hasData) return null;
    return sleep;
  } catch (e) {
    debugPrint('❌ [SleepProvider] Error fetching sleep data: $e');
    return null;
  }
});

/// Objective recovery score computed from Health Connect metrics.
///
/// Note: `hrv` and `bloodOxygen` were removed 2026-05-07 — Google Play Health
/// Connect minimum-scope policy required dropping those permissions. Score
/// is now derived from resting heart rate + sleep only.
class ObjectiveRecoveryScore {
  final int score;
  final int? restingHR;
  final SleepSummary? sleepSummary;

  const ObjectiveRecoveryScore({
    required this.score,
    this.restingHR,
    this.sleepSummary,
  });

  /// Label based on score thresholds.
  String get label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}

/// Provider that computes an objective recovery score from health data.
/// Returns null if Health Connect is not connected.
final recoveryProvider =
    FutureProvider.autoDispose<ObjectiveRecoveryScore?>((ref) async {
  final syncState = ref.watch(healthSyncProvider);
  if (!syncState.isConnected) return null;

  final healthService = ref.watch(healthServiceProvider);

  try {
    // Fetch recovery metrics and sleep in parallel
    final results = await Future.wait([
      healthService.getRecoveryMetrics(),
      ref.watch(sleepProvider.future),
    ]);

    final metrics = results[0] as RecoveryMetrics;
    final sleep = results[1] as SleepSummary?;

    // Score each available component
    double totalPoints = 0;
    double totalWeight = 0;

    // --- Resting HR scoring (weight 30) ---
    if (metrics.restingHR != null) {
      final hrPoints = _scoreRestingHR(metrics.restingHR!, healthService);
      totalPoints += await hrPoints;
      totalWeight += 30;
    }

    // HRV + blood-oxygen scoring removed 2026-05-07 (Google Play Health
    // Connect minimum scope). Score now weighted across RHR + Sleep only.

    // --- Sleep quality scoring (weight 25) ---
    if (sleep != null && sleep.hasData) {
      totalPoints += _scoreSleepQuality(sleep.quality);
      totalWeight += 25;
    }

    // Compute weighted average normalized to 100
    int finalScore = 0;
    if (totalWeight > 0) {
      finalScore = ((totalPoints / totalWeight) * 100).round().clamp(0, 100);
    }

    return ObjectiveRecoveryScore(
      score: finalScore,
      restingHR: metrics.restingHR,
      sleepSummary: sleep,
    );
  } catch (e) {
    debugPrint('❌ [RecoveryProvider] Error computing recovery score: $e');
    return null;
  }
});

/// Score resting HR by comparing today vs 7-day baseline.
/// Returns points out of 30 max.
Future<double> _scoreRestingHR(
    int todayHR, HealthService healthService) async {
  try {
    final hrData = await healthService.getHeartRateData(days: 7);

    // Extract resting HR values from the 7-day history
    final restingValues = <int>[];
    for (final point in hrData) {
      if (point.type == HealthDataType.RESTING_HEART_RATE) {
        final v =
            (point.value as NumericHealthValue).numericValue.toInt();
        restingValues.add(v);
      }
    }

    if (restingValues.isEmpty) {
      // No historical data to compare -- give a moderate score
      return 20;
    }

    final avg = restingValues.reduce((a, b) => a + b) / restingValues.length;
    final diff = todayHR - avg;

    if (diff < -5) return 30; // Lower than avg by >5 bpm -- great recovery
    if (diff <= 5) return 20; // Within 5 bpm of avg -- normal
    return 10; // Higher by >5 bpm -- elevated, lower recovery
  } catch (e) {
    debugPrint('⚠️ [Recovery] Error scoring resting HR: $e');
    return 20; // Default moderate score on error
  }
}

// _scoreHRV and _scoreBloodOxygen removed 2026-05-07 — Google Play Health
// Connect minimum-scope policy required dropping HRV / SpO2 permissions, so
// the gating callers in `recoveryProvider` were deleted and these helpers
// are no longer reachable.

/// Score sleep quality string.
/// Returns points out of 25 max.
double _scoreSleepQuality(String quality) {
  switch (quality) {
    case 'excellent':
      return 25;
    case 'good':
      return 20;
    case 'fair':
      return 10;
    case 'poor':
      return 5;
    default:
      return 5;
  }
}
