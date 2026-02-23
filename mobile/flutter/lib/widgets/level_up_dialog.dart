import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/level_reward.dart';
import '../data/models/user_xp.dart';
import '../data/services/haptic_service.dart';

/// Level-up celebration dialog shown when user reaches a new level
class LevelUpDialog extends ConsumerStatefulWidget {
  final LevelUpEvent event;
  final VoidCallback onDismiss;

  const LevelUpDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  ConsumerState<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends ConsumerState<LevelUpDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _levelTransitionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _levelAnimation;

  bool _showNewLevel = false;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Scale animation for the dialog
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Level number transition animation
    _levelTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _levelAnimation = CurvedAnimation(
      parent: _levelTransitionController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Play haptic
    HapticService.heavy();

    // Start scale animation
    _scaleController.forward();

    // Start confetti
    _confettiController.play();

    // After a delay, animate level transition
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _levelTransitionController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _showNewLevel = true;
        });
        HapticService.success();
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _levelTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final newTitle = _getTitleForLevel(widget.event.newLevel);
    final titleColor = Color(newTitle.colorValue);

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {}, // Prevent tap-through
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
              titleColor,
              accentColor,
              Colors.amber,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            numberOfParticles: 30,
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
                  color: titleColor.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: titleColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header - LEVEL UP!
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        titleColor,
                        accentColor,
                        titleColor,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: titleColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Level transition badge
                  _buildLevelTransition(titleColor, textPrimary),

                  const SizedBox(height: 16),

                  // Congratulations message
                  Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You reached Level ${widget.event.newLevel}',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),

                  // New title badge (if title changed)
                  if (widget.event.hasNewTitle) ...[
                    const SizedBox(height: 12),
                    _buildNewTitleBadge(newTitle, titleColor),
                  ],

                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    color: textSecondary.withValues(alpha: 0.2),
                  ),

                  const SizedBox(height: 16),

                  // What's next section
                  _buildWhatsNextSection(textPrimary, textSecondary, titleColor),

                  const SizedBox(height: 16),

                  // Challenges section
                  _buildChallengesSection(
                      textPrimary, textSecondary, accentColor),

                  // Reward section - Show actual rewards from backend if available
                  const SizedBox(height: 16),
                  if (widget.event.hasRewards)
                    _buildBackendRewardsSection(textPrimary, titleColor)
                  else
                    _buildPerLevelRewardSection(textPrimary, titleColor),

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
                        backgroundColor: titleColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: titleColor.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        'Continue',
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

  Widget _buildLevelTransition(Color titleColor, Color textPrimary) {
    return AnimatedBuilder(
      animation: _levelAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                titleColor.withValues(alpha: 0.15),
                titleColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: titleColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Old level
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showNewLevel ? 0.4 : 1.0,
                child: _buildLevelBadge(
                  widget.event.oldLevel,
                  _getTitleForLevel(widget.event.oldLevel),
                  isOld: true,
                ),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _levelAnimation.value,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: titleColor,
                    size: 28,
                  ),
                ),
              ),

              // New level
              AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: _showNewLevel ? 1.1 : 0.8,
                curve: Curves.elasticOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _levelAnimation.value,
                  child: _buildLevelBadge(
                    widget.event.newLevel,
                    _getTitleForLevel(widget.event.newLevel),
                    isOld: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge(int level, XPTitle title, {required bool isOld}) {
    final color = Color(title.colorValue);
    final size = isOld ? 56.0 : 64.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isOld
            ? null
            : LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isOld ? color.withValues(alpha: 0.3) : null,
        border: Border.all(
          color: color,
          width: isOld ? 2 : 3,
        ),
        boxShadow: isOld
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Center(
        child: Text(
          level.toString(),
          style: TextStyle(
            fontSize: isOld ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: isOld ? color : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNewTitleBadge(XPTitle title, Color titleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            titleColor.withValues(alpha: 0.2),
            titleColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: titleColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: titleColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            'NEW TITLE: ${title.displayName.toUpperCase()}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: titleColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNextSection(
      Color textPrimary, Color textSecondary, Color accentColor) {
    final xpForNext = _getXpForNextLevel(widget.event.newLevel);
    final title = _getTitleForLevel(widget.event.newLevel);
    final nextMilestone = _getNextMilestone(widget.event.newLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, color: accentColor, size: 18),
            const SizedBox(width: 6),
            Text(
              "WHAT'S NEXT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.bolt,
          'XP to Level ${widget.event.newLevel + 1}',
          '${_formatNumber(xpForNext)} XP',
          textPrimary,
          textSecondary,
        ),
        const SizedBox(height: 6),
        _buildInfoRow(
          Icons.workspace_premium_rounded,
          'Title',
          '${title.displayName} (Levels ${title.levelRange})',
          textPrimary,
          textSecondary,
        ),
        // Show next milestone reward if there is one
        if (nextMilestone != null) ...[
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.card_giftcard_rounded,
            'Level ${nextMilestone.$1}',
            nextMilestone.$2,
            textPrimary,
            textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildChallengesSection(
      Color textPrimary, Color textSecondary, Color accentColor) {
    final challenges = _getLevelChallenges(widget.event.newLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_rounded, color: accentColor, size: 18),
            const SizedBox(width: 6),
            Text(
              'LEVEL ${widget.event.newLevel} CHALLENGES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...challenges.map((challenge) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      challenge,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  /// Build rewards section from actual backend response (Migration 231)
  Widget _buildBackendRewardsSection(Color textPrimary, Color titleColor) {
    final rewards = widget.event.rewards!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: titleColor, size: 18),
            const SizedBox(width: 6),
            Text(
              'REWARDS EARNED!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: titleColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rewards.map((reward) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRewardRow(reward, textPrimary, titleColor),
        )),
      ],
    );
  }

  /// Build a single reward row from backend reward data
  Widget _buildRewardRow(LevelUpReward reward, Color textPrimary, Color titleColor) {
    // Determine reward color based on type
    Color rewardColor;
    switch (reward.type) {
      case 'fitness_crate':
        rewardColor = Colors.orange;
        break;
      case 'premium_crate':
        rewardColor = Colors.purple;
        break;
      case 'streak_shield':
        rewardColor = Colors.blue;
        break;
      case 'xp_token_2x':
        rewardColor = Colors.amber;
        break;
      default:
        rewardColor = titleColor;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rewardColor.withValues(alpha: 0.15),
            rewardColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rewardColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rewardColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              reward.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${reward.level}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rewardColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${reward.displayName} x${reward.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textPrimary.withValues(alpha: 0.7),
                  ),
                ),
                // Show bonus if present (e.g., premium crate at major milestones)
                if (reward.hasBonus) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ ${reward.bonusDescription ?? "Bonus!"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerLevelRewardSection(Color textPrimary, Color titleColor) {
    final reward = LevelRewards.getRewardForLevel(widget.event.newLevel);

    // Determine reward color based on type
    Color rewardColor;
    IconData rewardIcon;
    String headerText;

    switch (reward.type) {
      case LevelRewardType.xpBonus:
        rewardColor = Colors.purple;
        rewardIcon = Icons.bolt_rounded;
        headerText = 'XP BONUS EARNED!';
        break;
      case LevelRewardType.streakShield:
        rewardColor = Colors.blue;
        rewardIcon = Icons.shield_rounded;
        headerText = 'SHIELD EARNED!';
        break;
      case LevelRewardType.doubleXpToken:
        rewardColor = Colors.amber;
        rewardIcon = Icons.star_rounded;
        headerText = 'TOKEN EARNED!';
        break;
      case LevelRewardType.cosmetic:
        rewardColor = Colors.pink;
        rewardIcon = Icons.auto_awesome_rounded;
        headerText = 'COSMETIC UNLOCKED!';
        break;
      case LevelRewardType.merch:
        rewardColor = Colors.green;
        rewardIcon = Icons.card_giftcard_rounded;
        headerText = '🎁 FREE MERCH UNLOCKED!';
        break;
      case LevelRewardType.crate:
        rewardColor = Color(CrateTierExtension.forLevel(widget.event.newLevel).colorValue);
        rewardIcon = Icons.inventory_2_rounded;
        headerText = 'FITNESS CRATE EARNED!';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rewardColor.withValues(alpha: 0.15),
            rewardColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rewardColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rewardColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: reward.icon != null
                ? Text(
                    reward.icon!,
                    style: const TextStyle(fontSize: 24),
                  )
                : Icon(
                    rewardIcon,
                    color: rewardColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rewardColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reward.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods

  XPTitle _getTitleForLevel(int level) {
    if (level <= 10) return XPTitle.novice;
    if (level <= 25) return XPTitle.apprentice;
    if (level <= 50) return XPTitle.athlete;
    if (level <= 75) return XPTitle.elite;
    if (level <= 99) return XPTitle.master;
    if (level == 100) return XPTitle.legend;
    return XPTitle.mythic;
  }

  int _getXpForNextLevel(int currentLevel) {
    if (currentLevel < 10) return 1000;
    if (currentLevel < 25) return 2500;
    if (currentLevel < 50) return 7500;
    if (currentLevel < 75) return 15000;
    if (currentLevel < 99) return 35000;
    if (currentLevel == 99) return 100000;
    return 150000; // Prestige levels
  }

  List<String> _getLevelChallenges(int level) {
    // Dynamic challenges based on level tier
    if (level <= 10) {
      return [
        'Complete ${level + 2} workouts this week',
        'Try a new exercise type',
        'Log your meals for 3 days',
      ];
    } else if (level <= 25) {
      return [
        'Complete ${(level / 5).ceil() + 3} workouts this week',
        'Set 2 new personal records',
        'Maintain a 7-day login streak',
      ];
    } else if (level <= 50) {
      return [
        'Complete 5+ workouts this week',
        'Set 3 new personal records',
        'Hit your protein goal 5 days in a row',
      ];
    } else if (level <= 75) {
      return [
        'Complete 6 workouts this week',
        'Set 5 new personal records',
        'Maintain a 14-day streak',
        'Log meals for 10 consecutive days',
      ];
    } else {
      return [
        'Complete 7 workouts this week',
        'Set 5+ personal records',
        'Maintain a 30-day streak',
        'Achieve a perfect week',
      ];
    }
  }

  String? _getLevelUnlock(int level) {
    // Cosmetic rewards + merch only (no gift cards to prevent fraud)
    switch (level) {
      case 5:
        return '"Rising Star" profile badge';
      case 10:
        return 'Custom profile frame unlock';
      case 15:
        return 'Exclusive theme color options';
      case 25:
        return '"Dedicated" animated badge';
      case 35:
        return 'Animated profile effects';
      case 50:
        return '"Veteran" badge + FREE FitWiz T-Shirt!';
      case 75:
        return '"Elite" holographic badge + FREE Shaker Bottle!';
      case 100:
        return '"Legend" animated badge + FREE FitWiz Hoodie + Merch Kit!';
      default:
        return null;
    }
  }

  /// Returns the next milestone level and its reward as a tuple (level, reward)
  /// Returns null if already at max or no upcoming milestone
  (int, String)? _getNextMilestone(int currentLevel) {
    // List of milestone levels in order
    const milestones = [5, 10, 15, 25, 35, 50, 75, 100];

    for (final milestone in milestones) {
      if (currentLevel < milestone) {
        final reward = _getLevelUnlock(milestone);
        if (reward != null) {
          return (milestone, reward);
        }
      }
    }
    return null; // Already at or past level 100
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}

/// Shows the level-up dialog
Future<void> showLevelUpDialog(
  BuildContext context,
  LevelUpEvent event,
  VoidCallback onDismiss,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return LevelUpDialog(
        event: event,
        onDismiss: () {
          Navigator.of(dialogContext).pop();
          onDismiss();
        },
      );
    },
  );
}
