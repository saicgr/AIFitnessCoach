/// Per-gym progress filter state.
///
/// This is intentionally and completely separate from the *active-workout*
/// gym (`activeGymProfileIdProvider`). Selecting a chip in the progress UI
/// only changes which gym's history a chart/score reads — it never changes the
/// gym workouts are generated for. See plan §E.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_history.dart';
import '../models/gym_profile.dart';
import '../models/scores.dart';
import '../repositories/exercise_history_repository.dart';
import '../repositories/scores_repository.dart';
import '../services/api_client.dart';
import 'gym_profile_provider.dart';

// ============================================================================
// Selection state
// ============================================================================

/// The selected progress-filter value for a single surface.
///
/// `gymProfileId == null` && `isAllGyms == false` means "not yet resolved" —
/// the host should adopt the endpoint's `resolved_scope` default the first
/// time it loads. `isAllGyms == true` means the explicit "All gyms" pool.
@immutable
class GymProgressSelection {
  /// The chosen gym profile id, or null when "All gyms" / unresolved.
  final String? gymProfileId;

  /// True when the user explicitly picked the pooled "All gyms" view.
  final bool isAllGyms;

  /// Whether this selection was resolved from the endpoint default (vs an
  /// explicit user tap). Hosts use this to know when to seed from
  /// `resolved_scope`.
  final bool resolved;

  const GymProgressSelection({
    this.gymProfileId,
    this.isAllGyms = false,
    this.resolved = false,
  });

  /// The unresolved initial state — host seeds it from `resolved_scope`.
  static const GymProgressSelection unresolved = GymProgressSelection();

  /// Explicit "All gyms" pooled view.
  static const GymProgressSelection allGyms =
      GymProgressSelection(isAllGyms: true, resolved: true);

  /// A specific gym.
  factory GymProgressSelection.gym(String id) =>
      GymProgressSelection(gymProfileId: id, resolved: true);

  /// The scope string the backend expects: `'current'` for a specific gym,
  /// `'all'` for the pooled view, or null when unresolved (let the backend
  /// pick the equipment-aware default).
  String? get scope {
    if (isAllGyms) return 'all';
    if (gymProfileId != null) return 'current';
    return null;
  }

  GymProgressSelection copyWith({
    String? gymProfileId,
    bool? isAllGyms,
    bool? resolved,
    bool clearGym = false,
  }) {
    return GymProgressSelection(
      gymProfileId: clearGym ? null : (gymProfileId ?? this.gymProfileId),
      isAllGyms: isAllGyms ?? this.isAllGyms,
      resolved: resolved ?? this.resolved,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GymProgressSelection &&
      other.gymProfileId == gymProfileId &&
      other.isAllGyms == isAllGyms &&
      other.resolved == resolved;

  @override
  int get hashCode => Object.hash(gymProfileId, isAllGyms, resolved);
}

/// Notifier holding the gym-progress selection for one surface key, with a
/// light persisted "last viewed gym filter" so re-opening a surface restores
/// the user's previous pick.
class GymProgressFilterNotifier extends StateNotifier<GymProgressSelection> {
  /// Surface key (e.g. `'exercise:Cable Row'`, `'strength'`, `'muscle'`).
  final String surfaceKey;

  GymProgressFilterNotifier(this.surfaceKey)
      : super(GymProgressSelection.unresolved) {
    _restore();
  }

  static const _prefsPrefix = 'gym_progress_filter_';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix$surfaceKey');
      if (raw == null) return;
      if (state.resolved) return; // host already seeded a default
      if (raw == '__all__') {
        state = GymProgressSelection.allGyms;
      } else if (raw.isNotEmpty) {
        state = GymProgressSelection.gym(raw);
      }
    } catch (_) {
      // Non-fatal — fall back to the endpoint default.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = state.isAllGyms ? '__all__' : (state.gymProfileId ?? '');
      await prefs.setString('$_prefsPrefix$surfaceKey', raw);
    } catch (_) {}
  }

  /// Seed the default from the endpoint's `resolved_scope` — only applied
  /// while the selection is still unresolved (no persisted pick, no user tap).
  /// `perGym == true` → default to [activeGymProfileId]; otherwise "All gyms".
  void seedDefault({required bool perGym, String? activeGymProfileId}) {
    if (state.resolved) return;
    if (perGym && activeGymProfileId != null) {
      state = GymProgressSelection.gym(activeGymProfileId);
    } else {
      state = GymProgressSelection.allGyms;
    }
  }

  /// User picked "All gyms".
  void selectAllGyms() {
    state = GymProgressSelection.allGyms;
    _persist();
  }

