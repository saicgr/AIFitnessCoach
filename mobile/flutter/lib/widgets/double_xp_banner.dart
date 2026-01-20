import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/xp_event.dart';
import '../data/providers/xp_provider.dart';
import '../core/constants/app_colors.dart';

/// A banner widget that shows when Double XP is active
class DoubleXPBanner extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onTap;

  const DoubleXPBanner({
    super.key,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(activeDoubleXPEventProvider);

    if (event == null) return const SizedBox.shrink();

    return compact
        ? _CompactBanner(event: event, onTap: onTap)
        : _FullBanner(event: event, onTap: onTap);
  }
}

class _FullBanner extends StatelessWidget {
  final XPEvent event;
  final VoidCallback? onTap;

  const _FullBanner({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getBannerColor(event).withValues(alpha: 0.9),
              _getBannerColor(event),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getBannerColor(event).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.bolt,
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Icon(
                Icons.star,
                size: 60,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // XP Icon with glow
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${event.xpMultiplier.toInt()}x',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: Colors.yellow,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.eventName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (event.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Time remaining
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ends in ${event.formattedTimeRemaining}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBanner extends StatelessWidget {
  final XPEvent event;
  final VoidCallback? onTap;

  const _CompactBanner({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getBannerColor(event),
              _getBannerColor(event).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt,
              color: Colors.yellow,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              event.multiplierDisplay,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.formattedTimeRemaining,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getBannerColor(XPEvent event) {
  // Use banner color from event if available, otherwise default to purple
  if (event.bannerColor != null) {
    try {
      return Color(int.parse(event.bannerColor!.replaceFirst('#', '0xFF')));
    } catch (_) {}
  }
  // Default gradient color for Double XP - purple for that premium XP feel
  return AppColors.purple;
}

/// A shimmer effect widget for the Double XP banner
class DoubleXPBannerShimmer extends StatefulWidget {
  final Widget child;

  const DoubleXPBannerShimmer({super.key, required this.child});

  @override
  State<DoubleXPBannerShimmer> createState() => _DoubleXPBannerShimmerState();
}

class _DoubleXPBannerShimmerState extends State<DoubleXPBannerShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Login streak display widget
class LoginStreakBadge extends ConsumerWidget {
  final bool showDetails;

  const LoginStreakBadge({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(loginStreakProvider);
    final theme = Theme.of(context);

    if (streak == null || streak.currentStreak == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${streak.currentStreak}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showDetails) ...[
            const SizedBox(width: 4),
            Text(
              'day streak',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// XP multiplier indicator (shows when multiplier > 1)
class XPMultiplierIndicator extends ConsumerWidget {
  const XPMultiplierIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiplier = ref.watch(xpMultiplierProvider);
    final theme = Theme.of(context);

    if (multiplier <= 1.0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt,
            color: Colors.yellow,
            size: 14,
          ),
          const SizedBox(width: 2),
          Text(
            '${multiplier.toStringAsFixed(multiplier == multiplier.roundToDouble() ? 0 : 1)}x',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
