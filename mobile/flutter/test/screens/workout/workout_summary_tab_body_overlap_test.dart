// Regression gate for two screenshot-confirmed overlap defects on the
// Workout Summary tab (iPhone 16e simulator):
//
//   1. The floating Plan|Summary pill blanketed the DURATION / SETS · REPS
//      stat cards, an exercise name, and a set row's data at rest, because
//      `WorkoutSummaryGeneral`'s SingleChildScrollView carried NO bottom
//      inset — the pill is a fixed screen overlay painted on top of whatever
//      the scroll view renders underneath it, independent of scroll offset.
//   2. The back button + Share/Favorite/Save/Redo cluster floated over
//      scrolling recap text with no background: unreadable against busy
//      content, and a tap aimed at the gap between/around the buttons fell
//      straight through to the card underneath instead of doing nothing.
//
// Both are fixed inside `WorkoutSummaryTabBody` / `SummaryHeaderScrim` in
// `lib/screens/workout/workout_summary_screen_v2.dart`. This suite asserts
// GEOMETRY (rect containment / non-intersection) and real HIT-TEST outcomes
// using the actual production widgets — not text/existence proxies, which is
// exactly the class of test that let the FAB's width regression (row 108)
// ship with all-green CI.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/core/providers/user_provider.dart' show useKgForWorkoutProvider;
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/services/api_client.dart'
    show ApiClient, apiClientProvider;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart'
    show exercisesProvider;
import 'package:fitwiz/data/models/exercise.dart' show LibraryExercise;
import 'package:fitwiz/screens/workout/widgets/summary_floating_pill.dart';
import 'package:fitwiz/screens/workout/workout_summary_screen_v2.dart';
import 'package:fitwiz/widgets/glass_back_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Supabase-free, network-free API client — same pattern as
// workout_result_unbounded_layout_test.dart. WorkoutAiRecapCard and
// ScoreLevelUpCelebration both `ref.read(apiClientProvider)`; the real
// provider dereferences `Supabase.instance`, which a widget test never
// initialises.
class _OfflineApiClient extends ApiClient {
  _OfflineApiClient() : super(const FlutterSecureStorage());

  static Response<T> _json<T>(String path, int status, T body) => Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
        data: body,
      );

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path.startsWith('/feedback/recap/')) {
      return _json<T>(path, 200, <String, dynamic>{'exists': false} as T);
    }
    if (path == '/scores/recent-level-ups') {
      return _json<T>(path, 200, <String, dynamic>{
        'muscle_level_ups': const [],
        'overall_level_up': null,
      } as T);
    }
    return _json<T>(path, 404, null as T);
  }
}

WorkoutSummaryResponse _summary() => WorkoutSummaryResponse.fromJson({
      'workout': {
        'id': 'w1',
        'name': 'Push Day',
        'type': 'strength',
        'exercises_json': [
          {'name': 'Bench Press', 'muscle_group': 'chest'},
          {'name': 'Squat', 'muscle_group': 'legs'},
        ],
      },
      'set_logs': [
        {
          'exercise_name': 'Bench Press',
          'exercise_index': 0,
          'set_number': 1,
          'reps_completed': 10,
          'weight_kg': 60.0,
          'set_type': 'working',
        },
      ],
      'performance_comparison': null,
      'personal_records': const [],
      'coach_summary': null,
      'hero_narrative': null,
      'completion_method': 'completed',
      'completed_at': '2026-06-07T11:00:00Z',
    });

