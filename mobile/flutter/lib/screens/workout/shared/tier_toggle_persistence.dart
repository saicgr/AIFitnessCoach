/// ONE way for the in-workout tier toggles to change the Easy/Advanced tier
/// AND confirm the change actually stuck (E2E #13b).
///
/// The reported defect: an explicit Easy↔Advanced tap left
/// `users.workout_ui_mode` NULL. `WorkoutUiModeNotifier.setMode` writes
/// SharedPreferences, PUTs `/users/{id}`, then refreshes the auth user — but
/// its backend write is wrapped in a `catch (e) { debugPrint(...) }`, and a
/// server that silently drops the field is not an exception at all. Either way
/// the UI flipped and told the user nothing, so the choice looked persisted
/// while the next cold start on another device reverted it.
///
/// This helper closes that loop at the only place the client can: after
/// `setMode` has completed (which includes its own `refreshUser()`), re-read
/// the freshly-refreshed user and check the server agrees. If it does not, the
/// user is TOLD, instead of the failure being swallowed.
///
/// It deliberately does NOT roll the tier back — the local preference is still
/// honoured for this session, which is what the user asked for. It only stops
/// the app claiming a cross-device save that did not happen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/workout_ui_mode_provider.dart';
import '../../../data/repositories/auth_repository.dart' show authStateProvider;
import '../../../widgets/app_snackbar.dart';

/// Apply an EXPLICIT tier choice and verify it persisted server-side.
///
/// Returns true when the server confirms the new tier, false when it could not
/// be confirmed (in which case the user has already been shown why).
Future<bool> applyExplicitTierChange(
  BuildContext context,
  WidgetRef ref,
  WorkoutUiMode target,
) async {
  final notifier = ref.read(workoutUiModeProvider.notifier);
  await notifier.setMode(target);

  // No signed-in user (or auth still resolving) → there is nothing to verify
  // against and nothing to report. The local preference is applied either way.
  final user = ref.read(authStateProvider).user;
  if (user == null) return true;

  final stored = WorkoutUiMode.fromString(user.workoutUiMode);
  if (stored == target) return true;

  // The refreshed user does NOT carry the tier we just wrote — either the PUT
  // failed or the server dropped the field. Say so.
  if (context.mounted) {
    AppSnackBar.error(
      context,
      'Saved on this device only — your ${target.label} choice did not sync. '
      'It may reset on another device.',
    );
  }
  return false;
}
