import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../models/feature_request.dart';
import '../../data/providers/feature_provider.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'widgets/suggest_feature_sheet.dart';
import 'widgets/feature_detail_sheet.dart';

import '../../l10n/generated/app_localizations.dart';

/// Feature-request board — submit, vote, filter, sort, search and discuss
/// upcoming features. Follows the app's signature theme (pill app bar,
/// segmented tabs, accent color, glass sheets).
class FeatureVotingScreen extends ConsumerStatefulWidget {
  const FeatureVotingScreen({super.key});

  @override
  ConsumerState<FeatureVotingScreen> createState() =>
      _FeatureVotingScreenState();
}

class _FeatureVotingScreenState extends ConsumerState<FeatureVotingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;
  Timer? _searchDebounce;
  final _searchController = TextEditingController();

  // Local mirror of the active filters (source of truth lives on the notifier).
  String _sort = 'trending';
  String? _category;

  static const List<({String value, String label})> _sorts = [
    (value: 'trending', label: 'Trending'),
    (value: 'top', label: 'Top voted'),
    (value: 'new', label: 'Newest'),
  ];

  static const List<({String? value, String label})> _categories = [
    (value: null, label: 'All'),
    (value: 'workout', label: 'Workout'),
    (value: 'nutrition', label: 'Nutrition'),
    (value: 'coaching', label: 'Coaching'),
    (value: 'social', label: 'Social'),
    (value: 'analytics', label: 'Analytics'),
    (value: 'integration', label: 'Integrations'),
    (value: 'ui_ux', label: 'UI / UX'),
    (value: 'other', label: 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Re-paint countdown timers once a second while any are visible.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(featuresProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final featuresAsync = ref.watch(featuresProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColorsLight.background,
      appBar: PillAppBar(
        title: 'Feature Requests',
        actions: [
          PillAppBarAction(
            icon: Icons.add_rounded,
            onTap: () => _showSuggestFeatureSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(isDark, accent),
          _buildFilterRow(isDark, accent),
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: [
              SegmentedTabItem(
                  label: AppLocalizations.of(context).featureVotingVoting),
              SegmentedTabItem(
                  label: AppLocalizations.of(context).featureVotingPlanned),
              SegmentedTabItem(
                  label: AppLocalizations.of(context).featureVotingInProgress),
              SegmentedTabItem(
                  label: AppLocalizations.of(context).featureVotingReleased),
            ],
          ),
          Expanded(
            child: featuresAsync.when(
              loading: () => _buildSkeletonList(isDark),
              error: (error, _) => _buildError(isDark, accent),
              data: (features) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeatureList(
                        features.where((f) => f.isVoting).toList(), isDark, accent),
                    _buildFeatureList(
                        features.where((f) => f.isPlanned).toList(), isDark, accent),
                    _buildFeatureList(
                        features.where((f) => f.inProgress).toList(), isDark, accent),
                    _buildFeatureList(
                        features.where((f) => f.isReleased).toList(), isDark, accent),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────

  Widget _buildSearchField(bool isDark, Color accent) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 15, color: textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search feature requests',
            hintStyle: TextStyle(fontSize: 15, color: textMuted),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: textMuted),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                    onPressed: () {
                      _searchController.clear();
                      _searchDebounce?.cancel();
                      ref.read(featuresProvider.notifier).setSearch('');
                      setState(() {});
                    },
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildSortButton(isDark, accent),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 22,
            color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: _categories.map((c) {
                  final selected = c.value == _category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _FilterChipPill(
                      label: c.label,
                      selected: selected,
                      accent: accent,
                      isDark: isDark,
                      onTap: () {
                        HapticService.light();
                        setState(() => _category = c.value);
                        ref.read(featuresProvider.notifier).setCategory(c.value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSortButton(bool isDark, Color accent) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final currentLabel =
        _sorts.firstWhere((s) => s.value == _sort).label;

    return PopupMenuButton<String>(
      initialValue: _sort,
      onSelected: (value) {
        HapticService.light();
        setState(() => _sort = value);
        ref.read(featuresProvider.notifier).setSort(value);
      },
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => _sorts
          .map((s) => PopupMenuItem<String>(
                value: s.value,
                child: Row(
                  children: [
                    Icon(
                      _sort == s.value
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: _sort == s.value ? accent : textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(s.label),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lists ─────────────────────────────────────────────────────────────

  Widget _buildFeatureList(
      List<FeatureRequest> features, bool isDark, Color accent) {
    if (features.isEmpty) return _buildEmpty(isDark);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: features.length,
      itemBuilder: (context, index) =>
          _buildFeatureCard(features[index], isDark, accent),
    );
  }

  Widget _buildFeatureCard(
      FeatureRequest feature, bool isDark, Color accent) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final voted = feature.userHasVoted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetail(feature),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vote pill (accent when voted)
                _VoteButton(
                  voteCount: feature.voteCount,
                  voted: voted,
                  accent: accent,
                  isDark: isDark,
                  onTap: () {
                    HapticService.light();
                    _handleVote(feature.id);
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feature.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _CategoryBadge(
                            label: feature.categoryDisplayName,
                            accent: accent,
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.mode_comment_outlined,
                              size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${feature.commentCount}',
                            style: TextStyle(fontSize: 12.5, color: textMuted),
                          ),
                          const Spacer(),
                          if (feature.releaseDate != null)
                            _Countdown(label: feature.formattedCountdown)
                          else
                            _StatusBadge(
                              label: feature.statusDisplayName,
                              status: feature.status,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────

  Widget _buildSkeletonList(bool isDark) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        height: 104,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final hasFilter =
        _searchController.text.isNotEmpty || _category != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Nothing here for that filter yet.'
                  : 'No requests here yet — be the first to suggest one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, Color accent) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              "Couldn't load feature requests.",
              style: TextStyle(fontSize: 15, color: textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () => ref.read(featuresProvider.notifier).refresh(),
              child: Text(AppLocalizations.of(context).buttonRetry),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────

  void _handleVote(String featureId) {
    ref.read(featuresProvider.notifier).toggleVote(featureId);
  }

  void _showDetail(FeatureRequest feature) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => FeatureDetailSheet(featureId: feature.id),
    );
  }

  void _showSuggestFeatureSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const GlassSheet(
        child: SuggestFeatureSheet(),
      ),
    );
  }
}

// ── Reusable card pieces ──────────────────────────────────────────────────

class _VoteButton extends StatelessWidget {
  final int voteCount;
  final bool voted;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _VoteButton({
    required this.voteCount,
    required this.voted,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final idleBg = isDark ? AppColors.surface : AppColorsLight.surface;
    final idleBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final idleFg = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final onAccent = accent.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: voted ? accent : idleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: voted ? accent : idleBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 22,
              color: voted ? onAccent : idleFg,
            ),
            Text(
              '$voteCount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: voted ? onAccent : idleFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _CategoryBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String status;
  final bool isDark;

  const _StatusBadge({
    required this.label,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Status uses semantic tones (not the user accent) so lifecycle reads
    // consistently regardless of the chosen accent.
    Color color;
    switch (status) {
      case 'planned':
        color = isDark ? AppColors.warning : AppColorsLight.warning;
        break;
      case 'in_progress':
        color = isDark ? AppColors.info : AppColorsLight.info;
        break;
      case 'released':
        color = isDark ? AppColors.success : AppColorsLight.success;
        break;
      default:
        color = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  final String label;
  const _Countdown({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.success : AppColorsLight.success;
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final idleBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final idleBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final idleFg = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final onAccent =
        accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : idleBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : idleBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? onAccent : idleFg,
          ),
        ),
      ),
    );
  }
}
