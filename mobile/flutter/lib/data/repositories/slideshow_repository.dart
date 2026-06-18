import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Source of photos for a transformation video.
enum SlideshowSource { workoutPhotos, progressPhotos, food }

extension SlideshowSourceWire on SlideshowSource {
  String get wire {
    switch (this) {
      case SlideshowSource.workoutPhotos:
        return 'workout_photos';
      case SlideshowSource.progressPhotos:
        return 'progress_photos';
      case SlideshowSource.food:
        return 'food';
    }
  }
}

/// Status of a server-side slideshow render job.
enum SlideshowStatus { pending, processing, done, error }

SlideshowStatus _statusFromWire(String? s) {
  switch (s) {
    case 'done':
      return SlideshowStatus.done;
    case 'processing':
      return SlideshowStatus.processing;
    case 'error':
      return SlideshowStatus.error;
    default:
      return SlideshowStatus.pending;
  }
}

/// A slideshow render job — mirrors the backend `SlideshowJobResponse`.
@immutable
class SlideshowJob {
  final String jobId;
  final SlideshowStatus status;
  final String source;
  final String? resultUrl;
  final String? error;

  const SlideshowJob({
    required this.jobId,
    required this.status,
    required this.source,
    this.resultUrl,
    this.error,
  });

  bool get isTerminal =>
      status == SlideshowStatus.done || status == SlideshowStatus.error;

  factory SlideshowJob.fromJson(Map<String, dynamic> json) {
    return SlideshowJob(
      jobId: json['job_id'] as String,
      status: _statusFromWire(json['status'] as String?),
      source: (json['source'] as String?) ?? '',
      resultUrl: json['result_url'] as String?,
      error: json['error'] as String?,
    );
  }
}

final slideshowRepositoryProvider = Provider<SlideshowRepository>((ref) {
  return SlideshowRepository(ref.watch(apiClientProvider));
});

/// Repository for the server-side transformation-video / reveal renders.
///
/// Backend: `POST /workout-photos/slideshow` enqueues a render job;
/// `GET /workout-photos/slideshow/{job_id}` polls status + the presigned MP4
/// URL. The render itself (ffmpeg composite of the user's real photos) runs in
/// a backend BackgroundTask — see backend/services/slideshow_service.py.
class SlideshowRepository {
  final ApiClient _client;

  SlideshowRepository(this._client);

  /// Enqueue a full transformation montage over a date span.
  Future<SlideshowJob> createMontage({
    required String userId,
    required SlideshowSource source,
    DateTime? dateFrom,
    DateTime? dateTo,
    String style = 'kenburns',
  }) async {
    return _create(userId, {
      'source': source.wire,
      'style': style,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo.toIso8601String(),
    });
  }

  /// Enqueue an F9 count-up reveal (a number ticking 0 → [finalValue]).
  Future<SlideshowJob> createCountUp({
    required String userId,
    required SlideshowSource source,
    required double finalValue,
    required String label,
    String unit = '',
    String valueFormat = 'int',
    String? backgroundKey,
  }) async {
    return _create(userId, {
      'source': source.wire,
      'count_up': {
        'final_value': finalValue,
        'label': label,
        'unit': unit,
        'value_format': valueFormat,
        if (backgroundKey != null) 'background_key': backgroundKey,
      },
    });
  }

  /// Enqueue an F4 before/after reveal. [caption] is generated upstream (no
  /// LLM call is made by this method or the render path).
  Future<SlideshowJob> createBeforeAfter({
    required String userId,
    required SlideshowSource source,
    required String beforeKey,
    required String afterKey,
    required String caption,
    String style = 'wipe',
  }) async {
    return _create(userId, {
      'source': source.wire,
      'before_after': {
        'before_key': beforeKey,
        'after_key': afterKey,
        'caption': caption,
        'style': style,
      },
    });
  }

  Future<SlideshowJob> _create(String userId, Map<String, dynamic> body) async {
    try {
      debugPrint('🎬 [Slideshow] enqueue ${body['source']} for $userId');
      final response = await _client.post(
        '/workout-photos/slideshow',
        queryParameters: {'user_id': userId},
        data: body,
      );
      return SlideshowJob.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Slideshow] enqueue failed: $e');
      rethrow;
    }
  }

  /// Poll a render job's status + (when done) its presigned MP4 URL.
  Future<SlideshowJob> getJob({
    required String userId,
    required String jobId,
  }) async {
    try {
      final response = await _client.get(
        '/workout-photos/slideshow/$jobId',
        queryParameters: {'user_id': userId},
      );
      return SlideshowJob.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Slideshow] poll failed: $e');
      rethrow;
    }
  }

  /// Convenience: enqueue then poll to completion. Polls every [interval] up to
  /// [maxAttempts]. Throws on render error or timeout (no silent fallback).
  Future<SlideshowJob> renderAndAwait({
    required String userId,
    required Future<SlideshowJob> Function() enqueue,
    Duration interval = const Duration(seconds: 2),
    int maxAttempts = 90,
  }) async {
    final job = await enqueue();
    var current = job;
    var attempts = 0;
    while (!current.isTerminal && attempts < maxAttempts) {
      await Future<void>.delayed(interval);
      current = await getJob(userId: userId, jobId: job.jobId);
      attempts++;
    }
    if (current.status == SlideshowStatus.error) {
      throw Exception(current.error ?? 'Render failed');
    }
    if (current.status != SlideshowStatus.done) {
      throw Exception('Render timed out — please try again');
    }
    return current;
  }
}
