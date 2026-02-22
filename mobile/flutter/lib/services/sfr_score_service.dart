import 'dart:convert';
import 'package:flutter/services.dart';

/// SFR (Stimulus-to-Fatigue Ratio) data for a single exercise.
class ExerciseSfr {
  /// SFR score 0.3-1.0 (higher = more efficient per fatigue unit)
  final double sfr;
  /// Systemic fatigue 0.0-1.0 (higher = more tiring overall)
  final double systemicFatigue;
  /// Local stimulus 0.0-1.0 (higher = better target muscle activation)
  final double localStimulus;

  const ExerciseSfr({
    required this.sfr,
    required this.systemicFatigue,
    required this.localStimulus,
  });
}

/// Service that loads research-backed SFR data and provides O(1) lookups.
///
/// Uses fuzzy matching: "Barbell Back Squat" matches "squat" pattern.
/// Falls back to compound/isolation defaults based on name heuristics.
class SfrScoreService {
  static Map<String, ExerciseSfr>? _patternCache;
  static ExerciseSfr? _defaultCompound;
  static ExerciseSfr? _defaultIsolation;

  static Future<void> _ensureLoaded() async {
    if (_patternCache != null) return;

    final jsonStr = await rootBundle.loadString('assets/data/exercise_sfr.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final patterns = data['patterns'] as Map<String, dynamic>;
    _patternCache = {};
    for (final entry in patterns.entries) {
      final vals = entry.value as Map<String, dynamic>;
      _patternCache![entry.key.toLowerCase()] = ExerciseSfr(
        sfr: (vals['sfr'] as num).toDouble(),
        systemicFatigue: (vals['systemic_fatigue'] as num).toDouble(),
        localStimulus: (vals['local_stimulus'] as num).toDouble(),
      );
    }

    final defaults = data['defaults'] as Map<String, dynamic>;
    final compoundVals = defaults['compound'] as Map<String, dynamic>;
    _defaultCompound = ExerciseSfr(
      sfr: (compoundVals['sfr'] as num).toDouble(),
      systemicFatigue: (compoundVals['systemic_fatigue'] as num).toDouble(),
      localStimulus: (compoundVals['local_stimulus'] as num).toDouble(),
    );
    final isolationVals = defaults['isolation'] as Map<String, dynamic>;
    _defaultIsolation = ExerciseSfr(
      sfr: (isolationVals['sfr'] as num).toDouble(),
      systemicFatigue: (isolationVals['systemic_fatigue'] as num).toDouble(),
      localStimulus: (isolationVals['local_stimulus'] as num).toDouble(),
    );
  }

  /// Get SFR data for an exercise by name. Fuzzy-matches against known patterns.
  static Future<ExerciseSfr> getSfr(String exerciseName) async {
    await _ensureLoaded();
    final lower = exerciseName.toLowerCase();

    // Exact key match first
    if (_patternCache!.containsKey(lower)) {
      return _patternCache![lower]!;
    }

    // Fuzzy: check if exercise name contains any pattern key
    for (final entry in _patternCache!.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fallback: compound vs isolation heuristic
    return _isLikelyCompound(lower) ? _defaultCompound! : _defaultIsolation!;
  }

  /// Compute fatigue-adjusted sets = rawSets * systemicFatigue.
  /// 4 sets of squat (0.9) = 3.6 fatigue sets.
  /// 4 sets of leg extension (0.15) = 0.6 fatigue sets.
  static Future<double> computeFatigueAdjustedSets(
    String exerciseName, int rawSets,
  ) async {
    final sfr = await getSfr(exerciseName);
    return rawSets * sfr.systemicFatigue;
  }

  /// Compute stimulus sets = rawSets * localStimulus.
  static Future<double> computeStimulusSets(
    String exerciseName, int rawSets,
  ) async {
    final sfr = await getSfr(exerciseName);
    return rawSets * sfr.localStimulus;
  }

  /// Batch lookup: get SFR scores for multiple exercises at once.
  /// Returns a map of exercise name (lowercase) -> SFR score (0-1).
  static Future<Map<String, double>> batchGetSfrScores(
    List<String> exerciseNames,
  ) async {
    await _ensureLoaded();
    final result = <String, double>{};
    for (final name in exerciseNames) {
      final sfr = await getSfr(name);
      result[name.toLowerCase()] = sfr.sfr;
    }
    return result;
  }

  static bool _isLikelyCompound(String name) {
    const compoundPatterns = [
      'bench press', 'squat', 'deadlift', 'overhead press', 'military press',
      'barbell row', 'bent over row', 'pull up', 'pull-up', 'chin up',
      'chin-up', 'dip', 'lunge', 'hip thrust', 'clean', 'snatch',
      'push press', 'front squat', 'romanian deadlift', 'rdl', 'pendlay row',
      't-bar row', 'incline press', 'decline press', 'leg press', 'hack squat',
    ];
    return compoundPatterns.any((p) => name.contains(p));
  }
}
