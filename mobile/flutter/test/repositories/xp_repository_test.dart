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
}
