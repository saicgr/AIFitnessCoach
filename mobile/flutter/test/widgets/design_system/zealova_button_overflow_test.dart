// Gate: ZealovaButton must clamp its label, not overflow.
//
// 46 files construct this button, so a layout defect here is one of the
// widest-reach in the app. The label was a bare Text inside a Row — rigid, so
// any label wider than the button overflowed rather than ellipsizing. That is
// reachable three ordinary ways: a long label, a longer translation of a short
// one, or a large accessibility text scale.
//
// The overflow gate measured 764px on a realistic label.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/design_system/zealova_button.dart';

Widget _harness({
  required String label,
  required double width,
  double textScale = 1.0,
  IconData? trailingIcon,
  bool expand = true,
}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ZealovaButton(
              label: label,
              onTap: () {},
              trailingIcon: trailingIcon,
              expand: expand,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ZealovaButton — label clamps instead of overflowing', () {
    testWidgets('a long label in a narrow button does not overflow',
        (tester) async {
      await tester.pumpWidget(_harness(
        label: 'Generate a brand new workout for today',
        width: 200,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: '46 files build this button — a rigid label overflows for '
              'all of them');
    });

    testWidgets('a long label with a trailing icon does not overflow',
        (tester) async {
      await tester.pumpWidget(_harness(
        label: 'Ease today\'s session further and adjust',
        width: 220,
        trailingIcon: Icons.arrow_forward_rounded,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    for (final scale in const [1.3, 2.0]) {
      testWidgets('an ordinary label survives ${scale}x text scale',
          (tester) async {
        // The commonest real-world trigger: the label fits at 1.0 and the user
        // has larger text set system-wide.
        await tester.pumpWidget(_harness(
          label: 'Start workout',
          width: 200,
          textScale: scale,
        ));
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'a button that only fits at the default text scale is '
                'broken for anyone using accessibility sizing');
      });
    }

    testWidgets('the label ellipsizes rather than being silently cut',
        (tester) async {
      await tester.pumpWidget(_harness(
        label: 'A considerably longer call to action than fits',
        width: 180,
      ));
      await tester.pump();
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.overflow, TextOverflow.ellipsis,
          reason: 'clipping mid-glyph reads as a rendering bug; an ellipsis '
              'reads as intentional truncation');
      expect(text.maxLines, 1);
    });

    testWidgets('a short label still renders in full — no over-clamping',
        (tester) async {
      // Guard against "fixing" the overflow by truncating everything.
      await tester.pumpWidget(_harness(label: 'Save', width: 300));
      await tester.pump();
      expect(find.text('SAVE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expand:false (intrinsic width) is unaffected', (tester) async {
      await tester.pumpWidget(_harness(
        label: 'Log set',
        width: 300,
        expand: false,
      ));
      await tester.pump();
      expect(find.text('LOG SET'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
