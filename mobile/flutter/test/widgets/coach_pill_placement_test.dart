// Gate for the global ✦ coach pill — Placement D (2026-08 nav redesign).
//
// Coach lost its bottom-nav tab, so the one always-reachable coach affordance
// is now an icon-only sparkle circle riding beside Quick Log. Five things have
// to stay true or the promotion regresses into exactly the control the research
// warned against:
//
//   1. INBOARD, NOT OUTBOARD, AND NEVER BOTTOM-LEFT. Bottom-left is the single
//      quadrant a right-handed one-handed user cannot reach without a grip
//      change (~⅓ of sessions). The circle sits to the LEFT of Quick Log
//      inside one right-anchored cluster — further from the edge, still deep
//      in the thumb arc.
//
//   2. ONE CLUSTER, CONSTANT GAP. Quick Log is not fixed-width: it morphs
//      between a labelled pill and an icon circle on every scroll
//      (`quickLogFabExpandedProvider`, 12 px collapse / 8 px re-expand). A
//      coach button with its own `Positioned(right:)` would have the gap
//      between them opening and shutting on every scroll. Laid out as one Row,
//      the gap is a constant and the morph slides the pair together.
//
//   3. ONE DIAMETER, EXACTLY TWO SLOTS. D4 (2026-08, real device): the founder
//      photographed three floats in this band at three different diameters —
//      the coach circle's own 40, Quick Log's 44 and the chat-head's hardcoded
//      56, three literals that derived from nothing. Every circular float now
//      derives from `kFloatCircleDiameter`, and the band holds exactly two of
//      them. Hierarchy is carried by fill and caption, never by shrinking one
//      circle below the 44 pt touch-target floor.
//
//   3b. THE COACH CONTROL IS AN AI CONTROL. D3: it rendered a chat bubble with
//      a half-size sparkle inside; at the 15 px it was drawn at, the sparkle
//      vanished and the founder read the leftover outline as a CAMERA. A
//      standalone sparkle is the universal "AI is this control's entire job"
//      mark. A chat bubble must never come back.
//
//   4. IT STANDS DOWN WHERE IT WOULD INTRUDE. Google Health users report
//      triggering their AI coach accidentally; a coach button floating over
//      the coach screen, or over an active workout that already has its own
//      Ask-coach pill and a docked mini player in this exact band, is that
//      complaint in miniature. Both the circle AND its gap must disappear —
//      a 10 px hole hanging off Quick Log's left edge is the artefact of a
//      control that isn't there.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitwiz/core/constants/chrome_constants.dart';
import 'package:fitwiz/core/providers/workout_mini_player_provider.dart';
import 'package:fitwiz/core/services/posthog_service.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/providers/coach_unread_provider.dart';
import 'package:fitwiz/widgets/coach_floating_button.dart';
import 'package:fitwiz/widgets/coach_quick_log_cluster.dart';
import 'package:fitwiz/widgets/coach_spark_icon.dart';
import 'package:fitwiz/widgets/quick_log_fab_chrome.dart';

Workout _workout() => Workout(
      id: 'w1',
      name: 'Lower Body',
      type: 'strength',
      scheduledDate: '2026-08-11T12:00:00+00:00',
    );

/// The shipped mini-player notifier, seeded with a live workout. Subclassed
/// (not re-implemented) so "a workout is active" means exactly what it means
/// in production: the notifier is holding a `workout`, which only `close()`
/// clears.
class _ActiveWorkoutMiniPlayer extends WorkoutMiniPlayerNotifier {
  _ActiveWorkoutMiniPlayer(super.posthog) {
    state = WorkoutMiniPlayerState(isMinimized: true, workout: _workout());
  }
}

