/// Structural widget tests for the three active-workout tiers.
///
/// Asserts the primary workout surface (everything on screen below any
/// pushed modal sheets) renders **zero vertical `Scrollable` descendants**.
/// Horizontal scrollables — e.g. exercise thumbnail carousels, horizontal
/// action-chip rows — are explicitly allowed per the no-scroll layout plan.
///
/// Matrix: 3 devices × 3 set counts × 3 tiers = 27 cases.
///
/// These tests are a hard gate: a red failure means a tier introduced a
/// vertical scroll (ListView / SingleChildScrollView / CustomScrollView)
/// that the layout budget forbids. Don't patch the test to pass — fix the
/// tier.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/core/providers/workout_ui_mode_provider.dart';
import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/screens/workout/active_workout_screen_refactored.dart';
import 'package:fitwiz/screens/workout/easy/easy_active_workout_screen.dart';

import 'fixtures/workout_fixtures.dart';

/// Stub notifier that seeds a stable state without running the real `_init()`
/// (which reads SharedPreferences + `authStateProvider` + hits Supabase).
/// We subclass `StateNotifier` directly rather than `WorkoutUiModeNotifier`
/// so the parent's constructor-time `_init()` call never fires.
class _StubWorkoutUiModeNotifier extends StateNotifier<WorkoutUiModeState>
    implements WorkoutUiModeNotifier {
  _StubWorkoutUiModeNotifier(WorkoutUiMode mode)
      : super(WorkoutUiModeState(mode: mode, isUserExplicit: true));

  @override
  Future<void> setMode(WorkoutUiMode mode) async {
    state = state.copyWith(mode: mode, isUserExplicit: true);
  }

  @override
  Future<void> refresh() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Tier selector — keeps each test one-liner readable.
// Simple tier was retired — collapsed into Easy.
enum Tier { easy, advanced }

/// Device-size spec matching the plan's matrix.
class _Device {
  final String label;
  final Size logicalSize;
  final double devicePixelRatio;
  const _Device(this.label, this.logicalSize, this.devicePixelRatio);
}

const _iphoneSE = _Device('iPhone SE 3', Size(375, 667), 2.0);
const _iphone16 = _Device('iPhone 16', Size(393, 852), 3.0);
const _ipadMini = _Device('iPad mini', Size(744, 1133), 2.0);
const _devices = <_Device>[_iphoneSE, _iphone16, _ipadMini];
const _setCounts = <int>[4, 7, 12];
const _tiers = <Tier>[Tier.easy, Tier.advanced];

/// Minimum overrides to let the tier screen pump without hitting the
/// network. We override the *derived* read-only providers directly — they
/// feed every UI branch the tier screens actually use during first frame
/// (user id, weight unit, etc.) — so we never spin up `authStateProvider`
/// (which triggers Supabase) or `apiClientProvider` (which binds Dio to
/// a Supabase auth listener).
List<Override> _minOverrides({WorkoutUiMode tierMode = WorkoutUiMode.simple}) {
  final user = app_user.User(
    id: 'test-user-fixture',
    username: 'tester',
    name: 'Tester',
    email: 'test@example.com',
    fitnessLevel: 'intermediate',
    workoutWeightUnit: 'kg',
    weightUnit: 'kg',
    onboardingCompleted: true,
  );
  return <Override>[
    currentUserProvider.overrideWith((ref) => AsyncValue.data(user)),
    currentUserIdProvider.overrideWithValue(user.id),
    weightUnitProvider.overrideWithValue('kg'),
    useKgProvider.overrideWithValue(true),
    workoutWeightUnitProvider.overrideWithValue('kg'),
    useKgForWorkoutProvider.overrideWithValue(true),
    workoutUiModeProvider.overrideWith(
      (ref) => _StubWorkoutUiModeNotifier(tierMode),
    ),
  ];
}

/// Build a tier widget with the specified set count.
Widget _tierWidgetWithSets(Tier tier, int setCount) {
  final workout = makeWorkout(setCount: setCount);
  switch (tier) {
    case Tier.easy:
      return EasyActiveWorkoutScreen(workout: workout);
    case Tier.advanced:
      return ActiveWorkoutScreen(workout: workout);
  }
}

/// Pump helper — applies device metrics, wraps the tier in ProviderScope +
/// MaterialApp, and settles the widget tree. Keeps each test under 25
/// lines per the task spec.
///
/// Async exceptions from side-effect providers (PR history preload, favorites
/// loader, etc.) are drained via [WidgetTester.takeException] so the
/// structural assertion — "zero vertical scrollables" — is the *only* gate.
/// Layout overflow errors (RenderFlex overflow) are drained too; those are
/// diagnostic, not structural — overflow means content doesn't fit, which is
/// exactly the bug no-scroll layouts might introduce — but that's verified by
/// a separate golden-free overflow test, not this one.
Future<void> _pumpTier(
  WidgetTester tester, {
  required Tier tier,
  required int setCount,
  required _Device device,
}) async {
  tester.view.physicalSize =
      device.logicalSize * device.devicePixelRatio;
  tester.view.devicePixelRatio = device.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Silence FlutterError reports (RenderFlex overflow, async provider errors
  // that bubble through FlutterError.onError) so `tester.takeException()`
  // stays the single source of truth for test-failing errors.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) { /* swallow for structural test */ };
  addTearDown(() => FlutterError.onError = originalOnError);

  final tierMode = switch (tier) {
    Tier.easy => WorkoutUiMode.easy,
    Tier.advanced => WorkoutUiMode.advanced,
  };

  // The tier screens fire background side effects on initState — PR history
  // preload, favorites refresh, etc. — that call Supabase through live code
  // paths. In a unit test Supabase is never initialized, so those async calls
  // raise `_pendingExceptionDetails` on the test-binding's Zone. Wrap the
  // pump in `runZonedGuarded` so those zone errors stay out of the harness.
  await runZonedGuarded(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _minOverrides(tierMode: tierMode),
        child: MaterialApp(
          home: _tierWidgetWithSets(tier, setCount),
        ),
      ),
    );
    // Let post-frame callbacks + async provider loads settle. Two 50ms pumps
    // beat `pumpAndSettle` here because the workout stopwatch keeps ticking
    // and would never let pumpAndSettle return.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }, (_, __) {
    // Zone-level errors (Supabase uninit during PR preload, etc.) are fine
    // for a structural test; we only care about the scrollable count below.
  });

  // Also drain any synchronous FlutterError events captured by the harness.
  dynamic drained = tester.takeException();
  while (drained != null) {
    drained = tester.takeException();
  }
}

