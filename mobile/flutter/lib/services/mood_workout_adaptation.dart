import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/mood.dart';
import '../data/models/workout_style.dart';

/// Per-user learned preference: for a given (mood, style), how often does
/// the user actually complete the workout? Used to personalize the
/// recommended style over time while keeping the research default visible.
@immutable
class StyleCompletionStats {
  final int generated;
  final int completed;

  const StyleCompletionStats({this.generated = 0, this.completed = 0});

  double get completionRate =>
      generated == 0 ? 0 : completed / generated;

  StyleCompletionStats plusGenerated() =>
      StyleCompletionStats(generated: generated + 1, completed: completed);

  StyleCompletionStats plusCompleted() =>
      StyleCompletionStats(generated: generated, completed: completed + 1);

  Map<String, dynamic> toJson() =>
      {'generated': generated, 'completed': completed};

  factory StyleCompletionStats.fromJson(Map<String, dynamic> j) =>
      StyleCompletionStats(
        generated: (j['generated'] as num?)?.toInt() ?? 0,
        completed: (j['completed'] as num?)?.toInt() ?? 0,
      );
}

/// Lightweight mood workout adaptation engine.
///
/// Persists a (mood, style) → stats map in SharedPreferences. Stays local-
/// only (no Drift migration required) and syncs opportunistically via the
/// existing context logging pipeline when events ship to the backend.
class MoodWorkoutAdaptation {
  static const _key = 'mood_workout_adaptation_v1';

  /// Personalized style for the given mood, or null if there isn't enough
  /// history to override the preset's default. Threshold: at least 3
  /// generations for that mood with ≥60 % completion rate.
  static Future<WorkoutStyle?> personalizedStyleFor(Mood mood) async {
    final stats = await _load();
    final moodStats = stats[mood.value] ?? const <String, StyleCompletionStats>{};
    if (moodStats.isEmpty) return null;

    StyleCompletionStats? best;
    WorkoutStyle? bestStyle;
    for (final entry in moodStats.entries) {
      if (entry.value.generated < 3) continue;
      if (entry.value.completionRate < 0.6) continue;
      if (best == null || entry.value.completionRate > best.completionRate) {
        best = entry.value;
        bestStyle = WorkoutStyle.fromValue(entry.key);
      }
    }
    return bestStyle;
  }

  /// Record that the user generated a mood workout with this style pairing.
  static Future<void> recordGeneration(Mood mood, WorkoutStyle style) async {
    final map = await _load();
    final moodMap =
        Map<String, StyleCompletionStats>.from(map[mood.value] ?? const {});
    moodMap[style.value] =
        (moodMap[style.value] ?? const StyleCompletionStats()).plusGenerated();
    map[mood.value] = moodMap;
    await _save(map);
  }

  /// Record that the user completed a mood workout. Call from the workout
  /// completion flow. Missing pairs are ignored silently.
  static Future<void> recordCompletion(Mood mood, WorkoutStyle style) async {
    final map = await _load();
    final moodMap =
        Map<String, StyleCompletionStats>.from(map[mood.value] ?? const {});
    final existing = moodMap[style.value];
    if (existing == null) return;
    moodMap[style.value] = existing.plusCompleted();
    map[mood.value] = moodMap;
    await _save(map);
  }

  /// Full per-(mood,style) breakdown for display in the mood history screen.
  static Future<Map<Mood, Map<WorkoutStyle, StyleCompletionStats>>>
      completionMatrix() async {
    final raw = await _load();
    final out = <Mood, Map<WorkoutStyle, StyleCompletionStats>>{};
    for (final entry in raw.entries) {
      final mood = Mood.fromString(entry.key);
      final styleMap = <WorkoutStyle, StyleCompletionStats>{};
      for (final se in entry.value.entries) {
        styleMap[WorkoutStyle.fromValue(se.key)] = se.value;
      }
      out[mood] = styleMap;
    }
    return out;
  }

  /// Clear all adaptation data (exposed for settings "reset personalization").
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------

  static Future<Map<String, Map<String, StyleCompletionStats>>>
      _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map<String, Map<String, StyleCompletionStats>>(
        (moodKey, styleBlob) {
          final styles = (styleBlob as Map<String, dynamic>)
              .map<String, StyleCompletionStats>(
            (styleKey, v) => MapEntry(
              styleKey,
              StyleCompletionStats.fromJson(v as Map<String, dynamic>),
            ),
          );
          return MapEntry(moodKey, styles);
        },
      );
    } catch (e) {
      debugPrint('⚠️ [MoodAdapt] load failed: $e');
      return {};
    }
  }

  static Future<void> _save(
      Map<String, Map<String, StyleCompletionStats>> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(map.map(
        (mood, styles) => MapEntry(
          mood,
          styles.map((k, v) => MapEntry(k, v.toJson())),
        ),
      ));
      await prefs.setString(_key, encoded);
    } catch (e) {
      debugPrint('⚠️ [MoodAdapt] save failed: $e');
    }
  }
}
