import 'dart:async';

import 'package:flutter/foundation.dart';

/// Cross-cutting helper for the optimistic-save pattern used by every Tier A
/// provider in the consumer app. Mutates local state in the same frame as the
/// caller's tap, then persists to the backend in an unawaited background
/// closure. On failure, the rollback callback restores the previous value and
/// the error surfaces to the UI via the provider's `state.error` field.
///
/// Reference implementation: `nutrition_preferences_provider.updateTargets`.
///
/// Edge cases covered (from
/// docs/planning/.../optimistic-saves plan §Edge cases):
///   * Concurrent calls — every call snapshots `previous` at invocation time,
///     so a chained rollback unwinds to the most recent stable value rather
///     than to pre-edit-1. Caller provides a monotonic `seq` when sequencing
///     matters (see [optimisticPersistSeq]).
///   * Network failure — caught here; rollback fires; error string flows to
///     the provider's state via the [rollback] callback.
///   * App backgrounded mid-save — the unawaited closure continues on iOS
///     for ~30s; for critical-data saves the caller layers a workmanager
///     job on top (out of scope for this helper).
///   * BuildContext use — none. This helper never touches UI. The provider
///     is the only thing it knows about.
void optimisticPersist({
  required void Function() applyOptimistic,
  required Future<void> Function() persist,
  required void Function(Object error, StackTrace stack) rollback,
  String? debugLabel,
}) {
  // Apply the optimistic update synchronously — on the same frame as the
  // caller's tap. UI reads the new state before this function returns.
  applyOptimistic();

  // Background persistence. Caller is unblocked the instant this returns.
  unawaited(() async {
    try {
      await persist();
      if (debugLabel != null) {
        debugPrint('✅ [optimisticPersist] $debugLabel persisted');
      }
    } catch (e, st) {
      debugPrint(
          '❌ [optimisticPersist] ${debugLabel ?? 'persist'} failed: $e');
      try {
        rollback(e, st);
      } catch (rollbackError) {
        // Don't let a rollback failure mask the original error — both are
        // logged. A failed rollback usually means the provider was disposed
        // mid-persist, which is acceptable (next cold start re-fetches).
        debugPrint(
            '❌ [optimisticPersist] rollback also failed: $rollbackError');
      }
    }
  }());
}

/// Sequenced variant for surfaces where the user can fire a save multiple
/// times in flight (Tier B toggle mashing, rapid macro edits). The caller
/// owns a monotonic counter and passes the current value as [seq]; the
/// helper drops stale `applyConfirmed` callbacks so server response order
/// doesn't matter — only the most recent persist's confirmation can land.
///
/// Usage:
/// ```dart
/// int _saveSeq = 0;
///
/// Future<void> updateX(...) async {
///   final mySeq = ++_saveSeq;
///   final previous = state.value;
///   optimisticPersistSeq(
///     seq: mySeq,
///     latestSeq: () => _saveSeq,
///     applyOptimistic: () => state = state.copyWith(value: optimistic),
///     persist: () => _repo.put(...),
///     rollback: (e, _) => state = state.copyWith(value: previous, error: '$e'),
///   );
/// }
/// ```
void optimisticPersistSeq({
  required int seq,
  required int Function() latestSeq,
  required void Function() applyOptimistic,
  required Future<void> Function() persist,
  required void Function(Object error, StackTrace stack) rollback,
  String? debugLabel,
}) {
  applyOptimistic();

  unawaited(() async {
    try {
      await persist();
      if (seq < latestSeq()) {
        // A newer save started after this one — its rollback semantics own
        // the post-failure path; we silently drop this success.
        debugPrint(
            '⏭️ [optimisticPersist] ${debugLabel ?? 'persist'} seq $seq superseded by ${latestSeq()}');
        return;
      }
      if (debugLabel != null) {
        debugPrint('✅ [optimisticPersist] $debugLabel (seq $seq) persisted');
      }
    } catch (e, st) {
      // Only the LATEST save's failure rolls back. Older failed saves are
      // already invalidated by a newer optimistic state.
      if (seq < latestSeq()) {
        debugPrint(
            '⏭️ [optimisticPersist] ${debugLabel ?? 'persist'} stale failure dropped (seq $seq < ${latestSeq()})');
        return;
      }
      debugPrint(
          '❌ [optimisticPersist] ${debugLabel ?? 'persist'} (seq $seq) failed: $e');
      try {
        rollback(e, st);
      } catch (rollbackError) {
        debugPrint(
            '❌ [optimisticPersist] rollback also failed: $rollbackError');
      }
    }
  }());
}

/// Debounce wrapper for Tier B toggle setters. Coalesces rapid taps into a
/// single trailing persist call ~[delay] after the last invocation, while
/// the UI state has already flipped on every tap. Disk cache writes are
/// kept per-tap by the caller (NOT debounced) so a kill mid-burst still
/// preserves the latest value.
class OptimisticDebouncer {
  OptimisticDebouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;
  Future<void> Function()? _pending;

  /// Schedule [action] to run after [delay] from the most recent call. If
  /// called again before the timer fires, the previous schedule is replaced.
  void schedule(Future<void> Function() action) {
    _pending = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      final task = _pending;
      _pending = null;
      if (task != null) unawaited(task());
    });
  }

  /// Run any pending action immediately (e.g. on app pause / dispose).
  void flush() {
    _timer?.cancel();
    final task = _pending;
    _pending = null;
    if (task != null) unawaited(task());
  }

  void dispose() {
    _timer?.cancel();
    _pending = null;
  }
}
