import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/level_reward.dart';
import '../data/services/haptic_service.dart';

/// Dialog shown when user reaches a streak milestone
class StreakMilestoneDialog extends ConsumerStatefulWidget {
  final StreakMilestone milestone;
  final int currentStreak;
  final VoidCallback onDismiss;

  const StreakMilestoneDialog({
    super.key,
    required this.milestone,
    required this.currentStreak,
    required this.onDismiss,
  });

  @override
  ConsumerState<StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();
}

class _StreakMilestoneDialogState extends ConsumerState<StreakMilestoneDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _flameController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _flameAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    HapticService.heavy();
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _confettiController.play();
      HapticService.success();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  Color _getMilestoneColor() {
    if (widget.milestone.days >= 365) return const Color(0xFFFFD700); // Gold
    if (widget.milestone.days >= 180) return const Color(0xFF4FC3F7); // Diamond blue
    if (widget.milestone.days >= 90) return const Color(0xFFE5E4E2); // Platinum
    if (widget.milestone.days >= 60) return const Color(0xFFFFD700); // Gold
    if (widget.milestone.days >= 30) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);
    final milestoneColor = _getMilestoneColor();

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {},
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              Colors.orange,
              Colors.red,
              Colors.amber,
              milestoneColor,
              accentColor,
            ],
            numberOfParticles: 35,
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.05,
            gravity: 0.2,
          ),
        ),

        // Dialog content
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with fire emoji
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _flameAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _flameAnimation.value,
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 32),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.orange, Colors.red, Colors.orange],
                        ).createShader(bounds),
                        child: const Text(
                          'STREAK MILESTONE!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _flameAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _flameAnimation.value,
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 32),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Streak count badge
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.3),
                          Colors.red.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.orange,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.currentStreak}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'DAYS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Badge name
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          milestoneColor.withValues(alpha: 0.2),
                          milestoneColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: milestoneColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.milestone.badgeIcon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.milestone.badgeName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: milestoneColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    color: textSecondary.withValues(alpha: 0.2),
                  ),

                  const SizedBox(height: 16),

                  // Rewards section
                  Text(
                    'REWARDS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Streak shields reward
                  _buildRewardRow(
                    '🛡️',
                    '${widget.milestone.shieldCount}x Streak Shield${widget.milestone.shieldCount > 1 ? 's' : ''}',
                    'Protect your streak',
                    textPrimary,
                    textSecondary,
                  ),

                  // Bonus XP (if applicable)
                  if (widget.milestone.bonusXp != null) ...[
                    const SizedBox(height: 8),
                    _buildRewardRow(
                      '⚡',
                      '+${widget.milestone.bonusXp} Bonus XP',
                      'Added to your total',
                      textPrimary,
                      textSecondary,
                    ),
                  ],

                  // Cosmetic reward (if applicable)
                  if (widget.milestone.cosmeticReward != null) ...[
                    const SizedBox(height: 8),
                    _buildRewardRow(
                      '✨',
                      widget.milestone.cosmeticReward!,
                      'Profile cosmetic unlocked',
                      textPrimary,
                      textSecondary,
                      isRare: true,
                    ),
                  ],

                  // Merch reward (if applicable)
                  if (widget.milestone.hasMerch) ...[
                    const SizedBox(height: 8),
                    _buildRewardRow(
                      '🎁',
                      'FREE FitWiz Merch!',
                      'Claim in the Rewards tab',
                      textPrimary,
                      textSecondary,
                      isRare: true,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Next milestone preview
                  _buildNextMilestonePreview(textPrimary, textSecondary),

                  const SizedBox(height: 20),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.light();
                        widget.onDismiss();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.orange.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        'Keep the Streak Going!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardRow(
    String icon,
    String title,
    String subtitle,
    Color textPrimary,
    Color textSecondary, {
    bool isRare = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRare
            ? Colors.amber.withValues(alpha: 0.1)
            : textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: isRare
            ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isRare) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RARE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMilestonePreview(Color textPrimary, Color textSecondary) {
    final nextMilestone = StreakMilestone.nextMilestone(widget.currentStreak);
    if (nextMilestone == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You\'ve reached the ultimate streak milestone!',
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final daysUntil = nextMilestone.days - widget.currentStreak;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(nextMilestone.badgeIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next: ${nextMilestone.badgeName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '$daysUntil day${daysUntil > 1 ? 's' : ''} to go!',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${nextMilestone.days} days',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the streak milestone dialog
Future<void> showStreakMilestoneDialog(
  BuildContext context,
  StreakMilestone milestone,
  int currentStreak,
  VoidCallback onDismiss,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return StreakMilestoneDialog(
        milestone: milestone,
        currentStreak: currentStreak,
        onDismiss: () {
          Navigator.of(context).pop();
          onDismiss();
        },
      );
    },
  );
}
