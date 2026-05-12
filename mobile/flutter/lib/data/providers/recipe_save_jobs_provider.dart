import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/nutrition_repository.dart';

// SaveAsRecipeResult lives in the nutrition repository part file so the
// repository (which is `part of nutrition_repository.dart` and can't import
// other libraries) can return it without circular import gymnastics. We
// re-export it here so callers of this provider don't have to import the
// repository to read job results.
export '../repositories/nutrition_repository.dart' show SaveAsRecipeResult;

/// Lifecycle of a single in-flight Save-as-Recipe call.
enum RecipeSaveStatus { pending, done, merged, error }

/// Tracks one Save-as-Recipe operation from tap → completion. Lives in the
/// root ProviderScope so the toast still fires even after the user navigates
/// away from the nutrition screen mid-job.
@immutable
class RecipeSaveJob {
  final String jobId;          // local UUID-ish key used by the listener to detect new completions
  final String logId;
  final int? itemIndex;        // null = whole meal; int = single item from multi-item meal
  final String mealName;       // displayed in the toast ("Saved 'Idli + Sambar' to your recipes")
  final RecipeSaveStatus status;
  final SaveAsRecipeResult? result;
  final String? error;

  const RecipeSaveJob({
    required this.jobId,
    required this.logId,
    required this.itemIndex,
    required this.mealName,
    required this.status,
    this.result,
    this.error,
  });

  RecipeSaveJob copyWith({
    RecipeSaveStatus? status,
    SaveAsRecipeResult? result,
    String? error,
  }) =>
      RecipeSaveJob(
        jobId: jobId,
        logId: logId,
        itemIndex: itemIndex,
        mealName: mealName,
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

/// StateNotifier holding the list of jobs (newest last). The list is bounded
/// — completed jobs older than 30s are pruned by [_prune] so the global
/// listener doesn't re-fire toasts after a hot-reload reads the same list.
class RecipeSaveJobsNotifier extends StateNotifier<List<RecipeSaveJob>> {
  final NutritionRepository _repository;

  RecipeSaveJobsNotifier(this._repository) : super(const []);

  /// Returns true if a pending job already exists for the same (logId, itemIndex)
  /// pair. Callers should check this BEFORE enqueuing to avoid double-tap dupes.
  bool isPending(String logId, int? itemIndex) {
    return state.any((j) =>
        j.logId == logId &&
        j.itemIndex == itemIndex &&
        j.status == RecipeSaveStatus.pending);
  }

  /// Fire-and-forget: enqueues a job, kicks the network call, returns
  /// immediately. The global listener (in main_shell.dart) watches this list
  /// and surfaces toasts when status flips off `pending`.
  void enqueue({
    required String logId,
    int? itemIndex,
    required String mealName,
    bool createCookEvent = false,
  }) {
    if (isPending(logId, itemIndex)) {
      debugPrint('[RecipeSaveJobs] dropping duplicate enqueue for $logId / $itemIndex');
      return;
    }
    _prune();
    final jobId = '${DateTime.now().microsecondsSinceEpoch}_${logId}_${itemIndex ?? '*'}';
    final job = RecipeSaveJob(
      jobId: jobId,
      logId: logId,
      itemIndex: itemIndex,
      mealName: mealName,
      status: RecipeSaveStatus.pending,
    );
    state = [...state, job];

    // Run the actual save in the background. Errors are stored on the job —
    // never thrown — so the listener can surface them as toasts.
    unawaited(_run(job, createCookEvent: createCookEvent));
  }

  Future<void> _run(RecipeSaveJob job, {required bool createCookEvent}) async {
    try {
      final result = await _repository.saveLogAsRecipe(
        logId: job.logId,
        itemIndex: job.itemIndex,
        createCookEvent: createCookEvent,
      );
      _replace(job.jobId, (j) => j.copyWith(
        status: result.merged ? RecipeSaveStatus.merged : RecipeSaveStatus.done,
        result: result,
      ));
    } catch (e) {
      _replace(job.jobId, (j) => j.copyWith(
        status: RecipeSaveStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _replace(String jobId, RecipeSaveJob Function(RecipeSaveJob) transform) {
    final idx = state.indexWhere((j) => j.jobId == jobId);
    if (idx < 0) return;
    final next = [...state]..[idx] = transform(state[idx]);
    state = next;
  }

  /// Drop completed jobs older than 30s and cap the total list at 20 entries
  /// so the provider doesn't grow unbounded across long sessions.
  void _prune() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final retained = state.where((j) {
      if (j.status == RecipeSaveStatus.pending) return true;
      final ts = int.tryParse(j.jobId.split('_').first) ?? now;
      return now - ts < const Duration(seconds: 30).inMicroseconds;
    }).toList();
    state = retained.length > 20 ? retained.sublist(retained.length - 20) : retained;
  }

  /// Called by the listener after it has surfaced a toast for [jobId] so we
  /// don't fire it again on a subsequent rebuild.
  void markAcknowledged(String jobId) {
    _replace(jobId, (j) => j); // noop right now; the prune timer will clean up.
    // Future: add an `acknowledged: true` flag on RecipeSaveJob if duplicate
    // toasts become a problem in practice.
  }
}

final recipeSaveJobsProvider =
    StateNotifierProvider<RecipeSaveJobsNotifier, List<RecipeSaveJob>>((ref) {
  return RecipeSaveJobsNotifier(ref.watch(nutritionRepositoryProvider));
});
