import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';
import 'auth_provider.dart';

/// Active-workout UI tiers. Easy is a thumb-first, polished screen for
/// most users; Advanced is the existing full-feature screen for power users.
///
/// The `simple` enum value is retained for DB backward-compat — users with
/// `workout_ui_mode = 'simple'` in Supabase are normalized to `easy` at
/// read-time and silently migrated on next profile write.
enum WorkoutUiMode {
  easy,
  @Deprecated('Simple tier was retired; retained for DB back-compat. '
      'fromString() normalizes "simple" → easy.')
  simple,
  advanced;

  /// Parse from the backend/SharedPreferences string form.
  /// Legacy `'simple'` is normalized to [easy].
  /// Unknown / null / empty → null (caller decides default).
  static WorkoutUiMode? fromString(String? value) {
    switch (value) {
      case 'easy':
      case 'simple': // Retired; treated as easy.
        return WorkoutUiMode.easy;
      case 'advanced':
        return WorkoutUiMode.advanced;
      default:
        return null;
    }
  }

  /// Serialize to the stored string form ('easy' | 'advanced').
  /// Deprecated `simple` serializes as `'easy'` to migrate on next write.
  String get asString => switch (this) {
        WorkoutUiMode.easy => 'easy',
        // ignore: deprecated_member_use_from_same_package
        WorkoutUiMode.simple => 'easy',
        WorkoutUiMode.advanced => 'advanced',
      };

  /// Display label for segmented controls.
  String get label => switch (this) {
        WorkoutUiMode.easy => 'Easy',
        // ignore: deprecated_member_use_from_same_package
        WorkoutUiMode.simple => 'Easy',
        WorkoutUiMode.advanced => 'Advanced',
      };

  /// Short label for narrow segmented controls.
  String get shortLabel => switch (this) {
        WorkoutUiMode.easy => 'E',
        // ignore: deprecated_member_use_from_same_package
        WorkoutUiMode.simple => 'E',
        WorkoutUiMode.advanced => 'A',
      };
}

/// State for the workout UI mode preference.
@immutable
class WorkoutUiModeState {
  final WorkoutUiMode mode;

  /// Whether the user has explicitly picked their tier via a toggle.
  /// Once true, auto-defaulting from fitness_level must never overwrite their
  /// choice — even if a sync pulls a different value from another device,
  /// the remote value still wins (it was also user-explicit there).
  final bool isUserExplicit;

  final bool isLoading;
  final String? error;

  const WorkoutUiModeState({
    this.mode = WorkoutUiMode.easy,
    this.isUserExplicit = false,
    this.isLoading = false,
    this.error,
  });

