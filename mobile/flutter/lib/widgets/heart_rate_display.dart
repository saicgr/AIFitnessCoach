import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/heart_rate_provider.dart';

/// Compact heart rate display for workout screens.
/// Shows live BPM from watch with color-coded heart rate zone indicator.
/// Tap the zone badge to learn what the zone means (beginner-friendly).
class HeartRateDisplay extends ConsumerWidget {
  final double iconSize;
  final double fontSize;
  final bool showZoneLabel;
  final int? maxHR; // For accurate zone calculation

  const HeartRateDisplay({
    super.key,
    this.iconSize = 16,
    this.fontSize = 14,
    this.showZoneLabel = false,
    this.maxHR,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(liveHeartRateProvider);

    return heartRateAsync.when(
      loading: () => _buildDisplay(context, null, isLoading: true),
      error: (_, __) => _buildDisplay(context, null),
      data: (reading) => _buildDisplay(context, reading?.bpm),
    );
  }

  Widget _buildDisplay(BuildContext context, int? bpm, {bool isLoading = false}) {
    final zone = bpm != null ? getHeartRateZone(bpm, maxHr: maxHR ?? 190) : null;
    final color = zone != null ? Color(zone.colorValue) : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated heart icon
        _AnimatedHeartIcon(
          size: iconSize,
          color: isLoading ? Colors.grey : color,
          isAnimating: bpm != null,
        ),
        const SizedBox(width: 4),

        // BPM value
        if (isLoading)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.grey,
            ),
          )
        else if (bpm != null)
          Text(
            '$bpm',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
            ),
          )
        else
          Text(
            '--',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey,
            ),
          ),

        // Optional zone label - tappable for beginners
        if (showZoneLabel && zone != null) ...[
          const SizedBox(width: 4),
          _TappableZoneBadge(zone: zone, color: color),
        ],
      ],
    );
  }
}

/// Tappable zone badge that shows zone info dialog when tapped.
class _TappableZoneBadge extends StatelessWidget {
  final HeartRateZone zone;
  final Color color;

  const _TappableZoneBadge({
    required this.zone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showZoneInfo(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              zone.shortLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.info_outline,
              size: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showZoneInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.favorite,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${zone.name} Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              zone.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.speed,
              'Heart Rate',
              '${zone.percentageRange} of max',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.local_fire_department,
              'Fat Burned',
              '${(zone.fatCaloriePercent * 100).round()}% of calories',
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

/// Larger heart rate display with zone information.
/// Shows BPM prominently with zone name and percentage range.
class HeartRateDisplayLarge extends ConsumerWidget {
  const HeartRateDisplayLarge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(liveHeartRateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return heartRateAsync.when(
      loading: () => _buildContent(context, null, isLoading: true, isDark: isDark),
      error: (_, __) => _buildContent(context, null, isDark: isDark),
      data: (reading) => _buildContent(context, reading?.bpm, isDark: isDark),
    );
  }

  Widget _buildContent(BuildContext context, int? bpm, {bool isLoading = false, required bool isDark}) {
    final zone = bpm != null ? getHeartRateZone(bpm) : null;
    final color = zone != null ? Color(zone.colorValue) : Colors.grey;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Animated heart icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _AnimatedHeartIcon(
                size: 28,
                color: isLoading ? Colors.grey : color,
                isAnimating: bpm != null,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // BPM and zone info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      )
                    else if (bpm != null)
                      Text(
                        '$bpm',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: color,
                          height: 1,
                        ),
                      )
                    else
                      Text(
                        '--',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          height: 1,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'bpm',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (zone != null)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${zone.name} Zone',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zone.percentageRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    bpm == null ? 'Waiting for watch...' : 'Calculating zone...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated heart icon that pulses when receiving heart rate data.
class _AnimatedHeartIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool isAnimating;

  const _AnimatedHeartIcon({
    required this.size,
    required this.color,
    required this.isAnimating,
  });

  @override
  State<_AnimatedHeartIcon> createState() => _AnimatedHeartIconState();
}

class _AnimatedHeartIconState extends State<_AnimatedHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.95).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.05).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_AnimatedHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isAnimating ? _scaleAnimation.value : 1.0,
          child: Icon(
            Icons.favorite,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
