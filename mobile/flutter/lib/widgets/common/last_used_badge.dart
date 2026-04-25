import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';

/// Tiny "last used" marker shown on a picker option that matches the user's
/// most recent choice. Always a fixed-size [Icons.auto_awesome] sparkle so it
/// never causes RenderFlex overflow on narrow screens (per
/// `feedback_no_overflow_adaptive_screens.md`). The text "Last used" lives in
/// the Tooltip rather than as a visible label, which avoids localization
/// overflow risk.
///
/// Two variants:
/// - [LastUsedBadge.glow] — animated glowing border, used on the Share Period
///   sheet for extra visual delight (per design feedback memory).
/// - [LastUsedBadge.static] — same icon, no animation, used on the other
///   pickers (no motion fatigue, cheaper to render in lists).
class LastUsedBadge extends StatelessWidget {
  final bool _glowing;
  final Color? colorOverride;
  final double size;

  const LastUsedBadge.glow({super.key, this.colorOverride, this.size = 16})
      : _glowing = true;

  const LastUsedBadge.static({super.key, this.colorOverride, this.size = 16})
      : _glowing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        colorOverride ?? AccentColorScope.of(context).getColor(isDark);
    final icon = Icon(Icons.auto_awesome, size: size, color: color);
    final wrapped = Tooltip(message: 'Last used', child: icon);
    if (!_glowing) return wrapped;
    return _GlowingHalo(color: color, size: size, child: wrapped);
  }
}

class _GlowingHalo extends StatefulWidget {
  final Color color;
  final double size;
  final Widget child;

  const _GlowingHalo({
    required this.color,
    required this.size,
    required this.child,
  });

  @override
  State<_GlowingHalo> createState() => _GlowingHaloState();
}

class _GlowingHaloState extends State<_GlowingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Container(
            width: widget.size + 8,
            height: widget.size + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.30 + 0.30 * t),
                  blurRadius: 4 + 8 * t,
                  spreadRadius: 0.5 + 1.5 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
