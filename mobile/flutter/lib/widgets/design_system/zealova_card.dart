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
    final bool isHero = variant == ZealovaCardVariant.hero;

    // IMPORTANT: never combine a borderRadius with a NON-uniform border —
    // Flutter asserts/crashes ("A borderRadius can only be given on borders
    // with uniform colors"). So all variants use a UNIFORM border, and the
    // hero's accent left edge is painted as a clipped 3px overlay instead.
    final Border? border = variant == ZealovaCardVariant.flat
        ? null
        : Border.all(color: AppColors.cardBorder, width: 1);

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tc.surface,
        border: border,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    if (isHero) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            card,
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: tc.accent),
            ),
          ],
        ),
      );
    }

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
