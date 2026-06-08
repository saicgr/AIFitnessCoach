// Regression gate for the unbounded-height white-screen class on the
// workout-result screens (see plan: "Kill the unbounded-height white-screen
// class on workout-result screens").
//
// Production 1.2.67 white-screened on /workout-complete and /workout-summary/:id
// with "BoxConstraints forces an infinite height" — a section inside the
// result screen's SingleChildScrollView demanded infinite height during the
// layout phase, the layout threw, and the whole route painted blank.
//
// This harness renders the real public result widgets at production-faithful
// sizes (the SingleChildScrollView hands its children unbounded height exactly
// as it does on device) across a data matrix (every conditional section) and a
// render matrix (SE↔tablet width, textScaler 2.0, RTL, dark/light), and asserts
// `tester.takeException()` is null. A layout-phase throw IS surfaced through
// takeException by the test binding, so any reintroduced unbounded child fails
// CI before it ships.
//
// NOTE: these are PUBLIC composition widgets — the private sections
// (_SessionScoreRings, _SessionTimelineAndHeatmap, _PyramidExerciseCard, …) are
// exercised transitively by feeding metadata/data that makes each render.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/data/models/exercise.dart' show LibraryExercise;
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/library/providers/library_providers.dart'
    show exercisesProvider;
import 'package:fitwiz/screens/workout/workout_summary_advanced.dart';
import 'package:fitwiz/screens/workout/workout_summary_general.dart';

// ───────────────────────── render matrix ─────────────────────────

class _RenderCase {
  final String label;
  final Size size;
  final double textScale;
  final Brightness brightness;
  final TextDirection direction;

  /// When true, only the catastrophic WHITE-SCREEN class (infinite-height /
  /// not-laid-out) fails the test; a horizontal overflow is tolerated. Used for
  /// the extreme 200%-text case, where eliminating every overflow on dense data
  /// tables is a separate responsive pass — but the screen must still never
  /// white-screen (the bug this gate exists for).
  final bool crashOnly;

  const _RenderCase(
    this.label,
    this.size,
    this.textScale,
    this.brightness,
    this.direction, {
    this.crashOnly = false,
  });
}

// Width is the axis that matters for the wrap/flex math; height is generous so
// nothing is artificially clipped. We cover the smallest phone, a normal phone,
// and a tablet; realistic text scales (1.0 + 1.3); both themes; LTR + RTL. The
// 200%-text case is crash-only (see _RenderCase.crashOnly).
const _renderCases = <_RenderCase>[
  _RenderCase('se-320', Size(320, 3200), 1.0, Brightness.dark, TextDirection.ltr),
  _RenderCase('phone-430', Size(430, 2800), 1.0, Brightness.light, TextDirection.ltr),
  _RenderCase('tablet-834', Size(834, 2800), 1.0, Brightness.dark, TextDirection.ltr),
  _RenderCase('phone-430-rtl', Size(430, 2800), 1.0, Brightness.light, TextDirection.rtl),
  _RenderCase('se-320-text1_3', Size(320, 4000), 1.3, Brightness.light, TextDirection.ltr),
  _RenderCase('se-320-text2x', Size(320, 5200), 2.0, Brightness.dark, TextDirection.ltr, crashOnly: true),
];

// Substrings that identify the catastrophic white-screen layout class (as
// opposed to a benign horizontal overflow).
const _whiteScreenMarkers = <String>[
  'forces an infinite',
  'was not laid out',
  'hasSize',
  'non-zero flex but incoming',
];

/// Assert the just-pumped frame did not hit the white-screen layout class. At
/// realistic text scales (!crashOnly) any exception — including overflow — fails.
void _expectNoLayoutFailure(WidgetTester tester, _RenderCase rc, String what) {
  final ex = tester.takeException();
  if (ex == null) return;
  final msg = ex.toString();
  final isWhiteScreen = _whiteScreenMarkers.any(msg.contains);
  if (rc.crashOnly && !isWhiteScreen) {
    return; // tolerate overflow at 200% text — documented follow-up.
  }
  fail('$what at "${rc.label}" threw: $msg');
}

