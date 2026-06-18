import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Workstream F growth + social — F5 referral / deferred deep links, F8
/// do-my-workout / try-this-recipe links + level-scaled resolution, F14 Friend
/// Streak, F16 "a year ago today".
///
/// Backends: backend/api/v1/share_growth.py + backend/api/v1/friend_streak.py.
/// Deep links are self-hosted (zealova.com/s/{token}); the primary share target
/// is the https app-link [webUrl] (host-verified on both platforms).

/// A mintable share link (referral / workout / recipe / friend-streak invite).
@immutable
class ShareLink {
  final String token;
  final String webUrl; // https://zealova.com/s/{token} — PRIMARY share target
  final String deepLink; // fitwiz://s/{token} — secondary custom scheme
  final String shareUrl; // provider-resolved (Branch/OneLink seam) or webUrl

  const ShareLink({
    required this.token,
    required this.webUrl,
    required this.deepLink,
    required this.shareUrl,
  });

  factory ShareLink.fromJson(Map<String, dynamic> j) => ShareLink(
        token: j['token'] as String? ?? '',
        webUrl: j['web_url'] as String? ?? '',
        deepLink: j['deep_link'] as String? ?? '',
        shareUrl: j['share_url'] as String? ?? (j['web_url'] as String? ?? ''),
      );
}

@immutable
class ReferralLink {
  final String referralCode;
  final ShareLink link;
  const ReferralLink({required this.referralCode, required this.link});

  factory ReferralLink.fromJson(Map<String, dynamic> j) => ReferralLink(
        referralCode: j['referral_code'] as String? ?? '',
        link: ShareLink.fromJson(j),
      );
}

/// One friend streak (1:1, kind = workout|food).
@immutable
class FriendStreak {
  final String id;
  final String kind;
  final String status; // pending | active | ended
  final int currentStreak;
  final int longestStreak;
  final String? inviteCode;

  const FriendStreak({
    required this.id,
    required this.kind,
    required this.status,
    required this.currentStreak,
    required this.longestStreak,
    this.inviteCode,
  });

  factory FriendStreak.fromJson(Map<String, dynamic> j) => FriendStreak(
        id: j['id'] as String,
        kind: j['kind'] as String? ?? 'workout',
        status: j['status'] as String? ?? 'pending',
        currentStreak: j['current_streak'] as int? ?? 0,
        longestStreak: j['longest_streak'] as int? ?? 0,
        inviteCode: j['invite_code'] as String?,
      );
}

final shareGrowthRepositoryProvider = Provider<ShareGrowthRepository>((ref) {
  return ShareGrowthRepository(ref.watch(apiClientProvider));
});

class ShareGrowthRepository {
  final ApiClient _client;

  ShareGrowthRepository(this._client);

  // ── F5 referral ──────────────────────────────────────────────────────────

  /// Issue (or return) the user's referral code + deferred deep link.
  Future<ReferralLink> getReferralLink() async {
    final res = await _client.get('/share/referral-link');
    return ReferralLink.fromJson(res.data as Map<String, dynamic>);
  }

  /// Two-sided attribution: report the referral code the user installed with.
  /// Call once, right after signup. Idempotent server-side.
  Future<void> attributeReferral(String referralCode) async {
    await _client.post('/share/referral/attribute',
        data: {'referral_code': referralCode});
  }

  /// Resolve a /s/{token} share link (public; for deferred-deep-link handling).
  Future<Map<String, dynamic>> resolveLink(String token) async {
    final res = await _client.get('/s/$token');
    return (res.data as Map).cast<String, dynamic>();
  }

  // ── F8 do-my-workout / try-this-recipe ───────────────────────────────────

  Future<ShareLink> workoutLink(String workoutId) async {
    final res = await _client.get('/share/workout-link/$workoutId');
    return ShareLink.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ShareLink> recipeLink(String recipeId) async {
    final res = await _client.get('/share/recipe-link/$recipeId');
    return ShareLink.fromJson(res.data as Map<String, dynamic>);
  }

  /// Resolve a shared workout token to a workout scaled to MY fitness level.
  /// Returns the raw map ({workout, scaled_for_level, requires_install}).
  Future<Map<String, dynamic>> resolveWorkout(String token) async {
    final res = await _client.get('/share/resolve-workout/$token');
    return (res.data as Map).cast<String, dynamic>();
  }

  // ── F16 a year ago today ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> onThisDay({String? date}) async {
    final res = await _client.get('/share/on-this-day', queryParameters: {
      if (date != null) 'date': date,
    });
    return (res.data as Map).cast<String, dynamic>();
  }

  // ── F14 Friend Streak ────────────────────────────────────────────────────

  /// Create a friend-streak invite ([kind] = 'workout' | 'food') + deep link.
  Future<Map<String, dynamic>> createStreakInvite({String kind = 'workout'}) async {
    final res = await _client.post('/friend-streak/invite', data: {'kind': kind});
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> acceptStreakInvite(String inviteCode) async {
    final res = await _client
        .post('/friend-streak/accept', data: {'invite_code': inviteCode});
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<FriendStreak>> listStreaks() async {
    final res = await _client.get('/friend-streak/list');
    final raw = (res.data as Map)['streaks'] as List? ?? const [];
    return raw
        .map((e) => FriendStreak.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Re-evaluate one streak now (e.g. right after logging). Idempotent.
  Future<Map<String, dynamic>> evaluateStreak(String streakId) async {
    try {
      final res = await _client.post('/friend-streak/$streakId/evaluate');
      return (res.data as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint('❌ [FriendStreak] evaluate failed: $e');
      rethrow;
    }
  }
}
