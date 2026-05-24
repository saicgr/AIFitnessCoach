import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scores.dart';
import '../providers/scores_provider.dart';

/// Thin facade over `scoresProvider` for Recovery-Readiness consumers
/// (home tile, detail screen). Keeps composer-facing widgets decoupled
/// from `scoresProvider`'s broader surface — when the new migration-2094
/// fields (rhr_*, weekly_trimp, cardio_load_state) get added to the
/// ReadinessScore JSON model they only need to be wired here, not in
/// every consumer.
///
/// The Wave 2 composer agent wires this into the home screen.
class ReadinessRepository {
  ReadinessRepository(this._ref);

  final Ref _ref;

  /// Today's check-in (or null if the user hasn't checked in yet).
  ReadinessScore? get today => _ref.read(todayReadinessProvider);

  /// True when the user has logged a readiness check-in today.
  bool get hasCheckedInToday => _ref.read(hasCheckedInTodayProvider);

  /// Trigger a fresh load of today's scores (Hooper + cardio extension).
  Future<void> refresh(String userId) async {
    await _ref.read(scoresProvider.notifier).loadScoresOverview(userId: userId);
  }
}

/// Repository provider — consumed by `readiness_tile.dart` and
/// `readiness_detail_screen.dart` (owned by Phase A.5).
final readinessRepositoryProvider = Provider<ReadinessRepository>((ref) {
  return ReadinessRepository(ref);
});

/// Convenience: today's readiness score reactive read for tile consumers.
/// Re-exported so the tile doesn't need to import scoresProvider directly.
final todayReadinessScoreProvider = Provider<ReadinessScore?>((ref) {
  return ref.watch(todayReadinessProvider);
});

/// True while the readiness sub-tree is calibrating (no check-in today AND
/// no historical baseline yet — surfaced as the "Building baseline" tile).
final readinessCalibratingProvider = Provider<bool>((ref) {
  final state = ref.watch(scoresProvider);
  if (state.isLoading && state.overview == null) return false;
  return !state.hasCheckedInToday && state.todayReadiness == null;
});
