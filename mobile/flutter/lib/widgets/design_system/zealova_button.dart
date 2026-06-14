import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';

enum ZealovaButtonVariant {
  /// THE one reserved-accent CTA per screen (solid accent fill, contrast text).
  primary,

  /// Secondary action — hairline outline, white label, no accent fill.
  ghost,
}

/// Signature button. `primary` is the single solid-accent CTA a screen is
/// allowed; everything else is `ghost` (outlined) to keep the accent reserved.
class ZealovaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ZealovaButtonVariant variant;
  final IconData? trailingIcon;
  final double height;
  final bool expand;

  const ZealovaButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = ZealovaButtonVariant.primary,
    this.trailingIcon,
    this.height = 52,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isPrimary = variant == ZealovaButtonVariant.primary;
    final fg = isPrimary ? tc.accentContrast : tc.textPrimary;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label.toUpperCase(),
            style: ZType.lbl(14, color: fg, letterSpacing: 2.5)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: fg),
        ],
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPrimary ? tc.accent : Colors.transparent,
            border: isPrimary ? null : Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// The universal quick-add "+" — white glyph on a subtle surface, never
/// accent-filled (keeps the accent reserved for the primary CTA).
class ZealovaPlusButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  const ZealovaPlusButton({super.key, this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tc.surface,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.add, size: 24, color: tc.textPrimary),
        ),
      ),
    );
  }
}