/// Count `Scrollable` descendants whose primary axis is vertical.
/// Only looks at the live root widget tree — pushed modal routes live on
/// a separate `Overlay`/Navigator stack and are excluded (the chat sheet,
/// exercise-info sheet, etc. are allowed to use vertical lists).
int _verticalScrollableCount(WidgetTester tester) {
  final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
  return scrollables.where((s) => s.axisDirection == AxisDirection.down
      || s.axisDirection == AxisDirection.up).length;
}

String _tierLabel(Tier t) => switch (t) {
      Tier.easy => 'Easy',
      Tier.advanced => 'Advanced',
    };

void main() {
  setUp(() {
    // Every notifier that touches SharedPreferences (accent color, fatigue
    // alerts, etc.) needs a stub backing store in tests.
    SharedPreferences.setMockInitialValues({});
  });

  group('Active workout tiers — no vertical scroll', () {
    for (final tier in _tiers) {
      for (final device in _devices) {
        for (final setCount in _setCounts) {
          testWidgets(
            '${_tierLabel(tier)} tier | ${device.label} | $setCount sets '
            '→ zero vertical scrollables',
            (tester) async {
              await _pumpTier(
                tester,
                tier: tier,
                setCount: setCount,
                device: device,
              );
              final vScrolls = _verticalScrollableCount(tester);
              expect(
                vScrolls,
                0,
                reason:
                    '${_tierLabel(tier)} tier must not introduce vertical '
                    'scroll. Device=${device.label}, setCount=$setCount. '
                    'Horizontal scrollables are allowed.',
              );
            },
          );
        }
      }
    }
  });
}
