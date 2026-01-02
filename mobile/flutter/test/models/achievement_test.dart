import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/achievement.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AchievementType', () {
    group('fromJson', () {
      test('should create AchievementType from valid JSON', () {
        final json = JsonFixtures.achievementTypeJson();
        final achievement = AchievementType.fromJson(json);

        expect(achievement.id, 'test-achievement-type-id');
        expect(achievement.name, 'First Workout');
        expect(achievement.description, 'Complete your first workout');
        expect(achievement.category, 'workout');
        expect(achievement.icon, 'trophy');
        expect(achievement.tier, 'bronze');
        expect(achievement.points, 10);
        expect(achievement.isRepeatable, false);
      });

      test('should handle optional threshold fields', () {
        final json = {
          'id': 'streak-achievement',
          'name': '7-Day Streak',
          'description': 'Work out 7 days in a row',
          'category': 'streak',
          'icon': 'fire',
          'tier': 'silver',
          'points': 50,
          'threshold_value': 7.0,
          'threshold_unit': 'days',
          'is_repeatable': true,
        };
        final achievement = AchievementType.fromJson(json);

        expect(achievement.thresholdValue, 7.0);
        expect(achievement.thresholdUnit, 'days');
        expect(achievement.isRepeatable, true);
      });
    });

    group('toJson', () {
      test('should serialize AchievementType to JSON', () {
        const achievement = AchievementType(
          id: 'test-id',
          name: 'Test Achievement',
          description: 'Test description',
          category: 'test',
          icon: 'star',
          tier: 'gold',
          points: 100,
          thresholdValue: 10.0,
          thresholdUnit: 'reps',
          isRepeatable: true,
        );
        final json = achievement.toJson();

        expect(json['id'], 'test-id');
        expect(json['name'], 'Test Achievement');
        expect(json['description'], 'Test description');
        expect(json['category'], 'test');
        expect(json['icon'], 'star');
        expect(json['tier'], 'gold');
        expect(json['points'], 100);
        expect(json['threshold_value'], 10.0);
        expect(json['threshold_unit'], 'reps');
        expect(json['is_repeatable'], true);
      });
    });
  });

  group('UserAchievement', () {
    test('should create from JSON', () {
      final json = {
        'id': 'user-achievement-id',
        'user_id': 'user-123',
        'achievement_id': 'achievement-456',
        'earned_at': '2025-01-15T10:30:00Z',
        'trigger_value': 100.0,
        'trigger_details': {'workout_name': 'Morning Workout'},
        'is_notified': true,
        'achievement': JsonFixtures.achievementTypeJson(),
      };
      final userAchievement = UserAchievement.fromJson(json);

      expect(userAchievement.id, 'user-achievement-id');
      expect(userAchievement.userId, 'user-123');
      expect(userAchievement.achievementId, 'achievement-456');
      expect(userAchievement.earnedAt.year, 2025);
      expect(userAchievement.earnedAt.month, 1);
      expect(userAchievement.earnedAt.day, 15);
      expect(userAchievement.triggerValue, 100.0);
      expect(userAchievement.triggerDetails, {'workout_name': 'Morning Workout'});
      expect(userAchievement.isNotified, true);
      expect(userAchievement.achievement, isNotNull);
      expect(userAchievement.achievement!.name, 'First Workout');
    });

    test('should serialize to JSON', () {
      final userAchievement = UserAchievement(
        id: 'ua-id',
        userId: 'u-id',
        achievementId: 'a-id',
        earnedAt: DateTime(2025, 1, 15, 10, 30),
        triggerValue: 50.0,
        isNotified: false,
      );
      final json = userAchievement.toJson();

      expect(json['id'], 'ua-id');
      expect(json['user_id'], 'u-id');
      expect(json['achievement_id'], 'a-id');
      expect(json['trigger_value'], 50.0);
      expect(json['is_notified'], false);
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'ua-id',
        'user_id': 'u-id',
        'achievement_id': 'a-id',
        'earned_at': '2025-01-15T10:30:00Z',
        'is_notified': false,
      };
      final userAchievement = UserAchievement.fromJson(json);

      expect(userAchievement.triggerValue, isNull);
      expect(userAchievement.triggerDetails, isNull);
      expect(userAchievement.achievement, isNull);
    });
  });

  group('UserStreak', () {
    test('should create from JSON', () {
      final json = {
        'id': 'streak-id',
        'user_id': 'user-123',
        'streak_type': 'workout',
        'current_streak': 7,
        'longest_streak': 14,
        'last_activity_date': '2025-01-15',
        'streak_start_date': '2025-01-09',
      };
      final streak = UserStreak.fromJson(json);

      expect(streak.id, 'streak-id');
      expect(streak.userId, 'user-123');
      expect(streak.streakType, 'workout');
      expect(streak.currentStreak, 7);
      expect(streak.longestStreak, 14);
      expect(streak.lastActivityDate, '2025-01-15');
      expect(streak.streakStartDate, '2025-01-09');
    });

    test('should use default values for missing fields', () {
      final json = {
        'id': 'streak-id',
        'user_id': 'user-123',
        'streak_type': 'workout',
      };
      final streak = UserStreak.fromJson(json);

      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastActivityDate, isNull);
      expect(streak.streakStartDate, isNull);
    });

    test('should serialize to JSON', () {
      const streak = UserStreak(
        id: 's-id',
        userId: 'u-id',
        streakType: 'hydration',
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: '2025-01-15',
      );
      final json = streak.toJson();

      expect(json['id'], 's-id');
      expect(json['user_id'], 'u-id');
      expect(json['streak_type'], 'hydration');
      expect(json['current_streak'], 5);
      expect(json['longest_streak'], 10);
      expect(json['last_activity_date'], '2025-01-15');
    });
  });

  group('PersonalRecord', () {
    test('should create from JSON', () {
      final json = {
        'id': 'pr-id',
        'user_id': 'user-123',
        'exercise_name': 'Bench Press',
        'record_type': 'weight',
        'record_value': 100.0,
        'record_unit': 'kg',
        'previous_value': 95.0,
        'improvement_percentage': 5.26,
        'workout_id': 'workout-456',
        'achieved_at': '2025-01-15T10:30:00Z',
      };
      final pr = PersonalRecord.fromJson(json);

      expect(pr.id, 'pr-id');
      expect(pr.userId, 'user-123');
      expect(pr.exerciseName, 'Bench Press');
      expect(pr.recordType, 'weight');
      expect(pr.recordValue, 100.0);
      expect(pr.recordUnit, 'kg');
      expect(pr.previousValue, 95.0);
      expect(pr.improvementPercentage, 5.26);
      expect(pr.workoutId, 'workout-456');
      expect(pr.achievedAt.year, 2025);
    });

    test('should serialize to JSON', () {
      final pr = PersonalRecord(
        id: 'pr-id',
        userId: 'u-id',
        exerciseName: 'Squat',
        recordType: 'volume',
        recordValue: 5000.0,
        recordUnit: 'kg',
        achievedAt: DateTime(2025, 1, 15),
      );
      final json = pr.toJson();

      expect(json['id'], 'pr-id');
      expect(json['user_id'], 'u-id');
      expect(json['exercise_name'], 'Squat');
      expect(json['record_type'], 'volume');
      expect(json['record_value'], 5000.0);
      expect(json['record_unit'], 'kg');
    });
  });

  group('AchievementsSummary', () {
    test('should create from JSON', () {
      final json = {
        'total_points': 150,
        'total_achievements': 5,
        'recent_achievements': [],
        'current_streaks': [],
        'personal_records': [],
        'achievements_by_category': {
          'workout': 3,
          'streak': 2,
        },
      };
      final summary = AchievementsSummary.fromJson(json);

      expect(summary.totalPoints, 150);
      expect(summary.totalAchievements, 5);
      expect(summary.recentAchievements, isEmpty);
      expect(summary.currentStreaks, isEmpty);
      expect(summary.personalRecords, isEmpty);
      expect(summary.achievementsByCategory, {'workout': 3, 'streak': 2});
    });

    test('should use default values for missing fields', () {
      final json = <String, dynamic>{};
      final summary = AchievementsSummary.fromJson(json);

      expect(summary.totalPoints, 0);
      expect(summary.totalAchievements, 0);
      expect(summary.recentAchievements, isEmpty);
      expect(summary.currentStreaks, isEmpty);
      expect(summary.personalRecords, isEmpty);
      expect(summary.achievementsByCategory, isEmpty);
    });

    test('should parse nested achievements, streaks, and PRs', () {
      final json = {
        'total_points': 100,
        'total_achievements': 1,
        'recent_achievements': [
          {
            'id': 'ua-1',
            'user_id': 'u-1',
            'achievement_id': 'a-1',
            'earned_at': '2025-01-15T10:30:00Z',
            'is_notified': false,
          }
        ],
        'current_streaks': [
          {
            'id': 's-1',
            'user_id': 'u-1',
            'streak_type': 'workout',
            'current_streak': 3,
            'longest_streak': 7,
          }
        ],
        'personal_records': [
          {
            'id': 'pr-1',
            'user_id': 'u-1',
            'exercise_name': 'Deadlift',
            'record_type': 'weight',
            'record_value': 150.0,
            'record_unit': 'kg',
            'achieved_at': '2025-01-15T10:30:00Z',
          }
        ],
        'achievements_by_category': {'workout': 1},
      };
      final summary = AchievementsSummary.fromJson(json);

      expect(summary.recentAchievements.length, 1);
      expect(summary.recentAchievements[0].id, 'ua-1');
      expect(summary.currentStreaks.length, 1);
      expect(summary.currentStreaks[0].currentStreak, 3);
      expect(summary.personalRecords.length, 1);
      expect(summary.personalRecords[0].exerciseName, 'Deadlift');
    });

    test('should serialize to JSON', () {
      const summary = AchievementsSummary(
        totalPoints: 200,
        totalAchievements: 10,
        achievementsByCategory: {'workout': 5, 'nutrition': 5},
      );
      final json = summary.toJson();

      expect(json['total_points'], 200);
      expect(json['total_achievements'], 10);
      expect(json['achievements_by_category'], {'workout': 5, 'nutrition': 5});
    });
  });
}
