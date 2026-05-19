// Shared mid-workout session state. Both the Easy and Advanced active-
// workout screens read on init / write on every logged set so that
// flipping the tier toggle mid-session preserves all completed sets and
// the current exercise index.
//
// The session is keyed by `workoutId` — `start(id)` only clears state
// when the id differs from what's already there, so a tier swap (which
// remounts the screen with the same workout id) keeps the data.
//
// ── WF4: crash-safe checkpoint ──────────────────────────────────────────
// Completed sets / current exercise / elapsed timer used to be RAM-only —
// killing the app mid-workout lost everything. Every mutation here now also
// debounce-persists a single JSON blob to SharedPreferences ([_WorkoutCheckpointStore]),
// keyed by workoutId and user-scoped. On relaunch / active-workout-screen
// mount, [restoreCheckpoint] rehydrates the in-memory session from disk.
// The blob is deleted on workout completion or explicit discard so a
// finished workout can never be "resumed" with stale sets.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_state.dart';

/// Schema version for the persisted checkpoint envelope. A mismatch drops
/// the slot (treated as no checkpoint) rather than mis-deserializing.
const int _kCheckpointSchemaVersion = 1;

/// SharedPreferences key prefix — `workout_checkpoint::<userId>`.
/// One slot per user; the blob itself carries the workoutId so a stale
/// checkpoint for a *different* workout is ignored on restore.
const String _kCheckpointPrefix = 'workout_checkpoint';

class ActiveWorkoutSessionState {
  final String? workoutId;
  final Map<int, List<SetLog>> completedSets;
  final int currentExerciseIndex;

  /// Elapsed workout seconds at the moment of the last checkpoint write.
  /// RAM-only field — the live timer owns the authoritative value; this is
  /// only the value that gets persisted so a relaunch can restore the clock.
  final int elapsedSeconds;

  const ActiveWorkoutSessionState({
    this.workoutId,
    this.completedSets = const {},
    this.currentExerciseIndex = 0,
    this.elapsedSeconds = 0,
  });

