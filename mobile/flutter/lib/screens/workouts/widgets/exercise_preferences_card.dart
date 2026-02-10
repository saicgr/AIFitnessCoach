import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/avoided_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/weight_increments_sheet.dart';

/// Expandable card showing exercise preferences in the Workouts screen
class ExercisePreferencesCard extends ConsumerStatefulWidget {
  /// Optional margin override. Defaults to horizontal 16px.
  /// Pass EdgeInsets.zero to disable margin (useful when parent already has padding).
  final EdgeInsetsGeometry? margin;

  const ExercisePreferencesCard({super.key, this.margin});

  @override
  ConsumerState<ExercisePreferencesCard> createState() =>
      _ExercisePreferencesCardState();
}

class _ExercisePreferencesCardState
    extends ConsumerState<ExercisePreferencesCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Ensure avoided exercises are loaded (lazy initialization)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(avoidedProvider.notifier).ensureInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Watch providers for counts
    final favoritesState = ref.watch(favoritesProvider);
    final staplesState = ref.watch(staplesProvider);
    final queueState = ref.watch(exerciseQueueProvider);
    final avoidedState = ref.watch(avoidedProvider);
    final warmupState = ref.watch(warmupDurationProvider);
    final weightIncrementsState = ref.watch(weightIncrementsProvider);

    final favoriteCount = favoritesState.favorites.length;
    final stapleCount = staplesState.staples.length;
    final queueCount = queueState.activeQueue.length;
    final avoidedCount = avoidedState.activeAvoided.length;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
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
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: accentColor,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'EXERCISE PREFERENCES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: textMuted,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showExercisePrefsHelp(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "What's this?",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  trailing: avoidedCount > 0 ? '$avoidedCount avoided' : null,
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
                ),
                _buildPreferenceItem(
                  context,
                  icon: Icons.tune,
                  title: 'Weight Increments',
                  subtitle: 'Customize +/- step per equipment',
                  trailing: weightIncrementsState.unit.toUpperCase(),
                  onTap: () => showWeightIncrementsSheet(context),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                // Warmup & Stretch section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WARMUP & COOLDOWN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enable or disable workout phases',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildToggleItem(
                  context,
                  icon: Icons.whatshot,
                  title: 'Warmup Phase',
                  subtitle: 'Dynamic warmup before workouts',
                  value: warmupState.warmupEnabled,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                  },
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                _buildToggleItem(
                  context,
                  icon: Icons.self_improvement,
                  title: 'Cooldown Stretch',
                  subtitle: 'Stretching after workouts',
                  value: warmupState.stretchEnabled,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                  },
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

  void _showExercisePrefsHelp(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    const helpItems = <Map<String, dynamic>>[
      {
        'icon': Icons.favorite,
        'title': 'Favorite Exercises',
        'description': 'Exercises you enjoy. The AI gives these a priority boost (2.5x) so they appear more often in your workouts — but they can still be rotated out for variety.',
        'color': AppColors.error,
      },
      {
        'icon': Icons.lock,
        'title': 'Staple Exercises',
        'description': 'Core lifts that are GUARANTEED in every workout for their muscle group. They never rotate out regardless of your variety setting. Scoped to specific gym profiles for equipment compatibility.',
        'color': AppColors.purple,
      },
      {
        'icon': Icons.playlist_add,
        'title': 'Exercise Queue',
        'description': 'One-time requests. Queued exercises are included in your next workout, then automatically removed from the queue. Great for trying a new exercise.',
        'color': AppColors.cyan,
      },
      {
        'icon': Icons.block,
        'title': 'Exercises to Avoid',
        'description': 'Blacklisted exercises the AI will NEVER include in any workout. Use for exercises that cause pain, discomfort, or you simply dislike.',
        'color': AppColors.error,
      },
      {
        'icon': Icons.accessibility_new,
        'title': 'Muscles to Avoid',
        'description': 'Muscle groups to skip entirely ("avoid") or reduce volume for ("reduce"). Useful for injuries or letting a muscle group recover.',
        'color': AppColors.orange,
      },
      {
        'icon': Icons.tune,
        'title': 'Weight Increments',
        'description': 'Customize the +/- weight step for each equipment type. For example, set barbell increments to 2.5 kg or dumbbell increments to 1 kg.',
        'color': AppColors.cyan,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: elevatedColor,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exercise Preferences Explained',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
            ),
            // Help items
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: helpItems.length,
                itemBuilder: (context, index) {
                  final item = helpItems[index];
                  final icon = item['icon'] as IconData;
                  final title = item['title'] as String;
                  final description = item['description'] as String;
                  final color = item['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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

  Widget _buildToggleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    bool isLast = false,
  }) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: orange,
              ),
            ],
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
