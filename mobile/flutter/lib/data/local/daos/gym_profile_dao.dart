import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/gym_profiles_table.dart';

part 'gym_profile_dao.g.dart';

@DriftAccessor(tables: [CachedGymProfiles])
class GymProfileDao extends DatabaseAccessor<AppDatabase>
    with _$GymProfileDaoMixin {
  GymProfileDao(super.db);

  Future<CachedGymProfile?> getActiveProfile(String userId) {
    return (select(cachedGymProfiles)
          ..where(
            (p) => p.userId.equals(userId) & p.isActive.equals(true),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<CachedGymProfile>> getAllProfiles(String userId) {
    return (select(cachedGymProfiles)
          ..where((p) => p.userId.equals(userId)))
        .get();
  }

  Future<void> upsertProfile(CachedGymProfilesCompanion entry) {
    return into(cachedGymProfiles).insertOnConflictUpdate(entry);
  }

  Future<void> upsertProfiles(List<CachedGymProfilesCompanion> entries) {
    return batch((b) {
      for (final entry in entries) {
        b.insert(
          cachedGymProfiles,
          entry,
          onConflict: DoUpdate((_) => entry),
        );
      }
    });
  }

  /// Wipe every cached gym-profile row owned by [userId]. Called from
  /// sign-out so the outgoing user's equipment list cannot bias the next
  /// account's workout generation.
  Future<int> clearForUser(String userId) {
    return (delete(cachedGymProfiles)..where((p) => p.userId.equals(userId)))
        .go();
  }
}
