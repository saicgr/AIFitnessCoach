import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../services/api_client.dart';
import 'e2ee_provider.dart';

/// Social service provider
final socialServiceProvider = Provider<SocialService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialService(apiClient);
});

/// Feed sort order provider (F3)
final feedSortProvider = StateProvider<String>((ref) => 'recent');

/// Activity feed provider (paginated, supports sorting via feedSortProvider)
/// Note: Removed autoDispose to prevent refetching on navigation
final activityFeedProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    final sortBy = ref.watch(feedSortProvider);
    return await socialService.getActivityFeed(userId: userId, sortBy: sortBy);
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

/// Followers list provider (extracts items from paginated response)
/// Note: Removed autoDispose to prevent refetching on navigation
final followersListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    final response = await socialService.getFollowers(userId: userId);
    return List<Map<String, dynamic>>.from(response['items'] ?? []);
  },
);

/// Following list provider (extracts items from paginated response)
/// Note: Removed autoDispose to prevent refetching on navigation
final followingListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    final response = await socialService.getFollowing(userId: userId);
    return List<Map<String, dynamic>>.from(response['items'] ?? []);
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

/// Conversation messages provider - fetches and decrypts messages
/// Note: Removed autoDispose to prevent refetching on navigation
final conversationMessagesProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String userId, String conversationId, String otherUserId})>(
  (ref, params) async {
    final socialService = ref.watch(socialServiceProvider);
    final messages = await socialService.getMessages(
      userId: params.userId,
      conversationId: params.conversationId,
    );

    // Decrypt encrypted messages
    final e2eeService = ref.watch(e2eeServiceProvider);
    final sharedSecret = await e2eeService.deriveSharedSecret(
      params.userId,
      params.otherUserId,
    );

    final decryptedMessages = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final encryptionVersion = msg['encryption_version'] as int? ?? 0;
      if (encryptionVersion > 0 && sharedSecret != null) {
        final encryptedContent = msg['encrypted_content'] as String?;
        final nonce = msg['encryption_nonce'] as String?;
        if (encryptedContent != null && nonce != null) {
          final decrypted = await e2eeService.decryptMessage(
            encryptedContent,
            nonce,
            sharedSecret,
          );
          decryptedMessages.add({
            ...msg,
            'decrypted_content': decrypted,
          });
        } else {
          decryptedMessages.add({
            ...msg,
            'decrypted_content': '[Unable to decrypt]',
          });
        }
      } else if (encryptionVersion > 0 && sharedSecret == null) {
        decryptedMessages.add({
          ...msg,
          'decrypted_content': '[Unable to decrypt]',
        });
      } else {
        decryptedMessages.add(msg);
      }
    }

    return decryptedMessages;
  },
);

/// Social stats provider (F7) - friends count, followers, following
final socialStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.read(socialServiceProvider);
    return await socialService.getSocialStats(userId: userId);
  },
);

/// Stories feed provider (F11) - stories from friends
final storiesFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final socialService = ref.read(socialServiceProvider);
    return await socialService.getStoriesFeed();
  },
);

/// Story views provider (F11) - views for a specific story
final storyViewsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, storyId) async {
    final socialService = ref.read(socialServiceProvider);
    return await socialService.getStoryViews(storyId);
  },
);

/// Trending hashtags provider (F10)
final trendingHashtagsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final socialService = ref.read(socialServiceProvider);
    return await socialService.getTrendingHashtags();
  },
);
