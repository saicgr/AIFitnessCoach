import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../log_meal_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    // Always show FAB for easy food logging access. This is the one primary
    // action on the surface, so it carries the resolved accent (Signature).
    final colors = ThemeColors.of(context);

    return PositionedDirectional(end: 16,
      bottom: 100, // Above the bottom nav bar
      child: FloatingActionButton.extended(
        heroTag: 'quick_add_b',
        onPressed: () => _openLogMealSheet(context, ref),
        backgroundColor: colors.accent,
        foregroundColor: colors.accentContrast,
        elevation: 6,
        highlightElevation: 8,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          AppLocalizations.of(context).quickLogFabLogFood,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _openLogMealSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showLogMealSheet(context, ref).then((_) => onMealLogged());
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
    // Always show FAB for easy food logging access. Primary action → accent.
    final colors = ThemeColors.of(context);

    return FloatingActionButton.extended(
      heroTag: 'quick_add_fab_simple',
      onPressed: () => _openLogMealSheet(context, ref),
      backgroundColor: colors.accent,
      foregroundColor: colors.accentContrast,
      elevation: 6,
      highlightElevation: 8,
      icon: const Icon(Icons.add_rounded, size: 24),
      label: Text(
        AppLocalizations.of(context).quickLogFabLogFood,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  void _openLogMealSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showLogMealSheet(context, ref).then((_) => onMealLogged());
  }
}