Future<void> _pumpResult(
  WidgetTester tester,
  Widget child,
  _RenderCase rc,
) async {
  tester.view.physicalSize = rc.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Deterministic: the muscle-heatmap section watches this; give it an
        // empty resolved catalog so it never hits cache/network in tests.
        exercisesProvider.overrideWith(
          (ref) => const AsyncValue<List<LibraryExercise>>.data([]),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        themeMode:
            rc.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        locale: rc.direction == TextDirection.rtl
            ? const Locale('ar')
            : const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: rc.size,
            textScaler: TextScaler.linear(rc.textScale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ───────────────────────── data fixtures ─────────────────────────

/// A rich set_logs entry. Override any field via [over].
Map<String, dynamic> _set({
  String name = 'Bench Press',
  int index = 0,
  int setNumber = 1,
  int reps = 10,
  double weightKg = 60,
  double? rpe = 8,
  int? rir = 2,
  String setType = 'working',
}) =>
    {
      'exercise_name': name,
      'exercise_index': index,
      'set_number': setNumber,
      'reps_completed': reps,
      'weight_kg': weightKg,
      'rpe': rpe,
      'rir': rir,
      'set_type': setType,
      'rest_duration_seconds': 90,
      'set_duration_seconds': 40,
      'target_reps': reps,
      'target_weight_kg': weightKg,
    };

List<Map<String, dynamic>> _richSetLogs() => [
      _set(name: 'Bench Press', index: 0, setNumber: 1, weightKg: 60),
      _set(name: 'Bench Press', index: 0, setNumber: 2, weightKg: 62.5),
      _set(name: 'Bench Press', index: 0, setNumber: 3, weightKg: 65, setType: 'failure'),
      _set(name: 'Squat', index: 1, setNumber: 1, weightKg: 100, reps: 5),
      _set(name: 'Squat', index: 1, setNumber: 2, weightKg: 100, reps: 5),
      _set(name: 'Lat Pulldown', index: 2, setNumber: 1, weightKg: 50, reps: 12, setType: 'warmup'),
    ];

Map<String, dynamic> _performanceComparison({bool hasPrevious = true}) => {
      'workout_comparison': {
        'current_duration_seconds': 3600,
        'current_total_volume_kg': 5400,
        'current_total_sets': 12,
        'current_total_reps': 96,
        'current_exercises': 3,
        'current_calories': 320,
        'has_previous': hasPrevious,
        if (hasPrevious) ...{
          'previous_duration_seconds': 3400,
          'previous_total_volume_kg': 5000,
          'previous_total_sets': 11,
          'previous_total_reps': 90,
          'previous_performed_at': '2026-06-01T10:00:00Z',
          'duration_diff_seconds': 200,
          'duration_diff_percent': 5.8,
          'volume_diff_kg': 400,
          'volume_diff_percent': 8.0,
        },
        'overall_status': hasPrevious ? 'improved' : 'first_time',
      },
      'exercise_comparisons': const [],
      'improved_count': 2,
      'maintained_count': 1,
      'declined_count': 0,
      'first_time_count': 0,
    };

List<Map<String, dynamic>> _personalRecords() => [
      {
        'exercise_name': 'Bench Press',
        'weight_kg': 65,
        'reps': 3,
        'estimated_1rm_kg': 71,
        'previous_1rm_kg': 68,
        'improvement_kg': 3,
        'improvement_percent': 4.4,
        'is_all_time_pr': true,
        'celebration_message': 'New all-time bench PR!',
      },
    ];

/// Full, every-section-on metadata blob.
Map<String, dynamic> _richMetadata() => {
      'sets_json': _richSetLogs(),
      'supersets': [
        {
          'group_id': 'g1',
          'exercises': [
            {'name': 'Bench Press', 'muscle_group': 'chest'},
            {'name': 'Lat Pulldown', 'muscle_group': 'back'},
          ],
        },
      ],
      'exercise_order': [
        {'exercise_name': 'Bench Press', 'order': 1},
        {'exercise_name': 'Squat', 'order': 2},
        {'exercise_name': 'Lat Pulldown', 'order': 3},
      ],
      'quit_early': false,
      'warmup_exercises': [
        {'name': 'Arm circles', 'duration_seconds': 30},
        {'name': 'Band pull-aparts', 'duration_seconds': 60},
      ],
      'warmup_status': 'completed',
      'stretch_exercises': [
        {'name': 'Chest stretch', 'duration_seconds': 30},
      ],
      'stretch_status': 'completed',
      'rest_intervals': [
        {'rest_type': 'between_sets', 'rest_seconds': 90, 'exercise_name': 'Bench Press', 'set_number': 1},
        {'rest_type': 'between_exercises', 'rest_seconds': 180, 'exercise_name': 'Squat', 'set_number': 1},
      ],
      'drink_events': [
        {'amount_ml': 250, 'drink_type': 'water', 'exercise_name': 'Bench Press', 'after_set': 2, 'logged_at': '2026-06-07T10:10:00Z'},
      ],
      'drink_intake_ml': 250,
      'ai_interactions': {
        'weight_suggestions_shown': 2,
        'weight_suggestions_accepted': 1,
        'coach_opened': 3,
        'chat_messages_sent': 2,
        'coach_tips_shown': 4,
        'coach_tips_dismissed': 1,
        'fatigue_alerts_triggered': 0,
        'rest_suggestions_shown': 1,
        'exercise_info_opened': 2,
        'video_views': 1,
      },
      'subjective_feedback': {
        'mood_after': 5,
        'energy_after': 4,
        'confidence_level': 5,
        'feeling_stronger': true,
      },
      'increment_settings': {
        'unit': 'lbs',
        'dumbbell': 5,
        'barbell': 10,
        'machine': 10,
        'kettlebell': 5,
        'cable': 5,
      },
    };

WorkoutSummaryResponse _summary({
  List<Map<String, dynamic>> setLogs = const [],
  Map<String, dynamic>? performanceComparison,
  List<Map<String, dynamic>> personalRecords = const [],
  String? coachSummary = 'Great session — you out-volumed last week and hit a bench PR.',
  String? heroNarrative = 'Bench PR + 8% more volume than last time. Momentum is real.',
  String? completionMethod = 'completed',
  Map<String, dynamic>? workout,
  double? distanceMeters,
  int? avgHrBpm,
}) =>
    WorkoutSummaryResponse.fromJson({
      'workout': workout ??
          {
            'id': 'w1',
            'name': 'Push Day',
            'type': 'strength',
            'exercises_json': [
              {'name': 'Bench Press', 'muscle_group': 'chest'},
              {'name': 'Squat', 'muscle_group': 'legs'},
              {'name': 'Lat Pulldown', 'muscle_group': 'back'},
            ],
          },
      'set_logs': setLogs,
      'performance_comparison': performanceComparison,
      'personal_records': personalRecords,
      'coach_summary': coachSummary,
      'hero_narrative': heroNarrative,
      'completion_method': completionMethod,
      'completed_at': '2026-06-07T11:00:00Z',
      'distance_meters': distanceMeters,
      'avg_hr_bpm': avgHrBpm,
    });

class _Fixture {
  final String label;
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  const _Fixture(this.label, this.data, this.metadata);
}

/// The data matrix — each entry exercises a distinct branch / degenerate shape.
List<_Fixture> _fixtures() => [
      _Fixture('full-rich',
          _summary(
            setLogs: _richSetLogs(),
            performanceComparison: _performanceComparison(),
            personalRecords: _personalRecords(),
          ),
          _richMetadata()),
      _Fixture('metadata-null',
          _summary(setLogs: _richSetLogs(), performanceComparison: _performanceComparison()),
          null),
      _Fixture('metadata-empty',
          _summary(setLogs: _richSetLogs(), performanceComparison: _performanceComparison()),
          const {}),
      _Fixture('setlogs-empty', _summary(setLogs: const []), _richMetadata()),
      _Fixture('quit-early',
          _summary(setLogs: _richSetLogs().take(2).toList(), completionMethod: 'quit_early'),
          {..._richMetadata(), 'quit_early': true, 'sets_json': _richSetLogs().take(2).toList()}),
      _Fixture('marked-done-empty',
          _summary(setLogs: const [], coachSummary: null, heroNarrative: null, completionMethod: 'marked_done'),
          null),
      _Fixture('bodyweight-only',
          _summary(setLogs: [
            _set(name: 'Push-up', weightKg: 0, reps: 20, rpe: null, rir: null),
            _set(name: 'Pull-up', index: 1, weightKg: 0, reps: 12, rpe: null, rir: null),
          ]),
          {'sets_json': [
            _set(name: 'Push-up', weightKg: 0, reps: 20, rpe: null, rir: null),
            _set(name: 'Pull-up', index: 1, weightKg: 0, reps: 12, rpe: null, rir: null),
          ]}),
      _Fixture('single-set', _summary(setLogs: [_set()]), {'sets_json': [_set()]}),
      _Fixture('no-previous',
          _summary(setLogs: _richSetLogs(), performanceComparison: _performanceComparison(hasPrevious: false)),
          _richMetadata()),
      _Fixture('no-rpe-rir',
          _summary(setLogs: [
            _set(rpe: null, rir: null),
            _set(setNumber: 2, rpe: null, rir: null),
          ]),
          {'sets_json': [_set(rpe: null, rir: null)]}),
      _Fixture('null-narrative',
          _summary(setLogs: _richSetLogs(), coachSummary: null, heroNarrative: null),
          _richMetadata()),
      _Fixture('warmup-skipped-stretch-absent',
          _summary(setLogs: _richSetLogs()),
          {'sets_json': _richSetLogs(), 'warmup_status': 'skipped', 'warmup_exercises': const [], 'stretch_status': null}),
      _Fixture('feedback-partial',
          _summary(setLogs: _richSetLogs()),
          {'sets_json': _richSetLogs(), 'subjective_feedback': {'mood_after': 3}}),
      // Legacy superset shape: exercises as plain name strings (not maps).
      // Must NOT crash the Advanced tab (was a hard `.cast<Map>()`).
      _Fixture('superset-legacy-strings',
          _summary(setLogs: _richSetLogs()),
          {'sets_json': _richSetLogs(), 'supersets': [
            {'group_id': '1', 'exercises': ['Bench Press', 'Lat Pulldown']},
          ]}),
      _Fixture('huge-count',
          _summary(setLogs: List.generate(40, (i) => _set(name: 'Exercise ${i ~/ 4}', index: i ~/ 4, setNumber: i % 4 + 1, weightKg: 20.0 + i))),
          {'sets_json': List.generate(40, (i) => _set(name: 'Exercise ${i ~/ 4}', index: i ~/ 4, setNumber: i % 4 + 1, weightKg: 20.0 + i))}),
      _Fixture('no-plan-workout',
          _summary(setLogs: _richSetLogs(), workout: {'id': 'w2', 'name': 'Freestyle', 'type': 'strength', 'exercises_json': null}),
          {'sets_json': _richSetLogs()}),
      _Fixture('cardio-session',
          _summary(setLogs: const [], distanceMeters: 5000, avgHrBpm: 145, coachSummary: 'Solid 5k.'),
          {'distance_meters': 5000, 'avg_hr_bpm': 145}),
    ];

void main() {
  group('Workout result screens never force infinite height', () {
    for (final f in _fixtures()) {
      for (final rc in _renderCases) {
        testWidgets('Advanced · ${f.label} · ${rc.label}', (tester) async {
          await _pumpResult(
            tester,
            WorkoutSummaryAdvanced(data: f.data, metadata: f.metadata, topPadding: 0),
            rc,
          );
          _expectNoLayoutFailure(
              tester, rc, 'WorkoutSummaryAdvanced · ${f.label}');
        });

        testWidgets('General · ${f.label} · ${rc.label}', (tester) async {
          await _pumpResult(
            tester,
            WorkoutSummaryGeneral(
              data: f.data,
              metadata: f.metadata,
              topPadding: 0,
            ),
            rc,
          );
          _expectNoLayoutFailure(
              tester, rc, 'WorkoutSummaryGeneral · ${f.label}');
        });
      }
    }
  });
}
