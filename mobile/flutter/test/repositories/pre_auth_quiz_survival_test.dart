// Regression tests for "finished pre-onboarding, signed up, got dropped back
// on question 1 of the quiz with every answer blank".
//
// Root cause: `AuthRepository._syncQuizAfterSignInImpl` treated ANY change of
// `lastAuthUserId` as an account switch and wiped the persisted pre-auth quiz —
// including when the wiped answers were the ones the user had just typed on the
// way to that very sign-up. The wipe also skipped the `/preferences` backup
// (which only runs when the quiz reads complete), so the answers were destroyed
// rather than merely re-asked, and the router's onboarding gate — which reads
// exactly that wiped state — sent the user back to `/pre-auth-quiz`, a screen
// with no resume.
//
// Three invariants are locked down here:
//   1. The account-switch rule keeps answers typed after the previous session.
//   2. `_wipeQuizKeys` covers every `preAuth_` key any setter writes, so no
//      answer (notably injuries) survives a clear and leaks into the next
//      account.
//   3. The quiz store always reaches a loaded state and announces it, so the
//      router can tell "still loading" apart from "never took the quiz".
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/screens/onboarding/pre_auth_quiz_data.dart';

void main() {
  group('shouldClearQuizOnAccountSwitch', () {
    final previousSignIn = DateTime(2026, 7, 22, 10, 00);

    test(
      'KEEPS answers typed after the previous account last signed in — the '
      'reported bug: second account on a device, quiz filled minutes before',
      () {
        expect(
          shouldClearQuizOnAccountSwitch(
            previousUserId: 'user-a',
            currentUserId: 'user-b',
            quizLastTouchedAt: previousSignIn.add(const Duration(hours: 2)),
            previousAuthAt: previousSignIn,
          ),
          isFalse,
        );
      },
    );

    test('CLEARS answers left over from before the previous sign-in', () {
      expect(
        shouldClearQuizOnAccountSwitch(
          previousUserId: 'user-a',
          currentUserId: 'user-b',
          quizLastTouchedAt: previousSignIn.subtract(const Duration(hours: 2)),
          previousAuthAt: previousSignIn,
        ),
        isTrue,
      );
    });

    test('treats a touch exactly at the previous sign-in as leftover', () {
      expect(
        shouldClearQuizOnAccountSwitch(
          previousUserId: 'user-a',
          currentUserId: 'user-b',
          quizLastTouchedAt: previousSignIn,
          previousAuthAt: previousSignIn,
        ),
        isTrue,
      );
    });

    test('never clears when the same user signs in again', () {
      expect(
        shouldClearQuizOnAccountSwitch(
          previousUserId: 'user-a',
          currentUserId: 'user-a',
          quizLastTouchedAt: previousSignIn.subtract(const Duration(days: 3)),
          previousAuthAt: previousSignIn,
        ),
        isFalse,
      );
    });

    test('never clears for the first account on a device', () {
      expect(
        shouldClearQuizOnAccountSwitch(
          previousUserId: null,
          currentUserId: 'user-a',
          quizLastTouchedAt: previousSignIn,
          previousAuthAt: null,
        ),
        isFalse,
      );
    });

    test(
      'keeps answers when the previous sign-in is undateable (installs that '
      'predate lastAuthAt) — losing a completed quiz is the worse failure',
      () {
        expect(
          shouldClearQuizOnAccountSwitch(
            previousUserId: 'user-a',
            currentUserId: 'user-b',
            quizLastTouchedAt: previousSignIn,
            previousAuthAt: null,
          ),
          isFalse,
        );
      },
    );

    test('nothing to clear when no answers were ever persisted', () {
      expect(
        shouldClearQuizOnAccountSwitch(
          previousUserId: 'user-a',
          currentUserId: 'user-b',
          quizLastTouchedAt: null,
          previousAuthAt: previousSignIn,
        ),
        isFalse,
      );
    });
  });

  group('userWithQuizApplied', () {
    // `/auth/sync` returns a BARE row for a brand-new sign-up, so the router's
    // server-truth check (`User.hasCompletedPreAuthQuiz`) reads false however
    // thoroughly the user answered. Patching the in-memory user after the
    // /preferences POST is what stops the quiz gate from resting on local
    // SharedPreferences alone.
    const bareUser = User(id: 'user-b');

    test('a bare /auth/sync user does NOT look quiz-complete', () {
      expect(bareUser.hasCompletedPreAuthQuiz, isFalse);
    });

    test('patched user satisfies the router quiz gate', () {
      final quiz = PreAuthQuizData(
        goals: ['build_muscle'],
        fitnessLevel: 'intermediate',
        daysPerWeek: 4,
        equipment: ['dumbbells', 'barbell'],
      );
      expect(quiz.isComplete, isTrue);

      final patched = userWithQuizApplied(bareUser, quiz);

      expect(patched.hasCompletedPreAuthQuiz, isTrue);
      expect(patched.goalsList, ['build_muscle']);
      expect(patched.equipmentList, containsAll(['dumbbells', 'barbell']));
    });

    test('merges custom equipment and preserves existing preferences', () {
      const user = User(id: 'user-b', preferences: '{"email":"a@b.co"}');
      final quiz = PreAuthQuizData(
        goals: ['lose_weight'],
        fitnessLevel: 'beginner',
        daysPerWeek: 3,
        equipment: ['dumbbells'],
        customEquipment: ['sandbag'],
        trainingSplit: 'full_body',
      );

      final patched = userWithQuizApplied(user, quiz);

      expect(patched.equipmentList, containsAll(['dumbbells', 'sandbag']));
      final prefs = jsonDecode(patched.preferences!) as Map<String, dynamic>;
      expect(prefs['email'], 'a@b.co');
      expect(prefs['days_per_week'], 3);
      expect(prefs['training_split'], 'full_body');
    });

    test('an empty quiz leaves the user untouched rather than faking it', () {
      final patched = userWithQuizApplied(bareUser, PreAuthQuizData());
      expect(patched.hasCompletedPreAuthQuiz, isFalse);
      expect(patched.goals, isNull);
    });
  });

  group('_wipeQuizKeys covers every persisted preAuth_ key', () {
    // Source-level guard: a new setter that persists a `preAuth_` key without
    // adding it to the wipe list silently leaks that answer into the next
    // account on the device. `preAuth_limitations` (injuries) leaked this way
    // and would have constrained a different person's generated plan.
    test('no written key is missing from the wipe list', () {
      final source = File(
        'lib/screens/onboarding/pre_auth_quiz_data.dart',
      ).readAsStringSync();

      final keyPattern = RegExp(r"'(preAuth_[A-Za-z]+)'");
      final allKeys = keyPattern
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();

      final wipeListStart = source.indexOf('const keysToRemove = [');
      expect(
        wipeListStart,
        greaterThan(-1),
        reason: 'wipe list literal not found — did _wipeQuizKeys get renamed?',
      );
      final wipeListEnd = source.indexOf('];', wipeListStart);
      final wipeList = source.substring(wipeListStart, wipeListEnd);
      final wipedKeys = keyPattern
          .allMatches(wipeList)
          .map((m) => m.group(1)!)
          .toSet();

      // `preAuth_lastTouchedAt` is the staleness clock, not an answer; it is
      // removed explicitly alongside every _wipeQuizKeys call site.
      final missing = allKeys.difference(wipedKeys)
        ..remove('preAuth_lastTouchedAt');

      expect(
        missing,
        isEmpty,
        reason:
            'These preAuth_ keys are persisted but never wiped, so they survive '
            'clear() and bleed into the next account: $missing',
      );
    });
  });

  group('PreAuthQuizNotifier load signal', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'reports not-loaded synchronously, then flips loaded and notifies — the '
      'router needs this to avoid bouncing a mid-load user to question 1',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(preAuthQuizProvider.notifier);
        expect(
          notifier.isLoaded,
          isFalse,
          reason: 'the prefs read has not resolved yet',
        );

        var notified = false;
        notifier.loadedListenable.addListener(() => notified = true);

        await notifier.ensureLoaded();

        expect(notifier.isLoaded, isTrue);
        expect(
          notified,
          isTrue,
          reason:
              'the router listens to loadedListenable to re-run its redirect; '
              'an empty quiz emits no StateNotifier change, so this is the '
              'only signal that ever arrives',
        );
      },
    );

    test('lastTouchedAt reflects a real answer being recorded', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(preAuthQuizProvider.notifier);
      await notifier.ensureLoaded();
      expect(await notifier.lastTouchedAt(), isNull);

      await notifier.setGoals(['build_muscle']);

      final touched = await notifier.lastTouchedAt();
      expect(
        touched,
        isNotNull,
        reason:
            'the account-switch rule dates answers by this timestamp — without '
            'it every switch falls back to discarding them',
      );
    });

    test('clear() wipes the touch clock along with the answers', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(preAuthQuizProvider.notifier);
      await notifier.ensureLoaded();
      await notifier.setGoals(['lose_weight']);
      expect(await notifier.lastTouchedAt(), isNotNull);

      await notifier.clear();

      expect(container.read(preAuthQuizProvider).goals, isNull);
      expect(await notifier.lastTouchedAt(), isNull);
    });
  });
}
