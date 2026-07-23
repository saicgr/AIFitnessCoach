// End-to-end scenario proof for the post-signup quiz bounce, driven through the
// REAL PreAuthQuizNotifier against REAL SharedPreferences state.
//
// The unit tests in pre_auth_quiz_survival_test.dart pin each piece in
// isolation. This file replays whole device timelines — sign-in, sign-out, quiz
// completion, second sign-up — in order, and asserts on the answers that
// actually survive, because the bug was not in any single piece: every part
// behaved as written, and the damage came from their sequence.
//
// The device fingerprint is read/written through the exported kLastAuth*Key
// constants, so if production renames a key these scenarios fail rather than
// silently testing a key nothing uses.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/screens/onboarding/pre_auth_quiz_data.dart';

/// Fill the quiz the way the funnel does — through the real setters, so the
/// real persistence and the real touch-clock both run.
Future<void> completeQuiz(PreAuthQuizNotifier quiz) async {
  await quiz.setGoals(['build_muscle']);
  await quiz.setFitnessLevel('intermediate');
  await quiz.setDaysPerWeek(4);
  await quiz.setEquipment(['dumbbells', 'barbell']);
}

/// What `_syncQuizAfterSignInImpl` records on a successful auth.
Future<void> recordSignIn(String userId, DateTime at) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(kLastAuthUserIdKey, userId);
  await sp.setInt(kLastAuthAtKey, at.millisecondsSinceEpoch);
}

/// What `_clearLocalSideEffects` now does on EVERY sign-out path.
Future<void> recordSignOut() async {
  final sp = await SharedPreferences.getInstance();
  await sp.remove(kLastAuthUserIdKey);
  await sp.remove(kLastAuthAtKey);
}

/// The decision `_syncQuizAfterSignInImpl` makes, fed from real persisted state.
Future<bool> wouldWipeQuizFor(
  String currentUserId,
  PreAuthQuizNotifier quiz,
) async {
  final sp = await SharedPreferences.getInstance();
  final previousAuthAtMs = sp.getInt(kLastAuthAtKey);
  return shouldClearQuizOnAccountSwitch(
    previousUserId: sp.getString(kLastAuthUserIdKey),
    currentUserId: currentUserId,
    quizLastTouchedAt: await quiz.lastTouchedAt(),
    previousAuthAt: previousAuthAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(previousAuthAtMs),
  );
}

