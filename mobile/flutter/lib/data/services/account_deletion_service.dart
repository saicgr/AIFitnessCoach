import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../local/database_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/onboarding_repository.dart';
import 'api_client.dart';

/// Centralized Delete-Account flow used by both the Profile tab and
/// the Settings > Danger Zone screen.
///
/// Responsible for:
///   1. Calling the backend reset endpoint (with optional password for email
///      auth users).
///   2. Clearing local persisted state (SharedPreferences + Drift) in
///      parallel.
///   3. Resetting in-memory providers (onboarding) and signing out via
///      Supabase.
///
/// Phase updates are pushed to [status] so callers can render a labeled
/// progress UI instead of a silent spinner. Navigation is left to the caller
/// because GoRouter usage requires a `BuildContext`.
class AccountDeletionService {
  final Ref _ref;
  AccountDeletionService(this._ref);

  Future<void> deleteAccount({
    required String userId,
    String? password,
    required ValueNotifier<String> status,
  }) async {
    debugPrint('[DeleteAccount] start userId=$userId');

    // Phase 1: backend delete (security-critical — invalidates the JWT and
    // the Supabase Auth identity before we touch local state).
    status.value = 'Deleting account from server…';
    final apiClient = _ref.read(apiClientProvider);
    final body = <String, dynamic>{};
    if (password != null) body['password'] = password;
    final response = await apiClient.dio.delete(
      '${ApiConstants.users}/$userId/reset',
      data: body,
    );
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Server returned ${response.statusCode}',
      );
    }
    debugPrint('[DeleteAccount] backend ok');

    // Phase 2: clear local persisted state in parallel — these are
    // independent and both safe to run concurrently.
    status.value = 'Clearing local data…';
    await Future.wait<void>([
      _clearSharedPrefs(),
      _clearDriftSafely(),
    ]);
    debugPrint('[DeleteAccount] local data cleared');

    // Phase 3: in-memory provider reset + Supabase sign-out.
    status.value = 'Signing out…';
    _ref.read(onboardingStateProvider.notifier).reset();
    await _ref.read(authStateProvider.notifier).signOut();
    debugPrint('[DeleteAccount] signed out');
  }

  Future<void> _clearSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Preserve tour flags so completed tutorials don't replay if the user
    // signs up again on the same device.
    final tourFlags = <String, bool>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('has_seen_')) {
        tourFlags[key] = prefs.getBool(key) ?? false;
      }
    }
    await prefs.clear();
    for (final entry in tourFlags.entries) {
      await prefs.setBool(entry.key, entry.value);
    }
  }

  Future<void> _clearDriftSafely() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      await db.clearAllUserData();
    } catch (e) {
      // Drift wipe is non-critical; the next sign-in will scope queries to
      // the new user_id, so a stale row left behind is harmless.
      debugPrint('[DeleteAccount] Drift clear failed (non-critical): $e');
    }
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>(
  (ref) => AccountDeletionService(ref),
);