  /// User picked a specific gym.
  void selectGym(String gymProfileId) {
    state = GymProgressSelection.gym(gymProfileId);
    _persist();
  }

  /// Seed a specific gym as the active filter (used by deep-links such as the
  /// "Progress at this gym" affordance). Marks the selection resolved so the
  /// endpoint default does not override it.
  void seedGym(String gymProfileId) {
    state = GymProgressSelection.gym(gymProfileId);
    _persist();
  }
}

/// Family of progress-filter selections, keyed by an opaque surface string.
///
/// NOT autoDispose: the persisted "last viewed" pick should survive a quick
/// navigation away and back without a re-read flash.
final gymProgressFilterProvider = StateNotifierProvider.family<
    GymProgressFilterNotifier, GymProgressSelection, String>(
  (ref, surfaceKey) => GymProgressFilterNotifier(surfaceKey),
);

// ============================================================================
// Gym option list (live + archived)
// ============================================================================

/// A single selectable gym in the filter row.
@immutable
class GymFilterOption {
  final String id;
  final String name;

  /// Hex color string the gym owns (drives the colored dot).
  final String colorHex;
  final bool isArchived;

  const GymFilterOption({
    required this.id,
    required this.name,
    required this.colorHex,
    this.isArchived = false,
  });
}

/// Fetches gym profiles INCLUDING archived ones, so the progress filter can
/// still surface a gym whose history is being viewed after it was archived.
///
/// Lives here (not in `gym_profile_repository.dart`, which is owned elsewhere)
/// and hits the same `/gym-profiles/?include_archived=true` endpoint directly.
/// Falls back gracefully to the live (non-archived) list on any error.
final gymProgressProfilesProvider =
    FutureProvider<List<GymProfile>>((ref) async {
  // Keep the live list in sync — re-fetch when profiles change.
  ref.watch(gymProfilesProvider);
  final apiClient = ref.watch(apiClientProvider);
  try {
    final userId = await apiClient.getUserId();
    if (userId == null) return const [];
    final response = await apiClient.get(
      '/gym-profiles/',
      queryParameters: {
        'user_id': userId,
        'include_archived': true,
      },
    );
    if (response.statusCode == 200 && response.data is Map) {
      final list = GymProfileListResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return list.profiles;
    }
  } catch (e) {
    debugPrint('⚠️ [GymProgressFilter] include_archived fetch failed: $e');
  }
  // Fallback to the already-loaded live list.
  return ref.read(gymProfilesProvider).valueOrNull ?? const [];
});

