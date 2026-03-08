import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/e2ee_encryption_service.dart';
import '../services/api_client.dart';

/// E2EE encryption service provider
final e2eeServiceProvider = Provider<E2EEncryptionService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  return E2EEncryptionService(secureStorage, apiClient);
});

/// Provider that initializes E2EE keys for a user.
/// Call this after login to ensure public key is uploaded.
final e2eeInitializedProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final e2eeService = ref.watch(e2eeServiceProvider);
    await e2eeService.getOrCreateKeyPair(userId);
    return true;
  },
);
