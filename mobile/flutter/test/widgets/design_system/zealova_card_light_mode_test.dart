// Light-mode contrast regression test for the shared-widgets lane's repair of
// lib/widgets/design_system/** and lib/widgets/signature/**.
//
// ZealovaCard/ZealovaListRow/ZealovaRule used to paint `AppColors.cardBorder`
// / `AppColors.hairline` — DARK-THEME LITERALS — directly, regardless of the
// active Brightness. Because these primitives back ~40 settings routes plus
// every Signature-styled card in the app, that one bug painted a dark
// hairline/border onto every card, row, and rule in light mode: readable in
// isolation (the literals aren't black-on-black), but visibly wrong — a
// near-black border sits on a card whose surface is now correctly light,
// undermining the theme everywhere these primitives are used.
//
// This test pumps each primitive under an EXPLICIT light theme and asserts
// the RESOLVED colours actually seen on screen are the light-palette values,
// not the dark literals — not merely that the widgets build without error.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/widgets/design_system/zealova_card.dart';
import 'package:fitwiz/widgets/design_system/zealova_list_row.dart';
import 'package:fitwiz/widgets/design_system/zealova_rule.dart';

/// Pumps [child] under a MaterialApp whose resolved theme is unambiguously
/// LIGHT (`Theme.of(context).brightness == Brightness.light`), which is what
/// `ThemeColors.of(context)` keys its `isDark` branch off of.
Future<void> _pumpLight(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      themeMode: ThemeMode.light,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration _decorationOf(WidgetTester tester, Finder containerFinder) {
  final container = tester.widget<Container>(containerFinder);
  return container.decoration! as BoxDecoration;
}

void main() {
  group('ZealovaCard — light mode resolves light colours, not dark literals', () {
    testWidgets('outlined card surface + border resolve to the light palette', (tester) async {
      await _pumpLight(
        tester,
        const ZealovaCard(
          key: ValueKey('card'),
          child: Text('hello'),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byKey(const ValueKey('card')),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      final decoration = _decorationOf(tester, containerFinder.first);

      // The resolved surface must be the LIGHT surface colour, and must be
      // visibly light (not a dark card floating on a light screen).
      expect(decoration.color, AppColorsLight.surface);
      expect(decoration.color, isNot(AppColors.surface));
      expect(
        decoration.color!.computeLuminance(),
        greaterThan(0.5),
        reason: 'ZealovaCard surface must be light when the app theme is '
            'light — got a dark surface instead.',
      );

      // The border is the fix under test: it used to be the raw dark
      // `AppColors.cardBorder` regardless of theme.
      final borderColor = decoration.border!.top.color;
      expect(borderColor, AppColorsLight.cardBorder);
      expect(borderColor, isNot(AppColors.cardBorder));

      // Background and border must actually be distinguishable from each
      // other (a real hairline, not an invisible same-colour-on-itself line).
      expect(borderColor, isNot(decoration.color));
    });
  });

  group('ZealovaListRow — light mode hairline + border resolve to the light palette', () {
    testWidgets('bottom hairline divider resolves light, not AppColors.hairline', (tester) async {
      await _pumpLight(
        tester,
        const ZealovaListRow(
          key: ValueKey('row'),
          icon: Icons.settings,
          label: 'Setting',
        ),
      );

      final containerFinder = find.descendant(
        of: find.byKey(const ValueKey('row')),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
        ),
      );
      final decoration = _decorationOf(tester, containerFinder.first);
      final hairlineColor = decoration.border!.bottom.color;

      // Must not be the dark-theme hairline literal (near-black, ~0xFF1A1A1A)
      // — that would render as a near-black rule on an otherwise light row.
      expect(hairlineColor, isNot(AppColors.hairline));
      expect(
        hairlineColor.computeLuminance(),
        greaterThan(0.5),
        reason: 'The row hairline must be a light, subtle rule in light mode, '
            'not the dark-theme literal.',
      );
    });

    testWidgets('leading icon frame border resolves to the light cardBorder', (tester) async {
      await _pumpLight(
        tester,
        const ZealovaListRow(
          key: ValueKey('row2'),
          icon: Icons.settings,
          label: 'Setting',
        ),
      );

      final frameFinder = find.descendant(
        of: find.byKey(const ValueKey('row2')),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 30 && w.decoration is BoxDecoration,
        ),
      );
      final decoration = _decorationOf(tester, frameFinder.first);
      final borderColor = decoration.border!.top.color;

      expect(borderColor, AppColorsLight.cardBorder);
      expect(borderColor, isNot(AppColors.cardBorder));
    });
  });

  group('ZealovaRule — light mode resolves a light rule, not the dark hairline literal', () {
    testWidgets('rule colour is light and visibly distinct from dark AppColors.hairline', (tester) async {
      await _pumpLight(
        tester,
        const SizedBox(
          key: ValueKey('rule-host'),
          child: ZealovaRule(),
        ),
      );

      final container = tester.widget<Container>(find.descendant(
        of: find.byKey(const ValueKey('rule-host')),
        matching: find.byType(Container),
      ));

      expect(container.color, isNot(AppColors.hairline));
      expect(
        container.color!.computeLuminance(),
        greaterThan(0.5),
        reason: 'ZealovaRule must resolve a light rule colour in light mode.',
      );
    });
  });
}
