/// Hydration Quick Actions Widget
///
/// Quick action buttons (Log Drink, Note) displayed above the exercise thumbnail strip.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Quick action buttons for the active workout screen (instructions + video + hydration + note)
class HydrationQuickActions extends StatelessWidget {
  /// Callback when the hydration button is tapped
  final VoidCallback onTap;

  /// Callback when the note button is tapped (optional)
  final VoidCallback? onNoteTap;

  /// Callback when the video button is tapped (optional)
  final VoidCallback? onVideoTap;

  /// Callback when the instructions (info) button is tapped (optional)
  final VoidCallback? onInstructionsTap;

  /// Callback when the ✦ AI quick-log chip is tapped (optional). When non-null,
  /// a leading "AI" chip is rendered as the first action — this is the
  /// natural-language set logger / add-exercise input folded into the row so it
  /// no longer reserves a dedicated band above the table (Advanced mode).
  final VoidCallback? onAiTap;

  /// Whether the AI input is currently open (highlights the chip).
  final bool aiActive;

  /// Accent color for the AI chip (defaults to a violet if not supplied).
  final Color? aiColor;

  const HydrationQuickActions({
    super.key,
    required this.onTap,
    this.onNoteTap,
    this.onVideoTap,
    this.onInstructionsTap,
    this.onAiTap,
    this.aiActive = false,
    this.aiColor,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // Trailing padding ensures the Note button (rightmost) isn't hidden
        // under the floating AI Coach avatar (56px wide + 20px margin = 76px).
        padding: const EdgeInsetsDirectional.only(end: 80),
        child: Row(
          children: [
            // ✦ AI quick-log chip (leading) — folds the natural-language set
            // logger / add-exercise input into this row instead of its own band.
            if (onAiTap != null) ...[
              _buildActionButton(
                // TODO(i18n): in-workout chip label, matches action_chips_row.dart
                icon: Icons.auto_awesome,
                label: 'AI',
                color: aiColor ?? const Color(0xFF8B5CF6),
                onTap: onAiTap!,
                filled: aiActive,
              ),
              const SizedBox(width: 10),
            ],

            // Instructions button (info) - vibrant green
            if (onInstructionsTap != null) ...[
              _buildActionButton(
                icon: Icons.menu_book_rounded,
                label: AppLocalizations.of(context).workoutShowcaseInstructions,
                color: const Color(0xFF10B981), // Vibrant emerald
                onTap: onInstructionsTap!,
              ),
              const SizedBox(width: 10),
            ],

            // Video button (if callback provided) - vibrant purple/accent
            if (onVideoTap != null) ...[
              _buildActionButton(
                icon: Icons.play_circle_outline,
                label: AppLocalizations.of(context).workoutShowcaseVideo,
                color: const Color(0xFF8B5CF6), // Vibrant purple
                onTap: onVideoTap!,
              ),
              const SizedBox(width: 10),
            ],

            // Hydration button - vibrant blue
            _buildActionButton(
              icon: Icons.water_drop,
              label: AppLocalizations.of(context).workoutShowcaseLogDrink,
              color: AppColors.quickActionWater, // Vibrant blue
              onTap: onTap,
            ),

            // Note button (if callback provided) - vibrant amber/yellow
            if (onNoteTap != null) ...[
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.sticky_note_2_outlined,
                label: AppLocalizations.of(context).workoutUiBuildersNote,
                color: const Color(0xFFF59E0B), // Vibrant amber
                onTap: onNoteTap!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final foreground = filled ? Colors.white : color;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
