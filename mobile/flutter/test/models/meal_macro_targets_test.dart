import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/meal_macro_targets.dart';

void main() {
  group('MealMacroTargets.fromJson', () {
    test('parses int fields', () {
      final m = MealMacroTargets.fromJson({
        'target_protein_g': 40,
        'target_carbs_g': 50,
        'target_fat_g': 15,
        'target_calories': 495,
      });
      expect(m.proteinG, 40);
      expect(m.carbsG, 50);
      expect(m.fatG, 15);
      expect(m.calories, 495);
    });

    test('tolerates doubles and numeric strings', () {
      final m = MealMacroTargets.fromJson({
        'target_protein_g': 40.6,
        'target_carbs_g': '50',
        'target_fat_g': '15.4',
        'target_calories': 500.0,
      });
      expect(m.proteinG, closeTo(40.6, 0.001));
      expect(m.carbsG, 50);
      expect(m.fatG, closeTo(15.4, 0.001));
      expect(m.calories, 500);
    });

    test('missing fields fall back to 0', () {
      final m = MealMacroTargets.fromJson(const {});
      expect(m.proteinG, 0);
      expect(m.carbsG, 0);
      expect(m.fatG, 0);
      expect(m.calories, 0);
    });

    test('toJson rounds grams to ints', () {
      const m = MealMacroTargets(
          proteinG: 40.6, carbsG: 50.2, fatG: 15.4, calories: 495);
      expect(m.toJson(), {
        'target_protein_g': 41,
        'target_carbs_g': 50,
        'target_fat_g': 15,
        'target_calories': 495,
      });
    });
  });

  group('MealMacroTargets.parseMap', () {
    test('null when value is null or not a map', () {
      expect(MealMacroTargets.parseMap(null), isNull);
      expect(MealMacroTargets.parseMap('nope'), isNull);
      expect(MealMacroTargets.parseMap(42), isNull);
    });

    test('parses a full per-meal map keyed by meal type', () {
      final map = MealMacroTargets.parseMap({
        'breakfast': {
          'target_protein_g': 30,
          'target_carbs_g': 40,
          'target_fat_g': 12,
          'target_calories': 388,
        },
        'lunch': {
          'target_protein_g': 45,
          'target_carbs_g': 55,
          'target_fat_g': 18,
          'target_calories': 562,
        },
        'dinner': {
          'target_protein_g': 50,
          'target_carbs_g': 60,
          'target_fat_g': 20,
          'target_calories': 620,
        },
      });
      expect(map, isNotNull);
      expect(map!.keys, containsAll(['breakfast', 'lunch', 'dinner']));
      expect(map['lunch']!.proteinG, 45);
      expect(map['dinner']!.calories, 620);
    });

    test('skips malformed entries but keeps valid ones', () {
      final map = MealMacroTargets.parseMap({
        'breakfast': {'target_protein_g': 30},
        'lunch': 'garbage',
      });
      expect(map, isNotNull);
      expect(map!.keys, ['breakfast']);
      expect(map['breakfast']!.proteinG, 30);
    });

    test('empty map → null', () {
      expect(MealMacroTargets.parseMap(const {}), isNull);
    });
  });
}
