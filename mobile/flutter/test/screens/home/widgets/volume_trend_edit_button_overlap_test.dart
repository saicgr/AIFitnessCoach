/// Regression test for Home → metrics carousel → TRAINING VOLUME page
/// (E2E row 133, MED).
///
/// The "— —" no-comparison delta placeholder rendered directly under the
/// carousel shell's top-right edit (pencil) button — two independent
/// widgets sharing the same pixels. This renders the real
/// `CarouselCardShell` + `VolumeTrendCard` pair at the real card width and
/// asserts their bounding rects (delta text vs. edit button) do not
/// intersect.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/metrics_carousel_data_provider.dart';
import 'package:fitwiz/screens/home/widgets/metrics_carousel/metrics_carousel_cards.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
      'the "— —" delta placeholder does not overlap the edit button',
      (tester) async {
    await tester.pumpWidget(createTestWidget(
      CarouselCardShell(
        onEdit: () {},
        pageIndex: 0,
        pageCount: 3,
        child: const VolumeTrendCard(data: VolumeTrendSnapshot.empty),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('— —'), findsOneWidget,
        reason: 'sanity: the no-comparison placeholder must actually render');
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget,
        reason: 'sanity: the shell edit button must actually render');

    final deltaRect = tester.getRect(find.text('— —'));
    final editRect = tester.getRect(find.byIcon(Icons.edit_outlined));

    expect(deltaRect.overlaps(editRect), isFalse,
        reason: 'the delta placeholder ($deltaRect) must not overlap the '
            'edit button ($editRect) — E2E row 133: the dashes used to pass '
            'behind the pencil and out the other side');
  });
}
