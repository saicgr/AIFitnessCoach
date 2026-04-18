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
import '../../data/providers/discover_provider.dart';
import '../../data/providers/fitness_profile_provider.dart';
import '../../data/providers/fitness_shape_history_provider.dart';
import '../../data/services/haptic_service.dart';

/// Workstream 2 — Discover tab.
///
/// Research-backed layout (Yu-kai Chou octalysis + Growth Engineering):
/// percentile hero → Rising Stars → Near You → collapsible Top 10.
/// Flat global leaderboards demotivate 95% of users — this structure
/// avoids that trap by making everyone visible and improving.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static const _boardOptions = [
    ('xp', 'XP This Week'),
    ('volume', 'Volume'),
    ('streaks', 'Streaks'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            SliverAppBar(
              toolbarHeight: 60,
              pinned: true,
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: Row(
                children: [
                  Icon(Icons.public, size: 26, color: accent),
                  const SizedBox(width: 10),
                  Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (isReloading) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RankHeroCard(
          snapshot: s,
          textColor: textColor,
          textMuted: textMuted,
          elevated: elevated,
          border: border,
          accent: accent,
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
        _sectionHeader('👀 Near You', s.nearYou.isEmpty ? 'Log a workout this week to appear' : 'Your neighborhood on the board', textColor: textColor, textMuted: textMuted),
        const SizedBox(height: 10),
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
            'Resets Sunday 11:59pm',
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
          for (final opt in _boardOptions)
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

class _RankHeroCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final s = snapshot;
    final hasRank = s.yourRank > 0;
    final percentileText = s.yourPercentile > 0
        ? 'TOP ${(100 - s.yourPercentile).clamp(1, 99).toStringAsFixed(0)}%'
        : 'JOIN THE BOARD';

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
          const SizedBox(height: 12),
          if (s.yourMetric > 0) ...[
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

// ─── Rising Stars strip ─────────────────────────────────────────────────────

class _RisingStarsStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                _Avatar(url: star.avatarUrl, fallback: star.bestName, radius: 20, accent: accent),
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

class _NearYouList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            Builder(builder: (ctx) => _row(ctx, entries[i])),
            if (i < entries.length - 1) Divider(height: 1, color: border),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, DiscoverEntry e) {
    final bg = e.isCurrentUser ? accent.withValues(alpha: 0.14) : Colors.transparent;
    return Material(
      color: bg,
      child: InkWell(
        onTap: e.isCurrentUser
            ? null
            : () => _openUserPeek(
                  context,
                  userId: e.userId,
                  name: e.bestName,
                  username: e.username,
                  avatarUrl: e.avatarUrl,
                  rank: e.rank,
                  metricValue: e.metricValue,
                  metricLabel: metricLabel,
                ),
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${e.rank}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: e.isCurrentUser ? FontWeight.w900 : FontWeight.w600,
                color: e.isCurrentUser ? accent : textMuted,
              ),
            ),
          ),
          _Avatar(url: e.avatarUrl, fallback: e.bestName, radius: 16, accent: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    e.isCurrentUser ? 'You' : e.bestName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: e.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (e.isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
              ],
            ),
          ),
          Text(
            '${e.metricValue.toStringAsFixed(0)} $metricLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ─── Top 10 collapsible ─────────────────────────────────────────────────────

class _Top10Collapsible extends StatefulWidget {
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
  State<_Top10Collapsible> createState() => _Top10CollapsibleState();
}

class _Top10CollapsibleState extends State<_Top10Collapsible> {
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
                onTap: widget.entries[i].isCurrentUser
                    ? null
                    : () => _openUserPeek(
                          context,
                          userId: widget.entries[i].userId,
                          name: widget.entries[i].bestName,
                          username: widget.entries[i].username,
                          avatarUrl: widget.entries[i].avatarUrl,
                          rank: widget.entries[i].rank,
                          metricValue: widget.entries[i].metricValue,
                          metricLabel: widget.metricLabel,
                        ),
                leading: SizedBox(
                  width: 28,
                  child: Text('#${widget.entries[i].rank}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: widget.textMuted)),
                ),
                title: Text(
                  widget.entries[i].isCurrentUser ? 'You' : widget.entries[i].bestName,
                  style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600),
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
}) {
  if (name.trim().isEmpty) return;
  HapticService.light();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _UserPeekSheet(
      userId: userId,
      name: name,
      username: username,
      avatarUrl: avatarUrl,
      rank: rank,
      metricValue: metricValue,
      metricLabel: metricLabel,
    ),
  );
}

class _UserPeekSheet extends ConsumerWidget {
  final String userId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final int rank;
  final double metricValue;
  final String metricLabel;
  const _UserPeekSheet({
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.rank,
    required this.metricValue,
    required this.metricLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    final profileAsync = ref.watch(fitnessProfileProvider(userId));

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
          const SizedBox(height: 20),
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
          // Compact rank + metric pill
          _RankPill(
            rank: rank,
            metricValue: metricValue,
            metricLabel: metricLabel,
            accent: accent,
            textColor: textColor,
            border: border,
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
  const _RankPill({
    required this.rank,
    required this.metricValue,
    required this.metricLabel,
    required this.accent,
    required this.textColor,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
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
          Text('#$rank',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: accent,
              )),
          Text('  ·  ', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
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
    final historyData = history.valueOrNull;
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
    final showViewerOverlay = viewer.any((v) => v > 0.01);
    final targetColor = widget.textMuted;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle:
                  const TextStyle(color: Colors.transparent, fontSize: 1),
              gridBorderData: BorderSide(color: widget.border, width: 0.8),
              radarBorderData: BorderSide(color: widget.border, width: 0.8),
              tickBorderData: BorderSide(color: widget.border, width: 0.5),
              titleTextStyle: TextStyle(
                color: widget.textMuted,
                fontSize: compactLabels ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
              titlePositionPercentageOffset: 0.12,
              getTitle: (index, angle) =>
                  RadarChartTitle(text: labels[index], angle: 0),
              dataSets: [
                RadarDataSet(
                  fillColor: targetColor.withValues(alpha: 0.30),
                  borderColor: targetColor,
                  borderWidth: 1.5,
                  entryRadius: 0,
                  dataEntries:
                      target.map((v) => RadarEntry(value: v)).toList(),
                ),
                if (showViewerOverlay)
                  RadarDataSet(
                    fillColor: widget.accent.withValues(alpha: 0.45),
                    borderColor: widget.accent,
                    borderWidth: 1.5,
                    entryRadius: 0,
                    dataEntries:
                        viewer.map((v) => RadarEntry(value: v)).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (showViewerOverlay)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: targetColor, label: 'Them', textColor: widget.textMuted),
              const SizedBox(width: 16),
              _LegendDot(color: widget.accent, label: 'You', textColor: widget.textMuted),
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
