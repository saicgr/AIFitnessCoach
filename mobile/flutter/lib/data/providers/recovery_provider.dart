import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../services/health_service.dart';
import 'sleep_provider.dart';

/// Objective recovery score computed from Health Connect metrics.
class ObjectiveRecoveryScore {
  final int score;
  final int? restingHR;
  final double? hrv;
  final double? bloodOxygen;
  final SleepSummary? sleepSummary;

  const ObjectiveRecoveryScore({
    required this.score,
    this.restingHR,
    this.hrv,
    this.bloodOxygen,
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

    // --- HRV scoring (weight 25, iOS only typically) ---
    if (metrics.hrv != null) {
      final hrvPoints = _scoreHRV(metrics.hrv!, healthService);
      totalPoints += await hrvPoints;
      totalWeight += 25;
    }

    // --- Blood oxygen scoring (weight 20) ---
    if (metrics.bloodOxygen != null) {
      totalPoints += _scoreBloodOxygen(metrics.bloodOxygen!);
      totalWeight += 20;
    }

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
      hrv: metrics.hrv,
      bloodOxygen: metrics.bloodOxygen,
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

/// Score HRV by comparing today vs 7-day baseline.
/// Returns points out of 25 max.
Future<double> _scoreHRV(double todayHRV, HealthService healthService) async {
  try {
    final hrData = await healthService.getHeartRateData(days: 7);

    final hrvValues = <double>[];
    for (final point in hrData) {
      if (point.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN ||
          point.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD) {
        final v =
            (point.value as NumericHealthValue).numericValue.toDouble();
        hrvValues.add(v);
      }
    }

    if (hrvValues.isEmpty) {
      return 15; // Moderate default
    }

    final avg = hrvValues.reduce((a, b) => a + b) / hrvValues.length;

    if (todayHRV > avg) return 25; // Higher HRV than avg -- excellent
    if ((todayHRV - avg).abs() <= avg * 0.1) return 15; // Within 10% of avg
    return 5; // Lower HRV -- stressed
  } catch (e) {
    debugPrint('⚠️ [Recovery] Error scoring HRV: $e');
    return 15;
  }
}

/// Score blood oxygen saturation.
/// Returns points out of 20 max.
double _scoreBloodOxygen(double spo2) {
  if (spo2 >= 97) return 20;
  if (spo2 >= 95) return 15;
  return 5;
}

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