/// Whether `gym_profile.archived_at` is set. The shared [GymProfile] model has
/// no `archivedAt` getter (its file is owned elsewhere), so we read it from the
/// decoded JSON map defensively.
bool _isArchived(GymProfile p) {
  try {
    final json = p.toJson();
    final v = json['archived_at'];
    return v != null && v.toString().isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Builds the filter option list. `liveProfiles` from [gymProfilesProvider]
/// always count as live; the archived set comes from
/// [gymProgressProfilesProvider]. Order: live (by displayOrder) then archived.
List<GymFilterOption> buildGymFilterOptions({
  required List<GymProfile> liveProfiles,
  required List<GymProfile> allProfiles,
  List<GymBreakdownEntry> breakdown = const [],
}) {
  final liveIds = liveProfiles.map((p) => p.id).toSet();

  // De-dupe by id; archived gyms are those in `allProfiles` that aren't live,
  // OR any breakdown gym not present in the live set.
  final byId = <String, GymFilterOption>{};

  final sortedLive = [...liveProfiles]
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  for (final p in sortedLive) {
    byId[p.id] = GymFilterOption(
      id: p.id,
      name: p.name,
      colorHex: p.color,
      isArchived: false,
    );
  }

  for (final p in allProfiles) {
    if (liveIds.contains(p.id)) continue;
    // A profile not in the live set is archived (it was excluded from the
    // non-archived list). Double-check the `archived_at` flag where present.
    byId[p.id] = GymFilterOption(
      id: p.id,
      name: p.name,
      colorHex: p.color,
      isArchived: _isArchived(p) || !liveIds.contains(p.id),
    );
  }

  // Any breakdown gym we still don't know about (e.g. archived + not returned)
  // gets a minimal option from the breakdown row itself.
  for (final b in breakdown) {
    final id = b.gymProfileId;
    if (id == null || byId.containsKey(id)) continue;
    byId[id] = GymFilterOption(
      id: id,
      name: b.gymName,
      colorHex: b.gymColor ?? '#9E9E9E',
      isArchived: !liveIds.contains(id),
    );
  }

  // Stable ordering: live first (already inserted in displayOrder), then
  // archived. Map insertion order in Dart is preserved, so live entries lead.
  final ordered = byId.values.toList();
  ordered.sort((a, b) {
    if (a.isArchived != b.isArchived) return a.isArchived ? 1 : -1;
    return 0;
  });
  return ordered;
}

// ============================================================================
// Gym-filtered data providers (read path)
// ============================================================================

/// Parameters for the gym-filtered exercise-history fetch.
@immutable
class GymExerciseHistoryArgs {
  final String exerciseName;
  final String timeRange;

  /// null gym + null scope → let the backend pick the equipment-aware default.
  final String? gymProfileId;
  final String? scope;

  const GymExerciseHistoryArgs({
    required this.exerciseName,
    required this.timeRange,
    this.gymProfileId,
    this.scope,
  });

  @override
  bool operator ==(Object other) =>
      other is GymExerciseHistoryArgs &&
      other.exerciseName == exerciseName &&
      other.timeRange == timeRange &&
      other.gymProfileId == gymProfileId &&
      other.scope == scope;

  @override
  int get hashCode =>
      Object.hash(exerciseName, timeRange, gymProfileId, scope);
}

/// Fetches an exercise's history WITH the per-gym filter applied, returning the
/// full [ExerciseHistoryResult] (incl. `resolved_scope` + `gym_breakdown`).
///
/// Kept separate from the existing `exerciseHistoryProvider` (which is owned by
/// another concern and only keyed by name) so the gym filter can drive its own
/// keyed fetch without editing that provider.
final gymExerciseHistoryProvider = FutureProvider.family<ExerciseHistoryResult,
    GymExerciseHistoryArgs>((ref, args) async {
  final repo = ref.watch(exerciseHistoryRepositoryProvider);
  return repo.getExerciseHistoryResult(
    exerciseName: args.exerciseName,
    timeRange: args.timeRange,
    gymProfileId: args.gymProfileId,
    scope: args.scope,
  );
});

/// Key for the gym-filtered per-exercise PR fetch.
typedef GymExercisePRsArgs = ({
  String exerciseName,
  String? gymProfileId,
  String? scope,
});

/// Fetches an exercise's PRs WITH the per-gym filter applied, so a machine/
/// cable PR set at one gym isn't crushed by an incomparable record elsewhere.
final gymExercisePRsProvider = FutureProvider.family<
    List<ExercisePersonalRecord>, GymExercisePRsArgs>((ref, args) async {
  final repo = ref.watch(exerciseHistoryRepositoryProvider);
  return repo.getExercisePRs(
    exerciseName: args.exerciseName,
    gymProfileId: args.gymProfileId,
    scope: args.scope,
  );
});

/// Parameters for the gym-filtered strength-score fetch.
@immutable
class GymStrengthScoresArgs {
  final String userId;
  final String? gymProfileId;

  const GymStrengthScoresArgs({required this.userId, this.gymProfileId});

  @override
  bool operator ==(Object other) =>
      other is GymStrengthScoresArgs &&
      other.userId == userId &&
      other.gymProfileId == gymProfileId;

  @override
  int get hashCode => Object.hash(userId, gymProfileId);
}

/// Fetches strength scores filtered to a specific gym. Only used when a gym is
/// explicitly selected in the strength surface; the combined view continues to
/// use the existing `scoresProvider` so nothing regresses.
final gymStrengthScoresProvider = FutureProvider.family<AllStrengthScores,
    GymStrengthScoresArgs>((ref, args) async {
  final repo = ref.watch(scoresRepositoryProvider);
  return repo.getAllStrengthScores(
    userId: args.userId,
    gymProfileId: args.gymProfileId,
  );
});

/// Key for the per-PR gym-tag fetch (Personal Records screen).
typedef PrGymTagsArgs = ({String userId, String? gymProfileId});

/// Per-exercise gym attribution map (`exerciseName.toLowerCase()` →
/// `{gym_profile_id, gym_name, gym_color}`) so the Personal Records screen can
/// label each PR with its gym color/name. Empty when no gym data is present
/// (single-gym users, legacy records) — labels simply don't render then.
final prGymTagsProvider =
    FutureProvider.family<Map<String, Map<String, String?>>, PrGymTagsArgs>(
        (ref, args) async {
  final repo = ref.watch(scoresRepositoryProvider);
  return repo.getPersonalRecordGymTags(
    userId: args.userId,
    gymProfileId: args.gymProfileId,
  );
});
