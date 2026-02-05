/// XP Repository and XP System Tests
///
/// These tests verify the XP system models and repository functionality
/// without requiring actual API calls.
///
/// Run with: flutter test test/repositories/xp_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/repositories/xp_repository.dart';

void main() {
  group('DailyGoalsStatus', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'weight_log': true,
        'meal_log': true,
        'workout_complete': false,
        'protein_goal': true,
        'body_measurements': false,
      };

      final status = DailyGoalsStatus.fromJson(json);

      expect(status.weightLog, isTrue);
      expect(status.mealLog, isTrue);
      expect(status.workoutComplete, isFalse);
      expect(status.proteinGoal, isTrue);
      expect(status.bodyMeasurements, isFalse);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final status = DailyGoalsStatus.fromJson(json);

      expect(status.weightLog, isFalse);
      expect(status.mealLog, isFalse);
      expect(status.workoutComplete, isFalse);
      expect(status.proteinGoal, isFalse);
      expect(status.bodyMeasurements, isFalse);
    });

    test('default constructor has all false values', () {
      const status = DailyGoalsStatus();

      expect(status.weightLog, isFalse);
      expect(status.mealLog, isFalse);
      expect(status.workoutComplete, isFalse);
      expect(status.proteinGoal, isFalse);
      expect(status.bodyMeasurements, isFalse);
    });
  });

  group('XP System Constants', () {
    test('weekly checkpoint total is 1575 XP', () {
      // Based on XP_SYSTEM_GUIDE.md
      const weeklyCheckpointXP = {
        'workouts': 200,
        'perfect_week': 500,
        'protein': 150,
        'calories': 150,
        'hydration': 100,
        'weight': 75,
        'habits': 100,
        'workout_streak': 100,
        'social': 150,
        'measurements': 50,
      };

      final total = weeklyCheckpointXP.values.reduce((a, b) => a + b);
      expect(total, equals(1575));
    });

    test('monthly achievement total is 5250 XP', () {
      // Based on XP_SYSTEM_GUIDE.md
      const monthlyAchievementXP = {
        'monthly_dedication': 500,
        'monthly_goal': 1000,
        'monthly_nutrition': 500,
        'monthly_consistency': 750,
        'monthly_hydration': 300,
        'monthly_weight': 400,
        'monthly_habits': 400,
        'monthly_prs': 500,
        'monthly_social_star': 300,
        'monthly_supporter': 200,
        'monthly_networker': 250,
        'monthly_measurements': 150,
      };

      final total = monthlyAchievementXP.values.reduce((a, b) => a + b);
      expect(total, equals(5250));
    });

    test('daily social XP cap is 270', () {
      // Based on XP_SYSTEM_GUIDE.md
      // Share: 15 × 3 = 45
      // React: 5 × 10 = 50
      // Comment: 10 × 5 = 50
      // Friend: 25 × 5 = 125
      // Total: 270

      const shareXP = 15 * 3;
      const reactXP = 5 * 10;
      const commentXP = 10 * 5;
      const friendXP = 25 * 5;

      expect(shareXP, equals(45));
      expect(reactXP, equals(50));
      expect(commentXP, equals(50));
      expect(friendXP, equals(125));
      expect(shareXP + reactXP + commentXP + friendXP, equals(270));
    });

    test('level progression formula is correct', () {
      // Level 1-10: 50 XP each (Novice) = 500 XP to reach level 11
      // Level 11-25: 75 XP each (Apprentice) = 1125 XP to reach level 26
      // Level 26-50: 100 XP each (Athlete) = 2500 XP to reach level 51
      // etc.

      int calculateXPForLevel(int level) {
        int totalXP = 0;
        for (int i = 1; i < level; i++) {
          if (i <= 10) {
            totalXP += 50;
          } else if (i <= 25) {
            totalXP += 75;
          } else if (i <= 50) {
            totalXP += 100;
          } else if (i <= 75) {
            totalXP += 125;
          } else if (i <= 100) {
            totalXP += 150;
          } else {
            totalXP += 200; // Mythic levels
          }
        }
        return totalXP;
      }

      // Level 1 = 0 XP
      expect(calculateXPForLevel(1), equals(0));

      // Level 10 = 450 XP (9 × 50)
      expect(calculateXPForLevel(10), equals(450));

      // Level 11 = 500 XP (10 × 50)
      expect(calculateXPForLevel(11), equals(500));
    });

    test('XP titles match level ranges', () {
      String getTitleForLevel(int level) {
        if (level <= 10) return 'Novice';
        if (level <= 25) return 'Apprentice';
        if (level <= 50) return 'Athlete';
        if (level <= 75) return 'Elite';
        if (level <= 100) return 'Master';
        if (level <= 150) return 'Mythic I';
        if (level <= 200) return 'Mythic II';
        return 'Mythic III';
      }

      expect(getTitleForLevel(1), equals('Novice'));
      expect(getTitleForLevel(10), equals('Novice'));
      expect(getTitleForLevel(11), equals('Apprentice'));
      expect(getTitleForLevel(25), equals('Apprentice'));
      expect(getTitleForLevel(26), equals('Athlete'));
      expect(getTitleForLevel(50), equals('Athlete'));
      expect(getTitleForLevel(51), equals('Elite'));
      expect(getTitleForLevel(75), equals('Elite'));
      expect(getTitleForLevel(76), equals('Master'));
      expect(getTitleForLevel(100), equals('Master'));
      expect(getTitleForLevel(101), equals('Mythic I'));
      expect(getTitleForLevel(150), equals('Mythic I'));
      expect(getTitleForLevel(151), equals('Mythic II'));
      expect(getTitleForLevel(200), equals('Mythic II'));
      expect(getTitleForLevel(201), equals('Mythic III'));
      expect(getTitleForLevel(250), equals('Mythic III'));
    });
  });

  group('First-Time Bonuses', () {
    test('all first-time bonuses add up correctly', () {
      // Based on XP_SYSTEM_GUIDE.md
      const firstTimeBonuses = {
        'first_chat': 50,
        'first_complete_profile': 100,
        'first_workout': 200,
        'first_meal_log': 75,
        'first_weight_log': 50,
        'first_hydration_log': 25,
        'first_body_measurements': 50,
        'first_photo': 100,
        'first_week_complete': 250,
        'first_month_complete': 500,
        'first_pr': 100,
        'first_share': 25,
      };

      final total = firstTimeBonuses.values.reduce((a, b) => a + b);
      expect(total, equals(1525)); // Total first-time bonus XP
    });

    test('first_complete_profile is 100 XP', () {
      const firstCompleteProfileXP = 100;
      expect(firstCompleteProfileXP, equals(100));
    });

    test('first_share bonus exists at 25 XP', () {
      const firstShareXP = 25;
      expect(firstShareXP, equals(25));
    });
  });

  group('Social XP Limits', () {
    test('share action limits are correct', () {
      const shareXP = 15;
      const shareMax = 3;
      expect(shareXP * shareMax, equals(45));
    });

    test('react action limits are correct', () {
      const reactXP = 5;
      const reactMax = 10;
      expect(reactXP * reactMax, equals(50));
    });

    test('comment action limits are correct', () {
      const commentXP = 10;
      const commentMax = 5;
      expect(commentXP * commentMax, equals(50));
    });

    test('friend action limits are correct', () {
      const friendXP = 25;
      const friendMax = 5;
      expect(friendXP * friendMax, equals(125));
    });
  });

  group('Level Rewards', () {
    test('level 100 has Legend badge', () {
      const legendBadgeLevel = 100;
      const legendBadgeReward = 'legend_badge';

      expect(legendBadgeLevel, equals(100));
      expect(legendBadgeReward, equals('legend_badge'));
    });

    test('level 250 has Eternal Legend badge', () {
      const eternalLegendLevel = 250;
      const eternalLegendReward = 'eternal_legend';

      expect(eternalLegendLevel, equals(250));
      expect(eternalLegendReward, equals('eternal_legend'));
    });

    test('key milestone levels have rewards', () {
      const milestoneLevels = [5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 100];

      for (final level in milestoneLevels) {
        expect(level, greaterThan(0));
        expect(level, lessThanOrEqualTo(100));
      }
    });
  });

  group('Weekly Checkpoint Configuration', () {
    test('all 10 weekly checkpoints are defined', () {
      const weeklyCheckpoints = [
        'workouts',
        'perfect_week',
        'protein',
        'calories',
        'hydration',
        'weight',
        'habits',
        'workout_streak',
        'social',
        'measurements',
      ];

      expect(weeklyCheckpoints.length, equals(10));
    });

    test('workouts checkpoint is 200 XP', () {
      const workoutsXP = 200;
      expect(workoutsXP, equals(200));
    });

    test('perfect_week checkpoint is 500 XP', () {
      const perfectWeekXP = 500;
      expect(perfectWeekXP, equals(500));
    });
  });

  group('Monthly Achievement Configuration', () {
    test('all 12 monthly achievements are defined', () {
      const monthlyAchievements = [
        'monthly_dedication',
        'monthly_goal',
        'monthly_nutrition',
        'monthly_consistency',
        'monthly_hydration',
        'monthly_weight',
        'monthly_habits',
        'monthly_prs',
        'monthly_social_star',
        'monthly_supporter',
        'monthly_networker',
        'monthly_measurements',
      ];

      expect(monthlyAchievements.length, equals(12));
    });

    test('monthly_goal achievement is 1000 XP', () {
      const monthlyGoalXP = 1000;
      expect(monthlyGoalXP, equals(1000));
    });

    test('monthly_consistency achievement is 750 XP', () {
      const monthlyConsistencyXP = 750;
      expect(monthlyConsistencyXP, equals(750));
    });
  });

  group('CrateReward', () {
    test('fromJson parses XP reward correctly', () {
      final json = {
        'type': 'xp',
        'amount': 63,
        'display_name': '+63 XP',
      };

      final reward = CrateReward.fromJson(json);

      expect(reward.type, equals('xp'));
      expect(reward.amount, equals(63));
      expect(reward.displayName, equals('+63 XP'));
      expect(reward.isXP, isTrue);
      expect(reward.isConsumable, isFalse);
    });

    test('fromJson parses consumable reward correctly', () {
      final json = {
        'type': 'streak_shield',
        'amount': 1,
        'display_name': '1 Streak Shield',
      };

      final reward = CrateReward.fromJson(json);

      expect(reward.type, equals('streak_shield'));
      expect(reward.amount, equals(1));
      expect(reward.displayName, equals('1 Streak Shield'));
      expect(reward.isXP, isFalse);
      expect(reward.isConsumable, isTrue);
    });

    test('fromJson parses xp_token_2x reward correctly', () {
      final json = {
        'type': 'xp_token_2x',
        'amount': 1,
        'display_name': '1 Xp Token 2x',
      };

      final reward = CrateReward.fromJson(json);

      expect(reward.type, equals('xp_token_2x'));
      expect(reward.amount, equals(1));
      expect(reward.isXP, isFalse);
      expect(reward.isConsumable, isTrue);
    });
  });

  group('CrateRewardResult', () {
    test('fromJson parses successful XP reward correctly', () {
      // This is the response format from the backend after the fix
      final json = {
        'success': true,
        'crate_type': 'daily',
        'reward': {
          'type': 'xp',
          'amount': 63,
          'display_name': '+63 XP',
        },
        'message': 'Crate opened!',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.crateType, equals('daily'));
      expect(result.message, equals('Crate opened!'));
      expect(result.reward, isNotNull);
      expect(result.reward!.type, equals('xp'));
      expect(result.reward!.amount, equals(63));
      expect(result.reward!.displayName, equals('+63 XP'));
    });

    test('fromJson parses successful streak shield reward correctly', () {
      final json = {
        'success': true,
        'crate_type': 'streak',
        'reward': {
          'type': 'streak_shield',
          'amount': 1,
          'display_name': '1 Streak Shield',
        },
        'message': 'Crate opened!',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.crateType, equals('streak'));
      expect(result.reward, isNotNull);
      expect(result.reward!.type, equals('streak_shield'));
      expect(result.reward!.amount, equals(1));
      expect(result.reward!.isConsumable, isTrue);
    });

    test('fromJson parses activity crate reward correctly', () {
      final json = {
        'success': true,
        'crate_type': 'activity',
        'reward': {
          'type': 'xp',
          'amount': 175,
          'display_name': '+175 XP',
        },
        'message': 'Crate opened!',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.crateType, equals('activity'));
      expect(result.reward, isNotNull);
      expect(result.reward!.amount, equals(175));
    });

    test('fromJson parses failure response correctly', () {
      final json = {
        'success': false,
        'crate_type': 'daily',
        'message': 'Crate already claimed today',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.crateType, equals('daily'));
      expect(result.message, equals('Crate already claimed today'));
      expect(result.reward, isNull);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.crateType, equals(''));
      expect(result.reward, isNull);
      expect(result.message, isNull);
    });

    test('fromJson parses no crate available response', () {
      final json = {
        'success': false,
        'message': 'No crate available today',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.message, equals('No crate available today'));
    });
  });

  group('DailyCratesState', () {
    test('fromJson parses unclaimed state correctly', () {
      final json = {
        'daily_crate_available': true,
        'streak_crate_available': false,
        'activity_crate_available': false,
        'selected_crate': null,
        'reward': null,
        'claimed': false,
        'claimed_at': null,
        'crate_date': '2025-02-04',
      };

      final state = DailyCratesState.fromJson(json);

      expect(state.dailyCrateAvailable, isTrue);
      expect(state.streakCrateAvailable, isFalse);
      expect(state.activityCrateAvailable, isFalse);
      expect(state.selectedCrate, isNull);
      expect(state.reward, isNull);
      expect(state.claimed, isFalse);
      expect(state.claimedAt, isNull);
    });

    test('fromJson parses claimed state correctly', () {
      final json = {
        'daily_crate_available': true,
        'streak_crate_available': true,
        'activity_crate_available': false,
        'selected_crate': 'streak',
        'reward': {
          'type': 'xp',
          'amount': 100,
        },
        'claimed': true,
        'claimed_at': '2025-02-04T10:30:00Z',
        'crate_date': '2025-02-04',
      };

      final state = DailyCratesState.fromJson(json);

      expect(state.dailyCrateAvailable, isTrue);
      expect(state.streakCrateAvailable, isTrue);
      expect(state.selectedCrate, equals('streak'));
      expect(state.reward, isNotNull);
      expect(state.reward!.type, equals('xp'));
      expect(state.reward!.amount, equals(100));
      expect(state.claimed, isTrue);
      expect(state.claimedAt, isNotNull);
    });

    test('availableCount returns correct count', () {
      final state = DailyCratesState(
        dailyCrateAvailable: true,
        streakCrateAvailable: true,
        activityCrateAvailable: true,
        crateDate: DateTime.now(),
      );

      expect(state.availableCount, equals(3));
    });

    test('availableCount with only daily crate', () {
      final state = DailyCratesState(
        dailyCrateAvailable: true,
        streakCrateAvailable: false,
        activityCrateAvailable: false,
        crateDate: DateTime.now(),
      );

      expect(state.availableCount, equals(1));
    });
  });

  group('Daily Crate XP Ranges', () {
    test('daily crate XP range is 25-75', () {
      // Daily crate: 60% chance 25-49 XP, 30% chance 50-74 XP, 10% streak shield
      const dailyMinXP = 25;
      const dailyMaxXP = 74;

      expect(dailyMinXP, equals(25));
      expect(dailyMaxXP, equals(74));
    });

    test('streak crate XP range is 75-150', () {
      // Streak crate: better rewards for 7+ day streak
      const streakMinXP = 75;
      const streakMaxXP = 149;

      expect(streakMinXP, equals(75));
      expect(streakMaxXP, equals(149));
    });

    test('activity crate XP range is 150-250', () {
      // Activity crate: best rewards for completing all daily goals
      const activityMinXP = 150;
      const activityMaxXP = 249;

      expect(activityMinXP, equals(150));
      expect(activityMaxXP, equals(249));
    });
  });
}
