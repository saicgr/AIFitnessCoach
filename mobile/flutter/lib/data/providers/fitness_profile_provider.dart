import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fitness_profile.dart';
import '../services/api_client.dart';

/// Lazy per-tap fitness profile for the Discover peek sheet.
/// Keyed by target user id. `autoDispose` with a 5s keepAlive so rapid
/// back-to-back taps on the same row don't fire duplicate requests, but the
/// cache doesn't grow forever.
final fitnessProfileProvider =
    FutureProvider.family.autoDispose<FitnessProfile?, String>(
  (ref, targetUserId) async {
    if (targetUserId.isEmpty) return null;

    // Keep the provider alive for 5s after the last listener drops. Prevents
    // duplicate RPC calls when the user taps a row, closes the sheet, taps it
    // again — the cached result is reused.
    final link = ref.keepAlive();
    Future.delayed(const Duration(seconds: 5), link.close);

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get('/leaderboard/user-profile/$targetUserId');
      return FitnessProfile.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('fitnessProfileProvider($targetUserId) failed: $e');
      return null;
    }
  },
);
