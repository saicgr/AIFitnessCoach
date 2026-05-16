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

import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/minigame_unlock_service.dart';
import '../../widgets/liquid_glass_action_bar.dart';
import '../../widgets/minigame/nutrient_rush_game.dart';
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
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // ── Hidden mini-game unlock easter-egg ──────────────────────────────
  // Tapping the header avatar [tapsToUnlock] times rapidly unlocks the
  // mini-games surface. Each tap resets a ~2s window; taps must be
  // consecutive. The first few taps are silent; the last 2-3 escalate a
  // haptic + show a subtle "N more…" hint so it stays discoverable.
  static const Duration _kTapWindow = Duration(milliseconds: 2000);
  int _avatarTapCount = 0;
  Timer? _tapWindowTimer;
  late final ConfettiController _unlockConfetti;

  @override
  void initState() {
    super.initState();
    _unlockConfetti =
        ConfettiController(duration: const Duration(milliseconds: 1400));
    // Always land on Overview by default — that's where the daily-glance
    // health snapshot (Today's Health / Last Night's Sleep / Weight Tracking)
    // lives. Previously Serious Mode redirected to Profile (the settings
    // surface), which forced users to swipe past gamification just to see
    // whether they hit their step goal. Serious Mode still dims the
    // gamification visuals on Overview (XpHeroTile reads `muted: serious`)
    // but no longer changes the landing tab.
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tapWindowTimer?.cancel();
    _unlockConfetti.dispose();
    super.dispose();
  }

  // ── Easter-egg tap handling ─────────────────────────────────────────

  /// Handles a tap on the header avatar. Once the mini-games surface is
  /// already unlocked, taps are a silent no-op.
  void _onAvatarTap() {
    final unlocked = ref.read(minigameUnlockedProvider);
    if (unlocked) return; // already unlocked — no-op

    _tapWindowTimer?.cancel();
    _avatarTapCount++;

    final remaining = MinigameUnlockService.tapsToUnlock - _avatarTapCount;

    if (remaining <= 0) {
      _triggerUnlock();
      return;
    }

    // Escalating feedback. Silent for the first taps; the final 3 taps
    // give a growing haptic + a subtle hint so the gesture is discoverable.
    if (remaining <= 2) {
      HapticService.medium();
    } else if (remaining == 3) {
      HapticService.light();
    }
    // else: silent (taps 1..N-3)

    if (remaining <= 3) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$remaining more…'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Reset the consecutive-tap window. A pause longer than _kTapWindow
    // discards progress so only rapid, deliberate tapping unlocks.
    _tapWindowTimer = Timer(_kTapWindow, () {
      _avatarTapCount = 0;
    });
  }

  Future<void> _triggerUnlock() async {
    _tapWindowTimer?.cancel();
    _avatarTapCount = 0;
    HapticService.success();
    _unlockConfetti.play();
    await ref.read(minigameUnlockedProvider.notifier).unlock();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🎮 Mini-games unlocked!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {}); // surface the permanent Mini-games entry point
  }

  /// Launches the mini-game in FREEPLAY mode — cosmetic only, NO XP.
  Future<void> _launchFreeplay() async {
    HapticService.light();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    // rewardEligible: false → anti-farm: freeplay never awards XP.
    await showNutrientRushGame(context, accent, rewardEligible: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);
    final minigamesUnlocked = ref.watch(minigameUnlockedProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Persistent header: avatar (hidden mini-game unlock target)
                // + title row + settings cog.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      // Profile avatar — also the hidden mini-game unlock
                      // gesture target (tap 7× rapidly). Once unlocked the
                      // taps become a silent no-op.
                      GestureDetector(
                        onTap: _onAvatarTap,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withValues(alpha: 0.7),
                                accent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'You',
                        style: TextStyle(
                          color: fg,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      // Permanent mini-games entry point — hidden until the
                      // easter-egg unlock fires. Launches FREEPLAY (no XP).
                      if (minigamesUnlocked)
                        IconButton(
                          icon: Icon(Icons.sports_esports_outlined, color: fg),
                          tooltip: 'Mini-games',
                          onPressed: _launchFreeplay,
                        ),
                      IconButton(
                        icon: Icon(Icons.bar_chart_rounded, color: fg),
                        tooltip: 'Stats & Scores',
                        onPressed: () => context.push('/stats'),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: fg),
                        tooltip: 'Settings',
                        onPressed: () => context.push('/settings'),
                      ),
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
            // Floating iOS 26 Liquid Glass tab bar — moves the
            // Overview / Profile / Stats & Rewards tabs to the thumb-zone
            // at the bottom, matching the Nutrition + Discover treatment.
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewPadding.bottom + 68,
              child: Center(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (_, __) => LiquidGlassActionBar(
                    accentColor: accent,
                    selectedIndex: _tabController.index,
                    items: [
                      LiquidGlassAction(
                        label: 'Overview',
                        icon: Icons.home_outlined,
                        onTap: () => _tabController.animateTo(0),
                      ),
                      LiquidGlassAction(
                        label: 'Profile',
                        icon: Icons.person_outline,
                        onTap: () => _tabController.animateTo(1),
                      ),
                      LiquidGlassAction(
                        label: 'Stats',
                        icon: Icons.emoji_events_outlined,
                        onTap: () => _tabController.animateTo(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Unlock celebration confetti — fires from the top center when
            // the mini-game easter-egg completes.
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _unlockConfetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 20,
                maxBlastForce: 18,
                minBlastForce: 6,
                gravity: 0.25,
                colors: [accent, Colors.amber, Colors.white],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
