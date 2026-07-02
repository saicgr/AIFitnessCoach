/// Tracks the lifecycle of a "bring your data" source import (MyFitnessPal /
/// MacroFactor / Cronometer / Apple Health CSV-or-Health flows, workout
/// history CSV) so surfaces OTHER than the import flow itself — chiefly the
/// Imports screen — can render a live mid-import progress banner and a
/// post-success summary banner.
///
/// [NutritionImportScreen] writes phase transitions here; the Imports screen
/// watches. The last completed result is persisted to SharedPreferences so
/// the "Last import" state survives an app restart.
library source_import_activity_provider;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SourceImportPhase { working, success, error }

class SourceImportActivity {
  const SourceImportActivity({
    required this.sourceId,
    required this.sourceLabel,
    required this.phase,
    required this.message,
    this.resultLines = const [],
    this.finishedAt,
  });

  /// Backend `source` id — myfitnesspal | macrofactor | cronometer |
  /// apple_health | workout_history.
  final String sourceId;
  final String sourceLabel;
  final SourceImportPhase phase;

  /// Working: the current status line ("Reading your MyFitnessPal data…").
  /// Error: the user-facing failure message.
  final String message;

  /// Success: human-readable summary lines ("213 days imported", …).
  final List<String> resultLines;
  final DateTime? finishedAt;

  Map<String, dynamic> toJson() => {
        'source_id': sourceId,
        'source_label': sourceLabel,
        'phase': phase.name,
        'message': message,
        'result_lines': resultLines,
        'finished_at': finishedAt?.toIso8601String(),
      };

  static SourceImportActivity? fromJson(Map<String, dynamic> j) {
    SourceImportPhase? phase;
    for (final p in SourceImportPhase.values) {
      if (p.name == j['phase']) phase = p;
    }
    if (phase == null) return null;
    return SourceImportActivity(
      sourceId: j['source_id'] as String? ?? '',
      sourceLabel: j['source_label'] as String? ?? '',
      phase: phase,
      message: j['message'] as String? ?? '',
      resultLines:
          (j['result_lines'] as List?)?.cast<String>() ?? const [],
      finishedAt: DateTime.tryParse(j['finished_at'] as String? ?? ''),
    );
  }
}

class SourceImportActivityNotifier extends StateNotifier<SourceImportActivity?> {
  SourceImportActivityNotifier() : super(null) {
    _restoreLastResult();
  }

  static const _prefsKey = 'source_import_last_result_v1';

  /// Restore the last completed (success/error) import so the Imports
  /// screen can show the post-import state across restarts. A `working`
  /// phase is never persisted — a killed app mid-import must not show a
  /// stuck spinner forever.
  Future<void> _restoreLastResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || !mounted || state != null) return;
      final restored = SourceImportActivity.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>());
      if (restored != null && restored.phase != SourceImportPhase.working) {
        state = restored;
      }
    } catch (_) {
      // best-effort — banner simply starts empty
    }
  }

  Future<void> _persist(SourceImportActivity? a) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (a == null || a.phase == SourceImportPhase.working) return;
      await prefs.setString(_prefsKey, jsonEncode(a.toJson()));
    } catch (_) {}
  }

  Future<void> _clearPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  void start({
    required String sourceId,
    required String sourceLabel,
    required String message,
  }) {
    state = SourceImportActivity(
      sourceId: sourceId,
      sourceLabel: sourceLabel,
      phase: SourceImportPhase.working,
      message: message,
    );
  }

  /// Update the status line of an in-flight import. No-op when idle.
  void progress(String message) {
    final s = state;
    if (s == null || s.phase != SourceImportPhase.working) return;
    state = SourceImportActivity(
      sourceId: s.sourceId,
      sourceLabel: s.sourceLabel,
      phase: SourceImportPhase.working,
      message: message,
    );
  }

  void succeed(List<String> resultLines) {
    final s = state;
    if (s == null) return;
    final done = SourceImportActivity(
      sourceId: s.sourceId,
      sourceLabel: s.sourceLabel,
      phase: SourceImportPhase.success,
      message: '',
      resultLines: resultLines,
      finishedAt: DateTime.now(),
    );
    state = done;
    _persist(done);
  }

  void fail(String message) {
    final s = state;
    if (s == null) return;
    final done = SourceImportActivity(
      sourceId: s.sourceId,
      sourceLabel: s.sourceLabel,
      phase: SourceImportPhase.error,
      message: message,
      finishedAt: DateTime.now(),
    );
    state = done;
    _persist(done);
  }

  /// User cancelled mid-flow (e.g. dismissed the preview sheet) — drop the
  /// working banner without recording a result.
  void cancel() {
    final s = state;
    if (s != null && s.phase == SourceImportPhase.working) state = null;
  }

  /// User dismissed the success/error banner on the Imports screen.
  void dismiss() {
    state = null;
    _clearPersisted();
  }
}

/// Global (non-autoDispose) so the banner survives navigation between the
/// import flow and the Imports screen.
final sourceImportActivityProvider =
    StateNotifierProvider<SourceImportActivityNotifier, SourceImportActivity?>(
        (ref) => SourceImportActivityNotifier());
