import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/workout_import_job.dart';
import '../models/workout_import_preview.dart';
import '../services/api_client.dart';

/// Repository for the file-upload import flow.
///
/// Wraps the five `/workout-history/...` file endpoints:
///   • `/import/preview`        — sync dry-run, returns [WorkoutImportPreview]
///   • `/import/file`           — async job creation, returns a job_id
///   • `/remap`                 — batch raw→canonical rename with audit
///   • `/remap/{audit}/undo`    — reverse a prior remap
///   • `/unresolved/{user_id}`  — list of unresolved raw names + suggestions
///
/// The polling helper [pollJob] is exposed so UIs can long-poll
/// `GET /media-jobs/{id}` with a consistent parsed shape.
class WorkoutHistoryImportFileRepository {
  WorkoutHistoryImportFileRepository(this._apiClient);

  final ApiClient _apiClient;

  // ───────────────────────────── Upload flows ─────────────────────────────

  /// Parse [bytes] synchronously WITHOUT writing to the DB.
  ///
  /// The backend runs the adapter + resolver, returns detected source app,
  /// row counts, sample rows, and unresolved exercises. Use this to drive
  /// the preview sheet before confirming.
  Future<WorkoutImportPreview> previewFile({
    required Uint8List bytes,
    required String filename,
    required String unitHint, // 'kg' | 'lb'
    required String timezoneHint, // IANA tz
    String? sourceAppHint,
  }) async {
    debugPrint('🔍 [WorkoutImport] previewFile name=$filename bytes=${bytes.length}');

    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'unit_hint': unitHint,
      'timezone_hint': timezoneHint,
      if (sourceAppHint != null && sourceAppHint.isNotEmpty)
        'source_app_hint': sourceAppHint,
    });

    final resp = await _apiClient.post(
      '/workout-history/import/preview',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final map = (resp.data as Map).cast<String, dynamic>();
    return WorkoutImportPreview.fromJson(map);
  }

  /// Upload [bytes] and enqueue a background import job.
  ///
  /// Returns the `job_id` so the caller can poll via [pollJob].
  Future<String> uploadFile({
    required Uint8List bytes,
    required String filename,
    required String unitHint,
    required String timezoneHint,
    String? sourceAppHint,
  }) async {
    debugPrint('📤 [WorkoutImport] uploadFile name=$filename bytes=${bytes.length}');

    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'unit_hint': unitHint,
      'timezone_hint': timezoneHint,
      if (sourceAppHint != null && sourceAppHint.isNotEmpty)
        'source_app_hint': sourceAppHint,
    });

    final resp = await _apiClient.post(
      '/workout-history/import/file',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final map = (resp.data as Map).cast<String, dynamic>();
    final jobId = map['job_id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw StateError('Server did not return a job_id');
    }
    return jobId;
  }

  /// Poll the media-jobs endpoint for [jobId].
  ///
  /// Returns a typed [WorkoutImportJob]. Server-side retries already happen
  /// automatically — this is just a read.
  Future<WorkoutImportJob> pollJob(String jobId) async {
    final resp = await _apiClient.get('/media-jobs/$jobId');
    final map = (resp.data as Map).cast<String, dynamic>();
    return WorkoutImportJob.fromJson(map);
  }

  // ───────────────────────────── Remap flows ──────────────────────────────

  /// Batch-remap every row where `LOWER(exercise_name) == LOWER(rawName)` for
  /// [userId] to [canonicalName] (+ optional resolved [exerciseId]).
  ///
  /// Returns `{rows_affected, audit_id}`. The audit id is required for undo.
  Future<RemapResult> remap({
    required String userId,
    required String rawName,
    required String canonicalName,
    String? exerciseId,
    String? sourceApp,
  }) async {
    debugPrint('🔀 [WorkoutImport] remap "$rawName" → "$canonicalName"');

    final resp = await _apiClient.post(
      '/workout-history/remap',
      data: {
        'user_id': userId,
        'raw_name': rawName,
        'canonical_name': canonicalName,
        if (exerciseId != null) 'exercise_id': exerciseId,
        if (sourceApp != null) 'source_app': sourceApp,
      },
    );
    final map = (resp.data as Map).cast<String, dynamic>();
    return RemapResult(
      rowsAffected: (map['rows_affected'] as num?)?.toInt() ?? 0,
      auditId: map['audit_id']?.toString() ?? '',
    );
  }

  /// Reverse a prior [remap] batch.
  Future<RemapResult> undoRemap(String auditId) async {
    debugPrint('↩️ [WorkoutImport] undoRemap audit=$auditId');
    final resp = await _apiClient.post('/workout-history/remap/$auditId/undo');
    final map = (resp.data as Map).cast<String, dynamic>();
    return RemapResult(
      rowsAffected: (map['rows_reverted'] as num?)?.toInt() ?? 0,
      auditId: map['audit_id']?.toString() ?? auditId,
    );
  }

  // ───────────────────────── Unresolved names ─────────────────────────────

  /// Fetch all distinct raw exercise names that the resolver couldn't match
  /// for [userId], each with up to 3 suggested canonical alternatives.
  Future<List<UnresolvedGroup>> getUnresolved({
    required String userId,
    int limit = 50,
  }) async {
    final resp = await _apiClient.get(
      '/workout-history/unresolved/$userId',
      queryParameters: {'limit': limit},
    );
    final list = (resp.data as List).cast<Map<String, dynamic>>();
    return list.map(UnresolvedGroup.fromJson).toList();
  }
}

/// Small value type returned by [WorkoutHistoryImportFileRepository.remap] and
/// its undo sibling. Kept here (rather than in a model file) because it's a
/// one-liner only the repository uses.
@immutable
class RemapResult {
  const RemapResult({required this.rowsAffected, required this.auditId});
  final int rowsAffected;
  final String auditId;
}
