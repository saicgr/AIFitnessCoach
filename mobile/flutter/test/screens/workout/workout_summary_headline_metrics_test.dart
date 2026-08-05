// Regression gate: the Summary tab's "SETS · REPS" headline stat summarised
// a distance/timed session as "$sets · 0" — a real-looking number ("0 reps")
// for a metric that was never applicable. Reps IS legitimately 0 for a
// distance/timed set (`easy_active_workout_state.dart` deliberately zeroes
// it), so a bare "0" reads as data loss / fabrication, the same class of bug
// as defect 5's exercise-table "Reps 0" cell.
//
// Fixed in `summary_session_totals.dart` (SummarySessionTotals now aggregates
// distanceMeters/timedOnlySeconds too, and broadens its "is this set
// completed" inference beyond reps>0 so a legacy distance/timed set with no
// explicit is_completed flag isn't silently dropped) and
// `summary_hero_stats.dart` (the headline cell shows Sets·Reps only when reps
// is real; otherwise Sets·Distance, Sets·Time, or bare Sets — never a
// fabricated "· 0"). Also verifies MUSCLES WORKED (workout_summary_general.dart)
// agrees with the headline on what "completed" means, per the coherence ask.
//
// Asserts rendered TEXT CONTENT, not widget existence.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/stat_typography.dart' show StatNumber;
import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/core/providers/user_provider.dart' show useKgForWorkoutProvider;
import 'package:fitwiz/data/models/exercise.dart' show LibraryExercise;
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/services/api_client.dart'
    show ApiClient, apiClientProvider;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart'
    show exercisesProvider;
import 'package:fitwiz/screens/workout/widgets/summary_exercise_table.dart'
    show formatSetDistanceMeters, formatSetDurationSeconds;
import 'package:fitwiz/screens/workout/widgets/summary_hero_stats.dart';
import 'package:fitwiz/screens/workout/workout_summary_general.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// The headline number is painted via `StatNumber` (metric_grid.dart), which
// renders through a raw `RichText`/`TextSpan` — NOT a `Text` widget — so
// `find.text(...)` can never match it (it would silently report "not found"
// regardless of whether the real bug is present or fixed, which is exactly
// the kind of proxy assertion this suite exists to avoid). Match on the
// actual `StatNumber.value` the widget was built with instead.
Finder _statValueFinder(String expected) =>
    find.byWidgetPredicate((w) => w is StatNumber && w.value == expected);

/// `MetricCell.label` is rendered `.toUpperCase()` (metric_grid.dart) — match
/// the real on-screen casing rather than the title-case string this test
/// would otherwise write.
Finder _labelFinder(String label) => find.text(label.toUpperCase());

// Supabase-free, network-free API client — same pattern as
// workout_result_unbounded_layout_test.dart. Only needed by the
// WorkoutSummaryGeneral test below (SummaryHeroStats alone doesn't touch it).
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

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        useKgForWorkoutProvider.overrideWith((ref) => false),
        exercisesProvider.overrideWith(
          (ref) => const AsyncValue<List<LibraryExercise>>.data([]),
        ),
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
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

WorkoutSummaryResponse _summary(List<Map<String, dynamic>> setLogs) =>
    WorkoutSummaryResponse.fromJson({
      'workout': {
        'id': 'w1',
        'name': 'Session',
        'type': 'cardio',
        'exercises_json': const [],
      },
      'set_logs': setLogs,
      'performance_comparison': null,
      'personal_records': const [],
      'coach_summary': null,
      'hero_narrative': null,
      'completion_method': 'completed',
      'completed_at': '2026-06-07T11:00:00Z',
    });

