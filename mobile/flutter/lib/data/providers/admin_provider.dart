import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

/// Provider to check if current user is an admin.
/// Use `.select()` for granular access:
///   ref.watch(isAdminProvider) — admin check (bool)
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.isAdmin ?? false));
});
