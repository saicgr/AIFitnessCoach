/// # Golden-test harness for editable share-card templates
///
/// Every [ShareableTemplateSpec] in [ShareableCatalog.all()] that carries a
/// `docBuilder` (i.e. has been migrated to the editable-card engine) is
/// rendered here through the production render path — [CardDocRenderer] — and
/// compared against a committed reference PNG under `goldens/`.
///
/// This locks the visual output of each preset: a future edit to a template
/// builder, the renderer, or any element type produces a diff that fails the
/// matching test, so unintended layout regressions are caught before release.
///
/// ## Generating / updating the goldens
///
/// The reference images are NOT committed by hand. Generate (first run) or
/// refresh them (after an intentional template change) with:
///
/// ```sh
/// flutter test --update-goldens test/shareables/card_doc_golden_test.dart
/// ```
///
/// That writes one `goldens/<template>.png` per editable template. Review the
/// image diffs, then commit the updated PNGs alongside the code change.
///
/// A plain `flutter test test/shareables/card_doc_golden_test.dart` (no flag)
/// compares against the committed PNGs and fails on any pixel difference.
///
/// Notes:
///  - Each template renders in its own `testWidgets`, so a failing template
///    reports independently and never aborts the rest of the suite.
///  - Network / S3 photo URLs in the sample payloads resolve to a placeholder
///    inside `FoodImage` during tests (no real fetch happens), keeping the
///    goldens deterministic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/shareables/doc/card_doc.dart';
import 'package:fitwiz/shareables/doc/card_doc_renderer.dart';
import 'package:fitwiz/shareables/shareable_catalog.dart';
import 'package:fitwiz/shareables/shareable_data.dart';

/// Aspect every golden is rendered at. Portrait (1080×1350) is the share
/// gallery's default preview ratio.
const ShareableAspect _kAspect = ShareableAspect.portrait;

/// A fully-populated food/meal [Shareable] — used for every template whose
/// `kinds` set lists [ShareableKind.foodLog]. Carries calories + macros +
/// daily goals, an itemized food list, a health score and an accent color so
/// macro charts, repeaters, badges and chip groups all have real data to bind.
Shareable _foodSample() => Shareable(
      kind: ShareableKind.foodLog,
      title: 'Grilled Chicken Bowl',
      periodLabel: 'May 21',
      mealLabel: 'Lunch',
      accentColor: const Color(0xFF06B6D4),
      aspect: _kAspect,
      healthScore: 8,
      logText:
          'grilled chicken, brown rice, broccoli, a drizzle of tahini sauce',
      userDisplayName: 'chetan',
      heroValue: 620,
      heroUnitSingular: 'kcal',
      caption: 'Hitting protein early today.',
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
          proteinG: 54,
          carbsG: 0,
          fatG: 6,
        ),
        ShareableFood(
          name: 'Brown rice',
          amount: '1 cup',
          calories: 216,
          proteinG: 5,
          carbsG: 45,
          fatG: 2,
        ),
        ShareableFood(
          name: 'Broccoli',
          amount: '100g',
          calories: 35,
          proteinG: 3,
          carbsG: 7,
          fatG: 0,
        ),
        ShareableFood(
          name: 'Tahini',
          amount: '1 tbsp',
          calories: 89,
          proteinG: 3,
          carbsG: 3,
          fatG: 8,
        ),
      ],
      foodImageUrls: const [
        '/tmp/golden_food_a.jpg',
        '/tmp/golden_food_b.jpg',
      ],
      deepLinkUrl: 'https://zealova.com/s/golden',
    );

