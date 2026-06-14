import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';

enum ZealovaCardVariant {
  /// Near-flat surface, no border — for secondary blocks.
  flat,

  /// Hairline-outlined surface — the default Signature card.
  outlined,

  /// The hero/focus card (e.g. the coach to-do): surface + accent left edge.
  hero,
}

/// The Signature surface primitive. Replaces the per-screen `Container`
/// + glass-card zoo. Hairline-led; accent comes from the resolved
/// AccentColorScope (never hardcoded). Glass is reserved for sheets, not cards.
class ZealovaCard extends StatelessWidget {
  final Widget child;
  final ZealovaCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const ZealovaCard({
    super.key,
    required this.child,
    this.variant = ZealovaCardVariant.outlined,
    this.padding = const EdgeInsets.all(15),
    this.onTap,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final Color bg;
    Border? border;
    switch (variant) {
      case ZealovaCardVariant.flat:
        bg = tc.surface;
        border = null;
        break;
      case ZealovaCardVariant.outlined:
        bg = tc.surface;
        border = Border.all(color: AppColors.cardBorder, width: 1);
        break;
      case ZealovaCardVariant.hero:
        bg = tc.surface;
        border = Border(
          left: BorderSide(color: tc.accent, width: 3),
          top: BorderSide(color: AppColors.cardBorder),
          right: BorderSide(color: AppColors.cardBorder),
          bottom: BorderSide(color: AppColors.cardBorder),
        );
        break;
    }
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
