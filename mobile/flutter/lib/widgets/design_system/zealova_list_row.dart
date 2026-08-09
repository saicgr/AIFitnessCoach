import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';

/// The Signature list row — a framed glyph + label + optional value + trailing,
/// sitting on a hairline (no boxed cards). One template restyles the ~40
/// settings routes. Used for settings, hub links, ledger rows.
class ZealovaListRow extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool hairline;
  final Color? labelColor;

  const ZealovaListRow({
    super.key,
    this.icon,
    this.emoji,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.hairline = true,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    Widget? leading;
    if (emoji != null) {
      leading = Text(emoji!, style: const TextStyle(fontSize: 16));
    } else if (icon != null) {
      leading = Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: tc.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: tc.textSecondary),
      );
    }
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: hairline
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: tc.hairline)),
            )
          : null,
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          // The label is the row's IDENTITY and must win the width fight.
          //
          // `value` used to be an unconstrained Text, so it claimed its full
          // intrinsic width and left `Expanded(label)` the remainder. A long
          // value ("View & manage what your AI coach remembers") squeezed the
          // label to a sliver — "Coach memory" wrapped onto THREE lines and
          // broke mid-word ("memor / y"). Now both are flexible, the label
          // gets the larger share, and the value ellipsizes first.
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: labelColor ?? tc.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (value != null)
            Flexible(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: ZType.lbl(11,
                        color: tc.textMuted, letterSpacing: 1)),
              ),
            ),
          if (trailing != null) trailing!,
          if (trailing == null && showChevron && onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right,
                  size: 18, color: tc.textMuted),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// The one toggle style — hairline track + accent thumb when on.
class ZealovaToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const ZealovaToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: tc.accentContrast,
      activeTrackColor: tc.accent,
      inactiveThumbColor: tc.textMuted,
      inactiveTrackColor: tc.surface,
      trackOutlineColor: WidgetStatePropertyAll(tc.cardBorder),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
