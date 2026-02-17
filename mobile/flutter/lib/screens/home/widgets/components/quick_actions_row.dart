import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/quick_action.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/providers/local_layout_provider.dart';
import '../../../../data/providers/quick_action_provider.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../widgets/main_shell.dart';
import '../../../../widgets/mood_picker_sheet.dart';
import '../../../../widgets/quick_actions_sheet.dart';
import '../../../fasting/widgets/log_weight_sheet.dart';
import '../../../nutrition/log_meal_sheet.dart';
import '../../../workout/widgets/quick_workout_sheet.dart';

/// Maps action IDs to the correct widget
Widget buildQuickActionWidget(String actionId, bool isDark, BuildContext context, WidgetRef ref) {
  switch (actionId) {
    case 'water':
      return _WaterGridActionItem(isDark: isDark);
    case 'weight':
      return _WeightGridActionItem(isDark: isDark);
    case 'fasting':
      return _FastGridActionItem(isDark: isDark);
    case 'mood':
      return _MoodGridActionItem(isDark: isDark);
    case 'food':
      return _GridActionItem(
        icon: Icons.restaurant_outlined,
        label: 'Food',
        iconColor: quickActionRegistry['food']!.color,
        onTap: () {
          HapticService.light();
          showLogMealSheet(context, ref);
        },
        isDark: isDark,
      );
    case 'quick_workout':
      return _GridActionItem(
        icon: Icons.flash_on,
        label: 'Quick',
        iconColor: quickActionRegistry['quick_workout']!.color,
        onTap: () {
          HapticService.light();
          showQuickWorkoutSheet(context, ref);
        },
        isDark: isDark,
      );
    default:
      final action = quickActionRegistry[actionId];
      if (action == null) return const SizedBox.shrink();
      return _GridActionItem(
        icon: action.icon,
        label: action.label,
        iconColor: action.color,
        onTap: () {
          HapticService.light();
          context.push(action.route!);
        },
        isDark: isDark,
      );
  }
}

