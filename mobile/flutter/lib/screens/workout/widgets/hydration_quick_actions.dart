/// Hydration Quick Actions Widget
///
/// Quick action buttons (Log Drink, Note) displayed above the exercise thumbnail strip.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Quick action buttons for the active workout screen (hydration + note)
class HydrationQuickActions extends StatelessWidget {
  /// Callback when the hydration button is tapped
  final VoidCallback onTap;

  /// Callback when the note button is tapped (optional)
  final VoidCallback? onNoteTap;

  const HydrationQuickActions({
    super.key,
    required this.onTap,
    this.onNoteTap,
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
          // Hydration button - vibrant blue
          _buildActionButton(
            icon: Icons.water_drop,
            label: 'Log Drink',
            color: AppColors.quickActionWater, // Vibrant blue
            onTap: onTap,
          ),

          // Note button (if callback provided) - vibrant amber/yellow
          if (onNoteTap != null) ...[
            const SizedBox(width: 10),
            _buildActionButton(
              icon: Icons.sticky_note_2_outlined,
              label: 'Note',
              color: const Color(0xFFF59E0B), // Vibrant amber
              onTap: onNoteTap!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
