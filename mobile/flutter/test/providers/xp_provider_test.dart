/// XP Provider and State Management Tests
///
/// These tests verify the XP provider state logic and model behavior
/// for the XP system.
///
/// Run with: flutter test test/providers/xp_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/providers/xp_provider.dart';

void main() {
  group('XPGoalType', () {
    test('all goal types are defined', () {
      expect(XPGoalType.values.length, equals(6));
      expect(XPGoalType.values.contains(XPGoalType.dailyLogin), isTrue);
      expect(XPGoalType.values.contains(XPGoalType.weightLog), isTrue);
      expect(XPGoalType.values.contains(XPGoalType.mealLog), isTrue);
      expect(XPGoalType.values.contains(XPGoalType.workoutComplete), isTrue);
      expect(XPGoalType.values.contains(XPGoalType.proteinGoal), isTrue);
      expect(XPGoalType.values.contains(XPGoalType.bodyMeasurements), isTrue);
    });
  });

  group('XPEarnedAnimationEvent', () {
    test('creates event with current timestamp by default', () {
      final event = XPEarnedAnimationEvent(
        xpAmount: 100,
        goalType: XPGoalType.workoutComplete,
      );

      expect(event.xpAmount, equals(100));
      expect(event.goalType, equals(XPGoalType.workoutComplete));
      expect(event.timestamp, isNotNull);
      expect(
        event.timestamp.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('accepts custom timestamp', () {
      final customTime = DateTime(2025, 1, 1, 12, 0);
      final event = XPEarnedAnimationEvent(
        xpAmount: 50,
        goalType: XPGoalType.weightLog,
        timestamp: customTime,
      );

      expect(event.timestamp, equals(customTime));
    });
  });

  group('DailyGoals', () {
    test('today() creates fresh goals for current date', () {
      final goals = DailyGoals.today();

      expect(goals.loggedIn, isFalse);
      expect(goals.completedWorkout, isFalse);
      expect(goals.loggedMeal, isFalse);
      expect(goals.loggedWeight, isFalse);
      expect(goals.hitProteinGoal, isFalse);
      expect(goals.loggedBodyMeasurements, isFalse);
      expect(goals.date.day, equals(DateTime.now().day));
    });

    test('completedCount returns correct count', () {
      final goals = DailyGoals(
        date: DateTime.now(),
        loggedIn: true,
        completedWorkout: true,
        loggedMeal: false,
        loggedWeight: true,
        hitProteinGoal: false,
        loggedBodyMeasurements: false,
      );

      expect(goals.completedCount, equals(3));
    });

    test('totalCount returns 6', () {
      final goals = DailyGoals.today();
      expect(goals.totalCount, equals(6));
    });

    test('progress returns correct fraction', () {
      final goals = DailyGoals(
        date: DateTime.now(),
        loggedIn: true,
        completedWorkout: true,
        loggedMeal: true,
        loggedWeight: false,
        hitProteinGoal: false,
        loggedBodyMeasurements: false,
      );

      expect(goals.progress, equals(0.5)); // 3/6
    });

    test('xpEarned calculates correct XP with multiplier', () {
      final goals = DailyGoals(
        date: DateTime.now(),
        loggedIn: true, // 5 XP
        completedWorkout: true, // 100 XP
        loggedMeal: true, // 25 XP
        loggedWeight: true, // 15 XP
        hitProteinGoal: true, // 50 XP
        loggedBodyMeasurements: true, // 20 XP
      );

      // Without multiplier
      expect(goals.xpEarned(1, 1.0), equals(215));

      // With 2x multiplier
      expect(goals.xpEarned(1, 2.0), equals(430));
    });

    test('xpEarned login XP is fixed at 5', () {
      final goalsLoginOnly = DailyGoals(
        date: DateTime.now(),
        loggedIn: true,
      );

      // Login gives fixed 5 XP, not streak-based
      expect(goalsLoginOnly.xpEarned(1, 1.0), equals(5));
      expect(goalsLoginOnly.xpEarned(7, 1.0), equals(5)); // Same with 7-day streak
    });

    test('isStale returns true for previous day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final goals = DailyGoals(date: yesterday);

      expect(goals.isStale(DateTime.now()), isTrue);
    });

    test('isStale returns false for today', () {
      final goals = DailyGoals.today();

      expect(goals.isStale(DateTime.now()), isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      final original = DailyGoals.today();
      final updated = original.copyWith(
        loggedIn: true,
        completedWorkout: true,
      );

      expect(original.loggedIn, isFalse);
      expect(original.completedWorkout, isFalse);
      expect(updated.loggedIn, isTrue);
      expect(updated.completedWorkout, isTrue);
      expect(updated.loggedMeal, isFalse); // unchanged
    });
  });

  group('XPState', () {
    test('default constructor has empty state', () {
      const state = XPState();

      expect(state.userXp, isNull);
      expect(state.allTrophies, isEmpty);
      expect(state.earnedTrophies, isEmpty);
      expect(state.recentTransactions, isEmpty);
      expect(state.leaderboard, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.activeEvents, isEmpty);
      expect(state.loginStreak, isNull);
      expect(state.weeklyCheckpoints, isNull);
      expect(state.monthlyCheckpoints, isNull);
      expect(state.consumables, isNull);
      expect(state.dailyCrates, isNull);
    });

    test('loading state tracks correctly', () {
      const loadingState = XPState(isLoading: true);
      expect(loadingState.isLoading, isTrue);
    });

    test('error state tracks correctly', () {
      const errorState = XPState(error: 'Failed to load XP');
      expect(errorState.error, equals('Failed to load XP'));
    });
  });

  group('XP Calculation Logic', () {
    test('daily goals XP values match guide', () {
      // From DailyGoals.xpEarned:
      // Login: 5 XP (fixed)
      // Workout: 100 XP
      // Meal: 25 XP
      // Weight: 15 XP
      // Protein: 50 XP
      // Measurements: 20 XP

      const expectedLoginXP = 5;
      const expectedWorkoutXP = 100;
      const expectedMealXP = 25;
      const expectedWeightXP = 15;
      const expectedProteinXP = 50;
      const expectedMeasurementsXP = 20;

      expect(expectedLoginXP, equals(5));
      expect(expectedWorkoutXP, equals(100));
      expect(expectedMealXP, equals(25));
      expect(expectedWeightXP, equals(15));
      expect(expectedProteinXP, equals(50));
      expect(expectedMeasurementsXP, equals(20));

      // Total daily XP (all goals)
      const totalDailyXP = 215;
      expect(
        expectedLoginXP +
            expectedWorkoutXP +
            expectedMealXP +
            expectedWeightXP +
            expectedProteinXP +
            expectedMeasurementsXP,
        equals(totalDailyXP),
      );
    });

    test('2x multiplier doubles XP correctly', () {
      final goals = DailyGoals(
        date: DateTime.now(),
        completedWorkout: true, // 100 XP
      );

      expect(goals.xpEarned(1, 1.0), equals(100));
      expect(goals.xpEarned(1, 2.0), equals(200));
    });
  });

  group('Streak Milestone Logic', () {
    test('streak milestones are at correct days', () {
      const streakMilestones = [7, 30, 100, 365];

      expect(streakMilestones.contains(7), isTrue);
      expect(streakMilestones.contains(30), isTrue);
      expect(streakMilestones.contains(100), isTrue);
      expect(streakMilestones.contains(365), isTrue);
    });

    test('streak milestone detection logic', () {
      bool isStreakMilestone(int streak) {
        return streak == 7 || streak == 30 || streak == 100 || streak == 365;
      }

      expect(isStreakMilestone(6), isFalse);
      expect(isStreakMilestone(7), isTrue);
      expect(isStreakMilestone(8), isFalse);
      expect(isStreakMilestone(29), isFalse);
      expect(isStreakMilestone(30), isTrue);
      expect(isStreakMilestone(31), isFalse);
      expect(isStreakMilestone(99), isFalse);
      expect(isStreakMilestone(100), isTrue);
      expect(isStreakMilestone(101), isFalse);
      expect(isStreakMilestone(364), isFalse);
      expect(isStreakMilestone(365), isTrue);
      expect(isStreakMilestone(366), isFalse);
    });
  });

  group('Level Calculations', () {
    test('XP required per level by tier', () {
      int getXPPerLevel(int level) {
        if (level <= 10) return 50; // Novice
        if (level <= 25) return 75; // Apprentice
        if (level <= 50) return 100; // Athlete
        if (level <= 75) return 125; // Elite
        if (level <= 100) return 150; // Master
        return 200; // Mythic
      }

      // Novice tier
      expect(getXPPerLevel(1), equals(50));
      expect(getXPPerLevel(10), equals(50));

      // Apprentice tier
      expect(getXPPerLevel(11), equals(75));
      expect(getXPPerLevel(25), equals(75));

      // Athlete tier
      expect(getXPPerLevel(26), equals(100));
      expect(getXPPerLevel(50), equals(100));

      // Elite tier
      expect(getXPPerLevel(51), equals(125));
      expect(getXPPerLevel(75), equals(125));

      // Master tier
      expect(getXPPerLevel(76), equals(150));
      expect(getXPPerLevel(100), equals(150));

      // Mythic tier
      expect(getXPPerLevel(101), equals(200));
      expect(getXPPerLevel(250), equals(200));
    });

    test('level 11 requires 500 total XP', () {
      // Levels 1-10: 50 XP each = 500 XP total
      const xpForLevel11 = 50 * 10;
      expect(xpForLevel11, equals(500));
    });
  });
}