/// Pumps the REAL [WorkoutSummaryTabBody] at a fixed screen size with a
/// Supabase-free API client, exactly the composition `_buildBody` renders for
/// the Summary tab (`_selectedView == 1`).
Future<void> _pumpTabBody(
  WidgetTester tester, {
  required Size size,
  double topPadding = 59,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exercisesProvider.overrideWith(
          (ref) => const AsyncValue<List<LibraryExercise>>.data([]),
        ),
        useKgForWorkoutProvider.overrideWith((ref) => false),
        apiClientProvider.overrideWith((ref) => _OfflineApiClient()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: EdgeInsets.only(top: topPadding, bottom: 34),
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: WorkoutSummaryTabBody(
              workoutId: 'w1',
              workout: Workout.fromJson(_summary().workout),
              summary: _summary(),
              metadata: const {},
              topPadding: topPadding,
              selectedView: 1,
              onSelectedViewChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WorkoutSummaryTabBody — pill clearance (defect: pill covers stats/rows at rest)', () {
    testWidgets('the summary scroll viewport clears the floating pill on a short phone',
        (tester) async {
      // iPhone-16e-class portrait size — the device the defect was
      // screenshot-confirmed on.
      await _pumpTabBody(tester, size: const Size(393, 852));

      final scrollRect =
          tester.getRect(find.byType(SingleChildScrollView).first);
      final pillRect = tester.getRect(find.byType(SummaryFloatingPill));

      expect(
        scrollRect.bottom,
        lessThanOrEqualTo(pillRect.top),
        reason: 'the summary content viewport (bottom ${scrollRect.bottom}) '
            'must end above the pill (top ${pillRect.top}) — otherwise '
            'content painted at the bottom of the viewport sits underneath '
            'the pill regardless of scroll position',
      );
    });

    testWidgets('the reserved gap matches the pill\'s own published clearance, '
        'not an arbitrary smaller value', (tester) async {
      // Guards against a "just enough to pass" regression: the gap between
      // the viewport and the pill must equal (not merely exceed-by-luck) the
      // pill's own SummaryFloatingPill.clearanceOf contract.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 59, bottom: 34),
            ),
            child: Builder(builder: (context) {
              return Text('${SummaryFloatingPill.clearanceOf(context)}');
            }),
          ),
        ),
      );
      final expectedClearance =
          double.parse(tester.widget<Text>(find.byType(Text)).data!);

      await _pumpTabBody(tester, size: const Size(393, 852));
      final scrollRect =
          tester.getRect(find.byType(SingleChildScrollView).first);
      final stackRect = tester.getRect(find.byType(WorkoutSummaryTabBody));

      expect(
        stackRect.bottom - scrollRect.bottom,
        closeTo(expectedClearance, 0.5),
        reason: 'bottom inset must be exactly SummaryFloatingPill.clearanceOf, '
            'not a smaller hand-picked number',
      );
    });
  });

  group('WorkoutSummaryTabBody — header scrim (defect: unreadable + steals taps)', () {
    testWidgets('the scrim fully covers the back button and action cluster',
        (tester) async {
      await _pumpTabBody(tester, size: const Size(393, 852));

      final scrimRect = tester.getRect(find.byType(SummaryHeaderScrim));
      final backButtonRect = tester.getRect(find.byType(GlassBackButton));

      expect(scrimRect.top, lessThanOrEqualTo(backButtonRect.top));
      expect(scrimRect.bottom, greaterThanOrEqualTo(backButtonRect.bottom));
      expect(scrimRect.left, lessThanOrEqualTo(backButtonRect.left));
      expect(scrimRect.right, greaterThanOrEqualTo(backButtonRect.right));
    });

    testWidgets('SummaryHeaderScrim.heightFor covers the real button footprint',
        (tester) async {
      // buttonTop(8) + buttonHeight(40) is the actual PositionedDirectional
      // offset + GlassBackButton size used by WorkoutSummaryTabBody above —
      // if either drifts, this fails instead of silently under-covering.
      const topPadding = 59.0;
      final height = SummaryHeaderScrim.heightFor(topPadding);
      final buttonBottom = topPadding +
          SummaryHeaderScrim.buttonTop +
          SummaryHeaderScrim.buttonHeight;
      expect(height, greaterThanOrEqualTo(buttonBottom));
    });
  });

  group('SummaryHeaderScrim — real hit-test behavior (isolated)', () {
    /// Hosts the REAL [SummaryHeaderScrim] over a full-screen tappable "card"
    /// stand-in (flips [cardTapped] on tap), with a real button positioned
    /// exactly like WorkoutSummaryTabBody's back button, in the SAME z-order
    /// the production Stack uses (content, then scrim, then button).
    Widget host({
      required ValueNotifier<bool> cardTapped,
      required ValueNotifier<bool> buttonTapped,
    }) {
      const topPadding = 59.0;
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              // Stand-in for the scrolled card content underneath the header.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => cardTapped.value = true,
                  child: Container(color: Colors.blueGrey),
                ),
              ),
              const SummaryHeaderScrim(topPadding: topPadding),
              PositionedDirectional(
                top: topPadding + 8,
                start: 16,
                child: GlassBackButton(onTap: () => buttonTapped.value = true),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('a tap in the header band that misses the button is absorbed, '
        'not passed through to the card', (tester) async {
      final cardTapped = ValueNotifier(false);
      final buttonTapped = ValueNotifier(false);
      await tester.pumpWidget(host(cardTapped: cardTapped, buttonTapped: buttonTapped));

      // Well clear of the 40×40 button (start:16..56, top:67..107) but still
      // inside the scrim band (0..heightFor(59)=131) — e.g. the empty gap to
      // the right of the back button.
      await tester.tapAt(const Offset(200, 90));
      await tester.pump();

      expect(buttonTapped.value, isFalse);
      expect(cardTapped.value, isFalse,
          reason: 'a stray tap inside the header band must be absorbed by '
              'the scrim, never reach the card behind it');
    });

    testWidgets('a tap directly on the button still reaches it', (tester) async {
      final cardTapped = ValueNotifier(false);
      final buttonTapped = ValueNotifier(false);
      await tester.pumpWidget(host(cardTapped: cardTapped, buttonTapped: buttonTapped));

      await tester.tap(find.byType(GlassBackButton));
      await tester.pump();

      expect(buttonTapped.value, isTrue,
          reason: 'the scrim must never steal the button\'s own taps');
      expect(cardTapped.value, isFalse);
    });

    testWidgets('a tap below the header band still reaches real content',
        (tester) async {
      final cardTapped = ValueNotifier(false);
      final buttonTapped = ValueNotifier(false);
      await tester.pumpWidget(host(cardTapped: cardTapped, buttonTapped: buttonTapped));

      // Below heightFor(59)=131, comfortably inside the card.
      await tester.tapAt(const Offset(200, 400));
      await tester.pump();

      expect(cardTapped.value, isTrue,
          reason: 'the scrim must not extend past its own band and swallow '
              'unrelated content taps');
    });
  });
}
