import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart' as app_user;

/// Provider for the current user from auth state
/// L1: Uses .select() to only rebuild when user data or status actually changes,
/// not on every auth state mutation (e.g. token refresh)
final currentUserProvider = Provider<AsyncValue<app_user.User?>>((ref) {
  final user = ref.watch(authStateProvider.select((s) => s.user));
  final status = ref.watch(authStateProvider.select((s) => s.status));
  final errorMessage = ref.watch(authStateProvider.select((s) => s.errorMessage));
  if (status == AuthStatus.loading) {
    return const AsyncValue.loading();
  }
  if (errorMessage != null) {
    return AsyncValue.error(errorMessage, StackTrace.current);
  }
  return AsyncValue.data(user);
});

/// Provider for the current user ID (convenience provider)
/// L1: Uses .select() to only rebuild when the user ID changes
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.id));
});

/// Provider for user's weight unit preference ('kg' or 'lbs')
/// Defaults to 'kg' if user is not loaded yet
/// L1: Uses .select() to only rebuild when weight unit changes
final weightUnitProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.preferredWeightUnit)) ?? 'kg';
});

/// Provider for whether user prefers metric (kg) units
/// Convenience provider for easy use in widgets
final useKgProvider = Provider<bool>((ref) {
  final unit = ref.watch(weightUnitProvider);
  return unit == 'kg';
});
