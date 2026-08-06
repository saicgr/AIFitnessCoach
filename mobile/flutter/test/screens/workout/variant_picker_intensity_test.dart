// Regression test for row 31 (fix_workout.json): tapping an INTENSITY chip
// must keep the user's PER WEEK (sessionsPerWeek) selection when a variant
// exists at that exact (weeks, sessions, intensity) combo — it must never
// silently pick a different sessions-per-week just because that combo
// happens to sort earlier in the variants list.
//
// Reproduces the real Pilates Foundations bug: default 4 weeks / 6x / Medium.
// Tapping "Hard" incorrectly landed on 4 weeks / 3x / Hard even though a
// 4 weeks / 6x / Hard variant exists, because the old resolution logic used
// `variants.firstWhere((v) => v.intensity == intensity && v.weeks == weeks)`
// — list order, not closeness to the current selection, decided the result.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/program_template.dart';
import 'package:fitwiz/screens/workout/widgets/variant_picker.dart';

void main() {
  // Mirrors production ordering: sorted by weeks, then sessionsPerWeek, then
  // intensity alphabetically (Easy, Hard, Medium) — the exact shape that
  // made `firstWhere` land on the wrong sessions-per-week before this fix.
  final variants = <ProgramVariantOption>[
    for (final sessions in [3, 6])
      for (final intensity in ['Easy', 'Hard', 'Medium'])
        ProgramVariantOption(
          variantId: 'v-4-$sessions-$intensity',
          weeks: 4,
          sessionsPerWeek: sessions,
          intensity: intensity,
          isDefault: sessions == 6 && intensity == 'Medium',
        ),
  ];

  Widget buildTestWidget({
    required String? selectedVariantId,
    required ValueChanged<ProgramVariantOption> onSelect,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: VariantSelectorRow(
          variants: variants,
          selectedVariantId: selectedVariantId,
          defaultVariantId: 'v-4-6-Medium',
          onSelect: onSelect,
          onResetToDefault: () {},
        ),
      ),
    );
  }

  testWidgets(
    'tapping INTENSITY "Hard" while at 6x keeps sessionsPerWeek == 6 '
    'when a (4wk, 6x, Hard) variant exists',
    (tester) async {
      ProgramVariantOption? selected;

      await tester.pumpWidget(
        buildTestWidget(
          selectedVariantId: 'v-4-6-Medium',
          onSelect: (v) => selected = v,
        ),
      );

      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(
        selected!.sessionsPerWeek,
        6,
        reason:
            'PER WEEK must stay 6 — a (4wk, 6x, Hard) variant exists and '
            'must be preferred over the 3x Hard variant that sorts earlier '
            'in the list.',
      );
      expect(selected!.weeks, 4);
      expect(selected!.intensity, 'Hard');
      expect(selected!.variantId, 'v-4-6-Hard');
    },
  );
}
