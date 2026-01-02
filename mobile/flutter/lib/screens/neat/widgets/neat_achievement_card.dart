import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Achievement tier levels with their properties
enum AchievementTier {
  bronze('Bronze', 0.2),
  silver('Silver', 0.4),
  gold('Gold', 0.6),
  platinum('Platinum', 0.8),
  diamond('Diamond', 1.0);

  final String label;
  final double threshold;

  const AchievementTier(this.label, this.threshold);

  Color get color {
    switch (this) {
      case bronze:
        return const Color(0xFFCD7F32);
      case silver:
        return const Color(0xFFC0C0C0);
      case gold:
        return const Color(0xFFFFD700);
      case platinum:
        return const Color(0xFFE5E4E2);
      case diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  Color get glowColor {
    switch (this) {
      case bronze:
        return const Color(0xFFCD7F32);
      case silver:
        return const Color(0xFF87CEEB);
      case gold:
        return const Color(0xFFFFD700);
      case platinum:
        return const Color(0xFF3B82F6);
      case diamond:
        return const Color(0xFF00CED1);
    }
  }

  IconData get icon {
    switch (this) {
      case bronze:
        return Icons.military_tech;
      case silver:
        return Icons.military_tech;
      case gold:
        return Icons.military_tech;
      case platinum:
        return Icons.workspace_premium;
      case diamond:
        return Icons.diamond;
    }
  }
}

/// Represents an achievement in the NEAT system
class NeatAchievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementTier tier;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0 for locked achievements
  final int? currentValue;
  final int? targetValue;

  const NeatAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    this.currentValue,
    this.targetValue,
  });

  bool get isNew {
    if (!isUnlocked || unlockedAt == null) return false;
    final difference = DateTime.now().difference(unlockedAt!);
    return difference.inDays < 3;
  }
}

/// A card widget displaying a NEAT achievement.
///
/// Features:
/// - Achievement icon with tier color (bronze, silver, gold, platinum, diamond)
/// - Achievement name and description
/// - "NEW!" badge for recently unlocked
/// - Progress bar for locked achievements
/// - Celebration animation on unlock
class NeatAchievementCard extends StatefulWidget {
  /// The achievement to display
  final NeatAchievement achievement;

  /// Whether to play unlock animation
  final bool playUnlockAnimation;

  /// Whether to use dark theme
  final bool isDark;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  const NeatAchievementCard({
    super.key,
    required this.achievement,
    this.playUnlockAnimation = false,
    this.isDark = true,
    this.onTap,
  });

  @override
  State<NeatAchievementCard> createState() => _NeatAchievementCardState();
}