void main() {
  group('SummaryHeroStats — no fabricated "· 0" for distance/timed sessions',
      () {
    testWidgets('distance-only session shows Sets · Distance, never "1 · 0"',
        (tester) async {
      await tester.pumpWidget(_wrap(SummaryHeroStats(
        summary: _summary([
          {
            'exercise_name': 'Air Swing Running',
            'set_number': 1,
            'reps_completed': 0,
            'weight_kg': 0.0,
            'distance_meters': 19950.0,
            'is_completed': true,
          },
        ]),
        metadata: const {},
      )));
      await tester.pumpAndSettle();

      expect(_labelFinder('Sets · Distance'), findsOneWidget);
      expect(
          _statValueFinder('1 · ${formatSetDistanceMeters(19950.0)}'),
          findsOneWidget);
      expect(_statValueFinder('1 · 0'), findsNothing,
          reason: '0 reps is not a real number for a distance set');
      expect(_labelFinder('Sets · Reps'), findsNothing);
    });

    testWidgets('timed-only session shows Sets · Time, never "1 · 0"',
        (tester) async {
      await tester.pumpWidget(_wrap(SummaryHeroStats(
        summary: _summary([
          {
            'exercise_name': 'Plank Hold',
            'set_number': 1,
            'reps_completed': 0,
            'weight_kg': 0.0,
            'set_duration_seconds': 90,
            'is_completed': true,
          },
        ]),
        metadata: const {},
      )));
      await tester.pumpAndSettle();

      expect(_labelFinder('Sets · Time'), findsOneWidget);
      expect(_statValueFinder('1 · ${formatSetDurationSeconds(90)}'),
          findsOneWidget);
      expect(_statValueFinder('1 · 0'), findsNothing);
    });

    testWidgets(
        'mixed session (one rep set + one distance set) keeps Sets · Reps '
        'with the TRUE rep count from the rep set', (tester) async {
      await tester.pumpWidget(_wrap(SummaryHeroStats(
        summary: _summary([
          {
            'exercise_name': 'Bench Press',
            'set_number': 1,
            'reps_completed': 10,
            'weight_kg': 60.0,
            'is_completed': true,
          },
          {
            'exercise_name': 'SkiErg',
            'set_number': 1,
            'reps_completed': 0,
            'weight_kg': 0.0,
            'distance_meters': 500.0,
            'is_completed': true,
          },
        ]),
        metadata: const {},
      )));
      await tester.pumpAndSettle();

      expect(_labelFinder('Sets · Reps'), findsOneWidget,
          reason: 'a real rep count exists (10) — showing it is honest, '
              'not a fabrication, even though the session is mixed');
      expect(_statValueFinder('2 · 10'), findsOneWidget);
    });

    testWidgets(
        'a completed set with no reps/distance/duration falls back to a '
        'bare Sets count, never "1 · 0"', (tester) async {
      await tester.pumpWidget(_wrap(SummaryHeroStats(
        summary: _summary([
          {
            'exercise_name': 'Mystery Movement',
            'set_number': 1,
            'reps_completed': 0,
            'weight_kg': 0.0,
            'is_completed': true,
          },
        ]),
        metadata: const {},
      )));
      await tester.pumpAndSettle();

      expect(_labelFinder('Sets'), findsOneWidget);
      expect(_statValueFinder('1'), findsOneWidget);
      expect(_statValueFinder('1 · 0'), findsNothing);
    });

    testWidgets(
        'a legacy distance set with NO explicit is_completed flag still '
        'counts as completed (broadened inference)', (tester) async {
      await tester.pumpWidget(_wrap(SummaryHeroStats(
        summary: _summary([
          {
            'exercise_name': 'Sled Push',
            'set_number': 1,
            'reps_completed': 0,
            'weight_kg': 0.0,
            'distance_meters': 20.0,
            // no 'is_completed' key at all — legacy row.
          },
        ]),
        metadata: const {},
      )));
      await tester.pumpAndSettle();

      expect(_labelFinder('Sets · Distance'), findsOneWidget,
          reason: 'a legacy row with no is_completed flag but a real '
              'distance value must still be recognised as completed, not '
              'silently dropped by a reps>0-only inference');
      expect(_statValueFinder('1 · ${formatSetDistanceMeters(20.0)}'),
          findsOneWidget);
    });
  });

  group('MUSCLES WORKED agrees with the headline on "completed"', () {
    testWidgets(
        'a legacy distance set with no explicit is_completed still counts '
        'toward MUSCLES WORKED, matching the headline', (tester) async {
      final summary = WorkoutSummaryResponse.fromJson({
        'workout': {
          'id': 'w2',
          'name': 'Session',
          'type': 'cardio',
          'exercises_json': [
            {'name': 'Sled Push', 'primary_muscle': 'quads'},
          ],
        },
        'set_logs': [
          {
            'exercise_name': 'Sled Push',
            'set_number': 1,
            'reps_completed': 0,
            'weight_kg': 0.0,
            'distance_meters': 20.0,
            // no is_completed — same legacy-row case as the headline test.
          },
        ],
        'performance_comparison': null,
        'personal_records': const [],
        'coach_summary': null,
        'hero_narrative': null,
        'completion_method': 'completed',
        'completed_at': '2026-06-07T11:00:00Z',
      });

      await tester.pumpWidget(_wrap(WorkoutSummaryGeneral(
        data: summary,
        metadata: const {},
        topPadding: 0,
      )));
      await tester.pumpAndSettle();

      expect(find.text('1 sets'), findsOneWidget,
          reason: 'MUSCLES WORKED must count this legacy distance set as '
              'completed too, agreeing with the headline (previous test) — '
              'not silently drop it via a reps>0-only inference');
    });
  });
}
