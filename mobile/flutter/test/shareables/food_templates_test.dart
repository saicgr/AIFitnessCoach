import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/shareables/shareable_catalog.dart';
import 'package:fitwiz/shareables/shareable_data.dart';
import 'package:fitwiz/shareables/templates/food_photo_macros_template.dart';
import 'package:fitwiz/shareables/templates/food_polaroid_template.dart';
import 'package:fitwiz/shareables/templates/food_magazine_template.dart';
import 'package:fitwiz/shareables/templates/food_collage_template.dart';
import 'package:fitwiz/shareables/templates/macro_rings_card_template.dart';
import 'package:fitwiz/shareables/templates/macro_numbers_card_template.dart';
import 'package:fitwiz/shareables/templates/macro_pie_card_template.dart';
import 'package:fitwiz/shareables/templates/macro_plate_card_template.dart';
import 'package:fitwiz/shareables/templates/what_i_ate_card_template.dart';
import 'package:fitwiz/shareables/templates/macro_waffle_card_template.dart';
import 'package:fitwiz/shareables/templates/macro_bars_card_template.dart';
import 'package:fitwiz/shareables/templates/nutrition_facts_card_template.dart';
import 'package:fitwiz/shareables/templates/food_receipt_template.dart';
import 'package:fitwiz/shareables/templates/food_score_card_template.dart';

/// A fully-populated food/meal `Shareable` for render + catalog assertions.
Shareable _food(ShareableAspect aspect, {bool photo = true}) => Shareable(
      kind: ShareableKind.foodLog,
      title: 'Grilled Chicken Bowl',
      periodLabel: 'May 21',
      mealLabel: 'Lunch',
      accentColor: const Color(0xFF06B6D4),
      aspect: aspect,
      healthScore: 8,
      logText: 'grilled chicken, brown rice, broccoli, a drizzle of tahini',
      userDisplayName: 'chetan',
      nutrition: const ShareableNutrition(
        calories: 620,
        proteinG: 48,
        carbsG: 55,
        fatG: 22,
        fiberG: 9,
        calorieGoal: 2000,
        proteinGoal: 150,
        carbsGoal: 220,
        fatGoal: 65,
      ),
      foodItems: const [
        ShareableFood(
            name: 'Grilled chicken breast',
            amount: '180g',
            calories: 297,
            proteinG: 54),
        ShareableFood(
            name: 'Brown rice', amount: '1 cup', calories: 216, carbsG: 45),
        ShareableFood(name: 'Broccoli', amount: '100g', calories: 35),
        ShareableFood(name: 'Tahini', amount: '1 tbsp', calories: 89, fatG: 8),
      ],
      foodImageUrls:
          photo ? const ['/tmp/nonexistent_a.jpg', '/tmp/nonexistent_b.jpg'] : null,
    );

typedef _Build = Widget Function(Shareable data);

const Map<String, _Build> _templates = {
  'foodPhotoMacros': _photoMacros,
  'foodPolaroid': _polaroid,
  'foodMagazine': _magazine,
  'foodCollage': _collage,
  'macroRingsCard': _rings,
  'macroNumbersCard': _numbers,
  'macroPieCard': _pie,
  'macroPlateCard': _plate,
  'whatIAteCard': _whatIAte,
  'macroWaffleCard': _waffle,
  'macroBarsCard': _bars,
  'nutritionFactsCard': _facts,
  'foodReceipt': _receipt,
  'foodScoreCard': _score,
};

Widget _photoMacros(Shareable d) => FoodPhotoMacrosTemplate(data: d);
Widget _polaroid(Shareable d) => FoodPolaroidTemplate(data: d);
Widget _magazine(Shareable d) => FoodMagazineTemplate(data: d);
Widget _collage(Shareable d) => FoodCollageTemplate(data: d);
Widget _rings(Shareable d) => MacroRingsCardTemplate(data: d);
Widget _numbers(Shareable d) => MacroNumbersCardTemplate(data: d);
Widget _pie(Shareable d) => MacroPieCardTemplate(data: d);
Widget _plate(Shareable d) => MacroPlateCardTemplate(data: d);
Widget _whatIAte(Shareable d) => WhatIAteCardTemplate(data: d);
Widget _waffle(Shareable d) => MacroWaffleCardTemplate(data: d);
Widget _bars(Shareable d) => MacroBarsCardTemplate(data: d);
Widget _facts(Shareable d) => NutritionFactsCardTemplate(data: d);
Widget _receipt(Shareable d) => FoodReceiptTemplate(data: d);
Widget _score(Shareable d) => FoodScoreCardTemplate(data: d);

void main() {
  // Every food template must lay out at every aspect with no overflow /
  // exception (overflow throws during layout — `takeException` catches it).
  for (final aspect in ShareableAspect.values) {
    for (final entry in _templates.entries) {
      testWidgets('${entry.key} renders ${aspect.name} cleanly',
          (tester) async {
        tester.view.physicalSize = aspect.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              child: SizedBox.fromSize(
                size: aspect.size,
                child: entry.value(_food(aspect)),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: '${entry.key} @ ${aspect.name} threw');
      });
    }
  }

  test('foodLog default template is foodPhotoMacros', () {
    expect(
      ShareableCatalog.defaultTemplateForKind(ShareableKind.foodLog),
      ShareableTemplate.foodPhotoMacros,
    );
  });

  test('photo templates are gated by foodImageUrls', () {
    final withPhoto = ShareableCatalog.availableFor(_food(ShareableAspect.story))
        .map((s) => s.template)
        .toSet();
    final noPhoto = ShareableCatalog.availableFor(
            _food(ShareableAspect.story, photo: false))
        .map((s) => s.template)
        .toSet();

    // A photo log offers the photo templates; a no-photo log hides them.
    expect(withPhoto.contains(ShareableTemplate.foodPhotoMacros), isTrue);
    expect(withPhoto.contains(ShareableTemplate.foodCollage), isTrue);
    expect(noPhoto.contains(ShareableTemplate.foodPhotoMacros), isFalse);
    expect(noPhoto.contains(ShareableTemplate.foodCollage), isFalse);

    // Photo-less cards are always available, including for a no-photo log.
    expect(noPhoto.contains(ShareableTemplate.whatIAteCard), isTrue);
    expect(noPhoto.contains(ShareableTemplate.macroRingsCard), isTrue);
    expect(noPhoto.contains(ShareableTemplate.nutritionFactsCard), isTrue);

    // A foodLog share surfaces exactly the 14 food templates — no generic
    // workout-shaped templates leak in.
    expect(withPhoto.length, 14);
  });
}
