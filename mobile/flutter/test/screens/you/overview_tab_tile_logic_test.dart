import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/you/tabs/overview_tab.dart';

void main() {
  group('leaderboardTapShouldNavigate', () {
    test('does not navigate while locked', () {
      // Regression for row 152: the SOCIAL tile read "8 to unlock / Log 8
      // more workouts" yet a single tap always opened the fully-populated
      // global XP leaderboard — the destination enforces no gate of its
      // own, so the tile's stated lock was pure decoration.
      expect(leaderboardTapShouldNavigate(false), isFalse);
    });

    test('navigates once unlocked, and when unlock status is unknown', () {
      expect(leaderboardTapShouldNavigate(true), isTrue);
      expect(leaderboardTapShouldNavigate(null), isTrue);
    });
  });

  group('activeSkillTileTitle', () {
    const active = 'ACTIVE SKILL';

    test('only reads ACTIVE SKILL when a chain is actually in progress', () {
      expect(
        activeSkillTileTitle(hasActive: true, activeLabel: active),
        active,
      );
    });

    test(
        'reads something other than ACTIVE SKILL for a mere recommendation '
        '(regression for row 151/201: the tile used to say "ACTIVE SKILL / '
        'Pushup Mastery / Try this next" — a fact and a recommendation '
        'under the same heading — while the Rewards tab correctly read '
        '"SKILLS · 0 active" for the identical user_skill_progress emptiness)',
        () {
      final title = activeSkillTileTitle(hasActive: false, activeLabel: active);
      expect(title, isNot(active));
    });
  });
}
