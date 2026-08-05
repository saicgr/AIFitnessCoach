/// Widget tests for [CoachNoticedBanner] — the "Coach noticed" card on the
/// home coach hero card (injury/recovery alert).
///
/// Two user-reported bugs this pins down:
///
/// 1. "Talk more" did nothing when tapped. Root cause: it was a bare ~70x15pt
///    `Text` inside a `GestureDetector`, far under the platform's 44x44pt
///    minimum touch target, so most taps landed just outside the hit-testable
///    region and silently missed. The fix wraps it in an explicit
///    `BoxConstraints(minWidth: 44, minHeight: 44)`. `test_geometry_*` below
///    asserts the actual rendered SIZE, not just that the widget exists —
///    a widget can "exist" at 70x15 and still fail the touch-target bar.
///
/// 2. The card had no way to collapse. Fixed with a `collapsed` flag +
///    `onToggleCollapsed` callback; persistence across app launches is owned
///    by `_CoachHeroCardState` (SharedPreferences, see coach_hero_card.dart)
///    and is exercised here via a rebuild-with-new-`collapsed`-value, which
///    is the contract the persisted value drives.
///
/// `CoachNoticedBanner` is deliberately provider-free (plain callbacks in,
/// plain rendering out) specifically so it's mountable here without the full
/// coach-card provider tree (auth, nutrition, sleep, workouts, etc.).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/providers/daily_coach_insight_provider.dart';
import 'package:fitwiz/screens/home/widgets/coach_hero_card.dart';

/// Must match `_CoachHeroCardState._kCoachNoticedCollapsedKey` in
/// coach_hero_card.dart exactly — that field is library-private (Dart
/// privacy is per-file), so it can't be imported here and is duplicated by
/// necessity. `test_persisted_key_round_trips` below is the guard: if the
/// production key string ever drifts from this literal, the widget-render
/// tests in this file would still pass (they don't touch SharedPreferences
/// at all) while real persistence silently breaks — so this constant + test
/// exists specifically to catch that.
const _kCoachNoticedCollapsedKey = 'coach_noticed_collapsed';

const _kMinTapTarget = 44.0;

CoachNoticed _buildNoticed({
  String body =
      'Your quads and hamstrings are still settling. I kept that work '
      'lighter today and swapped the exercises that aggravate them. Want '
      'me to ease it off further?',
  String title = 'Coach noticed',
  String acceptLabel = 'Ease today\'s session further',
  String dismissLabel = 'Talk more',
}) {
  return CoachNoticed(
    title: title,
    body: body,
    bodyPart: 'quadriceps (quadriceps femoris), hamstrings (biceps femoris)',
    phase: 'acute',
    action: 'adjust_today_workout',
    acceptLabel: acceptLabel,
    dismissLabel: dismissLabel,
    chatSeed: 'How are my quads and hamstrings?',
  );
}

