import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/health_service.dart';

/// Recovery readiness levels based on combined HRV/sleep/HR data.
enum ReadinessLevel { low, moderate, high, peak }

/// Recovery modifiers computed from health data.
class HrvRecoveryModifiers {
  /// Volume multiplier (0.7-1.1). Applied to set counts.
  final double volumeMultiplier;
  /// Intensity multiplier (0.85-1.05). Applied to working weight.
  final double intensityMultiplier;
  /// Readiness category for UI display.
  final ReadinessLevel readinessLevel;
  /// User-facing explanation (e.g., "Poor sleep (5.2h) -> -15% volume").
  final String? explanation;
  /// Whether actual health data was available.
  final bool hasData;

  const HrvRecoveryModifiers({
    required this.volumeMultiplier,
    required this.intensityMultiplier,
    required this.readinessLevel,
    this.explanation,
    required this.hasData,
  });

  /// Neutral modifiers (no adjustment) when no data is available.
  static const neutral = HrvRecoveryModifiers(
    volumeMultiplier: 1.0,
    intensityMultiplier: 1.0,
    readinessLevel: ReadinessLevel.high,
    hasData: false,
  );

  /// Display name for the readiness level.
  String get readinessDisplayName {
    switch (readinessLevel) {
      case ReadinessLevel.low:
        return 'Low';
      case ReadinessLevel.moderate:
        return 'Moderate';
      case ReadinessLevel.high:
        return 'High';
      case ReadinessLevel.peak:
        return 'Peak';
    }
  }
}

/// Computes recovery modifiers from Health Connect/HealthKit data.
///
/// Uses a 7-day rolling baseline for HRV and resting HR, comparing
/// today's values to detect suppression or elevation.
/// Gracefully returns neutral modifiers if no health data is available.
class HrvRecoveryService {
  static const _hrvBaselineKey = 'hrv_baseline_history';
  static const _restingHrBaselineKey = 'resting_hr_baseline_history';
  static const _baselineDays = 14; // Keep 14 days for rolling window

  /// Compute recovery modifiers from health data.
  static Future<HrvRecoveryModifiers> getModifiers() async {
    try {
      final healthService = HealthService();
      final isAvailable = await healthService.isHealthConnectAvailable();
      if (!isAvailable) return HrvRecoveryModifiers.neutral;

      final hasPermission = await healthService.hasHealthPermissions();
      if (!hasPermission) return HrvRecoveryModifiers.neutral;

      // Gather all modifiers in parallel
      final results = await Future.wait([
        _getHrvModifier(healthService),
        _getSleepModifier(healthService),
        _getRestingHrModifier(healthService),
      ]);

      final hrvMult = results[0];
      final sleepMult = results[1];
      final restingHrMult = results[2];

      // At least one real data source must be available
      if (hrvMult == 1.0 && sleepMult == 1.0 && restingHrMult == 1.0) {
        return HrvRecoveryModifiers.neutral;
      }

      // Combined multipliers
      final volumeMult = (hrvMult * sleepMult).clamp(0.7, 1.1);
      final intensityMult = (restingHrMult * (sleepMult > 0.90 ? 1.0 : sleepMult)).clamp(0.85, 1.05);

      // Determine readiness level
      final combined = volumeMult;
      ReadinessLevel level;
      if (combined < 0.80) {
        level = ReadinessLevel.low;
      } else if (combined < 0.92) {
        level = ReadinessLevel.moderate;
      } else if (combined <= 1.02) {
        level = ReadinessLevel.high;
      } else {
        level = ReadinessLevel.peak;
      }

      // Build explanation
      final explanations = <String>[];
      if (hrvMult < 0.95) explanations.add('HRV suppressed');
      if (hrvMult > 1.02) explanations.add('HRV elevated');
      if (sleepMult < 0.95) {
        explanations.add('Poor sleep');
      }
      if (restingHrMult < 0.95) explanations.add('Elevated resting HR');

      String? explanation;
      if (explanations.isNotEmpty) {
        final volPct = ((1 - volumeMult) * 100).abs().round();
        final direction = volumeMult < 1.0 ? '-' : '+';
        explanation = '${explanations.join(", ")} -> $direction$volPct% volume';
      }

      debugPrint('[HrvRecovery] HRV=$hrvMult, sleep=$sleepMult, '
          'HR=$restingHrMult -> vol=$volumeMult, int=$intensityMult, '
          'level=${level.name}');

      return HrvRecoveryModifiers(
        volumeMultiplier: volumeMult,
        intensityMultiplier: intensityMult,
        readinessLevel: level,
        explanation: explanation,
        hasData: true,
      );
    } catch (e) {
      debugPrint('[HrvRecovery] Error computing modifiers: $e');
      return HrvRecoveryModifiers.neutral;
    }
  }

