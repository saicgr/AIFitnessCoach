// REGRESSION GATE — E2E 2026-07-28, issue #38.
//
// A deep link to the Score tab (/stats?tab=3, and /stats/readiness which routes
// to initialTab 3) rendered NO Fitness Score card at all: zero height, no
// skeleton, no empty state. Two causes, both fixed:
//
//  1. `ScoresState.fitnessScore` is written only by loadFitnessScore /
//     calculateFitnessScore. The Stats screen's tab-3 loader called only
//     loadPersonalRecords, and the two widgets that self-trigger the fitness
//     load live on the OVERVIEW tab — which a deep link never builds, because
//     TabBarView lazily builds only the current page.
//  2. FitnessScoreCard returned `SizedBox.shrink()` on a null breakdown, so a
//     missing or FAILED load was indistinguishable from "this feature does not
//     exist".
//
// These tests pin the three states the card must render: skeleton while
// loading, the real card once the breakdown lands, and an honest retry state
// when the load failed.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/widgets/skeleton/skeleton.dart';
import 'package:fitwiz/data/models/scores.dart';
import 'package:fitwiz/data/providers/scores_provider.dart';
import 'package:fitwiz/data/repositories/scores_repository.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/stats/widgets/strength_tab.dart';

/// Stands in for the real notifier so the card's three states can be driven
/// without a network layer. `loadFitnessScore` either publishes a breakdown or
/// leaves it null and records an error — exactly what the real one does.
class _FakeScoresNotifier extends ScoresNotifier {
  _FakeScoresNotifier(this._result) : super(_UnusedRepository());

  final FitnessScoreBreakdown? _result;
  int loadCalls = 0;

  @override
  Future<void> loadFitnessScore({String? userId}) async {
    loadCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (_result == null) {
      state = state.copyWith(error: 'Failed to load fitness score: boom');
      return;
    }
    state = state.copyWith(fitnessScore: _result);
  }
}

class _UnusedRepository implements ScoresRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FitnessScoreBreakdown _breakdown() => const FitnessScoreBreakdown(
      fitnessScore: FitnessScoreData(
        userId: 'u1',
        // A real computed score always carries a `calculated_date` — only the
        // backend's un-scored default response leaves it null (see the
        // "never calculated" test below).
        calculatedDate: '2026-08-01',
        strengthScore: 80,
        readinessScore: 65,
        consistencyScore: 70,
        nutritionScore: 60,
        overallFitnessScore: 72,
        fitnessLevel: 'intermediate',
      ),
      levelDescription: 'Solid base',
      levelColor: '#00BCD4',
    );

/// What `GET /scores/fitness` actually returns for an account that has never
/// had a fitness score calculated: NOT a 404, NOT null — a
/// `FitnessScoreBreakdown` with `overall_fitness_score=0`,
/// `fitness_level="beginner"` and `calculated_date` unset (see
/// `backend/api/v1/scores_endpoints.py` `default_score`).
FitnessScoreBreakdown _neverCalculatedBreakdown() => const FitnessScoreBreakdown(
      fitnessScore: FitnessScoreData(
        userId: 'u1',
        calculatedDate: null,
        overallFitnessScore: 0,
        fitnessLevel: 'beginner',
      ),
      breakdown: [],
      levelDescription: 'Starting your fitness journey - focus on consistency.',
      levelColor: '#9E9E9E',
    );

void main() {
  Future<_FakeScoresNotifier> pumpCard(
    WidgetTester tester, {
    required FitnessScoreBreakdown? result,
  }) async {
    final notifier = _FakeScoresNotifier(result);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          scoresProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          localizationsDelegates: <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: <Locale>[Locale('en')],
          home: Scaffold(
            body: FitnessScoreCard(userId: 'u1'),
          ),
        ),
      ),
    );
    return notifier;
  }

  testWidgets('renders a skeleton while the breakdown is loading, never nothing',
      (tester) async {
    await pumpCard(tester, result: _breakdown());
    await tester.pump(); // post-frame callback fires the load

    expect(find.byType(SkeletonBox), findsOneWidget);
    final size = tester.getSize(find.byType(FitnessScoreCard));
    expect(size.height, greaterThan(0),
        reason: 'the card must never collapse to zero height');

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  });

  testWidgets('renders the real card once the breakdown lands', (tester) async {
    await pumpCard(tester, result: _breakdown());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('72'), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('renders an honest retry state when the load fails',
      (tester) async {
    final notifier = await pumpCard(tester, result: null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonBox), findsNothing);
    expect(find.textContaining("couldn't load"), findsOneWidget,
        reason: 'a failed fetch must be visible, not invisible');
    expect(find.text('RETRY'), findsOneWidget);
    expect(tester.getSize(find.byType(FitnessScoreCard)).height,
        greaterThan(0));

    final before = notifier.loadCalls;
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    expect(notifier.loadCalls, before + 1,
        reason: 'the retry affordance must actually retry');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'renders an honest "not scored yet" state for the backend\'s unscored '
      'default — never a fabricated 0/Beginner', (tester) async {
    await pumpCard(tester, result: _neverCalculatedBreakdown());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // The defect: the backend's default response (overall_fitness_score=0,
    // fitness_level="beginner") rendered as if it were a real grade.
    expect(find.text('0'), findsNothing,
        reason: 'a never-scored account must not show a fabricated 0');
    expect(find.text('BEGINNER'), findsNothing,
        reason: 'a never-scored account must not show a fabricated level');
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('Not scored yet'), findsOneWidget);
  });

  testWidgets('the card asks for its own data when nothing primed it',
      (tester) async {
    final notifier = await pumpCard(tester, result: _breakdown());
    await tester.pump();
    expect(notifier.loadCalls, 1,
        reason: 'a deep link that never builds the Overview tab must still '
            'produce a Fitness Score card');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  });
}
