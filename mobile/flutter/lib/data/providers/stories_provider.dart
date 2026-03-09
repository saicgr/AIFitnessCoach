import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'social_provider.dart';

/// Stories feed provider (F11) - stories from friends
/// Re-exports from social_provider.dart for convenience and additional providers.
///
/// The primary storiesFeedProvider and storyViewsProvider are defined in
/// social_provider.dart. This file provides additional story-specific providers.

/// Provider that groups stories by user for the stories ring display
final storiesByUserProvider =
    FutureProvider.autoDispose<Map<String, List<Map<String, dynamic>>>>((ref) async {
  final stories = await ref.watch(storiesFeedProvider.future);
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (final story in stories) {
    final userId = story['user_id'] as String? ?? '';
    grouped.putIfAbsent(userId, () => []).add(story);
  }
  return grouped;
});

/// Provider that returns the count of unseen stories
final unseenStoriesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final stories = await ref.watch(storiesFeedProvider.future);
  return stories.where((s) => !(s['viewed'] as bool? ?? false)).length;
});
