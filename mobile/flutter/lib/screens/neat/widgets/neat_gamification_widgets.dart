import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';


part 'neat_gamification_widgets_part_neat_level.dart';
part 'neat_gamification_widgets_part_neat_milestone_popup_state.dart';
part 'neat_gamification_widgets_part_leaderboard_row.dart';


/// NEAT Level Badge widget - displays user's current NEAT level with visual flair.
///
/// Features:
/// - Animated glow effect for higher levels
/// - Emoji icon representing level
/// - Gradient background based on tier
/// - Tap callback for level details
class NeatLevelBadge extends StatefulWidget {
  final NeatLevel level;
  final bool showName;
  final double size;
  final VoidCallback? onTap;

  const NeatLevelBadge({
    super.key,
    required this.level,
    this.showName = true,
    this.size = 48,
    this.onTap,
  });

  @override
  State<NeatLevelBadge> createState() => _NeatLevelBadgeState();
}

class _NeatLevelBadgeState extends State<NeatLevelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Only animate for higher levels
    if (widget.level.index >= NeatLevel.neatEnthusiast.index) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighLevel = widget.level.index >= NeatLevel.neatEnthusiast.index;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          HapticService.light();
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: widget.showName
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : EdgeInsets.all(widget.size * 0.2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.level.color.withOpacity(0.2),
                  widget.level.color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.showName ? 24 : 16),
              border: Border.all(
                color: widget.level.color.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: isHighLevel
                  ? [
                      BoxShadow(
                        color: widget.level.color
                            .withOpacity(0.2 + _pulseController.value * 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Level emoji with potential glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isHighLevel)
                      Container(
                        width: widget.size * 0.6,
                        height: widget.size * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.level.color
                                  .withOpacity(0.3 + _pulseController.value * 0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    Text(
                      widget.level.emoji,
                      style: TextStyle(fontSize: widget.size * 0.5),
                    ),
                  ],
                ),
                if (widget.showName) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.level.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.level.color,
                        ),
                      ),
                      Text(
                        'Level ${widget.level.index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
