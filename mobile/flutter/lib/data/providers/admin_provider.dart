import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

/// Provider to check if current user is an admin
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.isAdmin ?? false;
});

/// Provider to check if current user is a super admin
final isSuperAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.isSuperAdmin ?? false;
});

/// Provider to get admin role string
final adminRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.role;
});
