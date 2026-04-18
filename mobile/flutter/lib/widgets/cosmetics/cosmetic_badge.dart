import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cosmetic.dart';
import '../../data/providers/cosmetics_provider.dart';

/// Renders a small pill-shaped badge for an equipped badge cosmetic.
/// Renders nothing if no badge is equipped.
class EquippedBadgePill extends ConsumerWidget {
  final double height;
  final bool showLabel;
  final VoidCallback? onTap;

  const EquippedBadgePill({
    super.key,
    this.height = 22,
    this.showLabel = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(equippedBadgeProvider);
    if (badge == null) return const SizedBox.shrink();
    return CosmeticBadgePill(
      cosmetic: badge,
      height: height,
      showLabel: showLabel,
      onTap: onTap,
    );
  }
}

/// Renders any cosmetic as a badge pill. Used in gallery + equipped display.
class CosmeticBadgePill extends StatelessWidget {
  final Cosmetic cosmetic;
  final double height;
  final bool showLabel;
  final VoidCallback? onTap;

  const CosmeticBadgePill({
    super.key,
    required this.cosmetic,
    this.height = 22,
    this.showLabel = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = cosmetic.color ?? Colors.amber;
    final secondary = cosmetic.gradient ?? primary;

    final pill = Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.symmetric(horizontal: showLabel ? 10 : 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(height),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cosmetic.emoji != null)
            Text(cosmetic.emoji!, style: TextStyle(fontSize: height * 0.7)),
          if (showLabel) ...[
            if (cosmetic.emoji != null) SizedBox(width: height * 0.2),
            Text(
              cosmetic.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.52,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(height),
      child: pill,
    );
  }
}
