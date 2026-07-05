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

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/health_service.dart';
import '../../../data/services/you_overview_prewarmer.dart';
import '../you_hub_screen.dart' show kYouHubBodyBottomInset;
import '../../../widgets/xp_hero_tile.dart';
import '../../home/widgets/habits_section.dart';
import '../widgets/health_overview_card.dart';
import '../widgets/weight_tracking_card.dart';

import '../../../l10n/generated/app_localizations.dart';
// Cache lives in `youOverviewCache` (lib/data/services/you_overview_prewarmer.dart).
// It's shared with the prewarmer service so post-sign-in / post-onboarding
// pre-warming and the live tab read/write the same singleton.
final _overviewCache = youOverviewCache;

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
        SnackBar(
          content: Text(AppLocalizations.of(context).overviewCouldnTRefreshShowing),
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

    // Bottom padding must clear BOTH the floating sub-tab pill AND the
    // main nav bar underneath. `kYouHubBodyBottomInset` bundles both.
    final bottomInset =
        MediaQuery.of(context).viewPadding.bottom + kYouHubBodyBottomInset;

    return RefreshIndicator(
      color: accent,
      onRefresh: _manualRefresh,
      child: ListView(
        // ListView pads bottom for the floating glass bar; horizontal
        // padding is 0 so individual sections can manage their own inset
        // (the user card + gamification grid use 16px, while the health
        // composite + habits section self-pad internally).
        padding: EdgeInsets.fromLTRB(0, 16, 0, bottomInset),
        children: [
          // NOTE: The read-only UserCard (avatar + name) was removed from the
          // Overview tab — the "YOU" header already establishes identity, so
          // repeating the name here was redundant. The editable UserCard still
          // lives at the top of the Profile sub-tab.

          // ─── HEALTH OVERVIEW — single composite card (Surface
          // 5.A.2). Replaces the previous TodaysHealthCard +
          // LastNightSleepCard + CombinedHealthCard triple. Each section
          // self-hides when its data isn't connected.
          HealthOverviewCard(
            onRefresh: _refreshing ? null : _manualRefresh,
            isRefreshing: _refreshing,
          ),
          const SizedBox(height: 12),

          // Weight tracking (self-pads internally, kept here as a
          // secondary health-adjacent metric).
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: WeightTrackingCard(),
          ),
          const SizedBox(height: 8),

          // Permanent Cycle row — opens the dedicated /cycle experience.
          // Self-hides when menstrual tracking is disabled.
          const _CycleHubRow(),
          const SizedBox(height: 8),

          // ─── 3. GAMIFICATION 2×2 GRID (Surface 5.A.3). Single grid
          // replaces the two side-by-side Row + IntrinsicHeight blocks;
          // consistent tile heights, no IntrinsicHeight gymnastics.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GamificationGrid(
              trophySummary: _trophySummary,
              recentTrophies: _recentTrophies,
              skillsSummary: _skillsSummary,
              leaderboardUnlocked: _leaderboardUnlocked,
              workoutsNeeded: _workoutsNeeded,
              percentile: _percentile,
              fg: fg,
              accent: accent,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 8),

          // ─── 4. HABITS heatmap (Surface 5.B.5). Moved off Profile —
          // habits belong on the "at a glance" surface, not buried in
          // setup. HabitsSection self-pads internally.
          const HabitsSection(),
          const SizedBox(height: 16),

          // ─── 5. WEEKLY RECAP teaser (conditional, Surface 5.A.5).
          if (_latestSummary != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _WeeklyRecapTeaser(
                  summary: _latestSummary!, fg: fg, accent: accent),
            ),
            const SizedBox(height: 16),
          ],

          // ─── 6. XP HERO TILE (last per composition order in plan).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: XpHeroTile(muted: serious),
          ),

          // ─── 7. STREAK HERO TILE (Gravl-parity discoverability upgrade).
          // The streak number is the single most habit-forming metric, so it
          // gets a full-width hero tile — a flame + a BIG count — instead of
          // the old buried 20px-card horizontal strip. Shown EVEN in Serious
          // Mode (toned down) so the number is always discoverable; taps route
          // to the dedicated /streaks hub.
          if (_streaks != null && _streaks!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StreakHeroTile(
                streaks: _streaks!,
                fg: fg,
                accent: accent,
                isDark: isDark,
                serious: serious,
              ),
            ),
          ],
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

    final bottomInset =
        MediaQuery.of(context).viewPadding.bottom + kYouHubBodyBottomInset;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Framed hairline glyph — the spec's `.st-gl` box, not an
            // accent-tinted fill chip.
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.textSecondary, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).overviewLastWeek.toUpperCase(),
                    style: ZType.lbl(10,
                        color: AppColors.textMuted, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$workouts workouts · $prs PRs',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Prominent, discoverable streak HERO tile (Gravl-parity display upgrade).
///
/// Replaces the old buried `_StreaksRow` (a 20px-tall horizontal strip of tiny
/// cards under a small "Active Streaks" label). The streak count is the single
/// most habit-forming number in the app, so it now gets a full-width hero card:
/// a flame, a BIG count-up number, a "Day streak" label, and a "View all"
/// affordance. The whole tile taps through to the dedicated `/streaks` hub.
///
/// Shown EVEN in Serious Mode — just toned down (no glow halo, lower-alpha
/// accent) so the number stays discoverable without the celebratory chrome.
///
/// Data: each entry of [streaks] is a `Map<String,dynamic>` with `streak_type`
/// (e.g. `"workout"`, underscored) and `current_streak` (num). The hero number
/// is the `workout` streak; if there's no `workout` entry we fall back to the
/// highest current streak. Any OTHER active streak (>0, not the hero) surfaces
/// as a small secondary chip so they stay visible without a horizontal strip.
class _StreakHeroTile extends StatelessWidget {
  final List<dynamic> streaks;
  final Color fg;
  final Color accent;
  final bool isDark;
  final bool serious;

  const _StreakHeroTile({
    required this.streaks,
    required this.fg,
    required this.accent,
    required this.isDark,
    required this.serious,
  });

  /// Normalizes one raw streak entry into (type, count). Returns null for
  /// malformed entries so they're skipped rather than crashing the tile.
  static ({String type, int count})? _parse(dynamic raw) {
    if (raw is! Map) return null;
    final type = (raw['streak_type'] as String? ?? 'streak');
    final count = (raw['current_streak'] as num?)?.toInt() ?? 0;
    return (type: type, count: count);
  }

  @override
  Widget build(BuildContext context) {
    // Parse every entry, dropping malformed ones.
    final parsed = streaks
        .map(_parse)
        .whereType<({String type, int count})>()
        .toList();
    if (parsed.isEmpty) return const SizedBox.shrink();

    // Hero = the workout streak when present, otherwise the largest streak.
    final hero = parsed.firstWhere(
      (s) => s.type == 'workout',
      orElse: () => parsed.reduce((a, b) => a.count >= b.count ? a : b),
    );

    // Every OTHER active streak (>0, not the hero) becomes a secondary chip.
    final others = parsed
        .where((s) => s != hero && s.count > 0)
        .toList();

    // Friendly label for the hero — "Day streak" for daily-cadence types,
    // "Week streak" for the weekly workout cadence. Defaults to a humanized
    // version of the type ("login" → "Login streak").
    final heroLabel = _labelFor(hero.type);

    // Signature hero grammar: hairline surface + accent LEFT edge, an Anton
    // numeral, NO glow halo, NO accent-tint fill. Serious Mode drops the
    // accent edge to a plain hairline and renders the numeral in text color.
    final numberColor = serious ? fg : accent;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/streaks');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: serious
              ? Border.all(color: AppColors.cardBorder)
              : Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Framed hairline flame badge.
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                // Big Anton count + Barlow label.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedStatNumber(
                        value: hero.count.toDouble(),
                        format: (v) => v.round().toString(),
                        size: StatType.hero,
                        color: numberColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        heroLabel.toUpperCase(),
                        style: ZType.lbl(10,
                            color: AppColors.textMuted, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                // "View all" affordance.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all'.toUpperCase(),
                      style: ZType.lbl(10,
                          color: AppColors.textMuted, letterSpacing: 1.2),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
                  ],
                ),
              ],
            ),
            // Secondary streaks as compact hairline chips.
            if (others.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in others)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        '🔥 ${s.count} · ${_humanize(s.type)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hero label: workout streaks read as a weekly cadence ("Week streak");
  /// other types default to a daily cadence ("Day streak"). Anything else gets
  /// a humanized `Type streak`.
  static String _labelFor(String type) {
    switch (type) {
      case 'workout':
        return 'Week streak';
      case 'login':
      case 'daily_login':
      case 'nutrition':
      case 'logging':
        return 'Day streak';
      default:
        return '${_humanize(type)} streak';
    }
  }

  /// "daily_login" → "Daily login".
  static String _humanize(String type) {
    final spaced = type.replaceAll('_', ' ').trim();
    if (spaced.isEmpty) return 'Streak';
    return spaced[0].toUpperCase() + spaced.substring(1);
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
      title: AppLocalizations.of(context).overviewRecentTrophy,
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
      title: AppLocalizations.of(context).overviewActiveSkill,
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
      title: AppLocalizations.of(context).streakMilestoneRewards,
      headline: ready > 0 ? '$ready ready' : AppLocalizations.of(context).overviewViewPerks,
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
      title: AppLocalizations.of(context).statsRewardsSocial,
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
    // Signature hairline tile. `highlight` (action-ready) earns the accent
    // left edge; otherwise a flat warm hairline border. Framed glyph box,
    // Barlow kicker, Anton headline.
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(route);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: highlight
              ? Border.all(color: AppColors.cardBorder, width: 1)
              : Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Framed hairline glyph box (emoji sits bare for trophy/rarity).
            leadingEmoji != null
                ? Text(leadingEmoji!, style: const TextStyle(fontSize: 20))
                : Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(leadingIcon,
                        color: AppColors.textSecondary, size: 16),
                  ),
            const SizedBox(height: 10),
            Text(
              title.toUpperCase(),
              style: ZType.lbl(10,
                  color: AppColors.textMuted, letterSpacing: 1.5),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                headline,
                style: ZType.disp(17, color: fg, letterSpacing: 0.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // Flexible so the 2-line sub-text shrinks to whatever vertical
            // space remains in the GridView tile after the icon + title +
            // headline take their natural heights. Without Flexible the
            // Column tried to render both sub lines at their natural
            // height and overflowed the tile by ~1.7pt on some content
            // lengths.
            Flexible(
              child: Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// 2×2 GridView replacing the previous side-by-side Row + IntrinsicHeight
/// stacks (Surface 5.A.3). All four tiles share the same neutral surface;
/// the category-colored glyph is the only color signal.
class _GamificationGrid extends ConsumerWidget {
  final Map<String, dynamic>? trophySummary;
  final List<dynamic>? recentTrophies;
  final Map<String, dynamic>? skillsSummary;
  final bool? leaderboardUnlocked;
  final int workoutsNeeded;
  final double? percentile;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _GamificationGrid({
    required this.trophySummary,
    required this.recentTrophies,
    required this.skillsSummary,
    required this.leaderboardUnlocked,
    required this.workoutsNeeded,
    required this.percentile,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // A scrollable with null padding absorbs MediaQuery.padding (status
      // bar + home indicator) as its own — inside the Overview ListView that
      // rendered as ~60px of dead space above the grid and ~34px below it.
      padding: EdgeInsets.zero,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      // Stable tile height across the four cards (no IntrinsicHeight
      // required). 1.25 leaves room for a full 2-line sub-label — at 1.35
      // "Recently earned · tap to view" clipped mid-line on 390pt phones.
      childAspectRatio: 1.25,
      children: [
        _RecentTrophyCard(
          summary: trophySummary,
          recent: recentTrophies,
          fg: fg,
          accent: accent,
          isDark: isDark,
        ),
        _ActiveSkillCard(
          summary: skillsSummary,
          fg: fg,
          accent: accent,
          isDark: isDark,
        ),
        _RewardsReadyCard(fg: fg, accent: accent, isDark: isDark),
        _LeaderboardCard(
          unlocked: leaderboardUnlocked,
          workoutsNeeded: workoutsNeeded,
          percentile: percentile,
          fg: fg,
          accent: accent,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Permanent Cycle entry row for the You hub Overview tab.
///
/// Opens the dedicated `/cycle` experience. Reads [hormonalProfileProvider]
/// and self-hides (`SizedBox.shrink`) when menstrual tracking is disabled —
/// so male / opted-out accounts never see it, per the gender-gating table.
class _CycleHubRow extends ConsumerWidget {
  const _CycleHubRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(hormonalProfileProvider);
    final enabled = profileAsync.value?.menstrualTrackingEnabled ?? false;
    if (!enabled) return const SizedBox.shrink();

    final prediction = ref.watch(cyclePredictionProvider).value;

    String sub = 'Phase, calendar & fertility insights';
    if (prediction != null && prediction.predictionsAvailable) {
      final day = prediction.currentCycleDay;
      final phase = prediction.currentPhase;
      if (phase != null && day != null) {
        sub = '${phase.displayName} · day $day';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          context.push('/cycle');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // Framed hairline glyph — the heart keeps the cycle-pink tint
              // as a single semantic accent (domain signal, like macro dots),
              // but the surrounding chrome is matte hairline.
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: AppColors.pink, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).overviewCycle.toUpperCase(),
                      style: ZType.lbl(10,
                          color: AppColors.textMuted, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
