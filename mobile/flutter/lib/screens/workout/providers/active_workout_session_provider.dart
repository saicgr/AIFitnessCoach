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

/// E2E #136 — a freshly re-entered workout used to rehydrate a checkpoint
/// SILENTLY no matter how old it was: `save()` wrote `saved_at_ms` but
/// `load()` never read it back, so abandoning a session by backing out
/// (which leaves the blob on disk — `clear()` is the only delete call site)
/// and later re-starting the SAME workoutId rehydrated elapsedSeconds /
/// completedSets / currentExerciseIndex with no prompt, no banner, nothing —
/// a brand-new "Start Workout" tap opened already 23m37s / 161 kcal / 666 kg
/// into a session the user never actually started this time.
///
/// Two thresholds:
///  - Beyond [kCheckpointHardTtl] the checkpoint is auto-expired — treated as
///    if it never existed. Nobody wants a "resume from 5 hours ago" prompt.
///  - Between [kCheckpointStalePromptThreshold] and the hard TTL, the
///    checkpoint is still valid but old enough that silently inflating the
///    session's duration/kcal would be wrong — the caller must show an
///    explicit Resume / Start Fresh choice (see `easy_active_workout_state.dart`
///    / `active_workout_screen_refactored.dart`) instead of auto-adopting it.
///  - Under the prompt threshold (e.g. app briefly backgrounded and
///    reopened, or a genuine crash a few seconds after logging a set) the
///    checkpoint auto-resumes exactly as before — no added friction for the
///    common case this feature exists for.
const Duration kCheckpointStalePromptThreshold = Duration(minutes: 10);
const Duration kCheckpointHardTtl = Duration(hours: 6);

class ActiveWorkoutSessionState {
  final String? workoutId;
  final Map<int, List<SetLog>> completedSets;
  final int currentExerciseIndex;

  /// Elapsed workout seconds at the moment of the last checkpoint write.
  /// RAM-only field — the live timer owns the authoritative value; this is
  /// only the value that gets persisted so a relaunch can restore the clock.
  final int elapsedSeconds;

  /// When this state came from an on-disk checkpoint, the wall-clock time
  /// (epoch ms) it was written — null for a live, non-restored session.
  /// E2E #136: the sole purpose of carrying this into memory is so a caller
  /// can decide whether adopting it silently is safe, or whether to prompt.
  final int? savedAtMs;

  const ActiveWorkoutSessionState({
    this.workoutId,
    this.completedSets = const {},
    this.currentExerciseIndex = 0,
    this.elapsedSeconds = 0,
    this.savedAtMs,
  });

  ActiveWorkoutSessionState copyWith({
    String? workoutId,
    Map<int, List<SetLog>>? completedSets,
    int? currentExerciseIndex,
    int? elapsedSeconds,
    int? savedAtMs,
  }) {
    return ActiveWorkoutSessionState(
      workoutId: workoutId ?? this.workoutId,
      completedSets: completedSets ?? this.completedSets,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      savedAtMs: savedAtMs ?? this.savedAtMs,
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
      // E2E #136 — `saved_at_ms` was written but never read. A checkpoint
      // older than the hard TTL is auto-expired (never even worth asking
      // about); a missing timestamp (pre-#136 blob) is treated as
      // maximally stale rather than trusted.
      final savedAtMs = (decoded['saved_at_ms'] as num?)?.toInt();
      final ageMs = savedAtMs == null
          ? kCheckpointHardTtl.inMilliseconds + 1
          : DateTime.now().millisecondsSinceEpoch - savedAtMs;
      if (ageMs > kCheckpointHardTtl.inMilliseconds) return null;
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
        savedAtMs: savedAtMs,
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

  /// E2E #136 — peek the on-disk checkpoint's AGE without adopting it into
  /// the live session, so the caller can decide whether silently rehydrating
  /// is safe or whether to show a "Resume / Start fresh" prompt first.
  ///
  /// Returns null when there's no checkpoint for [workoutId] (including an
  /// expired one — `_WorkoutCheckpointStore.load` already drops anything
  /// past [kCheckpointHardTtl]) or when it's genuinely empty (no logged
  /// sets — nothing to lose, always safe to silently continue). Otherwise
  /// returns the checkpoint's age; the caller compares it against
  /// [kCheckpointStalePromptThreshold] to decide whether to prompt.
  Future<Duration?> peekStaleCheckpoint({
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
    if (restored == null || restored.completedSets.values.every((l) => l.isEmpty)) {
      return null;
    }
    final savedAtMs = restored.savedAtMs;
    if (savedAtMs == null) return kCheckpointHardTtl; // treat as maximally stale
    final ageMs = DateTime.now().millisecondsSinceEpoch - savedAtMs;
    return Duration(milliseconds: ageMs < 0 ? 0 : ageMs);
  }

  /// Delete the on-disk checkpoint for the CURRENTLY-BOUND user without
  /// touching the live in-memory session (unlike [clear], which also wipes
  /// `state` — the caller has typically already called `start(workoutId)`
  /// for a fresh session by the time it decides to discard). Used when the
  /// user picks "Start fresh" on the #136 stale-checkpoint prompt.
  Future<void> discardOnDiskCheckpoint() async {
    final uid = _userId;
    if (uid == null) return;
    await _WorkoutCheckpointStore.delete(uid);
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
