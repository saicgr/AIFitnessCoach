// GENERATED-STYLE, HAND-WRITTEN. Do NOT run build_runner (see
// `project_codegen_gotcha.md`). Keep this file paired with the parent
// workout_import_preview.dart — rename/remove fields in both at once.

// ignore_for_file: prefer_const_constructors

part of 'workout_import_preview.dart';

WorkoutImportPreview _$WorkoutImportPreviewFromJson(Map<String, dynamic> json) =>
    WorkoutImportPreview(
      dryRun: json['dry_run'] as bool? ?? true,
      sourceApp: json['source_app']?.toString() ?? 'unknown',
      mode: json['mode']?.toString() ?? 'ambiguous',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      strengthRowCount: (json['strength_row_count'] as num?)?.toInt() ?? 0,
      cardioRowCount: (json['cardio_row_count'] as num?)?.toInt() ?? 0,
      hasTemplate: json['has_template'] as bool? ?? false,
      unresolvedExercises: (json['unresolved_exercises'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      sampleRows: (json['sample_rows'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const <Map<String, dynamic>>[],
    );

Map<String, dynamic> _$WorkoutImportPreviewToJson(WorkoutImportPreview x) => {
      'dry_run': x.dryRun,
      'source_app': x.sourceApp,
      'mode': x.mode,
      'confidence': x.confidence,
      'strength_row_count': x.strengthRowCount,
      'cardio_row_count': x.cardioRowCount,
      'has_template': x.hasTemplate,
      'unresolved_exercises': x.unresolvedExercises,
      'warnings': x.warnings,
      'sample_rows': x.sampleRows,
    };

UnresolvedGroup _$UnresolvedGroupFromJson(Map<String, dynamic> json) =>
    UnresolvedGroup(
      rawName: json['raw_name']?.toString() ?? '',
      rowCount: (json['row_count'] as num?)?.toInt() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      sourceApps: (json['source_apps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => UnresolvedSuggestion.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const <UnresolvedSuggestion>[],
      firstSeen: _parseDate(json['first_seen']),
      lastSeen: _parseDate(json['last_seen']),
    );

Map<String, dynamic> _$UnresolvedGroupToJson(UnresolvedGroup x) => {
      'raw_name': x.rawName,
      'row_count': x.rowCount,
      'session_count': x.sessionCount,
      'source_apps': x.sourceApps,
      'suggestions': x.suggestions.map((e) => e.toJson()).toList(),
      'first_seen': x.firstSeen?.toIso8601String(),
      'last_seen': x.lastSeen?.toIso8601String(),
    };

UnresolvedSuggestion _$UnresolvedSuggestionFromJson(Map<String, dynamic> json) =>
    UnresolvedSuggestion(
      canonicalName: json['canonical_name']?.toString() ?? '',
      exerciseId: json['exercise_id']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      source: json['source']?.toString() ?? 'unknown',
    );

Map<String, dynamic> _$UnresolvedSuggestionToJson(UnresolvedSuggestion x) => {
      'canonical_name': x.canonicalName,
      'exercise_id': x.exerciseId,
      'confidence': x.confidence,
      'source': x.source,
    };

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}
