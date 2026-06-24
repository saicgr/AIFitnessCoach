import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/chrome_constants.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton/skeleton.dart';
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
import '../../shareables/adapters/zealova_score_adapter.dart';
import '../../shareables/shareable_catalog.dart' show ShareableTemplate;
import '../../shareables/shareable_data.dart';
import '../../shareables/shareable_sheet.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/signature/signature.dart';
import '../../widgets/top_segmented_control.dart';
import '../../widgets/tooltips/tooltips.dart';
import '../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'widgets/leaderboard_row_adornments.dart';
import '../../l10n/generated/app_localizations.dart';
// Gym-finder map (GymBeat-style). Disabled until Maps API key is provisioned.
// See `widgets/gym_map_section.dart` for the full impl + re-enable steps.
// import 'widgets/gym_map_section.dart';

/// Workstream 2 — Discover tab.
///
/// Research-backed layout (Yu-kai Chou octalysis + Growth Engineering):
/// percentile hero → Rising Stars → Near You → collapsible Top 10.
/// Flat global leaderboards demotivate 95% of users — this structure
/// avoids that trap by making everyone visible and improving.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  // Sub-tab strip labels. "XP" matches the shorter "Volume" / "Streaks"
  // siblings; the "this week" context is conveyed by the hero card.
  static const _boardOptions = [
    ('xp', 'XP'),
    ('volume', 'Volume'),
    ('streaks', 'Streaks'),
  ];

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with WidgetsBindingObserver {
  // Snapshot freshness window — within this we trust the cached snapshot
  // and skip the invalidate. Tab-switching within a minute should feel
  // instant. Past this, we silently refetch in the background while the
  // cached snapshot stays painted. Resume from background uses a longer
  // window so foreground hops don't keep slamming the leaderboard API.
  static const Duration _staleAfterMount = Duration(seconds: 60);
  static const Duration _staleAfterResume = Duration(minutes: 5);
  static DateTime? _lastFetchedAt;

  /// SharedPreferences key for the [CacheFirstView] first-ever-open flag.
  /// While true the screen shows a layout-matched skeleton instead of a
  /// blocking spinner; flipped false after the first successful render.
  static const String _seenKey = 'discover_screen';

  /// True only on a genuine first-ever open on this install — drives whether
  /// [CacheFirstView] shows the skeleton. Defaults to false so a returning
  /// user (whose provider seeds from the disk cache) never sees a skeleton if
  /// the flag read is slow.
  bool _isFirstEver = false;

  bool _isStale(Duration window) {
    final last = _lastFetchedAt;
    return last == null || DateTime.now().difference(last) > window;
  }

  void _maybeRefresh(Duration window) {
    if (!_isStale(window)) return;
    ref.invalidate(discoverSnapshotProvider);
    _lastFetchedAt = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Background refresh on mount, but only when the cached snapshot is
    // stale. Previously this fired on every mount which made tab-switching
    // feel laggy (and triggered the shared error path that bled "Claim
    // failed" toasts onto the Discover screen).
    //
    // Also kick the XP provider to load — the hero card reads userXpProvider
    // for the "Lvl N · 956 XP lifetime" badge. If XP state hasn't been
    // hydrated yet (fresh app open, no one loaded it upstream), the badge
    // would show the default Lvl 1 · 0 XP from UserXP.empty() which is
    // jarringly wrong for a real user. Explicit load on Discover mount
    // guarantees the hero gets real numbers.
    // Resolve whether this is a true cold-install first open. Returning users
    // already have a disk-cached snapshot, so they render content instantly
    // and must never see the skeleton again.
    CacheFirstView.hasBeenSeen(_seenKey).then((seen) {
      if (!mounted) return;
      if (!seen) setState(() => _isFirstEver = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeRefresh(_staleAfterMount);
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

  /// F12/F13 — build the Zealova Score [Shareable] from the live Discover
  /// snapshot (deterministic percentile + composite score) and open the share
  /// sheet on the `zealovaScore` preset. Returns gracefully when the viewer is
  /// not ranked yet (no honest percentile to brag about).
  Future<void> _shareMyScore() async {
    HapticService.light();
    Shareable? data;
    try {
      data = await ZealovaScoreAdapter.fromProviders(ref);
    } catch (_) {
      // surfaced below
    }
    if (!mounted) return;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're not ranked yet — log a few workouts and check back."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await ShareableSheet.show(
      context,
      data: data,
      initialTemplate: ShareableTemplate.zealovaScore,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    super.didChangeAppLifecycleState(appState);
    // Silent refresh when the app is brought back to the foreground while
    // Discover is the active screen — but only if the snapshot is older
    // than the resume window so a quick tab-out / tab-in doesn't slam the
    // leaderboard API.
    if (appState == AppLifecycleState.resumed && mounted) {
      _maybeRefresh(_staleAfterResume);
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
    // blanking the whole screen — CacheFirstView latches the last value, so the
    // previous board's data stays painted until the new board resolves.
    final isReloading = snap.valueOrNull != null && snap.isLoading;

    // Map AsyncValue<DiscoverSnapshot?> → AsyncValue<DiscoverSnapshot> for the
    // CacheFirstView. A resolved-but-null value (network failure with no disk
    // cache) becomes the genuinely-empty snapshot so the section empty-states
    // render — never a stuck skeleton, never synthetic data.
    final AsyncValue<DiscoverSnapshot> resolved = snap.when(
      data: (d) => AsyncValue.data(d ?? _emptySnapshot()),
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
    );

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          RefreshIndicator(
        color: accent,
        onRefresh: () async {
          ref.invalidate(discoverSnapshotProvider);
          _lastFetchedAt = DateTime.now();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header row. Since the 2026-06 redesign this screen is PUSHED
            // (from You › Stats & Rewards or /leaderboard deep links), not a
            // bottom-nav tab — so it needs a visible back button + title.
            // When a silent refetch is in-flight, a tiny progress dot appears
            // top-right so the user knows data is updating.
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded,
                              color: textColor, size: 22),
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).bottomNavLeaderboard.toUpperCase(),
                        style: ZType.disp(20, color: textColor, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      if (isReloading)
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                      // F12/F13 — Share my Zealova Score (composite + percentile).
                      IconButton(
                        icon: Icon(Icons.ios_share_rounded,
                            color: textColor, size: 20),
                        tooltip: 'Share my Score',
                        onPressed: _shareMyScore,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Board switcher — top segmented control (chrome
                  // consolidation Variant A, 2026-06). Replaces the floating
                  // Liquid Glass bar that used to stack above the MainShell
                  // nav. Keeps the discover_v1 step-3 tour anchor.
                  KeyedSubtree(
                    key: TooltipAnchors.discoverBoardTabs,
                    child: Builder(builder: (context) {
                      final board = ref.watch(discoverBoardProvider);
                      final selectedIndex = DiscoverScreen._boardOptions
                          .indexWhere((opt) => opt.$1 == board);
                      return TopSegmentedControl(
                        accentColor: accent,
                        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                        onSelected: (i) {
                          ref.read(discoverBoardProvider.notifier).state =
                              DiscoverScreen._boardOptions[i].$1;
                        },
                        items: [
                          for (final opt in DiscoverScreen._boardOptions)
                            TopSegmentItem(
                              label: opt.$2,
                              icon: switch (opt.$1) {
                                'xp' => Icons.bolt_outlined,
                                'volume' => Icons.fitness_center_outlined,
                                'streaks' =>
                                  Icons.local_fire_department_outlined,
                                _ => Icons.tune_rounded,
                              },
                            ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Instant-load: cache-first render. On a true cold install
                  // (no disk snapshot ever) a layout-matched skeleton shows;
                  // every later open paints the cached snapshot immediately
                  // and revalidates silently — no blocking spinner.
                  CacheFirstView<DiscoverSnapshot>(
                    value: resolved,
                    isFirstEver: _isFirstEver,
                    traceLabel: 'discover_screen',
                    skeletonBuilder: (context) => _DiscoverSkeleton(
                      elevated: elevated,
                      border: border,
                    ),
                    contentBuilder: (context, s) {
                      // Mark seen after the first real content paints so
                      // future opens compute isFirstEver == false.
                      if (_isFirstEver) {
                        CacheFirstView.markSeen(_seenKey);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _isFirstEver) {
                            setState(() => _isFirstEver = false);
                          }
                        });
                      }
                      return _buildContent(
                        context, ref, s,
                        textColor: textColor,
                        textMuted: textMuted,
                        elevated: elevated,
                        border: border,
                        accent: accent,
                      );
                    },
                  ),
                  // Clear the floating MainShell nav (the board switcher
                  // moved to the top, so only one floating bar remains).
                  SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom +
                        kMainNavClearance +
                        16,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
          // Inline gym-finder map placeholder. Renders nothing until the
          // Google Maps API key is wired in pubspec + native plists.
          // const Positioned.fill(child: IgnorePointer(child: GymMapSection())),
          // First-run spotlight tour. Anchors and tip copy live in
          // `widgets/tooltips/tours/discover_tour.dart`. The overlay
          // uses `Positioned.fill` so the painter can dim the whole
          // screen and ring the highlighted target.
          //
          // Gated on `!_isFirstEver`: on a true cold install (exactly when
          // this first-run tour runs) `CacheFirstView` paints a skeleton,
          // and the step-1/2 anchors (`discoverRisingStars`,
          // `discoverNearYou`) live inside the real content. Mounting the
          // tour only after the skeleton is replaced means steps 1-2 get
          // a real spotlight on the first frame instead of a blank dim.
          if (!_isFirstEver) DiscoverTour.overlay(),
        ],
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
        // Top reset chip — replaces the old footer italic
        // "Resets Sun, May 31 · 11:59 PM" with a compact neutral chip.
        // Local-day-name reset is sufficient context; midnight precision
        // was over-specific.
        Align(
          alignment: Alignment.centerLeft,
          child: _ResetChip(
            label: _resetLabel(s.weekStart),
            textMuted: textMuted,
            border: border,
          ),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 18),
        // Single consolidated leaderboard list (was: Rising Stars strip
        // + Near You + Top 10 collapsible — three list-shaped views of
        // the same data). Rising Stars is now an annotation chip on
        // the rows that gained 5+ ranks this week (see `_NearYouList`).
        // Top 10 is accessible via the "View top 10" button rendered at
        // the bottom of the list (opens a sheet reusing the same row UI).
        //
        // Tour anchor wraps BOTH branches so the spotlight target
        // resolves whether or not the user is on the board yet. The
        // legacy `discoverRisingStars` anchor is reattached here as a
        // sibling so first-run tour step 1 still has a hit target post
        // consolidation.
        // Signature-v2 section kicker above the consolidated leaderboard
        // list (Barlow uppercase orange). Replaces the prior unlabeled list.
        if (s.nearYou.isNotEmpty) ...[
          const ZSectionKicker(label: 'Near you'),
          const SizedBox(height: 10),
        ],
        KeyedSubtree(
          key: TooltipAnchors.discoverRisingStars,
          child: KeyedSubtree(
            key: TooltipAnchors.discoverNearYou,
            child: s.nearYou.isEmpty
                ? _emptyState(
                    // Single dot separator — em/en dashes are banned by
                    // the redesign copy rules.
                    'No entries yet · Log a workout this week to climb',
                    textMuted: textMuted,
                    elevated: elevated,
                    border: border,
                  )
                : _NearYouList(
                    entries: s.nearYou,
                    top10: s.top10,
                    elevated: elevated,
                    border: border,
                    textColor: textColor,
                    textMuted: textMuted,
                    accent: accent,
                    metricLabel: s.metricLabel,
                  ),
          ),
        ),
      ],
    );
  }

  // (Surface 4 redesign removed `_sectionHeader` and `_filterPills` —
  // the consolidated list no longer renders intra-section headers, and
  // the segmented in-line filter was always shadowed by the floating
  // FloatingTabBar at the bottom. Both helpers and the now-orphaned
  // `_SegmentedTab` widget have been retired with the rest of the
  // duplicate-leaderboard surfaces.)

  Widget _emptyState(String message, {required Color textMuted, required Color elevated, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          message,
          style: ZType.sans(13, color: textMuted, weight: FontWeight.w500, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Top-of-screen reset chip label. Localizes the reset day name from the
  /// server-provided `week_start` (Monday) + 6 days, so users in non-English
  /// locales see e.g. "Resets domingo" / "Resets dimanche". When weekStart
  /// is empty (cold load), fall back to the literal "Sunday" — every active
  /// leaderboard resets on Sunday-local-time so the fallback is accurate.
  ///
  /// No specific timestamp ("11:59 PM" or otherwise) by design — the chip
  /// is informational, not operational, and the timestamp added visual
  /// noise to the old footer without giving the user any actionable info.
  String _resetLabel(String weekStart) {
    if (weekStart.isEmpty) return 'Resets Sunday';
    try {
      final monday = DateTime.parse(weekStart);
      final resetDate = monday.add(const Duration(days: 6));
      // E.g. "Sunday" / "domingo" / "dimanche" — pulled from current
      // locale's full weekday name via the EEEE pattern.
      final dayName = DateFormat('EEEE').format(resetDate);
      return 'Resets $dayName';
    } catch (_) {
      return 'Resets Sunday';
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

// ─── Hero rank card ─────────────────────────────────────────────────────────

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

    // XP-purple, independent of the user's accent selection. The "XP this
    // week" line is a category metric, not a primary action, so it stays
    // purple even when the user switches their accent to blue / green /
    // etc. (per the design-system color budget: accent reserved for primary
    // semantics; macro/XP categories keep their fixed hue).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpPurple =
        isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;

    // Neutral surface — drops the prior accent-tinted gradient + accent
    // border. Accent is now reserved for the rank number itself (one
    // focused use) so the hero card no longer competes with the user-row
    // highlight downstream.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section kicker above the rank, signature-v2.
          Text(
            'YOUR STANDING',
            style: ZType.lbl(11, color: accent, letterSpacing: 2.0),
          ),
          const SizedBox(height: 10),
          // Tier-persistence streak nudge — "Week 2 in Top 1% · 3 more for
          // Iron Throne". Only renders once the user has held a qualifying
          // tier at least one week. Copy adapts to whether a next milestone
          // exists. Lifted to the top of the card now that the TOP-% pill
          // is gone, so the card still leads with momentum context when it
          // exists; otherwise the rank line leads.
          if (s.yourTierStreakWeeks >= 1) ...[
            _TierStreakLine(
              weeks: s.yourTierStreakWeeks,
              tier: s.yourTier,
              nextMilestoneWeeks: s.yourNextMilestoneWeeks,
              nextMilestoneXp: s.yourNextMilestoneXp,
              accent: accent,
              textColor: textColor,
              textMuted: textMuted,
            ),
            const SizedBox(height: 10),
          ],
          // Three states:
          //  1. On board (hasRank)  → primary line = rank + delta arrow,
          //     accent only on the rank number. Secondary = "{n} XP this
          //     week" in XP-purple.
          //  2. Not on board, has weekly XP → soft prompt with unranked XP.
          //  3. Not on board, no weekly XP → complete-a-workout prompt.
          if (hasRank) ...[
            // Self-entry rankDelta lives on the user's `nearYou` row, not
            // on the snapshot root. Look it up here so we can render a
            // delta arrow next to the rank. null when the user just
            // joined the board this week (no prior rank to compare).
            Builder(builder: (_) {
              final selfMatches = s.nearYou.where((e) => e.isCurrentUser);
              final int? selfDelta = selfMatches.isEmpty
                  ? null
                  : selfMatches.first.rankDelta;
              return _PrimaryRankLine(
                rank: s.yourRank,
                totalActive: s.totalActive,
                rankDelta: selfDelta,
                accent: accent,
                textColor: textColor,
                textMuted: textMuted,
              );
            }),
            const SizedBox(height: 6),
            // Secondary metric — "{n} XP this week" / "{n} kg this week"
            // / "{n}-day streak". Always-on, uses XP-purple for visual
            // category separation from the accent-tinted rank.
            Text(
              '${s.yourMetric.toStringAsFixed(0)} ${s.metricLabel} this week',
              style: ZType.data(14, color: xpPurple),
            ),
          ] else ...[
            // Surface the user's own weekly progress even though they're
            // not on the board yet. Login streak + meal XP still count
            // — the board gate is "1 completed workout this week", not
            // "any weekly XP". Shows "You: 5 XP" so they feel seen.
            if (s.yourWeeklyXpUnranked > 0) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppLocalizations.of(context).discoverYou,
                    style: ZType.lbl(14, color: textMuted, letterSpacing: 1.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.yourWeeklyXpUnranked}',
                    style: ZType.disp(30, color: textColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).discoverXpThisWeek,
                    style: ZType.lbl(12, color: textMuted, letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).discoverCompleteAWorkoutTo,
                style: ZType.sans(13, color: textMuted, weight: FontWeight.w500, height: 1.35),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context).discoverCompleteAWorkoutThis,
                style: ZType.disp(20, color: textColor, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).discoverYourRankPercentileAppears,
                style: ZType.sans(13, color: textMuted, weight: FontWeight.w500, height: 1.35),
              ),
            ],
          ],
          if (s.nextTier != null && s.unitsToNext > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  '${s.unitsToNext} ${s.metricLabel} to Top ${_tierPercent(s.nextTier!)}',
                  style: ZType.lbl(12.5, color: accent, letterSpacing: 1.0),
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

// ─── Hero primary line: rank + delta arrow ──────────────────────────────────

/// Single primary metric line for the slimmed-down rank hero card.
///
/// Renders: `[#]{rank}  ▲ {delta}  of {totalActive}` — accent only on the
/// rank number itself, neutral elsewhere. Delta arrow is green for gains,
/// red for losses, omitted when null (new joiner with no prior rank).
///
/// Replaces the prior multi-line stack of: TOP-% pill + "#X of Y" muted
/// line + big {metric} {label} + "this week" subtitle. The metric line is
/// now a sibling beneath this widget, rendered by the caller in XP-purple.
class _PrimaryRankLine extends StatelessWidget {
  final int rank;
  final int totalActive;
  final int? rankDelta;
  final Color accent, textColor, textMuted;
  const _PrimaryRankLine({
    required this.rank,
    required this.totalActive,
    required this.rankDelta,
    required this.accent,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final delta = rankDelta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // The rank number is the ONE focused accent use on the hero card.
        Text(
          '#$rank',
          style: ZType.disp(40, color: accent, letterSpacing: 0),
        ),
        if (delta != null && delta != 0) ...[
          const SizedBox(width: 8),
          Icon(
            delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 18,
            color: delta > 0 ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 2),
          Text(
            '${delta.abs()}',
            style: ZType.data(15,
                color: delta > 0 ? Colors.green : Colors.redAccent),
          ),
        ],
        const SizedBox(width: 10),
        Text(
          'OF $totalActive',
          style: ZType.lbl(12, color: textMuted, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

// ─── Reset chip (top-of-screen "Resets Sunday") ─────────────────────────────

/// Small neutral chip rendered at the top of the Leaderboard tab. Replaces
/// the prior italic footer "Resets Sun, May 31 · 11:59 PM" with a less
/// prominent, non-italic, no-specific-timestamp affordance. Reset day is
/// computed once in `_resetLabel` and passed in via [label].
class _ResetChip extends StatelessWidget {
  final String label;
  final Color textMuted;
  final Color border;
  const _ResetChip({
    required this.label,
    required this.textMuted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.2),
      ),
    );
  }
}

// ─── Movers chip (row-level annotation) ─────────────────────────────────────

/// Inline "Movers" chip rendered on `_NearYouList` rows whose `rankDelta`
/// is at least +5 this week. Replaces the standalone Rising Stars strip
/// that used to live above the Near You list — the same information now
/// surfaces in-context on the row that earned it, dropping one section
/// entirely from the screen.
class _MoversChip extends StatelessWidget {
  final Color textMuted;
  const _MoversChip({required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textMuted.withValues(alpha: 0.35), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 10, color: Colors.green),
          const SizedBox(width: 3),
          Text(
            'MOVERS',
            style: ZType.lbl(9, color: textMuted, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}

// ─── View top 10 button + sheet ─────────────────────────────────────────────

/// Tappable footer button rendered at the bottom of `_NearYouList`. Opens
/// a glass sheet showing the snapshot's `top10` entries with the same row
/// chrome as the in-line list. Reuses `_Top10Collapsible` content in an
/// always-expanded form so the sheet has no chevron / collapse affordance.
class _ViewTop10Button extends ConsumerWidget {
  final List<DiscoverEntry> top10;
  final String metricLabel;
  final Color textColor, textMuted, border, elevated, accent;
  const _ViewTop10Button({
    required this.top10,
    required this.metricLabel,
    required this.textColor,
    required this.textMuted,
    required this.border,
    required this.elevated,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticService.light();
        _openTop10Sheet(context, ref);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'VIEW TOP 10',
              style: ZType.lbl(12.5, color: textColor, letterSpacing: 1.6),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  void _openTop10Sheet(BuildContext context, WidgetRef ref) {
    // Hide the floating nav while the sheet is up, matching `_openUserPeek`.
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet<void>(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.85,
        child: _Top10Sheet(
          entries: top10,
          metricLabel: metricLabel,
          textColor: textColor,
          textMuted: textMuted,
          border: border,
          accent: accent,
        ),
      ),
    ).whenComplete(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }
}

class _Top10Sheet extends ConsumerWidget {
  final List<DiscoverEntry> entries;
  final String metricLabel;
  final Color textColor, textMuted, border, accent;
  const _Top10Sheet({
    required this.entries,
    required this.metricLabel,
    required this.textColor,
    required this.textMuted,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context).discoverTopOfTheWeek.toUpperCase(),
                style: ZType.disp(20, color: textColor, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++) ...[
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () => _openUserPeek(
                context,
                userId: entries[i].userId,
                name: entries[i].bestName,
                username: entries[i].username,
                avatarUrl: entries[i].avatarUrl,
                rank: entries[i].rank,
                metricValue: entries[i].metricValue,
                metricLabel: metricLabel,
                ref: ref,
                level: entries[i].currentLevel,
              ),
              leading: SizedBox(
                width: 28,
                child: Text(
                  '#${entries[i].rank}',
                  style: ZType.data(13, color: textMuted),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      entries[i].isCurrentUser
                          ? AppLocalizations.of(context).navYou
                          : entries[i].bestName,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.sans(14, color: textColor, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _LevelPill(level: entries[i].currentLevel, accent: accent),
                ],
              ),
              trailing: Text(
                '${entries[i].metricValue.toStringAsFixed(0)} $metricLabel',
                style: ZType.data(13, color: textColor),
              ),
            ),
            if (i < entries.length - 1)
              Divider(height: 1, color: border),
          ],
        ],
      ),
    );
  }
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
        text: 'WEEK $weeks IN ${tierLabel.toUpperCase()}',
        style: ZType.lbl(11.5, color: textColor, letterSpacing: 1.2),
      ),
    ];

    if (nextMilestoneWeeks != null) {
      final remaining = nextMilestoneWeeks! - weeks;
      parts.addAll([
        TextSpan(
          text: '  ·  ',
          style: ZType.lbl(11.5, color: textMuted, letterSpacing: 1.2),
        ),
        TextSpan(
          text: '$remaining MORE FOR ${_badgeIconForWeeks(nextMilestoneWeeks!).toUpperCase()}',
          style: ZType.lbl(11.5, color: accent, letterSpacing: 1.0),
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

// (Surface 4 redesign removed the lifetime XP sub-row from the hero card —
// it duplicated the XP Goals screen and bloated the hero vertically. The
// `_LifetimeBadge` widget and its `_formatXp` helper were retired with it.)

/// Compact "Lvl N" chip used on every leaderboard row.
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
        'LVL $level',
        style: ZType.lbl(9.5, color: accent, letterSpacing: 0.8),
      ),
    );
  }
}

// (Surface 4 redesign retired the standalone `_RisingStarsStrip`. The
// movers signal now renders as an inline `_MoversChip` on `_NearYouList`
// rows whose `rankDelta >= 5`, so the same information surfaces in
// context on the row that earned it without claiming its own section.)

// ─── Near You ────────────────────────────────────────────────────────────────

class _NearYouList extends ConsumerWidget {
  final List<DiscoverEntry> entries;
  /// Top-10 entries from the same snapshot. Used by the "View top 10"
  /// button at the bottom of the list to open a peek sheet — replaces
  /// the standalone collapsible Top 10 section that used to live below
  /// this list. Empty list ⇒ button is hidden.
  final List<DiscoverEntry> top10;
  final Color elevated, border, textColor, textMuted, accent;
  final String metricLabel;
  const _NearYouList({
    required this.entries,
    required this.top10,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                Builder(builder: (ctx) => _row(ctx, ref, entries[i])),
                if (i < entries.length - 1) ...[
                  // GapChip placement: only on the divider directly above OR
                  // directly below the current-user row. Shows "+42 XP" above
                  // (distance to catch them) or "-31 XP" below.
                  if (meIdx != -1 && (i == meIdx - 1 || i == meIdx)) ...[
                    Divider(height: 1, color: border),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: GapChip(
                        delta: i == meIdx - 1
                            ? entries[i].metricValue - entries[meIdx].metricValue
                            : entries[meIdx].metricValue -
                                entries[i + 1].metricValue,
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
        ),
        if (top10.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ViewTop10Button(
            top10: top10,
            metricLabel: metricLabel,
            textColor: textColor,
            textMuted: textMuted,
            border: border,
            elevated: elevated,
            accent: accent,
          ),
        ],
      ],
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
            style: ZType.data(13,
                color: e.isCurrentUser ? accent : textMuted,
                weight: e.isCurrentUser ? FontWeight.w700 : FontWeight.w400),
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
                  e.isCurrentUser ? AppLocalizations.of(context).navYou : e.bestName,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.sans(13.5,
                      color: textColor,
                      weight: e.isCurrentUser ? FontWeight.w800 : FontWeight.w600),
                ),
              ),
              if (hideIdentity) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock_outline, size: 12, color: textMuted),
                const SizedBox(width: 2),
                Text(
                  AppLocalizations.of(context).manageDuplicateImportsHidden.toUpperCase(),
                  style: ZType.lbl(9.5, color: textMuted, letterSpacing: 1.0),
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
              // Movers annotation — surfaces "this week's biggest movers"
              // in-line on the row that earned it (replaces the standalone
              // Rising Stars strip that used to live above this list).
              // Threshold = +5 ranks gained this week. Hidden on compact
              // widths to preserve the name's truncation budget.
              if (!compact &&
                  e.rankDelta != null &&
                  e.rankDelta! >= 5) ...[
                const SizedBox(width: 6),
                _MoversChip(textMuted: textMuted),
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
            child: Text(
              'YOU',
              style: ZType.lbl(9, color: Colors.white, letterSpacing: 0.8),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(
          '${e.metricValue.toStringAsFixed(0)} $metricLabel',
          style: ZType.data(12, color: textColor),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.border),
      ),
      clipBehavior: Clip.antiAlias,
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
                      AppLocalizations.of(context).discoverTopOfTheWeek.toUpperCase(),
                      style: ZType.lbl(13, color: widget.textColor, letterSpacing: 1.6),
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
                      style: ZType.data(13, color: widget.textMuted)),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.entries[i].isCurrentUser ? AppLocalizations.of(context).navYou : widget.entries[i].bestName,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.sans(14, color: widget.textColor, weight: FontWeight.w600),
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
                  style: ZType.data(13, color: widget.textColor),
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
            textAlign: TextAlign.center,
            style: name == 'Anonymous athlete'
                ? ZType.sans(20, color: textColor, weight: FontWeight.w600)
                : ZType.disp(24, color: textColor, letterSpacing: 0.5),
          ),
          if (username != null && username!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('@$username',
                style: ZType.data(12.5, color: textMuted, weight: FontWeight.w400)),
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
        style: ZType.ser(14, color: textMuted, height: 1.3),
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
        style: ZType.sans(13, color: textMuted, weight: FontWeight.w500, height: 1.4),
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
        style: ZType.data(13, color: textColor.withValues(alpha: 0.5)));
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
            Text('LVL $level', style: ZType.lbl(13, color: accent, letterSpacing: 1.0)),
            sep,
          ],
          Text('#$rank', style: ZType.data(15, color: accent)),
          sep,
          Text('${metricValue.toStringAsFixed(0)} $metricLabel',
              style: ZType.data(13, color: textColor)),
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
  FitnessHistoryRange _range = FitnessHistoryRange.oneDay;

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

    // Target = "Them" (the tapped user). Viewer = "You". We pin two
    // perceptually-distant hues regardless of the user's accent setting —
    // earlier the target reused `widget.accent`, which collapsed to the
    // same blue/cyan as the viewer when the user kept the default accent
    // and made the two shapes indistinguishable.
    //   AppColors.magenta = Them
    //   AppColors.cyan    = You
    const targetColor = AppColors.magenta;
    const viewerColor = AppColors.cyan;

    // Detect "no shape yet" case — every axis below 5% of full. Without
    // this guard fl_chart still draws a tiny regular hexagon at the
    // origin which users keep mistaking for a real shape (perfect hex
    // even though their stats clearly differ across axes).
    final targetIsFlat = target.every((v) => v < 0.05);

    // Pin the radar scale to a fixed maximum so the "You" shape stays the
    // same size regardless of which datasets are visible. fl_chart auto-
    // scales to the largest value across all rendered datasets — when the
    // target dataset is dropped (targetIsFlat) or the viewer overlay is
    // hidden (isSelfPeek), the remaining shape rescales and visibly
    // changes size between expanded/condensed views. Adding a transparent
    // anchor dataset at the global maximum keeps the scale stable.
    final double radarAnchorMax = [
      ...target,
      ...viewer,
      100.0, // floor so partial-data users still render at sensible scale
    ].reduce((a, b) => a > b ? a : b);

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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        tickCount: 4,
                        ticksTextStyle: const TextStyle(
                          color: Colors.transparent, fontSize: 1,
                        ),
                        // De-emphasise the grid so the data shapes pop —
                        // the bright background hex was being mistaken for
                        // a real "all axes equal" shape.
                        gridBorderData: BorderSide(
                          color: widget.border.withValues(alpha: 0.35),
                          width: 0.6,
                        ),
                        radarBorderData: BorderSide(
                          color: widget.border.withValues(alpha: 0.55),
                          width: 0.7,
                        ),
                        tickBorderData: BorderSide(
                          color: widget.border.withValues(alpha: 0.25),
                          width: 0.4,
                        ),
                        titleTextStyle: ZType.lbl(
                          compactLabels ? 10 : 11,
                          color: widget.textMuted,
                          letterSpacing: 0.8,
                        ),
                        titlePositionPercentageOffset: 0.12,
                        getTitle: (index, angle) =>
                            RadarChartTitle(text: labels[index], angle: 0),
                        dataSets: [
                          // Hidden anchor — pins the radar's max-scale so the
                          // "You" / "Them" shapes don't rescale between
                          // expanded and condensed views (Issue 9).
                          RadarDataSet(
                            fillColor: Colors.transparent,
                            borderColor: Colors.transparent,
                            borderWidth: 0,
                            entryRadius: 0,
                            dataEntries: List.generate(
                              labels.length,
                              (_) => RadarEntry(value: radarAnchorMax),
                            ),
                          ),
                          // Target ("Them") — magenta, drawn first so the
                          // viewer overlay sits on top.
                          if (!targetIsFlat)
                            RadarDataSet(
                              fillColor: targetColor.withValues(alpha: 0.45),
                              borderColor: targetColor,
                              borderWidth: 2.5,
                              entryRadius: 3,
                              dataEntries: target
                                  .map((v) => RadarEntry(value: v))
                                  .toList(),
                            )
                          else
                            // Need at least one dataset for fl_chart to render
                            // the grid; use an invisible zero-radius polygon.
                            RadarDataSet(
                              fillColor: Colors.transparent,
                              borderColor: Colors.transparent,
                              borderWidth: 0,
                              entryRadius: 0,
                              dataEntries: target
                                  .map((_) => const RadarEntry(value: 0))
                                  .toList(),
                            ),
                          // Viewer ("You") — cyan overlay, slightly thicker
                          // border so the foreground reads on top of the
                          // magenta fill.
                          if (showViewerOverlay)
                            RadarDataSet(
                              fillColor: viewerColor.withValues(alpha: 0.35),
                              borderColor: viewerColor,
                              borderWidth: 2.5,
                              entryRadius: 3,
                              dataEntries: viewer
                                  .map((v) => RadarEntry(value: v))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    if (targetIsFlat)
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                size: 32,
                                color: widget.textMuted.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context).habitDetailScreenNotEnoughDataYet,
                                textAlign: TextAlign.center,
                                style: ZType.sans(15, color: widget.textColor, weight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).discoverComplete3WorkoutsTo,
                                textAlign: TextAlign.center,
                                style: ZType.sans(12, color: widget.textMuted, weight: FontWeight.w500, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
              _LegendDot(color: targetColor, label: AppLocalizations.of(context).discoverThem, textColor: widget.textMuted),
              if (showViewerOverlay) ...[
                const SizedBox(width: 16),
                _LegendDot(color: viewerColor, label: AppLocalizations.of(context).navYou, textColor: widget.textMuted),
              ],
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context).discoverTapAnAxis,
                style: ZType.sans(11, color: widget.textMuted.withValues(alpha: 0.7), weight: FontWeight.w500),
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
                    style: ZType.lbl(15, color: textColor, letterSpacing: 3),
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
              style: ZType.data(10, color: textMuted, weight: FontWeight.w400),
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
  return showGlassSheet<DateTime>(
    context: context,
    builder: (ctx) => GlassSheet(
      child: _MonthYearPickerSheet(
        initial: initial,
        earliest: earliest,
        latest: latest,
        accent: accent,
      ),
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
                style: ZType.data(18, color: textColor),
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
                      style: ZType.lbl(13,
                          color: isSelected ? widget.accent : textColor,
                          letterSpacing: 1.0),
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
        Text(label.toUpperCase(), style: ZType.lbl(11, color: textColor, letterSpacing: 1.0)),
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
            style: ZType.disp(fontSize, color: accent)),
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
            style: ZType.lbl(10, color: textMuted, letterSpacing: 1.4),
          ),
          const SizedBox(width: 14),
          _dot(targetColor),
          const SizedBox(width: 4),
          Text(_pct(targetValue), style: ZType.data(13, color: textColor)),
          if (viewerValue != null) ...[
            const SizedBox(width: 12),
            _dot(viewerColor),
            const SizedBox(width: 4),
            Text(_pct(viewerValue!), style: ZType.data(13, color: textColor)),
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
    // Wrap (not Row): all 9 range chips don't fit one line on narrow phones —
    // a Row with spaceEvenly overflowed 44px because it never shrinks children.
    // Wrap flows the extras onto a second line so every range stays visible.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
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
          r.label.toUpperCase(),
          style: ZType.lbl(12,
              color: isSelected ? accent : textMuted, letterSpacing: 1.0),
        ),
      ),
    );
  }
}

// ─── Instant-load skeleton ──────────────────────────────────────────────────

/// Layout-matched loading placeholder for [DiscoverScreen].
///
/// Shown ONLY on a true cold-install first open (see `CacheFirstView`); every
/// later open paints the cached snapshot instantly. The shape mirrors
/// `_buildContent` — hero rank card, a Rising Stars header + horizontal strip,
/// a Near You section header, and a short list of leaderboard rows — so the
/// skeleton → content cross-fade does not reflow the layout.
///
/// Uses the shared skeleton primitives (theme-aware light + dark for free) and
/// is built as a non-scrolling Column so it drops straight into the existing
/// `SliverChildListDelegate`. Verified overflow-free on iPhone SE width.
class _DiscoverSkeleton extends StatelessWidget {
  final Color elevated;
  final Color border;

  const _DiscoverSkeleton({
    required this.elevated,
    required this.border,
  });

  /// One placeholder leaderboard row: rank chip + avatar + name/metric lines.
  Widget _row() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: const [
          SkeletonBox(width: 26, height: 26, radius: 8),
          SizedBox(width: 12),
          SkeletonCircle(size: 40),
          SizedBox(width: 12),
          Expanded(child: SkeletonText(lines: 2, lastLineFraction: 0.45)),
          SizedBox(width: 12),
          SkeletonBox(width: 48, height: 14),
        ],
      ),
    );
  }

  /// One section header placeholder: a title line + a shorter subtitle line.
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 150, height: 14),
        SizedBox(height: 6),
        SkeletonBox(width: 200, height: 11),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero rank card — tall rounded surface matching _RankHeroCard.
        Container(
          height: 188,
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 120, height: 13),
              SizedBox(height: 16),
              SkeletonBox(width: 160, height: 30),
              SizedBox(height: 14),
              SkeletonBox(width: double.infinity, height: 10, radius: 5),
              SizedBox(height: 18),
              SkeletonText(lines: 2, lastLineFraction: 0.7),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Rising Stars header + horizontal strip of star tiles.
        _header(),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 104,
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: const [
                  SkeletonCircle(size: 48),
                  SizedBox(height: 10),
                  SkeletonBox(width: 64, height: 11),
                  SizedBox(height: 6),
                  SkeletonBox(width: 40, height: 10),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Near You section header + leaderboard rows.
        _header(),
        const SizedBox(height: 10),
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _row(),
        ],
      ],
    );
  }
}
