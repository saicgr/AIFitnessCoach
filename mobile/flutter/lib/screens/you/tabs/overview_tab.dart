/// Overview tab body for the You hub.
///
/// The at-a-glance landing screen. Pulls the headline number from each of
/// the consolidated surfaces (XP, Trophies, Achievements/Streaks, Skills,
/// Wrapped, Rewards, Inventory-via-rewards-count, Leaderboard) and renders
/// them as a single scrollable dashboard. Tapping any card deep-links to
/// the detail screen for that surface.
///
/// Data sources:
///   • `userXpProvider` (backed by `/progress/xp/{id}`)   → level + XP bar
///   • `unclaimedCratesCountProvider` (repo-backed)       → rewards ready count
///   • /achievements/user/{id}/streaks                    → active streaks row
///   • /summaries/user/{id}/latest                        → last weekly recap
///   • /trophies/{id}/summary + /trophies/{id}/recent     → earned-of-total + latest trophy
///   • /skill-progressions/user/{id}/summary              → active skill step
///   • /leaderboard/unlock-status → /leaderboard/rank     → social percentile (or unlock progress)
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/xp_hero_tile.dart';
import '../../home/widgets/cards/last_night_sleep_card.dart';
import '../../home/widgets/cards/todays_health_card.dart';
import '../widgets/weight_tracking_card.dart';

/// Module-level in-memory cache for the Overview tab.
///
/// Mirrors the `_xpInMemoryCache` pattern used by `xp_provider.dart` —
/// keeps the last successful payload alive across tab switches so reopening
/// the You hub renders instantly from cache while a silent refresh runs in
/// the background. Without this, every tab switch refetched 6+ endpoints
/// and showed a spinner for ~1.5s on a warm device.
///
/// Cleared in two places:
///   • `AppLifecycleState.resumed` if the cache is older than 5 minutes
///   • Manual refresh button (refresh icon in AppBar / pull-to-refresh)
class _OverviewCache {
  List<dynamic>? streaks;
  Map<String, dynamic>? latestSummary;
  Map<String, dynamic>? trophySummary;
  List<dynamic>? recentTrophies;
  Map<String, dynamic>? skillsSummary;
  bool? leaderboardUnlocked;
  int workoutsNeeded = 10;
  double? percentile;
  DateTime? cachedAt;

  bool get hasData => cachedAt != null;

  Duration get age =>
      cachedAt == null ? Duration.zero : DateTime.now().difference(cachedAt!);

  void clear() {
    streaks = null;
    latestSummary = null;
    trophySummary = null;
    recentTrophies = null;
    skillsSummary = null;
    leaderboardUnlocked = null;
    workoutsNeeded = 10;
    percentile = null;
    cachedAt = null;
  }
}

/// Single shared cache instance — survives tab swaps inside the You hub
/// because it lives at module scope, not in widget state.
final _overviewCache = _OverviewCache();

/// Stale threshold for the lifecycle-resumed invalidation. Anything older
/// than 5 minutes gets a forced background refresh. Within the window we
/// trust the cache and skip the network entirely.
const Duration _overviewStaleAfter = Duration(minutes: 5);

class YouOverviewTab extends ConsumerStatefulWidget {
  const YouOverviewTab({super.key});

  @override
  ConsumerState<YouOverviewTab> createState() => _YouOverviewTabState();
}

