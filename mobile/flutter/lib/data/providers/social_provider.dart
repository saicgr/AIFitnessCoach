import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../services/api_client.dart';

/// Social service provider
final socialServiceProvider = Provider<SocialService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialService(apiClient);
});

/// Activity feed provider (paginated)
/// Note: Removed autoDispose to prevent refetching on navigation
final activityFeedProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getActivityFeed(userId: userId);
  },
);

/// User privacy settings provider
/// Note: Removed autoDispose to prevent refetching on navigation
final privacySettingsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getPrivacySettings(userId);
  },
);

/// Friends list provider
/// Note: Removed autoDispose to prevent refetching on navigation
final friendsListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getFriends(userId: userId);
  },
);

/// Followers list provider
/// Note: Removed autoDispose to prevent refetching on navigation
final followersListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getFollowers(userId: userId);
  },
);

/// Following list provider
/// Note: Removed autoDispose to prevent refetching on navigation
final followingListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getFollowing(userId: userId);
  },
);

/// Challenges list provider (all challenges with user participation)
/// Note: Removed autoDispose to prevent refetching on navigation
final challengesListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getChallenges(userId: userId);
  },
);

/// User's active challenges (challenges they are participating in)
/// Note: Removed autoDispose to prevent refetching on navigation
final userActiveChallengesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    final allChallenges = await socialService.getChallenges(userId: userId);
    // Filter to only challenges user is participating in
    return allChallenges.where((c) => c['user_participation'] != null).toList();
  },
);

/// Conversations list provider (direct messages)
/// Note: Removed autoDispose to prevent refetching on navigation
final conversationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return await socialService.getConversations(userId: userId);
  },
);
