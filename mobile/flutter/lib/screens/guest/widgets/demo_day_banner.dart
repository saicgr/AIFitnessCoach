import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demo Day Banner Widget
///
/// Shows a prominent banner with countdown timer for Demo Day (24-hour full access).
/// Features animated gradient background and shimmer effects.
class DemoDayBanner extends ConsumerStatefulWidget {
  final DateTime? demoDayEndTime;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const DemoDayBanner({
    super.key,
    this.demoDayEndTime,
    this.onTap,
    this.onDismiss,
  });

  @override
  ConsumerState<DemoDayBanner> createState() => _DemoDayBannerState();
}

class _DemoDayBannerState extends ConsumerState<DemoDayBanner>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _updateRemainingTime();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  void _updateRemainingTime() {
    if (widget.demoDayEndTime == null) {
      setState(() => _remainingTime = Duration.zero);
      return;
    }

    final now = DateTime.now();
    final remaining = widget.demoDayEndTime!.difference(now);

    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime == Duration.zero) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1), // Indigo
              const Color(0xFF8B5CF6), // Purple
              const Color(0xFFEC4899), // Pink
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shimmer overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0),
                          ],
                          stops: [
                            _shimmerController.value - 0.3,
                            _shimmerController.value,
                            _shimmerController.value + 0.3,
                          ].map((s) => s.clamp(0.0, 1.0)).toList(),
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Demo Day badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DEMO DAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Dismiss button
                      if (widget.onDismiss != null)
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Main message
                  Text(
                    '24 Hours of Full Access',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore all premium features - no commitment',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Countdown timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time Remaining: ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatTime(_remainingTime),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Features included
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureChip('AI Workouts'),
                      _buildFeatureChip('Full Library'),
                      _buildFeatureChip('Nutrition'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of the Demo Day Banner for inline use
class DemoDayBannerCompact extends StatelessWidget {
  final Duration remainingTime;
  final VoidCallback? onTap;

  const DemoDayBannerCompact({
    super.key,
    required this.remainingTime,
    this.onTap,
  });

  String _formatTimeCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    }
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    if (remainingTime == Duration.zero) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Demo Day: ${_formatTimeCompact(remainingTime)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
