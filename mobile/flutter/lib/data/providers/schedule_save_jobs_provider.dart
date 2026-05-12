import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/nutrition_repository.dart';

// Re-export the result type so callers don't need to import the repository.
export '../repositories/nutrition_repository.dart' show ScheduleFromLogResult, ScheduleSpec;

enum ScheduleSaveStatus { pending, done, error }

@immutable
class ScheduleSaveJob {
  final String jobId;
  final String logId;
  final String mealName;
  final String cadenceLabel;            // "Tomorrow only", "Every Mon/Wed/Fri", etc.
  final ScheduleSaveStatus status;
  final ScheduleFromLogResult? result;
  final String? error;

  const ScheduleSaveJob({
    required this.jobId,
    required this.logId,
    required this.mealName,
    required this.cadenceLabel,
    required this.status,
    this.result,
    this.error,
  });

  ScheduleSaveJob copyWith({
    ScheduleSaveStatus? status,
    ScheduleFromLogResult? result,
    String? error,
  }) =>
      ScheduleSaveJob(
        jobId: jobId,
        logId: logId,
        mealName: mealName,
        cadenceLabel: cadenceLabel,
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

/// Mirrors `RecipeSaveJobsNotifier`. Schedule jobs can take 3-8s when the
/// food_log isn't linked to a recipe yet (server-side enrichment runs first),
/// so we use the same fire-and-forget + global toast pattern.
class ScheduleSaveJobsNotifier extends StateNotifier<List<ScheduleSaveJob>> {
  final NutritionRepository _repository;

  ScheduleSaveJobsNotifier(this._repository) : super(const []);

  bool isPending(String logId) =>
      state.any((j) => j.logId == logId && j.status == ScheduleSaveStatus.pending);

  void enqueue({
    required String logId,
    required String mealName,
    required String cadenceLabel,
    required ScheduleSpec spec,
    int? itemIndex,
    bool createCookEvent = false,
  }) {
    if (isPending(logId)) {
      debugPrint('[ScheduleSaveJobs] dropping duplicate enqueue for $logId');
      return;
    }
    _prune();
    final jobId = '${DateTime.now().microsecondsSinceEpoch}_$logId';
    final job = ScheduleSaveJob(
      jobId: jobId,
      logId: logId,
      mealName: mealName,
      cadenceLabel: cadenceLabel,
      status: ScheduleSaveStatus.pending,
    );
    state = [...state, job];
    unawaited(_run(job, spec: spec, itemIndex: itemIndex, createCookEvent: createCookEvent));
  }

  Future<void> _run(
    ScheduleSaveJob job, {
    required ScheduleSpec spec,
    int? itemIndex,
    bool createCookEvent = false,
  }) async {
    try {
      final result = await _repository.scheduleMealFromLog(
        logId: job.logId,
        spec: spec,
        itemIndex: itemIndex,
        createCookEvent: createCookEvent,
      );
      _replace(job.jobId, (j) => j.copyWith(status: ScheduleSaveStatus.done, result: result));
    } catch (e) {
      _replace(job.jobId, (j) => j.copyWith(status: ScheduleSaveStatus.error, error: e.toString()));
    }
  }

  void _replace(String jobId, ScheduleSaveJob Function(ScheduleSaveJob) transform) {
    final idx = state.indexWhere((j) => j.jobId == jobId);
    if (idx < 0) return;
    final next = [...state]..[idx] = transform(state[idx]);
    state = next;
  }

  void _prune() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final retained = state.where((j) {
      if (j.status == ScheduleSaveStatus.pending) return true;
      final ts = int.tryParse(j.jobId.split('_').first) ?? now;
      return now - ts < const Duration(seconds: 30).inMicroseconds;
    }).toList();
    state = retained.length > 20 ? retained.sublist(retained.length - 20) : retained;
  }

  void markAcknowledged(String jobId) {
    _replace(jobId, (j) => j); // noop; prune handles cleanup
  }
}

final scheduleSaveJobsProvider =
    StateNotifierProvider<ScheduleSaveJobsNotifier, List<ScheduleSaveJob>>((ref) {
  return ScheduleSaveJobsNotifier(ref.watch(nutritionRepositoryProvider));
});
