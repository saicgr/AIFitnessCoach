import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/social_service.dart';
import '../services/api_client.dart';
import 'e2ee_provider.dart';

/// Social service provider
final socialServiceProvider = Provider<SocialService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialService(apiClient);
});

// ---------------------------------------------------------------------------
// Instant-load (Part-1 SWR) plumbing for the Social FutureProviders.
//
// A plain `FutureProvider` resolves exactly once, so it cannot do the classic
// "emit cache → emit fresh" double-emit of a StateNotifier. But the consumer
// surface here (`.watch`, `.future`, `.invalidate` — used by social_prewarmer
// and unified_notifications) MUST stay a `FutureProvider`, so we keep that type
// and instead make the FUTURE ITSELF instant on a warm disk cache:
//
//   * On cold start, if a disk blob exists and is within [_kInstantTtl], the
//     future resolves to it SYNCHRONOUSLY-fast (no network) — the screen paints
//     the cached feed/list immediately. A silent background refresh then runs
//     and writes the fresh value through to disk so the *next* cold start is
//     fresher. Resolving from cache + background revalidate IS stale-while-
//     revalidate within the FutureProvider model.
//   * If the blob is missing or older than [_kInstantTtl], the future does a
//     normal network fetch and writes through.
//   * A successful network fetch always writes through to disk.
//
// Disk blobs are user-scoped and carry a schema version, mirroring
// `CacheFirstMixin`'s envelope so a schema bump silently drops stale blobs.
// ---------------------------------------------------------------------------

/// Window during which a cached blob is served instantly (skipping the
/// blocking network round-trip) on a cold provider build. Within this window
/// the screen renders from disk and revalidates silently in the background.
const Duration _kInstantTtl = Duration(hours: 12);

/// Hard ceiling: blobs older than this are never served and are dropped on
/// read. Beyond [_kInstantTtl] but within this window, the disk blob is still
/// used as a last-resort instant render only when the network fetch fails.
const Duration _kMaxStaleTtl = Duration(days: 3);

/// Bump when any social payload shape changes so old blobs are discarded.
const int _kSocialCacheSchema = 1;

/// SharedPreferences key prefix for the social SWR slots.
const String _kSocialCachePrefix = 'social_swr';

/// Build the fully-qualified, user + schema scoped storage key.
String _socialCacheKey(String base, String userId) =>
    '$_kSocialCachePrefix::$base::v$_kSocialCacheSchema::'
    '${userId.isEmpty ? '_global' : userId}';

/// Read a JSON-typed value from the disk SWR cache.
///
/// Returns `(value, ageWithinInstantTtl)`. `value` is null on a miss, corrupt
/// blob, schema mismatch, or age beyond [_kMaxStaleTtl]. The bool is true only
/// when the blob is fresh enough to serve INSTANTLY (within [_kInstantTtl]);
/// when false but `value` is non-null the blob is stale-but-usable as a
/// network-failure fallback.
Future<({T? value, bool fresh})> _readSocialCache<T>({
  required String base,
  required String userId,
  required T Function(dynamic decoded) decode,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_socialCacheKey(base, userId));
    if (raw == null || raw.isEmpty) return (value: null, fresh: false);

    final env = jsonDecode(raw);
    if (env is! Map<String, dynamic>) return (value: null, fresh: false);
    if (env['sv'] != _kSocialCacheSchema) return (value: null, fresh: false);

    final cachedAt = env['cachedAt'];
    if (cachedAt is! int) return (value: null, fresh: false);
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    // Negative age = device clock moved backwards → treat as invalid.
    if (age < 0 || age >= _kMaxStaleTtl.inMilliseconds) {
      return (value: null, fresh: false);
    }

    final value = decode(env['data']);
    return (value: value, fresh: age < _kInstantTtl.inMilliseconds);
  } catch (e) {
    debugPrint('💾 [SocialSWR] read failed for $base: $e');
    return (value: null, fresh: false);
  }
}

