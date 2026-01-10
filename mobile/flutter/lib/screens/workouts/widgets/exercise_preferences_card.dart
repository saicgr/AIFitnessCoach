import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Expandable card showing exercise preferences in the Workouts screen
class ExercisePreferencesCard extends ConsumerStatefulWidget {
  const ExercisePreferencesCard({super.key});

  @override
  ConsumerState<ExercisePreferencesCard> createState() =>
      _ExercisePreferencesCardState();
}

class _ExercisePreferencesCardState
    extends ConsumerState<ExercisePreferencesCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final coral = AppColors.coral;

    // Watch providers for counts
    final favoritesState = ref.watch(favoritesProvider);
    final staplesState = ref.watch(staplesProvider);
    final queueState = ref.watch(exerciseQueueProvider);

    final favoriteCount = favoritesState.favorites.length;
    final stapleCount = staplesState.staples.length;
    final queueCount = queueState.activeQueue.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              HapticService.light();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: coral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: coral,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Favorites, avoided, queue',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: cardBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXERCISE PREFERENCES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize which exercises appear in workouts',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Preference items
                _buildPreferenceItem(
                  context,
                  icon: Icons.favorite,
                  title: 'Favorite Exercises',
                  subtitle: 'AI will prioritize these',
                  trailing: '$favoriteCount exercises',
                  onTap: () => context.push('/settings/favorite-exercises'),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildPreferenceItem(
                  context,
                  icon: Icons.lock,
                  title: 'Staple Exercises',
                  subtitle: 'Core lifts that never rotate',
                  trailing: '$stapleCount exercises',
                  onTap: () => context.push('/settings/staple-exercises'),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildPreferenceItem(
                  context,
                  icon: Icons.playlist_add,
                  title: 'Exercise Queue',
                  subtitle: 'Queue exercises for next workout',
                  trailing: '$queueCount queued',
                  onTap: () => context.push('/settings/exercise-queue'),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildPreferenceItem(
                  context,
                  icon: Icons.block,
                  title: 'Exercises to Avoid',
                  subtitle: 'Skip specific exercises',
                  trailing: null,
                  onTap: () => context.push('/settings/avoided-exercises'),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildPreferenceItem(
                  context,
                  icon: Icons.accessibility_new,
                  title: 'Muscles to Avoid',
                  subtitle: 'Skip or reduce muscle groups',
                  trailing: null,
                  onTap: () => context.push('/settings/avoided-muscles'),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isLast: true,
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String? trailing,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    bool isLast = false,
  }) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticService.light();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Divider(height: 1, color: cardBorder),
          ),
      ],
    );
  }
}
