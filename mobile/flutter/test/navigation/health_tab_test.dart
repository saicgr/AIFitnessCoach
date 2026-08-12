// Gate for the 2026-08 nav redesign: Coach leaves the bottom nav, Health takes
// the centre slot.
//
// Three invariants, each of which broke a real surface when it was wrong:
//
//  1. THE BRANCH RESOLVES. Branch index 2 of the `StatefulShellRoute` must be
//     `/health`, and the bar order must stay Home · Workout · Health ·
//     Nutrition · Community (the fifth slot converted from You in Step 2 —
//     see `community_tab_test.dart`). `MainShell` addresses branches POSITIONALLY
//     (`_calculateSelectedIndex`, `goBranch(index)`), so a branch inserted or
//     reordered anywhere silently sends every tab tap to the wrong screen.
//
//  2. THE SUB-TABS ROUTE TO THE RIGHT SCREENS. The rail composes five
//     already-shipped screens; chip N must show screen N, in embedded mode.
//     Embedded is what drops each screen's own `GlassBackButton` header — a
//     chip rendering a NON-embedded screen would put a back button inside a
//     tab, pointing at nothing to pop.
//
//  3. AN EMPTY SUB-TAB IS LABELLED. With no Health source connected there is
//     nothing for any of the five screens to draw. Each chip must say WHICH
//     view is empty and offer the Connect Health CTA (which Home gave up),
//     never a wall of blank cards.
//
// Plus the back-stack contract that made all of this safe: the five
// `/health/*` DETAIL routes stay top-level, outside the branch, so the ~23
// existing `push('/health/…')` call sites keep popping back to their referrer
// instead of switching tabs and stranding the user.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// HealthSyncNotifier / HealthSyncState live in a `part` of this library, so
// they come in through the parent import — never import the part file.
import 'package:fitwiz/data/providers/health_tab_request_provider.dart';
import 'package:fitwiz/core/stats/state_valence.dart';
import 'package:fitwiz/data/repositories/vitals_repository.dart';
import 'package:fitwiz/data/services/health_service.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/cardio/fitness_index_detail_screen.dart';
import 'package:fitwiz/screens/health/combined_health_screen.dart';
import 'package:fitwiz/screens/health/health_shell_screen.dart';
import 'package:fitwiz/screens/health/widgets/health_chrome.dart';
import 'package:fitwiz/screens/health/heart_health_detail_screen.dart';
import 'package:fitwiz/screens/health/sleep_detail_screen.dart';
import 'package:fitwiz/screens/health/vitals_detail_screen.dart';

/// A `HealthSyncNotifier` that never touches SharedPreferences or the platform
/// health store. Passing `demoMode: true` makes the real constructor return
/// immediately (it skips `_loadSyncState()`), after which the state is set
/// directly — so this is the shipped notifier with its I/O short-circuited,
/// not a parallel implementation that could drift from it.
class _StubHealthSync extends HealthSyncNotifier {
  _StubHealthSync({required bool connected}) : super(HealthService(), true) {
    state = HealthSyncState(isConnected: connected);
  }
}

