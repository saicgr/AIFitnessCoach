// Gate for the global ✦ coach pill — Placement D (2026-08 nav redesign).
//
// Coach lost its bottom-nav tab, so the one always-reachable coach affordance
// is now a 40 pt icon-only circle riding beside Quick Log. Four things have to
// stay true or the promotion regresses into exactly the control the research
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
//   3. QUICK LOG STAYS THE BIGGER TARGET. Target size tracks frequency: Quick
//      Log is the daily habitual action, coach is the quiet secondary.
//
//   4. IT STANDS DOWN WHERE IT WOULD INTRUDE. Google Health users report
//      triggering their AI coach accidentally; a coach button floating over
//      the coach screen, or over an active workout that already has its own
//      Ask-coach pill and a docked mini player in this exact band, is that
//      complaint in miniature. Both the circle AND its gap must disappear —
//      a 10 px hole hanging off Quick Log's left edge is the artefact of a
//      control that isn't there.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitwiz/core/providers/workout_mini_player_provider.dart';
import 'package:fitwiz/core/services/posthog_service.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/providers/coach_unread_provider.dart';
import 'package:fitwiz/widgets/coach_floating_button.dart';
import 'package:fitwiz/widgets/coach_quick_log_cluster.dart';
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

    testWidgets('Quick Log keeps the larger target', (tester) async {
      await _pumpCluster(tester, expanded: true);
      final coach = _rectOf(_coach);
      final quickLog = _rectOf(_quickLog);
      expect(coach.width, kCoachPillDiameter);
      expect(quickLog.height, kQuickLogFabHeight);
      expect(quickLog.width, greaterThan(coach.width),
          reason: 'target size tracks frequency; Quick Log is the daily action');
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

      expect(gapExpanded, closeTo(kCoachPillClusterGap, 0.01));
      expect(gapCollapsed, closeTo(kCoachPillClusterGap, 0.01),
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
        return w.width == kCoachPillClusterGap;
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
}
