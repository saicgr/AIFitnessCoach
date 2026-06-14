import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

import '../../l10n/generated/app_localizations.dart';
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
                    AppLocalizations.of(context)
                        .quickLogOverlayQuickLog
                        .toUpperCase(),
                    style: ZType.lbl(
                      18,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                      letterSpacing: 1.5,
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
                        label: Text(AppLocalizations.of(context).quickLogOverlayGoToApp),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
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
                        label: AppLocalizations.of(context).quickLogOverlayBreakfast,
                        onTap: () => _logMeal(context, ref, 'breakfast'),
                      ),
                      _MealTypeChip(
                        emoji: '☀️',
                        label: AppLocalizations.of(context).quickLogOverlayLunch,
                        onTap: () => _logMeal(context, ref, 'lunch'),
                      ),
                      _MealTypeChip(
                        emoji: '🌙',
                        label: AppLocalizations.of(context).quickLogOverlayDinner,
                        onTap: () => _logMeal(context, ref, 'dinner'),
                      ),
                      _MealTypeChip(
                        emoji: '🍎',
                        label: AppLocalizations.of(context).quickLogOverlaySnack,
                        onTap: () => _logMeal(context, ref, 'snack'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).quickLogOverlayTapAMealType,
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
          color: isDark ? AppColors.surface : AppColorsLight.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
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
