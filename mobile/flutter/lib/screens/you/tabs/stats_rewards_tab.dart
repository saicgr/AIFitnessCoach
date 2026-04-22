/// Stats & Rewards tab body for the You hub.
///
/// Grouped sections (not a flat grid):
///   • PROGRESS — XP Goals, Skills, Streaks summary (hierarchy-first info)
///   • RECOGNITION — Trophies, Achievements
///   • RECAPS & PERKS — Wrapped, Rewards, Inventory
///   • SOCIAL — Leaderboard
///
/// Cards render live headline data (earned / total, next-trophy %, etc.) so
/// the tab acts as a dashboard instead of a launcher. Failed sub-requests
/// fall back to "—" on a single card — never blank the whole page.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/api_client.dart';

class YouStatsRewardsTab extends ConsumerStatefulWidget {
  const YouStatsRewardsTab({super.key});

  @override
  ConsumerState<YouStatsRewardsTab> createState() => _YouStatsRewardsTabState();
}

class _YouStatsRewardsTabState extends ConsumerState<YouStatsRewardsTab> {
  // Live metrics populated from parallel fetches. All null until loaded;
  // cards render `—` as the fallback metric when their source failed.
  Map<String, dynamic>? _trophySummary;
  Map<String, dynamic>? _achievementsSummary;
  Map<String, dynamic>? _skillsSummary;
  Map<String, dynamic>? _latestSummary;
  int? _unclaimedRewards;
  int? _userRank;
  double? _userPercentile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final opts = Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
        validateStatus: (s) => s != null && s < 500,
      );

      final futures = await Future.wait([
        api.dio.get('/trophies/$userId/summary', options: opts),
        api.dio.get('/achievements/user/$userId/summary', options: opts),
        api.dio.get('/skill-progressions/user/$userId/summary', options: opts),
        api.dio.get('/summaries/user/$userId/latest', options: opts),
        api.dio.get('/xp/unclaimed-crates', options: opts),
        api.dio.get('/leaderboard/rank',
            queryParameters: {'user_id': userId}, options: opts),
      ]);

      if (futures[0].statusCode == 200 && futures[0].data is Map) {
        _trophySummary = (futures[0].data as Map).cast<String, dynamic>();
      }
      if (futures[1].statusCode == 200 && futures[1].data is Map) {
        _achievementsSummary = (futures[1].data as Map).cast<String, dynamic>();
      }
      if (futures[2].statusCode == 200 && futures[2].data is Map) {
        _skillsSummary = (futures[2].data as Map).cast<String, dynamic>();
      }
      if (futures[3].statusCode == 200 && futures[3].data is Map) {
        _latestSummary = (futures[3].data as Map).cast<String, dynamic>();
      }
      if (futures[4].statusCode == 200 && futures[4].data is Map) {
        final m = (futures[4].data as Map).cast<String, dynamic>();
        _unclaimedRewards = (m['count'] as num?)?.toInt();
      }
      if (futures[5].statusCode == 200 && futures[5].data is Map) {
        final m = (futures[5].data as Map).cast<String, dynamic>();
        _userRank = (m['rank'] as num?)?.toInt();
        _userPercentile = (m['percentile'] as num?)?.toDouble();
      }
    } catch (_) {
      // Each card renders its own fallback — a global error banner would
      // be noisy since individual sub-requests may still have succeeded.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    return RefreshIndicator(
      color: accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // PROGRESS — the "where am I on the journey" group
          _SectionLabel(label: 'PROGRESS', fg: fg),
          const SizedBox(height: 10),
          _ProgressGroup(
            xp: ref.watch(xpProvider),
            skills: _skillsSummary,
            achievements: _achievementsSummary,
            fg: fg,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // RECOGNITION — earned badges
          _SectionLabel(label: 'RECOGNITION', fg: fg),
          const SizedBox(height: 10),
          _RecognitionGroup(
            trophySummary: _trophySummary,
            achievementsSummary: _achievementsSummary,
            fg: fg,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // RECAPS & PERKS — optional, lower priority
          _SectionLabel(label: 'RECAPS & PERKS', fg: fg),
          const SizedBox(height: 10),
          _RecapsPerksGroup(
            latestSummary: _latestSummary,
            unclaimedRewards: _unclaimedRewards,
            fg: fg,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // SOCIAL — external / peer comparison
          _SectionLabel(label: 'SOCIAL', fg: fg),
          const SizedBox(height: 10),
          _SocialGroup(
            rank: _userRank,
            percentile: _userPercentile,
            fg: fg,
            accent: accent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color fg;
  const _SectionLabel({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: fg.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// =========================================================================
// PROGRESS GROUP — XP primary (wide), Skills + Achievements-progress row.
// Primary card gets extra visual weight because level/XP is the headline
// metric — everything else is secondary context.
// =========================================================================

class _ProgressGroup extends StatelessWidget {
  final XPState xp;
  final Map<String, dynamic>? skills;
  final Map<String, dynamic>? achievements;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _ProgressGroup({
    required this.xp,
    required this.skills,
    required this.achievements,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final level = xp.currentLevel;
    final progress = xp.progressFraction.clamp(0.0, 1.0);
    final xpToNext = xp.xpToNextLevel;

    final activeList = skills?['active_progressions'] as List?;
    final activeChains = activeList?.length ?? 0;
    final completedChains =
        (skills?['total_chains_completed'] as num?)?.toInt() ?? 0;
    String? activeSkillName;
    if (activeList != null && activeList.isNotEmpty) {
      final first = activeList.first;
      if (first is Map) {
        activeSkillName = first['current_step_name'] as String?;
      }
    }

    final achievementsEarned =
        (achievements?['total_achievements'] as num?)?.toInt();
    final achievementsPoints =
        (achievements?['total_points'] as num?)?.toInt();

    return Column(
      children: [
        _PrimaryTile(
          icon: Icons.bolt_rounded,
          title: 'Level $level',
          subtitle: xpToNext > 0
              ? '${(progress * 100).toInt()}% to Level ${level + 1}'
              : 'Maxed',
          progress: progress,
          fg: fg,
          accent: accent,
          isDark: isDark,
          route: '/xp-goals',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.timeline_rounded,
                title: 'Skills',
                headline: skills == null
                    ? '—'
                    : '$activeChains active',
                sub: activeSkillName ??
                    (completedChains > 0 ? '$completedChains done' : 'Start a chain'),
                fg: fg,
                accent: accent,
                isDark: isDark,
                route: '/skills',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.verified_rounded,
                title: 'Achievements',
                headline: achievementsEarned != null
                    ? '$achievementsEarned earned'
                    : '—',
                sub: achievementsPoints != null
                    ? '$achievementsPoints pts'
                    : 'Milestones',
                fg: fg,
                accent: accent,
                isDark: isDark,
                route: '/achievements',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =========================================================================
// RECOGNITION GROUP — trophies is the flagship (with progress bar),
// achievements-category breakdown renders inline.
// =========================================================================

class _RecognitionGroup extends StatelessWidget {
  final Map<String, dynamic>? trophySummary;
  final Map<String, dynamic>? achievementsSummary;
  final Color fg;
  final Color accent;
  final bool isDark;
  const _RecognitionGroup({
    required this.trophySummary,
    required this.achievementsSummary,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final earned = (trophySummary?['earned_trophies'] as num?)?.toInt();
    final total = (trophySummary?['total_trophies'] as num?)?.toInt();
    final points = (trophySummary?['total_points'] as num?)?.toInt();
    final progress = (earned != null && total != null && total > 0)
        ? earned / total
        : 0.0;

    return _PrimaryTile(
      icon: Icons.emoji_events_rounded,
      title: 'Trophies',
      subtitle: (earned != null && total != null)
          ? '$earned of $total earned${points != null ? ' · $points pts' : ''}'
          : 'View your trophy room',
      progress: progress,
      fg: fg,
      accent: accent,
      isDark: isDark,
      route: '/trophy-room',
    );
  }
}

// =========================================================================
// RECAPS & PERKS — weekly wrapped teaser + rewards + inventory.
// Inventory is intentionally text-only (no live count) to keep this row
// low-weight vs the primary progress/recognition sections.
// =========================================================================

class _RecapsPerksGroup extends StatelessWidget {
  final Map<String, dynamic>? latestSummary;
  final int? unclaimedRewards;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _RecapsPerksGroup({
    required this.latestSummary,
    required this.unclaimedRewards,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final workouts = (latestSummary?['workouts_completed'] as num?)?.toInt();
    final prs = (latestSummary?['prs_achieved'] as num?)?.toInt();
    final weekStart = latestSummary?['week_start'] as String?;
    final wrappedRoute = (weekStart != null && weekStart.isNotEmpty)
        ? '/weekly-wrapped?week_start=$weekStart'
        : '/weekly-wrapped';

    return Column(
      children: [
        _MetricTile(
          icon: Icons.auto_awesome_rounded,
          title: 'Wrapped',
          headline: latestSummary == null
              ? '—'
              : '$workouts workouts',
          sub: prs != null
              ? '$prs PRs last week'
              : 'Monthly & weekly recaps',
          fg: fg,
          accent: accent,
          isDark: isDark,
          route: wrappedRoute,
          wide: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.card_giftcard_rounded,
                title: 'Rewards',
                headline: unclaimedRewards != null && unclaimedRewards! > 0
                    ? '$unclaimedRewards ready'
                    : 'View perks',
                sub: unclaimedRewards != null && unclaimedRewards! > 0
                    ? 'Tap to claim'
                    : 'Redeem benefits',
                fg: fg,
                accent: accent,
                isDark: isDark,
                route: '/rewards',
                highlight: (unclaimedRewards ?? 0) > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.inventory_2_rounded,
                title: 'Inventory',
                headline: 'Items',
                sub: 'Collectibles',
                fg: fg,
                accent: accent,
                isDark: isDark,
                route: '/inventory',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =========================================================================
// SOCIAL — leaderboard rank with percentile tag.
// =========================================================================

class _SocialGroup extends StatelessWidget {
  final int? rank;
  final double? percentile;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _SocialGroup({
    required this.rank,
    required this.percentile,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rankLabel = rank != null ? '#$rank' : '—';
    final percentileLabel = percentile != null
        ? 'Top ${(100 - percentile!).toStringAsFixed(0)}%'
        : 'See where you stand';

    return _MetricTile(
      icon: Icons.leaderboard_rounded,
      title: 'Leaderboard',
      headline: rankLabel,
      sub: percentileLabel,
      fg: fg,
      accent: accent,
      isDark: isDark,
      route: '/xp-leaderboard',
      wide: true,
    );
  }
}

// =========================================================================
// Tile primitives
// =========================================================================

/// Large, wide tile with a progress bar. Used for flagship cards where
/// the progress-toward-next metric is the most important signal.
class _PrimaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color fg;
  final Color accent;
  final bool isDark;
  final String route;

  const _PrimaryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.fg,
    required this.accent,
    required this.isDark,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(route);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.10 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: fg.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: fg.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact 2-line metric tile. `wide: true` makes it span full width for
/// secondary info that deserves a bit more air than a half-width card.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String headline;
  final String sub;
  final Color fg;
  final Color accent;
  final bool isDark;
  final String route;
  final bool wide;
  final bool highlight;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.headline,
    required this.sub,
    required this.fg,
    required this.accent,
    required this.isDark,
    required this.route,
    this.wide = false,
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
        child: wide
            ? _wideLayout()
            : _compactLayout(),
      ),
    );
  }

  Widget _compactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: fg.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          headline,
          style: TextStyle(
            color: fg,
            fontSize: 16,
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
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                headline,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.4)),
      ],
    );
  }
}
