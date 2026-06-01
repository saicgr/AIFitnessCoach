import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/health_service.dart';
import '../services/mindfulness_service.dart';

/// Today's mindful minutes — the in-app server aggregate merged with Apple
/// Health "Mindful Minutes" on iOS. Drives the home mindful-minutes ring and
/// the metrics dashboard card; both `watch` this single provider so a logged
/// session updates everywhere at once.
///
/// Returns null when no user is resolved or the server call fails, so the UI
/// can render an honest empty/error state rather than a fabricated 0.
final mindfulnessTodayProvider =
    FutureProvider.autoDispose<MindfulnessToday?>((ref) async {
  ref.keepAlive();
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return null;

  final server = await ref.watch(mindfulnessServiceProvider).getToday(userId);
  if (server == null) return null;

  // iOS HealthKit MINDFULNESS merge — max(), never sum. We don't write
  // MINDFULNESS back to Apple Health, so an in-app session and a HealthKit
  // session are usually the SAME activity surfaced twice; max() avoids
  // inflation (plan edge case B3). On Android getTodayMindfulnessMinutes()
  // returns 0 by design (Play minimum-scope), so the in-app aggregate stands.
  var merged = server.minutes;
  try {
    final hk = await ref.watch(healthServiceProvider).getTodayMindfulnessMinutes();
    if (hk > merged) merged = hk;
  } catch (_) {
    // HealthKit unavailable / permission denied — optional source, ignore.
  }

  return server.copyWith(minutes: merged);
});

/// 7-day mindful-minutes history for the sparkline.
final mindfulnessHistoryProvider =
    FutureProvider.autoDispose<List<MindfulnessDayPoint>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return const [];
  return ref.watch(mindfulnessServiceProvider).getHistory(userId, days: 7);
});

/// Log a completed mindfulness session, then refresh the today + history
/// providers. Returns the server's new today-total (or null on failure — the
/// caller surfaces the error rather than pretending it logged).
Future<MindfulnessToday?> logMindfulnessSession(
  WidgetRef ref, {
  required String source,
  String? meditationSlug,
  required int durationSeconds,
}) async {
  final result = await ref.read(mindfulnessServiceProvider).logSession(
        source: source,
        meditationSlug: meditationSlug,
        durationSeconds: durationSeconds,
      );
  ref.invalidate(mindfulnessTodayProvider);
  ref.invalidate(mindfulnessHistoryProvider);
  return result;
}
