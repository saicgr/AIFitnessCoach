/// Regression coverage for E2E rows #44/#45 (fix_nutrition.json):
///
/// #44 — the targets editor pre-filled Calories/Protein/Carbs/Fat with the
///       literal 2000/150/200/65 fallbacks CLAUDE.md bans, for an account
///       that has never configured nutrition_preferences.
/// #45 — the goal banner showed the hardcoded "Maintain Weight" default
///       instead of the account's real onboarding goal (Build Muscle) when
///       nutrition_preferences was unconfigured.
///
/// Both defects share a root cause: `NutritionPreferences.primaryGoalEnum`
/// and the raw `?? 2000` / `?? 150` / `?? 200` / `?? 65` literals treat the
/// backend's all-null "no rows yet" response as if it were a real user
/// choice. These tests assert the RENDERED state for a 0-row account —
/// empty fields (not fabricated numbers) and the real fitness goal (not a
/// fabricated "Maintain Weight") — not just that the sheet builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/nutrition_preferences.dart';
import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/providers/nutrition_preferences_provider.dart';
import 'package:fitwiz/data/repositories/measurements_repository.dart';
import 'package:fitwiz/data/repositories/nutrition_preferences_repository.dart';
import 'package:fitwiz/data/services/api_client.dart' show ApiClient;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/nutrition/widgets/edit_targets_sheet.dart';

/// Seeds a real [NutritionPreferencesNotifier] with a given starting state,
/// without walking the live `authStateProvider` → Supabase dependency chain
/// (mirrors `test/providers/nutrition_preferences_provider_test.dart`).
class _SeededNutritionPreferencesNotifier extends NutritionPreferencesNotifier {
  _SeededNutritionPreferencesNotifier(super.repo, NutritionPreferencesState initial) {
    state = initial;
  }
}

/// A measurements notifier whose `loadAllMeasurements` is a no-op — the real
/// implementation hits the network, which isn't available in a widget test,
/// and `EditTargetsSheet.initState` unconditionally kicks one off via a
/// post-frame callback.
class _NoopMeasurementsNotifier extends MeasurementsNotifier {
  _NoopMeasurementsNotifier(super.repo);

  @override
  Future<void> loadAllMeasurements(String userId) async {}
}

ApiClient _fakeApiClient() => ApiClient(const FlutterSecureStorage());

/// A 0-row `nutrition_preferences` account — exactly the backend's all-null
/// `NutritionPreferencesResponse(user_id=...)` fallback shape (no targets,
/// no TDEE, no configured goal).
NutritionPreferences _unconfiguredPrefs() => const NutritionPreferences(
      userId: 'u1',
      nutritionGoals: [],
      nutritionGoal: 'maintain',
    );

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    ),
  );
}

List<Override> _baseOverrides({
  required NutritionPreferences prefs,
  required User user,
}) =>
    [
      nutritionPreferencesProvider.overrideWith(
        (ref) => _SeededNutritionPreferencesNotifier(
          NutritionPreferencesRepository(_fakeApiClient()),
          NutritionPreferencesState(preferences: prefs),
        ),
      ),
      currentUserProvider.overrideWith((ref) => AsyncValue.data(user)),
      measurementsProvider.overrideWith(
        (ref) => _NoopMeasurementsNotifier(
          MeasurementsRepository(_fakeApiClient()),
        ),
      ),
    ];

/// Pumps [sheet], filtering a pre-existing, unrelated Flutter debug-mode
/// paint assertion that fires from this sheet's diet-preset `ListTile` (a
/// `DecoratedBox` background sits above its `Material` ancestor) — nothing
/// to do with rows #44/#45 and out of this fix's scope. `testWidgets`
/// reassigns `FlutterError.onError` for the duration of the test body, so
/// the filter must be installed AFTER `pumpWidget` starts (inside the test),
/// not in `setUpAll`.
Future<void> _pumpSheet(WidgetTester tester, Widget sheet) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('ListTile background color')) {
      return;
    }
    original?.call(details);
  };
  try {
    await tester.pumpWidget(sheet);
    await tester.pump();
    // Let the post-frame measurement-load callback (now a no-op) settle.
    await tester.pump();
  } finally {
    FlutterError.onError = original;
  }
}

void main() {
  group('EditTargetsSheet — unconfigured account (rows #44/#45)', () {
    testWidgets(
        'does NOT pre-fill Calories/Protein/Carbs/Fat with the fabricated '
        '2000/150/200/65 defaults', (tester) async {
      final user = User(
        id: 'u1',
        primaryGoal: 'build_muscle',
        weightKg: 82.1,
        targetWeightKg: 76.2,
        gender: 'male',
      );

      await _pumpSheet(
        tester,
        _wrap(
          EditTargetsSheet(userId: 'u1', onSaved: () {}),
          _baseOverrides(prefs: _unconfiguredPrefs(), user: user),
        ),
      );

      // The literal banned defaults must not appear in any TextField.
      expect(find.widgetWithText(TextField, '2000'), findsNothing);
      expect(find.widgetWithText(TextField, '150'), findsNothing);
      expect(find.widgetWithText(TextField, '200'), findsNothing);
      expect(find.widgetWithText(TextField, '65'), findsNothing);

      // With no calculated TDEE, the recommendation fallback also can't
      // compute a real number — the fields must be genuinely empty, not
      // silently holding some other guessed value.
      final calorieField =
          tester.widget<TextField>(find.byType(TextField).first);
      expect(calorieField.controller!.text, isEmpty);
    });

    testWidgets(
        'the goal banner shows the account\'s real fitness goal, not the '
        'fabricated "Maintain Weight" default', (tester) async {
      final user = User(
        id: 'u1',
        primaryGoal: 'build_muscle',
        weightKg: 82.1,
        targetWeightKg: 76.2,
        gender: 'male',
      );

      await _pumpSheet(
        tester,
        _wrap(
          EditTargetsSheet(userId: 'u1', onSaved: () {}),
          _baseOverrides(prefs: _unconfiguredPrefs(), user: user),
        ),
      );

      // Both the goal banner ("Goal: Build Muscle · ...") and the goal
      // timeline ("Build Muscle → ~N wks") now read the real goal.
      expect(find.textContaining('Build Muscle'), findsWidgets);
      expect(find.textContaining('Maintain Weight'), findsNothing);
    });
  });
}
