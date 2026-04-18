import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover_snapshot.dart';
import '../services/api_client.dart';

/// W2: selected board + scope filters for the Discover tab.
final discoverBoardProvider = StateProvider<String>((_) => 'xp');
final discoverScopeProvider = StateProvider<String>((_) => 'global');

/// Loads the full Discover snapshot for the currently-selected board + scope.
/// Auto-refreshes when either filter changes.
final discoverSnapshotProvider = FutureProvider<DiscoverSnapshot?>((ref) async {
  final board = ref.watch(discoverBoardProvider);
  final scope = ref.watch(discoverScopeProvider);
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get(
      '/leaderboard/discover',
      queryParameters: {'board': board, 'scope': scope},
    );
    return DiscoverSnapshot.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('discoverSnapshotProvider failed: $e');
    return null;
  }
});
