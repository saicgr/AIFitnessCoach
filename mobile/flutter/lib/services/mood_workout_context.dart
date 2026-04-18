import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/mood.dart';
import '../data/models/workout_style.dart';
import 'hrv_recovery_service.dart';

/// Adjustment to a mood preset derived from real-time user context.
///
/// Values mutate the preset's style / difficulty / duration before they're
/// handed to [QuickWorkoutEngine]. A field of `null` means "leave the
/// existing value alone."
@immutable
class MoodContextAdjustment {
  final WorkoutStyle? overrideStyle;
  final String? overrideDifficulty;
  final int? durationCapMinutes;

  /// Short user-facing caption shown on the workout start screen.
  /// Explains the adjustment (e.g. "Late night — going low-impact").
  final String? caption;

  const MoodContextAdjustment({
    this.overrideStyle,
    this.overrideDifficulty,
    this.durationCapMinutes,
    this.caption,
  });

  static const none = MoodContextAdjustment();

  bool get hasAdjustment =>
      overrideStyle != null ||
      overrideDifficulty != null ||
      durationCapMinutes != null;
}

/// Evaluates contextual signals (time of day, recovery, recent streak,
/// mood repeat) and returns an adjustment that the mood workout service
/// layers on top of the raw [MoodPreset] defaults.
///
/// All checks are deterministic and fast (<5 ms). None of them block on
/// network calls — the service owns the overall 5 s safety timeout.
class MoodWorkoutContext {
  static const _prefsKeyRecentMoods = 'mood_workout_recent_moods_v1';

  /// Evaluate all signals and return the combined adjustment.
  ///
  /// [currentStyle] / [currentDifficulty] / [currentDuration] are the
  /// user's effective selections before context is applied, so we can skip
  /// redundant downgrades.
  static Future<MoodContextAdjustment> evaluate({
    required Mood mood,
    required WorkoutStyle currentStyle,
    required String currentDifficulty,
    required int currentDuration,
  }) async {
    WorkoutStyle? overrideStyle;
    String? overrideDifficulty;
    int? durationCap;
    final captions = <String>[];

    // ---- 1. Time-of-day ----
    final hour = DateTime.now().hour;
    final isLateNight = hour >= 22 || hour < 5;
    if (isLateNight && mood == Mood.angry && currentStyle == WorkoutStyle.cardio) {
      // Drop plyometrics / jumps at night — switch to low-impact bodyweight
      // so we don't wake the neighbors. User can still override.
      overrideStyle = WorkoutStyle.bodyweight;
      captions.add("Late night — keeping it low-impact");
    }

    // ---- 2. HRV / recovery ----
    try {
      final hrv = await HrvRecoveryService.getModifiers();
      if (hrv.hasData && hrv.readinessLevel == ReadinessLevel.low) {
        // Low readiness → cap intensity by one difficulty level.
        final downgraded = _downgrade(currentDifficulty);
        if (downgraded != currentDifficulty) {
          overrideDifficulty = downgraded;
          captions.add("Low readiness — capping intensity");
        }
      }
    } catch (_) {
      // Health permissions not granted / unavailable — skip silently.
    }

    // ---- 3. Comeback streak ----
    // If the last mood workout was ≥3 days ago, ease the user back in by
    // dropping one difficulty level.
    final gapDays = await _daysSinceLastMoodWorkout();
    if (gapDays != null && gapDays >= 3) {
      final downgraded = _downgrade(overrideDifficulty ?? currentDifficulty);
      if (downgraded != (overrideDifficulty ?? currentDifficulty)) {
        overrideDifficulty = downgraded;
        captions.add("Welcome back — easing in");
      }
    }

    // ---- 4. Mood repeat guardrail ----
    // If the user has tapped the same mood 3 times in the last 24 h,
    // tighten duration so they don't grind into overtraining.
    final repeatCount = await _recentMoodCount(mood);
    if (repeatCount >= 3 && currentDuration > 20) {
      durationCap = 20;
      captions.add("3rd ${mood.label.toLowerCase()} session today — keeping it short");
    }

    final caption = captions.isEmpty ? null : captions.first;
    return MoodContextAdjustment(
      overrideStyle: overrideStyle,
      overrideDifficulty: overrideDifficulty,
      durationCapMinutes: durationCap,
      caption: caption,
    );
  }

  /// Record that this mood was picked now, so future evaluations can
  /// compute streaks / repeat counts.
  static Future<void> recordMoodPick(Mood mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyRecentMoods) ?? [];
      final nowIso = DateTime.now().toIso8601String();
      list.add('${mood.value}|$nowIso');
      // Keep last 50 picks — plenty for 1-week windows.
      if (list.length > 50) {
        list.removeRange(0, list.length - 50);
      }
      await prefs.setStringList(_prefsKeyRecentMoods, list);
    } catch (_) {
      // Non-critical.
    }
  }

  // ---------------------------------------------------------------------------

  static String _downgrade(String difficulty) {
    switch (difficulty) {
      case 'hell':
        return 'hard';
      case 'hard':
        return 'medium';
      case 'medium':
        return 'easy';
      case 'easy':
      default:
        return 'easy';
    }
  }

  /// Returns how many days since the most recent mood workout, or `null`
  /// if there is no prior record.
  static Future<int?> _daysSinceLastMoodWorkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyRecentMoods) ?? [];
      if (list.isEmpty) return null;
      final last = list.last.split('|');
      if (last.length < 2) return null;
      final dt = DateTime.tryParse(last[1]);
      if (dt == null) return null;
      return DateTime.now().difference(dt).inDays;
    } catch (_) {
      return null;
    }
  }

  /// Count how many times the given mood was picked in the last 24 h.
  static Future<int> _recentMoodCount(Mood mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyRecentMoods) ?? [];
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      int n = 0;
      for (final entry in list) {
        final parts = entry.split('|');
        if (parts.length != 2) continue;
        if (parts[0] != mood.value) continue;
        final dt = DateTime.tryParse(parts[1]);
        if (dt != null && dt.isAfter(cutoff)) n++;
      }
      return n;
    } catch (_) {
      return 0;
    }
  }
}