  WorkoutUiModeState copyWith({
    WorkoutUiMode? mode,
    bool? isUserExplicit,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutUiModeState(
      mode: mode ?? this.mode,
      isUserExplicit: isUserExplicit ?? this.isUserExplicit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// The canonical Riverpod source for the active-workout UI tier.
///
/// All four toggle surfaces (Settings, Profile, Workouts-tab header,
/// Active-workout top bar) read+write this one provider so they never
/// diverge. Persisted to both SharedPreferences (instant UX on cold start)
/// and Supabase `users.workout_ui_mode` (cross-device sync).
final workoutUiModeProvider =
    StateNotifierProvider<WorkoutUiModeNotifier, WorkoutUiModeState>((ref) {
  return WorkoutUiModeNotifier(ref);
});

class WorkoutUiModeNotifier extends StateNotifier<WorkoutUiModeState> {
  final Ref _ref;

  static const String _modeKey = 'workout_ui_mode';
  static const String _explicitKey = 'workout_ui_mode_user_explicit';

  WorkoutUiModeNotifier(this._ref) : super(const WorkoutUiModeState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      await _loadFromLocalStorage();
      await _syncFromBackend();

      // If we still have no explicit tier after local + backend, derive a
      // sensible default from fitness_level and persist it so the derivation
      // is stable (and visible cross-device) — but keep isUserExplicit=false
      // so a future fitness_level change could still shift it until the user
      // manually toggles.
      if (!state.isUserExplicit) {
        await _applyFitnessLevelDefault();
      }

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      debugPrint('❌ [WorkoutUiMode] Init error: $e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = WorkoutUiMode.fromString(prefs.getString(_modeKey));
    final storedExplicit = prefs.getBool(_explicitKey) ?? false;
    if (storedMode != null) {
      state = state.copyWith(
        mode: storedMode,
        isUserExplicit: storedExplicit,
      );
      debugPrint(
        '✅ [WorkoutUiMode] Loaded from local: ${storedMode.asString} (explicit=$storedExplicit)',
      );
    }
  }

  Future<void> _syncFromBackend() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      if (user == null) {
        debugPrint('⚠️ [WorkoutUiMode] No user, skipping backend sync');
        return;
      }

      // Legacy 'simple' row migration: if the DB still has workout_ui_mode
      // set to 'simple' (tier retired), silently write 'easy' upstream on
      // first post-auth sync. fromString already normalizes to easy so the
      // UI renders correctly; this just cleans up the stored string.
      if (user.workoutUiMode == 'simple') {
        _syncToBackend({'workout_ui_mode': 'easy'});
      }

      final remoteMode = WorkoutUiMode.fromString(user.workoutUiMode);
      final remoteExplicit = user.workoutUiModeUserExplicit ?? false;

      if (remoteMode != null) {
        // Remote has a value → trust it. If the remote was user-explicit we
        // honor that; otherwise keep our local explicit flag (which may be
        // true from a toggle that hasn't synced up yet).
        state = state.copyWith(
          mode: remoteMode,
          isUserExplicit: remoteExplicit || state.isUserExplicit,
        );
        await _saveToLocalStorage();
        debugPrint(
          '✅ [WorkoutUiMode] Synced from backend: ${remoteMode.asString} (explicit=$remoteExplicit)',
        );
      }
    } catch (e) {
      // Don't fail init on a backend hiccup; local values remain authoritative.
      debugPrint('⚠️ [WorkoutUiMode] Backend sync failed (keeping local): $e');
    }
  }

  Future<void> _applyFitnessLevelDefault() async {
    final authState = _ref.read(authStateProvider);
    final fitnessLevel = authState.user?.fitnessLevel;
    // Simple tier was retired; intermediate + legacy default to Easy, which
    // is now the polished default that most users land on.
    final derived = switch (fitnessLevel) {
      'beginner' => WorkoutUiMode.easy,
      'intermediate' => WorkoutUiMode.easy,
      'advanced' => WorkoutUiMode.advanced,
      _ => WorkoutUiMode.easy,
    };

    if (derived == state.mode) return; // already matches; nothing to persist

    state = state.copyWith(mode: derived);
    await _saveToLocalStorage();
    // Write the derived value to the backend so other devices pick it up on
    // next sync. Keep isUserExplicit=false so a later fitness_level change
    // could still nudge the default (until the user hits a toggle).
    await _syncToBackend({
      'workout_ui_mode': derived.asString,
      'workout_ui_mode_user_explicit': false,
    });
    debugPrint(
      '✅ [WorkoutUiMode] Defaulted from fitness_level=$fitnessLevel → ${derived.asString}',
    );
  }

  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, state.mode.asString);
    await prefs.setBool(_explicitKey, state.isUserExplicit);
  }

  Future<void> _syncToBackend(Map<String, dynamic> updates) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        debugPrint('⚠️ [WorkoutUiMode] No user ID, skipping backend sync');
        return;
      }
      await apiClient.put('${ApiConstants.users}/$userId', data: updates);
      // Refresh so authStateProvider carries the new values back to any
      // observer (e.g. tier-toggle rows in Settings/Profile).
      await _ref.read(authStateProvider.notifier).refreshUser();
      debugPrint('✅ [WorkoutUiMode] Synced to backend: $updates');
    } catch (e) {
      debugPrint('⚠️ [WorkoutUiMode] Backend sync failed: $e');
    }
  }

  /// Public API — the one way toggles set the tier. After this, the explicit
  /// flag is sticky: auto-defaulting from fitness_level will no longer
  /// override the user's choice.
  Future<void> setMode(WorkoutUiMode mode) async {
    if (mode == state.mode && state.isUserExplicit) return;
    state = state.copyWith(mode: mode, isUserExplicit: true);
    await _saveToLocalStorage();
    await _syncToBackend({
      'workout_ui_mode': mode.asString,
      'workout_ui_mode_user_explicit': true,
    });
  }

  /// Re-run the init flow — used by the tour service when fitness_level
  /// changes mid-session, or by Settings → "Reset to recommended" action.
  Future<void> refresh() async {
    await _init();
  }
}
