import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cosmetic.dart';
import '../../data/providers/cosmetics_provider.dart';

/// Wraps a circular avatar with the currently-equipped frame cosmetic (if any).
class EquippedFramedAvatar extends ConsumerWidget {
  final Widget child; // the avatar (e.g., CircleAvatar, NetworkImage etc.)
  final double size;

  const EquippedFramedAvatar({
    super.key,
    required this.child,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(equippedFrameProvider);
    return FramedAvatar(frame: frame, size: size, child: child);
  }
}

/// Renders any frame around an avatar. Used in gallery previews too.
class FramedAvatar extends StatelessWidget {
  final Cosmetic? frame;
  final Widget child;
  final double size;

  const FramedAvatar({
    super.key,
    required this.child,
    required this.size,
    this.frame,
  });

  @override
  Widget build(BuildContext context) {
    if (frame == null) {
      return SizedBox(width: size, height: size, child: ClipOval(child: child));
    }

    final primary = frame!.color ?? Colors.amber;
    final secondary = frame!.gradient ?? primary;
    final borderWidth = size * 0.08;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: frame!.isAnimated
              ? [primary, secondary, primary, secondary, primary]
              : [primary, secondary, primary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}
