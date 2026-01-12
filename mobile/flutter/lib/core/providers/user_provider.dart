import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart' as app_user;

/// Provider for the current user from auth state
final currentUserProvider = Provider<AsyncValue<app_user.User?>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.status == AuthStatus.loading) {
    return const AsyncValue.loading();
  }
  if (authState.errorMessage != null) {
    return AsyncValue.error(authState.errorMessage!, StackTrace.current);
  }
  return AsyncValue.data(authState.user);
});

/// Provider for the current user ID (convenience provider)
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.id;
});

/// Provider for user's weight unit preference ('kg' or 'lbs')
/// Defaults to 'kg' if user is not loaded yet
final weightUnitProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.preferredWeightUnit ?? 'kg';
});

/// Provider for whether user prefers metric (kg) units
/// Convenience provider for easy use in widgets
final useKgProvider = Provider<bool>((ref) {
  final unit = ref.watch(weightUnitProvider);
  return unit == 'kg';
});
