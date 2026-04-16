/// Models for the AI Exercise Importer feature.
///
/// The backend contract for POST /api/v1/custom_exercises/{user_id}/import
/// returns EITHER:
///   * A synchronous completion payload (photo / text sources)
///     -> `ImportExerciseResult.complete(...)`
///   * An async job id (video source, 202 Accepted)
///     -> `ImportExerciseResult.async(...)`, caller polls via
///       [CustomExerciseRepository.pollImportJob] until `status == completed`.
///
/// These are plain Dart classes — no code generation. The canonical
/// `.g.dart` files for this project are committed, Flutter is pinned to
/// 3.38.10, and we must NEVER run `build_runner`.
library;

import 'custom_exercise.dart';

/// Result of an import request. Either completes synchronously with a
/// created exercise, or returns a job id for async polling.
class ImportExerciseResult {
  /// True when the exercise is ready now (photo/text paths).
  final bool isComplete;

  /// True when we only got a job id back and must poll (video path).
  final bool isAsync;

  /// The auto-saved custom exercise. Non-null when [isComplete].
  final CustomExercise? exercise;

  /// Whether ChromaDB indexing succeeded on the server.
  final bool ragIndexed;

  /// True when the backend detected this exercise already existed for the
  /// user and is returning the pre-existing row instead of creating a new
  /// one. UI should show "You already have this exercise" banner.
  final bool duplicate;

  /// Job id for async flows. Non-null when [isAsync].
  final String? jobId;

  /// Initial status of the async job ("pending" | "processing").
  final String? status;

  const ImportExerciseResult._({
    required this.isComplete,
    required this.isAsync,
    this.exercise,
    this.ragIndexed = false,
    this.duplicate = false,
    this.jobId,
    this.status,
  });

  factory ImportExerciseResult.complete({
    required CustomExercise exercise,
    required bool ragIndexed,
    required bool duplicate,
  }) {
    return ImportExerciseResult._(
      isComplete: true,
      isAsync: false,
      exercise: exercise,
      ragIndexed: ragIndexed,
      duplicate: duplicate,
    );
  }

  factory ImportExerciseResult.async({
    required String jobId,
    required String status,
  }) {
    return ImportExerciseResult._(
      isComplete: false,
      isAsync: true,
      jobId: jobId,
      status: status,
    );
  }
}

/// Snapshot of an async import job on the media-jobs endpoint.
class ImportJobStatus {
  final String jobId;

  /// "pending" | "processing" | "completed" | "failed".
  final String status;

  /// Populated only when [status] == "completed".
  final CustomExercise? exercise;

  final bool ragIndexed;
  final bool duplicate;

  /// Per-keyframe confidence scores from Gemini Vision (video path).
  final List<double>? keyframeConfidences;

  /// Human-readable error when [status] == "failed".
  final String? errorMessage;

  const ImportJobStatus({
    required this.jobId,
    required this.status,
    this.exercise,
    this.ragIndexed = false,
    this.duplicate = false,
    this.keyframeConfidences,
    this.errorMessage,
  });

  bool get isTerminal => status == 'completed' || status == 'failed';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  /// Average confidence across all keyframes (0.0 - 1.0), or null if
  /// no per-frame scores were returned.
  double? get averageConfidence {
    if (keyframeConfidences == null || keyframeConfidences!.isEmpty) {
      return null;
    }
    final sum = keyframeConfidences!.fold<double>(0, (a, b) => a + b);
    return sum / keyframeConfidences!.length;
  }
}
