// Regression test for E2E row 187: the ACTIVITY month tile (a hero-variant
// ZealovaCard) rendered visibly narrower than its outlined sibling in the same
// Row, slicing its own background watermark numerals mid-glyph at the card's
// right edge (docs/qa/screenshots/2026-08-05/ui_stats_87_strip5_s.png).
//
// Root cause was in the shared primitive, not the card that showed it:
// ZealovaCard's hero variant wraps its decorated Container in a Stack to paint
// the accent left edge. Stack defaults to StackFit.loose, which hands
// non-positioned children LOOSE constraints — so the decorated Container
// shrink-wrapped to its content's intrinsic width even though Expanded had
// given ZealovaCard a TIGHT width. The Stack itself still filled the tight
// width, so the visible surface/border ended short of the card's real box.
//
// This affects EVERY hero-variant ZealovaCard whose child doesn't itself force
// full width (a Column(mainAxisSize: min) is exactly that shape), so the fix
// and this test both live at the primitive.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/design_system/zealova_card.dart';

/// A child with a small intrinsic width and `mainAxisSize: min` — the shape
/// that exposed the bug (MonthHighlightCard's content is exactly this).
const _narrowContent = Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [Text('AUG'), Text('0')],
);

Future<void> _pumpPair(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: Row(
              children: [
                Expanded(
                  child: ZealovaCard(
                    key: ValueKey('hero'),
                    variant: ZealovaCardVariant.hero,
                    child: _narrowContent,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ZealovaCard(
                    key: ValueKey('outlined'),
                    variant: ZealovaCardVariant.outlined,
                    child: _narrowContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The DECORATED surface inside a card — the thing whose width the user
/// actually sees (background + hairline border), as opposed to the card's
/// outer box which was always full width.
Rect _surfaceRect(WidgetTester tester, String cardKey) {
  final surface = find.descendant(
    of: find.byKey(ValueKey(cardKey)),
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration,
    ),
  );
  return tester.getRect(surface.first);
}

void main() {
  testWidgets(
    'hero ZealovaCard paints its surface at the full width it was given, '
    'not its content intrinsic width',
    (tester) async {
      await _pumpPair(tester);

      final heroBox = tester.getRect(find.byKey(const ValueKey('hero')));
      final heroSurface = _surfaceRect(tester, 'hero');

      expect(
        heroSurface.width,
        heroBox.width,
        reason: 'The hero card\'s visible surface (${heroSurface.width}pt) '
            'must fill the box it was allotted (${heroBox.width}pt). It used '
            'to shrink-wrap to its content, leaving the background sliced at '
            'the card edge.',
      );
    },
  );

  testWidgets(
    'hero and outlined ZealovaCards laid out identically render the same width',
    (tester) async {
      await _pumpPair(tester);

      final hero = _surfaceRect(tester, 'hero');
      final outlined = _surfaceRect(tester, 'outlined');

      expect(
        hero.width,
        outlined.width,
        reason: 'Two ZealovaCards wrapped in identical Expandeds must render '
            'the same width regardless of variant. '
            'hero=${hero.width} outlined=${outlined.width}',
      );
    },
  );
}
