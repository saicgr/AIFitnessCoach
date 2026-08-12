/// R6 — the contextual card stack is ranked and capped.
///
/// Regression gate for the failure mode that punished both competitors: an
/// unbounded stack of self-collapsing cards that grows on a busy day because
/// nothing ever decided how many were too many. These tests pin the four
/// properties that make the cap trustworthy:
///
///   1. more eligible cards than the cap → exactly cap-many render,
///   2. the highest-ranked cards win, identically on every rebuild,
///   3. suppression is surfaced ("N more"), never silent,
///   4. a dismissed card frees its slot for the next-ranked card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/home/providers/contextual_card_rank_provider.dart';
import 'package:fitwiz/screens/home/widgets/extended_home_cards_stack.dart';

/// A synthetic manifest for the pure-ranking tests, so those assertions test
/// the ALGORITHM rather than restating today's product priorities (which are
/// allowed to change without this file failing).
const _fakeManifest = <ContextualCardSpec>[
  ContextualCardSpec(id: 'a_low', priority: 100, category: ContextualCardCategory.activity),
  ContextualCardSpec(id: 'a_high', priority: 900, category: ContextualCardCategory.activity),
  ContextualCardSpec(id: 'a_mid', priority: 500, category: ContextualCardCategory.activity),
  ContextualCardSpec(id: 'p_high', priority: 800, category: ContextualCardCategory.plan),
  ContextualCardSpec(id: 'p_mid', priority: 600, category: ContextualCardCategory.plan),
  ContextualCardSpec(id: 'p_low', priority: 200, category: ContextualCardCategory.plan),
  ContextualCardSpec(id: 's_high', priority: 700, category: ContextualCardCategory.social),
  ContextualCardSpec(id: 's_low', priority: 300, category: ContextualCardCategory.social),
  // Same priority as p_mid — earlier manifest index must win the tiebreak.
  ContextualCardSpec(id: 'f_tie', priority: 600, category: ContextualCardCategory.fasting),
];

const _allFakeIds = <String>{
  'a_low', 'a_high', 'a_mid', 'p_high', 'p_mid', 'p_low', 's_high', 's_low', 'f_tie',
};

ContextualCardPlan _plan({
  Set<String> eligible = _allFakeIds,
  Set<String> dismissed = const <String>{},
  int cap = 5,
  int maxPerCategory = 2,
  bool showAll = false,
}) {
  return planContextualCards(
    eligible: eligible,
    dismissed: dismissed,
    manifest: _fakeManifest,
    cap: cap,
    maxPerCategory: maxPerCategory,
    showAll: showAll,
  );
}

// ── Widget-level harness ─────────────────────────────────────────────────────

/// Real manifest ids spanning four categories, chosen so the per-category rule
/// and the global cap both bite. Ranked (priority desc):
///   injury_workaround   900  plan
///   plan_adjustments    740  plan
///   return_to_exercise  730  plan       ← blocked: plan already has 2
///   fast_zone_strip     705  fasting
///   weigh_in_day        530  milestone
///   stand_reminder      510  activity   ← 5th and final slot
///   macro_pattern       310  patterns   ← over cap
///   step_streak         220  activity   ← over cap
const _widgetIds = <String>[
  ContextualCardIds.injuryWorkaround,
  ContextualCardIds.planAdjustments,
  ContextualCardIds.returnToExercise,
  ContextualCardIds.fastZoneStrip,
  ContextualCardIds.weighInDay,
  ContextualCardIds.standReminder,
  ContextualCardIds.macroPatternCallout,
  ContextualCardIds.stepStreak,
];

Widget _harness(ValueNotifier<Set<String>> gatesFiring) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: gatesFiring,
            builder: (context, firing, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final id in _widgetIds)
                    ContextualCardSlot(
                      key: ValueKey('slot_$id'),
                      id: id,
                      // Stands in for a real card: 24pt tall when its gate
                      // fires, SizedBox.shrink when it doesn't (or when the
                      // user dismissed it).
                      child: firing.contains(id)
                          ? const SizedBox(height: 24, width: double.infinity)
                          : const SizedBox.shrink(),
                    ),
                  const ContextualCardOverflowNotice(),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Ids whose slot actually occupies space on screen. A suppressed slot is
/// `Offstage`, so its render box reports zero height — this measures what the
/// user can see, not what is in the widget tree.
List<String> _painted(WidgetTester tester) {
  return _widgetIds
      .where((id) => tester.getSize(find.byKey(ValueKey('slot_$id'))).height > 0)
      .toList();
}