/// Pumps the cluster right-anchored at the bottom, exactly as `MainShell`
/// mounts it (`PositionedDirectional(end: 24, bottom: …)`).
Future<void> _pumpCluster(
  WidgetTester tester, {
  required bool expanded,
  String location = '/home',
  bool workoutActive = false,
  int unread = 0,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      for (final p in const ['/home', '/chat'])
        GoRoute(
          path: p,
          builder: (context, state) => Scaffold(
            body: Stack(
              children: [
                PositionedDirectional(
                  end: 24,
                  bottom: 100,
                  child: CoachQuickLogCluster(
                    quickLogExpanded: expanded,
                    quickLogLabel: 'Quick Log',
                    onQuickLog: () {},
                    maxWidth: 320,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      coachUnreadCountProvider.overrideWith((ref) => unread),
      if (workoutActive)
        workoutMiniPlayerProvider.overrideWith(
          (ref) => _ActiveWorkoutMiniPlayer(ref.read(posthogServiceProvider)),
        ),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

Rect _rectOf(Finder f) {
  final element = f.evaluate().single;
  final box = element.renderObject! as RenderBox;
  final topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}

Finder get _coach => find.byType(CoachFloatingButton);
Finder get _quickLog => find.byType(QuickLogFabChrome);

void main() {
  group('1 — the pill renders inboard of Quick Log', () {
    testWidgets('both render, coach to the LEFT of Quick Log', (tester) async {
      await _pumpCluster(tester, expanded: true);

      expect(_coach, findsOneWidget);
      expect(_quickLog, findsOneWidget);

      final coach = _rectOf(_coach);
      final quickLog = _rectOf(_quickLog);
      expect(coach.right, lessThanOrEqualTo(quickLog.left),
          reason: 'the coach circle must sit INBOARD of Quick Log');
    });

    testWidgets('never bottom-left: it lives in the right half', (tester) async {
      await _pumpCluster(tester, expanded: true);
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(_rectOf(_coach).left, greaterThan(screenWidth / 2),
          reason:
              'bottom-left is the one quadrant a right-handed one-handed user '
              'cannot reach without a grip change');
    });

    testWidgets('both floats are ONE diameter (D4)', (tester) async {
      await _pumpCluster(tester, expanded: true);
      final coach = _rectOf(_coach);
      final quickLog = _rectOf(_quickLog);
      expect(coach.width, kFloatCircleDiameter);
      expect(coach.height, kFloatCircleDiameter);
      expect(quickLog.height, kFloatCircleDiameter,
          reason: 'a float is a float — one diameter, no exceptions');
      // Expanded, Quick Log is WIDER (it carries the caption). That is the
      // only dimension allowed to differ, and only in the expanded state.
      expect(quickLog.width, greaterThan(coach.width));
    });

    testWidgets('it is icon-only — never a second labelled pill',
        (tester) async {
      await _pumpCluster(tester, expanded: true);
      expect(_rectOf(_coach).width, _rectOf(_coach).height,
          reason: 'a circle, in both scroll states');
      expect(find.text('Ask coach'), findsNothing,
          reason:
              'a labelled coach pill would compete with Quick Log for the same '
              'band — the whole point of Placement D is that it does not');
    });
  });

  group('2 — it collapses WITH Quick Log, as one cluster', () {
    testWidgets('the gap never breathes', (tester) async {
      await _pumpCluster(tester, expanded: true);
      final gapExpanded = _rectOf(_quickLog).left - _rectOf(_coach).right;

      await _pumpCluster(tester, expanded: false);
      final gapCollapsed = _rectOf(_quickLog).left - _rectOf(_coach).right;

      expect(gapExpanded, closeTo(kFloatClusterGap, 0.01));
      expect(gapCollapsed, closeTo(kFloatClusterGap, 0.01),
          reason:
              'two independently-anchored floats would have this gap opening '
              'and shutting on every scroll');
    });

    testWidgets('the pair moves together when Quick Log collapses',
        (tester) async {
      await _pumpCluster(tester, expanded: true);
      final coachExpanded = _rectOf(_coach);
      final quickLogExpanded = _rectOf(_quickLog);

      await _pumpCluster(tester, expanded: false);
      final coachCollapsed = _rectOf(_coach);
      final quickLogCollapsed = _rectOf(_quickLog);

      // The cluster is right-anchored, so a narrower Quick Log pulls the coach
      // circle toward the edge with it — one movement, not two.
      expect(quickLogCollapsed.width, lessThan(quickLogExpanded.width));
      expect(coachCollapsed.left, greaterThan(coachExpanded.left));
      expect(quickLogCollapsed.right, closeTo(quickLogExpanded.right, 0.01),
          reason: 'the cluster stays anchored to the same right edge');
      // Vertically centred on each other in both states.
      expect(coachCollapsed.center.dy, closeTo(quickLogCollapsed.center.dy, 0.01));
      expect(coachExpanded.center.dy, closeTo(quickLogExpanded.center.dy, 0.01));
    });
  });

  group('3 — it hides where it would intrude', () {
    test('the rules are explicit and pure', () {
      expect(
        CoachFloatingButton.isSuppressed(
            location: '/home', workoutActive: false),
        isFalse,
      );
      expect(
        CoachFloatingButton.isSuppressed(
            location: '/chat', workoutActive: false),
        isTrue,
        reason: 'hidden on the coach screen itself',
      );
      expect(
        CoachFloatingButton.isSuppressed(
            location: '/chat?source=coach_fab', workoutActive: false),
        isTrue,
      );
      expect(
        CoachFloatingButton.isSuppressed(
            location: '/health', workoutActive: true),
        isTrue,
        reason:
            'deferred during an active workout — that flow has its own '
            'Ask-coach pill and a mini player docked in this band',
      );
    });

    testWidgets('on the coach screen: no circle, and no leftover gap',
        (tester) async {
      await _pumpCluster(tester, expanded: true, location: '/chat');

      // The widget still mounts (it owns the rule), but paints nothing.
      expect(_rectOf(_coach).width, 0);
      expect(_quickLog, findsOneWidget,
          reason: 'Quick Log is unaffected by the coach rule');

      // No 10 px hole hanging off Quick Log's leading edge.
      expect(find.byType(SizedBox).evaluate().where((e) {
        final w = e.widget as SizedBox;
        return w.width == kFloatClusterGap;
      }), isEmpty);
    });

    testWidgets('during an active workout: no circle', (tester) async {
      await _pumpCluster(tester, expanded: true, workoutActive: true);
      expect(_rectOf(_coach).width, 0);
      expect(_quickLog, findsOneWidget);
    });
  });

  group('4 — the unread badge moved onto the pill', () {
    testWidgets('no badge at zero', (tester) async {
      await _pumpCluster(tester, expanded: true, unread: 0);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('shows the count', (tester) async {
      await _pumpCluster(tester, expanded: true, unread: 3);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('caps the count at 9+', (tester) async {
      await _pumpCluster(tester, expanded: true, unread: 42);
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('the badge hides with the pill', (tester) async {
      await _pumpCluster(
          tester, expanded: true, unread: 3, location: '/chat');
      expect(find.text('3'), findsNothing);
    });
  });

  // ── D3 ────────────────────────────────────────────────────────────────────
  group('5 — the coach control reads as AI, not as messaging (D3)', () {
    Icon iconOf(Finder f) => f.evaluate().single.widget as Icon;

    testWidgets('CoachSparkIcon is a STANDALONE sparkle', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(child: CoachSparkIcon(color: Colors.black)),
        ),
      ));

      final icons = find.descendant(
        of: find.byType(CoachSparkIcon),
        matching: find.byType(Icon),
      );
      expect(icons, findsOneWidget,
          reason:
              'ONE icon. The composite this replaced layered a half-size '
              'sparkle over a chat bubble, and at float-glyph size the sparkle '
              'disappeared into antialiasing.');
      expect(iconOf(icons).icon, Icons.auto_awesome,
          reason:
              'the universal AI mark; a sparkle standing alone means "AI is '
              'this control\'s entire job"');
    });

    testWidgets('no chat bubble survives anywhere in the coach float',
        (tester) async {
      await _pumpCluster(tester, expanded: true);
      for (final icon in const [
        Icons.chat_bubble_outline_rounded,
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        Icons.chat_bubble_rounded,
        Icons.message_outlined,
        Icons.sms_outlined,
      ]) {
        expect(find.byIcon(icon), findsNothing,
            reason:
                'a messaging glyph advertises "send a message", not "AI" — '
                'and the founder read the old one as a camera');
      }
      expect(
        find.descendant(of: _coach, matching: find.byIcon(Icons.auto_awesome)),
        findsOneWidget,
      );
    });

    testWidgets('the sparkle defaults to the shared float glyph size',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(child: CoachSparkIcon(color: Colors.black)),
        ),
      ));
      expect(iconOf(find.byType(Icon)).size, kFloatGlyphSize);
    });

    testWidgets('coach ✦ and Quick Log + are optically the same size',
        (tester) async {
      await _pumpCluster(tester, expanded: true);
      final spark = find
          .descendant(of: _coach, matching: find.byIcon(Icons.auto_awesome))
          .evaluate()
          .single
          .widget as Icon;
      final plus = find
          .descendant(of: _quickLog, matching: find.byIcon(Icons.add_rounded))
          .evaluate()
          .single
          .widget as Icon;
      expect(spark.size, kFloatGlyphSize);
      expect(plus.size, kFloatGlyphSize,
          reason:
              'matched circles with mismatched glyphs still read as two '
              'unrelated controls');
    });
  });

  // ── D4 ────────────────────────────────────────────────────────────────────
  group('6 — the float band: one diameter, two slots, honest clearance', () {
    test('every circular float derives from ONE diameter token', () {
      // The three literals D4 was made of are gone. `kQuickLogFabHeight` is
      // now an alias, not an independent number — if someone re-splits them
      // this fails before it reaches a device.
      // NOT `expect(kQuickLogFabHeight, kFloatCircleDiameter)` — that is
      // tautological, because kQuickLogFabHeight is DEFINED as the alias. It
      // can only fail if someone re-splits it, which is exactly what this
      // reads the source to detect.
      final chrome =
          File('lib/core/constants/chrome_constants.dart').readAsStringSync();
      expect(
        RegExp(r'kQuickLogFabHeight\s*=\s*kFloatCircleDiameter')
            .hasMatch(chrome),
        isTrue,
        reason: 'kQuickLogFabHeight must stay an ALIAS of the one diameter '
            'token. Re-splitting it into its own literal is how the two '
            'floats drifted to different sizes in the first place.',
      );
      expect(kFloatCircleDiameter, greaterThanOrEqualTo(44.0),
          reason: 'platform minimum touch target; the old 40 pt coach circle '
              'was under it');
    });

    testWidgets('the cluster has EXACTLY TWO floats — never a third',
        (tester) async {
      await _pumpCluster(tester, expanded: true);
      final row = find
          .descendant(of: find.byType(CoachQuickLogCluster),
              matching: find.byType(Row))
          .evaluate()
          .first
          .widget as Row;
      // coach + gap + quick log. A third `Positioned`/child in this band is
      // the D4 defect; a new floating affordance either REPLACES a slot under
      // mutual exclusion (chat-head ↔ coach circle) or becomes a row inside
      // the Quick Log sheet.
      expect(row.children.length, lessThanOrEqualTo(3));
      expect(find.byType(CoachFloatingButton), findsOneWidget);
      expect(find.byType(QuickLogFabChrome), findsOneWidget);
    });

    testWidgets('collapsed, the two floats are the SAME rect size',
        (tester) async {
      await _pumpCluster(tester, expanded: false);
      final coach = _rectOf(_coach);
      final quickLog = _rectOf(_quickLog);
      expect(quickLog.size, coach.size,
          reason:
              'at rest-collapsed both are plain circles — the founder\'s '
              'screenshot showed them at visibly different diameters');
      expect(coach.height, kFloatCircleDiameter);
    });

    test('the reserved clearance covers the cluster\'s real footprint', () {
      // The band the cluster occupies above the safe-area inset.
      const bandBottom = kQuickLogFabBottomOffset;
      const bandTop = bandBottom + kFloatCircleDiameter;
      expect(kQuickLogFabClearance, greaterThanOrEqualTo(bandTop),
          reason:
              'a screen reserving less than this leaves its last rows under '
              'the button by construction');
      // Deliberately NOT `expect(kQuickLogFabClearance, bandTop + bleed)` —
      // that restates the definition verbatim and cannot fail. The inequality
      // above is the property worth holding; the exact value is an
      // implementation detail of the same expression.
    });

    test('the nav scrim paints UNDER the floats, not over them', () {
      // THE Z-ORDER REORDER — the single most consequential edit in the
      // overlap fix, and previously untested: every other assertion here is
      // over constants, so reverting this reorder left all of them green
      // while the scrim veiled the floats instead of the content behind them.
      //
      // A source-order assertion rather than a pumped shell: MainShell needs
      // the router, the full provider graph and a live workout session to
      // build. This is a proxy — but one that FAILS when the order changes,
      // which the constant assertions do not.
      final shell = File('lib/widgets/main_shell.dart').readAsStringSync();
      final navAt = shell.indexOf('_FloatingNavBarWithAI(');
      final clusterAt = shell.indexOf('CoachQuickLogCluster(');
      expect(navAt, greaterThan(-1), reason: 'nav bar not found in the shell');
      expect(clusterAt, greaterThan(-1), reason: 'cluster not found');
      expect(
        navAt,
        lessThan(clusterAt),
        reason: 'the nav (which carries the scrim) must be mounted BEFORE the '
            'float cluster in the Stack, so the scrim paints beneath the '
            'floats. Reversed, the widened scrim washes over the coach circle '
            'and Quick Log instead of the content under them.',
      );
    });

    test('the nav scrim starts ABOVE the band, so floats never sit on raw '
        'content', () {
      // THE OVERLAP ROOT CAUSE. The scrim box top sits at
      // `kMainNavBarHeight + kMainNavFadeHeight` above the safe-area inset.
      // At the old literal fade height (36) that was exactly 92 — the FAB's
      // BOTTOM edge — so the whole cluster floated on fully-opaque content and
      // the coach circle sat on the Connect Health card.
      const scrimTop = kMainNavBarHeight + kMainNavFadeHeight;
      expect(scrimTop, greaterThan(kQuickLogFabClearance),
          reason:
              'trailing scroll clearance cannot fix rest-position overlap — on '
              'any page taller than the viewport something is always under the '
              'band at scroll offset 0. The scrim is what fixes it, and it has '
              'to reach over the whole band.');
    });
  });
}
