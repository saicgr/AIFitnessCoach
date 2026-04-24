// Logic-only tests for the XP/weekly-summary/mastery math surfaced in the
// new Phase 2b–4d widgets. These are unit tests — no widget rendering —
// so they run fast and don't require a Flutter binding.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/user_xp.dart';
import 'package:fitwiz/data/models/weekly_xp_summary.dart';

void main() {
  group('UserXP.progressFraction', () {
    test('mid-level progress maps to correct fraction', () {
      const xp = UserXP(
        id: 'u1',
        userId: 'u1',
        currentLevel: 2,
        xpInCurrentLevel: 40,
        xpToNextLevel: 500,
      );
      expect(xp.progressFraction, closeTo(40 / 500, 1e-9));
      expect(xp.progressPercent, 8);
    });

    test('just-levelled-up renders as zero progress, not 100%', () {
      // Regression: old `currentXp % xpToNext` math would render this as
      // either 100% (wrap-around) or 0% depending on totals. The new
      // `xp_in_current_level / xp_to_next_level` is always correct.
      const xp = UserXP(
        id: 'u1',
        userId: 'u1',
        currentLevel: 3,
        xpInCurrentLevel: 0,
        xpToNextLevel: 700,
      );
      expect(xp.progressFraction, 0.0);
    });

    test('maxed level clamps to 1.0 instead of divide-by-zero', () {
      const xp = UserXP(
        id: 'u1',
        userId: 'u1',
        currentLevel: 250,
        xpInCurrentLevel: 0,
        xpToNextLevel: 0,
      );
      expect(xp.progressFraction, 1.0);
    });

    test('over-shoot is clamped (defensive against server data lag)', () {
      const xp = UserXP(
        id: 'u1',
        userId: 'u1',
        currentLevel: 2,
        xpInCurrentLevel: 600, // > xp_to_next
        xpToNextLevel: 500,
      );
      expect(xp.progressFraction, 1.0);
    });
  });

  group('WeeklyXpSummary', () {
    test('fromJson parses expected payload', () {
      final s = WeeklyXpSummary.fromJson({
        'this_week_xp': 420,
        'last_week_xp': 300,
        'sparkline_7day': [10, 20, 30, 40, 50, 60, 70],
        'next_nudge': 'log_breakfast',
      });
      expect(s.thisWeekXp, 420);
      expect(s.lastWeekXp, 300);
      expect(s.sparkline7day.length, 7);
      expect(s.nextNudge, 'log_breakfast');
      expect(s.delta, 120);
      expect(s.deltaPercent, closeTo(40.0, 1e-6));
      expect(s.sparklineMax, 70);
    });

    test('deltaPercent is null when lastWeek is zero (first-week guard)', () {
      final s = WeeklyXpSummary.fromJson({
        'this_week_xp': 150,
        'last_week_xp': 0,
        'sparkline_7day': [0, 0, 0, 0, 0, 0, 150],
        'next_nudge': '',
      });
      expect(s.deltaPercent, isNull);
      expect(s.delta, 150);
    });

    test('empty constant is stable', () {
      expect(WeeklyXpSummary.empty.thisWeekXp, 0);
      expect(WeeklyXpSummary.empty.sparkline7day.length, 7);
    });
  });

  group('NextLevelPreview', () {
    test('fromJson with full reward block', () {
      final p = NextLevelPreview.fromJson({
        'level': 4,
        'xp_in_level': 60,
        'xp_to_next': 300,
        'reward': {
          'kind': 'functional',
          'label': 'Second coach persona',
          'icon': 'switch_account_outlined',
          'tier': 'gold',
        },
      });
      expect(p.level, 4);
      expect(p.progressFraction, closeTo(60 / 300, 1e-9));
      expect(p.reward.kind, 'functional');
      expect(p.reward.tier, 'gold');
    });

    test('fromJson falls back to stub reward when server omits', () {
      final p = NextLevelPreview.fromJson({
        'level': 1,
        'xp_in_level': 0,
        'xp_to_next': 150,
      });
      expect(p.reward.kind, 'cosmetic');
      expect(p.reward.label, 'New cosmetic unlock');
    });
  });
}
