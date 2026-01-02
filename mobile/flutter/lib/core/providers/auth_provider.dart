/// Re-exports auth providers from auth_repository for convenience.
///
/// Provides easy access to auth state and user ID providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

// Re-export auth state provider
export '../../data/repositories/auth_repository.dart' show authStateProvider, AuthState, AuthNotifier;

/// Provider for the current user ID.
/// Returns null if no user is logged in.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.id;
});