class _YouOverviewTabState extends ConsumerState<YouOverviewTab>
    with WidgetsBindingObserver {
  // Local mirrors of the module-level cache — populated synchronously in
  // `initState` so the first frame after a tab switch already has data.
  List<dynamic>? _streaks;
  Map<String, dynamic>? _latestSummary;
  Map<String, dynamic>? _trophySummary;
  List<dynamic>? _recentTrophies;
  Map<String, dynamic>? _skillsSummary;
  bool? _leaderboardUnlocked;
  int _workoutsNeeded = 10;
  double? _percentile;

  /// True only on the first-ever render with no cached data. Drives the
  /// skeleton placeholder; subsequent silent refreshes never flip this back
  /// to true so users don't see the skeleton flash on every refresh.
  bool _firstLoad = true;

  /// True while a silent background refresh is in flight. Used to suppress
  /// duplicate refresh kicks but does NOT block rendering.
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Hydrate from module-level cache synchronously so the first frame
    // already has data — no spinner, no skeleton flash for repeat opens.
    if (_overviewCache.hasData) {
      _hydrateFromCache();
      _firstLoad = false;
      // Spawn a silent background refresh so the user gets fresh data
      // without ever seeing a loading indicator.
      unawaited(_load(silent: true));
    } else {
      // First-ever open — let the skeleton render and kick off the fetch.
      unawaited(_load(silent: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // On resume: invalidate health caches unconditionally (steps tick
      // every minute when the user is walking), but only re-fetch the
      // dashboard payload if the in-memory cache is older than 5 min.
      // This mirrors the stale-while-revalidate pattern documented in
      // `feedback_instant_data.md` — never make the user pull to refresh.
      ref.read(dailyActivityProvider.notifier).invalidateCache();
      final sync = ref.read(healthSyncProvider);
      if (sync.isConnected) {
        unawaited(
          ref.read(dailyActivityProvider.notifier).loadTodayActivity(force: true),
        );
        // Issue 12: also backfill the past 30 days so days the user walked
        // but didn't open the app (e.g. April 23) appear in the synced
        // workouts grid. Cheap — gated server-side by date matching.
        unawaited(
          ref.read(dailyActivityProvider.notifier).backfillRecentActivity(),
        );
      }

      if (!_overviewCache.hasData ||
          _overviewCache.age > _overviewStaleAfter) {
        unawaited(_load(silent: true));
      }
    }
  }

  /// Copy the module-level cache into widget state. Cheap — these are
  /// reference assignments, not deep copies.
  void _hydrateFromCache() {
    _streaks = _overviewCache.streaks;
    _latestSummary = _overviewCache.latestSummary;
    _trophySummary = _overviewCache.trophySummary;
    _recentTrophies = _overviewCache.recentTrophies;
    _skillsSummary = _overviewCache.skillsSummary;
    _leaderboardUnlocked = _overviewCache.leaderboardUnlocked;
    _workoutsNeeded = _overviewCache.workoutsNeeded;
    _percentile = _overviewCache.percentile;
  }

  /// Pull the latest payload. When [silent] is true the UI keeps showing
  /// whatever it has (cache or last-good values) — used for tab-reopen and
  /// lifecycle-resumed paths so users never stare at a spinner. When false
  /// (first-ever open, manual refresh) we flip `_firstLoad` so the skeleton
  /// shows.
  ///
  /// Each of the 6 dashboard endpoints fetches independently — a single
  /// failure cannot blank-out the rest. Network errors during a silent
  /// refresh surface as a non-blocking SnackBar but DO NOT clear the cache.
  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) {
      setState(() => _firstLoad = !_overviewCache.hasData);
    }

    final api = ref.read(apiClientProvider);
    final userId = await api.getUserId();
    if (userId == null) {
      _refreshing = false;
      if (mounted) setState(() => _firstLoad = false);
      return;
    }

    // XP refresh fires off independently — its provider has its own cache.
    unawaited(ref.read(xpProvider.notifier).loadUserXP(userId: userId));

    // 15s receive-timeout: the leaderboard snapshot + achievements summary
    // queries are heavier than the rest; 8s starved them into `—` states.
    final opts = Options(
      sendTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (s) => s != null && s < 500,
    );

    // Per-call try/catch so a single failure (e.g. the leaderboard endpoint
    // 500s) doesn't kill the other 5 calls. This replaces the old
    // `Future.wait([...])` fail-fast pattern.
    Future<Response<dynamic>?> safeGet(
      String path, {
      Map<String, dynamic>? query,
    }) async {
      try {
        return await api.dio
            .get(path, queryParameters: query, options: opts);
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait<Response<dynamic>?>([
      safeGet('/achievements/user/$userId/streaks'),
      safeGet('/summaries/user/$userId/latest'),
      safeGet('/progress/trophies/$userId/summary'),
      safeGet('/progress/trophies/$userId/recent', query: {'limit': 1}),
      safeGet('/skill-progressions/user/$userId/summary'),
      safeGet('/leaderboard/unlock-status', query: {'user_id': userId}),
    ], eagerError: false);

    int errorCount = 0;
    void countErr(Response<dynamic>? r) {
      if (r == null || r.statusCode != 200) errorCount++;
    }

    final streaksRes = results[0];
    countErr(streaksRes);
    if (streaksRes?.statusCode == 200) {
      final data = streaksRes!.data;
      if (data is List) _streaks = data;
      if (data is Map && data['streaks'] is List) {
        _streaks = data['streaks'] as List;
      }
    }
    final latestRes = results[1];
    countErr(latestRes);
    if (latestRes?.statusCode == 200 && latestRes!.data is Map) {
      _latestSummary = (latestRes.data as Map).cast<String, dynamic>();
    }
    final trophySumRes = results[2];
    countErr(trophySumRes);
    if (trophySumRes?.statusCode == 200 && trophySumRes!.data is Map) {
      _trophySummary = (trophySumRes.data as Map).cast<String, dynamic>();
    }
    final trophyRecentRes = results[3];
    countErr(trophyRecentRes);
    if (trophyRecentRes?.statusCode == 200 && trophyRecentRes!.data is List) {
      _recentTrophies = trophyRecentRes.data as List;
    }
    final skillsRes = results[4];
    countErr(skillsRes);
    if (skillsRes?.statusCode == 200 && skillsRes!.data is Map) {
      _skillsSummary = (skillsRes.data as Map).cast<String, dynamic>();
    }
    final unlockRes = results[5];
    countErr(unlockRes);
    if (unlockRes?.statusCode == 200 && unlockRes!.data is Map) {
      final m = (unlockRes.data as Map).cast<String, dynamic>();
      _leaderboardUnlocked = m['is_unlocked'] as bool? ?? false;
      _workoutsNeeded = (m['workouts_needed'] as num?)?.toInt() ?? 10;
      if (_leaderboardUnlocked == true) {
        try {
          final rankRes = await api.dio.get('/leaderboard/rank',
              queryParameters: {'user_id': userId}, options: opts);
          if (rankRes.statusCode == 200 && rankRes.data is Map) {
            final rm = (rankRes.data as Map).cast<String, dynamic>();
            _percentile = (rm['percentile'] as num?)?.toDouble();
          }
        } catch (_) {
          // Rank fetch is best-effort — keep last-known percentile.
        }
      }
    }

    // Only stamp the cache if at least one call succeeded. A full-blackout
    // refresh (no internet) keeps the previous cache intact.
    if (errorCount < 6) {
      _overviewCache
        ..streaks = _streaks
        ..latestSummary = _latestSummary
        ..trophySummary = _trophySummary
        ..recentTrophies = _recentTrophies
        ..skillsSummary = _skillsSummary
        ..leaderboardUnlocked = _leaderboardUnlocked
        ..workoutsNeeded = _workoutsNeeded
        ..percentile = _percentile
        ..cachedAt = DateTime.now();
    }

    _refreshing = false;
    if (!mounted) return;
    setState(() => _firstLoad = false);

    // Surface a non-blocking banner if EVERYTHING failed during a silent
    // refresh — but only if we have a cache to fall back on, otherwise the
    // empty-state copy already tells the user there's nothing to show.
    if (silent && errorCount == 6 && _overviewCache.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't refresh. Showing cached data."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Manual refresh — invalidates BOTH the dashboard cache and the health
  /// activity cache so users get truly-fresh numbers when they tap refresh.
  Future<void> _manualRefresh() async {
    _overviewCache.clear();
    ref.read(dailyActivityProvider.notifier).invalidateCache();
    final sync = ref.read(healthSyncProvider);
    if (sync.isConnected) {
      unawaited(
        ref.read(dailyActivityProvider.notifier).loadTodayActivity(force: true),
      );
    }
    await _load(silent: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);

    // First-ever open with no cache → render a skeleton, NOT a spinner.
    // Skeleton communicates layout earlier and avoids the "white screen
    // with a wheel" feel that competitors abandoned years ago.
    if (_firstLoad && !_overviewCache.hasData) {
      return _OverviewSkeleton(fg: fg);
    }

    final serious = ref.watch(seriousModeProvider);

    return RefreshIndicator(
      color: accent,
      onRefresh: _manualRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Inline header with refresh button. The You hub host doesn't
          // give us an AppBar, so we render the refresh affordance inline
          // at the top of the scroll view. Tapping it invalidates BOTH the
          // dashboard cache and the health caches.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                color: fg.withValues(alpha: 0.7),
                tooltip: 'Refresh',
                onPressed: _refreshing ? null : _manualRefresh,
              ),
            ],
          ),
          // HEALTH SNAPSHOT — first thing the user sees on the You tab.
          // Each card auto-hides via SizedBox.shrink when it has nothing
          // to show (no Health Connect connection, no sleep last night,
          // no weight log), so first-day users still see a clean Overview
          // headed by XpHeroTile.
          const TodaysHealthCard(),
          const SizedBox(height: 12),
          const LastNightSleepCard(),
          const SizedBox(height: 12),
          const WeightTrackingCard(),
          const SizedBox(height: 14),

          // Hero XP tile — three rows (weekly XP + sparkline, level +
          // progress + reward preview, streak + nudge). Reads directly
          // from `userXpProvider` + `weeklyXpSummaryProvider` +
          // `nextLevelPreviewProvider` so every surface that renders it
          // stays in sync with the rest of the app.
          XpHeroTile(muted: serious),
          const SizedBox(height: 14),
          // Recent trophy + active skill side-by-side. Each block silently
          // hides if there's nothing to show, so new users don't see
          // "—" chrome with no content underneath.
          //
          // `IntrinsicHeight` is required: the Row uses
          // `CrossAxisAlignment.stretch` so both cards match heights, but
          // inside a ListView the vertical axis is unbounded. Without
          // IntrinsicHeight, stretch tries to expand to infinity and
          // throws `BoxConstraints forces an infinite height`, which
          // cascades into `parentDataDirty` assertions downstream.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _RecentTrophyCard(
                    summary: _trophySummary,
                    recent: _recentTrophies,
                    fg: fg,
                    accent: accent,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActiveSkillCard(
                    summary: _skillsSummary,
                    fg: fg,
                    accent: accent,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_latestSummary != null) ...[
            _WeeklyRecapTeaser(summary: _latestSummary!, fg: fg, accent: accent),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: _RewardsReadyCard(
                  fg: fg,
                  accent: accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LeaderboardCard(
                  unlocked: _leaderboardUnlocked,
                  workoutsNeeded: _workoutsNeeded,
                  percentile: _percentile,
                  fg: fg,
                  accent: accent,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          // Streaks row hidden in Serious Mode — the most game-y surface.
          if (!serious) ...[
            const SizedBox(height: 14),
            _StreaksRow(streaks: _streaks, fg: fg, accent: accent),
          ],
          const SizedBox(height: 24),
          Text(
            serious
                ? 'Stats & Rewards tab has all the extras.'
                : 'Everything else — full trophy room, achievements, skills, '
                    'rewards, inventory — lives in Stats & Rewards.',
            style: TextStyle(
              color: fg.withValues(alpha: 0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}


/// First-load skeleton placeholder. Mirrors the shape of the real Overview
/// (health card, sleep card, hero XP tile, two side-by-side cards, recap)
/// so the layout doesn't reflow when the data lands. Uses the same neutral
/// surface treatment as the real cards (low-alpha fg) — no shimmer, since
/// the warm-cache path renders in <16ms anyway and shimmer would only show
/// on truly first-ever opens.
class _OverviewSkeleton extends StatelessWidget {
  final Color fg;
  const _OverviewSkeleton({required this.fg});

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        block(160), // Today's Health
        block(140), // Last night sleep
        block(80), // Weight tracking
        block(180), // Hero XP tile
        Row(
          children: [
            Expanded(child: block(120)),
            const SizedBox(width: 10),
            Expanded(child: block(120)),
          ],
        ),
        block(60), // Weekly recap teaser
      ],
    );
  }
}

class _WeeklyRecapTeaser extends StatelessWidget {
  final Map<String, dynamic> summary;
  final Color fg;
  final Color accent;
  const _WeeklyRecapTeaser({
    required this.summary,
    required this.fg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = summary['week_start'] as String? ?? '';
    final workouts = summary['workouts_completed'] ?? 0;
    final prs = summary['prs_achieved'] ?? 0;

    return GestureDetector(
      onTap: () => context.push(
        weekStart.isNotEmpty
            ? '/weekly-wrapped?week_start=$weekStart'
            : '/weekly-wrapped',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last week',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$workouts workouts • $prs PRs',
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: fg.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _StreaksRow extends StatelessWidget {
  final List<dynamic>? streaks;
  final Color fg;
  final Color accent;

  const _StreaksRow({required this.streaks, required this.fg, required this.accent});

  @override
  Widget build(BuildContext context) {
    final items = streaks ?? const [];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE STREAKS',
          style: TextStyle(
            color: fg.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final s = items[i] as Map<String, dynamic>;
              final type = (s['streak_type'] as String? ?? 'streak')
                  .replaceAll('_', ' ');
              final count = (s['current_streak'] as num?)?.toInt() ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            color: fg,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentTrophyCard extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final List<dynamic>? recent;
  final Color fg;
  final Color accent;
  final bool isDark;
  const _RecentTrophyCard({
    required this.summary,
    required this.recent,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final earned = (summary?['earned_trophies'] as num?)?.toInt() ?? 0;
    final total = (summary?['total_trophies'] as num?)?.toInt() ?? 0;

    String headline;
    String sub;
    String icon = '🏆';
    if (recent != null && recent!.isNotEmpty) {
      final first = recent!.first as Map;
      final trophy = first['trophy'];
      if (trophy is Map) {
        headline = trophy['name'] as String? ?? 'Trophy earned';
        sub = 'Recently earned · tap to view';
        icon = (trophy['icon'] as String?) ?? '🏆';
      } else {
        headline = 'Recent trophy';
        sub = 'Tap to view';
      }
    } else if (total > 0) {
      headline = '$earned / $total';
      sub = 'earned so far';
    } else {
      headline = 'Trophies';
      sub = 'No trophies yet';
    }

    return _HeadlineTile(
      leadingEmoji: icon,
      title: 'RECENT TROPHY',
      headline: headline,
      sub: sub,
      fg: fg,
      accent: accent,
      isDark: isDark,
      route: '/trophy-room',
    );
  }
}

class _ActiveSkillCard extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final Color fg;
  final Color accent;
  final bool isDark;
  const _ActiveSkillCard({
    required this.summary,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final active = (summary?['active_progressions'] as List?) ?? const [];
    String headline;
    String sub;
    if (active.isNotEmpty) {
      final first = active.first;
      if (first is Map) {
        final chainName = first['chain_name'] as String? ?? 'Active skill';
        final stepName =
            first['current_step_name'] as String? ?? 'Step';
        final pct = (first['progress_percentage'] as num?)?.toInt() ?? 0;
        headline = chainName;
        sub = '$stepName · $pct%';
      } else {
        headline = 'Active skill';
        sub = 'In progress';
      }
    } else {
      final recommended = summary?['recommended_next_chain'];
      if (recommended is Map) {
        headline = recommended['name'] as String? ?? 'Start a skill';
        sub = 'Try this next';
      } else {
        headline = 'Skills';
        sub = 'Start a chain';
      }
    }

    return _HeadlineTile(
      leadingIcon: Icons.timeline_rounded,
      title: 'ACTIVE SKILL',
      headline: headline,
      sub: sub,
      fg: fg,
      accent: accent,
      isDark: isDark,
      route: '/skills',
    );
  }
}

/// Rewards-ready headline tile. Reads `unclaimedCratesCountProvider`
/// (canonical, repo-backed) rather than the removed `/xp/unclaimed-crates`
/// raw endpoint call.
class _RewardsReadyCard extends ConsumerWidget {
  final Color fg;
  final Color accent;
  final bool isDark;
  const _RewardsReadyCard({
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(unclaimedCratesCountProvider);
    return _HeadlineTile(
      leadingIcon: Icons.card_giftcard_rounded,
      title: 'REWARDS',
      headline: ready > 0 ? '$ready ready' : 'View perks',
      sub: ready > 0 ? 'Tap to claim' : 'Redeem benefits',
      fg: fg,
      accent: accent,
      isDark: isDark,
      route: '/rewards',
      highlight: ready > 0,
    );
  }
}

/// Leaderboard headline tile with three legible states:
///   • unlocked + percentile known → "Top N%" / "on global leaderboard"
///   • locked                      → progress-to-unlock ("7 more workouts")
///   • unknown (unlock-status failed) → generic leaderboard launcher
///
/// Phase 1 just stops showing `—` forever. Phase 3 redesigns this to a
/// challenge-based card (auto-enrolled weekly challenge by default).
class _LeaderboardCard extends StatelessWidget {
  final bool? unlocked;
  final int workoutsNeeded;
  final double? percentile;
  final Color fg;
  final Color accent;
  final bool isDark;
  const _LeaderboardCard({
    required this.unlocked,
    required this.workoutsNeeded,
    required this.percentile,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    String headline;
    String sub;
    if (unlocked == false) {
      // Locked: surface exactly how far the user is from unlocking instead
      // of leaving them staring at "—". Copy reads naturally for 1 vs N.
      headline = workoutsNeeded == 1
          ? '1 to unlock'
          : '$workoutsNeeded to unlock';
      sub = workoutsNeeded == 1
          ? 'Log 1 more workout'
          : 'Log $workoutsNeeded more workouts';
    } else if (percentile != null) {
      final topPct = (100 - percentile!).toStringAsFixed(0);
      headline = 'Top $topPct%';
      sub = 'on global leaderboard';
    } else {
      headline = 'Leaderboard';
      sub = 'Compare with friends';
    }

    return _HeadlineTile(
      leadingIcon: Icons.leaderboard_rounded,
      title: 'SOCIAL',
      headline: headline,
      sub: sub,
      fg: fg,
      accent: accent,
      isDark: isDark,
      route: '/xp-leaderboard',
    );
  }
}

/// Shared tile used across the Overview dashboard. One of `leadingIcon` or
/// `leadingEmoji` must be provided. `highlight` toggles an accent border —
/// used for "action-ready" cards (e.g. rewards ready to claim).
class _HeadlineTile extends StatelessWidget {
  final IconData? leadingIcon;
  final String? leadingEmoji;
  final String title;
  final String headline;
  final String sub;
  final Color fg;
  final Color accent;
  final bool isDark;
  final String route;
  final bool highlight;

  const _HeadlineTile({
    this.leadingIcon,
    this.leadingEmoji,
    required this.title,
    required this.headline,
    required this.sub,
    required this.fg,
    required this.accent,
    required this.isDark,
    required this.route,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = highlight
        ? accent.withValues(alpha: 0.55)
        : fg.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(route);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: highlight ? 1.3 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: leadingEmoji != null
                  ? Text(leadingEmoji!, style: const TextStyle(fontSize: 18))
                  : Icon(leadingIcon, color: accent, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: fg.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              headline,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                color: fg.withValues(alpha: 0.55),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
