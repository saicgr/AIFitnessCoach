/// Workout history import — JOB polling shapes.
///
/// Models the JSON returned by `GET /api/v1/media-jobs/{job_id}` for jobs of
/// type `workout_history_import`. Hand-written (see
/// `project_codegen_gotcha.md`). The fromJson/toJson impls live in the
/// paired .g.dart file.
library;

import 'package:flutter/foundation.dart';

part 'workout_import_job.g.dart';

/// Lifecycle states for a media_analysis_jobs row.
///
/// Kept as a plain enum rather than a JsonValue-annotated class because the
/// wire protocol uses simple lowercase strings and we want to stay robust if
/// a new status ("queued_retry") is introduced server-side.
enum WorkoutImportJobStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
  unknown;

  bool get isTerminal =>
      this == WorkoutImportJobStatus.completed ||
      this == WorkoutImportJobStatus.failed ||
      this == WorkoutImportJobStatus.cancelled;

  bool get isActive =>
      this == WorkoutImportJobStatus.pending ||
      this == WorkoutImportJobStatus.inProgress;

  static WorkoutImportJobStatus fromWire(String? raw) {
    switch (raw) {
      case 'pending':
        return WorkoutImportJobStatus.pending;
      case 'in_progress':
        return WorkoutImportJobStatus.inProgress;
      case 'completed':
        return WorkoutImportJobStatus.completed;
      case 'failed':
        return WorkoutImportJobStatus.failed;
      case 'cancelled':
        return WorkoutImportJobStatus.cancelled;
    }
    return WorkoutImportJobStatus.unknown;
  }

  String get wireValue {
    switch (this) {
      case WorkoutImportJobStatus.pending:
        return 'pending';
      case WorkoutImportJobStatus.inProgress:
        return 'in_progress';
      case WorkoutImportJobStatus.completed:
        return 'completed';
      case WorkoutImportJobStatus.failed:
        return 'failed';
      case WorkoutImportJobStatus.cancelled:
        return 'cancelled';
      case WorkoutImportJobStatus.unknown:
        return 'unknown';
    }
  }
}

/// The polled job snapshot.
@immutable
class WorkoutImportJob {
  const WorkoutImportJob({
    required this.id,
    required this.status,
    required this.jobType,
    this.resultJson,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
    this.retryCount = 0,
  });

  final String id;
  final WorkoutImportJobStatus status;

  /// Always `workout_history_import` for our flow, but carried through so
  /// error copy can match the server-side job_type if support debugs it.
  final String jobType;

  /// Populated only when [status] == completed. Shape mirrors the importer's
  /// summary: inserted_strength_rows, duplicate_strength_rows,
  /// inserted_cardio_rows, template_id, unresolved_exercises, warnings, etc.
  final Map<String, dynamic>? resultJson;

  /// Populated only when [status] == failed.
  final String? errorMessage;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int retryCount;

  /// Convenience accessors for the common result_json fields — parsers in the
  /// summary sheet avoid repeating the null/int-cast dance.
  int get insertedStrengthRows =>
      (resultJson?['inserted_strength_rows'] as num?)?.toInt() ?? 0;
  int get duplicateStrengthRows =>
      (resultJson?['duplicate_strength_rows'] as num?)?.toInt() ?? 0;
  int get insertedCardioRows =>
      (resultJson?['inserted_cardio_rows'] as num?)?.toInt() ?? 0;
  int get duplicateCardioRows =>
      (resultJson?['duplicate_cardio_rows'] as num?)?.toInt() ?? 0;
  String? get templateId => resultJson?['template_id']?.toString();
  String? get sourceApp => resultJson?['source_app']?.toString();
  List<String> get unresolvedExercises =>
      ((resultJson?['unresolved_exercises'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
  List<String> get warnings =>
      ((resultJson?['warnings'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();

  factory WorkoutImportJob.fromJson(Map<String, dynamic> json) =>
      _$WorkoutImportJobFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutImportJobToJson(this);
}