  /// Compute HRV-based modifier using 7-day rolling baseline.
  static Future<double> _getHrvModifier(HealthService healthService) async {
    try {
      final recovery = await healthService.getRecoveryMetrics();
      if (recovery.hrv == null || recovery.hrv! <= 0) {
        return 1.0;
      }

      final todayHrv = recovery.hrv!;

      // Update baseline history
      final baseline = await _updateBaseline(
        _hrvBaselineKey, todayHrv,
      );

      if (baseline == null) return 1.0; // Not enough data yet

      // Compare today vs 7-day rolling average
      final ratio = todayHrv / baseline;

      if (ratio > 1.10) return 1.05;  // Well recovered
      if (ratio > 0.90) return 1.0;   // Normal
      if (ratio > 0.80) return 0.90;  // Slightly suppressed
      return 0.80;                      // Significantly suppressed
    } catch (e) {
      debugPrint('[HrvRecovery] HRV modifier error: $e');
      return 1.0;
    }
  }

  /// Compute sleep-based modifier.
  static Future<double> _getSleepModifier(HealthService healthService) async {
    try {
      final sleepData = await healthService.getSleepData(days: 1);
      if (!sleepData.hasData) return 1.0;

      final totalHours = sleepData.totalMinutes / 60.0;
      final deepPct = sleepData.totalMinutes > 0
          ? sleepData.deepMinutes / sleepData.totalMinutes
          : 0.0;

      double mult;
      if (totalHours < 5) {
        mult = 0.80; // Severe restriction
      } else if (totalHours < 6) {
        mult = 0.88;
      } else if (totalHours < 7) {
        mult = 0.95;
      } else if (totalHours <= 8) {
        mult = 1.0;
      } else {
        mult = 1.02;
      }

      // Deep sleep bonus: > 20% deep -> +0.03
      if (deepPct > 0.20) {
        mult += 0.03;
      }

      return mult.clamp(0.75, 1.05);
    } catch (e) {
      debugPrint('[HrvRecovery] Sleep modifier error: $e');
      return 1.0;
    }
  }

  /// Compute resting HR deviation modifier.
  static Future<double> _getRestingHrModifier(HealthService healthService) async {
    try {
      final recovery = await healthService.getRecoveryMetrics();
      if (recovery.restingHR == null || recovery.restingHR! <= 0) {
        return 1.0;
      }

      final todayHr = recovery.restingHR!.toDouble();

      // Update baseline
      final baseline = await _updateBaseline(
        _restingHrBaselineKey, todayHr,
      );

      if (baseline == null) return 1.0;

      // Elevated HR = possible illness/overtraining
      final ratio = todayHr / baseline;
      if (ratio > 1.10) return 0.92;  // Elevated
      if (ratio < 0.95) return 1.02;  // Lower than usual (good)
      return 1.0;
    } catch (e) {
      debugPrint('[HrvRecovery] Resting HR modifier error: $e');
      return 1.0;
    }
  }

  /// Update rolling baseline and return 7-day average.
  /// Returns null if fewer than 7 days of data.
  static Future<double?> _updateBaseline(
    String prefsKey,
    double todayValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);

    var history = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        history = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {}
    }

    // Add today's value
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Don't add duplicate for same day
    if (history.isEmpty || history.last['date'] != today) {
      history.add({'value': todayValue, 'date': today});
    } else {
      // Update today's value
      history.last['value'] = todayValue;
    }

    // Prune to last 14 days
    if (history.length > _baselineDays) {
      history = history.sublist(history.length - _baselineDays);
    }

    // Save
    await prefs.setString(prefsKey, jsonEncode(history));

    // Need at least 7 days for baseline
    if (history.length < 7) return null;

    // Compute 7-day rolling average (last 7 entries)
    final recent = history.sublist(max(0, history.length - 7));
    final sum = recent.fold<double>(
      0.0, (acc, e) => acc + (e['value'] as num).toDouble(),
    );
    return sum / recent.length;
  }
}
