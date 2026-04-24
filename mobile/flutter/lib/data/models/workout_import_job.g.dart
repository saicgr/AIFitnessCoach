// GENERATED-STYLE, HAND-WRITTEN. Do NOT run build_runner (see
// `project_codegen_gotcha.md`). Keep this file paired with the parent
// workout_import_job.dart — rename/remove fields in both at once.

// ignore_for_file: prefer_const_constructors

part of 'workout_import_job.dart';

WorkoutImportJob _$WorkoutImportJobFromJson(Map<String, dynamic> json) =>
    WorkoutImportJob(
      id: json['id']?.toString() ?? '',
      status: WorkoutImportJobStatus.fromWire(json['status']?.toString()),
      jobType: json['job_type']?.toString() ?? 'workout_history_import',
      resultJson: (json['result_json'] is Map)
          ? (json['result_json'] as Map).cast<String, dynamic>()
          : null,
      errorMessage: json['error_message']?.toString(),
      createdAt: _tryParseDate(json['created_at']),
      updatedAt: _tryParseDate(json['updated_at']),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WorkoutImportJobToJson(WorkoutImportJob x) => {
      'id': x.id,
      'status': x.status.wireValue,
      'job_type': x.jobType,
      'result_json': x.resultJson,
      'error_message': x.errorMessage,
      'created_at': x.createdAt?.toIso8601String(),
      'updated_at': x.updatedAt?.toIso8601String(),
      'retry_count': x.retryCount,
    };

DateTime? _tryParseDate(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}
