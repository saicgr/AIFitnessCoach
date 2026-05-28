import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../models/discover_snapshot.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// W2: selected board + scope filters for the Discover tab.
final discoverBoardProvider = StateProvider<String>((_) => 'xp');
final discoverScopeProvider = StateProvider<String>((_) => 'global');

/// Instant-load standard (Part 2) for the Discover tab.
///
/// Discover used to block on a centered `CircularProgressIndicator` on every
/// cold start because its snapshot lived only in memory and was lost on app
/// restart. This notifier adds a disk cache (via [CacheFirstMixin]) keyed per
/// `board + scope` so a restart paints the last-seen leaderboard instantly
/// while a fresh copy is fetched silently in the background.
///
/// Behaviour preserved from the old `FutureProvider`:
///  - Auto-reloads whenever `discoverBoardProvider` / `discoverScopeProvider`
///    change (the provider `watch`es both and re-runs `load()`).
///  - On a board toggle the PREVIOUS snapshot stays on screen (state keeps the
///    last `AsyncData`) while the new board's data loads — never blanks.
///  - The screen's own stale-window silent refresh keeps working: a
///    `ref.invalidate` rebuilds this notifier, which again serves the cached
///    value first, then revalidates over the network.
class DiscoverSnapshotNotifier
    extends StateNotifier<AsyncValue<DiscoverSnapshot?>>
    with CacheFirstMixin {
  DiscoverSnapshotNotifier({
    required ApiClient client,
    required String board,
    required String scope,
    required String userId,
  })  : _client = client,
        _board = board,
        _scope = scope,
        _userId = userId,
        super(const AsyncValue.loading()) {
    load();
  }

  final ApiClient _client;
  final String _board;
  final String _scope;
  final String _userId;

  /// Bump when the cached JSON shape changes (mirrors `DiscoverSnapshot`
  /// fields). A mismatch silently drops the old blob — never decodes a
  /// wrong-shaped payload into a crashing object.
  static const int _schemaVersion = 1;

  /// Cache-first load. Reads the per-board+scope disk blob first (instant
  /// paint), then fetches the network copy and writes it through so the next
  /// cold start is instant too. Never throws.
  Future<void> load() async {
    await loadCacheFirst<DiscoverSnapshot>(
      // Distinct disk slot per board + scope so toggling XP/Volume/Streaks
      // each restores its own last-seen snapshot independently.
      cacheKey: 'discover_snapshot::${_board}__$_scope',
      userId: _userId,
      // ~5-min TTL: long enough that a quick restart is instant, short enough
      // that the leaderboard never looks badly out of date.
      ttl: const Duration(minutes: 5),
      schemaVersion: _schemaVersion,
      fetch: _fetch,
      decode: DiscoverSnapshot.fromJson,
      encode: _encodeSnapshot,
      emit: (data, {required bool fromCache}) {
        // Called up to twice — cached value first (instant), then fresh.
        if (!mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (e, st) {
        // Only fires when the NETWORK fetch fails. If a cached value was
        // already emitted it stays on screen. Otherwise surface a real ERROR
        // state (not `data(null)`) so the screen shows a distinct
        // network-error UI with a retry — an empty-data state would wrongly
        // read as "nothing here" when the truth is "couldn't load".
        if (!mounted) return;
        try {
          if (state.valueOrNull == null) {
            state = AsyncValue.error(e, st);
          }
        } catch (_) {
          // Notifier disposed between the mounted check and the state read.
        }
      },
    );
  }

  /// Network fetch for the currently-selected board + scope.
  Future<DiscoverSnapshot> _fetch() async {
    final response = await _client.get(
      '/leaderboard/discover',
      queryParameters: {'board': _board, 'scope': _scope},
    );
    return DiscoverSnapshot.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Loads the full Discover snapshot for the currently-selected board + scope,
/// cache-first. Auto-refreshes when either filter (or the auth user) changes.
final discoverSnapshotProvider =
    StateNotifierProvider<DiscoverSnapshotNotifier, AsyncValue<DiscoverSnapshot?>>(
  (ref) {
    final board = ref.watch(discoverBoardProvider);
    final scope = ref.watch(discoverScopeProvider);
    final client = ref.watch(apiClientProvider);
    // User-scope the disk cache so two accounts on one device never share a
    // leaderboard slot. Empty string is tolerated by CacheFirstMixin (global
    // slot + a debug warning) for the rare unauthenticated render.
    final userId = ref.watch(authStateProvider).user?.id ?? '';
    return DiscoverSnapshotNotifier(
      client: client,
      board: board,
      scope: scope,
      userId: userId,
    );
  },
);

// ─── Serialization ──────────────────────────────────────────────────────────

/// Encodes a [DiscoverSnapshot] back into the exact JSON shape its
/// `fromJson` expects, so a round-trip through the disk cache is lossless.
/// `DiscoverSnapshot` ships only a `fromJson` (it is a read-only API DTO), so
/// the write-through encoder lives here next to the cache that needs it.
Map<String, dynamic> _encodeSnapshot(DiscoverSnapshot s) => {
      'board': s.board,
      'scope': s.scope,
      'week_start': s.weekStart,
      'your_rank': s.yourRank,
      'your_percentile': s.yourPercentile,
      'your_tier': s.yourTier,
      'your_metric': s.yourMetric,
      'total_active': s.totalActive,
      'next_tier': s.nextTier,
      'units_to_next': s.unitsToNext,
      'metric_label': s.metricLabel,
      'near_you': s.nearYou.map(_encodeEntry).toList(),
      'rising_stars': s.risingStars.map(_encodeRisingStar).toList(),
      'top_10': s.top10.map(_encodeEntry).toList(),
      'your_tier_streak_weeks': s.yourTierStreakWeeks,
      'your_peak_tier': s.yourPeakTier,
      'your_next_milestone_weeks': s.yourNextMilestoneWeeks,
      'your_next_milestone_xp': s.yourNextMilestoneXp,
      'your_weekly_xp_unranked': s.yourWeeklyXpUnranked,
    };

/// Encodes a [DiscoverEntry] — keys mirror `DiscoverEntry.fromJson`.
Map<String, dynamic> _encodeEntry(DiscoverEntry e) => {
      'user_id': e.userId,
      'username': e.username,
      'display_name': e.displayName,
      'avatar_url': e.avatarUrl,
      'rank': e.rank,
      'metric_value': e.metricValue,
      'is_current_user': e.isCurrentUser,
      'is_anonymous': e.isAnonymous,
      'current_level': e.currentLevel,
      'previous_rank': e.previousRank,
      'rank_delta': e.rankDelta,
      'current_streak': e.currentStreak,
      'hit_pr_this_week': e.prThisWeek,
      'country_code': e.countryCode,
      // Stored as ISO-8601; `_parseIsoDate` reads it back on decode.
      'last_active_at': e.lastActiveAt?.toIso8601String(),
      'peak_tier': e.peakTier,
    };

/// Encodes a [DiscoverRisingStar] — keys mirror `DiscoverRisingStar.fromJson`.
Map<String, dynamic> _encodeRisingStar(DiscoverRisingStar s) => {
      'user_id': s.userId,
      'username': s.username,
      'display_name': s.displayName,
      'avatar_url': s.avatarUrl,
      'current_rank': s.currentRank,
      'previous_rank': s.previousRank,
      'rank_delta': s.rankDelta,
      'metric_value': s.metricValue,
      'is_anonymous': s.isAnonymous,
      'current_level': s.currentLevel,
      'current_streak': s.currentStreak,
      'hit_pr_this_week': s.prThisWeek,
      'country_code': s.countryCode,
      'last_active_at': s.lastActiveAt?.toIso8601String(),
      'peak_tier': s.peakTier,
    };