class _NeatAchievementCardState extends State<NeatAchievementCard>
    with TickerProviderStateMixin {
  late AnimationController _unlockController;
  late AnimationController _shineController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shineAnimation;
  late Animation<double> _pulseAnimation;

  bool _hasPlayedUnlock = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Unlock celebration animation
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_unlockController);

    // Shine effect for unlocked achievements
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shineController,
      curve: Curves.linear,
    ));

    // Pulse animation for new achievements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.playUnlockAnimation && !_hasPlayedUnlock) {
      _triggerUnlock();
    }

    if (widget.achievement.isUnlocked) {
      _shineController.repeat();
    }

    if (widget.achievement.isNew) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _triggerUnlock() {
    _hasPlayedUnlock = true;
    HapticFeedback.heavyImpact();
    _unlockController.forward();
  }

  @override
  void didUpdateWidget(NeatAchievementCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle unlock transition
    if (widget.achievement.isUnlocked && !oldWidget.achievement.isUnlocked) {
      _triggerUnlock();
      _shineController.repeat();
    }

    if (widget.achievement.isNew != oldWidget.achievement.isNew) {
      if (widget.achievement.isNew) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _unlockController.dispose();
    _shineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final tier = achievement.tier;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        final scale = achievement.isNew
            ? _pulseAnimation.value
            : (_unlockController.isAnimating ? _scaleAnimation.value : 1.0);

        return Transform.scale(
          scale: scale,
          child: Semantics(
            label: _buildAccessibilityLabel(),
            button: widget.onTap != null,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: achievement.isUnlocked
                        ? tier.color.withOpacity(0.5)
                        : textMuted.withOpacity(0.2),
                    width: achievement.isUnlocked ? 2 : 1,
                  ),
                  boxShadow: achievement.isUnlocked
                      ? [
                          BoxShadow(
                            color: tier.glowColor.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Achievement icon
                    _AchievementIcon(
                      achievement: achievement,
                      shineAnimation: _shineAnimation,
                      isDark: isDark,
                    ),

                    const SizedBox(width: 16),

                    // Achievement info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name row with NEW badge
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  achievement.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: achievement.isUnlocked
                                        ? textPrimary
                                        : textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (achievement.isNew) ...[
                                const SizedBox(width: 8),
                                _NewBadge(),
                              ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Description
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: achievement.isUnlocked
                                  ? textSecondary
                                  : textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Progress bar for locked achievements
                          if (!achievement.isUnlocked) ...[
                            const SizedBox(height: 10),
                            _ProgressSection(
                              progress: achievement.progress,
                              currentValue: achievement.currentValue,
                              targetValue: achievement.targetValue,
                              tier: tier,
                              isDark: isDark,
                            ),
                          ],

                          // Unlocked date for unlocked achievements
                          if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: tier.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Tier badge
                    _TierBadge(
                      tier: tier,
                      isUnlocked: achievement.isUnlocked,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildAccessibilityLabel() {
    final achievement = widget.achievement;
    final parts = <String>[];

    parts.add(achievement.name);
    parts.add('${achievement.tier.label} tier');

    if (achievement.isUnlocked) {
      parts.add('Unlocked');
      if (achievement.isNew) {
        parts.add('New');
      }
    } else {
      parts.add('Locked');
      parts.add('${(achievement.progress * 100).toInt()} percent progress');
    }

    parts.add(achievement.description);

    return parts.join(', ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _AchievementIcon extends StatelessWidget {
  final NeatAchievement achievement;
  final Animation<double> shineAnimation;
  final bool isDark;

  const _AchievementIcon({
    required this.achievement,
    required this.shineAnimation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tier = achievement.tier;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return AnimatedBuilder(
      animation: shineAnimation,
      builder: (context, child) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: achievement.isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tier.color.withOpacity(0.4),
                      tier.color.withOpacity(0.2),
                    ],
                  )
                : null,
            color: achievement.isUnlocked ? null : glassSurface,
            border: Border.all(
              color: achievement.isUnlocked
                  ? tier.color.withOpacity(0.8)
                  : AppColors.textMuted.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: achievement.isUnlocked
                ? [
                    BoxShadow(
                      color: tier.glowColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  achievement.icon,
                  size: 28,
                  color: achievement.isUnlocked
                      ? tier.color
                      : AppColors.textMuted.withOpacity(0.5),
                ),
                // Shine effect
                if (achievement.isUnlocked)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ShinePainter(
                        progress: shineAnimation.value,
                        color: Colors.white.withOpacity(0.3),
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

class _ShinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShinePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0 || progress > 1) return;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(
        progress * size.width * 2 - size.width,
        0,
        size.width,
        size.height,
      ));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NewBadge extends StatefulWidget {
  @override
  State<_NewBadge> createState() => _NewBadgeState();
}

class _NewBadgeState extends State<_NewBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
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
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              'NEW!',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final int? currentValue;
  final int? targetValue;
  final AchievementTier tier;
  final bool isDark;

  const _ProgressSection({
    required this.progress,
    this.currentValue,
    this.targetValue,
    required this.tier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tier.color,
              ),
            ),
            if (currentValue != null && targetValue != null)
              Text(
                '$currentValue / $targetValue',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: glassSurface,
            color: tier.color.withOpacity(0.7),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  final AchievementTier tier;
  final bool isUnlocked;

  const _TierBadge({
    required this.tier,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnlocked
            ? tier.color.withOpacity(0.15)
            : AppColors.glassSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? tier.color.withOpacity(0.5)
              : AppColors.textMuted.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            size: 16,
            color: isUnlocked ? tier.color : AppColors.textMuted,
          ),
          const SizedBox(height: 2),
          Text(
            tier.label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? tier.color : AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
