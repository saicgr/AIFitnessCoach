import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../screens/onboarding/pre_auth_quiz_data.dart';
import '../models/ai_profile_payload.dart';
import '../repositories/auth_repository.dart';
import 'api_client.dart';

/// Auto-backup service for pre-auth quiz state.
///
/// Listens to [preAuthQuizProvider] and debounces a POST to
/// `/users/{id}/preferences` whenever the quiz mutates AND the user is
/// signed in but onboarding is incomplete.
///
/// Why this exists: quiz answers are written to SharedPreferences immediately
/// on each setter call, but the backend POST historically only happened at
/// coach-selection. If the user uninstalled mid-onboarding (e.g. between
/// personal-info and coach-selection), every quiz field set after sign-in
/// was lost on reinstall. This service makes every quiz mutation eventually
/// consistent with the server.
///
/// Debounce is 2s — long enough to coalesce burst writes (e.g. user toggling
/// 5 equipment chips in a row), short enough that a "tap Continue then close
/// app" sequence still flushes before the POST window expires.
class PreAuthQuizBackupService {
  PreAuthQuizBackupService(this._ref) {
    _subscription = _ref.listen<PreAuthQuizData>(
      preAuthQuizProvider,
      (previous, next) {
        if (!_shouldSync(previous, next)) return;
        _scheduleBackup();
      },
    );
  }

  final Ref _ref;
  ProviderSubscription<PreAuthQuizData>? _subscription;
  Timer? _debounce;
  static const Duration _debounceWindow = Duration(seconds: 2);

  bool _shouldSync(PreAuthQuizData? previous, PreAuthQuizData next) {
    // Skip the very first emission (provider construction) and no-op rebuilds.
    if (previous == null) return false;
    if (identical(previous, next)) return false;

    final auth = _ref.read(authStateProvider);
    if (auth.status != AuthStatus.authenticated) return false;
    final user = auth.user;
    if (user == null) return false;
    // After paywall completion the user object on the server is the source of
    // truth; quiz state is no longer authoritative.
    if (user.isPaywallComplete) return false;
    return true;
  }

  void _scheduleBackup() {
    _debounce?.cancel();
    _debounce = Timer(_debounceWindow, _flush);
  }

  Future<void> _flush() async {
    try {
      final auth = _ref.read(authStateProvider);
      final user = auth.user;
      if (user == null || auth.status != AuthStatus.authenticated) return;
      if (user.isPaywallComplete) return;

      final quizData = await _ref.read(preAuthQuizProvider.notifier).ensureLoaded();
      // Skip if quiz has no signal at all — avoids spamming POSTs on cleared
      // state (e.g. right after sign-out → sign-in account switch).
      if (!quizData.isComplete &&
          quizData.goals == null &&
          quizData.fitnessLevel == null &&
          quizData.daysPerWeek == null &&
          quizData.equipment == null &&
          quizData.weightDirection == null &&
          quizData.trainingSplit == null) {
        return;
      }

      final payload = AIProfilePayloadBuilder.buildPayload(quizData);
      // Personal-info fields not in the AI payload but accepted by the
      // /preferences endpoint (mirrors coach_selection_screen).
      if (quizData.gender != null) payload['gender'] = quizData.gender;
      if (quizData.age != null) payload['age'] = quizData.age;
      if (quizData.heightCm != null) payload['height_cm'] = quizData.heightCm;
      if (quizData.weightKg != null) payload['weight_kg'] = quizData.weightKg;
      if (quizData.goalWeightKg != null) payload['goal_weight_kg'] = quizData.goalWeightKg;
      if (quizData.weightDirection != null) payload['weight_direction'] = quizData.weightDirection;
      if (quizData.weightChangeAmount != null) payload['weight_change_amount'] = quizData.weightChangeAmount;
      if (quizData.weightChangeRate != null) payload['weight_change_rate'] = quizData.weightChangeRate;
      if (quizData.workoutDays != null) payload['workout_days'] = quizData.workoutDays;
      if (quizData.activityLevel != null) payload['activity_level'] = quizData.activityLevel;
      if (quizData.sleepQuality != null) payload['sleep_quality'] = quizData.sleepQuality;
      if (quizData.obstacles != null) payload['obstacles'] = quizData.obstacles;
      if (quizData.motivations != null) payload['motivations'] = quizData.motivations;
      if (quizData.name != null) payload['name'] = quizData.name;
      if (quizData.dateOfBirth != null) {
        payload['date_of_birth'] = quizData.dateOfBirth!.toIso8601String().split('T').first;
      }
      if (quizData.isTrainer != null) payload['is_trainer'] = quizData.isTrainer;

      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        '${ApiConstants.users}/${user.id}/preferences',
        data: payload,
      );
      debugPrint('💾 [QuizBackup] Synced quiz to backend for ${user.id}');
    } catch (e) {
      // Non-fatal: coach-selection's POST is the final guarantee. This is
      // a best-effort safety net for uninstall/reinstall mid-onboarding.
      debugPrint('⚠️ [QuizBackup] Sync failed (non-fatal): $e');
    }
  }

  /// Force an immediate flush bypassing the debounce. Call before navigating
  /// to a critical save point (e.g. coach selection submit) to ensure the
  /// latest state lands server-side without the 2s wait.
  Future<void> flushNow() async {
    _debounce?.cancel();
    await _flush();
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.close();
  }
}

/// Provider for the auto-backup service. Constructed lazily on first read.
/// Wire into app.dart so it's eagerly instantiated once per app session and
/// the internal ref.listen subscription stays alive.
final preAuthQuizBackupServiceProvider = Provider<PreAuthQuizBackupService>((ref) {
  final service = PreAuthQuizBackupService(ref);
  ref.onDispose(service.dispose);
  return service;
});