/// A grid of quick action buttons (2 rows x 4 columns) with hero card
/// Replaces the FAB + button functionality directly on home screen
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allActions = ref.watch(orderedQuickActionsProvider);
    final gridActions = allActions.take(8).toList();
    final cardBg = isDark
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero card (Track Your Progress / Active Fasting)
            _HeroActionCard(),
            const SizedBox(height: 8),
            // Row 1: first 4 actions
            Row(
              children: [
                for (int i = 0; i < 4 && i < gridActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(gridActions[i].id, isDark, context, ref)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: next 4 actions
            Row(
              children: [
                for (int i = 4; i < 8 && i < gridActions.length; i++) ...[
                  if (i > 4) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(gridActions[i].id, isDark, context, ref)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero card that shows contextual content based on fasting state
class _HeroActionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;

    if (hasFast) {
      return _FastingHeroCard(
        fastingState: fastingState,
        isDark: isDark,
      );
    } else {
      return _PhotoHeroCard(isDark: isDark);
    }
  }
}

/// Hero card prompting to take progress photo
class _PhotoHeroCard extends StatelessWidget {
  final bool isDark;

  const _PhotoHeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/stats?openPhoto=true');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 22,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Take a progress photo to see your transformation',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero card showing fasting progress
class _FastingHeroCard extends ConsumerWidget {
  final FastingState fastingState;
  final bool isDark;

  const _FastingHeroCard({
    required this.fastingState,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final activeFast = fastingState.activeFast;

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    // Calculate progress
    final elapsedMinutes = activeFast?.elapsedMinutes ?? 0;
    final goalMinutes = activeFast?.goalDurationMinutes ?? 960; // Default 16h
    final progress = (elapsedMinutes / goalMinutes).clamp(0.0, 1.0);
    final hours = elapsedMinutes ~/ 60;
    final mins = elapsedMinutes % 60;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/fasting');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.timer,
                  size: 24,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fasting',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hours}h ${mins}m',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.black,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _EndFastButton(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// End fast button with loading state
class _EndFastButton extends ConsumerStatefulWidget {
  final bool isDark;

  const _EndFastButton({required this.isDark});

  @override
  ConsumerState<_EndFastButton> createState() => _EndFastButtonState();
}

class _EndFastButtonState extends ConsumerState<_EndFastButton> {
  bool _isEnding = false;

  Future<void> _endFast() async {
    if (_isEnding) return;

    setState(() => _isEnding = true);
    HapticService.medium();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;

      await ref.read(fastingProvider.notifier).endFast(userId: userId);

      if (mounted) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Fast ended successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF2D2D2D),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end fast: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.isDark ? Colors.white : Colors.black;
    final textOnButton = widget.isDark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: _endFast,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isEnding
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textOnButton,
                ),
              )
            : Text(
                'End',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textOnButton,
                ),
              ),
      ),
    );
  }
}

/// Grid action item with icon and label
class _GridActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const _GridActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Water grid action item with tap to add default and long-press for options
class _WaterGridActionItem extends ConsumerStatefulWidget {
  final bool isDark;

  const _WaterGridActionItem({required this.isDark});

  @override
  ConsumerState<_WaterGridActionItem> createState() => _WaterGridActionItemState();
}

class _WaterGridActionItemState extends ConsumerState<_WaterGridActionItem> {
  bool _isLoading = false;
  static const int _defaultWaterMl = 500;

  static const List<({int ml, String label, IconData icon})> _waterSizes = [
    (ml: 250, label: '250ml', icon: Icons.local_cafe_outlined),
    (ml: 500, label: '500ml', icon: Icons.water_drop_outlined),
    (ml: 750, label: '750ml', icon: Icons.water_drop),
    (ml: 1000, label: '1L', icon: Icons.waves),
  ];

  Future<void> _quickAddWater(int amountMl) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to track hydration'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final success = await ref.read(hydrationProvider.notifier).quickLog(
            userId: userId,
            drinkType: 'water',
            amountMl: amountMl,
          );

      if (mounted) {
        if (success) {
          HapticService.success();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('+${amountMl}ml water logged'),
                ],
              ),
              backgroundColor: quickActionRegistry['water']!.color,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to log water. Please try again.'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log water. Please try again.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showWaterSizeOptions() {
    HapticService.medium();
    final isDark = widget.isDark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Log Water',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select amount to log',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _waterSizes.map((size) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _WaterSizeOption(
                          ml: size.ml,
                          label: size.label,
                          icon: size.icon,
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            _quickAddWater(size.ml);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/hydration');
                },
                child: Text(
                  'Open Hydration Tracker',
                  style: TextStyle(
                    color: quickActionRegistry['water']!.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showWaterSizeOptions,
        onLongPress: () => _quickAddWater(_defaultWaterMl),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: quickActionRegistry['water']!.color,
                      ),
                    )
                  : Icon(
                      Icons.water_drop_outlined,
                      size: 22,
                      color: quickActionRegistry['water']!.color,
                    ),
              const SizedBox(height: 4),
              Text(
                'Water',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mood grid action item - opens mood picker sheet
class _MoodGridActionItem extends ConsumerWidget {
  final bool isDark;

  const _MoodGridActionItem({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showMoodPickerSheet(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mood_outlined,
                size: 22,
                color: quickActionRegistry['mood']!.color,
              ),
              const SizedBox(height: 4),
              Text(
                'Mood',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weight grid action item - shows weight logging bottom sheet
class _WeightGridActionItem extends ConsumerWidget {
  final bool isDark;

  const _WeightGridActionItem({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          showLogWeightSheet(context, ref);
        },
        onLongPress: () {
          HapticService.light();
          context.push('/measurements');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                size: 22,
                color: quickActionRegistry['weight']!.color,
              ),
              const SizedBox(height: 4),
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fasting grid action item - shows status or navigates to fasting screen
class _FastGridActionItem extends ConsumerWidget {
  final bool isDark;

  const _FastGridActionItem({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;

    String label = 'Fasting';
    if (hasFast && fastingState.activeFast != null) {
      final elapsed = fastingState.activeFast!.elapsedMinutes;
      final hours = elapsed ~/ 60;
      final mins = elapsed % 60;
      label = '${hours}h ${mins}m';
    }

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/fasting');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    hasFast ? Icons.timer : Icons.timer_outlined,
                    size: 22,
                    color: quickActionRegistry['fasting']!.color,
                  ),
                  if (hasFast)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual water size option in the bottom sheet
class _WaterSizeOption extends StatelessWidget {
  final int ml;
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _WaterSizeOption({
    required this.ml,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.cardBorder.withValues(alpha: 0.3)
        : AppColorsLight.cardBorder.withValues(alpha: 0.3);
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: quickActionRegistry['water']!.color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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

/// QuickActionsRow: switches between compact (Minimalist) and classic (Old Default) modes
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapseBanners = ref.watch(collapseBannersProvider);

    if (collapseBanners) {
      return const CompactQuickActionsRow();
    }
    return const QuickActionsGrid();
  }
}

/// Compact quick actions: single row of pinned actions + "+" button
/// Used in Minimalist preset
class CompactQuickActionsRow extends ConsumerWidget {
  const CompactQuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinnedActions = ref.watch(pinnedQuickActionsProvider);
    final cardBg = isDark
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (int i = 0; i < pinnedActions.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(child: buildQuickActionWidget(pinnedActions[i].id, isDark, context, ref)),
            ],
            const SizedBox(width: 4),
            Expanded(child: _MoreActionsButton(isDark: isDark)),
          ],
        ),
      ),
    );
  }
}

/// "+" button that opens a bottom sheet with all quick actions
class _MoreActionsButton extends ConsumerWidget {
  final bool isDark;

  const _MoreActionsButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          showQuickActionsSheet(context, ref);
        },
        onLongPress: () {
          HapticService.medium();
          showQuickActionsSheet(context, ref, editMode: true);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz,
                size: 22,
                color: textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 4),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
