import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/discover_snapshot.dart';
import '../../data/models/fitness_profile.dart';
import '../../data/models/fitness_shape_history.dart';
import '../../core/utils/country_flag.dart';
import '../../core/utils/leaderboard_tier_color.dart';
import '../../data/providers/discover_provider.dart';
import '../../data/providers/fitness_profile_provider.dart';
import '../../data/providers/fitness_shape_history_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'widgets/leaderboard_row_adornments.dart';

/// Workstream 2 — Discover tab.
///
/// Research-backed layout (Yu-kai Chou octalysis + Growth Engineering):
/// percentile hero → Rising Stars → Near You → collapsible Top 10.
/// Flat global leaderboards demotivate 95% of users — this structure
/// avoids that trap by making everyone visible and improving.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  static const _boardOptions = [
    ('xp', 'XP This Week'),
    ('volume', 'Volume'),
    ('streaks', 'Streaks'),
  ];

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick a silent background refresh on every mount. The `isReloading`
    // branch below keeps prior data on screen during the refetch — no
    // blanking, no pull-to-refresh needed.
    //
    // Also kick the XP provider to load — the hero card reads userXpProvider
    // for the "Lvl N · 956 XP lifetime" badge. If XP state hasn't been
    // hydrated yet (fresh app open, no one loaded it upstream), the badge
    // would show the default Lvl 1 · 0 XP from UserXP.empty() which is
    // jarringly wrong for a real user. Explicit load on Discover mount
    // guarantees the hero gets real numbers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(discoverSnapshotProvider);
      final currentXp = ref.read(xpProvider).userXp;
      final looksEmpty = currentXp == null ||
          (currentXp.totalXp == 0 && currentXp.currentLevel <= 1);
      if (looksEmpty) {
        // Fire-and-forget; the badge watches the provider and rebuilds when
        // state updates.
        ref.read(xpProvider.notifier).loadUserXP(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Silent refresh when the app is brought back to the foreground while
    // Discover is the active screen. Data updates on its own.
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(discoverSnapshotProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(discoverSnapshotProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    // Keep the previous snapshot visible while a board-tab refetch is in flight
    // so toggling XP / Volume / Streaks updates the data in place instead of
    // blanking the whole screen with a spinner. First load (no prior value)
    // still shows the loading state below.
    final current = snap.valueOrNull;
    final isFirstLoad = current == null && snap.isLoading;
    final isReloading = current != null && snap.isLoading;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: accent,
        onRefresh: () async => ref.invalidate(discoverSnapshotProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Minimal top spacer. The bottom nav already labels this screen
            // "Discover", so we skip a redundant title. The safe-area pad is
            // kept via MediaQuery so the hero card doesn't clip the notch.
            // When a silent refetch is in-flight, a tiny progress dot appears
            // top-right so the user knows data is updating.
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 12,
                  child: isReloading
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation(accent),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (isFirstLoad)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildContent(
                      context, ref, current ?? _emptySnapshot(),
                      textColor: textColor,
                      textMuted: textMuted,
                      elevated: elevated,
                      border: border,
                      accent: accent,
                    ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DiscoverSnapshot s, {
    required Color textColor,
    required Color textMuted,
    required Color elevated,
    required Color border,
    required Color accent,
  }) {
    // Find the self entry in Near You (if on board) so the hero card can
    // tap-through to open the peek sheet with your own 6-axis radar.
    final selfEntry = s.nearYou.where((e) => e.isCurrentUser).isEmpty
        ? null
        : s.nearYou.firstWhere((e) => e.isCurrentUser);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: selfEntry == null
              ? null
              : () => _openUserPeek(
                    context,
                    userId: selfEntry.userId,
                    name: selfEntry.bestName,
                    username: selfEntry.username,
                    avatarUrl: selfEntry.avatarUrl,
                    rank: selfEntry.rank,
                    metricValue: selfEntry.metricValue,
                    metricLabel: s.metricLabel,
                    ref: ref,
                    level: selfEntry.currentLevel,
                  ),
          behavior: HitTestBehavior.opaque,
          child: _RankHeroCard(
            snapshot: s,
            textColor: textColor,
            textMuted: textMuted,
            elevated: elevated,
            border: border,
            accent: accent,
          ),
        ),
        const SizedBox(height: 14),
        _filterPills(context, ref, textColor: textColor, textMuted: textMuted, border: border, accent: accent),
        const SizedBox(height: 18),
        if (s.risingStars.isNotEmpty) ...[
          _sectionHeader('🚀 Rising Stars', 'This week\'s biggest movers', textColor: textColor, textMuted: textMuted),
          const SizedBox(height: 10),
          _RisingStarsStrip(stars: s.risingStars, elevated: elevated, textColor: textColor, textMuted: textMuted, border: border, accent: accent),
          const SizedBox(height: 18),
        ],
        if (s.nearYou.isEmpty)
          _emptyState(
            'No entries yet — your first workout this week puts you on the board.',
            textMuted: textMuted,
            elevated: elevated,
            border: border,
          )
        else
          _NearYouList(entries: s.nearYou, elevated: elevated, border: border, textColor: textColor, textMuted: textMuted, accent: accent, metricLabel: s.metricLabel),
        const SizedBox(height: 18),
        _Top10Collapsible(entries: s.top10, elevated: elevated, border: border, textColor: textColor, textMuted: textMuted, metricLabel: s.metricLabel),
        const SizedBox(height: 14),
        Center(
          child: Text(
            _resetLabel(s.weekStart),
            style: TextStyle(fontSize: 11, color: textMuted, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle, {required Color textColor, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted)),
      ],
    );
  }

  /// Compact segmented control — single row, full width, no overflow.
  /// Replaces the older double-row chip layout. Matches Strava/Peloton feel.
  Widget _filterPills(BuildContext context, WidgetRef ref,
      {required Color textColor, required Color textMuted, required Color border, required Color accent}) {
    final board = ref.watch(discoverBoardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final opt in DiscoverScreen._boardOptions)
            Expanded(
              child: _SegmentedTab(
                label: opt.$2,
                selected: board == opt.$1,
                accent: accent,
                textColor: textColor,
                textMuted: textMuted,
                onTap: () {
                  HapticService.light();
                  ref.read(discoverBoardProvider.notifier).state = opt.$1;
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, {required Color textMuted, required Color elevated, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Footer label: "Resets Sun, Apr 20 · 11:59 PM" — dynamically computed from
  /// the server-provided `week_start` (Monday) + 6 days so the user sees the
  /// exact date the board resets, not a generic "Sunday". Falls back to a
  /// generic string when no snapshot is loaded yet.
  String _resetLabel(String weekStart) {
    if (weekStart.isEmpty) return 'Resets Sunday · 11:59 PM';
    try {
      final monday = DateTime.parse(weekStart);
      final resetDate = monday.add(const Duration(days: 6));
      final formatted = DateFormat('E, MMM d').format(resetDate);
      return 'Resets $formatted · 11:59 PM';
    } catch (_) {
      return 'Resets Sunday · 11:59 PM';
    }
  }

  /// Returns a genuinely empty snapshot (zero entries). The layout renders
  /// its real empty-state UI for each section — no fake users, no fake ranks.
  /// App-store-safe: nothing presented to the user is synthetic data.
  DiscoverSnapshot _emptySnapshot() {
    return const DiscoverSnapshot(
      board: 'xp',
      scope: 'global',
      weekStart: '',
      yourRank: 0,
      yourPercentile: 0,
      yourTier: 'starter',
      yourMetric: 0,
      totalActive: 0,
      metricLabel: 'XP',
    );
  }

}

// ─── Segmented tab (single-row filter) ──────────────────────────────────────

class _SegmentedTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color textColor;
  final Color textMuted;
  final VoidCallback onTap;

  const _SegmentedTab({
    required this.label,
    required this.selected,
    required this.accent,
    required this.textColor,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : textMuted,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ─── Hero rank card — percentile first ──────────────────────────────────────

class _RankHeroCard extends ConsumerWidget {
  final DiscoverSnapshot snapshot;
  final Color textColor, textMuted, elevated, border, accent;
  const _RankHeroCard({
    required this.snapshot,
    required this.textColor,
    required this.textMuted,
    required this.elevated,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = snapshot;
    final hasRank = s.yourRank > 0;
    final percentileText = s.yourPercentile > 0
        ? 'TOP ${(100 - s.yourPercentile).clamp(1, 99).toStringAsFixed(0)}%'
        : 'JOIN THE BOARD';

    // Lifetime XP + level come from the XP system (user_xp table), not the
    // weekly leaderboard. We surface them here so the hero doesn't feel
    // disconnected from the XP Goals screen — e.g. user sees "Lvl 4 · 956 XP"
    // alongside the week's 754 XP.
    final userXp = ref.watch(userXpProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.25),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentileText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (hasRank) ...[
                const SizedBox(width: 8),
                Text(
                  '#${s.yourRank} of ${s.totalActive}',
                  style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          // Hide the lifetime badge when XP hasn't been hydrated yet. The
          // XPRepository returns UserXP.empty() on error, which has totalXp=0
          // and currentLevel=1 — rendering that would falsely claim the user
          // is level 1 with zero lifetime XP. We only show the badge once
          // we're confident the data is real (totalXp > 0 OR level > 1 OR a
          // valid userId is attached to the state).
          if (userXp != null &&
              (userXp.totalXp > 0 || userXp.currentLevel > 1)) ...[
            const SizedBox(height: 10),
            _LifetimeBadge(
              level: userXp.currentLevel,
              totalXp: userXp.totalXp,
              accent: accent,
              textColor: textColor,
              textMuted: textMuted,
            ),
          ],
          // Tier-persistence streak nudge — "Week 2 in Top 1% · 3 more for Iron Throne".
          // Only renders once the user has held a qualifying tier at least
          // one week. Copy adapts to whether a next milestone exists.
          if (s.yourTierStreakWeeks >= 1) ...[
            const SizedBox(height: 8),
            _TierStreakLine(
              weeks: s.yourTierStreakWeeks,
              tier: s.yourTier,
              nextMilestoneWeeks: s.yourNextMilestoneWeeks,
              nextMilestoneXp: s.yourNextMilestoneXp,
              accent: accent,
              textColor: textColor,
              textMuted: textMuted,
            ),
          ],
          const SizedBox(height: 12),
          // Three states:
          //  1. On board (hasRank)  → always show metric in big type, even
          //     if it's 0 (e.g. streaks=0 or volume=0 with logs missing
          //     duration). "0" beats a misleading "complete a workout" prompt.
          //  2. Not on board (rank=0) → prompt to complete a workout.
          if (hasRank) ...[
            Text(
              '${s.yourMetric.toStringAsFixed(0)} ${s.metricLabel}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'this week',
              style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            Text(
              'Complete a workout this week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Your rank + percentile appears once you\'re on the board',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.3),
            ),
          ],
          if (s.nextTier != null && s.unitsToNext > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  '${s.unitsToNext} ${s.metricLabel} to Top ${_tierPercent(s.nextTier!)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _tierPercent(String tier) => switch (tier) {
        'legendary' => '1%',
        'top' => '5%',
        'elite' => '10%',
        'rising' => '25%',
        'active' => '50%',
        _ => '%',
      };
}

/// Tier-persistence hero nudge.
///
/// Example copy:
///   "Week 2 in Top 1% · 3 more for Iron Throne 👑"
///   "Week 5 in Top 10% · 5 more for Immortal ⚜️"
///   "Week 10 in Top 1%" (no "more for X" when already at top milestone)
///
/// Hidden entirely when `weeks == 0` — caller gates the render.
class _TierStreakLine extends StatelessWidget {
  final int weeks;
  final String tier;  // top1 / top5 / top10 / top25 / legendary/top/elite/rising
  final int? nextMilestoneWeeks;
  final int? nextMilestoneXp;
  final Color accent;
  final Color textColor;
  final Color textMuted;

  const _TierStreakLine({
    required this.weeks,
    required this.tier,
    required this.nextMilestoneWeeks,
    required this.nextMilestoneXp,
    required this.accent,
    required this.textColor,
    required this.textMuted,
  });

  String _badgeIconForWeeks(int w) {
    if (w >= 10) return 'Immortal ⚜️';
    if (w >= 5) return 'Iron Throne 👑';
    return 'Podium Hat-Trick 🥉';
  }

  @override
  Widget build(BuildContext context) {
    final tierLabel = tierDisplayName(tier);
    if (tierLabel.isEmpty) return const SizedBox.shrink();

    final parts = <InlineSpan>[
      TextSpan(
        text: 'Week $weeks in $tierLabel',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    ];

    if (nextMilestoneWeeks != null) {
      final remaining = nextMilestoneWeeks! - weeks;
      parts.addAll([
        TextSpan(
          text: '  ·  ',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
        TextSpan(
          text: '$remaining more for ${_badgeIconForWeeks(nextMilestoneWeeks!)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ]);
    }

    return RichText(
      text: TextSpan(children: parts),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Hero sub-row: "Lvl 4 · 956 XP lifetime". Bridges the weekly leaderboard
/// metric to the lifetime XP shown on the XP Goals screen so the two numbers
/// don't feel contradictory.
class _LifetimeBadge extends StatelessWidget {
  final int level;
  final int totalXp;
  final Color accent, textColor, textMuted;
  const _LifetimeBadge({
    required this.level,
    required this.totalXp,
    required this.accent,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LevelPill(level: level, accent: accent),
        const SizedBox(width: 8),
        Text(
          '${_formatXp(totalXp)} XP lifetime',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Compact "Lvl N" chip used on the hero sub-row and every leaderboard row.
class _LevelPill extends StatelessWidget {
  final int level;
  final Color accent;
  const _LevelPill({required this.level, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        'Lvl $level',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

String _formatXp(int xp) {
  if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
  if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
  return xp.toString();
}

// ─── Rising Stars strip ─────────────────────────────────────────────────────

class _RisingStarsStrip extends ConsumerWidget {
  final List<DiscoverRisingStar> stars;
  final Color elevated, textColor, textMuted, border, accent;
  const _RisingStarsStrip({
    required this.stars,
    required this.elevated,
    required this.textColor,
    required this.textMuted,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final star = stars[i];
          return GestureDetector(
            onTap: () => _openUserPeek(
              context,
              userId: star.userId,
              name: star.bestName,
              username: star.username,
              avatarUrl: star.avatarUrl,
              rank: star.currentRank,
              metricValue: star.metricValue,
              metricLabel: 'XP',
              ref: ref,
              level: star.currentLevel,
            ),
            child: Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TierRingAvatar(
                      url: star.avatarUrl,
                      fallback: star.bestName,
                      radius: 20,
                      accent: accent,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      tier: star.peakTier,
                      peakTier: star.peakTier,
                      prHit: star.prThisWeek,
                      activeNow: star.isActiveNow,
                    ),
                    const Spacer(),
                    _LevelPill(level: star.currentLevel, accent: accent),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  star.bestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.green, size: 12),
                    Text(
                      '${star.rankDelta}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ranks',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

// ─── Near You ────────────────────────────────────────────────────────────────

class _NearYouList extends ConsumerWidget {
  final List<DiscoverEntry> entries;
  final Color elevated, border, textColor, textMuted, accent;
  final String metricLabel;
  const _NearYouList({
    required this.entries,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
    required this.accent,
    required this.metricLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compute the current-user's index so we can emit GapChip widgets on the
    // dividers directly above and below. If the user isn't on the board (no
    // row with isCurrentUser=true), no chips render.
    final meIdx = entries.indexWhere((e) => e.isCurrentUser);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            Builder(builder: (ctx) => _row(ctx, ref, entries[i])),
            if (i < entries.length - 1) ...[
              // GapChip placement: show only on the divider directly above
              // OR directly below the current-user row. Shows "+42 XP" above
              // (distance to catch them) or "−31 XP" below (distance ahead).
              if (meIdx != -1 && (i == meIdx - 1 || i == meIdx)) ...[
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: GapChip(
                    delta: i == meIdx - 1
                        ? entries[i].metricValue - entries[meIdx].metricValue
                        : entries[meIdx].metricValue - entries[i + 1].metricValue,
                    metricLabel: metricLabel,
                    accent: accent,
                  ),
                ),
                Divider(height: 1, color: border),
              ] else
                Divider(height: 1, color: border),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, DiscoverEntry e) {
    final bg = e.isCurrentUser ? accent.withValues(alpha: 0.14) : Colors.transparent;

    // Tapping any row (including your own) opens the peek sheet with the
    // 6-axis radar. For self-taps, the radar draws a single shape (no
    // overlay), since "you vs you" is redundant.
    return Material(
      color: bg,
      child: InkWell(
        onTap: () => _openUserPeek(
          context,
          userId: e.userId,
          name: e.bestName,
          username: e.username,
          avatarUrl: e.avatarUrl,
          rank: e.rank,
          metricValue: e.metricValue,
          metricLabel: metricLabel,
          ref: ref,
          level: e.currentLevel,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: LayoutBuilder(
            builder: (ctx, cons) => _buildRowContent(ctx, e, cons.maxWidth),
          ),
        ),
      ),
    );
  }

  Widget _buildRowContent(BuildContext context, DiscoverEntry e, double width) {
    // 320dp-and-below gets a compact layout: no rank-delta number (arrow-only),
    // no streak count (flame-only), no flag. 321dp+ shows everything.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = width < 310;
    final showFlag = !e.isCurrentUser && !compact && !e.isAnonymous;

    // Current user tier comes from the tier_streaks peak or current rank —
    // for row rendering we approximate from percentile: top 25% = rising+.
    // Since backend doesn't expose per-row current tier, we fall back to
    // peakTier for ring color (a sensible "best-known" indicator).
    final ringTier = e.peakTier ?? (e.isCurrentUser ? null : null);

    // When the viewer has anonymous mode on, their own row suppresses the
    // cached photo avatar (shows initial fallback instead) and shows a
    // "Hidden" lock badge so they can SEE their own row is anonymized —
    // without this the cached waterfall photo kept rendering even though
    // the backend was already returning avatar_url=null (CachedNetworkImage
    // served a stale disk cache).
    final hideIdentity = e.isAnonymous;

    return Row(
      children: [
        // Rank number (32dp fixed) + tiny rank-delta chip (24dp fixed)
        SizedBox(
          width: 28,
          child: Text(
            '#${e.rank}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: e.isCurrentUser ? FontWeight.w900 : FontWeight.w600,
              color: e.isCurrentUser ? accent : textMuted,
            ),
          ),
        ),
        RankDeltaChip(delta: e.rankDelta, compact: compact),
        const SizedBox(width: 4),
        TierRingAvatar(
          // Force-null URL when anonymized, so CachedNetworkImage can't serve
          // a stale photo from disk. Fallback lands on the initial letter of
          // bestName ("A" for "Anonymous athlete", "Y" for "You").
          url: hideIdentity ? null : e.avatarUrl,
          fallback: e.isCurrentUser && hideIdentity ? 'You' : e.bestName,
          radius: 16,
          accent: accent,
          isDark: isDark,
          tier: ringTier,
          peakTier: hideIdentity ? null : e.peakTier,
          prHit: e.prThisWeek,
          activeNow: e.isActiveNow,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  e.isCurrentUser ? 'You' : e.bestName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: e.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (hideIdentity) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock_outline, size: 12, color: textMuted),
                const SizedBox(width: 2),
                Text(
                  'Hidden',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
              if (showFlag) ...[
                const SizedBox(width: 4),
                FlagText(flagEmoji: flagFor(e.countryCode)),
              ],
              if (e.currentStreak > 0) ...[
                const SizedBox(width: 6),
                StreakFlame(
                  streak: e.currentStreak,
                  textColor: textMuted,
                  compact: compact,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 4),
        _LevelPill(level: e.currentLevel, accent: accent),
        if (e.isCurrentUser) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'YOU',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          '${e.metricValue.toStringAsFixed(0)} $metricLabel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ─── Top 10 collapsible ─────────────────────────────────────────────────────

class _Top10Collapsible extends ConsumerStatefulWidget {
  final List<DiscoverEntry> entries;
  final Color elevated, border, textColor, textMuted;
  final String metricLabel;
  const _Top10Collapsible({
    required this.entries,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
    required this.metricLabel,
  });

  @override
  ConsumerState<_Top10Collapsible> createState() => _Top10CollapsibleState();
}

class _Top10CollapsibleState extends ConsumerState<_Top10Collapsible> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: widget.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticService.light();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Top of the week',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: widget.textMuted),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: widget.border),
            for (int i = 0; i < widget.entries.length; i++) ...[
              ListTile(
                dense: true,
                onTap: () => _openUserPeek(
                  context,
                  userId: widget.entries[i].userId,
                  name: widget.entries[i].bestName,
                  username: widget.entries[i].username,
                  avatarUrl: widget.entries[i].avatarUrl,
                  rank: widget.entries[i].rank,
                  metricValue: widget.entries[i].metricValue,
                  metricLabel: widget.metricLabel,
                  ref: ref,
                  level: widget.entries[i].currentLevel,
                ),
                leading: SizedBox(
                  width: 28,
                  child: Text('#${widget.entries[i].rank}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: widget.textMuted)),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.entries[i].isCurrentUser ? 'You' : widget.entries[i].bestName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Consumer(builder: (context, ref, _) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final accent = ref.watch(accentColorProvider).getColor(isDark);
                      return _LevelPill(level: widget.entries[i].currentLevel, accent: accent);
                    }),
                  ],
                ),
                trailing: Text(
                  '${widget.entries[i].metricValue.toStringAsFixed(0)} ${widget.metricLabel}',
                  style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              if (i < widget.entries.length - 1) Divider(height: 1, color: widget.border),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers ─────────────────────────────────────────────────────────

/// Lightweight read-only peek at a user tapped on the leaderboard.
/// Shows the tapped user's identity + rank + 6-axis fitness radar overlaid
/// with the viewer's own shape. No social actions (Message / Follow /
/// Add-friend) — social is intentionally hidden until relaunched.
void _openUserPeek(
  BuildContext context, {
  required String userId,
  required String name,
  String? username,
  String? avatarUrl,
  required int rank,
  required double metricValue,
  required String metricLabel,
  required WidgetRef ref,
  int? level,
}) {
  if (name.trim().isEmpty) return;
  HapticService.light();

  // Hide the floating bottom nav while the peek sheet is up so it doesn't
  // overlap the glassmorphic chrome. Restore when the sheet closes.
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showGlassSheet<void>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.92,
      child: _UserPeekSheet(
        userId: userId,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        rank: rank,
        metricValue: metricValue,
        metricLabel: metricLabel,
        level: level,
      ),
    ),
  ).whenComplete(() {
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _UserPeekSheet extends ConsumerWidget {
  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final int rank;
  final double metricValue;
  final String metricLabel;
  final int? level;
  const _UserPeekSheet({
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.rank,
    required this.metricValue,
    required this.metricLabel,
    this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    final profileAsync = ref.watch(fitnessProfileProvider(userId));

    // Parent GlassSheet renders its own handle + background blur; we only
    // provide padding + scrollable content. No inner surface color.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          _Avatar(url: avatarUrl, fallback: name, radius: 38, accent: accent),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: name == 'Anonymous athlete'
                  ? FontWeight.w600
                  : FontWeight.w800,
              color: textColor,
            ),
          ),
          if (username != null && username!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('@$username',
                style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
          ],
          // Bio (only rendered inside _profileSection when stats are visible)
          _profileBio(profileAsync, textMuted),
          const SizedBox(height: 16),
          // Compact rank + level + metric pill.
          // Level comes from the row the user tapped — we pass it through
          // _openUserPeek so the pill reads "Lvl 4 · #1 · 841 XP". If the
          // caller doesn't have a level yet (shouldn't happen in practice
          // since every row renders a Lvl pill), the `Lvl` chunk is hidden.
          _RankPill(
            rank: rank,
            metricValue: metricValue,
            metricLabel: metricLabel,
            accent: accent,
            textColor: textColor,
            border: border,
            level: level,
          ),
          const SizedBox(height: 20),
          // Dual-overlay radar (the engagement lever)
          _profileSection(profileAsync, accent, textColor, textMuted, border),
        ],
      ),
    );
  }

  Widget _profileBio(AsyncValue<FitnessProfile?> async, Color textMuted) {
    final fp = async.valueOrNull;
    final bio = fp?.targetBio;
    if (fp == null || fp.targetStatsHidden || bio == null || bio.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '"${bio.trim()}"',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13, color: textMuted,
          fontStyle: FontStyle.italic, height: 1.3,
        ),
      ),
    );
  }

  Widget _profileSection(
    AsyncValue<FitnessProfile?> async,
    Color accent, Color textColor, Color textMuted, Color border,
  ) {
    final fp = async.valueOrNull;

    // Skeleton during first load
    if (async.isLoading && fp == null) {
      return SizedBox(
        height: 240,
        child: Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
      );
    }

    if (fp == null) {
      return _statusBlock(
        'Couldn\'t load fitness shape. Try again in a moment.',
        textMuted: textMuted,
      );
    }

    if (fp.targetStatsHidden) {
      return _statusBlock('Stats hidden', textMuted: textMuted);
    }

    if (fp.targetIsEmpty) {
      return _statusBlock(
        'Log your first workout to build your shape.',
        textMuted: textMuted,
      );
    }

    return _FitnessRadar(
      targetUserId: userId,
      profile: fp,
      accent: accent,
      textColor: textColor,
      textMuted: textMuted,
      border: border,
    );
  }

  Widget _statusBlock(String message, {required Color textMuted}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: textMuted, height: 1.35),
      ),
    );
  }
}

// ─── Rank + metric pill ─────────────────────────────────────────────────────

class _RankPill extends StatelessWidget {
  final int rank;
  final double metricValue;
  final String metricLabel;
  final Color accent, textColor, border;
  final int? level;
  const _RankPill({
    required this.rank,
    required this.metricValue,
    required this.metricLabel,
    required this.accent,
    required this.textColor,
    required this.border,
    this.level,
  });

  @override
  Widget build(BuildContext context) {
    final sep = Text('  ·  ',
        style: TextStyle(color: textColor.withValues(alpha: 0.5)));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (level != null && level! > 0) ...[
            Text('Lvl $level',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: accent,
                )),
            sep,
          ],
          Text('#$rank',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: accent,
              )),
          sep,
          Text('${metricValue.toStringAsFixed(0)} $metricLabel',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: textColor,
              )),
        ],
      ),
    );
  }
}

// ─── Dual-overlay fitness radar with time scrubber ─────────────────────────
// Target drawn first in muted fill; viewer drawn on top in the app's
// configured accent color. Slider below lets user scrub through historical
// snapshots to watch both shapes evolve.
//
// History comes from fitnessShapeHistoryProvider; if history has <2 points
// the slider is hidden and the radar renders today's live profile only.

class _FitnessRadar extends ConsumerStatefulWidget {
  final String targetUserId;
  final FitnessProfile profile;  // today's live shape (fallback if no history)
  final Color accent, textColor, textMuted, border;
  const _FitnessRadar({
    required this.targetUserId,
    required this.profile,
    required this.accent,
    required this.textColor,
    required this.textMuted,
    required this.border,
  });

  @override
  ConsumerState<_FitnessRadar> createState() => _FitnessRadarState();
}

class _FitnessRadarState extends ConsumerState<_FitnessRadar> {
  FitnessHistoryRange _range = FitnessHistoryRange.threeMonths;

  /// First-of-month anchor for the displayed snapshot. null = show the
  /// latest snapshot (default).
  DateTime? _viewedMonth;

  /// Axis index (0..5) the user tapped, or -1 if none. Drives the
  /// tooltip showing exact "You vs Them" values for that axis.
  int _selectedAxis = -1;

  /// Last non-null history value. Preserved across range-chip taps so the
  /// UI doesn't flash empty while the new provider key loads.
  FitnessShapeHistory? _lastHistory;

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  @override
  Widget build(BuildContext context) {
    final historyKey = FitnessHistoryKey(
      widget.targetUserId,
      _range.resolveDays(),
    );
    final history = ref.watch(fitnessShapeHistoryProvider(historyKey));

    final screenWidth = MediaQuery.of(context).size.width;
    final compactLabels = screenWidth < 360;
    final labels = compactLabels
        ? const ['Str', 'Mus', 'Rec', 'Con', 'End', 'Nut']
        : widget.profile.axisLabels;

    // Resolve which (target, viewer) values to render based on _viewedMonth.
    // null = latest snapshot (default). Otherwise find the most-recent point
    // whose date falls within the viewed month. If no point in that month,
    // fall back to the nearest prior point (common for sparse backfill).
    //
    // Cache the last non-null provider value to _lastHistory so chip taps
    // (which swap the provider key → brief null window) don't flash the UI.
    final live = history.valueOrNull;
    if (live != null && live.points.isNotEmpty) {
      _lastHistory = live;
    }
    final historyData = live ?? _lastHistory;

    List<double> target;
    List<double> viewer;
    DateTime? currentDate;

    FitnessHistoryPoint? picked;
    if (historyData != null && historyData.points.isNotEmpty) {
      if (_viewedMonth == null) {
        picked = historyData.latest;
      } else {
        final monthStart = _viewedMonth!;
        final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
        // Newest snapshot within the viewed month
        for (final p in historyData.points.reversed) {
          if (!p.date.isAfter(monthEnd) && !p.date.isBefore(monthStart)) {
            picked = p;
            break;
          }
        }
        // Fallback: latest snapshot at or before month end (shows stale data
        // rather than blank if no snapshot in the exact month).
        picked ??= historyData.points.reversed.firstWhere(
          (p) => !p.date.isAfter(monthEnd),
          orElse: () => historyData.points.first,
        );
      }
    }

    if (picked != null) {
      target = picked.targetForRadar();
      viewer = picked.viewerForRadar();
      currentDate = picked.date;
    } else {
      target = widget.profile.targetForRadar();
      viewer = widget.profile.viewerForRadar();
    }

    // If viewer has no own data (e.g. never worked out), drop the overlay.
    // Also drop when target == viewer (self-peek) since overlaying you on
    // yourself is redundant.
    final isSelfPeek = _listsNearlyEqual(target, viewer);
    final showViewerOverlay =
        !isSelfPeek && viewer.any((v) => v > 0.01);

    // Target = the person the user tapped, rendered as primary subject in
    // accent color. Viewer = "you", rendered as a contrasting cyan overlay
    // so "me vs them" reads at a glance.
    //   accent color (purple by default) = target
    //   AppColors.cyan                    = viewer
    // Both fully saturated with semi-transparent fills so overlap blends
    // naturally.
    final targetColor = widget.accent;
    final viewerColor = AppColors.cyan;

    // Clamp axis tap within bounds
    final tappedAxis = _selectedAxis.clamp(-1, labels.length - 1);

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  // Axis picker: tap anywhere on the chart → nearest axis
                  // becomes "selected" and its values show in the readout
                  // below. Near center clears selection.
                  final cx = constraints.maxWidth / 2;
                  const cy = 120.0; // half of fixed 240 height
                  final dx = details.localPosition.dx - cx;
                  final dy = details.localPosition.dy - cy;
                  if (dx * dx + dy * dy < 200) {
                    HapticService.light();
                    setState(() => _selectedAxis = -1);
                    return;
                  }
                  final angle = _angleFromTopDegrees(dx, dy);
                  final axisSpan = 360.0 / labels.length;
                  final idx = ((angle + axisSpan / 2) / axisSpan).floor() %
                      labels.length;
                  HapticService.light();
                  setState(() => _selectedAxis = idx);
                },
                child: RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    tickCount: 4,
                    ticksTextStyle: const TextStyle(
                      color: Colors.transparent, fontSize: 1,
                    ),
                    gridBorderData:
                        BorderSide(color: widget.border, width: 0.8),
                    radarBorderData:
                        BorderSide(color: widget.border, width: 0.8),
                    tickBorderData:
                        BorderSide(color: widget.border, width: 0.5),
                    titleTextStyle: TextStyle(
                      color: widget.textMuted,
                      fontSize: compactLabels ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                    titlePositionPercentageOffset: 0.12,
                    getTitle: (index, angle) =>
                        RadarChartTitle(text: labels[index], angle: 0),
                    dataSets: [
                      // Target (the tapped user) — primary subject in accent.
                      RadarDataSet(
                        fillColor: targetColor.withValues(alpha: 0.35),
                        borderColor: targetColor,
                        borderWidth: 2,
                        entryRadius: 0,
                        dataEntries:
                            target.map((v) => RadarEntry(value: v)).toList(),
                      ),
                      // Viewer ("you") — contrasting cyan overlay.
                      if (showViewerOverlay)
                        RadarDataSet(
                          fillColor: viewerColor.withValues(alpha: 0.30),
                          borderColor: viewerColor,
                          borderWidth: 2,
                          entryRadius: 0,
                          dataEntries: viewer
                              .map((v) => RadarEntry(value: v))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Tapped-axis readout OR legend fallback
        if (tappedAxis >= 0)
          _AxisReadout(
            label: labels[tappedAxis],
            targetValue: target[tappedAxis],
            viewerValue: showViewerOverlay ? viewer[tappedAxis] : null,
            targetColor: targetColor,
            viewerColor: viewerColor,
            textColor: widget.textColor,
            textMuted: widget.textMuted,
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: targetColor, label: 'Them', textColor: widget.textMuted),
              if (showViewerOverlay) ...[
                const SizedBox(width: 16),
                _LegendDot(color: viewerColor, label: 'You', textColor: widget.textMuted),
              ],
              const SizedBox(width: 16),
              Text(
                'Tap an axis',
                style: TextStyle(fontSize: 11, color: widget.textMuted.withValues(alpha: 0.7)),
              ),
            ],
          ),
        // Time-range chips — always visible once we have any history.
        if (historyData != null && historyData.points.isNotEmpty) ...[
          const SizedBox(height: 14),
          _RangeChips(
            selected: _range,
            accent: widget.accent,
            textMuted: widget.textMuted,
            border: widget.border,
            onSelect: (r) {
              HapticService.light();
              setState(() {
                _range = r;
                _viewedMonth = null; // reset to "latest" on range change
              });
            },
          ),
        ],
        // Month navigator — arrows ± 1 month, tap "APR 2026" label for picker.
        if (historyData != null && historyData.points.isNotEmpty) ...[
          const SizedBox(height: 8),
          _MonthNavigator(
            displayMonth: _viewedMonth ??
                _firstOfMonth(historyData.latest!.date),
            bounds: (
              _firstOfMonth(historyData.points.first.date),
              _firstOfMonth(historyData.latest!.date),
            ),
            currentSnapshotDate: currentDate,
            textColor: widget.textColor,
            textMuted: widget.textMuted,
            border: widget.border,
            accent: widget.accent,
            onPrev: () {
              HapticService.light();
              setState(() {
                final m = _viewedMonth ??
                    _firstOfMonth(historyData.latest!.date);
                _viewedMonth = DateTime(m.year, m.month - 1, 1);
              });
            },
            onNext: () {
              HapticService.light();
              setState(() {
                final m = _viewedMonth ??
                    _firstOfMonth(historyData.latest!.date);
                _viewedMonth = DateTime(m.year, m.month + 1, 1);
              });
            },
            onTapLabel: () async {
              final picked = await _showMonthYearPicker(
                context: context,
                initial: _viewedMonth ??
                    _firstOfMonth(historyData.latest!.date),
                earliest: _firstOfMonth(historyData.points.first.date),
                latest: _firstOfMonth(historyData.latest!.date),
                accent: widget.accent,
              );
              if (picked != null && mounted) {
                HapticService.light();
                setState(() => _viewedMonth = picked);
              }
            },
          ),
        ],
      ],
    );
  }
}

// ─── Month navigator (‹ APR 2026 ›) ─────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final DateTime displayMonth;
  /// (earliest, latest) first-of-month bounds — arrows disable at edges.
  final (DateTime, DateTime) bounds;
  final DateTime? currentSnapshotDate;
  final Color textColor, textMuted, border, accent;
  final VoidCallback onPrev, onNext, onTapLabel;

  const _MonthNavigator({
    required this.displayMonth,
    required this.bounds,
    required this.currentSnapshotDate,
    required this.textColor,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.onPrev,
    required this.onNext,
    required this.onTapLabel,
  });

  bool get _canGoPrev {
    final (earliest, _) = bounds;
    return displayMonth.isAfter(earliest);
  }

  bool get _canGoNext {
    final (_, latest) = bounds;
    return displayMonth.isBefore(latest);
  }

  @override
  Widget build(BuildContext context) {
    final monthYear =
        DateFormat('MMM yyyy').format(displayMonth).toUpperCase();
    final subtitle = currentSnapshotDate != null &&
            (currentSnapshotDate!.year != displayMonth.year ||
                currentSnapshotDate!.month != displayMonth.month)
        ? 'Latest: ${DateFormat.yMMMd().format(currentSnapshotDate!)}'
        : null;

    return Column(
      children: [
        Row(
          children: [
            _arrow(
              icon: Icons.chevron_left,
              enabled: _canGoPrev,
              onTap: onPrev,
              color: textColor,
              mutedColor: textMuted,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onTapLabel,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    monthYear,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            _arrow(
              icon: Icons.chevron_right,
              enabled: _canGoNext,
              onTap: onNext,
              color: textColor,
              mutedColor: textMuted,
            ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: textMuted, letterSpacing: 0.5),
            ),
          ),
      ],
    );
  }

  Widget _arrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Color color,
    required Color mutedColor,
  }) {
    return SizedBox(
      width: 44, height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 24,
            color: enabled ? color : mutedColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}


// ─── Month-year picker sheet (tap "APR 2026" to open) ──────────────────────

Future<DateTime?> _showMonthYearPicker({
  required BuildContext context,
  required DateTime initial,
  required DateTime earliest,
  required DateTime latest,
  required Color accent,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _MonthYearPickerSheet(
      initial: initial,
      earliest: earliest,
      latest: latest,
      accent: accent,
    ),
  );
}

class _MonthYearPickerSheet extends StatefulWidget {
  final DateTime initial, earliest, latest;
  final Color accent;
  const _MonthYearPickerSheet({
    required this.initial,
    required this.earliest,
    required this.latest,
    required this.accent,
  });

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  bool _monthEnabled(int m) {
    final candidate = DateTime(_year, m, 1);
    return !candidate.isBefore(DateTime(widget.earliest.year, widget.earliest.month, 1)) &&
        !candidate.isAfter(DateTime(widget.latest.year, widget.latest.month, 1));
  }

  bool get _canPrevYear => _year > widget.earliest.year;
  bool get _canNextYear => _year < widget.latest.year;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    const monthAbbrev = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Year navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _canPrevYear
                    ? () {
                        HapticService.light();
                        setState(() => _year -= 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: textColor,
                disabledColor: textMuted.withValues(alpha: 0.3),
              ),
              Text(
                '$_year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: _canNextYear
                    ? () {
                        HapticService.light();
                        setState(() => _year += 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: textColor,
                disabledColor: textMuted.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 4x3 month grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2,
            children: List.generate(12, (i) {
              final monthNum = i + 1;
              final enabled = _monthEnabled(monthNum);
              final isSelected = _month == monthNum && _year == widget.initial.year
                  ? _year == widget.initial.year && _month == widget.initial.month
                  : false;
              return GestureDetector(
                onTap: enabled
                    ? () {
                        HapticService.light();
                        Navigator.pop(context, DateTime(_year, monthNum, 1));
                      }
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? widget.accent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? widget.accent : border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: enabled ? 1.0 : 0.3,
                    child: Text(
                      monthAbbrev[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: isSelected ? widget.accent : textColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: textColor)),
      ],
    );
  }
}

/// Circular avatar that falls back to the first letter of [fallback] when
/// no URL is available or the image fails to load.
class _Avatar extends StatelessWidget {
  final String? url;
  final String fallback;
  final double radius;
  final Color accent;

  const _Avatar({
    required this.url,
    required this.fallback,
    required this.radius,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (fallback.isNotEmpty ? fallback[0] : '?').toUpperCase();
    final bg = accent.withValues(alpha: 0.2);
    final fontSize = radius * 0.8;

    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(initial,
            style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: fontSize)),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: radius * 2,
          height: radius * 2,
          color: bg,
        ),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          child: Text(initial,
              style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: fontSize)),
        ),
      ),
    );
  }
}

// Approximate equality check to detect self-peek (target == viewer).
// Values are 0..1 floats; 0.001 tolerance accounts for NUMERIC rounding.
bool _listsNearlyEqual(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 0.001) return false;
  }
  return true;
}


// ─── Axis helpers ───────────────────────────────────────────────────────────

/// Angle in degrees measured clockwise from "up" (12 o'clock = 0°).
/// Maps a radar tap position to its nearest axis index.
double _angleFromTopDegrees(double dx, double dy) {
  // atan2 returns -π..π counter-clockwise from +X (east).
  // We want clockwise from +Y (up): swap so 0 = north, add 90°, flip sign.
  final rad = math.atan2(dx, -dy);
  final deg = rad * 180.0 / math.pi;
  return (deg + 360.0) % 360.0;
}


// ─── Axis readout (tooltip-like card shown when an axis is tapped) ─────────

class _AxisReadout extends StatelessWidget {
  final String label;
  final double targetValue;
  final double? viewerValue;
  final Color targetColor, viewerColor, textColor, textMuted;

  const _AxisReadout({
    required this.label,
    required this.targetValue,
    required this.viewerValue,
    required this.targetColor,
    required this.viewerColor,
    required this.textColor,
    required this.textMuted,
  });

  String _pct(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 1, color: textMuted,
            ),
          ),
          const SizedBox(width: 14),
          _dot(targetColor),
          const SizedBox(width: 4),
          Text(_pct(targetValue),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
          if (viewerValue != null) ...[
            const SizedBox(width: 12),
            _dot(viewerColor),
            const SizedBox(width: 4),
            Text(_pct(viewerValue!),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
          ],
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}


// ─── Range chips (1M / 3M / 6M / 1Y / YTD) ──────────────────────────────────

class _RangeChips extends StatelessWidget {
  final FitnessHistoryRange selected;
  final Color accent, textMuted, border;
  final ValueChanged<FitnessHistoryRange> onSelect;

  const _RangeChips({
    required this.selected,
    required this.accent,
    required this.textMuted,
    required this.border,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final r in FitnessHistoryRange.values)
          _chip(r, r == selected),
      ],
    );
  }

  Widget _chip(FitnessHistoryRange r, bool isSelected) {
    return GestureDetector(
      onTap: () => onSelect(r),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? accent.withValues(alpha: 0.5) : border,
          ),
        ),
        child: Text(
          r.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? accent : textMuted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
