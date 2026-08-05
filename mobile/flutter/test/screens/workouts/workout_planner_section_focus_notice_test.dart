// Regression gate for defect 2: `WorkoutPlannerSection` used to render an
// "ⓘ Today's workout is done — showing <day>" banner under the day strip
// whenever the carousel's focused day differed from today (most commonly
// because today's workout was already complete and the carousel focus moved
// on to the next actionable day). Product decision: remove the banner
// outright — the day strip directly above already highlights which day is
// selected, so the extra line was noise, not a shared surface any other
// state relies on.
//
// Fix (`workout_planner_section.dart`): `_buildFocusDayNotice()` — and the
// `_weekdayName`/`_weekdayNames` helpers that existed only to feed it — were
// deleted outright, along with its call site in `build()`.
//
// This suite exercises the REAL trigger condition (not a synthetic proxy):
// today's workout is completed, and the user is looking at a different day
// on the strip — exactly the state the reported banner text described.

import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/providers/gym_profile_provider.dart'
    show activeGymProfileProvider;
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workouts/widgets/workout_planner_section.dart';

import '../../helpers/fake_supabase.dart';

/// A signed-in-shaped user with every weekday scheduled, so the date strip
/// renders (it hides itself entirely with no user — see
/// `_buildDateStrip`) and every day in the current week is tappable.
final _fakeUser = User(
  id: 'user-1',
  preferences: jsonEncode({
    'workout_days': [0, 1, 2, 3, 4, 5, 6],
  }),
);

/// Returns the exact workouts list `_repository.getWorkouts` resolves to —
/// this is what the notifier's OWN real async fetch converges to (signed-out
/// resolves the user id to null purely for its early-exit branch; here we
/// hand it a fixed id instead so it takes the real fetch path and lands on
/// data we control, rather than racing an empty `data([])` fallback against
/// our injected state).
class _FixedWorkoutRepository extends WorkoutRepository {
  _FixedWorkoutRepository(super.apiClient, this._workouts);
  final List<Workout> _workouts;

  @override
  Future<List<Workout>> getWorkouts(
    String userId, {
    int? limit,
    int? offset,
    bool allowMultiplePerDate = false,
  }) async {
    return _workouts;
  }
}

class _FixedWorkoutsNotifier extends WorkoutsNotifier {
  _FixedWorkoutsNotifier(Ref ref, List<Workout> workouts)
      : super(
          _FixedWorkoutRepository(ref.watch(apiClientProvider), workouts),
          ref.watch(apiClientProvider),
          'user-1',
        ) {
    state = AsyncValue.data(workouts);
  }
}

String _isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Widget _app({required Workout todayWorkout}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(AsyncValue.data(_fakeUser)),
      activeGymProfileProvider.overrideWith((ref) => null),
      workoutsProvider.overrideWith(
        (ref) => _FixedWorkoutsNotifier(ref, [todayWorkout]),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: WorkoutPlannerSection(),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(initFakeSupabase);

  group('WorkoutPlannerSection — focus-day notice removed', () {
    testWidgets(
        "no banner text appears once the carousel auto-focuses past "
        "today's completed workout", (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayWorkout = Workout(
        id: 'w-today',
        name: 'Completed Session',
        type: 'strength',
        scheduledDate: _isoDate(today),
        isCompleted: true,
      );

      await tester.pumpWidget(_app(todayWorkout: todayWorkout));
      // `HeroWorkoutCarousel` skips a completed today and auto-jumps to the
      // next actionable (placeholder) day via a post-frame callback
      // (`_pickInitialIndex` / `jumpToPage` in hero_workout_carousel.dart) —
      // no tap needed, this is the exact real-world path E2E #151 describes.
      // Bounded pumps, not pumpAndSettle — below-fold loading/shimmer
      // sub-states in this signed-out-shaped environment never fully settle.
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // ignore: avoid_print
      print('ALL TEXTS: ' +
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList().toString());
      // ignore: avoid_print
      print('today=$today weekday=${today.weekday}');
      for (final label in ['Completed Session', 'Thursday', 'Friday']) {
        final f = find.text(label);
        if (f.evaluate().isNotEmpty) {
          // ignore: avoid_print
          print('$label topLeft=${tester.getTopLeft(f.first)}');
        }
      }

      // The two exact message shapes the deleted banner used to render.
      expect(find.textContaining("Today's workout is done"), findsNothing);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            w.data != null &&
            RegExp(r'^Showing (tomorrow|yesterday|[A-Z][a-z]+day)$')
                .hasMatch(w.data!)),
        findsNothing,
        reason: 'the generic "Showing <day>" banner variant must also be '
            'gone — both branches of the deleted `_buildFocusDayNotice` '
            'message are checked',
      );
      // The banner was the only place in this widget using this icon.
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    });
  });
}
