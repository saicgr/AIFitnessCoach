/// Badge Hub — Garmin/Amazfit-style gallery of the user's trophies,
/// masteries, PRs, and active challenges.
///
/// Sections top-to-bottom:
///   1. Reward-Your-Progress hero banner (teal→green gradient)
///   2. MY BADGES — gradient tile showcasing recent earned trophies
///   3. IN PROGRESS — horizontal scroll of earnable badges with reset
///      dates (reuses existing trophy progress data)
///   4. CHALLENGES — JOIN-button cards (active async challenges)
///   5. PERSONAL BESTS — grid of PR medals (strength records)
///   6. MASTERIES — hex-badge grid of levelled counters (Steps Lv.6 etc.)
///   7. ALL AVAILABLE BADGES — footer deep-link to the full catalogue
///      (today's trophy_room_screen.dart lives on as the "browse" view)
///
/// Data is pulled from existing providers wherever possible:
///   • `trophySummaryProvider`, `earnedTrophiesProvider`,
///     `inProgressTrophiesProvider` (existing XP provider stack)
///   • `masteriesProvider` (new, Phase 4d)
///   • `/leaderboard/async-challenge` for active challenges
///   • `/progress/xp/{id}/summary` exposes PR counts — for the PB section
///     we use the trophy list filtered by category 'strength' until a
///     dedicated PR endpoint lands.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/masteries_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/pill_app_bar.dart';
import 'widgets/badge_hub_hero.dart';
import 'widgets/challenges_strip.dart';
import 'widgets/in_progress_strip.dart';
import 'widgets/masteries_grid.dart';
import 'widgets/my_badges_showcase.dart';
import 'widgets/personal_bests_grid.dart';

class BadgeHubScreen extends ConsumerStatefulWidget {
  const BadgeHubScreen({super.key});

  @override
  ConsumerState<BadgeHubScreen> createState() => _BadgeHubScreenState();
}

class _BadgeHubScreenState extends ConsumerState<BadgeHubScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the trophy + XP data is fresh when this screen opens. The
    // first-time landing from the You hub won't have loaded these yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xpProvider.notifier).loadAll();
      ref.read(xpProvider.notifier).loadTrophies();
      ref.read(xpProvider.notifier).loadTrophySummary();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(xpProvider.notifier).loadTrophies(),
      ref.read(xpProvider.notifier).loadTrophySummary(),
    ]);
    ref.invalidate(masteriesProvider);
  }

  void _showHowItWorks(BuildContext context, bool isDark) {
    HapticService.selection();
    showGlassSheet(
      context: context,
      builder: (_) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reward Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _HelpRow(
                icon: Icons.workspace_premium_outlined,
                title: 'Badges',
                body: 'One-time trophies for hitting milestones — time goals, consistency runs, big PRs.',
                isDark: isDark,
              ),
              _HelpRow(
                icon: Icons.timer_outlined,
                title: 'In Progress',
                body: 'Weekly or daily challenges you can chase. They reset on a schedule so you can always re-earn them.',
                isDark: isDark,
              ),
              _HelpRow(
                icon: Icons.military_tech_outlined,
                title: 'Masteries',
                body: 'Levelled badges that keep climbing as you log more steps, calories, sessions, or distance.',
                isDark: isDark,
              ),
              _HelpRow(
                icon: Icons.emoji_events_outlined,
                title: 'Personal Bests',
                body: 'Your highest lifts, longest sessions, biggest workouts. Beat them to upgrade the medal.',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);

    final allTrophies = ref.watch(allTrophiesProvider);
    final earned = ref.watch(earnedTrophiesProvider);
    final inProgress = ref.watch(inProgressTrophiesProvider);
    final summary = ref.watch(trophySummaryProvider);
    final masteriesAsync = ref.watch(masteriesProvider);

    // Personal-best trophies — filter by strength category until a
    // dedicated PR catalogue ships. Keeps the section populated with the
    // most PR-shaped earned trophies.
    final personalBests = allTrophies
        .where((t) {
          final c = t.trophy.category.toLowerCase();
          return c == 'strength' || c == 'performance';
        })
        .take(6)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: PillAppBar(
        title: 'Badges',
        actions: [
          PillAppBarAction(
            icon: Icons.info_outline,
            onTap: () => _showHowItWorks(context, isDark),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: accent,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
          children: [
            // 1. Hero banner — teal→green gradient with badge cluster
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BadgeHubHero(
                onHowItWorksTap: () => _showHowItWorks(context, isDark),
              ),
            ),
            const SizedBox(height: 24),

            // 2. MY BADGES — recently earned showcase
            _SectionHeader(
              label: 'MY BADGES',
              fg: fg,
              trailing: earned.isNotEmpty
                  ? () => context.push('/trophy-room')
                  : null,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MyBadgesShowcase(
                earned: earned,
                totalTrophies: summary?.totalTrophies ?? 0,
              ),
            ),
            const SizedBox(height: 24),

            // 3. IN PROGRESS — strip with progress bars + resets
            _SectionHeader(label: 'IN PROGRESS', fg: fg),
            const SizedBox(height: 10),
            InProgressStrip(trophies: inProgress.take(8).toList()),
            const SizedBox(height: 24),

            // 4. CHALLENGES — JOIN buttons for active async challenges
            _SectionHeader(label: 'CHALLENGES', fg: fg),
            const SizedBox(height: 10),
            const ChallengesStrip(),
            const SizedBox(height: 24),

            // 5. PERSONAL BESTS — 3-col medal grid
            _SectionHeader(label: 'PERSONAL BESTS', fg: fg),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PersonalBestsGrid(trophies: personalBests),
            ),
            const SizedBox(height: 24),

            // 6. MASTERIES — hex grid of levelled badges
            _SectionHeader(label: 'MASTERIES', fg: fg),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: masteriesAsync.when(
                data: (rows) => MasteriesGrid(entries: rows),
                loading: () => const MasteriesGrid(entries: [], loading: true),
                error: (_, __) => const MasteriesGrid(entries: []),
              ),
            ),
            const SizedBox(height: 24),

            // 7. ALL AVAILABLE BADGES — footer deep-link
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AllBadgesFooter(
                count: summary?.totalTrophies ?? allTrophies.length,
                onTap: () => context.push('/trophy-room'),
                fg: fg,
                accent: accent,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String label;
  final Color fg;
  final VoidCallback? trailing;

  const _SectionHeader({
    required this.label,
    required this.fg,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          if (trailing != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                Icons.chevron_right_rounded,
                color: fg.withValues(alpha: 0.55),
                size: 22,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                trailing!();
              },
            ),
        ],
      ),
    );
  }
}


class _AllBadgesFooter extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final Color fg;
  final Color accent;
  final bool isDark;

  const _AllBadgesFooter({
    required this.count,
    required this.onTap,
    required this.fg,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Material(
      color: isDark ? AppColors.elevated : AppColorsLight.elevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All available badges',
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                count > 0 ? '$count total' : '',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: fg.withValues(alpha: 0.55), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}


class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  const _HelpRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF22D3EE),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