void main() {
  late ProviderContainer container;
  late PreAuthQuizNotifier quiz;

  Future<void> bootDevice(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    container = ProviderContainer();
    addTearDown(container.dispose);
    quiz = container.read(preAuthQuizProvider.notifier);
    await quiz.ensureLoaded();
  }

  test(
    'SCENARIO the reported bug — second account on a device that already saw '
    'a first one, with no lastAuthAt because the install predates the fix',
    () async {
      // The device as it actually was: a previous account's id on file, and no
      // lastAuthAt at all (the key did not exist before this fix shipped).
      await bootDevice({kLastAuthUserIdKey: 'user-a-previous'});

      // The user runs the funnel and finishes the quiz.
      await completeQuiz(quiz);
      expect(container.read(preAuthQuizProvider).isComplete, isTrue);

      // They sign up as a brand-new account.
      //
      // Pin the contrast rather than describing it: the rule this replaced was
      // `previousUserId != null && previousUserId != user.id`, and on this
      // exact state it fires. That is the whole bug — so assert it fires, so
      // the scenario cannot quietly stop being a regression test.
      final sp = await SharedPreferences.getInstance();
      final previousUserId = sp.getString(kLastAuthUserIdKey);
      final oldRuleWouldWipe =
          previousUserId != null && previousUserId != 'user-b-new';
      expect(
        oldRuleWouldWipe,
        isTrue,
        reason: 'if this ever goes false the scenario no longer reproduces the '
            'device state that caused the bug',
      );

      expect(
        await wouldWipeQuizFor('user-b-new', quiz),
        isFalse,
        reason: 'same state, new rule: the answers are kept',
      );

      // Answers survive, so the backup runs and the published user carries them.
      final quizData = container.read(preAuthQuizProvider);
      final published = userWithQuizApplied(const User(id: 'user-b-new'), quizData);

      expect(quizData.isComplete, isTrue);
      expect(quizData.goals, ['build_muscle']);
      expect(
        published.hasCompletedPreAuthQuiz,
        isTrue,
        reason: 'this is the exact check the router gate reads — true means it '
            'routes onward instead of back to /pre-auth-quiz',
      );
    },
  );

  test(
    'SCENARIO steady state after the fix — sign-out clears the fingerprint, so '
    'the next person is not an account switch at all',
    () async {
      await bootDevice({});

      // Account A signs in, then signs out through any path.
      await recordSignIn('user-a', DateTime(2026, 7, 22, 9));
      await recordSignOut();

      // Account B runs the funnel on the same device and signs up.
      await completeQuiz(quiz);

      expect(
        await wouldWipeQuizFor('user-b', quiz),
        isFalse,
        reason: 'no fingerprint remains, so there is no switch to detect',
      );
      expect(container.read(preAuthQuizProvider).isComplete, isTrue);
    },
  );

  test(
    'SCENARIO the case the wipe exists for — answers abandoned BEFORE the '
    'previous account signed in are still discarded',
    () async {
      await bootDevice({});

      // Someone fills the quiz and walks away without signing up.
      await completeQuiz(quiz);

      // Later, account A signs in on this device — after those answers.
      await recordSignIn('user-a', DateTime.now().add(const Duration(hours: 1)));

      // Later still, account B signs up. Those answers are not B's.
      expect(
        await wouldWipeQuizFor('user-b', quiz),
        isTrue,
        reason: 'the original protection must still hold',
      );
    },
  );

  test(
    'SCENARIO shared device — B fills the quiz after A last signed in, so the '
    'answers are B\'s and must reach B\'s account',
    () async {
      await bootDevice({});

      await recordSignIn('user-a', DateTime.now().subtract(const Duration(minutes: 30)));

      // A signs out is not modelled here on purpose: this asserts the rule is
      // right even when the fingerprint survives (a revoked session, a crash).
      await completeQuiz(quiz);

      expect(await wouldWipeQuizFor('user-b', quiz), isFalse);

      final published =
          userWithQuizApplied(const User(id: 'user-b'), container.read(preAuthQuizProvider));
      expect(published.hasCompletedPreAuthQuiz, isTrue);
      expect(published.equipmentList, containsAll(['dumbbells', 'barbell']));
    },
  );

  test(
    'SCENARIO same user signing back in mid-onboarding keeps their own answers',
    () async {
      await bootDevice({});

      await completeQuiz(quiz);
      await recordSignIn('user-a', DateTime.now());

      // Session restored later; same account.
      expect(await wouldWipeQuizFor('user-a', quiz), isFalse);
      expect(container.read(preAuthQuizProvider).isComplete, isTrue);
    },
  );

  test(
    'SCENARIO a wipe that DOES fire leaves nothing behind — no answer from the '
    'previous person survives into the next account',
    () async {
      await bootDevice({});

      await completeQuiz(quiz);
      await quiz.setLimitations(['knees', 'lower_back']);
      await quiz.setNutritionEnabled(true);
      await quiz.setWorkoutVariety('varied');

      await quiz.clear();

      final after = container.read(preAuthQuizProvider);
      expect(after.isComplete, isFalse);
      expect(after.goals, isNull);
      expect(after.equipment, isNull);
      expect(
        after.limitations,
        isNull,
        reason: 'injuries leaking into another person constrains THEIR plan',
      );
      expect(after.nutritionEnabled, isNull);
      expect(after.workoutVariety, isNull);

      // And nothing survives a reload from disk either.
      final reloaded = await quiz.ensureLoaded();
      expect(reloaded.limitations, isNull);
      final sp = await SharedPreferences.getInstance();
      expect(
        sp.getKeys().where((k) => k.startsWith('preAuth_')),
        isEmpty,
        reason: 'clear() must leave zero preAuth_ keys on disk',
      );
    },
  );
}
