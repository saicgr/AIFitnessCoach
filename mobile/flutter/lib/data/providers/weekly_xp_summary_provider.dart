import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weekly_xp_summary.dart';
import '../services/api_client.dart';

/// Provider for `GET /xp/weekly-summary`. FutureProvider (not autoDispose) —
/// the XP card renders on multiple screens (home, you hub, profile) and we
/// don't want a network round-trip every time the user navigates between
/// them. Invalidated by XP-earning events.
final weeklyXpSummaryProvider = FutureProvider<WeeklyXpSummary>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final resp = await api.get('/xp/weekly-summary');
    if (resp.statusCode == 200 && resp.data is Map) {
      return WeeklyXpSummary.fromJson(
        (resp.data as Map).cast<String, dynamic>(),
      );
    }
  } catch (e) {
    debugPrint('weeklyXpSummaryProvider error: $e');
  }
  return WeeklyXpSummary.empty;
});

/// Provider for `GET /xp/next-level-preview`. Returns `null` on failure so
/// the UI can hide the reward preview rather than showing a garbage chip.
final nextLevelPreviewProvider = FutureProvider<NextLevelPreview?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final resp = await api.get('/xp/next-level-preview');
    if (resp.statusCode == 200 && resp.data is Map) {
      return NextLevelPreview.fromJson(
        (resp.data as Map).cast<String, dynamic>(),
      );
    }
  } catch (e) {
    debugPrint('nextLevelPreviewProvider error: $e');
  }
  return null;
});