/// Persist [data] (any JSON-encodable structure) in a versioned TTL envelope.
/// Best-effort — a write failure never propagates.
Future<void> _writeSocialCache({
  required String base,
  required String userId,
  required dynamic data,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final envelope = <String, dynamic>{
      'sv': _kSocialCacheSchema,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString(_socialCacheKey(base, userId), jsonEncode(envelope));
  } catch (e) {
    debugPrint('💾 [SocialSWR] write failed for $base: $e');
  }
}

/// Run a [FutureProvider] body cache-first.
///
/// 1. Read the disk cache. If a FRESH blob exists, return it immediately and
///    kick off a silent background [fetch] that writes the fresh value through
///    to disk (stale-while-revalidate — the cold-start screen is instant).
/// 2. Otherwise await [fetch]. On success, write through and return it. On
///    failure, fall back to a STALE-but-usable disk blob if one exists (so the
///    screen still shows something), else rethrow.
///
/// [base] is the cache slot name; [decode] turns the stored JSON back into [T];
/// [encode] turns a fresh [T] into a JSON-encodable structure for write-through.
Future<T> _cacheFirstFuture<T>({
  required String base,
  required String userId,
  required Future<T> Function() fetch,
  required T Function(dynamic decoded) decode,
  required dynamic Function(T value) encode,
}) async {
  final cached = await _readSocialCache<T>(
    base: base,
    userId: userId,
    decode: decode,
  );

  // ---- Fresh cache hit → instant render + silent background revalidate -----
  if (cached.value != null && cached.fresh) {
    // Revalidate in the background; never block the instant render on it.
    unawaited(() async {
      try {
        final fresh = await fetch();
        await _writeSocialCache(base: base, userId: userId, data: encode(fresh));
      } catch (e) {
        debugPrint('💾 [SocialSWR] background revalidate failed for $base: $e');
      }
    }());
    return cached.value as T;
  }

  // ---- Cold / stale cache → network fetch, write-through ------------------
  try {
    final fresh = await fetch();
    await _writeSocialCache(base: base, userId: userId, data: encode(fresh));
    return fresh;
  } catch (e) {
    // Network failed — fall back to a stale-but-usable blob if we have one so
    // the screen renders content instead of an error.
    if (cached.value != null) {
      debugPrint('💾 [SocialSWR] $base network failed — serving stale cache');
      return cached.value as T;
    }
    rethrow;
  }
}

/// Feed sort order provider (F3)
final feedSortProvider = StateProvider<String>((ref) => 'recent');

/// Activity feed provider (paginated, supports sorting via feedSortProvider).
///
/// Instant-load: resolves from the disk SWR cache on a cold start (within
/// [_kInstantTtl]) and revalidates silently, so a restart paints the cached
/// feed immediately. The cache slot is keyed by sort order so switching sort
/// modes doesn't serve the wrong list.
/// Note: Removed autoDispose to prevent refetching on navigation
final activityFeedProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    final sortBy = ref.watch(feedSortProvider);
    return _cacheFirstFuture<Map<String, dynamic>>(
      base: 'activity_feed::$sortBy',
      userId: userId,
      fetch: () => socialService.getActivityFeed(userId: userId, sortBy: sortBy),
      decode: (d) => Map<String, dynamic>.from(d as Map),
      encode: (v) => v,
    );
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

/// Friends list provider — instant-load via disk SWR cache.
/// Note: Removed autoDispose to prevent refetching on navigation
final friendsListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return _cacheFirstFuture<List<Map<String, dynamic>>>(
      base: 'friends_list',
      userId: userId,
      fetch: () => socialService.getFriends(userId: userId),
      decode: (d) => (d as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      encode: (v) => v,
    );
  },
);

/// Followers list provider (extracts items from paginated response) —
/// instant-load via disk SWR cache.
/// Note: Removed autoDispose to prevent refetching on navigation
final followersListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return _cacheFirstFuture<List<Map<String, dynamic>>>(
      base: 'followers_list',
      userId: userId,
      fetch: () async {
        final response = await socialService.getFollowers(userId: userId);
        return List<Map<String, dynamic>>.from(response['items'] ?? []);
      },
      decode: (d) => (d as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      encode: (v) => v,
    );
  },
);

/// Following list provider (extracts items from paginated response) —
/// instant-load via disk SWR cache.
/// Note: Removed autoDispose to prevent refetching on navigation
final followingListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return _cacheFirstFuture<List<Map<String, dynamic>>>(
      base: 'following_list',
      userId: userId,
      fetch: () async {
        final response = await socialService.getFollowing(userId: userId);
        return List<Map<String, dynamic>>.from(response['items'] ?? []);
      },
      decode: (d) => (d as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      encode: (v) => v,
    );
  },
);

/// Challenges list provider (all challenges with user participation) —
/// instant-load via disk SWR cache.
/// Note: Removed autoDispose to prevent refetching on navigation
final challengesListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return _cacheFirstFuture<List<Map<String, dynamic>>>(
      base: 'challenges_list',
      userId: userId,
      fetch: () => socialService.getChallenges(userId: userId),
      decode: (d) => (d as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      encode: (v) => v,
    );
  },
);

/// User's active challenges (challenges they are participating in) —
/// instant-load via disk SWR cache.
/// Note: Removed autoDispose to prevent refetching on navigation
final userActiveChallengesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return _cacheFirstFuture<List<Map<String, dynamic>>>(
      base: 'active_challenges',
      userId: userId,
      fetch: () async {
        final allChallenges = await socialService.getChallenges(userId: userId);
        // Filter to only challenges user is participating in.
        return allChallenges
            .where((c) => c['user_participation'] != null)
            .toList();
      },
      decode: (d) => (d as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      encode: (v) => v,
    );
  },
);

/// Conversations list provider (direct messages) — instant-load via disk SWR
/// cache so the messages list paints immediately on a cold start.
/// Note: Removed autoDispose to prevent refetching on navigation
final conversationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final socialService = ref.watch(socialServiceProvider);
    return _cacheFirstFuture<List<Map<String, dynamic>>>(
      base: 'conversations',
      userId: userId,
      fetch: () => socialService.getConversations(userId: userId),
      decode: (d) => (d as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      encode: (v) => v,
    );
  },
);

/// Conversation messages provider - fetches and decrypts messages.
///
/// Deliberately NOT disk-cached: messages are E2EE — persisting decrypted
/// plaintext to SharedPreferences would defeat the encryption. Riverpod's
/// in-memory cache (no autoDispose) still keeps an open thread instant within
/// a session.
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

/// Social stats provider (F7) - friends count, followers, following.
///
/// Instant-load via disk SWR cache. Kept non-autoDispose so the cached stats
/// survive navigation; the cache makes a cold start instant too.
final socialStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final socialService = ref.read(socialServiceProvider);
    return _cacheFirstFuture<Map<String, dynamic>>(
      base: 'social_stats',
      userId: userId,
      fetch: () => socialService.getSocialStats(userId: userId),
      decode: (d) => Map<String, dynamic>.from(d as Map),
      encode: (v) => v,
    );
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

/// Wipe every social SWR disk slot on this device — call on logout.
Future<void> clearSocialCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('$_kSocialCachePrefix::'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('🧹 [SocialSWR] cleared ${keys.length} social cache slots');
  } catch (e) {
    debugPrint('💾 [SocialSWR] clearSocialCache failed: $e');
  }
}
