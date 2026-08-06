/// Regression test for Home → STREAKS → "+ Add Habit" (E2E row 6, CRIT).
///
/// Tapping "+ Add Habit" on Home used to push `/habits?addHabit=true`.
/// `HabitsScreen.build()` (lib/screens/habits/habits_screen.dart) reacts to
/// that query param by writing `_autoOpenFiredProvider.notifier.state = true`
/// synchronously inside `build()` — a provider mutation during the build
/// phase — which Riverpod throws on, taking the user to a dead-end error
/// boundary with no back button and no bottom nav.
///
/// `lib/screens/habits/habits_screen.dart` is outside this lane's owned
/// directory (`lib/screens/home/`), so the fix here is at the Home-owned call
/// site: stop sending the crash-triggering query param at all, and route to
/// the same destination the (working) "View all" entry point already uses.
/// This test pins the OUTPUT of that call site — the exact route pushed by
/// go_router when "+ Add Habit" is tapped — so a regression back to
/// `?addHabit=true` fails immediately, without needing to mount the crashing
/// screen itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/data/repositories/hydration_repository.dart';
import 'package:fitwiz/data/repositories/nutrition_repository.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/home/widgets/habits_section.dart';

import '../test_provider_stubs.dart';

class _StubAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _StubAuthNotifier() : super(const AuthState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubDailyNutritionNotifier extends StateNotifier<DailyNutritionState>
    implements DailyNutritionNotifier {
  _StubDailyNutritionNotifier() : super(const DailyNutritionState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHydrationNotifier extends StateNotifier<HydrationState>
    implements HydrationNotifier {
  _StubHydrationNotifier() : super(const HydrationState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      '"+ Add Habit" pushes the plain /habits route, never the '
      '?addHabit=true route that crashes HabitsScreen.build()',
      (tester) async {
    final pushedLocations = <String>[];
    // Full URI (including query params) the destination route actually
    // matched on — `NavigatorObserver.didPush`'s `route.settings.name` does
    // NOT reliably carry go_router's query string, so the query-sensitive
    // assertion is made off `GoRouterState.uri` captured from inside the
    // destination route's own builder instead.
    final matchedUris = <String>[];

    final router = GoRouter(
      initialLocation: '/home',
      observers: [
        _RecordingNavigatorObserver(onPush: pushedLocations.add),
      ],
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: HabitsSection()),
        ),
        // Stand-in destination — the real HabitsScreen is out of this
        // lane's scope and is exactly the screen that crashes on
        // ?addHabit=true; this test only needs to prove which URL Home
        // pushes, not render the destination.
        GoRoute(
          path: '/habits',
          builder: (context, state) {
            matchedUris.add(state.uri.toString());
            return const Scaffold(body: Text('habits destination'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _StubAuthNotifier()),
          workoutsProvider.overrideWith(
              (ref) => StubWorkoutsNotifier(const AsyncValue.data([]))),
          dailyNutritionProvider(todayNutritionKey())
              .overrideWith((ref) => _StubDailyNutritionNotifier()),
          hydrationProvider.overrideWith((ref) => _StubHydrationNotifier()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Habit'), findsOneWidget,
        reason: 'the "+ Add Habit" row must render for this test to tap it');

    await tester.tap(find.text('Add Habit'));
    await tester.pumpAndSettle();

    expect(pushedLocations, isNotEmpty,
        reason: 'tapping "+ Add Habit" must push a route');
    expect(matchedUris, isNotEmpty,
        reason: 'the /habits destination route must have been reached');
    final lastUri = matchedUris.last;
    expect(lastUri, '/habits',
        reason: 'must route to the plain /habits screen (same destination '
            'as "View all"), never ?addHabit=true — that query param is '
            'what HabitsScreen.build() crashes on');
    expect(lastUri.contains('addHabit'), isFalse,
        reason: 'the addHabit query param must never be sent from Home — '
            'it triggers a build()-phase provider mutation that Riverpod '
            'throws on, landing the user on a dead-end error screen');

    // The stand-in destination actually rendered — i.e. no crash occurred.
    expect(find.text('habits destination'), findsOneWidget);
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  _RecordingNavigatorObserver({required this.onPush});
  final void Function(String) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) onPush(name);
    super.didPush(route, previousRoute);
  }
}
