import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/micronutrients.dart';

void main() {
  group('NutrientCategory', () {
    test('should have correct values', () {
      expect(NutrientCategory.vitamin.value, 'vitamin');
      expect(NutrientCategory.mineral.value, 'mineral');
      expect(NutrientCategory.fattyAcid.value, 'fatty_acid');
      expect(NutrientCategory.other.value, 'other');
    });

    test('fromValue should return correct enum', () {
      expect(NutrientCategory.fromValue('vitamin'), NutrientCategory.vitamin);
      expect(NutrientCategory.fromValue('mineral'), NutrientCategory.mineral);
      expect(NutrientCategory.fromValue('fatty_acid'), NutrientCategory.fattyAcid);
      expect(NutrientCategory.fromValue('other'), NutrientCategory.other);
    });

    test('fromValue should return other for unknown values', () {
      expect(NutrientCategory.fromValue('unknown'), NutrientCategory.other);
      expect(NutrientCategory.fromValue(''), NutrientCategory.other);
    });
  });

  group('NutrientStatus', () {
    test('should have correct values', () {
      expect(NutrientStatus.low.value, 'low');
      expect(NutrientStatus.optimal.value, 'optimal');
      expect(NutrientStatus.high.value, 'high');
      expect(NutrientStatus.overCeiling.value, 'over_ceiling');
    });

    test('fromValue should return correct enum', () {
      expect(NutrientStatus.fromValue('low'), NutrientStatus.low);
      expect(NutrientStatus.fromValue('optimal'), NutrientStatus.optimal);
      expect(NutrientStatus.fromValue('high'), NutrientStatus.high);
      expect(NutrientStatus.fromValue('over_ceiling'), NutrientStatus.overCeiling);
    });

    test('fromValue should return optimal for unknown values', () {
      expect(NutrientStatus.fromValue('unknown'), NutrientStatus.optimal);
      expect(NutrientStatus.fromValue(''), NutrientStatus.optimal);
    });
  });

  group('MicronutrientData', () {
    test('should create with default null values', () {
      const data = MicronutrientData();
      expect(data.vitaminAUg, isNull);
      expect(data.vitaminCMg, isNull);
      expect(data.calciumMg, isNull);
      expect(data.ironMg, isNull);
    });

    test('should create with specified values', () {
      const data = MicronutrientData(
        vitaminAUg: 500.0,
        vitaminCMg: 60.0,
        calciumMg: 800.0,
        ironMg: 12.0,
        omega3G: 1.5,
      );
      expect(data.vitaminAUg, 500.0);
      expect(data.vitaminCMg, 60.0);
      expect(data.calciumMg, 800.0);
      expect(data.ironMg, 12.0);
      expect(data.omega3G, 1.5);
    });

    test('operator + should add two MicronutrientData objects', () {
      const data1 = MicronutrientData(
        vitaminAUg: 300.0,
        vitaminCMg: 40.0,
        calciumMg: 500.0,
      );
      const data2 = MicronutrientData(
        vitaminAUg: 200.0,
        vitaminCMg: 20.0,
        ironMg: 8.0,
      );

      final result = data1 + data2;

      expect(result.vitaminAUg, 500.0);
      expect(result.vitaminCMg, 60.0);
      expect(result.calciumMg, 500.0); // Only in data1
      expect(result.ironMg, 8.0); // Only in data2
    });

    test('operator + should handle null values correctly', () {
      const data1 = MicronutrientData(vitaminAUg: 300.0);
      const data2 = MicronutrientData(vitaminCMg: 60.0);

      final result = data1 + data2;

      expect(result.vitaminAUg, 300.0);
      expect(result.vitaminCMg, 60.0);
      expect(result.calciumMg, isNull);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'vitamin_a_ug': 500.0,
        'vitamin_c_mg': 60.0,
        'calcium_mg': 800.0,
        'iron_mg': 12.0,
        'omega3_g': 1.5,
      };

      final data = MicronutrientData.fromJson(json);

      expect(data.vitaminAUg, 500.0);
      expect(data.vitaminCMg, 60.0);
      expect(data.calciumMg, 800.0);
      expect(data.ironMg, 12.0);
      expect(data.omega3G, 1.5);
    });

    test('toJson should serialize correctly', () {
      const data = MicronutrientData(
        vitaminAUg: 500.0,
        vitaminCMg: 60.0,
        calciumMg: 800.0,
      );

      final json = data.toJson();

      expect(json['vitamin_a_ug'], 500.0);
      expect(json['vitamin_c_mg'], 60.0);
      expect(json['calcium_mg'], 800.0);
    });
  });

  group('NutrientProgress', () {
    test('should create with required values', () {
      const progress = NutrientProgress(
        nutrientKey: 'vitamin_c_mg',
        displayName: 'Vitamin C',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 60.0,
        targetValue: 90.0,
        percentage: 66.7,
        status: 'low',
      );

      expect(progress.nutrientKey, 'vitamin_c_mg');
      expect(progress.displayName, 'Vitamin C');
      expect(progress.unit, 'mg');
      expect(progress.currentValue, 60.0);
      expect(progress.targetValue, 90.0);
      expect(progress.percentage, 66.7);
      expect(progress.status, 'low');
    });

    test('statusEnum should return correct NutrientStatus', () {
      const lowProgress = NutrientProgress(
        nutrientKey: 'test',
        displayName: 'Test',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 50.0,
        targetValue: 100.0,
        percentage: 50.0,
        status: 'low',
      );
      expect(lowProgress.statusEnum, NutrientStatus.low);

      const optimalProgress = NutrientProgress(
        nutrientKey: 'test',
        displayName: 'Test',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 100.0,
        targetValue: 100.0,
        percentage: 100.0,
        status: 'optimal',
      );
      expect(optimalProgress.statusEnum, NutrientStatus.optimal);
    });

    test('categoryEnum should return correct NutrientCategory', () {
      const vitaminProgress = NutrientProgress(
        nutrientKey: 'vitamin_c_mg',
        displayName: 'Vitamin C',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 60.0,
        targetValue: 90.0,
        percentage: 66.7,
        status: 'low',
      );
      expect(vitaminProgress.categoryEnum, NutrientCategory.vitamin);

      const mineralProgress = NutrientProgress(
        nutrientKey: 'calcium_mg',
        displayName: 'Calcium',
        unit: 'mg',
        category: 'mineral',
        currentValue: 800.0,
        targetValue: 1000.0,
        percentage: 80.0,
        status: 'low',
      );
      expect(mineralProgress.categoryEnum, NutrientCategory.mineral);
    });

    test('formattedCurrent should format value correctly', () {
      const wholeNumber = NutrientProgress(
        nutrientKey: 'test',
        displayName: 'Test',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 100.0,
        targetValue: 100.0,
        percentage: 100.0,
        status: 'optimal',
      );
      expect(wholeNumber.formattedCurrent, '100.0'); // toStringAsFixed(1) for values >= 1

      const decimal = NutrientProgress(
        nutrientKey: 'test',
        displayName: 'Test',
        unit: 'g',
        category: 'fatty_acid',
        currentValue: 1.5,
        targetValue: 2.0,
        percentage: 75.0,
        status: 'low',
      );
      expect(decimal.formattedCurrent, '1.5');

      const largeNumber = NutrientProgress(
        nutrientKey: 'test',
        displayName: 'Test',
        unit: 'mg',
        category: 'mineral',
        currentValue: 2500.0,
        targetValue: 3000.0,
        percentage: 83.3,
        status: 'low',
      );
      expect(largeNumber.formattedCurrent, '2.5k'); // Thousands formatted with k

      const smallNumber = NutrientProgress(
        nutrientKey: 'test',
        displayName: 'Test',
        unit: 'ug',
        category: 'vitamin',
        currentValue: 0.25,
        targetValue: 1.0,
        percentage: 25.0,
        status: 'low',
      );
      expect(smallNumber.formattedCurrent, '0.25'); // Small values with 2 decimal places
    });

    test('fromJson should parse correctly', () {
      final json = {
        'nutrient_key': 'vitamin_c_mg',
        'display_name': 'Vitamin C',
        'unit': 'mg',
        'category': 'vitamin',
        'current_value': 60.0,
        'target_value': 90.0,
        'floor_value': 45.0,
        'ceiling_value': 2000.0,
        'percentage': 66.7,
        'status': 'low',
        'color_hex': '#FF9F43',
      };

      final progress = NutrientProgress.fromJson(json);

      expect(progress.nutrientKey, 'vitamin_c_mg');
      expect(progress.displayName, 'Vitamin C');
      expect(progress.floorValue, 45.0);
      expect(progress.ceilingValue, 2000.0);
      expect(progress.colorHex, '#FF9F43');
    });
  });

  group('DailyMicronutrientSummary', () {
    test('should create with empty lists by default', () {
      const summary = DailyMicronutrientSummary(
        date: '2024-12-25',
        userId: 'user-123',
      );

      expect(summary.vitamins, isEmpty);
      expect(summary.minerals, isEmpty);
      expect(summary.fattyAcids, isEmpty);
      expect(summary.other, isEmpty);
      expect(summary.pinned, isEmpty);
    });

    test('allNutrients should combine all categories', () {
      const vitamin = NutrientProgress(
        nutrientKey: 'vitamin_c_mg',
        displayName: 'Vitamin C',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 60.0,
        targetValue: 90.0,
        percentage: 66.7,
        status: 'low',
      );
      const mineral = NutrientProgress(
        nutrientKey: 'calcium_mg',
        displayName: 'Calcium',
        unit: 'mg',
        category: 'mineral',
        currentValue: 800.0,
        targetValue: 1000.0,
        percentage: 80.0,
        status: 'low',
      );

      const summary = DailyMicronutrientSummary(
        date: '2024-12-25',
        userId: 'user-123',
        vitamins: [vitamin],
        minerals: [mineral],
      );

      expect(summary.allNutrients.length, 2);
      expect(summary.allNutrients, contains(vitamin));
      expect(summary.allNutrients, contains(mineral));
    });

    test('optimalNutrients should filter optimal status', () {
      const optimal = NutrientProgress(
        nutrientKey: 'vitamin_c_mg',
        displayName: 'Vitamin C',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 90.0,
        targetValue: 90.0,
        percentage: 100.0,
        status: 'optimal',
      );
      const low = NutrientProgress(
        nutrientKey: 'calcium_mg',
        displayName: 'Calcium',
        unit: 'mg',
        category: 'mineral',
        currentValue: 500.0,
        targetValue: 1000.0,
        percentage: 50.0,
        status: 'low',
      );

      const summary = DailyMicronutrientSummary(
        date: '2024-12-25',
        userId: 'user-123',
        vitamins: [optimal],
        minerals: [low],
      );

      expect(summary.optimalNutrients.length, 1);
      expect(summary.optimalNutrients.first, optimal);
    });

    test('overallScore should calculate correctly', () {
      const optimal1 = NutrientProgress(
        nutrientKey: 'vitamin_c_mg',
        displayName: 'Vitamin C',
        unit: 'mg',
        category: 'vitamin',
        currentValue: 90.0,
        targetValue: 90.0,
        percentage: 100.0,
        status: 'optimal',
      );
      const optimal2 = NutrientProgress(
        nutrientKey: 'vitamin_d_iu',
        displayName: 'Vitamin D',
        unit: 'IU',
        category: 'vitamin',
        currentValue: 600.0,
        targetValue: 600.0,
        percentage: 100.0,
        status: 'optimal',
      );
      const low = NutrientProgress(
        nutrientKey: 'calcium_mg',
        displayName: 'Calcium',
        unit: 'mg',
        category: 'mineral',
        currentValue: 500.0,
        targetValue: 1000.0,
        percentage: 50.0,
        status: 'low',
      );

      const summary = DailyMicronutrientSummary(
        date: '2024-12-25',
        userId: 'user-123',
        vitamins: [optimal1, optimal2],
        minerals: [low],
      );

      // 2 optimal out of 3 = 66.67%
      expect(summary.overallScore, closeTo(66.67, 0.1));
    });

    test('fromJson should parse correctly', () {
      final json = {
        'date': '2024-12-25',
        'user_id': 'user-123',
        'vitamins': [
          {
            'nutrient_key': 'vitamin_c_mg',
            'display_name': 'Vitamin C',
            'unit': 'mg',
            'category': 'vitamin',
            'current_value': 60.0,
            'target_value': 90.0,
            'percentage': 66.7,
            'status': 'low',
          }
        ],
        'minerals': [],
        'fatty_acids': [],
        'other': [],
        'pinned': [],
      };

      final summary = DailyMicronutrientSummary.fromJson(json);

      expect(summary.date, '2024-12-25');
      expect(summary.userId, 'user-123');
      expect(summary.vitamins.length, 1);
      expect(summary.vitamins.first.displayName, 'Vitamin C');
    });
  });

  group('NutrientRDA', () {
    test('should create with required values', () {
      const rda = NutrientRDA(
        nutrientName: 'Vitamin C',
        nutrientKey: 'vitamin_c_mg',
        unit: 'mg',
        category: 'vitamin',
        displayName: 'Vitamin C',
      );

      expect(rda.nutrientName, 'Vitamin C');
      expect(rda.nutrientKey, 'vitamin_c_mg');
      expect(rda.unit, 'mg');
      expect(rda.category, 'vitamin');
    });

    test('should support floor, target, and ceiling values', () {
      const rda = NutrientRDA(
        nutrientName: 'Vitamin C',
        nutrientKey: 'vitamin_c_mg',
        unit: 'mg',
        category: 'vitamin',
        displayName: 'Vitamin C',
        rdaFloor: 45.0,
        rdaTarget: 90.0,
        rdaCeiling: 2000.0,
      );

      expect(rda.rdaFloor, 45.0);
      expect(rda.rdaTarget, 90.0);
      expect(rda.rdaCeiling, 2000.0);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'nutrient_name': 'Vitamin C',
        'nutrient_key': 'vitamin_c_mg',
        'unit': 'mg',
        'category': 'vitamin',
        'display_name': 'Vitamin C',
        'rda_floor': 45.0,
        'rda_target': 90.0,
        'rda_ceiling': 2000.0,
        'rda_target_male': 90.0,
        'rda_target_female': 75.0,
        'display_order': 5,
        'color_hex': '#FF9F43',
      };

      final rda = NutrientRDA.fromJson(json);

      expect(rda.nutrientName, 'Vitamin C');
      expect(rda.rdaTargetMale, 90.0);
      expect(rda.rdaTargetFemale, 75.0);
      expect(rda.displayOrder, 5);
      expect(rda.colorHex, '#FF9F43');
    });
  });

  group('Constants', () {
    test('defaultPinnedNutrients should have expected nutrients', () {
      expect(defaultPinnedNutrients, contains('vitamin_d_iu'));
      expect(defaultPinnedNutrients, contains('calcium_mg'));
      expect(defaultPinnedNutrients, contains('iron_mg'));
      expect(defaultPinnedNutrients, contains('omega3_g'));
      expect(defaultPinnedNutrients.length, 4);
    });

    test('allNutrientKeys should contain all major nutrients', () {
      // Vitamins
      expect(allNutrientKeys, contains('vitamin_a_ug'));
      expect(allNutrientKeys, contains('vitamin_c_mg'));
      expect(allNutrientKeys, contains('vitamin_d_iu'));
      expect(allNutrientKeys, contains('vitamin_b12_ug'));

      // Minerals
      expect(allNutrientKeys, contains('calcium_mg'));
      expect(allNutrientKeys, contains('iron_mg'));
      expect(allNutrientKeys, contains('zinc_mg'));
      expect(allNutrientKeys, contains('potassium_mg'));

      // Fatty acids
      expect(allNutrientKeys, contains('omega3_g'));
      expect(allNutrientKeys, contains('omega6_g'));

      // Other
      expect(allNutrientKeys, contains('fiber_g'));
      expect(allNutrientKeys, contains('sugar_g'));
      expect(allNutrientKeys, contains('water_ml'));
    });
  });
}
