import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A dense list row scaffold with a bottom 1px hairline rule — the signature-v2
/// alternative to a boxed card for lists. NOT a [Card]; it reads as a compact
/// row separated only by a hairline.
///
/// Layout: `[accent stripe] [leading] title / subtitle [trailing]`.
///
/// - [leading] is an optional fixed-size slot (a thumbnail, an icon, a number).
/// - [title] sits over an optional [subtitle].
/// - [trailing] is an optional actions slot (a chevron, a button, a value).
/// - [accentStripeColor] draws a 3px stripe down the left edge — use it for
///   difficulty coloring (e.g. `programDifficultyColor(level)`).
///
/// ```dart
/// ZHairlineRow(
///   leading: const Icon(Icons.fitness_center),
///   title: Text('Push Day'),
///   subtitle: Text('CHEST · SHOULDERS · TRICEPS'),
///   trailing: const Icon(Icons.chevron_right),
///   accentStripeColor: programDifficultyColor('Advanced'),
///   onTap: () {},
/// )
/// ```
class ZHairlineRow extends StatelessWidget {
  /// Optional leading slot (thumb / icon / number badge).
  final Widget? leading;

  /// The primary line.
  final Widget title;

  /// Optional secondary line below the title.
  final Widget? subtitle;

  /// Optional trailing actions slot.
  final Widget? trailing;

  /// When non-null, the row becomes tappable.
  final VoidCallback? onTap;

  /// Draws a 3px accent stripe down the left edge (e.g. difficulty color).
  final Color? accentStripeColor;

  /// Whether to draw the bottom hairline rule. Defaults to true; set false for
  /// the last row in a group if you don't want a trailing rule.
  final bool showDivider;

  /// Vertical padding for the row content. Defaults to a dense 13px.
  final double verticalPadding;

  const ZHairlineRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accentStripeColor,
    this.showDivider = true,
    this.verticalPadding = 13,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            )
          : null,
      child: Row(
        children: [
          if (accentStripeColor != null) ...[
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: accentStripeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
