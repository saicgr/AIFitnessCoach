/// Hydration Quick Actions Widget
///
/// Single water button that opens a sheet for logging drinks during workout.
/// Displays above the exercise thumbnail strip.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/hydration.dart';

/// Single hydration button for the active workout screen
class HydrationQuickActions extends StatelessWidget {
  /// Callback when the hydration button is tapped
  final VoidCallback onTap;

  const HydrationQuickActions({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.surface : Colors.grey.shade50;
    final borderColor = isDark ? AppColors.cardBorder : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Hydration button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.teal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 18,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Log Drink',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.teal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
