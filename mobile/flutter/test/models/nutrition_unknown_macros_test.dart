import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/nutrition.dart';

/// The client half of the "unknown macros" contract.
///
/// The backend macro-integrity chokepoint
/// (`backend/services/gemini/parsers.enforce_macro_integrity`) sets a food
/// item's protein/carbs/fat to an explicit NULL — and the whole MEAL's totals
/// to NULL — whenever any item has calories but no macro split. Every payload
/// below is the literal JSON that chokepoint emits.
///
/// The client used to destroy that: `nutrition.g.dart` decoded the macros with
/// `?? 0` / `?? 0.0`, so "we don't know" arrived in the UI as a confident
/// "0 g". These tests pin null == unknown, all the way through decode, scaling
/// and re-encode.
void main() {
  // Verbatim shape of an `enforce_macro_integrity` result for a two-item meal
  // where the sauce's macro split is unknown.
  Map<String, dynamic> unknownMacroMealJson() => {
        'success': true,
        'food_log_id': 'fl-123',
        'total_calories': 494,
        'protein_g': null,
        'carbs_g': null,
        'fat_g': null,
        'fiber_g': null,
        'macros_unknown': true,
        'macros_unknown_items': ['House curry sauce'],
        'macros_known_subtotal': {
          'protein_g': 53.4,
          'carbs_g': 0.0,
          'fat_g': 6.2,
          'fiber_g': 0.0,
        },
        'food_items': [
          {
            'name': 'Grilled chicken breast',
            'calories': 284,
            'protein_g': 53.4,
            'carbs_g': 0.0,
            'fat_g': 6.2,
            'weight_g': 174.0,
          },
          {
            'name': 'House curry sauce',
            'calories': 210,
            'protein_g': null,
            'carbs_g': null,
            'fat_g': null,
            'fiber_g': null,
            'macros_unknown': true,
            'requires_user_confirmation': true,
            'confidence': 'low',
            'weight_g': 120.0,
            // flag_unknown_macros STRIPS the macro factors, keeps calories.
            'ai_per_gram': {'calories': 1.75},
          },
        ],
      };

  group('LogFoodResponse — unknown meal macros', () {
    test('null macro totals decode as null, never 0.0', () {
      final r = LogFoodResponse.fromJson(unknownMacroMealJson());

      expect(r.proteinG, isNull);
      expect(r.carbsG, isNull);
      expect(r.fatG, isNull);
      // Calories are known and must survive.
      expect(r.totalCalories, 494);
    });

    test('carries the reason for the null', () {
      final r = LogFoodResponse.fromJson(unknownMacroMealJson());

      expect(r.hasUnknownMacros, isTrue);
      expect(r.macrosUnknown, isTrue);
      expect(r.macrosUnknownItems, ['House curry sauce']);
      expect(r.macrosKnownSubtotal!['protein_g'], 53.4);
    });

    test('per-item unknown macros stay null and stay flagged', () {
      final r = LogFoodResponse.fromJson(unknownMacroMealJson());

      final known = r.foodItems[0];
      expect(known.proteinG, 53.4);
      // A REAL zero (chicken has ~0 g carbs) must NOT become null.
      expect(known.carbsG, 0.0);
      expect(known.hasUnknownMacros, isFalse);

      final unknown = r.foodItems[1];
      expect(unknown.calories, 210);
      expect(unknown.proteinG, isNull);
      expect(unknown.carbsG, isNull);
      expect(unknown.fatG, isNull);
      expect(unknown.macrosUnknown, isTrue);
      expect(unknown.hasUnknownMacros, isTrue);
    });

    test('json round-trip keeps null null', () {
      final r = LogFoodResponse.fromJson(unknownMacroMealJson());
      final revived = LogFoodResponse.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
      );

      expect(revived.proteinG, isNull);
      expect(revived.carbsG, isNull);
      expect(revived.fatG, isNull);
      expect(revived.macrosUnknown, isTrue);
      expect(revived.foodItems[1].proteinG, isNull);
      expect(revived.foodItems[1].macrosUnknown, isTrue);
    });

    test('a fully-known meal is unaffected', () {
      final r = LogFoodResponse.fromJson({
        'success': true,
        'total_calories': 284,
        'protein_g': 53.4,
        'carbs_g': 0.0,
        'fat_g': 6.2,
        'food_items': const [],
      });

      expect(r.proteinG, 53.4);
      expect(r.carbsG, 0.0);
      expect(r.hasUnknownMacros, isFalse);
    });
  });

  group('LogFoodResponse.copyWithMultiplier', () {
    test('scaling an unknown macro keeps it unknown, never 0', () {
      final scaled =
          LogFoodResponse.fromJson(unknownMacroMealJson()).copyWithMultiplier(2.0);

      expect(scaled.proteinG, isNull);
      expect(scaled.carbsG, isNull);
      expect(scaled.fatG, isNull);
      expect(scaled.totalCalories, 988);
      expect(scaled.macrosUnknown, isTrue);
      // The partial subtotal scales with the portion.
      expect(scaled.macrosKnownSubtotal!['protein_g'], closeTo(106.8, 0.001));
      // The flag rides along on the item too.
      expect(scaled.foodItems[1].proteinG, isNull);
      expect(scaled.foodItems[1].macrosUnknown, isTrue);
      // The known item still scales normally.
      expect(scaled.foodItems[0].proteinG, closeTo(106.8, 0.001));
    });
  });

  group('AiPerGramData', () {
    test('stripped macro factors decode as null, not 0', () {
      final apg = AiPerGramData.fromJson(const {'calories': 1.75});

      expect(apg.calories, 1.75);
      expect(apg.protein, isNull);
      expect(apg.carbs, isNull);
      expect(apg.fat, isNull);
      expect(apg.hasUnknownMacros, isTrue);
    });

    test('getForWeight leaves an unknown macro unknown at any portion', () {
      final scaled = AiPerGramData.fromJson(const {'calories': 1.75})
          .getForWeight(240.0);

      expect(scaled['calories'], closeTo(420.0, 0.001));
      expect(scaled['protein_g'], isNull);
      expect(scaled['carbs_g'], isNull);
      expect(scaled['fat_g'], isNull);
    });

    test('real factors still scale', () {
      final scaled = AiPerGramData.fromJson(const {
        'calories': 1.632,
        'protein': 0.307,
        'carbs': 0.0,
        'fat': 0.036,
      }).getForWeight(100.0);

      expect(scaled['protein_g'], closeTo(30.7, 0.001));
      // A real 0 factor scales to a real 0, distinct from null.
      expect(scaled['carbs_g'], 0.0);
      expect(scaled['carbs_g'], isNotNull);
    });
  });

  group('FoodItemRanking.withWeight', () {
    test('rescaling an unknown-macro item yields null macros, not 0 g', () {
      final item = FoodItemRanking.fromJson({
        'name': 'House curry sauce',
        'calories': 210,
        'protein_g': null,
        'carbs_g': null,
        'fat_g': null,
        'macros_unknown': true,
        'weight_g': 120.0,
        'ai_per_gram': const {'calories': 1.75},
      });

      final scaled = item.withWeight(240.0);

      expect(scaled.calories, 420);
      expect(scaled.proteinG, isNull);
      expect(scaled.carbsG, isNull);
      expect(scaled.fatG, isNull);
      expect(scaled.macrosUnknown, isTrue);
      expect(scaled.hasUnknownMacros, isTrue);
    });

    test('rescaling a known item still produces real macros', () {
      final item = FoodItemRanking.fromJson({
        'name': 'Grilled chicken breast',
        'calories': 284,
        'protein_g': 53.4,
        'carbs_g': 0.0,
        'fat_g': 6.2,
        'weight_g': 174.0,
        'ai_per_gram': const {
          'calories': 1.632,
          'protein': 0.307,
          'carbs': 0.0,
          'fat': 0.036,
        },
      });

      final scaled = item.withWeight(100.0);

      expect(scaled.calories, 163);
      expect(scaled.proteinG, 30.7);
      expect(scaled.carbsG, 0.0);
      expect(scaled.hasUnknownMacros, isFalse);
      expect(scaled.macrosUnknown, isNull);
    });
  });

  group('FoodItem (persisted food_logs row)', () {
    test('a NULL macro column stays null', () {
      final item = FoodItem.fromJson(const {
        'name': 'House curry sauce',
        'calories': 210,
        'protein_g': null,
        'carbs_g': null,
        'fat_g': null,
        'macros_unknown': true,
      });

      expect(item.proteinG, isNull);
      expect(item.macrosUnknown, isTrue);
      expect(item.hasUnknownMacros, isTrue);
      expect(item.toJson()['macros_unknown'], isTrue);
      expect(item.toJson()['protein_g'], isNull);
    });
  });

  group('FoodLog (persisted meal row) — Track 2 nullability', () {
    // The exact shape the server persists for a meal whose total macro split is
    // unknown (enforce_macro_integrity stored SQL NULL). FoodLog used to decode
    // these with `?? 0`, resurrecting a confident "0 g" on read-back.
    Map<String, dynamic> unknownMealRowJson() => {
          'id': 'fl-777',
          'user_id': 'u-1',
          'meal_type': 'lunch',
          'logged_at': '2026-07-21T12:00:00Z',
          'total_calories': 494,
          'protein_g': null,
          'carbs_g': null,
          'fat_g': null,
          'fiber_g': null,
          'created_at': '2026-07-21T12:00:00Z',
          'food_items': const [],
        };

    test('a persisted unknown-macro meal decodes as null, never 0.0', () {
      final log = FoodLog.fromJson(unknownMealRowJson());

      expect(log.proteinG, isNull);
      expect(log.carbsG, isNull);
      expect(log.fatG, isNull);
      // Calories are known and must survive.
      expect(log.totalCalories, 494);
    });

    test('json round-trip keeps a null macro null', () {
      final log = FoodLog.fromJson(unknownMealRowJson());
      final revived = FoodLog.fromJson(
        jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>,
      );

      expect(revived.proteinG, isNull);
      expect(revived.carbsG, isNull);
      expect(revived.fatG, isNull);
    });

    test('a real 0 g macro is preserved, distinct from unknown', () {
      final log = FoodLog.fromJson({
        ...unknownMealRowJson(),
        'protein_g': 40.0,
        'carbs_g': 0.0, // genuinely zero carbs — NOT unknown
        'fat_g': 12.0,
      });

      expect(log.proteinG, 40.0);
      expect(log.carbsG, 0.0);
      expect(log.carbsG, isNotNull);
      expect(log.fatG, 12.0);
    });
  });

  group('macroGrams / macroGramsValue helpers', () {
    test('null renders an em dash, never 0', () {
      expect(macroGrams(null), '—');
      expect(macroGramsValue(null), '—');
    });

    test('a value rounds and (for macroGrams) carries the g unit', () {
      expect(macroGrams(53.4), '53g');
      expect(macroGramsValue(53.4), '53');
    });

    test('a real 0 g renders "0g", distinct from the null em dash', () {
      expect(macroGrams(0), '0g');
      expect(macroGramsValue(0), '0');
    });
  });
}
