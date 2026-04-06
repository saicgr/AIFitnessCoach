import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'components/components.dart';
import 'gym_profile_switcher.dart';
import 'stacked_banner_controller.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';

/// Clean, minimal header for the "Minimalist" home screen preset.
///
/// Layout:
/// ```
/// [Gym Profile Switcher - collapsed tabs]
/// Hey, {name}         [XP badge (level)] [bell icon]
/// ```
class MinimalHeader extends ConsumerWidget {
  const MinimalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpState = ref.watch(xpProvider);
    final accentColor = ref.watch(accentColorProvider);
    final accent = accentColor.getColor(isDark);
    final progress = xpState.progressFraction.clamp(0.0, 1.0);

    return Padding(
      key: AppTourKeys.topBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Gym Profile Switcher - takes remaining space
          const Expanded(
            child: GymProfileSwitcher(collapsed: true),
          ),

          // Layout Edit Button
          IconButton(
            onPressed: () {
              HapticService.light();
              context.push('/settings/homescreen');
            },
            icon: Icon(
              Icons.dashboard_customize_outlined,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Edit Layout',
          ),

          // Settings icon
          IconButton(
            onPressed: () {
              HapticService.light();
              context.push('/settings');
            },
            icon: Icon(
              Icons.settings_outlined,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Settings',
          ),

          // XP Level Badge with progress ring
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/xp-goals');
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter: _LevelRingPainter(
                  progress: progress,
                  accentColor: accent,
                  trackColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    '${xpState.currentLevel}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Dismiss All Banners button (only visible when banners exist)
          _DismissAllBannersButton(isDark: isDark),

          // Notification Bell
          NotificationBellButton(isDark: isDark),
        ],
      ),
    );
  }
}

/// Animated X icon that expands into a "Dismiss All" pill button.
///
/// Only visible when there are active banners in the stacked banner panel.
/// Tap once → expands to show "Dismiss All" label.
/// Tap again (while expanded) → dismisses all banners and collapses.
/// Also auto-collapses after 3 seconds if not tapped.
class _DismissAllBannersButton extends ConsumerStatefulWidget {
  final bool isDark;

  const _DismissAllBannersButton({required this.isDark});

  @override
  ConsumerState<_DismissAllBannersButton> createState() =>
      _DismissAllBannersButtonState();
}

class _DismissAllBannersButtonState
    extends ConsumerState<_DismissAllBannersButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final bannerIds = ref.read(activeBannerIdsProvider);
    if (bannerIds.isEmpty) return;

    HapticService.light();

    if (!_isExpanded) {
      // First tap: expand to show "Dismiss All"
      setState(() => _isExpanded = true);
      _expandController.forward();

      // Auto-collapse after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isExpanded) {
          setState(() => _isExpanded = false);
          _expandController.reverse();
        }
      });
    } else {
      // Second tap: dismiss all banners
      HapticService.medium();
      ref
          .read(stackedBannerControllerProvider.notifier)
          .dismissAll(bannerIds);

      // Collapse
      setState(() => _isExpanded = false);
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerIds = ref.watch(activeBannerIdsProvider);

    // Don't render when no banners
    if (bannerIds.isEmpty) {
      // If was expanded, reset
      if (_isExpanded) {
        _isExpanded = false;
        _expandController.reset();
      }
      return const SizedBox.shrink();
    }

    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 10 : 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? (widget.isDark
                      ? AppColors.elevated
                      : AppColorsLight.elevated)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: _isExpanded
                  ? Border.all(
                      color: widget.isDark
                          ? AppColors.cardBorder
                          : AppColorsLight.cardBorder,
                      width: 0.5,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _isExpanded ? AppColors.orange : textMuted,
                ),
                // Animated label
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axis: Axis.horizontal,
                  child: FadeTransition(
                    opacity: _expandAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Dismiss All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints a circular progress ring around the level number.
class _LevelRingPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color trackColor;

  _LevelRingPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    const strokeWidth = 3.0;

    // Track (background ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.trackColor != trackColor;
}
