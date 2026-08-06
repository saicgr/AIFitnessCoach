import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/providers/gym_profile_provider.dart';
import 'package:fitwiz/screens/library/library_screen.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import '../../helpers/fake_supabase.dart';

/// The Discover tab ranks split presets against the active gym profile, which
/// (unoverridden) walks `gymProfilesProvider` → Supabase. Widget tests have no
/// initialized Supabase instance, so pin the profile to "none" — the ranking
/// provider then returns its beginner-friendly defaults with no network reach.
Widget _app({
  ThemeData? theme,
  String? initialCategory,
  String? initialSearch,
}) {
  return ProviderScope(
    overrides: [
      activeGymProfileProvider.overrideWith((ref) => null),
      if (initialSearch != null)
        exerciseSearchProvider.overrideWith((ref) => initialSearch),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      home: LibraryScreen(initialCategory: initialCategory),
    ),
  );
}

void main() {
  // The non-Discover tabs resolve their data through providers that read
  // Supabase.instance; give them the signed-out offline singleton.
  setUpAll(initFakeSupabase);

  group('LibraryScreen', () {
    testWidgets('renders header and tabs', (WidgetTester tester) async {
      await tester.pumpWidget(_app());

      // Wait for initial load + entry animations (flutter_animate schedules
      // timers the test binding asserts on at teardown).
      await tester.pumpAndSettle();

      // Header title renders upper-cased in the signature display face.
      expect(find.text('LIBRARY'), findsOneWidget);

      // Tab pills (also upper-cased).
      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.text('EXERCISES'), findsOneWidget);
      expect(find.text('WORKOUTS'), findsOneWidget);
      expect(find.text('CUSTOM'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
    });

    testWidgets('can switch between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(_app());

      await tester.pumpAndSettle();

      // Signed out + offline, the data tabs sit in their loading skeletons,
      // whose shimmer never stops — so drive fixed frames past the 200 ms tab
      // transition rather than pumpAndSettle()-ing on an endless animation.
      Future<void> settleTab() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      await tester.tap(find.text('WORKOUTS'));
      await settleTab();
      expect(find.text('WORKOUTS'), findsOneWidget);

      await tester.tap(find.text('YOU'));
      await settleTab();
      expect(find.text('YOU'), findsOneWidget);

      await tester.tap(find.text('EXERCISES'));
      await settleTab();
      expect(find.text('EXERCISES'), findsOneWidget);

      // Tear the screen down so the loading tabs' outstanding timers are
      // cancelled before the binding's end-of-test !timersPending check.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('displays correctly in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(_app(theme: ThemeData.dark()));

      await tester.pumpAndSettle();

      expect(find.text('LIBRARY'), findsOneWidget);
      expect(find.text('EXERCISES'), findsOneWidget);
    });

    testWidgets('displays correctly in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(_app(theme: ThemeData.light()));

      await tester.pumpAndSettle();

      expect(find.text('LIBRARY'), findsOneWidget);
      expect(find.text('EXERCISES'), findsOneWidget);
    });
  });

  group('LibraryScreen — search field (E2E row 96)', () {
    testWidgets(
      'clear (X) icon appears only once there is text, and clears the field',
      (WidgetTester tester) async {
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close_rounded), findsNothing);

        await tester.enterText(find.byType(TextField), 'Hay Bale');
        await tester.pump();

        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();

        expect(find.byIcon(Icons.close_rounded), findsNothing);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, isEmpty);
      },
    );

    testWidgets(
      'a Discover category deep-link clears a leftover search query instead '
      'of silently ANDing it with the new filter',
      (WidgetTester tester) async {
        final container = ProviderContainer(overrides: [
          activeGymProfileProvider.overrideWith((ref) => null),
          exerciseSearchProvider.overrideWith((ref) => 'Hay Bale'),
        ]);
        addTearDown(container.dispose);

        expect(container.read(exerciseSearchProvider), 'Hay Bale');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LibraryScreen(initialCategory: 'strength'),
            ),
          ),
        );
        // The deep-link fires from a post-frame callback in initState.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          container.read(exerciseSearchProvider),
          isEmpty,
          reason: 'switching to a category filter must drop the stale '
              'search text, not silently AND it with the new filter',
        );
        expect(
          container.read(selectedCategoriesProvider),
          {'strength'},
        );

        // Tear the screen down so the in-flight network-provider timers
        // (filter-options, category-exercises — this harness has no live
        // backend) are cancelled before the binding's end-of-test check.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