/// A fully-populated workout / stats [Shareable] — used for every non-food
/// template. Carries a hero value, populated highlights and sub-metrics so
/// grid / chart / editorial templates have enough real data to lay out.
Shareable _statsSample() => Shareable(
      kind: ShareableKind.statsOverview,
      title: 'Push Day Crushed',
      periodLabel: 'This Week',
      accentColor: const Color(0xFFF97316),
      aspect: _kAspect,
      heroValue: 12,
      heroUnitSingular: 'workout',
      heroPrefix: '',
      heroSuffix: '',
      userDisplayName: 'chetan',
      caption: 'Best week of the month.',
      logText: 'Felt strong on bench, hit a clean triple at 185.',
      healthScore: 9,
      highlights: const [
        ShareableMetric(label: 'TOTAL TIME', value: '4h 32m'),
        ShareableMetric(label: 'VOLUME', value: '48,200 lb'),
        ShareableMetric(label: 'WORKOUTS', value: '12'),
        ShareableMetric(label: 'STREAK', value: '21 days'),
        ShareableMetric(label: 'CALORIES', value: '3,140'),
        ShareableMetric(label: 'PRs', value: '3'),
      ],
      subMetrics: const [
        ShareableMetric(label: 'Mon', value: '52'),
        ShareableMetric(label: 'Tue', value: '0'),
        ShareableMetric(label: 'Wed', value: '61'),
        ShareableMetric(label: 'Thu', value: '44'),
        ShareableMetric(label: 'Fri', value: '70'),
        ShareableMetric(label: 'Sat', value: '38'),
        ShareableMetric(label: 'Sun', value: '0'),
      ],
      exercises: const [
        ShareableExercise(
          name: 'Bench Press',
          sets: [
            ShareableSet(weight: 185, unit: 'lbs', reps: 5, rpe: 8),
            ShareableSet(weight: 185, unit: 'lbs', reps: 5, rpe: 8.5),
            ShareableSet(weight: 185, unit: 'lbs', reps: 3, rpe: 9),
          ],
        ),
        ShareableExercise(
          name: 'Overhead Press',
          sets: [
            ShareableSet(weight: 115, unit: 'lbs', reps: 8, rpe: 7),
            ShareableSet(weight: 115, unit: 'lbs', reps: 7, rpe: 8),
          ],
        ),
        ShareableExercise(
          name: 'Pull Up',
          sets: [
            ShareableSet(unit: 'lbs', reps: 12, isBodyweight: true),
            ShareableSet(unit: 'lbs', reps: 10, isBodyweight: true),
          ],
        ),
      ],
      musclesWorked: const {'chest': 9, 'shoulders': 6, 'triceps': 5},
      secondaryMusclesWorked: const {'core': 3, 'lats': 2},
      planDays: [
        SharablePlanDay(
          date: DateTime(2026, 5, 18),
          workoutName: 'Push',
          workoutType: 'strength',
          durationMinutes: 52,
          isCompleted: true,
        ),
        SharablePlanDay(
          date: DateTime(2026, 5, 19),
          workoutName: null,
        ),
        SharablePlanDay(
          date: DateTime(2026, 5, 20),
          workoutName: 'Pull',
          workoutType: 'strength',
          durationMinutes: 61,
          isCompleted: true,
        ),
      ],
      deepLinkUrl: 'https://zealova.com/s/golden',
    );

/// Picks the sample payload that matches a template's declared [kinds]: a
/// foodLog template gets the food sample, everything else the stats sample.
Shareable _sampleFor(ShareableTemplateSpec spec) =>
    spec.kinds.contains(ShareableKind.foodLog)
        ? _foodSample()
        : _statsSample();

/// Wraps a [CardDocRenderer] at its fixed design size in the minimal tree the
/// golden capture needs: a `MaterialApp` for theme/directionality, a sized
/// `MediaQuery` so layout is deterministic, and a `RepaintBoundary` so the
/// matcher has a single layer to snapshot.
Widget _harness(CardDoc doc, Shareable data) {
  final size = doc.aspect.size;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MediaQuery(
      data: MediaQueryData(size: size, devicePixelRatio: 1.0),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.fromSize(
            size: size,
            child: RepaintBoundary(
              child: CardDocRenderer(
                doc: doc,
                data: data,
                showWatermark: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Only templates migrated to the editable-card engine (docBuilder != null)
  // are golden-tested — legacy widget-only templates render via a different
  // path and are covered by `food_templates_test.dart` / others.
  final editable = ShareableCatalog.all()
      .where((spec) => spec.docBuilder != null)
      .toList();

  group('CardDoc template goldens', () {
    test('catalog exposes editable templates to golden-test', () {
      // Guards against a future refactor that drops all docBuilders (which
      // would silently make this whole file a no-op).
      expect(editable, isNotEmpty,
          reason: 'No templates carry a docBuilder — nothing to golden-test.');
    });

    for (final spec in editable) {
      // `template.name` is the stable enum identifier — unique per spec and a
      // safe file name. (`spec.name` is the user-facing label and collides:
      // several templates share "Receipt", "Card", etc.)
      final key = spec.template.name;

      testWidgets('${spec.template.name} (${spec.name}) renders to golden',
          (tester) async {
        final data = _sampleFor(spec);
        final size = _kAspect.size;

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Build the preset document via the catalog's own builder — exactly
        // what the share sheet / editor / capture path does.
        final doc = spec.docBuilder!(data, _kAspect);

        await tester.pumpWidget(_harness(doc, data));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(CardDocRenderer),
          matchesGoldenFile('goldens/$key.png'),
        );
      });
    }
  });
}
