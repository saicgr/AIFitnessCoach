import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/providers/favorites_provider.dart';
import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/repositories/exercise_preferences_repository.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart';
import 'package:fitwiz/screens/library/tabs/my_library_tab.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import '../../../helpers/fake_supabase.dart';

/// A [FavoritesNotifier] stand-in that seeds a fixed favorites list without
/// touching the network — the real notifier's constructor kicks off an async
/// `refresh()` against `apiClientProvider` that a signed-out widget test
/// can't (and shouldn't need to) satisfy.
class _FakeFavoritesNotifier extends FavoritesNotifier {
  _FakeFavoritesNotifier(super.ref, List<FavoriteExercise> seed) {
    state = FavoritesState(favorites: seed);
  }

  @override
  Future<void> refresh() async {}
}

Widget _app({
  required List<FavoriteExercise> favorites,
  required List<ExerciseHistoryItem> history,
  bool useKgForWorkout = false,
}) {
  return ProviderScope(
    overrides: [
      favoritesProvider.overrideWith(
        (ref) => _FakeFavoritesNotifier(ref, favorites),
      ),
      // The full-catalog cross-reference deliberately finds nothing, mirroring
      // the real bug: `categoryExercisesProvider` only holds a 20-per-body-part
      // grouped slice, so a favorited exercise is very often absent from it.
      categoryExercisesProvider.overrideWith(
        (ref) async => const CategoryExercisesData(preview: {}, all: {}),
      ),
      exerciseHistoryProvider.overrideWith((ref) async => history),
      useKgForWorkoutProvider.overrideWithValue(useKgForWorkout),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MyLibraryTab()),
    ),
  );
}

/// The Recent Activity section sits below Custom Exercises + Favorites +
/// Staples, past the default 800x600 test surface — a plain `ListView`
/// still mounts those widgets, but `find.text`'s default `skipOffstage:true`
/// excludes anything outside the current viewport. Give the surface enough
/// height that everything is actually on-stage instead of loosening every
/// assertion with `skipOffstage: false`.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(initFakeSupabase);

  group('MyLibraryTab — Favorites section', () {
    testWidgets(
      'shows the favorited exercise instead of the empty state when the '
      'catalog cross-reference misses it (regression for the '
      'Favorites (1) / "nothing here yet" contradiction)',
      (WidgetTester tester) async {
        _useTallViewport(tester);
        await tester.pumpWidget(_app(
          favorites: [
            FavoriteExercise(
              id: 'fav-1',
              exerciseName: 'Shoulder Abduction',
              addedAt: DateTime(2026, 1, 1),
            ),
          ],
          history: const [],
        ));
        await tester.pumpAndSettle();

        // Header count is honest...
        expect(find.text('Favorites (1)'), findsOneWidget);
        // ...and the body must NOT contradict it with the empty state.
        expect(find.text('Heart exercises to save them here'), findsNothing);
        // The favorited exercise itself must be reachable somewhere on screen.
        expect(find.text('Shoulder Abduction'), findsOneWidget);
      },
    );

    testWidgets('empty state renders when there truly are no favorites',
        (WidgetTester tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_app(favorites: const [], history: const []));
      await tester.pumpAndSettle();

      expect(find.text('Favorites (0)'), findsOneWidget);
      expect(find.text('Heart exercises to save them here'), findsOneWidget);
    });
  });

  group('MyLibraryTab — Recent Activity card', () {
    testWidgets(
      'does not fabricate "Best: 0kg x 0" for an exercise with no logged '
      'weight/reps (e.g. a stretch)',
      (WidgetTester tester) async {
        _useTallViewport(tester);
        await tester.pumpWidget(_app(
          favorites: const [],
          history: [
            ExerciseHistoryItem(
              exerciseName: 'Side Lying Floor Stretch',
              totalSets: 3,
              maxWeight: 0,
              maxReps: 0,
              lastWorkoutDate: DateTime.now().toIso8601String(),
            ),
          ],
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('Best:'), findsNothing);
      },
    );

    testWidgets(
      'renders a real weight in the user\'s workout-weight unit (lbs), '
      'never a hard-coded "kg"',
      (WidgetTester tester) async {
        _useTallViewport(tester);
        await tester.pumpWidget(_app(
          favorites: const [],
          history: [
            ExerciseHistoryItem(
              exerciseName: 'Barbell Bench Press',
              totalSets: 4,
              maxWeight: 61.2, // ~135 lb, stored in kg
              maxReps: 8,
              lastWorkoutDate: DateTime.now().toIso8601String(),
            ),
          ],
          useKgForWorkout: false,
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('Best:'), findsOneWidget);
        expect(find.textContaining('kg'), findsNothing);
        expect(find.textContaining('lb'), findsOneWidget);
      },
    );
  });
}
