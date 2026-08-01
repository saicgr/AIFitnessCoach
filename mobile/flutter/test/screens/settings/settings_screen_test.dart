import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitwiz/core/constants/branding.dart';
import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/settings_screen.dart';

import '../../helpers/fake_supabase.dart';

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
