import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/animations/app_animations.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/fasting_provider.dart';
import '../data/repositories/hydration_repository.dart';
import '../data/services/api_client.dart';
import '../screens/nutrition/log_meal_sheet.dart';
import 'main_shell.dart';

/// Shows the quick actions bottom sheet when + button is tapped
void showQuickActionsSheet(BuildContext context, WidgetRef ref) {
  HapticFeedback.mediumImpact();

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _QuickActionsSheet(ref: ref),
  ).then((_) {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _QuickActionsSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _QuickActionsSheet({required this.ref});

  @override
  ConsumerState<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends ConsumerState<_QuickActionsSheet> {
  bool _isLoggingWater = false;

  Future<void> _quickAddWater() async {
    if (_isLoggingWater) return;

    setState(() => _isLoggingWater = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        if (mounted) {
          Navigator.pop(context);
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
            amountMl: 500,
          );

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('+500ml water logged'),
                ],
              ),
              backgroundColor: const Color(0xFF2D2D2D),
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
        Navigator.pop(context);
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
        setState(() => _isLoggingWater = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Define all actions with monochrome colors
    final trackActions = [
      _ActionData(
        icon: Icons.camera_alt_outlined,
        label: 'Photo',
        onTap: () {
          Navigator.pop(context);
          context.push('/progress');
        },
      ),
      _ActionData(
        icon: Icons.restaurant_outlined,
        label: 'Food',
        onTap: () {
          Navigator.pop(context);
          showLogMealSheet(context, widget.ref);
        },
      ),
      _ActionData(
        icon: Icons.water_drop_outlined,
        label: 'Water',
        onTap: _quickAddWater,
        isLoading: _isLoggingWater,
      ),
      _ActionData(
        icon: Icons.monitor_weight_outlined,
        label: 'Weight',
        onTap: () {
          Navigator.pop(context);
          context.push('/measurements');
        },
      ),
    ];

    final viewActions = [
      _ActionData(
        icon: Icons.insights_outlined,
        label: 'Stats',
        onTap: () {
          Navigator.pop(context);
          context.push('/stats');
        },
      ),
      _ActionData(
        icon: Icons.history_outlined,
        label: 'History',
        onTap: () {
          Navigator.pop(context);
          context.push('/progress');
        },
      ),
      _ActionData(
        icon: Icons.fitness_center_outlined,
        label: 'Workout',
        onTap: () {
          Navigator.pop(context);
          context.push('/workouts');
        },
      ),
      _ActionData(
        icon: Icons.timer_outlined,
        label: 'Fast',
        onTap: () {
          Navigator.pop(context);
          context.push('/fasting');
        },
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Hero Card (contextual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HeroActionCard(
                onClose: () => Navigator.pop(context),
              ).animateHeroEntrance(),
            ),

            const SizedBox(height: 16),

            // Row 1: Track Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: trackActions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index > 0 ? 6 : 0,
                        right: index < 3 ? 6 : 0,
                      ),
                      child: _CompactActionItem(
                        icon: action.icon,
                        label: action.label,
                        onTap: action.onTap,
                        isDark: isDark,
                        isLoading: action.isLoading,
                      ).animateListItem(index: index + 1),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Row 2: View/Act Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: viewActions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index > 0 ? 6 : 0,
                        right: index < 3 ? 6 : 0,
                      ),
                      child: _CompactActionItem(
                        icon: action.icon,
                        label: action.label,
                        onTap: action.onTap,
                        isDark: isDark,
                      ).animateListItem(index: index + 5),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Data class for action items
class _ActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  _ActionData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });
}

/// Hero card that shows contextual content based on fasting state
class _HeroActionCard extends ConsumerWidget {
  final VoidCallback onClose;

  const _HeroActionCard({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;

    if (hasFast) {
      return _FastingHeroCard(
        fastingState: fastingState,
        onClose: onClose,
        isDark: isDark,
      );
    } else {
      return _PhotoHeroCard(
        onClose: onClose,
        isDark: isDark,
      );
    }
  }
}

/// Hero card showing fasting progress
class _FastingHeroCard extends ConsumerWidget {
  final FastingState fastingState;
  final VoidCallback onClose;
  final bool isDark;

  const _FastingHeroCard({
    required this.fastingState,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final activeFast = fastingState.activeFast;

    // Monochrome colors
    final cardBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
    final iconBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8);

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
          onClose();
          context.push('/fasting');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Timer icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.timer,
                  size: 28,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fasting',
                          style: TextStyle(
                            fontSize: 14,
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
                    const SizedBox(height: 4),
                    Text(
                      '${hours}h ${mins}m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.black,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // End Fast button
              _EndFastButton(onClose: onClose, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// End fast button with loading state
class _EndFastButton extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final bool isDark;

  const _EndFastButton({required this.onClose, required this.isDark});

  @override
  ConsumerState<_EndFastButton> createState() => _EndFastButtonState();
}

class _EndFastButtonState extends ConsumerState<_EndFastButton> {
  bool _isEnding = false;

  Future<void> _endFast() async {
    if (_isEnding) return;

    setState(() => _isEnding = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;

      await ref.read(fastingProvider.notifier).endFast(userId: userId);

      if (mounted) {
        HapticFeedback.lightImpact();
        widget.onClose();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isEnding
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textOnButton,
                ),
              )
            : Text(
                'End',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textOnButton,
                ),
              ),
      ),
    );
  }
}

/// Hero card prompting to take progress photo
class _PhotoHeroCard extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDark;

  const _PhotoHeroCard({
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Monochrome colors
    final cardBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
    final iconBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onClose();
          context.push('/progress');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Camera icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 28,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take a progress photo to see your transformation',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact action item for the grid
class _CompactActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLoading;

  const _CompactActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Monochrome colors
    final cardColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);
    final borderColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE0E0E0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 24,
                  color: textColor,
                ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
