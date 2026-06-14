import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';

/// The 1px hairline that replaces boxed-card stacks in the Signature language.
class ZealovaRule extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;
  final bool strong;
  const ZealovaRule({
    super.key,
    this.height = 1,
    this.margin = EdgeInsets.zero,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      color: strong ? AppColors.hairlineStrong : AppColors.hairline,
    );
  }
}

/// Uppercase Barlow Condensed section kicker (e.g. "TODAY'S FOCUS", "FUEL").
/// Optionally tinted with the resolved accent.
class ZealovaSectionKicker extends StatelessWidget {
  final String label;
  final bool accent;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  const ZealovaSectionKicker(
    this.label, {
    super.key,
    this.accent = false,
    this.fontSize = 11,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: padding,
      child: Text(
        label.toUpperCase(),
        style: ZType.lbl(
          fontSize,
          color: accent ? tc.accent : tc.textMuted,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