Widget _wrap(Widget child, {required bool connected}) {
  return ProviderScope(
    overrides: [
      healthSyncProvider.overrideWith((ref) => _StubHealthSync(
            connected: connected,
          )),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Same as [_wrap], but hands back the backing [ProviderContainer] so a test
/// can drive [healthTabRequestProvider] from OUTSIDE the widget tree — this
/// is exactly how the real deep link fires it: `app_router_main_shell_routes
/// .dart`'s pageBuilder does `ProviderScope.containerOf(context, listen:
/// false).read(healthTabRequestProvider.notifier).requestTab(...)` from a
/// post-frame callback, not from inside `HealthShellScreen` itself.
({Widget widget, ProviderContainer container}) _wrapWithContainer(
  Widget child, {
  required bool connected,
}) {
  final container = ProviderContainer(
    overrides: [
      healthSyncProvider.overrideWith((ref) => _StubHealthSync(
            connected: connected,
          )),
    ],
  );
  return (
    widget: UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
    container: container,
  );
}

String _read(String relative) => File(relative).readAsStringSync();

void main() {
  // ───────────────────────────────────────────────────────────────────────
  group('1 — the Health branch resolves at index 2', () {
    late String shellRoutes;

    setUpAll(() {
      shellRoutes = _read('lib/navigation/app_router_main_shell_routes.dart');
    });

    /// The ROOT path of each `StatefulShellBranch`, in declaration order —
    /// i.e. the bottom-bar order. Only the first `path:` of each branch counts;
    /// later ones are secondary routes inside that branch (e.g. `/profile`,
    /// which lives in the Community branch behind its masthead avatar), not
    /// tabs.
    List<String> branchRootPaths(String source) {
      final shellStart = source.indexOf('StatefulShellRoute.indexedStack');
      expect(shellStart, greaterThan(-1),
          reason: 'the main shell must still be a StatefulShellRoute');
      // The shell ends where the first sibling top-level route begins.
      final shellEnd = source.indexOf('GoRoute(\n        path:', shellStart);
      expect(shellEnd, greaterThan(shellStart),
          reason: 'could not find the end of the StatefulShellRoute block');
      final body = source.substring(shellStart, shellEnd);
      final pathRe = RegExp(r"path:\s*'([^']+)'");
      return body
          .split('StatefulShellBranch(')
          .skip(1) // text before the first branch
          .map((segment) => pathRe.firstMatch(segment)?.group(1))
          .whereType<String>()
          .toList();
    }

    test('bar order is Home · Workout · Health · Nutrition · Community', () {
      expect(
        branchRootPaths(shellRoutes),
        ['/home', '/workouts', '/health', '/nutrition', '/community'],
        reason:
            'MainShell addresses branches positionally (goBranch(index) and '
            '_calculateSelectedIndex), so reordering or inserting a branch '
            'sends every tab tap to the wrong screen. Material 3 also caps the '
            'bar at five slots — this change converts one, it never adds a '
            'sixth.',
      );
    });

    test('index 2 is Health, and Coach no longer holds a branch', () {
      final paths = branchRootPaths(shellRoutes);
      expect(paths[2], '/health');
      expect(paths, isNot(contains('/coach')),
          reason: 'Coach gave up its tab; it is the global ✦ pill now');
    });

    test('/coach still resolves — as a redirect, not a dead route', () {
      // Home-timeline entries, widgets and older notification payloads still
      // carry the literal; dropping the path entirely lands them on the
      // router's "Page not found" screen.
      expect(shellRoutes, contains("path: '/coach'"));
      expect(
        RegExp(r"path: '/coach',\s*\n\s*redirect:").hasMatch(shellRoutes),
        isTrue,
        reason: '/coach must redirect (to the chat), never render a screen',
      );
    });

    test('MainShell maps a /health location to index 2', () {
      final shell = _read('lib/widgets/main_shell.dart');
      expect(shell, contains("if (location.startsWith('/health')) return 2;"));
      expect(shell, isNot(contains("startsWith('/coach')")));
      expect(shell, contains("context.go('/health');"));
    });

    test('the nav bar renders navHealth with a tour anchor', () {
      final navBar = _read('lib/widgets/main_shell_part_edge_panel_handle.dart');
      expect(navBar, contains('AppLocalizations.of(context).navHealth'));
      expect(navBar, contains('AppTourKeys.healthNavKey'));
      expect(navBar, isNot(contains('AppLocalizations.of(context).navCoach')));
      // Heart-pulse glyph, per the mockup — not a plain heart (reads as
      // "favourites") and not a generic activity icon.
      expect(navBar, contains('Icons.monitor_heart'));
    });

    test('_warmActiveTab warms Health, not the retired coach surfaces', () {
      final shell = _read('lib/widgets/main_shell.dart');
      final start = shell.indexOf('case 2: // Health');
      expect(start, greaterThan(-1), reason: 'no Health case in _warmActiveTab');
      // Search forward from `start` — `_onItemTapped` has its own `case 3:`
      // earlier in the file.
      final case2 = shell.substring(start, shell.indexOf('case 3:', start));
      expect(case2, contains('combinedHealthHistoryProvider'));
      expect(case2, contains('recoveryProvider'));
      expect(case2, isNot(contains('dailyCoachInsightProvider')));
    });

    test('navHealth ships in all 36 .arb files', () {
      final arbs = Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList();
      expect(arbs.length, 36);
      for (final f in arbs) {
        final map = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final key in ['navHealth', 'healthTabVitals', 'healthTabNoDataYet']) {
          expect(map[key], isA<String>(),
              reason: '${f.path} is missing "$key"');
          expect((map[key] as String).trim(), isNotEmpty,
              reason: '${f.path} has an empty "$key"');
        }
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('2 — the sub-tabs route to the right screens', () {
    test('the rail is OVERVIEW · SLEEP · RECOVERY · VITALS · BODY, in order',
        () {
      expect(
        HealthSubTab.values.map((t) => t.slug).toList(),
        ['overview', 'sleep', 'recovery', 'vitals', 'body'],
      );
    });

    test('each chip composes its own already-shipped screen', () {
      expect(healthSubTabScreen(HealthSubTab.overview),
          isA<CombinedHealthScreen>());
      expect(healthSubTabScreen(HealthSubTab.sleep), isA<SleepDetailScreen>());
      expect(healthSubTabScreen(HealthSubTab.recovery),
          isA<HeartHealthDetailScreen>());
      expect(healthSubTabScreen(HealthSubTab.vitals), isA<VitalsDetailScreen>());
      expect(healthSubTabScreen(HealthSubTab.body),
          isA<FitnessIndexDetailScreen>());
    });

    test('every composed screen is EMBEDDED — no back button inside a tab', () {
      expect(
        (healthSubTabScreen(HealthSubTab.overview) as CombinedHealthScreen)
            .embedded,
        isTrue,
      );
      expect(
        (healthSubTabScreen(HealthSubTab.sleep) as SleepDetailScreen).embedded,
        isTrue,
      );
      expect(
        (healthSubTabScreen(HealthSubTab.recovery) as HeartHealthDetailScreen)
            .embedded,
        isTrue,
      );
      expect(
        (healthSubTabScreen(HealthSubTab.vitals) as VitalsDetailScreen).embedded,
        isTrue,
      );
      expect(
        (healthSubTabScreen(HealthSubTab.body) as FitnessIndexDetailScreen)
            .embedded,
        isTrue,
      );
    });

    test('?tab= accepts a slug, an index, and survives junk', () {
      expect(HealthSubTab.fromParam('vitals'), HealthSubTab.vitals);
      expect(HealthSubTab.fromParam('3'), HealthSubTab.vitals);
      expect(HealthSubTab.fromParam(null), HealthSubTab.overview);
      expect(HealthSubTab.fromParam(''), HealthSubTab.overview);
      // A stale deep link lands on the hub, never on a crash or a 404.
      expect(HealthSubTab.fromParam('nonsense'), HealthSubTab.overview);
      expect(HealthSubTab.fromParam('99'), HealthSubTab.overview);
    });

    testWidgets('the rail renders all five chips', (tester) async {
      await tester.pumpWidget(_wrap(
        const HealthShellScreen(initialTab: HealthSubTab.body),
        connected: false,
      ));
      await tester.pump();

      for (final label in ['OVERVIEW', 'SLEEP', 'RECOVERY', 'VITALS', 'BODY']) {
        expect(find.text(label), findsWidgets, reason: 'rail chip $label');
      }
    });

    // The test above passes for ANY initialTab — it asserts the rail exists,
    // not that the requested chip is selected. This one asserts the selection
    // itself, by reading `HealthRail.activeIndex` off the built widget.
    testWidgets('initialTab actually selects that chip, for every value',
        (tester) async {
      for (final tab in HealthSubTab.values) {
        // A unique key per iteration is REQUIRED. Without it Flutter reuses
        // the element across `pumpWidget` calls (same runtime type), so
        // `initState` never re-runs and `_index` keeps the first iteration's
        // value — the assertion would then read a stale 0 and this test would
        // "fail" on a correct implementation.
        await tester.pumpWidget(_wrap(
          HealthShellScreen(key: ValueKey(tab), initialTab: tab),
          connected: false,
        ));
        await tester.pump();

        final rail = tester.widget<HealthRail>(
          find.byType(HealthRail),
        );
        expect(
          rail.activeIndex,
          HealthSubTab.values.indexOf(tab),
          reason: 'initialTab: ${tab.slug} must select rail index '
              '${HealthSubTab.values.indexOf(tab)}, got ${rail.activeIndex}',
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('2b — the deviation-vs-baseline sentence reaches the Health tab', () {
    // The frame's whole point: every populated signal states how far it is
    // from the user's OWN 30-day baseline, in words, with the ramp dot glued
    // to that sentence. Before this, no percent-vs-baseline line rendered
    // anywhere in the tab — `DeviationLine` shipped but was mounted only on
    // Home tiles.
    Future<void> pumpLine(WidgetTester tester, VitalSignal s) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (c) => vitalDeviationLine(c, s)),
        ),
      ));
      await tester.pump();
    }

    VitalSignal signal({
      double? value,
      double? baseline,
      double? z,
      String direction = 'high_bad',
      String state = 'in_range',
    }) =>
        VitalSignal(
          key: 'resting_heart_rate',
          label: 'Resting HR',
          unit: 'bpm',
          value: value,
          baseline: baseline,
          z: z,
          direction: direction,
          state: state,
        );

    testWidgets('a reading below baseline says so, as a signed percent',
        (tester) async {
      await pumpLine(
          tester, signal(value: 48, baseline: 50, z: -0.4));
      expect(find.text('4% below baseline'), findsOneWidget);
    });

    testWidgets('a reading above baseline says so', (tester) async {
      await pumpLine(
          tester, signal(value: 51, baseline: 50, z: 0.4));
      expect(find.text('2% above baseline'), findsOneWidget);
    });

    testWidgets('a reading that rounds to the baseline says "On baseline"',
        (tester) async {
      await pumpLine(tester, signal(value: 50.1, baseline: 50, z: 0.05));
      expect(find.text('On baseline'), findsOneWidget);
    });

    testWidgets('no baseline yet → the honest line, never a fabricated 0%',
        (tester) async {
      await pumpLine(tester, signal(value: 50, baseline: null, z: null));
      expect(find.text('Building baseline'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('the dot colour follows the VALENCE, not the direction of '
        'travel', (tester) async {
      // Resting HR is `high_bad`: BELOW baseline supports, ABOVE strains.
      // This is the rule the whole ramp exists to enforce — the same "+2%"
      // is green for steps and amber for resting HR.
      await pumpLine(tester, signal(value: 44, baseline: 50, z: -2.0));
      final supports = tester
          .widget<Container>(find.descendant(
              of: find.byType(DeviationLine), matching: find.byType(Container)))
          .decoration as BoxDecoration;

      await pumpLine(tester, signal(value: 56, baseline: 50, z: 2.0));
      final strains = tester
          .widget<Container>(find.descendant(
              of: find.byType(DeviationLine), matching: find.byType(Container)))
          .decoration as BoxDecoration;

      expect(supports.color, isNot(strains.color),
          reason: 'a low resting HR and a high one must not share a colour');
      expect(supports.color, SemanticState.supports.colorFor(false));
      expect(strains.color, SemanticState.strains.colorFor(false));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('3 — an empty sub-tab renders a LABELLED empty state', () {
    testWidgets('disconnected: the chip is named, and Connect Health is offered',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const HealthShellScreen(initialTab: HealthSubTab.sleep),
        connected: false,
      ));
      await tester.pump();

      // The label is what makes it a LABELLED empty state — "SLEEP" appears
      // twice: once as the rail chip, once as the empty state's own heading.
      expect(find.text('SLEEP'), findsNWidgets(2));
      expect(find.text('Connect Health to see your activity'), findsOneWidget);
      expect(find.widgetWithText(HealthCtaPill, 'CONNECT HEALTH'),
          findsOneWidget);

      // And crucially: NOT the composed screen. A disconnected Sleep tab must
      // not paint the hypnogram scaffolding with nothing in it.
      expect(find.byType(SleepDetailScreen), findsNothing);
    });

    testWidgets('every chip degrades, not just the landing one', (tester) async {
      for (final tab in HealthSubTab.values) {
        await tester.pumpWidget(_wrap(
          HealthShellScreen(key: ValueKey(tab), initialTab: tab),
          connected: false,
        ));
        await tester.pump();
        expect(
          find.widgetWithText(HealthCtaPill, 'CONNECT HEALTH'),
          findsOneWidget,
          reason: '${tab.slug} must offer the connect CTA when disconnected',
        );
        expect(
          find.text('Connect Health to see your activity'),
          findsOneWidget,
          reason: '${tab.slug} must explain itself, not render blanks',
        );
      }
    });

    testWidgets('tapping a rail chip moves to that chip\'s empty state',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const HealthShellScreen(),
        connected: false,
      ));
      await tester.pump();

      // Overview is the landing chip: its name appears twice (rail + heading).
      expect(find.text('OVERVIEW'), findsNWidgets(2));
      expect(find.text('VITALS'), findsOneWidget); // rail only

      await tester.tap(find.text('VITALS'));
      await tester.pumpAndSettle();

      expect(find.text('VITALS'), findsNWidgets(2));
      expect(find.text('OVERVIEW'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('5 — healthTabRequestProvider drives the WARM path', () {
    // `initialTab` only ever runs once, in `initState` — it is the COLD-entry
    // path. The whole reason `healthTabRequestProvider` exists is the branch
    // being already alive in the shell's `IndexedStack`: a second deep link
    // (or a home-card tap) into an already-mounted `HealthShellScreen` has no
    // `initState` to seed from, only `ref.listen` in `build`. These tests
    // drive that provider from outside the widget, the way the router does,
    // against an already-pumped (warm) shell.
    testWidgets(
        'a request arriving while the shell is already mounted switches the '
        'rail', (tester) async {
      final wrapped = _wrapWithContainer(
        const HealthShellScreen(), // cold-lands on Overview (index 0)
        connected: false,
      );
      addTearDown(wrapped.container.dispose);
      await tester.pumpWidget(wrapped.widget);
      await tester.pump();

      expect(
        tester
            .widget<HealthRail>(find.byType(HealthRail))
            .activeIndex,
        0,
        reason: 'sanity: cold entry lands on Overview',
      );

      // The shell is warm now. Request Vitals (index 3) exactly as the
      // router's post-frame callback does on a `/health?tab=vitals` push.
      wrapped.container
          .read(healthTabRequestProvider.notifier)
          .requestTab(HealthSubTab.vitals.index);
      // `_applyTabRequest`'s `setState` is itself deferred to a post-frame
      // callback, so this needs two pumps: one to run `ref.listen`'s
      // callback (which schedules the post-frame callback), one to run it.
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<HealthRail>(find.byType(HealthRail))
            .activeIndex,
        HealthSubTab.vitals.index,
        reason: 'a request against an already-warm shell must move the rail '
            '— this is the path initialTab cannot cover',
      );
    });

    testWidgets(
        'a repeated identical request still re-fires after the user moved '
        'the rail manually', (tester) async {
      final wrapped = _wrapWithContainer(
        const HealthShellScreen(),
        connected: false,
      );
      addTearDown(wrapped.container.dispose);
      await tester.pumpWidget(wrapped.widget);
      await tester.pump();

      final notifier =
          wrapped.container.read(healthTabRequestProvider.notifier);

      // First request: Vitals.
      notifier.requestTab(HealthSubTab.vitals.index);
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<HealthRail>(find.byType(HealthRail))
            .activeIndex,
        HealthSubTab.vitals.index,
      );

      // The user manually taps back to Overview — nothing to do with the
      // provider at all.
      await tester.tap(find.text('OVERVIEW'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<HealthRail>(find.byType(HealthRail))
            .activeIndex,
        0,
      );

      // The SAME index is requested again — e.g. the same push notification
      // tapped a second time, or the same `/health?tab=vitals` link opened
      // again. The requested *value* (3) is identical to the first request;
      // only the nonce (`seq`) differs. If the provider tracked plain value
      // equality instead of a nonce, this second request would be
      // indistinguishable from "nothing changed" and the rail would stay
      // stranded on Overview.
      notifier.requestTab(HealthSubTab.vitals.index);
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<HealthRail>(find.byType(HealthRail))
            .activeIndex,
        HealthSubTab.vitals.index,
        reason: 'the nonce must make an identical repeated request re-fire '
            'and snap the rail back after the user moved it away — that is '
            'the entire reason HealthTabRequest carries a seq instead of '
            'being a bare int',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group(
      '4 — source proxy: the /health/* detail routes are registered '
      'OUTSIDE the shell branch', () {
    // These two tests are a TEXT-SCAN PROXY, not an exercise of navigation
    // behaviour: they prove the five detail paths are registered in the
    // right FILE (`app_router_utility_routes.dart`, a plain top-level
    // `GoRoute` list) and absent from the shell-branch file, nothing more.
    // Building the real `app_router.dart` in a widget test isn't feasible
    // here — it wires auth state, Supabase, and dozens of other providers
    // that don't exist in this test's `ProviderScope` — so this cannot by
    // itself prove push/pop behaves correctly at those 23 call sites. Group
    // 6 below proves the MECHANISM (why top-level-vs-branch placement
    // matters) against a real `GoRouter` built with the identical shape;
    // this group only proves the real files still use that shape.
    const detailPaths = [
      '/health/sleep',
      '/health/combined',
      '/health/vitals',
      '/health/heart-health',
      '/health/fitness-index',
    ];

    test('all five stay registered OUTSIDE the shell branch (source scan)',
        () {
      final utility = _read('lib/navigation/app_router_utility_routes.dart');
      final shellRoutes =
          _read('lib/navigation/app_router_main_shell_routes.dart');
      for (final p in detailPaths) {
        expect(utility, contains("path: '$p'"),
            reason: '$p must stay a top-level route');
        expect(shellRoutes, isNot(contains("path: '$p'")),
            reason:
                '$p inside the Health branch breaks pop for ~23 push sites');
      }
    });

    test('the Health branch owns exactly one path (source scan)', () {
      final shellRoutes =
          _read('lib/navigation/app_router_main_shell_routes.dart');
      final healthPaths = RegExp(r"path: '(/health[^']*)'")
          .allMatches(shellRoutes)
          .map((m) => m.group(1)!)
          .toSet();
      expect(healthPaths, {'/health'});
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('6 — mechanism: a detail route sibling to the shell pushes and pops '
      'correctly', () {
    // This is the part group 4 cannot prove: that placing a route as a
    // SIBLING of `StatefulShellRoute.indexedStack` (rather than inside one of
    // its branches) actually behaves the way the ~23 call sites depend on —
    // pushed on top of whichever branch is active, popping back to exactly
    // that branch, never switching the active branch itself. Rather than
    // standing up the full app router (auth/Supabase/dozens of providers),
    // this builds a real `GoRouter` with the SAME STRUCTURAL SHAPE as
    // `app_router_main_shell_routes.dart` + `app_router_utility_routes.dart`
    // — two shell branches plus one sibling detail route — and drives real
    // go_router navigation against it. It exercises go_router's actual
    // push/pop semantics, not a text scan.
    GoRouter buildRouter() {
      return GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => navigationShell,
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      const Scaffold(body: Center(child: Text('HOME ROOT'))),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/health',
                  builder: (context, state) => const Scaffold(
                      body: Center(child: Text('HEALTH ROOT'))),
                ),
              ]),
            ],
          ),
          // Sibling of the shell route — exactly how `/health/vitals` etc.
          // sit in `app_router_utility_routes.dart`, outside every branch.
          GoRoute(
            path: '/health/vitals',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Builder(
                  builder: (innerContext) => TextButton(
                    // Mirrors `GlassBackButton`'s default `onTap`, which
                    // calls `context.pop()` when no explicit handler is
                    // given (`lib/widgets/glass_back_button.dart`).
                    onPressed: () => innerContext.canPop()
                        ? innerContext.pop()
                        : null,
                    child: const Text('VITALS DETAIL'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    testWidgets(
        'pushing the detail route lands on it without switching the active '
        'branch', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('HOME ROOT'), findsOneWidget);

      // Exactly what a Home card does: `context.push('/health/vitals')`.
      router.push('/health/vitals');
      await tester.pumpAndSettle();

      expect(find.text('VITALS DETAIL'), findsOneWidget);
      // The Home branch is still the one underneath — proven definitively by
      // the pop test below returning to HOME ROOT, not HEALTH ROOT.
    });

    testWidgets(
        'popping the detail route returns to the branch that pushed it, '
        'never to the Health branch root', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Push from Home, same as e.g. `today_stats_row.dart`'s
      // `context.push('/health/combined')`.
      router.push('/health/vitals');
      await tester.pumpAndSettle();
      expect(find.text('VITALS DETAIL'), findsOneWidget);

      await tester.tap(find.text('VITALS DETAIL'));
      await tester.pumpAndSettle();

      // If `/health/vitals` had instead been registered as a route INSIDE
      // the Health branch, this pop would land on '/health' (HEALTH ROOT),
      // stranding the user on a branch they never chose to visit. Landing
      // back on Home is what proves the sibling placement is load-bearing,
      // not incidental.
      expect(find.text('HOME ROOT'), findsOneWidget);
      expect(find.text('HEALTH ROOT'), findsNothing);
    });
  });
}
