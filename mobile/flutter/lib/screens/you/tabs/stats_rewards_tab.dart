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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/stat_typography.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/design_system/section_header.dart';
import '../you_hub_screen.dart' show kYouHubBodyBottomInset;
import '../../../widgets/xp_hero_tile.dart';

import '../../../l10n/generated/app_localizations.dart';
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
  // Leaderboard state — null while the unlock-status call is in flight.
  // `false` = locked, show progress-to-unlock. `true` = call `/rank` next.
  bool? _leaderboardUnlocked;
  int _workoutsNeeded = 10;
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

      // Kick off XP + unclaimed-crates refreshes through the canonical
      // provider stack. The `Rewards` tile below now watches
      // `unclaimedCratesCountProvider` directly, and the PROGRESS group
      // already watches `xpProvider` — so we stop making raw calls to the
      // non-existent `/xp/unclaimed-crates` endpoint here.
      unawaited(ref.read(xpProvider.notifier).loadUserXP(userId: userId));

      // 15s receive — the leaderboard snapshot + achievements summary
      // queries are the heaviest; 8s starved them into permanent "—".
      final opts = Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (s) => s != null && s < 500,
      );

      final futures = await Future.wait([
        api.dio.get('/progress/trophies/$userId/summary', options: opts),
        api.dio.get('/achievements/user/$userId/summary', options: opts),
        api.dio.get('/skill-progressions/user/$userId/summary', options: opts),
        api.dio.get('/summaries/user/$userId/latest', options: opts),
        api.dio.get('/leaderboard/unlock-status',
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
        _leaderboardUnlocked = m['is_unlocked'] as bool? ?? false;
        _workoutsNeeded = (m['workouts_needed'] as num?)?.toInt() ?? 10;
        // Only fetch the rank once unlock is confirmed — otherwise /rank
        // 404s and the card would sit at "—" forever.
        if (_leaderboardUnlocked == true) {
          final rankRes = await api.dio.get('/leaderboard/rank',
              queryParameters: {'user_id': userId}, options: opts);
          if (rankRes.statusCode == 200 && rankRes.data is Map) {
            final rm = (rankRes.data as Map).cast<String, dynamic>();
            _userRank = (rm['rank'] as num?)?.toInt();
            _userPercentile = (rm['percentile'] as num?)?.toDouble();
          }
        }
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

    // Bottom padding must clear BOTH the floating sub-tab pill AND the
    // main nav bar underneath it. `kYouHubBodyBottomInset` bundles both
    // heights + breathing room — single source of truth shared by every
    // You-hub sub-tab body.
    final bottomInset =
        MediaQuery.of(context).viewPadding.bottom + kYouHubBodyBottomInset;

    return RefreshIndicator(
      color: accent,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
        children: [
          // PROGRESS — the "where am I on the journey" group
          _SectionLabel(label: AppLocalizations.of(context).statsRewardsProgress, fg: fg),
          const SizedBox(height: 10),
          // Hero XP tile takes over the primary-tile slot. Skills +
          // Achievements continue to render below as secondary metrics.
          const XpHeroTile(),
          const SizedBox(height: 10),
          _ProgressSecondaryRow(
            skills: _skillsSummary,
            achievements: _achievementsSummary,
            fg: fg,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // INSIGHTS — interactive trends + correlations
          _SectionLabel(label: AppLocalizations.of(context).statsRewardsInsights, fg: fg),
          const SizedBox(height: 10),
          _MetricTile(
            icon: Icons.auto_graph_rounded,
            title: AppLocalizations.of(context).statsRewardsCustomTrends,
            headline: AppLocalizations.of(context).statsRewardsBuildATrend,
            sub: AppLocalizations.of(context).statsRewardsOverlayAnyTwoMetrics,
            fg: fg,
            accent: accent,
            isDark: isDark,
            route: '/trends/custom',
            wide: true,
          ),
          const SizedBox(height: 20),

          // RECOGNITION — earned badges
          _SectionLabel(label: AppLocalizations.of(context).statsRewardsRecognition, fg: fg),
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
          _SectionLabel(label: AppLocalizations.of(context).statsRewardsRecapsPerks, fg: fg),
          const SizedBox(height: 10),
          _RecapsPerksGroup(
            latestSummary: _latestSummary,
            fg: fg,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // SOCIAL — external / peer comparison
          _SectionLabel(label: AppLocalizations.of(context).statsRewardsSocial, fg: fg),
          const SizedBox(height: 10),
          _SocialGroup(
            unlocked: _leaderboardUnlocked,
            workoutsNeeded: _workoutsNeeded,
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

/// Section label — wraps the design-system [SectionHeader] so this tab's
/// existing call-sites (`_SectionLabel(label: 'PROGRESS', fg: fg)`) keep
/// compiling. Surface 5.C drops the colored / heavy-weight headers in
/// favor of the muted small-caps single style used everywhere.
class _SectionLabel extends StatelessWidget {
  final String label;
  // Retained for call-site compatibility — the actual color comes from
  // the design-system token (ThemeColors.textMuted).
  // ignore: unused_element_parameter
  final Color fg;
  const _SectionLabel({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      label: label,
      padding: const EdgeInsets.only(left: 4, top: 0, bottom: 0),
    );
  }
}

// =========================================================================
// PROGRESS GROUP — XP primary (wide), Skills + Achievements-progress row.
// Primary card gets extra visual weight because level/XP is the headline
// metric — everything else is secondary context.
// =========================================================================

/// Secondary row under the XP hero — Skills + Achievements side-by-side.
/// Kept as a plain Row (no PrimaryTile) because the hero card now owns
/// the "level/progress" headline slot.
class _ProgressSecondaryRow extends StatelessWidget {
  final Map<String, dynamic>? skills;
  final Map<String, dynamic>? achievements;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _ProgressSecondaryRow({
    required this.skills,
    required this.achievements,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.timeline_rounded,
            title: AppLocalizations.of(context).youSkills,
            headline: skills == null ? '—' : '$activeChains active',
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
            title: AppLocalizations.of(context).youAchievements,
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
      title: AppLocalizations.of(context).youTrophies,
      subtitle: (earned != null && total != null)
          ? '$earned of $total earned${points != null ? ' · $points pts' : ''}'
          : 'View your badges',
      progress: progress,
      fg: fg,
      accent: accent,
      isDark: isDark,
      // Route to the Garmin-style Badge Hub (gallery) instead of the
      // flat trophy-room grid. The grid is still reachable as "All
      // available badges" from the hub footer.
      route: '/badge-hub',
    );
  }
}

// =========================================================================
// RECAPS & PERKS — weekly wrapped teaser + rewards + inventory.
// Inventory is intentionally text-only (no live count) to keep this row
// low-weight vs the primary progress/recognition sections.
// =========================================================================

class _RecapsPerksGroup extends ConsumerWidget {
  final Map<String, dynamic>? latestSummary;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _RecapsPerksGroup({
    required this.latestSummary,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = (latestSummary?['workouts_completed'] as num?)?.toInt();
    final prs = (latestSummary?['prs_achieved'] as num?)?.toInt();
    final weekStart = latestSummary?['week_start'] as String?;
    final wrappedRoute = (weekStart != null && weekStart.isNotEmpty)
        ? '/weekly-wrapped?week_start=$weekStart'
        : '/weekly-wrapped';

    // Unclaimed-crate count now flows from `unclaimedCratesCountProvider`
    // (canonical, repo-backed). The old `/xp/unclaimed-crates` raw call
    // was removed because that endpoint doesn't exist — it silently 404'd
    // and left this tile showing "View perks" forever.
    final unclaimedRewards = ref.watch(unclaimedCratesCountProvider);

    return Column(
      children: [
        _MetricTile(
          icon: Icons.auto_awesome_rounded,
          title: AppLocalizations.of(context).youWrapped,
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
                title: AppLocalizations.of(context).statsRewardsRewards,
                headline: unclaimedRewards > 0
                    ? '$unclaimedRewards ready'
                    : 'View perks',
                sub: unclaimedRewards > 0
                    ? 'Tap to claim'
                    : 'Redeem benefits',
                fg: fg,
                accent: accent,
                isDark: isDark,
                route: '/rewards',
                highlight: unclaimedRewards > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.inventory_2_rounded,
                title: AppLocalizations.of(context).xpGoalsScreenInventory,
                headline: AppLocalizations.of(context).statsRewardsItems,
                sub: AppLocalizations.of(context).statsRewardsCollectibles,
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
  final bool? unlocked;
  final int workoutsNeeded;
  final int? rank;
  final double? percentile;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _SocialGroup({
    required this.unlocked,
    required this.workoutsNeeded,
    required this.rank,
    required this.percentile,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Three distinct states so the tile never renders "—" without a reason.
    // Phase 3 will replace this with a challenge-based tile by default.
    final String headline;
    final String sub;
    if (unlocked == false) {
      headline = workoutsNeeded == 1
          ? '1 to unlock'
          : '$workoutsNeeded to unlock';
      sub = workoutsNeeded == 1
          ? 'Log 1 more workout'
          : 'Log $workoutsNeeded more workouts';
    } else if (rank != null) {
      headline = '#$rank';
      sub = percentile != null
          ? 'Top ${(100 - percentile!).toStringAsFixed(0)}%'
          : 'On global leaderboard';
    } else {
      // Unlock-status fetch failed or user is unlocked but /rank didn't
      // return a row yet — treat as unknown rather than shouting "—".
      headline = 'Leaderboard';
      sub = 'See where you stand';
    }

    return _MetricTile(
      icon: Icons.leaderboard_rounded,
      title: AppLocalizations.of(context).statsRewardsLeaderboard,
      headline: headline,
      sub: sub,
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
        _MetricHeadline(headline: headline, fg: fg),
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
              _MetricHeadline(headline: headline, fg: fg),
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

/// Renders a [_MetricTile] headline so the NUMERIC part reads big and
/// glanceable while any trailing word stays small + muted.
///
/// The headlines this tab produces are one of two shapes:
///   • number-led — "3 active", "5 earned", "120 workouts", "340 pts",
///     "3 ready", "10 to unlock", or a rank like "#42". Here the leading
///     number is the metric, so it jumps to [StatType.secondary] (24px,
///     w800 to keep the existing emphasis) and the trailing word renders as
///     the small muted [StatNumber] unit.
///   • purely textual — "Build a trend", "View perks", "Items",
///     "Leaderboard", or the "—" fallback. These carry no number, so they
///     keep the original 16/w800 title style unchanged.
///
/// Detection is deterministic (a regex on the leading token), never an LLM
/// or a hardcoded whitelist of phrases — new number-led headlines added
/// later are picked up automatically.
class _MetricHeadline extends StatelessWidget {
  final String headline;
  final Color fg;

  const _MetricHeadline({required this.headline, required this.fg});

  /// Splits a number-led headline into (number, trailingUnit). The number
  /// token may carry a leading `#` (rank), thousands commas, or a decimal
  /// point. Returns null when the headline does not start with a number,
  /// signalling the textual-title fallback.
  static (String number, String unit)? _split(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    // Leading optional '#', then digits with optional commas/decimals.
    final match = RegExp(r'^(#?\d[\d,]*\.?\d*)(.*)$').firstMatch(value);
    if (match == null) return null;
    final number = match.group(1)!.trim();
    final unit = match.group(2)!.trim();
    return (number, unit);
  }

  @override
  Widget build(BuildContext context) {
    final parts = _split(headline);

    // Textual headline — keep the original emphasis exactly.
    if (parts == null) {
      return Text(
        headline,
        style: TextStyle(
          color: fg,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final (number, unit) = parts;
    return StatNumber(
      value: number,
      unit: unit.isEmpty ? null : unit,
      size: StatType.secondary,
      color: fg,
      weight: FontWeight.w800,
      unitColor: fg.withValues(alpha: 0.55),
    );
  }
}
