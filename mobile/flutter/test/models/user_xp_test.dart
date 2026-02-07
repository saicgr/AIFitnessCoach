import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/user_xp.dart';

void main() {
  group('UserXP', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = {
          'id': 'xp-1',
          'user_id': 'user-1',
          'total_xp': 1500,
          'current_level': 12,
          'xp_to_next_level': 50,
          'xp_in_current_level': 30,
          'prestige_level': 0,
          'title': 'Novice',
          'trust_level': 2,
        };
        final xp = UserXP.fromJson(json);

        expect(xp.id, 'xp-1');
        expect(xp.userId, 'user-1');
        expect(xp.totalXp, 1500);
        expect(xp.currentLevel, 12);
        expect(xp.xpToNextLevel, 50);
        expect(xp.xpInCurrentLevel, 30);
        expect(xp.prestigeLevel, 0);
        expect(xp.title, 'Novice');
        expect(xp.trustLevel, 2);
      });

      test('should use defaults for missing fields', () {
        final json = <String, dynamic>{};
        final xp = UserXP.fromJson(json);

        expect(xp.id, '');
        expect(xp.userId, '');
        expect(xp.totalXp, 0);
        expect(xp.currentLevel, 1);
        expect(xp.xpToNextLevel, 25);
        expect(xp.xpInCurrentLevel, 0);
        expect(xp.prestigeLevel, 0);
        expect(xp.title, 'Beginner');
        expect(xp.trustLevel, 1);
      });

      test('should handle xp_title field from API', () {
        final json = {
          'user_id': 'user-1',
          'xp_title': 'Elite',
          'total_xp': 5000,
          'current_level': 80,
        };
        final xp = UserXP.fromJson(json);

        expect(xp.title, 'Elite');
      });

      test('should use user_id as id fallback when id is missing', () {
        final json = {
          'user_id': 'user-42',
          'total_xp': 100,
        };
        final xp = UserXP.fromJson(json);

        expect(xp.id, 'user-42');
      });
    });

    group('progressFraction', () {
      test('should calculate correct progress', () {
        const xp = UserXP(xpInCurrentLevel: 15, xpToNextLevel: 50);

        expect(xp.progressFraction, 0.3);
      });

      test('should return 1.0 when xpToNextLevel is 0', () {
        const xp = UserXP(xpInCurrentLevel: 10, xpToNextLevel: 0);

        expect(xp.progressFraction, 1.0);
      });

      test('should clamp to 1.0 when over', () {
        const xp = UserXP(xpInCurrentLevel: 60, xpToNextLevel: 50);

        expect(xp.progressFraction, 1.0);
      });

      test('should clamp to 0.0 when negative', () {
        const xp = UserXP(xpInCurrentLevel: -5, xpToNextLevel: 50);

        expect(xp.progressFraction, 0.0);
      });
    });

    group('progressPercent', () {
      test('should return integer percentage', () {
        const xp = UserXP(xpInCurrentLevel: 15, xpToNextLevel: 50);

        expect(xp.progressPercent, 30);
      });

      test('should round to nearest integer', () {
        const xp = UserXP(xpInCurrentLevel: 33, xpToNextLevel: 100);

        expect(xp.progressPercent, 33);
      });
    });

    group('xpTitle', () {
      test('should return correct title for each level range', () {
        expect(const UserXP(currentLevel: 1).xpTitle, XPTitle.beginner);
        expect(const UserXP(currentLevel: 10).xpTitle, XPTitle.beginner);
        expect(const UserXP(currentLevel: 11).xpTitle, XPTitle.novice);
        expect(const UserXP(currentLevel: 25).xpTitle, XPTitle.novice);
        expect(const UserXP(currentLevel: 26).xpTitle, XPTitle.apprentice);
        expect(const UserXP(currentLevel: 50).xpTitle, XPTitle.apprentice);
        expect(const UserXP(currentLevel: 51).xpTitle, XPTitle.athlete);
        expect(const UserXP(currentLevel: 75).xpTitle, XPTitle.athlete);
        expect(const UserXP(currentLevel: 76).xpTitle, XPTitle.elite);
        expect(const UserXP(currentLevel: 100).xpTitle, XPTitle.elite);
        expect(const UserXP(currentLevel: 101).xpTitle, XPTitle.master);
        expect(const UserXP(currentLevel: 126).xpTitle, XPTitle.champion);
        expect(const UserXP(currentLevel: 151).xpTitle, XPTitle.legend);
        expect(const UserXP(currentLevel: 176).xpTitle, XPTitle.mythic);
        expect(const UserXP(currentLevel: 201).xpTitle, XPTitle.immortal);
        expect(const UserXP(currentLevel: 226).xpTitle, XPTitle.transcendent);
      });
    });

    group('formattedTotalXp', () {
      test('should show raw number below 1000', () {
        const xp = UserXP(totalXp: 500);

        expect(xp.formattedTotalXp, '500');
      });

      test('should show K format for thousands', () {
        const xp = UserXP(totalXp: 1500);

        expect(xp.formattedTotalXp, '1.5K');
      });

      test('should show M format for millions', () {
        const xp = UserXP(totalXp: 1500000);

        expect(xp.formattedTotalXp, '1.5M');
      });
    });

    group('formattedProgress', () {
      test('should show xp/total format', () {
        const xp = UserXP(xpInCurrentLevel: 30, xpToNextLevel: 50);

        expect(xp.formattedProgress, '30 / 50 XP');
      });

      test('should show 0 for negative xpInCurrentLevel', () {
        const xp = UserXP(xpInCurrentLevel: -5, xpToNextLevel: 50);

        expect(xp.formattedProgress, '0 / 50 XP');
      });
    });

    group('levelDisplay', () {
      test('should show Level N for no prestige', () {
        const xp = UserXP(currentLevel: 15, prestigeLevel: 0);

        expect(xp.levelDisplay, 'Level 15');
      });

      test('should show prestige prefix when prestiged', () {
        const xp = UserXP(currentLevel: 50, prestigeLevel: 2);

        expect(xp.levelDisplay, 'P2 Lvl 50');
      });
    });

    group('isMaxLevel', () {
      test('should return true at level 250', () {
        const xp = UserXP(currentLevel: 250);

        expect(xp.isMaxLevel, true);
      });

      test('should return false below 250', () {
        const xp = UserXP(currentLevel: 249);

        expect(xp.isMaxLevel, false);
      });
    });

    group('empty factory', () {
      test('should create with defaults and given userId', () {
        final xp = UserXP.empty('user-99');

        expect(xp.userId, 'user-99');
        expect(xp.totalXp, 0);
        expect(xp.currentLevel, 1);
        expect(xp.xpToNextLevel, 25);
        expect(xp.title, 'Beginner');
      });
    });
  });

  group('XPTitle extension', () {
    test('displayName should return correct text', () {
      expect(XPTitle.beginner.displayName, 'Beginner');
      expect(XPTitle.novice.displayName, 'Novice');
      expect(XPTitle.transcendent.displayName, 'Transcendent');
    });

    test('levelRange should return correct ranges', () {
      expect(XPTitle.beginner.levelRange, '1-10');
      expect(XPTitle.novice.levelRange, '11-25');
      expect(XPTitle.transcendent.levelRange, '226-250');
    });

    test('colorValue should be non-zero for all titles', () {
      for (final title in XPTitle.values) {
        expect(title.colorValue, isNonZero);
      }
    });
  });

  group('XPTransaction', () {
    test('should create from JSON', () {
      final json = {
        'id': 'tx-1',
        'user_id': 'user-1',
        'xp_amount': 50,
        'source': 'workout',
        'source_id': 'w-1',
        'description': 'Completed workout',
        'is_verified': true,
        'created_at': '2026-02-07T10:00:00Z',
      };
      final tx = XPTransaction.fromJson(json);

      expect(tx.id, 'tx-1');
      expect(tx.userId, 'user-1');
      expect(tx.xpAmount, 50);
      expect(tx.source, 'workout');
      expect(tx.description, 'Completed workout');
      expect(tx.isVerified, true);
    });

    group('sourceIcon', () {
      test('should return correct emoji for known sources', () {
        XPTransaction makeWithSource(String source) => XPTransaction(
              id: 'tx',
              userId: 'u',
              xpAmount: 10,
              source: source,
              createdAt: DateTime.now(),
            );

        expect(makeWithSource('workout').sourceIcon, contains(''));
        expect(makeWithSource('achievement').sourceIcon, isNotEmpty);
        expect(makeWithSource('pr').sourceIcon, isNotEmpty);
        expect(makeWithSource('streak').sourceIcon, isNotEmpty);
        expect(makeWithSource('unknown').sourceIcon, isNotEmpty);
      });
    });
  });

  group('XPSummary', () {
    test('should create from JSON', () {
      final json = {
        'total_xp': 2000,
        'current_level': 20,
        'title': 'Novice',
        'xp_to_next_level': 75,
        'xp_in_current_level': 40,
        'progress_percent': 53.3,
        'prestige_level': 0,
        'trust_level': 1,
        'rank_position': 5,
      };
      final summary = XPSummary.fromJson(json);

      expect(summary.totalXp, 2000);
      expect(summary.currentLevel, 20);
      expect(summary.rankPosition, 5);
      expect(summary.formattedRank, '#5');
      expect(summary.progressFraction, closeTo(0.533, 0.001));
    });
  });

  group('LevelUpEvent', () {
    test('should create from JSON', () {
      final json = {
        'new_level': 10,
        'old_level': 9,
        'new_title': 'Novice',
        'old_title': 'Beginner',
        'total_xp': 500,
        'xp_earned': 25,
        'unlocked_reward': 'Fitness Crate',
      };
      final event = LevelUpEvent.fromJson(json);

      expect(event.newLevel, 10);
      expect(event.oldLevel, 9);
      expect(event.hasNewTitle, true);
      expect(event.hasReward, true);
      expect(event.levelsGained, 1);
    });

    test('should detect when no new title', () {
      const event = LevelUpEvent(
        newLevel: 5,
        oldLevel: 4,
        newTitle: 'Beginner',
        oldTitle: 'Beginner',
      );

      expect(event.hasNewTitle, false);
    });

    test('should calculate multiple levels gained', () {
      const event = LevelUpEvent(newLevel: 15, oldLevel: 10);

      expect(event.levelsGained, 5);
    });
  });

  group('LevelUpReward', () {
    test('should create from JSON', () {
      final json = {
        'level': 10,
        'type': 'fitness_crate',
        'quantity': 1,
        'description': 'A fitness crate!',
        'bonus_type': 'streak_shield',
        'bonus_quantity': 1,
        'bonus_description': 'Bonus shield',
      };
      final reward = LevelUpReward.fromJson(json);

      expect(reward.level, 10);
      expect(reward.type, 'fitness_crate');
      expect(reward.hasBonus, true);
    });

    group('displayName', () {
      test('should return correct display names', () {
        expect(
          const LevelUpReward(level: 1, type: 'fitness_crate', quantity: 1, description: '').displayName,
          'Fitness Crate',
        );
        expect(
          const LevelUpReward(level: 1, type: 'premium_crate', quantity: 1, description: '').displayName,
          'Premium Crate',
        );
        expect(
          const LevelUpReward(level: 1, type: 'streak_shield', quantity: 1, description: '').displayName,
          'Streak Shield',
        );
        expect(
          const LevelUpReward(level: 1, type: 'xp_token_2x', quantity: 1, description: '').displayName,
          '2x XP Token',
        );
        expect(
          const LevelUpReward(level: 1, type: 'unknown', quantity: 1, description: '').displayName,
          'Reward',
        );
      });
    });

    group('icon', () {
      test('should return emoji for each type', () {
        expect(
          const LevelUpReward(level: 1, type: 'fitness_crate', quantity: 1, description: '').icon,
          isNotEmpty,
        );
        expect(
          const LevelUpReward(level: 1, type: 'unknown_type', quantity: 1, description: '').icon,
          isNotEmpty,
        );
      });
    });

    group('hasBonus', () {
      test('should return false when no bonus', () {
        const reward = LevelUpReward(level: 1, type: 'fitness_crate', quantity: 1, description: '');

        expect(reward.hasBonus, false);
      });
    });
  });

  group('XPLeaderboardEntry', () {
    test('should create from JSON', () {
      final json = {
        'user_id': 'user-1',
        'full_name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.jpg',
        'total_xp': 5000,
        'current_level': 30,
        'title': 'Apprentice',
        'prestige_level': 0,
        'rank': 1,
      };
      final entry = XPLeaderboardEntry.fromJson(json);

      expect(entry.userId, 'user-1');
      expect(entry.displayName, 'John Doe');
      expect(entry.totalXp, 5000);
      expect(entry.rank, 1);
      expect(entry.levelDisplay, 'Lvl 30');
    });

    test('should return Anonymous for null name', () {
      const entry = XPLeaderboardEntry(userId: 'u-1', fullName: null);

      expect(entry.displayName, 'Anonymous');
    });

    test('should show prestige in level display', () {
      const entry = XPLeaderboardEntry(
        userId: 'u-1',
        currentLevel: 100,
        prestigeLevel: 3,
      );

      expect(entry.levelDisplay, 'P3 Lvl 100');
    });
  });
}
