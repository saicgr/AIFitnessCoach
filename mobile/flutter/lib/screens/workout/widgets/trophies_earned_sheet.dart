import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

/// Shows a bottom sheet displaying trophies and achievements earned from the workout
Future<void> showTrophiesEarnedSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> newPRs,
  required Map<String, dynamic>? achievements,
  required int totalWorkouts,
  required int? currentStreak,
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
      ),
    ),
  );
}

class _TrophiesEarnedSheet extends StatelessWidget {
  final List<Map<String, dynamic>> newPRs;
  final Map<String, dynamic>? achievements;
  final int totalWorkouts;
  final int? currentStreak;

  const _TrophiesEarnedSheet({
    required this.newPRs,
    required this.achievements,
    required this.totalWorkouts,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            'Trophies & Achievements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Your session highlights',
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
                      // Personal Records Section
                      if (newPRs.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.trending_up_rounded,
                          title: 'Personal Records',
                          subtitle: '${newPRs.length} new PRs!',
                          color: AppColors.orange,
                        ),
                        const SizedBox(height: 12),
                        ...newPRs.asMap().entries.map((entry) {
                          final pr = entry.value;
                          final index = entry.key;
                          return _buildPRCard(context, pr, elevated, cardBorder)
                              .animate(delay: Duration(milliseconds: 150 + (index * 50)))
                              .fadeIn()
                              .slideX(begin: 0.1);
                        }),
                        const SizedBox(height: 24),
                      ],

                      // New Achievements Section
                      if (newAchievements.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.military_tech_rounded,
                          title: 'Achievements Unlocked',
                          subtitle: '${newAchievements.length} new badges',
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
                        title: 'Milestones',
                        subtitle: 'Your fitness journey',
                        color: AppColors.cyan,
                      ),
                      const SizedBox(height: 12),
                      _buildMilestonesGrid(context, elevated, cardBorder)
                          .animate(delay: 250.ms)
                          .fadeIn()
                          .slideY(begin: 0.1),

                      // Empty state if nothing earned
                      if (newPRs.isEmpty && newAchievements.isEmpty) ...[
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
                          'ALL-TIME',
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
                      '${weightKg?.toStringAsFixed(1) ?? '--'} kg',
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
                              '+${(improvement as num).toStringAsFixed(1)}kg',
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
                  'Total Workouts',
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
                  'Day Streak',
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

  Widget _buildEmptyState(BuildContext context, Color elevated) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 48,
            color: textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep Pushing!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new records this session, but every workout brings you closer to your goals!',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
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
