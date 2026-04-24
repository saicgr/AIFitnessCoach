/// Workout history import — PREVIEW shapes.
///
/// Models the JSON returned by `POST /workout-history/import/preview`.
/// Hand-written because this repo pins Flutter at 3.38.10 and deliberately
/// avoids `build_runner` (see `project_codegen_gotcha.md`). The generated
/// [WorkoutImportPreview.fromJson] and friends live in the .g.dart file.
library;

import 'package:flutter/foundation.dart';

part 'workout_import_preview.g.dart';

/// Top-level dry-run summary from the importer.
@immutable
class WorkoutImportPreview {
  const WorkoutImportPreview({
    required this.dryRun,
    required this.sourceApp,
    required this.mode,
    required this.confidence,
    required this.strengthRowCount,
    required this.cardioRowCount,
    required this.hasTemplate,
    required this.unresolvedExercises,
    required this.warnings,
    required this.sampleRows,
  });

  /// Always `true` for this endpoint — forwarded from the backend for clarity.
  final bool dryRun;

  /// Canonical slug for the detected source: `hevy`, `strong`, `nippard_*`, etc.
  final String sourceApp;

  /// `history` | `template` | `program_with_filled_history` | `cardio_only` | `ambiguous`.
  final String mode;

  /// Detector confidence [0,1]; <0.6 means we had to guess from the filename.
  final double confidence;

  final int strengthRowCount;
  final int cardioRowCount;

  /// True when the file contained a creator program template (RP, Nippard, etc.).
  final bool hasTemplate;

  /// Distinct raw exercise names the resolver couldn't match. Capped at 50.
  final List<String> unresolvedExercises;

  /// Detector-level + adapter-level warnings, rolled up for the UI.
  final List<String> warnings;

  /// First 20 parsed rows — raw dicts since adapters produce varied shapes.
  /// The preview sheet renders them as a simple key-value table.
  final List<Map<String, dynamic>> sampleRows;

  /// Convenience — `true` if either strength OR cardio rows came back.
  bool get hasAnyRows => strengthRowCount > 0 || cardioRowCount > 0;

  /// Confidence rendered as an integer percentage for chip labels.
  int get confidencePercent => (confidence * 100).round();

  factory WorkoutImportPreview.fromJson(Map<String, dynamic> json) =>
      _$WorkoutImportPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutImportPreviewToJson(this);
}

/// A single unresolved exercise group returned by `GET /unresolved/{user_id}`.
@immutable
class UnresolvedGroup {
  const UnresolvedGroup({
    required this.rawName,
    required this.rowCount,
    required this.sessionCount,
    required this.sourceApps,
    required this.suggestions,
    this.firstSeen,
    this.lastSeen,
  });

  /// Exercise name exactly as written in the user's source file.
  final String rawName;

  /// Total imported rows sharing this raw name.
  final int rowCount;

  /// Distinct session DATES (not sets) — a better signal for "how important".
  final int sessionCount;

  /// Every source app that produced rows for this raw name (usually just one).
  final List<String> sourceApps;

  /// Top-N (usually 3) resolver suggestions — may be empty.
  final List<UnresolvedSuggestion> suggestions;

  final DateTime? firstSeen;
  final DateTime? lastSeen;

  factory UnresolvedGroup.fromJson(Map<String, dynamic> json) =>
      _$UnresolvedGroupFromJson(json);

  Map<String, dynamic> toJson() => _$UnresolvedGroupToJson(this);
}

/// One resolver suggestion for a raw exercise name.
@immutable
class UnresolvedSuggestion {
  const UnresolvedSuggestion({
    required this.canonicalName,
    required this.confidence,
    required this.source,
    this.exerciseId,
  });

  final String canonicalName;
  final String? exerciseId;
  final double confidence;

  /// Resolver level: `alias` | `library` | `rag` | `unknown`.
  final String source;

  factory UnresolvedSuggestion.fromJson(Map<String, dynamic> json) =>
      _$UnresolvedSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$UnresolvedSuggestionToJson(this);
}
