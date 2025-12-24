import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../services/api_client.dart';

/// Social service provider
final socialServiceProvider = Provider<SocialService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialService(apiClient);
});

/// Activity feed provider (paginated)
final activityFeedProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getActivityFeed(userId: userId);
  },
);

/// User privacy settings provider
final privacySettingsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getPrivacySettings(userId);
  },
);
