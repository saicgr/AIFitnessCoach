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
    // The label is the row's IDENTITY and must win the width fight.
    //
    // `value` used to be an unconstrained trailing Text sharing the row with
    // the label (flex 3:6). That still truncated any genuinely descriptive
    // value ("Favorites, avoided & questionable ingredients") to a handful of
    // words + ellipsis, no matter the flex split, because a single line to
    // the right of a fixed-width icon + chevron simply never has room for a
    // full sentence. The value now sits on its own line BELOW the label,
    // left-aligned and indented to match, with two lines of room instead of
    // a truncated fragment of one.
    final labelRow = Row(
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 12)],
        Expanded(
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
        if (trailing != null) trailing!,
        if (trailing == null && showChevron && onTap != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(Icons.chevron_right,
                size: 18, color: tc.textMuted),
          ),
      ],
    );

    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: hairline
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: tc.hairline)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelRow,
          if (value != null)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: leading != null ? 42 : 0,
              ),
              child: Text(value!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: ZType.lbl(11,
                      color: tc.textMuted, letterSpacing: 1)),
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
