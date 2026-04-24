import 'package:flutter/material.dart';

import '../../core/constants/synced_workout_kinds.dart';

/// Rounded solid-fill square with the [SyncedKind]'s icon on top.
///
/// Used on the synced-workout card (40), history list tile (56), and detail
/// hero banner (80). The fill color is `kind.palette.fg` at full saturation;
/// the icon is drawn in white for high contrast.
class KindAvatar extends StatelessWidget {
  final SyncedKind kind;
  final double size;

  const KindAvatar({
    super.key,
    required this.kind,
    this.size = 40,
  });

  const KindAvatar.small({super.key, required this.kind}) : size = 40;
  const KindAvatar.medium({super.key, required this.kind}) : size = 56;
  const KindAvatar.large({super.key, required this.kind}) : size = 80;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = kind.palette(isDark);
    final iconSize = size * 0.55;
    final radius = size * 0.26;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.fg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: palette.fg.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        kind.icon,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
