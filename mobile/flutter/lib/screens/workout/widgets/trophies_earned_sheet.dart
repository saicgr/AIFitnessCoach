import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/cardio_pr.dart';
import '../../../widgets/glass_sheet.dart';
import '../../cardio/cardio_pr_history_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Shows a bottom sheet displaying trophies and achievements earned from the workout.
///
/// `cardioPrs` is purely additive — if non-null and non-empty, a new
/// "Cardio Achievements" section appears beneath the strength PR section.
/// First-time activity items render with a "First time!" orange badge
/// instead of the standard ALL-TIME ribbon.
Future<void> showTrophiesEarnedSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> newPRs,
  required Map<String, dynamic>? achievements,
  required int totalWorkouts,
  required int? currentStreak,
  List<CardioPersonalRecord>? cardioPrs,
}) async {
  HapticFeedback.mediumImpact();

  return showGlassSheet<void>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _TrophiesEarnedSheet(
        newPRs: newPRs,
        achievements: achievements,
        totalWorkouts: totalWorkouts,
        currentStreak: currentStreak,
        cardioPrs: cardioPrs,
      ),
    ),
  );
}

class _TrophiesEarnedSheet extends ConsumerWidget {
  final List<Map<String, dynamic>> newPRs;
  final Map<String, dynamic>? achievements;
  final int totalWorkouts;
  final int? currentStreak;
  final List<CardioPersonalRecord>? cardioPrs;