void main() {
  group('planContextualCards — ranking', () {
    test('renders exactly cap-many when more cards are eligible than fit', () {
      final plan = _plan();

      expect(_allFakeIds.length, greaterThan(5),
          reason: 'the fixture must over-supply, or the test proves nothing');
      expect(plan.visible.length, 5);
      expect(plan.suppressed.length, _allFakeIds.length - 5);
      expect(plan.overflowCount, _allFakeIds.length - 5);
    });

    test('the highest-priority cards win, category rule breaking the ties', () {
      final plan = _plan();

      // a_high 900 → activity 1/2
      // p_high 800 → plan 1/2
      // s_high 700 → social 1/2
      // p_mid  600 → plan 2/2
      // f_tie  600 → same priority, later manifest index, but fasting is empty
      //              and the 5th slot is still open
      expect(plan.visible, ['a_high', 'p_high', 's_high', 'p_mid', 'f_tie']);
      // a_mid (500) is a genuine loser to the cap, NOT to its category.
      expect(plan.suppressed, ['a_mid', 's_low', 'p_low', 'a_low']);
    });

    test('equal priorities break on manifest index, not set iteration order',
        () {
      // p_mid and f_tie both sit at 600; p_mid is declared first.
      final plan = _plan(eligible: {'f_tie', 'p_mid'}, cap: 1);
      expect(plan.visible, ['p_mid']);
      expect(plan.suppressed, ['f_tie']);
    });

    test('no category may take more than maxPerCategory slots', () {
      // All three activity cards eligible, plus one plan card.
      final plan = _plan(eligible: {'a_high', 'a_mid', 'a_low', 'p_high'});
      expect(plan.visible, ['a_high', 'p_high', 'a_mid']);
      expect(plan.suppressed, ['a_low'],
          reason: 'the third activity card is held back even though slots '
              'remain — one topic must not own the whole day');
    });

    test('is deterministic across repeated evaluations', () {
      final first = _plan();
      for (var i = 0; i < 25; i++) {
        // A differently-ordered Set with the same members must not reshuffle
        // anything — Home rebuilds constantly and must not jitter.
        final shuffled = <String>{
          'f_tie', 'a_low', 'p_high', 's_low', 'a_high',
          'p_low', 's_high', 'a_mid', 'p_mid',
        };
        final again = _plan(eligible: shuffled);
        expect(again.visible, first.visible);
        expect(again.suppressed, first.suppressed);
        expect(again.overflowCount, first.overflowCount);
      }
    });
  });

  group('planContextualCards — suppression is never silent', () {
    test('overflowCount reports what the cap held back', () {
      final plan = _plan();
      expect(plan.hasSuppressedCards, isTrue);
      expect(plan.overflowCount, 4);
      expect(plan.suppressed.length, plan.overflowCount);
    });

    test('an uncapped day reports nothing suppressed', () {
      final plan = _plan(eligible: {'a_high', 'p_high'});
      expect(plan.hasSuppressedCards, isFalse);
      expect(plan.overflowCount, 0);
      expect(plan.suppressed, isEmpty);
    });

    test('showAll reveals everything but still reports the overflow count', () {
      final plan = _plan(showAll: true);
      expect(plan.visible.length, _allFakeIds.length);
      expect(plan.showingAll, isTrue);
      // The count must survive expansion, or the affordance cannot honestly
      // flip back to "show less".
      expect(plan.overflowCount, 4);
    });
  });

  group('planContextualCards — dismissal', () {
    test('a dismissed card frees its slot for the next-ranked card', () {
      final before = _plan();
      expect(before.visible.contains('a_high'), isTrue);
      expect(before.visible.contains('a_mid'), isFalse);

      final after = _plan(dismissed: {'a_high'});

      expect(after.visible.contains('a_high'), isFalse);
      expect(after.visible.length, 5,
          reason: 'a dismissed card must not hold an empty slot');
      expect(after.visible, ['p_high', 's_high', 'p_mid', 'f_tie', 'a_mid']);
      expect(after.overflowCount, 3);
    });

    test('dismissing every card empties the stack without error', () {
      final plan = _plan(dismissed: _allFakeIds);
      expect(plan.visible, isEmpty);
      expect(plan.suppressed, isEmpty);
      expect(plan.overflowCount, 0);
    });
  });

  group('kContextualCardManifest', () {
    test('ids are unique — the id is the join key with the widget slots', () {
      final ids = kContextualCardManifest.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every card is ranked above zero and inside a known category', () {
      for (final spec in kContextualCardManifest) {
        expect(spec.priority, greaterThan(0), reason: spec.id);
        expect(ContextualCardCategory.values.contains(spec.category), isTrue);
      }
    });

    test('the cap is smaller than the manifest — it must actually bind', () {
      expect(kContextualCardDailyCap, lessThan(kContextualCardManifest.length));
      expect(kContextualCardMaxPerCategory, lessThan(kContextualCardDailyCap));
    });
  });

  group('ExtendedHomeCardsStack slots', () {
    testWidgets('renders exactly the cap when more cards are eligible',
        (tester) async {
      final gates = ValueNotifier<Set<String>>(_widgetIds.toSet());
      addTearDown(gates.dispose);

      await tester.pumpWidget(_harness(gates));
      await tester.pumpAndSettle();

      expect(_widgetIds.length, greaterThan(kContextualCardDailyCap));
      expect(_painted(tester).length, kContextualCardDailyCap);
    });

    testWidgets('the highest-ranked cards win, stably across rebuilds',
        (tester) async {
      final gates = ValueNotifier<Set<String>>(_widgetIds.toSet());
      addTearDown(gates.dispose);

      await tester.pumpWidget(_harness(gates));
      await tester.pumpAndSettle();

      const expected = [
        ContextualCardIds.injuryWorkaround,
        ContextualCardIds.planAdjustments,
        ContextualCardIds.fastZoneStrip,
        ContextualCardIds.weighInDay,
        ContextualCardIds.standReminder,
      ];
      expect(_painted(tester), expected);
      expect(
        _painted(tester).contains(ContextualCardIds.returnToExercise),
        isFalse,
        reason: 'plan already holds its 2 slots',
      );

      // Force several more build passes; the visible set must not move.
      for (var i = 0; i < 5; i++) {
        gates.value = {...gates.value};
        await tester.pumpAndSettle();
        expect(_painted(tester), expected);
      }
    });

    testWidgets('suppression is surfaced, not silent', (tester) async {
      final gates = ValueNotifier<Set<String>>(_widgetIds.toSet());
      addTearDown(gates.dispose);

      await tester.pumpWidget(_harness(gates));
      await tester.pumpAndSettle();

      // 8 eligible, 5 shown → the stack must say the other 3 exist.
      expect(find.text('+3 more suggestions'), findsOneWidget);

      // …and tapping it opens them rather than leaving the user to guess.
      await tester.tap(find.text('+3 more suggestions'));
      await tester.pumpAndSettle();

      expect(_painted(tester).length, _widgetIds.length);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('nothing is claimed when nothing is suppressed',
        (tester) async {
      final gates = ValueNotifier<Set<String>>({
        ContextualCardIds.injuryWorkaround,
        ContextualCardIds.fastZoneStrip,
      });
      addTearDown(gates.dispose);

      await tester.pumpWidget(_harness(gates));
      await tester.pumpAndSettle();

      expect(_painted(tester).length, 2);
      expect(find.textContaining('more suggestions'), findsNothing);
    });

    testWidgets('a dismissed card frees its slot for the next-ranked card',
        (tester) async {
      final gates = ValueNotifier<Set<String>>(_widgetIds.toSet());
      addTearDown(gates.dispose);

      await tester.pumpWidget(_harness(gates));
      await tester.pumpAndSettle();

      expect(_painted(tester).contains(ContextualCardIds.standReminder), isTrue);
      expect(
        _painted(tester).contains(ContextualCardIds.macroPatternCallout),
        isFalse,
      );

      // The user dismisses the stand reminder: the card collapses itself, which
      // is exactly how every existing per-card dismiss works.
      gates.value = {..._widgetIds}..remove(ContextualCardIds.standReminder);
      await tester.pumpAndSettle();

      final painted = _painted(tester);
      expect(painted.contains(ContextualCardIds.standReminder), isFalse);
      expect(painted.length, kContextualCardDailyCap,
          reason: 'the freed slot must be refilled, not left empty');
      expect(
        painted.contains(ContextualCardIds.macroPatternCallout),
        isTrue,
        reason: 'the next-ranked card takes the freed slot',
      );
      // Still blocked by its category, not by the dismissal.
      expect(painted.contains(ContextualCardIds.returnToExercise), isFalse);
      expect(find.text('+2 more suggestions'), findsOneWidget);
    });
  });
}