  ActiveWorkoutSessionState copyWith({
    String? workoutId,
    Map<int, List<SetLog>>? completedSets,
    int? currentExerciseIndex,
    int? elapsedSeconds,
  }) {
    return ActiveWorkoutSessionState(
      workoutId: workoutId ?? this.workoutId,
      completedSets: completedSets ?? this.completedSets,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

/// SharedPreferences-backed persistence for the in-progress workout. NOT a
/// Drift table by design — codegen is forbidden in this repo and the payload
/// is a single small JSON blob, so a prefs slot is the right tool.
class _WorkoutCheckpointStore {
  static String _key(String userId) => '$_kCheckpointPrefix::$userId';

  /// Serialize the live session to disk. Keyed by [userId]; the blob embeds
  /// [workoutId] so a restore for a different workout is rejected. No-op if
  /// there's nothing meaningful to save (no workout, no sets logged).
  static Future<void> save({
    required String userId,
    required ActiveWorkoutSessionState state,
  }) async {
    final workoutId = state.workoutId;
    if (workoutId == null) return;
    try {
      final completed = <String, List<Map<String, dynamic>>>{};
      state.completedSets.forEach((idx, logs) {
        completed['$idx'] = logs.map((l) => l.toJson()).toList();
      });
      final envelope = {
        'v': _kCheckpointSchemaVersion,
        'workout_id': workoutId,
        'current_exercise_index': state.currentExerciseIndex,
        'elapsed_seconds': state.elapsedSeconds,
        'saved_at_ms': DateTime.now().millisecondsSinceEpoch,
        'completed_sets': completed,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId), jsonEncode(envelope));
    } catch (e) {
      // Never let a checkpoint write crash a workout — it's best-effort.
      debugPrint('⚠️ [WorkoutCheckpoint] save failed: $e');
    }
  }

  /// Load the checkpoint for [userId]. Returns null on miss, schema
  /// mismatch, corruption, or a workoutId mismatch when [expectedWorkoutId]
  /// is supplied. Never throws.
  static Future<ActiveWorkoutSessionState?> load({
    required String userId,
    String? expectedWorkoutId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['v'] != _kCheckpointSchemaVersion) return null;
      final workoutId = decoded['workout_id'] as String?;
      if (workoutId == null) return null;
      // A checkpoint for a different workout must not bleed into this one.
      if (expectedWorkoutId != null && workoutId != expectedWorkoutId) {
        return null;
      }
      final completedRaw = decoded['completed_sets'];
      final completed = <int, List<SetLog>>{};
      if (completedRaw is Map) {
        completedRaw.forEach((k, v) {
          final idx = int.tryParse(k.toString());
          if (idx == null || v is! List) return;
          completed[idx] = v
              .whereType<Map>()
              .map((m) => SetLog.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        });
      }
      return ActiveWorkoutSessionState(
        workoutId: workoutId,
        completedSets: completed,
        currentExerciseIndex:
            (decoded['current_exercise_index'] as num?)?.toInt() ?? 0,
        elapsedSeconds: (decoded['elapsed_seconds'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('⚠️ [WorkoutCheckpoint] load failed: $e');
      return null;
    }
  }

  /// Delete the checkpoint slot for [userId] (workout finished or discarded).
  static Future<void> delete(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (e) {
      debugPrint('⚠️ [WorkoutCheckpoint] delete failed: $e');
    }
  }
}

class ActiveWorkoutSessionNotifier
    extends StateNotifier<ActiveWorkoutSessionState> {
  ActiveWorkoutSessionNotifier() : super(const ActiveWorkoutSessionState()) {
    _instances.add(this);
  }

  /// Track every live notifier so [clearCache] (a static, called from the
  /// sign-out orchestration in AuthRepository) can reach the in-memory
  /// session state without holding a Ref. There is normally only one
  /// instance — the StateNotifierProvider is not autoDispose — but the
  /// set keeps us safe across hot-reload / test rebuilds.
  static final Set<ActiveWorkoutSessionNotifier> _instances = {};

  /// User id used to scope the SharedPreferences checkpoint slot. Set via
  /// [bindUser] from the active-workout screens once auth is known. Null →
  /// checkpoint persistence is skipped (defensive — should never happen in
  /// a real session, but we never crash on it).
  String? _userId;

  /// Debounce timer so a burst of mutations (set logged → rest started →
  /// index changed) collapses into a single disk write.
  Timer? _checkpointDebounce;

  /// Debounce window for checkpoint writes. Short enough that an app kill a
  /// second after a set is logged still has the set on disk; long enough to
  /// coalesce the 2-3 mutations a single "log set" fires.
  static const Duration _checkpointDebounceWindow = Duration(milliseconds: 600);

  /// Wipe in-memory active-workout state on sign-out. Without this, a
  /// user who signs out mid-workout and signs in as a different account
  /// would briefly see the prior user's completed-sets map / current
  /// exercise index until the next `start()` call clobbered it.
  static void clearCache() {
    for (final n in _instances) {
      if (n.mounted) {
        n._checkpointDebounce?.cancel();
        n.state = const ActiveWorkoutSessionState();
        n._userId = null;
      }
    }
  }

  /// Associate the current user with this session so checkpoint reads/writes
  /// land in the correct user-scoped prefs slot. Idempotent.
  void bindUser(String? userId) {
    if (userId != null && userId.isNotEmpty) _userId = userId;
  }

  /// Begin (or continue) a session for [workoutId]. If the existing
  /// session is for a different workout, clear it. Otherwise leave it
  /// alone so a tier swap retains progress.
  void start(String? workoutId) {
    if (workoutId == null) return;
    if (state.workoutId == workoutId) return; // same workout — keep state
    state = ActiveWorkoutSessionState(workoutId: workoutId);
  }

  /// WF4: rehydrate this session from the on-disk checkpoint for [workoutId].
  ///
  /// Call once from the active-workout screen's mount path. Returns the
  /// restored state when a valid checkpoint existed for THIS workout (so the
  /// screen can re-seed its local maps + timer), or null when there was
  /// nothing to restore. Restoring also makes the restored state the live
  /// in-memory session so a subsequent tier swap keeps the same sets.
  ///
  /// A checkpoint with zero logged sets is still honored for the timer /
  /// current-exercise restore, but the caller can cheaply detect that case
  /// via `completedSets.isEmpty`.
  Future<ActiveWorkoutSessionState?> restoreCheckpoint({
    required String? workoutId,
    String? userId,
  }) async {
    if (workoutId == null) return null;
    bindUser(userId);
    final uid = _userId;
    if (uid == null) return null;

    final restored = await _WorkoutCheckpointStore.load(
      userId: uid,
      expectedWorkoutId: workoutId,
    );
    if (restored == null) return null;

    // Only adopt the checkpoint if the live session isn't already richer
    // for this workout (e.g. a tier swap already populated it this session).
    final liveIsRicherForSameWorkout = state.workoutId == workoutId &&
        _setCount(state.completedSets) >= _setCount(restored.completedSets);
    if (!liveIsRicherForSameWorkout) {
      state = restored;
    }
    return state;
  }

  static int _setCount(Map<int, List<SetLog>> m) =>
      m.values.fold<int>(0, (sum, l) => sum + l.length);

  /// Append a freshly-logged set for [exerciseIndex]. No-ops if the
  /// session was never started (defensive — log paths should always
  /// `start` first).
  void recordSet(int exerciseIndex, SetLog log) {
    if (state.workoutId == null) return;
    final next = Map<int, List<SetLog>>.from(state.completedSets);
    final list = List<SetLog>.from(next[exerciseIndex] ?? const <SetLog>[]);
    list.add(log);
    next[exerciseIndex] = list;
    state = state.copyWith(completedSets: next);
    _scheduleCheckpoint();
  }

  /// Replace an existing set at [setIndex] within [exerciseIndex] (used
  /// when the user edits a previously-logged set).
  void replaceSet(int exerciseIndex, int setIndex, SetLog log) {
    if (state.workoutId == null) return;
    final next = Map<int, List<SetLog>>.from(state.completedSets);
    final list = List<SetLog>.from(next[exerciseIndex] ?? const <SetLog>[]);
    if (setIndex < 0 || setIndex >= list.length) return;
    list[setIndex] = log;
    next[exerciseIndex] = list;
    state = state.copyWith(completedSets: next);
    _scheduleCheckpoint();
  }

  /// Replace the entire completed-sets map with [completedSets] and
  /// re-checkpoint.
  ///
  /// The append/replace/pop-last mutators can't express an arbitrary
  /// mid-list deletion (delete set 2 of 4, "uncomplete" an arbitrary set).
  /// Callers that mutate their local sets map by deletion call this with a
  /// fresh snapshot so the on-disk checkpoint EXACTLY mirrors what the user
  /// currently has logged — a restored checkpoint must never resurrect a
  /// set the user deleted. A deep copy is taken so later local mutations
  /// don't retroactively alter the persisted snapshot.
  void syncSets(Map<int, List<SetLog>> completedSets) {
    if (state.workoutId == null) return;
    final next = <int, List<SetLog>>{};
    completedSets.forEach((idx, logs) {
      next[idx] = List<SetLog>.from(logs);
    });
    state = state.copyWith(completedSets: next);
    _scheduleCheckpoint();
  }

  /// Drop the last set for [exerciseIndex] (used when undoing).
  void popLastSet(int exerciseIndex) {
    if (state.workoutId == null) return;
    final next = Map<int, List<SetLog>>.from(state.completedSets);
    final list = List<SetLog>.from(next[exerciseIndex] ?? const <SetLog>[]);
    if (list.isEmpty) return;
    list.removeLast();
    next[exerciseIndex] = list;
    state = state.copyWith(completedSets: next);
    _scheduleCheckpoint();
  }

  void setCurrentIndex(int idx) {
    if (state.workoutId == null) return;
    if (state.currentExerciseIndex == idx) return;
    state = state.copyWith(currentExerciseIndex: idx);
    _scheduleCheckpoint();
  }

  /// Record the latest elapsed workout time so a relaunch can restore the
  /// clock. Cheap, idempotent — callers feed it from the timer tick. To
  /// avoid a disk write every single second we only re-checkpoint when the
  /// value moved by at least 5s (the debounce coalesces the rest).
  void updateElapsedSeconds(int seconds) {
    if (state.workoutId == null) return;
    if ((seconds - state.elapsedSeconds).abs() < 5) {
      // Still keep the in-memory value fresh so the next set-triggered
      // checkpoint persists an accurate clock — just skip scheduling a write.
      state = state.copyWith(elapsedSeconds: seconds);
      return;
    }
    state = state.copyWith(elapsedSeconds: seconds);
    _scheduleCheckpoint();
  }

  /// Debounced checkpoint write. A burst of mutations collapses into one
  /// SharedPreferences write [_checkpointDebounceWindow] after the last one.
  void _scheduleCheckpoint() {
    final uid = _userId;
    if (uid == null) return; // user not bound yet — nothing to scope to
    _checkpointDebounce?.cancel();
    // Snapshot the state now so a later mutation can't change what we save.
    final snapshot = state;
    _checkpointDebounce = Timer(_checkpointDebounceWindow, () {
      unawaited(_WorkoutCheckpointStore.save(userId: uid, state: snapshot));
    });
  }

  /// Force an immediate (non-debounced) checkpoint write. Used when the app
  /// is about to background — we can't rely on the debounce timer firing
  /// before the process is frozen / killed.
  Future<void> flushCheckpoint() async {
    final uid = _userId;
    if (uid == null || state.workoutId == null) return;
    _checkpointDebounce?.cancel();
    await _WorkoutCheckpointStore.save(userId: uid, state: state);
  }

  /// Wipe the session. Call when the user finalizes or quits the
  /// workout — otherwise re-entering the same workout would double-
  /// count old sets. Also deletes the on-disk checkpoint so a finished
  /// workout can never be resumed with stale sets.
  void clear() {
    _checkpointDebounce?.cancel();
    final uid = _userId;
    if (uid != null) {
      unawaited(_WorkoutCheckpointStore.delete(uid));
    }
    state = const ActiveWorkoutSessionState();
  }

  @override
  void dispose() {
    _checkpointDebounce?.cancel();
    _instances.remove(this);
    super.dispose();
  }
}

final activeWorkoutSessionProvider = StateNotifierProvider<
    ActiveWorkoutSessionNotifier, ActiveWorkoutSessionState>(
  (ref) => ActiveWorkoutSessionNotifier(),
);
