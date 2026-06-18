import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'chat_repository.dart';
import 'gym_profile_repository.dart' show MediaJobStatus;

/// Repository for the in-workout / standalone AI Form Analysis flow.
///
/// Pipeline (mirrors the chat form-video path so there is one upload code path):
///   1. presign an S3 slot for the picked video  (ChatRepository.getPresignedUrl)
///   2. PUT/POST the bytes straight to S3         (ChatRepository.uploadToS3)
///   3. submit the `form_analysis` media job      (POST /media-jobs/form-analysis)
///   4. poll `GET /media-jobs/{job_id}` until terminal (reuses MediaJobStatus)
///
/// The result map returned on completion matches `FormAnalysisService.analyze_form`
/// (form_score 1-10, subscores, positives, issues, exercise_identified, …) which
/// is exactly the shape `FormAnalysisGaugeCard` consumes.
class FormAnalysisRepository {
  final ApiClient _apiClient;
  final ChatRepository _chatRepository;

  FormAnalysisRepository(this._apiClient, this._chatRepository);

  /// Upload [video] to S3 and return its `s3_key`.
  ///
  /// Reuses the chat media presign + S3 upload helpers verbatim so the form
  /// flow shares the exact upload path that chat form-videos already use.
  Future<String> uploadVideo(
    File video, {
    String mimeType = 'video/mp4',
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = await video.length();
    final filename = video.path.split('/').last;

    final presign = await _chatRepository.getPresignedUrl(
      filename: filename,
      contentType: mimeType,
      mediaType: 'video',
      expectedSizeBytes: bytes,
    );

    final presignedUrl =
        presign['presigned_url'] as String? ?? presign['url'] as String;
    final s3Key = presign['s3_key'] as String;
    final fields = presign['presigned_fields'] as Map<String, dynamic>?;

    await _chatRepository.uploadToS3(
      presignedUrl: presignedUrl,
      fields: fields,
      file: video,
      contentType: mimeType,
      onProgress: onProgress,
    );

    debugPrint('✅ [FormAnalysis] Uploaded video, s3_key: $s3Key');
    return s3Key;
  }

  /// Submit an already-uploaded video for form analysis. [exerciseName] is
  /// optional — the analyzer auto-identifies the movement when omitted.
  ///
  /// Returns the new `job_id`.
  Future<String> submitFormAnalysis({
    required String s3Key,
    String mimeType = 'video/mp4',
    String? exerciseName,
  }) async {
    final response = await _apiClient.post(
      '/media-jobs/form-analysis',
      data: {
        's3_key': s3Key,
        'mime_type': mimeType,
        if (exerciseName != null && exerciseName.trim().isNotEmpty)
          'exercise_name': exerciseName.trim(),
      },
    );
    if (response.statusCode == 200 && response.data is Map) {
      final jobId = response.data['job_id'] as String?;
      if (jobId != null && jobId.isNotEmpty) {
        debugPrint('🎥 [FormAnalysis] Submitted, job_id: $jobId');
        return jobId;
      }
    }
    throw Exception(
        'Failed to start form analysis (HTTP ${response.statusCode})');
  }

  /// Poll a single form-analysis job. Mirrors
  /// `GymProfileRepository.pollMediaJob` (the shared `/media-jobs/{id}` shape).
  Future<MediaJobStatus> pollJob(String jobId) async {
    final response = await _apiClient.get('/media-jobs/$jobId');
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return MediaJobStatus.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Job poll failed: HTTP ${response.statusCode}');
  }

  /// List the user's completed form analyses, newest first. When [exercise] is
  /// given, results are filtered to that movement (case-insensitive substring
  /// either way, server-side). Powers the per-exercise Form history tab.
  Future<List<FormAnalysisHistoryItem>> listAnalyses({
    String? exercise,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '/media-jobs/form-analyses/list',
      queryParameters: {
        if (exercise != null && exercise.trim().isNotEmpty)
          'exercise': exercise.trim(),
        'limit': limit,
      },
    );
    if (response.statusCode == 200 && response.data is Map) {
      final items = (response.data['items'] as List?) ?? const [];
      return items
          .whereType<Map>()
          .map((e) =>
              FormAnalysisHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Failed to load form analyses (HTTP ${response.statusCode})');
  }
}

/// One completed form-analysis record from the history list endpoint.
class FormAnalysisHistoryItem {
  final String jobId;
  final DateTime? createdAt;
  final DateTime? completedAt;

  /// Scored payload (same shape `FormAnalysisGaugeCard` renders).
  final Map<String, dynamic> result;

  const FormAnalysisHistoryItem({
    required this.jobId,
    required this.result,
    this.createdAt,
    this.completedAt,
  });

  factory FormAnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final rawResult = json['result'];
    return FormAnalysisHistoryItem(
      jobId: (json['job_id'] ?? '').toString(),
      result: rawResult is Map
          ? Map<String, dynamic>.from(rawResult)
          : const <String, dynamic>{},
      createdAt: parse(json['created_at']),
      completedAt: parse(json['completed_at']),
    );
  }

  /// Best timestamp to show under the gauge ("analyzed at").
  DateTime? get analyzedAt => completedAt ?? createdAt;
}

final formAnalysisRepositoryProvider = Provider<FormAnalysisRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);
  return FormAnalysisRepository(apiClient, chatRepo);
});

/// Per-exercise form-analysis history (newest first). Powers the exercise
/// detail Form tab. Keyed by exercise name; pass an empty string for "all".
/// Invalidate after a new analysis completes so the tab refreshes.
final exerciseFormAnalysesProvider = FutureProvider.autoDispose
    .family<List<FormAnalysisHistoryItem>, String>((ref, exerciseName) async {
  final repo = ref.watch(formAnalysisRepositoryProvider);
  return repo.listAnalyses(
    exercise: exerciseName.trim().isEmpty ? null : exerciseName,
  );
});
