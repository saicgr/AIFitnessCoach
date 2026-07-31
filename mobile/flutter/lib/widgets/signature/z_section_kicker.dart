import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/app_typography.dart';

/// A Barlow-Condensed uppercase section label in the app accent,
/// optionally followed by a trailing "SEE ALL ›" tap affordance.
///
/// This is the signature-v2 section header used above rails/lists. The label
/// is forced uppercase. Keep it short — it is a kicker, not a heading.
///
/// ```dart
/// ZSectionKicker(
///   label: 'Featured programs',
///   onSeeAll: () => context.push('/workout/program-library'),
/// )
/// ```
class ZSectionKicker extends StatelessWidget {
  /// The kicker text. Rendered uppercase regardless of input casing.
  final String label;

  /// When non-null, a trailing "SEE ALL ›" link is shown and tapped here.
  final VoidCallback? onSeeAll;

  /// Override the trailing link text (still uppercased). Defaults to "SEE ALL".
  final String seeAllLabel;

  /// The kicker color. Defaults to the live app accent (`context.accentColor`).
  final Color? color;

  const ZSectionKicker({
    super.key,
    required this.label,
    this.onSeeAll,
    this.seeAllLabel = 'SEE ALL',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.accentColor;
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(12, color: effectiveColor, letterSpacing: 2.0),
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  seeAllLabel.toUpperCase(),
                  style: ZType.lbl(11.5,
                      color: AppColors.textSecondary, letterSpacing: 1.4),
                ),
                const SizedBox(width: 3),
                const Text(
                  '›',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
