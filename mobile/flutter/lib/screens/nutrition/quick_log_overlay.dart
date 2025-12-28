import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'log_meal_sheet.dart';

/// Shows a quick log meal overlay that appears immediately from widgets
/// Has a "Go to App" button to navigate to full nutrition screen
void showQuickLogOverlay(BuildContext context, WidgetRef ref) {
  debugPrint('🎯 [QuickLogOverlay] showQuickLogOverlay called, about to show dialog');

  try {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) {
        debugPrint('🎯 [QuickLogOverlay] Dialog builder called, creating overlay widget');
        return const QuickLogOverlay();
      },
    ).then((value) {
      debugPrint('🎯 [QuickLogOverlay] Dialog dismissed with value: $value');
    });

    debugPrint('🎯 [QuickLogOverlay] showDialog called successfully');
  } catch (e, stack) {
    debugPrint('❌ [QuickLogOverlay] Error showing dialog: $e');
    debugPrint('Stack: $stack');
  }
}

class QuickLogOverlay extends ConsumerWidget {
  const QuickLogOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : AppColorsLight.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with "Go to App" button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Log',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/nutrition');
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Go to App'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick log options
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Meal type selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MealTypeChip(
                        emoji: '🌅',
                        label: 'Breakfast',
                        onTap: () => _logMeal(context, ref, 'breakfast'),
                      ),
                      _MealTypeChip(
                        emoji: '☀️',
                        label: 'Lunch',
                        onTap: () => _logMeal(context, ref, 'lunch'),
                      ),
                      _MealTypeChip(
                        emoji: '🌙',
                        label: 'Dinner',
                        onTap: () => _logMeal(context, ref, 'dinner'),
                      ),
                      _MealTypeChip(
                        emoji: '🍎',
                        label: 'Snack',
                        onTap: () => _logMeal(context, ref, 'snack'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap a meal type to log, or go to the app for more options',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logMeal(BuildContext context, WidgetRef ref, String mealType) {
    Navigator.of(context).pop();
    context.go('/nutrition');
    // Future: could auto-open the log sheet for the selected meal type
  }
}

class _MealTypeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _MealTypeChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface.withOpacity(0.5)
              : AppColorsLight.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