  const _TrophiesEarnedSheet({
    required this.newPRs,
    required this.achievements,
    required this.totalWorkouts,
    required this.currentStreak,
    this.cardioPrs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // PR weights are stored in kg; render in the user's WORKOUT weight unit.
    final useKg = ref.watch(useKgForWorkoutProvider);
    final l = AppLocalizations.of(context)!;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get new achievements from the achievements map
    final newAchievements = (achievements?['new_achievements'] as List<dynamic>?)
        ?.map((a) => Map<String, dynamic>.from(a as Map))
        .toList() ?? [];

    return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.orange, AppColors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.trophiesEarnedTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            l.trophiesEarnedSessionHighlights,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gravl-parity hero badge carousel — every earned item
                      // (PR, cardio PR, achievement) as a horizontally-
                      // scrolling medallion. Renders only when something was
                      // earned this session.
                      _buildBadgeCarousel(
                        context,
                        newPRs: newPRs,
                        cardioPrs: cardioPrs,
                        newAchievements: newAchievements,
                        useKg: useKg,
                      ),

                      // Personal Records Section
                      if (newPRs.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.trending_up_rounded,
                          title: l.trophiesEarnedPersonalRecords,
                          subtitle: l.trophiesEarnedNewPRs(newPRs.length),
                          color: AppColors.orange,
                        ),
                        const SizedBox(height: 12),
                        ...newPRs.asMap().entries.map((entry) {
                          final pr = entry.value;
                          final index = entry.key;
                          return _buildPRCard(context, pr, elevated, cardBorder, useKg)
                              .animate(delay: Duration(milliseconds: 150 + (index * 50)))
                              .fadeIn()
                              .slideX(begin: 0.1);
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Cardio Achievements Section (additive — only renders
                      // when the caller passes a non-empty list)
                      if (cardioPrs != null && cardioPrs!.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.directions_run_rounded,
                          title: l.trophiesEarnedCardioAchievements,
                          subtitle: l.trophiesEarnedNewCardioPRs(cardioPrs!.length),
                          color: AppColors.cyan,
                        ),
                        const SizedBox(height: 12),
                        ...cardioPrs!.asMap().entries.map((entry) {
                          final pr = entry.value;
                          final index = entry.key;
                          return _buildCardioPrCard(context, pr, elevated, cardBorder)
                              .animate(delay: Duration(milliseconds: 175 + (index * 50)))
                              .fadeIn()
                              .slideX(begin: 0.1);
                        }),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () {
                              // Capture a root navigator BEFORE popping so
                              // we can route the next sheet via the same
                              // context-independent navigator state. Avoids
                              // the use_build_context_synchronously warning
                              // and is safer than relying on the popped
                              // sheet's BuildContext after the frame ends.
                              final navState = Navigator.of(context, rootNavigator: true);
                              final ctx = navState.context;
                              navState.maybePop();
                              Future.microtask(() {
                                showCardioPrHistorySheet(ctx);
                              });
                            },
                            icon: Icon(Icons.timeline_rounded,
                                size: 18, color: AppColors.cyan),
                            label: Text(
                              l.trophiesEarnedViewAllCardioPRs,
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // New Achievements Section
                      if (newAchievements.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.military_tech_rounded,
                          title: l.trophiesEarnedAchievementsUnlocked,
                          subtitle: l.trophiesEarnedNewBadges(newAchievements.length),
                          color: AppColors.purple,
                        ),
                        const SizedBox(height: 12),
                        ...newAchievements.asMap().entries.map((entry) {
                          final achievement = entry.value;
                          final index = entry.key;
                          return _buildAchievementCard(context, achievement, elevated, cardBorder)
                              .animate(delay: Duration(milliseconds: 200 + (index * 50)))
                              .fadeIn()
                              .slideX(begin: 0.1);
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Milestones Section
                      _buildSectionHeader(
                        context,
                        icon: Icons.flag_rounded,
                        title: l.trophiesEarnedMilestones,
                        subtitle: l.trophiesEarnedYourFitnessJourney,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(height: 12),
                      _buildMilestonesGrid(context, elevated, cardBorder)
                          .animate(delay: 250.ms)
                          .fadeIn()
                          .slideY(begin: 0.1),

                      // Empty state if nothing earned (strength PR, cardio PR, OR achievement)
                      if (newPRs.isEmpty &&
                          newAchievements.isEmpty &&
                          (cardioPrs == null || cardioPrs!.isEmpty)) ...[
                        const SizedBox(height: 20),
                        _buildEmptyState(context, elevated),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
    );
  }

  /// Gravl-parity hero carousel: collapses every earned item this session into
  /// a single horizontally-scrolling row of badge medallions (gold trophy for
  /// strength PRs, sport-colored chip for cardio PRs, tier-gradient for
  /// achievements), each with a name + short description below. Renders nothing
  /// when nothing was earned. Works for 1–N items.
  Widget _buildBadgeCarousel(
    BuildContext context, {
    required List<Map<String, dynamic>> newPRs,
    required List<CardioPersonalRecord>? cardioPrs,
    required List<Map<String, dynamic>> newAchievements,
    required bool useKg,
  }) {
    final badges = <_BadgeData>[];

    // Strength PRs — gold trophy medallion.
    for (final pr in newPRs) {
      final name = (pr['exercise_name'] ?? pr['exercise'] ?? 'PR').toString();
      final weightKg = pr['weight_kg'] as num?;
      final reps = pr['reps'] as int?;
      final desc = weightKg != null
          ? '${WeightUtils.formatWorkoutWeight(weightKg.toDouble(), useKg: useKg)}'
              '${reps != null ? ' × $reps' : ''}'
          : 'New personal record';
      badges.add(_BadgeData(
        emoji: '🏆',
        gradient: const [Color(0xFFFFD700), Color(0xFFB8860B)],
        title: name,
        subtitle: desc,
      ));
    }

    // Cardio PRs — sport-colored medallion.
    for (final pr in (cardioPrs ?? const <CardioPersonalRecord>[])) {
      final color = _cardioSportColor(pr.sport);
      badges.add(_BadgeData(
        emoji: pr.isFirstTimeActivity ? '✨' : '🥇',
        gradient: [color, color.withOpacity(0.6)],
        title: '${_cardioSportLabel(pr.sport)} · ${pr.kindLabel}',
        subtitle: pr.formatValue(),
      ));
    }

    // Achievements — tier-gradient medallion with its own emoji.
    for (final a in newAchievements) {
      final tier = (a['tier'] as String? ?? 'bronze');
      final tierColor = _getTierColor(tier);
      badges.add(_BadgeData(
        emoji: _getIconEmoji(a['icon'] as String? ?? 'medal'),
        gradient: [tierColor, tierColor.withOpacity(0.6)],
        title: (a['name'] ?? a['title'] ?? 'Badge').toString(),
        subtitle: (a['description'] ?? '').toString(),
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: badges.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return _BadgeMedallion(badge: badges[index])
                .animate(delay: Duration(milliseconds: 120 + (index * 60)))
                .fadeIn(duration: 350.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPRCard(
    BuildContext context,
    Map<String, dynamic> pr,
    Color elevated,
    Color cardBorder,
    bool useKg,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final exerciseName = pr['exercise_name'] ?? pr['exercise'] ?? 'Exercise';
    final weightKg = pr['weight_kg'] as num?;
    final reps = pr['reps'] as int?;
    final improvement = pr['improvement_kg'] ?? pr['improvement'];
    final isAllTimePr = pr['is_all_time_pr'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withOpacity(0.15),
            AppColors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Trophy icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isAllTimePr ? Icons.emoji_events_rounded : Icons.trending_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // PR details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAllTimePr)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.trophiesEarnedAllTime,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      weightKg != null
                          ? WeightUtils.formatWorkoutWeight(
                              weightKg.toDouble(), useKg: useKg)
                          : '--',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                    if (reps != null) ...[
                      Text(
                        ' x $reps',
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                    ],
                    if (improvement != null && improvement > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward, size: 12, color: AppColors.green),
                            Text(
                              '+${WeightUtils.formatWorkoutWeight((improvement as num).toDouble(), useKg: useKg, space: false)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cardio PR card — parallels `_buildPRCard` but renders sport-aware
  /// styling + a "First time!" orange badge for `is_first_time_activity`
  /// (instead of the gold ALL-TIME ribbon used for strength PRs).
  Widget _buildCardioPrCard(
    BuildContext context,
    CardioPersonalRecord pr,
    Color elevated,
    Color cardBorder,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final sportColor = _cardioSportColor(pr.sport);
    final delta = pr.formatDelta();
    final isFirstTime = pr.isFirstTimeActivity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sportColor.withOpacity(0.15),
            sportColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sportColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Sport icon — colored chip (no gold trophy here; gold is reserved
          // for the all-time strength PR card).
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: sportColor.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: sportColor.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(
              _cardioSportIcon(pr.sport),
              color: sportColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_cardioSportLabel(pr.sport)} · ${pr.kindLabel}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFirstTime)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.trophiesEarnedFirstTime,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sportColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.trophiesEarnedNewPR,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: sportColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      pr.formatValue(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: sportColor,
                      ),
                    ),
                    if (delta != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward, size: 12, color: AppColors.green),
                            const SizedBox(width: 2),
                            Text(
                              delta,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (pr.celebrationMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    pr.celebrationMessage!,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _cardioSportIcon(String sport) {
    switch (sport) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'hiking':
        return Icons.terrain_rounded;
      case 'rowing':
        return Icons.rowing_rounded;
      case 'swimming':
        return Icons.pool_rounded;
      case 'elliptical':
      case 'stairs':
        return Icons.stairs_rounded;
      case 'skiing':
      case 'snowboarding':
        return Icons.downhill_skiing_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  Color _cardioSportColor(String sport) {
    switch (sport) {
      case 'running':
        return AppColors.orange;
      case 'cycling':
        return AppColors.cyan;
      case 'walking':
        return AppColors.green;
      case 'hiking':
        return const Color(0xFF8D6E63);
      case 'rowing':
        return AppColors.purple;
      case 'swimming':
        return const Color(0xFF26C6DA);
      default:
        return AppColors.cyan;
    }
  }

  String _cardioSportLabel(String sport) {
    if (sport.isEmpty) return sport;
    return sport[0].toUpperCase() + sport.substring(1);
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Map<String, dynamic> achievement,
    Color elevated,
    Color cardBorder,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final name = achievement['name'] ?? achievement['title'] ?? 'Achievement';
    final description = achievement['description'] ?? '';
    final icon = achievement['icon'] as String? ?? 'star';
    final tier = achievement['tier'] as String? ?? 'bronze';
    final points = achievement['points'] as int? ?? 0;

    // Get tier color
    final tierColor = _getTierColor(tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withOpacity(0.15),
            tierColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Badge icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tierColor, tierColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tierColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getIconEmoji(icon),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Achievement details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+$points pts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesGrid(BuildContext context, Color elevated, Color cardBorder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
        // Total Workouts
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalWorkouts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.trophiesEarnedTotalWorkouts,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Current Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${currentStreak ?? 0}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.trophiesEarnedDayStreak,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Next workout-count milestone after `current`. Returns null once the
  /// user has blown past the last threshold — defensive; in practice
  /// everyone is still chasing one of these.
  int? _nextMilestone(int current, List<int> thresholds) {
    for (final t in thresholds) {
      if (t > current) return t;
    }
    return null;
  }

  Widget _buildEmptyState(BuildContext context, Color elevated) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Workout-count ladder matches _WorkoutCompleteScreenState._milestoneThresholds
    // so copy here is consistent with what triggers trophies above.
    const workoutMilestones = [5, 10, 25, 50, 100, 150, 200, 250, 500, 1000];
    const streakMilestones = [3, 7, 14, 30, 60, 100, 365];

    final nextWorkoutMilestone = _nextMilestone(totalWorkouts, workoutMilestones);
    final streak = currentStreak ?? 0;
    final nextStreakMilestone = _nextMilestone(streak, streakMilestones);

    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                l.trophiesEarnedNextMilestones,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.trophiesEarnedNoNewRecords,
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 16),
          if (nextWorkoutMilestone != null)
            _MilestoneProgressRow(
              icon: Icons.fitness_center,
              iconColor: AppColors.purple,
              label: '$nextWorkoutMilestone-Workout Badge',
              current: totalWorkouts,
              target: nextWorkoutMilestone,
              unit: totalWorkouts == 1 ? 'workout' : 'workouts',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
          if (nextWorkoutMilestone != null && nextStreakMilestone != null)
            const SizedBox(height: 14),
          if (nextStreakMilestone != null)
            _MilestoneProgressRow(
              icon: Icons.local_fire_department,
              iconColor: AppColors.orange,
              label: '$nextStreakMilestone-Day Streak',
              current: streak,
              target: nextStreakMilestone,
              unit: streak == 1 ? 'day' : 'days',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
          if (nextWorkoutMilestone == null && nextStreakMilestone == null) ...[
            const SizedBox(height: 8),
            Text(
              l.trophiesEarnedAllMilestonesCleared,
              style: TextStyle(fontSize: 13, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return AppColors.cyan;
      default:
        return const Color(0xFFCD7F32); // Bronze
    }
  }

  String _getIconEmoji(String icon) {
    switch (icon.toLowerCase()) {
      case 'trophy':
        return '🏆';
      case 'fire':
        return '🔥';
      case 'star':
        return '⭐';
      case 'muscle':
        return '💪';
      case 'medal':
        return '🏅';
      case 'crown':
        return '👑';
      case 'lightning':
        return '⚡';
      case 'rocket':
        return '🚀';
      case 'heart':
        return '❤️';
      case 'target':
        return '🎯';
      default:
        return '🏅';
    }
  }
}

/// Labeled progress bar used in the "Next Milestones" empty state.
/// Caller passes a [current] count / [target] threshold and a [unit]
/// word (e.g. 'workouts', 'days') for the remaining-count copy.
class _MilestoneProgressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int current;
  final int target;
  final String unit;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _MilestoneProgressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - current).clamp(0, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Text(
              '$current / $target',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: textMuted.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remaining == 0
              ? AppLocalizations.of(context)!.trophiesEarnedMilestoneReached
              : AppLocalizations.of(context)!.trophiesEarnedRemainingToUnlock(remaining, unit),
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
      ],
    );
  }
}

/// Immutable description of one badge in the post-workout hero carousel.
class _BadgeData {
  final String emoji;
  final List<Color> gradient;
  final String title;
  final String subtitle;

  const _BadgeData({
    required this.emoji,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}

/// A single badge medallion: a glossy gradient disc with the badge emoji, a
/// title, and a one-line description. Fixed width so the carousel scrolls
/// horizontally with consistent card sizing regardless of count.
class _BadgeMedallion extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeMedallion({required this.badge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SizedBox(
      width: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medallion disc.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: badge.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badge.gradient.first.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(badge.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          if (badge.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              badge.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
