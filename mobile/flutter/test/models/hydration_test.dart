import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/hydration.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('HydrationLog', () {
    group('fromJson', () {
      test('should create HydrationLog from valid JSON', () {
        final json = JsonFixtures.hydrationLogJson();
        final log = HydrationLog.fromJson(json);

        expect(log.id, 'test-hydration-id');
        expect(log.userId, 'test-user-id');
        expect(log.drinkType, 'water');
        expect(log.amountMl, 250);
        expect(log.loggedAt, isNotNull);
      });

      test('should handle optional fields', () {
        final json = {
          'id': 'h-id',
          'user_id': 'u-id',
          'drink_type': 'coffee',
          'amount_ml': 200,
          'workout_id': 'w-id',
          'notes': 'Post-workout hydration',
        };
        final log = HydrationLog.fromJson(json);

        expect(log.workoutId, 'w-id');
        expect(log.notes, 'Post-workout hydration');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'h-id',
          'user_id': 'u-id',
          'drink_type': 'water',
          'amount_ml': 500,
        };
        final log = HydrationLog.fromJson(json);

        expect(log.workoutId, isNull);
        expect(log.notes, isNull);
        expect(log.loggedAt, isNull);
      });
    });

    group('toJson', () {
      test('should serialize HydrationLog to JSON', () {
        final log = TestFixtures.createHydrationLog(
          id: 'test-id',
          userId: 'user-id',
          drinkType: 'protein_shake',
          amountMl: 300,
        );
        final json = log.toJson();

        expect(json['id'], 'test-id');
        expect(json['user_id'], 'user-id');
        expect(json['drink_type'], 'protein_shake');
        expect(json['amount_ml'], 300);
      });
    });
  });

  group('DailyHydrationSummary', () {
    group('fromJson', () {
      test('should create DailyHydrationSummary from valid JSON', () {
        final json = JsonFixtures.dailyHydrationSummaryJson();
        final summary = DailyHydrationSummary.fromJson(json);

        expect(summary.date, isNotNull);
        expect(summary.totalMl, 2000);
        expect(summary.waterMl, 1500);
        expect(summary.proteinShakeMl, 300);
        expect(summary.sportsDrinkMl, 200);
        expect(summary.otherMl, 0);
        expect(summary.goalMl, 2500);
        expect(summary.goalPercentage, 0.8);
        expect(summary.entries, isEmpty);
      });

      test('should use default values for missing fields', () {
        final json = {'date': '2025-01-15'};
        final summary = DailyHydrationSummary.fromJson(json);

        expect(summary.date, '2025-01-15');
        expect(summary.totalMl, 0);
        expect(summary.waterMl, 0);
        expect(summary.proteinShakeMl, 0);
        expect(summary.sportsDrinkMl, 0);
        expect(summary.otherMl, 0);
        expect(summary.goalMl, 2500);
        expect(summary.goalPercentage, 0);
        expect(summary.entries, isEmpty);
      });

      test('should parse nested entries', () {
        final json = {
          'date': '2025-01-15',
          'total_ml': 500,
          'water_ml': 500,
          'protein_shake_ml': 0,
          'sports_drink_ml': 0,
          'other_ml': 0,
          'goal_ml': 2500,
          'goal_percentage': 0.2,
          'entries': [
            {
              'id': 'e-1',
              'user_id': 'u-1',
              'drink_type': 'water',
              'amount_ml': 250,
            },
            {
              'id': 'e-2',
              'user_id': 'u-1',
              'drink_type': 'water',
              'amount_ml': 250,
            },
          ],
        };
        final summary = DailyHydrationSummary.fromJson(json);

        expect(summary.entries.length, 2);
        expect(summary.entries[0].id, 'e-1');
        expect(summary.entries[1].id, 'e-2');
      });
    });

    group('toJson', () {
      test('should serialize DailyHydrationSummary to JSON', () {
        const summary = DailyHydrationSummary(
          date: '2025-01-15',
          totalMl: 2000,
          waterMl: 1800,
          proteinShakeMl: 200,
          goalMl: 3000,
          goalPercentage: 0.67,
        );
        final json = summary.toJson();

        expect(json['date'], '2025-01-15');
        expect(json['total_ml'], 2000);
        expect(json['water_ml'], 1800);
        expect(json['protein_shake_ml'], 200);
        expect(json['goal_ml'], 3000);
        expect(json['goal_percentage'], 0.67);
      });
    });
  });

  group('DrinkType', () {
    test('should have all expected values', () {
      expect(DrinkType.values.length, 5);
      expect(DrinkType.values, contains(DrinkType.water));
      expect(DrinkType.values, contains(DrinkType.proteinShake));
      expect(DrinkType.values, contains(DrinkType.sportsDrink));
      expect(DrinkType.values, contains(DrinkType.coffee));
      expect(DrinkType.values, contains(DrinkType.other));
    });

    test('should have correct values, labels, and emojis', () {
      expect(DrinkType.water.value, 'water');
      expect(DrinkType.water.label, 'Water');
      expect(DrinkType.water.emoji, isNotEmpty);

      expect(DrinkType.proteinShake.value, 'protein_shake');
      expect(DrinkType.proteinShake.label, 'Protein Shake');

      expect(DrinkType.sportsDrink.value, 'sports_drink');
      expect(DrinkType.sportsDrink.label, 'Sports Drink');

      expect(DrinkType.coffee.value, 'coffee');
      expect(DrinkType.coffee.label, 'Coffee');

      expect(DrinkType.other.value, 'other');
      expect(DrinkType.other.label, 'Other');
    });

    group('fromValue', () {
      test('should return correct DrinkType for valid values', () {
        expect(DrinkType.fromValue('water'), DrinkType.water);
        expect(DrinkType.fromValue('protein_shake'), DrinkType.proteinShake);
        expect(DrinkType.fromValue('sports_drink'), DrinkType.sportsDrink);
        expect(DrinkType.fromValue('coffee'), DrinkType.coffee);
        expect(DrinkType.fromValue('other'), DrinkType.other);
      });

      test('should return other for unknown values', () {
        expect(DrinkType.fromValue('unknown'), DrinkType.other);
        expect(DrinkType.fromValue('juice'), DrinkType.other);
        expect(DrinkType.fromValue(''), DrinkType.other);
      });
    });
  });

  group('QuickAmount', () {
    test('should have default amounts', () {
      expect(QuickAmount.defaults.length, 4);

      final glass = QuickAmount.defaults[0];
      expect(glass.ml, 250);
      expect(glass.label, '250ml');
      expect(glass.description, 'Glass');

      final bottle = QuickAmount.defaults[1];
      expect(bottle.ml, 500);
      expect(bottle.label, '500ml');
      expect(bottle.description, 'Bottle');

      final large = QuickAmount.defaults[2];
      expect(large.ml, 750);
      expect(large.label, '750ml');
      expect(large.description, 'Large');

      final liter = QuickAmount.defaults[3];
      expect(liter.ml, 1000);
      expect(liter.label, '1L');
      expect(liter.description, 'Liter');
    });

    test('should create custom QuickAmount', () {
      const custom = QuickAmount(350, '350ml', 'Medium');

      expect(custom.ml, 350);
      expect(custom.label, '350ml');
      expect(custom.description, 'Medium');
    });

    test('should handle null description', () {
      const custom = QuickAmount(200, '200ml');

      expect(custom.ml, 200);
      expect(custom.label, '200ml');
      expect(custom.description, isNull);
    });
  });
}
