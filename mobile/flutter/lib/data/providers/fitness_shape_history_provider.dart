import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fitness_shape_history.dart';
import '../services/api_client.dart';

/// Time ranges the user can select on the peek-sheet scrubber.
enum FitnessHistoryRange {
  oneDay,
  threeDays,
  sevenDays,
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  ytd,
}

extension FitnessHistoryRangeX on FitnessHistoryRange {
  String get label => switch (this) {
        FitnessHistoryRange.oneDay => '1D',
        FitnessHistoryRange.threeDays => '3D',
        FitnessHistoryRange.sevenDays => '7D',
        FitnessHistoryRange.oneWeek => '1W',
        FitnessHistoryRange.oneMonth => '1M',
        FitnessHistoryRange.threeMonths => '3M',
        FitnessHistoryRange.sixMonths => '6M',
        FitnessHistoryRange.oneYear => '1Y',
        FitnessHistoryRange.ytd => 'YTD',
      };

  /// Days-back to request from the backend.
  int resolveDays() {
    final now = DateTime.now();
    switch (this) {
      case FitnessHistoryRange.oneDay:
        return 1;
      case FitnessHistoryRange.threeDays:
        return 3;
      case FitnessHistoryRange.sevenDays:
        return 7;
      case FitnessHistoryRange.oneWeek:
        return 7;
      case FitnessHistoryRange.oneMonth:
        return 30;
      case FitnessHistoryRange.threeMonths:
        return 90;
      case FitnessHistoryRange.sixMonths:
        return 180;
      case FitnessHistoryRange.oneYear:
        return 365;
      case FitnessHistoryRange.ytd:
        final jan1 = DateTime(now.year, 1, 1);
        final days = now.difference(jan1).inDays + 1;
        return days < 1 ? 1 : days;
    }
  }
}

/// Key for the provider family: (targetUserId, days). We key by days so
/// switching ranges doesn't require a new user id.
@immutable
class FitnessHistoryKey {
  final String userId;
  final int days;
  const FitnessHistoryKey(this.userId, this.days);

  @override
  bool operator ==(Object other) =>
      other is FitnessHistoryKey &&
      other.userId == userId &&
      other.days == days;

  @override
  int get hashCode => Object.hash(userId, days);
}

/// Dual-series fitness snapshot history powering the peek-sheet scrubber.
final fitnessShapeHistoryProvider = FutureProvider.family
    .autoDispose<FitnessShapeHistory?, FitnessHistoryKey>(
  (ref, key) async {
    if (key.userId.isEmpty) return null;

    // Keep alive briefly after the sheet closes so re-tapping the same user
    // avoids a second round-trip.
    final link = ref.keepAlive();
    Future.delayed(const Duration(seconds: 10), link.close);

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get(
        '/leaderboard/user-profile/${key.userId}/history',
        queryParameters: {'days': key.days},
      );
      return FitnessShapeHistory.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('fitnessShapeHistoryProvider(${key.userId}, ${key.days}) failed: $e');
      return null;
    }
  },
);
