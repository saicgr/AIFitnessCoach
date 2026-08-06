import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:fitwiz/core/constants/branding.dart';
import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/settings_screen.dart';

import '../../helpers/fake_supabase.dart';

/// url_launcher returns `false` (does NOT throw) when there's no handler
/// for a URL — e.g. no mail client for `mailto:` on the test/CI device.
/// Fakes that exact scenario so it's distinguishable from a real exception.
class _NoHandlerUrlLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => false;
}

/// Every user-facing string in Settings comes from `AppLocalizations`, so the
/// delegate must be registered or the screen throws before it can be found.
const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// The settings tree fans out across a very wide provider surface (theme,
/// haptics, health sync, notifications, gym profiles, rep preferences…), and
/// nearly all of it resolves the signed-in user, which bottoms out in
/// `Supabase.instance` / the Keychain. Stubbing each provider individually is
/// not tractable here, so [initFakeSupabase] supplies a real, signed-out,
/// offline singleton plus an empty secure store instead — the state a
/// logged-out device is genuinely in.
void main() {
  setUpAll(initFakeSupabase);

  group('SettingsScreen', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
    });

    Future<void> pumpSettings(WidgetTester tester, {ThemeData? theme}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: theme,
            localizationsDelegates: _delegates,
            supportedLocales: supportedAppLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // The screen no longer uses a Material AppBar — it renders an Anton
    // masthead inside the scrolling body (uppercased `settingsTitle`) with a
    // back chevron and a help action beside it. Assert that header, not the
    // AppBar shape production stopped having.
    testWidgets('displays the SETTINGS masthead title', (tester) async {
      await pumpSettings(tester);

      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      await pumpSettings(tester);

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('displays a help action in the header', (tester) async {
      await pumpSettings(tester);

      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });

    // Section headers of the current iOS-style grouped layout. The old
    // PREFERENCES / HAPTICS / ACCESSIBILITY / HEALTH SYNC / NOTIFICATIONS /
    // SUPPORT / APP INFO groups were folded into these six when settings moved
    // to flat rows that push to dedicated sub-pages.
    testWidgets('displays TRAINING section', (tester) async {
      await pumpSettings(tester);

      expect(find.text('TRAINING'), findsOneWidget);
      expect(find.text('Workout Settings'), findsOneWidget);
    });

    testWidgets('displays PERSONALIZATION section', (tester) async {
      await pumpSettings(tester);

      expect(find.text('PERSONALIZATION'), findsOneWidget);
      // Theme/appearance and the haptics + notification prefs now live behind
      // rows here instead of in their own top-level sections.
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Sound & Notifs'), findsOneWidget);
    });

    testWidgets('displays CONNECTIONS section', (tester) async {
      await pumpSettings(tester);

      expect(find.text('CONNECTIONS'), findsOneWidget);
      expect(find.text('Health & Devices'), findsOneWidget);
    });

    testWidgets('displays ACCOUNT section', (tester) async {
      await pumpSettings(tester);

      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('displays HELP & SUPPORT section', (tester) async {
      await pumpSettings(tester);

      expect(find.text('HELP & SUPPORT'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
    });

    testWidgets('displays ABOUT section', (tester) async {
      await pumpSettings(tester);

      expect(find.text('ABOUT'), findsOneWidget);
    });

    // The version line reads its number from PackageInfo at runtime (NOT the
    // compile-time `Branding.version` constant the old assertion used), and
    // PackageInfo has no platform channel under `flutter test` — so the widget
    // renders its documented no-version fallback: the brand name alone.
    testWidgets('displays the version line', (tester) async {
      await pumpSettings(tester);

      expect(find.text(Branding.appName), findsOneWidget);
    });

    testWidgets('has scrollable content', (tester) async {
      await pumpSettings(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses SafeArea', (tester) async {
      await pumpSettings(tester);

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('displays Sign Out button', (tester) async {
      await pumpSettings(tester);

      // Scroll down to where the destructive actions live.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
    });

    // REGRESSION (E2E settings row 23): the masthead used to be a bare Row
    // with no background, so scrolled list rows painted visually through
    // "SETTINGS" (readable text/icon-box/divider fragments interleaved with
    // the title glyphs) once the user scrolled at all. The masthead must
    // sit on an opaque container, not just float over the scroll view.
    testWidgets(
        'masthead sits on an opaque background so scrolled rows cannot show through it',
        (tester) async {
      await pumpSettings(tester);

      final container = tester.widget<Container>(
        find.byKey(const Key('settings_masthead_background')),
      );
      expect(container.color, isNotNull);
      expect(container.color, isNot(Colors.transparent));
      expect((container.color as Color).a, greaterThan(0));
    });

    // REGRESSION (E2E settings row 77): `_computeMatchingSections` only ever
    // adds an `_settingsSearchIndex` KEY to the match set — a row's own
    // `sectionKeys` are dead unless one of them is also an index key. "Vacation
    // Mode" and "My Gyms" declare 'vacation'/'gym' among their sectionKeys, but
    // neither was an index key, so searching their own name found nothing.
    testWidgets('search for "vacation" surfaces the Vacation Mode row',
        (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(const ValueKey('search_fab')));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), 'vacation');
      await tester.pumpAndSettle();

      expect(find.text('Vacation Mode'), findsOneWidget);
      expect(find.text('No settings found'), findsNothing);
    });

    testWidgets('search for "gym" surfaces the My Gyms row', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(const ValueKey('search_fab')));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), 'gym');
      await tester.pumpAndSettle();

      expect(find.text('My Gyms'), findsOneWidget);
    });

    // REGRESSION (E2E settings row 78): the floating search FAB is pinned to
    // a fixed screen rectangle (`bottom: bottomPadding + 16`, 56px tall) that
    // used to sit directly over whatever list content the raw scroll offset
    // happened to place there — the Appearance row on load, Sign Out at the
    // list's end — with no reserved clearance. The scrollable viewport must
    // now stop above the FAB's rectangle at every scroll position, not just
    // grow extra padding after the last row.
    testWidgets(
        'the scrollable settings viewport never extends into the floating search control\'s rectangle',
        (tester) async {
      await pumpSettings(tester);

      final scrollAreaRect =
          tester.getRect(find.byKey(const Key('settings_scroll_area')));
      final fabRect =
          tester.getRect(find.byKey(const ValueKey('search_fab')));

      expect(scrollAreaRect.bottom, lessThanOrEqualTo(fabRect.top));
    });

    // REGRESSION (E2E settings row 83): launchUrl returns `false` (does not
    // throw) when there's no handler for a `mailto:` link, so a bare
    // try/catch around it never fires — the "?" help icon and Contact
    // Support silently did nothing. The boolean return value must be
    // checked explicitly and surfaced to the user.
    testWidgets(
        'tapping the help icon shows feedback when no mail handler exists',
        (tester) async {
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _NoHandlerUrlLauncher();
      addTearDown(() => UrlLauncherPlatform.instance = original);

      await pumpSettings(tester);

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not open'), findsOneWidget);
    });

    // REGRESSION (E2E settings row 84): the Health & Devices row's value
    // was a hardcoded platform name ("Apple Health" / "Health Connect")
    // regardless of connection state — in a column where every sibling
    // shows real state ("Off", "Dark", "4 days"), that reads as "connected".
    testWidgets(
        'Health & Devices row shows real connection state, not a bare platform name',
        (tester) async {
      await pumpSettings(tester);

      // Signed-out test session is never connected — must read "Not
      // connected", not "Apple Health"/"Health Connect".
      expect(find.text('Not connected'), findsOneWidget);
    });

    // REGRESSION (E2E settings row 85): the row opening FeatureVotingScreen
    // (real title "Feature Requests", a user voting board of unbuilt
    // requests) used to be labeled "Coming Soon" — copy that promises
    // shipped-soon features, not a wishlist. Row copy must match its
    // destination.
    testWidgets('feature-voting row is labeled to match its destination',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('Feature Requests'), findsOneWidget);
      expect(find.text('Coming Soon'), findsNothing);
    });

    testWidgets('uses correct background in dark mode', (tester) async {
      await pumpSettings(tester, theme: ThemeData.dark());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('uses correct background in light mode', (tester) async {
      await pumpSettings(tester, theme: ThemeData.light());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });
  });
}
