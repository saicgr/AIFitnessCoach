import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_import.dart';
import '../repositories/chat_repository.dart';
import 'api_client.dart';

/// Result of kicking off an AI workout import. Either an [workout] is ready
/// (photo/text synchronous path) or a [jobId] is returned to poll (video).
class WorkoutImportResult {
  final ImportedWorkout? workout;
  final String? jobId;
  WorkoutImportResult({this.workout, this.jobId});

  bool get isComplete => workout != null;
  bool get isAsync => jobId != null;
}

/// Terminal/poll status of a `workout_import` media job.
class WorkoutImportJobStatus {
  final String status; // pending | processing | completed | failed
  final ImportedWorkout? workout;
  final String? errorMessage;
  WorkoutImportJobStatus({
    required this.status,
    this.workout,
    this.errorMessage,
  });

  bool get isTerminal => status == 'completed' || status == 'failed';
  bool get isFailed => status == 'failed';
}

/// Talks to the AI workout-import endpoints (see
/// `backend/api/v1/saved_workouts.py`). Uploads reuse the chat presign → S3
/// pipeline, identical to the exercise importer.
class WorkoutImportService {
  final ApiClient _apiClient;
  final ChatRepository _chatRepo;

  WorkoutImportService(this._apiClient, this._chatRepo);

  Future<String> _requireUserId() async {
    final id = await _apiClient.getUserId();
    if (id == null || id.isEmpty) {
      throw Exception('You need to be signed in to import workouts.');
    }
    return id;
  }

  /// Upload a local file → returns its s3_key for the extractor.
  Future<String> uploadMedia({
    required File file,
    required String contentType,
  }) async {
    final size = await file.length();
    final filename = file.path.split('/').last;
    final mediaType = contentType.startsWith('video') ? 'video' : 'image';
    final presign = await _chatRepo.getPresignedUrl(
      filename: filename,
      contentType: contentType,
      mediaType: mediaType,
      expectedSizeBytes: size,
    );
    final url = presign['upload_url'] as String? ?? presign['url'] as String?;
    final fields = presign['fields'] as Map?;
    final s3Key = presign['s3_key'] as String?;
    if (url == null || s3Key == null) {
      throw Exception('Malformed presign response');
    }
    await _chatRepo.uploadToS3(
      presignedUrl: url,
      fields: fields?.map((k, v) => MapEntry(k.toString(), v)),
      file: file,
      contentType: contentType,
    );
    return s3Key;
  }

  Future<WorkoutImportResult> importFromPhoto({
    required String s3Key,
    String? userHint,
  }) async {
    final userId = await _requireUserId();
    final res = await _apiClient.post('/saved-workouts/import-ai', data: {
      'user_id': userId,
      'source': 'photo',
      's3_key': s3Key,
      if (userHint != null && userHint.isNotEmpty) 'user_hint': userHint,
    });
    return _parseImportResponse(res.data);
  }

  Future<WorkoutImportResult> importFromText({
    required String rawText,
    String? userHint,
  }) async {
    final userId = await _requireUserId();
    final res = await _apiClient.post('/saved-workouts/import-ai', data: {
      'user_id': userId,
      'source': 'text',
      'raw_text': rawText,
      if (userHint != null && userHint.isNotEmpty) 'user_hint': userHint,
    });
    return _parseImportResponse(res.data);
  }

  Future<WorkoutImportResult> importFromVideo({
    required String s3Key,
    String? userHint,
  }) async {
    final userId = await _requireUserId();
    final res = await _apiClient.post('/saved-workouts/import-ai', data: {
      'user_id': userId,
      'source': 'video',
      's3_key': s3Key,
      if (userHint != null && userHint.isNotEmpty) 'user_hint': userHint,
    });
    return _parseImportResponse(res.data);
  }

  WorkoutImportResult _parseImportResponse(dynamic data) {
    final m = Map<String, dynamic>.from(data as Map);
    final w = m['workout'];
    if (w is Map) {
      return WorkoutImportResult(
          workout: ImportedWorkout.fromJson(Map<String, dynamic>.from(w)));
    }
    final jobId = m['job_id']?.toString();
    if (jobId != null && jobId.isNotEmpty) {
      return WorkoutImportResult(jobId: jobId);
    }
    throw Exception('Unexpected import response');
  }

  /// Poll a `workout_import` media job once.
  Future<WorkoutImportJobStatus> pollImportJob(String jobId) async {
    final res = await _apiClient.get('/media-jobs/$jobId');
    final m = Map<String, dynamic>.from(res.data as Map);
    final status = (m['status'] ?? 'processing').toString();
    ImportedWorkout? workout;
    final result = m['result_json'] ?? m['result'];
    if (result is Map && result['workout'] is Map) {
      workout = ImportedWorkout.fromJson(
          Map<String, dynamic>.from(result['workout'] as Map));
    }
    return WorkoutImportJobStatus(
      status: status,
      workout: workout,
      errorMessage: m['error_message']?.toString() ?? m['error']?.toString(),
    );
  }

  /// Persist the reviewed workout into the user's Custom workouts.
  /// Returns the new workout id.
  Future<String> save({
    required ImportedWorkout workout,
    String? sourceUrl,
  }) async {
    final userId = await _requireUserId();
    final res = await _apiClient.post(
      '/saved-workouts/import-ai/save',
      data: workout.toSavePayload(userId: userId, sourceUrl: sourceUrl),
    );
    final m = Map<String, dynamic>.from(res.data as Map);
    final id = m['workout_id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Save returned no workout id');
    }
    if (kDebugMode) debugPrint('✅ [WorkoutImport] saved $id');
    return id;
  }
}

final workoutImportServiceProvider = Provider<WorkoutImportService>((ref) {
  return WorkoutImportService(
    ref.read(apiClientProvider),
    ref.read(chatRepositoryProvider),
  );
});
