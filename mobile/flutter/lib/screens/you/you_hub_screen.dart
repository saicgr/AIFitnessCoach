/// You Hub Screen
///
/// Replaces the Profile tab (tab index 4) in the bottom nav. Consolidates
/// profile + gamification surfaces (trophies, achievements, XP, skills,
/// wrapped, rewards, inventory) under one tab while preserving every
/// existing deep link.
///
/// Research context (see plan 1-weekly-crystalline-chipmunk.md Item 6):
///   Material 3 caps bottom nav at 5 tabs. We kept 5 tabs + renamed the
///   last one "You" (Strava/Nike pattern) instead of adding a 6th tab or
///   an FAB (FAB is semantically for "create" primary actions, not nav).
///
/// Architecture:
///   - Top-tabs: Overview | Profile | Stats & Rewards
///   - "Overview" is a new aggregated dashboard (level, XP, streaks,
///     recent trophies, next-trophy target).
///   - "Profile" reuses the existing ProfileScreen body.
///   - "Stats & Rewards" is a grid of deep-link cards to Trophies,
///     Achievements, XP Goals, Skills, Wrapped, Rewards, Inventory.
///   - Every existing route (/trophy-room, /xp-goals, etc.) still works
///     and opens its original screen — no deep-link breakage.
///   - Serious Mode toggle (in settings) dims the Overview gamification
///     visuals and makes Profile the landing tab for users who want a
///     lower-noise experience.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/serious_mode_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../profile/profile_screen.dart';
import 'tabs/overview_tab.dart';
import 'tabs/stats_rewards_tab.dart';

class YouHubScreen extends ConsumerStatefulWidget {
  /// Initial tab index (0 = Overview, 1 = Profile, 2 = Stats & Rewards).
  /// Defaults to Overview. Deep links may pass `?tab=profile` etc.
  final int initialTabIndex;
  final String? profileScrollTo;

  const YouHubScreen({
    super.key,
    this.initialTabIndex = 0,
    this.profileScrollTo,
  });

  @override
  ConsumerState<YouHubScreen> createState() => _YouHubScreenState();
}

class _YouHubScreenState extends ConsumerState<YouHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Serious Mode: Profile is the landing tab instead of Overview. We only
    // apply this when the caller didn't explicitly request a tab — respect
    // deep links like `/profile?tab=overview` even when Serious Mode is on.
    final serious = ref.read(seriousModeProvider);
    final defaultIdx = serious ? 1 : widget.initialTabIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: defaultIdx.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Persistent header: title row + settings cog. Avatar could be
            // added here in a future pass; keep header minimal for now so
            // the first-time user sees the tab content immediately.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    'You',
                    style: TextStyle(
                      color: fg,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: fg),
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            // Top-tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: accent,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                labelColor: fg,
                unselectedLabelColor: fg.withValues(alpha: 0.5),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Profile'),
                  Tab(text: 'Stats & Rewards'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const YouOverviewTab(),
                  ProfileScreen(scrollTo: widget.profileScrollTo),
                  const YouStatsRewardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
