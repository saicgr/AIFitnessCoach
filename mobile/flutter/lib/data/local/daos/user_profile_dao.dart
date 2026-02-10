import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/user_profile_table.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [CachedUserProfiles])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Future<CachedUserProfile?> getProfile(String userId) {
    return (select(cachedUserProfiles)..where((p) => p.id.equals(userId)))
        .getSingleOrNull();
  }

  Future<void> upsertProfile(CachedUserProfilesCompanion entry) {
    return into(cachedUserProfiles).insertOnConflictUpdate(entry);
  }

  Future<void> clearProfile() {
    return delete(cachedUserProfiles).go();
  }
}
