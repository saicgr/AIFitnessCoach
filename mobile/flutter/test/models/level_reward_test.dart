// Regression tests for E2E #371 — the merch unlock ladder must come from
// the backend `merch_type` value, never from a hardcoded level literal in
// this file. See mobile/flutter/lib/data/models/level_reward.dart and
// backend/api/v1/xp_endpoints.py (_get_merch_type_by_level).
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/level_reward.dart';

void main() {
  group('LevelRewards.getRewardForLevel merchType', () {
    test('backend merchType always wins, even at an old-ladder level', () {
      // Level 50 used to be hardcoded as the first merch tier
      // (sticker_pack). Under the rescaled ladder (migration 2424) it is
      // NOT a merch level — the backend correctly reports merchType: null.
      final reward = LevelRewards.getRewardForLevel(50, merchType: null);
      expect(reward.type, isNot(LevelRewardType.merch));
    });

    test('a backend-reported merch level produces a merch reward', () {
      // Level 20 is the new first merch tier (sticker_pack) per
      // merch_type_for_level() (migration 2424).
      final reward = LevelRewards.getRewardForLevel(20, merchType: 'sticker_pack');
      expect(reward.type, LevelRewardType.merch);
      expect(reward.name, contains('Sticker Pack'));
    });

    test('a level with no local milestone entry still surfaces backend merch', () {
      // Level 80 (full_merch_kit under the new ladder) has no entry in the
      // local milestone switch at all — the backend merchType must still
      // drive the reward rather than falling through to a generic XP/crate
      // reward.
      final reward = LevelRewards.getRewardForLevel(80, merchType: 'full_merch_kit');
      expect(reward.type, LevelRewardType.merch);
      expect(reward.name, contains('Full Merch Kit'));
    });

    test('null merchType (backend data not loaded yet) degrades to local flavor, never a guess', () {
      final reward = LevelRewards.getRewardForLevel(100, merchType: null);
      // Falls back to the local milestone switch's cosmetic copy for
      // level 100 — must not claim a specific merch item since that can
      // no longer be inferred from the level number alone.
      expect(reward.type, isNot(LevelRewardType.merch));
    });
  });
}
