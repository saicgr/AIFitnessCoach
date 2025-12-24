import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/data/models/user.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('User Model', () {
    group('fromJson', () {
      test('should create User from valid JSON', () {
        final json = JsonFixtures.userJson();
        final user = User.fromJson(json);

        expect(user.id, 'test-user-id');
        expect(user.username, 'testuser');
        expect(user.name, 'Test User');
        expect(user.email, 'test@example.com');
        expect(user.fitnessLevel, 'intermediate');
        expect(user.heightCm, 175.0);
        expect(user.weightKg, 70.0);
        expect(user.age, 30);
        expect(user.gender, 'male');
        expect(user.onboardingCompleted, true);
      });

      test('should handle null optional fields', () {
        final json = {'id': 'test-id'};
        final user = User.fromJson(json);

        expect(user.id, 'test-id');
        expect(user.username, isNull);
        expect(user.name, isNull);
        expect(user.email, isNull);
        expect(user.fitnessLevel, isNull);
      });
    });

    group('toJson', () {
      test('should serialize User to JSON', () {
        final user = TestFixtures.createUser();
        final json = user.toJson();

        expect(json['id'], 'test-user-id');
        expect(json['username'], 'testuser');
        expect(json['name'], 'Test User');
        expect(json['email'], 'test@example.com');
        expect(json['fitness_level'], 'intermediate');
      });
    });

    group('goalsList', () {
      test('should parse goals from JSON array string', () {
        final user = TestFixtures.createUser(
          goals: '["Build muscle", "Lose weight", "Improve cardio"]',
        );

        expect(user.goalsList, ['Build muscle', 'Lose weight', 'Improve cardio']);
      });

      test('should return empty list for null goals', () {
        final user = TestFixtures.createUser(goals: null);

        expect(user.goalsList, isEmpty);
      });

      test('should return empty list for empty string goals', () {
        final user = TestFixtures.createUser(goals: '');

        expect(user.goalsList, isEmpty);
      });

      test('should handle plain string goal as single item list', () {
        final user = TestFixtures.createUser(goals: 'Build muscle');

        expect(user.goalsList, ['Build muscle']);
      });

      test('should handle invalid JSON by treating as plain string', () {
        final user = TestFixtures.createUser(goals: 'invalid json {');

        expect(user.goalsList, ['invalid json {']);
      });
    });

    group('equipmentList', () {
      test('should parse equipment from JSON array string', () {
        final user = TestFixtures.createUser(
          equipment: '["Dumbbells", "Barbell", "Pull-up bar"]',
        );

        expect(user.equipmentList, ['Dumbbells', 'Barbell', 'Pull-up bar']);
      });

      test('should return empty list for null equipment', () {
        final user = TestFixtures.createUser(equipment: null);

        expect(user.equipmentList, isEmpty);
      });

      test('should return empty list for invalid JSON', () {
        final user = TestFixtures.createUser(equipment: 'invalid');

        expect(user.equipmentList, isEmpty);
      });
    });

    group('injuriesList', () {
      test('should parse active injuries from JSON array string', () {
        final user = TestFixtures.createUser(
          activeInjuries: '["Lower back", "Shoulder"]',
        );

        expect(user.injuriesList, ['Lower back', 'Shoulder']);
      });

      test('should return empty list for null injuries', () {
        final user = TestFixtures.createUser(activeInjuries: null);

        expect(user.injuriesList, isEmpty);
      });
    });

    group('displayName', () {
      test('should return name when available', () {
        final user = TestFixtures.createUser(name: 'John Doe', username: 'johnd');

        expect(user.displayName, 'John Doe');
      });

      test('should return username when name is null', () {
        final user = TestFixtures.createUser(name: null, username: 'johnd');

        expect(user.displayName, 'johnd');
      });

      test('should return "User" when both name and username are null', () {
        final user = User(id: 'test-id', name: null, username: null);

        expect(user.displayName, 'User');
      });
    });

    group('isOnboardingComplete', () {
      test('should return true when onboarding is completed', () {
        final user = TestFixtures.createUser(onboardingCompleted: true);

        expect(user.isOnboardingComplete, true);
      });

      test('should return false when onboarding is not completed', () {
        final user = TestFixtures.createUser(onboardingCompleted: false);

        expect(user.isOnboardingComplete, false);
      });

      test('should return false when onboarding is null', () {
        final user = User(id: 'test-id', onboardingCompleted: null);

        expect(user.isOnboardingComplete, false);
      });
    });

    group('fitnessGoal', () {
      test('should return first goal from goals list', () {
        final user = TestFixtures.createUser(
          goals: '["Build muscle", "Lose weight"]',
        );

        expect(user.fitnessGoal, 'Build muscle');
      });

      test('should return null when goals list is empty', () {
        final user = TestFixtures.createUser(goals: '[]');

        expect(user.fitnessGoal, isNull);
      });
    });

    group('workoutsPerWeek', () {
      test('should parse workouts_per_week from preferences', () {
        final user = TestFixtures.createUser(
          preferences: '{"workouts_per_week": 4}',
        );

        expect(user.workoutsPerWeek, 4);
      });

      test('should fall back to workout_days length', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_days": [0, 1, 2]}',
        );

        expect(user.workoutsPerWeek, 3);
      });

      test('should return null for null preferences', () {
        final user = TestFixtures.createUser(preferences: null);

        expect(user.workoutsPerWeek, isNull);
      });
    });

    group('workoutDays', () {
      test('should parse workout days from preferences', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_days": [0, 2, 4]}',
        );

        expect(user.workoutDays, [0, 2, 4]);
      });

      test('should return sorted list', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_days": [4, 0, 2]}',
        );

        expect(user.workoutDays, [0, 2, 4]);
      });

      test('should return empty list for null preferences', () {
        final user = TestFixtures.createUser(preferences: null);

        expect(user.workoutDays, isEmpty);
      });
    });

    group('workoutDayNames', () {
      test('should convert day numbers to abbreviated names', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_days": [0, 2, 4]}',
        );

        expect(user.workoutDayNames, ['Mon', 'Wed', 'Fri']);
      });

      test('should handle all days of the week', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_days": [0, 1, 2, 3, 4, 5, 6]}',
        );

        expect(user.workoutDayNames, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
      });
    });

    group('workoutDaysFormatted', () {
      test('should return comma-separated day names', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_days": [0, 2, 4]}',
        );

        expect(user.workoutDaysFormatted, 'Mon, Wed, Fri');
      });

      test('should return "Not set" when no workout days', () {
        final user = TestFixtures.createUser(preferences: '{}');

        expect(user.workoutDaysFormatted, 'Not set');
      });
    });

    group('trainingExperience', () {
      test('should parse training experience from preferences', () {
        final user = TestFixtures.createUser(
          preferences: '{"training_experience": "2_to_5_years"}',
        );

        expect(user.trainingExperience, '2_to_5_years');
      });

      test('should return null when not set', () {
        final user = TestFixtures.createUser(preferences: '{}');

        expect(user.trainingExperience, isNull);
      });
    });

    group('trainingExperienceDisplay', () {
      test('should convert training experience to display text', () {
        expect(
          TestFixtures.createUser(preferences: '{"training_experience": "never"}').trainingExperienceDisplay,
          'Never lifted',
        );
        expect(
          TestFixtures.createUser(preferences: '{"training_experience": "less_than_6_months"}').trainingExperienceDisplay,
          'Less than 6 months',
        );
        expect(
          TestFixtures.createUser(preferences: '{"training_experience": "6_months_to_2_years"}').trainingExperienceDisplay,
          '6 months - 2 years',
        );
        expect(
          TestFixtures.createUser(preferences: '{"training_experience": "2_to_5_years"}').trainingExperienceDisplay,
          '2-5 years',
        );
        expect(
          TestFixtures.createUser(preferences: '{"training_experience": "5_plus_years"}').trainingExperienceDisplay,
          '5+ years',
        );
      });

      test('should return "Not set" when no experience', () {
        final user = TestFixtures.createUser(preferences: '{}');

        expect(user.trainingExperienceDisplay, 'Not set');
      });
    });

    group('workoutEnvironment', () {
      test('should parse workout environment from preferences', () {
        final user = TestFixtures.createUser(
          preferences: '{"workout_environment": "commercial_gym"}',
        );

        expect(user.workoutEnvironment, 'commercial_gym');
      });
    });

    group('workoutEnvironmentDisplay', () {
      test('should convert workout environment to display text', () {
        expect(
          TestFixtures.createUser(preferences: '{"workout_environment": "commercial_gym"}').workoutEnvironmentDisplay,
          'Commercial Gym',
        );
        expect(
          TestFixtures.createUser(preferences: '{"workout_environment": "home_gym"}').workoutEnvironmentDisplay,
          'Home Gym',
        );
        expect(
          TestFixtures.createUser(preferences: '{"workout_environment": "home"}').workoutEnvironmentDisplay,
          'Home (Minimal)',
        );
        expect(
          TestFixtures.createUser(preferences: '{"workout_environment": "outdoors"}').workoutEnvironmentDisplay,
          'Outdoors',
        );
        expect(
          TestFixtures.createUser(preferences: '{"workout_environment": "hotel"}').workoutEnvironmentDisplay,
          'Hotel/Travel',
        );
      });
    });

    group('focusAreas', () {
      test('should parse focus areas from preferences', () {
        final user = TestFixtures.createUser(
          preferences: '{"focus_areas": ["chest", "back", "arms"]}',
        );

        expect(user.focusAreas, ['chest', 'back', 'arms']);
      });

      test('should return empty list when not set', () {
        final user = TestFixtures.createUser(preferences: '{}');

        expect(user.focusAreas, isEmpty);
      });
    });

    group('focusAreasDisplay', () {
      test('should convert focus areas to display text', () {
        final user = TestFixtures.createUser(
          preferences: '{"focus_areas": ["chest", "back", "arms"]}',
        );

        expect(user.focusAreasDisplay, 'Chest, Back, Arms');
      });

      test('should return "Full body" when no focus areas', () {
        final user = TestFixtures.createUser(preferences: '{}');

        expect(user.focusAreasDisplay, 'Full body');
      });
    });

    group('motivation', () {
      test('should parse motivation from preferences', () {
        final user = TestFixtures.createUser(
          preferences: '{"motivation": "seeing_progress"}',
        );

        expect(user.motivation, 'seeing_progress');
      });
    });

    group('motivationDisplay', () {
      test('should convert motivation to display text', () {
        expect(
          TestFixtures.createUser(preferences: '{"motivation": "seeing_progress"}').motivationDisplay,
          'Seeing progress',
        );
        expect(
          TestFixtures.createUser(preferences: '{"motivation": "feeling_stronger"}').motivationDisplay,
          'Feeling stronger',
        );
        expect(
          TestFixtures.createUser(preferences: '{"motivation": "looking_better"}').motivationDisplay,
          'Looking better',
        );
        expect(
          TestFixtures.createUser(preferences: '{"motivation": "health_improvements"}').motivationDisplay,
          'Health improvements',
        );
        expect(
          TestFixtures.createUser(preferences: '{"motivation": "stress_relief"}').motivationDisplay,
          'Stress relief',
        );
        expect(
          TestFixtures.createUser(preferences: '{"motivation": "social"}').motivationDisplay,
          'Social/accountability',
        );
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final user = TestFixtures.createUser();
        final updatedUser = user.copyWith(
          name: 'New Name',
          fitnessLevel: 'advanced',
        );

        expect(updatedUser.id, user.id);
        expect(updatedUser.name, 'New Name');
        expect(updatedUser.fitnessLevel, 'advanced');
        expect(updatedUser.email, user.email);
      });

      test('should preserve original values when not specified', () {
        final user = TestFixtures.createUser();
        final copy = user.copyWith();

        expect(copy.id, user.id);
        expect(copy.username, user.username);
        expect(copy.name, user.name);
        expect(copy.email, user.email);
      });
    });

    group('Equatable', () {
      test('should be equal when properties match', () {
        final user1 = TestFixtures.createUser();
        final user2 = TestFixtures.createUser();

        expect(user1, equals(user2));
      });

      test('should not be equal when properties differ', () {
        final user1 = TestFixtures.createUser(id: 'id-1');
        final user2 = TestFixtures.createUser(id: 'id-2');

        expect(user1, isNot(equals(user2)));
      });
    });
  });

  group('GoogleAuthRequest', () {
    test('should create from JSON', () {
      final json = {'access_token': 'test-token'};
      final request = GoogleAuthRequest.fromJson(json);

      expect(request.accessToken, 'test-token');
    });

    test('should convert to JSON', () {
      const request = GoogleAuthRequest(accessToken: 'test-token');
      final json = request.toJson();

      expect(json['access_token'], 'test-token');
    });
  });
}
