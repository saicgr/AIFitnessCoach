import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitwiz/screens/settings/settings_screen.dart';

void main() {
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

    testWidgets('displays Settings title in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays PREFERENCES section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PREFERENCES'), findsOneWidget);
    });

    testWidgets('displays HAPTICS section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HAPTICS'), findsOneWidget);
    });

    testWidgets('displays ACCESSIBILITY section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACCESSIBILITY'), findsOneWidget);
    });

    testWidgets('displays HEALTH SYNC section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HEALTH SYNC'), findsOneWidget);
    });

    testWidgets('displays NOTIFICATIONS section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
    });

    testWidgets('displays SUPPORT section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUPPORT'), findsOneWidget);
    });

    testWidgets('displays APP INFO section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('APP INFO'), findsOneWidget);
    });

    testWidgets('displays version text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FitWiz v1.0.0'), findsOneWidget);
    });

    testWidgets('has scrollable content', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses SafeArea', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('displays Sign Out button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to see the Sign Out button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('uses correct background in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.dark(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('uses correct background in light mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('app bar is centered', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('app bar has no elevation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, 0);
    });
  });
}
