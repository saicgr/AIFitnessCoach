import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../log_meal_sheet.dart';
import 'quick_add_sheet.dart';

/// Floating action button for quick meal logging
/// Always visible for easy access to food logging
class QuickAddFAB extends ConsumerWidget {
  final String userId;
  final VoidCallback onMealLogged;

  const QuickAddFAB({
    super.key,
    required this.userId,
    required this.onMealLogged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show FAB for easy food logging access
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Positioned(
      right: 16,
      bottom: 100, // Above the bottom nav bar
      child: FloatingActionButton.extended(
        heroTag: 'quick_add_fab',
        onPressed: () => _showQuickAddSheet(context, ref),
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 8,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Log Food',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref) {
    // Haptic feedback for button press
    HapticFeedback.lightImpact();

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(
        userId: userId,
        onMealLogged: onMealLogged,
      ),
    ).then((result) {
      // If user chose to open full log sheet, show LogMealSheet
      if (result == 'openFullLog' && context.mounted) {
        showLogMealSheet(context, ref).then((_) => onMealLogged());
      }
    });
  }
}

/// A simpler version of the FAB that can be used inside a Scaffold directly
class QuickAddFABSimple extends ConsumerWidget {
  final String userId;
  final VoidCallback onMealLogged;

  const QuickAddFABSimple({
    super.key,
    required this.userId,
    required this.onMealLogged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show FAB for easy food logging access
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return FloatingActionButton.extended(
      heroTag: 'quick_add_fab_simple',
      onPressed: () => _showQuickAddSheet(context, ref),
      backgroundColor: teal,
      foregroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 8,
      icon: const Icon(Icons.add_rounded, size: 24),
      label: const Text(
        'Log Food',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref) {
    // Haptic feedback for button press
    HapticFeedback.lightImpact();

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(
        userId: userId,
        onMealLogged: onMealLogged,
      ),
    ).then((result) {
      // If user chose to open full log sheet, show LogMealSheet
      if (result == 'openFullLog' && context.mounted) {
        showLogMealSheet(context, ref).then((_) => onMealLogged());
      }
    });
  }
}
