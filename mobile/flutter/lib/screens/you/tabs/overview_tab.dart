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
import '../../../widgets/xp_hero_tile.dart';

class YouOverviewTab extends ConsumerStatefulWidget {
  const YouOverviewTab({super.key});

  @override
  ConsumerState<YouOverviewTab> createState() => _YouOverviewTabState();
}

class _YouOverviewTabState extends ConsumerState<YouOverviewTab> {
  List<dynamic>? _streaks;
  Map<String, dynamic>? _latestSummary;
  Map<String, dynamic>? _trophySummary;
  List<dynamic>? _recentTrophies;
  Map<String, dynamic>? _skillsSummary;
  // Leaderboard state: null = still loading, unlocked=false → show unlock
  // progress, unlocked=true → show percentile / rank.
  bool? _leaderboardUnlocked;
  int _workoutsNeeded = 10;
  double? _percentile;
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
      if (userId == null) return;

      // Kick off the XP refresh via the canonical provider. It hits
      // `/progress/xp/{userId}` and updates `userXpProvider` which the
      // `_LevelCard` widget watches directly — no map plumbing needed.
      // `unclaimedCratesCountProvider` wraps the repository's crates call,
      // so the old broken `/xp/unclaimed-crates` fetch is gone too.
      unawaited(ref.read(xpProvider.notifier).loadUserXP(userId: userId));

      // 15s receive-timeout: the leaderboard snapshot + achievements summary
      // queries are heavier than the rest; 8s starved them into `—` states.
      final opts = Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (s) => s != null && s < 500,
      );

      final futures = await Future.wait([
        api.dio.get('/achievements/user/$userId/streaks', options: opts),
        api.dio.get('/summaries/user/$userId/latest', options: opts),
        api.dio.get('/progress/trophies/$userId/summary', options: opts),
        api.dio.get('/progress/trophies/$userId/recent',
            queryParameters: {'limit': 1}, options: opts),
        api.dio.get('/skill-progressions/user/$userId/summary', options: opts),
        api.dio.get('/leaderboard/unlock-status',
            queryParameters: {'user_id': userId}, options: opts),
      ]);

      if (futures[0].statusCode == 200) {
        final data = futures[0].data;
        if (data is List) _streaks = data;
        if (data is Map && data['streaks'] is List) _streaks = data['streaks'] as List;
      }
      if (futures[1].statusCode == 200 && futures[1].data is Map) {
        _latestSummary = (futures[1].data as Map).cast<String, dynamic>();
      }
      if (futures[2].statusCode == 200 && futures[2].data is Map) {
        _trophySummary = (futures[2].data as Map).cast<String, dynamic>();
      }
      if (futures[3].statusCode == 200 && futures[3].data is List) {
        _recentTrophies = futures[3].data as List;
      }
      if (futures[4].statusCode == 200 && futures[4].data is Map) {
        _skillsSummary = (futures[4].data as Map).cast<String, dynamic>();
      }
      if (futures[5].statusCode == 200 && futures[5].data is Map) {
        final m = (futures[5].data as Map).cast<String, dynamic>();
        _leaderboardUnlocked = m['is_unlocked'] as bool? ?? false;
        _workoutsNeeded = (m['workouts_needed'] as num?)?.toInt() ?? 10;
        // Only fetch the rank if the user has actually unlocked it —
        // otherwise /leaderboard/rank 404s and writes nothing.
        if (_leaderboardUnlocked == true) {
          final rankRes = await api.dio.get('/leaderboard/rank',
              queryParameters: {'user_id': userId}, options: opts);
          if (rankRes.statusCode == 200 && rankRes.data is Map) {
            final rm = (rankRes.data as Map).cast<String, dynamic>();
            _percentile = (rm['percentile'] as num?)?.toDouble();
          }
        }
      }
    } catch (_) {
      // Per-block error handling — overview renders whatever data it got.
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

    final serious = ref.watch(seriousModeProvider);

    return RefreshIndicator(
      color: accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
