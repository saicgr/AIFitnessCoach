import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/trophy.dart';
import 'package:fitwiz/screens/trophies/trophy_room_screen.dart';

Trophy _trophy({required bool isSecret, required bool isHidden}) => Trophy(
      id: '$isSecret-$isHidden-${identityHashCode(Object())}',
      name: 'T',
      description: '',
      category: 'consistency',
      icon: 'star',
      tier: 'bronze',
      points: 10,
      isSecret: isSecret,
      isHidden: isHidden,
    );

void main() {
  group('mysteryStats', () {
    test(
        'counts is_secret OR is_hidden (matching TrophyProgress.isMystery), '
        'not is_secret alone', () {
      // Regression for row 149: the stat strip used to read
      // summary.secretDiscovered/totalSecret (is_secret only = 30) while the
      // Mystery Trophies section below counted is_secret OR is_hidden (= 40)
      // for the exact same on-screen "Mystery" label — two different
      // denominators two inches apart. mysteryStats() is now the single
      // source both call sites read from.
      final trophies = [
        for (var i = 0; i < 30; i++)
          TrophyProgress(trophy: _trophy(isSecret: true, isHidden: false)),
        for (var i = 0; i < 10; i++)
          TrophyProgress(trophy: _trophy(isSecret: false, isHidden: true)),
        // Non-mystery trophies must not be counted at all.
        for (var i = 0; i < 5; i++)
          TrophyProgress(trophy: _trophy(isSecret: false, isHidden: false)),
      ];

      final (discovered, total) = mysteryStats(trophies);

      expect(total, 40, reason: 'is_secret(30) + is_hidden(10), not 30');
      expect(discovered, 0);
    });

    test('an earned mystery trophy counts toward discovered but drops out of total via isMystery semantics only when still unearned is false', () {
      // isMystery is `!isEarned && (isHidden || isSecret)`, so an EARNED
      // secret trophy is no longer "mystery" — discovered/total both reflect
      // that (matches TrophyProgress.isMystery's own contract).
      final trophies = [
        TrophyProgress(
          trophy: _trophy(isSecret: true, isHidden: false),
          isEarned: true,
        ),
        TrophyProgress(trophy: _trophy(isSecret: true, isHidden: false)),
      ];
      final (discovered, total) = mysteryStats(trophies);
      // The earned one is excluded from "mystery" entirely (isMystery=false
      // once earned), leaving exactly the 1 still-unearned secret trophy.
      expect(total, 1);
      expect(discovered, 0);
    });
  });
}
