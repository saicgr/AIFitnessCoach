/// [GlassDialog] is the `showDialog` counterpart to [GlassSheet]. Its whole
/// reason to exist is that dialogs and bottom sheets must look like ONE design
/// language — dialogs used to paint a flat opaque `ThemeColors.elevated` card
/// with their own radius and a hand-rolled `Colors.black54` scrim while every
/// sheet beside them was blurred glass.
///
/// So these tests assert the shared-token contract, not pixel values: whatever
/// `GlassSheetStyle` says, the dialog uses. If someone later hardcodes a blur,
/// radius, border or background in `glass_dialog.dart`, this fails.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/glass_dialog.dart';
import 'package:fitwiz/widgets/glass_sheet.dart';

/// The decorated glass surface — the single [Container] inside the dialog that
/// carries a [BoxDecoration] with a colour.
BoxDecoration _surfaceDecoration(WidgetTester tester) {
  final containers = tester.widgetList<Container>(
    find.descendant(
      of: find.byType(GlassDialog),
      matching: find.byType(Container),
    ),
  );
  final decorated = containers
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .where((d) => d.color != null)
      .toList();
  expect(decorated, hasLength(1),
      reason: 'GlassDialog should paint exactly one decorated surface');
  return decorated.single;
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required Brightness brightness,
  bool opaque = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showGlassDialog<void>(
                context: context,
                builder: (_) => GlassDialog(
                  opaque: opaque,
                  child: const Text('crate prompt'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('GlassDialog shares its surface tokens with GlassSheet', () {
    testWidgets('dark: background + border come from GlassSheetStyle',
        (tester) async {
      await _pumpDialog(tester, brightness: Brightness.dark);

      expect(find.text('crate prompt'), findsOneWidget);

      final d = _surfaceDecoration(tester);
      expect(d.color, GlassSheetStyle.backgroundColor(true));
      expect(
        (d.border as Border).top.color,
        GlassSheetStyle.borderColor(true),
      );
      expect(
        d.borderRadius,
        BorderRadius.circular(GlassSheetStyle.borderRadius),
        reason: 'a dialog rounds all four corners at the SHEET radius — not a '
            'locally-invented one',
      );
    });

    testWidgets('light: background + border come from GlassSheetStyle',
        (tester) async {
      await _pumpDialog(tester, brightness: Brightness.light);

      final d = _surfaceDecoration(tester);
      expect(d.color, GlassSheetStyle.backgroundColor(false));
      expect(
        (d.border as Border).top.color,
        GlassSheetStyle.borderColor(false),
      );
    });

    testWidgets('blurs what is behind it, at the sheet blur sigma',
        (tester) async {
      await _pumpDialog(tester, brightness: Brightness.dark);

      final filters = tester.widgetList<BackdropFilter>(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.byType(BackdropFilter),
        ),
      );
      expect(filters, hasLength(1),
          reason: 'the glass effect IS the BackdropFilter — without it this is '
              'just a translucent card');

      // ImageFilter has no public sigma getter; its toString carries them.
      expect(
        filters.single.filter.toString(),
        contains('${GlassSheetStyle.blurSigma}'),
        reason: 'blur must be the shared GlassSheetStyle.blurSigma',
      );
    });

    testWidgets('opaque: no blur, opaque surface — the mandatory-prompt mode',
        (tester) async {
      await _pumpDialog(tester, brightness: Brightness.dark, opaque: true);

      expect(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      final d = _surfaceDecoration(tester);
      expect(d.color, GlassSheetStyle.opaqueBackgroundColor(true));
      expect(d.color!.a, 1.0, reason: 'opaque means opaque');
    });

    testWidgets('the route paints the shared dialog scrim', (tester) async {
      await _pumpDialog(tester, brightness: Brightness.dark);

      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, GlassSheetStyle.dialogBarrierColor());
    });

    testWidgets('descendant Material widgets have a paint target',
        (tester) async {
      // Regression guard for the same defect GlassSheet documents: a decorated
      // container between the route's Material and the content occludes ink,
      // so buttons/ListTiles render without their background.
      await _pumpDialog(tester, brightness: Brightness.dark);

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(GlassDialog),
              matching: find.byType(Material),
            )
            .last,
      );
      expect(material.type, MaterialType.transparency);
    });
  });
}
