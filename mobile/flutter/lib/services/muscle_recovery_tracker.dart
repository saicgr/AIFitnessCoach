import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Entry recording training stress on a specific muscle.
class MuscleRecoveryEntry {
  final int sets;
  final double intensity; // 0.0-1.0 (RPE/10 or similar)
  final DateTime timestamp;

  const MuscleRecoveryEntry({
    required this.sets,
    required this.intensity,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'sets': sets,
    'intensity': intensity,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MuscleRecoveryEntry.fromJson(Map<String, dynamic> json) {
    return MuscleRecoveryEntry(
      sets: json['sets'] as int,
      intensity: (json['intensity'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Per-muscle recovery tracker using exponential decay.
///
/// Recovery formula: `score = 100 * (1 - fatigue * e^(-k * hoursElapsed))`
/// where fatigue = sets * intensity, k varies by muscle group.
///
/// Recovery rate constants (per hour):
/// - Fast recovery (calves, abs, forearms): k = 0.083 (~12h half-life)
/// - Medium recovery (shoulders, traps, biceps, triceps): k = 0.063 (~16h half-life)
/// - Slow recovery (chest, back, quads, hamstrings, glutes): k = 0.042 (~24h half-life)
class MuscleRecoveryTracker {
  static const _prefsKey = 'quick_workout_muscle_recovery';

  /// Recovery rate constants by muscle group (per hour).
  static const Map<String, double> _recoveryRates = {
    'calves': 0.083,
    'abs': 0.083,
    'obliques': 0.083,
    'forearms': 0.083,
    'shoulders': 0.063,
    'traps': 0.063,
    'biceps': 0.063,
    'triceps': 0.063,
    'chest': 0.042,
    'back': 0.042,
    'quads': 0.042,
    'hamstrings': 0.042,
    'glutes': 0.042,
    'lower_back': 0.042,
    'hip_flexors': 0.042,
  };

  /// Load all recovery entries from SharedPreferences.
  static Future<Map<String, List<MuscleRecoveryEntry>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<MuscleRecoveryEntry>>{};
      for (final entry in decoded.entries) {
        final list = (entry.value as List)
            .map((e) => MuscleRecoveryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        result[entry.key] = list;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Save recovery entries to SharedPreferences.
  ///
  /// Prunes entries older than 72 hours to keep storage compact.
  static Future<void> save(Map<String, List<MuscleRecoveryEntry>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(hours: 72));

    // Prune old entries
    final pruned = <String, List<MuscleRecoveryEntry>>{};
    for (final entry in data.entries) {
      final fresh = entry.value.where((e) => e.timestamp.isAfter(cutoff)).toList();
      if (fresh.isNotEmpty) {
        pruned[entry.key] = fresh;
      }
    }

    final encoded = <String, dynamic>{};
    for (final entry in pruned.entries) {
      encoded[entry.key] = entry.value.map((e) => e.toJson()).toList();
    }
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }

  /// Record a workout's muscle stress.
  ///
  /// [muscleSetCounts] maps muscle name to (sets, averageIntensity).
  static Future<void> recordWorkout(
    Map<String, (int sets, double intensity)> muscleSetCounts,
  ) async {
    final data = await load();
    final now = DateTime.now();

    for (final entry in muscleSetCounts.entries) {
      final muscle = entry.key.toLowerCase();
      final (sets, intensity) = entry.value;
      final existing = data[muscle] ?? [];
      existing.add(MuscleRecoveryEntry(
        sets: sets,
        intensity: intensity,
        timestamp: now,
      ));
      data[muscle] = existing;
    }

    await save(data);
  }

  /// Get recovery score (0-100) for a specific muscle.
  ///
  /// 100 = fully recovered, 0 = fully fatigued.
  static double getRecoveryScore(
    String muscle,
    List<MuscleRecoveryEntry> entries, {
    DateTime? now,
  }) {
    if (entries.isEmpty) return 100.0;

    final currentTime = now ?? DateTime.now();
    final k = _recoveryRates[muscle.toLowerCase()] ?? 0.042;

    double totalFatigue = 0;
    for (final entry in entries) {
      final hoursElapsed = currentTime.difference(entry.timestamp).inMinutes / 60.0;
      if (hoursElapsed < 0) continue; // future entries (shouldn't happen)

      final fatigue = entry.sets * entry.intensity;
      totalFatigue += fatigue * exp(-k * hoursElapsed);
    }

    // Normalize: 10 sets at RPE 10 = roughly max fatigue
    final normalizedFatigue = (totalFatigue / 10.0).clamp(0.0, 1.0);
    return (100.0 * (1.0 - normalizedFatigue)).clamp(0.0, 100.0);
  }

  /// Get recovery scores for all tracked muscles.
  static Future<Map<String, double>> getAllRecoveryScores() async {
    final data = await load();
    final scores = <String, double>{};

    for (final entry in data.entries) {
      scores[entry.key] = getRecoveryScore(entry.key, entry.value);
    }

    return scores;
  }

  /// Adjust recovery scores based on HRV/sleep modifiers.
  ///
  /// If HRV is suppressed (volumeMultiplier < 0.95), reduce all recovery
  /// scores proportionally. This feeds into exercise selection to
  /// prioritize more-recovered muscles.
  static Map<String, double> adjustRecoveryScoresWithHrv(
    Map<String, double> scores,
    double hrvVolumeMultiplier,
  ) {
    // No adjustment needed if multiplier is normal or above
    if (hrvVolumeMultiplier >= 0.95) return scores;

    // Scale factor: how much to reduce recovery scores
    // hrvMult 0.80 -> reduce by 20%, hrvMult 0.90 -> reduce by 10%
    final reductionFactor = hrvVolumeMultiplier;

    return scores.map((muscle, score) {
      // Reduce recovery score proportionally
      final adjusted = score * reductionFactor;
      return MapEntry(muscle, adjusted.clamp(0.0, 100.0));
    });
  }
}
