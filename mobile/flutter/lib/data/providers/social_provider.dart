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

/// Friends list provider
final friendsListProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getFriends(userId: userId);
  },
);

/// Followers list provider
final followersListProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getFollowers(userId: userId);
  },
);

/// Following list provider
final followingListProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getFollowing(userId: userId);
  },
);

/// Challenges list provider (all challenges with user participation)
final challengesListProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getChallenges(userId: userId);
  },
);

/// User's active challenges (challenges they are participating in)
final userActiveChallengesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    final allChallenges = await socialService.getChallenges(userId: userId);
    // Filter to only challenges user is participating in
    return allChallenges.where((c) => c['user_participation'] != null).toList();
  },
);
