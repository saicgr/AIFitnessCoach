import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/main_shell.dart';
import '../../../nutrition/log_meal_sheet.dart';
import '../../../workout/widgets/quick_workout_sheet.dart';

/// A compact row of quick action buttons for common tasks
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.restaurant_outlined,
                label: 'Log Food',
                color: const Color(0xFF34C759),
                onTap: () {
                  HapticService.light();
                  showLogMealSheet(context, ref);
                },
                isDark: isDark,
              ),
            ),
            _buildDivider(isDark),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.insights_outlined,
                label: 'Stats',
                color: AppColors.purple,
                onTap: () {
                  HapticService.light();
                  context.push('/stats');
                },
                isDark: isDark,
              ),
            ),
            _buildDivider(isDark),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.flash_on,
                label: 'Quick',
                color: AppColors.orange,
                onTap: () {
                  HapticService.light();
                  showQuickWorkoutSheet(context, ref);
                },
                isDark: isDark,
              ),
            ),
            _buildDivider(isDark),
            Expanded(
              child: _WaterQuickActionButton(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark
          ? AppColors.cardBorder.withValues(alpha: 0.5)
          : AppColorsLight.cardBorder.withValues(alpha: 0.5),
    );
  }
}

/// Individual quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
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

/// Water quick action button with tap to add default and long-press for options
class _WaterQuickActionButton extends ConsumerStatefulWidget {
  final bool isDark;

  const _WaterQuickActionButton({required this.isDark});

  @override
  ConsumerState<_WaterQuickActionButton> createState() =>
      _WaterQuickActionButtonState();
}

class _WaterQuickActionButtonState
    extends ConsumerState<_WaterQuickActionButton> {
  bool _isLoading = false;

  // Default water amount in ml (can be made configurable via settings)
  static const int _defaultWaterMl = 500;

  // Water size options for long-press menu
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
              backgroundColor: AppColors.electricBlue,
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
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                    color: AppColors.electricBlue,
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
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _quickAddWater(_defaultWaterMl),
        onLongPress: _showWaterSizeOptions,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.electricBlue,
                      ),
                    )
                  : Icon(
                      Icons.water_drop_outlined,
                      size: 22,
                      color: AppColors.electricBlue,
                    ),
              const SizedBox(height: 4),
              Text(
                'Water',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
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
                color: AppColors.electricBlue,
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
