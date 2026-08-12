// Gate for the 2026-08 nav redesign: Coach leaves the bottom nav, Health takes
// the centre slot.
//
// Three invariants, each of which broke a real surface when it was wrong:
//
//  1. THE BRANCH RESOLVES. Branch index 2 of the `StatefulShellRoute` must be
//     `/health`, and the bar order must stay Home · Workout · Health ·
//     Nutrition · You. `MainShell` addresses branches POSITIONALLY
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

// HealthSyncNotifier / HealthSyncState live in a `part` of this library, so
// they come in through the parent import — never import the part file.
import 'package:fitwiz/data/services/health_service.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/cardio/fitness_index_detail_screen.dart';
import 'package:fitwiz/screens/health/combined_health_screen.dart';
import 'package:fitwiz/screens/health/health_shell_screen.dart';
import 'package:fitwiz/screens/health/heart_health_detail_screen.dart';
import 'package:fitwiz/screens/health/sleep_detail_screen.dart';
import 'package:fitwiz/screens/health/vitals_detail_screen.dart';
import 'package:fitwiz/widgets/design_system/zealova_chip.dart';

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
    /// later ones are secondary routes inside that branch (e.g. `/social`
    /// living in the Nutrition branch), not tabs.
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

    test('bar order is Home · Workout · Health · Nutrition · You', () {
      expect(
        branchRootPaths(shellRoutes),
        ['/home', '/workouts', '/health', '/nutrition', '/profile'],
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
    // itself, by reading `ZealovaTextTabs.activeIndex` off the built widget.
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

        final rail = tester.widget<ZealovaTextTabs>(
          find.byType(ZealovaTextTabs),
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
      expect(find.widgetWithText(ElevatedButton, 'Connect Health'),
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
          find.widgetWithText(ElevatedButton, 'Connect Health'),
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
  group('4 — back-stack: the /health/* detail routes did NOT move', () {
    // The scout's finding: ~23 call sites across Home, Nutrition, You, chat
    // and `notifications_screen.dart` push these paths and rely on
    // `GlassBackButton`'s pop returning to the screen they came from. Inside a
    // StatefulShellBranch the same push switches BRANCHES — the bottom nav
    // jumps to Health, the previous tab is left behind in the IndexedStack
    // rather than popped to, and that back button pops to the Health root or
    // (cold push-notification deep link, no prior branch entry) no-ops
    // entirely. Keeping them top-level is what preserves all 23.
    const detailPaths = [
      '/health/sleep',
      '/health/combined',
      '/health/vitals',
      '/health/heart-health',
      '/health/fitness-index',
    ];

    test('all five stay registered OUTSIDE the shell branch', () {
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

    test('the Health branch owns exactly one path', () {
      final shellRoutes =
          _read('lib/navigation/app_router_main_shell_routes.dart');
      final healthPaths = RegExp(r"path: '(/health[^']*)'")
          .allMatches(shellRoutes)
          .map((m) => m.group(1)!)
          .toSet();
      expect(healthPaths, {'/health'});
    });
  });
}