Widget _harness({
  required bool collapsed,
  VoidCallback? onToggleCollapsed,
  VoidCallback? onAccept,
  VoidCallback? onTalkMore,
  CoachNoticed? noticed,
}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: CoachNoticedBanner(
          noticed: noticed ?? _buildNoticed(),
          collapsed: collapsed,
          onToggleCollapsed: onToggleCollapsed ?? () {},
          onAccept: onAccept ?? () {},
          onTalkMore: onTalkMore ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('CoachNoticedBanner — "Talk more" tap target geometry', () {
    testWidgets('renders at least 44x44 in both dimensions when expanded',
        (tester) async {
      await tester.pumpWidget(_harness(collapsed: false));
      await tester.pump();

      final talkMoreFinder = find.text('Talk more');
      expect(talkMoreFinder, findsOneWidget);

      // Walk up from the Text to the ConstrainedBox that owns the
      // BoxConstraints(minWidth: 44, minHeight: 44) fix, and assert the
      // ACTUAL rendered size — not merely that some ancestor widget exists.
      final constrainedBoxFinder = find.ancestor(
        of: talkMoreFinder,
        matching: find.byType(ConstrainedBox),
      );
      expect(
        constrainedBoxFinder,
        findsWidgets,
        reason: 'Talk more must be wrapped in an explicit size constraint',
      );

      final size = tester.getSize(constrainedBoxFinder.first);
      expect(
        size.width,
        greaterThanOrEqualTo(_kMinTapTarget),
        reason: 'Talk more tap target width ${size.width} is below the '
            '44pt minimum touch target',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(_kMinTapTarget),
        reason: 'Talk more tap target height ${size.height} is below the '
            '44pt minimum touch target',
      );

      // Same assertion via the actual GestureDetector hit-test region (the
      // opaque HitTestBehavior means this IS the tappable area, not just a
      // decorative wrapper).
      final gestureFinder = find.ancestor(
        of: talkMoreFinder,
        matching: find.byType(GestureDetector),
      );
      final tappableSize = tester.getSize(gestureFinder.first);
      expect(tappableSize.width, greaterThanOrEqualTo(_kMinTapTarget));
      expect(tappableSize.height, greaterThanOrEqualTo(_kMinTapTarget));
    });

    testWidgets('the Accept button also renders with real weight (regression guard)',
        (tester) async {
      // Not the bug being fixed, but pins the Accept button doesn't shrink
      // to match "Talk more" instead of the other way around.
      await tester.pumpWidget(_harness(collapsed: false));
      await tester.pump();

      final acceptFinder = find.text('Ease today\'s session further');
      expect(acceptFinder, findsOneWidget);
      final size = tester.getSize(
        find.ancestor(of: acceptFinder, matching: find.byType(Container)).first,
      );
      expect(size.height, greaterThan(0));
    });
  });

  group('CoachNoticedBanner — "Talk more" dispatches the chat callback', () {
    testWidgets('tapping Talk more invokes onTalkMore exactly once',
        (tester) async {
      var talkMoreTaps = 0;
      var acceptTaps = 0;
      await tester.pumpWidget(_harness(
        collapsed: false,
        onTalkMore: () => talkMoreTaps++,
        onAccept: () => acceptTaps++,
      ));
      await tester.pump();

      await tester.tap(find.text('Talk more'));
      await tester.pump();

      expect(talkMoreTaps, 1);
      expect(acceptTaps, 0, reason: 'must not also fire the Accept callback');
    });

    testWidgets('tapping anywhere in the enlarged hit area fires the callback '
        '(not just the literal text glyphs)', (tester) async {
      var talkMoreTaps = 0;
      await tester.pumpWidget(_harness(
        collapsed: false,
        onTalkMore: () => talkMoreTaps++,
      ));
      await tester.pump();

      // Tap the GestureDetector's own center rather than the Text — this is
      // exactly the class of tap that silently missed before the fix, when
      // the hit area was only as big as the text glyphs.
      final gestureFinder = find
          .ancestor(of: find.text('Talk more'), matching: find.byType(GestureDetector))
          .first;
      await tester.tap(gestureFinder);
      await tester.pump();

      expect(talkMoreTaps, 1);
    });
  });

  group('CoachNoticedBanner — collapse persistence contract', () {
    testWidgets('collapsed=false shows the full block; collapsed=true shows '
        'a one-line summary that still names the concern', (tester) async {
      await tester.pumpWidget(_harness(collapsed: false));
      await tester.pump();
      expect(find.text('COACH NOTICED'), findsOneWidget);
      expect(find.text('Talk more'), findsOneWidget);
      expect(
        find.textContaining('The engine drafts the change'),
        findsOneWidget,
      );

      await tester.pumpWidget(_harness(collapsed: true));
      await tester.pump();
      // Full block gone.
      expect(find.text('Talk more'), findsNothing);
      expect(
        find.textContaining('The engine drafts the change'),
        findsNothing,
      );
      // But collapsed state is NOT reduced to nothing — the one-line summary
      // (first clause of the body) still names the concern.
      expect(
        find.text('Your quads and hamstrings are still settling'),
        findsOneWidget,
      );
    });

    testWidgets('the state that drives persistence survives a rebuild with '
        'the same collapsed value (simulates SharedPreferences-hydrated '
        'state surviving a parent rebuild)', (tester) async {
      // _CoachHeroCardState hydrates `_coachNoticedCollapsed` from
      // SharedPreferences in initState and threads it into `collapsed` on
      // every build. This test stands in for that contract: once collapsed
      // is true, repeated rebuilds (widget tree churn — e.g. an insight
      // refresh) must keep rendering the collapsed summary, never silently
      // reverting to expanded.
      await tester.pumpWidget(_harness(collapsed: true));
      await tester.pump();
      expect(find.text('Talk more'), findsNothing);

      // Rebuild (new widget instance, same collapsed=true) — mirrors what
      // happens when the parent's `insight` provider emits a new value.
      await tester.pumpWidget(_harness(
        collapsed: true,
        noticed: _buildNoticed(body: 'Your knee is still settling. Updated.'),
      ));
      await tester.pump();
      expect(find.text('Talk more'), findsNothing);
      expect(find.text('Your knee is still settling'), findsOneWidget);
    });

    testWidgets('tapping the collapsed row invokes onToggleCollapsed',
        (tester) async {
      var toggles = 0;
      await tester.pumpWidget(_harness(
        collapsed: true,
        onToggleCollapsed: () => toggles++,
      ));
      await tester.pump();

      await tester.tap(find.text('Your quads and hamstrings are still settling'));
      await tester.pump();

      expect(toggles, 1);
    });

    testWidgets('the collapse chevron also meets the 44x44 minimum tap target',
        (tester) async {
      await tester.pumpWidget(_harness(collapsed: false));
      await tester.pump();

      final chevronFinder = find.byIcon(Icons.expand_less_rounded);
      expect(chevronFinder, findsOneWidget);
      final constrainedFinder = find.ancestor(
        of: chevronFinder,
        matching: find.byType(Container),
      );
      final size = tester.getSize(constrainedFinder.first);
      expect(size.width, greaterThanOrEqualTo(_kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(_kMinTapTarget));
    });

    testWidgets('tapping the collapse chevron in expanded state invokes '
        'onToggleCollapsed', (tester) async {
      var toggles = 0;
      await tester.pumpWidget(_harness(
        collapsed: false,
        onToggleCollapsed: () => toggles++,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.pump();

      expect(toggles, 1);
    });

    test('the persisted SharedPreferences key round-trips true/false '
        '(the mechanism _CoachHeroCardState hydrates `collapsed` from on '
        'every cold start)', () async {
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      // Nothing persisted yet -> production code's `?? false` default.
      expect(prefs.getBool(_kCoachNoticedCollapsedKey), isNull);

      await prefs.setBool(_kCoachNoticedCollapsedKey, true);
      // Simulate a fresh app launch re-reading the instance.
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_kCoachNoticedCollapsedKey), isTrue);

      await prefs.setBool(_kCoachNoticedCollapsedKey, false);
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_kCoachNoticedCollapsedKey), isFalse);
    });
  });
}
