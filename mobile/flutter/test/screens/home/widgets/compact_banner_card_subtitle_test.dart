/// Regression test for Home → banner stack subtitle truncation (E2E rows
/// 118, 132 — MED).
///
/// Every banner in the stack (missed workout, hydration reminder, Instagram
/// follow, …) shares [CompactBannerCard]. Its subtitle was capped at
/// `maxLines: 1`, clipping real information mid-word — "2 days ago · 45min ·
/// 6 exerci…" (the exercise count itself, cut in half) — even though the
/// card had unused vertical room. This pins that the exact strings from the
/// findings now render in full at the card's real width.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/home/widgets/banner_card_data.dart';
import 'package:fitwiz/screens/home/widgets/compact_banner_card.dart';

Widget _wrap(BannerCardData data, {double width = 358}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: CompactBannerCard(data: data)),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'the missed-workout subtitle (E2E row 118) renders the full exercise '
      'count, not "6 exerci…"', (tester) async {
    const subtitle = '2 days ago · 45min · 6 exercises';
    await tester.pumpWidget(_wrap(const BannerCardData(
      type: BannerType.missedWorkout,
      id: 'missed_test',
      icon: Icons.schedule_rounded,
      title: 'Missed: Upper Body',
      subtitle: subtitle,
      accentColor: Colors.orange,
      actionLabel: 'Do Today',
    )));
    await tester.pump();

    expect(tester.takeException(), isNull,
        reason: 'must not overflow the fixed 84px card');
    expect(find.text(subtitle), findsOneWidget,
        reason: 'the full subtitle, including the exercise count, must be '
            'present in the widget tree (not just visually truncated)');

    final textWidget = tester.widget<Text>(find.text(subtitle));
    expect(textWidget.maxLines, greaterThanOrEqualTo(2),
        reason: 'a 1-line cap is what clipped "6 exerci…" mid-word — must '
            'allow at least 2 lines');
  });

  testWidgets(
      'the Instagram follow subtitle (E2E row 132) renders in full, not '
      '"and c…"', (tester) async {
    const subtitle =
        'Workout tips, meal ideas, and community highlights @zealova';
    await tester.pumpWidget(_wrap(const BannerCardData(
      type: BannerType.contextual,
      id: 'contextual_instagram_follow',
      icon: Icons.camera_alt_outlined,
      title: 'Follow us on Instagram',
      subtitle: subtitle,
      accentColor: Colors.pink,
      actionLabel: 'Follow',
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(subtitle), findsOneWidget);
  });
}
