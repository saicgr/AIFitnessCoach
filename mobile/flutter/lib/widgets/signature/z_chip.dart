import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A signature-v2 pill chip with a Barlow-Condensed uppercase label.
///
/// - Unselected: hairline border + muted text, transparent fill.
/// - Selected: orange border + orange text + a faint orange fill.
/// - [leadingDot]: an optional small colored dot before the label (e.g. a
///   difficulty/category marker).
///
/// ```dart
/// ZChip(
///   label: 'Strength',
///   selected: filter == 'strength',
///   onTap: () => setState(() => filter = 'strength'),
///   leadingDot: programDifficultyColor('Advanced'),
/// )
/// ```
class ZChip extends StatelessWidget {
  /// The chip text. Rendered uppercase.
  final String label;

  /// Whether the chip is in its selected (accent) state.
  final bool selected;

  /// Tap handler. When null the chip is non-interactive (display only).
  final VoidCallback? onTap;

  /// Optional small dot drawn before the label.
  final Color? leadingDot;

  const ZChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leadingDot,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.orange;
    final borderColor = selected ? accent : AppColors.cardBorder;
    final textColor = selected ? accent : AppColors.textSecondary;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadingDot,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label.toUpperCase(),
            style: ZType.lbl(12, color: textColor, letterSpacing: 1.2),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}
